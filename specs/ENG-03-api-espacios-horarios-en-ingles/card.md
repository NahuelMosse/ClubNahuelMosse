# ENG-03 · los módulos de espacios y horarios de la API están en inglés

status: proposed
cap: 2 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «no me gusta nada que todo el codigo este en español» · elige «Todo, base y API incluidas» · «hacelo en paralelo» · «estamos en etapa critica, necesito que todo lo que hagamos se haga lo mas rapido posible» · elige «Seguir con todo»"
  - "glosario · docs/technical/glosario-ingles.md (ENG-00, ampliado en ENG-01)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "no me gusta nada que todo el codigo este en español" · acceptance: `apps/api/app/modules/` tiene `spaces/` y `availability/` con sus archivos en inglés según el glosario (`use_cases.py`, `rules.py`, `repository.py`, `routes.py`, `slots.py`); no quedan `espacios/` ni `horarios/`
- S2 · "no me gusta nada que todo el codigo este en español" · acceptance: en esos módulos cada clase, función, parámetro, atributo, variable, constante, comentario y docstring está en inglés: ningún identificador usa un término castellano del glosario y ningún comentario ni docstring tiene palabras castellanas comunes (`de`, `la`, `el`, `los`, `las`, `que`, `por`, `para`, `con`, `una`, `del`, `sin`, `cuando`, `si`); los textos que ve el usuario, el SQL, las rutas, las claves JSON y las claves del catálogo no cambian
- S3 · "Todo, base y API incluidas" · acceptance: el contrato tiene las mismas rutas, métodos, códigos, campos y `operationId` que el de main; sólo cambian los nombres de los esquemas
- ENG-03-ASM-01 · los nombres de los esquemas de `openapi.json` siguen a las clases en inglés y el archivo se regenera: la app no los lee, lee rutas y campos · S3
- ENG-03-ASM-02 · los demás módulos y `app/main.py` cambian sólo las líneas que importan estos módulos · S1
- ENG-03-ASM-03 · los tests cambian sólo lo que el renombre obliga con `refactor-tests:`; títulos y nombres de archivo de test quedan en castellano · S1
- ENG-03-ASM-04 · un nombre que el glosario no tiene se traduce con el mismo criterio y se agrega al glosario · S2

## Tasks

- T1 · S1,S2,S3,ENG-03-ASM-01,ENG-03-ASM-02,ENG-03-ASM-03,ENG-03-ASM-04 · apps/api/app/modules/spaces/__init__.py (presentation), apps/api/app/modules/spaces/use_cases.py (rule), apps/api/app/modules/spaces/rules.py (rule), apps/api/app/modules/spaces/repository.py (data), apps/api/app/modules/spaces/routes.py (presentation), apps/api/app/modules/availability/__init__.py (presentation), apps/api/app/modules/availability/use_cases.py (rule), apps/api/app/modules/availability/slots.py (rule), apps/api/app/modules/availability/rules.py (rule), apps/api/app/modules/availability/repository.py (data), apps/api/app/modules/availability/routes.py (presentation), apps/api/openapi.json, docs/technical/glosario-ingles.md (presentation) · tests: apps/api/tests/unit/test_modulos_espacios_en_ingles.py "los módulos de espacios y horarios se llaman como dice el glosario @ENG-03-S1 @assumption:ENG-03-ASM-02 @assumption:ENG-03-ASM-03"; apps/api/tests/unit/test_modulos_espacios_en_ingles.py "los nombres, comentarios y docstrings de espacios y horarios están en inglés @ENG-03-S2 @assumption:ENG-03-ASM-04"; apps/api/tests/unit/test_modulos_espacios_en_ingles.py "el contrato de espacios y horarios tiene las mismas rutas, métodos, códigos, campos y operationId que main @ENG-03-S3 @assumption:ENG-03-ASM-01"
  reuses: cada archivo de espacios y horarios cambia de nombre y conserva lo que hace; apps/api/tests/unit/test_base_en_ingles.py (el mismo criterio de palabras castellanas)

## Changes to existing behavior

- none: rutas, campos, códigos, SQL y textos no cambian; cambian nombres internos y los nombres de esquema del contrato

## Gate

```
suite [timeout 2 h]: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider
fmt: cd apps/api && uv run --no-sync ruff format --check app tests/unit/test_modulos_espacios_en_ingles.py
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/app apps/api/tests/unit/test_modulos_espacios_en_ingles.py
app: sh D:/Temp/w/herramientas/arq01-app.sh eng03_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh eng03_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
refactor-tests: los módulos de espacios y horarios cambian de nombre: los tests cambian sólo imports, símbolos y rutas de archivo
no-docs: nombres internos; el comportamiento y el modelo de datos no cambian (el glosario se actualiza en T1)
```

## Log

- L1 · no me gusta nada que todo el codigo este en español · Todo, base y API incluidas · hacelo en paralelo · estamos en etapa critica, necesito que todo lo que hagamos se haga lo mas rapido posible · Seguir con todo
- L2 · 2026-10-27 · declared · fault-db · la base es Postgres, no un archivo; la card no cambia cómo se conecta ni el SQL
- L3 · 2026-10-27 · parte de ENG-01 (base de la API en inglés), en paralelo con ENG-02, ENG-04 y ENG-05: cada una renombra sus módulos y sólo las líneas de import de los otros
