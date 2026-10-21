# Handoff — REV-07 · documentación de producción

- card: `specs/REV-07-documentacion-produccion/` · snapshot `proposed`
- branch: `card/REV-07`, worktree `D:/Temp/w/rev07` · base commit: `138bc54` · plan commit: `7dbf987` · tests-in-red commit: `7dbf987` (evento en `83b03a2`)
- grade: `production` · modules: `ui, api, data, infra, observability, security-l2` · lane: `normal`

## Groups, in order (from `plan.md` `## File map`)

1. `diseño del sistema y modelo de datos` — `docs/technical/system-design.md`, `docs/adr/0001-stack.md`, `docs/adr/0002-hosting-en-render.md` — tests: `@REV-07-H21-02`, `@REV-07-H21-03`, `@REV-07-H21-08`, `@REV-07-H21-09`
2. `seguridad` — `specs/asvs.md` — tests: `@REV-07-H21-01`
3. `licencias` — `scripts/avisos_de_terceros.py`, `THIRD_PARTY_NOTICES.md`, `apps/mobile/assets/fuentes/OFL.txt` — tests: `@REV-07-H21-04`, `@REV-07-H25-01`
4. `operación y README` — `docs/technical/infra-cost.md`, `docs/technical/runbook.md`, `docs/business/accessibility.md`, `README.md`, `apps/api/README.md`, `apps/mobile/README.md` — tests: `@REV-07-H21-05`, `@REV-07-H21-06`, `@REV-07-H21-07`, `@REV-07-H22-01`

Escenarios: `apps/api/tests/escenarios/test_documentacion.py`. Plantillas: `.claude/templates/{system-design,adr,asvs-level-1,asvs-level-2,infra-cost,runbook,accessibility-statement}.md`.

## Decided

- RFZ: none
- ASM open: REV-07-ASM-01 a ASM-08, en `plan.md`; ASM-01 es `any-answer: no`; OUT-01 y OUT-02 en `ambiguities.md`
- app: none · seed: none

## Already ran

- `pytest tests/escenarios/test_documentacion.py` sobre `7dbf987` → failed (11 de 11, los documentos no existen) · `D:/Temp/rojo-rev07.log`
- RED-REVIEW → hallazgos M y L corregidos en una ronda · `specs/REV-07-documentacion-produccion/red-review.md`
- Precios de Render, de https://render.com/pricing.md consultado el 2026-10-20: web 0.5c-512mb USD 7/mes, 1c-2g USD 25/mes; Postgres 0.1c-256mb USD 6/mes, 0.5c-1g USD 19/mes, almacenamiento USD 0,30/GB (1 GB incluido); cron USD 0,00016/min; backups lógicos en instancias pagas y PITR 3 días (Hobby) o 7 (Pro); la base free vence a los 30 días con 14 de gracia (dicho en `apps/api/README.md` y en la doc de Render). La página no dice si la base free tiene backups.

## Decisions of the main thread not written elsewhere

- Cada afirmación de un documento sale del código de `kit-3` o de `specs/REVISION-kit3.md`, con su archivo:línea, test o comando; lo que no se verificó dice `not verified`. Timeouts y reintentos reales: SMTP `timeout=10`, firebase-admin `httpTimeout=4`, el cliente de la app corta a 15 s; la base no tiene `connect_timeout` (hallazgo 2, lo corrige REV-02): se escribe así.
- La ASVS describe `kit-3`: lo que hoy falla y corrigen REV-01 a REV-06 queda `fails` con el hallazgo y la card. Al integrar esas cards se actualizan las filas (REV-07-ASM-05); no lo hagas acá.
- Los supuestos de los README salen de los `ambiguedades.md` de cada card vieja (`specs/*/ambiguedades.md`) con su ID real; el test compara contra los IDs registrados en `specs/`.
- Dueño y fecha de revisión del runbook, y los plazos de remediación de V15.1.1, los decide una persona: quedan como pendientes de una persona, sin inventarlos.
- Los hooks del kit ubican la card por las rutas absolutas del prompt y no reconocen rutas entre backticks: en cada prompt a un subagente poné al menos una vez la ruta plana, precedida de un espacio (por ejemplo D:/Temp/w/rev07/specs/REV-07-documentacion-produccion/plan.md ); en shell, `cd /d/Temp/w/rev07 && ...`.
- Los comandos de test llevan `TEST_DATABASE_URL="postgresql+psycopg://club:club@127.0.0.1:8703/club_rev07_test"`. No se pushea, no se abre PR, no se mergea: publicar queda «no se pudo correr».
