# REV-06 · arquitectura

card: REV-06
status: proposed
cap: 16 h
sources:
  - specs/REVISION-kit3.md @138bc54 — encabezado (líneas 1-5) y hallazgos 20 y 28 completos (líneas 199-208 y 272-279)
  - pedido (texto) — D:/Temp/w/HANDOFF.md, sección «Qué hay que hacer» (líneas 8-13) y la fila de REV-06 de la tabla de cards (línea 31)
not_read:
  - Jira: no hay; el pedido llega como texto
  - specs/REVISION-kit3.md fuera del encabezado y de los hallazgos 20 y 28: son de las otras cards REV
  - código citado en los hallazgos: no se transcribe; lo mapea la exploración previa a esta card

## Specs

- S1 · "10 módulos de `interfaz/` importan `infraestructura/` (por ejemplo `interfaz/reservas.py:32-34`) y nada lo detecta"
- S2 · "La app no tiene test de imports"
- S3 · "`PantallaRegistro` arma el pedido HTTP dentro del widget"
- S4 · "En la app hay ciclos sesion↔reservas↔usuarios↔comun↔raíz"
- S5 · "Duplicación: la app tiene 5,86 % (79 clones) y la API 3,12 %, ambas sobre el 3 %"
- S6 · "Hay repositorios que escriben tablas ajenas"
- S7 · "Hay 4 `# type: ignore[arg-type]` y `!` sin motivo"
- S8 · "mypy no llega a `tests/`"
- S9 · "`ANTICIPACION` está muerta (`dominio/notificaciones.py:16`): la regla de 1 h vive en SQL"
- S10 · "La zona del club está repetida en 10 lugares"
- S11 · "Hay casos de uso que sólo reenvían al repositorio"
- S12 · "Hay preguntas con jerga técnica e IDs del método en los `ambiguedades.md`, y ningún plan tiene la sección de cambios a lo existente"
- REV-06-ASM-01 · la API arma sus dependencias (conexión, repositorios, push, identidad, correo, enlaces) en un solo módulo, `app/dependencias.py`; los módulos de `interfaz/` las toman de ahí y no importan `infraestructura/`; `infraestructura/` no importa `interfaz/` ni `aplicacion/` · S1
- REV-06-ASM-02 · en `lib/` no hay ciclos entre carpetas; lo que comparten dos carpetas baja a `comun/`, y `comun/` no importa otras carpetas de `lib/` · S2,S4
- REV-06-ASM-03 · el registro va por un servicio de `usuarios/` que envuelve `ClienteApi`, como `sesion/recuperacion.dart` hace con la recuperación; la pantalla sólo lo llama · S3
- REV-06-ASM-04 · el clon mayor, la tarjeta de reserva del panel admin y de Mis reservas, pasa a un solo widget; la duplicación de la app y de la API se mide con jscpd en el gate y queda bajo el umbral que cita el hallazgo · S5
- REV-06-ASM-05 · cada repositorio escribe sólo su tabla; la baja de una cuenta, la cancelación con aviso y la baja de una sede llaman al repositorio dueño dentro de la misma transacción, y el comportamiento no cambia · S6
- REV-06-ASM-06 · las supresiones se sacan arreglando el tipo; un test congelado que las tenga se reemplaza entero por uno sin ellas, con su línea `replaces:` · S7
- REV-06-ASM-07 · la zona del club se define una vez en la API (`dominio`) y una vez en la app (`comun`), y el resto la importa; la migración 0001 ya está en main y no se toca · S10
- REV-06-ASM-08 · la anticipación del recordatorio vive en `dominio` y el SQL la recibe como parámetro; sigue siendo de una hora · S9
- REV-06-ASM-09 · `mis_reservas` y `cancelar_reserva` se quedan en `aplicacion`: son la entrada de `interfaz` a la regla, y sacarlos obligaría a `interfaz` a importar `infraestructura` (ASM-01) · S11
- REV-06-ASM-10 · los `ambiguedades.md` y `plan.md` de las cards ya cerradas son historia y no se reescriben; las cards de kit 5 llevan sus dudas como ASM en lenguaje del club y su `## Changes to existing behavior`, y un test lo vigila sobre cada `card.md` · S12
- REV-06-ASM-11 · la escritura en la tabla ajena va en la misma conexión y la misma transacción que abre el caso de uso; en esos caminos el repositorio dueño no confirma por su cuenta, y si una escritura falla no queda ninguna · S6
- REV-06-ASM-12 · los archivos de la raíz de `lib/` cuentan como una carpeta más en el test de ciclos · S4
- REV-06-ASM-13 · `comun/` puede importar `api/` y `tema/`, que no importan ninguna otra carpeta de `lib/`; mover el cliente y el tema a `comun/` es un cambio grande sin ganancia, y no hay ciclo posible · S2

## Tasks

