import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const copyDocs = readFileSync(new URL('../scripts/copy-docs.mjs', import.meta.url), 'utf8');

test('el sitio arma la página de integraciones en la sección técnica @DOC-08-S1', () => {
  assert.match(copyDocs, /\['docs\/technical\/integrations\.md', 'technical\/integrations\.md', 8\]/);
});
