# Revisión general · ClubNahuelMosse · `main`

`main` @ 61ad400 · 2026-10-24 · después de integrar las correcciones de la revisión anterior (`REV-01` a `REV-08`,
`INT-01`) y el rediseño (`RED-01` a `RED-04`). Revisión de la app entera —API, app Flutter, datos, despliegue,
seguridad y documentación— hecha por dos revisores independientes (uno para la API, otro para la app), más la suite
completa y la reverificación de la matriz ASVS. No se corrigió código ni se abrieron cards: cada hallazgo dice cómo se
arregla.

## Resumen

- **No hay hallazgos de gravedad alta.** Lo que la revisión de `kit-3` encontró grave (correo sin TLS verificado,
  base que colgaba la API, barrido sin recuperación, sin observabilidad, entradas que daban 500) está corregido y tiene
  test.
- **Diez hallazgos medios**: cinco de la API (casi todos de operación en Render) y cinco de la app (dos carreras de
  sesión, un manejo de cortes incompleto, una recarga de más y la firma del APK).
- **La suite no está en verde**: fallan ruff y `dart format`, y los tests reemplazados se cuentan como fallas (ver la
  sección propia). No hay regresiones de comportamiento: cada test que falla está reemplazado, salvo dos de entorno.
- **Lo que más conviene hacer primero**: poner la suite en verde, el 1 (`/ready` puede tumbar el servicio en un despliegue), el 6 (una carrera
  que cierra la sesión sola) y el 3 (logs que se salen del formato JSON). Son cambios chicos.
- **Seguridad**: de los 253 requisitos ASVS de nivel 2, 98 se cumplen, 29 fallan y el resto no aplica o no se pudo
  verificar (`specs/asvs.md`). De los 29 que fallan, la mayoría son decisiones pendientes de una persona (política de
  contraseñas, tiempos de sesión, retención de logs, plazos de remediación), no defectos de código.

## Qué corrió

| Corrida | Resultado |
|---|---|
| ruff (`apps/api`) | **falló** · 2 errores en tests congelados (ver «La suite no está en verde») |
| mypy estricto (`app`) | **pasó** |
| pytest contra Postgres 16 y el emulador de Auth | **falló** · 823 ok, 21 fallan, 1 saltado: 19 son tests reemplazados y declarados con `replaces:`; 2 no |
| `flutter analyze` | **pasó** · 0 issues |
| `dart format --set-exit-if-changed lib test` | **falló** · 14 de 192 archivos cambiarían |
| `flutter test` | **falló** · 598 ok, 9 fallan: los 9 son tests reemplazados y declarados con `replaces:` |
| Tests ad hoc de la app (carrera de `refrescar`, login con sesión, foco del buscador del admin) en una copia fuera del repo | reproducen los hallazgos 6, 7 y 9; se borraron |
| Logging real con la configuración de uvicorn y `crear_app()` | reproduce el hallazgo 3 |
| Reverificación de las 50 filas `fails` de la matriz ASVS contra el código | 21 pasan a `meets`, 29 siguen `fails` |
| Despliegue en Render, `X-Forwarded-For` real, health check en vivo | **no se pudo correr**: la API no está desplegada |
| e2e en el emulador Android, TalkBack en un dispositivo | **no se pudo correr**: fuera del alcance de esta revisión |
| Prueba de carga, auditoría de dependencias (salvo certifi) | **no se pudo correr** |

## La suite no está en verde

`scripts/test.sh` falla hoy en `main`, aunque todo lo que falla es de forma o está declarado:

- **ruff**: `tests/escenarios/test_contrato_publicado.py` (SIM300) y `tests/escenarios/test_suite_confiable.py` (F821,
  `CASOS_DE_USO` sin definir). Son tests congelados y reemplazados: no se pueden editar, y `scripts/test.sh` no sabe que
  los reemplazados no se lintean.
