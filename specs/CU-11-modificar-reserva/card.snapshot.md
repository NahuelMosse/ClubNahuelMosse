---
card: CU-11
extraido: 2026-09-27T12:05:00-03:00
fuentes:
  - CU-nuevos/CU-11 - Modificar reserva.md
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 3 Gestión de reservas"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 49:434 CU-08 · Mis reservas · Próximas (origen: botón MODIFICAR)"
  - "Figma · 67:1089 CU-11 · Modificar reserva · Elegir nuevo horario"
  - "Figma · 51:494 CU-11 · Modificar reserva · Confirmar cambio"
  - "Figma · 393:6532 Compartido · Algo cambió mientras tanto (overlay)"
  - "Figma · 42:384 Error de conexión · 42:410 Error del servidor (overlays compartidos)"
no_leido: []
estado: propuesta
---

# Snapshot — CU-11 · Modificar reserva

Doble lectura: dos lecturas independientes del CU y del enunciado, más la propia contra Figma.

## Card, tal como está escrita

**Definición** (fuente: CU-11)
- Módulo: Reservas. Actor principal: Usuario registrado. Alumna asignada: Sofía Mailén Granero.
- No tenía especificación en PDF ni diseño en el Figma grupal; se derivó de CU-09, CU-12 y el
  enunciado.
- Objetivo: «Permitir que el usuario cambie la fecha o el horario de una reserva vigente sin tener
  que cancelarla y volver a crearla, liberando el turno anterior solo cuando el nuevo queda
  confirmado.»
- Problema que resuelve: cancelar y reservar de nuevo arriesga perder el horario anterior sin
  conseguir el nuevo; modificar lo resuelve «en una sola transacción».

**Precondiciones** (fuente: CU-11)
- El usuario tiene la sesión iniciada.
- Existe al menos una reserva en estado Activa, con fecha y horario futuros.
- El espacio deportivo sigue habilitado y su sede también.

**Poscondiciones** (fuente: CU-11)
- La reserva conserva su identificador: se modifica, no se crea otra.
- El horario anterior queda liberado y disponible para otros usuarios.
- El horario nuevo queda bloqueado a nombre del usuario.
- Si no se pudo tomar el horario nuevo, la reserva queda exactamente como estaba.

**Reglas de negocio que hereda del enunciado** (fuente: CU-11)
- El horario nuevo tiene que ser futuro respecto del momento de la modificación.
- Inicio y fin en horas completas, mínimo una hora.
- El fin no puede superar el horario de cierre de la sede.
- El horario nuevo no puede superponerse con otra reserva del mismo espacio; la validación la hace el
  backend, igual que en CU-09.
- Una reserva cuyo horario ya empezó o ya pasó no se puede modificar.

**Flujo principal** (fuente: CU-11)
| # | Usuario | Sistema |
|---|---|---|
| 1 | En "Mis reservas", presiona "Modificar" en una reserva activa. | Abre la grilla de horarios del mismo espacio, con un aviso de que se está modificando y con el horario actual marcado como disponible. |
| 2 | Elige otra fecha o toca otra franja libre. | Marca la franja nueva y actualiza el resumen. |
| 3 | Presiona "Continuar con el cambio". | Muestra la pantalla de confirmación con la comparación Antes / Ahora. |
| 4 | Revisa el cambio y presiona "Guardar el cambio". | Valida contra el backend, libera el horario anterior, bloquea el nuevo y vuelve a Mis reservas con la reserva actualizada. |

**Flujos alternativos y de excepción** (fuente: CU-11)
- **FA1 · El usuario desiste** (origen pasos 3 y 4). Presiona «Dejar la reserva como está»; vuelve a
  Mis reservas sin tocar nada.
- **FA2 · El horario nuevo se ocupó mientras elegía** (origen paso 4). El backend rechaza; el sistema
  informa que ya no está disponible, conserva la reserva original intacta y vuelve a la grilla con la
  disponibilidad actualizada.
