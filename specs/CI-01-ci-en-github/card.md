# CI-01 · CI en GitHub Actions

status: proposed
cap: 90 min
sources: pedido de la persona en la sesión (texto); medición de main 7c503df: pytest 806 passed, 19 failed, 2 skipped; ruff 7 errores en 2 tests congelados; mypy limpio; flutter analyze limpio, `dart format` cambia 13 archivos de `test/` y uno de `lib/` (`search_rules.dart`); el test de SIM-02 que compara firmas con `git show main:` necesita la rama local `main`, que el checkout de un pull request no crea; flutter test 756 passed, 72 failed: 51 tests declarados reemplazados, 19 archivos que ENG-19 dejó sin compilar con sus copias, el test de ENG-08 que exige `apps/api` sin cambios en el árbol de trabajo y un cierre inesperado del compilador que no se repite
not_read: ninguno: no hay Jira ni adjuntos

## Specs

- S1 · "aprovechando que es un repo publico, metele CI"
- CI-01-ASM-01 · los tests congelados que una card ya declaró reemplazados (`replaces:` en su Log) siguen en sus archivos y fallan en un pytest o un flutter test plano; el CI no los borra: los jobs de la API y de la app dan verde si cada test que falla está declarado reemplazado y su reemplazo existe con sus tags y pasa, la misma regla del gate (`replacedFailures` de `verify.mjs`); un archivo de la app que no compila cuenta como reemplazado si alguna card declara reemplazados tests de ese archivo y el archivo de la copia existe · S1
- CI-01-ASM-02 · los tests congelados que fallan en main porque citan archivos o nombres que la migración a inglés renombró se corrigen para seguir el renombre sin cambiar lo que verifican: rutas de la app (`lib/comun/configuracion.dart` → `lib/common/config.dart`, `lib/spaces/espacios.dart` y `lib/bookings/horarios.dart` → `lib/features/...`), las pantallas `pantalla_*.dart` → `*_screen.dart` (con las filas del registro de accesibilidad), las rutas de evidencia de la matriz ASVS, los nombres del básquet que ENG-20 pasó a inglés, y el control de nombres de constraints deja afuera los NOT NULL que PostgreSQL 18 registra con el nombre de su columna · S1
- CI-01-ASM-03 · el CI corre lo mismo que `scripts/test.sh` con las versiones de la máquina de desarrollo: Postgres 18, Python 3.13, Node 24, Flutter 3.35.3, el emulador de Auth con Java 21; `ruff check .` plano, con los dos tests congelados que rompen el largo de línea o redefinen fixtures agregados a las excepciones por archivo de `pyproject.toml`, como los demás congelados; `dart format` revisa sólo `lib/`, en el CI y en `scripts/test.sh`: los tests quedan congelados al commitearse en rojo y su formato no se revisa; el único archivo de `lib/` sin formato en main se formatea; el job de la API crea la rama local `main` desde `origin/main` cuando el checkout no la trae · S1
- CI-01-ASM-04 · el CI corre en cada pull request y en cada push a main; no despliega nada (Render despliega solo desde main) · S1
- CI-01-ASM-05 · sale el test de ENG-14-S2 que exige que la rama `ingles-api` no esté en main: una vez mergeada lo está por definición y falla en todo main · S1

## Tasks

- T1 · S1,CI-01-ASM-01,CI-01-ASM-03,CI-01-ASM-04 · .github/workflows/ci.yml (presentation), scripts/ci-test-verdict.mjs (rule), scripts/test.sh, tests/ci.test.mjs · tests: tests/ci.test.mjs "the workflow runs on every pull request and on every push to main and deploys nothing @CI-01-S1 @assumption:CI-01-ASM-04"; tests/ci.test.mjs "the API job runs ruff, mypy and the whole pytest on Python 3.13 against Postgres 18 and the Auth emulator on Node 24 and Java 21 @CI-01-S1 @assumption:CI-01-ASM-03"; tests/ci.test.mjs "the app job runs flutter analyze, the format check and flutter test judged by the replaced tests rule @CI-01-S1 @assumption:CI-01-ASM-03"; tests/ci.test.mjs "scripts/test.sh checks the format of lib only, like the CI @CI-01-S1 @assumption:CI-01-ASM-03"; tests/ci.test.mjs "the node job runs the repo tests and the docs site tests @CI-01-S1"; tests/ci.test.mjs "pytest is green when every failing test is declared replaced and its replacement exists @CI-01-S1 @assumption:CI-01-ASM-01"; tests/ci.test.mjs "pytest is red when a failing test is not declared replaced @CI-01-S1 @assumption:CI-01-ASM-01"; tests/ci.test.mjs "pytest is red when the replacement of a failing test is missing, lacks its tags or fails too @CI-01-S1 @assumption:CI-01-ASM-01"; tests/ci.test.mjs "pytest is red on a collection error or any exit other than failed tests @CI-01-S1 @assumption:CI-01-ASM-01"; tests/ci.test.mjs "flutter test is green when every failing test and every file that no longer compiles is declared replaced @CI-01-S1 @assumption:CI-01-ASM-01"; tests/ci.test.mjs "flutter test is red when a failing test or a file that does not load is not declared replaced @CI-01-S1 @assumption:CI-01-ASM-01"; tests/ci.test.mjs "flutter test is red when a file that no longer compiles is declared replaced by a copy that does not exist @CI-01-S1 @assumption:CI-01-ASM-01"
  reuses: .claude/tools/verify.mjs replacedFailures
