#!/usr/bin/env python3
"""Builds the owner-facing authoring files (docs/CONTENT_SCHEMA.md section 2)
from the text layer of the Beni Suef edition PDF.

  python3 tools/book_import/build_authoring.py <raw.txt> <outDir> [--lexicon ar_full.txt]

Writes  <outDir>/book.txt, NNN-<slug>.txt per unit, REVIEW.md and
kaf_decisions.json (reused on later runs, so the lexicon is only needed once).
It never invents text: it only (a) repairs known extraction damage and
(b) rejoins hard-wrapped lines into paragraphs. Every repair is counted in
REVIEW.md for the owner.
"""
import argparse
import collections
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from kaf_repair import TOKEN, decide  # noqa: E402
from structure import UNITS, FRONT_SECTIONS  # noqa: E402

HAND_KEEP = frozenset({
    'آمين', 'آمون', 'آيات', 'آبائه', 'آباءك', 'آثامهم', 'وآمنوا', 'آية',
    'آتي', 'ابرآم', 'آثرت', 'آلة', 'آنية', 'فرآه', 'ورآه',
})

ARABIC = '\u0621-\u064a'
PAIN_SUFFIX = re.compile(r'^(?:و|ف|ب|ل)?آلام(?:ه|ك|هم|ي|ها|نا|كم|ا)?$')


def context_keep(token, prev, nxt):
    """Small context rules for words that are really ambiguous."""
    if PAIN_SUFFIX.match(token):
        if prev in ('توجد', 'وتوجد'):
            return True
        if prev == 'ولا' and nxt == 'جسمك':
            return True
        if prev == 'في' and nxt == 'المحيية':
            return True
    if token == 'وآمل' and nxt == 'أن':
        return True
    return False


class Stats:
    def __init__(self):
        self.counts = collections.Counter()
        self.kaf = collections.defaultdict(collections.Counter)  # status -> (orig,new)


def load_lexicon(path):
    lex = {}
    with open(path, encoding='utf-8') as f:
        for line in f:
            p = line.split()
            if len(p) == 2 and p[1].isdigit():
                lex[p[0]] = int(p[1])
    return lex


def repair_kaf(text, lex, decisions, stats):
    pieces = []
    last = 0
    toks = list(TOKEN.finditer(text))
    for i, m in enumerate(toks):
        tok = m.group(0)
        if 'آ' not in tok:
            continue
        prev = toks[i - 1].group(0) if i else ''
        nxt = toks[i + 1].group(0) if i + 1 < len(toks) else ''
        if context_keep(tok, prev, nxt):
            new, status = tok, 'context-kept'
        elif tok in decisions:
            new, status = decisions[tok]
        else:
            if lex is None:
                raise SystemExit(f'No decision for {tok!r}: run once with --lexicon')
            new, status = decide(tok, lex, HAND_KEEP)
            decisions[tok] = (new, status)
        stats.kaf[status][(tok, new)] += 1
        if new != tok:
            pieces.append(text[last:m.start()])
            pieces.append(new)
            last = m.end()
    pieces.append(text[last:])
    return ''.join(pieces)


def fix_chars(text, stats):
    n = text.count('\u06cc')
    text = text.replace('\u06cc', '\u064a')
    stats.counts['farsi-yeh->yeh'] += n
    n = text.count('االله')
    text = text.replace('االله', 'الله')
    stats.counts['alef-alef-lam-lam-ha->allah'] += n
    # tanwin displaced behind punctuation:  جدا،ً  ->  جداً،
    pat = re.compile(f'([{ARABIC}])([.،؛:؟!]+)\u064b')
    text, n = pat.subn('\\1\u064b\\2', text)
    stats.counts['tanwin-moved-before-punctuation'] += n
    return text


def clean_lines(raw):
    lines = []
    for l in raw.replace('\r\n', '\n').replace('\r', '\n').split('\n'):
        lines.append(l.rstrip())
    return lines


NUM_ITEM = re.compile(r'^-(\d+)\s+(.*)$')
LEAD_DOT = re.compile(r'^\.(?!\.)\s*')
PAREN_ITEM = re.compile(r'^\((?:[أ-ي]|\d+|ه\u0640?)\)')
FOOTNOTE = re.compile(r'^\(\d+\)')
SPEECH = re.compile(r'(?:^|\s)(?:و|ف)?(?:قال|قالت|قيل|قالوا|سأل|سألت|سئل|سأله|حدث|مرة|أجاب|اجاب|يقول|تقول|اذ|الجواب|جواب|سؤال|قائلا|قائلاً)(?:\s|$)')
TERMINAL = ('.', '؟', '!', ':', '"', '\u201d', '»', ')', '؛')


