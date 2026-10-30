# ENG-18 · handoff

Worktree `D:/Temp/w/eng18`, branch `ENG-18-contrato-ingles`, rebased onto origin/main 8732227 with the commit order kept (RED stays RED).

## Covered

- Gate: `verify: exit 0`, `required: passed`. Six lines passed on this code: suite, mobile (71 failures against 74 on main 8732227, none new), lint, attacks, apk and presentation-strings (7 presentation files changed, 0 visible texts).
- Mutation: exit 0 on every listed file, run on the rebased code. API: availability/rules, bookings/use_cases, notifications/rules, notifications/use_cases, spaces/rules, users/deactivation and shared/input_validation. Mobile: bookings/domain/search_rules, where tests that already fail on main are left out.
- `close.mjs`: all 9 checks passed. `closing.md` was regenerated and committed in "ENG-18: cierre sobre main 8732227".
- The Log records L116, the presentation-strings base set to 8732227. It also records L117-L129, `declared · K4` for ENG-19's Spanish/English test pairs that already duplicate on main, and for the three tagged ENG-18 tests.

## Not covered (turn budget)

Each item is *could not run*: the card-runner reached its turn limit.

- `git push -u origin ENG-18-contrato-ingles` (no force).
- `gh pr create --base main --title "ENG-18 · Contrato HTTP en inglés"`, with closing.md as the body plus the Claude Code line.
- Watch CI with `gh pr checks --watch > .validation/ci.log`, write `.validation/ci.md` and post it with `gh pr comment`.
- `gh pr close 30 --comment "Reemplazado por #<nuevo>: la rama se rebasó sobre main."`
- `gh pr merge <nuevo>`, if the publish hook allows it. If it refuses, leave the PR open.
- `git branch -D ENG-18-merge-main-local`.
- `git worktree remove D:/Temp/w/main-8732227`.
- Bring down the Firebase Auth emulator. Its PID is in `/d/Temp/w/eng18-auth.pid`: kill that process and its child node processes.
- Check that no `tail -F` remains on `/d/Temp/w/eng18-mutr-*.log`, then run `rg_ps`.
- Read the ASM list, `## Needs a person` and the `Cost:` line from `closing.md` (it is over 25k characters: grep first).
