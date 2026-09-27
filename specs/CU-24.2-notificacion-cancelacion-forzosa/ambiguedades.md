# Ambigüedades — CU-24.2 · Recibir notificación de cancelación forzosa

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | no aplica: sólo se dispara cuando hay una reserva afectada
| Duplicados    | la card dice: FA2 varias reservas del mismo usuario se agrupan en una notificación; FA4 una ya cancelada no se notifica
| Validación    | no aplica: no hay datos de entrada del usuario
| Error         | la card no dice qué pasa si el envío falla del lado del backend → CU-24.2-AMB-01
| Estado        | la card dice: la reserva pasa a «Cancelada» con trazabilidad; el nombre choca con CU-15 (ver CU-14-AMB-01)
| Permisos      | la card dice: sin permiso del sistema operativo no hay push, pero queda en el centro (FA3)
| Límites       | la card no dice en qué ventana se agrupan las reservas de FA2 (una misma baja o cualquier momento) → CU-24.2-AMB-02
| Orden         | no aplica: una notificación por evento
| Concurrencia  | la card dice: FA4 si el usuario ya la canceló no se envía nada
| Rastro        | la card dice: «el envío consta en la trazabilidad de la reserva»

## Eventos
CU-24.2-AMB-01 · 2026-09-27 · abierta · si el envío push falla, ¿se reintenta? ¿la trazabilidad registra «enviada» o «fallida»?
CU-24.2-AMB-02 · 2026-09-27 · abierta · la agrupación de FA2, ¿es por una misma acción del administrador (una baja) o por período?
CU-24.2-AMB-03 · 2026-09-27 · abierta · ¿la baja de sede o espacio cancela reservas futuras (este CU, CU-14 FA8) o se impide (CU-19 FA3)?
CU-24.2-AMB-04 · 2026-09-27 · abierta · ¿el historial del usuario tiene filtro por estado para abrir «filtrado por anuladas»?
CU-24.2-AMB-05 · 2026-09-27 · abierta · ¿achicar el horario de una sede (CU-18 FA3) anula reservas y dispara este aviso, o no?
CU-24.2-AMB-00 · 2026-09-27 · snapshot · congelado en f1e3ea7