def prev_ends_sentence(lines, i):
    """A heading starts after a blank line, a finished sentence, or another
    short title line; a line after an unfinished line is a wrapped fragment."""
    if i == 0:
        return True
    p = lines[i - 1].strip()
    if not p or p.endswith(TERMINAL + ('،',)):
        return True
    # previous line is itself a short standalone title (e.g. saint name)
    pp = lines[i - 2].strip() if i >= 2 else ''
    return (not pp) and len(p) <= 60 and not lines[i - 1].startswith(' ')


def is_colon_heading(line):
    """A short title line like "نشأته:". Sayings introductions such as
    "+ وقال مار اسحق:" are body text, not headings."""
    s = line.strip()
    core = s.rstrip(':').strip()
    return (line == line.lstrip() and 0 < len(s) <= 55 and s.endswith(':')
            and not s.startswith('+') and len(core.split()) <= 7
            and not SPEECH.search(core) and not PAREN_ITEM.match(s))


def is_paren_heading(line):
    s = line.strip()
    return line == line.lstrip() and len(s) <= 70 and s.endswith(':') and bool(PAREN_ITEM.match(s))


def block_paragraphs(lines, stats):
    """lines (already char-fixed) -> list of dicts {kind, text, indent}

    kind: 'section' (colon / numbered topic heading), 'heading' (###),
          'body', 'list'. indent: the paragraph started with an indent, a
          "+" or a "(n)" marker (a real paragraph start).
    """
    out = []
    buf = []
    buf_indent = [False]

    def flush():
        if buf:
            out.append({'kind': 'body', 'text': ' '.join(x.strip() for x in buf),
                        'indent': buf_indent[0]})
            buf.clear()
            buf_indent[0] = False

    i = 0
    n = len(lines)
    while i < n:
        line = lines[i]
        s = line.strip()
        if not s:
            flush()
            i += 1
            continue
        # a displaced full stop at the start of a line belongs to the line before
        if LEAD_DOT.match(s) and (s.startswith('. ') or line == line.lstrip()):
            rest = LEAD_DOT.sub('', s, count=1)
            if buf:
                buf[-1] = buf[-1].rstrip() + '.'
                stats.counts['leading-dot-moved-to-previous-line'] += 1
            elif out and out[-1]['kind'] == 'body':
                out[-1]['text'] = out[-1]['text'].rstrip() + '.'
                stats.counts['leading-dot-moved-to-previous-line'] += 1
            line = rest
            s = rest.strip()
            lines[i] = line
            if not s:
                i += 1
                continue
        mnum = NUM_ITEM.match(s) if line == line.lstrip() else None
        if mnum:
            j = i
            run = []
            while (j < n and lines[j].strip() and NUM_ITEM.match(lines[j].strip())
                   and lines[j] == lines[j].lstrip()):
                run.append(lines[j].strip())
                j += 1
            if len(run) >= 2:
                flush()
                out.append({'kind': 'list', 'indent': True, 'text': '\n'.join(
                    f'{NUM_ITEM.match(r).group(1)}- {NUM_ITEM.match(r).group(2)}' for r in run)})
                stats.counts['numbered-lists'] += 1
                i = j
                continue
            if len(s) <= 110 and not s.endswith(('،', '؟')) and prev_ends_sentence(lines, i):
                flush()
                title = f'{mnum.group(1)}- {mnum.group(2)}'.rstrip(':').strip()
                out.append({'kind': 'section', 'text': title, 'indent': True})
                i += 1
                continue
        if is_colon_heading(line) and prev_ends_sentence(lines, i):
            flush()
            out.append({'kind': 'section', 'text': s.rstrip(':').strip(), 'indent': True})
            i += 1
            continue
        if is_paren_heading(line) and prev_ends_sentence(lines, i):
            flush()
            out.append({'kind': 'heading', 'text': s.rstrip(':').strip(), 'indent': True})
            i += 1
            continue
        starts_new = (line.startswith(' ') or s.startswith('+')
                      or bool(FOOTNOTE.match(s)) or bool(PAREN_ITEM.match(s)))
        prev_blank = (i == 0) or not lines[i - 1].strip()
        nxt_blank = (i + 1 >= n) or not lines[i + 1].strip()
        if (prev_blank and nxt_blank and not starts_new and len(s) <= 60
                and not s.endswith(('.', '،', '؟', '!', '"', ')', ':', '؛'))):
            flush()
            out.append({'kind': 'heading', 'text': s, 'indent': True})
            i += 1
            continue
        if starts_new:
            flush()
        if not buf:
            buf_indent[0] = starts_new
        buf.append(s)
        i += 1
    flush()
    return out


