# Handoff SIM-01 (gate fixes)

Worktree D:/Temp/w/sim01-gate, branch card/SIM-01 (switched, committed). Last gate log: D:/Temp/sim01-gate8.log (101 min).
Use UV_PROJECT_ENVIRONMENT="D:/desktop folders/estudio/Universidad de moron/Electiva general/app-tp/apps/api/.venv".

## Done (committed)
- `# kit-shape:` first-line comment in apps/api/app/interfaz/{notificaciones,recuperacion,registro,reservas,sedes,sesion}.py.
- Log L56-L79 of card.md: `replaces:` for the 22 uncovered Flutter failures (copied from ARQ-03/RED-05/REV logs; every `by:` exists, carries the tags, passes), plus L78 (20+) and L79 (30 s, now with tags) correcting L27/L28 (L28's `by:` was not a file; L27's name had no tags).
- New test apps/mobile/test/rediseno/marcador_proximas_reemplazo_test.dart (@RED-03-ASM-13), passes alone.

## Left
1. shape: 7 Dart files in the diff have several classes and no marker. Add `// kit-shape: <why, Spanish, present>` as first line (widget y su State / modelos de un mismo pedido se leen juntos) to apps/mobile/lib/{admin/historial_reservas,api/cliente_api,app,comun/dialogo_error,inicio/pantalla_inicio,reservas/pantalla_mis_reservas,reservas/reservas}.dart.
   Check without the gate: `node /tmp/shape2.mjs` (reads shapeProblems of gate-checks.mjs over the diff; recreate it if /tmp is gone) must print nothing.
2. a11y failed in the gate: `TimeoutException after 12 minutes` (machine load, flutter running in parallel with the suite). Re-run alone via a runner: `node .claude/tools/once.mjs a11y -- sh D:/Temp/w/herramientas/flutter-mobile.sh test/sin_sobreingenieria_a11y_test.dart` (the builder hook refuses it to a builder).
3. mutate apps/api/app/infraestructura/notificaciones.py: "unmutated suite did not finish in 10 minutes" (load). Re-run alone: `node .claude/tools/once.mjs mutate -- node .claude/tools/mutate.mjs apps/api/app/infraestructura/notificaciones.py --since c6893a457879a988026bfe8b65f6ebd94cb6e9c5~1 -- <command of the card's Gate line>` (exact line in the `required:` output of the log).
4. suite: expected to pass as "passed with replaced" now (24 [E] failures, all declared); the 24th previously reported was L27/L28 mis-declared. Confirm on the next full gate.
5. Re-run `node .claude/tools/verify.mjs > D:/Temp/sim01-gate9.log 2>&1` in the background, wait with `.claude/tools/wait.mjs`; no other Flutter in this worktree meanwhile.

## Gate verdicts from sim01-gate8.log
passed: attacks, captures, lint, migrate-upgrade, 4 of 5 mutate, specs, layers, overdesign, migrations, boundaries, remove-only.
failed: a11y (timeout), suite (replacements incomplete, fixed since), mutate infraestructura/notificaciones (timeout), shape (Python fixed, 7 Dart pending), required (mutation).
