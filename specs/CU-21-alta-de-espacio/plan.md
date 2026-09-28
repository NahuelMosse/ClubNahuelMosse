# Implementation Plan: CU-21 · Alta de espacio deportivo

**Branch**: `card/CU-21` | **Date**: 2026-09-28 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

El panel suma la sección Espacios: el listado de los espacios activos y «ALTA ESPACIO». El
formulario pide sede, deporte, tipo (según el deporte), condición, iluminación y precio por hora,
y muestra el nombre compuesto que calcula la API con el número siguiente de ese tipo en esa sede.
Al guardar, la API vuelve a calcular el número bajo bloqueo: si otro alta lo tomó, responde con el
siguiente y la app lo muestra con el aviso del prototipo. El espacio nace activo y los usuarios lo
ven en `GET /espacios`.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Storage**: tabla `espacio` de MOD-01 (`UNIQUE (sede_id, deporte, tipo, numero)`, `nombre`
único e inmutable, rastro de alta); sin migraciones nuevas
**Testing**: escenario de API para el 403 de un usuario; `integration_test` con la sede y los
espacios previos cargados por la API como otro administrador, y la API intermedia para las fallas

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Siete escenarios; pantallas 63:1895, 63:2030, 63:2101, 63:2162, 63:2223 y 64:2065 (decisión 12) |
| II · Nada se supone en silencio | `CU-21-SUP-01` a `SUP-07`; AMB-03, 05, 06 y 07 resueltas por decisiones 4 y 8 |
| III · Tests antes del código | 6 escenarios de pantalla y 1 de API congelados en rojo en `1e5426e` |
| IV · El backend es la autoridad | La API arma el nombre, elige el número y valida contra el catálogo |
| V · Rastro | `creado_por`, `modificado_por` y `creado_en` en cada espacio |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-21-SUP-01 | Sin sedes, «Todavía no hay sedes» y no se puede elegir | `PantallaAltaEspacio`; `sin sedes lo dice y no deja elegir` |
| CU-21-SUP-02 | Precio en pesos enteros, de $ 1 a $ 9.999.999 | `validar_espacio`; `FormatoPrecio`; `test_el_precio_es_positivo_y_con_tope` |
| CU-21-SUP-03 | Listado por sede y por nombre | `EspaciosSql.activos`; `test_los_usuarios_ven_los_espacios_activos_…` |
| CU-21-SUP-04 | Catálogo del prototipo más pádel | `CATALOGO`; `GET /espacios/catalogo`; `test_el_catalogo_no_repite_claves` |
| CU-21-SUP-05 | Errores de red con los overlays compartidos | `mostrarErrorDeRed`; `@CU-21-H04-01` |
| CU-21-SUP-06 | GUARDAR ESPACIO atenuado pero tocable: marca lo que falta | `BotonPrimario.atenuado`; `@CU-21-H03-01` |
| CU-21-SUP-07 | Un nombre ya usado por otra sede se saltea; una sede que no aporta al nombre no se crea | `EspaciosSql._calcular`, `validar_sede`; `test_el_numero_saltea_…`, `test_nombre_y_calle_tienen_que_aportar_…` |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/app/dominio/espacios.py` | `CATALOGO`, `validar_espacio`, `nombre_compuesto` | el catálogo vive en el código: deporte y tipo se guardan por su clave (`Futbol`, `F5`) |
| `apps/api/app/aplicacion/espacios.py` | `nombre_sugerido`, `dar_de_alta_espacio`, `espacios_activos` | sólo el rol admin sugiere nombres y da de alta |
| `apps/api/app/infraestructura/espacios.py` | `EspaciosSql` | el alta toma la sede con `FOR SHARE` (una baja de sede no la cruza) y un candado por sede, deporte y tipo; el número sale del máximo incluidas las bajas, así que no se reutiliza, y saltea los nombres que ya usó otra sede. Si el número que vio el administrador lo tomó hace un momento él mismo con los mismos datos, es su pedido repetido tras un corte y se devuelve ese espacio |
| `apps/api/app/interfaz/espacios.py` | `GET /espacios/catalogo`, `GET /espacios`, `GET /espacios/nombre`, `POST /espacios` | 409 trae el nombre y el número siguientes, calculados bajo el candado; una sede de baja es un 422 del campo sede |
| `apps/mobile/lib/espacios/` | `Catalogo`, `Espacio`, `Espacios` | el catálogo se pide una vez por sesión de la app; `Espacios` avisa cuando se da de alta uno |
| `apps/mobile/lib/admin/pantalla_espacios_admin.dart` | listado y `TarjetaEspacioAdmin` | sin Editar ni Baja hasta CU-22 y CU-23 |
| `apps/mobile/lib/admin/pantalla_alta_espacio.dart` | formulario y vista previa del nombre | el tipo se habilita con el deporte y se borra si el deporte cambia; una respuesta de nombre vieja se descarta; si el nombre no se pudo calcular lo dice y ofrece reintentar; se manda lo que está elegido al tocar GUARDAR; el aviso de duplicado se trae a la vista; mientras guarda no se sale |
| `apps/mobile/lib/comun/formato_precio.dart` | `pesos`, `FormatoPrecio`, `leerPrecio` | el espacio después del `$` no se corta; el cursor queda donde se escribió; lo pegado con centavos se corta en la coma |

## Brief visual

**Invención 2 · densidad 3.** El mismo ABM que Sedes: el administrador ya lo conoce.

- **Desde dónde.** Pestaña ESPACIOS del panel; ALTA ESPACIO arriba del listado; al terminar,
  IR AL LISTADO muestra el espacio nuevo.
- **Listado.** Cada tarjeta: ícono del deporte, tipo con condición y precio, y el nombre
  compuesto en mono debajo, que es el dato que después se busca.
- **Formulario.** Seis campos en una columna; condición e iluminación de a pares en 393 y
  apiladas debajo de 340 de ancho útil, donde sus valores no entran. La vista previa del nombre
  pasa de borde gris a lima cuando está completa.
- **Variables visuales.** Lima = acción principal y nombre listo; rojo = lo que falta o el
  duplicado; mono = el nombre compuesto.
- **Material.** Inter, Archivo ExtraBold en títulos, JetBrains Mono en el nombre; tarjetas
  `bg/surface-raised` sobre `bg/base`; separación por espacio; radio pill en controles, 20 en
  tarjetas y 12 en la vista previa.
