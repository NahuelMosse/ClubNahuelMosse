---
card: CU-13
extraido: 2026-09-27T11:40:00-03:00
fuentes:
  - CU/CU-13 - Consultar Canchas.pdf
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 3 Gestión de reservas (horarios dentro del funcionamiento de la sede, horas completas, mínimo una hora, horarios futuros, no superposición) · § RF 5"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 52:734 CU-13 · Consultar canchas · Filtros"
  - "Figma · 52:1085 CU-13 · Consultar canchas · Horario inválido"
  - "Figma · 52:824 CU-13 · Consultar canchas · Resultados"
  - "Figma · 52:963 CU-13 · Consultar canchas · Sin resultados"
  - "Figma · 201:6295 CU-13 · Consultar canchas · Error al consultar"
  - "Figma · 37:147 CU-01 · Home · Usuario (acceso «Buscar cancha · Por sede, fecha y horario»)"
no_leido:
  - "las imágenes de pantalla embebidas en el PDF del CU (pdftotext solo extrae texto)"
estado: propuesta
---

# Snapshot — CU-13 · Consultar canchas

## Card, tal como está escrita

**Definición** (fuente: CU-13)
- Actor principal: Usuario registrado.
- Objetivo: «Permitir al usuario consultar la disponibilidad de canchas y espacios deportivos según
  sede, tipo de deporte, fecha y horario, antes de iniciar una reserva.»
- Problema que resuelve: «Evita que el usuario intente reservar espacios ocupados, fuera del
  horario de funcionamiento o que no coinciden con sus criterios de búsqueda, centralizando la
  disponibilidad real en una única consulta.»

**Precondiciones** (fuente: CU-13)
- El usuario debe estar autenticado en la aplicación.
- Deben existir sedes y espacios deportivos activos cargados en el sistema, con horarios de
  funcionamiento definidos.

**Poscondiciones** (fuente: CU-13)
- El sistema muestra el listado de canchas disponibles para los criterios seleccionados o informa
  que no existen opciones para ese horario.
- No se genera ninguna reserva hasta que el usuario confirme la operación en el caso de uso
  correspondiente.
- Los filtros seleccionados quedan visibles para que el usuario pueda modificarlos y realizar una
  nueva consulta.

**Flujo principal** (fuente: CU-13)
| Paso | Actor | Sistema |
|---|---|---|
| 1 | El usuario accede a la sección "Reservas" y selecciona la opción "Consultar canchas". | El sistema muestra los filtros de búsqueda: sede, tipo de espacio deportivo, fecha, hora de inicio y hora de finalización. |
| 2 | El usuario selecciona una sede, un tipo de cancha y el rango horario que desea consultar. | El sistema valida que la fecha y el horario sean futuros, que correspondan a horas completas y que estén dentro del horario de funcionamiento de la sede. |
| 3 | El usuario presiona el botón "Consultar disponibilidad". | El sistema consulta la API REST enviando sede, tipo de espacio, fecha y horario, y compara las reservas existentes para detectar superposiciones. |
| 4 | El usuario visualiza el listado de canchas disponibles y revisa la información de cada opción. | El sistema muestra tarjetas con nombre de cancha, sede, tipo de deporte, dirección, horario consultado, estado de disponibilidad y precio si corresponde. |
| 5 | El usuario selecciona una cancha disponible o modifica los filtros para realizar una nueva búsqueda. | El sistema conserva los criterios seleccionados y, si el usuario elige una cancha, habilita la continuidad hacia el caso de uso "Reservar espacio deportivo". |

**Flujos alternativos y de excepción** (fuente: CU-13)
- **FA1 · Sin canchas disponibles.** Origen: paso 4. Condición: la API no encuentra canchas
  disponibles para la sede, tipo, fecha y rango. Sistema: mensaje de disponibilidad vacía, por
  ejemplo «No hay canchas disponibles para este horario», y permite modificar fecha, horario, sede o
  tipo sin perder el contexto de búsqueda.
- **FA2 · Fecha u horario inválido.** Origen: paso 2. Condición: fecha pasada, hora que no comienza
  o finaliza en minuto 00, duración menor a una hora u horario fuera del funcionamiento de la sede.
  Sistema: bloquea la consulta, muestra el mensaje de validación correspondiente y solicita corregir
  los filtros antes de llamar al backend.
