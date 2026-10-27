# Handoff DOC-04 · T1

## Hecho (commit RED 02dbede + commit WIP)
- sitio-docs/tests/api-nativa.test.mjs (RED, commiteado). Su test S1 usa operationId como slug y es incorrecto: el plugin nombra
  los archivos por resumen+ruta (`alta-de-sede-sedes-post.api.mdx`). Reemplazo: tests/api-nativa-paginas.test.mjs (mismo tag
  @DOC-04-S1). Falta: `git rm`/ignorar el test viejo de S1 (el guard puede impedir editarlo) y anotar en `## Log`:
  `- L<n> · <fecha> · replaces: sitio-docs/tests/api-nativa.test.mjs "la referencia de la API ..." · slug por operationId, el plugin usa resumen+ruta · by: sitio-docs/tests/api-nativa-paginas.test.mjs "..."`.
- copiar.mjs: sin api.mdx ni swagger-ui, con integraciones (8), contrato con `servers` en static/openapi.json.
- Swagger.js borrado, .gitignore sin static/swagger-ui, package.json: plugin/theme openapi-docs 5.2.0, docusaurus-plugin-sass, sass,
  sin swagger-ui-dist; scripts `api` (`docusaurus gen-api-docs all`) en `build` y `start`.
- docusaurus.config.js: plugin openapi-docs (id api, docsPluginId classic, specPath static/openapi.json, outputDir docs/api,
  groupPathsBy tag), theme, docItemComponent '@theme/ApiItem'.

## Abierto: el build del cliente
- `npm install` normal falla: postinstall de postman-code-generators pide yarn. Se instaló con `npm install --ignore-scripts`
  (CI: revisar el workflow del sitio, probablemente `npm ci` falle igual; hay que resolverlo, p. ej. `--ignore-scripts` en CI).
- webpack 5.112.2 (el instalado): "Cannot get final name for export '__esModule'" rompe el build. Con
  `optimization.concatenateModules:false` (plugin inline configureWebpack) el build pasa, pero en el navegador
  `ReferenceError: exports is not defined` (common.*.js) y 34 warnings "export 'default' (imported as 'OperationTabs') was not found in
  '@theme/OperationTabs'": la página no hidrata. NO sirve.
- Override webpack 5.99.9: OOM ("invalid table size") a los 36 s incluso con 6 GB. NO sirve.
- Estado actual: sin override ni hack (config y package.json limpios); node_modules quedó con 5.99.9, correr `npm install --ignore-scripts`.
- Ideas: probar otras versiones de webpack (5.10x intermedias) o el theme/plugin openapi-docs 4.x; o `future.faster.rspackBundler`
  (`@docusaurus/faster`); revisar issues de docusaurus-theme-openapi-docs sobre Docusaurus 3.10 y `exports is not defined`.
  Verificar siempre en navegador (`npx docusaurus serve`, página /api/alta-de-sede-sedes-post, consola sin errores).

## Gate
- `node --test sitio-docs/tests/` y `cd sitio-docs && npm run build` (build ~3 min, en background con log; usar wait.mjs).
- Sección API: ruta `/api/<resumen>-<ruta>-<método>` (p. ej. /api/alta-de-sede-sedes-post).
