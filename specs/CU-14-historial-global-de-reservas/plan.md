# Implementation Plan: CU-14 · Historial global de reservas (admin)

**Branch**: `card/CU-14` | **Date**: 2026-09-29 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

El panel admin gana su pestaña «Reservas»: el historial completo de todos los usuarios, todas
las sedes y todos los espacios, con pestañas de estado (Todas, Activas, Completadas, Anuladas),
un panel de filtros (sede, deporte, estado, rango de fechas) y búsqueda de texto que se combina
con los filtros. El listado pagina de a 20 y trae un contador que respeta los filtros vigentes.
Tocar una reserva abre el detalle de sólo lectura con su trazabilidad (creación y, si corresponde,
anulación). CU-15 construye la anulación sobre este mismo listado y detalle; esta card no la
implementa.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Storage**: sólo lectura de `reserva_con_estado` ya existente, con `JOIN` a `espacio`, `sede` y
`usuario`; ninguna tabla ni columna nueva — el estado, el precio del momento y la trazabilidad de
cancelación/anulación ya están en el esquema (CU-09/CU-10)
**Testing**: `integration_test` con reservas sembradas por `/_pruebas/reservas` (activa,
cancelada, anulada) y `/_pruebas/espacios/baja`; integración de `GET /reservas/todas` y
`GET /reservas/todas/{id}`; widget del listado y del detalle

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | 16 escenarios de los 18 del snapshot (15 en la app, 1 en la API); H01-07 y H08-01 (anular) quedan para CU-15 (SUP-04) |
| II · Nada se supone en silencio | `CU-14-SUP-01` a `SUP-07`, con AMB-02 a AMB-10 vencidas |
| III · Tests antes del código | 15 escenarios de app + 1 de API, congelados en rojo |
| IV · El backend es la autoridad | `GET /reservas/todas` valida el rol, el rango de fechas y arma la página; la app no filtra por su cuenta |
| V · Rastro | La consulta no escribe nada (poscondición); la trazabilidad que se muestra ya está en `creado_en`/`usuario_id` y `cancelada_en`/`cancelada_por`/`motivo` de cada reserva (RNF 5, decisión 4) |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-14-SUP-01 | El historial pagina en el servidor, 20 por página, sin tope adicional | `HistorialDeReservas.historial`, `GET /reservas/todas?pagina=` |
| CU-14-SUP-02 | La búsqueda es por coincidencia parcial insensible a mayúsculas (`ILIKE`), sin normalizar tildes | `ReservasSql.historial` |
| CU-14-SUP-03 | No hay aviso especial de cambio concurrente; el detalle refleja el estado vigente al abrirlo o al volver a consultarlo | `PantallaDetalleReserva` — no releé en segundo plano |
| CU-14-SUP-04 | Anular (paso 9, FA7, H01-07, H08-01) queda para CU-15; el detalle sólo lee | `PantallaDetalleReserva` deja la sección de acciones lista para agregar el botón |
| CU-14-SUP-05 | No hay un log de auditoría aparte de las consultas | — (sin cobertura, ver abajo) |
| CU-14-SUP-06 | «Acceso denegado» sólo en la entrada bare `/admin` (la pestaña que abre esta card); las subrutas de sedes y espacios conservan el redirect silencioso ya existente | `app.dart`, `@CU-14-H05-01` |
| CU-14-SUP-07 | El detalle no muestra la línea «Notificación enviada al usuario» (es de CU-15) | `PantallaDetalleReserva` |
| CU-14-SUP-08 | Sin encabezados por día: las tarjetas van de la más reciente a la más antigua y cada una lleva su fecha (el prototipo 55:251 no agrupa) | `ReservasSql.historial` (`ORDER BY inicio DESC, id DESC`), `_TarjetaReservaAdmin` |
| CU-14-SUP-09 | El filtro de sede ofrece sólo las sedes activas (`GET /sedes`); las de baja se encuentran por la búsqueda de texto | `PantallaPanelAdmin._abrirFiltros` |
| CU-14-SUP-10 | La paginación sigue por OFFSET y la app descarta por id las reservas repetidas entre páginas | `_PantallaPanelAdminState._cargarMas` |
| CU-14-SUP-11 | El listado arma las tarjetas a demanda; un escenario congelado que busque texto sin desplazarse puede fallar por eso | `PantallaPanelAdmin` (`SliverList.builder`) |
| CU-14-SUP-12 | Si falla la relectura del detalle, queda lo que mostraba el listado | `PantallaDetalleReserva` |
| CU-14-SUP-13 | En 360 de ancho el buscador dice «Buscar» y los campos Desde y Hasta se apilan, para que nada quede cortado | `PantallaPanelAdmin`, `PantallaFiltrosReservas` (visual, sin test) |

## Supuestos sin cobertura

