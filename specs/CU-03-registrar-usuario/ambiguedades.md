# Ambigüedades — CU-03 · Registrar usuario

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | la card dice: «Se muestra un mensaje/tooltip en pantalla indicando los campos faltantes» (FA1)
| Duplicados    | la card dice: «El correo electrónico y/o el dni ingresado ya se encuentra registrado» (FA2); no dice si el correo se compara sin mayúsculas ni si el DNI se compara sin puntos → CU-03-AMB-01
| Validación    | la card dice «valida el formato de los datos» sin decir cuál: DNI, fecha, correo, contraseña → CU-03-AMB-02
| Error         | la card no dice qué pasa sin conexión o con el servidor caído → CU-03-AMB-03
| Estado        | la card no dice si la cuenta nace activa o requiere verificar el correo → CU-03-AMB-04
| Permisos      | la card no dice si registrarse crea siempre un usuario común (nunca admin) → CU-03-AMB-05
| Límites       | la card no dice edad mínima, largo máximo de nombre y apellido, ni rango de fecha de nacimiento → CU-03-AMB-06
| Orden         | no aplica: no hay listados
| Concurrencia  | la card no dice qué pasa si dos personas registran el mismo correo o DNI al mismo tiempo → CU-03-AMB-07
| Rastro        | la card no dice que se estampe la fecha de alta de la cuenta → CU-03-AMB-08

## Eventos
CU-03-AMB-01 · 2026-09-27 · abierta · ¿«correo ya registrado» compara sin distinguir mayúsculas? ¿el DNI se guarda y compara sólo con dígitos?
CU-03-AMB-02 · 2026-09-27 · abierta · ¿qué reglas valen para cada campo: contraseña (¿las tres de CU-04?), DNI (¿7 u 8 dígitos?), fecha (¿no futura?), correo (¿formato estándar?)?
CU-03-AMB-03 · 2026-09-27 · abierta · sin conexión o con el servidor caído, ¿se usan los overlays compartidos y se conservan los datos del formulario?
CU-03-AMB-04 · 2026-09-27 · abierta · ¿la cuenta queda activa al crearse o hay que verificar el correo antes de poder iniciar sesión?
CU-03-AMB-05 · 2026-09-27 · abierta · ¿el registro crea siempre rol usuario? ¿cómo se da de alta un administrador?
CU-03-AMB-06 · 2026-09-27 · abierta · ¿hay edad mínima para registrarse y límites de largo en nombre y apellido?
CU-03-AMB-07 · 2026-09-27 · abierta · con dos registros simultáneos del mismo correo o DNI, ¿el segundo cae en FA2?
CU-03-AMB-08 · 2026-09-27 · abierta · ¿se guarda la fecha y hora de creación de la cuenta?
CU-03-AMB-09 · 2026-09-27 · abierta · al terminar, ¿el usuario vuelve al login (poscondición y prototipo) o queda autenticado (paso 3)?
CU-03-AMB-00 · 2026-09-27 · snapshot · congelado en 9ae9dd3
CU-03-AMB-02 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-03-AMB-02 · 2026-09-27 · resuelta · la contraseña del registro sigue las reglas de CU-04; DNI de 7 u 8 dígitos, editable y único; fecha de nacimiento pasada, sin edad mínima (decisión 9)
CU-03-AMB-03 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-03-AMB-03 · 2026-09-27 · resuelta · se usan los overlays compartidos del prototipo en toda la app (decisión 11)
CU-03-AMB-05 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-03-AMB-05 · 2026-09-27 · resuelta · el rol lo trae la cuenta y se guarda en la base; el login no tiene selector de rol; la primera cuenta de administrador se crea al inicializar la base (decisión 2)
CU-03-AMB-08 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-03-AMB-08 · 2026-09-27 · resuelta · todas las entidades guardan fecha de creación y de modificación, las acciones del administrador guardan su autor, la reserva guarda el precio del momento; las bajas son lógicas y no borran historial (decisión 4)
CU-03-AMB-09 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-03-AMB-09 · 2026-09-27 · resuelta · si el CU y el prototipo dicen distinto, manda el prototipo (decisión 12)
