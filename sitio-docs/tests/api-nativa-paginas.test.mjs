// Reemplaza la prueba de páginas por operación de api-nativa.test.mjs: el generador nombra los
// archivos por el resumen y la ruta de cada operación, no por su operationId.
import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const sitio = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const contrato = JSON.parse(readFileSync(join(sitio, '..', 'apps', 'api', 'openapi.json'), 'utf8'));

function archivos(dir) {
  if (!existsSync(dir)) return [];
  return readdirSync(dir).flatMap((nombre) => {
    const ruta = join(dir, nombre);
    return statSync(ruta).isDirectory() ? archivos(ruta) : [ruta];
  });
}

const operaciones = Object.values(contrato.paths).flatMap((ruta) => Object.values(ruta));
const mdx = archivos(join(sitio, 'docs', 'api')).filter((a) => a.endsWith('.api.mdx'));
const hayBuild = existsSync(join(sitio, 'build', 'api'));

test('la referencia de la API son páginas del sitio generadas del contrato, una por operación @DOC-04-S1', () => {
  assert.ok(operaciones.length > 0);
  assert.equal(mdx.length, operaciones.length, 'una página por operación en docs/api (npm run build)');
  const titulos = mdx.map((a) => readFileSync(a, 'utf8').match(/^title: (.+)$/m)?.[1]);
  for (const op of operaciones) {
    assert.ok(titulos.includes(JSON.stringify(op.summary)), `falta la página de «${op.summary}»`);
  }
  if (hayBuild) {
    const paginas = readdirSync(join(sitio, 'build', 'api')).filter((n) =>
      existsSync(join(sitio, 'build', 'api', n, 'index.html')),
    );
    assert.ok(paginas.length >= operaciones.length, 'faltan páginas de operaciones en build/api');
  }
  const config = readFileSync(join(sitio, 'docusaurus.config.js'), 'utf8');
  assert.match(config, /docusaurus-plugin-openapi-docs/);
  assert.match(config, /docusaurus-theme-openapi-docs/);
  assert.match(config, /@theme\/ApiItem/);
});
