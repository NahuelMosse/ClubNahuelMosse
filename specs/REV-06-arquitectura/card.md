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

## Tasks

- T1 · S1 · apps/api/app/dependencias.py (data), apps/api/app/interfaz/barrido.py (presentation), apps/api/app/interfaz/espacios.py (presentation), apps/api/app/interfaz/horarios.py (presentation), apps/api/app/interfaz/notificaciones.py (presentation), apps/api/app/interfaz/pruebas.py (presentation), apps/api/app/interfaz/recuperacion.py (presentation), apps/api/app/interfaz/registro.py (presentation), apps/api/app/interfaz/reservas.py (presentation), apps/api/app/interfaz/sedes.py (presentation), apps/api/app/interfaz/sembrar_admin.py (presentation), apps/api/app/interfaz/sesion.py (presentation) · tests: apps/api/tests/unit/test_capas.py "interfaz no importa infraestructura: las dependencias salen de dependencias.py @REV-06-S1 @assumption:REV-06-ASM-01"; apps/api/tests/unit/test_capas.py "infraestructura no importa interfaz ni aplicacion @REV-06-S1 @assumption:REV-06-ASM-01"
- T2 · S2,S4 · apps/mobile/lib/reservas/reserva_pendiente.dart (rule), apps/mobile/lib/comun/pantalla_acceso_denegado.dart (presentation), apps/mobile/lib/usuarios/reglas_contrasena.dart (rule), apps/mobile/lib/usuarios/reglas_registro.dart (rule), apps/mobile/lib/sesion/pantalla_inicio_sesion.dart (presentation), apps/mobile/lib/sesion/pantalla_nueva_contrasena.dart (presentation), apps/mobile/lib/sesion/pantalla_recuperar_contrasena.dart (presentation), apps/mobile/lib/sesion/tarjeta_cuenta.dart (presentation) · tests: apps/mobile/test/arquitectura_test.dart "ninguna carpeta de lib forma un ciclo de imports @REV-06-S4 @assumption:REV-06-ASM-02"; apps/mobile/test/arquitectura_test.dart "la app tiene un test de imports y comun no importa otras carpetas de lib @REV-06-S2 @assumption:REV-06-ASM-02"
- T3 · S3 · apps/mobile/lib/usuarios/registro.dart (data), apps/mobile/lib/usuarios/pantalla_registro.dart (presentation) · tests: apps/mobile/test/registro_servicio_test.dart "la pantalla de registro no arma el pedido HTTP: lo hace el servicio de registro @REV-06-S3 @assumption:REV-06-ASM-03"; apps/mobile/test/registro_servicio_test.dart "el servicio de registro manda los datos de la persona a /registro @REV-06-S3"
- T4 · S5 · apps/mobile/lib/comun/tarjeta_reserva.dart (presentation), apps/mobile/lib/admin/pantalla_panel_admin.dart (presentation), apps/mobile/lib/reservas/pantalla_mis_reservas.dart (presentation) · tests: apps/mobile/test/tarjeta_reserva_test.dart "el panel admin y Mis reservas muestran la reserva con la misma tarjeta @REV-06-S5 @assumption:REV-06-ASM-04"
- T5 · S6 · apps/api/app/infraestructura/usuarios.py (data), apps/api/app/infraestructura/reservas.py (data), apps/api/app/infraestructura/sedes.py (data), apps/api/app/infraestructura/notificaciones.py (data), apps/api/app/infraestructura/espacios.py (data) · tests: apps/api/tests/unit/test_capas.py "cada repositorio escribe sólo su tabla @REV-06-S6 @assumption:REV-06-ASM-05"; apps/api/tests/escenarios/test_repositorios_propios.py "dar de baja una cuenta sigue cancelando sus reservas futuras @REV-06-S6 @assumption:REV-06-ASM-05"; apps/api/tests/escenarios/test_repositorios_propios.py "cancelar una reserva sigue dejando su aviso @REV-06-S6 @assumption:REV-06-ASM-05"; apps/api/tests/escenarios/test_repositorios_propios.py "dar de baja una sede sigue dando de baja sus espacios @REV-06-S6 @assumption:REV-06-ASM-05"; apps/api/tests/escenarios/test_repositorios_propios.py "la baja de una sede y de sus espacios sobrevive al reinicio de la app sobre la misma base @REV-06-S6 @assumption:REV-06-ASM-05"
- T6 · S7,S8 · apps/api/pyproject.toml, apps/mobile/lib/admin/historial_reservas.dart (presentation), apps/api/tests/unit/test_espacios.py, apps/api/tests/unit/test_sedes.py · tests: apps/api/tests/unit/test_capas.py "no queda un type: ignore en la API ni en sus tests @REV-06-S7 @assumption:REV-06-ASM-06"; apps/mobile/test/arquitectura_test.dart "historial_reservas.dart no fuerza nulos con el operador ! @REV-06-S7 @assumption:REV-06-ASM-06"; apps/api/tests/unit/test_capas.py "mypy estricto cubre app y tests @REV-06-S8"
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
suite: cd apps/api && uv run --no-sync pytest -q -p no:cacheprovider
lint: cd apps/api && uv run --no-sync ruff check . && uv run --no-sync mypy --strict app tests
app-suite: cd apps/mobile && flutter analyze && flutter test
scenarios: cd apps/api && uv run --no-sync pytest -q -p no:cacheprovider tests/unit/test_capas.py tests/escenarios/test_repositorios_propios.py
duplication-app: npx -y jscpd@4 --silent --threshold 3 --format dart apps/mobile/lib
duplication-api: npx -y jscpd@4 --silent --threshold 3 --format python apps/api/app
mutate apps/api/app/dependencias.py: cd apps/api && uv run --no-sync pytest -q -x tests/unit/test_capas.py tests/escenarios/test_repositorios_propios.py
mutate apps/api/app/infraestructura/usuarios.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_repositorios_propios.py
mutate apps/api/app/infraestructura/reservas.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_repositorios_propios.py
mutate apps/api/app/infraestructura/sedes.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_repositorios_propios.py
mutate apps/api/app/infraestructura/notificaciones.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_repositorios_propios.py
mutate apps/api/app/infraestructura/espacios.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_repositorios_propios.py
mutate apps/mobile/lib/usuarios/registro.dart: cd apps/mobile && flutter test test/registro_servicio_test.dart
mutate apps/mobile/lib/comun/tarjeta_reserva.dart: cd apps/mobile && flutter test test/tarjeta_reserva_test.dart
mutate apps/mobile/lib/reservas/reservas.dart: cd apps/mobile && flutter test test/arquitectura_test.dart
no-visual: la página de recuperacion.py sólo cambia el import de sus dependencias; ninguna pantalla cambia
migrate-upgrade: cd apps/api && DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8703/club_rev06_test uv run --no-sync alembic upgrade head
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
