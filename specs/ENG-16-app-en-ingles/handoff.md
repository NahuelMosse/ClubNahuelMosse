# Handoff ENG-16

Worktree D:/Temp/w/eng16, branch ENG-16-app-en-ingles (base origin/ENG-14-api-en-ingles-verde). Not pushed.

## Done (commits)
- b96febc card.md + risk.json (small · low · no lenses at plan time) + specs/.current.
- RED: apps/mobile/test/app_en_ingles_verde_test.dart retagged @ENG-16-S1/@ENG-16-ASM-01/@ENG-16-S2 (S3 dropped); failed for the right reason.
- f64a83e: `git checkout ingles -- apps/mobile` + 265 Spanish files removed + specs ENG-08..11, ENG-15 from `ingles`. Test file kept as the ENG-16 version. No `replaces:` declared in those cards.
- SAL-01 (home_greeting.dart) and VIS-02 (common/skeleton*.dart) verified present.

## Gate run (log /tmp/v16.log = D:/Temp/v16.log, 13.5 min, exit 1)
passed: fmt, lint, specs, layers, overdesign, migrations.
failed:
1. suite: `+685 -27` (transiciones_test "@RED-04-ASM-09" etc). Need the 27 names (`cd apps/mobile; flutter test --reporter failures-only` with PATH=/d/projects/flutter/bin) and compare with main (D:/desktop folders/estudio/Universidad de moron/Electiva general/app-tp at 424319d). Known on main per ENG-15 L4/L33: interfaz_accesible_test @REV-04-S1; limpieza_test @ARQ-03-ASM-02/@ARQ-03-ASM-04; limpieza_plan_test @ARQ-03-ASM-04; sin_sobreingenieria_test @SIM-01-S4; 17 in test/rediseno; esqueletos_de_carga_test @VIS-02-S1 x4. Declare each in the Log with the main evidence (ENG-15 Log L4, L32-L35 is the model); fix any that fail only here (ENG-16-ASM-01).
2. attacks: "contract lens without attacks line": the diff escalated the risk to high with lenses contract, interpretation, security (false positives: lib/app.dart, common/config.dart etc. "shared code imported by apps/api/app/*" by name collision; session/* "sensitive module"). Declared L2/L3 (fault-db/attacks) are in the card; check whether verify accepts `declared · attacks` (ENG-15 had it; add an `attacks:` declaration line in the same shape if needed).
3. shape: ~classes-per-file in lib/common/*.dart (badge, bib, booking_card, bottom_bar, button...). Moved files from main, not new code: declare per file `declared · shape · <file> · <why>` (see the exact line format in the verify message; read full output with Grep on `^shape`).
4. boundaries: lib/common/* "grab-bag folder (common/)": same, declare per file `declared · boundaries · <file> · …` (renaming common/ would break the English layout of ENG-08..11 and the tests).
5. required (run `node .claude/tools/required.mjs`): (a) 313 files "not in the `## Tasks`" (lib/common 64, lib/features 235, integration_test, tool, app.dart, main.dart, router.dart, redirect.dart, theme, api): list them in the Tasks lines of card.md (T1 files, with layers; T2 tests/integration_test/tool) or add the broader paths the check accepts; (b) mutation of 33 `domain/*.dart` files: `declared · mutate · <file> · <why>` (ENG-15 L7 model: files that are renamed, no logic change; or run once.mjs mutate as the message says, in background); (c) ~60 K4 clones: `declared · K4 · <file> · bloque repetido por el renombre/ya en main` one Log line per file (ENG-15 L9-L35 model); (d) "risk.json says review: high · launch the judge PLAN": the diff re-escalated risk. Run `node .claude/tools/risk.mjs specs/ENG-16-app-en-ingles` after editing Tasks; if it stays high, launch the `judge` with a PLAN prompt on card.md, close its ACT lines, rerun.

## Left
Everything above, then: `node .claude/tools/verify.mjs > /tmp/v16.log 2>&1` in background + `node .claude/tools/wait.mjs <log> --until 'verify: ' --max 570`; then `node .claude/tools/close.mjs` until 9/9, commit closing.md. The Log only grows (append `- L<n> · 2026-10-27 · ...`); card.md edits to Tasks/Gate are allowed, L1 never.
Env: flutter at D:/projects/flutter/bin; firebase emulator :9099; gate command `sh D:/Temp/w/herramientas/flutter-mobile.sh`.
