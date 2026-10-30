# ENG-20 handoff

## Done (committed on ENG-20-textos-api-en-ingles)
- card.md frozen, risk.json (large · high · contract, interpretation, security), plan judge: judge.md with ACT-01 and ACT-02 closed (T2 tests per email and notification kind, ENG-20-ASM-03 scan rule, ENG-20-ASM-04 seed command keeps its options).
- RED: `apps/api/tests/escenarios/test_english_texts.py`, committed before the code.
- Production: every Spanish literal of `apps/api/app/**` in English (errors, emails, push and stored notifications, catalog names, seed command output, OpenAPI texts); `apps/api/openapi.json` regenerated. Keys, routes, catalog keys, CLI options and env vars unchanged.
- T4: API tests compare the English texts (refactor-tests).
- Lint (`eng17-ruff-mypy.sh` through once.mjs): passed.
- Suite (`tests/escenarios/test_english_texts.py tests/integracion tests/unit`): 583 passed, 14 failed; 4 of those fixed since (the 4 files rerun: 68 passed). Left failing: the 5 ENG-18 tests in `tests/integracion/test_contract_in_english.py` that froze main's Spanish texts (declared as `replaces:` L4-L8), and 5 tests that fail the same on main in this worktree (L9).

## Next
1. Mutation: `sh D:/Temp/w/herramientas/eng18-mutate-all.sh D:/Temp/w/herramientas/eng20-mutate-list.txt` (log `/tmp/eng20-mut.log`). Text-only files exit 3 (no operator applies): declare each in the Log as ENG-18 L92-L96 did. `availability/rules.py` went over the 10-minute budget against the whole suite: map it in the script to `tests/unit/test_horarios.py tests/unit/test_contract_values_edges.py`.
2. Gate: `node .claude/tools/verify.mjs`. Open items from the last run:
   - `attacks:` could not run (app did not answer): check `arq01-app.sh eng20_app` starts.
   - `no-visual:` fails because `password_recovery/routes.py` changes `<html lang="es">` to `en` on the recover-link page. That page's text is in scope (S1/S2 reading); decide: keep `no-visual` with a Log `declared` line, or turn the lens on (costly).
   - `required:` K4 duplication between `tests/escenarios/test_recordatorio.py:95-109` and `tests/escenarios/test_reservar.py`: Log `declared · K4 · <file> · <why>` or extract.
   - `layers:` SQL outside a data file in e2e_support.py, deactivation.py, registration.py, shared/email.py: they are now `(data)` in T5; rerun.
   - add `--deselect` of the 5 tests of L9 to `suite:` if verify does not accept the declared line.
3. `/close`: `node .claude/tools/close.mjs`, then branch, PR (Spanish), CI, merge. Push was refused by the publish hook until `required.mjs` exits 0.
