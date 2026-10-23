# Auditoría de pantalla — REV-05 · Básquet en el catálogo

Pantallas tocadas: la sede del socio (filtro de deporte y tarjeta) y el alta de espacio (diálogos Deporte y Tipo). La card no
crea pantallas ni componentes: suma una opción de datos a componentes que ya existen. La app es Flutter: `motion-audit.mjs` y
`overflow.mjs` miden en un navegador y no corren sobre ella; la evidencia son las tiras de `.validation/capturas-rev05/x1/`.

| # | Item | Answer and evidence |
|---|---|---|
| 1 | Pointer hover feedback | not applicable · app móvil táctil sin puntero fino; el chip Básquet es el mismo componente que Fútbol y Tenis |
| 2 | Pointer press feedback | could not run · el chip y las opciones del diálogo son los componentes previos, sin cambio en la card; `motion-audit.mjs` es de navegador y la tira estática no muestra la pulsación |
| 3 | Keyboard focus feedback | could not run · mismo motivo que 2; la card no agrega elementos enfocables nuevos (una opción más del mismo `Wrap` y del mismo diálogo) |
| 4 | Selection transition | Básquet elegido toma el relleno acento como los demás chips (`x1/sede_basquet_360_oscuro.png`, `x1/sede_basquet_430_claro.png`); la transición es la del componente previo, no capturada en movimiento |
| 5 | Open / close transition | los diálogos Deporte y Tipo abren con el velo de siempre (`x1/deporte_lista_360_oscuro.png`, `x1/tipo_lista_430_claro.png`); la card no cambia su apertura |
| 6 | Content insertion | al elegir Básquet la lista queda con una tarjeta y «1 CANCHA · BÁSQUET» (`x1/sede_basquet_*`); la entrada de la lista es la previa del filtro, sin cambio de la card |
| 7 | Content removal | not applicable · la card no hace desaparecer nada; las tarjetas que salen al filtrar son el comportamiento previo de CU-20 |
| 8 | Loading state | not applicable · la card no agrega cargas; el filtro por Básquet usa el mismo pedido `GET /espacios?deporte=` que los demás deportes |
| 9 | Loading → success state | not applicable · mismo motivo que 8 |
| 10 | Error feedback | not applicable · la card no agrega errores (ambiguities.md, «Error»: los mensajes de siempre) |
| 11 | Layout changes | a 360 el tercer chip (Básquet) baja a una segunda línea del `Wrap` sin cortarse; a 430 entran los tres en una (`x1/sede_basquet_360_oscuro.png` contra `x1/sede_basquet_430_claro.png`); el diálogo Deporte con siete opciones entra sin scroll a 360×800 |
| 12 | Navigation continuity | not applicable · la card no agrega navegación |
| 13 | Progressive disclosure | el diálogo Tipo ofrece sólo los tipos de Básquet («Básquet 5», «Básquet 3×3») una vez elegido el deporte (`x1/tipo_lista_*`), como con los demás deportes |
| 14 | Empty → populated transition | not applicable · una sede sin canchas de Básquet no muestra el chip (ambiguities.md, «Empty case»: sigue igual) |
| 15 | Drag / reorder feedback, where applicable | not applicable · no hay nada que arrastrar ni reordenar |
| 16 | Reduced-motion behavior | not applicable · la card no agrega movimiento propio; el de los componentes previos no cambia |
