# Handoff ENG-08 (post merge de origin/main 1ee70de)

Hecho: merge commiteado (1d4f5ba) con VIS-01/NOT-03/SES-01 y nombres en inglés (lib/common/loading_screen.dart `LoadingScreen`, `LogoMark(color:)` + `LogoMarkPainter`); glosario actualizado; tests nuevos de main con imports/símbolos migrados; analyze limpio. Fix posterior: base_en_ingles_test (ASM-05 compara contra 1ee70de; 'Las','Aviso' en app.dart).

Gate (verify.mjs, log /tmp/eng08gate.log): fmt, lint, specs, overdesign, migrations passed. Falla:
- suite: 26 -> 24 preexistentes de L9 + 2 de base_en_ingles (arreglados, sin re-correr).
- captures: ShaderCompilerException (entorno).
- K4 (43 clones de archivos renombrados, parecen "nuevos"), layers/shape/boundaries (carpeta common/), attacks, mutation registration_rules, linter test_correo_brevo.py (API de MAIL-01): declarar en Log o resolver.
- close --check punto 6: faltan en ## Tasks los archivos de lib/ (admin, common, inicio, notificaciones, reservas, sedes, sesion, usuarios, theme, rutas.dart), integration_test, tool/generar_isotipo_test.dart, android/ y assets/icono (VIS-01), apps/api correo.py/config.py (MAIL-01). Agregarlos con Edit a la línea T1 (o globs si plan.mjs los acepta).
