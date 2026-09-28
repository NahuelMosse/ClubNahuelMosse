# Implementation Plan: TP-05 · Listado de espacios deportivos

**Branch**: `card/TP-05` | **Date**: 2026-09-28 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

El requisito 5 del enunciado queda cubierto por pantallas que ya existen: la de cada sede lista
sus canchas bajo el nombre y la dirección de la sede, con el nombre compuesto en cada una y el
filtro por deporte y tipo de CU-20; el panel del administrador lista los espacios de todas las
sedes, y cada tarjeta lleva el nombre compuesto, que dice la sede. No hay pantalla de usuario con
los espacios de todas las sedes (TP-05-AMB-03, resuelta).

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Storage**: sin cambios
**Testing**: `integration_test` con sedes y espacios cargados por la API; el alta de H01-04 por
la pantalla del administrador

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Seis escenarios del requisito 5; pantallas 63:1895 y la sede de CU-16 |
| II · Nada se supone en silencio | `TP-05-SUP-01` a `SUP-05`; AMB-03 resuelta |
| III · Tests antes del código | Los seis escenarios, congelados en `6deb03d`, nacen en verde: el listado por sede, el nombre compuesto, el panel y el filtro los hicieron CU-16, CU-21 y CU-20 |
| IV · El backend es la autoridad | La API dice qué espacios están activos y arma el nombre compuesto |
| V · Rastro | No aplica: consulta de sólo lectura |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| TP-05-SUP-01 | Avisos de sede sin canchas y panel sin espacios; el filtro nunca vacía la lista | `PantallaSede`, `PantallaEspaciosAdmin` |
| TP-05-SUP-02 | Sólo los espacios activos | `EspaciosSql.activos` |
| TP-05-SUP-03 | Sin paginación | `GET /espacios` |
| TP-05-SUP-04 | Sede: deporte, tipo y número; panel: sede y después lo mismo | `EspaciosSql.activos`; `@TP-05-H01-01` |
| TP-05-SUP-05 | El «tipo» es el deporte, con la variante adentro | `PantallaSede._filtrar`; `@TP-05-H02-01` |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/mobile/integration_test/espacios/listado_espacios_test.dart` | Los seis escenarios | la sede de cada tarjeta del panel se busca en su etiqueta accesible, que la lleva aparte del nombre |
