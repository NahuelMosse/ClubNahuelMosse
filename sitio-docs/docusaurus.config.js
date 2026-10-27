import { themes as prismThemes } from 'prism-react-renderer';

/** @type {import('@docusaurus/types').Config} */
export default {
  title: 'ClubNahuelMosse',
  tagline: 'Documentación de la app de reservas de espacios deportivos',
  url: 'https://nahuelmosse.github.io',
  baseUrl: '/',
  onBrokenLinks: 'warn',
  markdown: {
    // Los .md se leen como Markdown común y no como MDX: los documentos traen `<`, `{` y tablas.
    format: 'detect',
    mermaid: true,
    hooks: { onBrokenMarkdownLinks: 'warn' },
  },
  i18n: { defaultLocale: 'es', locales: ['es'] },
  clientModules: ['./src/clientModules/zoom-de-diagramas.js'],
  presets: [
    [
      'classic',
      {
        docs: {
          routeBasePath: '/',
          sidebarPath: './sidebars.js',
        },
        blog: false,
        theme: { customCss: './src/css/custom.css' },
      },
    ],
    [
      'redocusaurus',
      {
        // static/openapi.json lo arma scripts/copiar.mjs desde apps/api/openapi.json, con las direcciones de la API.
        specs: [{ id: 'api', spec: 'static/openapi.json', route: '/api' }],
        theme: { primaryColor: '#4d6600' },
      },
    ],
  ],
  themes: [
    '@docusaurus/theme-mermaid',
    [
      '@easyops-cn/docusaurus-search-local',
      { hashed: true, language: ['es'], docsRouteBasePath: '/', indexBlog: false },
    ],
  ],
  themeConfig: {
    colorMode: { defaultMode: 'dark', respectPrefersColorScheme: true },
    navbar: {
      title: 'ClubNahuelMosse',
      items: [{ to: '/api', label: 'API', position: 'left' }],
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'dart', 'python', 'powershell', 'yaml', 'json'],
    },
  },
};
