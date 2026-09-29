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
