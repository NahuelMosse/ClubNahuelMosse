# DOC-10 · los tests de documentación pasan en main

status: proposed
cap: 45 min
sources: pedido de la persona en la sesión (texto), sobre la nota de un agente lateral citada en L1; salida de pytest de los 5 tests sobre main bdfc6b4
not_read: ninguno: no hay Jira ni adjuntos

## Specs

- S1 · "arreglalo asi no frena a nadie mas"
- S2 · "Revisan la página de navegación, integraciones.md y las capturas del README"
- DOC-10-ASM-01 · se corrige la documentación donde cita archivos de la app que ENG-17 y ENG-19 renombraron, y los tests que leen esos archivos siguen el renombre (`rutas.dart` → `router.dart`, `redireccion.dart` → `redirect.dart`) sin cambiar lo que verifican; el resto de las páginas viejas queda para ENG-21 · S2
- DOC-10-ASM-02 · el test congelado de DOC-06-S1 que cuenta el logo como captura, ya reemplazado por DOC-09 (`test_readme_capturas_sin_el_logo.py`), sale de `test_readme_conciso.py`: su reemplazo sigue corriendo · S1

## Tasks

- T1 · S1,S2,DOC-10-ASM-01,DOC-10-ASM-02 · docs/technical/navegacion-de-la-app.md, docs/technical/integraciones.md, apps/api/tests/unit/test_documentacion_del_modelo.py, apps/api/tests/unit/test_rutas_documentadas.py, apps/api/tests/unit/test_readme_conciso.py, apps/api/tests/unit/test_docs_follow_the_app.py · tests: apps/api/tests/unit/test_docs_follow_the_app.py "the documentation tests pass without deselecting any @DOC-10-S1 @assumption:DOC-10-ASM-02"; apps/api/tests/unit/test_docs_follow_the_app.py "every app file the navigation and integrations pages cite exists @DOC-10-S2 @assumption:DOC-10-ASM-01"

## Changes to existing behavior

- apps/api/tests/unit/test_documentacion_del_modelo.py · lee `apps/mobile/lib/router.dart` en vez de `rutas.dart`, y una ruta que `router.dart` arma en un método aparte cuelga de la ruta donde se lo llama · "cada ruta que nombra la página de navegación existe en app.dart @DOC-01-S2" y "la página de navegación lista cada ruta de app.dart @DOC-01-S2" verifican lo mismo
- apps/api/tests/unit/test_rutas_documentadas.py · lee `router.dart` y `redirect.dart` · "la página de navegación nombra rutas.dart y redireccion.dart, donde viven las rutas y la redirección @SIM-04-S1" verifica lo mismo
- apps/api/tests/unit/test_readme_conciso.py · sale "el README muestra a lo sumo 4 capturas en una fila y no quedan capturas sin usar @DOC-06-S1", reemplazado por DOC-09

## Gate

```
suite: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_docs_follow_the_app.py tests/unit/test_documentacion_del_modelo.py tests/unit/test_rutas_documentadas.py tests/unit/test_integraciones_documentadas.py tests/unit/test_readme_conciso.py tests/unit/test_readme_capturas_sin_el_logo.py tests/unit/test_readme_logo_y_capturas.py
lint: sh D:/Temp/w/herramientas/eng17-ruff-mypy.sh apps/api
app: sh D:/Temp/w/herramientas/arq01-app.sh doc10_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh doc10_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /venues {"name": "Attack Venue", "address": "Street 1", "opens_at": "08:00", "closes_at": "23:00", "open_days": [1, 2, 3, 4, 5, 6, 7]}' --read /bookings --read /me --openapi apps/api/openapi.json
refactor-tests: los tests de documentación que leen archivos de la app siguen el renombre de ENG-17 y ENG-19 (rutas.dart → router.dart, redireccion.dart → redirect.dart) y el lector de rutas sigue la ruta que router.dart arma en un método aparte; lo que verifican no cambia
no-docs: la card corrige páginas que citaban archivos que ya no existen; no cambia comportamiento
```

## Log

- L1 · Pedido de la persona: «arreglalo asi no frena a nadie mas». Sobre esta nota: «Heads up · Hay 5 tests de documentación que ya fallan en main, y el agente principal los sacó del control de ENG-20 para que no lo frenen. **Cinco tests de documentación ya fallan en main** * El **gate** es la lista de controles que una card tiene que pasar antes de cerrarse. Para ENG-20, el agente principal le agregó `--deselect` a 5 tests: así pytest no los corre. * Fallan igual en main, sin relación con esta card. Revisan la página de navegación, `integraciones.md` y las capturas del README. * Como el gate ya no los corre, ENG-20 no muestra que esos tests están rotos. * El CI que pediste va a correr toda la suite en cada PR, así que **va a salir en rojo desde el primer día** salvo que se arreglen antes. * **Conviene arreglarlos en ENG-21** (la card de docs) o antes de activar el CI, no dejarlos excluidos para siempre.»
- L2 · 2026-11-09 · replaces: apps/api/tests/unit/test_readme_conciso.py "el README muestra a lo sumo 4 capturas en una fila y no quedan capturas sin usar @DOC-06-S1" · cuenta el logo como captura; DOC-09 ya lo reemplazó y esta card lo saca del archivo · by: apps/api/tests/unit/test_readme_capturas_sin_el_logo.py "el README muestra a lo sumo 4 capturas en una fila y no quedan capturas sin usar, sin contar el logo @DOC-06-S1"
