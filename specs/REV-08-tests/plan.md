# Plan — REV-08 · tests

## Time plan

1. Size and risk: 2 archivos de producción de la app (manifiesto de rutas y cliente de la API) y la suite: `conftest.py`, dos recongelados de RNF-01, los dos tests engañosos de `test_restricciones.py`, unitarios nuevos de `aplicacion/reservas.py` · riesgo: bajo en producto; alto en dejar la suite más débil sin darse cuenta
2. without method: 90–150–240 min · goal: 750 min · cap: 12 h
3. Critical path: rebase sobre `card/REV-01` (trae `apps/api/openapi.json` y `GET /health`) → tests en rojo → plan → implementer → verify con la suite entera → juicio · on the side from the start: `uv sync` y `flutter pub get` (hechos)
4. Split: plan 40 · code 200 · verification 300 · correction 200 min
5. Cut if it does not fit: el conteo de consultas de `GET /espacios/disponibles`; nunca un chequeo de la vara

## Verification

```
suite: cd apps/api && uv run --no-sync pytest -q -p no:cacheprovider
lint: cd apps/api && uv run --no-sync ruff check . && uv run --no-sync mypy --strict app
app-suite: cd apps/mobile && flutter analyze && flutter test
scenarios: cd apps/api && uv run --no-sync pytest -q -p no:cacheprovider tests/escenarios/test_suite_confiable.py
mutate apps/api/app/aplicacion/reservas.py: cd apps/api && uv run --no-sync pytest -q -x tests/unit/test_casos_de_uso_reservas.py
```

`cliente_api.dart` y `rutas.dart` son Dart: sin mutador, «no se pudo correr». La mutación de `aplicacion/reservas.py` es la que el hallazgo 23 no pudo medir: se corre con los unitarios nuevos, que no necesitan base ni emulador.

## File map

Grupo 1 · la suite de la API
- apps/api/tests/conftest.py — sin `FIREBASE_AUTH_EMULATOR_HOST` la sesión termina con error y el mensaje «hace falta el emulador de Firebase Auth»; con `--sin-emulador` los tests de API se saltan y queda dicho en la salida
- apps/api/tests/escenarios/test_requisitos_no_funcionales.py — recongelado con `node .claude/tools/refreeze.mjs` y su evento: RNF-01-H06-02 exige `>= 28` y suma `/health` a las públicas; RNF-01-H04-01 deja de leer Dart con regex (lo cubre el manifiesto de la app) y sigue comprobando que `/openapi.json` publique y `/docs` responda
- apps/api/tests/integracion/test_restricciones.py — salen `test_la_reserva_dura_entre_una_y_cuatro_horas` y `test_la_baja_libera_el_correo_y_el_dni`, reemplazados por los escenarios REV-08-H23-02 y H23-03 (no tienen tag: no están congelados)
- apps/api/tests/unit/test_casos_de_uso_reservas.py — nuevo: unitarios de los siete casos de uso de `aplicacion/reservas.py` con un repositorio en memoria y `ahora` fijo, sin base ni emulador

Grupo 2 · las rutas de la app
- apps/mobile/lib/api/rutas.dart — nuevo: `rutasDeLaApi`, la lista de `(metodo, ruta)` que usa la app, con las rutas escritas como en el contrato (`/reservas/{reserva_id}/cancelar`) · rule · test: apps/mobile/test/rutas_de_la_api_test.dart
- apps/mobile/lib/api/cliente_api.dart — en modo debug, `assert` de que cada pedido coincide con una ruta declarada; en release no cambia nada

Tests
- apps/api/tests/escenarios/test_suite_confiable.py, apps/mobile/test/rutas_de_la_api_test.dart, apps/mobile/test/anular_desde_el_detalle_test.dart — los escenarios REV-08 (rojo o verde de inicio, del hilo principal)

- System design: unchanged — sin módulos ni datos
- ADR: unchanged

## Assumptions

