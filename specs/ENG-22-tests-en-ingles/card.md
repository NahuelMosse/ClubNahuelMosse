# ENG-22 · los tests en inglés

status: proposed
cap: 600 min
sources:
  - "pedido (texto) · mensaje del usuario en la sesión de Claude Code, 2026-11-09: «es grave, todo deberia estar en ingles, menos la parte en espa;ol de la internacionalizacion, el codigo en ingles y todo lo demas en ingles»"
  - "alcance (texto) · la porción del pedido que es esta card, del plan de la sesión: ENG-22 son los tests (títulos, nombres de archivo y carpetas, helpers y fixtures); los nombres castellanos que quedan en el código de producción y la configuración son de ENG-23"
  - "glosario · docs/technical/glossary.md (ENG-00): el nombre en inglés de cada término del dominio"
  - "relevamiento del repo en 5a4861dd (2026-11-09): 166 archivos de tests de la API (20.278 líneas), 188 de tests de la app (33.718) y 30 de integration_test (8.213), con carpetas, nombres de archivo, títulos, fixtures, helpers, variables y comentarios en castellano; `@supuesto:` en 33 archivos; ~412 capturas PNG en `test/capturas/`; en main, el CI pasa con 10 tests de pytest y 50 de flutter fallando y 19 archivos de flutter que no compilan, todos declarados reemplazados por cards anteriores"
not_read:
  - "no hay Jira: no hay comentarios, adjuntos ni enlaces que leer"

## Specs

- S1 · "todo deberia estar en ingles" · acceptance: cada carpeta y archivo de tests de `apps/api/tests`, `apps/mobile/test` y `apps/mobile/integration_test` tiene nombre en inglés y ningún test lleva la etiqueta `@supuesto:`
- S2 · "menos la parte en espa;ol de la internacionalizacion" · acceptance: el texto castellano de la app que los tests comprueban (UI, mensajes de la API, datos de prueba) queda como está
- S3 · "el codigo en ingles" · acceptance: los títulos de los tests, los nombres que declaran (funciones, clases, fixtures, helpers, variables) y sus comentarios están en inglés
- S4 · "y todo lo demas en ingles" · acceptance: lo que cita una ruta de test (docs, README, reglas del kit, configuración de ruff, mypy y el analizador, scripts) cita la ruta nueva, que existe
- ENG-22-ASM-01 · alcance: los tests y lo que sigue a sus renombres; un nombre castellano del código de producción o de la configuración es de ENG-23 y un test que lo usa (lo importa, lo sobreescribe o lo pasa como argumento) lo sigue usando como está · S3,S4
- ENG-22-ASM-02 · los registros del método en `specs/` (cards, Logs, TRAZABILIDAD) no se reescriben: citan las rutas y títulos viejos tal como eran; la card sólo declara de nuevo lo que el CI necesita (ASM-06) · S4
- ENG-22-ASM-03 · el texto castellano que un test usa o compara (UI, mensajes, datos como nombres, direcciones y correos) queda; cuando un título o comentario en inglés lo cita, va entre «» · S2
- ENG-22-ASM-04 · medida del inglés: un nombre de archivo, carpeta o declarado es castellano si tiene acento o ñ, o una palabra de la lista castellana del test (las palabras castellanas que tenían los nombres de los tests en main, más la lista del kit y las palabras frecuentes); un título o comentario es castellano si, fuera de «», comillas, código en línea, etiquetas y URLs, tiene dos palabras frecuentes castellanas (`de`, `la`, `el`, `los`, `las`, `que`, `y`, `con`, `para`, `por`, `una`, `del`, `se`, `un`, `al`, `lo`, `como`, `sin`) o una en un texto de ocho palabras o menos, o una palabra de la lista; `en` y `es` no cuentan, son los códigos de idioma de la app; un nombre que también existe en el código de producción no cuenta (ASM-01) · S3
- ENG-22-ASM-05 · carpetas: `tests/escenarios` → `tests/scenarios`, `tests/integracion` → `tests/integration`, `test/capturas` → `test/screenshots` (con `_capturas.dart` → `_screenshots.dart`), `test/rediseno` → `test/redesign`, `test/soporte` → `test/support`, `integration_test/soporte` → `integration_test/support`, y las áreas de `integration_test` `errores`, `espacios`, `inicio`, `notificaciones`, `registro`, `reservas`, `sedes`, `sesion`, `usuarios` → `errors`, `spaces`, `home`, `notifications`, `registration`, `bookings`, `venues`, `session`, `users` · S1
- ENG-22-ASM-06 · los tests que en main fallan o no compilan y una card anterior declaró reemplazados también se renombran y traducen; el Log de esta card declara de nuevo cada reemplazo con la ruta y el título nuevos del test y de su reemplazo, para que el CI siga leyéndolos como reemplazados · S1,S3
- ENG-22-ASM-07 · las capturas PNG de `test/screenshots/` se mueven (`git mv`, mismos bytes) a nombres en inglés y los archivos de capturas las siguen comparando; cada PNG que un archivo de capturas nombra existe · S1
- ENG-22-ASM-08 · HEAD sobre una ruta GET de la API responde 405, igual que en main: FastAPI no registra HEAD y esta card no toca rutas; la fila `head-unsupported` del ataque queda ignorada en `specs/ENG-22-tests-en-ingles/http-attack.config.json` con este ASM · S4

