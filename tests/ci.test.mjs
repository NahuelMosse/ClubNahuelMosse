// The GitHub Actions workflow runs every check of the repo, and its pytest and flutter test verdicts follow the gate's rule
// for replaced tests.
import { spawnSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const repo = resolve(import.meta.dirname, '..');
const workflow = readFileSync(join(repo, '.github', 'workflows', 'ci.yml'), 'utf8');
const job = (name) => workflow.split(/^ {2}(?=\w[\w-]*:\s*$)/m).find((block) => block.startsWith(`${name}:`)) ?? '';

const run = (runner, output, code, cwd = repo) => {
  const dir = mkdtempSync(join(tmpdir(), 'ci-verdict-'));
  const file = join(dir, `${runner}.log`);
  writeFileSync(file, output);
  return spawnSync(process.execPath, [join(repo, 'scripts', 'ci-test-verdict.mjs'), runner, file, String(code)], { cwd, encoding: 'utf8' });
};
const verdict = (output, code, cwd) => run('pytest', output, code, cwd);
const flutter = (output, code, cwd) => run('flutter', output, code, cwd);
// A repo of its own, with one card whose Log declares the given lines and the given files written.
const fixture = (log, files = {}) => {
  const root = mkdtempSync(join(tmpdir(), 'ci-repo-'));
  const write = (path, text) => {
    mkdirSync(dirname(join(root, path)), { recursive: true });
    writeFileSync(join(root, path), text);
  };
  write('specs/X-01-card/card.md', `# X-01\n\n## Log\n\n${log.map((l, i) => `- L${i + 1} · 2026-11-09 · ${l}`).join('\n')}\n`);
  for (const [path, text] of Object.entries(files)) write(path, text);
  return root;
};
const REPLACED = 'FAILED tests/integracion/test_contract_in_english.py::test_a_void_error_names_reason_in_english - AssertionError';
const NOT_REPLACED = 'FAILED tests/escenarios/test_basquet.py::test_el_catalogo_ofrece_basquet_con_su_tipo - AssertionError';
// flutter test names each file by its absolute path, with forward slashes also on Windows.
const slash = (p) => p.split('\\').join('/');
const MOBILE = `${slash(repo)}/apps/mobile/test`;
const FL_REPLACED = `00:40 +115 -1: ${MOBILE}/bilingual_account_test.dart: the home shows English @ENG-19-S1 [E]`;
const FL_NOT_REPLACED = `00:41 +116 -2: ${MOBILE}/baja_sede_test.dart: desde la edición: confirma, avisa y vuelve al listado sin la sede [E]`;
const FL_UNLOADED = `00:00 +0 -1: loading ${MOBILE}/notificaciones_test.dart [E]`;
const FL_UNLOADED_UNDECLARED = `00:00 +0 -1: loading ${MOBILE}/baja_sede_test.dart [E]`;
const SOME_FAILED = 'Some tests failed.';
const OLD_TITLE = 'el socio reserva @X-01-S1';
const OLD_PY = 'tests/test_old.py';
const NEW_PY = 'tests/test_new.py';
const PY_REPLACES = `replaces: apps/api/${OLD_PY} "${OLD_TITLE}" · the contract changed · by: apps/api/${NEW_PY} "${OLD_TITLE}"`;
const pyTest = (fn, docstring) => `def ${fn}() -> None:\n    """${docstring}"""\n    assert True\n`;
const PY_FAILED = (file, fn) => `FAILED ${file}::${fn} - AssertionError\n1 failed, 10 passed in 3.00s\n`;

test('the workflow runs on every pull request and on every push to main and deploys nothing @CI-01-S1 @assumption:CI-01-ASM-04', () => {
  assert.match(workflow, /^on:\s*\n\s+pull_request:\s*\n\s+push:\s*\n\s+branches: \[main\]/m);
  assert.doesNotMatch(workflow, /deploy|render\.com|RENDER_|secrets\./i);
});

test('the API job runs ruff, mypy and the whole pytest on Python 3.13 against Postgres 18 and the Auth emulator on Node 24 and Java 21 @CI-01-S1 @assumption:CI-01-ASM-03', () => {
  const api = job('api');
  assert.match(api, /python-version: "3\.13"/);
  assert.match(api, /node-version: 24/);
  assert.match(api, /java-version: 21/);
  assert.match(api, /image: postgres:18-alpine/);
  assert.match(api, /firebase emulators:start --only auth/);
  assert.match(api, /FIREBASE_AUTH_EMULATOR_HOST: 127\.0\.0\.1:9099/);
  assert.match(api, /uv run ruff check \./);
  assert.match(api, /uv run mypy app/);
  assert.match(api, /uv run pytest -q -p no:cacheprovider\)/);
  assert.match(api, /node scripts\/ci-test-verdict\.mjs pytest pytest\.log "\$code"/);
});

test('the app job runs flutter analyze, the format check and flutter test judged by the replaced tests rule @CI-01-S1 @assumption:CI-01-ASM-03', () => {
  const mobile = job('mobile');
  assert.match(mobile, /flutter-version: 3\.35\.3/);
  assert.match(mobile, /run: flutter analyze/);
  assert.match(mobile, /run: dart format --output=none --set-exit-if-changed lib\n/);
  assert.match(mobile, /flutter test --reporter expanded > \.\.\/\.\.\/flutter\.log/);
  assert.match(mobile, /node scripts\/ci-test-verdict\.mjs flutter flutter\.log "\$code"/);
});

test('scripts/test.sh checks the format of lib only, like the CI @CI-01-S1 @assumption:CI-01-ASM-03', () => {
  const local = readFileSync(join(repo, 'scripts', 'test.sh'), 'utf8');
  assert.match(local, /dart format --output=none --set-exit-if-changed lib\n/);
});

