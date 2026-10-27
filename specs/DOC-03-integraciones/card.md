# DOC-03 · la documentación explica cada integración y dónde se hace

status: proposed
cap: 1 h
sources:
  - "pedido (texto) · mensaje del usuario en la sesión (2026-10-27): «y la docu lo mas importante que tiene que tener, tiene que hablar de las integraciones y donde se hace cada una»"
  - "repo · docs/technical/{arquitectura,system-design,mapa-del-codigo,runbook}.md (mencionan integraciones repartidas), render.yaml, firebase.json, apps/api/app/shared/config.py, apps/api/app/shared/correo.py, apps/api/app/modules/notificaciones/push.py, apps/mobile/lib/sesion/firebase.dart, apps/mobile/lib/notificaciones/sistema_fcm.dart"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "tiene que hablar de las integraciones" · acceptance: `docs/technical/integraciones.md` tiene una sección por cada servicio externo que usa el sistema: Firebase Authentication, Firebase Cloud Messaging, Brevo (correo, con SMTP y buzón como alternativas), PostgreSQL en Render, Render (API y despliegue) y el monitor que mantiene despierta la API; cada sección dice para qué se usa
- S2 · "y donde se hace cada una" · acceptance: cada sección nombra los archivos exactos del repo donde se hace la integración (de la API, de la app o de la configuración, los que existan para ese servicio) y los nombres de las variables de entorno o de compilación que necesita
- DOC-03-ASM-01 · los nombres de archivo y de variable que cita el documento existen en el repo: un test lo verifica, así el documento no queda viejo sin que nadie se entere · S2
- DOC-03-ASM-02 · el documento se enlaza desde `docs/technical/arquitectura.md` y `system-design.md`, que hoy mencionan las integraciones sueltas · S1
- DOC-03-ASM-03 · el documento cita sólo nombres de variables, nunca valores: ni claves (Brevo, Firebase), ni la cuenta de servicio, ni URLs de base con contraseña; un test busca formas de secreto (`xkeysib-`, `rnd_`, `postgresql://…:…@`, `"private_key"`) y no encuentra ninguna · S2
- DOC-03-ASM-04 · un servicio sin archivo en la app (PostgreSQL, Render, el monitor) nombra sólo los archivos que tiene (configuración, API o despliegue); el «qué pasa si no responde» y el «cómo se prueba en local» se suman como una línea por sección sólo donde ya están en el runbook, sin inventarlos · S2

## Tasks

- T1 · S1,S2,DOC-03-ASM-01,DOC-03-ASM-02,DOC-03-ASM-03,DOC-03-ASM-04 · docs/technical/integraciones.md (presentation), docs/technical/arquitectura.md (presentation), docs/technical/system-design.md (presentation) · tests: apps/api/tests/unit/test_integraciones_documentadas.py "integraciones.md tiene una sección por servicio con para qué se usa @DOC-03-S1 @assumption:DOC-03-ASM-02"; apps/api/tests/unit/test_integraciones_documentadas.py "cada sección nombra sus archivos y sus variables @DOC-03-S2 @assumption:DOC-03-ASM-04"; apps/api/tests/unit/test_integraciones_documentadas.py "cada archivo y variable que cita integraciones.md existe en el repo @assumption:DOC-03-ASM-01"; apps/api/tests/unit/test_integraciones_documentadas.py "integraciones.md no tiene claves, cuentas de servicio ni URLs con contraseña @assumption:DOC-03-ASM-03"
  new: no había un documento de integraciones; estaban repartidas en arquitectura.md, system-design.md y mapa-del-codigo.md

## Changes to existing behavior

- none: la card agrega documentación

## Gate

```
suite: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_integraciones_documentadas.py
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/tests/unit/test_integraciones_documentadas.py
refactor-tests: apps/api/tests/unit/test_integraciones_documentadas.py · el linter (E501, 100 columnas) rechaza líneas largas de los tests recién escritos; sólo se parten líneas, sin cambiar lo que verifican
no-visual: la card agrega documentación; ninguna pantalla
```

## Log

- L1 · y la docu lo mas importante que tiene que tener, tiene que hablar de las integraciones y donde se hace cada una
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base
- L3 · 2026-10-27 · declared · attacks · la card no toca la API
- L4 · 2026-10-27 · el juez del plan pide que no se citen valores secretos (ACT-01: DOC-03-ASM-03), qué escribe un servicio sin archivos en la app (ACT-02: DOC-03-ASM-04, S2 dice «los que existan») y no sumar lo que L1 no pide (ACT-03: S1 y S2 sin «qué pasa si no responde» ni «cómo se prueba en local» como exigencia; ASM-04 los deja sólo donde el runbook ya los tiene)
- L5 · 2026-10-27 · declared · DOC-03-ASM-04 · las líneas de caída y de prueba local son opcionales y copian el runbook; el test de S2 verifica archivos y variables, que es lo que el supuesto exige
- L6 · 2026-10-27 · declared · S1 · S1 ya no pide «qué pasa si no responde» ni «cómo se prueba en local» (L4); su único miembro es «para qué se usa», que verifica su test
- L7 · 2026-10-27 · T1 · node .claude/tools/verify.mjs → exit 0 (lint, suite, specs, layers, shape, overdesign, migrations, boundaries, required passed); integraciones.md + enlaces desde arquitectura.md y system-design.md; refactor-tests declarado en Gate (sólo se partieron líneas largas por E501)
