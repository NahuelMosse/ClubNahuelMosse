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
        // El contrato versionado de la API, el mismo que publica /openapi.json.
        specs: [{ id: 'api', spec: '../apps/api/openapi.json', route: '/referencia-api/' }],
        theme: { primaryColor: '#4d6600', primaryColorDark: '#d4ff3d' },
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
      items: [
        { to: '/referencia-api/', label: 'Referencia de la API', position: 'left' },
        { to: '/codigo/interfaz', label: 'Referencia del código', position: 'left' },
        { href: 'https://github.com/NahuelMosse/ClubNahuelMosse', label: 'GitHub', position: 'right' },
      ],
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'dart', 'python', 'powershell', 'yaml', 'json'],
    },
  },
};
