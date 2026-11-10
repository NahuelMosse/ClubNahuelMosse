# ENG-24 · handoff

Branch `ENG-24-tests-en-ingles-fin`, stacked on ENG-22 (PR #38) and merged with origin/main at 3de930d1 (kit 6.45.1).
`specs/.current` stays as main's in the commits; set it locally to `ENG-24-tests-en-ingles-fin` before running the kit tools.

## Verified

- lint (ruff, mypy, flutter analyze, dart format) passes; eslint over the touched `tests/*.test.mjs` passes; `required.mjs` had nothing missing before the merge.
- vs-main passes: tags and test cases are main's plus ENG-22's and ENG-24's own, the PNGs are main's blobs, the Spanish texts of the app the tests compare (titles and single lowercase words aside) are as on main.
- pytest: the 7 failures are tests ENG-17, ENG-20 and ENG-22 declared replaced.
- attacks: only the HEAD 405 rows, ignored in `http-attack.config.json` under ENG-24-ASM-01 (ENG-22-ASM-08).
- migrate-upgrade passes.

## Open

- node: `docs-site` needed `npm ci` in the worktree (the CI installs it).
- flutter: one run had "The Dart compiler exited unexpectedly" loading accessibility_admin_test.dart while the whole gate ran in parallel; its tests then ran.
- screenshots: 18 home captures differ from their PNGs (the greeting under the fixed 15:00 clock says «BUENAS TARDES», the PNG «BUENOS DÍAS»); the PNGs are main's byte for byte, and main's run of the same files is the baseline.
