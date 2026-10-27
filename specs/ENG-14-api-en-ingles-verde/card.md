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
