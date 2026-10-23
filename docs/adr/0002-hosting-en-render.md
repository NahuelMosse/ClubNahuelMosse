# ADR-0002: Render para la API y la base de datos en la nube

## Status

`accepted` · 2026-10-03 · NahuelMosse (autor del repo), al resolver RNF-01-AMB-05 (commit eb1041f); el `render.yaml` entró en 5ab2343 el
mismo día.

## Problem and requirement

El enunciado exige que la API REST y la base estén disponibles en la nube y nombra a Render como ejemplo. El escenario
RNF-01-H06-01 (API y base en la nube) lo pide. La restricción es el presupuesto: el autor no tiene un gasto mensual
previsto para la demostración.

## Alternatives

### Alternative A — Render: web service de Python y Postgres gestionado, con un `render.yaml`

| Axis | Answer |
|---|---|
| Meets the requirement | sí: el Blueprint `render.yaml` define la API y la base; el despliegue real no se hizo y el escenario RNF-01-H06-01 se saltea sin `API_URL_NUBE` (revisión, «Cobertura sólo nominal») |
| Deployment ease | un Blueprint y las variables `sync: false`; los despliegues siguientes salen solos con cada commit de la rama (`apps/api/README.md`, «Desplegar en Render») |
| Monthly infra cost | hoy USD 0 con web y base `free`; con plan pago, web USD 7 y Postgres USD 6 al mes como mínimo, según https://render.com/pricing.md consultado el 2026-10-20 (`docs/technical/infra-cost.md`) |
| Cost to operate | en el plan free el servicio se duerme a los 15 minutos, el barrido de recordatorios se detiene, la base no tiene backups y vence a los 30 días (hallazgos 3 y 4); `preDeployCommand` no existe, así que las migraciones corren en el build (`render.yaml:9-11`) |
| Corrective maintenance cost | el autor no lo usó en producción todavía; la configuración se reproduce desde el repo; la documentación y el soporte son los de Render (`not verified`) |
| Lock-in and exit | bajo: la API es un proceso `uvicorn` con `DATABASE_URL` y la base es Postgres estándar; migrar es dump y restore más otro host, pero no hay backups hoy con qué probarlo |

### Alternative B — Railway, Fly.io o una base gratuita aparte (Neon o Supabase) con la API en otro servicio

| Axis | Answer |
|---|---|
| Meets the requirement | sí en general; el enunciado menciona Render como ejemplo, no como obligación |
| Deployment ease | varios servicios, o un contenedor propio con Dockerfile que el repo no tiene |
| Monthly infra cost | según la pregunta RNF-01-AMB-05: Railway sin plan gratuito permanente y desde unos USD 5 al mes; Fly.io unos USD 5 a 15 al mes; los precios no se volvieron a consultar (`not verified`) |
| Cost to operate | con la base separada de la API, dos cuentas y dos paneles que cuidar |
| Corrective maintenance cost | el autor no los conoce (`not verified`) |
| Lock-in and exit | similar a A mientras la base sea Postgres estándar |

## Decision and why

Se eligió la alternativa A: es el ejemplo del enunciado, no cuesta nada para la demostración y un solo Blueprint describe la
API y la base. Se acepta como costo que el plan free duerme el servicio, que los recordatorios no salen con el servicio dormido
y que la base no tiene backups y vence a los 30 días. Se revisa en cuanto se quiera una instalación real del club: el
cambio a planes pagos de web y base, o a un cron para el barrido, queda como decisión de una persona (`docs/technical/infra-cost.md`
y `docs/technical/runbook.md`).
