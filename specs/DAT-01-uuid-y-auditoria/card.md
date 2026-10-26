# DAT-01 · el modelo de datos con UUIDv7 y auditoría en todas las tablas

status: proposed
cap: 6 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-26): «por que el modelo de datos no sigue el estandar de la industria? UUIDv7 y los tipicos campos de auditoria cuando se creo y cuando se actualizo» · «hacelo en paralelo»"
  - "relevamiento · plan sobre card/SIM-01 (2026-10-26): 9 tablas, 8 claves bigint identity y 17 referencias; sólo usuario, sede, espacio y reserva tienen creado_en/modificado_en con trigger; Postgres 16 (sin uuidv7 nativo); Python 3.12/3.13 (sin uuid.uuid7); la base de Render no tiene datos reales"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "UUIDv7" · acceptance: la clave de cada una de las 9 tablas (usuario, sede, espacio, reserva, enlace_recuperacion, correo_saliente, dispositivo, notificacion; notificacion_reserva por su clave compuesta) es un `uuid` versión 7 que genera la base al insertar, y cada una de las 17 referencias a otra tabla es `uuid`; los ids nuevos salen en el orden en que se crean
- S2 · "los tipicos campos de auditoria cuando se creo y cuando se actualizo" · acceptance: cada una de las 9 tablas tiene `creado_en` y `modificado_en`; `modificado_en` lo mantiene la base al actualizar una fila
- S3 · "el estandar de la industria" (que el cambio llegue a la API y a la app) · acceptance: la API recibe y devuelve los ids como texto UUID en rutas, cuerpos y consultas, y la app los usa así en sus pantallas y rutas; un id mal formado responde 422 y un UUID que no existe, 404
- DAT-01-ASM-01 · la base genera los ids con una función SQL `uuid_v7()` creada en la migración 0010 y puesta como valor por defecto, con la fracción de milisegundo para que dos filas del mismo milisegundo salgan en orden · S1
- DAT-01-ASM-02 · las filas que ya existen reciben un UUID versión 7 armado a partir de su id viejo (marca de tiempo cero), que conserva el orden y deja todo lo viejo antes de lo nuevo; volver atrás la migración falla con un mensaje claro si ya hay filas creadas después · S1
- DAT-01-ASM-03 · las columnas de auditoría con otro nombre pasan a `creado_en` / `modificado_en` (`notificacion.creada_en`, `dispositivo.registrado_en` y `actualizado_en`, `enlace_recuperacion.emitido_en`); los campos que publica la API conservan su nombre · S2
- DAT-01-ASM-04 · `notificacion_reserva` conserva su clave compuesta (avisos y reservas) y suma `creado_en` / `modificado_en` · S1,S2
- DAT-01-ASM-05 · un aviso push ya enviado a una app vieja con `reserva_id` numérico no abre la reserva: abre el centro de notificaciones; la app nueva lee el UUID y abre la reserva · S3
- DAT-01-ASM-06 · la API acepta como id cualquier texto UUID que lea Pydantic (mayúsculas o minúsculas, con o sin guiones, de cualquier versión) y siempre responde en minúsculas con guiones · S3
- DAT-01-ASM-07 · en las filas que ya existen, `creado_en` conserva la fecha que la tabla ya tenía (la columna renombrada) y, donde no había ninguna (`notificacion_reserva`), es el momento de la migración; `modificado_en` arranca igual a `creado_en` · S2
- DAT-01-ASM-08 · un método que una ruta no admite responde 405 aunque el id esté mal formado: FastAPI elige la ruta antes de validar · S3

## Tasks

- T1 · S1,S2,DAT-01-ASM-01,DAT-01-ASM-02,DAT-01-ASM-03,DAT-01-ASM-04,DAT-01-ASM-07 · apps/api/migraciones/versions/0010_identificadores_uuid_y_auditoria.py (data) · tests: apps/api/tests/integracion/test_uuid_y_auditoria.py "después de la migración 0010 la clave de usuario, sede, espacio, reserva, enlace_recuperacion, correo_saliente, dispositivo y notificacion es uuid con valor por defecto uuid_v7() @DAT-01-S1 @assumption:DAT-01-ASM-01"; apps/api/tests/integracion/test_uuid_y_auditoria.py "las 17 referencias entre tablas, también las de notificacion_reserva, son uuid y apuntan a la tabla correcta @DAT-01-S1 @assumption:DAT-01-ASM-04"; apps/api/tests/integracion/test_uuid_y_auditoria.py "los ids nuevos son versión 7 y salen en el orden en que se crean @DAT-01-S1"; apps/api/tests/integracion/test_uuid_y_auditoria.py "la migración 0010 da a las filas existentes un UUID versión 7 con sus relaciones intactas y vuelve atrás si no hay filas nuevas @assumption:DAT-01-ASM-02"; apps/api/tests/integracion/test_uuid_y_auditoria.py "cada una de las 9 tablas tiene creado_en y modificado_en y la base actualiza modificado_en @DAT-01-S2 @assumption:DAT-01-ASM-03 @assumption:DAT-01-ASM-04"; apps/api/tests/integracion/test_uuid_y_auditoria.py "las filas existentes conservan su fecha en creado_en y modificado_en arranca igual @assumption:DAT-01-ASM-07"
  new: no hay migración que convierta claves; la función uuid_v7 no existe en Postgres 16
