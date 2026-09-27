# Ambigüedades — CU-04b · Recuperar contraseña

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | la card dice: con el correo vacío o mal formado «El botón permanece deshabilitado» (FA2)
| Duplicados    | la card dice: pedir un reenvío «invalida el enlace anterior» (FA5)
| Validación    | la card dice: formato de correo (paso 2) y las reglas de contraseña (paso 5); las reglas son las de CU-04 según el prototipo
| Error         | la card dice: FA6 overlay compartido de conexión o de servidor, «No se cambia nada»
| Estado        | la card dice: enlace «de un solo uso con vencimiento a 30 minutos» (poscondiciones, FA3)
| Permisos      | la card dice: actor sin sesión iniciada; no dice si una cuenta dada de baja (CU-07) puede recuperar → CU-04b-AMB-01
| Límites       | la card no dice cuántos reenvíos se permiten por hora → CU-04b-AMB-02
| Orden         | no aplica
| Concurrencia  | la card no dice qué pasa si el usuario cambia la contraseña por CU-04 con un enlace de recuperación todavía vigente → CU-04b-AMB-03
| Rastro        | la card no dice que se estampe cuándo se pidió y cuándo se usó cada enlace → CU-04b-AMB-04

## Eventos
CU-04b-AMB-01 · 2026-09-27 · abierta · ¿una cuenta dada de baja puede pedir el enlace? ¿recibe mail?
CU-04b-AMB-02 · 2026-09-27 · abierta · ¿hay tope de pedidos de enlace por correo y por hora?
CU-04b-AMB-03 · 2026-09-27 · abierta · si la contraseña cambió por otra vía, ¿los enlaces vigentes se invalidan?
CU-04b-AMB-04 · 2026-09-27 · abierta · ¿se guarda fecha de emisión y de uso de cada enlace?
CU-04b-AMB-05 · 2026-09-27 · abierta · ¿cómo abre la app el enlace del correo: deep link a la app, página web intermedia, o el flujo de restablecimiento de Firebase Auth?
CU-04b-AMB-00 · 2026-09-27 · snapshot · congelado en 25bd071
