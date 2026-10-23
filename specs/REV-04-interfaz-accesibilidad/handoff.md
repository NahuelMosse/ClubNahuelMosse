# Handoff — REV-04 · interfaz y accesibilidad

- card: `specs/REV-04-interfaz-accesibilidad/` · snapshot `proposed`
- branch: `card/REV-04`, worktree `D:/Temp/w/rev04` · base commit: `138bc54` · plan commit: `dfc129d` · tests-in-red commit: `dfc129d` (evento en `e16667b`)
- grade: `production` · modules: `ui, api, data, infra, observability, security-l2` · lane: `normal`

## Groups, in order (from `plan.md` `## File map`)

1. `componentes comunes y reloj` — `apps/mobile/lib/comun/{reloj,calendario,campo_texto,selector,boton,dialogo_error,barra_inferior}.dart` — tests: `@REV-04-H18-01`, `@REV-04-H18-02`, `@REV-04-H18-05`, `@REV-04-H18-06`, `@REV-04-H27-01`, `@REV-04-H27-02`, `@REV-04-H27-03`
2. `formularios` — `apps/mobile/lib/usuarios/pantalla_registro.dart`, `apps/mobile/lib/admin/pantalla_formulario_sede.dart`, `apps/mobile/lib/admin/pantalla_alta_espacio.dart` — tests: `@REV-04-H17`, `@REV-04-H27-04`
3. `confirmaciones y avisos` — `apps/mobile/lib/reservas/{pantalla_confirmar_reserva,pantalla_confirmar_cambio,reglas_busqueda}.dart`, `apps/mobile/lib/notificaciones/{panel_avisos,pantalla_notificaciones}.dart`, `apps/mobile/pubspec.yaml` — tests: `@REV-04-H18-03`, `@REV-04-H18-04`
4. `capturas` — `apps/mobile/test/capturas/*_capturas.dart` y sus PNG — evidencia del paso 9 y de `@REV-04-H27-03`

Escenarios: `apps/mobile/test/interfaz_accesible_test.dart`.

## Decided

- RFZ: none
- ASM open: REV-04-ASM-01 a ASM-09, en `plan.md` `## Assumptions`; ASM-04 y ASM-06 son `any-answer: no` y van destacadas en el cierre; OUT-01 y OUT-02 en `ambiguities.md`
- app: none (Flutter, sin servidor web; las pantallas se juzgan con widget tests, capturas y, si está el emulador, e2e) · seed: none

## Already ran

- `flutter test test/interfaz_accesible_test.dart` sobre `dfc129d` → failed: no compila sin `lib/comun/reloj.dart`; la variante sin ese test (fuera del repo, `D:/Temp/w/borradores/rev04/sin_reloj_test.dart`) da 21 fallan y 2 pasan (dos de `@REV-04-H27-04` a 320 × 568, que ya andan) · `D:/Temp/rojo-rev04b.log`
- RED-REVIEW → hallazgos H y M corregidos en una ronda · `specs/REV-04-interfaz-accesibilidad/red-review.md`
- `plan-check.mjs` → passed

## Decisions of the main thread not written elsewhere

- El test «a 320 × 568 el alta de espacio completa, con su nombre generado, entra entera» falla hoy con `Bad state: No element` en `ensureVisible`. Si al implementar se ve que el motivo es el test y no la pantalla, se recongela con `node .claude/tools/refreeze.mjs` y su evento, nunca editándolo a mano.
- Flutter: `export PATH="/d/projects/flutter/bin:$PATH"`. `mutate.mjs` no trae mutador de Dart: la mutación queda «no se pudo correr».
- Capturas: `cd apps/mobile && flutter test --update-goldens test/capturas/<archivo>_capturas.dart`, sólo las que cambian por esta card, y se miran en el paso 9.
- Emulador Android: se intentó levantar `emulator-5554` (PID en `/tmp/avd.pid`); si `adb devices` lo muestra, los e2e de registro, reservas y sedes corren con `sh /d/Temp/e2e-archivos.sh /d/Temp/w/rev04 rev04 integration_test/<archivo>.dart`; si no, TalkBack y e2e quedan «no se pudo correr».
- Los hooks del kit ubican la card por las rutas absolutas del prompt y no reconocen rutas entre backticks: en cada prompt a un subagente poné al menos una vez la ruta plana, precedida de un espacio (por ejemplo D:/Temp/w/rev04/specs/REV-04-interfaz-accesibilidad/plan.md ); en shell, `cd /d/Temp/w/rev04 && ...`.
- No se mueve la llamada HTTP de `PantallaRegistro` (REV-06). No se pushea, no se abre PR, no se mergea: publicar queda «no se pudo correr». Máquina compartida: lo largo en background con log y `wait.mjs`; matar procesos sólo por PID propio.
