import { readFileSync } from 'node:fs';
import { basename } from 'node:path';

const HTTP_METHODS = ['get', 'put', 'post', 'delete', 'patch', 'head', 'options'];
const escape = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// The declared statuses per operation of an OpenAPI document: { 'GET /items/{id}': Set('200', '404') }. JSON is parsed;
// YAML is read by a minimal indentation parser (`paths:` > path > method > `responses:` > status keys).
export function contractOf(text) {
  const ops = {};
  let doc = null;
  try { doc = JSON.parse(text); } catch { /* YAML */ }
  if (doc) {
    for (const [p, item] of Object.entries(doc.paths ?? {})) {
      for (const m of HTTP_METHODS) if (item?.[m]) ops[`${m.toUpperCase()} ${p}`] = new Set(Object.keys(item[m].responses ?? {}).map(String));
    }
    return ops;
  }
  const unquote = (k) => k.trim().replace(/^(['"])(.*)\1$/, '$2');
  let inPaths = false, path = null, method = null, resp = null, pathIndent = -1, respIndent = -1, child = null;
  for (const raw of text.split(/\r?\n/)) {
    if (!raw.trim() || raw.trim().startsWith('#')) continue;
    const indent = raw.length - raw.trimStart().length;
    const m = raw.trim().match(/^(['"][^'"]+['"]|[^\s:'"][^:]*?)\s*:(?:\s|$)/);
    if (indent === 0) { inPaths = /^paths\s*:/.test(raw); path = method = resp = null; continue; }
    if (!inPaths || !m) continue;
    const key = unquote(m[1]);
    if (pathIndent < 0 && key.startsWith('/')) pathIndent = indent;
    if (indent === pathIndent) { path = key.startsWith('/') ? key : null; method = resp = null; continue; }
    if (!path) continue;
    if (resp && indent > respIndent) { child ??= indent; if (indent === child) ops[resp].add(key); continue; }
    resp = null;
    child = null;
    if (HTTP_METHODS.includes(key.toLowerCase()) && indent > pathIndent && (method === null || indent <= method.indent)) { method = { name: key.toUpperCase(), indent }; continue; }
    if (method && key === 'responses' && indent > method.indent) { resp = `${method.name} ${path}`; ops[resp] ??= new Set(); respIndent = indent; }
  }
  return ops;
}

const documents = (declared, code) => [...declared].some((d) => d === code || d.toUpperCase() === `${code[0]}XX` || d.toLowerCase() === 'default');

// Every status the app answered during the run, against the statuses the contract declares for its operation (the most
// specific template that matches). One finding per operation and undeclared status; a path the contract lacks is not judged.
export function openapiProbe(run, file) {
  const spec = (probe, target, name) => ({ group: 'contract', probe, target, name });
  let ops;
  try { ops = contractOf(readFileSync(file, 'utf8').replace(/^\uFEFF/, '')); } catch (e) {
    run.notRun(spec('openapi', 'contract', `--openapi ${basename(file)}`), `the contract cannot be read: ${e.code ?? e.message}`);
    return;
  }
  const templates = Object.keys(ops).map((key) => {
    const at = key.indexOf(' ');
    const tpl = key.slice(at + 1);
    return { key, method: key.slice(0, at), tpl, re: new RegExp(`^${tpl.split(/\{[^}]*\}/).map(escape).join('[^/]+')}/?$`) };
  });
  if (!templates.length) { run.notRun(spec('openapi', 'contract', `--openapi ${basename(file)}`), 'no operation found under `paths`'); return; }
  const reported = new Set();
  let judged = 0;
  for (const { method, path, s } of run.client.seen) {
    const hit = templates.filter((t) => t.method === method && t.re.test(path)).sort((a, b) => a.tpl.split('{').length - b.tpl.split('{').length)[0];
    if (!hit) continue;
    judged++;
    const code = String(s);
    if (documents(ops[hit.key], code) || reported.has(`${hit.key} ${code}`)) continue;
    reported.add(`${hit.key} ${code}`);
    run.fail('undocumented-status', spec(`openapi-${code}`, hit.key, `${hit.key} answered ${code}`), code, `one of ${[...ops[hit.key]].join(', ') || '(none declared)'}`,
      `seen on ${method} ${path}`);
  }
  if (!judged) run.notRun(spec('openapi', 'contract', `--openapi ${basename(file)}`), 'no response of the run matched an operation of the contract');
  else if (!reported.size) run.pass(spec('openapi', 'responses', `every status answered is declared in ${basename(file)}`), judged, 'declared statuses');
}
