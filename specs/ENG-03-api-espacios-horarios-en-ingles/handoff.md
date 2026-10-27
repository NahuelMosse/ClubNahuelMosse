# Handoff ENG-03 (builder 1 stopped at the context cap; nothing written or committed yet)

## Done
Only reading. No file edited, no commit, card.md untouched.

## Read and learned (do not re-read the 11 module files unless writing them)
Modules: `apps/api/app/modules/espacios/{__init__,casos_de_uso,reglas,repositorio,rutas}.py` and
`horarios/{__init__,casos_de_uso,disponibilidad,reglas,repositorio,rutas}.py`.
Model test to copy: `apps/api/tests/unit/test_base_en_ingles.py` (uses `_castellano()`, `_nombres_definidos`, `_textos_de_prosa`,
`PALABRAS_COMUNES`, `EXTRA_CASTELLANO`, glossary words via `tests.unit.test_glosario_ingles`). The new test
`apps/api/tests/unit/test_modulos_espacios_en_ingles.py` has 3 tests with the titles/tags in card.md T1 (S1 files exist / old dirs gone;
S2 names+prose English over the 11 new files, with EXTRA words such as `agenda franja grilla disponibilidad horarios espacios tipo clave tipos
deporte deportes apertura cierre dias altura calle`; S3 openapi from `create_app()` equals main's (git `show main:apps/api/openapi.json` is not
available in a test: compare against a stored copy of paths/methods/codes/fields/operationId/params/security with schema names normalised, or
compare `openapi.json` committed vs regenerated after the rename: paths+methods+operationId+parameters+security+response codes+field names per
operation must equal the pre-rename snapshot; easiest: snapshot the CURRENT openapi.json (pre-rename) into the test as a normalised JSON
fixture `apps/api/tests/unit/` is not allowed to be bigger than needed, so compute the normalised form from a hardcoded dict of
`{(path, method): operationId}` plus parameters/security derived by resolving `$ref`s and replacing schema names by their property-name sets).
Pydantic view classes' fields are Spanish JSON keys: the S2 test must skip AnnAssign fields of `BaseModel` subclasses in `routes.py`.

## Rules from the caller (add each as ASM in `## Specs` with its planned test, via Edit, before RED; CRLF: never shell-write card.md)
- ASM-05 Pydantic field names stay Spanish (JSON keys / validation `loc`), class names English, no alias -> test S3 (+ S2 skip).
- ASM-06 `scripts/e2e.sh` and `app/e2e_support.py` change only the module paths they import -> S1.
- ASM-07 S3 test also compares parameters and `security` per operation -> S3.
- ASM-08 docs naming these paths updated (`docs/technical/mapa-del-codigo.md`, `apps/api/README.md`, anything a doc test reads) -> S1.
- ASM-09 explicit `operation_id` stays on every route so operationIds do not change (routes currently have no explicit operation_id: the
  default id is derived from the function name + path, so renaming functions CHANGES operationIds -> set `operation_id="<old function name>_<old path>"`
  exactly as FastAPI generated it, read from openapi.json) -> S3.
- Catalog keys (Futbol, F5, ...) are data; route paths, SQL, user texts, `tags=["espacios"|"horarios"]` unchanged.

## Planned rename map (apply with a grunt; `git mv` files)
Files: espacios->spaces, horarios->availability; casos_de_uso->use_cases, reglas->rules, repositorio->repository, rutas->routes,
disponibilidad->slots (this file holds the "available spaces" query: `canchas_disponibles`).
Symbols (glossary + ASM-04 new ones, add the new ones to `docs/technical/glosario-ingles.md` "Clases y funciones principales"):
- spaces: `CATALOGO`->`CATALOG`, `Deporte`->`Sport`, `Tipo`->`Kind` (fields `clave`->`key`, `nombre`->`name`, `tipos`->`kinds`), `Espacio`->`Space`,
  `EspacioNuevo`->`NewSpace`, `DatosEspacio`->`SpaceData`, `CambioDeEspacio`->`SpaceChange`, `NombreSugerido`->`SuggestedName`,
  `SedeDelEspacio`->`SpaceVenue`, `Espacios`(Protocol)->`Spaces`, `EspaciosSql`->`SpacesSql`, `repositorio_espacios`->`spaces_repository`,
  `espacio_de_fila`->`space_of_row`, `COLUMNAS_DE_ESPACIO`->`SPACE_COLUMNS`, `parte_de_sede`->`venue_part`, `parte_de_calle`->`street_part`,
  `nombre_compuesto`->`composite_name`, `tipo_del_catalogo`->`catalog_kind`, `validar_espacio`->`validate_space`, `validar_cambio`->`validate_change`,
  use cases `catalogo`->`catalog`, `nombre_sugerido`->`suggested_name`, `dar_de_alta_espacio`->`create_space`, `espacios_activos`->`active_spaces`,
  `editar_espacio`->`update_space`, `dar_de_baja_espacio`->`deactivate_space`; repo methods `activos`->`active`, `siguiente`->`next_number`,
  `insertar`->`insert`, `actualizar`->`update`, `dar_de_baja`->`deactivate`, `dar_de_baja_de_sede`->`deactivate_venue_spaces`;
  domain field names English (`sede_id`->`venue_id`, `sede`->`venue`, `deporte`->`sport`, `tipo`->`kind`, `numero`->`number`, `techada`->`covered`,
  `iluminada`->`lit`, `precio_por_hora`->`price_per_hour`, `nombre`->`name`, `altura`->`street_number`, `calle`->`street`); SQL row attributes
  (`fila.sede_id`, `fila.techada`...) stay Spanish (columns unchanged); validation error dict KEYS stay Spanish (they are JSON keys).
  `ListaDeEspacios`->`SpaceList`, `EspacioVista`->`SpaceView`, `TipoVista`->`KindView`, `DeporteVista`->`SportView`, `Catalogo`->`CatalogView`,
  `Sugerencia`->`Suggestion`, `Errores`->`ErrorBody`, `PedidoDeEspacio`->`SpaceRequest`, `PedidoDeCambioDeEspacio`->`SpaceChangeRequest`,
  `vista_de_espacio`->`space_view`; route functions `ver_catalogo`->`show_catalog`, `listar_espacios`->`list_spaces`, `sugerir_nombre`->`suggest_name`,
  `alta_de_espacio`->`create_space_route`... (keep operation_id explicit, ASM-09). Pydantic views must be built explicitly (Spanish fields from
  English dataclass attrs), not `model_validate(..., from_attributes=True)`.
