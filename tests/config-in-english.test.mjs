// The configuration, the tools, the API's names and the docs are English (ENG-23): environment variables, dart-defines, command-line
// options, npm scripts, option values, OpenAPI tags, logger names and comments. The Spanish the app keeps is app_es.arb.
import { execFileSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { wordsOf } from '../.claude/tools/code-language.mjs';
import { ACCENT, declaredNames, proseOf, read, repo, report, spanishProse, spanishWordsIn, walk } from './spanish-detector.mjs';

// The Spanish names this card renames, and the Spanish value of an option.
const SPANISH_NAMES = new RegExp(
  [
    '\\b(?:AUTH_EMULADOR|ADMIN_CORREO|ADMIN_CONTRASENA|CORREO_MODO|CORREO_REMITENTE|SMTP_PUERTO|SMTP_USUARIO|SMTP_CONTRASENA)\\b',
    '\\b(?:URL_PUBLICA|FIREBASE_CREDENCIALES_JSON|RECORDATORIOS_CADA|AVISOS_SEGUNDOS|PRUEBAS|DISPOSITIVO)\\b',
    '--(?:correo|nombre|apellido|nacimiento|promover)\\b',
    '\\bnpm run emuladores\\b|"emuladores"|PUSH=simulado|\\bbuzon\\b',
  ].join('|'),
);

// The frozen tests that assert a Spanish name is still read are replaced (Log), not updated.
const REPLACED_FILES = new Set([
  'apps/api/tests/unit/test_config_in_english.py',
  'apps/api/tests/unit/test_api_in_english.py',
  'apps/api/tests/unit/test_brevo_email.py',
  // The test of the old names that must stay unread.
  'apps/api/tests/unit/test_config_english_only.py',
]);
const SOURCE_FILES = [
  ...walk('apps/api/app', (path) => path.endsWith('.py')),
  ...['apps/api/.env.example', 'apps/api/pyproject.toml', 'package.json', 'render.yaml', 'firebase.json'],
  ...walk('scripts', (path) => /\.(sh|mjs)$/.test(path)),
  ...walk('.github'),
  ...walk('apps/mobile/lib', (path) => path.endsWith('.dart') && !path.includes('/l10n/')),
  ...walk('apps/mobile/test', (path) => path.endsWith('.dart')),
  ...walk('apps/mobile/integration_test', (path) => path.endsWith('.dart')),
  ...walk('apps/api/tests', (path) => path.endsWith('.py')),
].filter((path) => !REPLACED_FILES.has(path) && existsSync(`${repo}/${path}`));

test('every environment variable, dart-define, command-line option, npm script and option value is English and no Spanish name is read @ENG-23-S4 @assumption:ENG-23-ASM-02', () => {
  const offenders = SOURCE_FILES.flatMap((path) =>
    read(path)
      .split('\n')
      .map((line, index) => [line, index + 1])
      .filter(([line]) => SPANISH_NAMES.test(line))
      .map(([line, number]) => `${path}:${number}: ${line.trim().slice(0, 100)}`),
  );
  assert.deepEqual(offenders, [], report(offenders));
  const config = read('apps/mobile/lib/common/config.dart');
  assert.ok(config.includes("'AUTH_EMULATOR'") && config.includes("== 'simulated'"));
  assert.ok(read('package.json').includes('"emulators"'));
});

const CONFIG_FILES = ['apps/api/.env.example', 'apps/api/pyproject.toml', 'render.yaml', 'package.json', ...walk('scripts', (path) => path.endsWith('.sh')), ...walk('.github', (path) => /\.ya?ml$/.test(path))];
const commentsOfConfig = (path, text) => {
  if (path.endsWith('package.json')) return [JSON.parse(text).description ?? ''];
  return text.split('\n').flatMap((line) => {
    const match = line.match(/(?:^|\s)#(?!!)\s*(.*)$/);
    return match ? [match[1]] : [];
  });
};

test('the comments of render.yaml, .env.example, the scripts, package.json, pyproject.toml and the workflows are English @ENG-23-S4', () => {
  const offenders = CONFIG_FILES.flatMap((path) =>
    commentsOfConfig(path, read(path))
      .filter(spanishProse)
      .map((chunk) => `${path}: «${chunk.trim().slice(0, 90)}»`),
  );
  assert.deepEqual(offenders, [], report(offenders));
});

test('the OpenAPI tags and the logger names of the API are English @ENG-23-S4 @assumption:ENG-23-ASM-05', () => {
  const sources = walk('apps/api/app', (path) => path.endsWith('.py'));
  const tags = sources.flatMap((path) => [...read(path).matchAll(/APIRouter\(tags=\[([^\]]*)\]/g)].flatMap((m) => [...m[1].matchAll(/"([^"]*)"/g)].map((t) => t[1])));
  const loggers = sources.flatMap((path) => [...read(path).matchAll(/getLogger\(\s*"([^"]*)"/g)].map((m) => m[1]));
  for (const tag of ['availability', 'bookings', 'notifications', 'spaces', 'users', 'venues']) assert.ok(tags.includes(tag), `tag ${tag}`);
  for (const suffix of ['email', 'identity', 'password_recovery', 'deactivation', 'password', 'registration']) assert.ok(loggers.includes(`clubnahuelmosse.${suffix}`), `logger ${suffix}`);
  const spanish = [...tags, ...loggers].filter((name) => spanishWordsIn(wordsOf(name.replace(/[.]/g, '_'))).length > 0);
  assert.deepEqual(spanish, []);
  const contract = JSON.parse(read('apps/api/openapi.json'));
  const published = new Set(Object.values(contract.paths).flatMap((methods) => Object.values(methods).flatMap((operation) => operation.tags ?? [])));
  assert.deepEqual([...published].filter((tag) => spanishWordsIn(wordsOf(tag.replace(/\s+/g, '_'))).length > 0), []);
  for (const tag of ['availability', 'bookings', 'notifications', 'spaces', 'users', 'venues']) assert.ok(published.has(tag), `published ${tag}`);
});

// A message to the developer: what an exception, a print or a log line says.
const developerMessagesOf = (text) =>
  [...text.matchAll(/\b(?:raise\s+\w+|print|\w*log\.\w+|logging\.\w+)\(\s*f?"((?:\\.|[^"\\\n])*)"/g)].map((m) => m[1]);

test('every file, name, comment and developer message of apps/api/app is English @ENG-23-S3', () => {
  const offenders = walk('apps/api/app', (path) => path.endsWith('.py')).flatMap((path) => {
    const text = read(path);
    const file = path.split('/').pop().replace('.py', '');
    const names = declaredNames(text).filter((name) => ACCENT.test(name) || spanishWordsIn(wordsOf(name)).length > 0);
    const prose = [...proseOf(path, text), ...developerMessagesOf(text)].filter(spanishProse);
    return [
      ...(spanishWordsIn(wordsOf(file)).length > 0 ? [`${path}: file name`] : []),
      ...names.map((name) => `${path}: name ${name}`),
      ...prose.map((chunk) => `${path}: «${chunk.trim().slice(0, 90)}»`),
    ];
  });
  assert.deepEqual(offenders, [], report(offenders));
});

test('the docs and READMEs cite only the English routes, variables, options and scripts @ENG-23-S4', () => {
  const pages = [...walk('docs', (path) => path.endsWith('.md')), 'README.md', 'apps/api/README.md', 'apps/mobile/README.md'].filter((path) => !path.endsWith('glossary.md'));
  const offenders = pages.flatMap((path) =>
    read(path)
      .split('\n')
      .map((line, index) => [line, index + 1])
      .filter(([line]) => SPANISH_NAMES.test(line) || /\bcorreo_saliente\b/.test(line))
      .map(([line, number]) => `${path}:${number}: ${line.trim().slice(0, 100)}`),
  );
  assert.deepEqual(offenders, [], report(offenders));
});

// The files this card's commits touch.
const BASE = '8fa77294';
const touchedByTheCard = () =>
  [...new Set(execFileSync('git', ['log', '--grep=ENG-23', '--name-only', '--format=', `${BASE}..HEAD`], { cwd: repo, encoding: 'utf8' }).split('\n').filter(Boolean))];

test('app_es.arb and the Spanish texts the tests compare stay as on main @ENG-23-S2', () => {
  assert.ok(!touchedByTheCard().includes('apps/mobile/lib/l10n/app_es.arb'));
  const arb = JSON.parse(read('apps/mobile/lib/l10n/app_es.arb'));
  assert.equal(arb.accessDeniedTitle, 'Acceso denegado');
  const tests = walk('apps/mobile/test', (path) => path.endsWith('.dart')).map(read).join('\n');
  assert.ok(tests.includes('Acceso denegado') && tests.includes('Estás modificando'));
});

test("the card leaves other cards' specs, the kit, main's migrations and app_es.arb untouched @assumption:ENG-23-ASM-03", () => {
  const outside = touchedByTheCard().filter(
    (path) => (path.startsWith('specs/') && !path.startsWith('specs/ENG-23-') && path !== 'specs/.current') || path.startsWith('.claude/') || path === 'CLAUDE.md' || path.startsWith('apps/api/migrations/versions/') || path.endsWith('app_es.arb'),
  );
  assert.deepEqual(outside, []);
});

// A replaced file may be deleted: it must have existed on main.
const existsInBase = (path) => {
  try {
    execFileSync('git', ['cat-file', '-e', `${BASE}:${path}`], { cwd: repo, stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
};

test('every replacement this card declares names an existing test and a replacement that carries its tags @assumption:ENG-23-ASM-06', () => {
  const lines = read('specs/ENG-23-nombres-en-ingles/card.md')
    .split('\n')
    .filter((line) => line.includes(' · replaces: ') && line.includes('apps/api/tests/'));
  assert.ok(lines.length >= 6, 'the card declares its replacements');
  const problems = lines.flatMap((line) => {
    const match = line.match(/replaces: (\S+) "(.*)" · .* · by: (\S+) "(.*)"$/);
    if (!match) return [`unreadable: ${line.slice(0, 80)}`];
    const [, oldFile, oldTitle, newFile, newTitle] = match;
    const oldTags = oldTitle.match(/@[\w:-]+/g) ?? [];
    const newText = existsSync(`${repo}/${newFile}`) ? read(newFile) : '';
    return [
      ...(existsInBase(oldFile) ? [] : [`${oldFile} does not exist`]),
      ...(newText.includes(newTitle) ? [] : [`${newFile} lacks «${newTitle.slice(0, 60)}»`]),
      ...oldTags.filter((tag) => !newTitle.includes(tag)).map((tag) => `${newFile} lacks ${tag}`),
    ];
  });
  assert.deepEqual(problems, []);
});
