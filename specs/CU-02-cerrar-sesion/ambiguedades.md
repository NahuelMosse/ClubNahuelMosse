# Ambigüedades — CU-02 · Cerrar sesión

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | no aplica: siempre hay una sesión abierta cuando el caso empieza (precondición)
| Duplicados    | no aplica: no crea entidades
| Validación    | no aplica: no hay datos de entrada
| Error         | la card no dice qué pasa si no hay conexión o el servidor falla al cerrar la sesión → CU-02-AMB-01
| Estado        | la card dice: «El usuario se encuentra con su sesion cerrada»; no dice si se invalida el token en el servidor o sólo en el dispositivo → CU-02-AMB-02
| Permisos      | la card no dice si el administrador cierra sesión por el mismo camino → CU-02-AMB-03
| Límites       | no aplica
| Orden         | no aplica
| Concurrencia  | la card no dice si cerrar sesión en un dispositivo cierra las de los demás → CU-02-AMB-04
| Rastro        | la card no dice si se estampa la hora de cierre de sesión → CU-02-AMB-05

## Eventos
CU-02-AMB-01 · 2026-09-27 · abierta · sin conexión o con el servidor caído, ¿se cierra la sesión igual en el dispositivo o se muestra el error y se queda adentro?
CU-02-AMB-02 · 2026-09-27 · abierta · ¿el cierre invalida el token en el backend o sólo lo borra del dispositivo? ¿se deja de recibir push de recordatorio (CU-24.1) después de cerrar sesión?
CU-02-AMB-03 · 2026-09-27 · abierta · ¿el administrador cierra sesión desde la misma tarjeta del avatar?
CU-02-AMB-04 · 2026-09-27 · abierta · ¿cerrar sesión afecta a las otras sesiones del mismo usuario?
CU-02-AMB-05 · 2026-09-27 · abierta · ¿se registra fecha y hora del cierre de sesión?
CU-02-AMB-06 · 2026-09-27 · abierta · ¿qué datos lleva la tarjeta del avatar (los seis del CU o los tres del prototipo) y se muestra «Sesión cerrada exitosamente» al volver al login?
CU-02-AMB-00 · 2026-09-27 · snapshot · congelado en 53bb895
CU-02-AMB-02 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-02-AMB-02 · 2026-09-27 · resuelta · la sesión sigue abierta al reabrir la app y se permiten varias a la vez; al cerrar sesión el dispositivo deja de recibir push (decisión 14)
CU-02-AMB-04 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-02-AMB-04 · 2026-09-27 · resuelta · la sesión sigue abierta al reabrir la app y se permiten varias a la vez; al cerrar sesión el dispositivo deja de recibir push (decisión 14)
CU-02-AMB-06 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-02-AMB-06 · 2026-09-27 · resuelta · si el CU y el prototipo dicen distinto, manda el prototipo (decisión 12)
