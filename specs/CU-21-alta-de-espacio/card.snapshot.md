---
card: CU-21
extraido: 2026-09-27T12:30:00-03:00
fuentes:
  - CU/CU-21 - Alta Espacio Deportivo.pdf
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 5 Módulo de Espacios deportivos («Cada espacio deportivo deberá estar asociado a una sede y contar, como mínimo, con un tipo y un nombre compuesto por la sede, dirección, tipo de espacio deportivo y un número. Por ejemplo: Moron_Rivadavia_19850_Paddle_1.»)"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 63:1895 CU-21 · Gestionar espacios"
  - "Figma · 63:2030 CU-21 · Alta espacio · Formulario vacío"
  - "Figma · 63:2101 CU-21 · Alta espacio · Formulario completo"
  - "Figma · 63:2162 CU-21 · Alta espacio · Campo obligatorio"
  - "Figma · 63:2223 CU-21 · Alta espacio · Duplicado"
  - "Figma · 64:2065 CU-21 · Alta espacio · Éxito"
no_leido:
  - "las imágenes de pantalla embebidas en el PDF del CU (pdftotext solo extrae texto)"
estado: propuesta
---

# Snapshot — CU-21 · Alta de espacio deportivo

## Card, tal como está escrita

**Definición** (fuente: CU-21)
- Actor principal: Administrador.
- Objetivo: «Registrar un nuevo espacio deportivo en el sistema, asociándolo a una sede existente,
  para que quede disponible para ser reservado por los usuarios.»
- Problema que resuelve: sin este flujo no se incorporan espacios al catálogo; el alta centralizada
  mantiene la oferta «(canchas de fútbol, paddle, básquet, etc.)» y vincula cada espacio a su sede
  «con un nombre estandarizado».

**Precondiciones** (fuente: CU-21)
- El administrador debe estar autenticado en el sistema con rol de administrador.
- Debe existir al menos una sede cargada en el sistema.
- El administrador debe tener permisos para gestionar espacios deportivos.

**Poscondiciones** (fuente: CU-21)
- El nuevo espacio deportivo queda registrado en la base de datos con estado activo.
- Queda asociado a la sede seleccionada y visible para los usuarios en el listado de espacios
  disponibles.
- El nombre se genera automáticamente a partir de la sede, dirección, tipo y un número asignado por
  el sistema, con el formato `Sede_Dirección_Deporte_Tipo_Número` (ej. `Moron_Rivadavia_Futbol_F5_1`).

**Flujo principal** (fuente: CU-21)
| Paso | Actor | Sistema |
|---|---|---|
| 1 | El administrador accede al módulo de gestión de espacios deportivos y selecciona la opción "+ Alta espacio". | El sistema muestra el formulario "Nuevo espacio deportivo" con los campos: sede, deporte, tipo, precio por hora, y una vista previa del nombre generado. |
| 2 | Selecciona la sede a la que se asociará el nuevo espacio deportivo. | El sistema toma la sede y su dirección para componer el nombre, y habilita los campos de deporte y tipo. |
| 3 | Selecciona el deporte y el tipo (ej. Fútbol / Fútbol 5) e ingresa el precio por hora. | El sistema asigna automáticamente el próximo número disponible para ese tipo en esa sede y actualiza la vista previa del nombre. |
| 4 | Verifica los datos ingresados y el nombre generado automáticamente (ej. Moron_Rivadavia_Futbol_F5_1). | El sistema mantiene la vista previa del nombre compuesto y habilita el botón "Guardar espacio". |
| 5 | Presiona "Guardar espacio". | El sistema valida que no exista un espacio duplicado, registra el nuevo espacio deportivo (asociado a la sede, con su tipo y precio por hora) en la base de datos y muestra un mensaje de éxito. |

**Flujos alternativos y de excepción** (fuente: CU-21)
- **FA1 · Espacio deportivo duplicado.** Origen: paso 5. Condición: ya existe un espacio con el mismo
  nombre compuesto (misma sede, tipo y número). Sistema: «Ya existe un espacio deportivo con ese
  nombre en la sede seleccionada» y recalcula el próximo número disponible.
- **FA2 · Datos incompletos o inválidos.** Origen: pasos 2, 3 o 5. Condición: falta la sede, el
  deporte, el tipo o el precio por hora. Sistema: «Guardar espacio» deshabilitado; resalta el campo
  faltante indicando que es obligatorio.
