# Implementation Plan: CU-22 · Editar espacio deportivo

**Branch**: `card/CU-22` | **Date**: 2026-09-30 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

Cada espacio del panel tiene «Editar», que abre «Editar espacio deportivo»: sede, deporte y tipo
a la vista y deshabilitados, condición, iluminación y precio por hora editables, y el nombre
compuesto confirmado. GUARDAR ESPACIO se habilita sólo con un cambio válido. Al guardar, un aviso y
el listado con el precio nuevo; las reservas ya hechas conservan el suyo. Si otra sesión dio de
baja el espacio, «Esto cambió mientras tanto» y el listado. DAR DE BAJA EL ESPACIO abre la
confirmación de CU-23.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Storage**: `UPDATE` de `techada`, `iluminada`, `precio_por_hora` y `modificado_*` de `espacio`;
el nombre compuesto no cambia (trigger `nombre_espacio_inmutable`) y cada reserva guarda su
precio
**Testing**: `integration_test` con espacios y reservas cargados por la API y bajas por
`/_pruebas/espacios/baja`; integración de `PUT /espacios/{id}`; widget del formulario

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Nueve escenarios; pantallas 63:1895, 63:2302, 390:6522 y 393:6532 |
| II · Nada se supone en silencio | `CU-22-SUP-01` a `SUP-07`; AMB-04 resuelta |
| III · Tests antes del código | Nueve escenarios congelados en rojo en `e26f9e9` |
| IV · El backend es la autoridad | La API valida el precio y decide si el espacio sigue activo |
| V · Rastro | `modificado_por` y `modificado_en`; la reserva guarda el precio del momento (decisión 4) |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-22-SUP-01 | La condición es techada o al aire libre, más la iluminación; no hay «fuera de servicio» | `CambioDeEspacio`, `PantallaEditarEspacio` |
| CU-22-SUP-02 | Pesos enteros entre $ 1 y $ 9.999.999 | `validar_cambio` |
| CU-22-SUP-03 | Gana el último que guarda, campo por campo | `PUT /espacios/{id}` sólo con lo que cambió |
| CU-22-SUP-04 | DAR DE BAJA EL ESPACIO abre la confirmación de CU-23 | `confirmarBajaDeEspacio`; `@CU-22-H07-01` |
| CU-22-SUP-05 | Los mensajes del alta; las letras no se escriben | `validar_cambio`, `FormatoPrecio`; `@CU-22-H03-01` |
| CU-22-SUP-06 | GUARDAR ESPACIO deshabilitado sin un cambio válido | `PantallaEditarEspacio`; `@CU-22-H04-01` |
| CU-22-SUP-07 | Un aviso y el listado; FA4 con «Esto cambió mientras tanto» | `PantallaEditarEspacio`; `@CU-22-H05-01` |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/app/dominio/espacios.py` | `CambioDeEspacio`, `validar_cambio` | la regla del precio es la misma del alta |
| `apps/api/app/infraestructura/espacios.py` | `EspaciosSql.actualizar` | la sede compartida y después la fila del espacio, el orden de una reserva: la que se está guardando toma el precio de antes o el de ahora, entero; lo que no vino queda como estaba; si el espacio se dio de baja entre el chequeo y el `UPDATE`, no se guardó nada y es 404 |
| `apps/api/app/interfaz/espacios.py` | `PUT /espacios/{id}` | cada campo es opcional y el que no viene no se toca; 404 si el espacio o su sede no están activos; 422 por campo |
| `apps/mobile/lib/admin/pantalla_editar_espacio.dart` | el formulario | reusa del alta `ParDeCampos` y `NombreGenerado`; manda sólo lo que cambió, así no pisa lo que otro guardó mientras tanto; el precio cargado no se marca hasta que se lo cambia; sede, deporte y tipo apagados pero legibles |
| `apps/mobile/lib/admin/pantalla_espacios_admin.dart` | «Editar» en la tarjeta | la tarjeta se lee como un dato y el botón nombra el espacio |

## Brief visual

**Invención 1 · densidad 3.** Editar es el alta con lo que no se puede tocar a la vista pero
apagado: el administrador ve de qué espacio se trata y sólo puede mover lo que cambia de verdad.

- **Desde dónde.** Desde la tarjeta del espacio en el panel; guardar y cancelar vuelven ahí.
- **Teléfono chico.** En 360 la condición y la iluminación bajan una debajo de la otra; el precio
  y GUARDAR ESPACIO quedan a un scroll corto.
- **Variables visuales.** Apagado = lo que no se edita; lima = el nombre confirmado y la acción
  principal; rojo = el error y la baja.
- **Material.** El del alta de espacio (CU-21) y los overlays compartidos.