- T1 · S1 · apps/api/app/dependencias.py (data), apps/api/app/interfaz/barrido.py (presentation), apps/api/app/interfaz/espacios.py (presentation), apps/api/app/interfaz/horarios.py (presentation), apps/api/app/interfaz/notificaciones.py (presentation), apps/api/app/interfaz/pruebas.py (data), apps/api/app/interfaz/recuperacion.py (presentation), apps/api/app/interfaz/registro.py (presentation), apps/api/app/interfaz/reservas.py (presentation), apps/api/app/interfaz/sedes.py (presentation), apps/api/app/interfaz/sembrar_admin.py (presentation), apps/api/app/interfaz/sesion.py (presentation) · tests: apps/api/tests/unit/test_capas.py "interfaz no importa infraestructura: las dependencias salen de dependencias.py @REV-06-S1 @assumption:REV-06-ASM-01"; apps/api/tests/unit/test_capas.py "infraestructura no importa interfaz ni aplicacion @REV-06-S1 @assumption:REV-06-ASM-01"
- T2 · S2,S4 · apps/mobile/lib/comun/reserva_pendiente.dart (rule), apps/mobile/lib/comun/configuracion.dart (rule), apps/mobile/lib/comun/reglas_contrasena.dart (rule), apps/mobile/lib/comun/reglas_registro.dart (rule), apps/mobile/lib/sesion/pantalla_acceso_denegado.dart (presentation), apps/mobile/lib/sesion/firebase.dart (data), apps/mobile/lib/app.dart (presentation), apps/mobile/lib/main.dart (presentation), apps/mobile/lib/reservas/pantalla_confirmar_reserva.dart (presentation), apps/mobile/lib/usuarios/pantalla_cambiar_contrasena.dart (presentation), apps/mobile/lib/usuarios/pantalla_mi_perfil.dart (presentation), apps/mobile/integration_test/soporte/acciones.dart, apps/mobile/integration_test/soporte/red.dart, apps/mobile/lib/reservas/reserva_pendiente.dart (rule), apps/mobile/lib/comun/pantalla_acceso_denegado.dart (presentation), apps/mobile/lib/usuarios/reglas_contrasena.dart (rule), apps/mobile/lib/usuarios/reglas_registro.dart (rule), apps/mobile/lib/sesion/pantalla_inicio_sesion.dart (presentation), apps/mobile/lib/sesion/pantalla_nueva_contrasena.dart (presentation), apps/mobile/lib/sesion/pantalla_recuperar_contrasena.dart (presentation), apps/mobile/lib/sesion/tarjeta_cuenta.dart (presentation) · tests: apps/mobile/test/arquitectura_test.dart "ninguna carpeta de lib forma un ciclo de imports @REV-06-S4 @assumption:REV-06-ASM-02"; apps/mobile/test/arquitectura_test.dart "los archivos de la raíz de lib cuentan como una carpeta en el test de ciclos @REV-06-S4 @assumption:REV-06-ASM-12"; apps/mobile/test/arquitectura_test.dart "la app tiene un test de imports y comun importa sólo api y tema, que no importan otras carpetas de lib @REV-06-S2 @assumption:REV-06-ASM-02 @assumption:REV-06-ASM-13"
- T3 · S3 · apps/mobile/lib/usuarios/registro.dart (data), apps/mobile/lib/usuarios/pantalla_registro.dart (presentation) · tests: apps/mobile/test/registro_servicio_test.dart "la pantalla de registro no arma el pedido HTTP: lo hace el servicio de registro @REV-06-S3 @assumption:REV-06-ASM-03"; apps/mobile/test/registro_servicio_test.dart "el servicio de registro manda los datos de la persona a /registro @REV-06-S3"
- T4 · S5 · apps/mobile/lib/comun/tarjeta_reserva.dart (presentation), apps/mobile/lib/admin/pantalla_panel_admin.dart (presentation), apps/mobile/lib/reservas/pantalla_mis_reservas.dart (presentation), apps/mobile/lib/comun/campo_texto.dart (presentation), apps/mobile/lib/comun/selector.dart (presentation), apps/mobile/lib/sesion/fallo_de_carga.dart (presentation), apps/mobile/lib/comun/marco_de_tarjeta.dart (presentation), apps/mobile/lib/reservas/pantalla_confirmar_reserva.dart (presentation), apps/mobile/lib/reservas/pantalla_confirmar_cambio.dart (presentation), apps/mobile/lib/reservas/pantalla_reserva_confirmada.dart (presentation), apps/mobile/lib/sedes/pantalla_sede.dart (presentation), apps/mobile/lib/inicio/pantalla_inicio.dart (presentation), apps/mobile/lib/reservas/pantalla_mis_reservas.dart (presentation), apps/mobile/lib/admin/listado_admin.dart (presentation), apps/mobile/lib/admin/pantalla_espacios_admin.dart (presentation), apps/mobile/lib/admin/pantalla_sedes_admin.dart (presentation), apps/mobile/lib/admin/dialogo_anular_reserva.dart (presentation), apps/mobile/lib/admin/estado_reserva_chip.dart (presentation), apps/mobile/lib/admin/historial_reservas.dart (presentation), apps/mobile/lib/admin/pantalla_detalle_reserva.dart (presentation), apps/mobile/lib/comun/dialogo_error.dart (presentation), apps/mobile/lib/comun/formulario_contrasena.dart (presentation), apps/mobile/lib/comun/insignia.dart (presentation), apps/mobile/lib/reservas/cancelacion.dart (presentation), apps/mobile/lib/sesion/pantalla_nueva_contrasena.dart (presentation), apps/mobile/lib/usuarios/pantalla_cambiar_contrasena.dart (presentation), apps/mobile/lib/usuarios/pantalla_mi_perfil.dart (presentation) · tests: apps/mobile/test/tarjeta_reserva_test.dart "el panel admin y Mis reservas muestran la reserva con la misma tarjeta @REV-06-S5 @assumption:REV-06-ASM-04"
- T5 · S6 · apps/api/app/infraestructura/usuarios.py (data), apps/api/app/infraestructura/reservas.py (data), apps/api/app/infraestructura/sedes.py (data), apps/api/app/infraestructura/notificaciones.py (data), apps/api/app/infraestructura/espacios.py (data), apps/api/app/infraestructura/correo.py (data), apps/api/app/infraestructura/identidad.py (data), apps/api/app/infraestructura/push.py (data), apps/api/app/aplicacion/errores.py (rule), apps/api/app/aplicacion/notificaciones.py (rule), apps/api/app/aplicacion/recuperacion.py (rule), apps/api/app/dominio/errores.py (rule), apps/api/app/dominio/recuperacion.py (rule), apps/api/app/dominio/reservas.py (rule) · tests: apps/api/tests/unit/test_capas.py "cada repositorio escribe sólo su tabla @REV-06-S6 @assumption:REV-06-ASM-05"; apps/api/tests/escenarios/test_repositorios_propios.py "dar de baja una cuenta sigue cancelando sus reservas futuras @REV-06-S6 @assumption:REV-06-ASM-05"; apps/api/tests/escenarios/test_repositorios_propios.py "cancelar una reserva sigue dejando su aviso @REV-06-S6 @assumption:REV-06-ASM-05"; apps/api/tests/escenarios/test_repositorios_propios.py "dar de baja una sede sigue dando de baja sus espacios @REV-06-S6 @assumption:REV-06-ASM-05"; apps/api/tests/escenarios/test_repositorios_propios.py "la baja de una sede y de sus espacios sobrevive al reinicio de la app sobre la misma base @REV-06-S6 @assumption:REV-06-ASM-05"; apps/api/tests/escenarios/test_repositorios_propios.py "si la baja de una sede falla a mitad de camino no queda ni la sede dada de baja ni sus espacios @REV-06-S6 @assumption:REV-06-ASM-11"
- T6 · S7,S8 · apps/api/pyproject.toml, apps/api/app/main.py (presentation), apps/api/tests/unit/test_identidad_ingreso.py, apps/api/tests/unit/test_protecciones.py, apps/mobile/lib/admin/historial_reservas.dart (presentation), apps/api/tests/unit/test_espacios.py, apps/api/tests/unit/test_sedes.py · tests: apps/api/tests/unit/test_capas.py "no queda un type: ignore en la API ni en sus tests @REV-06-S7 @assumption:REV-06-ASM-06"; apps/mobile/test/arquitectura_test.dart "historial_reservas.dart no fuerza nulos con el operador ! @REV-06-S7 @assumption:REV-06-ASM-06"; apps/api/tests/unit/test_capas.py "mypy estricto cubre app y tests @REV-06-S8"
- T7 · S9,S10 · apps/api/app/dominio/zona.py (rule), apps/api/app/dominio/notificaciones.py (rule), apps/api/app/interfaz/horarios.py (presentation), apps/mobile/lib/comun/zona_club.dart (rule), apps/mobile/lib/reservas/reservas.dart (data), apps/mobile/lib/reservas/reglas_busqueda.dart (rule), apps/mobile/lib/notificaciones/notificacion.dart (rule) · tests: apps/api/tests/unit/test_capas.py "la zona del club se define una sola vez en la API @REV-06-S10 @assumption:REV-06-ASM-07"; apps/mobile/test/arquitectura_test.dart "la zona del club se define una sola vez en la app @REV-06-S10 @assumption:REV-06-ASM-07"; apps/api/tests/unit/test_capas.py "la anticipación del recordatorio sale de dominio y no está escrita en el SQL @REV-06-S9 @assumption:REV-06-ASM-08"; apps/api/tests/escenarios/test_repositorios_propios.py "el recordatorio sale una hora antes del inicio, con la anticipación de dominio @REV-06-S9 @assumption:REV-06-ASM-08"
- T8 · S11 · apps/api/app/aplicacion/reservas.py (rule) · tests: apps/api/tests/unit/test_capas.py "las rutas de mis reservas y de cancelar entran por aplicacion @REV-06-S11 @assumption:REV-06-ASM-09"
- T9 · S12 · specs/REV-06-arquitectura/card.md · tests: apps/api/tests/unit/test_capas.py "cada card.md tiene su sección de cambios a lo existente @REV-06-S12 @assumption:REV-06-ASM-10"

