# DAT-01 · el modelo de datos con UUIDv7 y auditoría en todas las tablas

status: proposed
cap: 6 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-26): «por que el modelo de datos no sigue el estandar de la industria? UUIDv7 y los tipicos campos de auditoria cuando se creo y cuando se actualizo» · «hacelo en paralelo»"
  - "relevamiento · plan sobre card/SIM-01 (2026-10-26): 9 tablas, 8 claves bigint identity y 17 referencias; sólo usuario, sede, espacio y reserva tienen creado_en/modificado_en con trigger; Postgres 16 (sin uuidv7 nativo); Python 3.12/3.13 (sin uuid.uuid7); la base de Render no tiene datos reales"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "UUIDv7" · acceptance: la clave de cada tabla es un `uuid` versión 7 que genera la base al insertar, y cada referencia a otra tabla es `uuid`; los ids nuevos salen en el orden en que se crean
- S2 · "los tipicos campos de auditoria cuando se creo y cuando se actualizo" · acceptance: cada tabla tiene `creado_en` y `modificado_en`; `modificado_en` lo mantiene la base al actualizar una fila
- S3 · "el estandar de la industria" (que el cambio llegue a la API y a la app) · acceptance: la API recibe y devuelve los ids como texto UUID y la app los usa así en sus pantallas y rutas; un id mal formado responde 422
- DAT-01-ASM-01 · la base genera los ids con una función SQL `uuid_v7()` creada en la migración 0010 y puesta como valor por defecto, con la fracción de milisegundo para que dos filas del mismo milisegundo salgan en orden · S1
- DAT-01-ASM-02 · las filas que ya existen reciben un UUID versión 7 armado a partir de su id viejo (marca de tiempo cero), que conserva el orden y deja todo lo viejo antes de lo nuevo; volver atrás la migración falla con un mensaje claro si ya hay filas creadas después · S1
- DAT-01-ASM-03 · las columnas de auditoría con otro nombre pasan a `creado_en` / `modificado_en` (`notificacion.creada_en`, `dispositivo.registrado_en` y `actualizado_en`, `enlace_recuperacion.emitido_en`); los campos que publica la API conservan su nombre · S2
- DAT-01-ASM-04 · `notificacion_reserva` conserva su clave compuesta (avisos y reservas) y suma `creado_en` / `modificado_en` · S1,S2
- DAT-01-ASM-05 · un aviso push ya enviado a una app vieja con `reserva_id` numérico no abre la reserva; la app nueva lee el UUID · S3

## Tasks

- T1 · S1,S2,DAT-01-ASM-01,DAT-01-ASM-02,DAT-01-ASM-03,DAT-01-ASM-04 · apps/api/migraciones/versions/0010_identificadores_uuid_y_auditoria.py (data) · tests: apps/api/tests/integracion/test_uuid_y_auditoria.py "después de la migración 0010 toda clave es uuid con valor por defecto uuid_v7() y toda referencia es uuid @DAT-01-S1 @assumption:DAT-01-ASM-01"; apps/api/tests/integracion/test_uuid_y_auditoria.py "los ids nuevos son versión 7 y salen en el orden en que se crean @DAT-01-S1"; apps/api/tests/integracion/test_uuid_y_auditoria.py "la migración 0010 da a las filas existentes un UUID versión 7 con sus relaciones intactas y vuelve atrás si no hay filas nuevas @assumption:DAT-01-ASM-02"; apps/api/tests/integracion/test_uuid_y_auditoria.py "cada tabla tiene creado_en y modificado_en y la base actualiza modificado_en @DAT-01-S2 @assumption:DAT-01-ASM-03 @assumption:DAT-01-ASM-04"
  new: no hay migración que convierta claves; la función uuid_v7 no existe en Postgres 16
- T2 · S3 · apps/api/app (los repositorios, casos de uso y rutas que usan ids, después de ARQ-04), apps/api/openapi.json · tests: apps/api/tests/integracion/test_uuid_y_auditoria.py "la API devuelve y recibe los ids como texto UUID y un id mal formado responde 422 @DAT-01-S3"
  reuses: el tipo `Identificador` de entradas.py, que pasa a UUID en un solo lugar
- T3 · S3,DAT-01-ASM-05 · apps/mobile/lib/espacios/espacio.dart (data), apps/mobile/lib/sedes/sede.dart (data), apps/mobile/lib/sedes/fotos.dart (presentation), apps/mobile/lib/reservas/reservas.dart (data), apps/mobile/lib/admin/historial_reservas.dart (data), apps/mobile/lib/notificaciones/notificacion.dart (data), apps/mobile/lib/app.dart (presentation) · tests: apps/mobile/test/ids_uuid_test.dart "la app lee los ids como texto UUID y navega con ellos @DAT-01-S3"; apps/mobile/test/ids_uuid_test.dart "un aviso con reserva_id UUID abre la reserva @assumption:DAT-01-ASM-05"
  reuses: los modelos existentes; el id pasa de int a String

## Changes to existing behavior

- base de datos · claves y referencias pasan de bigint a uuid (migración 0010); columnas de auditoría renombradas y agregadas
- API · los ids viajan como texto UUID en rutas, cuerpos y respuestas; `openapi.json` los publica como `string` `uuid`
- app · los ids son texto

## Look

- remove-only: ninguna pantalla cambia lo que muestra; sólo el tipo de los ids que usa

## Gate

```
suite: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/app apps/api/tests apps/mobile
migrate-upgrade: cd apps/api && sh -c "DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8701/club_dat01_migra uv run --no-sync alembic upgrade head"
app-suite: sh D:/Temp/w/herramientas/flutter-mobile.sh
app: sh D:/Temp/w/herramientas/arq01-app.sh dat01_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh dat01_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
```

## Log

- L1 · por que el modelo de datos no sigue el estandar de la industria? UUIDv7 y los tipicos campos de auditoria cuando se creo y cuando se actualizo · hacelo en paralelo
- L2 · 2026-10-26 · orden: T1 (base) y T3 (app) arrancan ya; T2 (API) espera a que ARQ-04 se integre, porque mueve esos archivos
- L3 · 2026-10-26 · declared · fault-db · la base es Postgres, no un archivo; la suite de integración la usa como siempre