- **`dart format`**: 4 archivos de `lib` (`admin/listado_admin.dart`, `api/cliente_api.dart`, `main.dart`,
  `sesion/sesion.dart`) y 10 de `test` quedaron con otro formato después de integrar las REV. Los de `lib` se arreglan
  con `dart format` sobre esos cuatro archivos; los de `test` son congelados y no se reformatean.
- **pytest**: además de los 19 reemplazados, fallan dos que ninguna card declara.
  `test_datos_tandas_y_cola.py::test_la_pagina_avanzada_del_historial_global_no_recorre_las_filas_anteriores` cae junto
  con los demás reemplazados de ese archivo y probablemente es un reemplazo que no se anotó.
  `test_operacion.py::test_el_respaldo_se_guarda_y_se_restaura` necesita `pg_dump` en la máquina o
  `RESPALDO_PREFIJO`, y falla sin ellos.
- **Arreglo:** que `scripts/test.sh` excluya del lint y de la corrida los tests que una card declara reemplazados (o los
  marque como esperados), formatear los cuatro de `lib`, declarar el reemplazo que falta y que el test del respaldo se
  saltee sin `pg_dump`. Mientras tanto, una suite roja no distingue una regresión de lo ya sabido.

## Hallazgos

De más a menos grave. M = medio, L = bajo. «Confirmado» quiere decir reproducido con un test o un comando, o que el código
no admite otra lectura; «plausible» quiere decir que sale del código y no se reprodujo.

### M · API

1. **`/ready` exige que la base esté exactamente en la migración del código** · operación · confirmado (el reinicio de
   Render, plausible)
   - `apps/api/app/infraestructura/db.py` (`esquema_al_dia`: `actual == ultima`), usado por `/ready`, que es el health
     check de `render.yaml`.
   - Escenario: el build migra la base y la versión nueva no arranca. Render sigue con la vieja, pero la base ya está
     en una migración que el código viejo no conoce: `/ready` da 503 para siempre y Render puede reiniciar la
     instancia que andaba. Pasa también, por unos segundos, en cada despliegue con migraciones.
   - Arreglo: aceptar una base igual o más nueva que el código (`int(actual) >= int(ultima)`).

2. **Cada pedido con sesión espera a Firebase con una conexión de la base tomada** · operación · confirmado (la
   saturación, plausible)
   - `apps/api/app/interfaz/sesion.py` (`usuario_actual`) e `infraestructura/identidad.py` (`check_revoked=True` hace
     una llamada a Google por pedido).
   - Escenario: FastAPI resuelve `conexion` antes de verificar el token, así que con Firebase lento diez pedidos llenan
     el pool y el resto recibe 503. Con Firebase caído, `CertificateFetchError` y `UnavailableError` no se atrapan:
     cada pedido da 500 con traza en lugar de 503.
   - Arreglo: verificar el token en una dependencia que no tome conexión y traducir los errores de red de Firebase a
     503. Sacar `check_revoked` es la otra mitad de la decisión pendiente sobre la card de optimización.

3. **Tres módulos escriben fuera del log JSON** · observabilidad · confirmado
   - `apps/api/app/aplicacion/notificaciones.py`, `infraestructura/push.py` e `interfaz/barrido.py` usan
     `getLogger(__name__)`, fuera del árbol `clubnahuelmosse` al que `registro_errores.py` le pone el formato JSON.
   - Escenario: `aviso_sin_enviar` y «el barrido falló» salen como texto suelto, sin hora, nivel, referencia ni versión;
     los INFO de esos módulos se pierden. Los tests no lo ven porque `caplog` captura igual.
   - Arreglo: llamar a esos loggers `clubnahuelmosse.<módulo>`.

