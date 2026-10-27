# Handoff ENG-13 (builder 2)

Worktree D:/Temp/w/ingles, branch `ingles`. Never push, never PR, never touch main. Gate env: export
`UV_PROJECT_ENVIRONMENT="D:/desktop folders/estudio/Universidad de moron/Electiva general/app-tp/apps/api/.venv"`
and `FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099`; Postgres 127.0.0.1:8701. Use `git -C <root>`.
`sed -i` on app/ is blocked: Edit/Write or a `grunt` (Edit replace_all). Context cap: delegate mechanical renames to grunts.

## Done
- RED test `apps/api/tests/unit/test_api_en_ingles.py` (S1-S4, ASM-04). Merged ENG-00..ENG-04 (committed). ENG-03 leftover imports fixed and committed.
- ENG-04 merge: resolved by taking ENG-04 files + English names for the other modules (committed).
- ENG-05 merge COMMITTED (643c316): bookings module imports English module names, main.py ok (`import app.main` works, ruff check app clean). openapi.json is the "ours" copy: regenerate at the end. Unrun: nothing of tests (no suite run since ENG-03).
- Known leftovers: `tests/unit/test_correo_brevo.py` (@MAIL-01, frozen) still uses `modules.recuperacion`, `Mensaje`, `config.correo_modo` (replace it by a new file with the same tag, log `replaces:`); docs/technical/system-design.md (3) and arquitectura.md (1) still mention `modules/recuperacion|usuarios|sesion`; `test_modulos_espacios_en_ingles.py` names old modules on purpose.

## Left
1. (done) ENG-05 merge.
2. `git merge origin/main` (already fetched): MAIL-02 moved email into app/shared/correo.py, shared/mensaje.py, shared/plantilla_correo.py, reservas/correo.py (booking confirmation email), reminder email in notificaciones. Port to English: shared/email.py, shared/message.py, shared/email_template.py, bookings/email.py, notifications reminder email; add to docs/technical/glosario-ingles.md. password_recovery/email.py already has `_by_brevo`/`_SENDERS` from ENG-02: reconcile with main's shared mail code.
3. `scripts/e2e.sh` ~line 88: `app.modules.usuarios.sembrar_admin` -> `app.modules.users.seed_admin`; seed_admin reads ADMIN_PASSWORD then ADMIN_CONTRASENA (S3 test). Update README/docs mentions.
4. Log (Edit, card.md ## Log, append only): METRICS_TOKEN/BEHIND_PROXY/INTERACTIVE_DOCS no longer exist in main (test_sin_sobreingenieria asserts removal): record as ENG-13-ASM-05 with its test title, or declare.
5. Regenerate `apps/api/openapi.json`; `ruff format/check`, mypy; full suite in background with a log (read only failing lines); failures that also fail in D:/Temp/w/main go in the Log. Then the gate `node .claude/tools/verify.mjs`; Log line `- L<n> · <date> · T1 · <evidence>`.
6. Commit per step (`ENG-13: ...`, trailer `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`); never push.
