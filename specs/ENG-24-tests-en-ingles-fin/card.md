# ENG-24 · los tests en inglés, lo que ENG-22 dejó pendiente

status: proposed
cap: 600 min
sources:
  - "pedido (texto) · mensaje del usuario en la sesión de Claude Code, 2026-11-09: «es grave, todo deberia estar en ingles, menos la parte en espa;ol de la internacionalizacion, el codigo en ingles y todo lo demas en ingles»"
  - "specs/ENG-22-tests-en-ingles/card.md (rama ENG-22-tests-en-ingles, 7422a3ef): su L1 (el mismo pedido), sus Specs S2 y S3 sin cumplir, sus ASM ENG-22-ASM-01..08, y su Log L268 (lo que quedó afuera por el tope de tiempo: T2, T3, T4 y los nombres compartidos de la app) y L270 (el CI en rojo del PR #38)"
  - "specs/ENG-22-tests-en-ingles/handoff.md y D:/Temp/w/eng22-maps/phase3.md: las reglas de la traducción de los cuerpos de los tests y el mapa de nombres compartidos de la app (ren_dart.py), con los choques montar→mountScreen y ahoraClub→noticesNow"
  - "CI del PR #38 (corridas 42796113793 y 42797435098): pytest con 5 fallas no declaradas (test_documentation_assumptions_current, test_reliable_suite, test_reliable_suite_replacements_coverage, test_ci_suite_green ×2), flutter con deactivate_venue_test.dart y search_court_test.dart sin declarar, node con CI-01-S1 y ENG-21-ASM-06"
  - "glosario · docs/technical/glossary.md (ENG-00): el nombre en inglés de cada término del dominio"
not_read:
  - "no hay Jira: no hay comentarios, adjuntos ni enlaces que leer"

## Specs

- S1 · "todo deberia estar en ingles" · acceptance: ningún test de `apps/api/tests`, `apps/mobile/test` ni `apps/mobile/integration_test` lleva la etiqueta `@supuesto:`, y los nombres que comparten los tests de la app (helpers y fixtures de `test/support` e `integration_test/support`) están en inglés
- S2 · "menos la parte en espa;ol de la internacionalizacion" · acceptance: el texto castellano de la app que los tests comprueban (UI, mensajes de la API, datos de prueba) queda como está; cuando la prosa en inglés lo cita, va entre «»
- S3 · "el codigo en ingles" · acceptance: los títulos de los tests, los nombres que declaran (funciones, clases, fixtures, helpers, variables, parámetros) y sus comentarios están en inglés en los tests de la API y de la app
- S4 · "y todo lo demas en ingles" · acceptance: los tests que leen la ruta, el nombre o el título de otro test y la documentación que cita una ruta de test citan la ruta y el nombre nuevos, que existen, y los tres jobs del CI (API, App, node) pasan sin fallas que ninguna card declare
- ENG-24-ASM-01 · esta card reusa por referencia las ASM 01 a 08 de la card ENG-22 (alcance: un nombre de producción queda; `specs/` no se reescribe; el castellano de la app queda y se cita entre «»; la medida del inglés del detector; las carpetas; los reemplazos; las capturas; HEAD 405) y no abre otra ronda de preguntas: ENG-22 ya la tuvo · S1,S2,S3,S4
- ENG-24-ASM-02 · un test reemplazado que sigue fallando y cuyo título (o el de su reemplazo) esta card traduce se declara de nuevo en el Log de esta card con los títulos en inglés, para que el CI lo siga leyendo como reemplazado · S3,S4

## Tasks

