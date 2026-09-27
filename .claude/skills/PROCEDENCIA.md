# De dónde salió cada skill y bajo qué licencia

Este repo es una plantilla: lo que está acá se copia a proyectos de clientes. Una skill sin
origen verificable no se puede actualizar, y una sin licencia no se puede distribuir.

**Todo lo vendorizado es MIT, verificado en el `LICENSE` del upstream —no en el README ni en el
frontmatter—** el 21/09/2026.

| Skill | Upstream | Licencia | Cómo entró |
|---|---|---|---|
| `interface-design` | `Dammyjay93/interface-design` | MIT | `npx skills add` → `skills-lock.json` con hash |
| `clean-architecture` | `tokenaissance/clean-architecture` | MIT (trae `LICENSE`) | `npx skills add` → `skills-lock.json` con hash |
| `architecture-review` | `tansuasici/claude-code-kit` | MIT, Tansu Asici | copia manual |
| `design-review` | `tansuasici/claude-code-kit` | MIT, Tansu Asici | copia manual |
| `accessibility-audit` | `tansuasici/claude-code-kit` | MIT, Tansu Asici | copia manual |
| `beyond-solid-principles` | `florianbuetow` (marketplace) | MIT | copia manual |
| `speckit-*` (10) | `github/spec-kit` | MIT, GitHub Inc. | `specify init` |

| Comando | Upstream | Licencia |
|---|---|---|
| `.claude/commands/design-deslop.md` | `Dammyjay93/interface-design` | MIT |

`card.md`, `escenarios.md`, `validar.md` y `cerrar.md` son propios.

`/code-review` y `/simplify` **vienen con Claude Code**: no están en este kit y no hay que
buscarlos acá.

## Dos homónimos que no son la misma cosa

**`design-review`.** El de acá es el de `claude-code-kit`. Existe otro con el mismo nombre en
`Dammyjay93/interface-design`, que es el que invoca el texto de `design-deslop`. Distintos
artefactos, distinto contenido.

**`interface-design`.** Es el nombre de la skill *y* el de una skill homónima dentro de
`claude-code-kit`. La instalada es la de `Dammyjay93`.

## La regla

**Antes de vendorizar: licencia verificada en el archivo del upstream, y una forma de volver a
bajarlo.** Preferir `npx skills add`, que deja la entrada en `skills-lock.json` con hash; si se
copia a mano, la fila va acá.

No alcanza con que el frontmatter declare una licencia: se vio un caso apuntando a un
`LICENSE.txt` que no existía en ningún lado. **Se verifica el archivo, no la promesa.**

`skills-lock.json` sólo cubre lo instalado con la herramienta —hoy 2 de 16—, así que **este
documento es el registro, no el lockfile.**