def merge_page_breaks(items, stats):
    """Text cut by a page break: the next unindented paragraph continues the
    last unfinished body paragraph (footnote paragraphs in between are kept
    and moved after the merged paragraph)."""
    out = []
    last_body = None  # index in out
    held = []         # footnotes seen since last_body
    for it in items:
        if it['kind'] == 'body' and FOOTNOTE.match(it['text']):
            if last_body is not None and not held and out[-1] is not out[last_body]:
                pass
            held.append(it)
            out.append(it)
            continue
        if it['kind'] == 'body':
            if (not it['indent'] and last_body is not None
                    and not out[last_body]['text'].rstrip().endswith(TERMINAL)):
                out[last_body]['text'] = out[last_body]['text'].rstrip() + ' ' + it['text']
                stats.counts['page-break-paragraphs-rejoined'] += 1
                # footnotes that sat in between stay where they are (after)
                held = []
                continue
            out.append(it)
            last_body = len(out) - 1
            held = []
            continue
        out.append(it)
        if it['kind'] in ('section', 'heading', 'list'):
            last_body = None
            held = []
    return out


def split_unit_title(lines, title):
    """Leading title lines of a unit -> (epithet or None, remaining lines)."""
    k = 0
    heads = []
    while k < len(lines) and len(heads) < 3:
        s = lines[k].strip()
        if (not s or len(s) > 60 or lines[k].startswith(' ')
                or s.endswith((':', '.', '،', '؟')) or PAREN_ITEM.match(s)):
            break
        heads.append(s)
        k += 1
    # the saint / chapter name is on the first line (or the first two, when
    # the first is only an honorific such as "القديس")
    name_lines = 1
    if heads and heads[0] in ('القديس', 'الأب', 'الأنبا', 'القديسة', 'أنبا'):
        name_lines = 2
    epithet = ' '.join(heads[name_lines:]) or None
    if epithet and epithet in title:
        epithet = None
    return epithet, lines[k:]


def assemble_sections(items, first_title, epithet):
    """items -> [[title, [(kind,text)...]], ...]. A section heading with no
    text of its own becomes a ### heading at the top of the next section."""
    sections = []
    cur = None
    pre = []
    carry = []
    for it in items:
        k, t = it['kind'], it['text']
        if k == 'section':
            if cur is not None and not cur[1]:
                carry.append(('heading', cur[0]))
                sections.pop()
            cur = [t, list(carry)]
            carry = []
            sections.append(cur)
            if pre:
                cur[1][0:0] = pre
                pre = []
        elif cur is None:
            pre.append((k, t))
        else:
            cur[1].append((k, t))
    if cur is not None and not cur[1]:
        sections.pop()
        if sections:
            sections[-1][1].append(('heading', cur[0]))
        else:
            sections.append([cur[0], []])
    if pre:
        sections.insert(0, [first_title, pre])
    if epithet:
        if not sections:
            sections.append([first_title, []])
        sections[0][1].insert(0, ('heading', epithet))
    return sections


