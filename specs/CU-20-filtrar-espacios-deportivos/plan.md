# Implementation Plan: CU-20 · Filtrar espacios deportivos

**Branch**: `card/CU-20` | **Date**: 2026-09-28 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

La pantalla de una sede suma dos filas de chips: DEPORTE, con los deportes que tienen canchas en
la sede, y TIPO DE CANCHA, con «Todos» y los tipos de ese deporte, que aparece sólo si el deporte
elegido tiene más de uno. Cada toque pide a la API las canchas de la sede con ese deporte y tipo;
el contador dice cuántas quedan y qué se filtró, como el prototipo. Si el pedido falla, el aviso
de conexión o de servidor y la pantalla quedan como estaban. El filtro sigue mientras el usuario
esté en la sede, también al volver de los horarios.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Storage**: sin cambios
**Testing**: `integration_test` con una sede de dos Fútbol 5, un Fútbol 7 y un Hockey 7 cargada
por la API; la API intermedia para las fallas; test de API del filtro

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Nueve escenarios; pantallas 53:431, 54:604, 54:818, 123:5686, 406:6534 y el resto de CU-20 (decisión 12) |
| II · Nada se supone en silencio | `CU-20-SUP-01` a `SUP-09`; AMB-04 resuelta por la decisión 8 |
| III · Tests antes del código | 8 escenarios congelados en rojo en `6f7f4d3`; H04-01 nació en verde porque la sede sin canchas ya no mostraba filtros desde CU-16 |
| IV · El backend es la autoridad | Qué canchas pasan el filtro lo dice la API en cada toque |
| V · Rastro | No aplica: consulta de sólo lectura |

Los escenarios de CU-16 esperaban el contador sin el filtro; se recongelaron en `32954b9` con el
texto del prototipo.

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-20-SUP-01 | Los chips salen de las canchas activas de la sede | `_Contenido._filtros`; `@CU-20-H01-01` |
| CU-20-SUP-02 | El filtro vive mientras sigue en la sede | estado de `PantallaSede`; `@CU-20-H01-04` |
| CU-20-SUP-03 | El panel del administrador no filtra | — |
| CU-20-SUP-04 | Deportes y tipos en el orden del catálogo | `_tiposEnOrden`, `_filtros` |
| CU-20-SUP-05 | La sede abre con todos los deportes | `_contador`; `@CU-20-H01-01` |
| CU-20-SUP-06 | Filtra dentro de una sede; el listado global es de CU-13 | — |
| CU-20-SUP-07 | Cada filtro consulta a la API; si falla, todo queda igual | `PantallaSede._filtrar`; `@CU-20-H05-01`, `@CU-20-H06-01` |
| CU-20-SUP-08 | Tocar el deporte elegido lo quita; «Todos» quita el tipo | `alElegirDeporte`, `alElegirTipo`; `deporte, tipo, «Todos» y quitar el deporte` |
| CU-20-SUP-09 | El contador dice siempre «canchas» | `_contador` |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/app/interfaz/espacios.py` | `GET /espacios?deporte=&tipo=` | los dos filtros son opcionales y se suman al de sede |
| `apps/mobile/lib/espacios/espacios.dart` | `Espacios.activos(sedeId, deporte, tipo)` | — |
| `apps/mobile/lib/sedes/pantalla_sede.dart` | `_filtrar`, `_Filtro`, `_Chip`, `_contador` | también quitar el deporte pregunta a la API; los chips quedan deshabilitados mientras hay una lectura o un filtro en curso, y la respuesta de un pedido que ya no es el último se descarta; los tipos se toman de la respuesta sin tipo elegido, así aparece uno nuevo; al volver a leer la sede se vuelve a pedir el filtro elegido, salvo el deporte o el tipo que ya no tengan canchas; cada chip lleva «Deporte» o «Tipo» en su etiqueta accesible, porque el mismo nombre está en la portada |
| `apps/mobile/lib/espacios/iconos.dart` | `iconoDeDeporte` | lo usan el panel y la sede del usuario |

## Brief visual

**Invención 2 · densidad 4.** Chips de filtro como en cualquier catálogo: el lima dice qué está
elegido y el contador dice el resultado.

- **Desde dónde.** En la misma sede, entre la portada y las canchas: filtrar no saca al usuario
  de donde está.
- **Chips.** Pill de 48 de alto con el ícono del deporte; el elegido en lima con el texto
  oscuro, el resto en superficie con borde. En 360 los de deporte entran en una fila con tres
  deportes y pasan a dos si hay más.
- **Contador.** Overline lima que se anuncia al cambiar («2 CANCHAS · FÚTBOL 5»).
- **Variables visuales.** Lima = elegido y resultado; lo demás, neutro.
- **Material.** El de la pantalla de sede de CU-16.
