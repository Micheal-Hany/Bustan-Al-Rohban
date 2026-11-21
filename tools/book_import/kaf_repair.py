"""Repairs the kaf corruption of the Beni Suef PDF text layer.

In the PDF's font the *initial form* of kaf (word start, or right after a
letter that does not join to the next one) was extracted as alef-madda (آ).
Kaf after a joining letter and word-final kaf came out correctly, so an
alef-madda right after a joining letter is a real alef-madda (الآن, الآباء).

Only initial-position alef-madda needs a decision. Order of decision:
  1. a stem of real alef-madda words (آخر, آمين, آباء, آدم, ...)  -> keep
  2. the word-frequency list strongly prefers the alef-madda word   -> keep
  3. otherwise                                                      -> kaf
Every decision is written to the review file for the owner; contexts that
are ambiguous by nature (آلام: pains / speech) use small context rules.
"""
import re

NON_JOINING = set('ادذرزوؤأإآةىء')
ARABIC = 'ء-ي'
TOKEN = re.compile(f'[{ARABIC}ً-ْـ]+')
DIAC = re.compile('[ً-ْـ]')

RATIO = 25


def strip_diac(t: str) -> str:
    return DIAC.sub('', t)


def initial_positions(token: str):
    out = []
    for i, ch in enumerate(token):
        if ch == 'آ' and (i == 0 or token[i - 1] in NON_JOINING):
            out.append(i)
    return out


def to_kaf(token: str, positions) -> str:
    chars = list(token)
    for p in positions:
        chars[p] = 'ك'
    return ''.join(chars)


def decide(token: str, lex: dict, hand_keep=frozenset()):
    """(repaired, status).

    status: same (nothing to do) | legit (kept, real alef-madda) |
            fixed (kaf restored) | unknown (kaf restored, word not in the
            list: names, rare forms) | review (default kaf; owner checks) |
            hand (kept by an explicit decision)
    """
    base = strip_diac(token)
    positions = initial_positions(base)
    if not positions or base != token:
        return token, 'same'
    kaf = to_kaf(token, positions)
    if token in hand_keep:
        return token, 'hand'
    lo, lc = lex.get(token, 0), lex.get(kaf, 0)
    if lo > 0 and lo >= RATIO * (lc + 1):
        return token, 'legit'
    if lc > 0 and lc >= RATIO * (lo + 1):
        return kaf, 'fixed'
    if lo == 0 and lc == 0:
        return kaf, 'unknown'
    return kaf, 'review'
