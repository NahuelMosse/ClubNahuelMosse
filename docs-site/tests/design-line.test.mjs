import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const repo = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const read = (path) => readFileSync(join(repo, path), 'utf8');

const RAW_COLOR = /#[0-9a-f]{3,8}\b|\brgba?\(|\bhsla?\(/i;
const RAW_LENGTH = /\b(?:padding|margin|gap|border-radius)\s*:[^;}]*\b\d+px/;

// The values design/line.md section 3 lists, by token name.
const dark = {
  '--neutral-0': '#0A0A0B',
  '--neutral-1': '#141416',
  '--neutral-2': '#1E1E21',
  '--neutral-3': '#2A2A2E',
  '--neutral-6': '#64646E',
  '--neutral-8': '#85858C',
  '--neutral-9': '#A1A1AA',
  '--neutral-12': '#FFFFFF',
  '--accent': '#D4FF3D',
};
const sharedTokens = {
  '--space-1': '4px', '--space-2': '8px', '--space-3': '12px', '--space-4': '16px',
  '--space-5': '24px', '--space-6': '32px', '--space-7': '48px', '--space-8': '64px',
  '--radius-1': '6px', '--radius-2': '10px',
  '--duration-instant': '80ms', '--duration-fast': '120ms', '--duration-base': '180ms', '--duration-slow': '260ms',
};

const block = (css, selector) => {
  const start = css.indexOf(`${selector} {`);
  assert.notEqual(start, -1, `${selector} block missing`);
  return css.slice(start, css.indexOf('\n}', start));
};
const declares = (body, name, value) =>
  new RegExp(`${name}:\\s*${value}\\s*;`, 'i').test(body);

test('the docs site takes its colors, space and motion from design/tokens.css @ENG-21-S3', () => {
  const tokens = read('design/tokens.css');
  const root = block(tokens, ':root');
  const night = block(tokens, ':root[data-theme="dark"]');
  const custom = read('docs-site/src/css/custom.css');
  const copyDocs = read('docs-site/scripts/copy-docs.mjs');
  const swagger = read('docs-site/src/components/Swagger.js');
  const config = read('docs-site/docusaurus.config.js');
  const page = copyDocs.slice(copyDocs.indexOf('<!doctype html>'));

  const cases = [
    ['tokens: dark values of the line', () => {
      for (const [name, value] of Object.entries(dark)) assert.ok(declares(night, name, value), `${name} ${value} in dark`);
    }],
    ['tokens: light accent is the olive ink', () => assert.ok(declares(root, '--accent', '#4D6600'))],
    ['tokens: dark redefines the semantic names', () => {
      for (const name of ['--surface', '--surface-raised', '--text', '--text-soft', '--text-muted', '--border', '--focus', '--accent-on'])
        assert.ok(new RegExp(`${name}:`).test(night), `${name} redefined in dark`);
      assert.ok(declares(root, '--danger', '#FF4D6A'));
    }],
    ['tokens: space, radius and durations', () => {
      for (const [name, value] of Object.entries(sharedTokens)) assert.ok(declares(root, name, value), `${name} ${value}`);
      for (const name of ['--motion-button-press', '--motion-hover', '--motion-focus', '--motion-content-enter'])
        assert.ok(new RegExp(`${name}:`).test(root), name);
    }],
    ['the set exists', () => {
      for (const file of ['primitives.css', 'components.css']) assert.ok(existsSync(join(repo, 'design/components', file)), file);
    }],
    ['the embedded Swagger page writes no raw color or length', () => {
      assert.doesNotMatch(page, RAW_COLOR);
      assert.doesNotMatch(page, RAW_LENGTH);
      assert.match(page, /design\/tokens\.css/);
    }],
    ['custom.css writes no raw color and Infima reads the tokens', () => {
      assert.doesNotMatch(custom.replace(/\/\*[\s\S]*?\*\//g, ''), RAW_COLOR);
      assert.match(custom, /--ifm-color-primary:\s*var\(--accent\)/);
      assert.match(custom, /--ifm-background-color:\s*var\(--bg\)/);
    }],
    ['the site loads the tokens and the set', () => {
      assert.match(copyDocs, /design/);
      for (const sheet of ['tokens.css', 'primitives.css', 'components.css']) assert.ok(config.includes(sheet), sheet);
    }],
    ['Swagger.js composes from the set', () => {
      assert.match(swagger, /className="[^"]*\bbtn\b/);
      assert.match(swagger, /\bsurface\b/);
      assert.doesNotMatch(swagger, /button--/);
    }],
    ['motion: hover, press, focus, entrance and reduced motion', () => {
      assert.match(custom, /transition:[^;]*var\(--motion-hover\)/);
      assert.match(custom, /:focus-visible[^}]*var\(--focus\)/);
      assert.match(custom, /animation:[^;]*var\(--motion-content-enter\)/);
      assert.doesNotMatch(custom, /transition:\s*all/);
      const reduced = custom.slice(custom.indexOf('@media (prefers-reduced-motion: reduce)'));
      assert.match(reduced, /transition:\s*none/);
      assert.match(reduced, /translate|transform/);
    }],
  ];
  for (const [label, check] of cases) assert.doesNotThrow(check, label);
});
