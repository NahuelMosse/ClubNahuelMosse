// Arma sitio-docs/docs/ con los .md del repo: la documentación vive en docs/, los README y specs/,
// y el sitio sólo la muestra. Los enlaces a otro documento incluido apuntan a su página; los que
// apuntan a otro archivo del repo, a GitHub.
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join, posix, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const sitio = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const repo = resolve(sitio, '..');
const destino = join(sitio, 'docs');
const github = 'https://github.com/NahuelMosse/ClubNahuelMosse/blob/main/';

// [origen en el repo, destino en docs/, posición en su sección]
const paginas = [
  ['README.md', 'intro.md', 1],
  ['docs/guia-basica.md', 'guia-basica.md', 2],
  ['docs/technical/arquitectura.md', 'tecnica/arquitectura.md', 1],
  ['docs/technical/mapa-del-codigo.md', 'tecnica/mapa-del-codigo.md', 2],
  ['docs/technical/system-design.md', 'tecnica/system-design.md', 3],
  ['docs/technical/runbook.md', 'tecnica/runbook.md', 4],
  ['docs/technical/infra-cost.md', 'tecnica/infra-cost.md', 5],
  ['apps/api/README.md', 'guias/api.md', 1],
  ['apps/mobile/README.md', 'guias/app.md', 2],
  ['docs/adr/0001-stack.md', 'decisiones/0001-stack.md', 1],
  ['docs/adr/0002-hosting-en-render.md', 'decisiones/0002-hosting-en-render.md', 2],
  ['docs/business/accessibility.md', 'producto/accesibilidad.md', 1],
  ['specs/TRAZABILIDAD.md', 'producto/trazabilidad.md', 2],
  ['specs/REVISION-main.md', 'producto/revision.md', 3],
];

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
for (const [carpeta, [etiqueta, posicion]] of Object.entries(secciones)) {
  writeFileSync(
    join(destino, carpeta, '_category_.json'),
    JSON.stringify({ label: etiqueta, position: posicion }, null, 2),
  );
}
console.log(`${paginas.length} páginas en ${relative(repo, destino)}`);

// La referencia del código sale de los docstrings de la API (scripts/docstrings.py).
const python = ['python3', 'python'].find((p) => spawnSync(p, ['--version']).status === 0);
if (!python) throw new Error('hace falta Python 3 para generar la referencia del código');
const generado = spawnSync(python, [join(sitio, 'scripts', 'docstrings.py')], { stdio: 'inherit' });
if (generado.status !== 0) process.exit(generado.status ?? 1);
