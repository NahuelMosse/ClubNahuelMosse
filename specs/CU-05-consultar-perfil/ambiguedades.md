# Ambigüedades — CU-05 · Consultar perfil

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | la card no dice qué se muestra si un dato opcional está vacío (por ejemplo DNI en una cuenta sin él) → CU-05-AMB-01
| Duplicados    | no aplica: es una consulta
| Validación    | no aplica: no hay datos de entrada salvo el selector de tema
| Error         | la card dice: FA2 sin conexión sin datos parciales ni caché, FA3 error de servidor, FA4 sesión expirada al login
| Estado        | la card dice que muestra «el estado de la membresía» sin decir qué estados existen además de «Miembro activo» → CU-05-AMB-02
| Permisos      | la card dice: «el perfil devuelto es siempre el del portador del token»
| Límites       | no aplica
| Orden         | la card dice el orden: datos personales, luego la fila «Seguridad: Cambiar contraseña» (paso 3)
| Concurrencia  | la card dice: si la cuenta se eliminó desde otro dispositivo, FA4 (sesión finalizada)
| Rastro        | no aplica: la card dice que no modifica nada; la preferencia de tema queda en CU-05-AMB-03

## Eventos
CU-05-AMB-01 · 2026-09-27 · abierta · ¿qué se muestra en un campo del perfil sin valor?
CU-05-AMB-02 · 2026-09-27 · abierta · ¿qué estados de membresía existen además de «Miembro activo» y de dónde salen?
CU-05-AMB-03 · 2026-09-27 · abierta · ¿la preferencia de tema se guarda en el dispositivo o en el perfil del backend? ¿sobrevive a cerrar sesión?
CU-05-AMB-04 · 2026-09-27 · abierta · ¿los errores cierran con «Aceptar» (CU) o con «Reintentar / Volver» (overlay compartido del prototipo)?
CU-05-AMB-00 · 2026-09-27 · snapshot · congelado en a2d901f
CU-05-AMB-04 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-05-AMB-04 · 2026-09-27 · resuelta · se usan los overlays compartidos del prototipo en toda la app (decisión 11)
CU-05-AMB-01 · 2026-09-27 · vencida → CU-05-SUP-01 · el registro pide todos los datos, así que no hay campos vacíos; si alguno llegara vacío se muestra «—»
CU-05-AMB-02 · 2026-09-27 · vencida → CU-05-SUP-02 · el único estado visible es «MIEMBRO ACTIVO»: una cuenta dada de baja no inicia sesión
CU-05-AMB-03 · 2026-09-27 · vencida → CU-05-SUP-03 · el tema se guarda en el dispositivo, sobrevive a cerrar sesión y arranca en oscuro
