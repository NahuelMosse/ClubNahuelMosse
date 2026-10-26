# DOC-01 · la documentación explica el modelo de datos y la navegación de la app

status: proposed
cap: 1 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-26): «y la docu en ningun lado explica el modelo de datos, que es super importante» · «en la docu podes poner el router de la app?»"
  - "relevamiento · el modelo estaba sólo en la sección «Data» de docs/technical/system-design.md, mezclado con observabilidad y amenazas y sin diagrama; las rutas de la app no estaban documentadas"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "la docu en ningun lado explica el modelo de datos, que es super importante" · acceptance: docs/technical/modelo-de-datos.md explica cada tabla (qué representa, columnas importantes y reglas de la base), con un diagrama entidad-relación, los estados de una reserva y de un aviso y las bajas lógicas; cada tabla, columna y restricción que nombra existe en las migraciones
- S2 · "podes poner el router de la app?" · acceptance: docs/technical/navegacion-de-la-app.md lista cada ruta de la app con su pantalla y quién puede entrar, con un diagrama de la navegación y lo que pasa sin sesión, con otro rol y al tocar un aviso; cada ruta que nombra existe en apps/mobile/lib/app.dart
- S3 · "la docu" · acceptance: las dos páginas aparecen en el sitio de documentación, en la sección Técnica, y system-design.md remite a la del modelo en vez de repetirla
- DOC-01-ASM-01 · la sección «Data» de system-design.md queda como un párrafo que remite a modelo-de-datos.md, sin la tabla de columnas: un solo lugar describe el modelo · S3

## Tasks

- T1 · S1,S3,DOC-01-ASM-01 · docs/technical/modelo-de-datos.md, docs/technical/system-design.md · tests: apps/api/tests/unit/test_documentacion_del_modelo.py "cada tabla y columna que nombra la página del modelo de datos existe en las migraciones @DOC-01-S1"; apps/api/tests/unit/test_documentacion_del_modelo.py "la página del modelo de datos explica cada tabla de las migraciones @DOC-01-S1"; apps/api/tests/unit/test_documentacion_del_modelo.py "los estados de reserva y de aviso de la página son los que admiten las migraciones, todos @DOC-01-S1"; apps/api/tests/unit/test_documentacion_del_modelo.py "la sección Data de system-design remite a la página del modelo de datos sin repetir sus columnas @DOC-01-S3 @assumption:DOC-01-ASM-01"
- T2 · S2 · docs/technical/navegacion-de-la-app.md · tests: apps/api/tests/unit/test_documentacion_del_modelo.py "cada ruta que nombra la página de navegación existe en app.dart @DOC-01-S2"; apps/api/tests/unit/test_documentacion_del_modelo.py "la página de navegación lista cada ruta de app.dart @DOC-01-S2"; apps/mobile/test/navegacion_documentada_test.dart "quién puede entrar a cada ruta es lo que dice la página de navegación @DOC-01-S2"
- T3 · S3 · sitio-docs/scripts/copiar.mjs (data) · tests: apps/api/tests/unit/test_documentacion_del_modelo.py "el sitio de documentación incluye el modelo de datos y la navegación en Técnica @DOC-01-S3"
  reuses: sitio-docs/scripts/copiar.mjs la lista `paginas`

## Changes to existing behavior

- docs/technical/system-design.md · la sección «Data» pasa a remitir a modelo-de-datos.md

## Gate

```
suite: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_documentacion_del_modelo.py tests/escenarios/test_documentacion_vigente.py tests/unit/test_mapa_por_funcionalidad.py
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/tests/unit/test_documentacion_del_modelo.py
no-visual: la card escribe documentación sobre la app y su navegación; no cambia ninguna pantalla
```

## Log

- L1 · y la docu en ningun lado explica el modelo de datos, que es super importante · en la docu podes poner el router de la app?
