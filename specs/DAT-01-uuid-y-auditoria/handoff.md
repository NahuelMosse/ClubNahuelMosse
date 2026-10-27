# Handoff DAT-01 T2 (API UUID)

Hecho: app/ completo (mypy --strict app y ruff limpios). tests/escenarios con ids UUID/str segun origen (sin errores de ids en mypy). En tests/integracion: helpers de la API (`_espacio_nuevo`, `_cancha`, `_espacio`, `_alta`) pasan a `str` y devuelven `str(r.json()["id"])`; E501 de test_espacios_api.py:443 corregido.

Como verificar sin correr suites (mypy cubre tests; la config del repo choca con tests/escenarios, por eso se usa un ini aparte sin `mypy_path` del repo):
- integracion y unit: `uv run --no-sync mypy --strict tests/integracion` (idem `tests/unit`).
- escenarios: `/tmp/m.ini` = `[mypy] strict=True, plugins=pydantic.mypy, mypy_path=tests/escenarios, namespace_packages=True` + `ignore_missing_imports` para firebase_admin; `mypy --config-file /tmp/m.ini $(ls tests/escenarios/*.py | grep -v documentacion)`. Los errores restantes de escenarios (var-annotated, CanalQueFalla, smtplib, CASOS_DE_USO) no son de ids.

Pendiente (refactor-tests):
- tests/integracion: hecho (ids UUID/str segun origen, `min(id)` sobre usuario pasa a `ORDER BY id LIMIT 1` porque Postgres no tiene `min(uuid)`). `mypy --strict tests/integracion` deja 2 errores que no son de ids: test_api_limpia_persistencia.py:45 (var-annotated) y test_aviso_en_envio_perdido.py:19 (`invalidos=[]` vs `tuple[str, ...]`). test_uuid_api.py y test_uuid_y_auditoria.py no se tocaron.
- tests/unit: ~194 errores mypy por fakes de puertos con `int` (usuario_id, sede_id, autor, notificacion_id, `Perfil(id=1)`, etc.) -> `UUID`. No estaba en la lista original.
- `apps/api/openapi.json`: regenerar con el comando de apps/api/README.md:80.
- Barrido final: `grep -rnE "int\(" apps/api/tests` junto a ids; mypy de las tres carpetas; ruff de los archivos tocados.
