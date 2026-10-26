# Runbook · ClubNahuelMosse

Para quien opera la API en Render y no la escribió. Frases cortas, comandos que se pegan, síntomas antes que causas. Lo que
no se ejecutó en Render dice `not verified`: el despliegue en Render no se hizo todavía (el escenario RNF-01-H06-01 se
saltea sin `API_URL_NUBE`). Los números de hallazgo remiten a la revisión de la rama `kit-3` (`specs/REVISION-kit3.md`).
La arquitectura está en [`arquitectura.md`](arquitectura.md), el diseño del sistema en
[`system-design.md`](system-design.md) y los costos en [`infra-cost.md`](infra-cost.md).

Dueño: pendiente de una persona · Última revisión: pendiente de una persona (la revisa alguien que no lo escribió)

## Deploy

La fuente de la configuración es `render.yaml`, en la raíz del repo. Render lo lee como Blueprint y crea el web service
`clubnahuelmosse-api` y la base `clubnahuelmosse-db`. Los pasos de la primera vez (cuenta, proyecto de Firebase, Blueprint,
sembrar al administrador) están en «Desplegar en Render» de `apps/api/README.md`.

Cada commit a la rama enlazada despliega solo. En cada despliegue Render corre, en `apps/api`:

1. Build: `uv sync --frozen --no-dev && uv run --no-sync alembic upgrade head`. **Las migraciones corren acá, contra la
   base real**, con la versión anterior todavía sirviendo: si fallan, el despliegue no sale y el servicio sigue con la
   versión anterior. Cada migración corre en su transacción y las que crean índices sobre tablas con datos lo hacen con
   `CONCURRENTLY` y `lock_timeout`, así que no bloquean a la versión que atiende.
2. Arranque: `uv run --no-sync uvicorn app.main:app --host 0.0.0.0 --port $PORT`.
3. Health check: `GET /health`, que responde 200 mientras el proceso está vivo.

Cómo saber que terminó: el estado del servicio en el panel de Render pasa a «Live» (`not verified`: no se hizo un
despliegue), `GET /health` devuelve la versión desplegada. Comprobación mínima de la API:
`GET /sedes` sin sesión responde 401. Con el plan free el primer pedido después de dormir tarda alrededor de un minuto.

## Roll back

**Código.** No hay un comando propio: se vuelve a desplegar el commit anterior. Dos caminos, en este orden de preferencia:

1. `git revert <commit malo>` y push a la rama enlazada: Render despliega el revert con el mismo build de arriba.
2. En el panel del servicio, desplegar a mano un commit anterior (`not verified`: no se usó el panel).

**Datos.** La base `free` no tiene copias automáticas, vence a los 30 días y se borra 14 días después: no hay vuelta atrás de
datos.

**Migraciones.** El build corre `alembic upgrade head`, pero no hay un comando de vuelta atrás en el despliegue. Si el commit
anterior no trae la última migración, Alembic se queja de una revisión que no conoce y el build falla (comportamiento
conocido de Alembic, no ensayado contra Render: `not verified`). La vuelta atrás de una migración se hace a mano, contra la
**External Database URL** de la base, desde `apps/api`: `DATABASE_URL=<External Database URL> uv run alembic downgrade -1`.
Tres bajadas borran tablas con datos y no se deben correr sobre una base con uso real: la 0003 (`correo_saliente`,
`enlace_recuperacion`), la 0005 (`notificacion`, `dispositivo`) y la 0007 (`notificacion_reserva` y las columnas `cantidad` y
`reemplazada_por`). La 0008 y la 0009 bajan sin perder reservas.

Cómo confirmar que sirve la versión anterior: el estado del despliegue en el panel, `GET /health` con la versión anterior y
el comportamiento que se había roto.

## Diagnose

Primer vistazo, en este orden:

1. `GET https://<servicio>.onrender.com/health`: si responde, el proceso web está vivo; trae la versión. Si tarda cerca
   de un minuto, estaba dormido (plan free).
2. `GET /sedes` sin sesión: 401 es lo normal.
3. El log del servicio en el panel de Render (`not verified`).
4. La base: `psql "<External Database URL>" -c "select 1"` (`not verified`: `psql` no se probó contra Render).

## Alerts, by symptom

No hay alertas definidas ni `runbook_url`. Lo que sigue es por síntoma, para quien lo ve en la app o en el log.

### base-caida: la app dice que no se pudo conectar

- **What the user sees:** el aviso de error de red con reintento.
- **Confirm:** `/health` responde pero las pantallas fallan; el log trae errores de `OperationalError`.
- **Mitigate:** comprobar que la base no venció (30 días en el plan free) y su estado en el panel de Render.
- **Verify:** `GET /sedes` con sesión responde 200.
- **Escalate:** si la base venció, sus datos se pierden a los 14 días de gracia: crear una base nueva y migrarla.

### esquema-viejo: errores en pantallas que usan tablas o columnas nuevas

- **What the user sees:** errores en las pantallas que usan tablas o columnas nuevas.
- **Confirm:** la base no está en la última migración (`alembic current` contra la base).
- **Mitigate:** correr `DATABASE_URL=<External Database URL> uv run alembic upgrade head` desde `apps/api`, o redesplegar.
- **Verify:** las pantallas responden.
- **Escalate:** si la migración falla, a quien escribió la migración, con el error.

