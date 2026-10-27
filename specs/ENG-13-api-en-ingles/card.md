# ENG-13 · la API está en inglés sobre el main de hoy, en la rama `ingles`

status: proposed
cap: 3 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «no me gusta nada que todo el codigo este en español» · elige «Todo, base y API incluidas» · «terminala en paralelo» · «dejala en su propia branch, sin tocar main»"
  - "trabajo previo · ramas ENG-01-api-base-en-ingles, ENG-02-api-sedes-usuarios-sesion-en-ingles, ENG-03-api-espacios-horarios-en-ingles, ENG-04-api-notificaciones-en-ingles, ENG-05-api-reservas-en-ingles (renombres hechos sobre main 9b83c86, compuertas sin cerrar, tope de tiempo vencido) y sus handoff.md"
  - "glosario · docs/technical/glosario-ingles.md (ENG-00, rama ENG-00-glosario-ingles)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "no me gusta nada que todo el codigo este en español" · acceptance: en `apps/api/app` la base (`main.py`, `health.py`, `e2e_support.py`, `shared/`) y los módulos (`venues`, `users`, `session`, `password_recovery`, `spaces`, `availability`, `notifications`, `bookings`) tienen archivos, clases, funciones, parámetros, variables, comentarios y docstrings en inglés según el glosario; no queda ninguna carpeta ni archivo de módulo con nombre castellano
- S2 · "Todo, base y API incluidas" · acceptance: la API responde igual que main: mismas rutas, métodos, códigos, campos JSON, parámetros, `operationId` y `security`; sólo cambian los nombres de los esquemas de `openapi.json`
- S3 · "Todo, base y API incluidas" · acceptance: la configuración lee cada variable de entorno con su nombre en inglés y con el de hoy (gana la inglesa), así Render sigue andando sin tocar sus variables; incluye `CORREO_MODO`/`EMAIL_MODE` con `brevo` y `BREVO_API_KEY`
- S4 · "dejala en su propia branch, sin tocar main" · acceptance: todo el trabajo queda en la rama `ingles`, que trae main y no se mergea a main ni se publica como PR a main
- ENG-13-ASM-01 · las claves JSON, las rutas, el SQL, los valores guardados y los textos que ve el usuario siguen en castellano: cambiarlos es la card de base y contrato, que va con un APK nuevo · S2
- ENG-13-ASM-02 · lo que main sumó después de 9b83c86 (correo por Brevo, correos con diseño, reservas y recordatorios por correo) se integra con los nombres en inglés · S1
- ENG-13-ASM-03 · los títulos y archivos de los tests quedan en castellano; los tests cambian sólo lo que el renombre obliga, con `refactor-tests:` · S1

## Tasks

- T1 · S1,S2,S3,S4,ENG-13-ASM-01,ENG-13-ASM-02,ENG-13-ASM-03 · apps/api/app/main.py (presentation), apps/api/app/health.py (presentation), apps/api/app/e2e_support.py (data), apps/api/app/shared/config.py (data), apps/api/app/shared/db.py (data), apps/api/openapi.json, docs/technical/glosario-ingles.md (presentation) · tests: apps/api/tests/unit/test_api_en_ingles.py "la base y los módulos de la API se llaman como dice el glosario y no queda ninguno en castellano @ENG-13-S1 @assumption:ENG-13-ASM-02 @assumption:ENG-13-ASM-03"; apps/api/tests/unit/test_api_en_ingles.py "la API responde con las mismas rutas, códigos, campos, operationId y security que main @ENG-13-S2 @assumption:ENG-13-ASM-01"; apps/api/tests/unit/test_api_en_ingles.py "la configuración lee cada variable en inglés y en castellano, también el modo brevo @ENG-13-S3"; apps/api/tests/unit/test_api_en_ingles.py "la rama ingles trae main y main no tiene sus commits @ENG-13-S4"
  reuses: los renombres de las ramas ENG-01..ENG-05 (se mergean en orden y se resuelven contra main), con su criterio de palabras castellanas en comentarios

## Changes to existing behavior

- none: rutas, campos, códigos, SQL y textos no cambian; cambian nombres internos y los nombres de esquema del contrato

## Gate

```
suite [timeout 2 h]: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider
fmt: cd apps/api && uv run --no-sync ruff format --check app
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/app apps/api/tests/unit/test_api_en_ingles.py
app: sh D:/Temp/w/herramientas/arq01-app.sh eng13_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh eng13_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
refactor-tests: la base y los módulos de la API cambian de nombre: los tests cambian sólo imports, símbolos y rutas de archivo
no-docs: nombres internos; el comportamiento y el modelo de datos no cambian (el glosario y el mapa del código se actualizan en T1)
no-visual: la card no toca la app
```

## Log

- L1 · no me gusta nada que todo el codigo este en español · Todo, base y API incluidas · terminala en paralelo · dejala en su propia branch, sin tocar main
- L2 · 2026-10-27 · declared · fault-db · la base es Postgres, no un archivo; la card no cambia cómo se conecta ni el SQL
- L3 · 2026-10-27 · reemplaza el cierre de ENG-01..ENG-05: sus topes vencieron con las compuertas en rojo y sus ramas quedaron sobre un main viejo; esta card las integra sobre el main de hoy
