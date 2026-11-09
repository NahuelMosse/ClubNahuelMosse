import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { UsageError } from './errors.mjs';
import { formToJson } from './body.mjs';
import { RULES } from './registry.mjs';
import { checkBody, errorPosition, readBodyFile, toPath } from './args.mjs';

export const DEFAULT_CONFIG_FILE = 'http-attack.config.json';

// Settings that describe the app and may be given for every route at once.
const GENERAL_KEYS = ['bodyLimit', 'maxHeaderBytes', 'invalidUtf8', 'vary', 'contentType'];
// Settings that relax a check: only for one route, and only with the reason written down (they act as suppressions).
const RELAXING_KEYS = ['public', 'idempotentCreate'];
const ROUTE_KEYS = [...GENERAL_KEYS, ...RELAXING_KEYS, 'reason'];
const TOP_KEYS = [...GENERAL_KEYS, 'routes', 'ignore', 'commonHeaders', 'rawExempt', 'authHeaderNames', 'itemPath', 'persistIgnore',
  'persistDir', 'faultCmd', 'faultRestore', 'writes', 'reads', 'searches', 'uniques'];

const fail = (file, msg) => { throw new UsageError(`${file}: ${msg}`); };

const checkRoute = (file, where, s, { top }) => {
  if (s === null || typeof s !== 'object' || Array.isArray(s)) fail(file, `${where} must be an object.`);
  const known = top ? GENERAL_KEYS : ROUTE_KEYS;
  for (const k of Object.keys(s)) {
    if (top && (RELAXING_KEYS.includes(k) || k === 'reason')) fail(file, `${where}: "${k}" is only allowed inside "routes", for one route, with a "reason".`);
    if (!known.includes(k)) fail(file, `${where}: unknown setting "${k}" (known: ${known.join(', ')}).`);
  }
  for (const k of RELAXING_KEYS) if (k in s && typeof s[k] !== 'boolean') fail(file, `${where}.${k} must be true or false.`);
  if (!top && RELAXING_KEYS.some((k) => s[k] === true) && !(typeof s.reason === 'string' && s.reason.trim())) {
    fail(file, `${where} sets ${RELAXING_KEYS.filter((k) => s[k]).join('/')} and needs a non-empty "reason".`);
  }
  for (const k of ['bodyLimit', 'maxHeaderBytes']) if (k in s && !(Number.isInteger(s[k]) && s[k] > 0)) fail(file, `${where}.${k} must be a positive integer.`);
  if ('invalidUtf8' in s && !['reject', 'replace'].includes(s.invalidUtf8)) fail(file, `${where}.invalidUtf8 must be "reject" or "replace".`);
  for (const k of ['vary', 'contentType', 'reason']) if (k in s && typeof s[k] !== 'string') fail(file, `${where}.${k} must be a string.`);
};

