// Arma sitio-docs/docs/ con los .md del repo: la documentación vive en docs/, los README y specs/,
// y el sitio sólo la muestra. Los enlaces a otro documento incluido apuntan a su página; los que
// apuntan a otro archivo del repo, a GitHub.
import { spawnSync } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join, posix, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const sitio = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const repo = resolve(sitio, '..');
const destino = join(sitio, 'docs');
const github = 'https://github.com/NahuelMosse/ClubNahuelMosse/blob/main/';

// [origen en el repo, destino en docs/, posición en su sección]
const todas = [
  ['README.md', 'intro.md', 1],
  ['docs/guia-basica.md', 'guia-basica.md', 2],
  ['docs/technical/arquitectura.md', 'tecnica/arquitectura.md', 1],
  ['docs/technical/modelo-de-datos.md', 'tecnica/modelo-de-datos.md', 2],
  ['docs/technical/navegacion-de-la-app.md', 'tecnica/navegacion-de-la-app.md', 3],
  ['docs/technical/mapa-del-codigo.md', 'tecnica/mapa-del-codigo.md', 4],
  ['docs/technical/system-design.md', 'tecnica/system-design.md', 5],
  ['docs/technical/runbook.md', 'tecnica/runbook.md', 6],
  ['docs/technical/infra-cost.md', 'tecnica/infra-cost.md', 7],
  ['apps/api/README.md', 'guias/api.md', 1],
  ['apps/mobile/README.md', 'guias/app.md', 2],
  ['docs/adr/0001-stack.md', 'decisiones/0001-stack.md', 1],
  ['docs/adr/0002-hosting-en-render.md', 'decisiones/0002-hosting-en-render.md', 2],
  ['docs/business/accessibility.md', 'producto/accesibilidad.md', 1],
  ['specs/TRAZABILIDAD.md', 'producto/trazabilidad.md', 2],
  ['specs/REVISION-main.md', 'producto/revision.md', 3],
];

// Una página cuyo origen falta (todavía no se fusionó) se omite con un aviso, no frena el armado.
const paginas = todas.filter(([origen]) => {
  if (existsSync(join(repo, origen))) return true;
  console.warn(`aviso: falta ${origen}, se omite`);
  return false;
});

const secciones = {
  tecnica: ['Técnica', 2],
  guias: ['Guías', 3],
  decisiones: ['Decisiones', 4],
  producto: ['Producto y calidad', 5],
};

const porOrigen = new Map(paginas.map(([origen, dest]) => [origen, dest]));

