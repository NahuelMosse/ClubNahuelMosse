# Revisión de veredicto — REV-05 · Básquet en el catálogo

Fuente: `card.snapshot.md` (escenarios REV-05-H19-01 a H19-04). Cambio de producción: 15beb3f. No hay app compartida
(`.validation/app.json` no existe): la API se manejó en proceso (`TestClient` de `app.main.crear_app`) contra
`club_rev05_test` y el emulador de Auth en 127.0.0.1:9099, con datos `reviewer-…`; la pantalla de sede, con un widget
test propio. Scripts y salidas: `.validation/reviewer/probe_api.py` + `probe_api.log`,
`.validation/reviewer/filtro_basquet_test.dart` + `filtro.log`.

Veredicto: **falla H19-04 (la foto)**; H19-01, H19-02 y H19-03 se cumplen.

## 1. ¿Hace lo que pide la card?

| Escenario | Estado | Cómo |
|---|---|---|
| REV-05-H19-01 · el catálogo ofrece Básquet con su tipo de cancha | meets | `GET /espacios/catalogo` como socio: `('Basquet','Básquet',['B5:Básquet 5','3X3:Básquet 3x3'])`, entre Vóley y Hockey. |
| REV-05-H19-02 · el administrador da de alta una cancha de Básquet | meets (API) | `POST /espacios` como admin: `Basquet/B5` → 201 `…_Basquet_B5_1`; el segundo → `…_B5_2`; `Basquet/3X3` → 201 `…_Basquet_3X3_1` (numeración propia por tipo); `GET /espacios/nombre?…&tipo=3X3` → `…_3X3_2`. Formas inválidas: `3x3`, `Básquet`, `basquet`, `PAD` → 422 con mensaje de campo; `tipo: null` / `deporte: null` → 422; `tipo: ""` → 422 «Este campo es obligatorio»; como socio → 403. El formulario de alta de la app no se manejó: arma sus opciones del catálogo (`pantalla_alta_espacio.dart:245`) sin código propio de Básquet. |
| REV-05-H19-03 · el socio filtra los espacios por Básquet | meets | API: `GET /espacios?sede_id&deporte=Basquet` devuelve sólo las tres de Básquet (no la de Fútbol); con `tipo=3X3`, sólo la 3X3; `GET /sedes` da `deportes: ['Basquet','Futbol']`. App (widget test propio sobre `PantallaSede`): aparece un chip «Deporte Básquet» con el ícono de básquet; al tocarlo la app pide `/espacios?sede_id=1&deporte=Basquet` y muestra la barra de tipos «Básquet 5» / «Básquet 3x3». |
| REV-05-H19-04 · la app muestra Básquet con su ícono y su foto | **fails** (la foto); el ícono, meets | Ícono: `Icons.sports_basketball_rounded` en el chip (widget test). Foto: `fotoDeDeporte('Basquet')` es `assets/imagenes/sedes/portada_1.jpg`, y esa imagen es una **cancha de fútbol vista desde arriba** (arcos, áreas, círculo central sobre césped). Una cancha de Básquet se ve con foto de fútbol. El test `la foto de Básquet no es la de una cancha de fútbol` sólo afirma que difiere del asset de los otros deportes, no lo que muestra. |

## 2. Lo que está y la card no pidió

- `apps/api/README.md`, sección «Catálogo de deportes»: documentación de las decisiones ASM-01..03; no es comportamiento
  del producto. Sin objeción.
- `apps/mobile/test/soporte/montar.dart`: el catálogo falso de los tests suma Básquet; soporte de tests.
- No se encontró ningún comportamiento agregado fuera de lo que piden los cuatro escenarios.

## 3. Supuestos

ASM-01..03 vienen decididos y no se juzgan. Sólo se registra un hecho, que es la base del ACT de abajo: el texto de
ASM-02 dice «la portada 1 del club, que no es de ningún otro deporte», y la portada 1 es una cancha de fútbol (la
portada 4, que toman Fútbol y Hockey, también lo es). La opción entregada no cumple la condición del propio supuesto.

## Acciones

ACT-?? · F1 · M · REV-05-H19-04: la cancha de Básquet muestra como foto `portada_1.jpg`, que es una cancha de fútbol (abrir `apps/mobile/assets/imagenes/sedes/portada_1.jpg`; `fotoDeDeporte('Basquet')` la devuelve), contra ASM-02 «que no es de ningún otro deporte» · close: la imagen que devuelve `fotoDeDeporte('Basquet')`, abierta, no muestra una cancha de otro deporte (o el supuesto, reescrito en `ambiguities.md`, dice qué se acepta mostrar), y el test de H19-04 afirma eso y no sólo que el asset es distinto · open

## OUT (código que la card no tocó)

- REV-05-OUT-01 · L · Hockey (y todo deporte fuera del `switch`) cae en `portada_4.jpg`, también una cancha de fútbol
  (`apps/mobile/lib/sedes/fotos.dart`, rama `_`). Existía antes de la card.
- REV-05-OUT-02 · L · `GET /espacios` ordena dentro de un deporte por la clave del tipo (`ORDER BY … e.tipo`,
  `infraestructura/espacios.py:65`): `3X3` sale antes que `B5`, al revés del orden del catálogo; igual ya pasaba con
  Golf (`9H` antes que `DR`) y Tenis (`CEM` antes que `PDL`).
- REV-05-OUT-03 · L · `GET /espacios?deporte=Básquet` (clave que no existe) responde 200 con lista vacía en vez de
  rechazar la clave; comportamiento previo, igual para cualquier deporte desconocido.

## Observaciones

- El 403 de `POST /espacios` como socio llega con cuerpo vacío (no JSON); previo a la card.
- No se manejó la app real en un emulador ni el formulario de alta en pantalla: *could not run* en esta revisión
  (sin app compartida); el alta queda verificada en la API.
