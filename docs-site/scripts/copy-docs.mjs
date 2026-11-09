// Builds docs-site/docs/ from the repo's .md files: the documentation lives in docs/, the READMEs and specs/,
// and the site only shows it. Links to another included document point to its page; links to any other
// file of the repo point to GitHub.
import { spawnSync } from 'node:child_process';
import { cpSync, copyFileSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join, posix, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const site = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const repo = resolve(site, '..');
const destination = join(site, 'docs');
const github = 'https://github.com/NahuelMosse/ClubNahuelMosse/blob/main/';

// [source in the repo, destination in docs/, position in its section]
const allPages = [
  ['README.md', 'intro.md', 1],
  ['docs/getting-started.md', 'getting-started.md', 2],
  ['docs/technical/architecture.md', 'technical/architecture.md', 1],
  ['docs/technical/data-model.md', 'technical/data-model.md', 2],
  ['docs/technical/app-navigation.md', 'technical/app-navigation.md', 3],
  ['docs/technical/code-map.md', 'technical/code-map.md', 4],
  ['docs/technical/system-design.md', 'technical/system-design.md', 5],
  ['docs/technical/runbook.md', 'technical/runbook.md', 6],
  ['docs/technical/infra-cost.md', 'technical/infra-cost.md', 7],
  ['docs/technical/integrations.md', 'technical/integrations.md', 8],
  ['docs/technical/glossary.md', 'technical/glossary.md', 9],
  ['apps/api/README.md', 'guides/api.md', 1],
  ['apps/mobile/README.md', 'guides/app.md', 2],
  ['docs/adr/0001-stack.md', 'decisions/0001-stack.md', 1],
  ['docs/adr/0002-hosting-on-render.md', 'decisions/0002-hosting-on-render.md', 2],
  ['docs/documentation-assumptions.md', 'product/documentation-assumptions.md', 4],
  ['docs/business/accessibility.md', 'product/accessibility.md', 1],
  ['specs/TRAZABILIDAD.md', 'product/traceability.md', 2],
  ['specs/REVISION-main.md', 'product/review.md', 3],
];

// A page whose source is missing (not merged yet) is skipped with a warning; it does not stop the build.
const pages = allPages.filter(([source]) => {
  if (existsSync(join(repo, source))) return true;
  console.warn(`warning: ${source} is missing, skipped`);
  return false;
});

const sections = {
  technical: ['Technical', 2],
  guides: ['Guides', 3],
  decisions: ['Decisions', 4],
  product: ['Product and quality', 5],
};

const bySource = new Map(pages.map(([source, page]) => [source, page]));

function rewriteLink(fromSource, fromPage, url) {
  if (/^([a-z]+:|#|\/)/i.test(url)) return url;
  const [path, anchor = ''] = url.split(/(?=#)/);
  const target = posix.normalize(posix.join(posix.dirname(fromSource), decodeURI(path)));
  const page = bySource.get(target);
  if (page) return posix.relative(posix.dirname(fromPage), page) + anchor;
  if (existsSync(join(repo, target))) return encodeURI(github + target) + anchor;
  return url;
}

rmSync(destination, { recursive: true, force: true });
for (const [source, page, position] of pages) {
  const text = readFileSync(join(repo, source), 'utf8').replace(
    /\]\(([^)\s]+)\)/g,
    (_, url) => `](${rewriteLink(source, page, url)})`,
  );
  const file = join(destination, page);
  mkdirSync(dirname(file), { recursive: true });
  const cover = page === 'intro.md' ? 'slug: /\n' : '';
  // The side menu already names the product: the title without " · ClubNahuelMosse".
  const title = (text.match(/^# (.+)$/m)?.[1] ?? '').replace(/ · ClubNahuelMosse$/, '');
  const label = page === 'intro.md' ? 'Home' : title;
  const header =
    `---\n${cover}sidebar_position: ${position}\nsidebar_label: ${JSON.stringify(label)}\n` +
    `custom_edit_url: ${github}${source}\n---\n\n`;
  writeFileSync(file, header + text);
}
// The API page, with Swagger UI inside the documentation.
writeFileSync(
  join(destination, 'api.mdx'),
  `---
sidebar_position: 6
sidebar_label: API (Swagger)
hide_table_of_contents: true
---

import Swagger from '@site/src/components/Swagger';

# API

Every API route, with its parameters, responses and errors. It comes from \`apps/api/openapi.json\`, the contract
that a test compares with the API. "Try it out" sends the request from the browser to the server chosen above.

<Swagger />
`,
);
for (const [folder, [label, position]] of Object.entries(sections)) {
  writeFileSync(
    join(destination, folder, '_category_.json'),
    JSON.stringify({ label, position }, null, 2),
  );
}
console.log(`${pages.length} pages in ${relative(repo, destination)}`);

// The API contract for Swagger UI, with the addresses it is tried against.
const contract = JSON.parse(readFileSync(join(repo, 'apps', 'api', 'openapi.json'), 'utf8'));
contract.servers = [
  { url: 'https://clubnahuelmosse-api.onrender.com', description: 'Render' },
  { url: 'http://localhost:8000', description: 'Local' },
];
mkdirSync(join(site, 'static'), { recursive: true });
writeFileSync(join(site, 'static', 'openapi.json'), JSON.stringify(contract));

// The project's design line: the tokens and the component set are served beside the site, which links them.
const design = join(site, 'static', 'design');
mkdirSync(design, { recursive: true });
copyFileSync(join(repo, 'design', 'tokens.css'), join(design, 'tokens.css'));
cpSync(join(repo, 'design', 'components'), join(design, 'components'), { recursive: true });

// Swagger UI already built (swagger-ui-dist), served as is: bundling it needs Node modules.
const swagger = join(site, 'static', 'swagger-ui');
mkdirSync(swagger, { recursive: true });
for (const file of ['swagger-ui.css', 'swagger-ui-bundle.js']) {
  copyFileSync(join(site, 'node_modules', 'swagger-ui-dist', file), join(swagger, file));
}
writeFileSync(
  join(swagger, 'index.html'),
  `<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>API · ClubNahuelMosse</title>
<link rel="stylesheet" href="/design/tokens.css">
<link rel="stylesheet" href="/swagger-ui/swagger-ui.css">
<style>
  body { margin: 0; background: transparent; }
  /* The title and the description are already in the documentation page. */
  .swagger-ui .info { display: none; }
  .swagger-ui .scheme-container { padding: 0 0 var(--space-4); box-shadow: none; background: transparent; }
  .swagger-ui .wrapper { padding: 0; }
  /* Swagger UI has no dark mode: with the site's dark theme it is inverted, leaving the method colors alone. */
  body.dark { background: var(--bg); }
  body.dark .swagger-ui { filter: invert(0.92) hue-rotate(180deg); }
</style></head>
<body><div id="swagger"></div>
<script src="/swagger-ui/swagger-ui-bundle.js"></script>
<script>
  SwaggerUIBundle({ url: '/openapi.json', dom_id: '#swagger', deepLinking: false, docExpansion: 'list' });
  // Follows the light or dark theme of the page that contains it.
  const root = window.parent.document.documentElement;
  const theme = () => {
    document.documentElement.dataset.theme = root.dataset.theme;
    document.body.classList.toggle('dark', root.dataset.theme === 'dark');
  };
  theme();
  new MutationObserver(theme).observe(root, { attributes: true, attributeFilter: ['data-theme'] });
</script>
</body></html>
`,
);

// The code reference comes from the API docstrings (scripts/docstrings.py).
const python = ['python3', 'python'].find((p) => spawnSync(p, ['--version']).status === 0);
if (!python) throw new Error('Python 3 is needed to generate the code reference');
const generated = spawnSync(python, [join(site, 'scripts', 'docstrings.py')], { stdio: 'inherit' });
if (generated.status !== 0) process.exit(generated.status ?? 1);
