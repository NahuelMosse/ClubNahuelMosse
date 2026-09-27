# Cómo se trabaja en este repo

El **caso de uso es la especificación**. El QUÉ vive en el CU; el CÓMO, en el plan que genera
spec-kit; el comportamiento verificado, en los tests tagueados por card. No se genera una spec
paralela.

Los CU viven en `../CU/` y `../CU-nuevos/`, fuera del repo. Cada uno trae actor, flujo principal,
flujos alternativos y reglas de negocio: eso es la card. El enunciado del TP —
`../Trabajo Práctico_2026.docx.pdf` — manda por encima de cualquier CU.

## Lo primero, antes de tocar nada

> **Si estás leyendo esto, el método aplica. Leé `.claude/METODOLOGIA.md` entero antes de la
> primera herramienta.** Son nueve pasos y cada uno cierra con un comando; ahí está todo lo que
> este archivo no repite.

**No decidas primero si el método aplica.** Medido en la primera corrida: el agente supo que el
método existía, pudo nombrar sus pasos, y nunca abrió `METODOLOGIA.md` — *«decidí que el método
no aplicaba, por el directorio, antes de bajar al nivel de ¿reviso los pasos?»*. La decisión de
si esto «es una card» se toma por encima de la instrucción de leer, y una vez tomada en contra,
lo que diga el archivo ya no importa.

Así que: **que el directorio parezca vacío, que el pedido llegue pegado en el prompt en vez de
como CU, que no haya `specs/` todavía, o que no parezca «el proyecto del método», no son
motivos para saltearlo.** Este archivo cargado es la señal, y es la única que hace falta. Si
algo del método no se puede correr acá, eso se descubre leyéndolo y se declara — no se presume
antes.

| Cuándo | Qué leer |
|---|---|
| Cualquier card, antes de empezar | `.claude/METODOLOGIA.md` — los 9 pasos, sus validaciones y qué skill va en cada uno |
| No hay nadie mirando (corrida desatendida) | `.claude/AUTONOMIA.md` — qué garantiza y qué no, y qué hacer al llegar a un límite |
| Vas a escribir el snapshot | `.claude/plantillas/card.snapshot.md` |
| Tenés que elegir entre dos skills de revisión, o justificar por qué no corriste una | `.claude/skills/CUANDO.md` |
| Vas a vendorizar una skill o querés saber de dónde salió una | `.claude/skills/PROCEDENCIA.md` |
| Vas a escribir o correr tests, o un comando del método está en su forma web | `.claude/STACK.md` — rutas, comandos y equivalencias de Flutter y pytest |
| Tocaste `apps/mobile/lib/**` o `apps/api/app/**` | `.claude/rules/arquitectura.md`, y en la app también `interfaz.md` — **se cargan solas**, no las busques |

Nada más se carga solo. Este archivo, las descripciones de skills y agentes, y nada más.

## Lo que no depende de tu buena voluntad

`.claude/hooks/guardia.mjs` bloquea, con el motivo en pantalla: editar `card.snapshot.md`,
`Edit` sobre `ambiguedades.md` (es append-only), y editar un test tagueado que ya está
commiteado. Si te frena, no busques la vuelta: el mensaje dice qué hacer en su lugar.

## Los invariantes

Estos no tienen momento en el que algo te los recuerde. El resto está en `METODOLOGIA.md`.

1. **Nunca se codea sin leer el requerimiento entero en esta sesión.** Ni de memoria, ni de un
   resumen, ni del plan ya escrito.
   *Porque un resumen viejo no sabe qué decía el CU completo.*
   - **Hay CU escrito:** se lee el archivo entero, con sus flujos alternativos y sus reglas de
     negocio. Un CU al que sólo se le leyó el flujo principal no está leído.
   - **El requerimiento llegó como texto** —pegado en el prompt, un mail, un mensaje—: **ese
     texto es la fuente y se congela igual.** `fuentes:` dice de dónde salió y `no_leido:` lista
     lo que no se pudo consultar. El método sigue entero desde el paso 2.
     *No tener CU escrito no es no tener card.*

2. **Nunca resuelvas una ambigüedad por tu cuenta.** Se registra como `<ID>-AMB-NN` en
   `ambiguedades.md`, se pregunta al usuario, y si no hay respuesta se vuelve supuesto
   `<ID>-SUP-NN` en la interpretación más barata de deshacer, tagueado en el test que lo encoda.
   *Porque rellenar un hueco en silencio es la falla más grave de este repo.*

3. **Tres estados, no dos: pasó · falló · no se pudo correr.** Si un comando no existe, no se
   pudo correr, o no lo corriste — **no digas que pasó.** Decí cuál no corrió y por qué, y **no
   cierres la card.**
   *Porque decir que algo se verificó cuando no se sabe es la mentira que este método existe
   para evitar.*

4. **El snapshot nace `estado: propuesta`** y pasa a `firmado` sólo con revisión humana.

