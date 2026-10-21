# Plan — REV-05 · Básquet en el catálogo

## Time plan

1. Size and risk: 3 archivos de producción (catálogo de la API, ícono y foto de la app) y los JSON de catálogo de los tests de la app · riesgo: bajo
2. without method: 15–30–60 min · goal: 150 min · cap: 5 h
3. Critical path: tests en rojo → plan → implementer → verify → juicio · on the side from the start: `uv sync` y `flutter pub get` (hechos)
4. Split: plan 20 · code 40 · verification 60 · correction 30 min
5. Cut if it does not fit: nada; la card es chica

## Verification

```
suite: cd apps/api && uv run --no-sync pytest -q -p no:cacheprovider
lint: cd apps/api && uv run --no-sync ruff check . && uv run --no-sync mypy --strict app
app-suite: cd apps/mobile && flutter analyze && flutter test
scenarios: cd apps/api && uv run --no-sync pytest -q -p no:cacheprovider tests/escenarios/test_basquet.py
mutate apps/api/app/dominio/espacios.py: cd apps/api && uv run --no-sync pytest -q -x tests/unit/test_espacios.py tests/escenarios/test_basquet.py
```

La app es Flutter: sin mutador de Dart, la mutación de `iconos.dart` y `fotos.dart` queda «no se pudo correr».

## File map

- apps/api/app/dominio/espacios.py — `CATALOGO` suma `Deporte("Basquet", "Básquet", (Tipo("B5", "Básquet 5"), Tipo("3X3", "Básquet 3x3")))`, después de Vóley · rule · test: apps/api/tests/escenarios/test_basquet.py
- apps/mobile/lib/espacios/iconos.dart — `'Basquet' => Icons.sports_basketball_rounded` · presentation
- apps/mobile/lib/sedes/fotos.dart — `'Basquet'` toma la portada 1, que ningún deporte usa · presentation
- apps/mobile/test/soporte/montar.dart — el `_catalogoJson` de prueba suma Básquet (una línea nueva)
- apps/api/tests/escenarios/test_basquet.py, apps/mobile/test/basquet_test.dart — los escenarios (rojo, del hilo principal)

- System design: unchanged — sin módulos ni datos nuevos
- ADR: unchanged — no cambia la arquitectura

## Assumptions

- REV-05-ASM-01 · Básquet tiene dos tipos: «Básquet 5» (`B5`, cancha completa) y «Básquet 3x3» (`3X3`, media cancha) · any-answer: yes
- REV-05-ASM-02 · hasta que haya una foto de Básquet, la cancha toma la portada 1 del club, que no es de ningún otro deporte · any-answer: yes
- REV-05-ASM-03 · Básquet va después de Vóley en el catálogo · any-answer: yes

## Perimeter

API real con el emulador de Firebase Auth en `127.0.0.1:9099` y la base `club_rev05_test`; la app con widget tests. CU-21-SUP-04 queda reemplazado por esta card. Fuera: fotos nuevas, otros deportes.

## Bar

- R1 · el catálogo, el alta y el filtro se prueban por HTTP con sesiones reales
- R2 · diez preguntas y AMB-01 a AMB-03
- R3 · cada ASM dice si sirve con cualquier respuesta
- R4 · ASM-01 va en `apps/api/README.md` junto al catálogo
- R5 · preguntas en lenguaje del club
- R6 · un test con tag por escenario
- R7 · cada hunk corresponde al hallazgo 19
- R8 · lo ajeno visto va como `REV-05-OUT-NN`
- R9–R10 · not applicable · sin requisitos no funcionales ni seguridad nuevos
- D1–D4 · el catálogo sigue en un solo lugar del dominio
- D5 · la app repite las claves de deporte para ícono y foto: se suma la de Básquet; unificarlo es de REV-06
- D6–D15 · not applicable · sin módulos, dependencias ni contratos nuevos
- K1–K11 · ruff, mypy y analyze limpios; nombres del dominio
- E1–E16 · not applicable · sin escrituras ni errores nuevos
- T1 · rojo antes del código
- T2 · ningún test se ablanda
- T3 · mutación de `dominio/espacios.py` con su subconjunto; Dart «no se pudo correr»
- T4–T10 · cada test afirma lo que ve el socio o el admin; borde: un tipo de otro deporte se rechaza
- T11 · cobertura si `pytest-cov` está; si no, «no se pudo correr»
- T12 · no applicable · los tests de la app son de función
- T13 · `dominio/espacios.py` marcado `rule`
- T14 · no applicable
- S1–S24 · not applicable · sin superficie nueva
- P1–P16 · not applicable · sin datos nuevos: el deporte ya es texto libre en la base
- O1–O29 · not applicable · sin operación nueva
- I1–I26 · el filtro y el alta suman una opción con ícono; las guías de las pantallas no cambian
- C1 · la app lee el catálogo de la API: Básquet aparece sin cambio de contrato
- C2–C4 · las respuestas existentes no cambian; el catálogo suma un deporte
- A1–A9 · cada «pasó» con su comando; diff chico; nada se apaga
- V1 · snapshot en b7d7c30
- V2–V7 · plan antes del código, commits con qué y por qué, cierre de las validaciones
- W5 · not applicable
- W8 · el catálogo documentado en OpenAPI no cambia de forma
- W9 · not applicable
- ci · off by decision · not chosen at install: no signal found in the repo
- docs · off by decision · not chosen at install: no signal found in the repo
- i18n · off by decision · not chosen at install: no signal found in the repo

## Edges

- Defense against legitimate data · la tilde de «Básquet» se conserva en el nombre y se normaliza en el nombre generado (`_Basquet_`)
- State after the action · la cancha de Básquet queda activa como cualquier otra
- Honest notices · un tipo ajeno se rechaza con el mensaje de siempre
- What does not exist · not applicable
- Writes · not applicable
- Origin of the request · not applicable
- What travels to another program · not applicable
- Restart · not applicable
- What no test notices · que la portada 1 se vea bien en la tarjeta de Básquet: se mira en las capturas

## Changes to existing behavior

- README: `apps/api/README.md` suma Básquet y sus tipos a la descripción del catálogo
- ASVS: unchanged — sin seguridad
- El catálogo suma Básquet con dos tipos; lo demás queda igual

## Visual brief

- Sin pantallas nuevas: el filtro de deportes y el alta de espacio suman la opción Básquet con `Icons.sports_basketball_rounded`; la tarjeta de una cancha de Básquet usa la portada 1.
