- ACT-01 · M · `lib/api/` está fuera y dentro del alcance a la vez: S1 lo excluye («el cliente `lib/api/` pasa con la card del contrato»), pero el test de S1 en T1 dice «el router y la api viven en inglés» y la línea `refactor-tests:` del Gate dice «y la api de la app pasan a inglés». O el builder traduce `lib/api/` (contra S1 y L3), o el test de S1 da rojo para siempre. lenses.md · interpretation: «Does each `S#` say the same as the sentence it quotes, no less and no more?» · card.md S1, T1, Gate · plan · closed · S1 y la línea refactor-tests ya no nombran lib/api (pasa con la card del contrato)

## Verified

- interpretation · fails (ACT-01). Las otras frases de L1 están cubiertas: «base y API incluidas» quedan fuera por L2/L3/L4 (cards en paralelo ENG-09/ENG-10); «su propia branch» por L4.
- security · meets: no hay cambio de rutas, cuerpos, logs ni manejo de texto (S3, L3); los flujos de contraseña y sesión se mueven sin cambiar su comportamiento.
- overdesign · meets: `domain/` en cada funcionalidad lo pide el usuario (S2, `why-layer:` cita L1) y está atado a `capas_test.dart`; `users/domain/` ya existe de ENG-08, así que S2 se cumple sin carpetas vacías. No hay interfaces, factories ni configuración nuevas en el plan.
