# Handoff SIM-01 (API)

## Hecho
- RED commiteado (9faf496): `apps/api/tests/unit/test_sin_sobreingenieria.py` (T1,T2,T3,T6) y `apps/api/tests/integracion/test_sin_sobreingenieria_api.py` (T4,T5).
- T1 (casi) y T2 hechos: `main.py` reescrito sin protecciones/registro/503/emulador/docs condicionados; `salud.py` sólo `/health`; `config.py` sin `database_url_app`, `metricas_token`, `detras_de_proxy`, `documentacion_interactiva`, `hosts_permitidos`; `db.py` sin pool/timeouts/`base_disponible`/`esquema_al_dia`/`uso_del_pool`/`POOL_*`; `dependencias.py` sin esos; `git rm` de `interfaz/{metricas,limites,protecciones,registro_errores}.py`; `Frenado` y `frenar_*` sacados de `registro.py`, `recuperacion.py`, `sesion.py` (queda el 429 de `PUT /yo/contrasena`); `prometheus-client` fuera de `pyproject.toml` y `uv.lock` (`uv lock`); `render.yaml` sin `DOCUMENTACION_INTERACTIVA`/`DETRAS_DE_PROXY`/`DATABASE_URL_APP`/`METRICAS_TOKEN`, `healthCheckPath: /health`.

## Falta
- T1: `.env.example` (variables que salen); chequear con Grep que nada importe lo borrado (`grep -rn "limites\|metricas\|protecciones\|registro_errores\|base_disponible\|POOL_MAXIMO" apps/api`) incl. scripts y tests viejos (L2).
- T3: `entradas.py` sin `max_length`/`_sin_control` ni alias `Texto40/Texto120/Busqueda/Correo/Clave/Codigo/TokenDeDispositivo/Parrafo`: reemplazar sus usos por `str` en espacios, horarios, notificaciones, reservas, sedes, registro, sesion, recuperacion; sacar `string_too_long` y `caracteres_no_permitidos` de `_MENSAJES`. Hoy el test de T3 falla por `string_too_long` en `PedidoDeSede`.
- T4, T5, T6 enteros (ver card.md y los hallazgos del handoff previo, git show 52a1a37:specs/SIM-01-sin-sobreingenieria/handoff.md).
- Nota: el test T1 "no hay tiempos de espera..." exige que `app.interfaz.marcador` no exista: sólo pasa al hacer T4 (git rm de `interfaz/marcador.py`).
- L2: correr la suite API entera en background y borrar/reescribir tests de lo que sale; registrar en el Log.
- Ya pasan (por azar) "una reserva sobrevive a reiniciar" y "un aviso que falla queda fallido y no se reintenta"; el resto del RED de integración falla por lo correcto (marcador, columnas, migración 0009).

## Comandos
- `sh D:/Temp/w/herramientas/arq01-pytest.sh -q tests/unit/test_sin_sobreingenieria.py tests/integracion/test_sin_sobreingenieria_api.py` (desde la raíz); lint `sh D:/Temp/w/herramientas/sim01-lint.sh` (no corrido aún).
- Gate no corrido. No tocar `apps/mobile` (T7/T8).
