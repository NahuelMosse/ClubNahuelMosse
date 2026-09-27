# Ambigüedades — MOD-01 · Modelo de datos

Una sola lectura del enunciado, declarada. Las preguntas de datos que ya abrió cada CU no se
repiten acá: se nombran por su ID.

## Las diez preguntas
| Caso vacío    | no aplica: el modelo no tiene pantalla
| Duplicados    | la card dice: no hay dos reservas superpuestas del mismo espacio (RF 3); para correo, DNI, sede y espacio ver CU-03-AMB-01, CU-17-AMB-02 y CU-21-AMB-06
| Validación    | la card dice: reservas en horas completas, mínimo una hora, fin antes del cierre, en el futuro (RF 3)
| Error         | no aplica: el modelo no tiene flujo de error
| Estado        | la card dice que una reserva se cancela y otra finaliza; no dice los estados → CU-09-AMB-03, CU-14-AMB-01
| Permisos      | la card dice: la API identifica al usuario autenticado (RNF 5); el rol administrador no aparece en el enunciado → MOD-01-AMB-01
| Límites       | la card no dice si el horario de la sede varía por día → CU-12-AMB-06
| Orden         | no aplica
| Concurrencia  | la card dice: «El backend deberá validar la disponibilidad del espacio deportivo antes de registrar una reserva» (RF 3); no dice si la base lo garantiza con una restricción → CU-09-AMB-06
| Rastro        | la card no dice que se estampe fecha de creación ni autor de los cambios en ninguna entidad → MOD-01-AMB-02

## Eventos
MOD-01-AMB-01 · 2026-09-27 · abierta · ¿el rol administrador es un atributo del usuario en la base o un claim de Firebase Auth?
MOD-01-AMB-02 · 2026-09-27 · abierta · ¿todas las entidades llevan fecha de creación y de última modificación, y las acciones del administrador el autor? (CU-03-AMB-08, CU-09-AMB-07, CU-10-AMB-06, CU-17-AMB-07, CU-21-AMB-05)
MOD-01-AMB-03 · 2026-09-27 · abierta · ¿las bajas de usuario, sede y espacio son lógicas, para que el historial se conserve? (CU-07-AMB-03, CU-19-AMB-01, CU-23-AMB-04)
MOD-01-AMB-04 · 2026-09-27 · abierta · ¿la reserva guarda una copia del nombre del espacio y del precio al momento de reservar? (CU-14 FA8, CU-09-AMB-07)
MOD-01-AMB-05 · 2026-09-27 · abierta · ¿las notificaciones y los tokens de dispositivo son entidades del modelo o viven sólo en Firebase?
MOD-01-AMB-00 · 2026-09-27 · snapshot · congelado en b5dac58
MOD-01-AMB-01 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
MOD-01-AMB-01 · 2026-09-27 · resuelta · el rol lo trae la cuenta y se guarda en la base; el login no tiene selector de rol; la primera cuenta de administrador se crea al inicializar la base (decisión 2)
MOD-01-AMB-02 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
MOD-01-AMB-02 · 2026-09-27 · resuelta · todas las entidades guardan fecha de creación y de modificación, las acciones del administrador guardan su autor, la reserva guarda el precio del momento; las bajas son lógicas y no borran historial (decisión 4)
MOD-01-AMB-03 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
MOD-01-AMB-03 · 2026-09-27 · resuelta · todas las entidades guardan fecha de creación y de modificación, las acciones del administrador guardan su autor, la reserva guarda el precio del momento; las bajas son lógicas y no borran historial (decisión 4)
MOD-01-AMB-04 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
MOD-01-AMB-04 · 2026-09-27 · resuelta · todas las entidades guardan fecha de creación y de modificación, las acciones del administrador guardan su autor, la reserva guarda el precio del momento; las bajas son lógicas y no borran historial (decisión 4)
MOD-01-AMB-05 · 2026-09-27 · vencida · → MOD-01-SUP-01: las notificaciones y los tokens de dispositivo no se modelan en esta card; los crea la primera card de notificaciones (CU-24.1)
MOD-01-TESTS · 2026-09-27 · congelados en 658a103
