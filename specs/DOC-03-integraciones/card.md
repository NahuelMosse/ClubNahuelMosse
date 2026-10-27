# DOC-03 · la documentación explica cada integración y dónde se hace

status: proposed
cap: 1 h
sources:
  - "pedido (texto) · mensaje del usuario en la sesión (2026-10-27): «y la docu lo mas importante que tiene que tener, tiene que hablar de las integraciones y donde se hace cada una»"
  - "repo · docs/technical/{arquitectura,system-design,mapa-del-codigo,runbook}.md (mencionan integraciones repartidas), render.yaml, firebase.json, apps/api/app/shared/config.py, apps/api/app/shared/correo.py, apps/api/app/modules/notificaciones/push.py, apps/mobile/lib/sesion/firebase.dart, apps/mobile/lib/notificaciones/sistema_fcm.dart"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "tiene que hablar de las integraciones" · acceptance: `docs/technical/integraciones.md` tiene una sección por cada servicio externo que usa el sistema: Firebase Authentication, Firebase Cloud Messaging, Brevo (correo, con SMTP y buzón como alternativas), PostgreSQL en Render, Render (API y despliegue) y el monitor que mantiene despierta la API; cada sección dice para qué se usa y qué pasa si el servicio no responde
- S2 · "y donde se hace cada una" · acceptance: cada sección nombra los archivos exactos de la API y de la app donde se hace la integración (con ruta del repo), las variables de entorno o de compilación que necesita, y cómo se prueba en local (emulador de Auth, buzón de correo, Postgres local)
- DOC-03-ASM-01 · los nombres de archivo y de variable que cita el documento existen en el repo: un test lo verifica, así el documento no queda viejo sin que nadie se entere · S2
- DOC-03-ASM-02 · el documento se enlaza desde `docs/technical/arquitectura.md` y `system-design.md`, que hoy mencionan las integraciones sueltas · S1

## Tasks

- T1 · S1,S2,DOC-03-ASM-01,DOC-03-ASM-02 · docs/technical/integraciones.md (presentation), docs/technical/arquitectura.md (presentation), docs/technical/system-design.md (presentation) · tests: apps/api/tests/unit/test_integraciones_documentadas.py "integraciones.md tiene una sección por servicio con para qué se usa y qué pasa si no responde @DOC-03-S1 @assumption:DOC-03-ASM-02"; apps/api/tests/unit/test_integraciones_documentadas.py "cada sección nombra sus archivos, variables y cómo se prueba en local @DOC-03-S2"; apps/api/tests/unit/test_integraciones_documentadas.py "cada archivo y variable que cita integraciones.md existe en el repo @assumption:DOC-03-ASM-01"
  new: no había un documento de integraciones; estaban repartidas en arquitectura.md, system-design.md y mapa-del-codigo.md

## Changes to existing behavior

- none: la card agrega documentación

## Gate

```
suite: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_integraciones_documentadas.py
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/tests/unit/test_integraciones_documentadas.py
no-visual: la card agrega documentación; ninguna pantalla
```

## Log

- L1 · y la docu lo mas importante que tiene que tener, tiene que hablar de las integraciones y donde se hace cada una
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base
- L3 · 2026-10-27 · declared · attacks · la card no toca la API
