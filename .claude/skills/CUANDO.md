# Qué skill va en qué momento

Referencia. No hace falta leerla para seguir el método: cada paso de `METODOLOGIA.md` nombra
la suya. Esto sirve cuando hay que decidir entre dos, o justificar por qué no se corrió una.

No son alternativas: son **momentos distintos**. Correrlas juntas sobre el mismo cambio produce
cuatro informes que dicen lo mismo y nadie lee ninguno.

| Skill | Cuándo | Qué mira | Costo |
|---|---|---|---|
| `clean-architecture` | **Antes de codear**, en el paso 5, si hay decisión de diseño | una propuesta en lenguaje natural, no código | bajo |
| `interface-design` | **Antes de la pantalla**, en el paso 5, al escribir el `## Brief visual` | dominio del producto, foco, firma visual, tokens, estados | bajo |
| `.claude/rules/arquitectura.md` | **Antes de mergear**, en el paso 7 — no se invoca, se carga sola | las cuatro reglas del stack, con sus `grep` | gratis hasta tocar `apps/**` |
| `/design-review` | **Paso 8, si el diff toca UI** | el código del componente: tokens, consistencia, patrones genéricos, breakpoints declarados | bajo |
| `/accessibility-audit` | **Paso 8, si el diff toca UI** | el código: semántica, foco, teclado, ARIA, contraste declarado | bajo |
| `/architecture-review` | **Fuera del ciclo de una card** | el repo entero, 5 fases, SOLID una por una + escalabilidad a 10× | **alto** |
| `/beyond-solid-principles` | **Bajo demanda**, ante un smell puntual | lo que le indiques, por principio | medio/alto |

**Las de UI leen código, no pantalla.** Ninguna abre un navegador ni saca una captura, así que
**ninguna sustituye al paso 9**: revisan lo que se decide escribiendo el componente —un contraste
declarado en un token, un `aria-label` que falta, doce tarjetas idénticas—, no lo que aparece
recién cuando el navegador compone la página. Los cinco defectos que motivaron el paso 9 están
todos en la segunda categoría.

**El reparto de las de UI, que es fácil de confundir.** Cuatro momentos y tres objetos distintos:

| | Cuándo | Sobre qué | Qué pregunta |
|---|---|---|---|
| `interface-design` | paso 5, al escribir el brief | ninguno todavía — decide | ¿cuál es el foco y la firma de esta pantalla? |
| `/design-review` · `/accessibility-audit` | paso 8 | el **código** del componente | ¿es coherente con sus propios tokens? |
| `/design-deslop` | paso 9, con las capturas | el **render**, y recién después el diff | ¿se nota que lo generó un modelo? |
| **una persona** | paso 9, antes de cerrar | la tira contra lo anterior | **¿quedó mejor, o sólo distinto?** |

**La última fila no la cubre ninguna skill, y es la que más falta hizo.** Las tres juzgan un
build contra una barra; ninguna compara contra la versión anterior. Medido: una pantalla salió
más distintiva y peor con las tres revisiones en verde.

Correr las de revisión sin haber escrito el brief es pedirle a un revisor que adivine contra qué
comparar: lo único que puede marcar es incoherencia interna, no si la pantalla quedó genérica.

`/design-deslop` viene de `Dammyjay93/interface-design` —MIT, mismo upstream que la skill— y su
texto referencia un `/interface-design:design-review` que **en este repo no existe**: el
`/design-review` de acá es el de `claude-code-kit`, homónimo y distinto. El archivo se deja tal
cual vino para poder actualizarlo.

**Las dos de abajo no van en el ciclo de una card.** `/architecture-review` barre el repo entero y
produce un informe largo: sirve para onboarding, para una auditoría antes de una release, o para
planificar un refactor grande. Correrla por card es pagar una auditoría de repo para revisar
quince archivos.

**`/beyond-solid-principles` es la única que mira lo que no son capas** — DRY, Ley de Demeter,
KISS, YAGNI, resiliencia (timeouts, retries, circuit breakers), evolvability. Invocala por
principio (`sw-dry`, `sw-demeter`, `sw-coupling`) cuando sospeches algo puntual; pedirle los diez
cuesta como una auditoría completa.

**Y las dos built-in, que sí van siempre**, en el paso 8: `/simplify` limpia y `/code-review`
busca bugs. Hacen cosas distintas sobre el mismo diff.
