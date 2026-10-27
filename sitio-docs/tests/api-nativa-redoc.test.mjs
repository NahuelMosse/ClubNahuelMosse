// La referencia de la API es una página del sitio generada de apps/api/openapi.json con Redoc
// integrado al tema (redocusaurus); reemplaza las pruebas de páginas por operación.
import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const sitio = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const leer = (...ruta) => readFileSync(join(sitio, ...ruta), 'utf8');
const contrato = JSON.parse(leer('..', 'apps', 'api', 'openapi.json'));
const paginaApi = join(sitio, 'build', 'api', 'index.html');
const config = leer('docusaurus.config.js');

test('la referencia de la API es una página nativa del sitio generada del contrato, con el tema del sitio @DOC-04-S1', () => {
  assert.match(config, /redocusaurus/);
  assert.match(config, /route: '\/api'/);
  assert.match(config, /primaryColor: '#4d6600'/);
  assert.match(config, /to: '\/api'/);
  if (!existsSync(paginaApi)) return;
  const html = readFileSync(paginaApi, 'utf8');
  assert.match(html, /class="navbar/, 'la página lleva la barra del sitio');
  for (const ruta of Object.values(contrato.paths)) {
    for (const op of Object.values(ruta)) {
      assert.ok(html.includes(op.summary.replaceAll('&', '&amp;')) || html.includes(op.summary), `falta «${op.summary}»`);
    }
  }
});

test('el sitio no tiene iframe ni Swagger UI incrustado @DOC-04-S2', () => {
  assert.equal(existsSync(join(sitio, 'src', 'components', 'Swagger.js')), false);
  assert.doesNotMatch(leer('package.json'), /swagger-ui-dist/);
  assert.doesNotMatch(leer('scripts', 'copiar.mjs'), /swagger-ui/);
  if (!existsSync(paginaApi)) return;
  const html = readFileSync(paginaApi, 'utf8');
  assert.doesNotMatch(html, /<iframe/i);
  assert.doesNotMatch(html, /swagger-ui/i);
});

test('el contrato del sitio trae la dirección de la API desplegada @assumption:DOC-04-ASM-01', () => {
  assert.match(leer('scripts', 'copiar.mjs'), /https:\/\/clubnahuelmosse-api\.onrender\.com/);
  const rutaCopia = join(sitio, 'static', 'openapi.json');
  assert.ok(existsSync(rutaCopia), 'falta la copia del contrato (npm run copiar)');
  const copia = JSON.parse(readFileSync(rutaCopia, 'utf8'));
  assert.equal(copia.servers[0].url, 'https://clubnahuelmosse-api.onrender.com');
});

test('si el generador de una página por operación no compila, la referencia es Redoc integrado al tema @assumption:DOC-04-ASM-03', () => {
  assert.doesNotMatch(config, /docusaurus-plugin-openapi-docs/);
  assert.match(leer('package.json'), /"redocusaurus"/);
});

test('integraciones.md está en la sección técnica del sitio @assumption:DOC-04-ASM-02', () => {
  assert.match(leer('scripts', 'copiar.mjs'), /'docs\/technical\/integraciones\.md', 'tecnica\/integraciones\.md'/);
  assert.ok(existsSync(join(sitio, 'docs', 'tecnica', 'integraciones.md')), 'falta docs/tecnica/integraciones.md');
});
