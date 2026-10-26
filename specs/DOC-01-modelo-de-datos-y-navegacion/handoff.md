# Handoff DOC-01

Worktree D:/Temp/w/doc01 (branch card/DOC-01). Commands run from the worktree root.

## Done
- RED tests written and committed (pages still untracked, not committed):
  - apps/api/tests/unit/test_documentacion_del_modelo.py (8 tests: tables/columns, explained tables, states, system-design trim, routes x2, copiar.mjs)
  - apps/mobile/test/navegacion_documentada_test.dart (parses the route table of the page; mounts App with no session / usuario / admin per route)
- `uv sync` in apps/api was launched in the background (the fresh worktree had an empty .venv; arq01-pytest.sh needs it). Check `apps/api/.venv` has psycopg before running pytest.

## Left
1. Run `sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_documentacion_del_modelo.py` (from worktree root); fix the two pages (docs/technical/modelo-de-datos.md, navegacion-de-la-app.md) where tests find gaps. Known: intro says "Nada se borra" but trigger only on usuario, sede, espacio, reserva: make precise (also bullet in "Bajas lógicas"). Navigation doc has a "No verificado" section: resolve or drop.
2. Run the dart test: `cd apps/mobile && D:/projects/flutter/bin/flutter pub get && D:/projects/flutter/bin/flutter test test/navegacion_documentada_test.dart`; its regex for rows may need adjustment (4-column table: ruta, pantalla, quién, qué muestra).
3. Commit the two pages.
4. system-design.md `## Data` (line ~49 up to `## ` next): reduce to one paragraph linking to modelo-de-datos.md, no `|` tables, <120 words (test asserts). CONFLICT: tests/escenarios/test_documentacion_supuestos_vigente.py (REV-07-S8, lines ~60-100: Data section needs index/trigger/PK words, each table `### ...\`tabla\`` heading with every column) reads the Data section of system-design.md; they must be retargeted to modelo-de-datos.md (committed tagged tests are guarded: write replacements in a new file with same tags and log `replaces:` in card ## Log; if guard blocks, report to main thread). The new page would need an "Índices" mention and headings with backticked table names for those. Also check tests/unit/test_sin_sobreingenieria.py (doc word bans) and test_documentacion_vigente.py still pass.
5. sitio-docs/scripts/copiar.mjs: add `['docs/technical/modelo-de-datos.md','tecnica/modelo-de-datos.md',2]` and navegacion-de-la-app (3), renumber system-design 4, runbook 5, infra-cost 6; skip a missing source with a warning (`existsSync(join(repo, origen))` literal is asserted by the test). `paginas.length` message and `porOrigen` must use only the existing ones.
6. Gate lines: pytest line above plus `tests/escenarios/test_documentacion_vigente.py tests/unit/test_mapa_por_funcionalidad.py`; lint `sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh` (ruff line-length: the long test titles may need `# noqa: E501` or fmt, check).
7. Append Log lines L2.. to card.md (T1,T2,T3 evidence), card.md `reuses:` for T3 exists. Commit; report.