4. **El límite por origen depende de que Render agregue la IP al final de `X-Forwarded-For`** · seguridad · plausible
   - `apps/api/app/interfaz/limites.py` toma el último valor cuando `DETRAS_DE_PROXY=true`.
   - Escenario: si Render tiene más de un salto, el último valor es una IP interna y todos los anónimos comparten el
     cupo de 10 pedidos por minuto en registro y recuperación: un abusador frena a todos.
   - Arreglo: al desplegar, registrar un `X-Forwarded-For` real y ajustar qué valor se toma.

5. **Sin tope de reservas por persona ni límite de frecuencia en `POST /reservas`** · abuso · confirmado
   - `apps/api/app/aplicacion/reservas.py` (`reservar`).
   - Escenario: una cuenta con un script reserva todas las canchas de los próximos 7 días. Es una decisión documentada
     (CU-09-SUP-02), pero en producción es un riesgo.
   - Arreglo: un tope de reservas activas por persona o un límite por cuenta en la ruta.

### M · App

6. **Ir y volver a Perfil con la API lenta cierra la sesión** · correctitud · confirmado
   - `apps/mobile/lib/sesion/sesion.dart` (`refrescar`, compara `identical(_perfil, antes)`) y
     `usuarios/pantalla_mi_perfil.dart`.
   - Escenario: con Render despertando, la persona abre Perfil, va a Inicio y vuelve antes de la primera respuesta. Los
     dos `refrescar()` corren a la vez; el primero cambia `_perfil` y el segundo lo toma como sesión vencida: aparece
     «Tu sesión expiró» y la sesión se cierra. Los tests no lo ven porque `SesionFalsa` reemplaza `refrescar`.
   - Arreglo: compartir el `Future` del `refrescar` en curso, o comparar con un contador que sólo cambien `iniciar` y
     `cerrar`.

7. **Se puede llegar al login con la sesión abierta** · correctitud · confirmado (lo de los avisos, plausible)
   - `apps/mobile/lib/app.dart` (el `redirect` no mira `/`) y `sesion/pantalla_nueva_contrasena.dart` («Volver al inicio
     de sesión» hace `go('/')` sin cerrar la sesión).
   - Escenario: con sesión, abrir un enlace de recuperación vencido y volver: aparece el login con la sesión viva. Si
     entra con otra cuenta, `CentroDeNotificaciones` no rearranca y el teléfono sigue registrado para la primera: sus
     avisos le llegan a la segunda.
   - Arreglo: que el `redirect` mande `/` al inicio del perfil si hay sesión, y que el centro rearranque al cambiar de
     cuenta.

8. **Un timeout no cuenta como «puede haber llegado» en las operaciones que no se repiten** · correctitud · confirmado
   por lectura
   - `ServidorSinRespuesta` hereda de `ErrorDelServidor` (`apps/mobile/lib/api/cliente_api.dart`), pero la marca de
     corte sólo se pone con `SinConexion` en `usuarios/pantalla_registro.dart`, `usuarios/pantalla_mi_perfil.dart`,
     `admin/pantalla_formulario_sede.dart`, `admin/anular_reserva.dart` y `reservas/cancelacion.dart`;
     `reservas/pantalla_confirmar_cambio.dart` no maneja el corte.
   - Escenario: el registro tarda más de 60 s, la API crea la cuenta y la app dice «El servidor no responde». Al
     reintentar, el 409 se muestra como «correo ya registrado» en lugar del mensaje pensado para ese caso. Al modificar
     una reserva, aparece «Otra persona modificó estos datos» cuando fue la misma persona.
   - Arreglo: una función `puedeHaberLlegado(e)` que cuente también `ServidorSinRespuesta`.

9. **Tocar el buscador del panel de admin recarga el listado** · UX · confirmado
   - `apps/mobile/lib/admin/pantalla_panel_admin.dart`: el listener reacciona a cualquier cambio del controlador (foco,
     cursor) y `_cargar` vacía la lista.
   - Escenario: el admin bajó tres páginas y toca el buscador: a los 300 ms vuelve el spinner y la página 1. Abrir o
     limpiar los filtros probablemente dispara una segunda recarga (plausible).
   - Arreglo: ignorar los avisos en los que el texto no cambió, como ya hace `pantalla_registro.dart`.

