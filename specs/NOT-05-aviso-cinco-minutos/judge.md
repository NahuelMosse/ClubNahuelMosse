- ACT-01 · H · NOT-05-ASM-02 promete el aviso de 5 minutos a «una reserva creada con menos de 5 minutos de anticipación», pero T1 reutiliza `vencidos` y `_sigue_vigente`, que excluyen toda reserva con `greatest(creado_en, modificado_en) > inicio - anticipacion`; si esa anticipación pasa a ser de 5 minutos, la reserva nunca recibe el aviso. El único test planeado para ASM-02 cubre la reserva «que ya empezó», no la creada tarde. Pregunta de interpretation sin responder: «Does a quantifier name its members, and does each member have a test?» · card.md L16, L20 · plan · closed · NOT-05-ASM-02 (la misma regla que el recordatorio de una hora) y su test
- ACT-02 · H · S1 exige que el aviso salga una sola vez y solo para una reserva activa, pero el despacho filtra por el literal 'recordatorio': `tomar_siguiente` (`n.tipo <> 'recordatorio' OR (... r.estado = 'activa' AND r.inicio > now())`) despacharía un `recordatorio_cinco` pendiente de una reserva ya cancelada, movida o empezada, y `marcar_varados_fallidos` nunca lo pasaría a `fallida`. Ninguna tarea nombra esas funciones ni las prueba. Pregunta de contract sin responder: «Does an existing client keep working: which route, field or status of main changes?» · card.md L13, L20-21 · plan · closed · NOT-05-ASM-03 y su test de integración (`tomar_siguiente` y `marcar_varados_fallidos` tratan los dos tipos)

## Verified

- interpretation: fails (ACT-01)
- quantifiers: fails (ACT-01)
- contract: fails (ACT-02)
- overdesign: meets · T1 y T2 extienden archivos que ya existen, sin capas, interfaces ni patrones nuevos
