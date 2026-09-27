---
card: CU-19
extraido: 2026-09-27T12:30:00-03:00
fuentes:
  - CU/CU-19 - Dar de baja sede (Admin).pdf
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 4 Módulo de Sedes · § RF 6 Historial · § RF 7"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 62:1648 CU-17 · Gestionar sedes (acción «Dar de baja»)"
  - "Figma · 62:1968 CU-18 · Editar sede (acción «DAR DE BAJA LA SEDE»)"
  - "Figma · 42:329 CU-19 · Baja de sede · Confirmar (overlay)"
  - "Figma · 42:345 CU-19 · Baja de sede · Reservas futuras (overlay)"
  - "Figma · 393:6532 Algo cambió mientras tanto · 42:410 Error del servidor (overlays compartidos)"
no_leido:
  - "las imágenes de pantalla embebidas en el PDF del CU (pdftotext solo extrae texto)"
estado: propuesta
---

# Snapshot — CU-19 · Dar de baja sede

## Card, tal como está escrita

**Definición** (fuente: CU-19)
- Actor principal: Administrador.
- Objetivo: «Permitir que el administrador elimine una sede existente del sistema mediante una
  acción de confirmación.»
- Problema que resuelve: retirar una sede que ya no debe formar parte de la gestión, «evitando que
  continúe apareciendo como una sede disponible para los usuarios».

**Precondiciones** (fuente: CU-19)
- El administrador debe estar autenticado en la plataforma.
- El administrador debe contar con permisos para gestionar sedes.
- Debe existir la sede seleccionada en el sistema.
- El administrador debe haber ingresado a la pantalla de edición de la sede.

**Poscondiciones** (fuente: CU-19)
- La sede queda eliminada del sistema.
- La sede deja de aparecer en el listado de sedes disponibles.
- Los espacios deportivos asociados a la sede dejan de estar disponibles para nuevas reservas.
- El sistema informa al administrador que la sede fue eliminada correctamente.

**Flujo principal** (fuente: CU-19)
| Paso | Actor | Sistema |
|---|---|---|
| 1 | El administrador accede al listado de sedes. | El sistema muestra las sedes disponibles. |
| 2 | El administrador selecciona una sede y accede a su edición. | El sistema muestra la pantalla Editar Sede con los datos de la sede. |
| 3 | El administrador presiona "DAR DE BAJA". | El sistema muestra un Dialog de confirmación preguntando si desea dar de baja la sede. |
| 4 | El administrador presiona "DAR DE BAJA" en el Dialog. | El sistema valida la operación y elimina la sede. |
| 5 | — | El sistema muestra el mensaje de éxito: "La sede fue dada de baja correctamente." |

**Flujos alternativos y de excepción** (fuente: CU-19)
- **FA1 · Cancelación de la baja.** Origen: paso 2. Sistema: al presionar «CANCELAR» cierra el
  diálogo, mantiene la sede sin cambios y no elimina nada.
- **FA2 · Sede inexistente o ya eliminada.** Origen: paso 3. Sistema: no realiza la operación y
  advierte «La sede ya no se encuentra disponible.»; el administrador puede volver al listado.
- **FA3 · Sede con reservas futuras.** Origen: paso 3. Sistema: impide la eliminación y advierte «No
  se puede dar de baja la sede porque posee reservas futuras asociadas.» El administrador debe
  gestionar esas reservas antes.
- **FA4 · Error al realizar la eliminación.** Origen: paso 3. Sistema: no completa la operación y
  muestra «No se pudo dar de baja la sede. Intente nuevamente.»; el administrador permanece en la
  edición.

**Diseño declarado en el CU** (fuente: CU-19) — Listado de sedes · Editar sede · diálogo de
confirmación · mensaje de éxito. Botones DAR DE BAJA SEDE, CANCELAR, DAR DE BAJA.

**Pantallas del prototipo** (fuente: Figma)
- Confirmar: «¿Dar de baja la sede?» · «Sede Morón · Av. Rivadavia 19850. Sus espacios deportivos
  dejan de estar disponibles.» · DAR DE BAJA · CANCELAR.
- Reservas futuras: «No se puede dar de baja la sede» · «La sede posee reservas futuras asociadas a
  sus espacios deportivos. Gestionalas primero.» · ACEPTAR.
- El listado del panel tiene además «Dar de baja» en cada tarjeta, sin pasar por la edición.

## Escenarios

- [ ] CU-19-H01-01 — da de baja una sede sin reservas futuras, ve el éxito y la sede deja de aparecer para los usuarios
- [ ] CU-19-H01-02 — después de la baja, los espacios de esa sede no se pueden reservar
- [ ] CU-19-H02-01 — cancela en el diálogo y la sede sigue igual
- [ ] CU-19-H03-01 — la sede ya fue dada de baja en otra sesión y se le avisa que no está disponible
- [ ] CU-19-H04-01 — la sede tiene reservas futuras y no se permite la baja
- [ ] CU-19-H05-01 — falla la baja, ve el error y sigue en la edición con la sede intacta

## Contradicciones dentro de la card

- La poscondición dice que la sede «queda eliminada del sistema»; otra dice que sus espacios «dejan
  de estar disponibles para nuevas reservas», y el historial del enunciado incluye reservas pasadas
  que apuntan a esos espacios · CU-19 poscondiciones, enunciado RF 6.
- FA1 tiene origen en el paso 2, pero el diálogo con CANCELAR aparece en el paso 3 · CU-19 FA1.
- FA3 prohíbe la baja con reservas futuras; CU-24.2 existe para avisar cancelaciones forzosas del
  club · CU-19 FA3, CU-24.2.
- La precondición exige entrar por la edición de la sede; el panel del prototipo ofrece «Dar de
  baja» directo en el listado · CU-19 precondiciones, Figma 62:1648.
- El CU cierra con el mensaje «La sede fue dada de baja correctamente.»; el prototipo no tiene esa
  pantalla ni ese mensaje · CU-19 paso 5.
