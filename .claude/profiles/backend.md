# Profile: backend

HTTP services and stored data. The base method does not name HTTP; this profile brings the instruments.

## What it brings
- Modules: `api`, `data`, `observability`, `infra`; `security-l2` stays opt-in (decided by R10).
- Tools: `attack.mjs`, `migrations`, `migrate-upgrade`.
- `reference/http-defaults.md`: the default answer to each question an HTTP card leaves open, assumed as an `ASM` with its test.

## Gate lines it uses
`attacks:`, `--common-headers`, `--unique`, `--fault-db`, `--openapi`, `--search`, `migrate-upgrade:`. The `contract` and `integrity` lenses need it.

## How to turn it on
- `node .claude/tools/install.mjs --profiles backend` at install (without the flag, signals suggest it).
- `node .claude/tools/kit.mjs profile on backend --reason "..."` afterwards; `profile off backend --reason "..."` removes it.
- With it off, a `contract` or `integrity` card lists `lensesOff` in `risk.json` and the close puts it under `## Could not run`.
