// The docs, the READMEs, the docs site and the README screenshots are English (ENG-21).
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const repo = resolve(import.meta.dirname, '..');
const read = (path) => readFileSync(join(repo, path), 'utf8');
const walk = (dir, accept) =>
  readdirSync(join(repo, dir), { withFileTypes: true }).flatMap((entry) => {
    const path = `${dir}/${entry.name}`;
    if (entry.isDirectory()) return entry.name === 'node_modules' ? [] : walk(path, accept);
    return accept(path) ? [path] : [];
  });

const docsPages = () => walk('docs', (path) => path.endsWith('.md'));
const readmes = ['README.md', 'apps/api/README.md', 'apps/mobile/README.md'];

const SPANISH_WORDS = new Set(
  'de la el los las que y con para por una del se es en un al lo como sin'.split(' '),
);
const SPANISH_SHARE = 0.02;

// The prose of a page: no fenced code, inline code or URLs.
const prose = (markdown) =>
  markdown
    .replace(/^```[\s\S]*?^```/gm, ' ')
    .replace(/`[^`\n]*`/g, ' ')
    .replace(/https?:\/\/\S+/g, ' ')
    .replace(/\]\([^)]*\)/g, ' ');

const spanishShare = (text) => {
  const words = text.toLowerCase().match(/[a-záéíóúñü]+/g) ?? [];
  if (words.length === 0) return 0;
  return words.filter((word) => SPANISH_WORDS.has(word)).length / words.length;
};

// The glossary maps Spanish names to English ones: its first column is Spanish by design.
const withoutSpanishColumn = (markdown) => markdown.replace(/^\|[^|\n]*\|/gm, '|');

test('every docs page and README is English @ENG-21-S1 @ENG-21-S2 @assumption:ENG-21-ASM-02', () => {
  const pages = [...docsPages(), ...readmes];
  const offenders = pages
    .map((path) => {
      const text = path.endsWith('glossary.md') ? withoutSpanishColumn(read(path)) : read(path);
      return [path, spanishShare(prose(text))];
    })
    .filter(([, share]) => share >= SPANISH_SHARE)
    .map(([path, share]) => `${path} ${(share * 100).toFixed(1)}%`);
  assert.deepEqual(offenders, []);
});

test('the Spanish detector flags a Spanish paragraph and passes an English one with code and names @assumption:ENG-21-ASM-03', () => {
  const spanish = 'La reserva se confirma con el pago de la sede y el usuario recibe un aviso para los demás.';
  const english =
    'A booking is confirmed when the venue accepts it. Run `pytest -q` in `apps/api`; see https://example.com/de/la/que. Sede Morón stays a proper name.';
  assert.ok(spanishShare(prose(spanish)) >= SPANISH_SHARE);
  assert.ok(spanishShare(prose(english)) < SPANISH_SHARE);
  assert.equal(spanishShare(prose('```\nde la el los\n```')), 0);
  assert.equal(spanishShare(''), 0);
});

const ENGLISH_PAGES = [
  'docs/technical/architecture.md',
  'docs/technical/code-map.md',
  'docs/technical/app-navigation.md',
  'docs/technical/data-model.md',
  'docs/technical/system-design.md',
  'docs/technical/runbook.md',
  'docs/technical/infra-cost.md',
  'docs/technical/integrations.md',
  'docs/technical/glossary.md',
  'docs/getting-started.md',
  'docs/documentation-assumptions.md',
  'docs/adr/0001-stack.md',
  'docs/adr/0002-hosting-on-render.md',
  'docs/business/accessibility.md',
];

test('every docs page has an English file name @ENG-21-S1', () => {
  assert.deepEqual(docsPages().sort(), [...ENGLISH_PAGES].sort());
});

// Paths of the app a doc cites.
const dartPaths = (markdown) => [...new Set(markdown.match(/[\w./-]+\.dart/g) ?? [])];
const appFileExists = (cited) => {
  const candidates = [cited, `apps/mobile/${cited}`, `apps/mobile/lib/${cited}`, `apps/mobile/test/${cited}`];
  if (candidates.some((candidate) => existsSync(join(repo, candidate)))) return true;
  if (cited.includes('/')) return false;
  return walk('apps/mobile', (path) => path.endsWith(`/${cited}`) && !path.includes('/build/')).length > 0;
};

test('every app file the navigation page cites exists @ENG-21-S5', () => {
  const page = 'docs/technical/app-navigation.md';
  assert.ok(existsSync(join(repo, page)), `${page} is missing`);
  const cited = dartPaths(read(page));
  assert.ok(cited.length > 0);
  assert.deepEqual(cited.filter((path) => !appFileExists(path)), []);
});

const ROOTS = /^(apps|docs|specs|tests|scripts|docs-site|\.github)\//;
const GENERATED = /^(docs-site\/(docs|static|node_modules|build|\.docusaurus)\/|apps\/mobile\/build\/)/;
const citedRepoPaths = (markdown) =>
  [...markdown.matchAll(/`([^`\s]+)`/g)]
    .map(([, code]) => code.replace(/[:#].*$/, '').replace(/[.,;)]+$/, ''))
    .filter((path) => ROOTS.test(path) && /\.\w+$|\/$/.test(path) && !/[*<>{}$]/.test(path))
    .filter((path) => !GENERATED.test(path));

test('every repo path a doc cites exists @assumption:ENG-21-ASM-06', () => {
  const missing = [...docsPages(), ...readmes]
    .filter((page) => !page.endsWith('glossary.md'))
    .flatMap((page) =>
      citedRepoPaths(read(page))
        .filter((path) => !existsSync(join(repo, path)))
        .map((path) => `${page} cites ${path}`),
    );
  assert.deepEqual(missing, []);
  const accessibility = read('docs/business/accessibility.md');
  assert.match(accessibility, /apps\/mobile\/lib\/main\.dart/);
  assert.match(accessibility, /resumeWithRetry/);
  assert.match(accessibility, /apps\/mobile\/test\/arranque_sin_conexion_test\.dart/);
});

const SPANISH_CHARACTERS = /[áéíóúñ¿¡ÁÉÍÓÚÑ]/;
const SITE_FILES = [
  'docs-site/docusaurus.config.js',
  'docs-site/scripts/copy-docs.mjs',
  'docs-site/scripts/docstrings.py',
  'docs-site/src/clientModules/diagram-zoom.js',
  'docs-site/src/components/Swagger.js',
];

test('the docs site lives in docs-site and is English @ENG-21-S3 @assumption:ENG-21-ASM-05', () => {
  assert.ok(existsSync(join(repo, 'docs-site')));
  assert.ok(!existsSync(join(repo, 'sitio-docs')));
  const config = read('docs-site/docusaurus.config.js');
  assert.match(config, /defaultLocale: 'en', locales: \['en'\]/);
  assert.match(config, /language: \['en'\]/);
  assert.match(config, /\.\/src\/clientModules\/diagram-zoom\.js/);
  for (const file of SITE_FILES) {
    assert.doesNotMatch(read(file), SPANISH_CHARACTERS, `${file} has Spanish text`);
  }
  const copy = read('docs-site/scripts/copy-docs.mjs');
  assert.match(copy, /<html lang="en">/);
  assert.doesNotMatch(copy, /lang="es"/);
  for (const label of ['Technical', 'Guides', 'Decisions', 'Product and quality', 'Home']) {
    assert.ok(copy.includes(`'${label}'`), `label ${label}`);
  }
  for (const page of ENGLISH_PAGES) assert.ok(copy.includes(`'${page}'`), `copy table misses ${page}`);
  const workflow = read('.github/workflows/ci.yml');
  for (const legacy of ['sitio-docs', 'tecnica', 'guia-basica', 'zoom-de-diagramas']) {
    assert.ok(!copy.includes(legacy) && !workflow.includes(legacy), legacy);
  }
  assert.match(workflow, /docs-site\/tests\/\*\.test\.mjs/);
});

test('the site keeps publishing the specs records under English sections @assumption:ENG-21-ASM-01', () => {
  const copy = read('docs-site/scripts/copy-docs.mjs');
  assert.match(copy, /\['specs\/TRAZABILIDAD\.md', 'product\/traceability\.md', 2\]/);
  assert.match(copy, /\['specs\/REVISION-main\.md', 'product\/review\.md', 3\]/);
  assert.match(copy, /product: \['Product and quality', 5\]/);
});

test("the site's files and the README capture have English names @assumption:ENG-21-ASM-07", () => {
  const present = [
    ...SITE_FILES,
    'docs-site/tests/integrations-on-site.test.mjs',
    'docs-site/tests/diagram-zoom.test.mjs',
    'apps/mobile/test/screenshots/readme_screenshots.dart',
  ];
  assert.deepEqual(present.filter((path) => !existsSync(join(repo, path))), []);
  const old = [
    'docs-site/scripts/copiar.mjs',
    'docs-site/src/clientModules/zoom-de-diagramas.js',
    'docs-site/tests/integraciones-en-el-sitio.test.mjs',
    'docs-site/tests/zoom-de-diagramas.test.mjs',
  ];
  assert.deepEqual(old.filter((path) => existsSync(join(repo, path))), []);
});

const SCREENSHOTS = ['01-login', '03-venues', '05-availability', '07-done'];
const SCREENSHOT_WIDTH = 430;
const pngWidth = (path) => readFileSync(join(repo, path)).readUInt32BE(16);

test('the README screenshots are the ones the English capture produces @ENG-21-S4 @assumption:ENG-21-ASM-04', () => {
  assert.ok(!existsSync(join(repo, 'docs/capturas')));
  for (const name of SCREENSHOTS) {
    const path = `docs/screenshots/${name}.png`;
    assert.ok(existsSync(join(repo, path)), `${path} is missing`);
    assert.equal(readFileSync(join(repo, path)).subarray(1, 4).toString(), 'PNG');
    assert.equal(pngWidth(path), SCREENSHOT_WIDTH);
    assert.match(read('README.md'), new RegExp(`docs/screenshots/${name}\\.png`));
  }
  assert.doesNotMatch(read('README.md'), /docs\/capturas/);
  const capture = read('apps/mobile/test/screenshots/readme_screenshots.dart');
  assert.match(capture, /Locale\('en'\)/);
  assert.match(capture, /lightTheme/);
  assert.match(capture, /Size\(430,/);
  assert.match(capture, /docs\/screenshots/);
  assert.ok(statSync(join(repo, 'docs/screenshots')).isDirectory());
});
