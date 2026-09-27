# Metodología SDD — una página

**Regla única: el caso de uso es la especificación. Nada se supone en silencio; todo lo que se
supone se declara, se numera y se puede objetar.**

Cada paso cierra con un comando. La salida del comando es la evidencia; lo que vos digas no lo es.

**Dónde viven los archivos.** El paso 1 crea `specs/<ID>-<slug-corto>/` con el ID de la card —por
ejemplo `specs/GST-412-busqueda-clientes/`— y ahí escribe sus dos archivos. En el paso 5 se le
indica esa misma carpeta a `/speckit-plan`, que agrega `spec.md`, `plan.md` y `tasks.md`. Abajo se
la llama `<feature>/` en los dos casos. Si spec-kit igual crea la suya propia con numeración
(`001-`, `002-`), se mueven `card.snapshot.md` y `ambiguedades.md` a esa carpeta y se sigue ahí. La
card se identifica por el campo `card:` del frontmatter del snapshot, no por el nombre de la
carpeta.

**No se guarda estado en carpetas.** El estado de una card es su snapshot más el verde/rojo de la
suite. Nada de archivos de progreso, checklists marcadas a mano ni carpetas `en-curso/`:
un estado paralelo se desincroniza y después hay que decidir cuál de los dos tiene razón.

**Carpeta de tests E2E.** Se fija una sola vez, acá:
```
E2E="apps/mobile/integration_test apps/api/tests/escenarios"
```
Las validaciones que siguen usan `$E2E` en vez de las carpetas a mano. **Los comandos que este
archivo escribe en su forma web (`npm test`, `npx playwright`, `.spec.ts`) se corren con su
equivalente de `.claude/STACK.md`**, que es el que manda en este repo.

**Si no existe, se crea — no se frena.** En un proyecto que arranca de cero no existe ninguna de
las cosas que el método valida: ni carpeta de tests, ni suite, ni `npm test`, ni `specs/`. **La
primera card de un repo nuevo crea el andamio como parte de su trabajo**, y lo dice en el
comentario de cierre: qué había y qué hubo que montar.

Lo que **no** se puede es dar por verificado algo que no corrió porque el andamio no estaba: eso
es *no se pudo correr*, y no cierra. La diferencia entre montar lo que falta y saltear lo que
falta es la única que importa acá.

*Porque un método que sólo funciona sobre un repo que ya tiene todo no sirve para el caso en que
más falta hace: el producto nuevo, que es donde se toman las decisiones que después no se
deshacen.*

---

**1 · Traé la card entera y congelala.**
`/card <ID>` crea la carpeta `specs/<ID>-<slug-corto>/` —no existe todavía, la crea este paso— y
lee el CU entero —flujo principal, alternativos, excepciones y reglas de negocio, nunca de
memoria— y escribe ahí `card.snapshot.md` con dos listas: de dónde salió cada cosa (`fuentes:`) y
qué existe y no pudiste leer (`no_leido:`). Si la card cambia, se renombra el viejo con su fecha y
se escribe uno nuevo. Nunca se edita. Al commitear, `/card` registra el hash del commit en
`ambiguedades.md` como evento: `<ID>-AMB-00 · <fecha> · snapshot · congelado en <hash>`.

→ **Validá:** `git diff --name-only <commit-del-snapshot>..HEAD -- specs/<feature>/card.snapshot.md`
no puede listar nada. El commit sale del evento `AMB-00` en `ambiguedades.md`, no de la memoria de
la sesión. Si algo aparece, el snapshot se tocó después de congelarse: revertilo y re-extraé.

**2 · Lo que la card no dice es una ambigüedad, no una decisión tuya.**

**No alcanza con leer buscando.** Medido en la primera corrida del método: de cuatro huecos, tres
se resolvieron sin que el que decidía los percibiera como una decisión —*«lo escribí como
obvio»*, *«lo tecleé sin pausar»*, *«ni siquiera lo procesé como decisión»*—. Una instrucción de
notar no atrapa lo que no se presenta como elección. Por eso este paso es **una lista cerrada que
se contesta entera**, no una invitación a estar atento.

Recorré las diez, y escribí una línea por cada una aunque la respuesta sea que la card lo dice:

