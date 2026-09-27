# Ambigüedades — CU-04 · Cambiar contraseña

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | la card dice: la pantalla abre «con los tres campos vacíos y el botón deshabilitado» (paso 1)
| Duplicados    | la card no dice si la contraseña nueva puede ser igual a la actual → CU-04-AMB-01
| Validación    | la card dice: «8 caracteres, una mayúscula, un número» y que la repetición coincida (pasos 3–4, FA2, FA3)
| Error         | la card dice: FA4 overlay de conexión conservando datos, FA5 overlay de servidor sin cambios, FA6 sesión expirada al login
| Estado        | la card dice: «Las demás sesiones del usuario se invalidan» y «La sesión actual se mantiene abierta»
| Permisos      | la card dice: el actor es el usuario con sesión iniciada; no dice si el administrador usa el mismo flujo → CU-04-AMB-02
| Límites       | la card no dice largo máximo ni si hay tope de intentos con la contraseña actual equivocada → CU-04-AMB-03
| Orden         | no aplica
| Concurrencia  | la card dice que las demás sesiones se invalidan; no dice qué ve un dispositivo cuya sesión se invalidó a mitad de una operación → CU-04-AMB-04
| Rastro        | la card no dice que se estampe cuándo se cambió la contraseña → CU-04-AMB-05

## Eventos
CU-04-AMB-01 · 2026-09-27 · abierta · ¿se rechaza una contraseña nueva igual a la actual?
CU-04-AMB-02 · 2026-09-27 · abierta · ¿el administrador cambia su contraseña por el mismo flujo, desde su propio perfil?
CU-04-AMB-03 · 2026-09-27 · abierta · ¿hay largo máximo de contraseña y tope de intentos con la contraseña actual incorrecta?
CU-04-AMB-04 · 2026-09-27 · abierta · la sesión invalidada en otro dispositivo, ¿ve «Tu sesión expiró» en su próxima operación?
CU-04-AMB-05 · 2026-09-27 · abierta · ¿se guarda fecha y hora del último cambio de contraseña?
CU-04-AMB-06 · 2026-09-27 · abierta · ¿el campo de contraseña nueva empieza deshabilitado hasta escribir la actual (CU) o habilitado (prototipo)?
CU-04-AMB-00 · 2026-09-27 · snapshot · congelado en 31c4de7
CU-04-AMB-05 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-04-AMB-05 · 2026-09-27 · resuelta · todas las entidades guardan fecha de creación y de modificación, las acciones del administrador guardan su autor, la reserva guarda el precio del momento; las bajas son lógicas y no borran historial (decisión 4)
CU-04-AMB-01 · 2026-09-27 · vencida → CU-04-SUP-01 · se acepta una contraseña nueva igual a la actual: el prototipo no tiene mensaje para rechazarla
CU-04-AMB-02 · 2026-09-27 · vencida → CU-04-SUP-02 · el administrador no tiene perfil en la app (CU-02-SUP-02): cambia su contraseña por Recuperar contraseña (CU-04b)
CU-04-AMB-03 · 2026-09-27 · vencida → CU-04-SUP-03 · el largo máximo es el del registro; sin tope propio de intentos: si Firebase frena por demasiados intentos se ve el error del servidor
CU-04-AMB-04 · 2026-09-27 · vencida → CU-04-SUP-04 · la otra sesión ve «Sesión expirada» en su próximo pedido a la API y vuelve al login
CU-04-AMB-06 · 2026-09-27 · resuelta · los tres campos empiezan habilitados, como el prototipo (decisión 12)
