// The tests of the apps are English: folders, files, titles, declared names and comments (ENG-22). The Spanish they keep is
// the app's Spanish text they check, quoted.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { replacementsOf } from '../.claude/tools/verify.mjs';
import { wordsOf } from '../.claude/tools/code-language.mjs';
import { ACCENT, offendersIn, read, repo, report, spanishName, spanishProse, spanishWordsIn, testSources, TEST_ROOTS, walk } from './spanish-detector.mjs';

test('every test folder and file of the apps has an English name @ENG-22-S1 @assumption:ENG-22-ASM-05', () => {
  const offenders = TEST_ROOTS.flatMap((root) => walk(root))
    .flatMap((path) => path.split('/').slice(root(path).split('/').length))
    .filter((segment, i, all) => all.indexOf(segment) === i)
    .filter((segment) => spanishWordsIn(wordsOf(segment.replace(/\.(dart|py|png|yaml)$/, ''))).length > 0 || ACCENT.test(segment));
  assert.deepEqual(offenders, [], report(offenders));
  const folders = {
    'apps/api/tests/scenarios': 'apps/api/tests/escenarios',
    'apps/api/tests/integration': 'apps/api/tests/integracion',
    'apps/mobile/test/screenshots': 'apps/mobile/test/capturas',
    'apps/mobile/test/redesign': 'apps/mobile/test/rediseno',
    'apps/mobile/test/support': 'apps/mobile/test/soporte',
    'apps/mobile/integration_test/support': 'apps/mobile/integration_test/soporte',
    'apps/mobile/integration_test/bookings': 'apps/mobile/integration_test/reservas',
    'apps/mobile/integration_test/venues': 'apps/mobile/integration_test/sedes',
    'apps/mobile/integration_test/spaces': 'apps/mobile/integration_test/espacios',
    'apps/mobile/integration_test/session': 'apps/mobile/integration_test/sesion',
    'apps/mobile/integration_test/users': 'apps/mobile/integration_test/usuarios',
    'apps/mobile/integration_test/notifications': 'apps/mobile/integration_test/notificaciones',
    'apps/mobile/integration_test/registration': 'apps/mobile/integration_test/registro',
    'apps/mobile/integration_test/errors': 'apps/mobile/integration_test/errores',
    'apps/mobile/integration_test/home': 'apps/mobile/integration_test/inicio',
  };
  for (const [now, before] of Object.entries(folders)) {
    assert.ok(existsSync(join(repo, now)), `${now} exists`);
    assert.ok(!existsSync(join(repo, before)), `${before} is gone`);
  }
  assert.deepEqual(walk('apps/mobile/test/screenshots', (p) => /_capturas\.dart$/.test(p)), []);
});
const root = (path) => TEST_ROOTS.find((r) => path.startsWith(`${r}/`)) ?? '';

test('every title, declared name and comment of the API tests is English @ENG-22-S3 @assumption:ENG-22-ASM-04', () => {
  const offenders = offendersIn(['apps/api/tests']);
  assert.deepEqual(offenders, [], report(offenders));
});

test('every title, declared name and comment of the app tests is English @ENG-22-S3 @assumption:ENG-22-ASM-04', () => {
  const offenders = offendersIn(['apps/mobile/test', 'apps/mobile/integration_test']);
  assert.deepEqual(offenders, [], report(offenders));
});

test('no test carries the Spanish tag supuesto @ENG-22-S1', () => {
  const offenders = testSources().filter((path) => read(path).includes('@supuesto:'));
  assert.deepEqual(offenders, []);
});

test('the Spanish detector flags Spanish names and prose and passes English that quotes Spanish UI text @ENG-22-S2 @assumption:ENG-22-ASM-03', () => {
  for (const name of ['test_un_usuario_reserva_una_cancha', 'crearReserva', 'montarPantalla', 'sedeHaedoJson', 'año']) {
    assert.ok(spanishName(name), name);
  }
  for (const name of ['test_a_user_books_a_court', 'createBooking', 'mountScreen', 'haedoVenueJson', 'enLocale', 'dni']) {
    assert.ok(!spanishName(name), name);
  }
  for (const text of ['un usuario reserva una cancha', 'Verifica: la sede guarda nombre', 'si falla, revisar la grilla', 'está bien']) {
    assert.ok(spanishProse(text), text);
  }
  for (const text of [
    'the login screen shows «Ingresá tu correo» under the field @ENG-19-S2',
    "the venue 'Sede Haedo' keeps its address",
    'the es locale and the en locale',
    'shows `reservas` in the URL https://example.com/de/la/que',
    'a booking past its slot stays in the user history',
  ]) {
    assert.ok(!spanishProse(text), text);
  }
});