| | La pregunta que hay que contestar |
|---|---|
| Caso vacío | ¿Qué se ve cuando no hay ninguno? |
| Duplicados | ¿Qué pasa si ya existe uno igual? ¿Igual por qué campo? |
| Validación | ¿Qué se rechaza, con qué criterio, y con qué mensaje? |
| Error | ¿Qué pasa cuando la operación falla? |
| Estado | ¿Hay estados? ¿Qué transiciones son válidas? |
| Permisos | ¿Quién puede hacer esto y quién no? |
| Límites | ¿Exacto o parcial? ¿Sensible a mayúsculas? ¿Cuántos como máximo? |
| Orden | ¿En qué orden se muestran? |
| Concurrencia | ¿Qué pasa si dos lo hacen a la vez? |
| Rastro | ¿Qué hay que estampar ahora porque después no se reconstruye? |

**La de Rastro no es una más: es la única cuyo costo sube con el tiempo.** Las otras nueve se
contestan tarde y se arregla; ésta no. Medido: una corrida no guardó fecha de creación en ninguna
entidad, y ninguna de las nueve preguntas lo cubría. Un revisor técnico externo lo puso como *«lo
que más me preocupa a seis meses: hoy cuesta dos campos y en seis meses el dato no existe y no se
puede reconstruir»*. Cuándo se creó, quién lo cambió y cuándo — **se estampa aunque todavía no
haya pantalla que lo muestre.**

Cada fila da `la card lo dice: <cita>`, `la card no lo dice → <ID>-AMB-NN`, o `no aplica` con el
motivo. Las diez van en el bloque `## Las diez preguntas` que encabeza `ambiguedades.md`, antes
del log de eventos. **Una fila en blanco es el modo de falla de este paso**; `no aplica` escrito
no lo es.

En una épica, despachá dos lecturas independientes que no se vean entre sí y comparalas; en una
card chica, una sola lectura y declaralo. Divergencia de nombres u orden es ruido. Que las dos
lecturas coincidan **no** prueba que la card era clara: escribí "las dos lecturas coincidieron",
nunca "la card es clara".

Cada ambigüedad va a `specs/<feature>/ambiguedades.md`, una línea por evento, append-only:
`abierta → preguntada → resuelta | vencida`. Se le pregunta al usuario y se espera su respuesta.

**Si no hay a quién preguntar** —corrida desatendida, nadie del otro lado— **el ciclo se colapsa
en un evento**, no en tres:
```
<ID>-AMB-01 · <fecha> · sin canal · <la pregunta> → <ID>-SUP-01
```
Observado: con nueve ambigüedades y sin canal, el ciclo completo gastó veintisiete líneas para
registrar veintisiete veces un hecho que ya se sabía en la primera. **Un registro que se infla
deja de leerse**, y el valor de este archivo es que alguien lo lea en seis semanas.

**Y mientras implementás, cada vez que pienses «esto no lo hago por alcance», eso es un
`SUP-NN`.** En la misma corrida, el único hueco que el agente sí notó conscientemente —validar el
dígito verificador del CUIT, y decidir no hacerlo— tampoco quedó registrado en ninguna parte. El
momento de elegir no dejar algo es exactamente el momento de anotarlo.

→ **Validá que estén las diez contestadas:**
```
grep -cE "^\| *(Caso vacío|Duplicados|Validación|Error|Estado|Permisos|Límites|Orden|Concurrencia|Rastro) *\|.+[^ |]" specs/<feature>/ambiguedades.md
```
Tiene que dar **10**. Menos de 10 es una fila en blanco, y una fila en blanco es el hueco que se
va a resolver solo.

→ **Y que ninguna quede viva:** mirá el último evento de cada `AMB-NN`. No puede quedar ninguno
en `abierta`, ni en `preguntada` con el plazo vencido. Si queda, no cerrás.

**3 · Lo que vence sin respuesta se vuelve supuesto declarado.**
Va a `## Supuestos` del plan como `<ID>-SUP-NN`, siempre la interpretación **más barata de
deshacer**, y tagueado en el test que lo implementa: `@supuesto:<ID>-SUP-NN`.

