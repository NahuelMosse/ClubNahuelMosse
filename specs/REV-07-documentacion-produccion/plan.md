# Plan — REV-07 · documentación de producción

## Time plan

1. Size and risk: documentación (matriz ASVS de 253 requisitos, diseño del sistema, dos ADR, avisos de terceros con su script, costos, runbook, declaración de accesibilidad, tres README) y un archivo de licencia · riesgo: bajo en código; alto en afirmar algo que no se verificó
2. without method: 180–300–480 min · goal: 1500 min · cap: 20 h
3. Critical path: tests en rojo → plan → implementer grupo 1 (diseño y modelo de datos) → grupo 2 (ASVS) → grupo 3 (licencias) → grupo 4 (operación y README) → verify → juicio · on the side from the start: nada que instalar
4. Split: plan 60 · code 600 · verification 300 · correction 240 min
5. Cut if it does not fit: el detalle de evidencia de las filas `not applicable` de la ASVS (queda la razón del requisito); nunca un chequeo de la vara

## Verification

```
suite: cd apps/api && uv run --no-sync pytest -q -p no:cacheprovider
scenarios: cd apps/api && uv run --no-sync pytest -q -p no:cacheprovider tests/escenarios/test_documentacion.py
lint: cd apps/api && uv run --no-sync ruff check tests/escenarios/test_documentacion.py ../../scripts/avisos_de_terceros.py && uv run --no-sync ruff format --check tests/escenarios/test_documentacion.py ../../scripts/avisos_de_terceros.py
notices: uv run --directory apps/api --no-sync python ../../scripts/avisos_de_terceros.py --comprobar
```

La card no cambia código de producción: la mutación no aplica (`required.mjs` lo dirá; si pide algo, «no se pudo correr» con el motivo).

## File map

Grupo 1 · diseño del sistema y modelo de datos
- docs/technical/system-design.md — nuevo, desde `.claude/templates/system-design.md`: C4 (app Flutter, API FastAPI, Postgres, Firebase Auth, FCM, SMTP, Render); `## Data` con las tablas de las migraciones 0001 a 0007 (columnas, claves, índices, triggers, qué guarda cada una); `## Infrastructure` con local y Render; `## External dependencies` con timeout, reintento y qué pasa si falla cada una, leídos del código; `## Threat model` STRIDE por superficie; SLOs de disponibilidad y latencia como objetivo sin medir; presupuesto de rendimiento (p95) y capacidad; RPO/RTO y retención como están hoy (sin backups en la base free); `## Personal data` con el inventario (DNI, nacimiento, correo, token de dispositivo) y la Ley 25.326
- docs/adr/0001-stack.md, docs/adr/0002-hosting-en-render.md — nuevos, desde `.claude/templates/adr.md`, `accepted`, con la fecha del commit que adoptó cada cosa

Grupo 2 · seguridad
- specs/asvs.md — nuevo: nivel 1 y nivel 2 completos (`.claude/templates/asvs-level-1.md` y `asvs-level-2.md`), cada fila con `meets`, `fails`, `not verified` o `not applicable` y su evidencia (test, archivo:línea o comando); las filas que hoy fallan nombran el hallazgo de `specs/REVISION-kit3.md` y la card REV-NN que lo corrige; V15.1.1 queda `fails` hasta que una persona fije los plazos (REV-07-ASM-06)

Grupo 3 · licencias
- scripts/avisos_de_terceros.py — nuevo: arma `THIRD_PARTY_NOTICES.md` desde los metadatos de los paquetes instalados de la API (`importlib.metadata`, sin los de desarrollo) y desde `apps/mobile/pubspec.lock` más la licencia en el caché de pub; `--comprobar` sale distinto de cero si el archivo no coincide
- THIRD_PARTY_NOTICES.md — nuevo, generado por el script: cada dependencia con versión, licencia SPDX y atribución; secciones `## MPL-2.0` (certifi: se usa sin modificar, el código fuente está en su repositorio) y `## LGPL-3.0` (psycopg: se usa como biblioteca enlazada dinámicamente, sin modificar, reemplazable); las fuentes Inter con OFL-1.1
- apps/mobile/assets/fuentes/OFL.txt — nuevo: el texto de la SIL Open Font License 1.1 de Inter