- availability: `Agenda`->`OpeningHours` (`apertura`->`opens_at`, `cierre`->`closes_at`, `dias`->`open_days`), `Franja`->`Slot`, `Grilla`->`SlotGrid`
  (`fecha`->`date`, `hoy`->`today`, `abre`->`opens`, `franjas`->`slots`, `no_disponibles`->`unavailable`), `Horarios`(Protocol)->`Availability`,
  `Disponibilidad`->`SlotSearch`(new), `HorariosSql`->`AvailabilitySql`, `agenda_de_fila`->`opening_hours_of_row`, `repositorio_horarios`->
  `availability_repository`, `horarios_disponibles`->`available_slots`, `canchas_disponibles`->`available_spaces`, `validar_consulta`->`validate_query`,
  `validar_rango`->`validate_range`, `validar_reserva`->`validate_booking`, `rango`->`time_range`, `grilla`->`slot_grid`,
  `error_de_duracion`->`duration_error`, `DIAS_A_LA_VISTA`->`DAYS_IN_VIEW`, `MIN_HORAS/MAX_HORAS`->`MIN_HOURS/MAX_HOURS`, `HORAS_POR_DIA`->`HOURS_PER_DAY`,
  methods `agenda`->`opening_hours`, `agenda_de_sede`->`venue_opening_hours`, `ocupadas`->`taken`, `libres`->`free`.

## Outside imports to touch (import lines + the uses they force; tell the main thread: this exceeds "import lines only")
- `app/main.py:9` imports `espacios, horarios` (and `.router` uses).
- `sedes/repositorio.py:8,184` (`EspaciosSql().dar_de_baja_de_sede`), `sedes/reglas.py:7,84,94` (`parte_de_sede/calle`),
  `notificaciones/reglas.py:8,114-115` (`CATALOGO`, `d.clave`, `d.tipos`, `t.clave` -> `.key`, `.kinds`),
  `reservas/almacen.py:5`, `reservas/casos_de_uso.py:5` (+ uses of `DIAS_A_LA_VISTA`, `error_de_duracion`, `rango`, `validar_reserva`, type `Agenda`),
  `reservas/repositorio.py:11,145,196` (`Agenda`, `HorariosSql(...).agenda(`, `agenda_de_fila`).
  The reservas `agenda` method names/params belong to ENG-04: only change what comes from my module (`HorariosSql(...).agenda` -> `.opening_hours`).
- Tests (refactor-tests, imports/symbols only): `test_casos_de_uso_reservas.py` (Agenda kwargs line 41), `test_horarios.py`, `test_espacios.py`,
  `test_nombre_compuesto.py`, `test_api_limpia_reservas.py`, `test_sin_sobreingenieria.py:100`, `escenarios/test_modelo.py:130`,
  `escenarios/test_repositorios_propios.py:9,135-141`; also grep tests for `modules.espacios|modules.horarios` path strings read by doc/architecture tests
  (`test_capas_funcionalidades.py`, `test_arquitectura_funcionalidades.py`, `test_api_limpia_plan_funcionalidades.py`, `test_sin_sobreingenieria.py`).
- Also: `scripts/e2e.sh`, `app/e2e_support.py` (module paths only), `docs/technical/mapa-del-codigo.md`, `apps/api/README.md`.
- openapi.json: regenerate after the rename (`create_app().openapi()` dumped with `json.dumps(indent=2, ensure_ascii=False)+"\n"`, as the ENG-01 test does).

## Next steps
1. Edit card.md: ASM-05..09 with planned tests; fill `reuses:` already present. 2. Write the new test file (RED, fails: dirs still Spanish), commit it.
3. Delegate the mechanical rename to a `grunt` with the map above (git mv first). 4. Regenerate openapi.json, update glossary + docs.
5. Gate: `node .claude/tools/verify.mjs` (lines suite/fmt/lint/app/attacks in card.md; long ones in background with a log).
6. Log line `- L4 · 2026-10-27 · T1 · <evidence>` appended to card.md via Edit.

## Open decision for the main thread
The caller's rule "other modules change only import lines" collides with renaming dataclass attributes (`CATALOGO` fields `.clave/.tipos`, `HorariosSql.agenda`
method, `Agenda` kwargs in tests). Proposed: rename them and adjust the few forced uses (listed above), declared as ASM.
