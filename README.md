# ClubNahuelMosse

Aplicación móvil para reservar espacios deportivos de distintas sedes, consultar su disponibilidad y recibir avisos de las
reservas próximas. Trabajo práctico de Electiva General, Universidad de Morón.

## Cómo se arma

| Parte | Carpeta | Tecnología |
|---|---|---|
| App móvil (sólo Android) | `apps/mobile` | Flutter |
| API REST | `apps/api` | FastAPI y SQLAlchemy, con PostgreSQL |
| Autenticación y avisos push | Firebase | Authentication y Cloud Messaging; el emulador de Auth está en `firebase.json` |
| Despliegue de la API y la base | `render.yaml` | Render (planes `free`) |

La app habla con la API por HTTPS; la API valida los tokens de Firebase, guarda en PostgreSQL y manda los avisos.

## Cómo se usa

Cada parte se configura, ejecuta, prueba y despliega con su propio README:

- [`apps/api/README.md`](apps/api/README.md): la API y su base, la configuración por variables de entorno y el despliegue en
  Render.
- [`apps/mobile/README.md`](apps/mobile/README.md): la app, sus `--dart-define` y cómo construir el APK.

Desde la raíz, `sh scripts/test.sh` corre los chequeos y las pruebas de la API y de la app; `npm run emuladores` levanta el
emulador de Firebase Auth (después de `npm ci`).

## Documentación

- [Diseño del sistema](docs/technical/system-design.md): arquitectura, modelo de datos, entornos, dependencias externas,
  amenazas, secretos, datos personales y presupuesto de rendimiento.
- [Decisiones de arquitectura](docs/adr): el stack ([0001](docs/adr/0001-stack.md)) y el hosting
  ([0002](docs/adr/0002-hosting-en-render.md)).
- [Runbook](docs/technical/runbook.md): despliegue, vuelta atrás, diagnóstico, incidentes y rotación de secretos.
- [Costo de la infraestructura](docs/technical/infra-cost.md).
- [Declaración de accesibilidad](docs/business/accessibility.md) y el registro por pantalla.
- [Matriz de seguridad ASVS](specs/asvs.md), nivel 2.
- [Licencias de terceros](THIRD_PARTY_NOTICES.md), generadas con `python scripts/avisos_de_terceros.py`.

Los supuestos que cambian lo que ve quien usa la app o lo que hace quien la opera están en los README de `apps/api` y
`apps/mobile`; el registro completo de cada caso de uso, en `specs/<caso>/ambiguedades.md`.

## Supuestos de la documentación

- REV-07-ASM-01: donde la app todavía no tiene algo (copias de seguridad, objetivos de servicio medidos, presupuesto de
  rendimiento) el documento lo dice tal cual y escribe el objetivo como meta sin medir.
- REV-07-ASM-02: los README de `apps/api` y `apps/mobile` listan los supuestos que cambian lo que ve quien usa o lo que hace
  quien opera, con su ID, y no los 545 registrados.
- REV-07-ASM-03: el modelo de datos lleva columnas, claves, índices y triggers de cada tabla.
- REV-07-ASM-04: estos documentos se escriben aunque el módulo de documentación del método esté apagado, porque los pide el
  grado de producción.
- REV-07-ASM-05: los documentos describen la rama `kit-3`; al integrar las otras correcciones se actualizan las filas y las
  secciones que cambian.
- REV-07-ASM-06: las filas de la matriz ASVS que hoy fallan quedan `fails` con el hallazgo y la card que las corrige; los
  plazos de remediación (V15.1.1) los decide una persona.
- REV-07-ASM-07: los avisos de terceros cubren las dependencias de producción, directas y transitivas, que el script lee de los
  paquetes instalados y de `pubspec.lock`; en Dart entran también las transitivas de las herramientas de desarrollo.
- REV-07-ASM-08: los precios salen de https://render.com/pricing.md consultado el 2026-10-20; la página no dice si la base
  free tiene backups.
- REV-07-ASM-09: la política de claves con su ciclo de vida, el inventario criptográfico completo y el documento de las vías
  de autenticación (ASVS V11.1.1, V11.1.2, V6.1.3) no estaban pedidos y los decide una persona: esas filas quedan `fails`.

## Estado

La revisión general de la rama `kit-3` (`specs/REVISION-kit3.md`) lista lo que hoy falla y lo que corrigen las cards
siguientes; los documentos de arriba describen la app como está en esa rama.
