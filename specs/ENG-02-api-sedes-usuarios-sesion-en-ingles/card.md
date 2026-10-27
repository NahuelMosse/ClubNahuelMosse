# ENG-02 · los módulos de sedes, usuarios, sesión y recuperación de la API están en inglés

status: proposed
cap: 2 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «no me gusta nada que todo el codigo este en español» · elige «Todo, base y API incluidas» · «hacelo en paralelo» · «estamos en etapa critica, necesito que todo lo que hagamos se haga lo mas rapido posible» · elige «Seguir con todo»"
  - "glosario · docs/technical/glosario-ingles.md (ENG-00, ampliado en ENG-01)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "no me gusta nada que todo el codigo este en español" · acceptance: `apps/api/app/modules/` tiene `venues/`, `users/`, `session/` y `password_recovery/` con sus archivos en inglés según el glosario (`use_cases.py`, `rules.py`, `repository.py`, `routes.py`, `email.py`, `profile.py`, `current_user.py`, `admins.py`, `deactivation.py`, `password.py`, `registration.py`, `account_routes.py`, `registration_routes.py`, `seed_admin.py`); no quedan `sedes/`, `usuarios/`, `sesion/` ni `recuperacion/`
- S2 · "no me gusta nada que todo el codigo este en español" · acceptance: en esos módulos cada clase, función, parámetro, atributo, variable, constante, comentario y docstring está en inglés: ningún identificador usa un término castellano del glosario y ningún comentario ni docstring tiene palabras castellanas comunes (`de`, `la`, `el`, `los`, `las`, `que`, `por`, `para`, `con`, `una`, `del`, `sin`, `cuando`, `si`); los textos que ve el usuario, el SQL, las rutas y las claves JSON no cambian
- S3 · "Todo, base y API incluidas" · acceptance: el contrato tiene las mismas rutas, métodos, códigos, campos y `operationId` que el de main; sólo cambian los nombres de los esquemas
- ENG-02-ASM-01 · los nombres de los esquemas de `openapi.json` siguen a las clases en inglés y el archivo se regenera: la app no los lee, lee rutas y campos · S3
- ENG-02-ASM-02 · los demás módulos (espacios, horarios, notificaciones, reservas) y `app/main.py` cambian sólo las líneas que importan estos módulos · S1
- ENG-02-ASM-03 · los tests cambian sólo lo que el renombre obliga con `refactor-tests:`; títulos y nombres de archivo de test quedan en castellano · S1
- ENG-02-ASM-04 · un nombre que el glosario no tiene se traduce con el mismo criterio y se agrega al glosario · S2
- ENG-02-ASM-05 · los campos de los modelos Pydantic de entrada y salida conservan su nombre castellano, porque son las claves JSON (y los `loc` de los errores de validación); sólo la clase pasa a inglés, sin `alias` · S2
- ENG-02-ASM-06 · `scripts/e2e.sh` y `apps/api/app/e2e_support.py` cambian sólo la ruta del módulo que llaman o importan; las opciones de línea de comandos (`--correo`) no cambian · S1
- ENG-02-ASM-07 · el contrato se compara también en parámetros y `security` de cada operación: ninguna ruta pierde su control de sesión · S3
- ENG-02-ASM-08 · los documentos que nombran las rutas de estos módulos (`docs/technical/mapa-del-codigo.md`, `apps/api/README.md` y los que el test de documentación lea) se actualizan con los nombres nuevos · S1

## Tasks

