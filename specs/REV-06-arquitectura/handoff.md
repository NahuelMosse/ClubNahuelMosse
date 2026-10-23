# Handoff · REV-06 · parte API (T1, T5, T8, T9, API de T6 y T7)

## Hecho (commiteado)
- RED (4d2b2f6): `apps/api/tests/unit/test_capas.py` (9) y `tests/escenarios/test_repositorios_propios.py` (6).
- `app/dependencias.py` y `app/dominio/zona.py` (NOMBRE_ZONA_CLUB, ZONA_CLUB).
- Infraestructura sin importar aplicacion: errores en `dominio/errores.py` (aplicacion/errores.py los reexporta con `X as X`); `Cuando` en dominio/reservas.py; `Pendiente`, `ResultadoDeEnvio`, `CanalNoConfigurado`, `CanalPush` en dominio/notificaciones.py; `Mensaje` en dominio/recuperacion.py (todos reexportados desde aplicacion). `zoneinfo` agregado a PERMITIDOS_EN_DOMINIO.
- S6: `EspaciosSql.dar_de_baja_de_sede`, `ReservasSql.cancelar_futuras_de`, `NotificacionesSql.encolar_cancelacion_usuario` (sin commit); SedesSql, UsuariosSql y ReservasSql los llaman.
- S9: `ANTICIPACION` en infraestructura/notificaciones.py (vencidos y registrar), sin `1 hour`.
- S10 parcial: infraestructura/reservas.py y sedes.py usan `NOMBRE_ZONA_CLUB`.
- Verde: tests/escenarios/test_repositorios_propios.py (6) y tests/unit/test_arquitectura.py (2).

## Falta (en este orden)
1. Interfaz (`apps/api/app/interfaz/*.py`): cada módulo importa de `app.dependencias` en vez de `app.infraestructura.*` (barrido, espacios, notificaciones, pruebas, recuperacion [`enviar_correo as enviar`], registro, reservas, sedes, sembrar_admin, sesion, horarios); `ZONA = ZoneInfo(...)` pasa a `from app.dominio.zona import ZONA_CLUB as ZONA` en horarios, registro, reservas, sembrar_admin, sesion (sacar el import de zoneinfo). `interfaz/reservas.py` importa `Cuando` de `app.dominio.reservas` (ya está reexportado por aplicacion, no urgente). `interfaz/barrido.py` y reservas.py importan `CanalPush` de aplicacion (ok).
2. S10: `interfaz/pruebas.py` líneas ~62 y ~98: la literal de la zona en f-string con `NOMBRE_ZONA_CLUB` (de app.dominio.zona).
3. S7/S8: sacar los 4 `type: ignore` de `tests/unit/test_espacios.py` (31, 78) y `test_sedes.py` (21, 94) arreglando el tipo (sin etiquetas: editables); `pyproject.toml` `[tool.mypy] files = ["app", "tests"]`; correr `mypy --strict app tests` y arreglar lo que salga en tests.
4. S11/S12 y T8/T9: ya pasan (guardas); sin cambio de código.
5. Correr `tests/unit/test_capas.py` (los 9 deben pasar), luego `node .claude/tools/affected.mjs <archivos tocados>` y las suites afectadas en background con -k/log único; luego Log (una línea por tarea T1, T5, T6, T7, T8, T9) y commit con rutas explícitas.

## Cómo correr
`cd apps/api; export TEST_DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8703/club_rev06_test FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:8702; .venv/Scripts/python.exe -m pytest -q -p no:cacheprovider tests/unit/test_capas.py tests/escenarios/test_repositorios_propios.py`
