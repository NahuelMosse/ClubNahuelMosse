# Handoff ARQ-04 (worktree D:/Temp/w/arq04, rama card/ARQ-04)

## Hecho
T1 (RED), T2+T3 (shared, sesion, espacios, sedes, horarios) verificados: `ruff check app` limpio, `mypy --strict app` OK (69 archivos), integración verde. Log L7-L9 escrito. Migraciones idénticas a card/SIM-01 (comprobar `git diff --stat card/SIM-01 -- apps/api/migraciones/versions` vacío antes de cada commit; ruff sólo sobre app/ y tests/).

## Entorno
`export UV_PROJECT_ENVIRONMENT="D:/desktop folders/estudio/Universidad de moron/Electiva general/app-tp/apps/api/.venv"` en CADA llamada (no persiste; sin él uv crea apps/api/.venv y falla psycopg: borrarlo). Tests: `sh D:/Temp/w/herramientas/arq01-pytest.sh tests/unit tests/integracion -v -rf -p no:cacheprovider` (el script hace cd apps/api, rutas relativas a apps/api). Tarda ~12 min con la máquina cargada: background + `node .claude/tools/wait.mjs <log> --until '^exit ' --max 570`. No correr tests/escenarios enteros sin necesidad (muy lentos).

## Falta T4 (notificaciones + reservas, ASM-04)
- `git mv` (app/): aplicacion/almacen_de_avisos->modules/notificaciones/almacen.py, aplicacion/notificaciones->casos_de_uso, dominio/notificaciones->reglas, infraestructura/notificaciones->repositorio, infraestructura/push->push, interfaz/notificaciones->rutas, interfaz/barrido->barrido; reservas: aplicacion/almacen_de_reservas->almacen, aplicacion/reservas->casos_de_uso, dominio/reservas->reglas, infraestructura/reservas->repositorio, interfaz/reservas->rutas.
- Script listo: `python D:/Temp/w/herramientas/arq04_mover_t4.py D:/Temp/w/arq04/apps/api` (idempotente, reescribe imports y strings en app/, tests/, migraciones/env.py; colapsa imports entre módulos al `__init__`; imprime qué nombres debe exportar cada `__init__`). Ejecutarlo DESPUÉS del git mv. Escribir `__init__.py` de ambos (patrón: modules/sedes/__init__.py) y mover a cada repositorio.py los providers `repositorio_notificaciones/reservas` y `canal_push` (hoy en app/dependencias.py, que debe perder esas entradas).
- ASM-04: en notificaciones/reglas.py un dataclass `DatosDeReserva(id, deporte, tipo, sede, inicio)`; `mensaje_cancelacion(r: DatosDeReserva)` y quitar `from app.dominio.reservas import Reserva` de reglas. reservas/repositorio.py (cancelar, ~línea 243) arma `DatosDeReserva(...)` desde su `Reserva`. Imports: reservas -> notificaciones (por `__init__`), nunca al revés. `interfaz/notificaciones.py` importa `Errores` de interfaz/reservas: moverlo a shared (p. ej. shared/respuestas.py) o a notificaciones. infraestructura/usuarios.py y pruebas.py también usan NotificacionesSql/ReservasSql/canal_push.
- Capas: rutas/barrido/__init__ presentation, casos_de_uso/almacen/reglas rule, repositorio/push data.
- Verificar: ruff, mypy --strict, tests de reservas y notificaciones; el test `notificaciones no importa reservas` debe pasar. Commit + Log (L10 T4) con `replaces:` si se reescriben tests congelados.

## Falta T5, T6 (sin tocar)
T5: usuarios, recuperacion, main/salud/pruebas arriba, nombres de esquema (ASM-05: `PedidoDeEdicion` de interfaz/sesion.py -> `PedidoDeEdicionDePerfil`, `PedidoDeCambioDeReserva`, `PedidoDeCambioDeEspacio`, `PedidoDeEdicionDeSede`) y openapi.json. T6: docs/mapa, e2e.sh, README, .claude/rules/arquitectura.md.

## Tests congelados que quedan rojos y requieren reemplazo (ASM-07, `replaces:` en Log, archivo nuevo mismo tag)
- tests/unit/test_api_limpia.py (3 tests), test_api_limpia_plan.py (2), test_capas.py (zona, supresiones, y los de capas), test_sin_supresiones.py: leen app/infraestructura, app/interfaz, `interfaz/entradas.py`, `dominio/zona.py`, `infraestructura/db.py`. Reescribir para escanear `app/shared/*` y `app/modules/*/repositorio.py` (zona -> shared/zona.py, entradas -> shared/entradas.py, db -> shared/db.py).
- tests/unit/test_arquitectura.py (T1, mío): líneas 202/212/213 tienen `# type: ignore` que rompe test_sin_supresiones y test_capas supresiones: reemplazarlo con un archivo nuevo mismo tag sin los ignore (cast/typing). Sus demás fallas se resuelven con T4-T6.
- test_mapa_por_funcionalidad.py: se resuelve con T6.
Resultado actual de unit+integración: 417 passed, 19 failed (todos de esta lista).
