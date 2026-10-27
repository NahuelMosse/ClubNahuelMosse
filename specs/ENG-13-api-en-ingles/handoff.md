# Handoff ENG-13 (builder 1)

Worktree D:/Temp/w/ingles, branch `ingles`. Never push, never PR, never touch main. Gate env: export
`UV_PROJECT_ENVIRONMENT="D:/desktop folders/estudio/Universidad de moron/Electiva general/app-tp/apps/api/.venv"`
and `FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099`; Postgres 127.0.0.1:8701. Use `git -C <root>` (compound `cd && git` calls were refused by the context cap hook).
`sed -i` on app/ is blocked by a hook: use Edit/Write, or a `grunt` (Edit replace_all).

## Done (committed)
- RED `apps/api/tests/unit/test_api_en_ingles.py` (f7592ce): S1 (module folders/file stems), S2 (openapi vs `git show 1ee70de:apps/api/openapi.json`, schema names ignored), S3 (`Settings` class, AliasChoices pairs, brevo/buzon, ADMIN_PASSWORD via `app.modules.users.seed_admin.main` + its module-level `engine`), S4 (git merge-base), ASM-04 (e2e.sh text). It imports `Settings` from app.shared.config (exists since ENG-01 merge).
- Merged in order, conflicts resolved: ENG-00, ENG-01 (config.py = Settings with `email_mode` outbox|smtp|brevo, `brevo_api_key`; `buzon` accepted), ENG-02 (recuperacion/correo.py deleted; brevo ported into `password_recovery/email.py` as `_by_brevo`, `_SENDERS` dict), ENG-03 (merge commit made with leftovers below).
- specs/.current kept as ENG-13-api-en-ingles at each merge (`git checkout --ours specs/.current`).

## Left
1. FIRST (ENG-03 leftovers, not yet applied): in `apps/api/app/modules/spaces/routes.py`, `spaces/use_cases.py`, `availability/routes.py` replace `app.modules.sesion`->`app.modules.session`, `Perfil`->`Profile`, `SinSesion`->`NoSession`, `usuario_actual`->`current_user`, and `profile.rol`->`profile.role` (use_cases.py:78); keep isort order. Check no other file still imports Spanish module names: `grep -rnE "app\.modules\.(sedes|usuarios|sesion|recuperacion|espacios|horarios)" apps/api` (app and tests).
2. `apps/api/openapi.json` was resolved with "ours" at the ENG-03 merge: regenerate at the end (look at how ENG-05 handoff did it / the repo's generator) and make sure operation_ids stay (explicit `operation_id=` in routes; S2 test compares against 1ee70de).
3. Merge ENG-04-api-notificaciones-en-ingles then ENG-05-api-reservas-en-ingles (`git merge --no-edit <branch>`); expect modify/delete conflicts (old Spanish files modified by main-side renames: accept the deletion with `git rm`, port the HEAD-side import changes into the new English files), conflicts in main.py (routers), tests test_arquitectura_funcionalidades / test_capas_funcionalidades / test_sin_sobreingenieria, docs/technical/mapa-del-codigo.md. Keep `specs/.current` = ENG-13-api-en-ingles. Read each branch's handoff (`git show <branch>:specs/<card>/handoff.md`) for rename maps. Old module `notificaciones` -> `notifications`, `reservas` -> `bookings` (ENG-05 uses explicit operation_id).
4. `scripts/e2e.sh` line ~88: `app.modules.usuarios.sembrar_admin` -> `app.modules.users.seed_admin` (same options; `--correo "$ADMIN_CORREO"`). `seed_admin.py` (users module) must read `ADMIN_PASSWORD` first, then `ADMIN_CONTRASENA` (S3 test). README/docs mention of the module command: update (`apps/api/README.md`, docs/technical/*).
5. S3 note: S3 lists METRICS_TOKEN/BEHIND_PROXY/INTERACTIVE_DOCS but main retired those variables (test_sin_sobreingenieria asserts they are gone); they are not config fields. Log it in card.md `## Log` as `OUT`/ASM-style note instead of re-adding.
6. Update `render.yaml` only if it names renamed modules (it should not). Keep Brevo behavior from main.
7. Run `uv run --no-sync ruff format apps/api/app` + `ruff check`/mypy; full unit suite in background to a log (read only failing lines); compare failures with D:/Temp/w/main (known failures on main are logged, not weakened). Then the gate `node .claude/tools/verify.mjs`; add Log lines (`- L5 · <date> · T1 · <evidence>`, via Edit) in card.md. Update `docs/technical/glosario-ingles.md` + mapa-del-codigo if names changed.
8. Commit per step (`ENG-13: ...`, Co-Authored-By trailer as in the repo); never push.
