# ENG-04 · el módulo de notificaciones de la API está en inglés

status: proposed
cap: 2 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «no me gusta nada que todo el codigo este en español» · elige «Todo, base y API incluidas» · «hacelo en paralelo» · «estamos en etapa critica, necesito que todo lo que hagamos se haga lo mas rapido posible» · elige «Seguir con todo»"
  - "glosario · docs/technical/glosario-ingles.md (ENG-00, ampliado en ENG-01)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "no me gusta nada que todo el codigo este en español" · acceptance: `apps/api/app/modules/` tiene `notifications/` con sus archivos en inglés según el glosario (`use_cases.py`, `rules.py`, `repository.py`, `routes.py`, `store.py`, `sweep.py`, `push.py`); no queda `notificaciones/`
- S2 · "no me gusta nada que todo el codigo este en español" · acceptance: en ese módulo cada clase, función, parámetro, atributo, variable, constante, comentario y docstring está en inglés: ningún identificador usa un término castellano del glosario y ningún comentario ni docstring tiene palabras castellanas comunes (`de`, `la`, `el`, `los`, `las`, `que`, `por`, `para`, `con`, `una`, `del`, `sin`, `cuando`, `si`); los textos de los avisos, el SQL, las rutas, las claves JSON y los datos del push no cambian
- S3 · "Todo, base y API incluidas" · acceptance: el contrato tiene las mismas rutas, métodos, códigos, campos y `operationId` que el de main; sólo cambian los nombres de los esquemas; el mensaje push lleva el mismo título, cuerpo, datos y clave de reemplazo que hoy
- ENG-04-ASM-01 · los nombres de los esquemas de `openapi.json` siguen a las clases en inglés y el archivo se regenera: la app no los lee, lee rutas y campos · S3
- ENG-04-ASM-02 · los demás módulos y `app/main.py` cambian sólo las líneas que importan este módulo · S1
- ENG-04-ASM-03 · los tests cambian sólo lo que el renombre obliga con `refactor-tests:`; títulos y nombres de archivo de test quedan en castellano · S1
- ENG-04-ASM-04 · un nombre que el glosario no tiene se traduce con el mismo criterio y se agrega al glosario · S2
- ENG-04-ASM-05 · los campos de los modelos Pydantic (`token`, `plataforma`, `permiso`, `errores`, `titulo`, `cuerpo`, `reserva_id`, `creada_en`, `leida`, `notificaciones`, `no_leidas`) siguen en castellano: son claves JSON y `loc` de validación; las clases van en inglés y no hay alias; el test de S2 los exime · S2 (test: S2)
- ENG-04-ASM-06 · las claves y valores de los datos del push y los textos de los avisos no cambian; las claves SQL y los valores guardados tampoco · S3 (test: S3 compara `armar_mensaje`/`build_message`)
- ENG-04-ASM-07 · `scripts/e2e.sh` y `app/e2e_support.py` cambian sólo las rutas de módulo que importan · S1 (test: S1)
- ENG-04-ASM-08 · los docs que nombran las rutas del módulo (`docs/technical/mapa-del-codigo.md`, `apps/api/README.md`, los que leen los tests de docs) se actualizan · S1 (test: S1)
- ENG-04-ASM-09 · cada operación lleva `operation_id` explícito con el valor de hoy, así los `operationId` no cambian; el test de S3 compara también parámetros y `security` por operación · S3 (test: S3)

## Tasks

- T1 · S1,S2,S3,ENG-04-ASM-01,ENG-04-ASM-02,ENG-04-ASM-03,ENG-04-ASM-04 · apps/api/app/modules/notifications/__init__.py (presentation), apps/api/app/modules/notifications/use_cases.py (rule), apps/api/app/modules/notifications/rules.py (rule), apps/api/app/modules/notifications/store.py (rule), apps/api/app/modules/notifications/repository.py (data), apps/api/app/modules/notifications/sweep.py (data), apps/api/app/modules/notifications/push.py (data), apps/api/app/modules/notifications/routes.py (presentation), apps/api/openapi.json, docs/technical/glosario-ingles.md (presentation) · tests: apps/api/tests/unit/test_modulo_notificaciones_en_ingles.py "el módulo de notificaciones se llama como dice el glosario @ENG-04-S1 @assumption:ENG-04-ASM-02 @assumption:ENG-04-ASM-03"; apps/api/tests/unit/test_modulo_notificaciones_en_ingles.py "los nombres, comentarios y docstrings de notificaciones están en inglés @ENG-04-S2 @assumption:ENG-04-ASM-04"; apps/api/tests/unit/test_modulo_notificaciones_en_ingles.py "el contrato y el mensaje push de notificaciones son los de main @ENG-04-S3 @assumption:ENG-04-ASM-01"
  reuses: cada archivo de notificaciones cambia de nombre y conserva lo que hace; apps/api/tests/unit/test_base_en_ingles.py (el mismo criterio de palabras castellanas)

## Changes to existing behavior

- none: rutas, campos, códigos, SQL, avisos y push no cambian; cambian nombres internos y los nombres de esquema del contrato

## Gate

```
suite [timeout 2 h]: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider
fmt: cd apps/api && uv run --no-sync ruff format --check app tests/unit/test_modulo_notificaciones_en_ingles.py
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/app apps/api/tests/unit/test_modulo_notificaciones_en_ingles.py
app: sh D:/Temp/w/herramientas/arq01-app.sh eng04_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh eng04_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
refactor-tests: el módulo de notificaciones cambia de nombre: los tests cambian sólo imports, símbolos y rutas de archivo
no-docs: nombres internos; el comportamiento y el modelo de datos no cambian (el glosario se actualiza en T1)
```

## Log

- L1 · no me gusta nada que todo el codigo este en español · Todo, base y API incluidas · hacelo en paralelo · estamos en etapa critica, necesito que todo lo que hagamos se haga lo mas rapido posible · Seguir con todo
- L2 · 2026-10-27 · declared · fault-db · la base es Postgres, no un archivo; la card no cambia cómo se conecta ni el SQL
- L3 · 2026-10-27 · parte de ENG-01 (base de la API en inglés), en paralelo con ENG-02, ENG-03 y ENG-05: cada una renombra sus módulos y sólo las líneas de import de los otros
- L4 · 2026-10-27 · T1 · renombre aplicado (commits 388ffef, a6b210f, 1758626 + último); `test_modulo_notificaciones_en_ingles.py` 3 passed; gate `node .claude/tools/verify.mjs` en rojo: fmt passed, attacks passed, specs/overdesign/migrations/boundaries passed; suite 26 failed/198 errors (DB compartida por otras cards y emulador Auth caído en parte; fallos de ENG-01 ajenos: test_base_en_ingles `/_pruebas/`, `type: ignore` en test_config_en_ingles.py:91, firmas de test_codigo_legible, README URL_PUBLICA, test_suite_confiable); lint failed: F811 en tests/escenarios/test_basquet_3x3.py (previo) y B033 en el test RED (no editable); layers/shape: SQL en e2e_support/reservas y push.py ya existían antes del renombre; required: faltan mutación de rules/store/use_cases, archivos de importadores y pyproject.toml fuera de `## Tasks`, K4 por archivos renombrados, judge.md (review high)
- L5 · 2026-10-27 · gate red · pytest · `pyproject.toml` ignora `MulticastMessage.tokens` DeprecationWarning (el test RED nuevo no lo marca como test_push.py); queda por correr con emulador: tests/escenarios de cancelación forzosa y confirmación (29, ERROR de setup sin emulador 9099)
