// Output formats and the exit code of the linter.
import { UsageError } from './errors.mjs';
import { ERROR, RULES, RULE_IDS } from './rules.mjs';

export const SCHEMA_VERSION = 1;
export const FORMATS = ['text', 'json', 'sarif', 'github'];
const TOOL = { name: 'migrations-safe', informationUri: 'https://github.com/NahuelMosse/migrations-safe' };

export const parseFailOn = (value) => {
  const tokens = value.split(',').map((t) => t.trim()).filter(Boolean);
  if (!tokens.length) throw new UsageError('--fail-on needs warning, error or rule ids');
  const bad = tokens.filter((t) => t !== 'warning' && t !== 'error' && !RULE_IDS.has(t));
  if (bad.length) throw new UsageError(`--fail-on: unknown level or rule ${bad.join(', ')}`);
  return { level: tokens.includes('warning') ? 'warning' : 'error', rules: new Set(tokens.filter((t) => RULE_IDS.has(t))) };
};

// 1 when a finding reaches the threshold (errors by default; `warning` adds warnings) or has a rule named in --fail-on.
export const exitCodeFor = (findings, failOn = { level: 'error', rules: new Set() }) =>
  findings.some((f) => f.level === ERROR || failOn.level === 'warning' || failOn.rules.has(f.rule)) ? 1 : 0;

const escapeData = (s) => s.replace(/%/g, '%25').replace(/\r/g, '%0D').replace(/\n/g, '%0A');
const escapeProp = (s) => escapeData(s).replace(/:/g, '%3A').replace(/,/g, '%2C');

export const renderResult = (result, format) => {
  const { findings } = result;
  if (format === 'json') return JSON.stringify({ schemaVersion: SCHEMA_VERSION, tool: 'migration-lint', ...result }, null, 2);
  if (format === 'github') {
    const lines = findings.map((f) => `::${f.level === ERROR ? 'error' : 'warning'} file=${escapeProp(f.file)},line=${f.line},title=${escapeProp(f.rule)}::${escapeData(f.message)}`);
    lines.push(`::notice::${summary(result)}`);
    return lines.join('\n');
  }
  if (format === 'sarif') {
    return JSON.stringify({
      $schema: 'https://json.schemastore.org/sarif-2.1.0.json', version: '2.1.0',
      runs: [{
        tool: { driver: { ...TOOL, rules: RULES.map((r) => ({ id: r.id, shortDescription: { text: r.id }, defaultConfiguration: { level: r.level } })) } },
        results: findings.map((f) => ({
          ruleId: f.rule, level: f.level === ERROR ? 'error' : 'warning', message: { text: f.message },
          locations: [{ physicalLocation: { artifactLocation: { uri: f.file }, region: { startLine: f.line } } }],
        })),
        invocations: [{ executionSuccessful: true }],
      }],
    }, null, 2);
  }
  const rows = findings.map((f) => `${f.level.padEnd(7)} ${f.rule.padEnd(28)} ${f.file}:${f.line}  ${f.message}`);
  rows.push(...(result.notes ?? []).map((n) => `note: ${n}`), summary(result));
  return rows.join('\n');
};

const summary = (r) => `${r.files} file(s)${r.history ? `, history vs ${r.history.base}` : ''}: ${r.errors} error(s), ${r.warnings} warning(s)`;

// A failure to run, in the requested format; always paired with exit code 2.
export const renderFailure = (message, format) => {
  if (format === 'json') return JSON.stringify({ schemaVersion: SCHEMA_VERSION, tool: 'migration-lint', error: { message }, exitCode: 2 }, null, 2);
  if (format === 'github') return `::error title=migration-lint could not run::${escapeData(message)}`;
  if (format === 'sarif') {
    return JSON.stringify({
      $schema: 'https://json.schemastore.org/sarif-2.1.0.json', version: '2.1.0',
      runs: [{ tool: { driver: TOOL }, results: [], invocations: [{ executionSuccessful: false, toolExecutionNotifications: [{ level: 'error', message: { text: message } }] }] }],
    }, null, 2);
  }
  return `could not run: ${message}`;
};
