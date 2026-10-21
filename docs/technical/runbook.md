# Runbook · ClubNahuelMosse

Para quien opera la API en Render y no la escribió. Frases cortas, comandos que se pegan, síntomas antes que causas. Lo que
no se ejecutó en Render dice `not verified`: el despliegue en Render no se hizo (escenario RNF-01-H06-01 saltado sin
`API_URL_NUBE`, revisión «Cobertura sólo nominal»). La arquitectura está en `docs/technical/system-design.md`; los costos,
en `docs/technical/infra-cost.md`.

Dueño: pendiente de una persona · Última revisión: pendiente de una persona (la revisa alguien que no lo escribió)

## Deploy

La fuente de la configuración es `render.yaml`, en la raíz del repo. Render lo lee como Blueprint y crea el web service
`clubnahuelmosse-api` y la base `clubnahuelmosse-db`. Los pasos de la primera vez (cuenta, proyecto de Firebase, Blueprint,
sembrar al administrador) están en «Desplegar en Render» de `apps/api/README.md`.

Cada commit a la rama enlazada despliega solo. En cada despliegue Render corre, en `apps/api`:

1. Build (`render.yaml:11`): `uv sync --frozen --no-dev && uv run --no-sync alembic upgrade head`. **Las migraciones corren
   acá, contra la base real**: si fallan, el despliegue no sale y el servicio sigue con la versión anterior.
2. Arranque (`render.yaml:12`): `uv run --no-sync uvicorn app.main:app --host 0.0.0.0 --port $PORT`.
3. Health check (`render.yaml:14`): `GET /docs`. No usa la base: con la base caída el despliegue igual se da por sano.

Cómo saber que terminó: el estado del servicio en el panel de Render pasa a «Live» (`not verified`: no se hizo un
despliegue) y `https://<servicio>.onrender.com/openapi.json` devuelve el esquema. Comprobación mínima de la API: `GET /sedes`
sin sesión responde 401. Con el plan free el primer pedido después de dormir tarda alrededor de un minuto
(`apps/api/README.md`, «Límites del plan free»).

## Roll back

**Código.** No hay un comando propio: se vuelve a desplegar el commit anterior. Dos caminos, en este orden de preferencia:

1. `git revert <commit malo>` y push a la rama enlazada: Render despliega el revert con el mismo build de arriba.
2. En el panel del servicio, desplegar a mano un commit anterior (`not verified`: no se usó el panel).

**Datos: no hay vuelta atrás.** La base `free` no tiene backups, vence a los 30 días y se borra 14 días después (revisión,
hallazgo 4). No hay RPO ni RTO, ni restore probado. Lo que una migración o un error borró no se recupera.

**Migraciones.** El build corre `alembic upgrade head`, pero no hay un comando de vuelta atrás en el despliegue. Si el commit
anterior no trae la última migración, Alembic se queja de una revisión que no conoce y el build falla (comportamiento
conocido de Alembic, no ensayado acá: `not verified`). La vuelta atrás de una migración se hace a mano, contra la
**External Database URL** de la base, desde `apps/api`: `DATABASE_URL=<External Database URL> uv run alembic downgrade -1`.
Tres bajadas borran tablas con datos y no se deben correr sobre una base con uso real: la 0003 (`correo_saliente`,
`enlace_recuperacion`), la 0005 (`notificacion`, `dispositivo`) y la 0007 (`notificacion_reserva` y las columnas `cantidad` y
`reemplazada_por`). La ida y vuelta 0001 a 0007 con datos pasó en la revisión; no está en la suite. Las migraciones no son
seguras en caliente (hallazgo 13).

Cómo confirmar que sirve la versión anterior: el estado del despliegue en el panel, `GET /openapi.json` y el comportamiento
que se había roto.

## Diagnose

Primer vistazo, en este orden:

1. `GET https://<servicio>.onrender.com/docs`: si responde, el proceso web está vivo. Si tarda cerca de un minuto, estaba
   dormido (plan free).
2. `GET /sedes` sin sesión: 401 es lo normal. Un 500 apunta a la base o a un error del código.
3. El log del servicio en el panel de Render (`not verified`). Es una línea de texto por evento
   (`%(asctime)s %(levelname)s %(name)s %(message)s`, `app/interfaz/registro_errores.py:15`); las respuestas de error 5xx
   traen `<método> <ruta> <código> usuario=<id>` y el traceback. No hay métricas, trazas, tableros ni `X-Request-ID`
   (hallazgo 15).