- REV-08-ASM-01 · la anulación desde el detalle del historial (CU-14-H01-07 y H08-01) se prueba con tag de esta card aunque ya funcione: faltaba el test · any-answer: yes
- REV-08-ASM-02 · toda operación no pública responde 401 sin sesión y se cuentan todas las del contrato; hoy son 28; RNF-01-H06-02 se recongela a `>= 28` · any-answer: yes
- REV-08-ASM-03 · sin el emulador, la corrida falla con un mensaje claro; saltarse los tests de API sólo pasa con `--sin-emulador` · any-answer: yes
- REV-08-ASM-04 · la app declara sus rutas en `lib/api/rutas.dart`; su cliente falla en debug si pide otra, así todos los widget tests lo vigilan; un test compara el manifiesto con `apps/api/openapi.json` · any-answer: yes
- REV-08-ASM-05 · los pedidos de uso diario con consultas fijas son `GET /reservas`, `GET /sedes` y `GET /reservas/todas` · any-answer: yes
- REV-08-ASM-06 · los dos tests engañosos de `test_restricciones.py` se quitan, porque los escenarios nuevos prueban lo que sus nombres prometían · any-answer: yes

## Perimeter

Base `club_rev08_test` y emulador en `127.0.0.1:9099`. La rama parte de `card/REV-01` para tener el contrato versionado y `/health`. Fuera: la mutación de Dart, la cobertura de Flutter, las corridas de diez veces de toda la suite (T7, T8) salvo los escenarios nuevos.

## Bar

- R1 · los escenarios corren la suite como la corre quien la usa (subprocess de pytest, widget tests)
- R2–R5 · diez preguntas, AMB-01 a AMB-05, preguntas en lenguaje del club
- R6 · un test con tag por escenario
- R7–R8 · cada hunk corresponde al hallazgo 23 o a los dos escenarios de CU-14
- R9–R10 · not applicable
- D1–D15 · `rutas.dart` es el contrato de la app con la API (D12); lo demás not applicable · sin módulos nuevos
- K1–K11 · ruff, mypy, analyze limpios; nombres que dicen lo que prueban (el centro de la card)
- E1–E16 · not applicable · sin comportamiento de errores nuevo en producción
- T1 · rojo antes del código; los que pasan de inicio (H23-02, H23-03, H23-06, H30) se declaran: el defecto era la falta de test
- T2 · se sube una cota ablandada; ninguna se baja
- T3 · mutación de `aplicacion/reservas.py` con los unitarios nuevos
- T4 · cada test afirma un resultado
- T5 · el regex sobre Dart sale de RNF-01-H04-01
- T6 · los tests nuevos no tienen lógica fuera de fixtures y ayudantes
- T7 · cada test crea sus datos
- T8 · los nuevos tres veces (`repeat.mjs`)
- T9 · los casos de uso de reservas sin base
- T10 · cada borde con su test (0, 1, 4, 5 horas)
- T11 · cobertura si `pytest-cov` está; si no, «no se pudo correr»
- T12 · los widget tests buscan por texto
- T13 · `rutas.dart` marcado `rule`
- T14 · no applicable
- S1–S24 · not applicable
- P1–P9 · not applicable
- P10 · el conteo de consultas por pedido (H23-06)
- P11–P16 · not applicable
- O1–O29 · not applicable
- I1–I26 · not applicable · no cambia pantallas
- C1–C2 · not applicable
- C3 · la suite entera sigue verde, con más tests
- C4 · not applicable
- A1–A9 · cada «pasó» con su comando; ningún test se apaga (A9: los que salen se reemplazan por los escenarios)
- V1 · snapshot en bad92cc
- V2–V7 · plan antes del código, commits con qué y por qué
- W5 · not applicable
- W8 · not applicable
- W9 · el manifiesto de la app contra el contrato de la API
- ci · off by decision · not chosen at install: no signal found in the repo
- docs · off by decision · not chosen at install: no signal found in the repo
- i18n · off by decision · not chosen at install: no signal found in the repo

## Edges

- Defense against legitimate data · rutas con parámetros (`{reserva_id}`) se comparan como plantilla
- State after the action · not applicable
- Honest notices · el salto sin emulador queda dicho en la salida
- What does not exist · una ruta no declarada falla en debug
- Writes · not applicable
- Origin of the request · not applicable
- What travels to another program · not applicable
- Restart · not applicable
- What no test notices · que un widget test que no toca el cliente use una ruta: lo cubre el resto de la suite

## Changes to existing behavior

- README: `apps/api/README.md` dice cómo correr la suite sin emulador (`--sin-emulador`) y que sin él falla
- ASVS: unchanged
- La suite falla sin emulador en vez de salir verde
- RNF-01-H06-02 y RNF-01-H04-01 recongelados
- La app falla en debug si pide una ruta no declarada; en release, igual que hoy