- T1 · S3,ENG-24-ASM-01 · apps/api/tests/** · títulos (docstrings y nombres de las funciones de test), fixtures, helpers, variables, parámetros y comentarios de los tests de la API en inglés · tests: tests/tests-in-english-finish.test.mjs "every title, declared name and comment of the API tests is English @ENG-24-S3 @assumption:ENG-24-ASM-01"
  new: no escribe lógica de producción
- T2 · S1,S3 · apps/mobile/test/**, apps/mobile/integration_test/** · los nombres compartidos de `test/support` e `integration_test/support` (ren_dart.py) y los títulos, nombres locales y comentarios de los tests de la app en inglés · tests: tests/tests-in-english-finish.test.mjs "every title, declared name and comment of the app tests is English @ENG-24-S3"; tests/tests-in-english-finish.test.mjs "the helpers and fixtures the app tests share have English names @ENG-24-S1"
  new: no escribe lógica de producción
- T3 · S1,S2 · apps/api/tests/**, apps/mobile/test/**, apps/mobile/integration_test/** · `@supuesto:` → `@assumption:`; el texto castellano que los tests comparan queda · tests: tests/tests-in-english-finish.test.mjs "no test carries the Spanish tag supuesto @ENG-24-S1"; tests/tests-in-english-finish.test.mjs "the Spanish app strings the tests compare are quoted, not translated @ENG-24-S2"
  new: no escribe lógica de producción
- T4 · S4 · apps/api/tests/scenarios/test_reliable_suite.py, apps/api/tests/scenarios/test_reliable_suite_replacements_coverage.py, apps/api/tests/unit/test_ci_suite_green.py, apps/api/tests/scenarios/test_documentation_assumptions_current.py, apps/api/tests/scenarios/test_migrations_folder.py, apps/api/tests/scenarios/test_english_schema.py, tests/ci-suite.test.mjs, docs/** (presentation), apps/mobile/test/deactivate_venue_test.dart, apps/mobile/test/search_court_test.dart · los tests que leen rutas o títulos de otros tests y los docs que citan rutas de test siguen los renombres de ENG-22 · tests: tests/tests-in-english-finish.test.mjs "every test path a test or a doc cites exists @ENG-24-S4"
  new: no escribe lógica de producción
- T5 · ENG-24-ASM-02 · specs/ENG-24-tests-en-ingles-fin/card.md · las líneas `replaces:` del Log con los títulos traducidos · tests: tests/tests-in-english-finish.test.mjs "every replacement this card declares names an existing test and a replacement that carries its tags @assumption:ENG-24-ASM-02"
  new: no escribe lógica de producción

## Changes to existing behavior

- los títulos, nombres locales y comentarios de los tests de la API y de la app pasan al inglés; sus etiquetas `@<ID>-S<n>`, `@<ID>-H<n>` y `@assumption:<ID>-ASM-NN` quedan, y lo que cada test verifica no cambia
- los helpers y fixtures compartidos de `apps/mobile/test/support` y `apps/mobile/integration_test/support` cambian de nombre, y cada test que los usa los sigue
- la opción `--sin-emulador` de `apps/api/tests/conftest.py` pasa a `--no-emulator`, con los docs y scripts que la citan
- los tests que leen la ruta o el título de otro test (`test_reliable_suite*.py`, `test_ci_suite_green.py`, `test_documentation_assumptions_current.py`, `tests/*.test.mjs`) siguen el renombre (refactor-tests)

## Gate

```
suite [timeout 60 min]: sh D:/Temp/w/herramientas/eng24-pytest.sh -q -p no:cacheprovider
flutter [timeout 60 min]: sh D:/Temp/w/herramientas/eng24-flutter.sh
screenshots [timeout 40 min]: sh D:/Temp/w/herramientas/eng24-screenshots.sh
node: node --test --test-force-exit tests/*.test.mjs docs-site/tests/*.test.mjs
vs-main: node D:/Temp/w/herramientas/eng24-vs-main.mjs origin/main
lint: sh D:/Temp/w/herramientas/eng24-lint.sh apps/api apps/mobile/test apps/mobile/integration_test
app: sh D:/Temp/w/herramientas/eng24-app.sh eng24_app
attacks: sh D:/Temp/w/herramientas/eng24-attacks.sh eng24_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /venues {"name": "Attack Venue", "address": "Street 1", "opens_at": "08:00", "closes_at": "23:00", "open_days": [1, 2, 3, 4, 5, 6, 7]}' --read /bookings --read /me --item-path "/bookings/all/{id}" --openapi apps/api/openapi.json
migrate-upgrade: sh D:/Temp/w/herramientas/eng24-migrate.sh
refactor-tests: los tests de cards anteriores pasan a títulos, nombres, variables y comentarios en inglés; sus etiquetas y lo que verifican no cambian; los que leen la ruta o el título de otro test siguen el renombre
no-visual: la card no toca ninguna pantalla de la app ni las capturas PNG
no-docs: la documentación sólo cambia las rutas de tests que cita; no cambia comportamiento ni contrato
```

## Log
- L1 · 2026-11-09 «es grave, todo deberia estar en ingles, menos la parte en espa;ol de la internacionalizacion, el codigo en ingles y todo lo demas en ingles» · alcance de esta card: lo que ENG-22 dejó sin hacer (su Log L268 y L270): los títulos, nombres locales y comentarios de los tests, `@supuesto:`, los nombres compartidos de la app y el CI en rojo del PR #38; el código de producción y la configuración siguen siendo de ENG-23
- L2 · 2026-11-10 · sin Jira y con la ronda de preguntas ya hecha por ENG-22: sus ASM se reusan por referencia (ENG-24-ASM-01), sin ronda nueva
- L3 · 2026-11-10 · la card se apila sobre ENG-22 (rama ENG-22-tests-en-ingles, 7422a3ef, PR #38 abierto)
- L4 · 2026-11-10 · declared · S4 · la ruta, el nombre y el título de un test son la misma cita a otro test: un solo test recorre todas las citas de los tests y los docs y comprueba que lo citado existe
- L5 · 2026-11-10 · declared · ENG-24-ASM-01 · «08» y «405» nombran las ASM de ENG-22 que se reusan, no valores que esta card compruebe: HEAD 405 lo comprueba el test de ENG-22-ASM-08 (apps/api/tests/unit/test_head_not_allowed.py)
