# Handoff DAT-01 T2 (API UUID)

Hecho: app/ completo en commit "DAT-01 T2: la API recibe y devuelve los ids como UUID" (mypy --strict y ruff limpios).

Pendiente (refactor-tests, no verificado: no se corren suites):
- Anotaciones `int` de ids en tests/escenarios y tests/integracion (helpers `_espacio`, `_yo`, `_usuario`, `_cancha`, `cancha`, `sede` de test_basquet, `usuario_id`, `id_`) pasan a `str`/`UUID` segun vengan de la API (str) o de la base (UUID).
- Casts `int(...)` de ids que ahora rompen en runtime: test_recordatorio.py:134, test_reservar.py:49, test_seguridad_api.py:112, test_reservas_api.py:274, test_espacios_api.py:606, test_notificaciones_api.py:154, test_notificaciones_api.py _yo/_registrar, test_reservas_api.py:_yo.
- Ids de la base (UUID) en `json=`/`params=` hay que pasarlos a `str(...)`.
- Comparaciones UUID vs str (fila.id == r.json()["id"]).
- openapi.json sin regenerar (README.md:80 tiene el comando).
