# NOT-05 handoff

## Hecho (commits 2556e2c RED, luego el de código)
- API: `migraciones/versions/0011_recordatorio_cinco_minutos.py` (CHECKs `notificacion_tipo_check` y `notificacion_check` + índice único; downgrade borra y revierte), `reglas.py` (`ANTICIPACION_CINCO`, `ClaseDeRecordatorio`, `Recordatorio.clase`, título por clase), `repositorio.py` (`vencidos` recorre las clases con `_vencidos_de`; `registrar` y `_sigue_vigente` por clase; `tomar_siguiente` y `marcar_varados_fallidos` tratan ambos tipos). `casos_de_uso.py` no cambió: `vencidos` devuelve las dos clases.
- App: `notificacion.dart` (`recordatorioCinco`), `tarjeta_aviso.dart` (switch del ícono; sumado a T2 en card.md).
- `pyproject.toml`: per-file-ignores de los tests nuevos (E501, SIM300).
- Test de integración de ASM-02 corregido: el disparador `reserva_modificado` pisa `creado_en`, se apaga dentro del test; a `inicio-4min` salen 2 avisos (1 h y 5 min).

## Último gate (antes de los arreglos): app-tests, attacks, migrate-upgrade, layers, shape, overdesign, migrations, boundaries passed
## Falta
1. Correr `node .claude/tools/verify.mjs` (env: UV_PROJECT_ENVIRONMENT del venv compartido, FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099; la DB `club_not05_migra` ya existe). Pendientes que vio: suite (el test ASM-02, ya corregido, sin reconfirmar), lint (E501/SIM300, ya con ignores, sin reconfirmar), mutación de `reglas.py`, K4 (duplicación de fakes en test_recordatorio_cinco.py vs test_correos_con_diseno.py y entre los dos tests nuevos: declarar en el Log `declared · K4 · <archivo> · <por qué>` o extraer).
2. Append al `## Log` de card.md: una línea por tarea T1/T2 con evidencia (con Edit, no shell).
3. `docs`: la card declara `no-docs`.
