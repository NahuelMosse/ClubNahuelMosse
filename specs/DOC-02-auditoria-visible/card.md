# DOC-02 · el modelo de datos muestra cuándo se creó y se modificó cada fila

status: proposed
cap: 1 h
sources:
  - "pedido (texto) · mensaje del usuario en la sesión (2026-10-27): «por que las tablas no dicen cuando se creo o se modifico?»"
  - "relevamiento · docs/technical/modelo-de-datos.md tiene una sola frase general sobre `creado_en` y `modificado_en`; el diagrama entidad-relación no las muestra en ninguna tabla y sólo 4 de las 9 secciones las nombran; el test de DOC-01 las excluye a propósito como columnas comunes"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "por que las tablas no dicen cuando se creo o se modifico?" · acceptance: en la página del modelo de datos, cada una de las nueve tablas del diagrama entidad-relación muestra `creado_en` y `modificado_en`, y la sección de cada tabla las nombra y dice qué guarda cada una

## Tasks

- T1 · S1 · docs/technical/modelo-de-datos.md (presentation), apps/api/tests/unit/test_auditoria_documentada.py · tests: apps/api/tests/unit/test_auditoria_documentada.py "cada tabla del diagrama y de su sección muestra creado_en y modificado_en @DOC-02-S1"
  reuses: el diagrama y las secciones existentes de docs/technical/modelo-de-datos.md

## Changes to existing behavior

- docs/technical/modelo-de-datos.md · el diagrama y cada sección suman las dos columnas de auditoría

## Gate

```
suite: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_auditoria_documentada.py tests/unit/test_documentacion_del_modelo.py tests/escenarios/test_documentacion_modelo_uuid.py tests/escenarios/test_documentacion_modelo_vigente.py
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/tests/unit/test_auditoria_documentada.py
app: sh D:/Temp/w/herramientas/arq01-app.sh doc02_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh doc02_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
no-visual: la card cambia documentación; ninguna pantalla de la app
```

## Log

- L1 · por que las tablas no dicen cuando se creo o se modifico?
