# DOC-05 · el README presenta el proyecto con capturas reales de la app

status: proposed
cap: 1 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «el readme me lo podes dejar lindo tambien, con fotos de la aplicacion real» · «vendiendo el proyecto»"
  - "capturas · tomadas del emulador Android (2026-10-27) con el APK de release contra la API de Render: pantalla de carga, inicio de sesión, inicio (oscuro y claro), sedes, sede, horarios, confirmación, reserva confirmada, mis reservas, notificaciones y perfil; el panel de administración sale de la captura de prueba `apps/mobile/test/capturas/admin/reservas_430_oscuro.png`"
  - "repo · README.md (hoy: tabla de partes, cómo se usa, documentación), docs/technical/integraciones.md, docs/guia-basica.md, apps/api/tests/escenarios/test_documentacion_vigente.py, test_documentacion_supuestos_vigente.py, test_readme_app_configuracion.py, test_requisitos_no_funcionales.py, test_requisitos_no_funcionales_readme_app.py (leen el README)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "con fotos de la aplicacion real" · acceptance: el README muestra capturas reales de la app guardadas en `docs/capturas/` (de 360 px de ancho), ordenadas como el recorrido de una persona: entra, busca sede y cancha, elige horario, confirma, ve sus reservas y sus avisos; y una del panel de administración
- S2 · "vendiendo el proyecto" · acceptance: el README abre con qué es y para quién en dos frases, sigue con lo que la app hace (funcionalidades con sus capturas), cómo está hecha (Flutter, FastAPI, PostgreSQL, Firebase Auth y Cloud Messaging, Brevo, Render) con enlace a `docs/technical/integraciones.md`, y termina con cómo correrla y la documentación; sin prometer nada que la app no haga hoy
- DOC-05-ASM-01 · lo que los tests leen hoy del README (enlaces, comandos, secciones) se conserva · S2
- DOC-05-ASM-02 · la captura del panel de administración es la de la suite de pruebas (datos de prueba), y el README lo aclara en su epígrafe · S1
- DOC-05-ASM-03 · las capturas muestran sólo la cuenta de prueba (`socio@test.test`, datos inventados) y el README no publica ninguna contraseña ni clave · S1

## Tasks

- T1 · S1,S2,DOC-05-ASM-01,DOC-05-ASM-02,DOC-05-ASM-03 · README.md (presentation), docs/capturas/00-carga.jpg, docs/capturas/01-login.jpg, docs/capturas/02-inicio.jpg, docs/capturas/03-sedes.jpg, docs/capturas/04-sede.jpg, docs/capturas/05-horarios.jpg, docs/capturas/06-confirmar.jpg, docs/capturas/07-listo.jpg, docs/capturas/08-reservas.jpg, docs/capturas/09-avisos.jpg, docs/capturas/10-perfil.jpg, docs/capturas/11-inicio-claro.jpg, docs/capturas/12-admin-reservas.png, docs/business/accessibility.md, specs/asvs.md, apps/api/README.md · tests: apps/api/tests/unit/test_readme_presenta.py "el README muestra capturas reales de cada paso del recorrido y del panel de administración, y cada imagen existe @DOC-05-S1 @assumption:DOC-05-ASM-02"; apps/api/tests/unit/test_readme_presenta.py "el README presenta qué es, qué hace, cómo está hecha con enlace a integraciones, cómo correrla y la documentación @DOC-05-S2"; apps/api/tests/unit/test_readme_presenta.py "lo que los tests de documentación leen del README sigue estando @assumption:DOC-05-ASM-01"; apps/api/tests/unit/test_readme_presenta.py "el README no publica contraseñas ni claves @assumption:DOC-05-ASM-03"
  new: el README no tenía capturas ni una presentación del proyecto

## Changes to existing behavior

- none: la card cambia el README y suma imágenes

## Gate

```
suite: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_readme_presenta.py tests/escenarios/test_documentacion_vigente.py tests/escenarios/test_documentacion_supuestos_vigente.py tests/escenarios/test_readme_app_configuracion.py tests/escenarios/test_requisitos_no_funcionales.py tests/escenarios/test_requisitos_no_funcionales_readme_app.py
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/tests/unit/test_readme_presenta.py
no-visual: la card cambia el README; ninguna pantalla de la app
```

## Log

- L1 · el readme me lo podes dejar lindo tambien, con fotos de la aplicacion real · vendiendo el proyecto
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base
- L3 · 2026-10-27 · declared · attacks · la card no toca la API
- L4 · 2026-10-27 · T1 · docs al día tras los merges: accessibility.md (fila pantalla_de_carga), specs/asvs.md (rutas a shared/correo.py), apps/api/README.md (BREVO_API_KEY, modo brevo); los tests de documentación pasan; test_requisitos_no_funcionales: error de setup por emulador de Firebase en :9099 (ambiental)
