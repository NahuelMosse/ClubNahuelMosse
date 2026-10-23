# Accesibilidad — REV-05 · Básquet en el catálogo

Lo que el diff toca de pantalla: una opción más en el chip de deportes (filtro de la sede, Home), una opción más en el
desplegable Deporte del alta de espacio, un ícono (`Icons.sports_basketball_rounded`) y la foto de las tarjetas de
cancha de Básquet (`portada_1.jpg`). No hay pantallas, componentes ni colores nuevos.

La app es Flutter sin destino web en este entorno: `app.mjs probe --axe` y `--contrast` no corren sobre ella. Lo que
se ve en pantalla lo mira el juez visual con las capturas.

| Criterio (WCAG 2.2) | Estado | Evidencia |
|---|---|---|
| 1.1.1 Contenido no textual | meets | El ícono acompaña al texto «Básquet» en el chip (`pantalla_sede.dart:311`, `pantalla_inicio.dart:476`); la foto va bajo `ExcludeSemantics` (`fotos.dart:33`), decorativa. |
| 1.3.1 Información y relaciones | meets | El chip conserva la etiqueta accesible con prefijo: «Deporte Básquet» (`pantalla_sede.dart:461`), igual que los otros deportes. |
| 1.4.3 Contraste (texto sobre la foto) | not verified | El texto de la tarjeta de Básquet va sobre `portada_1.jpg` con el velo de `FotoConVelo` (negro 20 % → 90 %, `fotos.dart:38-46`). `portada_1.jpg` es más oscura que `portada_4.jpg`, la de Fútbol, ya en uso con el mismo velo; no se midió el contraste sobre la foto. |
| 1.4.11 Contraste no textual (ícono) | meets | El ícono usa el mismo color que los otros deportes (`p.accentInk`, `pantalla_inicio.dart:479`); no cambia la paleta. |
| 2.4.6 / 3.3.2 Etiquetas | meets | «Básquet 5» y «Básquet 3x3» en el desplegable Tipo (salen de la API, `espacio.dart:25-41`). |
| 4.1.2 Nombre, función, valor | meets | El chip de Básquet es el mismo `_Chip` que los demás; no hay widget nuevo. Las pruebas de accesibilidad existentes (`test/accesibilidad_*_test.dart`, con `montar.dart` ya con Básquet en el catálogo) las corre `verify.mjs`. |
