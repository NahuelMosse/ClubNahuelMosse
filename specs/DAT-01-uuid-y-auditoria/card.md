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
- T2 · S3,DAT-01-ASM-06,DAT-01-ASM-08 · apps/api/app/shared/entradas.py (presentation), apps/api/app/modules (los repositorios, casos de uso, reglas y rutas que usan ids), apps/api/openapi.json · tests: apps/api/tests/integracion/test_uuid_api.py "la API devuelve y recibe los ids como texto UUID en rutas, cuerpos y consultas @DAT-01-S3"; apps/api/tests/integracion/test_uuid_api.py "un id mal formado en la ruta, en el cuerpo o en la consulta responde 422 y un UUID que no existe responde 404 @DAT-01-S3"; apps/api/tests/integracion/test_uuid_api.py "un UUID en mayúsculas o sin guiones se acepta y la respuesta lo trae en minúsculas con guiones @assumption:DAT-01-ASM-06"; apps/api/tests/integracion/test_uuid_api.py "un método no admitido responde 405 aunque el id esté mal formado @assumption:DAT-01-ASM-08"
  reuses: el tipo `Identificador` de shared/entradas.py, que pasa a UUID en un solo lugar
- T3 · S3,DAT-01-ASM-05 · apps/mobile/lib/espacios/espacio.dart (data), apps/mobile/lib/sedes/sede.dart (data), apps/mobile/lib/sedes/fotos.dart (presentation), apps/mobile/lib/reservas/reservas.dart (data), apps/mobile/lib/admin/historial_reservas.dart (data), apps/mobile/lib/notificaciones/notificacion.dart (data), apps/mobile/lib/app.dart (presentation) · tests: apps/mobile/test/ids_uuid_app_test.dart "la app lee los ids como texto UUID y navega con ellos @DAT-01-S3"; apps/mobile/test/ids_uuid_app_test.dart "un aviso con reserva_id UUID abre la reserva y uno con reserva_id numérico abre el centro de notificaciones @assumption:DAT-01-ASM-05"
  reuses: los modelos existentes; el id pasa de int a String
- T4 · S1,S2,DAT-01-ASM-01,DAT-01-ASM-03,DAT-01-ASM-04 · docs/technical/modelo-de-datos.md · tests: apps/api/tests/unit/test_documentacion_del_modelo.py "cada tabla y columna que nombra la página del modelo de datos existe en las migraciones @DOC-01-S1"; apps/api/tests/escenarios/test_documentacion_modelo_uuid.py "el modelo de datos documenta las nueve tablas con sus columnas vigentes @REV-07-S8 @DAT-01-S2"
  reuses: la página del modelo de DOC-01, con las claves uuid, uuid_v7() y creado_en/modificado_en en las 9 tablas

## Changes to existing behavior

- base de datos · claves y referencias pasan de bigint a uuid (migración 0010); columnas de auditoría renombradas y agregadas
- API · los ids viajan como texto UUID en rutas, cuerpos y respuestas; `openapi.json` los publica como `string` `uuid`
- app · los ids son texto; una app ya instalada de antes de esta card no funciona contra la API nueva y hay que actualizarla
- avisos push · uno viejo con `reserva_id` numérico abre el centro de notificaciones en vez de la reserva

## Look

- remove-only: ninguna pantalla cambia lo que muestra; sólo el tipo de los ids que usa

## Gate

```
suite [timeout 2 h]: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/app apps/api/tests apps/mobile
migrate-upgrade: cd apps/api && sh -c "DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8701/club_dat01_migra uv run --no-sync alembic upgrade head"
app-suite: sh D:/Temp/w/herramientas/flutter-mobile.sh
app: sh D:/Temp/w/herramientas/arq01-app.sh dat01_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh dat01_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
refactor-tests: los ids pasan de int a UUID en toda la API: los tests que arman ids o comparan con números se ajustan en su lugar
```

## Log

