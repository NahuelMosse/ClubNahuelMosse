# Handoff ENG-13 (builder 3)

Worktree D:/Temp/w/ingles, branch `ingles`. Never push, never PR, never touch main. Gate env: export
`UV_PROJECT_ENVIRONMENT="D:/desktop folders/estudio/Universidad de moron/Electiva general/app-tp/apps/api/.venv"`
and `FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099`; Postgres 127.0.0.1:8701. Use `git -C <root>`.
Shell redirections/sed on app/ are blocked: use Edit/Write or a `grunt` (give it exact edits). Context cap: delegate mechanical work.

## Done
- RED test `apps/api/tests/unit/test_api_en_ingles.py`; ENG-00..ENG-05 merged and committed.
- `git merge origin/main` (MAIL-02) IN PROGRESS (conflict resolved in tree; commit it if not yet committed: `git status`, then `git commit` with message `ENG-13: merge origin/main (MAIL-02) in English`):
  - Spanish files removed; English ones written: app/shared/{email.py,message.py,email_template.py} (html_email), modules/bookings/email.py (booking_email), notifications/rules.py `reminder_email` + `Reminder.email/.name`, use_cases `_notify_by_email`, `short_kind` exported by notifications, password_recovery html body, bookings routes `create_booking` sends via BackgroundTasks `after`, password_recovery/email.py deleted (routes import app.shared.email.send), repository.py conflict resolved (`email=row.correo, name=row.nombre_usuario`), specs/.current = ENG-13-api-en-ingles.
  - Tests ported by a grunt: tests/unit/test_emails_with_design.py, test_email_template.py, test_brevo_email.py (old Spanish files git rm'd); pyproject per-file ignore renamed. Check the grunt finished: `git status`, then run those 3 tests.

## Not done (in order)
1. Confirm the merge is committed; run ruff check/format app tests, mypy; run the 3 ported tests.
2. Log (Edit on card.md ## Log, append only): `- L<n> · <date> · replaces: apps/api/tests/unit/test_correo_brevo.py "<each test title>" · module/names renamed to English · by: tests/unit/test_brevo_email.py "<title>"`; same for test_correos_con_diseno.py and test_plantilla_correo.py (MAIL-02, merged from main).
3. seed_admin (app/modules/users/seed_admin.py line ~36): read `ADMIN_PASSWORD` then `ADMIN_CONTRASENA` (S3 test in test_api_en_ingles.py); update docstring, .env.example, apps/api/README.md mentions. scripts/e2e.sh: grep showed no `sembrar_admin` left; verify.
4. Docs: docs/technical/system-design.md (lines ~128 `recuperacion/correo.py` -> `shared/email.py`; ~150 `modules/recuperacion/casos_de_uso.py` -> `modules/password_recovery/use_cases.py`; ~212 `modules/usuarios/baja.py` -> `modules/users/...`), arquitectura.md line ~136 `modules/sesion/usuario_actual.py` -> `modules/session/...`; add glossary entries to docs/technical/glosario-ingles.md (shared/correo.py->email.py, mensaje->message, plantilla_correo->email_template `html_de_correo->html_email`, reservas/correo.py->bookings/email.py `correo_de_reserva->booking_email`, `tipo_corto->short_kind`, `correo_recordatorio->reminder_email`, Message fields para/asunto/cuerpo -> recipient/subject/body); docs feature page for MAIL-02 if one exists in docs/features names old modules.
5. Log ENG-13-ASM-05: METRICS_TOKEN/BEHIND_PROXY/INTERACTIVE_DOCS no longer exist in main (test_sin_sobreingenieria asserts removal) -> the English config does not carry them; record with that test title or declare.
6. Regenerate apps/api/openapi.json; full suite in background to a log, read only failing lines; compare failures against D:/Temp/w/main; then `node .claude/tools/verify.mjs`; Log line `- L<n> · <date> · T1 · <evidence>`.
7. Commit per step (`ENG-13: ...`, trailer `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`); never push.