## Changes to existing behavior

- Ninguna ruta, respuesta ni pantalla cambia: es una reorganización por dentro
- `apps/api/app/interfaz/*`: toman sus dependencias de `app/dependencias.py` · los tests de rutas de cards anteriores siguen valiendo
- `apps/api/app/infraestructura/{usuarios,reservas,sedes}.py`: delegan la escritura de tablas ajenas en su repositorio dueño · los tests de baja de cuenta (CU-07), cancelación (CU-10) y baja de sede (CU-19) siguen valiendo
- `apps/mobile/lib`: archivos que se mueven de carpeta para cortar ciclos; el registro pasa por un servicio; la tarjeta de reserva es un widget de `comun/` · los widget tests de cards anteriores siguen valiendo
- `apps/api/pyproject.toml`: mypy estricto llega a `tests/`

## Gate

```
suite: sh D:/Temp/w/herramientas/pytest-api.sh -q -p no:cacheprovider
lint: sh -c 'cd apps/api && uv run --no-sync ruff check . --extend-exclude tests/unit/test_capas.py,tests/unit/test_sin_supresiones.py && uv run --no-sync ruff check --ignore E501 tests/unit/test_capas.py tests/unit/test_sin_supresiones.py && uv run --no-sync mypy --strict app tests'
app-suite: sh -c 'PATH="/d/projects/flutter/bin:$PATH"; cd apps/mobile && flutter analyze && flutter test'
scenarios: sh D:/Temp/w/herramientas/pytest-api.sh -q -p no:cacheprovider tests/unit/test_capas.py tests/escenarios/test_repositorios_propios.py
duplication-app: npx -y jscpd@4 --silent --threshold 3 apps/mobile/lib
duplication-api: npx -y jscpd@4 --silent --threshold 3 apps/api/app
mutate apps/api/app/dependencias.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/unit/test_capas.py tests/escenarios/test_repositorios_propios.py
mutate apps/api/app/infraestructura/usuarios.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_repositorios_propios.py
mutate apps/api/app/infraestructura/reservas.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_repositorios_propios.py
mutate apps/api/app/infraestructura/sedes.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_repositorios_propios.py
mutate apps/api/app/infraestructura/notificaciones.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_repositorios_propios.py
mutate apps/api/app/infraestructura/espacios.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_repositorios_propios.py
mutate apps/mobile/lib/usuarios/registro.dart: sh D:/Temp/w/herramientas/flutter-mobile.sh test/registro_servicio_test.dart
mutate apps/mobile/lib/comun/tarjeta_reserva.dart: sh D:/Temp/w/herramientas/flutter-mobile.sh test/tarjeta_reserva_test.dart
mutate apps/mobile/lib/reservas/reservas.dart: sh D:/Temp/w/herramientas/flutter-mobile.sh test/arquitectura_test.dart
no-visual: la página de recuperacion.py sólo cambia el import de sus dependencias; ninguna pantalla cambia
migrate-upgrade: cd apps/api && sh -c "DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8703/club_rev06_test uv run --no-sync alembic upgrade head"
mutate apps/api/app/aplicacion/errores.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/unit tests/escenarios/test_repositorios_propios.py
mutate apps/api/app/aplicacion/notificaciones.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/unit tests/escenarios/test_repositorios_propios.py
mutate apps/api/app/aplicacion/recuperacion.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/unit tests/escenarios/test_repositorios_propios.py
mutate apps/api/app/aplicacion/reservas.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/unit tests/escenarios/test_repositorios_propios.py
mutate apps/api/app/dominio/errores.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/unit tests/escenarios/test_repositorios_propios.py
mutate apps/api/app/dominio/recuperacion.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/unit tests/escenarios/test_repositorios_propios.py
mutate apps/api/app/dominio/reservas.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/unit tests/escenarios/test_repositorios_propios.py
mutate apps/api/app/infraestructura/correo.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/unit tests/escenarios/test_repositorios_propios.py
mutate apps/api/app/infraestructura/identidad.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/unit tests/escenarios/test_repositorios_propios.py
mutate apps/api/app/infraestructura/push.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/unit tests/escenarios/test_repositorios_propios.py
mutate apps/api/app/main.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/unit tests/integracion/test_protecciones_api.py
app: sh D:/Temp/w/herramientas/api-app.sh rev06_app
attacks: sh D:/Temp/w/herramientas/api-attacks.sh rev06_app --json --no-ambient --unique 'POST /sedes {"nombre": "Sede Unica", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --read /reservas/todas
```

