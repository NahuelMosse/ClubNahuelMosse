# Handoff ENG-14 (builder, T1)

Worktree D:/Temp/w/ingles-api, branch `ingles-api`. Never push/PR/touch main. Env: UV_PROJECT_ENVIRONMENT=".../app-tp/apps/api/.venv", FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099. Run files from the worktree root: `sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider --tb=line <files relative to apps/api>` in background to a log (one run at a time, shared DB).

## State: `git merge origin/main` IN PROGRESS, NOT COMMITTED (all staged with `git add -A specs apps`)
- Conflicts resolved: specs/.current = ENG-14-api-en-ingles-verde; specs/asvs.md (took main's lines, paths -> shared/email.py, modules/notifications/sweep.py); the four deleted-in-HEAD notificaciones files were removed.
- ENG-13 housekeeping commit already made before the merge ("riesgo y sesiones").
- Ported MAIL-02/03 + NOT-05 to English in apps/api/app/modules/notifications/: rules.py (ReminderKind, LEAD_TIME_BY_KIND, TITLE_BY_KIND, Recipient, Reminder.reminder_kind, NoticeKind has recordatorio_cinco), store.py (`recipient`), repository.py (`due` loops kinds via `_due_of`, `recipient`, ON CONFLICT DO NOTHING, IN ('recordatorio','recordatorio_cinco')), email.py (new, `notice_email`), use_cases.py (`_notify_by_email`, `deliver(..., recipient=None)`, send_reminders passes known Recipient). Not yet run.
- Migration 0011 came in as `apps/api/migraciones/versions/0011_recordatorio_cinco_minutos.py` (keep).
- Grunt agent a9f94e663a127372b was launched to port the 6 new main tests (unit/test_aviso_por_correo*.py, test_aviso_sin_correo.py, test_recordatorio_cinco.py, integracion/test_destinatario_del_aviso.py, test_recordatorio_cinco_base.py) to English app names and run them. Check its result before touching those files. If a guard refuses edits of those (tagged) tests, replace them per the builder rules.

## Left
1. Finish the merge commit (second -m with the why is required by the commit hook) once the grunt is green.
2. Also port two other new main tests: unit/test_integraciones_documentadas.py, unit/test_readme_conciso.py (check they pass; README merged has Spanish env var names, ENG-13 README test_requisitos_no_funcionales:323 expects names - compare with main).
3. Check apps/api/pyproject.toml merged per-file-ignores still valid (main added ignores for the two new test files by Spanish names; fine).
4. Write RED file apps/api/tests/unit/test_api_en_ingles_verde.py with exact titles from card.md T1 (S1: no Spanish imports/module paths in tests; S2: branch ingles-api not in main), commit it before more fixes.
5. Fix the 26 failures listed in specs/ENG-13-api-en-ingles/handoff.md, file by file, comparing each with D:/Temp/w/main (fix only what passes there). Behavior must equal main (ENG-14-ASM-01).
6. Gate `node .claude/tools/verify.mjs`, then `close.mjs`; log lines L<n> in card.md `## Log` via Edit only.