5. **No se publica el informe de cierre sin aprobación previa**, y ese informe sale sólo de la
   salida de las validaciones, nunca de la memoria de la sesión.
   *Porque es lo que se defiende en la entrega.*

6. **No pushees salvo pedido expreso.**

## Cómo trabajar

**Antes de decir «terminé», revisá de nuevo.** ¿Hiciste todo o sólo lo principal? ¿Quedó un TODO,
un caso sin cubrir, un test sin correr? ¿Funciona o lo asumiste? Si queda algo y lo podés
resolver, **resolvelo ahora** — no lo listes como pendiente. Repetí hasta que no quede nada.
*Porque nadie va a preguntarte si quedaron pendientes.*

**Antes de decir «bloqueado», autopreguntate:** ¿hay otra forma de conseguirlo? ¿puedo asumir y
registrarlo como `SUP-NN`? ¿qué parte **no** depende de esto? → hacela y terminala. Bloqueado con
trabajo que sí podías hacer no es un bloqueo, es una parada temprana.

**Las dudas van a la cola, no frenan el trabajo.** La cola es `ambiguedades.md`. Se asume lo más
razonable, se registra el supuesto, y se sigue con todo lo que no dependa de eso. Se frena sólo
cuando **todo** lo pendiente está bloqueado por la misma duda.

**El entregable muestra el resultado, no el proceso.** Vale para código, tests, plan e informe de
cierre. Afuera: notas que narran el cambio («antes X», «ahora Y», `fix:`, `NUEVO`, «actualizado»),
código viejo comentado por las dudas, archivos `_v2`/`_old`, secciones de cambios que nadie pidió,
rastros de la card en un comentario. Un comentario se gana el lugar sólo si explica algo que **no
se deduce leyendo el código** — una restricción externa, un bug de una dependencia, una decisión
contraintuitiva. El historial ya lo guarda git.
*La prueba: alguien abre esto en seis meses sin la card y sin saber que existió esta sesión.*

**Nada bloquea el turno.** Nada que pueda pasar de ~30 s va en foreground: tests, builds,
instalaciones, servidores. Van en background redirigidos a un log, y el log se lee con `Grep` o
se lo lee un subagente. **Nunca se vuelca un log entero al contexto.**

**Pero el turno no termina con una validación pendiente**, y **si no hay nadie mirando esta regla se invierte entera** (`.claude/AUTONOMIA.md`). Mandar al fondo sirve para seguir
trabajando mientras corre; **no sirve para cerrar.** Medido: una corrida terminó escribiendo *«las
validaciones 7 a 11 siguen corriendo en background, sigo cuando terminen»* — y no hubo un
«cuando terminen», porque el turno se había acabado. Si lo único que queda es esperar un
resultado, **esperalo**: el reporte se escribe con la salida, no con la promesa de la salida.

## Lo que cuesta una card, y de dónde sale

**Antes de leer nada de esto: no se optimiza sacando chequeos.** Lo que hace que este método
valga es que te dice **todo** lo que hay que tener en cuenta — el que codea no tiene que
acordarse de la accesibilidad, del origen de la petición, de la fecha que después no se
reconstruye. Sacar una fila de una tabla para ahorrar dos dólares destruye exactamente eso.

*Lo que se optimiza es cómo se ejecuta la lista, nunca qué tiene la lista.* Si una corrida sale
cara, la pregunta es **qué se está releyendo cuatrocientas veces**, no qué chequeo se puede
saltear.

**Medido sobre nueve corridas: el costo es casi lineal en peticiones, ~11 centavos cada una**, y
la mitad de eso es **releer el contexto** que se fue acumulando. Todo lo que entra al hilo
principal se vuelve a pagar en cada petición que sigue: una salida cruda leída en la petición 50
de 500 se paga **450 veces**.

De ahí salen tres cosas concretas, en orden de cuánto pesan:

- **Escribí el archivo entero, no lo edites diez veces.** Dos corridas del mismo kit con la misma
  nota: una hizo **115 `Edit`** y la otra **4 `Edit` y 53 `Write`**. La diferencia fueron 111
  peticiones y **$25**. Pensá el archivo completo antes de escribirlo; corregir en el editor es
  gratis, corregir acá cuesta una petición y queda en el contexto para siempre.
- **La salida larga no entra acá.** Tests, builds, instalaciones y logs van a `runner`, que
  devuelve el veredicto. Medido: las corridas usan `Agent` **cuatro veces en quinientas
  peticiones** y se comen la salida de setenta comandos. *Delegar no es una preferencia de estilo:
  es el único lugar donde la salida se lee una vez en vez de cuatrocientas.*
- **Agrupá lo independiente en una llamada.** Tres `grep` que no dependen entre sí son una
  petición, no tres.