4. La base: `psql "<External Database URL>" -c "select 1"` (`not verified`: `psql` no se probó contra Render). Con la base
   en una dirección sin ruta la API no corta la conexión: un pedido tardó 131 s en dar 500 (hallazgo 2).

## Alerts, by symptom

No hay alertas definidas ni `runbook_url` (hallazgo 15). Lo que sigue es por síntoma, para quien lo ve en la app o en el log.

### sin-conexion: la app dice «Revisá tu conexión a internet»

- **What the user sees:** el aviso de conexión, aunque el teléfono tenga internet. La app corta cada pedido a los 15 s
  (`lib/api/cliente_api.dart:28`).
- **Confirm:** abrir `/docs` en el navegador; si tarda cerca de un minuto, es el servicio dormido del plan free.
- **Mitigate:** esperar a que despierte y reintentar. Antes de una demostración, abrir `/docs`.
- **Verify:** la app inicia sesión sin el aviso.
- **Escalate:** si pasa un minuto y `/docs` no responde, mirar el estado del servicio en Render.

### base-caida: todo lo que usa la base da error de servidor

- **What the user sees:** «El servidor no respondió», con `/docs` en verde porque no usa la base.
- **Confirm:** `GET /sedes` con sesión da 500 y el log trae un traceback de `psycopg` o `sqlalchemy`.
- **Mitigate:** comprobar que la base no venció (30 días en el plan free) y su estado en el panel de Render.
- **Verify:** `GET /sedes` responde 200 con sesión.
- **Escalate:** si la base venció, sus datos se pierden a los 14 días de gracia: sin backups no hay restauración.

### sin-recordatorios: no llegan los avisos de una hora antes

- **What the user sees:** ningún aviso push antes del turno.
- **Confirm:** el barrido corre dentro del proceso web (`app/main.py:26-31`) y no corre mientras Render duerme el servicio
  (hallazgo 3); un aviso que falla queda `fallida` sin reintento ni alerta.
- **Mitigate:** mantener el servicio despierto en la hora previa a los turnos, por ejemplo con un pedido a `/docs`.
- **Verify:** la tabla `notificacion` del aviso pasa a `enviada`.
- **Escalate:** el arreglo de fondo lo corrige REV-02.

### sin-correo: no llega el correo de recuperación

- **What the user sees:** pide recuperar la contraseña y nunca llega el enlace; la respuesta es la misma que para un correo
  sin cuenta.
- **Confirm:** el error de SMTP va al log (`app/infraestructura/correo.py:41-42`); el timeout es de 10 s. Revisar `SMTP_HOST`,
  `SMTP_USUARIO` y `SMTP_CONTRASENA` en *Environment* del servicio.
- **Mitigate:** corregir la variable y volver a desplegar; si la contraseña de la cuenta de correo cambió, ver «Secret
  rotation and revocation».
- **Verify:** pedir la recuperación con una cuenta de prueba y recibir el correo.
- **Escalate:** a quien administra la cuenta de correo saliente.

### ingreso-frenado: la persona no puede iniciar sesión y la API responde 429

- **What the user sees:** pide reintentar más tarde.
- **Confirm:** Firebase respondió `TOO_MANY_ATTEMPTS` (`app/infraestructura/identidad.py:92-93`); la API no bloquea por su
  cuenta.
- **Mitigate:** esperar; Firebase levanta el freno solo.
- **Verify:** el ingreso vuelve a funcionar.
- **Escalate:** no hace falta.

## Support view

No hay una vista para soporte: no existen ids de referencia en los errores que ve la persona (hallazgo 14) ni una herramienta de
búsqueda en el log. Quien opera busca por hora y ruta en el log de Render. Pendiente de una persona: niveles de soporte,
máscara de datos personales y auditoría de accesos.

## Escalation matrix

| Severity | Support level | Who | Channel | In how long | Data package passed |
|---|---|---|---|---|---|
| todas | pendiente de una persona | pendiente de una persona | pendiente de una persona | pendiente de una persona | hora UTC, ruta, usuario si se conoce, qué se esperaba, qué pasó, pasos para repetirlo |

## Incidents

