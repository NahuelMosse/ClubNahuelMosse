# Implementation Plan: CU-23 · Baja de espacio deportivo

**Branch**: `card/CU-23` | **Date**: 2026-09-29 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

«Baja», en la tarjeta de cada espacio del panel, y DAR DE BAJA EL ESPACIO, en su edición, piden
confirmación con el nombre compuesto y avisan que la acción es permanente. Al confirmar, la API
da de baja el espacio (baja lógica, con fecha y autor) y el listado queda sin él, con «El espacio
fue dado de baja correctamente». La sede muestra una cancha menos y el espacio deja de poder
reservarse. Con reservas que todavía no terminaron, la baja no se hace y se avisa. Si ya lo dio
de baja otra sesión, «Esto cambió mientras tanto». Con un error de red, el aviso compartido y el
espacio intacto.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Storage**: `activo`, `dado_de_baja_en` y `dado_de_baja_por` de `espacio`
**Testing**: `integration_test` con sedes y espacios cargados por la API; integración de
`DELETE /espacios/{id}`; widget del flujo

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Cinco escenarios; pantallas 63:1895, 42:368, 42:384, 42:410 y 393:6532 |
| II · Nada se supone en silencio | `CU-23-SUP-01` a `SUP-05`; AMB-02, 03, 04 y 07 resueltas |
| III · Tests antes del código | Cinco escenarios congelados en rojo en `abb76a1` |
| IV · El backend es la autoridad | La API decide si el espacio sigue activo y si tiene reservas pendientes |
| V · Rastro | Baja lógica con fecha y autor (decisión 4) |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-23-SUP-01 | Ya dado de baja: «Esto cambió mientras tanto» y el listado | `darDeBaja` |
| CU-23-SUP-02 | Sólo un administrador | `dar_de_baja_espacio` |
| CU-23-SUP-03 | Se puede dar de baja el último espacio de una sede | `EspaciosSql.dar_de_baja`, sin chequeo |
| CU-23-SUP-04 | Con una reserva sin terminar no se da de baja | `EspaciosSql.dar_de_baja` (`fin > now()`), `mostrarEspacioConReservas` |
| CU-23-SUP-05 | El listado sin el espacio y el aviso; desde la edición termina en el listado | `darDeBajaEspacio`; `@CU-23-H01-01` |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/app/aplicacion/espacios.py` | `dar_de_baja_espacio` | sólo un administrador; con reservas pendientes no se permite (decisión 5) |
| `apps/api/app/infraestructura/espacios.py` | `EspaciosSql.dar_de_baja` | la sede compartida y el espacio exclusivo, el orden de una reserva: la que se está haciendo termina antes y cuenta, o espera y encuentra el espacio dado de baja |
| `apps/api/app/interfaz/espacios.py` | `DELETE /espacios/{id}` | 204; 404 si no está activo; 409 `errores.espacio` con reservas pendientes |
| `apps/mobile/lib/admin/baja.dart` | la confirmación, el pedido y los avisos de una baja | lo comparten la sede (CU-19) y el espacio; mientras el pedido está en camino no se toca el listado ni el formulario; después de un corte, que ya no esté es el éxito del pedido cortado |
| `apps/mobile/lib/admin/baja_sede.dart`, `apps/mobile/lib/admin/baja_espacio.dart` | la baja de cada uno sobre `baja.dart` | la sede vuelve a su listado, el espacio al suyo |
| `apps/mobile/lib/admin/pantalla_espacios_admin.dart` | «Baja» en la tarjeta | al lado de «Editar», apilados con cualquier agrandado del texto; cada uno nombra el espacio; mientras la baja está en camino no se sale del listado |
| `apps/mobile/lib/admin/pantalla_editar_espacio.dart` | DAR DE BAJA EL ESPACIO | mientras la baja está en camino, su botón espera y el formulario no se toca |
| `apps/mobile/lib/espacios/espacios.dart`, `apps/mobile/lib/comun/dialogo_error.dart` | `darDeBaja` y «No se puede dar de baja el espacio» | 404 y 409 como excepciones propias |

## Brief visual

**Invención 1 · densidad 3.** La misma baja que la de sede: un botón rojo, una confirmación que
dice que no se deshace y un aviso de que salió.

- **Desde dónde.** Desde la tarjeta del espacio en el panel o desde su edición; termina en el
  listado.
- **Teléfono chico.** En 360 «Editar» y «Baja» van lado a lado; con el texto grande, uno abajo
  del otro.
- **Variables visuales.** Rojo = lo que no se deshace.
- **Material.** Los overlays compartidos del prototipo.