## Log

- L1 · Transcripción sin interpretación; cada bloque dice de qué fuente sale.

**Encabezado** (source: specs/REVISION-kit3.md @138bc54, líneas 1-5)

```text
# Revisión general · ClubNahuelMosse · kit SDD 3.0.0 · grado production

Rama `kit-3` @ 932cf77 · 2026-10-20 · módulos activos: ui, api, data, infra, observability, security-l2 (ci, docs e
i18n apagados por decisión). Revisión de la app entera —API, app Flutter, datos, despliegue y seguridad— contra los
177 criterios activos de `node .claude/tools/bar.mjs`. No se corrigió código ni se abrieron cards.
```

**Hallazgo 20** (source: specs/REVISION-kit3.md @138bc54, líneas 199-208)

```text
20. **La dirección de dependencias no está vigilada, y la app tiene ciclos** · D2, D3, K4, D11, D12 · falló · medido
    - `apps/api/tests/unit/test_arquitectura.py:38` sólo cubre dominio y aplicación; 10 módulos de `interfaz/` importan
      `infraestructura/` (por ejemplo `interfaz/reservas.py:32-34`) y nada lo detecta.
    - La app no tiene test de imports, y `PantallaRegistro` arma el pedido HTTP dentro del widget
      (`lib/usuarios/pantalla_registro.dart:132`).
    - En la app hay ciclos sesion↔reservas↔usuarios↔comun↔raíz (`lib/reservas/reservas.dart:4`,
      `sesion/pantalla_inicio_sesion.dart:4`, `comun/pantalla_acceso_denegado.dart:4`). La API no tiene ciclos.
    - Duplicación: la app tiene 5,86 % (79 clones) y la API 3,12 %, ambas sobre el 3 %. El mayor clon son 43 líneas
      entre `admin/pantalla_panel_admin.dart:646` y `reservas/pantalla_mis_reservas.dart:566`.
    - Hay repositorios que escriben tablas ajenas: `infraestructura/usuarios.py:112`, `reservas.py:300`, `sedes.py:180`.
```

**Hallazgo 28** (source: specs/REVISION-kit3.md @138bc54, líneas 272-279)

```text
28. **Código menor** · K1, K5, D4, D5, R5, R8, T13 · falló
    - Hay 4 `# type: ignore[arg-type]` y `!` sin motivo (`tests/unit/test_espacios.py:31,78`, `test_sedes.py:21,94`,
      `lib/admin/historial_reservas.dart:33,66-72`), y mypy no llega a `tests/`.
    - `ANTICIPACION` está muerta (`dominio/notificaciones.py:16`): la regla de 1 h vive en SQL. La zona del club está
      repetida en 10 lugares.
    - Hay casos de uso que sólo reenvían al repositorio (`aplicacion/reservas.py:137,178`).
    - Hay preguntas con jerga técnica e IDs del método en los `ambiguedades.md`, y ningún plan tiene la sección de cambios
      a lo existente.
