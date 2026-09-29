# Implementation Plan: CU-18 · Editar sede

**Branch**: `card/CU-18` | **Date**: 2026-09-29 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

Cada sede del panel tiene «Editar sede», que abre el mismo formulario del alta con los datos
cargados: nombre, dirección, apertura, cierre y días que abre. GUARDAR CAMBIOS se deshabilita
mientras un campo tenga error. Si el horario nuevo deja afuera reservas futuras, la API
responde cuántas son y la app pide confirmar con «¿Guardar el horario nuevo?». GUARDAR IGUAL
guarda y las reservas se mantienen; REVISAR EL HORARIO vuelve al formulario. Al guardar, un
aviso y el listado releído. Si otra sesión dio de baja la sede, «Esto cambió mientras tanto» y
el listado. DAR DE BAJA LA SEDE abre la confirmación de CU-19.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Storage**: `UPDATE` de la fila de `sede` con `modificado_por` y `modificado_en`; las reservas
y los nombres de los espacios no se tocan
**Testing**: `integration_test` con sedes y espacios cargados por la API y bajas por
`/_pruebas/sedes/baja`; integración de `PUT /sedes/{id}`; widget del formulario

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Diez escenarios; pantallas 62:1648, 62:1968, 62:2035, 393:6496, 42:329 y 393:6532 |
| II · Nada se supone en silencio | `CU-18-SUP-01` a `SUP-09`; AMB-04 y AMB-05 resueltas |
| III · Tests antes del código | Diez escenarios congelados en rojo en `0d87f4e` |
| IV · El backend es la autoridad | La API valida los datos, el nombre único y cuenta las reservas que quedan afuera |
| V · Rastro | `modificado_por` y `modificado_en` (decisión 4) |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-18-SUP-01 | Otro nombre en uso: «Ya existe una sede con ese nombre» | índice `sede_nombre_activa_unico`, `SedesSql.actualizar` |
| CU-18-SUP-02 | Los límites del alta | `validar_sede` |
| CU-18-SUP-03 | Gana el último que guarda | `SedesSql.actualizar`, sin versión |
| CU-18-SUP-04 | Las reservas afuera se mantienen; se cuentan las que el horario nuevo deja afuera y el de antes admitía | `SedesSql.actualizar`; `@CU-18-H04-01` |
| CU-18-SUP-05 | La edición incluye DÍAS QUE ABRE | `PantallaFormularioSede` |
| CU-18-SUP-06 | GUARDAR CAMBIOS deshabilitado con un error | `PantallaFormularioSede`; `@CU-18-H03-01` |
| CU-18-SUP-07 | La sede dada de baja: «Esto cambió mientras tanto» y el listado | `PantallaFormularioSede`; `@CU-18-H05-01` |
| CU-18-SUP-08 | DAR DE BAJA LA SEDE abre la confirmación de CU-19 | `confirmarBajaDeSede`; `@CU-18-H07-01` |
| CU-18-SUP-09 | Un aviso abajo y el listado releído | `PantallaFormularioSede`; `@CU-18-H01-01` |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/app/aplicacion/sedes.py` | `editar_sede` | sólo un administrador; las mismas reglas que el alta |
| `apps/api/app/infraestructura/sedes.py` | `SedesSql.actualizar` | la sede se toma exclusiva, así una reserva que se está haciendo en ella termina antes o espera al horario nuevo; una reserva queda afuera si, en la hora del club, empieza antes de la apertura, termina después del cierre (a las 00:00 es la medianoche) o cae en un día que la sede no abre; sólo se cuentan las futuras activas que el horario de antes admitía, así lo que ya estaba afuera no se vuelve a preguntar |
| `apps/api/app/aplicacion/reservas.py`, `apps/api/app/infraestructura/reservas.py` | reservar y modificar con la agenda vigente | `insertar` y `mover` reciben la agenda con que se validó y la comparan con la de la sede ya tomada; si un administrador la cambió en el medio, se vuelve a validar con la nueva: ninguna reserva entra con el horario viejo |
| `apps/api/app/interfaz/sedes.py` | `PUT /sedes/{id}` | 404 si no está activa; 409 `errores.nombre` o `reservas_afuera` sin `confirmar`; 422 por campo |
| `apps/mobile/lib/admin/pantalla_formulario_sede.dart` | el formulario del alta y de la edición | uno solo, con `editando`; el aviso de reservas afuera dice qué se achicó (apertura, cierre o días) y, si fue más de una cosa, habla del horario nuevo |
| `apps/mobile/lib/admin/pantalla_sedes_admin.dart` | «Editar sede» en la tarjeta | la tarjeta se lee como un dato y el botón aparte nombra la sede |
| `apps/mobile/lib/comun/dialogo_error.dart` | «¿Guardar el horario nuevo?» y «¿Dar de baja la sede?» | el mismo `Modal`; la baja en rojo |

## Brief visual

**Invención 1 · densidad 3.** Editar es el alta con los datos puestos: el administrador ya
conoce el formulario, y lo único nuevo es la advertencia cuando el horario deja reservas afuera.

- **Desde dónde.** Desde la tarjeta de la sede en el panel; guardar vuelve ahí.
- **Teléfono chico.** En 360 los cinco campos entran con scroll corto; GUARDAR CAMBIOS y DAR DE
  BAJA LA SEDE quedan fijos abajo.
- **Variables visuales.** Rojo = lo que no se deshace (la baja) y el campo con error; lima = la
  acción principal.
- **Material.** El del alta de sede (CU-17) y los overlays compartidos.