- T1 · S1,S2,S3,ENG-02-ASM-01,ENG-02-ASM-02,ENG-02-ASM-03,ENG-02-ASM-04,ENG-02-ASM-05,ENG-02-ASM-06,ENG-02-ASM-07,ENG-02-ASM-08 · scripts/e2e.sh, apps/api/app/e2e_support.py (data), docs/technical/mapa-del-codigo.md (presentation), apps/api/README.md, apps/api/app/modules/venues/__init__.py (presentation), apps/api/app/modules/venues/use_cases.py (rule), apps/api/app/modules/venues/rules.py (rule), apps/api/app/modules/venues/repository.py (data), apps/api/app/modules/venues/routes.py (presentation), apps/api/app/modules/users/__init__.py (presentation), apps/api/app/modules/users/admins.py (rule), apps/api/app/modules/users/deactivation.py (rule), apps/api/app/modules/users/password.py (rule), apps/api/app/modules/users/profile.py (rule), apps/api/app/modules/users/registration.py (rule), apps/api/app/modules/users/rules.py (rule), apps/api/app/modules/users/repository.py (data), apps/api/app/modules/users/account_routes.py (presentation), apps/api/app/modules/users/registration_routes.py (presentation), apps/api/app/modules/users/seed_admin.py (presentation), apps/api/app/modules/session/__init__.py (presentation), apps/api/app/modules/session/use_cases.py (rule), apps/api/app/modules/session/profile.py (rule), apps/api/app/modules/session/repository.py (data), apps/api/app/modules/session/current_user.py (presentation), apps/api/app/modules/password_recovery/__init__.py (presentation), apps/api/app/modules/password_recovery/use_cases.py (rule), apps/api/app/modules/password_recovery/email.py (data), apps/api/app/modules/password_recovery/rules.py (rule), apps/api/app/modules/password_recovery/repository.py (data), apps/api/app/modules/password_recovery/routes.py (presentation), apps/api/openapi.json, docs/technical/glosario-ingles.md (presentation) · tests: apps/api/tests/unit/test_modulos_cuenta_en_ingles.py "los módulos de sedes, usuarios, sesión y recuperación se llaman como dice el glosario @ENG-02-S1 @assumption:ENG-02-ASM-02 @assumption:ENG-02-ASM-03"; apps/api/tests/unit/test_modulos_cuenta_en_ingles.py "los nombres, comentarios y docstrings de esos módulos están en inglés @ENG-02-S2 @assumption:ENG-02-ASM-04"; apps/api/tests/unit/test_modulos_cuenta_en_ingles.py "el contrato tiene las mismas rutas, métodos, códigos, campos y operationId que main @ENG-02-S3 @assumption:ENG-02-ASM-01"; apps/api/tests/unit/test_modulos_cuenta_en_ingles.py "los campos de los modelos de entrada y salida siguen siendo las claves JSON en castellano @assumption:ENG-02-ASM-05"; apps/api/tests/unit/test_modulos_cuenta_en_ingles.py "scripts/e2e.sh y e2e_support usan los módulos nuevos con las mismas opciones @assumption:ENG-02-ASM-06"; apps/api/tests/unit/test_modulos_cuenta_en_ingles.py "cada operación conserva sus parámetros y su security @assumption:ENG-02-ASM-07"; apps/api/tests/unit/test_modulos_cuenta_en_ingles.py "ningún documento nombra sedes, usuarios, sesion ni recuperacion como módulo @assumption:ENG-02-ASM-08"
  reuses: cada archivo de sedes, usuarios, sesion y recuperacion cambia de nombre y conserva lo que hace; apps/api/tests/unit/test_base_en_ingles.py (el mismo criterio de palabras castellanas)

## Changes to existing behavior

- none: rutas, campos, códigos, SQL y textos no cambian; cambian nombres internos y los nombres de esquema del contrato

## Gate

```
suite [timeout 2 h]: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider
fmt: cd apps/api && uv run --no-sync ruff format --check app tests/unit/test_modulos_cuenta_en_ingles.py
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/app apps/api/tests/unit/test_modulos_cuenta_en_ingles.py
app: sh D:/Temp/w/herramientas/arq01-app.sh eng02_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh eng02_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
refactor-tests: los módulos de sedes, usuarios, sesión y recuperación cambian de nombre: los tests cambian sólo imports, símbolos y rutas de archivo
no-docs: nombres internos; el comportamiento y el modelo de datos no cambian (el glosario se actualiza en T1)
```

## Log

- L1 · no me gusta nada que todo el codigo este en español · Todo, base y API incluidas · hacelo en paralelo · estamos en etapa critica, necesito que todo lo que hagamos se haga lo mas rapido posible · Seguir con todo
- L2 · 2026-10-27 · declared · fault-db · la base es Postgres, no un archivo; la card no cambia cómo se conecta ni el SQL
- L3 · 2026-10-27 · parte de ENG-01 (base de la API en inglés, rama ENG-01-api-base-en-ingles), en paralelo con ENG-03, ENG-04 y ENG-05: cada una renombra sus módulos y sólo las líneas de import de los otros
- L4 · 2026-10-27 · T1 · tests/unit con el venv compartido: 319 passed, 6 failed antes del ajuste; test_arquitectura_funcionalidades (nombres de esquema) corregido y en verde (11 passed); pyproject per-file-ignores cubre `*routes.py`
- L5 · 2026-10-27 · T1 · gate parcial: fallan en unit test_base_en_ingles (contract/_pruebas), test_codigo_legible (firmas vs main), test_sin_supresiones x2 (type:ignore), test_sin_sobreingenieria (DB puerto 8703); la comprobación contra la base ENG-01 no corrió (time-cap)