- T2 · S3,DAT-01-ASM-06,DAT-01-ASM-08 · apps/api/app (los repositorios, casos de uso y rutas que usan ids, después de ARQ-04), apps/api/openapi.json · tests: apps/api/tests/integracion/test_uuid_y_auditoria.py "la API devuelve y recibe los ids como texto UUID en rutas, cuerpos y consultas @DAT-01-S3"; apps/api/tests/integracion/test_uuid_y_auditoria.py "un id mal formado en la ruta, en el cuerpo o en la consulta responde 422 y un UUID que no existe responde 404 @DAT-01-S3"; apps/api/tests/integracion/test_uuid_y_auditoria.py "un UUID en mayúsculas o sin guiones se acepta y la respuesta lo trae en minúsculas con guiones @assumption:DAT-01-ASM-06"; apps/api/tests/integracion/test_uuid_y_auditoria.py "un método no admitido responde 405 aunque el id esté mal formado @assumption:DAT-01-ASM-08"
  reuses: el tipo `Identificador` de entradas.py, que pasa a UUID en un solo lugar
- T3 · S3,DAT-01-ASM-05 · apps/mobile/lib/espacios/espacio.dart (data), apps/mobile/lib/sedes/sede.dart (data), apps/mobile/lib/sedes/fotos.dart (presentation), apps/mobile/lib/reservas/reservas.dart (data), apps/mobile/lib/admin/historial_reservas.dart (data), apps/mobile/lib/notificaciones/notificacion.dart (data), apps/mobile/lib/app.dart (presentation), apps/mobile/lib/espacios/espacios.dart (data), apps/mobile/lib/sedes/sedes.dart (data), apps/mobile/lib/reservas/horarios.dart (data), apps/mobile/lib/notificaciones/notificaciones.dart (data), apps/mobile/lib/notificaciones/centro.dart (rule), apps/mobile/lib/notificaciones/sistema.dart (rule), apps/mobile/lib/notificaciones/sistema_fcm.dart (data), apps/mobile/lib/reservas/pantalla_horarios.dart (presentation), apps/mobile/lib/reservas/pantalla_mis_reservas.dart (presentation), apps/mobile/lib/reservas/cancelacion.dart (presentation), apps/mobile/lib/sedes/pantalla_sede.dart (presentation), apps/mobile/lib/inicio/pantalla_inicio.dart (presentation), apps/mobile/lib/admin/pantalla_espacios_admin.dart (presentation), apps/mobile/lib/admin/pantalla_sedes_admin.dart (presentation), apps/mobile/lib/admin/pantalla_filtros_reservas.dart (presentation) · tests: apps/mobile/test/ids_uuid_test.dart "la app lee los ids como texto UUID y navega con ellos @DAT-01-S3"; apps/mobile/test/ids_uuid_test.dart "un aviso con reserva_id UUID abre la reserva y uno con reserva_id numérico abre el centro de notificaciones @assumption:DAT-01-ASM-05"
  reuses: los modelos existentes; el id pasa de int a String

## Changes to existing behavior

- base de datos · claves y referencias pasan de bigint a uuid (migración 0010); columnas de auditoría renombradas y agregadas
- API · los ids viajan como texto UUID en rutas, cuerpos y respuestas; `openapi.json` los publica como `string` `uuid`
- app · los ids son texto; una app ya instalada de antes de esta card no funciona contra la API nueva y hay que actualizarla
- avisos push · uno viejo con `reserva_id` numérico abre el centro de notificaciones en vez de la reserva

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
- L4 · 2026-10-26 · plan judge: ACT-01..06 cerrados con las 9 tablas y 17 referencias nombradas en S1/S2 y sus tests, los casos 422/404 de S3, DAT-01-ASM-05..08 con sus tests y la app vieja en «Changes to existing behavior»; ver judge.md
- L5 · 2026-10-26 · replaces: test/ids_uuid_test.dart (sus tests) · no compilaba: usa catalogoJson sin importar soporte/admin.dart · by: test/ids_uuid_app_test.dart (mismos títulos y tags)
- L6 · 2026-10-26 · replaces: test/anular_desde_el_detalle_test.dart (sus tests) · ids pasan a UUID en los datos de prueba · by: test/anular_desde_el_detalle_uuid_test.dart (mismos títulos y tags)
- L7 · 2026-10-26 · replaces: test/interfaz_accesible_test.dart (sus tests) · ids pasan a UUID en los datos de prueba · by: test/interfaz_accesible_uuid_test.dart (mismos títulos y tags)
- L8 · 2026-10-26 · replaces: test/interfaz_accesible_supuestos_test.dart (sus tests) · ids pasan a UUID en los datos de prueba (importaba el anterior) · by: test/interfaz_accesible_supuestos_uuid_test.dart (mismos títulos y tags)
- L9 · 2026-10-26 · replaces: test/rediseno/movimiento_pantallas_test.dart (sus tests) · ids pasan a UUID en los datos de prueba · by: test/rediseno/movimiento_pantallas_uuid_test.dart (mismos títulos y tags)
- L10 · 2026-10-26 · replaces: test/rediseno/pantallas_test.dart (sus tests) · ids pasan a UUID en los datos de prueba · by: test/rediseno/pantallas_uuid_test.dart (mismos títulos y tags)
- L11 · 2026-10-26 · replaces: test/rediseno/transiciones_test.dart (sus tests) · ids pasan a UUID en los datos de prueba · by: test/rediseno/transiciones_uuid_test.dart (mismos títulos y tags)
- L12 · 2026-10-26 · replaces: test/rutas_de_la_api_test.dart (sus tests) · ids pasan a UUID en los datos de prueba · by: test/rutas_de_la_api_uuid_test.dart (mismos títulos y tags)
- L13 · 2026-10-26 · replaces: test/sin_sobreingenieria_a11y_test.dart (sus tests) · ids pasan a UUID en los datos de prueba · by: test/sin_sobreingenieria_a11y_uuid_test.dart (mismos títulos y tags)
- L14 · 2026-10-26 · T3 · app lee ids como texto UUID: flutter analyze, flutter test completo y capturas verdes (salidas en el reporte del builder)