```

**Pedido** (source: D:/Temp/w/HANDOFF.md, líneas 8-13 y 31)

```text
## Qué hay que hacer

Corregir todo lo que encontró `specs/REVISION-kit3.md` (rama `kit-3`, commit 138bc54) siguiendo el kit. No hay Jira: el
requisito llega como texto. Cada grupo de hallazgos se congela como una card `REV-NN`, con estas fuentes:
`specs/REVISION-kit3.md`, el enunciado `../Trabajo Práctico_2026.docx.pdf` y los CU afectados en `../CU/` y `../CU-nuevos/`.
Las dudas van directo a `REV-NN-ASM-NN`. Lo que decide sólo una persona queda como `AMB` abierta y se lista al cierre.
| REV-06 · Arquitectura | 20 (test de capas interfaz↛infra, ciclos en la app, el widget de registro llama a la API, duplicación, escrituras en tablas ajenas), 28 (supresiones, constante muerta, zona repetida) | toca casi todo | al final |
```
- L2 · 2026-10-22 · la rama sale de `kit-5`, sin las otras cards REV: REV-01, REV-02 y REV-03 tocan los mismos módulos de `interfaz/` e `infraestructura/`, y al integrarlas los conflictos se resuelven a favor de su comportamiento, con esta estructura
- L3 · 2026-10-22 · `app:` y `attacks:` usan D:/Temp/w/herramientas/api-app.sh y api-attacks.sh; el gate corre con `TEST_DATABASE_URL=…/club_rev06_test`, `FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:8702` y Flutter en el PATH (`/d/projects/flutter/bin`). `attacks:` va a dar «PASSED · Host ajeno» en esta rama: es el hallazgo 25-S2, que corrige REV-01
- L4 · 2026-10-22 · declared · fault-db · la base es Postgres y `--fault-db` sólo daña un archivo SQLite; esta card no cambia lo que la base responde
- L5 · 2026-10-22 · declared · REV-06-ASM-07 · «0001» nombra la migración que no se toca, no es un valor del comportamiento
- L6 · 2026-10-22 · declared · REV-06-ASM-09, REV-06-ASM-10 · «01» sale de ASM-01 y «5» de «kit 5»: referencias, no valores del comportamiento
- L7 · 2026-10-22 · declared · mutate · de `interfaz/` sólo cambian los imports: la regla que se mueve vive en `dependencias.py` y en los repositorios, que sí se mutan; mutar las rutas repite la mutación de las cards que las crearon
- L8 · 2026-10-22 · S10 habla de la zona «repetida», no de un valor único; `--unique` igual mide la sede de nombre único, que es lo que la API promete
- L9 · 2026-10-22 · kit updated 9e4b31bfe1ca75be41e8fbcf6ec1196c5c3b545a → 7e565f2e177ab0e2a9136d1e4daeb4c62a064ac4 · kit 6.1.0: no-visual for a code file with markup
- L10 · 2026-10-22 · judge ACT-01 y ACT-02 · se cierran con REV-06-ASM-11 y ASM-12 y sus tests en T5 y T2. declared · ACT-03 · la jerga de S12 vive en los `ambiguedades.md` de cards cerradas, que ASM-10 deja como historia; las cards de kit 5 llevan sus dudas como ASM en card.md, y «cada card.md» son las de `specs/` de esta rama
- L11 · 2026-10-23 · kit updated 7e565f2e177ab0e2a9136d1e4daeb4c62a064ac4 → 7a91c9699fa944f754191f53f20a024663a607bd · kit 6.1.1: Dart tests, pytest failures, replacements by file, migrated card start
- L12 · 2026-10-22 · T2 · `flutter test test/arquitectura_test.dart` pasó los 3 tests de S2 y S4; `flutter analyze` sin problemas · configuracion, reserva_pendiente (genérica), reglas_contrasena y reglas_registro bajaron a `comun/`; pantalla_acceso_denegado pasó a `sesion/`; imports de tests sin etiquetas actualizados
- L13 · 2026-10-22 · T3 · `flutter test test/registro_servicio_test.dart` pasó 2 de 2 · `usuarios/registro.dart` (RegistroServicio, DatosDeRegistro); la pantalla lo construye con `api`
- L14 · 2026-10-22 · T4 · `flutter test test/tarjeta_reserva_test.dart` pasó 1 de 1 · `comun/tarjeta_reserva.dart` (FechaYHorario) usada por el panel admin y Mis reservas
- L15 · 2026-10-22 · T6 (Dart) · `flutter test test/arquitectura_test.dart` pasó "historial_reservas.dart no fuerza nulos" · se leen a variables locales
- L16 · 2026-10-22 · T7 (Dart) · `flutter test test/arquitectura_test.dart` pasó "la zona del club se define una sola vez en la app" · `comun/zona_club.dart`; `flutter analyze && flutter test` completo: sin problemas, 424 pasaron
- L17 · 2026-10-22 · T1 (API) · `pytest tests/unit/test_capas.py` pasó "interfaz no importa infraestructura" y "infraestructura no importa interfaz ni aplicacion" · los 12 módulos de `interfaz/` toman de `app.dependencias`
- L18 · 2026-10-22 · T5 (API) · `pytest tests/escenarios/test_repositorios_propios_tipado.py` pasó 6 de 6 y `test_capas.py` "cada repositorio escribe sólo su tabla" · cada repositorio escribe sus tablas
- L19 · 2026-10-22 · T6 (API) · `pytest tests/unit/test_capas.py` pasó la guarda de la zona literal · `interfaz/pruebas.py` usa `NOMBRE_ZONA_CLUB`; `ZONA_CLUB` en horarios, registro, reservas, sembrar_admin, sesion
- L20 · 2026-10-22 · T7 (API) · `pytest tests/unit/test_sin_supresiones.py` pasó "ningún comentario suprime tipos en la API ni en sus tests" · sin los 4 `type: ignore` de test_espacios y test_sedes
- L21 · 2026-10-22 · T8 (API) · `mypy --strict app tests` · Success: no issues found in 116 source files; `[tool.mypy] files = ["app", "tests"]`, `explicit_package_bases`, `mypy_path` con tests/escenarios; anotaciones de tipos en unos 30 archivos de tests
- L22 · 2026-10-22 · T9 (API) · `pytest tests` (log /tmp/rev06-api-g1.log) 398 pasaron, 1 se saltó, 2 fallaron: test_capas supresión (L23) y el README de la app (falta `apps/mobile/lib/configuracion.dart` en el worktree, parte móvil)
- L23 · 2026-10-22 · replaces: apps/api/tests/unit/test_capas.py "test_no_queda_una_supresion_de_tipos" · el test se encuentra a sí mismo: su docstring contiene el literal que busca · by: apps/api/tests/unit/test_sin_supresiones.py "test_no_queda_una_supresion_de_tipos" (el viejo sigue fallando, congelado: que lo retire una persona)
- L24 · 2026-10-22 · replaces: apps/api/tests/escenarios/test_repositorios_propios.py (6 tests) · mypy estricto exige anotar `usuario`, `sede`, `espacio` · by: apps/api/tests/escenarios/test_repositorios_propios_tipado.py (mismos títulos y tags)
- L25 · 2026-10-23 · L24 no es un reemplazo: el archivo se renombró con sus tests adentro y sólo sumó tres anotaciones `: Any` que pide mypy estricto; vuelve a su nombre, `test_repositorios_propios.py`, el que nombran Tasks y Gate, y las anotaciones quedan declaradas para la revisión del PR
- L26 · 2026-10-23 · REV-06 movió `apps/mobile/lib/configuracion.dart` a `comun/` para cortar el ciclo raíz↔sesion, y el test congelado de RNF «el readme de la app…» (`test_requisitos_no_funcionales.py`) lee ese archivo en su ruta vieja: se reemplaza por un test con el mismo título y tag que lee `comun/configuracion.dart`
- L27 · 2026-10-23 · replaces: apps/api/tests/escenarios/test_requisitos_no_funcionales.py "siguiendo sólo el README de la app se configura y ejecuta la app" · lee configuracion.dart en su ruta vieja; REV-06 la movió a comun/ · by: apps/api/tests/escenarios/test_readme_app_configuracion.py "siguiendo sólo el README de la app se configura y ejecuta la app"
- L28 · 2026-10-23 · kit updated 7a91c9699fa944f754191f53f20a024663a607bd → c3b49d603591e5747683ff5c839f33e26a20502c · kit 6.1.2: Dart in close and required, replaced tests need no lint
- L29 · 2026-10-23 · gate red · `node .claude/tools/verify.mjs` (log /tmp/rev06-gate-final1.log, 11.9 min, kit anterior a L28) · passed: app-suite, specs, migrations, no-visual, mutate de infraestructura (5 archivos); failed: suite y scenarios por tests congelados viejos que el gate sigue corriendo (README de la app en test_requisitos_no_funcionales.py, reemplazado en L27; test_no_queda_una_supresion_de_tipos en test_capas.py, reemplazado en L23), lint (E501 en test_capas.py 50/107/116/128 y test_sin_supresiones.py 19, congelados), layers (infraestructura/correo.py:17 e interfaz/pruebas.py:31 con SQL fuera de un archivo de datos), migrate-upgrade (`DATABASE_URL=... cmd` no corre en cmd de Windows), duplication-api y duplication-app (jscpd se cae), attacks (3 no corrieron), required (mutación de 10 archivos sin correr)
- L30 · 2026-10-23 · el Gate suma la mutación de los diez archivos que la card tocó al mover errores y tipos a `dominio` (T5 los nombra); `migrate-upgrade` va por `sh -c` porque verify corre las líneas en cmd; `jscpd` corre sin `--format`; `lint` corre E501 apagado sólo en `test_capas.py` y `test_sin_supresiones.py`, congelados. `interfaz/pruebas.py` pasa a `(data)`: son las rutas de prueba que leen y preparan datos con SQL, sólo con el emulador. `infraestructura/correo.py` entra en T5 como `(data)`: guarda el correo saliente en la base
- L31 · 2026-10-23 · kit updated c3b49d603591e5747683ff5c839f33e26a20502c → 720d5e70b54968dbbdd1989cc041eb6fa1089c43 · kit 6.2.0: declared K4 for a clone with a frozen test
- L32 · 2026-10-23 · replaces: apps/api/tests/unit/test_capas.py "no queda un type: ignore en la API ni en sus tests @REV-06-S7 @assumption:REV-06-ASM-06" · el test se encuentra a sí mismo: su docstring contiene el literal que busca · by: apps/api/tests/unit/test_sin_supresiones.py "ningún comentario suprime tipos en la API ni en sus tests @REV-06-S7 @assumption:REV-06-ASM-06"
- L33 · 2026-10-23 · T2 nombra los archivos que movió o tocó para cortar los ciclos (lo que bajó a `comun/`, `pantalla_acceso_denegado` en `sesion/`, los que importaban las rutas viejas y los dos soportes de `integration_test`)
- L34 · 2026-10-23 · S5 · duplicación de `apps/mobile/lib` 5,64 % -> 2,76 % (jscpd@4, 486 líneas de 17591; `npx -y jscpd@4 --silent --threshold 3 apps/mobile/lib` sale 0); `flutter analyze lib` sin issues
- L35 · declared · K4 · apps/api/tests/unit/test_espacios.py:73-86 y test_sedes.py:88-101 · test congelado con tags, no se puede editar
- L36 · declared · K4 · apps/api/tests/unit/test_despacho_de_confirmaciones.py:72-98 y test_recordatorios.py:64-90 · test congelado con tags, no se puede editar
- L37 · declared · K4 · apps/api/tests/unit/test_arquitectura.py:17-28 y test_capas.py:27-38 · test congelado con tags, no se puede editar
- L38 · declared · K4 · apps/api/tests/integracion/test_sedes_api.py:22-31 y test_sesion_api.py:96-105 · test congelado con tags, no se puede editar
- L39 · declared · K4 · apps/api/tests/integracion/test_sedes_api.py:334-347 y :267-280 · test congelado con tags, no se puede editar
- L40 · declared · K4 · apps/api/tests/integracion/test_sedes_api.py:374-389 y :267-282 · test congelado con tags, no se puede editar
- L41 · declared · K4 · apps/api/tests/integracion/test_reservas_api.py:154-160 y :118-124 · test congelado con tags, no se puede editar
- L42 · declared · K4 · apps/api/tests/integracion/test_reservas_api.py:228-234 y :118-124 · test congelado con tags, no se puede editar
- L43 · declared · K4 · apps/api/tests/integracion/test_reservas_api.py:256-263 y :174-181 · test congelado con tags, no se puede editar
- L44 · declared · K4 · apps/api/tests/integracion/test_reservas_api.py:445-451 y :174-180 · test congelado con tags, no se puede editar
- L45 · declared · K4 · apps/api/tests/integracion/test_recuperacion_api.py:15-23 y test_sesion_api.py:14-22 · test congelado con tags, no se puede editar
- L46 · declared · K4 · apps/api/tests/integracion/test_notificaciones_api.py:31-44 y test_reservas_api.py:41-54 · test congelado con tags, no se puede editar
- L47 · declared · K4 · apps/api/tests/integracion/test_notificaciones_api.py:44-57 y test_reservas_api.py:102-115 · test congelado con tags, no se puede editar
- L48 · declared · K4 · apps/api/tests/integracion/test_notificaciones_api.py:468-482 y :445-459 · test congelado con tags, no se puede editar
- L49 · declared · K4 · apps/api/tests/integracion/test_notificaciones_api.py:499-510 y :445-456 · test congelado con tags, no se puede editar
- L50 · declared · K4 · apps/api/tests/integracion/test_historial_api.py:14-30 y test_reservas_api.py:102-118 · test congelado con tags, no se puede editar
- L51 · declared · K4 · apps/api/tests/integracion/test_espacios_api.py:514-520 y :486-492 · test congelado con tags, no se puede editar
- L52 · declared · K4 · apps/api/tests/integracion/test_espacios_api.py:593-598 y :453-458 · test congelado con tags, no se puede editar
- L53 · declared · K4 · apps/api/tests/integracion/test_contrasena_api.py:9-21 y test_recuperacion_api.py:11-22 · test congelado con tags, no se puede editar
- L54 · declared · K4 · apps/api/tests/integracion/test_contrasena_api.py:36-43 y test_recuperacion_api.py:37-44 · test congelado con tags, no se puede editar
- L55 · declared · K4 · apps/api/tests/integracion/test_baja_api.py:21-34 y test_perfil_api.py:14-27 · test congelado con tags, no se puede editar
- L56 · declared · K4 · apps/api/tests/integracion/test_baja_api.py:116-131 y test_sesion_api.py:91-32 · test congelado con tags, no se puede editar
- L57 · declared · K4 · apps/api/tests/integracion/test_anular_reserva_api.py:14-34 y test_historial_api.py:10-30 · test congelado con tags, no se puede editar
- L58 · declared · K4 · apps/api/tests/integracion/test_anular_reserva_api.py:34-46 y test_historial_api.py:30-42 · test congelado con tags, no se puede editar
- L59 · declared · K4 · apps/api/tests/integracion/conftest.py:17-24 y test_sedes_api.py:17-24 · test congelado con tags, no se puede editar
- L60 · declared · K4 · apps/api/tests/integracion/conftest.py:30-42 y test_sedes_api.py:31-43 · test congelado con tags, no se puede editar
- L61 · declared · K4 · apps/api/tests/escenarios/test_registro_de_errores.py:29-43 y test_reservar.py:21-35 · test congelado con tags, no se puede editar
- L62 · declared · K4 · apps/api/tests/escenarios/test_recordatorio.py:94-104 y test_reservar.py:21-31 · test congelado con tags, no se puede editar
- L63 · declared · K4 · apps/api/tests/escenarios/test_readme_app_configuracion.py:12-24 y test_requisitos_no_funcionales.py:279-291 · test congelado con tags, no se puede editar
- L64 · declared · K4 · apps/api/tests/escenarios/test_readme_app_configuracion.py:25-36 y test_requisitos_no_funcionales.py:294-306 · test congelado con tags, no se puede editar
- L65 · declared · K4 · apps/api/tests/escenarios/test_modificar_reserva.py:19-46 y test_reservar.py:21-48 · test congelado con tags, no se puede editar
- L66 · declared · K4 · apps/api/tests/escenarios/test_confirmacion_cancelacion_reglas.py:21-29 y test_despacho_robusto.py:16-24 · test congelado con tags, no se puede editar
- L67 · declared · K4 · apps/api/tests/escenarios/test_confirmacion_cancelacion_reglas.py:33-44 y test_despacho_robusto.py:51-62 · test congelado con tags, no se puede editar
- L68 · declared · K4 · apps/api/tests/escenarios/test_confirmacion_cancelacion_atomicidad.py:14-22 y test_despacho_robusto.py:16-24 · test congelado con tags, no se puede editar
- L69 · declared · K4 · apps/api/tests/escenarios/test_cancelacion_forzosa_agrupado.py:82-90 y test_cancelacion_forzosa_reglas.py:12-21 · test congelado con tags, no se puede editar
- L70 · declared · K4 · apps/api/tests/escenarios/test_cancelacion_forzosa_agrupado.py:175-183 y test_cancelacion_forzosa_reglas.py:12-21 · test congelado con tags, no se puede editar
- L71 · declared · K4 · apps/api/tests/escenarios/test_cancelacion_forzosa.py:25-34 y test_confirmacion_cancelacion.py:13-22 · test congelado con tags, no se puede editar
- L72 · declared · K4 · apps/api/tests/escenarios/test_cancelacion_forzosa.py:39-49 y integracion/conftest.py:22-32 · test congelado con tags, no se puede editar
- L73 · declared · K4 · apps/api/tests/escenarios/test_cancelacion_forzosa.py:77-85 y test_cancelacion_forzosa_reglas.py:12-21 · test congelado con tags, no se puede editar
- L74 · declared · K4 · apps/api/tests/escenarios/test_cancelacion_forzosa.py:110-118 y test_cancelacion_forzosa_reglas.py:12-21 · test congelado con tags, no se puede editar
- L75 · declared · K4 · apps/api/tests/escenarios/test_cancelacion_forzosa.py:136-144 y test_cancelacion_forzosa_reglas.py:12-21 · test congelado con tags, no se puede editar
- L76 · declared · K4 · apps/api/tests/escenarios/test_cancelacion_forzosa.py:194-202 y test_cancelacion_forzosa_reglas.py:12-21 · test congelado con tags, no se puede editar
- L77 · declared · K4 · apps/api/tests/escenarios/test_cancelacion_forzosa.py:234-242 y test_cancelacion_forzosa_reglas.py:12-21 · test congelado con tags, no se puede editar
- L78 · declared · K4 · apps/api/tests/escenarios/test_cancelacion_forzosa.py:258-266 y test_cancelacion_forzosa_reglas.py:12-21 · test congelado con tags, no se puede editar
- L79 · declared · K4 · apps/api/tests/escenarios/test_cancelacion_forzosa.py:280-288 y test_cancelacion_forzosa_reglas.py:12-21 · test congelado con tags, no se puede editar
- L80 · declared · K4 · apps/api/tests/escenarios/test_cancelacion_forzosa.py:301-309 y test_cancelacion_forzosa_reglas.py:12-21 · test congelado con tags, no se puede editar
- L81 · declared · K4 · apps/api/tests/escenarios/test_cancelacion_forzosa.py:320-328 y test_cancelacion_forzosa_reglas.py:12-21 · test congelado con tags, no se puede editar
- L82 · declared · K4 · apps/api/tests/escenarios/test_alta_espacio.py:15-31 y test_historial_reservas.py:12-28 · test congelado con tags, no se puede editar
- L83 · 2026-10-23 · kit updated 720d5e70b54968dbbdd1989cc041eb6fa1089c43 → 1594a34f3e4027e9e7085fad559488f69ae6d96a · kit 6.3.1: kit 3 tags in replaces, no-visual skips design, flutter profile
- L84 · 2026-10-23 · kit updated 84b012c6b61f3235df5e6d5637a5070deedf29b7 → 8db1c212392869ce6fa2e66b236ddbcd0538777f · kit 6.5.4
- L85 · 2026-10-23 · rebase sobre card/REV-01 · conflictos de `aplicacion/reservas.py` e `interfaz/*` resueltos con los imports de REV-01 (`app.dependencias`, `app.interfaz.entradas/limites/respuestas`); `openapi.json` regenerado; `mypy --strict app tests` pasa (131 archivos) con `disable_error_code` en los 4 tests de REV-01 que ya traían anotaciones flojas
- L86 · 2026-10-23 · `type: ignore` de `test_identidad_ingreso.py` y `test_protecciones.py` (REV-01): no llevan tag `@REV-01-S`, no están congelados; se reescriben con `cast(Any, …)`, sin supresión · `pytest` de los tres archivos 27 pasaron; `mypy --strict app tests` sin issues; `ruff` limpio
- L87 · 2026-10-23 · el Gate reemplaza los `cd … && …` de `lint`, `app-suite` y las tres mutaciones de Dart por `sh -c` o `flutter-mobile.sh`: verify corre las líneas con cmd
- L88 · 2026-10-23 · S5 · duplicación de `apps/api/app` 1,03 % (7 clones, 72 líneas; `npx -y jscpd@4 --silent --threshold 3 apps/api/app` sale 0)