const requestOf = (file, where, r, cwd, env, json) => {
  if (!r || typeof r !== 'object' || typeof r.path !== 'string') fail(file, `${where} needs a "path".`);
  let body = r.body ?? '';
  const fromFile = typeof body === 'string' && body.startsWith('@') ? body.slice(1) : null;
  if (typeof body === 'object') body = JSON.stringify(body);
  else if (fromFile) body = readBodyFile(fromFile, cwd, `${file} ${where}`);
  else if (typeof body !== 'string') fail(file, `${where}.body must be an object, a string or "@file".`);
  if (json && body && !/^\s*[{[]/.test(body)) body = formToJson(body);
  checkBody(body, r.contentType, `${file} ${where}`, fromFile && `the body file "${fromFile}"`);
  return { method: String(r.method ?? 'POST').toUpperCase(), path: toPath(r.path, env), body, contentType: r.contentType };
};

// An ignore id is a finding id or a prefix ending in *, always starting with a known rule: a bare "*" silences everything.
const checkIgnore = (file, entry, i) => {
  if (typeof entry?.id !== 'string' || !entry.id.trim()) fail(file, `ignore[${i}] needs an "id" (a finding id, a rule name, or "<rule>:<prefix>*").`);
  if (typeof entry.reason !== 'string' || !entry.reason.trim()) fail(file, `ignore[${i}] ("${entry.id}") needs a non-empty "reason": a suppression without a reason is not accepted.`);
  const rule = entry.id.split(':')[0];
  if (!(rule in RULES)) fail(file, `ignore[${i}]: "${entry.id}" does not start with a known rule (known: ${Object.keys(RULES).join(', ')}).`);
  if (rule === 'not-run' && !/^not-run:[^*:]/.test(entry.id)) fail(file, `ignore[${i}]: "${entry.id}" would hide every probe that could not run: name the probe, as "not-run:<probe>" or "not-run:<probe>:<target>".`);
};

export function loadConfig(file, { cwd = process.cwd(), env = process.env, json: toJson = false } = {}) {
  const explicit = file !== undefined;
  const path = resolve(cwd, file ?? DEFAULT_CONFIG_FILE);
  const empty = { settings: {}, routes: {}, usedRoutes: new Set(), ignore: [], persistIgnore: [], writes: [], reads: [], searches: [], uniques: [], path: null };
  if (!explicit && !existsSync(path)) return empty;
  let raw;
  try { raw = readFileSync(path, 'utf8').replace(/^\uFEFF/, ''); } catch (e) { fail(path, `cannot read the config file: ${e.code ?? e.message}`); }
  let json;
  try { json = JSON.parse(raw); } catch (e) { fail(path, `not valid JSON, ${errorPosition(e)}.`); }
  if (json === null || typeof json !== 'object' || Array.isArray(json)) fail(path, 'the top level must be an object.');
  for (const k of Object.keys(json)) {
    if (TOP_KEYS.includes(k)) continue;
    if (ROUTE_KEYS.includes(k)) fail(path, `"${k}" is only allowed inside "routes", for one route, with a "reason".`);
    fail(path, `unknown key "${k}" (known: ${TOP_KEYS.join(', ')}).`);
  }
  checkRoute(path, 'top level', Object.fromEntries(Object.entries(json).filter(([k]) => GENERAL_KEYS.includes(k))), { top: true });
  const routes = {};
  for (const [k, v] of Object.entries(json.routes ?? {})) {
    checkRoute(path, `routes["${k}"]`, v, { top: false });
    const m = k.match(/^([A-Za-z]+) (.+)$/);
    routes[m ? `${m[1].toUpperCase()} ${toPath(m[2], env)}` : toPath(k, env)] = v;
  }
  const ignore = json.ignore ?? [];
  if (!Array.isArray(ignore)) fail(path, '"ignore" must be a list.');
  ignore.forEach((entry, i) => checkIgnore(path, entry, i));
  for (const k of ['faultCmd', 'faultRestore', 'persistDir']) if (k in json && typeof json[k] !== 'string') fail(path, `"${k}" must be a string.`);
  if (json.faultRestore && !json.faultCmd) fail(path, '"faultRestore" needs "faultCmd".');
  const list = (k) => { const v = json[k] ?? []; if (!Array.isArray(v)) fail(path, `"${k}" must be a list.`); return v; };
  const requests = (k) => list(k).map((r, i) => requestOf(path, `${k}[${i}]`, r, cwd, env, toJson));
  return {
    path,
    settings: Object.fromEntries(Object.entries(json).filter(([k]) => GENERAL_KEYS.includes(k))),
    routes,
    usedRoutes: new Set(),
    ignore,
    persistIgnore: list('persistIgnore'),
    persistDir: json.persistDir ? resolve(cwd, json.persistDir) : undefined,
    faultCmd: json.faultCmd, faultRestore: json.faultRestore,
    commonHeaders: json.commonHeaders, rawExempt: json.rawExempt, authHeaderNames: json.authHeaderNames, itemPath: json.itemPath,
    writes: requests('writes'), uniques: requests('uniques'),
    reads: list('reads').map((r) => toPath(r, env)),
    searches: list('searches').map((s, i) => {
      if (typeof s?.path !== 'string' || typeof s.param !== 'string') fail(path, `searches[${i}] needs "path" and "param".`);
      return { path: toPath(s.path, env), param: s.param };
    }),
  };
}

// A route key matches a path literally, or as a template: "/items/{id}" matches "/items/42".
const keyMatches = (keyPath, path) => keyPath === path
  || (keyPath.includes('{') && new RegExp(`^${keyPath.split(/\{[^}]*\}/).map((s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('[^/]+')}$`).test(path));

// Settings for one route: top-level defaults, then the matching path keys, then "METHOD path"; the command line wins over the defaults.
export const routeSettings = (config, flags, method, path) => {
  const bare = path.split('?')[0];
  const merged = {
    ...config.settings,
    ...(flags.bodyLimit ? { bodyLimit: flags.bodyLimit } : {}),
    ...(flags.vary ? { vary: flags.vary } : {}),
  };
  const take = (key) => { config.usedRoutes?.add(key); Object.assign(merged, config.routes[key]); };
  const keys = Object.keys(config.routes);
  for (const key of keys) if (!/^[A-Z]+ /.test(key) && keyMatches(key, bare)) take(key);
  for (const key of keys) {
    const m = key.match(/^([A-Z]+) (.+)$/);
    if (m && m[1] === method.toUpperCase() && keyMatches(m[2], bare)) take(key);
  }
  return merged;
};

export const unusedRoutes = (config) => Object.keys(config.routes).filter((k) => !config.usedRoutes.has(k));

// A pattern is an id, a rule, "<rule>:<probe>" (every target of that probe) or an id prefix ending in *.
const matches = (pattern, row) => pattern === row.id || pattern === row.rule || row.id.startsWith(`${pattern}:`)
  || (pattern.endsWith('*') && row.id.startsWith(pattern.slice(0, -1)));

// A suppression keeps the row, marked with its reason; it no longer counts as a finding or a gap.
export function applyIgnores(rows, ignore) {
  const used = new Set();
  for (const row of rows) {
    if (row.verdict !== 'fail' && row.verdict !== 'not-run') continue;
    const hit = ignore.find((entry) => matches(entry.id, row));
    if (!hit) continue;
    used.add(hit);
    Object.assign(row, { was: row.verdict, verdict: 'suppressed', suppressedBy: hit.reason });
  }
  return ignore.filter((entry) => !used.has(entry));
}
