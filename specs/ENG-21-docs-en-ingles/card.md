# ENG-21 · la documentación, los README y el sitio en inglés

status: proposed
cap: 420 min
sources:
  - "pedido (texto) · mensajes del usuario: 2026-10-27 «quiero que termines esa migracion al ingles, y no solo el codigo, quiero que todo pase a ingles» · 2026-10-27 «porque quiero que este en ingles, igual que absolutamente todo en el repo» · 2026-11-09 «perfecto, continua con lo que falta entonces»"
  - "alcance (texto) · la porción del pedido que es esta card, del plan acordado en la sesión (memoria migracion-ingles-pendiente): «ENG-21 · docs, README y sitio (`sitio-docs/` → `docs-site/`) en inglés, capturas nuevas; también las tablas viejas de `navegacion-de-la-app.md`»"
  - "glosario · docs/technical/glosario-ingles.md (ENG-00): el nombre en inglés de cada término del dominio"
  - "relevamiento del repo (2026-11-09): 17 páginas de docs/ y 3 README en castellano o mixtos; ~20 tests congelados que leen encabezados o frases en castellano de esos archivos; las 30 filas de la tabla de navegacion-de-la-app.md citan `pantalla_*.dart` que ya no existen; accessibility.md cita `test/pantalla_error_de_arranque_test.dart`, que no existe"
not_read:
  - "no hay Jira: no hay comentarios, adjuntos ni enlaces que leer"

## Specs

