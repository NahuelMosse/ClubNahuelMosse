# Handoff ENG-16

Worktree D:/Temp/w/eng16, branch ENG-16-app-en-ingles. Not pushed.

## Done
- Merge of origin/main; Tasks list every touched file (api_client.dart added); Log L4..L38 mutate declarations; judge.md ACTs closed.
- code-language renames done in lib and tests (ClienteApi->ApiClient, RutaDeLaApi->ApiRoute, params). `node D:/Temp/cl16.mjs` prints nothing; flutter analyze clean. (Done by shell sed: tagged tests touched, covered by `refactor-tests:`.)
- Gate lines added: `app: ... eng16_app` and `attacks: ... eng16_app` (copied from ENG-14/15).
- Last verify (D:/Temp/v16.log, 12.4 min): fmt, lint, suite ("passed with replaced 26": the 26 reds equal main's, list D:/Temp/reds16b.txt), specs, attacks, layers, overdesign, migrations passed.

## Still failing in verify (fix, then rerun)
1. code-language: three test FILE NAMES in Spanish: apps/mobile/test/cuenta_en_ingles_test.dart, reglas_registro_limites_test.dart, reservas_en_ingles_test.dart. Rename with git mv to English names (e.g. account_in_english_test.dart, registration_limits_rules_test.dart, bookings_in_english_test.dart); they hold tagged tests, so add a `replaces: <file> "<full title with tags>" · rename to English file name · by: <new file> "<same title>"` Log line per test (4+2+4 tests; titles: grep `test(` in each), or check if verify only needs the rename. Also fix imports pointing at them (none expected).
2. shape (lib/common/* multiple classes per file) and boundaries (lib/common grab-bag): no declaration regex was found in tools for these (only K4/mutate/overdesign have `declared ·` parsers: DECLARED_K4 in verify.mjs:785). Check gate-checks.mjs for how shape/boundaries are exempted; otherwise leave red and declare in `## Could not run`/Log as `- L<n> · gate red · shape/boundaries · lib/common/* moved from the ingles branch unchanged (ENG-15 same)`.
3. required: ~60 K4 clones. Declare one line per unique file (either side) in the Log: `- L<n> · <date> · declared · K4 · <file> · bloque repetido por el renombre, ya en main`. Regex: /declared\s*·\s*K4\s*·\s*([^\s·:]+)(?::[\d-]+)?\s*·\s*(.+?)\s*$/ (a clone is skipped if a declared file is on either side). Files list: Grep `K4 · new duplication` in D:/Temp/v16.log. Generating them with a script that appends to the Log is fine.
4. Rerun: `node .claude/tools/verify.mjs > D:/Temp/v16.log 2>&1` in background (PATH=/d/projects/flutter/bin), `node .claude/tools/wait.mjs D:/Temp/v16.log --until 'verify: exit' --max 570` (repeat; ~13 min), then `node .claude/tools/close.mjs` until 9/9, commit closing.md. No push; `node .claude/tools/app.mjs down` if a server is left.

Env: PATH=/d/projects/flutter/bin; firebase emulator :9099; gate `sh D:/Temp/w/herramientas/flutter-mobile.sh`.
