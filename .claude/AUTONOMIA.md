# Modo desatendido: qué garantiza el cron y qué no

El método se ejecuta sin nadie mirando. El requerimiento entra como caso de uso; todo lo demás lo
hace Claude. Este documento dice **cómo se consigue** y, sobre todo, **dónde deja de conseguirse** —
porque la falla que este método existe para evitar es exactamente decir que algo se verificó
cuando no se sabe.

## La regla que ordena todo

> **Se puede garantizar que algo se ejecutó. No se puede garantizar que su veredicto sea
> correcto.**

De las 21 validaciones del método, 6 se deciden con un exit code, 6 con parseo de la salida, y
**9 necesitan que alguien lea un informe y opine**. El cron mecaniza las 12 primeras por completo
y, en las 9 restantes, garantiza que el informe se produjo y que cualquier hallazgo frena la
card. Lo que no puede es saber si el informe tiene razón.

## La orquestación no vive en el modelo

**Un hook no puede obligar al modelo a invocar una skill.** Está documentado: los hooks sólo
inyectan texto que el modelo lee como recordatorio y puede ignorar. Tampoco existe un gate duro
de «no termina la sesión hasta que pasen los tests»: un `Stop` hook bloquea hasta 8 veces y
después el sistema lo pisa.

La consecuencia es la decisión central de este diseño: **cada paso es una invocación separada de
`claude -p`, y el encadenado lo hace el runner leyendo exit codes.** Nada depende de que el
modelo se acuerde del paso siguiente, porque el modelo no conoce el paso siguiente.

```
para cada card en la cola:
  claude -p "/card <ID>"          → falla: la card no se pudo leer      → cola de revisión
  claude -p "/escenarios <ID>"    → falla: los tests no quedan en rojo  → cola de revisión
  claude -p "/speckit-plan …"     → falla: no hay Mapa de archivos      → cola de revisión
  claude -p "implementá <ID>"
  claude -p "/cerrar <ID>"        → falla: cualquier validación en rojo → cola de revisión
```

Cada llamada usa `--output-format json` y devuelve un veredicto estructurado. **El paso siguiente
sólo arranca si el anterior salió 0.** Eso es determinista porque es un `if` de shell, no un
juicio del modelo.

## Lo que sí es determinista dentro de la sesión

`PreToolUse` con exit 2 **bloquea la herramienta**, y el modelo no puede sortearlo. Ahí va lo que
no puede depender de buena voluntad — `.claude/hooks/guardia.mjs`:

| Se bloquea | Por qué |
|---|---|
| Escribir `card.snapshot.md` | Editarlo pone en verde lo que estaba en rojo sin dejar rastro |
| `Edit` sobre `ambiguedades.md` | Es append-only: una línea escrita no se toca |
| Editar un test tagueado **ya commiteado** | Regla 7: el que implementa no baja la vara |

El tercero no usa un archivo de estado: pregunta a git. Un test tagueado que ya entró a un commit
está congelado; uno que todavía no, se está escribiendo. **El congelamiento del paso 4 ya era un
commit** — el guardia sólo lo hace cumplir.

El guardia **falla cerrado**: si no puede leer el archivo o consultar git, frena. Un guardia que
ante la duda deja pasar es una sugerencia.

## Desatendido, nada que el cierre necesite va al fondo

`CLAUDE.md` dice que nada bloquea el turno, y para una sesión con alguien mirando es correcto:
mandar la suite al fondo mantiene la conversación viva. **Acá esa regla se invierte.** No hay
turno que proteger — hay un proceso que termina, y lo que quedó corriendo se muere con él.

Medido, tres veces: la corrida mandó las validaciones al fondo, escribió *«sigo cuando
terminen»* y **no hubo un cuando terminen**. Una vez el trabajo se salvó porque estaba
commiteado; no hay ninguna garantía de que se salve siempre.

**La regla desatendida:** lo que el cierre necesita se espera **en primer plano**, o se despacha a
un subagente, que espera por vos y vuelve con la salida. Al fondo va lo que podés abandonar sin
que cambie el resultado — y si no podés nombrar qué es, no hay nada que mandar al fondo.

## Las tres cosas que ningún mecanismo resuelve

No son limitaciones de la herramienta. Son puntos donde el método pide un juicio que no existe si
no hay nadie.

**1 · La ambigüedad que nadie contesta.** El paso 2 pregunta en la card y espera. Sin nadie del
lado del negocio, *toda* ambigüedad vence y se vuelve supuesto. El registro sigue siendo honesto
—queda escrito qué se supuso y por qué— pero deja de ser un mecanismo de control: pasa a ser un
sello automático. **Cuantos más supuestos acumule una card, menos dice su verde.**

Observado en la primera corrida: nueve ambigüedades, cero canal, nueve supuestos. Sin canal el
ciclo se colapsa en un evento `sin canal` por ambigüedad —no tres— y **el conteo de supuestos
vivos encabeza el comentario de cierre.** Nueve supuestos sobre una card de tres campos no es
un detalle al pie: es el titular.

**2 · El snapshot que nadie firma.** `estado: propuesta` pasa a `firmado` sólo con revisión
humana. Desatendido, toda card cierra en `propuesta`, y eso debe salir en el comentario.

**3 · La pantalla que nadie mira.** Medido: un modelo con el brief detecta 3 de 5 defectos reales
de teléfono; una persona, 5. Los dos que se escapan son juicio tipográfico y jerarquías anidadas.
El cron produce la tira de capturas y su lectura del modelo; **el 2 de 5 que falta no lo cubre
nadie.**

## Qué hace el cron cuando llega a un límite

**No cierra la card y no miente.** La mueve a revisión con el detalle exacto de qué no se pudo
verificar y por qué. Es la regla de los tres estados aplicada al operador ausente: *no se pudo
correr* y *nadie lo aprobó* son el mismo estado —«no lo sé»— y ninguno cierra.

El comentario de cierre lista siempre, aunque todo esté verde:

- los `SUP-NN` vivos, y **cuántos vencieron sin respuesta** en vez de resolverse;
- que el snapshot sigue en `propuesta`;
- que el veredicto visual lo dio un modelo y no una persona;
- cualquier hallazgo de `/code-review`, `/simplify`, `/design-review`, `/accessibility-audit` o
  `/design-deslop` que no se haya corregido.

**Un hallazgo sin corregir frena el cierre.** Con una persona esto se resolvía solo, porque la
persona leía el informe y actuaba. Un cron que corre la revisión, escribe el informe y cierra
igual es peor que no correrla: produce la evidencia de que algo estaba mal y la archiva.

## La válvula de escape no aplica acá

Con una persona, apagar un chequeo que nadie entiende en un minuto es sensato. Desatendido, le da
**al mismo actor que está bloqueado el poder de desactivar lo que lo bloquea**, sin nadie que lo
objete. En modo cron un chequeo que frena no se apaga: **frena la card y va a revisión.**
