import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { formToJson } from './body.mjs';
import { UsageError } from './errors.mjs';

export const HELP = `http-attack: adversarial probes against an HTTP API running on this machine.

usage: node http-attack.mjs <base-url> [options]

Routes
  --write "<METHOD> <path> <body>"   a request that creates or changes state, with a legitimate body. The body is JSON
                                     (starts with { or [), a form (a=1&b=2) or @file to read it from a file (use a file in
                                     Windows PowerShell 5.1, which strips the quotes of inline JSON). Repeatable.
  --read "<path>"                    a request that returns data, with its query if any (?limit=10). Repeatable.
  --search "<path> <param>"          a read with a free-text search parameter. Repeatable.
  --unique "<METHOD> <path> <body>"  a create guarded by a unique key: N identical requests are sent at once. Repeatable.
  --item-path "/items/{id}"          where a created item is read back when the create answers no Location.
  --vary "<json-pointer | field>"    the body field that keeps requests apart (default: the first string with an @, else
                                     the first string), e.g. /item/email for {"item":{"email":...}}.
  --content-type <type>              the media type of every write body (default application/json, or a form).
  --json                             send form bodies (a=1&b=2) as JSON objects of the same fields. Without it, a form
                                     write whose legitimate request answers 415 is switched to JSON for the rest of the run.

Credentials
  --header "Name: value"             sent on every request (user A). Repeatable.
  --auth-env <VAR>                   sends "Authorization: Bearer $VAR" without the token on the command line.
  --auth-header-name <name>          a custom header that carries credentials (X-Auth-Token): removed in the no-credentials rows.
  --other-header "Name: value"       user B's credentials, for the ownership (IDOR) rows. Repeatable.
  --other-auth-env <VAR>             user B's bearer token from an environment variable.

Expectations
  --common-headers "A, B"            headers every response must carry, parser errors included.
  --raw-exempt "<why>"               parser errors are answered by a proxy before the app: skip the common-header check there.
  --body-limit <bytes>               the documented body limit.
  --csrf                             the app authenticates with cookies: cross-origin writes must be refused.
  --origin-check always|cookie       always: every write and read is also sent from a foreign Origin (another site, another
                                     port, no Sec-Fetch, null) with the given credentials, and must be refused. cookie
                                     (default): only the --csrf rows, with the session cookie.
  --no-ambient                       the API takes no credential a browser sends on its own (cookie, HTTP auth): the
                                     origin rows are replaced by one check, no legitimate response sets Set-Cookie or
                                     asks WWW-Authenticate. Cannot be combined with --csrf.
  --host-check                       every write and read is also sent with a foreign Host; accepted, it is an info row.
  --strict-host                      the same, and an accepted foreign Host is a finding.
  --leak-path <path>                 one more file the app must not serve (2xx with a non-HTML body is file-served). Repeatable.
  --openapi <file>                   an OpenAPI file (JSON or YAML): every status the app answered must be one the
                                     contract declares for that operation.
  --config <file>                   per-route expectations and suppressions (default ./http-attack.config.json if present).

Faults and durability
  --fault-sqlite <file>              holds BEGIN EXCLUSIVE on the app's SQLite file while the first --write is sent.
                                     Any other fault (docker pause db) is a shell command and is only read from the config
                                     file (faultCmd, faultRestore), never from the command line.
  --persist-save <file>              create one item through the first --write, save how to read it back, then stop.
  --persist-verify <file>            after a restart, read the saved item back and compare it.

Tuning
  --race-count <n>                   identical requests per race (default 8).
  --race-attempts <n>                races to try before concluding (default 1).
  --hang-ms <ms>                     how long a never-ending body is waited for (default 6000).
  --format text|json                 report format (default text).
  --help                             this text.

Exit codes: 0 no findings (after suppressions) · 1 findings · 2 the run could not complete (crash, bad argument, app
down, zero probes run, probes not run).`;

const need = (cond, msg) => { if (!cond) throw new UsageError(msg); };

const intFlag = (flag, text, min, max) => {
  const n = Number(text);
  need(text !== '' && Number.isInteger(n) && n >= min && n <= max, `${flag} wants a whole number between ${min} and ${max}, got "${text}".`);
  return n;
};

// Git Bash and MSYS2 rewrite "/path" into a Windows path before node sees it. The path is restored when its prefix is a
// known install root; a path given without the leading slash is also accepted.
const unixRoots = (env) => [env.EXEPATH, env.MSYSTEM_PREFIX && resolve(env.MSYSTEM_PREFIX, '..'), 'C:\\msys64', 'C:\\msys32']
  .filter(Boolean).map((p) => p.replace(/\\/g, '/').replace(/\/+$/, '').toLowerCase());
