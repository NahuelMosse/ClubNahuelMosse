# ENG-01 · la base de la API (shared, config, main, health, e2e_support) está en inglés

status: proposed
cap: 2 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «no me gusta nada que todo el codigo este en español» · elige «Todo, base y API incluidas» · «deja haciendo la migracion a ingles en segundo plano, que como vos dijiste es grande» · «hacelo en paralelo»"
  - "glosario · docs/technical/glosario-ingles.md (ENG-00): secciones «Carpetas y archivos», «Clases y funciones principales», «Rutas de pantalla y variables de entorno», «Reglas»"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "no me gusta nada que todo el codigo este en español" · acceptance: en `apps/api/app/` y `apps/api/app/shared/` los archivos se llaman `main.py`, `health.py`, `e2e_support.py`, `config.py`, `db.py`, `firebase_credential.py`, `body_limit.py`, `input_validation.py`, `errors.py`, `http_errors.py`, `identity.py`, `responses.py`, `club_timezone.py`; no queda `salud.py`, `pruebas.py`, `credencial_firebase.py`, `cuerpo.py`, `entradas.py`, `errores.py`, `errores_http.py`, `identidad.py`, `respuestas.py` ni `zona.py`
- S2 · "no me gusta nada que todo el codigo este en español" · acceptance: en esos archivos cada clase, función, parámetro, atributo, variable y constante definida, y cada comentario y docstring, está en inglés según el glosario; los textos que ve el usuario o que viajan en la API (mensajes, claves JSON, valores) no cambian
- S3 · "Todo, base y API incluidas" · acceptance: la API sigue respondiendo igual: el contrato publicado (`apps/api/openapi.json`) es byte a byte el de main, `/health` responde el mismo cuerpo, y `/_pruebas/...` sigue en la misma ruta (su traducción es de ENG-07)
- S4 · "Todo, base y API incluidas" · acceptance: la configuración lee las variables de entorno con su nombre en inglés (`FIREBASE_CREDENTIALS_JSON`, `PUBLIC_URL`, `EMAIL_MODE`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `EMAIL_SENDER`, `E2E_TESTING`, `REMINDERS_EVERY`) y también con el de hoy (`FIREBASE_CREDENCIALES_JSON`, `URL_PUBLICA`, `CORREO_MODO`, `SMTP_PUERTO`, `SMTP_USUARIO`, `SMTP_CONTRASENA`, `CORREO_REMITENTE`, `PRUEBAS`, `RECORDATORIOS_CADA`); con las dos, gana la inglesa
- ENG-01-ASM-01 · `EMAIL_MODE` acepta `outbox` y también `buzon` (el valor de hoy en `scripts/e2e.sh` y en el entorno de los tests), y los dos significan lo mismo · S4
- ENG-01-ASM-02 · `render.yaml` y `scripts/e2e.sh` siguen con los nombres de variables de hoy: cambiarlos en Render pide cargar los secretos de nuevo a mano; los pasa la card de documentación del final · S4
- ENG-01-ASM-03 · los tests cambian sólo lo que el renombre obliga (imports, símbolos, rutas de archivo) con `refactor-tests:`; sus títulos y nombres de archivo quedan como están (R4 del glosario) · S1
- ENG-01-ASM-04 · un nombre de estos archivos que el glosario no tiene se traduce con el mismo criterio y se agrega al glosario en esta card (R3) · S2

## Tasks

- T1 · S1,S2,S3,ENG-01-ASM-03,ENG-01-ASM-04 · apps/api/app/main.py (presentation), apps/api/app/health.py (presentation), apps/api/app/e2e_support.py (data), apps/api/app/shared/db.py (data), apps/api/app/shared/firebase_credential.py (data), apps/api/app/shared/body_limit.py (presentation), apps/api/app/shared/input_validation.py (presentation), apps/api/app/shared/errors.py (rule), apps/api/app/shared/http_errors.py (presentation), apps/api/app/shared/identity.py (data), apps/api/app/shared/responses.py (presentation), apps/api/app/shared/club_timezone.py (rule), apps/api/app/shared/__init__.py (data), docs/technical/glosario-ingles.md (presentation) · tests: apps/api/tests/unit/test_base_en_ingles.py "los archivos de la base de la API se llaman como dice el glosario @ENG-01-S1"; apps/api/tests/unit/test_base_en_ingles.py "los nombres, comentarios y docstrings de la base de la API están en inglés @ENG-01-S2 @assumption:ENG-01-ASM-04"; apps/api/tests/unit/test_base_en_ingles.py "el contrato, la salud y la ruta de pruebas responden igual que en main @ENG-01-S3"; apps/api/tests/unit/test_base_en_ingles.py "ningún test importa un módulo de la base con su nombre en castellano @assumption:ENG-01-ASM-03"
  reuses: apps/api/app/shared (cada archivo cambia de nombre y conserva su contenido); apps/api/tests/unit/test_glosario_ingles.py `_traducciones` (lee los pares del glosario)
- T2 · S4,ENG-01-ASM-01,ENG-01-ASM-02 · apps/api/app/shared/config.py (data) · tests: apps/api/tests/unit/test_config_en_ingles.py "la configuración lee cada variable con su nombre en inglés y con el de hoy, y gana la inglesa @ENG-01-S4"; apps/api/tests/unit/test_config_en_ingles.py "el modo de correo acepta outbox y buzon como lo mismo @assumption:ENG-01-ASM-01"; apps/api/tests/unit/test_config_en_ingles.py "render.yaml y scripts/e2e.sh siguen con los nombres de hoy y la configuración los lee @assumption:ENG-01-ASM-02"
  reuses: apps/api/app/shared/config.py `Settings` (pydantic-settings; cada campo suma `validation_alias=AliasChoices(inglés, castellano)`)

## Changes to existing behavior

- none: el contrato, las rutas, los cuerpos, la base y los textos no cambian; cambian nombres internos y la configuración acepta además los nombres en inglés

## Gate

```
suite [timeout 2 h]: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider
fmt: cd apps/api && uv run --no-sync ruff format --check app tests/unit/test_base_en_ingles.py tests/unit/test_config_en_ingles.py
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/app apps/api/tests/unit/test_base_en_ingles.py apps/api/tests/unit/test_config_en_ingles.py
app: sh D:/Temp/w/herramientas/arq01-app.sh eng01_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh eng01_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
refactor-tests: los módulos de la base de la API cambian de nombre (salud, pruebas y los de shared): los tests cambian sólo imports, símbolos y rutas de archivo
no-docs: nombres internos; el contrato, la base y el comportamiento no cambian (el glosario se actualiza en T1)
```

## Log

- L1 · no me gusta nada que todo el codigo este en español · Todo, base y API incluidas · deja haciendo la migracion a ingles en segundo plano, que como vos dijiste es grande · hacelo en paralelo
- L2 · 2026-10-27 · plan: primera card de la cadena de la API (ENG-01..ENG-05), en paralelo con la de la app (ENG-08..ENG-11); parte de ENG-00 (glosario) y no toca módulos de funcionalidad, base ni contrato
- L3 · 2026-10-27 · declared · fault-db · la base es Postgres, no un archivo; la card no cambia cómo se conecta ni el SQL
