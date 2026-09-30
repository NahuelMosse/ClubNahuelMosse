# Ambigüedades — CU-24.1 · Recibir notificación recordatoria

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | la card dice: sin permiso, el centro muestra «Notificaciones desactivadas» con la acción para activarlas (FA2); no dice qué muestra el centro sin ninguna notificación → CU-24.1-AMB-01
| Duplicados    | la card dice: «Se envía una sola vez, una hora antes del inicio»
| Validación    | no aplica: no hay datos de entrada
| Error         | la card dice: FA5 el reintento lo maneja el servicio de notificaciones; no dice qué pasa si el envío falla del lado del backend → CU-24.1-AMB-02
| Estado        | la card dice: queda registrada como enviada y como no leída si se ignora (FA3); no dice cómo pasa a leída → CU-24.1-AMB-03
| Permisos      | la card dice: el usuario tiene que haber concedido el permiso del sistema operativo
| Límites       | la card no dice qué pasa con una reserva creada con menos de una hora de anticipación → CU-24.1-AMB-04
| Orden         | la card no lo dice; el prototipo ordena el centro de la más nueva a la más vieja, agrupada por día → CU-24.1-AMB-05
| Concurrencia  | la card dice: FA4 cancelación o modificación antes del envío descartan o reprograman el recordatorio
| Rastro        | la card dice: «queda registrada como enviada»; no dice que se guarde la hora de envío y de lectura → CU-24.1-AMB-06

