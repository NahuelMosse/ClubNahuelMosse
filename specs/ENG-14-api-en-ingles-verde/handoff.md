# Handoff ENG-14 (builder, T1)

Worktree D:/Temp/w/ingles-api, branch `ingles-api`. Never push/PR/touch main. Env: UV_PROJECT_ENVIRONMENT=".../app-tp/apps/api/.venv", FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099. Run from the worktree root: `sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider --tb=line <files relative to apps/api>` (one run at a time, shared DB; full suite ~14 min, run in background to D:/Temp/w/full.log and `node .claude/tools/wait.mjs`). Compare with main by running the same file from D:/Temp/w/main.

## Done (committed)
- Merge of origin/main finished (commit "Merge origin/main en ingles-api"); 6 main tests + test_integraciones_documentadas + test_readme_conciso pass; docs/technical/integraciones.md paths in English.
- RED file apps/api/tests/unit/test_api_en_ingles_verde.py committed (S1, S2; both pass).
- Test doubles fixed to `DeliveryResult(sent=, invalid=)`, `.data`, `.starts_at`; ruff import order fixed; apps/api/README.md variable table uses English names (with Spanish alias); test_requisitos_no_funcionales expects PUBLIC_URL.

## Left
Full suite last run: 35 failed. Several fixed since (notification 'fallida' group, limpia_reservas, requisitos_no_funcionales, ruff I001, stray modules/notificaciones dir removed). Re-run full suite, then:
1. Fail on main too, name each in `## Log` with its main run (Edit only): test_capas_funcionalidades::test_la_anticipacion_sale..., test_repositorios_propios::test_el_recordatorio_sale_una_hora_antes (ANTICIPACION monkeypatch), test_mapa_por_funcionalidad (2), test_suite_confiable (3 on main; check the `_reemplazos` ones and test_codigo_legible 40 lines on main too: compare which function).
2. Pass on main, must pass here: contract tests (test_seguridad_api::test_el_contrato_versionado_coincide_con_la_api, test_api_limpia_funcionalidades, test_base_en_ingles, test_modulos_cuenta_en_ingles contract, test_modulos_espacios_en_ingles contract, test_api_en_ingles contract at 1ee70de: GET /notifications... differs because main moved past 1ee70de with new fields). Regenerate/commit apps/api/openapi.json for the English app and make the ENG-13 reference tests compare with current main (replace per builder rules: new file, same tag, Log `replaces:` line) if they pin the old commit.
3. test_modulos_cuenta_en_ingles: expects password_recovery modules list incl. `email` but flags `modules\password_recovery\email.py` (language check of comments/names): fix its Spanish names/comments.
4. test_documentacion_supuestos_vigente:142 (ASVS evidence paths with old names in docs/asvs matrix: update paths), test_notificaciones_api::test_el_aviso_guarda..., test_despacho_robusto/test_cancelacion_forzosa_* (re-check after DeliveryResult fix), test_codigo_legible ruff + 40 lines, test_mapa_por_funcionalidad (check English map doc).
5. Gate `node .claude/tools/verify.mjs`, then close; Log lines `- L<n> · <date> · T1 · ...` and the main-fails list via Edit only.
