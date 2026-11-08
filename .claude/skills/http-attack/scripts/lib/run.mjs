import { routeSettings } from './config.mjs';
import { severityOf } from './registry.mjs';
import { is5xx } from './http.mjs';

// Stack traces and driver errors from Node, Python, Go, Java, Rails and SQL drivers.
const LEAK = new RegExp([
  String.raw`\bat \S+ \(`, String.raw`\bat [\w$.<>]+\([\w$]+\.(?:java|kt|scala):\d+\)`, 'node:internal', String.raw`Traceback \(most recent`,
  String.raw`File "[^"]+", line \d+`, 'panic: ', String.raw`goroutine \d+ \[`, String.raw`ActiveRecord::`, String.raw`ActionController::`,
  'SQLSTATE', 'SQLITE_', String.raw`sqlite3\.`, String.raw`\bPG::`, 'psycopg', String.raw`org\.postgresql`, String.raw`com\.mysql`,
  String.raw`java\.lang\.\w+Exception`, String.raw`\.rb:\d+:in `,
].join('|'), 'i');
export const leaksInternals = (text) => LEAK.test(text);

const snippet = (text) => text.replace(/\s+/g, ' ').slice(0, 120);

// Collects the rows of one run. `spec` is { group, probe, target, name }: probe and target form the stable id.
export class Run {
  constructor({ client, opts, config }) {
    Object.assign(this, { client, opts, config, rows: [] });
  }

  settings(method, path) { return routeSettings(this.config, this.opts, method, path); }

  add(row) { this.rows.push({ ...row }); }

  pass(spec, got, expected, evidence) {
    this.add({ ...spec, id: `ok:${spec.probe}:${spec.target}`, verdict: 'pass', got: String(got ?? ''), expected, evidence });
  }

  fail(rule, spec, got, expected, evidence) {
    this.add({ ...spec, id: `${rule}:${spec.probe}:${spec.target}`, rule, verdict: 'fail', severity: severityOf(rule), got: String(got ?? ''), expected, evidence });
  }

  notRun(spec, why) {
    this.add({ ...spec, id: `not-run:${spec.probe}:${spec.target}`, rule: 'not-run', verdict: 'not-run', got: '', expected: '', evidence: why });
  }

  // Seen and reported, but neither a finding nor a pass: what an option (such as --strict-host) would turn into a finding.
  info(spec, got, expected, evidence) {
    this.add({ ...spec, id: `info:${spec.probe}:${spec.target}`, verdict: 'info', got: String(got ?? ''), expected, evidence });
  }

  // Not applicable because the configuration says so (not a gap, not a pass).
  skipped(spec, why) {
    this.add({ ...spec, id: `skipped:${spec.probe}:${spec.target}`, verdict: 'skipped', got: '', expected: '', evidence: why });
  }

  // A response that is a failure whatever the probe was: no answer, a dead app, a 5xx (with its leak check).
  // Returns true when it recorded the outcome.
  async transportFault(res, spec, expected) {
    if (res.s === null || res.truncated) {
      if (await this.client.alive()) this.fail('connection-dropped', spec, res.err, expected, 'the connection was closed without a complete response');
      else this.fail('process-died', spec, res.err, expected, 'the app stopped answering');
      return true;
    }
    if (is5xx(res.s)) {
      this.fail('server-error', spec, res.s, expected, spec.hint);
      if (leaksInternals(res.text ?? '')) this.fail('stack-leak', spec, res.s, 'a fixed error body without internals', `the body shows: ${snippet(res.text)}`);
      return true;
    }
    return false;
  }
}