**No todo supuesto tiene un test donde vivir, y forzarlo es peor.** Medido en la segunda corrida:
de nueve supuestos, seis —concurrencia, orden, permisos, manejo de error, ausencia de estados,
duplicados— no tenían ningún escenario que los ejercitara, **porque la card no los mencionaba,
que es exactamente por qué son supuestos**. Exigirles un tag obliga a inventar un test que
finge cubrir algo, o deja la validación imposible de pasar.

Cada `SUP-NN` va entonces a una de dos columnas, y las dos son declaración:

| | Cómo queda | Qué significa |
|---|---|---|
| **Cubierto** | `@supuesto:<ID>-SUP-NN` en el test que lo ejercita | se supuso y se verificó que el sistema hace eso |
| **Sin cubrir** | fila en `## Supuestos sin cobertura` del plan, con el motivo | se supuso y **nadie lo probó** |

→ **Validá:** por cada `SUP-NN` del plan, o bien `grep -r --include='*_test.dart' --include='test_*.py' "@supuesto:<ID>-SUP-NN" $E2E` devuelve
al menos una línea, o bien aparece en `## Supuestos sin cobertura`. **Un supuesto que no está en
ninguna de las dos está escondido**, y eso no cierra.
Si el plan no tiene `## Supuestos`, esta validación corre cero veces: **eso no es verde**, es que
falta la sección del paso 5.

**Los sin cobertura van al comentario de cierre, nombrados uno por uno.** Un supuesto que nadie
probó es *más* importante de contarle al cliente que uno que sí, no menos: es la lista de
decisiones que tomamos por él y que ni siquiera sabemos si funcionan.

**4 · Cada escenario de aceptación es un test, antes del código, en rojo, en su propio commit.**
`/escenarios <ID>` escribe un test por escenario, tagueado `@<ID>-H<NN>-<NN>`.

→ **Cómo se escribe un test de esta suite —archivo por pantalla, todo por interfaz, rol real,
selectores por nombre accesible, la grilla de diez categorías— está en el propio comando.** Se
carga al invocarlo: no hay nada que recordar acá.

→ **Validá, en las dos direcciones, siempre junto con el denominador:**
- Por cada ID del snapshot: `grep -rl --include='*_test.dart' --include='test_*.py' "@<ID>-H01-01" $E2E` devuelve al menos un archivo.
- Al revés: `grep -rhoE --include='*_test.dart' --include='test_*.py' "@[A-Z]+-[0-9]+[a-z]?(\.[0-9]+)?-H[0-9]+-[0-9]+" $E2E | sort -u` — todo tag que salga
  tiene que existir en `## Escenarios` del snapshot.
- `find $E2E -name '*_test.dart' -o -name 'test_*.py' | wc -l` — un grep en cero **no es verde si el denominador
  también es cero**: es «no se pudo verificar».

**Un escenario no es un caso, y el cierre reporta escenarios.** Un mismo escenario puede tener
tres casos —el mismo total verificado desde el tablero, el listado y la ficha— y eso está bien:
es la regla contestada igual en todas las pantallas. Lo que no está bien es contarlos como tres.
Medido: una corrida cerró diciendo *«los 11 escenarios de la card»* cuando eran **11 casos
tagueados sobre 9 escenarios distintos**. El número que va al cierre es el de tags únicos:
```
grep -rhoE --include='*_test.dart' --include='test_*.py' "@[A-Z]+-[0-9]+[a-z]?(\.[0-9]+)?-H[0-9]+-[0-9]+" $E2E | sort -u | wc -l
```
*Igual que contar capturas como tests, inflar escenarios con casos hace que el cierre mienta
hacia arriba — y el cierre es lo que se defiende en la entrega.*

→ **Dato centinela.** Cada test afirma sobre un valor que **ese mismo test creó**, no sobre un
fixture ni un dato preexistente. Si el escenario no lo admite, `@sin-centinela:<motivo>`.

**5 · El plan lo genera spec-kit, después de los escenarios.**
`/speckit-plan` con el snapshot y los escenarios ya escritos como entrada, indicándole la carpeta
que ya creó el paso 1 —no dejarlo crear una propia con numeración de spec-kit—, y después
`/speckit-tasks`. **Nunca `/speckit-specify`:** reescribe el requerimiento de negocio y borra el
registro de ambigüedades, que son las dos cosas sobre las que se apoya este método. La spec es la
card, ya está congelada en el paso 1.

