import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const site = join(dirname(fileURLToPath(import.meta.url)), '..');

test("the site's home page shows the README's logo and screenshots under its own title @assumption:ENG-21-ASM-09", () => {
  const copied = spawnSync('node', [join(site, 'scripts', 'copy-docs.mjs')], { encoding: 'utf8' });
  assert.equal(copied.status, 0, copied.stderr);

  const home = readFileSync(join(site, 'docs', 'intro.md'), 'utf8');
  assert.match(home, /^title: "?ClubNahuelMosse"?$/m);

  const sources = [...home.matchAll(/<img src="([^"]+)"/g)].map((match) => match[1]);
  assert.equal(sources.length, 5, 'the logo and four screenshots');
  for (const source of sources) {
    assert.match(source, /^\//, `${source} is a site path`);
    assert.ok(existsSync(join(site, 'static', source)), `${source} is copied to static/`);
  }
});
