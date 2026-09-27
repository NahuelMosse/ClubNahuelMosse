# Ambigüedades — CU-07 · Dar cuenta de baja

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | la card dice: «Se liberan o anulan los compromisos futuros si los hubiera»; sin reservas futuras no hay nada que liberar
| Duplicados    | la card no dice si el mismo correo o DNI puede volver a registrarse después de la baja → CU-07-AMB-01
| Validación    | la card dice: sólo la confirmación del diálogo (paso 2–3); no pide contraseña para confirmar → CU-07-AMB-02
| Error         | la card dice: FA2 sin conexión y FA3 error de servidor, en ambos «La cuenta no se elimina»
| Estado        | la card no dice si la baja es borrado físico o la cuenta pasa a un estado «dada de baja» → CU-07-AMB-03
| Permisos      | la card dice: el usuario autenticado da de baja su propia cuenta; no dice si un administrador puede darse de baja ni si hay que dejar al menos un admin → CU-07-AMB-04
| Límites       | la card no dice qué pasa con una reserva en curso en el momento de la baja → CU-07-AMB-05
| Orden         | no aplica
| Concurrencia  | la card no lo dice; CU-05 FA4 sí: si la cuenta «fue eliminada desde otro dispositivo», la otra sesión se da por finalizada y va al login
| Rastro        | la card no dice qué queda del usuario y de sus reservas para el historial del administrador (CU-14) → CU-07-AMB-06

## Eventos
CU-07-AMB-01 · 2026-09-27 · abierta · después de la baja, ¿se puede crear una cuenta nueva con el mismo correo y el mismo DNI?
CU-07-AMB-02 · 2026-09-27 · abierta · ¿alcanza con confirmar el diálogo o se pide la contraseña antes de eliminar?
CU-07-AMB-03 · 2026-09-27 · abierta · ¿borrado físico de la cuenta y sus datos, o baja lógica con los datos personales anonimizados?
CU-07-AMB-04 · 2026-09-27 · abierta · ¿un administrador puede eliminar su propia cuenta?
CU-07-AMB-05 · 2026-09-27 · abierta · ¿una reserva que está en curso al momento de la baja se anula, se borra o se deja completar?
CU-07-AMB-06 · 2026-09-27 · abierta · ¿las reservas pasadas del usuario borrado siguen en el historial del administrador? ¿las futuras quedan como «anuladas» con motivo «baja de cuenta» o se borran?
CU-07-AMB-07 · 2026-09-27 · abierta · ¿al anular las reservas futuras por la baja se envía alguna notificación (CU-24.2 o CU-24.3)?
CU-07-AMB-00 · 2026-09-27 · snapshot · congelado en bb991e1
CU-07-AMB-00 · 2026-09-27 · snapshot · congelado en 3cc2677
CU-07-AMB-03 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-07-AMB-03 · 2026-09-27 · resuelta · todas las entidades guardan fecha de creación y de modificación, las acciones del administrador guardan su autor, la reserva guarda el precio del momento; las bajas son lógicas y no borran historial (decisión 4)
CU-07-AMB-06 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-07-AMB-06 · 2026-09-27 · resuelta · estados Activa, Completada, Cancelada (por el usuario) y Anulada (por el club, con motivo); todas las entidades guardan fecha de creación y de modificación, las acciones del administrador guardan su autor, la reserva guarda el precio del momento; las bajas son lógicas y no borran historial (decisión 3, 4)