def render(unit_id, title, aliases, sections):
    o = ['@saint', f'id: {unit_id}', f'title: {title}']
    if aliases:
        o.append('aliases: ' + '; '.join(aliases))
    o += ['fixture: false', '']
    for st, items in sections:
        o.append(f'## {st}')
        for kind, text in items:
            if kind == 'heading':
                o.append(f'### {text}')
            else:
                o.append(text)
                o.append('')
        if o[-1] != '':
            o.append('')
    return '\n'.join(o).rstrip() + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('raw')
    ap.add_argument('out')
    ap.add_argument('--lexicon')
    a = ap.parse_args()
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    dec_path = Path(__file__).parent / 'kaf_decisions.json'
    decisions = {}
    if dec_path.exists():
        decisions = {k: tuple(v) for k, v in json.loads(dec_path.read_text(encoding='utf-8')).items()}
    lex = load_lexicon(a.lexicon) if a.lexicon else None

    stats = Stats()
    raw_lines = clean_lines(Path(a.raw).read_text(encoding='utf-8'))
    # verification of the structure table against the raw text
    for uid, slug, title, start, must, _ in UNITS:
        line = raw_lines[start - 1].replace('\u06cc', '\u064a')
        # heading may be split over two lines (القديس / name)
        window = line + ' ' + raw_lines[start].replace('\u06cc', '\u064a')
        if must not in window:
            raise SystemExit(f'Structure check failed for {uid}: line {start} is {line!r}, expected {must!r}')

    starts = [u[3] for u in UNITS] + [len(raw_lines) + 1]
    summary = []
    for idx, (uid, slug, title, start, must, aliases) in enumerate(UNITS):
        lines = raw_lines[start - 1: starts[idx + 1] - 1]
        text = fix_chars('\n'.join(lines), stats)
        text = repair_kaf(text, lex, decisions, stats)
        lines = text.split('\n')
        if uid == 'front-matter':
            bounds = [x for x, _ in FRONT_SECTIONS] + [starts[1]]
            sections = []
            for k, (sl, st) in enumerate(FRONT_SECTIONS):
                seg = lines[sl - 1: bounds[k + 1] - 1]
                items = merge_page_breaks(block_paragraphs(seg, stats), stats)
                for it in items:
                    if it['kind'] == 'section':
                        it['kind'] = 'heading'
                items = [it for it in items
                         if not (it['kind'] == 'heading' and it['text'].replace('\u064b', '') == st)]
                sections.append([st, [(it['kind'], it['text']) for it in items]])
        else:
            epithet, rest = split_unit_title(lines, title)
            items = merge_page_breaks(block_paragraphs(rest, stats), stats)
            sections = assemble_sections(items, title, epithet)
        body = render(uid, title, aliases, sections)
        nsec = len(sections)
        npar = sum(len(i) for _, i in sections)
        fname = f'{idx + 1:03d}-{slug}.txt'
        (out / fname).write_text(body, encoding='utf-8')
        summary.append((fname, uid, title, nsec, npar, len(body)))

    (out / 'book.txt').write_text('\n'.join([
        '@book',
        'id: bustan-al-rohban',
        'title: بستان الرهبان',
        'language: ar',
        'fixture: false',
        'edition: بستان الرهبان لآباء الكنيسة القبطية',
        'publisher: لجنة التحرير والنشر بمطرانية بني سويف والبهنسا',
        'year: 1968 (مقدمة الطبعة الأولى) / 1976 (مقدمة الطبعة الثانية)',
        'attribution: قام بمراجعته وتنقيحه لجنة التحرير والنشر بمطرانية بني سويف والبهنسا',
        'rights: owner-confirmed',
        '',
    ]), encoding='utf-8')
    dec_path.write_text(json.dumps({k: list(v) for k, v in sorted(decisions.items())}, ensure_ascii=False, indent=1), encoding='utf-8')
    write_review(out / 'REVIEW.md', stats, summary)
    print(json.dumps({'files': len(summary)}))


def write_review(path, stats, summary):
    b = ['# Import review (generated)', '',
         'Text repairs applied to the PDF text layer. Nothing else was changed except',
         'rejoining hard-wrapped lines into paragraphs. Please review the kaf list.', '',
         '## Counts', '']
    for k, v in stats.counts.items():
        b.append(f'- {k}: {v}')
    for status, c in stats.kaf.items():
        b.append(f'- kaf `{status}`: {sum(c.values())} occurrences, {len(c)} distinct words')
    b += ['', '## Units', '', '| File | Id | Title | Sections | Paragraph blocks |', '|---|---|---|---|---|']
    for f, uid, t, ns, npar, _ in summary:
        b.append(f'| {f} | {uid} | {t} | {ns} | {npar} |')
    for status in ('review', 'unknown', 'context-kept', 'hand', 'legit'):
        c = stats.kaf.get(status)
        if not c:
            continue
        b += ['', f'## kaf: {status} ({len(c)} words)', '']
        b.append({'review': 'Replaced by default (kaf) but the word list was not decisive. CHECK THESE.',
                  'unknown': 'Not in the word list (names, rare forms): kaf restored. Check names.',
                  'context-kept': 'Kept as alef-madda by a context rule.',
                  'hand': 'Kept as alef-madda by an explicit decision.',
                  'legit': 'Kept: real alef-madda words (آخر، آباء، الآن ...).'}[status])
        b.append('')
        for (o, n), cnt in sorted(c.items(), key=lambda x: -x[1]):
            b.append(f'- {o} → {n} ({cnt})')
    b += ['', '## Fixed (sample of the most frequent)', '']
    for (o, n), cnt in sorted(stats.kaf.get('fixed', {}).items(), key=lambda x: -x[1])[:60]:
        b.append(f'- {o} → {n} ({cnt})')
    path.write_text('\n'.join(b) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