- **FA3 · Error de conexión o servidor.** Origen: paso 5. Sistema: «No se pudo guardar el espacio
  deportivo. Verifique su conexión e intente nuevamente» y conserva los datos para reintentar.

**Diseño declarado en el CU** (fuente: CU-21)
- Pantallas: listado de espacios (admin) · formulario vacío · confirmación de alta · formulario
  completo · dropdowns de Sede (4 sedes), Deporte (Fútbol, Tenis, Paddle, Hockey, Vóley, Golf) y Tipo
  (según el deporte: Fútbol → F5/F7/F11) · duplicado (Snackbar-Error) · campo obligatorio
  (Inline-Error bajo Tipo) · error de conexión (Snackbar-Error).
- Btn-Primary «Guardar espacio» (40 % de opacidad deshabilitado), Btn-Secondary «Cancelar»,
  «+ Alta espacio», «Ir al listado», «Crear otro»; Input-Precio con prefijo «$» y validación
  numérica; Card-PreviewNombre punteada si está incompleta; Toast «¡Espacio deportivo creado!»;
  Inline-Error «⚠ Este campo es obligatorio».

**Reglas que sólo están en el enunciado** (fuente: enunciado)
- RF 5: asociado a una sede; tipo y nombre compuesto por sede, dirección, tipo y número, ejemplo
  `Moron_Rivadavia_19850_Paddle_1`. Filtrable por tipo.

**Pantallas del prototipo** (fuente: Figma)
- Gestionar espacios: «17 ESPACIOS ACTIVOS · 4 SEDES», tarjetas con deporte, tipo, condición,
  precio, código, Editar y Baja.
- Formulario: «El nombre se arma solo con la sede, la dirección, el deporte, el tipo y el número.»;
  SEDE, DEPORTE, TIPO, PRECIO POR HORA, NOMBRE GENERADO AUTOMÁTICAMENTE; GUARDAR ESPACIO · CANCELAR.
  Nombre de ejemplo `Moron_Rivadavia_19850_Futbol_F5_3`.
- Éxito: «¡Espacio deportivo creado!» · «Ya está disponible para que los usuarios lo reserven.» · IR
  AL LISTADO · Crear otro.

## Escenarios

- [ ] CU-21-H01-01 — da de alta un espacio con sede, deporte, tipo y precio, y los usuarios lo ven en la sede
- [ ] CU-21-H01-02 — el nombre se arma solo con la sede, la dirección, el deporte, el tipo y el siguiente número libre
- [ ] CU-21-H01-03 — un usuario sin rol de administrador no puede dar de alta un espacio
- [ ] CU-21-H02-01 — el nombre calculado ya existe al guardar: ve el error y el número se recalcula
- [ ] CU-21-H03-01 — falta un campo obligatorio y no puede guardar
- [ ] CU-21-H04-01 — sin conexión o con el servidor caído al guardar, ve el error y conserva lo cargado

## Contradicciones dentro de la card

- El formato del CU es `Sede_Dirección_Deporte_Tipo_Número` con el ejemplo `Moron_Rivadavia_Futbol_F5_1`,
  sin altura; el enunciado usa `Moron_Rivadavia_19850_Paddle_1`, con altura y sin deporte separado
  del tipo; el prototipo usa `Moron_Rivadavia_19850_Futbol_F5_3` · CU-21 poscondiciones, enunciado
  RF 5, Figma 63:2101.
- CU-16 exige que cada cancha tenga condición techada o al aire libre, iluminación y franja horaria;
  el formulario de alta sólo pide sede, deporte, tipo y precio · CU-16 precondiciones, CU-21 paso 1.
- El CU incluye Paddle entre los deportes; los datos del prototipo no tienen ningún espacio de pádel
  · CU-21 diseño, Figma 63:1895.
- El número se asigna solo, así que un duplicado sólo puede venir de dos altas simultáneas; el
  prototipo de duplicado muestra el nombre `…_F5_1`, que ya existe · CU-21 FA1, Figma 63:2223.
- El CU pide Snackbar-Error para conexión; el prototipo usa los overlays compartidos · CU-21 FA3,
  Figma 42:384.
