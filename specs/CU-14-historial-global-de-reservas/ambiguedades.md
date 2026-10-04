# Ambigüedades — CU-14 · Consultar historial global de reservas

Una sola lectura del CU, declarada.

## Las diez preguntas
| Caso vacío    | la card dice: FA6 «No hay reservas» sin «Limpiar filtros»; FA1 «Sin resultados» con filtros visibles y «Limpiar filtros»
| Duplicados    | no aplica: es una consulta; la anulación de una reserva ya anulada cae en CU-15 FA3
| Validación    | la card dice: FA3 «desde» no puede ser posterior a «hasta», «Aplicar» deshabilitado
| Error         | la card dice: FA2 pantalla de error con «Reintentar», sin datos parciales
| Estado        | la card dice: pestañas Todas, Activas, Completadas, Anuladas, y anular deja «Cancelada»; los nombres chocan con CU-15 y el prototipo → CU-14-AMB-01
| Permisos      | la card dice: FA4 sin rol de administrador, entrada oculta y «Acceso denegado» por enlace profundo
| Límites       | la card no dice si el listado se pagina ni si la búsqueda distingue mayúsculas o busca coincidencia parcial → CU-14-AMB-02, CU-14-AMB-03
| Orden         | la card dice: «agrupado por fecha y ordenado de la más reciente a la más antigua»
| Concurrencia  | la card no dice qué pasa si la reserva cambió (el usuario la canceló o modificó) mientras el administrador la miraba → CU-14-AMB-04
| Rastro        | la card dice: la anulación registra autor y fecha; la consulta se registra en un log de auditoría con fecha, administrador, filtros y acción