10. **El APK `release` se firma con la clave de depuración** · publicación · confirmado
    - `apps/mobile/android/app/build.gradle.kts` (quedó el TODO de la plantilla).
    - Consecuencia: no se puede publicar en Play, y un APK armado en otra máquina no actualiza al instalado.
    - Arreglo: un `signingConfig` de release que lea `key.properties`, fuera de git.

### L · API

11. **Un NUL en `GET /espacios/disponibles?deporte=` da 500** · `apps/api/app/interfaz/horarios.py`: `deporte` y `tipo`
    son `str` sin el validador de texto, y el test de NUL sólo cubre cuerpos. Arreglo: usar `Texto40`. Confirmado por
    lectura.
12. **Un recordatorio puede salir dos veces** · `infraestructura/notificaciones.py` lo registra `pendiente` y no pasa por
    `enviando`; si el proceso cae después de que FCM lo aceptó, `tomar_siguiente` lo vuelve a mandar, contra la regla de
    «se envía una sola vez». Arreglo: registrarlo `enviando` con `tomada_en`. Raro.
13. **Un aviso reemplazado mientras estaba `enviando` puede quedar trabado** · las consultas de varados y de toma excluyen
    `reemplazada_por` no nulo; la trazabilidad del admin muestra el envío vacío para siempre. Raro.
14. **La hora del club está definida dos veces** · `dominio/notificaciones.py` usa un desfase fijo de −3 h y
    `dominio/zona.py` usa `ZoneInfo`. `tests/unit/test_capas.py` sólo busca el literal de la zona, así que no lo detecta.
    Sólo importa si Argentina vuelve al horario de verano.
15. **El contrato publicado contradice el código en `PUT /dispositivos`** · la descripción (`interfaz/notificaciones.py`
    y `openapi.json`) dice que un token de otra cuenta pasa a quien lo pide, y desde REV-01 no pasa. Además, la baja de
    una cuenta no desactiva sus dispositivos (lo mitiga que la app borra su token al salir).
16. **Las migraciones no tienen `lock_timeout` global** · sólo lo pone la 0008; una migración futura que espere un lock en
    el build deja esperando a la API en vivo. Arreglo: `SET lock_timeout` en `migraciones/env.py`.
17. **`/ready` relee los archivos de migración en cada llamada** · `esquema_al_dia`. Costo menor; cachear el head.
18. **Un `IntegrityError` inesperado puede llevar datos personales al log** · el DETAIL «Failing row contains (…)» no lo
    tapa `hide_parameters`. Plausible, no observado.
19. **`scripts/usuario_de_la_app.py` recibe la clave por argumento** · queda en el historial de la terminal; `sembrar_admin`
    la toma de una variable de entorno.
20. **Duplicación** · `_leer_hora` está tres veces en `interfaz/` (sólo una con `re.ASCII`); varias rutas arman a mano las
    respuestas de error que ya ofrece `respuestas.py`; el agrupado de avisos y sus textos viven en
    `infraestructura/notificaciones.py`, cuando son reglas del dominio.

### L · App

21. **Contraste bajo en bordes y en la línea del día** · `borderControl` da 1,84:1 contra el fondo oscuro (WCAG 1.4.11
    pide 3:1) en campos de texto y chips; en la línea del día, libre contra ocupada da 1,45:1 en oscuro y 1,13:1 en
    claro; el chip «ACTIVA» en claro da 4,39:1. `paleta_test` sólo cubre texto sobre superficies.
22. **La pantalla de arranque ignora el tema elegido** · `_Marco` en `main.dart` no recibe `themeMode`: en modo claro se ve
    el arranque claro y después la app en oscuro.
23. **El aviso «despertando» no se anuncia con TalkBack** · `comun/aviso_despertando.dart` sin `liveRegion`.
24. **El manifest no fija `allowBackup`** · el refresh token de Firebase puede entrar en la copia automática de Android.
    Plausible.
