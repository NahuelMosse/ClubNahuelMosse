---
card: CU-24.1
extraido: 2026-09-27T14:20:00-03:00
fuentes:
  - CU-nuevos/CU-24.1 - Notificacion recordatoria.md
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 3 («Recibir notificaciones push sobre reservas próximas.») · § RNF 5 («Firebase para autenticación y notificaciones push»)"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 65:328 CU-24.1 · Pantalla bloqueada (contexto del sistema)"
  - "Figma · 65:348 CU-24.1 · Push recordatoria (en la app)"
  - "Figma · 65:401 CU-24 · Centro de notificaciones"
  - "Figma · 65:470 CU-24 · Notificaciones desactivadas"
  - "Figma · 43:1462 CU-24 · Notificaciones in-app (overlay)"
no_leido: []
estado: propuesta
---

# Snapshot — CU-24.1 · Recibir notificación recordatoria

## Card, tal como está escrita

**Definición** (fuente: CU-24.1)
- Módulo: Notificaciones. Actor principal: Usuario registrado. Actor secundario: el sistema, que la
  dispara solo. Alumnos asignados: Nahuel Alejandro Mlakar y Jerónimo Zarlenga.
- CU-24 se separa en tres porque son notificaciones con disparador, emisor y momento distintos:
  24.1 la dispara el sistema una hora antes (informativo); 24.2 el club desde CU-15, CU-19 o CU-23
  (alerta); 24.3 el propio usuario desde CU-10 (confirmación).
- Objetivo: «Avisar al usuario, una hora antes, que tiene una reserva próxima, para que no la olvide
  y para reducir las canchas que quedan vacías.»
- Problema que resuelve: lo pide el enunciado (RF 3); una reserva olvidada es una cancha ocupada que
  nadie usa.

**Precondiciones** (fuente: CU-24.1)
- El usuario tiene una reserva en estado Activa con horario futuro.
- El usuario concedió el permiso de notificaciones del sistema operativo.
- El dispositivo tiene un token de notificaciones registrado en el backend.

**Poscondiciones** (fuente: CU-24.1)
- La notificación queda registrada como enviada y aparece en el centro de notificaciones de la app.
- No cambia el estado de la reserva: es solo un aviso.

**Regla de disparo** (fuente: CU-24.1) — Se envía una sola vez, una hora antes del inicio. Si la
reserva se cancela o se modifica antes, el recordatorio pendiente se descarta o se reprograma con el
horario nuevo.

**Flujo principal** (fuente: CU-24.1)
| # | Acción | Sistema |
|---|---|---|
| 1 | — | Una hora antes del inicio, el backend dispara la notificación al dispositivo del usuario. |
| 2 | El usuario ve el aviso en la pantalla bloqueada o sobre la app. | Muestra el deporte, la sede y el rango horario. |
| 3 | Toca la notificación. | Abre la app en "Mis reservas", con la reserva correspondiente a la vista. |

**Flujos alternativos y de excepción** (fuente: CU-24.1)
- **FA1 · La app está abierta** (origen paso 2). Tarjeta en la parte superior, sin salir de la
  pantalla.
- **FA2 · El usuario no concedió el permiso** (origen paso 1). No se envía nada. El centro de
  notificaciones muestra «Notificaciones desactivadas» con la acción para activarlas.
- **FA3 · El usuario ignora la notificación** (origen paso 2). Queda en el centro marcada como no
  leída.
- **FA4 · La reserva se canceló o se modificó** (origen paso 1). El recordatorio se descarta, o se
  reprograma con el horario nuevo si se modificó (CU-11).
- **FA5 · El dispositivo está sin conexión** (origen paso 1). El servicio de notificaciones
  reintenta según su propia política; es comportamiento del sistema operativo, no de la app.

**Mensajes** (fuente: CU-24.1) — Título «Tu reserva es en 1 hora»; cuerpo «Fútbol 5 · Sede Morón ·
21:00 – 22:00».

**Pantallas del prototipo** (fuente: Figma)
- Pantalla bloqueada a las 20:00 con «CLUBNAHUELMOSSE · AHORA · Tu reserva es en 1 hora · Fútbol 5 ·
  Sede Morón · 21:00 – 22:00».
- Centro de notificaciones agrupado por HOY / AYER con «HACE 2 MIN»; overlay in-app con «MARCAR
  TODAS».
- Desactivadas: «Activá los avisos para que te recordemos tus reservas una hora antes.» · ACTIVAR
  NOTIFICACIONES.

## Escenarios

FA5 no tiene escenario: el reintento lo hace el servicio de notificaciones del sistema operativo.

- [ ] CU-24.1-H01-01 — una hora antes del inicio recibe el recordatorio con deporte, sede y horario
- [ ] CU-24.1-H01-02 — al tocar el recordatorio la app abre Mis reservas con esa reserva
- [ ] CU-24.1-H01-03 — el recordatorio queda en el centro de notificaciones
- [ ] CU-24.1-H02-01 — con la app abierta, el recordatorio aparece como tarjeta superior sin cambiar de pantalla
- [ ] CU-24.1-H03-01 — sin permiso de notificaciones no se envía y el centro muestra «Notificaciones desactivadas»
- [ ] CU-24.1-H03-02 — desde «Notificaciones desactivadas» activa los avisos y empieza a recibirlos
- [ ] CU-24.1-H04-01 — un recordatorio que no se tocó queda como no leído
- [ ] CU-24.1-H04-02 — «Marcar todas» deja todas las notificaciones como leídas
- [ ] CU-24.1-H05-01 — la reserva se canceló antes y el recordatorio no llega
- [ ] CU-24.1-H05-02 — la reserva se modificó y el recordatorio llega una hora antes del horario nuevo

## Contradicciones dentro de la card

- FA2 dice que sin permiso «no se envía nada» y la poscondición dice que la notificación queda en el
  centro de notificaciones; no queda claro si sin permiso el recordatorio aparece igual en el centro
  · CU-24.1 FA2, poscondiciones.
- El CU fija «una hora antes»; el enunciado sólo dice «reservas próximas» y no dice qué pasa con una
  reserva creada con menos de una hora de anticipación · CU-24.1 regla de disparo, enunciado RF 3.
