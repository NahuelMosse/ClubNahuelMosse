# NOT-05 · un aviso por push y correo cinco minutos antes de la reserva

status: proposed
cap: 45 min
sources:
  - "pedido (texto) · mensaje del usuario en la sesión (2026-10-27): «el email si me llego, podrias hacer otra notificacion e email 5 minutos antes»"
  - "repo · apps/api/migraciones/versions/0005_notificaciones.py (CHECK de `tipo` con 'recordatorio', 'cancelacion_forzosa', 'cancelacion_usuario'; índice único `notificacion_recordatorio_unico` sobre (reserva_id, reserva_inicio) WHERE tipo = 'recordatorio'), apps/api/app/modules/notificaciones/reglas.py (`ANTICIPACION = timedelta(hours=1)`), repositorio.py (`vencidos`, `registrar`), casos_de_uso.py (`enviar_recordatorios`, `entregar` manda push y correo), apps/mobile/lib/notificaciones/notificacion.dart (`TipoDeNotificacion`)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "podrias hacer otra notificacion e email 5 minutos antes" · acceptance: cuando faltan 5 minutos o menos para una reserva activa, el barrido registra un aviso de tipo `recordatorio_cinco` («Tu reserva empieza en 5 minutos», con deporte, sede y horario) y lo manda por push y por correo, una sola vez por reserva y horario; el recordatorio de una hora antes sigue igual
- S2 · "otra notificacion" · acceptance: la app muestra el aviso de 5 minutos en el centro de notificaciones con el mismo ícono y destino que el recordatorio (tocarlo abre la reserva), y no lo confunde con un tipo desconocido
- NOT-05-ASM-01 · una migración nueva suma `recordatorio_cinco` al CHECK de `tipo`, a la regla que le exige reserva y horario, y un índice único igual al del recordatorio para ese tipo; su downgrade los saca · S1
- NOT-05-ASM-02 · una reserva creada con menos de 5 minutos de anticipación recibe el aviso de 5 minutos en el próximo barrido, y la de menos de una hora no recibe el de una hora: cada aviso sale sólo si todavía no empezó la reserva · S1

## Tasks

- T1 · S1,NOT-05-ASM-01,NOT-05-ASM-02 · apps/api/migraciones/versions/0011_recordatorio_cinco_minutos.py (data), apps/api/app/modules/notificaciones/reglas.py (rule), apps/api/app/modules/notificaciones/repositorio.py (data), apps/api/app/modules/notificaciones/casos_de_uso.py (rule) · tests: apps/api/tests/unit/test_recordatorio_cinco.py "a 5 minutos de la reserva sale un aviso por push y por correo, una sola vez @NOT-05-S1"; apps/api/tests/unit/test_recordatorio_cinco.py "una reserva que ya empezó no recibe el aviso de 5 minutos @assumption:NOT-05-ASM-02"; apps/api/tests/integracion/test_recordatorio_cinco_base.py "la base acepta el tipo recordatorio_cinco y no deja dos para la misma reserva y horario @assumption:NOT-05-ASM-01"
  reuses: apps/api/app/modules/notificaciones/casos_de_uso.py `enviar_recordatorios`, `entregar` (push y correo); repositorio.py `vencidos`, `registrar`
- T2 · S2 · apps/mobile/lib/notificaciones/notificacion.dart (presentation) · tests: apps/mobile/test/aviso_cinco_minutos_test.dart "el aviso de 5 minutos se muestra con el ícono del recordatorio y abre la reserva @NOT-05-S2"
  reuses: apps/mobile/lib/notificaciones/notificacion.dart `TipoDeNotificacion`

## Changes to existing behavior

- además del recordatorio de una hora, sale un aviso 5 minutos antes de cada reserva activa

## Gate

```
suite: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_recordatorio_cinco.py tests/integracion/test_recordatorio_cinco_base.py tests/unit/test_recordatorios.py tests/unit/test_aviso_por_correo.py tests/unit/test_aviso_por_correo_por_tipo.py tests/integracion/test_notificaciones_api.py
app-tests: sh D:/Temp/w/herramientas/flutter-mobile.sh test/aviso_cinco_minutos_test.dart test/notificaciones_test.dart
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/app apps/api/tests/unit/test_recordatorio_cinco.py apps/api/tests/integracion/test_recordatorio_cinco_base.py
migrate-upgrade: cd apps/api && sh -c "DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8701/club_not05_migra uv run --no-sync alembic upgrade head && DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8701/club_not05_migra uv run --no-sync alembic downgrade -1 && DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8701/club_not05_migra uv run --no-sync alembic upgrade head"
app: sh D:/Temp/w/herramientas/arq01-app.sh not05_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh not05_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
no-docs: un aviso más del mismo tipo de los que ya existen; el contrato no cambia
no-visual: el aviso usa el ícono y la tarjeta del recordatorio
```

## Log

- L1 · el email si me llego, podrias hacer otra notificacion e email 5 minutos antes
- L2 · 2026-10-27 · declared · attacks · la card no cambia rutas ni cuerpos de la API
- L3 · 2026-10-27 · declared · fault-db · la base es Postgres, no un archivo; el aviso usa el mismo camino de registro que el recordatorio