- **FA3 · No eligió un horario distinto** (origen paso 3). El botón permanece deshabilitado.
- **FA4 · La reserva dejó de ser modificable** (origen paso 4). El horario ya empezó, un
  administrador la anuló (CU-15) o se dio de baja el espacio (CU-23). Informa que ya no se puede
  modificar y recarga el listado.
- **FA5 · Error de conexión o del servidor** (origen paso 4). Overlay compartido; la reserva queda
  como estaba.

**Relación con otros CU** (fuente: CU-11) — reutiliza la grilla de CU-12 en modo edición; comparte la
tarjeta con CU-08, donde está «Modificar» junto a «Cancelar»; no dispara CU-24.2 «porque el cambio
lo hace el propio usuario y no el club».

**Componentes y mensajes** (fuente: CU-11)
- `Card-Reserva` con «Modificar» · `Snackbar` Info con el aviso · `Slot-Horario` · `Chip-Fecha` ·
  `Segmented` de duración · filas Antes / Ahora · `Btn` Primary y Outline-Danger.
- «Estás modificando tu reserva del Mié 12, 21:00 – 22:00. El horario anterior se libera al
  guardar.» · «El horario seleccionado ya no está disponible. Tu reserva original no se modificó.»

**Pantallas del prototipo** (fuente: Figma)
- Elegir nuevo horario: «Estás modificando tu reserva del Jue 12, 21:00 – 22:00. Mantenés la misma
  duración de 1 hora y el horario anterior se libera al guardar.»; SELECCIONÁ CANCHA (Cancha 1 /
  Cancha 2), FECHA, grilla con «21:00 (actual)», sin selector de duración; CONTINUAR CON EL CAMBIO.
- Confirmar cambio: ANTES «Jue 12 · 21:00 – 22:00», AHORA «Jue 12 · 19:00 – 20:00», Cancha, Fecha,
  TOTAL; GUARDAR EL CAMBIO · DEJAR LA RESERVA COMO ESTÁ.

## Escenarios

- [ ] CU-11-H01-01 — cambia el horario y la reserva, con el mismo identificador, muestra el horario nuevo
- [ ] CU-11-H01-02 — después del cambio, el horario anterior queda libre para otros y el nuevo ocupado
- [ ] CU-11-H01-03 — el backend rechaza un horario nuevo en el pasado o que termina después del cierre
- [ ] CU-11-H02-01 — desiste con «Dejar la reserva como está» y nada cambia
- [ ] CU-11-H03-01 — el horario nuevo se ocupó mientras elegía: se rechaza y la reserva original sigue intacta
- [ ] CU-11-H04-01 — sin elegir un horario distinto, el botón sigue deshabilitado
- [ ] CU-11-H05-01 — la reserva ya empezó y se le informa que no se puede modificar
- [ ] CU-11-H05-02 — la reserva fue anulada por un administrador y se le informa que no se puede modificar
- [ ] CU-11-H06-01 — sin conexión o con el servidor caído al guardar, la reserva queda como estaba

## Contradicciones dentro de la card

- Los componentes incluyen un `Segmented` de duración; el prototipo no deja cambiar la duración y
  dice «Mantenés la misma duración» · CU-11 componentes, Figma 67:1089.
- El paso 1 abre «la grilla de horarios del mismo espacio»; el prototipo ofrece elegir entre Cancha
  1 y Cancha 2, que son espacios distintos · CU-11 paso 1, Figma 67:1089.
- FA2 vuelve a la grilla con el mensaje «El horario seleccionado ya no está disponible. Tu reserva
  original no se modificó.»; el prototipo usa el overlay compartido «Esto cambió mientras tanto» ·
  CU-11 FA2, Figma 393:6532.
- El mensaje de aviso del CU dice «Mié 12»; el prototipo dice «Jue 12» · CU-11 mensajes, Figma
  67:1089.
