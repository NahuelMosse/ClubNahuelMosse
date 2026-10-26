# Handoff SIM-01 (API)

## Hecho
- RED commiteado (9faf496): `apps/api/tests/unit/test_sin_sobreingenieria.py` (T1,T2,T3,T6) y `apps/api/tests/integracion/test_sin_sobreingenieria_api.py` (T4,T5).
- T1 y T2 en código (ver commit 930724f): main, salud, config, db, dependencias, interfaz sin metricas/limites/protecciones/registro_errores, prometheus fuera, render.yaml.
- T3 en código: `entradas.py` sólo con `Identificador`, `leer_hora`, `errores_de_forma`, `instalar`; todos los alias `Texto40/120/Busqueda/Correo/Clave/Codigo/TokenDeDispositivo/Parrafo` reemplazados por `str` en espacios, notificaciones, reservas, sedes, registro, sesion, recuperacion.
- T4 en código: `Marcador` y `TandaDeReservas` fuera de `dominio/reservas.py`; `FiltrosHistorial.despues` y `HistorialDeReservas.hay_mas` fuera; `ReservasSql.de_usuario(usuario_id, cuando) -> list[Reserva]` (sin LIMIT ni marcador); `mis_reservas` devuelve la lista; `GET /reservas` sin `despues`/`siguiente`; `GET /reservas/todas` conserva `pagina` con OFFSET, sin `despues`/`siguiente`; `interfaz/marcador.py` borrado (git rm).
- L2 (git rm de tests de lo que salió): `tests/unit/{test_limites,test_protecciones,test_registro_errores,test_api_limpia_metricas,test_marcador}.py`, `tests/integracion/test_registro_de_errores_api.py`. FALTA registrarlo en el Log de card.md.

## Falta
- La suite no colecta: 4 archivos importan lo borrado (L2, reescribir en archivo nuevo con sólo los tests que siguen, mismo nombre y tags, y `git rm` del viejo):
  - `tests/escenarios/test_datos_tandas_y_cola.py` (importa `Marcador`; `test_datos_plan_reemplazo.py` importa `_capturar_sql` de ahí: conservar lo que siga usando)
  - `tests/unit/test_casos_de_uso_reservas.py` (importa `TandaDeReservas`; adaptar `de_usuario` falso a `list[Reserva]`)
  - `tests/unit/test_entradas.py` (alias y topes de largo/control: sólo siguen los tests de `leer_hora`, `Identificador`, `errores_de_forma`)
- Otros con referencias a lo borrado (Grep): `tests/unit/test_api_limpia.py`, `test_api_limpia_plan.py`, `test_capas_integracion.py`, `tests/escenarios/test_operacion.py` (21), `test_operacion_rutas_publicas.py`, `test_seguridad_api.py` (3; ojo caso `Clave\x00Nueva1` de T3), `test_seguridad_entradas_extra.py`, y `apps/api/openapi.json` (6; regenerar o editar: sin /metrics, /ready, `despues`, `siguiente`, 429/503 de límites).
- T1: `.env.example` (no encontré su ruta: Glob dio timeout; buscar con `git ls-files | grep env.example`) sin `DATABASE_URL_APP`, `METRICAS_TOKEN`, `DETRAS_DE_PROXY`, `DOCUMENTACION_INTERACTIVA`, hosts, pool/timeouts. Grep final de `limites|metricas|protecciones|registro_errores|base_disponible|POOL_MAXIMO|Marcador|TandaDeReservas` en apps/api (scripts incluidos).
- Correr suite API entera (con `--maxfail` alto, en background) y los tests nuevos; lint `sh D:/Temp/w/herramientas/sim01-lint.sh` (no corrido).
- Log de card.md: una línea por T1, T3, T4 con evidencia, y las líneas L2 de lo borrado.
- T5 (migración 0009, avisos sin reintentos), T6 (scripts y docs), T7/T8 (app) siguen sin hacer. El test T1 "no hay tiempos de espera..." debería pasar ya (marcador borrado).

## Comandos
- `sh D:/Temp/w/herramientas/arq01-pytest.sh -q tests/unit/test_sin_sobreingenieria.py tests/integracion/test_sin_sobreingenieria_api.py` (desde apps/api o raíz, como lo usé: raíz).
- Gate no corrido. No tocar `apps/mobile`.