## Eventos
CU-14-AMB-01 · 2026-09-27 · abierta · ¿cuál es el nombre del estado de una reserva anulada por el club: Cancelada (CU-14), Anulada por administración (CU-15) o Anulada (prototipo)? ¿se distingue de la cancelada por el usuario?
CU-14-AMB-02 · 2026-09-27 · abierta · ¿el historial global se pagina o carga por partes? ¿hay tope de resultados?
CU-14-AMB-03 · 2026-09-27 · abierta · ¿la búsqueda es por coincidencia parcial, sin distinguir mayúsculas ni tildes?
CU-14-AMB-04 · 2026-09-27 · abierta · si la reserva cambió mientras el administrador la miraba, ¿«Esto cambió mientras tanto» al anular?
CU-14-AMB-05 · 2026-09-27 · abierta · ¿anular desde el panel pide motivo como CU-15, o CU-14 y CU-15 son la misma acción?
CU-14-AMB-06 · 2026-09-27 · abierta · ¿hace falta un log de auditoría de las consultas (con los filtros usados) o alcanza con la trazabilidad de cada reserva?
CU-14-AMB-07 · 2026-09-27 · abierta · ¿las reservas de un espacio o sede dado de baja pasan a canceladas (FA8) o la baja se impide mientras haya reservas futuras (CU-19 FA3)?
CU-14-AMB-08 · 2026-09-27 · abierta · el precio que muestra el historial, ¿es el que se pagó al reservar o el precio actual del espacio?
CU-14-AMB-00 · 2026-09-27 · snapshot · congelado en f96fe08
CU-14-AMB-00 · 2026-09-27 · snapshot · congelado en 9eb7bed
CU-14-AMB-00 · 2026-09-27 · snapshot · congelado en c9a3c55
CU-14-AMB-01 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-14-AMB-01 · 2026-09-27 · resuelta · estados Activa, Completada, Cancelada (por el usuario) y Anulada (por el club, con motivo) (decisión 3)
CU-14-AMB-07 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-14-AMB-07 · 2026-09-27 · resuelta · la baja de una sede o de un espacio con reservas futuras no se permite; la cancelación forzosa sale sólo de CU-15 (decisión 5)
CU-14-AMB-08 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-14-AMB-08 · 2026-09-27 · resuelta · todas las entidades guardan fecha de creación y de modificación, las acciones del administrador guardan su autor, la reserva guarda el precio del momento; las bajas son lógicas y no borran historial (decisión 4)
CU-14-AMB-02 · 2026-09-29 · vencida → CU-14-SUP-01 · el historial global se pagina en el servidor con offset/límite de tamaño fijo (20 por página); sin tope adicional de resultados
CU-14-AMB-03 · 2026-09-29 · vencida → CU-14-SUP-02 · la búsqueda es por coincidencia parcial insensible a mayúsculas (ILIKE), sin normalizar tildes
CU-14-AMB-04 · 2026-09-29 · vencida → CU-14-SUP-03 · no hay aviso especial de cambio concurrente; el detalle siempre refleja el estado vigente al abrirlo o al volver a consultarlo
CU-14-AMB-05 · 2026-09-29 · vencida → CU-14-SUP-04 · la anulación (paso 9, FA7, H01-07, H08-01) se difiere a CU-15 por alcance asignado explícitamente para esta card; CU-14 entrega listado y detalle en modo sólo lectura, con la estructura preparada para que CU-15 agregue la acción
CU-14-AMB-06 · 2026-09-29 · vencida → CU-14-SUP-05 · no se implementa un log de auditoría aparte para las consultas; alcanza con la trazabilidad que ya guarda cada reserva (creación y, si corresponde, anulación)
CU-14-AMB-09 · 2026-09-29 · sin canal · el redirect de /admin ya es silencioso para toda ruta de administración (sedes, espacios); la card pide una pantalla "Acceso denegado" en el enlace profundo → CU-14-SUP-06 · la pantalla se muestra sólo en la entrada bare /admin (la pestaña Reservas que abre esta card); las subrutas de sedes y espacios conservan el redirect silencioso ya existente, para no tocar el comportamiento de CU-17/CU-18/CU-19
CU-14-AMB-10 · 2026-09-29 · sin canal · el detalle de una reserva anulada en el prototipo (59:1336) incluye "Notificación enviada al usuario"; esa notificación la envía la acción de anular, que es de CU-15 → CU-14-SUP-07 · el detalle de CU-14 muestra trazabilidad de creación y, si corresponde, de anulación (autor, fecha, motivo), sin la línea de notificación
CU-14-TESTS · 2026-09-29 · congelados en 33284d9 · 15 escenarios de app y 1 de API en rojo porque GET /reservas/todas y GET /reservas/todas/{id} todavia no existian (404) y el panel admin era un cascaron sin listado
CU-14-AMB-11 · 2026-10-03 · sin canal · el listado se arma de a páginas y el CU lo pide «agrupado por fecha»; el prototipo (55:251) no trae encabezados de día → CU-14-SUP-08 · las tarjetas van de la más reciente a la más antigua y cada una lleva su fecha, sin encabezados por día
CU-14-AMB-12 · 2026-10-03 · sin canal · el filtro de sede, ¿ofrece también las sedes dadas de baja (FA8)? → CU-14-SUP-09 · sólo ofrece las sedes activas, que es lo que devuelve `GET /sedes`; ofrecer las de baja pide un endpoint nuevo; sus reservas se encuentran por la búsqueda de texto
CU-14-AMB-13 · 2026-10-03 · sin canal · la paginación por OFFSET repite o salta reservas si el historial cambia entre dos páginas → CU-14-SUP-10 · se mantiene `pagina` en el contrato y la app descarta por id las reservas que ya tiene; un cursor (inicio, id) cambiaría el contrato de la API
CU-14-AMB-14 · 2026-10-03 · sin canal · el listado de tarjetas, ¿se arma entero o a demanda? → CU-14-SUP-11 · a demanda (`SliverList.builder`); un escenario congelado de `integration_test` que busque texto de una tarjeta sin desplazarse puede fallar por eso, y la pasada final de e2e decide si se desplaza el escenario o se cambia la lista
CU-14-AMB-15 · 2026-10-03 · sin canal · si falla la relectura del detalle al abrirlo → CU-14-SUP-12 · el detalle queda con lo que mostraba el listado, sin error: la anulación vuelve a verificar contra el servidor
CU-14-TESTS · 2026-10-03 · recongelados en 1f97663 · H07-01 parte de un sistema sin reservas con la API de pruebas: la base de la corrida se comparte entre archivos
CU-14-TESTS · 2026-10-03 · recongelados en fad15b7 · H02-01 busca la reserva con scroll tras limpiar los filtros: la lista perezosa (CU-14-SUP-11) la deja fuera de pantalla
CU-14-TESTS · 2026-10-03 · recongelados en a70b38e · H03-01 toca REINTENTAR por su texto: el botón de la app es un TextButton, no un FilledButton
CU-14-TESTS · 2026-10-03 · recongelados en ea95cb2 · H04-01 baja hasta el rango de fechas del filtro: con las sedes de la corrida queda fuera de lo que arma la lista (primer intento en 8efcc08)
CU-14-TESTS · 2026-10-03 · recongelados en 6407653 · H05-01 navega con el contexto de una pantalla: el de MaterialApp está por encima del GoRouter
CU-14-AMB-16 · 2026-10-03 · sin canal · en un teléfono de 360 de ancho el prototipo (393) no entra tal cual: «Buscar reserva» queda cortado junto a Filtros y los dos campos de fecha cortan «DD / MM / AAAA» → CU-14-SUP-13 · por debajo de 400 de ancho el campo dice «Buscar» y, por debajo de 330 de ancho útil, Desde y Hasta se apilan con el error bajo cada uno; la etiqueta accesible y el resto no cambian
