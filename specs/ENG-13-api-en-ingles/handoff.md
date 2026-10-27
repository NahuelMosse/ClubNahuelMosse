# Handoff ENG-13 API (builder 4)

Worktree D:/Temp/w/ingles-api, branch `ingles-api`. Never push/PR/touch main or `ingles`. Env: export
`UV_PROJECT_ENVIRONMENT="D:/desktop folders/estudio/Universidad de moron/Electiva general/app-tp/apps/api/.venv"`,
`FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099`, `PG_PUERTO=8701`. Hook blocks a bare whole-suite run in a subagent: use
`node .claude/tools/verify.mjs > /tmp/x.log` in background (26 min) or bounded pytest on files
(`cd apps/api; uv run --no-sync pytest -q -p no:cacheprovider --tb=line <files>`).

## Done (committed up to 3414fb5 + "test_correo sobre shared.email")
- Merge of main committed; seed_admin reads ADMIN_PASSWORD then ADMIN_CONTRASENA; .env.example, README, docs/technical (system-design, arquitectura), glossary rows (email/message/email_template/booking_email/short_kind/reminder_email/Message fields); Log L5-L9 (replaces x3, ASM-05, seed_admin).
- openapi.json regenerated: same paths/methods/responses/params as 1ee70de, only schema names differ.
- mypy clean (fixed `profile.rol`->`role` in notifications/use_cases.py); ruff format on app clean; test_correo.py ported to app.shared.email/Message; test_basquet_3x3 and test_horarios lint fixed.

## Open: last verify (/tmp/ingles-api-verify2.log): 36 failed, 684 passed. Failures seen, with cause
1. Tests still importing old paths: tests/unit/test_config_en_ingles.py:82 `from app.modules.password_recovery import email` (-> `app.shared.email`, Message in `app.shared.message`); same check any other test importing `password_recovery.email` / `password_recovery.rules.Message`.
2. tests/unit/test_mapa_por_funcionalidad.py: docs/technical/mapa-del-codigo.md lists `password_recovery/email.py` (gone) and lacks new files (bookings/email.py, shared/email.py, message.py, email_template.py); update the map.
3. test_glosario_ingles.py / test_glosario_ingles_completo.py: glossary parse complains about `Errors` term joining (section 'Clases y ...'); my 3 new glossary rows may duplicate a term or join two terms in one name: check the failing assert, adjust rows.
4. test_sin_supresiones.py / test_capas_funcionalidades.py::test_no_queda_una_supresion_de_tipos: tests/unit/test_brevo_email.py has `# type: ignore[arg-type]` (ported file); remove it (cast/Any).
5. test_codigo_legible.py:122 `assert 3 > 10` (public signatures of use cases and repositories vs main: probably counts functions in modules renamed; inspect) and test_api_limpia_funcionalidades.py:42 `assert []` (route-handler scan; inspect, likely module path list needs bookings/email or password_recovery changes).
6. Not yet diagnosed (run per file, compare with `D:/Temp/w/main` same test): escenarios/test_cancelacion_forzosa*.py, test_confirmacion_cancelacion_reglas, test_despacho_robusto, integracion/test_api_limpia_reservas, test_notificaciones_api (likely the MAIL-02 `_notify_by_email`/Reminder `.email` rename or `rol`-like attribute left; check tracebacks), escenarios/test_suite_confiable*.py (test names/paths of reservas module -> bookings), test_documentacion*.py and test_requisitos_no_funcionales (README/docs paths), test_modulos_cuenta_en_ingles + test_base_en_ingles (contract/glosario main comparison: maybe my regenerated openapi or glossary).
Fix those failing only here; rerun the files; then verify again.

## Gate lines (last run)
passed: attacks, fmt, specs, migrations, boundaries. failed: lint (that line runs flutter analyze: 20799 issues, mobile side, not API), suite (above), layers/shape/overdesign (`repository.py` names not recognised as data files, availability/rules.py, notifications/push.py, session/use_cases.py class+functions, users/registration UserRepository: same code as main, only renamed; need `declared · ...` Log lines or card marks), rounds/dead-clicks/copy/axe/contrast/focus (visual lens, no look in a rename card), required (T1 does not list renamed files/pyproject/.env.example; K4 duplications in renamed tests; I-tokens on email_template).
Those structural lines need a decision from the card owner (declare in Log or enumerate files in T1).