- S1 · "docs" · acceptance: cada página de `docs/` está escrita en inglés y tiene un nombre de archivo en inglés
- S2 · "README" · acceptance: el README de la raíz y los de `apps/api` y `apps/mobile` están en inglés
- S3 · "sitio (`sitio-docs/` → `docs-site/`)" · acceptance: el sitio vive en `docs-site/` y sus secciones, etiquetas, páginas generadas, idioma e `html lang` están en inglés
- S4 · "capturas nuevas" · acceptance: las capturas del README muestran la app en inglés
- S5 · "también las tablas viejas de `navegacion-de-la-app.md`" · acceptance: cada archivo de la app que cita la página de navegación existe
- ENG-21-ASM-01 · los registros del método en `specs/` (`TRAZABILIDAD.md`, `REVISION-main.md` y las cards) quedan en castellano: citan los CU y el enunciado, que están en castellano, y el texto congelado no se reescribe; el sitio los sigue publicando, bajo secciones con título en inglés · S1,S3
- ENG-21-ASM-02 · las páginas citan el texto de la app en inglés, su idioma base; el castellano sólo aparece en la columna castellana del glosario, en nombres propios y en código (`inline` o bloques) · S1,S2
- ENG-21-ASM-03 · una página es inglés cuando, fuera de bloques de código, código en línea y URLs, menos del 2 % de sus palabras son palabras castellanas frecuentes (`de`, `la`, `el`, `los`, `las`, `que`, `y`, `con`, `para`, `por`, `una`, `del`, `se`, `es`, `en`, `un`, `al`, `lo`, `como`, `sin`); el glosario se mide sin su columna castellana · S1,S2
- ENG-21-ASM-04 · las cuatro capturas del README se vuelven a sacar con la app en inglés desde un archivo de capturas (`apps/mobile/test/capturas/readme_screenshots.dart`, locale `en`, modo claro, 430 px) que la corrida por defecto no toma y que, antes de escribir cada PNG, comprueba que la pantalla muestra su texto en inglés; quedan en `docs/screenshots/` como PNG (`01-login.png`, `03-venues.png`, `05-availability.png`, `07-done.png`) y el README las muestra con `alt` en inglés · S4
- ENG-21-ASM-05 · el sitio tiene un solo idioma, inglés: `defaultLocale 'en'`, `locales ['en']`, la búsqueda en `en` y `<html lang="en">` · S3
- ENG-21-ASM-06 · además de la tabla de navegación, cada ruta del repo que cita una página existe: las viejas siguen su renombre y la fila del error de arranque de accessibility.md cita el diálogo con reintento de `apps/mobile/lib/main.dart` (`resumeWithRetry`) y `apps/mobile/test/arranque_sin_conexion_test.dart`; el glosario queda afuera porque mapea nombres viejos a nuevos · S5
- ENG-21-ASM-07 · los archivos del sitio que esta card toca y el archivo de capturas nuevo llevan nombre en inglés (`docs-site/scripts/copy-docs.mjs`, `docs-site/src/clientModules/diagram-zoom.js`, `docs-site/tests/integrations-on-site.test.mjs`, `docs-site/tests/diagram-zoom.test.mjs`, `apps/mobile/test/capturas/readme_screenshots.dart`); las carpetas y los nombres de los tests existentes de `apps/` (`test/capturas/`, `tests/escenarios/`) son de ENG-22 · S1,S3
- ENG-21-ASM-08 · HEAD sobre una ruta GET de la API responde 405, igual que en main: FastAPI no registra HEAD y esta card no toca rutas; la fila `head-unsupported` del ataque queda ignorada en `specs/ENG-21-docs-en-ingles/http-attack.config.json` con este ASM · S1
- ENG-21-ASM-09 · la portada del sitio (el README copiado) muestra el logo y las cuatro capturas, que `copy-docs.mjs` copia a `static/` y enlaza con rutas del sitio, y se titula «ClubNahuelMosse», no con el nombre del archivo; en main las imágenes salían rotas · S3
- ENG-21-ASM-10 · el pedido no trae diseño del sitio: la referencia es la línea de diseño del repo (`design/line.md`, `design/tokens.css`, la de la app) para la marca, y la documentación de Stripe (https://docs.stripe.com) para la estructura de un sitio de documentación técnica de primer nivel: barra lateral, ancho de lectura, bloques de código · S3

## Look

- ref: design/line.md · https://docs.stripe.com
- behavior: cursor · los enlaces del lateral y los botones responden a hover, press y foco con el motion de `design/tokens.css`
- behavior: view · la página entra una vez; con reduced-motion, sin movimiento
- tokens: mood sobrio, técnico · genre developer documentation · spacing y easing los de `design/tokens.css`
- copy: el README de la raíz es la portada: ClubNahuelMosse, la app de reservas de canchas, con sus cuatro capturas

## Tasks

- T1 · S3,ENG-21-ASM-01,ENG-21-ASM-05,ENG-21-ASM-07 · docs-site/docusaurus.config.js (presentation), docs-site/scripts/copy-docs.mjs (presentation), docs-site/scripts/docstrings.py (presentation), docs-site/src/clientModules/diagram-zoom.js (presentation), docs-site/src/components/Swagger.js (presentation), docs-site/src/css/custom.css (presentation), docs-site/sidebars.js (presentation), docs-site/.gitignore (presentation), specs/ENG-21-docs-en-ingles/http-attack.config.json, docs-site/tests/integrations-on-site.test.mjs, docs-site/tests/diagram-zoom.test.mjs, .github/workflows/ci.yml (presentation), tests/ci.test.mjs, tests/docs-in-english.test.mjs · tests: tests/docs-in-english.test.mjs "the docs site lives in docs-site and is English @ENG-21-S3 @assumption:ENG-21-ASM-05"; tests/docs-in-english.test.mjs "the site keeps publishing the specs records under English sections @assumption:ENG-21-ASM-01"; tests/docs-in-english.test.mjs "the site's files and the README capture have English names @assumption:ENG-21-ASM-07"
  reuses: docs-site/scripts/copy-docs.mjs (hoy copiar.mjs) su tabla de páginas (sólo cambian los nombres de origen y destino y las etiquetas) y la config de Docusaurus existente
- T2 · S2,ENG-21-ASM-02,ENG-21-ASM-03 · README.md (presentation), apps/api/README.md (presentation), apps/mobile/README.md (presentation) · tests: tests/docs-in-english.test.mjs "every docs page and README is English @ENG-21-S1 @ENG-21-S2 @assumption:ENG-21-ASM-02"; tests/docs-in-english.test.mjs "the Spanish detector flags a Spanish paragraph and passes an English one with code and names @assumption:ENG-21-ASM-03"
  reuses: cada README en su lugar; se traduce el texto, la estructura queda
- T3 · S1,S5,ENG-21-ASM-06 · docs/technical/architecture.md (presentation), docs/technical/code-map.md (presentation), docs/technical/app-navigation.md (presentation), docs/technical/data-model.md (presentation) · tests: tests/docs-in-english.test.mjs "every docs page has an English file name @ENG-21-S1"; tests/docs-in-english.test.mjs "every app file the navigation page cites exists @ENG-21-S5"; tests/docs-in-english.test.mjs "every repo path a doc cites exists @assumption:ENG-21-ASM-06"
  reuses: cada página en su lugar (git mv al nombre en inglés); se traduce el texto, la estructura queda
- T4 · S1,ENG-21-ASM-06 · docs/technical/system-design.md (presentation), docs/technical/runbook.md (presentation), docs/technical/infra-cost.md (presentation), docs/technical/integrations.md (presentation), docs/technical/glossary.md (presentation) · tests: tests/docs-in-english.test.mjs "every docs page and README is English @ENG-21-S1 @ENG-21-S2 @assumption:ENG-21-ASM-02"
  reuses: cada página en su lugar (git mv al nombre en inglés); se traduce el texto, la estructura queda
- T5 · S1,ENG-21-ASM-06 · docs/getting-started.md (presentation), docs/documentation-assumptions.md (presentation), docs/adr/0001-stack.md (presentation), docs/adr/0002-hosting-on-render.md (presentation), docs/business/accessibility.md (presentation) · tests: tests/docs-in-english.test.mjs "every docs page and README is English @ENG-21-S1 @ENG-21-S2 @assumption:ENG-21-ASM-02"
  reuses: cada página en su lugar (git mv al nombre en inglés); se traduce el texto, la estructura queda
- T6 · S4,ENG-21-ASM-04 · apps/mobile/test/capturas/readme_screenshots.dart, apps/mobile/test/capturas/sesion_capturas.dart, apps/mobile/test/soporte/montar.dart, docs/screenshots/01-login.png (presentation), docs/screenshots/03-venues.png (presentation), docs/screenshots/05-availability.png (presentation), docs/screenshots/07-done.png (presentation) · tests: tests/docs-in-english.test.mjs "the README screenshots are the ones the English capture produces @ENG-21-S4 @assumption:ENG-21-ASM-04"
  reuses: apps/mobile/test/soporte/montar.dart cargarFuentes y los montajes de los archivos de capturas existentes (test/capturas/*_capturas.dart)
- T7 · S1,S2,S3,S4 · apps/api/tests/** , apps/mobile/test/navegacion_documentada_test.dart, apps/mobile/test/sin_sobreingenieria_test.dart · los tests de documentación que leen encabezados, frases, nombres de archivo o la carpeta `sitio-docs` siguen la traducción y el renombre (refactor-tests)
  new: no escribe lógica de producción
- T9 · ENG-21-ASM-09 · docs-site/scripts/copy-docs.mjs (presentation), docs-site/tests/home-page.test.mjs · tests: docs-site/tests/home-page.test.mjs "the site's home page shows the README's logo and screenshots under its own title @assumption:ENG-21-ASM-09"
  reuses: la copia del README que ya hace copy-docs.mjs y la carpeta `static/` que ya llena
- T8 · S3 · design/line.md (presentation), design/DESIGN.md (presentation), design/tokens.css (presentation), design/components/primitives.css (presentation), design/components/components.css (presentation), design/components/fonts/InterVariable.woff2 (presentation), design/components/fonts/OFL.txt (presentation), docs-site/src/css/custom.css (presentation), docs-site/src/components/Swagger.js (presentation), docs-site/src/theme/ColorModeToggle/index.js (presentation), docs-site/scripts/copy-docs.mjs (presentation), docs-site/docusaurus.config.js (presentation), specs/ENG-21-docs-en-ingles/probe-docs.json, specs/ENG-21-docs-en-ingles/probe-drawer.json, docs-site/tests/design-line.test.mjs · el sitio movido sigue la línea de diseño del proyecto (la de la app): tokens en `design/tokens.css`, el set de `design/components/` para lo que el sitio agrega, motion de hover, press, foco y entrada con su reduced-motion · tests: docs-site/tests/design-line.test.mjs "the docs site takes its colors, space and motion from design/tokens.css @ENG-21-S3"
  reuses: la paleta de `apps/mobile/lib/theme/tokens.dart` y el set de `.claude/templates/components/`

## Changes to existing behavior

- `sitio-docs/` → `docs-site/`; el sitio sale en inglés; el job `node` del CI corre los tests de `docs-site/tests`
- cada página de `docs/` cambia a su nombre en inglés y se traduce; los README se traducen; `docs/capturas/*.jpg` → `docs/screenshots/*.png`
- los tests de documentación que comparan un encabezado, una frase o un nombre de archivo en castellano pasan a compararlo en inglés (T7); lo que verifican no cambia

## Gate

```
suite [timeout 30 min]: sh D:/Temp/w/herramientas/ci01-pytest.sh -q -p no:cacheprovider -rf tests/unit tests/escenarios/test_documentacion_vigente.py tests/escenarios/test_documentacion_supuestos_vigente.py tests/escenarios/test_requisitos_no_funcionales.py tests/escenarios/test_requisitos_no_funcionales_readme_app.py tests/escenarios/test_readme_app_configuracion.py
node: node --test --test-force-exit tests/*.test.mjs docs-site/tests/*.test.mjs
flutter: sh -c "cd apps/mobile && /d/projects/flutter/bin/flutter test test/navegacion_documentada_test.dart test/sin_sobreingenieria_test.dart test/capturas/readme_screenshots.dart"
lint: sh D:/Temp/w/herramientas/eng17-ruff-mypy.sh apps/api
app: sh D:/Temp/w/herramientas/ci01-app.sh eng21_app
attacks: sh D:/Temp/w/herramientas/ci01-attacks.sh eng21_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /venues {"name": "Attack Venue", "address": "Street 1", "opens_at": "08:00", "closes_at": "23:00", "open_days": [1, 2, 3, 4, 5, 6, 7]}' --read /bookings --read /me --item-path "/bookings/all/{id}" --openapi apps/api/openapi.json
probe docs [timeout 25 min]: sh D:/Temp/w/herramientas/eng21-docs-probe.sh specs/ENG-21-docs-en-ingles/probe-docs.json --out .validation/probe/docs --widths 390,1280 --contrast "article p,.theme-doc-sidebar-container .menu__link--active,.navbar__title"
probe drawer [timeout 10 min]: sh D:/Temp/w/herramientas/eng21-docs-probe.sh specs/ENG-21-docs-en-ingles/probe-drawer.json --out .validation/probe/drawer --widths 390 --contrast ".navbar-sidebar--show .menu__link--active,.navbar__title"
refactor-tests: los tests de documentación que leen un encabezado, una frase, un nombre de archivo o la carpeta del sitio siguen la traducción a inglés y el renombre (`sitio-docs` → `docs-site`, cada página a su nombre en inglés, `docs/capturas/*.jpg` → `docs/screenshots/*.png`); lo que verifican no cambia
no-visual: la card no toca ninguna pantalla de la app; el archivo de capturas es un test
no-docs: la card traduce la documentación; no cambia comportamiento ni contrato
```

## Log
- L1 · 2026-10-27 «quiero que termines esa migracion al ingles, y no solo el codigo, quiero que todo pase a ingles» · 2026-10-27 «porque quiero que este en ingles, igual que absolutamente todo en el repo» · alcance de esta card en el plan: «ENG-21 · docs, README y sitio (`sitio-docs/` → `docs-site/`) en inglés, capturas nuevas; también las tablas viejas de `navegacion-de-la-app.md`» · 2026-11-09 «perfecto, continua con lo que falta entonces»
- L2 · 2026-11-09 · sin Jira: las dudas van directo a ASM (ENG-21-ASM-01..06), sin ronda de preguntas
- L3 · 2026-11-09 · la rama sale de CI-01-ci-en-github (PR #35, abierto para una persona por su `## Needs a person`): el CI de CI-01 corre los tests de `sitio-docs/tests`, que esta card renombra
- L4 · 2026-11-09 · T1 · docs-site renombrado y en inglés; node --test tests/ci.test.mjs docs-site/tests/*.test.mjs tests/docs-in-english.test.mjs: S3 y ASM-01 pasan
- L5 · 2026-11-09 · T6 · flutter test test/capturas/readme_screenshots.dart: 4 passed, PNG 430 px en docs/screenshots; falta el README (T2) para el test S4
- L6 · 2026-11-09 · T4+T5 · 10 páginas traducidas y renombradas (git mv); rutas citadas verificadas con ls; el detector de castellano (tests/docs-in-english.test.mjs) no corrió: el time-cap bloqueó la suite, medido con Grep por palabras
- L7 · 2026-11-09 · cap 150 → 420 min por orden de la persona (2026-11-09): la línea de diseño que pide el sitio movido (I-line, I-tokens, I-set, I-motion) y T7 necesitan builder
- L8 · 2026-11-09 · T8 · design/tokens.css, design/components/, custom.css, Swagger.js, copy-docs.mjs, config; node --test docs-site/tests/design-line.test.mjs docs-site/tests/*.test.mjs tests/ci.test.mjs: 15 pass; required.mjs lists no I-* item (those are measured by verify.mjs)
- L9 · 2026-11-09 · T7 · refactor-tests: 25 archivos de apps/api/tests y 2 de apps/mobile/test editados en el lugar (nombres, encabezados y frases en inglés, docs-site/scripts/copy-docs.mjs); flutter test navegacion_documentada + sin_sobreingenieria + readme_screenshots: 12 passed; pytest unit+escenarios de documentación: 398 passed y 4 failed que quedaron corregidos y verificados por separado (25 passed en documentacion_vigente/supuestos); falta corrida final de la línea suite: Docker se cayó (Postgres 8701 sin respuesta)
- L10 · 2026-11-09 · uncovered · ENG-21-ASM-08 · lo cubre el ataque HTTP de la línea attacks: del Gate (la fila head-unsupported ignorada con su motivo en http-attack.config.json), no un test etiquetado: la card no toca rutas
- L11 · 2026-11-09 · uncovered · ENG-21-ASM-10 · la referencia del aspecto la comprueban las rondas del designer contra ref/, no un test etiquetado
