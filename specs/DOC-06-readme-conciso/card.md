# DOC-06 · el README es conciso: vende el proyecto en una pantalla

status: proposed
cap: 45 min
sources:
  - "pedido (texto) · mensaje del usuario en la sesión (2026-10-27): «no me gusto que quedaran tantas capturas, el readme es para vender el proyecto, pero ahora quedo demasiado largo, hay que sacarle relleno. Que sea conciso y al punto»"
  - "repo · README.md (137 líneas, 14 capturas, secciones Qué hace, Cómo está hecha, Cómo correrla, Documentación, Supuestos de la documentación, Estado), docs/capturas/, apps/api/tests/unit/test_readme_presenta.py (DOC-05: exige una captura por paso del recorrido y la del panel), apps/api/tests/escenarios/test_documentacion_*.py, test_readme_app_configuracion.py, test_requisitos_no_funcionales*.py (leen el README)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "no me gusto que quedaran tantas capturas" · acceptance: el README muestra a lo sumo 4 capturas reales, en una sola fila al principio (inicio, horarios, reserva confirmada y notificaciones); las capturas que dejan de usarse se borran de `docs/capturas/`
- S2 · "hay que sacarle relleno. Que sea conciso y al punto" · acceptance: el README entra en unas 60 líneas: qué es en una frase, la fila de capturas, qué hace en no más de 6 viñetas de una línea, con qué está hecha en una tabla corta con el enlace a `docs/technical/integraciones.md`, cómo correrla en pocos comandos y la documentación como lista de enlaces; sin párrafos que repitan lo que ya está en las capturas o en los documentos enlazados
- DOC-06-ASM-01 · lo que los tests de documentación leen del README (comandos, enlaces, y los supuestos que listan con su ID) se conserva; lo que sea largo pasa a un documento enlazado en vez de borrarse · S2
- DOC-06-ASM-02 · el README sigue sin publicar contraseñas ni claves · S2

## Tasks

- T1 · S1,S2,DOC-06-ASM-01,DOC-06-ASM-02 · README.md (presentation), docs/capturas/00-carga.jpg, docs/capturas/01-login.jpg, docs/capturas/03-sedes.jpg, docs/capturas/04-sede.jpg, docs/capturas/06-confirmar.jpg, docs/capturas/08-reservas.jpg, docs/capturas/10-perfil.jpg, docs/capturas/11-inicio-claro.jpg, docs/capturas/12-admin-reservas.png · tests: apps/api/tests/unit/test_readme_conciso.py "el README muestra a lo sumo 4 capturas en una fila y no quedan capturas sin usar @DOC-06-S1"; apps/api/tests/unit/test_readme_conciso.py "el README entra en unas 60 líneas con qué es, qué hace en 6 viñetas, con qué está hecha, cómo correrla y la documentación @DOC-06-S2"; apps/api/tests/unit/test_readme_conciso.py "lo que los tests de documentación leen del README sigue estando @assumption:DOC-06-ASM-01"; apps/api/tests/unit/test_readme_conciso.py "el README no publica contraseñas ni claves @assumption:DOC-06-ASM-02"
  reuses: el README de DOC-05 (se recorta); las capturas de docs/capturas que quedan

## Changes to existing behavior

- el README pasa de 137 líneas y 14 capturas a unas 60 líneas y 4 capturas

## Gate

```
suite: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_readme_conciso.py tests/escenarios/test_documentacion_vigente.py tests/escenarios/test_documentacion_supuestos_vigente.py tests/escenarios/test_readme_app_configuracion.py tests/escenarios/test_requisitos_no_funcionales.py tests/escenarios/test_requisitos_no_funcionales_readme_app.py
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/tests/unit/test_readme_conciso.py
no-visual: la card cambia el README; ninguna pantalla de la app
```

## Log

- L1 · no me gusto que quedaran tantas capturas, el readme es para vender el proyecto, pero ahora quedo demasiado largo, hay que sacarle relleno. Que sea conciso y al punto
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base
- L3 · 2026-10-27 · declared · attacks · la card no toca la API
- L4 · 2026-10-27 · replaces: apps/api/tests/unit/test_readme_presenta.py "el README muestra capturas reales de cada paso del recorrido y del panel de administración, y cada imagen existe" · el usuario pide menos capturas: ya no hay una por paso ni la del panel · by: apps/api/tests/unit/test_readme_conciso.py "el README muestra a lo sumo 4 capturas en una fila y no quedan capturas sin usar"
- L5 · 2026-10-27 · replaces: apps/api/tests/unit/test_readme_presenta.py "el README presenta qué es, qué hace, cómo está hecha con enlace a integraciones, cómo correrla y la documentación" · ahora además con límite de largo · by: apps/api/tests/unit/test_readme_conciso.py "el README entra en unas 60 líneas con qué es, qué hace en 6 viñetas, con qué está hecha, cómo correrla y la documentación"
- L6 · 2026-10-27 · T1 · README.md 137 -> 52 líneas, 4 capturas en una fila, 9 capturas borradas, test_readme_presenta.py borrado (sus 4 tests los cubre test_readme_conciso.py), supuestos REV-07 y Estado movidos a docs/supuestos-de-la-documentacion.md · test_readme_conciso.py: 4 passed
- L7 · 2026-10-27 · gate red · suite · test_documentacion_vigente.py::test_la_declaracion_de_accesibilidad_y_el_registro_por_pantalla_estan_publicados y test_documentacion_supuestos_vigente.py::test_el_registro_de_accesibilidad_nombra_cada_pantalla_... fallan con `['pantalla_de_carga']` sin registro en docs/business/accessibility.md; fallan igual en main sin esta card (no leen el README)
