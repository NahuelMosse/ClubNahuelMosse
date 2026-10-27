# ENG-01 handoff (2)

## Done
- RED committed (61d269b): apps/api/tests/unit/test_base_en_ingles.py, test_config_en_ingles.py (fail for the right reason).
- `git mv` of the 10 base files done (health, e2e_support, shared/{firebase_credential,body_limit,input_validation,errors,http_errors,identity,responses,club_timezone}); CONTENT NOT YET REWRITTEN (still Spanish, old imports).
- Two `grunt` agents were launched with `specs/ENG-01-api-base-en-ingles/rename-map.md` (exact map) over app/modules + migraciones/env.py and over tests/**. Check `git status`; they may still be running or done. They do NOT touch main.py, health.py, e2e_support.py, shared/**.

## Left
1. Rewrite whole (English names/comments/docstrings; texts, JSON keys, SQL unchanged, per the map): shared/{errors,club_timezone,responses,http_errors,firebase_credential,body_limit,input_validation,identity,db,config}.py, main.py (create_app, _lifespan, BodyLimit, input_validation.install, http_errors.install, config.reminders_every / e2e_testing), health.py (`vivo`->`alive`; keep `operation_id="vivo_health_get"` and `description="La API está viva; no mira la base ni Firebase."` explicit in the decorator), e2e_support.py (English names; wire names via Field(alias)+populate_by_name, dump by_alias; SQL and /_pruebas paths unchanged).
   Names: InvalidData.errors, Duplicate.fields, NumberTaken(next_number,name), BookingsOutsideHours.count; BodyLimit, LIMIT_BYTES, TIMEOUT_SECONDS; Identifier, parse_time, shape_errors, install; conflict; service_credential(content); CLUB_TIMEZONE(_NAME).
2. config.py: class Settings; fields with `validation_alias=AliasChoices(english, spanish)` (english first), `populate_by_name=True`; email_mode normalized "buzon"->"outbox" by a validator (Literal["outbox","smtp"] after normalization); e2e_testing from E2E_TESTING/PRUEBAS; defaults unchanged (email_mode "smtp", reminders_every 30). Instance `config` stays; API_ROOT, _PROJECT.
3. db.py: RETRY_WINDOW, _create_engine, _Engine/engine, connection, DbConnection, in_transaction, violated_constraint. identity.py: FirebaseProvider, identity(), identity_log (logger name string unchanged), _firebase_app, _TIMEOUT_S, _REJECTIONS, _sign_in_url, methods create_account/uid_of/delete_account/uid_from_token/password_matches/change_password(email,password,new_password).
4. Update docs/technical/glosario-ingles.md (new names, Config->Settings).
5. Run affected tests, then the gate; fix what the grunts left (grep old names, ruff, mypy).

## PITFALL
The PreToolUse hook refuses `Write` of production files in this worktree: it looks for the card in the MAIN repo (CLAUDE_PROJECT_DIR = app-tp, no specs/ENG-01 there) and says "missing ## Specs". Grunt Edits passed. Options: main thread places the card where the hook looks, or the files are written through a grunt.

## Env
UV_PROJECT_ENVIRONMENT="D:/desktop folders/estudio/Universidad de moron/Electiva general/app-tp/apps/api/.venv"; Postgres 127.0.0.1:8701; Auth emulator 127.0.0.1:9099. `git mv` can hit a transient index.lock while grunts run: retry.
