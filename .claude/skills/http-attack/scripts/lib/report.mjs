import { EXIT, SEVERITIES } from './registry.mjs';

export const SCHEMA_VERSION = 1;

export function summarize(rows) {
  const count = (fn) => rows.filter(fn).length;
  const bySeverity = Object.fromEntries(SEVERITIES.map((s) => [s, count((r) => r.verdict === 'fail' && r.severity === s)]));
  const passed = count((r) => r.verdict === 'pass');
  const failed = count((r) => r.verdict === 'fail');
  const suppressed = count((r) => r.verdict === 'suppressed');
  return {
    run: passed + failed + count((r) => r.verdict === 'suppressed' && r.was === 'fail'),
    passed, failed, suppressed,
    notRun: count((r) => r.verdict === 'not-run'),
    skipped: count((r) => r.verdict === 'skipped'),
    info: count((r) => r.verdict === 'info'),
    bySeverity,
  };
}

// 0 clean, 1 findings, 2 nothing could be concluded: no probe ran, or some probe could not run.
export function exitCode(summary) {
  if (summary.failed > 0) return EXIT.FINDINGS;
  if (summary.run === 0 || summary.notRun > 0) return EXIT.ERROR;
  return EXIT.OK;
}

const ORDER = Object.fromEntries(SEVERITIES.map((s, i) => [s, i]));

export function renderJson({ base, rows, summary, unusedIgnores, unusedRoutes = [] }) {
  const findings = rows.filter((r) => r.verdict === 'fail').sort((a, b) => ORDER[a.severity] - ORDER[b.severity]);
  return JSON.stringify({
    schemaVersion: SCHEMA_VERSION,
    base,
    summary: { ...summary, exitCode: exitCode(summary) },
    findings: findings.map((r) => r.id),
    unusedIgnores: unusedIgnores.map((i) => i.id),
    unusedRoutes,
    rows: rows.map(({ id, rule, group, probe, target, name, verdict, severity, got, expected, evidence, was, suppressedBy }) =>
      ({ id, rule: rule ?? null, group, probe, target, name, verdict, severity: severity ?? null, got: got ?? '', expected: expected ?? '', evidence: evidence ?? null, was: was ?? null, suppressedBy: suppressedBy ?? null })),
  }, null, 2);
}

const MARK = { fail: (r) => `FAIL ${r.severity.padEnd(8)}`, 'not-run': () => 'NOT RUN      ', pass: () => 'pass         ', skipped: () => 'skipped      ', info: () => 'info         ', suppressed: () => 'suppressed   ' };

export function renderText({ rows, summary, unusedIgnores, unusedRoutes = [] }) {
  const out = [];
  const pad = ' '.repeat(20);
  for (const r of rows) {
    out.push(`${(MARK[r.verdict] ?? ((x) => String(x.verdict).padEnd(13)))(r)} ${(r.got || '-').padEnd(5)} [${r.group}] ${r.name}`);
    if (r.verdict === 'pass') continue;
    if (r.verdict === 'suppressed') { out.push(`${pad}${r.was === 'fail' ? 'finding' : 'not run'} suppressed: ${r.suppressedBy}`, `${pad}id: ${r.id}`); continue; }
    if (r.verdict === 'skipped') { out.push(`${pad}${r.evidence}`); continue; }
    out.push(`${pad}expected: ${r.expected || '-'}`);
    if (r.evidence) out.push(`${pad}evidence: ${r.evidence}`);
    out.push(`${pad}id: ${r.id}`);
  }
  for (const i of unusedIgnores) out.push(`warning: the ignore "${i.id}" matched nothing`);
  for (const k of unusedRoutes) out.push(`warning: the route settings "${k}" matched no request`);
  const s = summary;
  out.push('', `${s.run} probes run - ${s.failed} findings (critical ${s.bySeverity.critical}, high ${s.bySeverity.high}, medium ${s.bySeverity.medium}, low ${s.bySeverity.low})`
    + ` - ${s.suppressed} suppressed - ${s.notRun} not run${s.skipped ? ` - ${s.skipped} skipped by configuration` : ''}${s.info ? ` - ${s.info} info` : ''}`);
  return out.join('\n');
}
