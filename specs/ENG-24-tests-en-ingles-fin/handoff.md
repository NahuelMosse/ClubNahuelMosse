# ENG-24 · handoff

Branch `ENG-24-tests-en-ingles-fin`, stacked on ENG-22 (PR #38) and merged with origin/main at 3de930d1 (kit 6.45.1).
`specs/.current` stays as main's in the commits; set it locally to `ENG-24-tests-en-ingles-fin` before running the kit tools.
No PR is open yet; the branch is pushed up to 36e7e79c.

## Verified

- lint (ruff, mypy, flutter analyze, dart format) passes; eslint over the touched `tests/*.test.mjs` passes.
- vs-main passes (tags, number of test cases, PNG blobs, Spanish app texts the tests compare).
- pytest: the 7 failures are tests ENG-17, ENG-20 and ENG-22 declared replaced.
- attacks: only the HEAD 405 rows, ignored in `http-attack.config.json` under ENG-24-ASM-01 (ENG-22-ASM-08).
- migrate-upgrade and node pass (docs-site needs `docs-site/node_modules/swagger-ui-dist`, installed by hand; `npm ci` stalls on this disk).

## Failed: flutter, 82 failures (gate run `D:/Temp/w/eng24-verify3.log`, log `D:/Temp/w/eng24-flutter.log`)

The translation of the app tests broke literal bytes the tests compare. Two causes found:

1. **Backslashes lost.** The rewrite went through shells that eat `\\` (the Bash tool turns `\\` into `\` even inside a quoted heredoc).
   Example: `screen_pieces_test.dart` `_withPieces` has `RegExp(r"^import '([a-z_]+/.dart)'")` where main has `\.dart`, so no
   piece is followed and every `accentOnMedia` / on-media token test fails.
2. **Non-breaking spaces turned into spaces.** `spaces_admin_test.dart` price tests: main's literal U+00A0 after `\$` became a
   space. **Fixed** in the commit with this handoff (lines restored to main's form: `\u00A0` escapes where main had escapes,
   the literal U+00A0 where main had it).

`D:/Temp/w/eng24-esc.py` (with `D:/Temp/w/eng24-pairs.txt`, from `git diff -M30% --name-status origin/main HEAD`) compares, per
renamed test file, the backslashes, `\u`/`\$` escapes and invisible characters against main. After the fix it still flags:

- `apps/mobile/test/screen_pieces_test.dart` backslash main 6, HEAD 5 (the `\.dart` above)
- `apps/mobile/test/token_clock_test.dart` main 4, HEAD 3
- `apps/mobile/test/cleanup_plan_test.dart` main 10, HEAD 11
- `apps/mobile/test/my_bookings_test.dart` main 0, HEAD 1
- `apps/mobile/test/no_overengineering_a11y_test.dart` main 0, HEAD 1

The script does not cover files git sees as added (`A`), e.g. `redesign/over_photo_test.dart`, which fails the same way
(`accentOnMedia` not found: same lost `\.` in its import regex, presumably). The failing files, by count:
loading_skeletons 15, screen_pieces 9, redesign/over_photo 8, redesign/screens 4, spaces_admin 3 (fixed), redesign/palette_redesign 3,
keyboard_in_login 3, bilingual_app 3, cleanup 2, bilingual_common 2, bilingual_admin 2, token_clock 1, and files that did not
compile (`loading ... [E]`): skeletons_account, skeletons_account_closed, search_court, registration_screen, registration_rules,
registration_limits_rules, redesign/transitions, redesign/motion_screens, redesign/motion_reduced_replacement, notifications
(`Method not found: 'arrivedLabel'`, `getter 'label' isn't defined for 'DayGroup'`: a production name translated in the test,
against ENG-22-ASM-01).
`node scripts/ci-test-verdict.mjs flutter ../eng24-flutter.log 1` lists the ones no card declares replaced.

## Failed: screenshots

verify3 ran flutter and screenshots in parallel in the same `apps/mobile/build` (`PathExistsException ... test_cache`).
`D:/Temp/w/herramientas/eng24-flutter.sh` and `eng24-screenshots.sh` now take a mkdir lock (`D:/Temp/w/eng24-flutter.lock`, bounded
at 720 × 5 s) so they run one at a time; not yet run with the lock. If a stale lock dir is left, remove it before the gate.

## Not covered (turn budget)

Each item is *could not run*:

- Fixing the five flagged backslash diffs, `redesign/over_photo_test.dart`, and every other failing file above: compare each with its
  main original (`git diff -M30% --name-status origin/main HEAD`) for string literals, regexes and production identifiers; fix
  with the Edit tool, never through a shell heredoc.
- The compile failures (notifications and the others): restore the production names main's tests used.
- Rerunning the gate: `node .claude/tools/verify.mjs` in the background to a new log, then `required.mjs`, `close.mjs`.
- Publishing: PR (title «ENG-24 · los tests en inglés, lo que ENG-22 dejó pendiente», body `closing.md` plus the attribution
  line), CI watch, closing comment, merge if green.
- Cleanup of my resources (agent `app-tp/eng24`, agt_bcb923817efe): auth emulator (Bash PID 31081; Windows 33500 and child 31876),
  the `docker logs -f` watcher (sh 35608/33056, docker.exe 32792), the container `rg-app-tp-eng24-postgres` (`rg_release`
  contenedor, stop=true) and ports 8701–8704, the app verify3 started if still up, the lock dir, `D:/Temp/w/eng24-pack`,
  `D:/Temp/w/eng24-maps`, `D:/Temp/w/eng24-ea-main.dart`.
