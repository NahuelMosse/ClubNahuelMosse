# Implementation Plan: CU-06 · Editar perfil

**Branch**: `card/CU-06` | **Date**: 2026-09-27 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

En Mi perfil, «Editar» convierte DATOS PERSONALES en un formulario con nombre, apellido, DNI y
fecha de nacimiento, y el correo a la vista pero deshabilitado (RF 2). «GUARDAR» valida con las
reglas del registro: si algo no pasa, marca cada campo inválido con «El formato de los datos no es
válido» y no manda nada; si pasa, `PUT /yo` vuelve a validar, guarda y devuelve el perfil nuevo, y
la tarjeta vuelve a modo lectura con los datos guardados. Sin conexión o con el servidor caído se
ve el overlay y lo escrito se conserva. El modo oscuro se alterna desde APARIENCIA, que trajo
CU-05.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Storage**: `usuario` (nombre, apellido, dni, fecha_nacimiento); `modificado_en` lo estampa el
disparador de MOD-01
**Testing**: pytest contra la base · `integration_test` con la API intermedia · tests de widget con
la `App` real

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Cinco escenarios; pantallas 43:314 y 43:421 (decisión 12) |
| II · Nada se supone en silencio | `CU-06-SUP-01` a `SUP-05`; AMB-03, 04, 06, 09 y 10 resueltas por decisión |
| III · Tests antes del código | 4 escenarios en rojo; H01-03 nació en verde porque el selector de tema lo trajo CU-05 |
| IV · El backend es la autoridad | La API valida todo otra vez; el DNI único lo garantiza el índice de la base |
| V · Rastro | `modificado_en` por disparador |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-06-SUP-01 | Nombre, apellido, DNI y fecha son obligatorios; un campo vacío lleva el mensaje genérico | `validar_edicion`; `test_un_dato_invalido_no_guarda_nada` |
| CU-06-SUP-02 | Un DNI de otra cuenta activa se rechaza con «Este DNI ya está registrado» | 409 de `PUT /yo`; `test_un_dni_de_otra_cuenta_se_rechaza` |
| CU-06-SUP-03 | No hay «Cancelar»: salir de la pantalla descarta la edición | `_PantallaMiPerfilState` |
| CU-06-SUP-04 | Los límites del registro: 60 caracteres y fecha pasada | `_errores_personales` |
| CU-06-SUP-05 | Gana el último guardado | `UsuariosSql.actualizar` |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/app/dominio/usuarios.py` | `DatosPersonales`, `PerfilEditado`, `validar_edicion` | las reglas de nombre, apellido, DNI y fecha son una sola función que usan el registro y la edición |
| `apps/api/app/aplicacion/perfil.py` | `editar_perfil` | el correo no forma parte de lo editable |
| `apps/api/app/infraestructura/usuarios.py` | `UsuariosSql.actualizar` | el índice único del DNI se traduce a `Duplicado(["dni"])` |
| `apps/api/app/interfaz/sesion.py` | `PUT /yo` | 200 con el perfil nuevo · 409 `{errores: {dni}}` · 422 `{errores}` · 401 |
| `apps/mobile/lib/sesion/sesion.dart` | `Sesion.editarPerfil`, `DatosRechazados` | el perfil de la sesión pasa a ser el que devolvió la API, sólo si la sesión sigue siendo la misma que cuando salió el pedido; un 409 se marca como dato repetido |
| `apps/mobile/lib/usuarios/pantalla_mi_perfil.dart` | `_Edicion`: formulario, validación al guardar, errores de la API | el error de un campo se va cuando cambia su texto; salir durante el guardado no toca la pantalla cerrada y una sesión vencida se cierra igual |
| `apps/mobile/lib/comun/calendario.dart` | el calendario de la fecha de nacimiento, compartido con el registro | abre en la fecha escrita acotada al rango, aunque sea de hoy, futura o anterior a 1900 |
| `apps/mobile/lib/inicio/pantalla_inicio.dart`, `sesion/tarjeta_cuenta.dart` | nombre e iniciales escuchan a la sesión | se actualizan al editar el perfil |

## Brief visual

**Invención 1 · densidad 3.** El mismo formulario del registro, dentro de la tarjeta.

- **Edición.** En el teléfono chico entran nombre, apellido y DNI; el resto con scroll. El error
  aparece debajo de cada campo inválido; el correo al 40 % con candado dice que no se toca.
- **Variables visuales.** Rojo = dato que no se puede guardar; gris al 40 % = dato fijo; lima = la
  acción.
- **Material.** Los campos pill del registro sobre la tarjeta `bg/surface`.