Grupo 4 · operación y README
- docs/technical/infra-cost.md — nuevo, desde `.claude/templates/infra-cost.md`: hoy USD 0 (web y base free de Render); las alternativas con precios de https://render.com/pricing.md consultado el 2026-10-20: web 0.5c-512mb USD 7/mes, Postgres 0.1c-256mb USD 6/mes, 0.5c-1g USD 19/mes, almacenamiento USD 0,30/GB, cron USD 0,00016/min
- docs/technical/runbook.md — nuevo, desde `.claude/templates/runbook.md`: deploy y vuelta atrás con `render.yaml`, diagnóstico, incidentes, rotación de las variables `sync: false` de `render.yaml`; dueño y revisión como pendientes de una persona
- docs/business/accessibility.md — nuevo, desde `.claude/templates/accessibility-statement.md`: estado de conformidad con los cuatro términos de VPAT y el registro por pantalla (cada `lib/**/pantalla_*.dart`) con lo verificado y lo no verificado (TalkBack sin correr)
- README.md — nuevo en la raíz: qué es, cómo se arma, enlaces a los dos README y a `docs/`
- apps/api/README.md, apps/mobile/README.md — suman la sección de supuestos con sus IDs (`- CU-09-SUP-NN · …`), los que cambian lo que ve quien usa o hace quien opera

Tests
- apps/api/tests/escenarios/test_documentacion.py — los escenarios REV-07 (rojo, del hilo principal)

- System design: written by this card
- ADR: written by this card (stack y hosting)

## Assumptions

- REV-07-ASM-01 · donde hoy falta algo (backups, SLOs medidos, presupuesto) el documento lo dice tal cual y escribe el objetivo como meta sin medir · any-answer: no — si se quiere sólo lo que existe, las metas salen
- REV-07-ASM-02 · los README listan los supuestos que cambian lo que ve quien usa o lo que hace quien opera, con su ID, no los 545 · any-answer: yes
- REV-07-ASM-03 · el modelo de datos lleva columnas, claves, índices y triggers de cada tabla · any-answer: yes
- REV-07-ASM-04 · estos documentos se escriben aunque el módulo docs esté apagado: los pide el grado production (R9, D8, D9, S15, S19, S21, O13, O14, P7, P14, P15, W5, I17) · any-answer: yes
- REV-07-ASM-05 · los documentos describen `kit-3`; al integrar las otras cards, las filas y secciones que cambian se actualizan en esa integración · any-answer: yes
- REV-07-ASM-06 · las filas ASVS que hoy fallan quedan `fails` con el hallazgo y la card que las corrige; los plazos de remediación (V15.1.1) los decide una persona y la fila queda `fails` hasta entonces · any-answer: yes
- REV-07-ASM-07 · los avisos de terceros cubren todas las dependencias de producción (directas y transitivas) que el script lee de los metadatos instalados y de `pubspec.lock` · any-answer: yes
- REV-07-ASM-08 · los precios salen de https://render.com/pricing.md consultado el 2026-10-20; la página no dice si la base free tiene backups, y el documento lo cita así · any-answer: yes

## Perimeter

Sólo documentación, un script de generación y un archivo de licencia. No cambia comportamiento. Los datos se toman del código de `kit-3` (los extrae un `scout` o el implementer leyendo) y de la revisión; nada se afirma sin su evidencia. Los snapshots viejos no se tocan (hallazgo 24, declarado). Fuera: corregir lo que la matriz marca `fails` (REV-01 a REV-06).

## Bar

