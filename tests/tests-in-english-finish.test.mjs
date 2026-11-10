// The tests of the apps are English down to their titles, declared names and comments (ENG-24, after ENG-22 renamed their
// folders and files). The Spanish they keep is the app's Spanish text they check, quoted.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { replacementsOf } from '../.claude/tools/verify.mjs';
import { offendersIn, offendersInFiles, read, repo, report, testSources, walk } from './spanish-detector.mjs';

test('every title, declared name and comment of the API tests is English @ENG-24-S3 @assumption:ENG-24-ASM-01', () => {
  const offenders = offendersIn(['apps/api/tests']);
  assert.deepEqual(offenders, [], report(offenders));
});

test('every title, declared name and comment of the app tests is English @ENG-24-S3', () => {
  const offenders = offendersIn(['apps/mobile/test', 'apps/mobile/integration_test']);
  assert.deepEqual(offenders, [], report(offenders));
});

test('the helpers and fixtures the app tests share have English names @ENG-24-S1', () => {
  const support = ['apps/mobile/test/support', 'apps/mobile/integration_test/support'].flatMap((dir) => walk(dir, (p) => p.endsWith('.dart')));
  assert.ok(support.length > 0, 'the app tests share helpers in a support folder');
  const offenders = offendersInFiles(support).filter((line) => /: name /.test(line));
  assert.deepEqual(offenders, [], report(offenders));
});

test('no test carries the Spanish tag supuesto @ENG-24-S1', () => {
  const offenders = testSources().filter((path) => read(path).includes('@supuesto:'));
  assert.deepEqual(offenders, []);
});

// How many times each Spanish text of the app (a value of app_es.arb) appeared as a whole string literal in the tests before
// they were translated, not counting the titles of tests and groups: translating a title or a comment never touches them.
const quotedCount = (sources, value) => {
  const escaped = value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const rx = new RegExp(`(['"])${escaped}\\1`, 'g');
  return sources.reduce((n, text) => n + (text.match(rx)?.length ?? 0), 0);
};

test('the Spanish app strings the tests compare are quoted, not translated @ENG-24-S2', () => {
  const before = JSON.parse(read('tests/fixtures/spanish-app-strings-in-tests.json'));
  assert.ok(Object.keys(before).length > 100, 'the baseline holds the Spanish app texts the tests compared');
  const sources = testSources().map(read);
  // A single lowercase word («sede», «usuario») is also an old table name, a SQL bind key or a local label, not only app text.
  const lost = Object.entries(before)
    .filter(([value]) => !/^[a-záéíóúñ]+$/.test(value))
    .map(([value, count]) => [value, count, quotedCount(sources, value)])
    .filter(([, count, now]) => now < count)
    .map(([value, count, now]) => `«${value}»: ${count} → ${now}`);
  assert.deepEqual(lost, []);
});

// A path to a test file that a test or a doc cites. The method's records in specs/ cite the old ones (ENG-22-ASM-02) and the
// glossary maps old names to new ones on purpose; a literal a test checks is absent stays.
const CITING = () => [
  ...walk('apps/api/tests', (p) => p.endsWith('.py')),
  ...walk('apps/mobile/test', (p) => p.endsWith('.dart')),
  ...walk('apps/mobile/integration_test', (p) => p.endsWith('.dart')),
  ...walk('docs', (p) => p.endsWith('.md') && !p.endsWith('glossary.md')),
];
const CITED = /(?<![\w./@:-])(?:apps\/(?:api|mobile)\/)?(?:tests|test|integration_test)\/[A-Za-z0-9_./-]*\.(?:py|dart)(?![\w])/g;
const OLD_FOLDER = /\/(?:escenarios|integracion|capturas|rediseno|soporte|reservas|sedes|espacios|sesion|usuarios|notificaciones|registro|errores|inicio)\//;
// A test that builds a path from its folders (`TESTS / "escenarios" / name`) cites the folder by its old name.
const OLD_SEGMENT = /\btests\/(?:escenarios|integracion)\b|["'](?:escenarios|integracion)["']|\btest\/(?:capturas|rediseno|soporte)\b|\bintegration_test\/(?:soporte|reservas|sedes|espacios|sesion|usuarios|notificaciones|registro|errores|inicio)\b/g;
const existsFromSomeRoot =(cited) => ['', 'apps/api/', 'apps/mobile/'].some((base) => existsSync(join(repo, base + cited)));
const absentOnPurpose = (text, cited) =>
  new RegExp(`(?:not\\s+(?:\\w+\\.)?exists?|assert\\s+not|isFalse|doesNotExist|\\bnot in\\b)[^\\n]*${cited.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`).test(text);

test('every test path a test or a doc cites exists @ENG-24-S4', () => {
  const offenders = CITING().flatMap((path) => {
    const text = read(path);
    return [...new Set(text.match(CITED) ?? [])]
      .filter((cited) => !existsFromSomeRoot(cited) && (OLD_FOLDER.test(`/${cited}`) || !absentOnPurpose(text, cited)))
      .map((cited) => `${path}: ${cited}`)
      .concat((text.match(OLD_SEGMENT) ?? []).map((segment) => `${path}: ${segment}`));
  });
  assert.deepEqual(offenders, [], offenders.join('\n'));
});

test('every replacement this card declares names an existing test and a replacement that carries its tags @assumption:ENG-24-ASM-02', () => {
  const replacements = replacementsOf(read('specs/ENG-24-tests-en-ingles-fin/card.md'));
  assert.ok(replacements.length > 0, 'the card declares again the replacements whose titles it translated');
  const flat = (s) => String(s).replace(/\s+/g, ' ');
  const holds = (r) => {
    if (!existsSync(join(repo, r.file)) || !existsSync(join(repo, r.by))) return false;
    const by = flat(read(r.by));
    const tags = r.name.match(/@(?:assumption:)?[A-Z][A-Z0-9]*-\d+-(?:S\d+|ASM-\d+|SUP-\d+|H\d+(?:-\d+)?)(?![\w-])/g) ?? [];
    return (r.byName.startsWith('(') || by.includes(flat(r.byName))) && tags.every((tag) => by.includes(tag));
  };
  // The Log only grows: a later line of the same replaced test, or of the same declaration (file, reason and replacement),
  // corrects an earlier one.
  const same = (r, s) => s.file === r.file && (s.name === r.name || (s.why === r.why && s.by === r.by));
  const offenders = replacements.filter((r) => !replacements.some((s) => same(r, s) && holds(s)));
  assert.deepEqual(offenders.map((r) => `${r.file} "${r.name}" → ${r.by} "${r.byName}"`), []);
});
