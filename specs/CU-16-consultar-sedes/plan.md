# Implementation Plan: CU-16 · Consultar sedes

**Branch**: `card/CU-16` | **Date**: 2026-09-28 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

La pestaña SEDES del usuario deja de ser un lugar vacío: lista todas las sedes activas con su
portada, nombre, dirección, horario, cantidad de canchas y deportes. Tocar una sede abre su
pantalla con cada cancha: tipo, nombre compuesto, condición, iluminación, precio y descripción, y
«VER HORARIOS / RESERVAR», que lleva a la pantalla de horarios con esa cancha elegida entre las de
su tipo. La API suma los deportes de cada sede a `GET /sedes`, el filtro `sede_id` a
`GET /espacios` y el número de cada cancha.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Storage**: sin cambios: `sede` y `espacio` de MOD-01
**Testing**: `integration_test` con sedes y canchas cargadas por la API como el administrador de
la corrida, y la API intermedia para las fallas; tests de API del filtro y los deportes

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Ocho escenarios; pantallas 53:319, 54:986 y las de sede 406:6534 y 53:431 sin los selectores de CU-20 (decisión 12) |
| II · Nada se supone en silencio | `CU-16-SUP-01` a `SUP-08`; AMB-02, 07 y 08 resueltas por decisiones 4, 7 y 15 |
| III · Tests antes del código | 8 escenarios congelados en rojo en `1cb1155` |
| IV · El backend es la autoridad | Qué sedes y canchas están activas y qué deportes tiene cada sede lo dice la API |
| V · Rastro | No aplica: consulta de sólo lectura |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-16-SUP-01 | Sin sedes: «Todavía no hay sedes» | `PantallaSedes`; `sin sedes lo dice` |
| CU-16-SUP-02 | Sólo con sesión | `_rolDe` en `app.dart` |
| CU-16-SUP-03 | Sin paginación | `PantallaSedes`, `PantallaSede` |
| CU-16-SUP-04 | Sedes por nombre; canchas por deporte, tipo y número | `SedesSql.activas`, `EspaciosSql.activos`; `test_se_filtran_los_espacios_…` |
| CU-16-SUP-05 | Al entrar a la sede se vuelve a pedir; si ya no está, aviso y vuelta al listado | `PantallaSede._cargar`; `una sede que ya no está vuelve al listado con el aviso` |
| CU-16-SUP-06 | Fotos fijas de la app: portada por sede y foto por deporte | `sedes/fotos.dart` |
| CU-16-SUP-07 | Descripción armada con tipo, condición e iluminación | `TarjetaCancha` |
| CU-16-SUP-08 | Todas las canchas activas están disponibles | `TarjetaCancha` sin Badge-Estado |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/app/infraestructura/sedes.py` | deportes de cada sede | las claves de los deportes de sus canchas activas, sin repetir |
| `apps/api/app/interfaz/espacios.py` | `GET /espacios?sede_id=`, `numero` | el filtro es opcional: sin él siguen todas las canchas |
| `apps/mobile/lib/sedes/pantalla_sedes.dart` | «Todas las sedes» y `TarjetaSede` | la tarjeta se toca entera; la portada crece si el nombre ocupa dos líneas; sin datos frescos no se muestra nada, sólo REINTENTAR; se vuelve a leer cuando la sede o la cancha que se abrió avisa que ya no está; tapada por otra pantalla no abre avisos |
| `apps/mobile/lib/comun/etiqueta.dart`, `estado_vacio.dart` | `Tag` y `Empty-State` | los comparten las pantallas de sedes |
| `apps/mobile/lib/sedes/pantalla_sede.dart` | la sede y `TarjetaCancha` | «Todas las sedes» vuelve al listado que quedó debajo, con su posición; cada «VER HORARIOS / RESERVAR» dice de qué cancha es al lector de pantalla |
| `apps/mobile/lib/reservas/pantalla_horarios.dart` | «Horarios disponibles» | por ahora el tipo, la sede y «SELECCIONÁ CANCHA» con las canchas de ese tipo; la grilla la suma CU-12 |
| `apps/mobile/lib/sedes/fotos.dart` | portadas y `FotoConVelo` | las cuatro imágenes del prototipo; el velo oscuro vale en los dos modos, por eso el texto encima usa la paleta oscura |
| `apps/mobile/lib/app.dart` | rutas `/sedes/:sede` y `/sedes/:sede/canchas/:cancha` | el rol de una sección vale para todo lo que cuelga de ella |
| `apps/mobile/lib/comun/barra_inferior.dart` | `enRaiz` | adentro de una sede, la pestaña SEDES vuelve al listado |
| `apps/mobile/lib/comun/boton.dart` | `BotonPrimario` | alto mínimo, no fijo: con el texto agrandado el botón crece en vez de achicar o cortar la letra |

## Brief visual

**Invención 3 · densidad 4.** Un catálogo para elegir dónde jugar: la foto hace de primer
filtro, y la cifra de canchas en lima es lo que se busca de un vistazo.

- **Desde dónde.** La pestaña SEDES; tocar una sede abre sus canchas y de cada cancha se pasa a
  los horarios. «Todas las sedes» arriba de la portada vuelve al listado.
- **Listado.** Portada de 158 con el nombre en Archivo, dirección y horario; a la derecha, el
  contador lima; abajo, los deportes y «Ver canchas». En 360 entran dos tarjetas enteras.
- **Sede.** Portada con dirección y horario en lima, el nombre grande y los deportes; debajo el
  contador y una tarjeta por cancha con su foto, el nombre compuesto en mono, las condiciones, el
  precio en lima y el botón.
- **Variables visuales.** Lima = lo que se cuenta (canchas, precio) y la acción; la foto = el
  deporte; mono = el nombre compuesto.
- **Material.** Inter, Archivo ExtraBold y JetBrains Mono; fotos con velo sobre `bg/base`;
  tarjetas `bg/surface`; radio 20 en tarjetas y pill en etiquetas y botones.
