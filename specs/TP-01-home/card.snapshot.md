---
card: TP-01
extraido: 2026-09-27T14:10:00-03:00
fuentes:
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 1 («Una vez iniciada la sesión, la aplicación deberá mostrar una página inicial (Home Page).») — texto de la card, sin CU propio"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 37:147 CU-01 · Home · Usuario"
  - "Figma · 43:1422 CU-02 · Tarjeta del avatar (overlay)"
  - "Figma · 43:1462 CU-24 · Notificaciones in-app (overlay)"
  - "Figma · 55:251 CU-14 · Panel admin · Reservas · Todas (inicio del administrador)"
no_leido: []
estado: propuesta
---

# Snapshot — TP-01 · Página inicial (Home)

Ningún CU especifica el contenido del Home: el enunciado pide que exista y el prototipo lo define.
La card transcribe las dos fuentes.

## Card, tal como está escrita

**Requerimiento funcional 1** (fuente: enunciado)
> «Una vez iniciada la sesión, la aplicación deberá mostrar una página inicial (Home Page).»

**Pantalla del prototipo** (fuente: Figma 37:147)
- Cabecera: «BUENOS DÍAS,» con el nombre del usuario («Nahuel») y el avatar con sus iniciales.
- Hero: «RESERVÁ TU CANCHA» · «4 sedes · 17 canchas · disponibilidad en tiempo real».
- «TU PRÓXIMA RESERVA» con «VER TODAS →»: tarjeta con deporte, sede y dirección, precio, estado
  «ACTIVA», código del espacio, fecha y horario, y los botones MODIFICAR y CANCELAR.
- «DEPORTES»: chips Fútbol, Tenis, Hockey, Vóley, Golf.
- «ACCESOS RÁPIDOS»: «Buscar cancha · Por sede, fecha y horario» y «Ver sedes · Explorá las 4 sedes».
- Barra inferior: INICIO · SEDES · RESERVAS · PERFIL.
- Avatar: abre la tarjeta con «Perfil completo», «Mis reservas» y «Cerrar sesión» (43:1422).
- Aviso de notificaciones: overlay «NOTIFICACIONES · MARCAR TODAS» sobre el Home (43:1462).

**Inicio del administrador** (fuente: Figma 55:251) — «PANEL ADMIN» con la barra RESERVAS · SEDES ·
ESPACIOS.

## Escenarios

- [ ] TP-01-H01-01 — al iniciar sesión ve el Home con el saludo y su nombre
- [ ] TP-01-H01-02 — el Home muestra su próxima reserva activa, la más cercana, con fecha, horario y sede
- [ ] TP-01-H01-03 — desde la próxima reserva puede modificarla o cancelarla
- [ ] TP-01-H01-04 — «Ver todas» lleva a Mis reservas
- [ ] TP-01-H01-05 — la cantidad de sedes y canchas del hero sale de los datos cargados
- [ ] TP-01-H01-06 — «Buscar cancha» lleva a Consultar canchas y «Ver sedes» al listado de sedes
- [ ] TP-01-H01-07 — la barra inferior lleva a Inicio, Sedes, Reservas y Perfil
- [ ] TP-01-H01-08 — desde la tarjeta del avatar llega a su perfil y a Mis reservas
- [ ] TP-01-H02-01 — sin reservas próximas, el Home no muestra la tarjeta de próxima reserva
- [ ] TP-01-H03-01 — un administrador, al iniciar sesión, llega al panel de administración

## Contradicciones dentro de la card

- El prototipo no muestra el Home sin reservas próximas; no está definido qué aparece en ese lugar
  · Figma 37:147.
- Los chips de deporte del Home no tienen destino definido en ningún CU · Figma 37:147.
- El saludo dice «BUENOS DÍAS»; no está definido si cambia según la hora · Figma 37:147.
