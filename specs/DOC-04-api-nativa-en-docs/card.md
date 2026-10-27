# DOC-04 · la referencia de la API es parte nativa del sitio de documentación

status: proposed
cap: 1 h
sources:
  - "pedido (texto) · mensaje del usuario en la sesión (2026-10-27): «el swagger incluido dentro de la docu no se siente nativo, ademas tiene un scroll dentro»"
  - "repo · sitio-docs/src/components/Swagger.js (un `iframe` con Swagger UI que mide su alto cada 300 ms), sitio-docs/scripts/copiar.mjs (arma la página `api` con `<Swagger />`, copia `swagger-ui-dist` a `static/swagger-ui/` y el contrato; su lista de páginas no tiene `docs/technical/integraciones.md`), sitio-docs/docusaurus.config.js, sitio-docs/sidebars.js, apps/api/openapi.json"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "el swagger incluido dentro de la docu no se siente nativo" · acceptance: la referencia de la API sale de `apps/api/openapi.json` como páginas propias del sitio (con `docusaurus-plugin-openapi-docs` y `docusaurus-theme-openapi-docs`): una página por operación, agrupadas en el menú lateral por etiqueta del contrato, con el tema, la tipografía, el modo claro y oscuro y la búsqueda del resto del sitio
- S2 · "ademas tiene un scroll dentro" · acceptance: ninguna página del sitio tiene un `iframe` ni un panel con scroll propio para la API; se borran `src/components/Swagger.js`, la copia de `swagger-ui-dist` a `static/swagger-ui/` y la dependencia `swagger-ui-dist`
- DOC-04-ASM-01 · cada operación conserva el panel para probarla contra la API (el que trae el tema de openapi-docs), con la misma dirección de la API desplegada que hoy usa la página de Swagger · S1
- DOC-04-ASM-02 · `docs/technical/integraciones.md` entra en la lista de páginas que arma el sitio, en la sección técnica · S1
- DOC-04-ASM-03 · si el generador de una página por operación no compila con esta versión de Docusaurus, la referencia es Redoc integrado al tema (redocusaurus, en `/api`, con el color del sitio y la barra de navegación del sitio) · S1

## Tasks

- T1 · S1,S2,DOC-04-ASM-01,DOC-04-ASM-02 · sitio-docs/docusaurus.config.js (presentation), sitio-docs/sidebars.js (presentation), sitio-docs/scripts/copiar.mjs (presentation), sitio-docs/package.json, sitio-docs/package-lock.json, sitio-docs/src/components/Swagger.js (presentation) · tests: sitio-docs/tests/api-nativa.test.mjs "la referencia de la API son páginas del sitio generadas del contrato, una por operación @DOC-04-S1"; sitio-docs/tests/api-nativa.test.mjs "el sitio no tiene iframe ni Swagger UI incrustado @DOC-04-S2"; sitio-docs/tests/api-nativa.test.mjs "cada operación se puede probar contra la API desplegada @assumption:DOC-04-ASM-01"; sitio-docs/tests/api-nativa.test.mjs "integraciones.md está en la sección técnica del sitio @assumption:DOC-04-ASM-02"
  reuses: apps/api/openapi.json (el contrato, sin cambios); sitio-docs/scripts/copiar.mjs (la lista de páginas)
  new: docusaurus-plugin-openapi-docs y docusaurus-theme-openapi-docs: el generador nativo de Docusaurus para OpenAPI; nada del repo arma páginas desde el contrato

## Changes to existing behavior

- la página «API (Swagger)» pasa a ser una sección «API» con una página por operación; el sitio suma la página de integraciones

## Gate

```
suite: node --test sitio-docs/tests/
build: cd sitio-docs && npm run build
no-docs: la card cambia el sitio de documentación mismo; el contrato y el modelo de datos no cambian
no-visual: el sitio toma el tema de Docusaurus que ya tiene; lo verifica el build y el test de páginas
```

## Log

- L1 · el swagger incluido dentro de la docu no se siente nativo, ademas tiene un scroll dentro
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base
- L3 · 2026-10-27 · declared · attacks · la card no toca la API
- L4 · 2026-10-27 · docusaurus-plugin/theme-openapi-docs 5.2.0 y 4.7.1 no compilan con Docusaurus 3.10 + webpack 5.112 («Cannot get final name for export '__esModule'»; con concatenateModules:false las páginas fallan con «exports is not defined»; webpack 5.99.9 da OOM) · cambio de enfoque: la referencia es Redoc integrado al tema (redocusaurus) en /api, sin iframe, una sola barra de scroll · DOC-04-ASM-03
- L5 · 2026-10-27 · replaces: sitio-docs/tests/api-nativa.test.mjs (4 pruebas) y sitio-docs/tests/api-nativa-paginas.test.mjs · esperaban páginas por operación del generador openapi-docs, que no compila · by: sitio-docs/tests/api-nativa-redoc.test.mjs (mismas etiquetas S1, S2, ASM-01, ASM-02 y ASM-03)
