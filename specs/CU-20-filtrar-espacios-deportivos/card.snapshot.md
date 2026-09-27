---
card: CU-20
extraido: 2026-09-27T11:40:00-03:00
fuentes:
  - CU/CU-20 - Filtrar espacios deportivos.pdf
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 5 Módulo de Espacios deportivos («Permitir filtrar los espacios deportivos por tipo (Fútbol, Paddle, Básquet, etc.)»)"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 53:431 CU-20 · Sede Morón · Fútbol · Todos"
  - "Figma · 54:604 CU-20 · Sede Morón · Fútbol 5 · 123:5686 · Fútbol 7 · 123:5984 · Fútbol 11"
  - "Figma · 54:818 CU-20 · Sede Morón · Hockey (sin variantes)"
  - "Figma · 121:5256 CU-20 · Sede Morón · Tenis · 123:6273 · Tenis · Polvo de ladrillo · 123:6473 · Tenis · Cemento"
  - "Figma · 120:4885 San Justo · Fútbol · 121:5974 San Justo · Golf · 120:5389 Castelar · Tenis · 121:5647 Castelar · Vóley · 406:6534 Sede Ramos Mejía"
  - "Figma · 54:986 CU-16 · Sede sin canchas"
  - "Figma · 42:384 Error de conexión · 42:410 Error del servidor (overlays compartidos)"
no_leido:
  - "las imágenes de pantalla embebidas en el PDF del CU (pdftotext solo extrae texto)"
estado: propuesta
---

# Snapshot — CU-20 · Filtrar espacios deportivos

Doble lectura: dos lecturas independientes del CU y del enunciado, más la propia. Las tres
coincidieron en los flujos y en los escenarios; las diferencias están en `ambiguedades.md`.

## Card, tal como está escrita

**Definición** (fuente: CU-20)
- Actor principal: Usuario registrado.
- Objetivo: «Mostrar únicamente las canchas de una sede que coinciden con el deporte y el tipo de
  cancha que elige el usuario.»
- Problema que resuelve: «La dificultad de encontrar una cancha cuando la sede ofrece varios
  deportes y modalidades.»

**Precondiciones** (fuente: CU-20)
- El usuario debe estar autenticado en la aplicación.
- El usuario debe estar en la pantalla de una sede.

**Poscondiciones** (fuente: CU-20)
- El listado muestra solo las canchas que cumplen con el filtro seleccionado.
- El contador refleja la cantidad de canchas y el deporte filtrado.
- Los chips seleccionados quedan resaltados y el filtro se mantiene mientras el usuario siga en la
  sede.
- No se modifica ningún dato: la operación es de solo lectura.

**Flujo principal** (fuente: CU-20)
| Paso | Actor | Sistema |
|---|---|---|
| 1 | El usuario abre la pantalla de una sede. | El sistema muestra los chips de deporte con el primero seleccionado y el listado de canchas de ese deporte. |
| 2 | El usuario presiona el chip de un deporte. | El sistema resalta el chip, muestra las variantes de ese deporte en "Todos" y filtra el listado. |
| 3 | El usuario presiona el chip de una variante. | El sistema resalta el chip, muestra solo las canchas de ese tipo y actualiza el contador. |

**Flujos alternativos y de excepción** (fuente: CU-20)
- **FA1 · Deporte sin variantes.** Origen: paso 2. Condición: el deporte elegido tiene una sola
  modalidad en esa sede. Sistema: no muestra la barra de variantes y filtra solo por deporte. El
  caso de uso termina en el paso 2.
- **FA2 · Quitar el filtro de variante.** Origen: paso 3. Condición: presiona el chip «Todos».
  Sistema: vuelve a mostrar todas las canchas del deporte seleccionado. El filtro de deporte no
  cambia.
- **FA3 · Sede sin canchas.** Origen: paso 1. Condición: la sede no tiene ninguna cancha activa.
  Sistema: no muestra los chips de filtro y avisa que la sede no tiene canchas disponibles.