Se declara un incidente si la persona usuaria lo ve y no se resuelve con una de las secciones de arriba, si hace falta otra
persona, o si sigue sin resolverse a la hora. Al declararlo se nombran tres roles (quien lidera, quien comunica y quien
anota; pueden ser la misma persona) y se abre un documento vivo con una línea de tiempo en hora UTC: qué se vio, qué se
hizo y a qué hora. Primero se frena el daño (volver al commit anterior, apagar el barrido con `RECORDATORIOS_CADA=0`) y
después se busca la causa. Al cerrarlo se escribe un postmortem sin culpas: impacto, línea de tiempo, causa y acciones con
dueño. Dónde se anota y quién lidera es una decisión pendiente de una persona.

## Communication

Cuatro estados, con un texto breve para cada uno: Investigando, Identificado, Monitoreando, Resuelto. Primer mensaje a los 5
minutos de declarar el incidente, novedades cada 20 minutos como mínimo en las primeras dos horas, siempre con la hora de la
próxima. El cierre dice si hubo pérdida de datos. Por qué canal se avisa a socios y administradores no está decidido:
pendiente de una persona.

## Secret rotation and revocation

Inventario con nombres y lugares, sin valores: `## Secrets inventory` de `docs/technical/system-design.md`. En Render viven
como variables de *Environment* del servicio; cambiar una exige volver a desplegar. Dueños, frecuencia y fechas de
rotación: pendientes de una persona.

| Secreto | Cómo se rota | Cómo se comprueba que el valor viejo dejó de servir |
|---|---|---|
| `FIREBASE_CREDENCIALES_JSON` | Consola de Firebase → *Configuración del proyecto* → *Cuentas de servicio* → *Generar nueva clave privada*; pegar el JSON completo en la variable; desplegar; borrar la clave vieja de la cuenta de servicio en Google Cloud | la API arranca y verifica tokens con la clave nueva; la clave vieja ya no figura en la cuenta de servicio (`not verified` en la consola) |
| `SMTP_CONTRASENA` | Cambiarla en el proveedor de correo y después en la variable; desplegar | pedir la recuperación de una cuenta de prueba y recibir el correo; el proveedor rechaza la contraseña vieja |
| `FIREBASE_API_KEY` | Crear una clave nueva en Google Cloud (credenciales del proyecto), cambiar la variable de la API y construir de nuevo el APK con la `--dart-define=FIREBASE_API_KEY` nueva: la clave viaja dentro de la app | la app nueva inicia sesión; borrar la clave vieja deja sin servicio a las instalaciones viejas |
| `DATABASE_URL` | La entrega la base por `fromDatabase` (`render.yaml:18-21`). Cómo cambiar su contraseña: `not verified`, no se consultó el procedimiento de Render | la API se conecta con la nueva y la vieja falla en `psql` |
| `ADMIN_CONTRASENA` | Sólo siembra la cuenta. Para cambiarla, la persona administradora usa «Recuperar contraseña» (CU-04-SUP-02) | iniciar sesión con la contraseña nueva; la vieja da error |

Ante una fuga, en este orden: revocar todo lo expuesto en la misma operación, emitir el reemplazo, desplegar, comprobar que el
valor viejo falla (401 o 403), limpiar el lugar de la fuga, revisar el uso del secreto en la ventana expuesta y dejarlo
registrado. Borrar el commit o reiniciar la API no revoca nada. Para cortar las sesiones de una cuenta, se le cambia la
contraseña: la API revoca sus refresh tokens al cambiarla (`app/infraestructura/identidad.py:103`) y verifica cada token con
`check_revoked=True` (`identidad.py:72`). No hay un comando para revocar las sesiones de todas las cuentas a la vez.

No hay un escáner de secretos como pre-commit ni un gestor de secretos por ambiente: hoy el repo sólo evita versionar el
`.env` (`.env.example` no tiene valores).

## Security incident response

Fases: detectar, contener, erradicar, recuperar y postmortem. **Detectar:** hoy no hay alertas; se detecta por un reporte o por
el log de Render. **Contener:** rotar lo expuesto con la sección anterior y, si hace falta, apagar el servicio desde el panel
de Render. **Erradicar y recuperar:** corregir la causa, desplegar y comprobar. Quién decide si hubo datos personales
involucrados (DNI, fecha de nacimiento, correo, token de dispositivo: `## Personal data` del diseño del sistema) y si hay
que avisar a las personas o a la autoridad por la Ley 25.326, se decide antes de que ocurra: pendiente de una persona; no se
consultó el texto de la ley (`not verified`). Toda filtración se documenta aunque no se notifique, y el postmortem sigue sin
culpas, con impacto, línea de tiempo, causas y acciones con dueño.