- L1 · por que el modelo de datos no sigue el estandar de la industria? UUIDv7 y los tipicos campos de auditoria cuando se creo y cuando se actualizo · hacelo en paralelo
- L2 · 2026-10-26 · orden: T1 (base) y T3 (app) arrancan ya; T2 (API) espera a que ARQ-04 se integre, porque mueve esos archivos
- L3 · 2026-10-26 · declared · fault-db · la base es Postgres, no un archivo; la suite de integración la usa como siempre
- L4 · 2026-10-26 · plan judge: ACT-01..06 cerrados con las 9 tablas y 17 referencias nombradas en S1/S2 y sus tests, los casos 422/404 de S3, DAT-01-ASM-05..08 con sus tests y la app vieja en «Changes to existing behavior»; ver judge.md
- L5 · 2026-10-26 · T1 · `sh D:/Temp/w/herramientas/arq01-pytest.sh -q tests/integracion/test_uuid_y_auditoria.py` → 6 passed (rojo en 73b13cb, verde con 0010; subida 0009→0010, bajada, subida y bajada rechazada con filas nuevas); ruff check, ruff format y mypy --strict limpios sobre test y migración; `alembic upgrade head` sobre base vacía exit 0. Cada reescritura de tabla tarda minutos en este disco (la suite del archivo, 18 min)
- L6 · 2026-10-26 · OUT · `dispositivo.actualizado_en` pasa a `modificado_en` conservando su valor (no se iguala a `creado_en`): ya era la fecha de la última actualización; ASM-07 rige donde se agrega la columna
- L7 · 2026-10-26 · replaces: test/ids_uuid_test.dart (sus tests) · no compilaba: usa catalogoJson sin importar soporte/admin.dart · by: test/ids_uuid_app_test.dart (mismos títulos y tags)
- L8 · 2026-10-26 · replaces: test/anular_desde_el_detalle_test.dart (sus tests) · ids pasan a UUID en los datos de prueba · by: test/anular_desde_el_detalle_uuid_test.dart (mismos títulos y tags)
- L9 · 2026-10-26 · replaces: test/interfaz_accesible_test.dart (sus tests) · ids pasan a UUID en los datos de prueba · by: test/interfaz_accesible_uuid_test.dart (mismos títulos y tags)
- L10 · 2026-10-26 · replaces: test/interfaz_accesible_supuestos_test.dart (sus tests) · ids pasan a UUID en los datos de prueba (importaba el anterior) · by: test/interfaz_accesible_supuestos_uuid_test.dart (mismos títulos y tags)
- L11 · 2026-10-26 · replaces: test/rediseno/movimiento_pantallas_test.dart (sus tests) · ids pasan a UUID en los datos de prueba · by: test/rediseno/movimiento_pantallas_uuid_test.dart (mismos títulos y tags)
- L12 · 2026-10-26 · replaces: test/rediseno/pantallas_test.dart (sus tests) · ids pasan a UUID en los datos de prueba · by: test/rediseno/pantallas_uuid_test.dart (mismos títulos y tags)
- L13 · 2026-10-26 · replaces: test/rediseno/transiciones_test.dart (sus tests) · ids pasan a UUID en los datos de prueba · by: test/rediseno/transiciones_uuid_test.dart (mismos títulos y tags)
- L14 · 2026-10-26 · replaces: test/rutas_de_la_api_test.dart (sus tests) · ids pasan a UUID en los datos de prueba · by: test/rutas_de_la_api_uuid_test.dart (mismos títulos y tags)
- L15 · 2026-10-26 · replaces: test/sin_sobreingenieria_a11y_test.dart (sus tests) · ids pasan a UUID en los datos de prueba · by: test/sin_sobreingenieria_a11y_uuid_test.dart (mismos títulos y tags)
- L16 · 2026-10-26 · T3 · app lee ids como texto UUID: flutter analyze y capturas verdes; la suite completa queda en L32
- L17 · 2026-10-26 · replaces: test/buscar_cancha_test.dart "pantalla consultar pide sede, deporte, fecha y rango, y lista las libres" · los ids son texto UUID (DAT-01-S3) · by: test/buscar_cancha_uuid_test.dart "pantalla consultar pide sede, deporte, fecha y rango, y lista las libres"
- L18 · 2026-10-26 · replaces: test/espacios_admin_test.dart "Espacios el nombre sugerido va con la sede, el deporte y el tipo" · los ids son texto UUID (DAT-01-S3) · by: test/espacios_admin_uuid_test.dart "Espacios el nombre sugerido va con la sede, el deporte y el tipo"
- L19 · 2026-10-26 · replaces: test/modificar_reserva_test.dart "MODIFICAR abre la grilla del día de la reserva, sin duración y con su horario marcado" · los ids son texto UUID (DAT-01-S3) · by: test/modificar_reserva_uuid_test.dart "MODIFICAR abre la grilla del día de la reserva, sin duración y con su horario marcado"
- L20 · 2026-10-26 · replaces: test/notificaciones_test.dart "cuándo llegó y en qué día agrupa por día conservando de la más nueva a la más vieja" · los ids son texto UUID (DAT-01-S3) · by: test/notificaciones_uuid_test.dart "cuándo llegó y en qué día agrupa por día conservando de la más nueva a la más vieja"
- L21 · 2026-10-26 · replaces: test/notificaciones_test.dart "el panel con la app abierta tocar un aviso lo abre" · los ids son texto UUID (DAT-01-S3) · by: test/notificaciones_uuid_test.dart "el panel con la app abierta tocar un aviso lo abre"
- L22 · 2026-10-26 · replaces: test/sedes_admin_test.dart "Sedes el alta manda los datos y devuelve la sede guardada" · los ids son texto UUID (DAT-01-S3) · by: test/sedes_admin_uuid_test.dart "Sedes el alta manda los datos y devuelve la sede guardada"
- L23 · 2026-10-26 · replaces: test/sedes_usuario_test.dart "filtro deporte, tipo, «Todos» y quitar el deporte" · los ids son texto UUID (DAT-01-S3) · by: test/sedes_usuario_uuid_test.dart "filtro deporte, tipo, «Todos» y quitar el deporte"
- L24 · 2026-10-26 · replaces: test/sedes_usuario_test.dart "filtro quitar el deporte vuelve a preguntar y trae lo nuevo" · los ids son texto UUID (DAT-01-S3) · by: test/sedes_usuario_uuid_test.dart "filtro quitar el deporte vuelve a preguntar y trae lo nuevo"
- L25 · 2026-10-26 · replaces: test/sedes_usuario_test.dart "una sede muestra la portada, el contador y cada cancha" · los ids son texto UUID (DAT-01-S3) · by: test/sedes_usuario_uuid_test.dart "una sede muestra la portada, el contador y cada cancha"
- L26 · 2026-10-26 · replaces: test/anular_desde_el_detalle_uuid_test.dart "el administrador anula una reserva desde el detalle del historial @REV-08-S8 @assumption:REV-08-ASM-01" · importaba soporte/admin.dart sin usarlo y flutter analyze avisa · by: test/anular_desde_el_detalle_sin_import_test.dart "el administrador anula una reserva desde el detalle del historial @REV-08-S8 @assumption:REV-08-ASM-01"
- L27 · 2026-10-26 · replaces: test/anular_desde_el_detalle_uuid_test.dart "el detalle de una reserva anulada dice quién la anuló, cuándo y por qué @REV-08-S8" · importaba soporte/admin.dart sin usarlo y flutter analyze avisa · by: test/anular_desde_el_detalle_sin_import_test.dart "el detalle de una reserva anulada dice quién la anuló, cuándo y por qué @REV-08-S8"
- L28 · 2026-10-26 · replaces: test/anular_desde_el_detalle_uuid_test.dart "volver sin confirmar la anulación deja la reserva igual @REV-08-S9" · importaba soporte/admin.dart sin usarlo y flutter analyze avisa · by: test/anular_desde_el_detalle_sin_import_test.dart "volver sin confirmar la anulación deja la reserva igual @REV-08-S9"
- L29 · 2026-10-26 · replaces: test/anular_desde_el_detalle_uuid_test.dart "cancelar el diálogo de anulación deja la reserva igual y la franja ocupada @REV-08-S9" · importaba soporte/admin.dart sin usarlo y flutter analyze avisa · by: test/anular_desde_el_detalle_sin_import_test.dart "cancelar el diálogo de anulación deja la reserva igual y la franja ocupada @REV-08-S9"
- L30 · 2026-10-26 · replaces: test/anular_desde_el_detalle_uuid_test.dart "tocar fuera del diálogo de anulación deja la reserva igual y vuelve al detalle @REV-08-S9" · importaba soporte/admin.dart sin usarlo y flutter analyze avisa · by: test/anular_desde_el_detalle_sin_import_test.dart "tocar fuera del diálogo de anulación deja la reserva igual y vuelve al detalle @REV-08-S9"
- L31 · 2026-10-26 · replaces: test/rediseno/pantallas_uuid_test.dart "tarjeta de reserva una reserva activa resaltada conserva el contorno de foco y suma el borde @RED-03-ASM-10" · abría '/reservas?reserva=2' con un id numérico; ahora el UUID de esa reserva · by: test/rediseno/pantallas_uuid_reserva_test.dart "tarjeta de reserva una reserva activa resaltada conserva el contorno de foco y suma el borde @RED-03-ASM-10"
- L32 · 2026-10-26 · T3 · portadas: sedes_usuario_capturas usa sus propios ids de sede (cuarto grupo 8001) para que Morón, Ramos Mejía y Haedo conserven la portada que tenían con ids numéricos; sin regenerar capturas. flutter analyze sin avisos; flutter test completo: 36 fallos, todos de tests declarados reemplazados en el Log de esta card o de otra (L17-L31, ARQ-03, RED-01..05, REV-04, SIM-01); capturas (arq03-capturas.sh) 350 verdes
- L33 · 2026-10-26 · replaces: apps/api/tests/escenarios/test_documentacion_modelo_vigente.py "el modelo de datos documenta todas las tablas" · exige las columnas viejas (emitido_en, creada_en, registrado_en, actualizado_en) que la 0010 renombró · by: apps/api/tests/escenarios/test_documentacion_modelo_uuid.py "el modelo de datos documenta cada columna del esquema vigente"
- L34 · 2026-10-26 · replaces: apps/api/tests/escenarios/test_documentacion_modelo_vigente.py "cada tabla del esquema migrado figura en el modelo de datos con sus columnas" · mismo motivo · by: apps/api/tests/escenarios/test_documentacion_modelo_uuid.py "cada seccion de tabla nombra sus columnas vigentes"
- L35 · 2026-10-26 · replaces: apps/api/tests/escenarios/test_documentacion_vigente.py "el modelo de datos documenta todas las tablas" · lee la sección Data de system-design.md, que sólo remite a modelo-de-datos.md (ya fallaba, 99 faltantes) · by: apps/api/tests/escenarios/test_documentacion_modelo_uuid.py "la seccion de datos del diseno remite al modelo de datos"
- L36 · 2026-10-26 · T4 · docs/technical/modelo-de-datos.md reescrita sobre la 0010 (uuid_v7, 17 referencias uuid, notificacion_reserva con PK compuesta, creado_en/modificado_en en las 9 con trigger, columnas renombradas, diez revisiones); pytest test_documentacion_del_modelo_corregida + test_documentacion_modelo_uuid + los vigentes: 17 passed, 3 failed (los 3 reemplazados en L33-L35)
- L37 · 2026-10-27 · kit updated 440e63628bf1cf2dc2867520e033d628b18457c9 → cb07a2b53635c38c871c3815c8414c707d77b9af · actualización del kit pedida por la persona
- L38 · 2026-10-27 · T2 (la API con ids UUID) pasa a la card DAT-02: esta card venció su tope y, pasado el tope, el kit no deja que un builder corra suites. La persona pidió terminar UUID y seguir solo toda la noche. DAT-01 y DAT-02 entran juntas a main: con 0010 aplicada, la API de esta rama todavía usa ids enteros, y la suite completa de la API, las líneas `app:` y `attacks:` y S3 en la API se verifican en DAT-02
- L39 · 2026-10-27 · uncovered · DAT-01-ASM-06 y DAT-01-ASM-08 son de la API: sus tests los escribe DAT-02
- L40 · 2026-10-27 · Tasks y Gate: T3 nombra ids_uuid_app_test.dart (L7) y T4 los tests de la documentación que quedaron tras DOC-01 (test_documentacion_del_modelo.py corregido en su lugar, test_documentacion_modelo_uuid.py); la suite corre los tests de esta card y la de la app los afectados
- L41 · 2026-10-27 · corrige L38-L40: T2 vuelve a esta card. Separarla en DAT-02 dejaba a DAT-01 sin `app:` ni `attacks:`, que su lente de contrato exige. Con el kit 6.21 el cambio mecánico de la API lo hace un grunt (no corre suites) y la compuerta la corre el hilo principal; la suite vuelve a ser la completa, con `refactor-tests:` para los tests que arman ids enteros. Los tests de T2 viven en test_uuid_api.py
