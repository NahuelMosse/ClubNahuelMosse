# ADR-0001: FastAPI con PostgreSQL para la API, Flutter para la app y Firebase para la identidad

## Status

`accepted` · 2026-09-27 · NahuelMosse (autor del repo). Fecha de los commits que armaron cada pieza: la API en d13f90d y la app en
c55abec, ambos del 2026-09-27.

## Problem and requirement

El enunciado del TP pide una app móvil en Flutter, una API REST documentada con Swagger/OpenAPI (lenguaje libre,
«preferentemente Python»), una base relacional («preferentemente PostgreSQL») y Firebase para la autenticación y los avisos
push. Las restricciones son un equipo de una persona, sin presupuesto y con la entrega en un cuatrimestre. Los requisitos que
lo exigen son RNF-01 (requisitos no funcionales) y los CU de sesión, reservas y avisos.

## Alternatives

### Alternative A — FastAPI, SQLAlchemy, Alembic y PostgreSQL; Flutter; Firebase Authentication y Cloud Messaging

| Axis | Answer |
|---|---|
| Meets the requirement | sí: la API publica `/openapi.json` y `/docs` (`apps/api/README.md`), la app es Flutter (`apps/mobile/pubspec.yaml`), la base es PostgreSQL y Firebase identifica y avisa. La restricción de no superposición de reservas se resuelve en la base con `btree_gist` (`apps/api/migrations/versions/0001_modelo_inicial.py:170-171`) |
| Deployment ease | un `render.yaml` describe la API y la base; el build instala con `uv` y migra con Alembic (`render.yaml:11`). Firebase es un servicio gestionado |
| Monthly infra cost | hoy USD 0 con los planes free de Render y Firebase Authentication; las alternativas pagas están en `docs/technical/infra-cost.md` |
| Cost to operate | parches de dependencias a mano (sin bot de actualizaciones, hallazgo 25); sin backups en la base free (hallazgo 4); Firebase no se opera |
| Corrective maintenance cost | el autor conoce el stack, se reproduce en local con Postgres y el emulador de Firebase Auth (`firebase.json`), y los tres tienen comunidad grande. Hay 384 tests de la API y 416 de la app que corren en local (revisión, «Qué corrió») |
| Lock-in and exit | los datos son Postgres estándar; la API es REST con OpenAPI. Salir de Firebase Authentication exige migrar las cuentas y las contraseñas (`usuario.firebase_uid` es la clave de unión) y reemplazar la verificación de tokens (`shared/identidad.py`) |

### Alternative B — Django REST Framework con la autenticación propia (usuarios y contraseñas en la base) y avisos push con otro servicio

| Axis | Answer |
|---|---|
| Meets the requirement | en parte: cumple Python, OpenAPI y PostgreSQL, pero el enunciado nombra a Firebase para la autenticación y las notificaciones push, y la identidad propia obliga a guardar contraseñas, recuperar cuentas y emitir tokens |
| Deployment ease | un solo servicio y una base, como A, sin depender de Firebase para la identidad |
| Monthly infra cost | el mismo servicio web y base de Render que A; el costo de otro servicio de push no se calculó (`not verified`) |
| Cost to operate | guardar, rotar y proteger los hashes de contraseñas, el envío de correos y el límite de intentos lo operaría el autor |
| Corrective maintenance cost | Django es el framework más conocido de Python y trae ORM y migraciones; el autor no lo evaluó con una prueba (`not verified`) |
| Lock-in and exit | menor que A para la identidad; no se midió el costo del resto |

## Decision and why

Se eligió la alternativa A. Decidieron el enunciado, que nombra Flutter, Python, PostgreSQL y Firebase, y el costo de operar
una identidad propia, que el autor evitó. Se acepta como costo el acople a Firebase para las cuentas, los tokens y los
avisos, y que el SDK acepta tokens sin firma si el entorno define `FIREBASE_AUTH_EMULATOR_HOST` (hallazgo 25). Se revisa si
Firebase deja de ser gratuito para el volumen del club o si el enunciado cambia de proveedor. Los números de infraestructura
están en `docs/technical/infra-cost.md`; el estado actual del sistema, en `docs/technical/system-design.md`.