- **FA3 · Error de conexión a Internet.** Origen: paso 3. Sistema: modal o pantalla «Error de
  conexión» con opción de reintentar, manteniendo visibles los filtros.
- **FA4 · Error en el servidor / falla en la API.** Origen: paso 3. Condición: timeout, error interno
  o datos incompletos. Sistema: informa que no se pudo consultar la disponibilidad, ofrece reintentar
  más tarde y «evita mostrar resultados desactualizados como si fueran confirmados».

**Diseño declarado en el CU** (fuente: CU-13)
- Pantallas: filtros · listado de canchas disponibles · estado vacío con acceso rápido para cambiar
  fecha u horario · error de conectividad y de servidor con reintento. Modo oscuro y claro.
- Selector de sede; chips o lista para tipo de deporte («Fútbol», «Pádel», «Tenis», «Básquet»,
  etc.); DatePicker y TimePicker con intervalos de hora completa; botones «Consultar
  disponibilidad» y «Limpiar filtros» o «Modificar búsqueda»; indicador de carga.

**Reglas que sólo están en el enunciado** (fuente: enunciado)
- RF 3: horarios dentro del funcionamiento de la sede; duración mínima una hora; inicio y fin en el
  minuto 00; «La hora de finalización de una reserva no podrá superar el horario de cierre de la
  sede»; horarios futuros; sin superposición para el mismo espacio y fecha.

**Pantallas del prototipo** (fuente: Figma)
- Filtros: SEDE, DEPORTE, TIPO DE CANCHA («Todos los tipos»), FECHA, DESDE, HASTA; «Elegí sede,
  deporte y rango horario. Solo horas completas, de 1 a 4 horas.»; botones LIMPIAR y CONSULTAR.
- Inválido: «La fecha tiene que ser futura», «La duración mínima es de una hora».
- Resultados: «2 CANCHAS DISPONIBLES · FÚTBOL 5 · 18:00 – 19:00», chips «Todas (2) · Polvo (1) ·
  Cemento (1)», tarjetas con «VER HORARIOS / RESERVAR».
- Sin resultados: «No hay canchas disponibles» · «Ninguna cancha coincide con ese horario. Probá
  con otro rango o otra sede.» · LIMPIAR FILTROS.
- Error: «No se pudo consultar la disponibilidad» · «Revisá tu conexión e intentá nuevamente. Los
  filtros que cargaste se mantienen.» · VOLVER · REINTENTAR.

## Escenarios

- [ ] CU-13-H01-01 — consulta sede, tipo, fecha y rango y ve sólo las canchas libres en todo ese rango
- [ ] CU-13-H01-02 — una cancha con una reserva que se superpone con el rango no aparece como disponible
- [ ] CU-13-H01-03 — elige una cancha del resultado y pasa a reservarla con el horario consultado
- [ ] CU-13-H01-04 — después de consultar, los filtros siguen visibles y se pueden cambiar
- [ ] CU-13-H02-01 — ninguna cancha está libre en el rango y ve el aviso sin perder los filtros
- [ ] CU-13-H03-01 — elige una fecha pasada y no se consulta
- [ ] CU-13-H03-02 — elige un rango de menos de una hora y no se consulta
- [ ] CU-13-H03-03 — elige un rango que termina después del cierre de la sede y no se consulta
- [ ] CU-13-H04-01 — sin conexión al consultar, ve el error y conserva los filtros
- [ ] CU-13-H05-01 — el servidor falla al consultar y no se muestran resultados viejos

## Contradicciones dentro de la card

- El paso 5 lleva la cancha elegida a «Reservar espacio deportivo» con el horario ya consultado; el
  prototipo pone en cada tarjeta «VER HORARIOS / RESERVAR», que lleva a la grilla de horarios ·
  CU-13 paso 5, Figma 52:824.
- El prototipo limita el rango a «de 1 a 4 horas»; el CU y el enunciado sólo fijan el mínimo de una
  hora y el cierre de la sede · Figma 52:734, CU-13 FA2, enunciado RF 3.
- En los resultados de Fútbol 5, los chips del prototipo son «Polvo» y «Cemento», superficies de
  tenis · Figma 52:824.
- El CU nombra Pádel y Básquet como tipos; el prototipo tiene Fútbol, Tenis, Hockey, Vóley y Golf ·
  CU-13 diseño, Figma 52:734.
- El CU pide el horario «futuro»; no dice si un rango que empieza en la hora en curso cuenta como
  futuro · CU-13 paso 2.