→ **Validá:** el plan existe en `specs/<feature>/plan.md` y menciona los escenarios del snapshot.
Si el plan habla de algo que no está en `## Escenarios`, o ignora un escenario que sí está, se
corrige antes de escribir código.

→ **Completá a mano, en el mismo `plan.md`, las secciones que este método necesita y que spec-kit
no genera** —su plantilla trae `Summary`, `Technical Context`, `Constitution Check`,
`Project Structure` y `Complexity Tracking`, ninguna de éstas— y commiteá antes de escribir
código:
- `## Mapa de archivos` — las rutas que se van a tocar, **incluidos los archivos de test**, y por
  cada una **qué responsabilidad tiene y qué decisiones de estructura ya están tomadas**: dónde
  vive cada regla, qué capa conoce a cuál, qué se deriva de la enumeración y qué se escribe. *El
  mapa es lo que hace que implementar sea escribir y no decidir* — y si una decisión de estructura
  no está acá, aparece a mitad del código y ya nadie la revisa.
- `## Supuestos` — los `<ID>-SUP-NN` que vengan del paso 3, con su tag.
- `## Perímetro` — con qué auth, qué mocks y qué quedó afuera.
- `## Brief visual` — **sólo si la card toca una pantalla.** Qué tiene que poder hacer y leer el
  usuario en cada vista. **Cómo se escribe está en `.claude/rules/interfaz.md`, que se carga sola
  al tocar un archivo de pantalla.**

El mapa se escribe **antes** de implementar; si se escribe después, se escribe mirando el diff y
el paso 7 se confirma a sí mismo. El brief tiene el mismo problema y una razón más: **es el
insumo que vuelve posible el paso 9.** Medido —mismo modelo, mismas capturas, un sitio con cinco
defectos— sin brief detecta 1 de 5 y con brief 3 de 5. Revisar una pantalla sin brief es una
opinión; con brief es una comparación, que es el mismo movimiento que hace el paso 1 con la card.

Acá también aterrizan los supuestos visuales, y para ésos **«más barato de deshacer» significa
más contenido, no más convencional**: una zona, un componente, un set de tokens. Una ambigüedad
visual casi nunca se contesta —quien escribió la card no pensó la pantalla—, así que vence a
supuesto casi siempre; si además se desempata por lo que nadie va a objetar, el método produce
interfaz genérica por diseño.

→ **Si el plan trae una decisión de diseño** —un módulo o servicio nuevo, una integración
externa, un cambio de storage, una cola o un cache—, **invocá `clean-architecture` antes de
escribir código.** Es la única skill de revisión que sirve *antes*: te da el
mapa de capas y la dirección de dependencias, y trae un gate anti-sobreingeniería explícito.
Úsala para decidir, no para revisar. Si la card es un ABM, no la invoques: el gate te va a decir
que entregues un ABM y te vas a haber gastado la invocación.

**6 · El que implementa no toca los tests de escenario.**
Si un test está mal, lo decís y pedís que otro lo corrija. Los tests **sin** tag de card
(unitarios) sí son del implementador, ciclo completo.

**Y el que corrige vuelve a congelar.** El guardia bloquea a cualquiera que edite un test tagueado
ya commiteado — no distingue quién es, sólo que está congelado, que es lo que lo hace un mecanismo
y no una convención. Así que la corrección tiene su propio paso, y se hace explícito:

1. El implementador **no arregla**: reporta el defecto con el archivo, la línea y la corrección
   mínima que propone.
2. Quien corrige hace el cambio **con el guardia apagado a propósito para eso**, en un commit
   separado que toca sólo `$E2E`.
3. Ese commit **reemplaza al del paso 4**: su hash se registra en `ambiguedades.md` como
   `<ID>-TESTS · <fecha> · recongelados en <hash> · <motivo en una línea>`.
4. Desde ahí el diff del paso 6 se compara contra el hash nuevo.

