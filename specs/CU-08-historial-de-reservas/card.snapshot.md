---
card: CU-08
extraido: 2026-09-27T12:05:00-03:00
fuentes:
  - CU/CU-08 Consultar Historial de Reservas Individual.pdf
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 3 («Listar las reservas realizadas por el usuario, indicando sede, espacio deportivo, fecha y horario.») · § RF 6 Historial de reservas · § RF 7"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 49:434 CU-08 · Mis reservas · Próximas"
  - "Figma · 49:544 CU-08 · Mis reservas · Historial"
  - "Figma · 49:651 CU-08 · Mis reservas · Sin próximas"
  - "Figma · 49:697 CU-08 · Mis reservas · Sin pasadas"
  - "Figma · 37:147 CU-01 · Home · Usuario («TU PRÓXIMA RESERVA · VER TODAS →»)"
no_leido:
  - "las imágenes de pantalla embebidas en el PDF del CU (pdftotext solo extrae texto)"
estado: propuesta
---

# Snapshot — CU-08 · Consultar historial de reservas

Doble lectura: dos lecturas independientes del CU y del enunciado, más la propia contra Figma.

## Card, tal como está escrita

**Definición** (fuente: CU-08)
- Actor principal: Usuario registrado.
- Objetivo: «Permitir al usuario visualizar el historial completo de sus reservas realizadas en la
  plataforma.»
- Problema que resuelve: «Brinda acceso a la información histórica de reservas realizadas por el
  usuario, facilitando el seguimiento de actividades realizadas, reservas vigentes y canceladas.»

**Precondiciones** (fuente: CU-08) — El usuario debe estar autenticado en la plataforma.

**Poscondiciones** (fuente: CU-08) — El historial de reservas es mostrado al usuario.

**Flujo principal** (fuente: CU-08)
| Paso | Actor | Sistema |
|---|---|---|
| 1 | El usuario accede a la sección "Mis Reservas". | El sistema valida la sesión y carga la pantalla de próximas reservas. |
| 2 | Selecciona la opción "Historial". | El sistema consulta las reservas asociadas al usuario. |
| 3 | Espera la carga de resultados. | El sistema muestra el listado de reservas ordenadas por fecha. |
| 4 | El usuario puede ver sus reservas pasadas. | Fin caso de uso. |

**Flujos alternativos y de excepción** (fuente: CU-08)
- **FA1 · No Existen Reservas Registradas.** Origen: paso 2. Condición: el usuario no posee reservas
  registradas. Sistema: «Muestra el mensaje "No se encontraron reservas asociadas a su cuenta"».

**Diseño declarado en el CU** (fuente: CU-08)
- Pantallas: Home · Mis Reservas - Próximas · Mis Reservas - Historial · Sin Próximas · Sin Pasadas.
- Tab-Toggle Próximas / Historial (activo en lima, inactivo gris claro). Tarjeta con ícono o imagen
  del deporte, sede, código de cancha, fecha y horario, precio y Badge-Estado (Activa / Completada).
- Mensajes: «No se encontraron próximas reservas asociadas a su cuenta» / «No se encontraron reservas
  pasadas asociadas a su cuenta».

**Reglas que sólo están en el enunciado** (fuente: enunciado)
- RF 3: listar las reservas del usuario «indicando sede, espacio deportivo, fecha y horario».
- RF 6: «Acceder al historial de reservas realizadas, incluyendo las reservas cuyo horario ya haya
  finalizado.»
- RF 7: manejar sin conexión y servidor caído.

**Pantallas del prototipo** (fuente: Figma)
- Próximas: tarjetas con deporte, sede y dirección, precio, «ACTIVA», código del espacio, fecha,
  horario, y MODIFICAR · CANCELAR.
- Historial: «COMPLETADA» y «ANULADA» con el motivo «Anulada por el administrador · mantenimiento de
  la cancha».
- Vacíos: «No hay próximas reservas · No se encontraron próximas reservas asociadas a tu cuenta.» y
  «No hay reservas pasadas · No se encontraron reservas pasadas asociadas a tu cuenta.»

## Escenarios

`H01` es el flujo principal y `H02` es FA1; `H03` son los errores que pide el enunciado (RF 7) y el
CU no trae.

- [ ] CU-08-H01-01 — abre Mis reservas y ve sus próximas reservas con sede, espacio, fecha, horario y precio
- [ ] CU-08-H01-02 — una reserva recién hecha aparece en Próximas
- [ ] CU-08-H01-03 — abre Historial y ve sus reservas ya finalizadas, ordenadas por fecha
- [ ] CU-08-H01-04 — una reserva cancelada o anulada aparece en el historial con su estado
- [ ] CU-08-H01-05 — no ve reservas de otros usuarios
- [ ] CU-08-H02-01 — sin reservas próximas, ve el aviso de que no tiene
- [ ] CU-08-H02-02 — sin reservas pasadas, ve el aviso de que no tiene
- [ ] CU-08-H03-01 — sin conexión, ve el error de conexión
- [ ] CU-08-H03-02 — el servidor falla y no se muestran datos parciales

## Contradicciones dentro de la card

- El objetivo incluye reservas «vigentes y canceladas»; el Badge-Estado del CU sólo tiene Activa y
  Completada, y el prototipo agrega ANULADA · CU-08 objetivo y diseño, Figma 49:544.
- FA1 tiene un mensaje único («No se encontraron reservas asociadas a su cuenta»); el diseño del CU y
  el prototipo tienen uno por pestaña · CU-08 FA1 y diseño, Figma 49:651 y 49:697.
- El CU trata la consulta como sólo lectura; el prototipo pone MODIFICAR y CANCELAR en las tarjetas
  de Próximas, que son CU-11 y CU-10 · Figma 49:434.
- El CU no trae flujos de error de conexión ni de servidor; el enunciado los exige · CU-08, enunciado
  RF 7.
