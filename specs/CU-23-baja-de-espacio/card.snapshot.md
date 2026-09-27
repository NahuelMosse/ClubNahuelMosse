---
card: CU-23
extraido: 2026-09-27T12:30:00-03:00
fuentes:
  - CU/CU-23 - Baja Espacio Deportivo.pdf
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 5 · § RF 6 Historial · § RF 7 Manejo de errores"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 63:1895 CU-21 · Gestionar espacios (acción «Baja»)"
  - "Figma · 42:368 CU-23 · Baja de espacio · Confirmar (overlay)"
  - "Figma · 42:384 Error de conexión · 42:410 Error del servidor (overlays compartidos)"
no_leido:
  - "las imágenes de pantalla embebidas en el PDF del CU (pdftotext solo extrae texto)"
estado: propuesta
---

# Snapshot — CU-23 · Baja de espacio deportivo

## Card, tal como está escrita

**Definición** (fuente: CU-23)
- Actor principal: Administrador.
- Objetivo: «El administrador de la baja de un espacio deportivo.»
- Problema que resuelve: «el administrador puede dar la baja del espacio deportivo en caso de que,
  por algún hecho o inconveniente, el mismo no se encuentre disponible para su uso.»

**Precondiciones** (fuente: CU-23)
- El adminstrador debe haber iniciado sesión en la plataforma.
- El espacio deportivo debe estar creado en la plataforma.

**Poscondiciones** (fuente: CU-23) — «Los espacios deportivos de la sede afectada se ven reducidos
en 1.»

**Flujo principal** (fuente: CU-23)
| Paso | Actor | Sistema |
|---|---|---|
| 1 | El usuario selecciona la opción "Espacios" del panel admin. | El sistema carga y muestra los datos de los espacios deportivos con opciones para dar alta, editar o dar baja. |
| 2 | Seleccionar botón "Baja" en el box correspondiente al espacio a dar de baja. | El sistema muestra un mensaje de confirmación para advertir de que la acción será permanente. |
| 3 | Seleccionar opción "Confirmar Baja". | El sistema vuelve a cargar y mostrar los datos de los espacios deportivos con opciones para dar alta, editar o dar baja, pero sin el espacio que se dio de baja. |

**Flujos alternativos y de excepción** (fuente: CU-23)
- **FA1 · Cancelar la baja.** Origen: paso 3. Sistema: «Retrotrae la acción y vuelve al paso 2 del
  flujo principal sin modificar ningún dato.»

**Diseño declarado en el CU** (fuente: CU-23) — Panel admin (Espacios) · Mensaje de confirmación.

**Reglas que sólo están en el enunciado** (fuente: enunciado)
- RF 6: el historial incluye reservas cuyo horario ya finalizó, que apuntan a espacios.
- RF 7: manejar sin conexión y servidor caído.

**Pantallas del prototipo** (fuente: Figma)
- Confirmar: «¿Dar de baja el espacio?» · «Moron_Rivadavia_19850_Futbol_F5_1. La acción es
  permanente.» · CONFIRMAR BAJA · CANCELAR.

## Escenarios

`H01` es el flujo principal y `H02` es FA1; `H03` son los errores que pide el enunciado (RF 7) y el
CU no trae.

- [ ] CU-23-H01-01 — da de baja un espacio y deja de aparecer en el panel y en la sede para los usuarios
- [ ] CU-23-H01-02 — después de la baja, la sede muestra un espacio menos
- [ ] CU-23-H01-03 — después de la baja, el espacio no se puede reservar
- [ ] CU-23-H02-01 — cancela en la confirmación y el espacio sigue igual
- [ ] CU-23-H03-01 — sin conexión o con el servidor caído al confirmar, el espacio no se da de baja

## Contradicciones dentro de la card

- El CU no dice qué pasa con las reservas futuras del espacio; CU-19 prohíbe dar de baja una sede
  con reservas futuras y CU-11 FA4 da por hecho que un espacio dado de baja deja reservas sin poder
  modificarse · CU-23, CU-19 FA3, CU-11 FA4.
- La acción se anuncia «permanente»; el historial del enunciado sigue mostrando reservas pasadas de
  ese espacio · CU-23 paso 2, enunciado RF 6.
- CU-22 declara que el paso 3 de su edición lleva a esta baja; el CU sólo la inicia desde el listado
  · CU-22 FA6, CU-23 paso 2.
- El CU no trae flujos de error; el enunciado los exige · CU-23, enunciado RF 7.
