---
card: CU-22
extraido: 2026-09-27T12:30:00-03:00
fuentes:
  - CU-nuevos/CU-22 - Editar espacio deportivo.md
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 5 Módulo de Espacios deportivos"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 63:1895 CU-21 · Gestionar espacios (origen: «Editar»)"
  - "Figma · 63:2302 CU-22 · Editar espacio"
  - "Figma · 390:6522 CU-22 · Editar espacio · Precio inválido"
  - "Figma · 393:6532 Algo cambió mientras tanto · 42:384 Error de conexión · 42:410 Error del servidor (overlays compartidos)"
no_leido: []
estado: propuesta
---

# Snapshot — CU-22 · Editar espacio deportivo

## Card, tal como está escrita

**Definición** (fuente: CU-22)
- Módulo: Sedes y espacios deportivos. Actor principal: Administrador. Alumno asignado: Carlos
  Augusto Silva.
- Estaba diseñado en el Figma grupal sin especificación escrita; CU-21 y CU-23 muestran «Editar» en
  cada tarjeta.
- Objetivo: «Permitir que el administrador corrija el precio por hora y la disponibilidad de un
  espacio deportivo ya cargado.»
- Problema que resuelve: el precio cambia por temporada, y una cancha puede quedar temporalmente
  fuera de servicio sin que corresponda darla de baja.

**Precondiciones** (fuente: CU-22)
- El administrador tiene la sesión iniciada con rol de administrador.
- El espacio deportivo existe y está activo.

**Poscondiciones** (fuente: CU-22)
- El precio y la condición quedan actualizados.
- «Las reservas ya confirmadas conservan el precio con el que se hicieron.» El precio nuevo rige
  para las reservas posteriores.

**Regla de negocio: el nombre compuesto no se edita** (fuente: CU-22) — El nombre
`Moron_Rivadavia_19850_Futbol_F5_1` se arma con sede, dirección con altura, deporte, tipo y número.
Esos cinco campos quedan deshabilitados: cambiarlos haría que el espacio pase a ser otro y rompería
la trazabilidad de sus reservas. Para mover un espacio de sede se da de baja (CU-23) y se crea uno
nuevo (CU-21).

**Flujo principal** (fuente: CU-22)
| # | Administrador | Sistema |
|---|---|---|
| 1 | Desde el panel admin, entra a la pestaña "Espacios". | Muestra el listado de espacios con su nombre compuesto, tipo y precio. |
| 2 | Presiona "Editar" en uno de ellos. | Abre el formulario: sede, deporte y tipo deshabilitados; precio editable. La vista previa del nombre se muestra en estado confirmado. |
| 3 | Modifica el precio por hora. | Valida que sea numérico y mayor a cero, y habilita "Guardar espacio". |
| 4 | Presiona "Guardar espacio". | Guarda y vuelve al listado con el precio nuevo. |

**Flujos alternativos y de excepción** (fuente: CU-22)
- **FA1 · El administrador cancela** (origen pasos 3 y 4). Vuelve al listado sin guardar.
- **FA2 · Precio inválido** (origen paso 3). Vacío, no numérico o cero: el campo queda marcado y el
  botón se deshabilita.
- **FA3 · No modificó nada** (origen paso 4). El botón permanece deshabilitado.
- **FA4 · El espacio fue dado de baja desde otra sesión** (origen paso 4). Informa que ya no está
  disponible y vuelve al listado.
- **FA5 · Error de conexión o del servidor** (origen paso 4). Overlay compartido; los datos se
  conservan.
- **FA6 · El administrador da de baja el espacio** (origen paso 3). El control pasa a CU-23.

**Mensajes** (fuente: CU-22) — «El precio tiene que ser un número mayor a cero» · «Los cambios se
guardaron correctamente».

**Pantallas del prototipo** (fuente: Figma)
- Editar: SEDE, DEPORTE, TIPO, PRECIO POR HORA, NOMBRE GENERADO AUTOMÁTICAMENTE; GUARDAR ESPACIO ·
  CANCELAR.
- Precio inválido: «$ 0» con «Ingresá un precio mayor a cero».

## Escenarios

- [ ] CU-22-H01-01 — cambia el precio de un espacio y el listado y la sede muestran el nuevo
- [ ] CU-22-H01-02 — una reserva hecha antes del cambio conserva su precio y una nueva usa el nuevo
- [ ] CU-22-H01-03 — sede, deporte y tipo no se pueden editar
- [ ] CU-22-H02-01 — cancela y el precio no cambia
- [ ] CU-22-H03-01 — deja el precio vacío, en cero o con letras y no puede guardar
- [ ] CU-22-H04-01 — sin modificar nada, el botón de guardar sigue deshabilitado
- [ ] CU-22-H05-01 — el espacio fue dado de baja en otra sesión y se le avisa al guardar
- [ ] CU-22-H06-01 — sin conexión al guardar, ve el error y conserva el precio escrito
- [ ] CU-22-H07-01 — desde la edición pasa a dar de baja el espacio

## Contradicciones dentro de la card

- El objetivo y la poscondición incluyen la «disponibilidad» o «condición» del espacio; el flujo y el
  prototipo sólo editan el precio · CU-22 objetivo y poscondiciones, CU-22 paso 3, Figma 63:2302.
- FA6 da de baja desde la edición; el formulario del prototipo no tiene botón de baja, sólo GUARDAR
  ESPACIO y CANCELAR · CU-22 FA6, Figma 63:2302.
- El mensaje del CU es «El precio tiene que ser un número mayor a cero»; el prototipo dice «Ingresá
  un precio mayor a cero» · CU-22 mensajes, Figma 390:6522.
- La regla dice que se deshabilitan cinco campos; el formulario tiene tres (sede, deporte, tipo) más
  el nombre generado · CU-22 regla de negocio, paso 2.