- T2 · S1,CI-01-ASM-02,CI-01-ASM-03,CI-01-ASM-05 · apps/api/pyproject.toml, apps/mobile/lib/features/bookings/domain/search_rules.dart (rule), apps/api/tests/escenarios/test_basquet.py, apps/api/tests/escenarios/test_documentacion_supuestos_vigente.py, apps/api/tests/escenarios/test_english_schema.py, apps/api/tests/escenarios/test_readme_app_configuracion.py, apps/api/tests/escenarios/test_requisitos_no_funcionales.py, apps/api/tests/escenarios/test_requisitos_no_funcionales_readme_app.py, apps/api/tests/unit/test_api_en_ingles_verde.py, docs/business/accessibility.md (presentation), specs/asvs.md (presentation), apps/api/tests/unit/test_ci_suite_green.py · tests: apps/api/tests/unit/test_ci_suite_green.py "the frozen tests that cited renamed files or Spanish names cite the current ones @CI-01-S1 @assumption:CI-01-ASM-02"; apps/api/tests/unit/test_ci_suite_green.py "the named constraints check ignores the NOT NULL constraints PostgreSQL 18 records @CI-01-S1 @assumption:CI-01-ASM-02"; apps/api/tests/unit/test_ci_suite_green.py "plain ruff passes on the API @CI-01-S1 @assumption:CI-01-ASM-03"; apps/api/tests/unit/test_ci_suite_green.py "the check that the ingles-api branch is not in main is gone @CI-01-S1 @assumption:CI-01-ASM-05"

## Changes to existing behavior

- apps/api/tests/escenarios/test_basquet.py · espera los nombres en inglés que ENG-20 le dio al catálogo (Basketball, Basketball 5, Basketball 3x3); las claves no cambian · "el catálogo ofrece básquet con su tipo @REV-05-S1" verifica lo mismo
- apps/api/tests/escenarios/test_documentacion_supuestos_vigente.py · busca las pantallas como `*_screen.dart` · "el registro de accesibilidad nombra cada pantalla con lector, navegador y resultado @REV-07-S7" verifica lo mismo
- apps/api/tests/escenarios/test_english_schema.py · deja afuera los constraints NOT NULL (`contype = 'n'`) que PostgreSQL 18 registra · "every named constraint is in English @ENG-17-S1" verifica lo mismo
- apps/api/tests/escenarios/test_readme_app_configuracion.py, apps/api/tests/escenarios/test_requisitos_no_funcionales_readme_app.py · leen `lib/common/config.dart` · "siguiendo sólo el README de la app se configura y ejecuta la app @RNF-01-H07-01" verifica lo mismo
- apps/api/tests/escenarios/test_requisitos_no_funcionales.py · lee `lib/features/spaces/data/spaces_repository.dart` y `lib/features/bookings/data/availability_api.dart` · "la API publica su documentación OpenAPI con todos los endpoints que usa la app @RNF-01-H04-01" verifica lo mismo
- apps/api/tests/unit/test_api_en_ingles_verde.py · sale "la rama ingles-api no está en main @ENG-14-S2"
- docs/business/accessibility.md, specs/asvs.md · citan los archivos con su nombre actual
- scripts/test.sh · `dart format` revisa sólo `lib/`, como el CI
- apps/mobile/lib/features/bookings/domain/search_rules.dart · sólo cambia el formato que `dart format` exige; el comportamiento no cambia

## Gate

