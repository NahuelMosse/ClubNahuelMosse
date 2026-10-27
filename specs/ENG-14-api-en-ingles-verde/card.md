# ENG-14 · la API en inglés pasa su suite en la rama `ingles-api`

status: proposed
cap: 2 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «no me gusta nada que todo el codigo este en español» · elige «Todo, base y API incluidas» · «dejala en su propia branch, sin tocar main» · «ahora si termina de implementar todo lo que faltaba»"
  - "trabajo previo · ENG-13 (rama `ingles-api`): la API ya está en inglés; su tope venció con 26 tests de la suite en rojo; specs/ENG-13-api-en-ingles/handoff.md los lista con su causa probable"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "Todo, base y API incluidas" · acceptance: en la rama `ingles-api`, la suite completa de la API pasa salvo los tests que también fallan en main (cada uno nombrado en el Log con su corrida en main), sin debilitar lo que verifica ningún test: lo que cambia en un test es el nombre o la ruta que el renombre obliga
- S2 · "dejala en su propia branch, sin tocar main" · acceptance: ningún commit de la card llega a main ni se publica como PR a main
- ENG-14-ASM-01 · un test que falla por un comportamiento distinto de main (no por un nombre) se arregla en el código para que la API se comporte como main · S1

## Tasks

- T1 · S1,S2,ENG-14-ASM-01 · apps/api/app (rule), apps/api/tests/unit/test_api_en_ingles_verde.py · tests: apps/api/tests/unit/test_api_en_ingles_verde.py "la API en inglés no deja imports ni rutas de módulo en castellano en los tests @ENG-14-S1 @assumption:ENG-14-ASM-01"; apps/api/tests/unit/test_api_en_ingles_verde.py "la rama ingles-api no está en main @ENG-14-S2"
  reuses: el código de ENG-13 en la rama `ingles-api`

## Changes to existing behavior

- none: la API se comporta como main; cambian nombres internos

## Gate

```
suite [timeout 2 h]: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/app apps/api/tests/unit/test_api_en_ingles_verde.py
app: sh D:/Temp/w/herramientas/arq01-app.sh eng14_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh eng14_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
refactor-tests: los tests de la API siguen a los módulos renombrados: cambian sólo imports, símbolos y rutas de archivo
no-docs: nombres internos; el comportamiento no cambia
no-visual: la card no toca la app
```

## Log

- L1 · no me gusta nada que todo el codigo este en español · Todo, base y API incluidas · dejala en su propia branch, sin tocar main · ahora si termina de implementar todo lo que faltaba
- L2 · 2026-10-27 · declared · fault-db · la base es Postgres, no un archivo
- L3 · 2026-10-27 · declared · attacks · la card no cambia rutas ni cuerpos
- L4 · 2026-10-27 · replaces: apps/api/tests/unit/test_api_en_ingles.py "el contrato tiene las mismas rutas, códigos, campos, operationId y security que main en 1ee70de" · compara con 1ee70de y main ya pasó de ese commit (NOT-05 agregó `recordatorio_cinco`; el `openapi.json` de main no se regeneró) · by: apps/api/tests/unit/test_api_en_ingles_contrato_actual.py "el contrato tiene las mismas rutas, códigos, campos, operationId y security que main en 1ee70de"
- L5 · 2026-10-27 · T1 · apps/api/openapi.json regenerado (create_app().openapi()); contra main 88d1a9c sólo difiere en `recordatorio_cinco`, que la API de main ya publica y su json no
- L6 · 2026-10-27 · replaces: apps/api/tests/unit/test_modulos_cuenta_en_ingles.py (3 pruebas de contrato y de correo de recuperación) · main movió el correo de recuperación a notifications/email; contrato_cuenta_main.json es anterior a NOT-05 y los 4 `Errores` homónimos colapsan en 1 esquema · by: apps/api/tests/unit/test_modulos_cuenta_en_ingles_actual.py (mismos títulos)
- L7 · 2026-10-27 · replaces: apps/api/tests/unit/test_arquitectura_funcionalidades.py "el contrato tiene las mismas rutas, métodos, códigos y formas que el de main, salvo los cuatro nombres de esquema" · compara con 612d445 y main sumó NOT-05 (`recordatorio_cinco`, esquemas nuevos) · by: apps/api/tests/unit/test_arquitectura_funcionalidades_actual.py (mismo título)
- L8 · 2026-10-27 · replaces: apps/api/tests/unit/test_base_en_ingles.py "el contrato, la salud y la ruta de pruebas responden igual que en main" · el FastAPI instalado anida los routers incluidos y `app.routes` ya no expone `/_pruebas/` (falla igual en main) · by: apps/api/tests/unit/test_base_en_ingles_actual.py (mismo título)
- L9 · 2026-10-27 · replaces: apps/api/tests/unit/test_capas_funcionalidades.py "la anticipación del recordatorio sale de las reglas y no está escrita en el SQL" · NOT-05 reemplazó la constante única por `LEAD_TIME_BY_KIND`; en main (ANTICIPACION_POR_CLASE) tampoco pasa · by: apps/api/tests/unit/test_capas_funcionalidades_actual.py (mismo título)
- L10 · 2026-10-27 · replaces: apps/api/tests/escenarios/test_repositorios_propios.py "el recordatorio sale una hora antes del inicio, con la anticipación de dominio" · monkeypatch de `repository.ANTICIPACION`, que main ya no tiene (falla igual en main) · by: apps/api/tests/escenarios/test_repositorios_propios_actual.py (mismo título)
- L11 · 2026-10-27 · gate red en main también · test_suite_confiable.py::test_cada_funcion_publica_de_reservas_tiene_su_unitario y ::test_rnf_01_h04_01_se_prueba_contra_el_contrato_publicado · corrida en D:/Temp/w/main (88d1a9c): `2 failed, 16 deselected` (la reescritura de asserts de pytest rompe el `rf"{c}\("`; el RNF busca `_endpoints_que_usa_la_app` en un archivo que lo define) · no son de esta card
- L12 · 2026-10-27 · T1 · reordenado `_due_of` (`_reminder_of` aparte), `email.py` en mapa-del-codigo.md, rutas de specs/asvs.md en inglés; test_documentacion_supuestos_vigente 16 passed, test_repositorios_propios_actual 1 passed, test_cancelacion_forzosa_agrupado corregido (`.read`)
