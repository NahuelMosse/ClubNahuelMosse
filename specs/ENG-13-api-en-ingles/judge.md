- ACT-01 · M · S3 «cada variable» no nombra sus miembros ni los valores: render.yaml lee 13 claves (FIREBASE_CREDENCIALES_JSON, URL_PUBLICA, SMTP_PUERTO, SMTP_USUARIO, SMTP_CONTRASENA, CORREO_REMITENTE…), config suma PRUEBAS y RECORDATORIOS_CADA, y ADMIN_CONTRASENA se lee fuera de config (`usuarios/sembrar_admin.py`); no dice qué es «en inglés» para DATABASE_URL o BREVO_API_KEY ni si los valores `buzon`/`smtp`/`brevo` (que usan render.yaml y scripts/e2e.sh) siguen aceptándose · card.md S3 · lenses interpretation «Does a quantifier name its members, and does each member have a test?» · closed · S3
- ACT-02 · M · S1 renombra `usuarios` y sus archivos, pero `scripts/e2e.sh` corre `python -m app.modules.usuarios.sembrar_admin --correo` con `ADMIN_CONTRASENA`, `PRUEBAS=1` y `CORREO_MODO=buzon`; el script no está en `## Tasks` ni en un test, y el e2e deja de arrancar · card.md S1, T1 · lenses contract «Does an existing client keep working: which route, field or status of main changes?» · closed · ENG-13-ASM-04, T1
- ACT-03 · M · los tests de S2 y S4 comparan contra `main` sin fijar la referencia: si S2 compara con el `openapi.json` que T1 regenera es tautológico, y S4 «la rama ingles trae main» se vuelve falso en cuanto main avanza (suite roja sin cambio de código) y no corre donde no hay ref `main` · card.md S2, S4, T1 tests · lenses interpretation «Which reading works with any answer to the open question, and is that the one assumed?» · closed · S2 y S4 fijados en 1ee70de

## Verified

- interpretation · fails (ACT-01, ACT-03)
- contract · fails (ACT-02)
- security · meets · rutas, credenciales y textos no cambian (ASM-01) y el Gate corre `attacks` sobre las mismas rutas
- overdesign · meets · T1 sólo renombra; no agrega capas, interfaces ni patrones
