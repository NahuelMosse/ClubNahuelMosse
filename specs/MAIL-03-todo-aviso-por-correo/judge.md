# MAIL-03 · plan judge

- ACT-01 · M · S1 nombra sus miembros («el recordatorio de una hora antes, la cancelación que hace el club o un administrador (también la agrupada por baja de sede o espacio) y la confirmación de la cancelación que hizo la persona») y el único test de S1 llama a `entregar` con un solo aviso `cancelacion_forzosa`; no hay test planeado por miembro (cancelación de administrador, agrupada por baja de sede/espacio, confirmación propia) que muestre que cada uno sale por correo · card.md S1, T1 `tests:` · lenses.md interpretation/quantifiers «Does a quantifier ("each", "all", "any") name its members, and does each member have a test?» · plan · closed · T1 «el recordatorio, la cancelación del club, la agrupada y la propia salen cada una por correo»
- ACT-02 · M · todo correo que no es el recordatorio depende de `NotificacionesSql.destinatario` (repositorio.py, `data` en T1) y ningún test planeado lo ejerce contra la base: los tests de T1 usan un repositorio falso. Como S2 hace que un fallo del correo sólo quede en el log, un SQL roto deja la suite verde y ningún correo de cancelación sale · card.md T1 «apps/api/app/modules/notificaciones/repositorio.py (data)» y S2 «si el correo falla queda en el log» · lenses.md contract «Does an existing client keep working…» / quantifiers (miembro sin test) · plan · closed · T1 «el destinatario de un aviso sale de la base…» (integración contra Postgres); MAIL-03-ASM-04

## Verified

- interpretation · meets (S1 y S2 cubren L1; ASM-01..03 declaran las lecturas abiertas)
- quantifiers · fails (ACT-01)
- contract · fails (ACT-02) · no cambia ruta, campo ni estado del API; el hueco es el camino de datos sin test
- overdesign · meets (`destinatario` del protocolo tiene falso en el test; el parámetro opcional de `entregar` lo justifica ASM-01; `Destinatario` lo comparten recordatorio y despacho)
