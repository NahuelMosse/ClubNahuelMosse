// Server versions and editions the rules depend on, and where a project declares them.
// A version is { dialect, major, minor, patch, label }; SQL Server uses the release year as `major`
// (2016, 2019, 2022, 2025). A missing minor or patch means the newest of the series.
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { UsageError } from './errors.mjs';
import { DEFAULT_MYSQL_VERSION, parseMysqlVersion } from './mysql.mjs';

export const DEFAULT_SERVER_VERSION = { mysql: DEFAULT_MYSQL_VERSION, mssql: '2022', oracle: '19', db2: '11.5' };
export const EDITIONS = { mssql: ['standard', 'enterprise', 'azure'], oracle: ['se2', 'ee'] };
// A compose file that runs Developer does not prove production is Enterprise: the conservative edition is the default.
export const DEFAULT_EDITION = { mssql: 'standard', oracle: 'se2' };
const EXAMPLES = { mysql: '8.0, 8.0.28, 8.4, 5.7, mariadb-10.6', mssql: '2016, 2019, 2022, 2025', oracle: '11.2, 12.1, 19, 23', db2: '10.5, 11.1, 11.5' };
const DISPLAY = { mysql: 'MySQL', mssql: 'SQL Server', oracle: 'Oracle', db2: 'Db2' };
const MSSQL_BY_MAJOR = { 11: 2012, 12: 2014, 13: 2016, 14: 2017, 15: 2019, 16: 2022, 17: 2025 };

const make = (dialect, major, minor, patch, name) => {
  const numbers = [major, minor, patch].filter((n) => n !== null).join('.');
  return { dialect, major, minor, patch, label: `${name} ${numbers}${minor === null && dialect !== 'mssql' ? ' (newest minor)' : ''}` };
};

export const parseServerVersion = (dialect, text) => {
  if (dialect === 'mysql') { const v = parseMysqlVersion(text); return v && { ...v, dialect }; }
  const t = String(text ?? '').trim().toLowerCase();
  if (dialect === 'mssql') {
    const m = t.match(/^(?:sql\s*server[-: ]?)?(?:(\d{4})|(\d{2})(?:\.\d+)*)(?![\d])/);
    const year = m && (m[1] ? Number(m[1]) : MSSQL_BY_MAJOR[Number(m[2])]);
    return year && year >= 2008 && year <= 2030 ? make('mssql', year, null, null, 'SQL Server') : null;
  }
  if (dialect === 'oracle') {
    const m = t.match(/^(?:oracle[-: ]?)?(\d{1,2})(?:\.(\d+))?(?:\.\d+)*(?:ai|c|g)?(?![\d])/);
    return m ? make('oracle', Number(m[1]), m[2] === undefined ? null : Number(m[2]), null, 'Oracle Database') : null;
  }
  if (dialect === 'db2') {
    const m = t.match(/^(?:db2[-: ]?)?v?(\d+)\.(\d+)(?:\.\d+)*(?![\d])/);
    return m ? make('db2', Number(m[1]), Number(m[2]), null, 'Db2 LUW') : null;
  }
  return null;
};

export const serverVersionOrThrow = (dialect, text) => {
  const v = parseServerVersion(dialect, text);
  if (!v) throw new UsageError(`unknown ${DISPLAY[dialect] ?? dialect} version "${String(text).slice(0, 30)}" (examples: ${EXAMPLES[dialect] ?? 'none'})`);
  return v;
};

export const editionOrThrow = (dialect, text) => {
  const known = EDITIONS[dialect];
  if (!known) throw new UsageError(`--edition has no meaning for ${dialect}: it applies to mssql (${EDITIONS.mssql.join('|')}) and oracle (${EDITIONS.oracle.join('|')})`);
  const e = String(text).trim().toLowerCase();
  if (!known.includes(e)) throw new UsageError(`unknown ${dialect} edition "${String(text).slice(0, 20)}" (${known.join(', ')})`);
  return e;
};