### sin-recordatorios: no llegan los avisos de una hora antes

- **What the user sees:** ningún aviso push antes del turno; en el centro de avisos de la app el aviso sí aparece cuando
  la API está despierta.
- **Confirm:** el barrido corre dentro del proceso web cada `RECORDATORIOS_CADA` segundos y no corre mientras Render duerme
  el servicio. En la tabla `notificacion`, el `envio` del aviso dice qué pasó: `sin_permiso` (la persona no dio permiso),
  `sin_canal` (falta `FIREBASE_CREDENCIALES_JSON`), `fallida` (FCM falló; el log trae `aviso_sin_enviar` con el número del
  aviso).
- **Mitigate:** disparar el barrido desde afuera con `uv run python -m app.interfaz.barrido --una-vez` (por ejemplo, con un
  cron externo), o mantener el servicio despierto en la hora previa a los turnos.
- **Verify:** el aviso pasa a `enviada`.
- **Escalate:** el arreglo de fondo es un cron que llame al barrido; el plan free de Render no tiene cron jobs.

### sin-correo: no llega el correo de recuperación

- **What the user sees:** pide recuperar la contraseña y nunca llega el enlace; la respuesta es la misma que para un correo
  sin cuenta.
- **Confirm:** el log trae «no se pudo enviar el correo» con el asunto y el tipo de error (sin la dirección); el timeout es
  de 10 s y el certificado del servidor se verifica. Revisar `SMTP_HOST`, `SMTP_USUARIO`, `SMTP_CONTRASENA` y
  `CORREO_REMITENTE` en *Environment* del servicio.
- **Mitigate:** corregir la variable y volver a desplegar; si la contraseña de la cuenta de correo cambió, ver «Secret
  rotation and revocation».
- **Verify:** pedir la recuperación con una cuenta de prueba y recibir el correo.
- **Escalate:** a quien administra la cuenta de correo saliente.

### demasiados-pedidos: el ingreso responde 429

- **What the user sees:** pide esperar antes de reintentar.
- **Confirm:** el ingreso respondió `TOO_MANY_ATTEMPTS`: lo corta Firebase, la API no limita pedidos.
- **Mitigate:** esperar.
- **Verify:** el ingreso vuelve a funcionar.
- **Escalate:** si persiste, revisar el estado de Firebase Authentication.

## Support view

Quien opera busca en el log de Render la línea del error. Pendiente de una persona: niveles de soporte, quién tiene acceso al
log y auditoría de esos accesos.

## Escalation matrix

| Severity | Support level | Who | Channel | In how long | Data package passed |
|---|---|---|---|---|---|
| todas | pendiente de una persona | pendiente de una persona | pendiente de una persona | pendiente de una persona | hora UTC, ruta, qué se esperaba, qué pasó, pasos para repetirlo |

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
| `DATABASE_URL` | La entrega la base por `fromDatabase` en `render.yaml`. Cómo cambiar su contraseña: `not verified`, no se consultó el procedimiento de Render | las migraciones corren con la nueva y la vieja falla en `psql` |
| `ADMIN_CONTRASENA` | Sólo siembra la cuenta. Para cambiarla, la persona administradora usa «Recuperar contraseña» (CU-04-SUP-02) | iniciar sesión con la contraseña nueva; la vieja da error |

Ante una fuga, en este orden: revocar todo lo expuesto en la misma operación, emitir el reemplazo, desplegar, comprobar que el
valor viejo falla (401 o 403), limpiar el lugar de la fuga, revisar el uso del secreto en la ventana expuesta y dejarlo
registrado. Borrar el commit o reiniciar la API no revoca nada. Para cortar las sesiones de una cuenta, se le cambia la
contraseña: la API revoca sus refresh tokens al cambiarla (`ProveedorFirebase.cambiar_contrasena` en
`app/infraestructura/identidad.py`) y verifica cada token con `check_revoked=True`. No hay un comando para revocar las
sesiones de todas las cuentas a la vez.

No hay un escáner de secretos como pre-commit ni un gestor de secretos por ambiente: hoy el repo sólo evita versionar el
`.env` (`apps/api/.env.example` no tiene valores).

## Security incident response

Fases: detectar, contener, erradicar, recuperar y postmortem. **Detectar:** hoy no hay alertas; se detecta por un reporte, por
el log de Render. **Contener:** rotar lo expuesto con la sección anterior y, si hace falta, apagar el servicio
desde el panel de Render. **Erradicar y recuperar:** corregir la causa, desplegar y comprobar. Quién decide si hubo datos
personales involucrados (DNI, fecha de nacimiento, correo, token de dispositivo: `## Personal data` del diseño del sistema) y
si hay que avisar a las personas o a la autoridad por la Ley 25.326, se decide antes de que ocurra: pendiente de una persona;
no se consultó el texto de la ley (`not verified`). Toda filtración se documenta aunque no se notifique, y el postmortem
sigue sin culpas, con impacto, línea de tiempo, causas y acciones con dueño.