- **FA4 · Error de conexión a Internet.** Origen: pasos 1, 2 o 3. Condición: al aplicar el filtro
  detecta falta de conectividad. Sistema: alerta y pide reintentar una vez restablecida la conexión.
  «El listado no cambia.»
- **FA5 · Error en el servidor/falla en la API.** Origen: pasos 1, 2 o 3. Condición: la petición HTTP
  falla. Sistema: informa el error del servidor y solicita reintentar más tarde. «El listado no
  cambia.»

**Diseño declarado en el CU** (fuente: CU-20)
- Pantallas: Fútbol · Todos · Fútbol 5 · Fútbol 11 · Hockey · Vóley · sede sin canchas · error de
  conexión · error del servidor, en modo nocturno y claro. Acento lima para el elemento
  seleccionado.
- Chips de deporte «Fútbol», «Hockey», «Vóley»; chips de variante «Todos», «Fútbol 5», «Fútbol 11»;
  botón «Ver horarios / Reservar» en cada tarjeta; botón «Aceptar» en los errores. Contador de
  canchas con el filtro aplicado.

**Reglas que sólo están en el enunciado** (fuente: enunciado)
- RF 5: «Mostrar el listado de espacios deportivos indicando la sede donde se ubica cada uno.» «Cada
  espacio deportivo deberá estar asociado a una sede y contar, como mínimo, con un tipo y un nombre
  compuesto por la sede, dirección, tipo de espacio deportivo y un número.» «Permitir filtrar los
  espacios deportivos por tipo (Fútbol, Paddle, Básquet, etc.).»

**Pantallas del prototipo** (fuente: Figma)
- Sección DEPORTE con chips por deporte (con emoji); sección TIPO DE CANCHA con «Todos» y las
  variantes (Fútbol 5 · Fútbol 7 · Fútbol 11; Polvo de ladrillo · Cemento).
- Contador: «4 CANCHAS · FÚTBOL · TODOS LOS TIPOS», «2 CANCHAS · FÚTBOL 5», «1 CANCHA · HOCKEY»,
  «2 CANCHAS · TODOS LOS DEPORTES» (Ramos Mejía, sin deporte elegido).
- Hockey en Morón: sin sección TIPO DE CANCHA.

## Escenarios

- [ ] CU-20-H01-01 — elige un deporte en una sede y sólo ve las canchas de ese deporte, con el contador
- [ ] CU-20-H01-02 — elige una variante y sólo ve las canchas de ese tipo, con el contador actualizado
- [ ] CU-20-H01-03 — una cancha recién dada de alta aparece al filtrar por su deporte y su tipo
- [ ] CU-20-H01-04 — el filtro elegido se mantiene mientras sigue en la sede
- [ ] CU-20-H02-01 — elige un deporte con una sola modalidad y no aparece la barra de variantes
- [ ] CU-20-H03-01 — toca «Todos» y vuelve a ver todas las canchas del deporte, sin perder el deporte
- [ ] CU-20-H04-01 — entra a una sede sin canchas y no ve chips, sólo el aviso
- [ ] CU-20-H05-01 — sin conexión al filtrar, ve la alerta y el listado no cambia
- [ ] CU-20-H06-01 — el servidor falla al filtrar, ve el error y el listado no cambia

## Contradicciones dentro de la card

- El paso 1 dice que la sede abre «con el primero seleccionado»; el prototipo de Ramos Mejía abre sin
  deporte elegido («2 CANCHAS · TODOS LOS DEPORTES») · CU-20 paso 1, Figma 406:6534.
- El enunciado pide filtrar «los espacios deportivos por tipo», sobre el listado de espacios
  «indicando la sede donde se ubica cada uno»; el CU filtra sólo dentro de una sede · enunciado
  RF 5, CU-20 precondiciones.
- El enunciado filtra por «tipo»; el CU agrega un segundo nivel, deporte y variante, que el
  enunciado no nombra · enunciado RF 5, CU-20 pasos 2–3.
- FA4 y FA5 suponen que cada filtro consulta al servidor («Al aplicar el filtro, el sistema detecta
  falta de conectividad»); el paso 3 sólo dice que el sistema «filtra el listado» ya cargado ·
  CU-20 FA4, paso 3.