- **CU-14-SUP-05.** No hay ningún escenario que verifique la ausencia de un log de auditoría
  aparte: es una decisión de no construir algo, no un comportamiento observable. Se nombra en el
  cierre.

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/app/dominio/reservas.py` | `ReservaHistorial`, `FiltrosHistorial`, `HistorialDeReservas` (página + contadores) | dataclasses nuevas, no tocan `Reserva`; `FiltrosHistorial.estado` acepta sólo `activa`, `completada`, `anulada` o `None` (sin «cancelada»: el filtro de estado replica las cuatro pestañas del prototipo, «cancelada por el usuario» sólo aparece dentro de «Todas») |
| `apps/api/app/aplicacion/reservas.py` | `historial_global`, `detalle_admin`; el `Protocol Reservas` gana `historial` y `una_de_cualquiera` | ambas piden `perfil.rol == "admin"` (si no, `Prohibido`); `historial_global` valida `desde <= hasta` (si no, `DatosInvalidos`) antes de tocar la base |
| `apps/api/app/infraestructura/reservas.py` | `ReservasSql.historial`, `ReservasSql.una_de_cualquiera` | un único `SELECT` con `JOIN` a `espacio`, `sede` y `usuario`, `WHERE` armado con los filtros presentes, `LIMIT 20 OFFSET`; `desde`/`hasta` cortan los días a medianoche de `America/Argentina/Buenos_Aires` (la sesión de Postgres está en UTC); la búsqueda escapa `\`, `%` y `_` y usa `ILIKE ... ESCAPE '\'`; los contadores salen de un segundo `SELECT ... GROUP BY estado_actual` con los mismos filtros salvo el de estado; `espacio_de_baja` es `NOT e.activo OR NOT s.activa` |
| `apps/api/app/interfaz/reservas.py` | `GET /reservas/todas`, `GET /reservas/todas/{id}` | mismo patrón 403/422 que el resto del router; `estado`, `sede_id`, `deporte`, `desde`, `hasta`, `q`, `pagina` como query params opcionales |
| `apps/api/app/interfaz/pruebas.py` | sin cambios | `/_pruebas/reservas` (con `estado`/`motivo`), `/_pruebas/reservas/anular` y `/_pruebas/espacios/baja` ya alcanzan para sembrar los 14 escenarios |
| `apps/mobile/lib/admin/historial_reservas.dart` | modelo `ReservaHistorial`, `FiltrosReservas`, cliente `HistorialDeReservas` (una página por llamada) | `desdeJson` sigue el patrón de `Reserva.desdeJson`; guarda la última página pedida para poder pedir la siguiente con los mismos filtros |
| `apps/mobile/lib/admin/pantalla_panel_admin.dart` | listado: pestañas, buscador, botón Filtros, tarjetas en un `SliverList.builder`, scroll perezoso (pide la página siguiente al acercarse al final y descarta por id las repetidas), estados de carga/error/sin resultados/vacío | cada pedido nuevo (filtro, pestaña, refresco, anulación) apaga el spinner de «cargando más»; guarda los filtros vigentes en el estado de la pantalla, se los pasa al detalle y relee el listado cada vez que se vuelve de él (H01-08) |
| `apps/mobile/lib/admin/pantalla_filtros_reservas.dart` | el panel de Filtros, a pantalla completa: chips de sede y deporte, chips de estado, rango de fechas | la búsqueda de texto vive sólo en el listado y el panel la conserva; abre aunque falle el pedido de sedes o del catálogo; «Aplicar» deshabilitado y las fechas en rojo si `desde > hasta` (FA3) o si un campo tiene texto que no es una fecha («Fecha inválida»), sin pedir nada al servidor hasta que sea válido; la X tiene nombre accesible «Cerrar» |
| `apps/mobile/lib/admin/pantalla_detalle_reserva.dart` | detalle de sólo lectura: datos de la reserva, trazabilidad | al abrirse pide `historial.detalle(id)` y muestra lo vigente (la reserva del listado sólo llena el primer cuadro); el deporte sale del catálogo; la flecha tiene nombre accesible «Volver»; «Volver» respeta `Navigator.pop` para no perder los filtros del listado |
| `apps/mobile/lib/comun/pantalla_acceso_denegado.dart` | overlay compartido «Acceso denegado» | mismo lenguaje visual que `dialogo_error.dart`; un único botón que va a `/inicio` |
| `apps/mobile/lib/app.dart` | rutas `/admin/reserva/:id` (el `extra` es la reserva y los filtros del listado); `/admin` bare a `/admin/acceso-denegado` si el rol no es admin | sólo la entrada bare cambia de destino (SUP-06); el resto de `/admin/*` no se toca |

## Perímetro

- **Auth**: Firebase (emulador en los escenarios), igual que el resto de la API; el rol se lee del
  perfil ya resuelto por `usuario_actual`.
- **Mocks**: en los tests de widget y capturas, `apiRutas` con las rutas `GET /reservas/todas`;
  en los escenarios de app, la API real contra la base de la corrida.
- **Queda afuera**: anular una reserva (CU-15, SUP-04); un log de auditoría aparte de las
  consultas (SUP-05); notificaciones (SUP-07).

## Brief visual

**Invención 2 · densidad 7.** Es una grilla de datos con filtros — el patrón ya resuelto del
panel admin — no un tablero nuevo. La densidad es alta porque cada tarjeta trae siete datos
(deporte, sede, espacio, usuario, horario, precio, estado) y el administrador la usa para
auditar, no para navegar linda.

- **Desde dónde.** Desde la pestaña RESERVAS del panel admin (`BarraAdmin`), que ya existe y hoy
  no tiene pantalla real detrás.
- **Teléfono chico.** En 360 entran sin scroll: el título, el buscador + Filtros, las pestañas de
  estado y el contador. Las tarjetas empiezan debajo, con scroll. El detalle muestra la tarjeta
  de la reserva y la trazabilidad sin cortar el horario ni el precio.
- **Variables visuales.** El color del pill de estado es el mismo código que ya usa «Mis
  reservas» (`EstadoDeReserva`): verde para activa, gris para completada, rojo para anulada o
  cancelada. El lima queda para la pestaña de estado activa y las acciones principales.
- **Material.** Tipografía, lienzo, separación, radio y densidad de fila: los mismos tokens que
  `pantalla_sedes_admin.dart` (`Textos`, `Medidas`, `Paleta`) — es una vista más del panel admin,
  no una superficie nueva.
