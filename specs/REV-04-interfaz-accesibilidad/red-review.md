# RED-REVIEW · REV-04 · interfaz y accesibilidad

Fuente única: `card.snapshot.md` (escenarios H17-01 a H27-04, hallazgos 17, 18 y 27, CU-03/09/11/12/17/18/21). Del plan,
sólo `## Assumptions` y `## Perimeter`. Tests leídos: `apps/mobile/test/interfaz_accesible_test.dart`. Rojo:
`D:/Temp/rojo-rev04b.log` (variante sin H27-03): 12 fallan, **1 pasa (H27-04)**.

## Resultado

Cada escenario tiene un test y los 12 que fallan, fallan por la razón esperada (el texto, el foco, el SnackBar, el
contraste 3,40, el borde 358 > 352, la fecha 2026-10-19). Pero tres escenarios no los prueba lo que dice su nombre
(H27-02, H27-03, H27-04), y varios comportamientos que la card da a «un campo» o a «una confirmación» se prueban en un
solo tipo o en un solo lugar.

## Hallazgos

| # | Test (tag) | Qué falta | Por qué | Gravedad |
|---|---|---|---|---|
| 1 | H27-04 · alta de espacio a 320 × 568 | Pasa en rojo (`+1` en el log). Sólo mira `takeException()` tras elegir Sede/Deporte/Tipo y tocar GUARDAR; no carga el precio ni mira los estados que el hallazgo 27 dice que fallan (las 6 capturas: inicial vacío, desplegables Sede/Deporte/Tipo abiertos, error en línea bajo Tipo, duplicado, éxito) | Un test que pasa antes del cambio no prueba el escenario; el hallazgo dice «6 de alta de espacio fallan a 320×568» y este test no reproduce ninguno | H |
| 2 | H27-03 · la hora del club sale del reloj | Es un test unitario de `ahoraEnElClub`. El escenario es «las capturas no cambian según el día en que se generan»: ningún test monta una pantalla con el reloj fijo y comprueba que lo que muestra sale de ese reloj. Hoy leen `DateTime.now()` `panel_avisos.dart:34`, `pantalla_notificaciones.dart:39`, `reglas_busqueda.dart:15`, `pantalla_mi_perfil.dart:443`, `calendario.dart:11` y `pantalla_registro.dart:61` | La función puede existir y las capturas seguir dependiendo del día; ASM-09 (12/11/2026 15:00) no está atada a ningún test | H |
| 3 | H27-02 · calendario de nacimiento | El escenario dice «el calendario **de reservas** parte del día del club»; el test prueba el de **nacimiento** (ASM-08) llamando a `elegirFechaDeNacimiento` suelto, no por la pantalla. Tampoco cubre la validación de la fecha tipeada a mano: `pantalla_registro.dart:61` y `pantalla_mi_perfil.dart:443` validan con el día del teléfono (a las 23:30 del 12 en el club, tipear 12/11 o 13/11) | El nombre del escenario y el test no hablan de la misma pantalla; si el escenario es el de reservas, no tiene test | H |
| 4 | H18-05 · foco en NO CANCELAR | Sólo la cancelación desde Mis reservas. ASM-03 dice «en **cada** confirmación irreversible»: faltan la cancelación desde Inicio (`pantalla_inicio.dart:150`), la baja de sede (`confirmarBajaDeSede`), la baja de espacio (`confirmarBajaDeEspacio`) y la variante con `TextButton` secundario del diálogo común (`dialogo_error.dart:346-355`) además de la de `OutlinedButton`. No se afirma «el orden de los botones no cambia» | El defecto está en el componente compartido y el escenario es general; un `autofocus` puesto sólo en `confirmarCancelacion` lo pasa | H |
| 5 | H18-01 · error junto al campo | Prueba `CampoTexto` suelto, no `CampoSelector`, que el hallazgo nombra (`selector.dart:104-129`, el error es un nodo `liveRegion` aparte). Tampoco por una pantalla real (registro, sede, alta de espacio con su error «Este campo es obligatorio» bajo Tipo). No afirma que el error deje de ser un nodo aparte: si se suma al label y queda el nodo viejo, el test pasa y el lector lo lee dos veces | «Afecta a todos los formularios»: un comportamiento de «un campo» probado en un solo tipo | H |
| 6 | H17-01 · CREAR CUENTA vacío | Sólo el formulario entero vacío. Faltan: algunos campos completos y otros no (que se muestren **sólo** los faltantes, CU-03 FA1); un campo con sólo espacios; dónde queda el foco tras tocar CREAR CUENTA (ASM-01: «el foco va al primero», sin assert en el registro); que escribir en un campo con error lo limpie y que el resto siga (ASM-01: «se actualizan mientras la persona escribe»); que con todo completo después del error se envíe el pedido | Qué limpia cada mensaje y dónde cae el foco tras enviar no están probados en el registro | M |
| 7 | H17-01 + ASM-01 · salir de un campo vacío | Sólo campos de texto (Nombre → Apellido). Falta el campo de fecha: cerrar el calendario sin elegir hoy marca el campo (`pantalla_registro.dart:181`). La ausencia (`findsNothing`) no va precedida de la señal positiva del mismo estado (p. ej. Apellido con foco) | Un borde de ASM-01 en otro tipo de campo; ausencia sin ancla | M |
| 8 | H17-02 · edición de sede sin nombre | Un solo faltante (nombre, que además es el primero). Faltan: dos faltantes a la vez con el foco en el primero; un faltante que es selector (horario de apertura/cierre: ¿adónde va el foco?); que el **alta** de sede se comporte igual («igual que el alta», el mismo test parametrizado); que corregir el campo limpie el mensaje y el PUT salga. ASM-04 es `any-answer: no` frente a CU-18 FA2 («Guardar cambios se deshabilita») y el test fija una sola respuesta | Foco tras enviar con selector; comportamiento de «un campo» probado sólo en texto | M |
| 9 | H18-03 / H18-04 · rechazo a la vista | Una sola forma de entrada: `422 {"errores": {"fecha": "..."}}`. Faltan: `errores` con valor no string (`{"fecha": 5}` → `ReservaRechazada({})` y hoy `errores.values.first` revienta), `errores` vacío, dos errores, clave distinta de `fecha`. No se mira dónde cae el foco cuando aparece el aviso ni tras ELEGIR OTRO HORARIO; ni qué hace atrás/Escape con el aviso abierto | I20 pide que el rechazo se lea; formas faltantes, nulas y de tipo equivocado no cubiertas; foco tras fallo sin assert | M |
| 10 | H18-04 · rechazo de un cambio | Tras ELEGIR OTRO HORARIO sólo afirma que el texto se fue. CU-11 FA2: «conserva la reserva original intacta y vuelve a la grilla con la disponibilidad actualizada»; no se afirma que se vuelva a la grilla en modo edición ni que se pida de nuevo la grilla | Qué limpia el mensaje y adónde lleva, sin assert | M |
| 11 | H18-06 · barra al 200 % | Escenario: «cada destino completo». Se mira sólo RESERVAS (socio) y ESPACIOS (admin); el resto de etiquetas de las dos barras no. RESERVAS sólo con `didExceedMaxLines`: un recorte por ancho del padre (ClipRect, FittedBox mal puesto, `softWrap: false`) no lo detecta; no se mira que el texto quede dentro de su ítem. Sólo a 360 de ancho, no a 320. El 352 de ESPACIOS no sale de la card. ASM-05 («íconos y alto no cambian») sin assert. El test admin no mira `takeException()` | Borde de I9 a medias | M |
| 12 | H27-01 · contraste del atenuado | Resuelve el estilo con `<WidgetState>{}` (habilitado). La card deja abierta la contradicción «atenuado frente a deshabilitado» y CU-21 dice «deshabilitado con opacidad 40%»: falta el estado `disabled` (`alTocar: null`). Lee colores del estilo, no lo pintado: un `Opacity` envolvente o un texto translúcido no entra en `contraste()` (que asume opacos). Sólo GUARDAR SEDE; GUARDAR ESPACIO no por su pantalla | Puede pasar con el botón real todavía bajo AA | M |
| 13 | H18-02 · formato de fecha anunciado | Sólo la fecha de nacimiento del registro; el perfil (`pantalla_mi_perfil.dart`) tiene el mismo campo. No se mira el anuncio con un error presente (formato + error juntos) | «Afecta a todos los formularios» | L |
| 14 | archivo entero | Importa `comun/reloj.dart`: hasta que exista, los 13 tests están rojos por compilación, no por su razón. El rojo útil es el de la variante sin H27-03 | El rojo del archivo tal cual no distingue causas | L |

## Bordes de los criterios nombrados

- **I1** (contraste): sólo el estado habilitado del atenuado en oscuro (#12).
- **I7** (error y formato atados al campo): `CampoTexto` y la fecha del registro; `CampoSelector` y pantallas reales, no (#5, #13).
- **I9** (texto al 200 %): dos etiquetas a 360 px; el resto de destinos y 320 px, no (#11).
- **I20** (aviso que no se va solo): una forma de 422; formas mal tipadas y foco, no (#9, #10).
- **I22** (qué falta al enviar): formulario vacío y un faltante de texto; parciales, selector, limpieza al escribir y foco en el registro, no (#6, #7, #8).
- **I24** (foco en la opción segura): una de cuatro confirmaciones (#4).
- **I26** (fechas del club): función del reloj y calendario de nacimiento; pantallas con reloj fijo y validación tipeada, no (#2, #3).

## Pendiente

Nada sin correr de lo que tocaba a esta revisión: no se ejecutaron tests (se leyó el log dado). No se editó ningún test.