export const unmangle = (value, env = process.env) => {
  const text = String(value);
  if (!/^[A-Za-z]:[\\/]/.test(text)) return text;
  const slashed = text.replace(/\\/g, '/');
  for (const root of unixRoots(env)) if (slashed.toLowerCase().startsWith(`${root}/`)) return slashed.slice(root.length);
  return slashed.replace(/^[A-Za-z]:\/.*?\/(?:Git|msys64|msys32)\//i, '/');
};
// A request path is printable ASCII: a space or a non-ASCII character would crash the HTTP client, so it is rejected here.
export const toPath = (value, env) => {
  const path = '/' + unmangle(value, env).replace(/^\/+/, '');
  if (/[^\x21-\x7e]/.test(path)) throw new UsageError(`"${path}" is not a valid request path: percent-encode spaces and non-ASCII characters (a%20b).`);
  return path;
};

const HEADER_NAME = /^[a-z0-9!#$%&'*+.^_`|~-]+$/;
const headerInto = (target, line, flag) => {
  const at = String(line).indexOf(':');
  const key = String(line).slice(0, at).trim().toLowerCase();
  need(at > 0 && HEADER_NAME.test(key), `${flag} wants "Name: value", got "${line}".`);
  target[key] = String(line).slice(at + 1).trim();
};

export const readBodyFile = (name, cwd, flag) => {
  try { return readFileSync(resolve(cwd, name), 'utf8').replace(/^\uFEFF/, '').trim(); }
  catch (e) { throw new UsageError(`${flag}: cannot read the body file "${name}": ${e.code ?? e.message}`); }
};

// A body that looks like JSON (or is sent as a JSON media type) must parse: a mangled body never goes out silently.
// Where a JSON parse error is, without the text around it (a file may hold secrets).
export const errorPosition = (e) => {
  const m = String(e.message).match(/position (\d+)(?: \(line (\d+) column (\d+)\))?/);
  return m ? `at position ${m[1]}${m[2] ? ` (line ${m[2]}, column ${m[3]})` : ''}` : 'at an unknown position';
};

// `source` names a file when the body came from one: the message then shows the position, never the content.
export const checkBody = (body, contentType, flag, source) => {
  if (!body) return;
  if (!/^[{[]/.test(body) && !/json/i.test(contentType ?? '')) return;
  try { JSON.parse(body); } catch (e) {
    throw new UsageError(source
      ? `${flag}: ${source} is not valid JSON, ${errorPosition(e)}.`
      : `${flag}: the body is not valid JSON, ${errorPosition(e)}.\nreceived: ${body.slice(0, 300)}\n`
        + 'PowerShell 5.1 strips the quotes of inline JSON: put the body in a file and pass "<METHOD> <path> @body.json".');
  }
};

export const requestSpec = (text, flag, { cwd, env, contentType, json = false }) => {
  const [method, path, ...rest] = String(text ?? '').split(' ');
  need(method && path, `${flag} wants "<METHOD> <path> <body>", got "${text ?? ''}".`);
  need(/^[A-Za-z]+$/.test(method), `${flag}: "${method}" is not an HTTP method.`);
  let body = rest.join(' ');
  const fromFile = body.startsWith('@') ? body.slice(1) : null;
  if (fromFile) body = readBodyFile(fromFile, cwd, flag);
  if (json && body && !/^\s*[{[]/.test(body)) body = formToJson(body);
  checkBody(body, contentType, flag, fromFile && `the body file "${fromFile}"`);
  return { method: method.toUpperCase(), path: toPath(path, env), body, contentType };
};

export const FLAGS_WITH_VALUE = new Set(['--write', '--read', '--search', '--unique', '--item-path', '--vary', '--content-type', '--header',
  '--auth-env', '--auth-header-name', '--other-header', '--other-auth-env', '--common-headers', '--raw-exempt', '--body-limit', '--config',
  '--fault-sqlite', '--persist-save', '--persist-verify', '--race-count', '--race-attempts',
  '--hang-ms', '--format', '--origin-check', '--openapi', '--leak-path']);

export const BOOLEAN_FLAGS = new Set(['--csrf', '--json', '--no-ambient', '--strict-host', '--host-check', '--help']);
const BOOLEAN_OPTIONS = { '--csrf': 'csrf', '--json': 'json', '--no-ambient': 'noAmbient', '--strict-host': 'strictHost', '--host-check': 'hostCheck' };

const LOOPBACK = /^(localhost|127(?:\.\d{1,3}){3}|\[::1\]|[\w-]+\.localhost)$/i;

export const parseBase = (text, env = process.env) => {
  need(/^https?:\/\//i.test(text ?? ''), 'The first argument is the base URL, e.g. http://127.0.0.1:3000.');
  let base;
  try { base = new URL(text); } catch { throw new UsageError(`"${text}" is not a valid URL.`); }
  need(base.protocol === 'http:', 'Only plain http is supported: probe the app behind its TLS terminator.');
  // Loopback is not "local": a tunnel (kubectl port-forward, ssh -L, a cloud SQL proxy) passes this check.
  need(LOOPBACK.test(base.hostname) || env.HTTP_ATTACK_ALLOW_REMOTE === '1',
    `${base.hostname} is not loopback. These probes create and delete data: run them only against an app you own.`);
  return base;
};

export function parseArgs(argv, { cwd = process.cwd(), env = process.env } = {}) {
  const opt = {
    writes: [], reads: [], searches: [], uniques: [], common: [], headers: {}, otherHeaders: {}, authHeaderNames: [],
    leakPaths: [], csrf: false, json: false, hostCheck: false, noAmbient: false, strictHost: false, originCheck: 'cookie',
    format: 'text', help: false, raceCount: 8, raceAttempts: 1, hangMs: 6000,
  };
  if (argv.includes('--help') || argv.includes('-h')) return { help: true, opt: { ...opt, help: true } };
  const base = parseBase(argv[0], env);
  // Bodies are parsed after the loop, so --content-type may come after --write.
  const pendingRequests = [];
  for (let i = 1; i < argv.length; i++) {
    const flag = argv[i];
    if (flag in BOOLEAN_OPTIONS) { opt[BOOLEAN_OPTIONS[flag]] = true; continue; }
    need(FLAGS_WITH_VALUE.has(flag), `Unknown option ${flag}. See --help.`);
    need(i + 1 < argv.length, `${flag} needs a value.`);
    const value = argv[++i];
    switch (flag) {
      case '--write': pendingRequests.push(['writes', flag, value]); break;
      case '--unique': pendingRequests.push(['uniques', flag, value]); break;
      case '--read': opt.reads.push(toPath(value, env)); break;
      case '--search': {
        const [path, param] = unmangle(value, env).split(' ');
        need(path && param, '--search wants "<path> <param>".');
        opt.searches.push({ path: toPath(path, env), param });
        break;
      }
      case '--header': headerInto(opt.headers, value, flag); break;
      case '--other-header': headerInto(opt.otherHeaders, value, flag); break;
      case '--auth-env': need(env[value], `--auth-env ${value}: the variable is empty or unset.`); opt.headers.authorization = `Bearer ${env[value]}`; break;
      case '--other-auth-env': need(env[value], `--other-auth-env ${value}: the variable is empty or unset.`); opt.otherHeaders.authorization = `Bearer ${env[value]}`; break;
      case '--auth-header-name': need(HEADER_NAME.test(value.toLowerCase()), `--auth-header-name: "${value}" is not a header name.`); opt.authHeaderNames.push(value.toLowerCase()); break;
      case '--item-path': opt.itemPath = toPath(value, env); need(opt.itemPath.includes('{id}'), '--item-path must contain {id}.'); break;
      case '--vary': opt.vary = value; break;
      case '--content-type': need(/^[\w.+-]+\/[\w.+-]+/.test(value), `--content-type: "${value}" is not a media type.`); opt.contentType = value; break;
      case '--common-headers': opt.common = value.split(',').map((h) => h.trim().toLowerCase()).filter(Boolean); break;
      case '--raw-exempt': opt.rawExempt = value; break;
      case '--body-limit': opt.bodyLimit = intFlag(flag, value, 16, 2 ** 31); break;
      case '--config': opt.config = value; break;
      case '--fault-sqlite': opt.faultSqlite = value; break;
      case '--persist-save': opt.persistSave = value; break;
      case '--persist-verify': opt.persistVerify = value; break;
      case '--race-count': opt.raceCount = intFlag(flag, value, 2, 64); break;
      case '--race-attempts': opt.raceAttempts = intFlag(flag, value, 1, 20); break;
      case '--hang-ms': opt.hangMs = intFlag(flag, value, 100, 600_000); break;
      case '--format': need(value === 'text' || value === 'json', `--format wants text or json, got "${value}".`); opt.format = value; break;
      case '--origin-check': need(value === 'always' || value === 'cookie', `--origin-check wants always or cookie, got "${value}".`); opt.originCheck = value; break;
      case '--openapi': opt.openapi = resolve(cwd, value); break;
      case '--leak-path': opt.leakPaths.push(toPath(value, env)); break;
      default: throw new UsageError(`Unknown option ${flag}.`);
    }
  }
  need(!Object.keys(opt.otherHeaders).length || !Object.entries(opt.otherHeaders).every(([k, v]) => opt.headers[k] === v),
    'The credentials for user B are the same credentials as user A: the ownership rows would prove nothing.');
  need(!(opt.noAmbient && opt.csrf), '--no-ambient says no cookie reaches the API, --csrf says the API authenticates with one: choose one.');
  need(!opt.json || !opt.contentType || /json/i.test(opt.contentType), `--json sends JSON bodies, but --content-type is "${opt.contentType}".`);
  for (const [list, flag, value] of pendingRequests) {
    opt[list].push(requestSpec(value, flag, { cwd, env, contentType: opt.contentType, json: opt.json }));
  }
  return { help: false, base, opt };
}
