# Handoff REV-03 · ronda h

## Hecho
- Faltaba en git `apps/api/tests/escenarios/test_datos_migraciones_lock.py` (reemplazo L31, nunca se había commiteado tras el rebase): recreado, 1 passed (10 min bajo carga), commit "test de lock_timeout de 0008". El lint de required lo necesitaba.
- K4 en producción: jscpd (`npx -y jscpd@4`, mismos argumentos que verify) no halla ningún clon con un archivo que no sea test; nada que extraer ni declarar (los de tests ya están L32 a L37).
- Mutaciones: dominio/notificaciones.py 5/5 (exit 0). Las demás: el baseline de test_datos.py tarda 512 s porque incluye los dos tests de migraciones congelados (lentos), así que mutate.mjs las rechaza por presupuesto (exit 4: mutantes x baseline > 10 min). Se relanzan con `--deselect` de esos dos tests (reemplazados por test_datos_migraciones*.py): script `/tmp/mut-seq2.sh`, log `/tmp/mut-seq2.log` (puede haberse perdido; el comando está abajo).
- required.mjs imprime las líneas de `once.mjs lint -- cd apps/api && ...` que cmd parte en el `&&`: se corre con un script `sh` (`/tmp/lint-inner.sh`: `cd D:/Temp/w/rev03`, PATH flutter, la línea de lint del Gate) como `node .claude/tools/once.mjs lint -- sh /tmp/lint-inner.sh`; ruff pasó ("All checks passed", "74 files already formatted"), faltaba sólo el lock test, ya creado. Reintentar.

## Falta
1. Leer `/tmp/mut-seq2.log` (grep -v "^mutate: exit"). Por cada archivo: sobrevivientes -> tests nuevos en archivos nuevos o equivalente en `specs/REV-03-datos/equivalents.md`. Si sale exit 4 en migraciones/env.py y 0008 (cada test de migración ~45 s): declararlo como no se pudo correr (presupuesto de 10 min de mutate.mjs) o acotar con un test más corto.
2. Actualizar las líneas `mutate ...` del `## Gate` de card.md con los `--deselect` usados, si cambian (no tocar las de .dart).
3. Reintentar el lint de once y `node .claude/tools/required.mjs`.
4. Línea final al Log: `- L40 · 2026-10-23 · T1..T4 · <resultados>`.

## Comando de mutación (una a la vez, sin carga paralela; `FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:8702`)
`node .claude/tools/once.mjs mutate -- node .claude/tools/mutate.mjs <archivo> --since c9625bdd3b7b67d3ab43ec66a7c29208469e6bbd~1 --equivalents specs/REV-03-datos/equivalents.md --parallel 2 -- sh D:/Temp/w/herramientas/pytest-api.sh -q -x <tests> --deselect tests/escenarios/test_datos.py::test_la_migracion_nueva_no_se_queda_esperando_un_bloqueo --deselect tests/escenarios/test_datos.py::test_cada_migracion_va_y_vuelve_con_datos`
Esperar con `timeout 570 sh -c 'until grep -q "END <archivo>" /tmp/mut-seq2.log; do sleep 10; done'` (wait.mjs corta en la primera línea `exit` vieja). Hay otros agentes (rev08) cargando la máquina.
