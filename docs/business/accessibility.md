# Accesibilidad de ClubNahuelMosse

ClubNahuelMosse quiere que todas las personas puedan reservar un espacio deportivo desde la app. Este documento dice cuánto
se logró hoy, sin adornos: lo que no se probó figura como `not verified`.

## Standard

La app apunta a cumplir WCAG 2.2 nivel AA. El contexto legal es la Ley 26.653 de accesibilidad de la información en las
páginas web, que informa el texto; no se evaluó el cumplimiento de la ley.

## Conformance status

Cumple parcialmente (Partially conforms), al 2026-10-20. La app es una aplicación Android de Flutter; los resultados usan los
cuatro términos del VPAT 2.5Rev INT.

| Area | Result (Supports, Partially Supports, Does Not Support, Not Applicable) | Notes |
|---|---|---|
| Keyboard operation | Partially Supports | en las confirmaciones irreversibles ningún botón tiene `autofocus` y el primer Tab cae en el destructivo (`lib/comun/dialogo_error.dart:316-345`, hallazgo 18, I24); el resto del teclado `not verified` |
| Screen readers (reader and browser tested) | Partially Supports | pruebas de semántica en widget tests (68 de 68 pasan); TalkBack no se corrió: `not verified`. El error de cada campo es un nodo aparte y el formato esperado («DD / MM / AAAA») queda oculto para el lector (I7) |
| Zoom and reflow (200 % text, 320 px) | Partially Supports | 170 capturas a 320 px y 170 al 200 % sin excepción de desborde; con el texto al 200 %, la barra inferior corta «RESERVAS» en «RESERV» (I9); 6 capturas de alta de espacio fallan a 320×568, sin analizar (hallazgo 27) |
| Color and contrast | Partially Supports | el botón `atenuado` en modo oscuro da 4,06:1 con 15 px en negrita, debajo de AA (`lib/comun/boton.dart:44-47`); el resto no se midió pantalla por pantalla |
| Forms and errors | Partially Supports | I7 y, al enviar el registro, no se dice qué falta (hallazgo 17) |
| Time limits and motion | Partially Supports | el rechazo de una reserva sale en un SnackBar de 4 s y la pantalla vuelve atrás al mismo tiempo (I20); el movimiento `not verified` |

## How it was assessed

La revisión del 2026-10-20 de la rama `kit-3` (`specs/REVISION-kit3.md`, hallazgos 17, 18 y 27) la hizo el equipo de
desarrollo, sin una auditoría externa. Corrieron: 68 tests de accesibilidad de widgets, que pasaron; capturas golden de 85
vistas a 360 y 430 px en oscuro y claro, 340 de 340 sin diferencias, y 170 a 320 px y 170 al 200 % sin excepción de
desborde; sondas de semántica y de foco en widget tests para I7, I20 e I24. **No corrieron:** TalkBack en un teléfono o
emulador (`not verified`), la prueba de teclado en un dispositivo, un lector de pantalla de iOS (la app sólo se construye
para Android), ni una auditoría externa.

## Registro por pantalla

Una fila por pantalla (`apps/mobile/lib/**/pantalla_*.dart`). «Supports» quiere decir que no se encontró ninguna falla en
los tests de widgets ni en las capturas; no que se probó con TalkBack (`not verified` en todas). Las referencias I7, I9, I20 e I24
son las de la revisión; la columna dice cuál afecta a cada pantalla.

