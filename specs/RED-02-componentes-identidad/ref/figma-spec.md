# Rediseño «Camiseta del club» — lo que fija el Figma

Archivo: https://www.figma.com/design/zCsUSxyy2QjwEJ7AyR6XWt (copia del usuario). Componentes en la
página `02 · Components` (1:3); pantallas en `03 · App · Prototipo` (1:4).

## Tokens de color (colección `Color`, modos Dark | Light)

Los nombres mapean 1:1 a `Paleta` de `apps/mobile/lib/tema/tokens.dart` (`bg/surface-raised` → `bgSurfaceRaised`).

| token | Dark | Light |
|---|---|---|
| bg/base | #0B0A12 | #FFFFFF |
| bg/surface | #17152A | #F4F4F6 |
| bg/surface-raised | #211E3A | #FFFFFF |
| bg/scrim | #000000 @A8 | #000000 @73 |
| bg/hero-from | #2A1A55 | #EEE8FF |
| bg/hero-to | #0B0A12 | #FFFFFF |
| text/primary | #FFFFFF | #0A0A0B |
| text/secondary | #A9A3C2 | #52525B |
| text/muted | #87819F | #6B6B75 |
| text/inverse | #0B0A12 | #FFFFFF |
| text/on-media | #FFFFFF | #FFFFFF |
| text/on-media-muted | #DCD8EE | #D4D4D8 |
| border/default | #2C2847 | #E4E4E7 |
| border/control | #3E3961 | #8A8A93 |
| border/focus | #A88BFF | #6D3CF0 |
| border/error | #FF4D6A | #D92D4A |
| accent/base | #7C4DFF | #6D3CF0 |
| accent/on | #FFFFFF | #FFFFFF |
| accent/muted | #7C4DFF @26 | #6D3CF0 @47 |
| accent/ink | #D4FF3D | #5B2BD6 |
| accent/edge | #7C4DFF @00 | #6D3CF0 |
| accent/on-media | #D4FF3D | #D4FF3D |
| state/danger | #FF4D6A | #D92D4A |
| state/danger-ink | #FF7B8E | #B4233D |
| state/danger-muted | #FF4D6A @2E | #DC2626 @1F |
| state/danger-strong | #E02D4A | #B91C1C |
| state/success | #3DD68C | #16A34A |
| state/success-ink | #3DD68C | #15803D |
| state/success-muted | #3DD68C @2E | #16A34A @1F |
| state/warning | #FFB020 | #D97706 |
| state/warning-ink | #FFB020 | #A85B00 |
| state/disabled | #3E3961 | #D4D4D8 |

(@xx = alfa en hex.) Escala: space 4/8/12/16/20/24/32/40/48; radius md 12, lg 20, pill 999;
iconos 16/20/24; toque mínimo 44. Tipografías: Archivo Black (cifras, dorsales, iniciales),
Archivo, Inter, JetBrains Mono (códigos, números de ficha, marcas horarias).

## Componentes nuevos de identidad

- **Marca/Isotipo** 64×64: escudo de trazo `accent/base` 2.5 con pelota/cancha estilizada y punto
  relleno. Se usa en Login, Ficha de socio (32×32) y como marca.
- **Marcador** 345×72: fila de 3 celdas (SEDES · CANCHAS · LIBRES HOY) separadas por líneas de
  1×40 `border/default`; fondo `bg/scrim` @0.66 con desenfoque de fondo, borde `accent/base` 1, radio 16,
  padding 12/4. Cifra Archivo Black 28 ls −1 (`text/on-media`; la de LIBRES HOY en `accent/base`),
  rótulo Inter Bold 11 tracking 8% `text/on-media-muted`, gap 2.
- **Tile-Deporte** 124×148 radio 20: foto del deporte con degradé oscuro abajo, emoji 16 + nombre
  Inter SemiBold 17 `text/on-media`. Estados Default / Selected / Pressed.
- **Ficha-Socio** 345×261 (perfil): foto + degradé, borde `accent/base` 1.5, radio 24, padding 20,
  gap 18. Dorsal gigante «10» Archivo Black 170 ls −4 sólo con trazo `accent/base` @0.28 detrás.
  Encabezado: «FICHA DE SOCIO» Inter Bold 11 tracking 8% `accent/on-media` + «N° 000127 · DESDE 2026»
  JetBrains Mono 13 `text/on-media-muted`, isotipo 32 a la derecha. Identidad: iniciales en
  cuadrado 76 radio 20 `accent/base` (Archivo Black 28 `accent/on`), nombre Inter Bold 20 y correo
  Inter Medium 13. Abajo un Marcador con estadísticas del socio.
