---
card: CU-24.2
extraido: 2026-09-27T12:50:00-03:00
fuentes:
  - CU-nuevos/CU-24.2 - Notificacion de cancelacion forzosa.md
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 3 (notificaciones push) · § RNF 5 (Firebase para notificaciones push)"
  - "CU/CU-15-Anular-reserva-admin.docx.pdf (poscondición que la exige)"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 65:363 CU-24.2 · Push cancelación forzosa"
  - "Figma · 65:401 CU-24 · Centro de notificaciones · 43:1462 CU-24 · Notificaciones in-app (overlay)"
  - "Figma · 59:1336 CU-14 · Panel admin · Detalle · Anulada (envío en la trazabilidad)"
  - "Figma · 49:544 CU-08 · Mis reservas · Historial (reserva anulada con motivo)"
no_leido: []
estado: propuesta
---

# Snapshot — CU-24.2 · Recibir notificación de cancelación forzosa

## Card, tal como está escrita

**Definición** (fuente: CU-24.2)
- Módulo: Notificaciones. Actor principal: Usuario registrado afectado. Actor que la origina:
  Administrador. Alumnos asignados: Nahuel Alejandro Mlakar y Jerónimo Zarlenga.
- No tenía especificación ni diseño; surge de la nota de la lista de CU y de que CU-15 lo exige en su
  poscondición («el sistema solicita el envío de una notificación al usuario afectado»).
- Objetivo: «Avisarle al usuario que el club dio de baja su reserva por una decisión propia,
  explicando el motivo, para que no se presente a una cancha que ya no tiene.»
- Problema que resuelve: es la única notificación que el usuario no puede anticipar; por eso lleva
  el motivo.

**Disparadores** (fuente: CU-24.2)
1. CU-15: el administrador anula una reserva puntual, con motivo obligatorio.
2. CU-19: el administrador da de baja una sede, «y caen todas las reservas futuras de sus
   espacios».
3. CU-23: el administrador da de baja un espacio, «y caen sus reservas futuras».
En 2 y 3 el motivo se genera solo: «Baja del espacio deportivo» o «Baja de la sede» (CU-14 FA8).

**Precondiciones** (fuente: CU-24.2)
- Existía una reserva en estado Activa con horario futuro.
- El administrador ejecutó una de las tres acciones anteriores.
- El usuario tiene un token de notificaciones registrado.

**Poscondiciones** (fuente: CU-24.2)
- La reserva pasa a estado Cancelada, con la trazabilidad de quién la anuló y cuándo.
- El horario queda liberado.
- La notificación queda registrada y el envío consta en la trazabilidad de la reserva.
- La reserva sigue en el historial del usuario, marcada como anulada por el club.

**Flujo principal** (fuente: CU-24.2)
| # | Acción | Sistema |
|---|---|---|
| 1 | El administrador confirma la anulación en CU-15 (o la baja en CU-19 / CU-23). | Cambia el estado de la reserva a Cancelada y encola la notificación para el usuario afectado. |
| 2 | — | Envía la notificación con el motivo incluido. |
| 3 | El usuario ve el aviso. | Muestra el deporte, la sede, la fecha y el motivo, con el tratamiento visual de alerta. |
| 4 | Toca la notificación. | Abre la app en el historial de reservas, con la reserva anulada y su motivo a la vista. |

**Flujos alternativos y de excepción** (fuente: CU-24.2)
- **FA1 · Una baja afecta a varios usuarios** (origen paso 1, desde CU-19 o CU-23). Una notificación
  por usuario afectado, con los datos de su propia reserva. No hay aviso masivo.
- **FA2 · Un mismo usuario tiene varias reservas afectadas** (origen paso 1). Se agrupan en una sola
  notificación que indica la cantidad; al tocarla se abre el historial filtrado por anuladas.
- **FA3 · El usuario no concedió el permiso** (origen paso 2). No se envía el push, pero la
  notificación queda igual en el centro de notificaciones de la app.
- **FA4 · El usuario ya había cancelado esa reserva** (origen paso 1). No se envía nada.

**Diferencia con CU-24.3** (fuente: CU-24.2) — 24.2 la canceló el club, lleva motivo, color de
alerta; 24.3 la canceló el usuario, es una confirmación, color de éxito.

**Mensajes** (fuente: CU-24.2) — Título «El club anuló tu reserva»; cuerpo «Hockey 7 · Sede Ramos
Mejía · Jue 30, 19:00. Motivo: mantenimiento de la cancha.»

**Pantallas del prototipo** (fuente: Figma)
- Push sobre el Home: «El club anuló tu reserva · Hockey 7 · Sede Ramos Mejía · Vie 30, 19:00.
  Motivo: mantenimiento de la cancha.»
- Overlay in-app: «El club anuló tu reserva · Tenis Polvo de Ladrillo · Sede Castelar · Vie 13,
  19:00. Motivo: mantenimiento.»

## Escenarios

- [ ] CU-24.2-H01-01 — el administrador anula una reserva y el usuario recibe el aviso con deporte, sede, fecha y motivo
- [ ] CU-24.2-H01-02 — al tocar el aviso la app abre el historial con la reserva anulada y su motivo
- [ ] CU-24.2-H01-03 — el envío del aviso queda en la trazabilidad de la reserva
- [ ] CU-24.2-H02-01 — una baja que afecta a varios usuarios manda un aviso a cada uno con su propia reserva
- [ ] CU-24.2-H03-01 — un usuario con varias reservas afectadas recibe un solo aviso con la cantidad
- [ ] CU-24.2-H04-01 — sin permiso de notificaciones no llega el push pero el aviso está en el centro
- [ ] CU-24.2-H05-01 — si el usuario ya había cancelado la reserva, no recibe aviso

## Contradicciones dentro de la card

- Los disparadores 2 y 3 dan por hecho que dar de baja una sede o un espacio cancela sus reservas
  futuras; CU-19 FA3 impide la baja de una sede con reservas futuras · CU-24.2 disparadores, CU-19
  FA3.
- La poscondición deja la reserva en «Cancelada»; CU-15 la deja «Anulada por administración» y el
  historial del prototipo la muestra «ANULADA» · CU-24.2 poscondiciones, CU-15 poscondiciones,
  Figma 49:544.
- FA2 abre «el historial filtrado por anuladas»; el historial de CU-08 no tiene filtro por estado ·
  CU-24.2 FA2, CU-08.
- El mensaje del CU dice «Jue 30»; el prototipo dice «Vie 30» para la misma reserva · CU-24.2
  mensajes, Figma 65:363.
