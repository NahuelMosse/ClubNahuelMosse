# ENG-00 · el glosario fija cómo se llama en inglés cada concepto del código

status: proposed
cap: 1 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «no me gusta nada que todo el codigo este en español» · elige «Todo, base y API incluidas» · «deja haciendo la migracion a ingles en segundo plano, que como vos dijiste es grande»"
  - "relevamiento · plan del planner sobre main 9b83c86 (2026-10-27): glosario castellano→inglés de módulos, archivos, tablas, columnas, valores, rutas, campos JSON, clases y funciones; secuencia de cards ENG-01..ENG-12"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "no me gusta nada que todo el codigo este en español" · acceptance: docs/technical/glosario-ingles.md da, para cada módulo de la API, cada tabla de la base y cada ruta de la API que existen hoy, su nombre en inglés, y ningún término castellano tiene dos traducciones
- ENG-00-ASM-01 · `reserva` es `booking`, `sede` es `venue`, `espacio` es `space`, `tipo` es `kind` y la tabla `usuario` es `app_user` (por qué, en el glosario) · S1
- ENG-00-ASM-02 · los títulos de los tests con tag y sus nombres de archivo quedan en castellano: 281 líneas `replaces:` los nombran por título exacto; traducirlos es una card aparte · S1
- ENG-00-ASM-03 · queda en castellano lo que ve el usuario, los contenidos guardados (avisos, correos), las claves del catálogo, `dni`, las migraciones 0001–0010 y los registros de `specs/` · S1

## Tasks

- T1 · S1,ENG-00-ASM-01,ENG-00-ASM-02,ENG-00-ASM-03 · docs/technical/glosario-ingles.md (presentation), apps/api/tests/unit/test_glosario_ingles.py · tests: apps/api/tests/unit/test_glosario_ingles.py "el glosario traduce cada módulo, tabla y ruta de la API de hoy, una sola vez @ENG-00-S1"; apps/api/tests/unit/test_glosario_ingles.py "el glosario fija booking, venue, space, kind y app_user, deja en castellano los títulos de test y lo que ve el usuario @assumption:ENG-00-ASM-01 @assumption:ENG-00-ASM-02 @assumption:ENG-00-ASM-03"
  new: no había glosario; el repo nombraba todo en castellano

## Changes to existing behavior

- none: la card sólo agrega la página del glosario y su test

## Gate

```
suite: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_glosario_ingles.py
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/tests/unit/test_glosario_ingles.py
app: sh D:/Temp/w/herramientas/arq01-app.sh eng00_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh eng00_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
no-visual: la card agrega documentación; ninguna pantalla
```

## Log

- L1 · no me gusta nada que todo el codigo este en español · Todo, base y API incluidas · deja haciendo la migracion a ingles en segundo plano, que como vos dijiste es grande
- L2 · 2026-10-27 · plan: ENG-01..ENG-05 la API por módulo y ENG-08..ENG-11 la app por carpeta, sin cambiar base ni contrato; ENG-06 (base, migración 0011) y ENG-07 (contrato de la API y capa de datos de la app) van juntas al final, con APK nuevo; ENG-12 la documentación
