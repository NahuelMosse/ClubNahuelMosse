// The Flutter the CI installs, the SDK floor of the app and the docs that name it agree.
import { readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const repo = resolve(import.meta.dirname, '..');
const read = (...path) => readFileSync(join(repo, ...path), 'utf8');
const workflow = read('.github', 'workflows', 'ci.yml');
const pubspec = read('apps', 'mobile', 'pubspec.yaml');
const lock = read('apps', 'mobile', 'pubspec.lock');

const flutterVersion = workflow.match(/flutter-version:\s*([\d.]+)/)?.[1] ?? '';
const parts = (version) => version.split('.').map(Number);
const atLeast = (version, floor) => {
  const [a, b] = [parts(version), parts(floor)];
  const i = a.findIndex((n, k) => n !== b[k]);
  return i === -1 || a[i] > b[i];
};

test('the app job installs a Flutter whose Dart is 3.11 or more @CI-02-S1', () => {
  assert.ok(flutterVersion, 'ci.yml pins no flutter-version');
  // 3.41.2 is the first stable release that ships Dart 3.11.0.
  assert.ok(atLeast(flutterVersion, '3.41.2'), `Flutter ${flutterVersion} ships a Dart older than 3.11`);
});

test('the app job installs the latest 3.41 Flutter @CI-02-ASM-01', () => {
  assert.equal(flutterVersion, '3.41.9');
});

test('the SDK floor of the app is Dart 3.11.0 and the lock agrees @CI-02-ASM-02', () => {
  assert.match(pubspec, /^ {2}sdk: \^3\.11\.0$/m);
  assert.match(lock, /^ {2}dart: ">=3\.11\.0 <4\.0\.0"$/m);
});

test('the current docs name the Dart of the app SDK floor @CI-02-ASM-03', () => {
  assert.match(read('apps', 'mobile', 'README.md'), /Dart `\^3\.11\.0`/);
  assert.match(read('docs', 'technical', 'architecture.md'), /Flutter \(Dart 3\.11\)/);
  assert.match(read('docs', 'technical', 'system-design.md'), /Flutter, Dart \^3\.11\.0, Android only/);
});
