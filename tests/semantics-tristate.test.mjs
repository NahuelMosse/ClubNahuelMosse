// Flutter 3.41 reports the enabled, selected, toggled, expanded, required and focused semantics flags as a Tristate,
// not as a bool: a test reads them compared with Tristate.isTrue.
import { readdirSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const mobile = resolve(import.meta.dirname, '..', 'apps', 'mobile');
const tristate = '(?:isEnabled|isSelected|isToggled|isExpanded|isRequired|isFocused)';
const reads = [
  new RegExp(`flagsCollection\\s*\\.\\s*${tristate}\\b(?!\\s*==)`, 'g'),
  new RegExp(`\\bflags\\((?:[^()]|\\([^()]*\\))*\\)\\.${tristate}\\b(?!\\s*==)`, 'g'),
];
const dartFiles = (dir) =>
  readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) return dartFiles(path);
    return entry.name.endsWith('.dart') ? [path] : [];
  });

test('the semantics tests compare the Tristate flags with Tristate.isTrue @CI-02-ASM-04', () => {
  const bare = ['test', 'integration_test'].flatMap((dir) =>
    dartFiles(join(mobile, dir)).flatMap((file) => {
      const text = readFileSync(file, 'utf8');
      return reads.flatMap((read) => [...text.matchAll(read)].map((match) => `${file}: ${match[0].replace(/\s+/g, ' ')}`));
    }),
  );
  assert.deepEqual(bare, []);
});

test('the tests that read a Tristate flag import it from dart:ui @CI-02-ASM-04', () => {
  const missing = ['test', 'integration_test'].flatMap((dir) =>
    dartFiles(join(mobile, dir)).filter((file) => {
      const text = readFileSync(file, 'utf8');
      return /Tristate\.isTrue/.test(text) && !/import 'dart:ui'[^;]*\bTristate\b/.test(text);
    }),
  );
  assert.deepEqual(missing, []);
});
