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