## Eventos
CU-24.1-AMB-01 · 2026-09-27 · abierta · con el permiso concedido y sin ninguna notificación, ¿qué muestra el centro?
CU-24.1-AMB-02 · 2026-09-27 · abierta · si el backend no puede enviar (token vencido, servicio caído), ¿reintenta? ¿cuántas veces?
CU-24.1-AMB-03 · 2026-09-27 · abierta · ¿una notificación pasa a leída al tocarla, al abrir el centro, o con «Marcar todas»?
CU-24.1-AMB-04 · 2026-09-27 · abierta · una reserva hecha con menos de una hora de anticipación, ¿recibe recordatorio inmediato o ninguno?
CU-24.1-AMB-05 · 2026-09-27 · abierta · ¿el centro ordena de la más nueva a la más vieja y agrupa por día? ¿cuánto tiempo guarda las notificaciones?
CU-24.1-AMB-06 · 2026-09-27 · abierta · ¿se guarda la hora de envío y la de lectura de cada notificación?
CU-24.1-AMB-07 · 2026-09-27 · abierta · sin permiso, ¿el recordatorio aparece igual en el centro de la app (como en CU-24.2 FA3) o no se registra?
CU-24.1-AMB-08 · 2026-09-27 · abierta · si el usuario cerró sesión o tiene varios dispositivos, ¿a qué dispositivos llega?
CU-24.1-AMB-00 · 2026-09-27 · snapshot · congelado en c8f04f1
CU-24.1-AMB-00 · 2026-09-27 · snapshot · congelado en 06b71f1
CU-24.1-AMB-04 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-24.1-AMB-04 · 2026-09-27 · resuelta · las tres notificaciones van por push y quedan en el centro de notificaciones; una reserva hecha con menos de una hora de anticipación no recibe recordatorio (decisión 10)
CU-24.1-AMB-07 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-24.1-AMB-07 · 2026-09-27 · resuelta · las tres notificaciones van por push y quedan en el centro de notificaciones; una reserva hecha con menos de una hora de anticipación no recibe recordatorio (decisión 10)
CU-24.1-AMB-08 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-24.1-AMB-08 · 2026-09-27 · resuelta · la sesión sigue abierta al reabrir la app y se permiten varias a la vez; al cerrar sesión el dispositivo deja de recibir push (decisión 14)
CU-24.1-AMB-01 · 2026-09-30 · sin canal · con el permiso concedido y sin ninguna notificación el centro muestra el estado vacío «Todavía no tenés notificaciones» con la leyenda «Acá vas a ver los recordatorios de tus reservas.» → CU-24.1-SUP-01
CU-24.1-AMB-02 · 2026-09-30 · sin canal · el backend no reintenta un envío fallido: la notificación queda en el centro con el envío marcado como fallido, y un token que el servicio rechaza por inválido se da de baja → CU-24.1-SUP-02
CU-24.1-AMB-03 · 2026-09-30 · sin canal · una notificación pasa a leída al tocarla o con «Marcar todas»; abrir el centro no las marca → CU-24.1-SUP-03
CU-24.1-AMB-05 · 2026-09-30 · sin canal · el centro ordena de la más nueva a la más vieja, agrupado en HOY, AYER y la fecha (dd/mm); se conservan todas, sin purga → CU-24.1-SUP-04
CU-24.1-AMB-06 · 2026-09-30 · sin canal · se estampan la hora de creación, la de envío y la de lectura de cada notificación → CU-24.1-SUP-05
CU-24.1-AMB-09 · 2026-09-30 · abierta · el envío push real (FCM) no se puede verificar sin proyecto Firebase ni credenciales: va detrás de un puerto en la API; la implementación FCM se activa sólo si el entorno trae GOOGLE_APPLICATION_CREDENTIALS y la de por defecto guarda lo enviado en memoria sin salir a ninguna red
CU-24.1-AMB-09 · 2026-09-30 · sin canal · el envío push real (FCM) no se puede verificar sin proyecto Firebase ni credenciales: va detrás de un puerto en la API; la implementación FCM se activa sólo si el entorno trae GOOGLE_APPLICATION_CREDENTIALS y la de por defecto guarda lo enviado en memoria sin salir a ninguna red → CU-24.1-SUP-06
CU-24.1-AMB-10 · 2026-09-30 · abierta · el recordatorio no se guarda como tarea agendada: se deriva de las reservas activas, y un barrido cada 30 s envía el de toda reserva que empieza dentro de la hora siguiente, creada o modificada con una hora o más de anticipación, y que no tenga ya su aviso; si el servidor estuvo caído y la reserva no empezó, el aviso sale tarde
CU-24.1-AMB-10 · 2026-09-30 · sin canal · el recordatorio no se guarda como tarea agendada: se deriva de las reservas activas, y un barrido cada 30 s envía el de toda reserva que empieza dentro de la hora siguiente, creada o modificada con una hora o más de anticipación, y que no tenga ya su aviso; si el servidor estuvo caído y la reserva no empezó, el aviso sale tarde → CU-24.1-SUP-07
CU-24.1-AMB-11 · 2026-09-30 · abierta · el permiso del sistema operativo lo informa la app al registrar cada dispositivo; sin ningún dispositivo con permiso no hay push y el aviso queda igual en el centro, que muestra «Notificaciones desactivadas»
CU-24.1-AMB-11 · 2026-09-30 · sin canal · el permiso del sistema operativo lo informa la app al registrar cada dispositivo; sin ningún dispositivo con permiso no hay push y el aviso queda igual en el centro, que muestra «Notificaciones desactivadas» → CU-24.1-SUP-08
CU-24.1-AMB-12 · 2026-09-30 · abierta · con la app abierta el aviso es el panel del prototipo (43:1462) con las notificaciones no leídas y «Marcar todas»; la app lo detecta consultando la API cada 20 s y al llegar un push en primer plano
CU-24.1-AMB-12 · 2026-09-30 · sin canal · con la app abierta el aviso es el panel del prototipo (43:1462) con las notificaciones no leídas y «Marcar todas»; la app lo detecta consultando la API cada 20 s y al llegar un push en primer plano → CU-24.1-SUP-09
CU-24.1-AMB-13 · 2026-09-30 · abierta · el centro se abre desde una campana con contador de no leídas en el Home del usuario; el administrador no tiene centro
CU-24.1-AMB-13 · 2026-09-30 · sin canal · el centro se abre desde una campana con contador de no leídas en el Home del usuario; el administrador no tiene centro → CU-24.1-SUP-10
CU-24.1-AMB-14 · 2026-09-30 · abierta · tocar un aviso abre Mis reservas con esa reserva resaltada; si ya no figura entre las próximas se abre Mis reservas sin resaltar
CU-24.1-AMB-14 · 2026-09-30 · sin canal · tocar un aviso abre Mis reservas con esa reserva resaltada; si ya no figura entre las próximas se abre Mis reservas sin resaltar → CU-24.1-SUP-11
CU-24.1-AMB-15 · 2026-09-30 · abierta · una reserva modificada recibe un aviso nuevo para su horario nuevo; el ya enviado por el horario anterior no se retira del centro
CU-24.1-AMB-15 · 2026-09-30 · sin canal · una reserva modificada recibe un aviso nuevo para su horario nuevo; el ya enviado por el horario anterior no se retira del centro → CU-24.1-SUP-12
CU-24.1-AMB-16 · 2026-09-30 · abierta · en el emulador de Firebase Auth (escenarios) la app usa un sistema de notificaciones simulado cuyo permiso se guarda en el dispositivo y arranca concedido; tocar el aviso en la bandeja del sistema y verlo en la pantalla bloqueada no se pueden ejecutar
CU-24.1-AMB-16 · 2026-09-30 · sin canal · en el emulador de Firebase Auth (escenarios) la app usa un sistema de notificaciones simulado cuyo permiso se guarda en el dispositivo y arranca concedido; tocar el aviso en la bandeja del sistema y verlo en la pantalla bloqueada no se pueden ejecutar → CU-24.1-SUP-13
CU-24.1-AMB-17 · 2026-09-30 · abierta · el aviso nombra el deporte con el tipo corto del catálogo («Fútbol 5», «Tenis») y las horas en la hora del club
CU-24.1-AMB-17 · 2026-09-30 · sin canal · el aviso nombra el deporte con el tipo corto del catálogo («Fútbol 5», «Tenis») y las horas en la hora del club → CU-24.1-SUP-14
CU-24.1-TESTS · 2026-09-30 · congelados en 7b15a2d
CU-24.1-AMB-18 · 2026-09-30 · abierta · el panel sólo se abre por una llegada si no quedan sin leer que ya avisó en esta sesión; lo que llega después de cerrarlo sin leer suma a la campana y no vuelve a tapar la pantalla, y en la primera lectura avisa lo que llegó en los últimos cinco minutos
CU-24.1-AMB-18 · 2026-09-30 · sin canal · el panel sólo se abre por una llegada si no quedan sin leer que ya avisó en esta sesión; lo que llega después de cerrarlo sin leer suma a la campana y no vuelve a tapar la pantalla, y en la primera lectura avisa lo que llegó en los últimos cinco minutos → CU-24.1-SUP-15
CU-24.1-AMB-19 · 2026-09-30 · abierta · el teléfono borra su token de FCM en todo camino de salida de la sesión; no se hace una baja por token sin sesión para reintentarla en el próximo arranque
CU-24.1-AMB-19 · 2026-09-30 · sin canal · el teléfono borra su token de FCM en todo camino de salida de la sesión; no se hace una baja por token sin sesión para reintentarla en el próximo arranque → CU-24.1-SUP-16
