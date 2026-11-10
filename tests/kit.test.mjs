// The kit installed in this repo is the one the update brought, and its files are as installed.
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const repo = resolve(import.meta.dirname, '..');
const kit = JSON.parse(readFileSync(join(repo, '.claude', 'kit.json'), 'utf8'));
const files = JSON.parse(readFileSync(join(repo, '.claude', 'kit-files.json'), 'utf8'));
// The team adds its plugins to settings.json, and `dart format` rewraps the Flutter test helpers; the installer keeps those edits.
const EDITED_BY_THE_TEAM = new Set([
  '.claude/settings.json',
  'apps/mobile/test/kit/kit_a11y.dart',
  'apps/mobile/test/kit/kit_motion.dart',
  'apps/mobile/test/kit/kit_states.dart',
]);

test('the installed kit is 6.44.0 @KIT-06-S1', () => {
  assert.equal(kit.kit, '6.44.0');
});

test('the kit was installed from the kit-v6.44.0 release @KIT-06-S2', () => {
  assert.match(kit.source.commit, /^[0-9a-f]{40}$/);
  assert.ok(kit.source.path);
});

// The update installs from a clone of the release tag, not from the dev-kit working copy.
test('the install source is the kit-v6.44.0 tag commit @KIT-06-ASM-01', () => {
  assert.equal(kit.source.commit, '4b95e4e8a1e8b969b9e3ed81f1aa0dfcdbea3dff');
});

test('cada archivo del kit está como lo instaló la actualización, salvo settings.json y el formato de los ayudantes de Flutter @KIT-03-S1', () => {
  const changed = Object.entries(files)
    .filter(([path]) => !EDITED_BY_THE_TEAM.has(path))
    .filter(([path, { sha256 }]) => createHash('sha256').update(readFileSync(join(repo, path))).digest('hex') !== sha256)
    .map(([path]) => path);
  assert.deepEqual(changed, []);
});

test('CLAUDE.md no declara otro idioma para el código @assumption:KIT-01-ASM-02', () => {
  assert.doesNotMatch(readFileSync(join(repo, 'CLAUDE.md'), 'utf8'), /^Code language:/m);
});