| Pantalla | Resultado | Qué se encontró | Verificado |
|---|---|---|---|
| `pantalla_inicio_sesion` | Partially Supports | I7: errores de campo como nodo aparte | widget tests y capturas; TalkBack `not verified` |
| `pantalla_registro` | Partially Supports | I7; al enviar, no dice qué falta (hallazgo 17) | widget tests y capturas; TalkBack `not verified` |
| `pantalla_registro_exitoso` | Supports | sin fallas encontradas | widget tests y capturas; TalkBack `not verified` |
| `pantalla_recuperar_contrasena` | Partially Supports | I7 | widget tests y capturas; TalkBack `not verified` |
| `pantalla_nueva_contrasena` | Partially Supports | I7 | widget tests y capturas; TalkBack `not verified` |
| `pantalla_cambiar_contrasena` | Partially Supports | I7 | widget tests y capturas; TalkBack `not verified` |
| `pantalla_mi_perfil` | Partially Supports | I7; I9 (barra inferior); I24 en la baja de cuenta | widget tests y capturas; TalkBack `not verified` |
| `pantalla_inicio` | Partially Supports | I9 (barra inferior); I24 en la cancelación | widget tests y capturas; TalkBack `not verified` |
| `pantalla_sedes` | Partially Supports | I9 (barra inferior) | widget tests y capturas; TalkBack `not verified` |
| `pantalla_sede` | Partially Supports | I9 (barra inferior) | widget tests y capturas; TalkBack `not verified` |
| `pantalla_buscar_cancha` | Partially Supports | I7 en fecha y horas | widget tests y capturas; TalkBack `not verified` |
| `pantalla_horarios` | Supports | sin fallas encontradas | widget tests y capturas; TalkBack `not verified` |
| `pantalla_confirmar_reserva` | Partially Supports | I20: SnackBar de 4 s con la pantalla volviendo atrás | widget tests y capturas; TalkBack `not verified` |
| `pantalla_confirmar_cambio` | Partially Supports | I20 | widget tests y capturas; TalkBack `not verified` |
| `pantalla_reserva_confirmada` | Supports | sin fallas encontradas | widget tests y capturas; TalkBack `not verified` |
| `pantalla_mis_reservas` | Partially Supports | I9 (barra inferior); I24 en la cancelación | widget tests y capturas; TalkBack `not verified` |
| `pantalla_notificaciones` | Supports | sin fallas encontradas | widget tests y capturas; TalkBack `not verified` |
| `pantalla_acceso_denegado` | Supports | sin fallas encontradas | widget tests y capturas; TalkBack `not verified` |
| `pantalla_panel_admin` | Partially Supports | I9 («ESPACIOS» toca el borde al 200 %); I24 en las bajas | widget tests y capturas; TalkBack `not verified` |
| `pantalla_sedes_admin` | Supports | sin fallas encontradas | widget tests y capturas; TalkBack `not verified` |
| `pantalla_formulario_sede` | Partially Supports | I7; contraste del botón GUARDAR SEDE (4,06:1 en oscuro); I24 en la baja | widget tests y capturas; TalkBack `not verified` |
| `pantalla_sede_creada` | Supports | sin fallas encontradas | widget tests y capturas; TalkBack `not verified` |
| `pantalla_espacios_admin` | Partially Supports | I24 en la baja de espacio | widget tests y capturas; TalkBack `not verified` |
| `pantalla_alta_espacio` | Partially Supports | I7; contraste del botón GUARDAR ESPACIO; 6 capturas fallan a 320×568 (sin analizar) | widget tests y capturas; TalkBack `not verified` |
| `pantalla_editar_espacio` | Partially Supports | I7; contraste del botón GUARDAR ESPACIO; I24 en la baja | widget tests y capturas; TalkBack `not verified` |
| `pantalla_espacio_creado` | Supports | sin fallas encontradas | widget tests y capturas; TalkBack `not verified` |
| `pantalla_filtros_reservas` | Partially Supports | I7 | widget tests y capturas; TalkBack `not verified` |
| `pantalla_detalle_reserva` | Partially Supports | I24 en la anulación de una reserva | widget tests y capturas; TalkBack `not verified` |
| `pantalla_error_de_arranque` | Supports | sin fallas encontradas (test/pantalla_error_de_arranque_test.dart) | widget tests; TalkBack `not verified` |

## Known limitations

- **Errores de formulario (I7).** Afecta a todos los formularios; quien usa un lector de pantalla no oye el formato esperado
  de la fecha y encuentra el error en un nodo aparte. Alternativa: ninguna escrita. Corrección: pendiente de una persona.
- **Rechazo de una reserva (I20).** El aviso dura 4 s y la pantalla vuelve atrás a la vez: quien lo necesita más tiempo puede
  perderlo. Alternativa: la reserva no aparece en «Mis reservas». Corrección: pendiente de una persona.
- **Confirmaciones irreversibles (I24).** Sin foco inicial: con teclado, el primer Tab cae en el botón destructivo. Corrección:
  pendiente de una persona.
- **Texto al 200 % (I9).** La barra inferior corta «RESERVAS» y «ESPACIOS» toca el borde. Corrección: pendiente de una persona.
- **Contraste.** El botón `atenuado` en oscuro, 4,06:1. Corrección: pendiente de una persona.
- **Lector de pantalla.** No se probó con TalkBack, así que pueden existir fallas que los tests de widgets no ven.

Quién corrige cada una y cuándo no está decidido: el pedido de esta documentación no corrige código.

## Feedback and contact

Cómo avisar de una barrera de accesibilidad, quién responde y en cuánto tiempo: pendiente de una persona. Hasta que se decida,
se avisa a quien mantiene el repositorio.

## Date

Última revisión: 2026-10-20, sobre la rama `kit-3`. La hizo el equipo de desarrollo; no la revisó una persona externa.
