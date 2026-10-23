# Handoff REV-03 · ronda i

## Hecho
- `D:/Temp/w/herramientas/pytest-unit.sh` (sin base por corrida) en las líneas `mutate` del Gate; los .dart usan `flutter-mobile.sh`; el lint va con `sh -c '...'`.
- Mutaciones corridas una a una (script `D:/Temp/w/herramientas/mut-rev03.sh "<archivo>|<comando de test>"`): resultados en el Log L41. Tests nuevos: test_datos_tanda_justa.py, test_datos_tanda_justa_propia.py, test_datos_migraciones_transacciones.py. Equivalentes en equivalents.md (dominio/reservas:69, infraestructura/reservas:130, 0008:13).

## Falta
- `node .claude/tools/required.mjs` sigue listando 17 faltantes: mutate de aplicacion/notificaciones, dominio/notificaciones, infraestructura/notificaciones, env.py, 0008, y los 12 linters. Probable causa: el registro no coincide con el comando/estado de código; re-correr cada mutación con la línea `mutate` del Gate vía once.mjs (0008 se debe re-correr para que el equivalente cuente) y la línea `lint` tal cual la imprime required, con PATH="/d/projects/flutter/bin:$PATH".
- Comando: `node .claude/tools/once.mjs mutate -- node .claude/tools/mutate.mjs <archivo> --since c9625bdd3b7b67d3ab43ec66a7c29208469e6bbd~1 --equivalents specs/REV-03-datos/equivalents.md --parallel 2 -- <línea del Gate>`; esperar con `timeout 560 sh -c 'until grep -q "END ..." log; do sleep 10; done'`.
