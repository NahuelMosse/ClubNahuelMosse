// Prueba las páginas de la API generadas del contrato. Necesita `npm run copiar` y
// `docusaurus gen-api-docs all` (los hace `npm run build`); si el build existe también mira su HTML.
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

const operaciones = Object.values(contrato.paths).flatMap((ruta) =>
  Object.values(ruta).map((op) => op.operationId),
);
const mdx = archivos(join(sitio, 'docs', 'api')).filter((a) => a.endsWith('.api.mdx'));
const html = archivos(join(sitio, 'build', 'api')).filter((a) => a.endsWith('.html'));
const hayBuild = html.length > 0;
const slug = (id) => id.replaceAll('_', '-');

test('la referencia de la API son páginas del sitio generadas del contrato, una por operación @DOC-04-S1', () => {
  assert.ok(operaciones.length > 0);
  for (const id of operaciones) {
    const hojas = mdx.filter((a) => a.includes(slug(id)));
    assert.equal(hojas.length, 1, `falta la página de ${id} en docs/api`);
    if (hayBuild) {
      assert.ok(html.some((a) => a.includes(slug(id))), `falta ${id} en build/api`);
    }
  }
  const config = readFileSync(join(sitio, 'docusaurus.config.js'), 'utf8');
  assert.match(config, /docusaurus-plugin-openapi-docs/);
  assert.match(config, /docusaurus-theme-openapi-docs/);
  assert.match(config, /@theme\/ApiItem/);
});

test('el sitio no tiene iframe ni Swagger UI incrustado @DOC-04-S2', () => {
  assert.equal(existsSync(join(sitio, 'src', 'components', 'Swagger.js')), false);
  const paquete = readFileSync(join(sitio, 'package.json'), 'utf8');
  assert.doesNotMatch(paquete, /swagger-ui-dist/);
  const copiar = readFileSync(join(sitio, 'scripts', 'copiar.mjs'), 'utf8');
  assert.doesNotMatch(copiar, /swagger-ui/);
  for (const pagina of [...mdx, ...html]) {
    const texto = readFileSync(pagina, 'utf8');
    assert.doesNotMatch(texto, /<iframe/i, pagina);
    assert.doesNotMatch(texto, /swagger-ui/i, pagina);
  }
});

test('cada operación se puede probar contra la API desplegada @assumption:DOC-04-ASM-01', () => {
  const copiar = readFileSync(join(sitio, 'scripts', 'copiar.mjs'), 'utf8');
  assert.match(copiar, /https:\/\/clubnahuelmosse-api\.onrender\.com/);
  const generadas = mdx.filter((a) => a.includes(slug(operaciones[0])));
  assert.equal(generadas.length, 1);
  // El panel «Send API Request» y la dirección del servidor van en la página; el tema los arma desde el contrato.
  assert.match(readFileSync(generadas[0], 'utf8'), /ApiItem|api:/);
  const contratoCopiado = join(sitio, 'static', 'openapi.json');
  assert.ok(existsSync(contratoCopiado), 'falta la copia del contrato (npm run copiar)');
  const copia = JSON.parse(readFileSync(contratoCopiado, 'utf8'));
  assert.equal(copia.servers[0].url, 'https://clubnahuelmosse-api.onrender.com');
});

test('integraciones.md está en la sección técnica del sitio @assumption:DOC-04-ASM-02', () => {
  const copiar = readFileSync(join(sitio, 'scripts', 'copiar.mjs'), 'utf8');
  assert.match(copiar, /'docs\/technical\/integraciones\.md', 'tecnica\/integraciones\.md'/);
  assert.ok(existsSync(join(sitio, 'docs', 'tecnica', 'integraciones.md')), 'falta docs/tecnica/integraciones.md');
});
