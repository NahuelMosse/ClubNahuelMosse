---
card: CU-24.3
extraido: 2026-09-27T12:50:00-03:00
fuentes:
  - CU-nuevos/CU-24.3 - Confirmacion de cancelacion.md
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 3 (notificaciones push) · § RNF 5 (Firebase para notificaciones push)"
  - "CU/CU-10 - Cancelar Reserva.pdf (origen)"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 65:383 CU-24.3 · Push confirmación de cancelación"
  - "Figma · 65:401 CU-24 · Centro de notificaciones · 43:1462 CU-24 · Notificaciones in-app (overlay)"
  - "Figma · 42:312 CU-10 · Cancelar reserva · Éxito (overlay)"
no_leido: []
estado: propuesta
---

# Snapshot — CU-24.3 · Recibir confirmación de cancelación

## Card, tal como está escrita

**Definición** (fuente: CU-24.3)
- Módulo: Notificaciones. Actor principal: Usuario registrado. Alumnos asignados: Nahuel Alejandro
  Mlakar y Jerónimo Zarlenga.
- No tenía especificación ni diseño; sale de la nota de la lista de CU («notificar cancelación de
  reserva»).
- Objetivo: «Dejarle al usuario una constancia de que la reserva que él mismo canceló quedó
  efectivamente cancelada y de que el horario se liberó.»
- Problema que resuelve: el mensaje de éxito de CU-10 desaparece; la notificación deja un registro
  consultable y confirma que el backend procesó la baja.

**Precondiciones** (fuente: CU-24.3) — El usuario canceló una reserva propia mediante CU-10, y el
backend confirmó la operación.

**Poscondiciones** (fuente: CU-24.3)
- La notificación queda registrada en el centro de notificaciones.
- No cambia ningún estado: la cancelación ya ocurrió en CU-10.

**Flujo principal** (fuente: CU-24.3)
| # | Acción | Sistema |
|---|---|---|
| 1 | El usuario confirma la cancelación en CU-10. | El backend cancela la reserva, libera el horario y encola la notificación. |
| 2 | — | Envía la confirmación al dispositivo del usuario. |
| 3 | El usuario ve el aviso. | Muestra qué reserva se canceló y aclara que el horario quedó liberado, con tratamiento visual de éxito. |
| 4 | Toca la notificación. | Abre la app en el historial de reservas, donde la reserva figura como cancelada. |

**Flujos alternativos y de excepción** (fuente: CU-24.3)
- **FA1 · El usuario está en la app** (origen paso 3). Tarjeta superior. No se duplica con el mensaje
  de CU-10: si sigue en Mis reservas, sólo se muestra el de CU-10.
- **FA2 · El usuario no concedió el permiso** (origen paso 2). No se envía el push; queda sólo en el
  centro de notificaciones.
- **FA3 · La cancelación falló** (origen paso 1). No se envía nada; CU-10 FA3 informa el error.
  «Nunca se notifica una cancelación que no se completó.»

**Por qué es un CU aparte** (fuente: CU-24.3) — CU-10 termina con «Reserva cancelada con éxito»; el
envío, la entrega, el registro en el centro y la relectura son un flujo con sus propios modos de
falla, y cubren el requisito de notificaciones del enunciado.

**Mensajes** (fuente: CU-24.3) — Título «Reserva cancelada»; cuerpo «Vóley · Sede Ramos Mejía · Mar
11, 20:00. El horario quedó liberado.»

**Pantallas del prototipo** (fuente: Figma)
- Push sobre el Home: «Reserva cancelada · Vóley · Sede Ramos Mejía · Mié 11, 20:00. El horario quedó
  liberado.»
- Overlay in-app: «Reserva cancelada · Cancelaste Vóley · Sede Ramos Mejía · Mié 11, 20:00. El horario
  quedó liberado.»

## Escenarios

- [ ] CU-24.3-H01-01 — cancela una reserva y recibe la confirmación con la reserva y el horario liberado
- [ ] CU-24.3-H01-02 — al tocar la confirmación la app abre el historial con la reserva cancelada
- [ ] CU-24.3-H01-03 — la confirmación queda en el centro de notificaciones
- [ ] CU-24.3-H02-01 — si sigue en Mis reservas, ve sólo el mensaje de éxito de la cancelación, sin la tarjeta
- [ ] CU-24.3-H03-01 — sin permiso de notificaciones no llega el push pero la confirmación está en el centro
- [ ] CU-24.3-H04-01 — si la cancelación falló, no recibe ninguna confirmación

## Contradicciones dentro de la card

- El enunciado pide push «sobre reservas próximas»; esta notificación avisa una cancelación, que el
  enunciado no pide · CU-24.3 objetivo, enunciado RF 3.
- El mensaje del CU dice «Mar 11»; el prototipo dice «Mié 11», y el 11 de noviembre de 2026 es
  miércoles · CU-24.3 mensajes, Figma 65:383.