test('the node job runs the repo tests and the docs site tests @CI-01-S1', () => {
  assert.match(job('node'), /run: node --test tests\/\*\.test\.mjs sitio-docs\/tests\/\*\.test\.mjs/);
});

test('pytest is green when every failing test is declared replaced and its replacement exists @CI-01-S1 @assumption:CI-01-ASM-01', () => {
  const ok = verdict(`${REPLACED}\n1 failed, 10 passed in 3.00s\n`, 1);
  assert.equal(ok.status, 0, ok.stderr);
  assert.match(ok.stdout, /1 replaced tests failing/);
});

test('pytest is red when a failing test is not declared replaced @CI-01-S1 @assumption:CI-01-ASM-01', () => {
  const red = verdict(`${REPLACED}\n${NOT_REPLACED}\n2 failed, 10 passed in 3.00s\n`, 1);
  assert.equal(red.status, 1);
  assert.match(red.stderr, /no card declares replaced/);
});

test('pytest is red when the replacement of a failing test is missing, lacks its tags or fails too @CI-01-S1 @assumption:CI-01-ASM-01', () => {
  const old = { [`apps/api/${OLD_PY}`]: pyTest('test_old', OLD_TITLE) };
  const holds = fixture([PY_REPLACES], { ...old, [`apps/api/${NEW_PY}`]: pyTest('test_new', OLD_TITLE) });
  assert.equal(verdict(PY_FAILED(`apps/api/${OLD_PY}`, 'test_old'), 1, holds).status, 0);
  const missing = fixture([PY_REPLACES], old);
  assert.equal(verdict(PY_FAILED(`apps/api/${OLD_PY}`, 'test_old'), 1, missing).status, 1);
  const untagged = fixture([PY_REPLACES.replace(/by: (\S+) "[^"]+"/, 'by: $1 "el socio reserva"')], { ...old, [`apps/api/${NEW_PY}`]: pyTest('test_new', 'el socio reserva') });
  assert.equal(verdict(PY_FAILED(`apps/api/${OLD_PY}`, 'test_old'), 1, untagged).status, 1);
  const both = `FAILED apps/api/${OLD_PY}::test_old - AssertionError\nFAILED apps/api/${NEW_PY}::test_new - AssertionError\n2 failed, 10 passed in 3.00s\n`;
  assert.equal(verdict(both, 1, holds).status, 1);
});

test('pytest is red on a collection error or any exit other than failed tests @CI-01-S1 @assumption:CI-01-ASM-01', () => {
  assert.equal(verdict(`${REPLACED}\n1 failed, 10 passed, 1 error in 3.00s\n`, 1).status, 1);
  assert.equal(verdict('no tests ran in 0.10s\n', 2).status, 1);
  assert.equal(verdict('10 passed in 3.00s\n', 0).status, 0);
  // A call without the runner, the file or the exit code is a usage error of the workflow, not a test verdict.
  assert.equal(spawnSync(process.execPath, [join(repo, 'scripts', 'ci-test-verdict.mjs'), 'pytest'], { encoding: 'utf8' }).status, 2);
});

test('flutter test is green when every failing test and every file that no longer compiles is declared replaced @CI-01-S1 @assumption:CI-01-ASM-01', () => {
  const ok = flutter(`${FL_UNLOADED}\n${FL_REPLACED}\n${SOME_FAILED}\n`, 1);
  assert.equal(ok.status, 0, ok.stderr);
  assert.match(ok.stdout, /1 replaced tests failing/);
  assert.match(ok.stdout, /1 files that no longer compile, replaced/);
  assert.equal(flutter(`${FL_UNLOADED}\n${SOME_FAILED}\n`, 1).status, 0);
});

test('flutter test is red when a failing test or a file that does not load is not declared replaced @CI-01-S1 @assumption:CI-01-ASM-01', () => {
  assert.equal(flutter(`${FL_REPLACED}\n${FL_NOT_REPLACED}\n${SOME_FAILED}\n`, 1).status, 1);
  const unloaded = flutter(`${FL_UNLOADED_UNDECLARED}\n${SOME_FAILED}\n`, 1);
  assert.equal(unloaded.status, 1);
  assert.match(unloaded.stderr, /could not load apps\/mobile\/test\/baja_sede_test\.dart/);
  assert.equal(flutter(`${SOME_FAILED}\n`, 1).status, 1);
  assert.equal(flutter('', 69).status, 1);
});

test('flutter test is red when a file that no longer compiles is declared replaced by a copy that does not exist @CI-01-S1 @assumption:CI-01-ASM-01', () => {
  const log = ['replaces: apps/mobile/test/old_test.dart "el socio reserva @X-01-S1" · the file no longer compiles · by: apps/mobile/test/old_copy_test.dart "el socio reserva @X-01-S1"'];
  const old = { 'apps/mobile/test/old_test.dart': "void main() {}\n" };
  const line = (root) => `00:00 +0 -1: loading ${slash(root)}/apps/mobile/test/old_test.dart [E]\n${SOME_FAILED}\n`;
  const copied = fixture(log, { ...old, 'apps/mobile/test/old_copy_test.dart': "void main() {}\n" });
  assert.equal(flutter(line(copied), 1, copied).status, 0);
  const gone = fixture(log, old);
  const red = flutter(line(gone), 1, gone);
  assert.equal(red.status, 1);
  assert.match(red.stderr, /could not load apps\/mobile\/test\/old_test\.dart/);
  // Earlier cards name the app's tests from apps/mobile: `test/x_test.dart`.
  const short = fixture([log[0].replaceAll('apps/mobile/test/', 'test/')], { ...old, 'apps/mobile/test/old_copy_test.dart': "void main() {}\n" });
  assert.equal(flutter(line(short), 1, short).status, 0);
});
