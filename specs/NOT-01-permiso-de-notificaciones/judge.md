# NOT-01 · judge (plan)

- ACT-01 · M · S1 «con lo que conteste, el teléfono se registra en la API con ese permiso» y S2 «si la persona ya contestó (concedió o negó)» nombran dos respuestas cada una, pero `tests:` de T1 planea un solo test por spec; además `SistemaSimulado.solicitarPermiso` siempre concede, así que la respuesta «negó» (registro con `permiso: false`, y no volver a preguntar tras negar) no tiene test ni forma de simularse en el plan · lenses.md interpretation: «Does a quantifier ("each", "all", "any") name its members, and does each member have a test?» · card.md S1, S2, T1 · plan · closed · T1 «si al entrar niega el permiso, el teléfono se registra sin permiso y no se vuelve a preguntar» y NOT-01-ASM-03 (el simulado guarda la respuesta fijada)
- ACT-02 · L · NOT-01-ASM-02 define «todavía no le preguntó» en el sistema simulado como «la ausencia de una respuesta guardada», pero hoy `SistemaSimulado` documenta «arranca concedido» y `permitido()` devuelve `true` sin respuesta guardada; el plan no dice qué devuelve `permitido()` en ese estado ni lo anota en `## Changes to existing behavior`, y los escenarios que fijan el permiso dependen de ese default · lenses.md interpretation: «What does the card leave to the default of a library (…), and is it written down?» · card.md NOT-01-ASM-02, Changes to existing behavior · plan · closed · NOT-01-ASM-03 y su test, más la línea del simulado en «Changes to existing behavior»

## Verified

- interpretation · fails (ACT-02) · S1/S2 citan L1; ASM-01 (rol) y ASM-02 (estado) declarados con test. ASM-02 contra FCM: firebase_messaging 16.7.0 en el pub cache sí resuelve `notDetermined` en Android 13+ (`resolveNotificationAuthorizationStatus`); la versión fijada en `pubspec.lock` no se verificó.
- quantifiers · fails (ACT-01)
- overdesign · meets · T1 toca tres archivos existentes, sin capa, carpeta ni interfaz nueva; `SistemaDeNotificaciones` ya tiene dos implementaciones (`SistemaFcm`, `SistemaSimulado`).
- lenses de risk.json · not verified · `lenses: []`, no hay lens de visual, contract, integrity ni security que revisar.
