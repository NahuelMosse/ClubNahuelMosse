---
description: Congela el requerimiento en un snapshot y lista las ambigüedades. Lee el CU entero si lo hay; si llegó como texto, congela ese texto.
argument-hint: <CU-ID>
---

Card: `$1`.

## 1 · Leer entero, nunca recordar

**Si `$1` es un caso de uso:** leé el archivo completo de `../CU/` o `../CU-nuevos/` — flujo
principal, **todos** los flujos alternativos y de excepción, precondiciones, postcondiciones y
reglas de negocio. Cruzá contra el enunciado del TP (`../Trabajo Práctico_2026.docx.pdf`), que
manda por encima del CU. Si el CU y el enunciado se contradicen, eso es una ambigüedad del paso 3,
no algo que se resuelve acá. Nada de memoria ni de resúmenes.

**Si el requerimiento llegó como texto** —pegado en el prompt, un mail, un mensaje— **ese texto
es la fuente y se congela igual.** No hay nada que traer y no se frena: `fuentes:` dice de dónde
salió, y `no_leido:` lista lo que no se pudo consultar porque no existe el canal.
El resto del comando sigue idéntico.

*No tener CU escrito no es no tener card. Frenar acá deja al método sin entrada.*

## 2 · Escribir el snapshot

Creá la carpeta `specs/$1-<slug-corto>/` —todavía no existe, la crea este paso— y escribí ahí
`card.snapshot.md`, con la plantilla `.claude/plantillas/card.snapshot.md`. En el paso 5 de la
metodología esta misma carpeta se le indica a `/speckit-plan`; si spec-kit igual crea la suya
propia, en ese momento se mueven los archivos de este método ahí.

- `fuentes:` no puede ir vacía. `no_leido:` puede ir vacía pero no puede faltar: lo que existe y
  no pudiste abrir se declara ahí.
- `estado: propuesta` — lo redactaste vos, no lo aprobó nadie.
- En `## Escenarios`, una línea por escenario: `- [ ] $1-H<NN>-<NN> — <título en el idioma de la
  card>`. Dos dígitos siempre: `H01`, no `H1`.
- Transcribí la card; no la interpretes. Lo que se resuelve, se resuelve en el plan.

Si ya existe un snapshot y la card cambió: renombralo a `card.snapshot.<fecha-vieja>.md`
y escribí uno nuevo. **Nunca lo edites.**

## 3 · Ambigüedades

**No releas "buscando": contestá las diez.** Medido, un hueco que no se contesta explícitamente
se resuelve solo y en silencio. `ambiguedades.md` arranca con este bloque, escrito de una, y
**ninguna fila queda sin respuesta** — ni siquiera las que la card sí contesta:

```
## Las diez preguntas
| Caso vacío    | la card no lo dice → $1-AMB-01
| Duplicados    | la card no lo dice → $1-AMB-02
| Validación    | la card dice: "el CUIT tiene que ser válido"
| Error         | la card no lo dice → $1-AMB-03
| Estado        | no aplica: el cliente no tiene estados
| Permisos      | la card dice: "sólo el analista da de alta"
| Límites       | la card no lo dice → $1-AMB-04
| Orden         | no aplica
| Concurrencia  | no aplica
| Rastro        | la card no lo dice → $1-AMB-05

## Eventos
```

`no aplica` es una respuesta válida y hay que escribirla; **una fila en blanco no lo es.**

Debajo de `## Eventos`, append-only, una línea por evento:

```
$1-AMB-01 · 2026-09-01 · abierta · ¿el CUIT se busca con guiones, sin guiones, o las dos?
$1-AMB-01 · 2026-09-02 · preguntada · comentario en la card, plazo acordado: 2026-09-05
```

No resuelvas ninguna por tu cuenta. Preguntá en la card **sólo con aprobación del usuario**.

## 4 · Cerrar el paso

Commiteá el snapshot solo, guardate el hash del commit y agregalo como evento en
`ambiguedades.md`:

```
$1-AMB-00 · 2026-09-01 · snapshot · congelado en <hash>
```

Verificá:

```
git diff --name-only <hash>..HEAD -- specs/$1-<slug-corto>/card.snapshot.md
```

No puede listar nada. Reportá: cuántos escenarios, cuántas ambigüedades abiertas, qué quedó en
`no_leido:`. Si algún comando no lo pudiste correr, decilo y no sigas.
