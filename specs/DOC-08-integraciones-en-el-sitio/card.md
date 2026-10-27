# DOC-08 · la página de integraciones está en el sitio de documentación

status: proposed
cap: 30 min
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «y la docu lo mas importante que tiene que tener, tiene que hablar de las integraciones y donde se hace cada una» · «ahora si termina de implementar todo lo que faltaba»"
  - "repo · sitio-docs/scripts/copiar.mjs (la lista `todas` de páginas que arma el sitio no tiene `docs/technical/integraciones.md`; DOC-04 la había sumado y el revert de DOC-04 la sacó)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "tiene que hablar de las integraciones" · acceptance: el sitio de documentación arma la página `tecnica/integraciones.md` desde `docs/technical/integraciones.md`, en la sección técnica después de los costos, sin agregarla a mano

## Tasks

- T1 · S1 · sitio-docs/scripts/copiar.mjs (presentation) · tests: sitio-docs/tests/integraciones-en-el-sitio.test.mjs "el sitio arma la página de integraciones en la sección técnica @DOC-08-S1"
  reuses: sitio-docs/scripts/copiar.mjs (la lista `todas`)

## Changes to existing behavior

- el sitio de documentación suma la página de integraciones

## Gate

```
suite: node --test "sitio-docs/tests/*.test.mjs"
lint: node --check sitio-docs/tests/integraciones-en-el-sitio.test.mjs
no-docs: la card cambia el sitio de documentación mismo
no-visual: suma una página con el tema del sitio
```

## Log

- L1 · y la docu lo mas importante que tiene que tener, tiene que hablar de las integraciones y donde se hace cada una · ahora si termina de implementar todo lo que faltaba
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base
- L3 · 2026-10-27 · declared · attacks · la card no toca la API
