# Handoff ENG-16

Worktree D:/Temp/w/eng16, branch ENG-16-app-en-ingles. Not pushed. origin/main (31a23b9) merged (conflicts resolved with the English side).

## Done
- Merge of origin/main; specs/.current kept.
- card.md: Tasks list every touched file by layer (T1 files presentation/rule domain/data, T2 tests); ASM-02/ASM-03 added; 35 `declared · mutate` Log lines (L4..L38); judge.md ACT-01..05 closed (judge.md exists, written by a previous judge run; its ACTs now closed/declared).
- `once.mjs lint` ran green (exit 0): clears the 100 "linter on" lines.
- Fixed the only suite red that is NOT red on main: SIM-03-S2 (space_search_screen.dart build was 81 lines; extracted _bodyWithoutOptions/_form). codigo_legible_test passes.
- Suite comparison (full runs, logs D:/Temp/suite16.log here, D:/Temp/suite16main.log main): 27 reds here; every one except SIM-03-S2 is also red on main at 31a23b9 (VIS-02 x4, REV-04-S1, ARQ-03 limpieza x3, SIM-01-S4, RED-* 17 in test/rediseno). Lists: D:/Temp/reds16.txt (here), D:/Temp/redsmain.txt (main). Main has 4 more reds that pass here (ARQ-03-S3, piezas_de_pantalla, REV-06-S5, ...).

## Left
1. Log: one `declared · suite · <test> · roja también en main 31a23b9 (D:/Temp/redsmain.txt)` line per remaining red (model: ENG-15 Log L4, L32-L35 in specs/ENG-15-app-en-ingles-verde/card.md of main); check the verify message for the exact declared format.
2. attacks: "contract lens without attacks line": risk escalated by the diff to high (lenses contract, interpretation, security; false positives by name collision). Declared L2/L3 (fault-db, attacks) are in the Log but verify still fails; check `declared · attacks` shape in verify/plan messages, or run risk.mjs after Tasks naming lib/app.dart, main.dart, session/*, spaces.dart, venues.dart (they are now listed; risk.mjs run said "small · low" but verify said "risk escalated by the diff: high" at 23:36, re-run to see).
3. shape (~classes-per-file in lib/common/*) and boundaries (lib/common "grab-bag"): `declared · shape · <file> · <why>` / `declared · boundaries · <file> · <why>` per file; full lists: Grep `^shape|^boundaries` in D:/Temp/v16.log.
4. NEW gate check code-language (kit 6.24): production files moved by the card keep Spanish identifiers: `ClienteApi` (lib/api/cliente_api.dart, used by ~15 lib files and ~30 frozen tests), `RutaDeLaApi` in lib/api/rutas.dart, params `sedes`, `inicio`, `boton`, `cuenta`, `datos`, `_nombres`, `reserva`, `correo`, `_controlador`, `tarjeta`, `pedido`, `_fecha`, `horas` in bookings/presentation and home_screen. Full list: `node D:/Temp/cl16.mjs`. Fixing needs renames that touch frozen tests (guard refuses): decision for the main thread (replace tests via new files, or declare gate red in the Log and a follow-up card for identifiers). The card S1 only asserted folders/files.
5. required: ~60 K4 `declared · K4 · <file> · bloque repetido por el renombre, ya en main` lines (Grep `K4 ·` in D:/Temp/v16.log or run `node .claude/tools/required.mjs`); re-check "judge.md: review high" after Tasks edits (judge.md exists with ACTs closed; the message appeared before it was closed).
6. Rerun `node .claude/tools/verify.mjs > D:/Temp/v16.log 2>&1` in background + `node .claude/tools/wait.mjs D:/Temp/v16.log --until 'verify: exit' --max 570`, then `node .claude/tools/close.mjs` until 9/9; commit closing.md.

Env: PATH=/d/projects/flutter/bin; firebase emulator :9099; gate `sh D:/Temp/w/herramientas/flutter-mobile.sh`. Scripts in D:/Temp: gen16.mjs/gen16b.mjs (already run), cl16.mjs (code-language scan).
