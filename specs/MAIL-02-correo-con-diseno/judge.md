- ACT-01 · M · S1 fija un diseño concreto (colores de `tokens.dart`, marca «CLUB NAHUEL MOSSE», botón «Crear contraseña nueva») que L1 («es horrible, se puede mejorar?») no pide; la lectura no está declarada como `ASM` · card.md S1 · lenses.md interpretation «Which reading works with any answer to the open question, and is that the one assumed?» · closed · MAIL-02-ASM-03 (L3: «aprovechando el diseño de la app»)
- ACT-02 · M · `Mensaje` suma `html` pero el plan no dice si es opcional ni qué mandan Brevo y SMTP cuando falta; cuatro tests existentes lo construyen sin `html` (`tests/unit/test_correo.py:7`, `test_correo_brevo.py:14`, `tests/escenarios/test_seguridad_api.py:166`, `test_seguridad_entradas_extra.py:126`), y `test_correo.py`, que prueba `_por_smtp`, no está en la línea `suite:` del Gate · card.md T1 «reuses: … `Mensaje` (suma `html`)» y Gate `suite:` · lenses.md contract «Does an existing client keep working: which route, field or status of main changes?» · closed · MAIL-02-ASM-01; test_correo.py en la suite

## Verified

- interpretation: fails (ACT-01)
- contract: fails (ACT-02)
- security: meets. El nombre se escapa (ASM-02, con su test). El `href` sale de `url_publica` y de un código que genera el servidor (`casos_de_uso.py:78`). El log de `correo.py:75` registra solo el asunto y el tipo de error.
- overdesign: meets. Un campo en `Mensaje` y tres archivos que ya existen, sin capas, interfaces ni config nuevas.
