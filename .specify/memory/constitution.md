# ClubNahuelMosse Constitution

## Core Principles

### I. El caso de uso es la especificación
El QUÉ vive en el CU congelado en `specs/<ID>-<slug>/card.snapshot.md`. El enunciado del TP
(`../Trabajo Práctico_2026.docx.pdf`) manda sobre cualquier CU en comportamiento y reglas; el
prototipo de Figma `VUiZR6V4USuiyxRgtshhEn` manda en lo visual. Un plan que contradice el snapshot
se corrige antes de escribir código. Nunca se usa `/speckit-specify`.

### II. Nada se supone en silencio
Lo que la card no dice es una ambigüedad (`<ID>-AMB-NN` en `ambiguedades.md`, append-only). Si no
se resuelve, se vuelve supuesto `<ID>-SUP-NN` en la interpretación más barata de deshacer, y queda
cubierto por un test o declarado sin cobertura.

### III. Tests de escenario antes del código (NO NEGOCIABLE)
Cada escenario del snapshot es un test tagueado `@<ID>-H<NN>-<NN>`, escrito en rojo y commiteado
solo antes de implementar. Quien implementa no los edita. El test afirma sobre un dato que él
mismo creó.

### IV. El backend es la autoridad de las reglas de reserva
Horas completas, mínimo una hora, fin antes del cierre de la sede, horario futuro y no
superposición en el mismo espacio se validan en la API y los garantiza la base, no sólo la app.
Toda operación sobre usuarios y reservas identifica al usuario autenticado.

### V. Lo que después no se reconstruye se estampa ahora
Fecha de creación, autor de cada cambio del administrador y precio al momento de reservar se
guardan aunque todavía ninguna pantalla los muestre. Las bajas no borran el historial.

## Stack y restricciones

- App móvil en Flutter (`apps/mobile/`); API REST en Python con FastAPI y OpenAPI (`apps/api/`);
  PostgreSQL; Firebase para autenticación y notificaciones push; API y base desplegadas en la nube.
- Nombre de la app y del repositorio: `ClubNahuelMosse`.
- Cada proyecto tiene su README con configuración, ejecución y despliegue.
- Comandos y convenciones de tests: `.claude/STACK.md`.
- Sin secretos en el repositorio: `.env` fuera de git, `.env.example` versionado.

## Flujo de trabajo

Los nueve pasos de `.claude/METODOLOGIA.md`, card por card: snapshot, ambigüedades, supuestos,
escenarios en rojo, plan con `/speckit-plan` y `/speckit-tasks`, implementación, diff contra el
mapa de archivos, `/validar` y, si hay pantalla, capturas revisadas contra el prototipo. El informe
de cierre sale sólo de la salida de las validaciones y se aprueba antes de publicarse.

## Governance

Esta constitución y `.claude/METODOLOGIA.md` mandan sobre cualquier otra práctica. Un cambio a
cualquiera de las dos se hace en un commit propio con el motivo en el mensaje. Todo plan pasa el
Constitution Check contra los cinco principios.

**Version**: 1.0.0 | **Ratified**: 2026-09-27 | **Last Amended**: 2026-09-27
