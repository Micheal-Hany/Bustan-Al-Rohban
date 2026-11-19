/* Prints stored answer reports for the owner's review.
 *   REPORTS_FILE=./data/reports.jsonl npm run reports:list
 *   npm run reports:list -- --json
 */
import { FileReportStore } from '../src/reports/report.store';

async function main(): Promise<void> {
  const file = process.env.REPORTS_FILE;
  if (!file) {
    console.error('Set REPORTS_FILE to the reports file.');
    process.exit(2);
  }
  const reports = await new FileReportStore(file).list();
  if (process.argv.includes('--json')) {
    console.log(JSON.stringify(reports, null, 2));
    return;
  }
  console.log(`${reports.length} report(s)\n`);
  for (const r of reports) {
    console.log(`#${r.id}  ${r.receivedAt}  [${r.reason}]  content v${r.contentVersion}  ${r.provider}/${r.model}`);
    console.log(`  Question: ${r.question}`);
    console.log(`  Answer:   ${r.answerText}`);
    console.log(`  Cited:    ${r.citedParagraphIds.join(', ') || '-'}`);
    if (r.note) console.log(`  Note:     ${r.note}`);
    console.log('');
  }
}

void main();
