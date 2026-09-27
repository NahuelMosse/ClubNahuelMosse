# Implementation Plan: CU-04b · Recuperar contraseña

**Branch**: `card/CU-04b` | **Date**: 2026-09-27 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

Desde «¿Olvidaste tu contraseña?» la persona escribe su correo y pide un enlace; la app muestra
«Revisá tu correo» tenga o no cuenta ese correo. La API emite un enlace de un solo uso que vence en
30 minutos y lo manda por correo. El correo lleva un enlace https a la API
(`/enlace/recuperar#codigo=…`) cuya página abre la app con un intent de Android en «Creá una
contraseña nueva» (`clubnahuelmosse://app/recuperar?codigo=…`); al guardar, la API cambia la contraseña en Firebase,
el enlace deja de servir y todas las sesiones de la cuenta quedan vencidas. Reenviar el correo
reemplaza el enlace anterior. Un enlace vencido, usado o reemplazado muestra «El enlace no es
válido».

La contraseña sigue viviendo en Firebase (decisión 1). El enlace es de la API y no el de Firebase
porque así abre la pantalla del prototipo dentro de la app, y la API aplica las reglas de la
contraseña, el vencimiento de 30 minutos, el reemplazo al reenviar y el tope por hora.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Primary Dependencies**: firebase-admin (`update_user`); `smtplib` para el correo en producción
**Storage**: tablas `enlace_recuperacion` (sólo el hash del código) y `correo_saliente` (migración
0003)
**Testing**: pytest con el buzón · `integration_test` que lee el buzón por `/_pruebas` y abre la
app con el enlace, como Android
**Constraints**: los clientes de correo no vuelven tocable un esquema propio: por eso el enlace es
https y la API tiene que tener su dirección pública en `URL_PUBLICA`. Los correos salen por SMTP
(`SMTP_HOST`, `SMTP_PUERTO`, `SMTP_USUARIO`, `SMTP_CONTRASENA`, `CORREO_REMITENTE`); nada de eso
se guarda en el repo. `CORREO_MODO=buzon` y `/_pruebas` (con `PRUEBAS=1` y el emulador de Auth)
son sólo para desarrollo y escenarios

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Nueve escenarios; textos del prototipo (decisión 12) |
| II · Nada se supone en silencio | `CU-04b-SUP-01` a `SUP-04`; AMB-04 y AMB-05 resueltas por decisión |
| III · Tests antes del código | 9 escenarios de pantalla commiteados en rojo |
| IV · El backend es la autoridad | La API decide si el enlace sirve y valida la contraseña nueva |
| V · Rastro | Cada enlace guarda emisión, vencimiento, uso y reemplazo; el cambio estampa `contrasena_cambiada_en` |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-04b-SUP-01 | Una cuenta dada de baja no recibe enlace; la respuesta es la misma | `EnlacesSql.destinatario`; `test_una_cuenta_dada_de_baja_no_recibe_enlace` |
| CU-04b-SUP-02 | Como mucho tres enlaces por correo por hora | `MAXIMO_POR_HORA`; `test_despues_del_tope_por_hora_no_se_envian_mas` |
| CU-04b-SUP-03 | Un cambio de contraseña por otra vía invalida los enlaces emitidos antes | `_VIGENTE`; `test_cambiar_la_contrasena_por_otra_via_invalida_los_enlaces` |
| CU-04b-SUP-04 | La confirmación es «Contraseña actualizada» con «VOLVER AL INICIO DE SESIÓN» | `PantallaNuevaContrasena` |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/migraciones/versions/0003_recuperacion.py` | `enlace_recuperacion` y `correo_saliente` | el código se guarda como SHA-256 |
| `apps/api/app/dominio/recuperacion.py` | `Destinatario`, `EnlaceReclamado` | — |
| `apps/api/app/aplicacion/recuperacion.py` | `pedir_enlace` devuelve el correo a enviar, `enlace_vigente`, `usar_enlace` | el código va después del `#` del enlace: no llega a ningún registro de pedidos; una contraseña débil no gasta el enlace; si Firebase falla, el enlace vuelve a servir salvo que un reenvío lo haya reemplazado |
| `apps/api/app/infraestructura/enlaces.py` | consultas de enlaces | emitir toma un candado por cuenta, cuenta, invalida y guarda en una transacción: pedidos simultáneos no dejan dos vigentes ni saltean el tope; el vencimiento lo calcula la base; reclamar es un solo `UPDATE … RETURNING` |
| `apps/api/app/infraestructura/correo.py` | `enviar` al buzón o por SMTP | SMTP es el default y sale después de responder, así la demora no delata la cuenta; sin servidor configurado falla en el log, nunca en la respuesta |
| `apps/api/app/interfaz/recuperacion.py` | `POST /recuperacion` 202 · `POST /recuperacion/consulta` 204/410 · `PUT /recuperacion` 204/410/422 · `GET /enlace/recuperar` | el código viaja en el cuerpo, nunca en la ruta |
| `apps/api/app/interfaz/pruebas.py` | `/_pruebas/correos` y `/_pruebas/recuperacion/{codigo}/vencer` | sólo con `PRUEBAS=1` y el emulador de Auth, fuera del OpenAPI |
| `apps/mobile/android/app/src/main/AndroidManifest.xml` | el enlace `clubnahuelmosse://app/…` abre la app | — |
| `apps/mobile/lib/sesion/recuperacion.dart` | `Recuperacion`: pedir, consultar y usar el enlace | — |
| `apps/mobile/lib/sesion/pantalla_recuperar_contrasena.dart` | pedir el enlace y «Revisá tu correo» con reenvío | el formato se marca al salir del campo |
| `apps/mobile/lib/sesion/pantalla_nueva_contrasena.dart` | comprobar el enlace, crear la contraseña, resultado | una pantalla por código: otro enlace se vuelve a comprobar; si había sesión abierta se cierra al terminar; un «no es válido» después de un corte de red avisa que quizás ya se cambió |
| `apps/mobile/lib/comun/resultado.dart`, `usuarios/reglas_contrasena.dart`, `comun/boton.dart` | pantalla de resultado, reglas en vivo y barra de acción, compartidas con CU-04 | — |
| `scripts/e2e.sh` | la API de la corrida con `PRUEBAS=1` y el buzón | — |

## Brief visual

**Invención 1 · densidad 2.** Un flujo de «olvidé mi contraseña» como el de cualquier app.

- **Pedir el enlace.** Un campo y el botón fijo abajo. El error de formato aparece debajo del
  campo al salir de él.
- **Revisá tu correo · El enlace no es válido · Contraseña actualizada.** La misma pantalla de
  resultado: ícono en círculo, título, texto y una o dos acciones centradas.
- **Variables visuales.** Gris = aviso neutro (correo enviado); rojo = el enlace no sirve; verde =
  hecho; lima = la acción.
- **Material.** El de las cards anteriores.
