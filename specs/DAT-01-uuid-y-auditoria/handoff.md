# Handoff DAT-01 T2 (API UUID)

Hecho: app/ completo (mypy --strict app y ruff limpios). tests/escenarios con ids UUID/str segun origen (sin errores de ids en mypy). En tests/integracion: helpers de la API (`_espacio_nuevo`, `_cancha`, `_espacio`, `_alta`) pasan a `str` y devuelven `str(r.json()["id"])`; E501 de test_espacios_api.py:443 corregido.

Como verificar sin correr suites (mypy cubre tests; la config del repo choca con tests/escenarios, por eso se usa un ini aparte sin `mypy_path` del repo):
- integracion y unit: `uv run --no-sync mypy --strict tests/integracion` (idem `tests/unit`).
- escenarios: `/tmp/m.ini` = `[mypy] strict=True, plugins=pydantic.mypy, mypy_path=tests/escenarios, namespace_packages=True` + `ignore_missing_imports` para firebase_admin; `mypy --config-file /tmp/m.ini $(ls tests/escenarios/*.py | grep -v documentacion)`. Los errores restantes de escenarios (var-annotated, CanalQueFalla, smtplib, CASOS_DE_USO) no son de ids.

Pendiente (refactor-tests):
- tests/integracion, ids de la base (UUID) en helpers: `_usuario`, `_yo`, `_registrar`, `_barrer`, `usuario`/`espacio` en test_reservas_api.py (lineas 23-24, 44, 190), test_notificaciones_api.py (34, 61, 154, 415-428), test_api_limpia_reservas.py (`_usuario`, `_agenda`, `_dar_de_baja id_`, fixture `cancha: tuple[int,int,int]` -> `tuple[str, str, UUID]`; lineas 72-73 `yo + 1_000_000` y `reserva.id + 1_000_000` pasan a `uuid.uuid4()`), test_api_limpia_reserva_movida.py, test_aviso_en_envio_perdido.py (`id_: int`), test_baja_api.py, test_restricciones.py, test_sin_sobreingenieria_api.py (116, 166), test_historial_api.py `_ids -> set[str]`.
- Quitar `int(...)`: test_reservas_api.py:47 y 274, test_notificaciones_api.py:37 y 154, test_baja_api.py:44/58, test_espacios_api.py:606, test_anular_reserva_api.py / test_api_limpia_reservas.py `_usuario`.
- Ids de la base en `json=`/`params=`/f-strings a la API: `str(...)`. Ids de la API que entran a `ReservasSql`/`NotificacionesSql`: `UUID(...)`.
- Comparaciones UUID vs str (`str(fila.id) == r.json()["id"]`), barrido con grep `\.id ==`.
- tests/unit: ~194 errores mypy por fakes de puertos con `int` (usuario_id, sede_id, autor, notificacion_id, `Perfil(id=1)`, etc.) -> `UUID`. No estaba en la lista original.
- `apps/api/openapi.json`: regenerar con el comando de apps/api/README.md:80.
- Barrido final: `grep -rnE "int\(" apps/api/tests` junto a ids; mypy de las tres carpetas; ruff de los archivos tocados.
