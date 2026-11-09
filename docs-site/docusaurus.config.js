import { themes as prismThemes } from 'prism-react-renderer';

/** @type {import('@docusaurus/types').Config} */
export default {
  title: 'ClubNahuelMosse',
  tagline: 'Documentation of the sports venue booking app',
  url: 'https://nahuelmosse.github.io',
  baseUrl: '/',
  onBrokenLinks: 'warn',
  markdown: {
    // The .md files are read as plain Markdown, not MDX: the documents carry `<`, `{` and tables.
    format: 'detect',
    mermaid: true,
    hooks: { onBrokenMarkdownLinks: 'warn' },
  },
  i18n: { defaultLocale: 'en', locales: ['en'] },
  // The project's design line, copied into static/design/ by scripts/copy-docs.mjs.
  stylesheets: ['/design/tokens.css', '/design/components/primitives.css', '/design/components/components.css'],
  clientModules: ['./src/clientModules/diagram-zoom.js'],
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
  ],
  themes: [
    '@docusaurus/theme-mermaid',
    [
      '@easyops-cn/docusaurus-search-local',
      { hashed: true, language: ['en'], docsRouteBasePath: '/', indexBlog: false },
    ],
  ],
  themeConfig: {
    colorMode: { disableSwitch: true, defaultMode: 'dark', respectPrefersColorScheme: true },
    navbar: {
      title: 'ClubNahuelMosse',
      items: [],
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'dart', 'python', 'powershell', 'yaml', 'json'],
    },
  },
};
