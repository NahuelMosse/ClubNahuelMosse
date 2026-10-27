# SIM-04 · la documentación de la navegación sigue al router en rutas.dart

status: proposed
cap: 1 h
sources:
  - "pedido (texto) · mensaje del usuario en la sesión (2026-10-26): «en la docu podes poner el router de la app?» (DOC-01-S2)"
  - "integración en main (2026-10-27): SIM-03 llevó las rutas de GoRouter de apps/mobile/lib/app.dart a apps/mobile/lib/rutas.dart; los dos tests de DOC-01 que leen las rutas de app.dart quedan en rojo en main (pytest completo: 662 passed, 5 failed, 2 de ellos éstos) y la página de navegación sigue diciendo que las rutas están en app.dart"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "en la docu podes poner el router de la app?" · acceptance: la página de navegación nombra el archivo donde viven hoy las rutas (`apps/mobile/lib/rutas.dart`) y la redirección (`apps/mobile/lib/redireccion.dart`), y los tests que comparan la página con el código leen ese archivo

## Tasks

- T1 · S1 · docs/technical/navegacion-de-la-app.md (presentation), docs/technical/arquitectura.md, docs/technical/mapa-del-codigo.md, apps/api/tests/unit/test_documentacion_del_modelo.py, apps/api/tests/unit/test_rutas_documentadas.py · tests: apps/api/tests/unit/test_rutas_documentadas.py "la página de navegación nombra rutas.dart y redireccion.dart, donde viven las rutas y la redirección @SIM-04-S1"
  reuses: el lector de rutas `_rutas_de_app_dart` de test_documentacion_del_modelo.py, apuntado al archivo nuevo del router

## Changes to existing behavior

- docs/technical/navegacion-de-la-app.md · dice que las rutas están en rutas.dart y la redirección en redireccion.dart

## Gate

```
suite: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_documentacion_del_modelo.py tests/unit/test_rutas_documentadas.py
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/tests/unit/test_documentacion_del_modelo.py apps/api/tests/unit/test_rutas_documentadas.py
app: sh D:/Temp/w/herramientas/arq01-app.sh sim04_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh sim04_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
refactor-tests: SIM-03 movió las rutas de app.dart a rutas.dart; los dos tests de DOC-01 que las leen cambian sólo la ruta del archivo
no-visual: la card cambia documentación y tests; ninguna pantalla
```

## Log

- L1 · en la docu podes poner el router de la app?
- L2 · 2026-10-27 · kit updated 1013a50fa7803b47e455fb6e186a0899bfae88b2 → 8536fa90613ca7e11abc0090e440768a668903cd · SIM-04: kit 6.21.4