- **Y la palanca más grande: los chequeos mecánicos no los corre el que decide.** Toda la lista
  de `/validar` que es comando —los `grep`, los conteos, los exit codes, los ataques contra la
  app levantada— la ejecuta `runner`, que devuelve el veredicto y los errores. **La lista se
  corre entera igual**; lo que cambia es que su salida se lee una vez en un contexto barato en
  vez de cuatrocientas en el caro. *Leer un log en Sonnet contra Opus es cinco veces menos por
  exactamente el mismo trabajo.*

*Cada petición que no gastás en releer es presupuesto para un chequeo más. Ésa es la única
dirección en la que se mueve esto: más cobertura por el mismo dinero, nunca menos cobertura por
menos dinero.*

**Lo que abrís, lo cerrás — y sólo lo que abriste vos.** Servidores, puertos, contenedores,
subagentes, shells de background: antes de cerrar la card no queda nada tuyo vivo sin
explicación.

**Matá por PID, nunca por nombre de proceso.** Guardá el pid de lo que levantás y bajá ese. Un
`taskkill /IM node.exe`, un `pkill node` o un `killall` se llevan puestos los procesos de otros
agentes, del editor y del usuario — y no hay forma de deshacerlo. Si no sabés el pid, buscalo por
el puerto que reservaste; si tampoco, dejalo vivo y decilo.
*Pasó: un agente de revisión liberó su puerto con `taskkill /F /IM node.exe /T` y tiró abajo un
servidor MCP de la sesión que lo había lanzado.*

**Herramientas dedicadas, no shell.** `Read`, `Grep`, `Glob` y `Edit` para leer, buscar y editar:
traen más por llamada y no vuelcan salida cruda. Bash y PowerShell son para **ejecutar procesos**.

**Delegá lo que ensucia el contexto, y al agente que corresponde.** El hilo principal decide y
revisa; no explora ni ejecuta.
*Porque una card larga se muere por contexto gastado en salidas que no había que leer enteras —
y porque lo que más se paga no es escribir, es releer.*

| Si la tarea es | Va a |
|---|---|
| Barrer archivos, «dónde está X», leer más de dos archivos, mapear cómo funciona algo | `scout` |
| Correr una lista de comandos y devolver exit codes, sin interpretar | `ejecutor` |
| Correr tests, builds, linters, type-checks, instalaciones, o leer cualquier log | `runner` |
| Traer un requerimiento de su fuente y congelarlo tal cual | `archivista` |
| Aplicar un cambio ya decidido en varios lugares — renombres, migrar una firma, un patrón repetido | `grunt` |
| Escribir el código de un plan que ya trae el mapa de archivos con sus decisiones de estructura | `implementador` |
| Decidir el orden y los riesgos de algo grande **antes** de que `/speckit-plan` escriba el plan | `planner` |
| Un problema difícil donde ya falló lo obvio: un bug que no cierra, un diff que no se entiende | `oracle` |

**Cada agente trae su modelo y su esfuerzo declarados, y ésa es media optimización.** El criterio
para elegir: **delegá al modelo más barato cuya salida puedas verificar sin rehacer el trabajo.**
Un exit code se verifica mirándolo; un juicio no. Por eso `ejecutor` y `archivista` corren en
haiku —devuelven números y transcripciones— y `oracle` corre en opus con esfuerzo `max`.

**Y lo que decide no se delega nunca**, por barato que sea: las diez preguntas del paso 2, qué
significa un test en rojo, y el veredicto de la pantalla se quedan acá.

*Medido: el guardia de `.claude/hooks/` **sí alcanza a los subagentes** — un `grunt` que intenta
editar un test congelado recibe el mismo bloqueo que el hilo principal, con el mismo mensaje y sin
tocar el archivo. No está documentado; se probó. Por eso delegar un paso que toca archivos
congelados no abre un agujero.*

**Nunca uses `general-purpose` para algo que cubre uno de los cinco.** Medido: una corrida delegó
cuatro tareas —*«chequeos mecánicos del paso 8»*, *«aplicar correcciones»*— al genérico, que
hereda **Opus**, teniendo `runner` y `grunt` definidos en **Sonnet** en ese mismo repo. Leer
contexto en Sonnet cuesta **$0,30 el millón contra $1,50**: cinco veces menos por exactamente el
mismo trabajo de leer un log o aplicar un cambio ya decidido. *El genérico no es el default: es
el último recurso.*

`planner` y `oracle` corren en Opus a propósito: no los llames para algo que resuelve `scout` o
`runner`, y si el problema es difícil de verdad no lo mandes a un sonnet para ahorrar dos
centavos. **El reporte del agente es el resultado** — no rehagas su trabajo para verificarlo; si
no confiás en lo que volvió, pedile más al mismo agente. Las subtareas independientes salen en
paralelo, en un solo mensaje.

**No se delega:** las decisiones de diseño, y nada que dependa de contexto que el agente no
tiene. Un `grep` de un símbolo que ya sabés dónde está no es una subtarea.
