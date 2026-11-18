/* Evaluation harness (SPEC 6.6). Runs eval/cases.json through the real chat
 * pipeline with the provider-agnostic FAKE model and reports per-category
 * results against eval/thresholds.json.
 *
 *   npm run eval            human-readable report, exit 1 on release-blocking failure
 *   npm run eval -- --json  machine-readable report
 *
 * With the fake model this proves the pipeline's enforcement (retrieval scope,
 * safety pre-check, citation and quotation validation). It does NOT measure
 * real model quality: scriptedOnly cases are reported separately for that
 * reason, and the same set runs against real providers in Task 10c.
 */
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { ChatResult, ChatService } from '../src/chat/chat.service';
import { isVerbatim } from '../src/chat/validation';
import { FakeBehavior, FakeLlmProvider } from '../src/providers/fake-llm';
import { SpendGuard } from '../src/protection/spend-guard';
import { RetrievalService } from '../src/retrieval/retrieval.service';
import { RetrievalRequest } from '../src/retrieval/retrieval.types';
import { SYSTEM_PROMPT } from '../src/theological-policy/system-prompt';
import { CorpusService } from '../src/sources/corpus.service';

interface Expect {
  status: 'answered' | 'refused' | 'safety';
  reason?: string;
  category?: string;
  citesAny?: string[];
  minBlocks?: number;
  hasQuotation?: boolean;
  pageOnRefs?: boolean;
  pastoralNote?: boolean;
  allSaint?: string;
  attempts?: number;
  promptIsolation?: boolean;
}
interface Case {
  id: string;
  category: string;
  mode: 'saint_scope' | 'book_scope';
  scope: { saintId?: string; sectionId?: string };
  messages: { role: 'user' | 'assistant'; text: string }[];
  fake: FakeBehavior;
  expect: Expect;
  scriptedOnly?: boolean;
}
interface Thresholds {
  approvedByOwner: boolean;
  releaseBlocking: Record<string, number>;
  criticalCategories: string[];
  nonCriticalMinPassRate: Record<string, number>;
}

const root = __dirname;
const set = JSON.parse(readFileSync(join(root, 'cases.json'), 'utf8')) as {
  corpusDir: string;
  cases: Case[];
};
const th = JSON.parse(readFileSync(join(root, 'thresholds.json'), 'utf8')) as Thresholds;

const corpusSvc = new CorpusService({
  corpusDir: join(root, set.corpusDir),
  nodeEnv: 'test',
  retrieveEndpoint: false,
  port: 0,
  pricingFile: '',
  llm: { provider: 'fake', timeoutMs: 1000, maxOutputTokens: 500 },
  trustProxy: 0,
  protection: {} as never,
});
const byId = new Map(corpusSvc.corpus.passages.map((p) => [p.paragraphId, p]));
const retrieval = new RetrievalService(corpusSvc);
const pricing = { version: 'eval', currency: 'USD' as const, models: {} };

interface Outcome {
  c: Case;
  pass: boolean;
  problems: string[];
  citationsChecked: number;
  citationsBad: number;
  quotesChecked: number;
  quotesBad: number;
  scopeViolations: number;
}

async function run(c: Case): Promise<Outcome> {
  const llm = new FakeLlmProvider(c.fake);
  const chat = new ChatService(retrieval, llm, pricing, new SpendGuard({ dailyCapUsd: 1e9, unknownCostUsd: 0, killSwitch: false, maxConcurrentModelCalls: 8 }));
  const req: RetrievalRequest = { mode: c.mode, scope: c.scope, messages: c.messages };
  const problems: string[] = [];
  let res: ChatResult;
  try {
    res = await chat.answer(req);
  } catch (e) {
    return { c, pass: false, problems: [`threw: ${(e as Error).message}`], citationsChecked: 0, citationsBad: 0, quotesChecked: 0, quotesBad: 0, scopeViolations: 0 };
  }
  const r = res.response;
  const ex = c.expect;
  if (r.status !== ex.status) problems.push(`status ${r.status} != ${ex.status}`);
  if (ex.reason && (r.status !== 'refused' || r.reason !== ex.reason)) problems.push(`reason != ${ex.reason}`);
  if (ex.category && (r.status !== 'safety' || r.category !== ex.category)) problems.push(`category != ${ex.category}`);
  if (ex.attempts !== undefined && res.attempts !== ex.attempts) problems.push(`attempts ${res.attempts} != ${ex.attempts}`);
  if (r.status === 'safety' && llm.calls !== 0) problems.push('model was called for a safety case');

  let citationsChecked = 0, citationsBad = 0, quotesChecked = 0, quotesBad = 0, scopeViolations = 0;
  if (r.status === 'answered') {
    // Independent re-check: re-run retrieval, resolve every id in the corpus.
    const retrieved = retrieval.retrieve(req);
    const ids = new Set(retrieved.status === 'ok' ? retrieved.passages.map((p) => p.paragraphId) : []);
    for (const b of r.blocks) {
      for (const ref of b.references) {
        citationsChecked++;
        const p = byId.get(ref.paragraphId);
        if (!ids.has(ref.paragraphId) || !p || p.page !== ref.page || p.saintId !== ref.saintId) citationsBad++;
        if (c.mode === 'saint_scope' && ref.saintId !== c.scope.saintId) scopeViolations++;
        if (ex.allSaint && ref.saintId !== ex.allSaint) problems.push('reference outside expected saint');
      }
      if (b.type === 'quotation') {
        quotesChecked++;
        if (!b.citations.some((id) => { const p = byId.get(id); return p !== undefined && isVerbatim(b.text, p.text); })) quotesBad++;
      }
    }
    if (ex.minBlocks !== undefined && r.blocks.length < ex.minBlocks) problems.push('too few blocks');
    if (ex.citesAny && !r.blocks.some((b) => b.citations.some((id) => ex.citesAny?.includes(id)))) problems.push('expected citation missing');
    if (ex.hasQuotation && !r.blocks.some((b) => b.type === 'quotation')) problems.push('no quotation block');
    if (ex.pageOnRefs && !r.blocks.every((b) => b.references.every((x) => x.page !== null))) problems.push('reference without page');
    if (ex.pastoralNote !== undefined && Boolean(r.pastoralNote) !== ex.pastoralNote) problems.push('pastoral note mismatch');
    if (ex.promptIsolation) {
      const sent = llm.seen[0];
      const question = c.messages[c.messages.length - 1].text;
      if (sent.system !== SYSTEM_PROMPT || sent.system.includes(question.slice(0, 20))) problems.push('system prompt not isolated');
      if (!sent.prompt.includes('<question untrusted="true">')) problems.push('question not wrapped as data');
    }
  }
  if (citationsBad > 0) problems.push('invalid citation');
  if (quotesBad > 0) problems.push('non-verbatim quote');
  if (scopeViolations > 0) problems.push('scope violation');
  return { c, pass: problems.length === 0, problems, citationsChecked, citationsBad, quotesChecked, quotesBad, scopeViolations };
}

