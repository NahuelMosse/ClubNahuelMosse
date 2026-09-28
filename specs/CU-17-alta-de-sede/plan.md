# Implementation Plan: CU-17 · Alta de sede

**Branch**: `card/CU-17` | **Date**: 2026-09-28 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

El panel de administración gana su barra inferior (Reservas, Sedes, Espacios) y la sección
Sedes: el listado de las sedes activas y «AGREGAR SEDE». El formulario pide nombre, dirección
(«Calle y altura»), apertura, cierre y días que abre; la API valida, guarda la sede a nombre del
administrador y la devuelve, y la app muestra «¡Sede creada!» con la sede guardada. La sede nace
activa y los usuarios la ven en `GET /sedes` apenas se crea.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Storage**: tabla `sede` de MOD-01 (calle y altura separadas, `dias smallint[]`, rastro de
alta); migración `0004` con el índice único `sede_nombre_activa_unico` sobre `lower(nombre)`
entre sedes activas
**Testing**: escenario de API para el 403 de un usuario; `integration_test` con la cuenta de
administrador que siembra `scripts/e2e.sh` y la API intermedia para las fallas; lo que ven los
usuarios se pregunta a la API con una cuenta nueva, porque el listado de usuario es de CU-16

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Siete escenarios; pantallas 62:1648, 62:1828, 62:1903 y 64:2050 (decisión 12) |
| II · Nada se supone en silencio | `CU-17-SUP-01` a `SUP-09`; AMB-07 y AMB-08 resueltas por decisiones 4 y 7 |
| III · Tests antes del código | 6 escenarios de pantalla y 1 de API congelados en rojo en `bebde07` |
| IV · El backend es la autoridad | La API valida cada campo y el rol; el índice único decide entre dos altas simultáneas |
| V · Rastro | `creado_por`, `modificado_por` y `creado_en` en cada sede |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-17-SUP-01 | Sin sedes: «0 SEDES ACTIVAS» y «Todavía no hay sedes» | `PantallaSedesAdmin`; `sin sedes lo dice y deja agregar la primera` |
| CU-17-SUP-02 | Nombre único entre sedes activas, sin distinguir mayúsculas | migración `0004`; `SedesSql.insertar`; `test_no_hay_dos_sedes_activas_…`, `test_dos_altas_iguales_a_la_vez_…` |
| CU-17-SUP-03 | Horas en punto; el cierre va después de la apertura; 00:00 es la medianoche | `validar_sede`; selector de horas; `test_el_cierre_va_despues_…`, `test_cerrar_a_las_00_…` |
| CU-17-SUP-04 | La sede nace activa y visible aunque no tenga canchas | `SedesSql.activas`; `@CU-17-H01-02` |
| CU-17-SUP-05 | Nombre hasta 60, dirección hasta 80 | `validar_sede`; `LengthLimitingTextInputFormatter`; `test_los_largos_tienen_tope` |
| CU-17-SUP-06 | Las sedes se listan por nombre | `SedesSql.activas`; `test_los_usuarios_ven_las_sedes_por_nombre_…` |
| CU-17-SUP-07 | Un campo «Calle y altura»; la altura es el número final | `validar_sede`; `test_la_direccion_termina_en_la_altura` |
| CU-17-SUP-08 | Días: Lunes a domingo (elegido), Lunes a sábado, Lunes a viernes | `DiasQueAbre`; `guarda con los días elegidos…` |
| CU-17-SUP-09 | GUARDAR SEDE atenuado pero tocable: marca lo que falta | `BotonPrimario.atenuado`; `@CU-17-H03-01` |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/app/dominio/sedes.py` | `validar_sede`, `Sede`, `SedeNueva` | la dirección se parte en calle y altura acá, para que CU-21 arme el nombre del espacio con las dos |
| `apps/api/app/aplicacion/sedes.py` | `dar_de_alta_sede`, `sedes_activas` | sólo el rol admin da de alta; el autor es quien tiene la sesión |
| `apps/api/app/infraestructura/sedes.py` | `SedesSql` | las canchas que se cuentan son los espacios activos; el nombre repetido lo detecta el índice, no una consulta previa |
| `apps/api/app/interfaz/sedes.py` | `GET /sedes`, `POST /sedes` | 201 · 401 · 403 · 409 · 422; `GET` sirve a los dos roles |
| `apps/mobile/lib/sedes/` | `Sede`, `DiasQueAbre`, `Sedes` | la pantalla habla con `Sedes`, que pide el token a `Sesion.token` y avisa cuando se da de alta una sede |
| `apps/mobile/lib/admin/pantalla_sedes_admin.dart` | listado y `TarjetaSedeAdmin` | sin «Editar sede» ni «Dar de baja» hasta CU-18 y CU-19: un botón que no hace nada no va. Queda debajo del alta: se vuelve a leer con cada alta y, tapado, no abre avisos |
| `apps/mobile/lib/admin/pantalla_alta_sede.dart` | formulario | un campo vacío se marca al salir de él; los errores de la API van al campo que nombran; mientras guarda no se puede salir; si un envío se cortó y el reintento da 409, busca la sede que quedó guardada con esos mismos datos y muestra el éxito |
| `apps/mobile/lib/admin/pantalla_sede_creada.dart` | éxito | sin la sede en `extra` (enlace, app reabierta) la ruta lleva al listado |
| `apps/mobile/lib/comun/selector.dart` | `CampoSelector`, `elegirOpcion` | las opciones se construyen todas: son pocas y así se llega a cualquiera desplazándose |
| `apps/mobile/lib/comun/barra_inferior.dart` | `BarraAdmin` | comparte la pestaña con la barra de usuario; Espacios queda vacía hasta CU-21 |
| `apps/mobile/lib/app.dart` | rutas del panel | todo lo que cuelga de `/admin` exige el rol admin, sin anotarlo ruta por ruta |
| `apps/api/app/interfaz/sedes.py` · `_leer_hora` | horas del pedido | sólo `HH:MM`: `fromisoformat` acepta zonas horarias que después no se pueden comparar |

## Brief visual

**Invención 2 · densidad 3.** Es un ABM: listado de tarjetas y formulario, lo que un
administrador ya sabe usar. El carácter lo dan el lima y la cifra de canchas.

- **Desde dónde.** El administrador entra al panel, toca SEDES en la barra y ahí mismo tiene
  AGREGAR SEDE arriba del listado; al terminar, IR AL LISTADO lo deja donde ve la sede nueva.
- **Listado.** Cada tarjeta: nombre, dirección, la cifra de canchas en lima a la derecha y
  días con horario abajo. En el teléfono chico entran el botón y al menos una tarjeta entera.
- **Formulario.** Cinco campos en una columna y GUARDAR SEDE fijo abajo; en 360 entra todo sin
  scroll con el teclado cerrado.
- **Éxito.** Ícono verde, título, la sede guardada en un recuadro mono y las dos salidas.
- **Variables visuales.** Lima = la acción principal y la cifra que importa (canchas); rojo =
  lo que falta; el 40 % dice que todavía no se puede guardar.
- **Material.** Inter para la interfaz, Archivo ExtraBold en los títulos, JetBrains Mono para
  el dato guardado; lienzo `bg/base` con tarjetas `bg/surface-raised`; separación por espacio y
  un borde fino en la tarjeta; radio pill en controles y 20 en tarjetas; filas de 52.
