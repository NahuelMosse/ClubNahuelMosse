# Costo de la infraestructura · ClubNahuelMosse

Modelo de costos de la API y su base. Hoy todo corre en los planes `free` de Render y cuesta USD 0 por mes; el modelo
dice cuánto costaría sostener la app en producción con los planes pagos más chicos y qué pasaría con diez veces el
volumen. La arquitectura actual está en `docs/technical/system-design.md` (`## Infrastructure`); el hosting, en
`docs/adr/0002-hosting-en-render.md`. Se actualiza en cada card que toca la infraestructura.

Los precios de Render salen de https://render.com/pricing.md, consultado el 2026-10-20. Lo que esa página no dice, o que
no se consultó, figura como `not verified`.

## Volume assumptions

Nada de esto está medido: la app no se desplegó en Render (`docs/technical/system-design.md`, `## Infrastructure`) y no hay
métricas de uso. Son supuestos de esta card (REV-07-ASM-01), y los objetivos de capacidad son los de
`## Performance and capacity budget` del diseño del sistema.

| Assumption | Today | Growth per month | Source |
|---|---|---|---|
| Active users | sin uso real: `not verified` | no estimado | REV-07-ASM-01; objetivo de 20 personas con sesión a la vez (`system-design.md`, presupuesto de capacidad) |
| Orders (reservas) per day | sin uso real: `not verified` | no estimado | REV-07-ASM-01 |
| Stored data (GB) | por debajo de 1 GB, supuesto: el techo de capacidad es de 100 000 reservas | no estimado | REV-07-ASM-01; el tamaño en disco no se midió (`not verified`) |
| Outbound traffic (GB per month) | `not verified`: no se midió | no estimado | REV-07-ASM-01 |
| Logs, metrics and traces ingested (GB per month) | 0: no hay observabilidad de producción, sólo el log de texto de la API (`system-design.md`, `## Observability`) | no aplica | revisión, hallazgo 15 |

A 10x se toma diez veces el objetivo de capacidad: 200 personas con sesión a la vez y 50 pedidos simultáneos. Con el pool
de 15 conexiones de la API (`system-design.md`, `## Infrastructure`) ese volumen no entra en una sola instancia sin
cambiar la configuración: es una estimación, no una medición.

## Cost per component

| Component | Provider | Plan | Public price | URL | Date checked | Cost today | Cost at 10x |
|---|---|---|---|---|---|---|---|
| Compute: web service de la API | Render | `free` (`render.yaml:7`) | free: USD 0. Alternativas: `0.5c-512mb` USD 7/mes; `1c-2g` USD 25/mes | https://render.com/pricing.md | checked: 2026-10-20 | USD 0 | USD 25/mes (`1c-2g`), supuesto: la instancia chica no alcanza para 200 personas; no se midió |
| Database: Postgres gestionado | Render | `free` (`render.yaml:47`) | free: USD 0 y vence a los 30 días con 14 de gracia. Alternativas: `0.1c-256mb` USD 6/mes; `0.5c-1g` USD 19/mes | https://render.com/pricing.md | checked: 2026-10-20 | USD 0 | USD 19/mes (`0.5c-1g`) |
| Storage and backups | Render | almacenamiento de la base | USD 0,30 por GB al mes, 1 GB incluido. Backups lógicos en instancias pagas y recuperación a un punto en el tiempo de 3 días (Hobby) o 7 (Pro). La página no dice si la base free tiene backups | https://render.com/pricing.md | checked: 2026-10-20 | USD 0: la base free está sin backups (revisión, hallazgo 4) | USD 0 si la base sigue por debajo de 1 GB (supuesto); USD 0,30 por cada GB de más |
| Network and CDN | Render | ancho de banda incluido en el plan | `not verified`: no se leyó el precio del tráfico de salida | https://render.com/pricing.md | checked: 2026-10-20 | USD 0 | `not verified` |
| Observability: ingest and retention of logs, metrics and traces | ninguno | no hay observabilidad de producción | no aplica | no aplica | checked: 2026-10-20 | USD 0 | `not verified`: sin proveedor elegido; lo decide REV-02 |
| Third-party services (mail, push) | Firebase (Authentication y Cloud Messaging) y un servidor SMTP | planes de la cuenta de Firebase y de la cuenta de correo | `not verified`: no se consultaron los precios de Firebase ni del proveedor de correo | no consultada | no consultada | `not verified` | `not verified` |

Alternativa para el barrido de recordatorios (hallazgo 3 de la revisión: hoy corre dentro del proceso web, que el plan
free duerme): un cron de Render a USD 0,00016 por minuto, cada minuto, son 43 200 minutos al mes, unos USD 6,91 por mes.
Es un cálculo sobre el precio por minuto; el cobro mínimo por ejecución `not verified`. No hay una decisión tomada.

## Totals

Los totales suman sólo los precios verificados: Render web y base. Firebase y el correo quedan afuera (`not verified`).

| | Per month | Per year |
|---|---|---|
| Today (planes free) | USD 0 | USD 0 |
| Producción con los planes pagos más chicos (`0.5c-512mb` USD 7 más `0.1c-256mb` USD 6) | USD 13 | USD 156 |
| At 10x (`1c-2g` USD 25 más `0.5c-1g` USD 19) | USD 44 | USD 528 |

## What breaks first

Antes que el costo se agota lo que da el plan free, no el presupuesto: la base free vence a los 30 días y se borra 14 días
después, sin backups ni vuelta atrás de datos (revisión, hallazgo 4), y el servicio se duerme a los 15 minutos sin tráfico
(`apps/api/README.md`, «Límites del plan free»). Para operar de verdad hay que pasar la base a un plan pago, USD 6 por mes
como mínimo, y el web service a uno que no se duerma, USD 7 por mes como mínimo. Con diez veces el volumen lo que crece más
rápido es la base (USD 19 por mes y USD 0,30 por GB), y el límite que se alcanza antes es el pool de 15 conexiones por
instancia, no el precio.
