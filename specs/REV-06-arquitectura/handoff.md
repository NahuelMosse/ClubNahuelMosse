# Handoff · REV-06 · parte API (T1, T5, T8, T9, API de T6 y T7)

## Hecho
- RED commiteado (4d2b2f6): `apps/api/tests/unit/test_capas.py` (9 tests) y `apps/api/tests/escenarios/test_repositorios_propios.py` (6 tests), con los títulos de la card en el docstring. Fallan por la razón correcta (13 rojos); pasan solos el de S11 y el de S12, que son guardas.
- Base `club_rev06_test` creada; `uv sync --frozen --python 3.13` hecho.
- Escrito sin commitear: `apps/api/app/dependencias.py` (reexporta conexion, motor, repositorios Sql, canal_push, ProveedorFirebase, enviar_correo) y `apps/api/app/dominio/zona.py` (NOMBRE_ZONA_CLUB, ZONA_CLUB); `aplicacion/errores.py` sigue en su lugar (el movimiento a `dominio/errores.py` se deshizo y queda por hacer).

## Bloqueo
Los Edit sobre `apps/api/app/interfaz/*.py` los frena el hook: «the module i18n is off ... the card brings a language, a translation or a locale». La salida que propone el hook es `node .claude/tools/kit.mjs on i18n` o `confirm-off i18n --reason ...`, que cambia la configuración del kit: lo decide el hilo principal o una persona, no el builder.

## Falta (en este orden)
1. Interfaz: cada módulo importa de `app.dependencias` (barrido, espacios, notificaciones, pruebas, recuperacion [`enviar_correo as enviar`], registro, reservas, sedes, sembrar_admin, sesion, horarios); `ZONA = ZoneInfo(...)` pasa a `from app.dominio.zona import ZONA_CLUB as ZONA` en horarios, registro, reservas, sembrar_admin, sesion.
2. Infraestructura sin importar aplicacion: mover a dominio (con reexport `X as X` en aplicacion para los tests viejos) las excepciones (`dominio/errores.py`), `Cuando` (dominio/reservas.py), `Pendiente`, `ResultadoDeEnvio`, `CanalNoConfigurado`, `CanalPush` (dominio/notificaciones.py) y `Mensaje` (dominio/recuperacion.py); `Cuando` en interfaz/reservas.py se importa de dominio. Agregar `zoneinfo` a PERMITIDOS_EN_DOMINIO de `tests/unit/test_arquitectura.py` (sin etiquetas, editable).
3. S6: `EspaciosSql.dar_de_baja_de_sede(sede_id, autor)` sin commit (SedesSql lo llama); `ReservasSql` método sin commit para cancelar futuras de un usuario (UsuariosSql.dar_de_baja lo llama); `NotificacionesSql` método sin commit para encolar `cancelacion_usuario` (ReservasSql.cancelar lo llama). Mismo `conn`, el caso de uso confirma.
4. S9: `vencidos` y `registrar` reciben `CAST(:anticipacion AS interval)` con `ANTICIPACION` de `dominio.notificaciones` (leído en la llamada, importado en infraestructura/notificaciones.py); sin `1 hour` en ese archivo (enlaces.py es otra regla, queda).
5. S10: la literal de la zona sólo en `dominio/zona.py`: en infraestructura/reservas.py (`_ZONA_CLUB`), sedes.py (`_afuera`) e interfaz/pruebas.py (líneas ~62, ~98) usar f-string con `NOMBRE_ZONA_CLUB`.
6. S7/S8: sacar los 4 `type: ignore` de `tests/unit/test_espacios.py` (31, 78) y `test_sedes.py` (21, 94) arreglando el tipo (sin etiquetas: editables); `pyproject.toml` `[tool.mypy] files = ["app", "tests"]`; correr `mypy --strict app tests` y arreglar lo que salga en tests.
7. T8: sin cambio de código (ASM-09); el test lo vigila. T9: la card ya tiene `## Changes to existing behavior`.
8. Correr con `-k` y en background: `node .claude/tools/affected.mjs <archivos>`; luego Log (una línea por tarea) y commit con rutas explícitas.

## Cómo correr
`cd apps/api; export TEST_DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8703/club_rev06_test FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:8702; .venv/Scripts/python.exe -m pytest -q -p no:cacheprovider tests/unit/test_capas.py tests/escenarios/test_repositorios_propios.py`