25. **El bloqueo por intentos se muestra como «Revisá tus datos»** · `sesion.dart` trata `too-many-requests` como
    credenciales inválidas y empuja a seguir intentando.
26. **Código muerto y detalles** · `enDelClub` es un alias de `enElClub`; el caso 429 de `cambiarContrasena` no se alcanza;
    «BUENOS DÍAS,» es fijo sin importar la hora; `test/anular_desde_el_detalle_test.dart` está excluido del análisis;
    el inicio y los horarios piden en serie lo que podrían pedir en paralelo; los errores de producción sólo van a
    `debugPrint`.

### Documentación

27. **Los documentos describían la rama `kit-3`** · `system-design.md`, el runbook, los README y la matriz ASVS decían que
    el health check era `/docs`, que no había logs JSON, métricas ni `X-Request-ID`, y que el SMTP no verificaba TLS. Se
    actualizaron junto con esta revisión, y se sumaron [`docs/technical/arquitectura.md`](../docs/technical/arquitectura.md)
    y [`docs/technical/mapa-del-codigo.md`](../docs/technical/mapa-del-codigo.md).

## Sin hallazgo

Los dos revisores buscaron y no encontraron:

- **Doble reserva ni deadlocks**: exclusión GiST, bloqueos en el mismo orden en todos los caminos (cuenta → sede →
  espacio → reserva), revalidación si la sede cambió de horario e idempotencia en reservar, modificar, cancelar y anular.
- **IDOR**: todas las rutas filtran por dueño o por rol.
- **Bucles de `redirect`** en la app, ni controladores, timers o listeners sin liberar.
- **Secuestro del enlace de recuperación**: el código va en el fragmento y la página abre la app con un `intent://` atado
  al paquete.
- **Tokens o datos personales en los logs** de la app ni de la API (salvo el caso plausible 18).
- **Zona horaria** mal calculada: hay un reloj inyectable y un test de arquitectura que lo exige.
- **Entradas desmesuradas** (`horas`, `pagina`, fechas extremas) que den 500: están acotadas.

## Puntos fuertes

- Las reglas duras están en la base, no sólo en el código: exclusión de superposición, horas en punto, total coherente,
  bajas lógicas con triggers, identidad inmutable.
- La cola de avisos se recupera sola: el aviso se encola en la misma transacción que el hecho, se toma con
  `SKIP LOCKED` y los varados se retoman con intentos acotados.
- Los tiempos de espera son explícitos en cada dependencia, y una base caída da 503 con referencia en segundos.
- La superficie está endurecida: Host permitido, tope de cuerpo, CSP, `/docs` apagado en producción, `/metrics` con
  token, `/_pruebas` con doble candado y la API que se niega a arrancar con el emulador junto a credenciales reales.
- Las capas de la API se vigilan con tests de arquitectura y mypy estricto; la app tiene análisis estricto limpio.
- La app resuelve bien el arranque en frío de Render (espera de 60 s, aviso a los 5 s, reintento sin perder la sesión) y
  respeta «quitar animaciones» en todo el movimiento.
- Cada escenario de cada card tiene su test con el tag en el nombre: desde un requisito se llega al test y al revés.

## Qué no se pudo correr

- El despliegue en Render: el comportamiento de `/ready` en un despliegue fallido (hallazgo 1), el `X-Forwarded-For` real
  (hallazgo 4) y el dormir del plan free.
- Los e2e en el emulador Android, TalkBack en un dispositivo y la app al 200 % en Horarios.
- Una prueba de carga, la ida y vuelta de las migraciones con datos fuera de la suite y una auditoría completa de
  dependencias.
- Pantallas de admin en detalle (alta y edición de espacio, formulario de sede, detalle, filtros), sede, sedes y las de
  contraseña: el revisor de la app no llegó a recorrerlas.
