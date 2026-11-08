#!/usr/bin/env node
// attack.mjs [<base-url>] [skill flags...] — the kit's door to the vendored http-attack engine
// (`.claude/skills/http-attack/scripts/lib/cli.mjs`). The attacks, flags, report rows, rule ids and exit codes (0 no findings,
// 1 findings, 2 could not run) are the skill's: read `.claude/skills/http-attack/SKILL.md`. `node .claude/tools/help.mjs attack`
// prints this comment.
//
// What the kit adds on top of the skill:
//   <base-url>         without it, `APP_URL` of the environment (verify.mjs sets it when the `## Gate` has an `app:` line).
//   --fault-db <file>  the skill's --fault-sqlite; `$DATA_DIR`, `${DATA_DIR}` and `%DATA_DIR%` take DATA_DIR of the environment.
//   --raw-headers-exempt "<why>"  the skill's --raw-exempt.
//   ATTACK_HANG_MS     the skill's --hang-ms, unless the flag is given.
//   --origin-check always by default: every write and read is also sent cross-origin with the given credentials.
//   --strict-host      added at the production grade (or when the manifest cannot be read); below it --host-check, so
//                      the Host rows come back as info.
//   credentials        without --header carrying credentials, --auth-env or --auth-header-name, `not-run:no-credentials`
//                      is suppressed; without --other-header/--other-auth-env, `not-run:idor`. They go as `ignore` entries
//                      appended to the project's config in a temp copy.
//   config             --config, else specs/<current card>/http-attack.config.json (the card's suppressions, each with the
//                      ASM that justifies it, live with the card), else ./http-attack.config.json.
//   --leak-path        the kit's own files: /.claude/settings.json, /specs/.current, /specs/<current card>/card.md and
//                      /design/line.md; a 2xx with a non-HTML body is `file-served`.
// The last line is `attack: exit <N> in <X> min`.
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { endsWithLine } from './final-line.mjs';
import { gradeOf, readManifest } from './kit.mjs';
import { main } from '../skills/http-attack/scripts/lib/cli.mjs';

endsWithLine('attack');
const USAGE = 'usage: node attack.mjs [<base-url>] [--header "Name: value"]... [--write "POST /path a=1"]... [--read "/path"]... [--fault-db <sqlite>] [--raw-headers-exempt "<why>"] — every flag: .claude/skills/http-attack/SKILL.md';
const ALIASES = { '--fault-db': '--fault-sqlite', '--raw-headers-exempt': '--raw-exempt' };
const withDataDir = (path) => path.replace(/\$\{DATA_DIR\}|\$DATA_DIR(?![\w])|%DATA_DIR%/g, process.env.DATA_DIR ?? '$&');

const args = process.argv.slice(2);
if (args.includes('--help') || args.includes('-h')) process.exit(await main(['--help']));
const given = /^https?:\/\//.test(args[0] ?? '');
const base = given ? args[0] : process.env.APP_URL;
if (!base || !/^https?:\/\//.test(base)) {
  console.error(USAGE);
  process.exit(2);
}

const forwarded = [];
for (let i = given ? 1 : 0; i < args.length; i++) {
  const flag = ALIASES[args[i]] ?? args[i];
  forwarded.push(flag);
  if (flag === '--fault-sqlite' && i + 1 < args.length) forwarded.push(withDataDir(args[++i]));
}
const has = (flag) => forwarded.includes(flag);

if (!has('--origin-check') && !has('--no-ambient')) forwarded.push('--origin-check', 'always');
if (!has('--hang-ms') && process.env.ATTACK_HANG_MS) forwarded.push('--hang-ms', process.env.ATTACK_HANG_MS);
// A foreign Host refused is asked for only at production: a 421 added to satisfy a row broke legitimate clients.
let production;
try { production = gradeOf(readManifest(process.cwd())) === 'production'; } catch { production = true; }
if (production && !has('--strict-host')) forwarded.push('--strict-host');

if (!production && !has('--host-check') && !has('--strict-host')) forwarded.push('--host-check');

// A run without credentials or without user B has rows that cannot reach a verdict; the card said so by not giving them.
const valueOf = (flag) => forwarded.flatMap((f, i) => (f === flag ? [forwarded[i + 1] ?? ''] : []));
const CREDENTIAL_HEADER = /^\s*(authorization|cookie|proxy-authorization|[\w-]*(auth|token|key|session)[\w-]*)\s*:/i;
const hasCredentials = has('--auth-env') || has('--auth-header-name') || valueOf('--header').some((h) => CREDENTIAL_HEADER.test(h));
const hasUserB = has('--other-header') || has('--other-auth-env');
const ignores = [
  ...(hasCredentials ? [] : [{ id: 'not-run:no-credentials', reason: "the card's API has no login: attack.mjs got no credentials" }]),
  ...(hasUserB ? [] : [{ id: 'not-run:idor', reason: 'the card gives no second user' }]),
];
const currentCard = (() => { try { return readFileSync('specs/.current', 'utf8').trim(); } catch { return ''; } })();
const cardConfig = /^[\w.-]+$/.test(currentCard) ? join('specs', currentCard, 'http-attack.config.json') : null;
let mergedConfig;
const at = forwarded.indexOf('--config');
const source = at >= 0 ? forwarded[at + 1] : [cardConfig, 'http-attack.config.json'].find((f) => f && existsSync(f)) ?? null;
if (ignores.length || (at < 0 && source)) {
  let project = {};
  if (source) { try { project = JSON.parse(readFileSync(source, 'utf8').replace(/^﻿/, '')); } catch { project = null; } }
  // An unreadable or invalid project config goes to the skill as is, so its own error is the one reported.
  if (project && typeof project === 'object' && !Array.isArray(project)) {
    mergedConfig = join(mkdtempSync(join(tmpdir(), 'kit-attack-')), 'http-attack.config.json');
    const own = Array.isArray(project.ignore) ? project.ignore : [];
    const ownIds = new Set(own.map((e) => e?.id));
    writeFileSync(mergedConfig, JSON.stringify({ ...project, ignore: [...own, ...ignores.filter((e) => !ownIds.has(e.id))] }));
    if (at >= 0) forwarded.splice(at, 2);
    forwarded.push('--config', mergedConfig);
    process.on('exit', () => rmSync(dirname(mergedConfig), { recursive: true, force: true }));
  } else if (at < 0 && source) forwarded.push('--config', source);
}

const leaks = ['/.claude/settings.json', '/specs/.current', ...(/^[\w.-]+$/.test(currentCard) ? [`/specs/${currentCard}/card.md`] : []), '/design/line.md'];
for (const path of leaks) forwarded.push('--leak-path', path);

process.exit(await main([base, ...forwarded]));