*Sin esto, la regla 7 deja el trabajo trabado: el implementador no puede tocarlo, el corrector
tampoco, y la única salida es apagar el guardia sin dejar rastro — que es exactamente lo que el
guardia existe para impedir.* **Un test corregido después del congelamiento y sin evento es
indistinguible de uno que alguien bajó de vara.**

→ **Y si no hay nadie que apague el guardia, el hueco se declara.** Desatendido no hay corrector
humano, así que un test que falta **no se agrega**: se escribe en `## Supuestos sin cobertura`
del plan y se nombra en el cierre.

Medido, y es el caso que lo motivó: una corrida encontró un bug real —un monto vacío pasaba como
oportunidad de cero—, **lo arregló en el código y no pudo escribir su test** porque el archivo de
escenarios estaba congelado. Lo declaró como *«cobertura faltante, no algo que se verificó»* en
vez de saltear el guardia.

**Eso es lo correcto y tiene que quedar dicho, porque la alternativa es peor:** un agente que
frente a un bloqueo apaga el mecanismo es un agente que aprendió que los mecanismos se apagan.
*Un bug arreglado sin test y declarado vale más que uno arreglado con un test que nadie congeló.*

→ **Validá:** `git diff --name-only <commit-de-tests>..HEAD -- $E2E` tiene que salir vacío.
El hash sale del commit del paso 4, registrado en `ambiguedades.md` igual que el del snapshot —
no de la memoria de la sesión, o no lo puede reproducir nadie más.
Si sale algo, el implementador bajó la vara para pasar.

**7 · El diff hace lo que el plan dijo que iba a hacer, y nada más.**

→ **Validá, en las dos direcciones:** `git diff --name-only main...HEAD` contra las rutas de
`## Mapa de archivos` del plan. Si el plan no tiene esa sección, la validación **no pasa: se
frena** y se completa el plan — un mapa ausente no es un mapa vacío. Archivo en el diff que no
está en el plan → alcance no declarado. Archivo en el plan que no está en el diff → se planeó algo
que no se hizo. Cualquiera de los dos se explica o se corrige; ninguno se ignora.

→ **Si el cambio fue estructural** —módulo nuevo, dependencia nueva entre módulos, un servicio
que creció, responsabilidades que se movieron—, revisalo contra las cuatro reglas de
`.claude/rules/arquitectura.md`: controller que va directo al ORM, dominio que importa un SDK
externo, ciclo entre módulos, servicio con demasiadas responsabilidades. La regla se carga sola
al tocar los archivos que le corresponden y trae los `grep` concretos. Si el diff son tres
archivos de un CRUD, saltalo.

**8 · Todo verde, y recién ahí el cierre.**

→ **`/validar <ID>`** corre el paso entero y trae su propia doctrina: la suite y los tipos, las
revisiones built-in, las salidas de emergencia del diff, la accesibilidad afirmada por tests, el
repaso de seguridad probado contra la app levantada, la coherencia de una regla entre pantallas,
y el cambio de prueba con el test que lo reemplaza.

La doctrina entera está en el comando: qué se corre, qué se prueba contra la app levantada y
por qué. **No hay nada que recordar acá.**

Dos cosas sí, porque deciden si el paso existe:

- **`sh scripts/test.sh` tiene que correr todo lo que cuenta.** El comando por defecto es el que va a
  correr el que no leyó nada: si no corre lo que importa, la suite no existe para él.
- **Lo que falte para que esto esté impecable tiene dos destinos, y ninguno es una lista de
  pendientes:** se arregla en esta card, o se pregunta en la card como `<ID>-AMB-NN`. **Un techo
  sólo es techo si lo puso el negocio** — «es chico», «son datos sembrados» o «no da el tiempo»
  no son limitantes, son la decisión de no hacerlo. *Una lista de lo que no hicimos, mantenida
  card tras card, es un método que enseña a no hacerlo.*

→ **Antes de cerrar, mirá el diff contra la card:** **¿qué hay acá que no se pidió?**
`/cerrar <ID>` redacta el informe de cierre **únicamente** con lo que las validaciones dijeron.

**9 · Si la card tocó una pantalla, miralá. El paso 8 no la mira.**
Sólo si el diff toca UI. Si la card es de backend, saltalo y decilo.