## Tasks

- T1 · S1,S4,ENG-22-ASM-01,ENG-22-ASM-02,ENG-22-ASM-05 · tests/tests-in-english.test.mjs, apps/api/tests/**, apps/mobile/test/**, apps/mobile/integration_test/**, apps/api/pyproject.toml, apps/mobile/analysis_options.yaml, apps/mobile/test/analysis_options.yaml, scripts/e2e.sh, docs/technical/system-design.md (presentation), docs/technical/code-map.md (presentation), docs/technical/architecture.md (presentation), docs/technical/data-model.md (presentation), docs/getting-started.md (presentation), docs/business/accessibility.md (presentation), apps/mobile/README.md (presentation), apps/api/README.md (presentation), .claude/STACK.md, .claude/rules/interfaz.md, tests/docs-in-english.test.mjs · las carpetas y archivos de tests pasan a su nombre en inglés (`git mv`) y lo que los cita sigue la ruta nueva · tests: tests/tests-in-english.test.mjs "every test folder and file of the apps has an English name @ENG-22-S1 @assumption:ENG-22-ASM-05"; tests/tests-in-english.test.mjs "every repo path to a test that a doc, a kit rule, a config or a script cites exists @ENG-22-S4 @assumption:ENG-22-ASM-01 @assumption:ENG-22-ASM-02"
  new: no escribe lógica de producción
- T2 · S3,ENG-22-ASM-04 · apps/api/tests/** · títulos (docstrings y nombres de las funciones de test), fixtures, helpers, variables y comentarios de los tests de la API en inglés · tests: tests/tests-in-english.test.mjs "every title, declared name and comment of the API tests is English @ENG-22-S3 @assumption:ENG-22-ASM-04"
  new: no escribe lógica de producción
- T3 · S3,ENG-22-ASM-04 · apps/mobile/test/**, apps/mobile/integration_test/** · títulos, helpers, variables y comentarios de los tests de la app en inglés · tests: tests/tests-in-english.test.mjs "every title, declared name and comment of the app tests is English @ENG-22-S3 @assumption:ENG-22-ASM-04"
  new: no escribe lógica de producción
- T4 · S1,S2,ENG-22-ASM-03 · apps/api/tests/**, apps/mobile/test/**, apps/mobile/integration_test/** · `@supuesto:` → `@assumption:`; el texto castellano que los tests comparan queda · tests: tests/tests-in-english.test.mjs "no test carries the Spanish tag supuesto @ENG-22-S1"; tests/tests-in-english.test.mjs "the Spanish detector flags Spanish names and prose and passes English that quotes Spanish UI text @ENG-22-S2 @assumption:ENG-22-ASM-03"
  new: no escribe lógica de producción
- T5 · ENG-22-ASM-06 · specs/ENG-22-tests-en-ingles/card.md · las líneas `replaces:` del Log para los tests reemplazados que siguen fallando, con su ruta y título nuevos · tests: tests/tests-in-english.test.mjs "every replacement this card declares names an existing test and a replacement that carries its tags @assumption:ENG-22-ASM-06"
  new: no escribe lógica de producción
- T7 · ENG-22-ASM-08 · apps/api/tests/unit/test_head_not_allowed.py · tests: apps/api/tests/unit/test_head_not_allowed.py "HEAD on a GET route answers 405, as on main @assumption:ENG-22-ASM-08"
  new: no escribe lógica de producción
- T6 · ENG-22-ASM-07 · apps/mobile/test/screenshots/** · las capturas PNG pasan a nombres en inglés · tests: tests/tests-in-english.test.mjs "every screenshot a screenshots file names exists under an English name @assumption:ENG-22-ASM-07"
  new: no escribe lógica de producción

## Changes to existing behavior

- las carpetas y archivos de tests de `apps/api/tests`, `apps/mobile/test` y `apps/mobile/integration_test` cambian de nombre; `scripts/e2e.sh` toma las áreas de `integration_test` con sus nombres en inglés
- los títulos de los tests cambian (traducidos); sus etiquetas `@<ID>-S<n>`, `@<ID>-H<n>` y `@assumption:<ID>-ASM-NN` quedan, y lo que cada test verifica no cambia
- los tests que leen la ruta o el nombre de otro test (`test_ci_suite_green.py`, `test_docs_follow_the_app.py`, `test_suite_confiable*.py`, `codigo_legible_test.dart`, `account_in_english*_test.dart`, `tests/docs-in-english.test.mjs`) siguen el renombre (refactor-tests)
- `.claude/kit.json` (`rules.interfaz`) sigue citando `apps/mobile/test/capturas/**`: el guard protege el archivo y `kit.mjs` no tiene comando para las rutas de una regla; queda para una persona

## Gate

```
suite [timeout 60 min]: sh D:/Temp/w/herramientas/eng22-pytest.sh -q -p no:cacheprovider
flutter [timeout 60 min]: sh D:/Temp/w/herramientas/eng22-flutter.sh
screenshots [timeout 40 min]: sh D:/Temp/w/herramientas/eng22-screenshots.sh
node: node --test --test-force-exit tests/*.test.mjs docs-site/tests/*.test.mjs
vs-main: node D:/Temp/w/herramientas/eng22-vs-main.mjs origin/main
lint: sh D:/Temp/w/herramientas/eng22-lint.sh
app: sh D:/Temp/w/herramientas/eng22-app.sh eng22_app
attacks: sh D:/Temp/w/herramientas/eng22-attacks.sh eng22_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /venues {"name": "Attack Venue", "address": "Street 1", "opens_at": "08:00", "closes_at": "23:00", "open_days": [1, 2, 3, 4, 5, 6, 7]}' --read /bookings --read /me --item-path "/bookings/all/{id}" --openapi apps/api/openapi.json
migrate-upgrade: sh D:/Temp/w/herramientas/eng22-migrate.sh
refactor-tests: los tests de cards anteriores pasan a nombres, títulos, variables y comentarios en inglés y a carpetas en inglés; sus etiquetas y lo que verifican no cambian; los que leen la ruta o el nombre de otro test siguen el renombre
no-visual: la card no toca ninguna pantalla de la app; los PNG de capturas se mueven con los mismos bytes
no-docs: la documentación sólo cambia las rutas de tests que cita; no cambia comportamiento ni contrato
```

## Log
- L1 · 2026-11-09 «es grave, todo deberia estar en ingles, menos la parte en espa;ol de la internacionalizacion, el codigo en ingles y todo lo demas en ingles» · alcance de esta card en el plan: los tests (títulos, nombres de archivo y carpetas, helpers y fixtures); el código de producción y la configuración son de ENG-23
- L2 · 2026-11-09 · sin Jira: las dudas van directo a ASM (ENG-22-ASM-01..07), sin ronda de preguntas
- L3 · 2026-11-10 · uncovered · ENG-22-ASM-08 · lo cubre el ataque HTTP de la línea attacks: del Gate (la fila head-unsupported ignorada con su motivo en http-attack.config.json), no un test etiquetado: la card no toca rutas
- L4 · 2026-11-10 · declared · restart · la card sólo renombra y traduce tests: no guarda nada que un reinicio de la app pueda perder
- L5 · 2026-11-10 · ACT-05 · ENG-22-ASM-08 sí tiene test etiquetado: apps/api/tests/unit/test_head_not_allowed.py (T7), además de la fila ignorada del ataque; L3 queda corregida por esta línea
- L6 · 2026-11-10 · ACT-03, ACT-04, ACT-06 · línea vs-main: del Gate (D:/Temp/w/herramientas/eng22-vs-main.mjs contra origin/main): las etiquetas de los tests y su cantidad son las de main más las de ENG-22, los PNG de capturas son los blobs de main byte por byte, y cada literal de los tests de main que es un texto castellano de la app (un valor de app_es.arb) sigue apareciendo igual cantidad de veces