function enlace(desdeOrigen, desdeDestino, url) {
  if (/^([a-z]+:|#|\/)/i.test(url)) return url;
  const [ruta, ancla = ''] = url.split(/(?=#)/);
  const objetivo = posix.normalize(posix.join(posix.dirname(desdeOrigen), decodeURI(ruta)));
  const pagina = porOrigen.get(objetivo);
  if (pagina) return posix.relative(posix.dirname(desdeDestino), pagina) + ancla;
  if (existsSync(join(repo, objetivo))) return encodeURI(github + objetivo) + ancla;
  return url;
}

rmSync(destino, { recursive: true, force: true });
for (const [origen, dest, posicion] of paginas) {
  const texto = readFileSync(join(repo, origen), 'utf8').replace(
    /\]\(([^)\s]+)\)/g,
    (_, url) => `](${enlace(origen, dest, url)})`,
  );
  const archivo = join(destino, dest);
  mkdirSync(dirname(archivo), { recursive: true });
  const portada = dest === 'intro.md' ? 'slug: /\n' : '';
  // El menú lateral ya dice de qué producto es: el título sin « · ClubNahuelMosse».
  const titulo = (texto.match(/^# (.+)$/m)?.[1] ?? '').replace(/ · ClubNahuelMosse$/, '');
  const etiqueta = dest === 'intro.md' ? 'Inicio' : titulo;
  const cabecera =
    `---\n${portada}sidebar_position: ${posicion}\nsidebar_label: ${JSON.stringify(etiqueta)}\n` +
    `custom_edit_url: ${github}${origen}\n---\n\n`;
  writeFileSync(archivo, cabecera + texto);
}
// La página de la API, con Swagger UI dentro de la documentación.
writeFileSync(
  join(destino, 'api.mdx'),
  `---
sidebar_position: 6
sidebar_label: API (Swagger)
hide_table_of_contents: true
---

import Swagger from '@site/src/components/Swagger';

# API

Cada ruta de la API, con sus parámetros, sus respuestas y sus errores. Sale de \`apps/api/openapi.json\`, el contrato
que un test compara con la API. «Try it out» manda el pedido desde el navegador al servidor elegido arriba.

<Swagger />
`,
);
for (const [carpeta, [etiqueta, posicion]] of Object.entries(secciones)) {
  writeFileSync(
    join(destino, carpeta, '_category_.json'),
    JSON.stringify({ label: etiqueta, position: posicion }, null, 2),
  );
}
console.log(`${paginas.length} páginas en ${relative(repo, destino)}`);

// El contrato de la API para Swagger UI, con las direcciones contra las que se prueba.
const contrato = JSON.parse(readFileSync(join(repo, 'apps', 'api', 'openapi.json'), 'utf8'));
contrato.servers = [
  { url: 'https://clubnahuelmosse-api.onrender.com', description: 'Render' },
  { url: 'http://localhost:8000', description: 'Local' },
];
mkdirSync(join(sitio, 'static'), { recursive: true });
writeFileSync(join(sitio, 'static', 'openapi.json'), JSON.stringify(contrato));

// Swagger UI ya armado (swagger-ui-dist), servido tal cual: empaquetarlo pide módulos de Node.
const swagger = join(sitio, 'static', 'swagger-ui');
mkdirSync(swagger, { recursive: true });
for (const archivo of ['swagger-ui.css', 'swagger-ui-bundle.js']) {
  copyFileSync(join(sitio, 'node_modules', 'swagger-ui-dist', archivo), join(swagger, archivo));
}
writeFileSync(
  join(swagger, 'index.html'),
  `<!doctype html>
<html lang="es">
<head><meta charset="utf-8"><title>API · ClubNahuelMosse</title>
<link rel="stylesheet" href="/swagger-ui/swagger-ui.css">
<style>
  body { margin: 0; background: transparent; }
  /* El título y la descripción ya están en la página de la documentación. */
  .swagger-ui .info { display: none; }
  .swagger-ui .scheme-container { padding: 0 0 16px; box-shadow: none; background: transparent; }
  .swagger-ui .wrapper { padding: 0; }
  /* Swagger UI no trae modo oscuro: con el tema oscuro del sitio se invierte, sin tocar los colores de los métodos. */
  body.oscuro { background: #0a0a0b; }
  body.oscuro .swagger-ui { filter: invert(0.92) hue-rotate(180deg); }
</style></head>
<body><div id="swagger"></div>
<script src="/swagger-ui/swagger-ui-bundle.js"></script>
<script>
  SwaggerUIBundle({ url: '/openapi.json', dom_id: '#swagger', deepLinking: false, docExpansion: 'list' });
  // Sigue el tema claro u oscuro de la página que lo contiene.
  const raiz = window.parent.document.documentElement;
  const tema = () => document.body.classList.toggle('oscuro', raiz.dataset.theme === 'dark');
  tema();
  new MutationObserver(tema).observe(raiz, { attributes: true, attributeFilter: ['data-theme'] });
</script>
</body></html>
`,
);

// La referencia del código sale de los docstrings de la API (scripts/docstrings.py).
const python = ['python3', 'python'].find((p) => spawnSync(p, ['--version']).status === 0);
if (!python) throw new Error('hace falta Python 3 para generar la referencia del código');
const generado = spawnSync(python, [join(sitio, 'scripts', 'docstrings.py')], { stdio: 'inherit' });
if (generado.status !== 0) process.exit(generado.status ?? 1);