Un test tagueado afirma sobre el DOM y el usuario lee píxeles. Medido sobre una pantalla con cinco
defectos reales: el chequeo de ancho atrapó **0**, axe **0**, un escenario tagueado **0**, y mirar
las capturas **5**.

→ **Producí el artefacto** — mecánico y binario:
```
cd apps/mobile && flutter test test/capturas --tags capturas --update-goldens   # 360 y 430 de ancho, claro y oscuro
```
**Y las capturas quedan fuera de la corrida por defecto.** No alcanza con ponerlas en otra
carpeta: `flutter test` sin argumentos corre todo `test/`. Se excluyen con el tag `capturas` en
`dart_test.yaml`. Medido: una
corrida reportó «41 de 41» y eran 29 tests más 12 capturas que no afirman nada. *El conteo del
cierre tiene que ser de casos que verifican algo — si no, el número miente hacia arriba.*
```
cd apps/mobile && flutter test integration_test   # lo que cuenta para el cierre
```
Existe la tira o no existe. Si el emulador o la API no levantan, es **no se pudo correr** y no
cierra.

→ **El veredicto lo da alguien mirando, y no se mecaniza.** Qué se mira, contra qué, y las tres
preguntas que hay que contestar —¿está obstruido? ¿se nota que lo generó un modelo? ¿quedó mejor
o sólo distinto?— están en `.claude/rules/interfaz.md`, que ya está cargada si tocaste la
pantalla.

→ La tira va adjunta al comentario de cierre, junto con quién la miró.

---

**Los tres estados. Lo más importante que queda del método.**
**Pasó · falló · no se pudo correr.** Si un comando no existe, no se pudo correr, o no lo
corriste — **no digas que pasó.** Decí exactamente cuál no corrió y por qué, y **no cierres la
card.** "No se pudo correr" no es "casi bien": es "no lo sé", y no cierra nunca.

**Válvula de escape, sólo con una persona presente.** Si un chequeo frena una card por un motivo
que nadie entiende en menos de un minuto, **se apaga y se dice que está apagado** — en el plan y
en el comentario de cierre. Nunca se lo deja bloqueando en silencio, y nunca se vuelve la razón
de tirar el resto del método.

**Desatendido la válvula no existe:** le daría al mismo actor que está bloqueado el poder de
apagar lo que lo bloquea, sin nadie que lo objete. En modo cron un chequeo que frena **frena la
card y la manda a revisión**. Ver `.claude/AUTONOMIA.md`.

**Un hallazgo sin corregir frena el cierre.** Vale para `/code-review`, `/simplify`,
`/design-review`, `/accessibility-audit` y `/design-deslop`: correr la revisión, escribir el
informe y cerrar igual es peor que no correrla — produce la evidencia de que algo estaba mal y
la archiva.

**Las skills de spec-kit que se usan, y las que no.** Están las diez instaladas; usarlas es
gratis sólo si se invocan las que hacen falta.

| Skill | |
|---|---|
| `/speckit-plan`, `/speckit-tasks` | el paso 5 |
| `/speckit-implement` | opcional, para ejecutar las tasks |
| `/speckit-analyze` | opcional, consistencia entre spec, plan y tasks |
| `/speckit-specify` | **prohibida** — reescribe el requerimiento (ver paso 5) |
| `/speckit-clarify` | **no se usa** — se solapa con el paso 2, que va contra la card real y no contra una spec generada |
| `/speckit-checklist`, `/speckit-converge`, `/speckit-constitution`, `/speckit-taskstoissues` | no las necesita este flujo |

**Si el proyecto usa `superpowers`** en vez de spec-kit: `writing-plans` reemplaza al paso 5, y
**su ciclo TDD completo va sólo a los tests sin tag de card** — los tagueados ya nacieron en rojo
en el paso 4.

**Reglas de arquitectura del proyecto:** `.claude/rules/arquitectura.md` — se carga sola cuando se
tocan los archivos que le corresponden.

**Qué skill va en qué momento:** `.claude/skills/CUANDO.md` — referencia, no hace falta
leerla para seguir el método: cada paso nombra la suya.
