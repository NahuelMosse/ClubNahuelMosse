import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const copiar = readFileSync(new URL('../scripts/copiar.mjs', import.meta.url), 'utf8');

test('el sitio arma la página de integraciones en la sección técnica @DOC-08-S1', () => {
  assert.match(copiar, /\['docs\/technical\/integraciones\.md', 'tecnica\/integraciones\.md', 8\]/);
});