- R1 · los tests leen los documentos que una persona abre en el repo
- R2 · diez preguntas y AMB-01 a AMB-05
- R3 · cada ASM dice si sirve con cualquier respuesta
- R4 · los supuestos de operación en los README, con ID (el escenario H22-01)
- R5 · preguntas en lenguaje del club
- R6 · un test con tag por escenario
- R7 · cada archivo corresponde a los hallazgos 21, 22 o S12
- R8 · lo ajeno visto va como `REV-07-OUT-NN`
- R9 · el presupuesto de rendimiento y capacidad queda escrito (H21-09)
- R10 · ASVS nivel 2 elegido (módulo security-l2) y respondido entero (H21-01)
- D1–D7 · not applicable · sin código de producción
- D8 · la matriz de dependencias externas con timeout, reintento y falla (H21-02)
- D9 · STRIDE por superficie (H21-02)
- D10–D13 · not applicable · sin código
- D14 · los ADR de stack y hosting (H21-03)
- D15 · not applicable
- K1–K11 · el script sigue ruff y mypy; lo demás no aplica · sin código de producción
- E1–E16 · not applicable · sin comportamiento nuevo
- T1 · rojo antes de los documentos
- T2 · ningún test se ablanda
- T3 · not applicable · sin código de producción que mutar
- T4 · cada test afirma el contenido que pide el escenario
- T5 · los tests leen documentos porque el requisito es el documento
- T6 · sin lógica salvo leer secciones
- T7 · no dependen del orden
- T8 · deterministas
- T9–T14 · not applicable · sin reglas de negocio ni pantallas
- S1–S14 · not applicable · la card no cambia seguridad; documenta su estado
- S15 · la matriz ASVS entera
- S16–S18 · not applicable
- S19 · `THIRD_PARTY_NOTICES.md` generado por comando, con atribución
- S20 · not applicable · el usuario propio de base es de REV-02; la matriz lo marca `fails`
- S21 · STRIDE por superficie en system-design.md
- S22 · el inventario de secretos en system-design.md y la rotación en el runbook
- S24 · not applicable
- P1–P6 · not applicable · sin datos nuevos
- P7 · retención, backups, RPO y RTO como están hoy en system-design.md
- P8–P13 · not applicable
- P14 · el modelo de datos de todas las tablas en system-design.md
- P15 · datos personales inventariados y clasificados, con la Ley 25.326
- P16 · not applicable
- O1–O12 · not applicable · sin cambios de operación
- O13 · el modelo de costos versionado
- O14 · la infraestructura como está hoy en system-design.md
- O15–O19 · not applicable
- O20 · SLOs como objetivo, coherentes con lo medido en la revisión (p95 local de ~55 ms)
- O21–O29 · not applicable · los corrige REV-02
- I1–I16 · not applicable · sin pantallas
- I17 · la declaración de accesibilidad
- I18–I26 · not applicable
- C1–C4 · not applicable · sin comportamiento
- A1 · cada «pasó» con su comando
- A2 · el cierre nombra sólo lo del diff
- A3 · AMB registradas, sin canal → ASM
- A4 · hooks y `verify.mjs`
- A5 · diff proporcional
- A6 · los README enlazan los documentos
- A7 · el juicio no reemplaza un comando
- A8 · not applicable
- A9 · ningún test se apaga
- V1 · snapshot en 3b040b0
- V2 · este plan antes de los documentos
- V3 · commits con qué y por qué
- V4 · registro de la sesión
- V5 · el registro de accesibilidad por pantalla
- V6 · el cierre sale de las validaciones
- V7 · una persona aprueba antes de integrar
- W5 · el runbook
- W8 · not applicable · el contrato lo versiona REV-01
- W9 · not applicable
- ci · off by decision · not chosen at install: no signal found in the repo
- docs · off by decision · not chosen at install: no signal found in the repo
- i18n · off by decision · not chosen at install: no signal found in the repo

## Edges

- Defense against legitimate data · nombres de paquetes con guion y punto en los avisos
- State after the action · el script regenera el mismo archivo (`--comprobar`)
- Honest notices · lo que no existe se dice; lo no verificado queda `not verified`
- What does not exist · not applicable
- Writes · not applicable
- Origin of the request · not applicable
- What travels to another program · not applicable
- Restart · not applicable
- What no test notices · que cada afirmación del documento sea cierta: lo juzga el inspector contra el código

## Changes to existing behavior

- README: nuevo en la raíz; `apps/api/README.md` y `apps/mobile/README.md` suman los supuestos
- ASVS: `specs/asvs.md` nuevo, niveles 1 y 2
- Nuevo: system-design, dos ADR, avisos de terceros y su script, costos, runbook, declaración de accesibilidad, licencia OFL
- Nada del comportamiento de la app cambia