// True when the server is `major.minor.patch` or newer (an unknown minor or patch counts as the newest).
export const versionAtLeast = (v, major, minor = 0, patch = 0) => {
  if (v.major !== major) return v.major > major;
  if ((v.minor ?? Infinity) !== minor) return (v.minor ?? Infinity) > minor;
  return (v.patch ?? Infinity) >= patch;
};

// ── Where a project declares its server version ────────────────────────────────────────────────────────

const read = (p) => { try { return readFileSync(p, 'utf8'); } catch { return ''; } };
const readdirSafe = (dir) => { try { return readdirSync(dir); } catch { return null; } };
const COMPOSE = ['docker-compose.yml', 'docker-compose.yaml', 'compose.yml', 'compose.yaml', 'docker-compose.override.yml'];

// image reference -> version text, per dialect
const IMAGE = {
  mysql: /^\s*(?:-\s*)?image:\s*["']?(?:docker\.io\/(?:library\/)?)?(mysql|mariadb)(?::|\/)?([\d][\w.-]*)/gim,
  mssql: /^\s*(?:-\s*)?image:\s*["']?mcr\.microsoft\.com\/mssql\/server:(\d[\w.-]*)/gim,
  oracle: /^\s*(?:-\s*)?image:\s*["']?(?:docker\.io\/)?(?:gvenzl\/oracle-(?:free|xe)|container-registry\.oracle\.com\/database\/(?:free|enterprise|express)):(\d[\w.-]*)/gim,
  db2: /^\s*(?:-\s*)?image:\s*["']?(?:icr\.io\/db2_community\/db2|ibmcom\/db2):(\d[\w.-]*)/gim,
};
const TOOL = { mysql: /^(mysql|mariadb)\s+(\d[\w.]*)/im };

const fromText = (dialect, text) => {
  if (dialect === 'mysql') return [...text.matchAll(IMAGE.mysql)].map((m) => `${m[1]}-${m[2]}`);
  return [...text.matchAll(IMAGE[dialect])].map((m) => m[1]);
};

const order = (v) => [v.major, v.minor ?? Infinity, v.patch ?? Infinity];
const older = (a, b) => { const [x, y] = [order(a), order(b)]; for (let i = 0; i < 3; i++) if (x[i] !== y[i]) return x[i] < y[i]; return false; };

// The server version declared next to the migrations: a compose file or CI workflow image, or .tool-versions
// (MySQL). Returns { version, evidence, conflict } where `conflict` lists the labels when the declarations
// disagree (the oldest is then used, because the rules must hold on every declared server).
export const projectServerVersion = (path, dialect, limit = 8) => {
  if (!IMAGE[dialect]) return null;
  let dir = resolve(path);
  if (existsSync(dir) && !readdirSafe(dir)) dir = dirname(dir);
  for (let n = 0; n < limit; n++) {
    const hits = [];
    for (const f of COMPOSE) for (const v of fromText(dialect, read(join(dir, f)))) hits.push({ v, from: f });
    const tools = TOOL[dialect] && read(join(dir, '.tool-versions')).match(TOOL[dialect]);
    if (tools) hits.push({ v: `${tools[1]}-${tools[2]}`, from: '.tool-versions' });
    const wf = join(dir, '.github', 'workflows');
    for (const f of readdirSafe(wf) ?? []) if (/\.ya?ml$/i.test(f)) for (const v of fromText(dialect, read(join(wf, f)))) hits.push({ v, from: `.github/workflows/${f}` });
    const parsed = hits.map((h) => ({ ...h, parsed: parseServerVersion(dialect, h.v) })).filter((h) => h.parsed);
    if (parsed.length) {
      const labels = [...new Set(parsed.map((h) => h.parsed.label))];
      const pick = parsed.reduce((best, h) => (h.parsed.flavor === best.parsed.flavor && older(h.parsed, best.parsed) ? h : best), parsed[0]);
      return { version: pick.parsed, evidence: `${pick.from} in ${dir}`, conflict: labels.length > 1 ? labels : null };
    }
    if (existsSync(join(dir, '.git')) || dirname(dir) === dir) break;
    dir = dirname(dir);
  }
  return null;
};
