# ENG-04 handoff

RED committed (e0ce5ea): `apps/api/tests/unit/test_modulo_notificaciones_en_ingles.py` (3 tests; do not edit). card.md ASM-05..09 done.
Env: `export UV_PROJECT_ENVIRONMENT="D:/desktop folders/estudio/Universidad de moron/Electiva general/app-tp/apps/api/.venv"`; run from `apps/api` with `uv run --no-sync pytest -q -p no:cacheprovider <file>`; Postgres 127.0.0.1:8701, Auth emulator 127.0.0.1:9099. Long runs in background with a log and `node .claude/tools/wait.mjs <log> --until '^EXIT' --max 270`.

## Done (commit 388ffef, not pushed)
- `apps/api/app/modules/notificaciones` -> `notifications` (use_cases, rules, repository, routes, store, sweep, push), rewritten in English; DB values, SQL, log literals, JSON keys, `--una-vez` unchanged. Names follow the glossary (see `docs/technical/glosario-ingles.md`, rows added). Notice(title, body, data); Reminder(booking_id, user_id, starts_at, ends_at, sport, kind, venue); VoidedBooking(booking_id, starts_at, sport, kind, venue, reason); LostNotice(notification_id, kind); PendingNotice(notification_id, user_id, notice); DeliveryResult(sent, invalid); Notification(id, kind, title, body, booking_id, created_at, read); store methods due/register/tokens_with_permission/has_devices/fail_stranded/take_next/mark_delivery/deactivate_tokens/register_device/unregister_device/of_user/read/read_all; channel method `send(tokens, notice)`.
- routes: explicit `operation_id=` per route, `Path(alias="notificacion_id")`, `_view` maps explicitly; Pydantic fields Spanish.
- Importers updated: app/main.py, app/e2e_support.py, reservas/rutas.py, reservas/repositorio.py.
- 25 test files renamed by word map (script `tools_tmp/rename_tests.py`, untracked: delete it and `tools_tmp/dump_openapi.py` before closing), plus `test_arquitectura_funcionalidades.py` keys.
- Docs updated (mapa-del-codigo, README, system-design, runbook, arquitectura, glossary). `openapi.json` regenerated: only schema names changed, operationIds and path param unchanged.
- `ruff format` and `ruff check --select I --fix` run on app and tests.

## Left
1. Run `tests/unit tests/escenarios tests/integracion` (the previous run, /tmp/eng04_t.log, showed many F and E; read only failing lines). Likely causes: test fakes still reading Spanish attributes of renamed dataclasses (`.titulo/.cuerpo/.datos`, `aviso` param/kwarg, `reserva_id=`/`usuario_id=`/`inicio=`/`fin=`/`deporte=`/`tipo=`/`sede=`/`motivo=` kwargs for Reminder/VoidedBooking/LostNotice/PendingNotice, `DeliveryResult(enviados=, invalidos=)`, `Notification` attrs); `test_arquitectura_funcionalidades.py` and `test_capas_funcionalidades.py` hard-code Spanish file names (`casos_de_uso`, `reglas`, `repositorio`, `rutas`) for every feature incl. notifications; E errors may be the environment (check Postgres/emulator up before blaming code). Fix imports/symbols/paths only in tests.
2. New test `tests/unit/test_modulo_notificaciones_en_ingles.py` must pass (also check Spanish words `de|la|el|los|las|que|por|para|con|una|del|sin|cuando|si` in comments and docstrings of the module).
3. `node .claude/tools/affected.mjs <files>`, `ruff format`, commit in Spanish ending with `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.
4. Remaining mentions of the old module path: `docs/technical/*` and `specs/asvs.md`/ARQ-04 card are historical or other cards (leave); `docs/guia-basica.md:74` names the Dart folder (leave).
5. card.md `## Log` line `- L<n> · <date> · T1 · <evidence>` via Edit (never touch L1), then the gate `node .claude/tools/verify.mjs` (background log + wait.mjs).
