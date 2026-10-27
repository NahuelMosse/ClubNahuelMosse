# Handoff MAIL-02

## Hecho
- Ciclo de imports resuelto: `Mensaje` en app/shared/mensaje.py; envío en app/shared/correo.py; `recuperacion/correo.py` borrado; `recuperacion/__init__` exporta `correo` (= `app.shared.correo`), `enviar`, `Mensaje` (los tests viejos `from app.modules.recuperacion import correo` siguen valiendo, incluido el parche de `correo.motor`: no hace falta test de reemplazo). reservas y notificaciones importan de app.shared.
- ruff check, ruff format y mypy --strict de `app`: limpios. pyproject: E501 ignorado para test_correos_con_diseno.py.
- card.md: Tasks, reuses/new y Log L7..L10 listos.
- Commits: c3d3bcc RED, 6d69aec WIP, 4d7779f ciclo. Falta commitear: shared/mensaje.py, ajustes de imports, pyproject, card, handoff.

## Falta
1. Levantar el emulador de Firebase Auth: el de herramientas (puerto 8702) ya no existe (8702 hoy es el Postgres de otro agente). Sin él fallan/erroran todos los tests con sesión (integracion, test_correo_brevo 202). Levantarlo en un puerto libre con el firebase.json de D:/Temp/w/herramientas/emulador (cambiar el puerto), y exportar `FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:<puerto>`; `firebase` no está en el PATH (probar `npx firebase-tools emulators:start --only auth --project demo-clubnahuelmosse`).
2. Correr la suite del Gate con ese emulador y `node .claude/tools/verify.mjs`.
3. Del último verify (antes de los arreglos de shape/Tasks/E501): quedan `rounds`/`dead-clicks`/`copy`/`axe`/`contrast`/`focus` (la card no tiene pantalla: el verify escaló a visual porque lee plantilla_correo.py como pantalla; declarar en el Log `declared · …` si no hay otra salida), `required`: mutación de los 6 archivos (comandos `once.mjs mutate` en la salida del verify; correrlos en background con wait.mjs), K4 en el test (declarar en el Log), I-tokens (colores hex en plantilla_correo.py: un correo no puede usar var(--x); declarar en el Log), notificaciones/__init__ y recuperacion/rutas ya figuran en T1 (probar que `required` lo acepta).
4. Aviso de K4 viejo en reservas/rutas.py 358-363 y 166-171: no es de la card.