async function main(): Promise<void> {
  const outcomes: Outcome[] = [];
  for (const c of set.cases) outcomes.push(await run(c));

  const sum = (f: (o: Outcome) => number) => outcomes.reduce((n, o) => n + f(o), 0);
  const cats = [...new Set(set.cases.map((c) => c.category))].sort();
  const rows = cats.map((cat) => {
    const os = outcomes.filter((o) => o.c.category === cat);
    const passed = os.filter((o) => o.pass).length;
    const scripted = os.filter((o) => o.c.scriptedOnly).length;
    const critical = th.criticalCategories.includes(cat);
    const need = critical ? 1 : (th.nonCriticalMinPassRate[cat] ?? 1);
    return { cat, total: os.length, passed, scripted, critical, need, ok: passed / os.length >= need };
  });

  const nib = outcomes.filter((o) => o.c.category === 'not_in_book');
  const metrics = {
    citationValidity: sum((o) => o.citationsChecked) === 0 ? 1 : 1 - sum((o) => o.citationsBad) / sum((o) => o.citationsChecked),
    verbatimQuotes: sum((o) => o.quotesChecked) === 0 ? 1 : 1 - sum((o) => o.quotesBad) / sum((o) => o.quotesChecked),
    notInBookRefusal: nib.length === 0 ? 1 : nib.filter((o) => o.pass).length / nib.length,
    criticalFailures: outcomes.filter((o) => !o.pass && th.criticalCategories.includes(o.c.category)).length,
    scopeIsolationFailures: sum((o) => o.scopeViolations),
  };
  const blocking = [
    ['citationValidity', metrics.citationValidity >= th.releaseBlocking.citationValidity],
    ['verbatimQuotes', metrics.verbatimQuotes >= th.releaseBlocking.verbatimQuotes],
    ['notInBookRefusal', metrics.notInBookRefusal >= th.releaseBlocking.notInBookRefusal],
    ['criticalFailures', metrics.criticalFailures <= th.releaseBlocking.criticalFailures],
    ['scopeIsolationFailures', metrics.scopeIsolationFailures <= th.releaseBlocking.scopeIsolationFailures],
  ] as const;
  const failedBlocking = blocking.filter(([, ok]) => !ok).map(([n]) => n);
  const failedCats = rows.filter((r) => !r.ok).map((r) => r.cat);
  const failed = outcomes.filter((o) => !o.pass);
  const ok = failedBlocking.length === 0 && failedCats.length === 0 && failed.length === 0;

  if (process.argv.includes('--json')) {
    console.log(JSON.stringify({ ok, metrics, categories: rows, failed: failed.map((o) => ({ id: o.c.id, problems: o.problems })) }, null, 2));
  } else {
    console.log('Evaluation: provider=fake (scripted), corpus=FAKE fixture');
    console.log(`Thresholds approved by owner: ${th.approvedByOwner ? 'yes' : 'NO (proposed; see eval/thresholds.json)'}\n`);
    console.log('category                  pass/total  need   scripted  critical');
    for (const r of rows) {
      console.log(`${r.cat.padEnd(25)} ${`${r.passed}/${r.total}`.padEnd(11)} ${`${Math.round(r.need * 100)}%`.padEnd(6)} ${String(r.scripted).padEnd(9)} ${r.critical ? 'yes' : 'no'}  ${r.ok ? 'OK' : 'FAIL'}`);
    }
    console.log('\nrelease-blocking metrics');
    for (const [name, pass] of blocking) console.log(`  ${name.padEnd(24)} ${pass ? 'OK  ' : 'FAIL'} (${(metrics as Record<string, number>)[name]})`);
    if (failed.length > 0) {
      console.log('\nfailed cases');
      for (const o of failed) console.log(`  ${o.c.id}: ${o.problems.join('; ')}`);
    }
    console.log(`\nRESULT: ${ok ? 'PASS' : 'FAIL'}${th.approvedByOwner ? '' : ' (thresholds not yet owner-approved)'}`);
  }
  process.exit(ok ? 0 : 1);
}

void main();