- **Linea-Del-Dia** 345 (horarios): tarjeta `bg/surface` borde `border/default` radio 16 padding 14
  gap 8. Cabecera «TU DÍA EN LA CANCHA» Inter Bold 11 tracking 8% + leyenda (Libre = lima @0.30,
  Ocupado = #3A3A40, Elegido = lima). Fila de 15 cuadrados 18×18 radio 4 (08 a 22 h, gap 3) y marcas
  08/12/16/20/23 en JetBrains Mono 11 `text/muted`.
- **Card-Sede** 345×216 radio 20: portada 158 alto con degradé verde (#1C4530→#0D211A→#050A08) o foto;
  dorsal gigante con el número de canchas (Archivo Black 92 sólo trazo `text/on-media` @0.45) y
  rótulo «CANCHAS»; contador en bloque `accent/base` radio 12; rating en píldora negra @0.6; pie
  `bg/surface` con tags píldora y acción «Ver canchas» `accent/ink` + chevron. Estado Pressed.
- **Card-Reserva** (pase troquelado) 345 radio 20 `bg/surface-raised` borde `border/default`: arriba
  miniatura 48 radio 12 + info + precio `accent/ink` y badge de estado; **troquel**: línea punteada
  `border/control` 1.5 con dos muescas circulares de 16 del color de fondo a los lados; detalle con
  cuenta regresiva («FALTAN 2 DÍAS» Inter Bold 11 tracking 8% `accent/ink`), código de cancha en
  JetBrains Mono 13, fecha y horario; acciones Modificar (contorno) y Cancelar (contorno danger);
  **borde lima** de 4 a la izquierda (`accent/base`) en las activas. Variantes Rol × Estado
  (Activa, Completada, Anulada, Cancelada).

## Animaciones (sólo al entrar a una pantalla o al cambiar de estado; se reproducen una vez)

Curvas: EASE_OUT ≈ Curves.easeOut; GENTLE ≈ spring suave (Curves.easeOutCubic sirve); QUICK ≈
easeOutQuart; BOUNCY ≈ Curves.elasticOut suave / easeOutBack; EASE_OUT_BACK = Curves.easeOutBack.

- **Entrada escalonada** (patrón general): bloques de la pantalla aparecen con opacidad 0→1 y
  desplazamiento Y +12..26 → 0 en 0.40–0.50 s easeOut, escalonados ~0.08–0.10 s.
  Login: isotipo cae de −70 con rotación 25°→0 (0.70 s, rebote) y opacidad 0.2 s; hero Y 16→0
  (0.30–0.70 s); form 0.46 s; botón 0.54 s; pie 0.62 s.
  Home (llegada): claim 0.05 s; Marcador opacidad 0.25→0.50 y escala 0.85→1 (0.5 s quick);
  sección «Tu próxima reserva» Y 26→0 a 0.45 s; tiles de deporte entran desde X +120 con rotación −8°→0
  y rebote (0.55 s) escalonados desde 0.70 s; accesos rápidos igual.
  Perfil: Ficha-Socio Y −24→0 y rotación −3°→0 (0.55 s gentle), tarjetas de datos/seguridad/
  apariencia/zona de riesgo escalonadas.
- **Error de validación**: el campo con error (o el snackbar) tiembla en X: 0 → −9 → 9 → −6 → 6 → −3 → 0
  en 0.36 s (pasos de 0.06 s).
- **Éxito** (registro, cambio de contraseña, alta): círculo del ícono escala 0.4→1 con rebote (0.55 s)
  y opacidad 0.2 s; el tilde se dibuja (path trim 0→1, 0.45 s desde 0.17 s); título, texto y acciones
  entran Y 14→0 escalonados (0.37/0.46/0.55 s).
- **Reserva confirmada (festejo)**: fondo de festejo aparece 0.3 s; aros concéntricos giran
  −120° en 2.3 s easeOut; chispas escalan 0→1.6→1 (0.45 s) desde 0.37 s; el «grito» (título grande)
  escala 0.55→1 easeOutBack 0.5 s desde 0.42 s; el comprobante aparece a 0.87 s y sus filas bajan
  desde −228 (0.7 s easeOut).
- **Horarios**: al elegir duración, la Línea del día late (escala 1→1.03→1, 0.5 s) y el slot elegido
  escala 0.88→1 con rebote (0.4 s). Elegir slot: transición 0.3 s gentle.
- **Modales/diálogos**: opacidad 0.2 s + escala 0.88→1 quick 0.4 s. Panel inferior (filtros): scrim
  opacidad 0.25 s + panel desde Y +420 (0.45 s gentle). Tarjeta del avatar: Y −16→0 0.35 s.
- **Push in-app**: entra desde Y −150 con rebote (0.6 s), escala 0.94→1, opacidad 0.12 s.
- **Presión de botones**: estado presionado en 0.08 s easeOut (escala ~0.97).

Transiciones entre pantallas:
- Pestañas de la barra inferior: **instantáneas** (sin animación).
- Avanzar en un flujo (CTA, Editar, Registrarse, Olvidé): **push desde la derecha 0.32 s easeOut**.
- Volver/breadcrumb/cancelar: push inverso 0.28 s easeOut; botón atrás del sistema igual.
- Filtros, chips, tabs internas, segmented: **no recargan la pantalla**: el contenido cambia en
  su lugar con 0.12–0.20 s (cross-fade / smart animate del indicador); chips de deporte 0.3 s gentle.
- Éxito que cierra flujo (Btn-Primary → resultado): dissolve 0.25 s.
- Overlays (filtros, baja, anular): aparecen sobre la pantalla con su propia animación (arriba).

Respetar `MediaQuery.disableAnimations` / reducir movimiento: todo pasa a instantáneo o cross-fade corto.