```
suite [timeout 20 min]: sh D:/Temp/w/herramientas/ci01-pytest.sh -q -p no:cacheprovider -rf tests/unit/test_ci_suite_green.py tests/escenarios/test_basquet.py tests/escenarios/test_documentacion_supuestos_vigente.py tests/escenarios/test_english_schema.py tests/escenarios/test_readme_app_configuracion.py tests/escenarios/test_requisitos_no_funcionales.py tests/escenarios/test_requisitos_no_funcionales_readme_app.py tests/unit/test_api_en_ingles_verde.py tests/unit/test_sin_supresiones.py
node: node --test tests/ci.test.mjs tests/kit.test.mjs sitio-docs/tests/integraciones-en-el-sitio.test.mjs sitio-docs/tests/zoom-de-diagramas.test.mjs
lint: sh D:/Temp/w/herramientas/eng17-ruff-mypy.sh apps/api
lint: npx -y eslint@9 --no-config-lookup --rule {"no-unused-vars":"error"} tests/ci.test.mjs scripts/ci-test-verdict.mjs
migrate-upgrade: sh D:/Temp/w/herramientas/ci01-pytest.sh -q -p no:cacheprovider tests/escenarios/test_english_schema_rows.py
mutate scripts/ci-test-verdict.mjs: node --test tests/ci.test.mjs
app: sh D:/Temp/w/herramientas/ci01-app.sh ci01_app
attacks: sh D:/Temp/w/herramientas/ci01-attacks.sh ci01_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /venues {"name": "Attack Venue", "address": "Street 1", "opens_at": "08:00", "closes_at": "23:00", "open_days": [1, 2, 3, 4, 5, 6, 7]}' --read /bookings --read /me --openapi apps/api/openapi.json
refactor-tests: los tests congelados que citaban archivos o nombres que la migración a inglés renombró siguen el renombre, el control de constraints deja afuera los NOT NULL de PostgreSQL 18 y sale el control obsoleto de la rama ingles-api; lo que verifican los demás no cambia
no-visual: la card no toca ninguna pantalla de la app
no-docs: la card agrega CI y corrige citas de archivos; no cambia comportamiento ni contrato
```

## Log

- L1 · Pedido de la persona: «aprovechando que es un repo publico, metele CI»
- L2 · 2026-11-09 · declared · restart · la card no guarda nada: agrega el workflow del CI y corrige tests congelados y citas de archivos; la app y su base quedan como en main
- L3 · 2026-11-09 · replaces: apps/mobile/test/notificaciones_test.dart "cuándo llegó y en qué día el rótulo del día es HOY, AYER o la fecha" · ENG-19 copió el archivo entero porque dejó de compilar y lo declaró en prosa (L140 de su Log), con una copia que ENG-20 renombró; esta línea lo declara con su copia actual para que el CI lo reconozca · by: apps/mobile/test/notifications_spanish_test.dart "cuándo llegó y en qué día el rótulo del día es HOY, AYER o la fecha"
- L4 · 2026-11-09 · declared · ACT-02 · el test de ENG-08 «la base de la app no toca apps/api» mira el árbol de trabajo y el CI parte de un checkout limpio, así que pasa; un cierre inesperado del compilador de Dart deja el job en rojo y se vuelve a correr a mano: el CI no reintenta solo, para no esconder una falla real
- L5 · 2026-11-09 · declared · mutate · scripts/ci-test-verdict.mjs:34 · “.trim()” → “.trimEnd()” · el resumen de pytest -q no lleva espacios al principio y el recorte sólo cambia el texto del mensaje de error, no el veredicto
- L6 · 2026-11-09 · declared · K4 · apps/api/tests/escenarios/test_requisitos_no_funcionales_readme_app.py · test congelado de RNF-01 que repite a propósito los de test_readme_app_configuracion.py y test_requisitos_no_funcionales.py; la card sólo le corrige la ruta que la migración renombró y los congelados no se refactorizan
- L7 · 2026-11-09 · declared · K4 · apps/api/tests/escenarios/test_readme_app_configuracion.py · test congelado de REV con el mismo encabezado que su par de RNF-01; la card sólo le corrige la ruta que la migración renombró
- L8 · 2026-11-09 · declared · K4 · apps/api/tests/escenarios/test_requisitos_no_funcionales.py · test congelado de RNF-01 que comparte las líneas del README de la app con su par; la card sólo le corrige las rutas que la migración renombró
- L9 · 2026-11-09 · declared · mutate · scripts/ci-test-verdict.mjs:34 · “.trim()” → “.trimEnd()” · “.*$/gm)].at(-1)?.[0]@@??'';if(!summary||/\” · el resumen de pytest -q no lleva espacios al principio; el recorte sólo cambia el texto del mensaje de error, no el veredicto
- L10 · 2026-11-09 · declared · mutate · apps/mobile/lib/features/bookings/domain/search_rules.dart · sólo cambia el formato que exige dart format; ninguna línea de lógica cambia y sus tests de main siguen corriendo en el job de la app