// A path to a test that a doc, a kit rule, a config or a script cites. The method's records in specs/ cite the old ones (ENG-22-ASM-02),
// and the glossary maps old names to new ones on purpose.
const CITING = () => [
  ...walk('docs', (p) => p.endsWith('.md') && !p.endsWith('glossary.md')),
  'README.md',
  'apps/api/README.md',
  'apps/mobile/README.md',
  '.claude/STACK.md',
  '.claude/rules/interfaz.md',
  'apps/api/pyproject.toml',
  'apps/mobile/analysis_options.yaml',
  ...walk('scripts', (p) => /\.(sh|mjs)$/.test(p)),
  ...walk('.github/workflows'),
];
const CITED = /(?<![\w./@-])(?:apps\/(?:api|mobile)\/)?(?:tests|test|integration_test)\/[A-Za-z0-9_./*{}-]*[A-Za-z0-9_*}]/g;
const existsFromSomeRoot = (cited) => {
  const plain = cited.replace(/[*{].*$/, '').replace(/\/[^/]*$/, (last) => (cited.includes('*') || cited.includes('{') ? '' : last));
  return ['', 'apps/api/', 'apps/mobile/'].some((base) => existsSync(join(repo, base + plain)));
};

test('every repo path to a test that a doc, a kit rule, a config or a script cites exists @ENG-22-S4 @assumption:ENG-22-ASM-01 @assumption:ENG-22-ASM-02', () => {
  const offenders = CITING()
    .filter((path) => existsSync(join(repo, path)) && statSync(join(repo, path)).isFile())
    .flatMap((path) => [...new Set(read(path).match(CITED) ?? [])].filter((cited) => !existsFromSomeRoot(cited)).map((cited) => `${path}: ${cited}`));
  assert.deepEqual(offenders, []);
});

test('every replacement this card declares names an existing test and a replacement that carries its tags @assumption:ENG-22-ASM-06', () => {
  const replacements = replacementsOf(read('specs/ENG-22-tests-en-ingles/card.md'));
  assert.ok(replacements.length > 0, 'the card declares the replacements of the moved tests that still fail');
  const flat = (s) => String(s).replace(/\s+/g, ' ');
  // ENG-24 translated the titles of the tests and declares again, with them, each replacement whose titles it translated.
  const translated = new Set(replacementsOf(read('specs/ENG-24-tests-en-ingles-fin/card.md')).map((r) => `${r.file} ${r.by}`));
  const offenders = replacements.filter((r) => {
    if (!existsSync(join(repo, r.file)) || !existsSync(join(repo, r.by))) return true;
    const by = flat(read(r.by));
    const tags = r.name.match(/@(?:assumption:)?[A-Z][A-Z0-9]*-\d+-(?:S\d+|ASM-\d+|SUP-\d+|H\d+(?:-\d+)?)(?![\w-])/g) ?? [];
    return !(by.includes(flat(r.byName)) || translated.has(`${r.file} ${r.by}`)) || !tags.every((tag) => by.includes(tag));
  });
  assert.deepEqual(offenders.map((r) => `${r.file} "${r.name}" → ${r.by} "${r.byName}"`), []);
});

test('every screenshot a screenshots file names exists under an English name @assumption:ENG-22-ASM-07', () => {
  // readme_screenshots.dart writes its PNGs into docs/screenshots instead of comparing them.
  const pngs = ['apps/mobile/test/screenshots', 'docs/screenshots'].flatMap((dir) => walk(dir, (p) => p.endsWith('.png')));
  assert.ok(pngs.some((png) => png.startsWith('apps/mobile/test/screenshots/')), 'the screenshots live in apps/mobile/test/screenshots');
  const missing = walk('apps/mobile/test/screenshots', (p) => p.endsWith('.dart')).flatMap((path) =>
    [...read(path).matchAll(/(['"])([^'"\n]*\.png)\1/g)]
      .map((m) => m[2])
      .filter((cited) => {
        const rx = new RegExp(`${cited.replace(/\$\{[^}]*\}|\$\w+/g, '\u0000').replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace(/\u0000/g, '[^/]+')}$`);
        return !pngs.some((png) => rx.test(png));
      })
      .map((cited) => `${path}: ${cited}`),
  );
  assert.deepEqual(missing, []);
});
