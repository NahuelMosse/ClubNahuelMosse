---
description: Corre las revisiones del paso 8 sobre lo implementado — suite, tipos, seguridad, accesibilidad, coherencia y costo del próximo cambio.
argument-hint: <CARD-ID>
---

Card: `$1`. Esto es el paso 8 entero. Cuando esté todo verde, el cierre lo redacta `/cerrar $1`.

**En este repo el stack es Flutter y FastAPI.** Los comandos de abajo ya están traducidos; las
equivalencias de lo que se nombra en web (`axe`, selectores, anchos) están en `.claude/STACK.md`.

**Tres estados, no dos: pasó · falló · no se pudo correr.** Un comando que no existe no pasó.

## Primero: esto no lo corrés vos

**Despachá las secciones 1, 3 y 5 a `runner`, y la 4 a otro `runner`, en un solo mensaje.** Son
comandos y ataques: producen la salida más larga de toda la card y no necesitan tu criterio para
ejecutarse. Cada uno vuelve con **el veredicto, los exit codes y sólo los errores** — la salida
cruda se lee una vez, en un contexto barato, en vez de cuatrocientas veces en el tuyo.

Las secciones 2, 6, 7 y 8 sí son tuyas: piden decidir, no ejecutar.

*Medido, y es el motivo de que esto esté acá arriba y no como consejo: nueve corridas gastaron la
mitad de su plata releyendo el contexto acumulado, y usaron subagentes cuatro veces en quinientas
peticiones. La lista se corre entera igual — lo único que cambia es dónde se lee.*

**Lo que no se delega es la decisión.** Si un `runner` vuelve con un fallo, qué significa y qué se
hace lo resolvés vos: él ejecuta y reporta, no interpreta.

## 1 · La suite, y que corra todo lo que cuenta

```
sh scripts/test.sh                                                  # todo lo que cuenta
cd apps/mobile && flutter analyze && dart format --set-exit-if-changed lib test integration_test
cd apps/api && ruff check . && mypy --strict app
cd apps/mobile && flutter test integration_test --name "@$1-"       # los escenarios de esta card
cd apps/api && pytest tests/escenarios --card $1
cd apps/mobile && flutter test integration_test                     # la suite entera: acá aparecen las regresiones
cd apps/api && pytest tests/escenarios
```

**`sh scripts/test.sh` tiene que correr todo lo que cuenta.** Medido: una corrida dejó `npm test` corriendo
sólo los unitarios y los e2e —**el grueso de la cobertura**— detrás de otro comando. Quien clone
el repo y corra lo obvio ve verde sin haber ejercitado nada de la pantalla. *El comando por
defecto es el que va a correr el que no leyó nada: si no corre lo que importa, la suite no existe
para él.*

La última no es redundante. Filtrando por `@$1` sólo se corre lo que esta card agregó: si esta
card rompió el escenario de una card vieja, el filtro lo **excluye**.

**Y llega un punto en que la suite entera deja de caber por card.** Medido en un repo real: 336
tests tardan 37 minutos, y a 800 serían casi dos horas — con `retries: 0` y la máquina
compartida, eso no es una corrida lenta, son **corridas enteras que se pierden**. La salida no es
bajar la vara ni permitir reintentos: es partir la suite por costo, un camino feliz por área como
gate de cada card (un archivo por área bajo `integration_test/gate/`) y el barrido completo antes
de mergear (`flutter test integration_test`).
*Lo que no se puede es correr la mitad y reportar como si se hubiera corrido todo.*

### Un test que falla después de implementar: por qué falla decide de quién es

En el paso 4 un test puede fallar porque el botón todavía no existe. **Acá ya no.** Con el código
escrito, la forma de la falla dice qué pasó, y son cosas distintas:

| Falla con | Qué significa |
|---|---|
| `Expected: … Actual: …` — recibido contra esperado | el producto no hace lo que el escenario pide. **Es tuyo: arreglá el código** |
| `could not find any matching widgets`, `Too many elements` | el selector no encuentra nada o encuentra de más. **Es del test, o al producto le falta semántica** |

```
cd apps/mobile && flutter test integration_test --name "@$1-" 2>&1 | grep -cE "could not find any matching widgets|Too many elements"
```

Tiene que dar **0**. Si no da cero, decidí cuál de las dos es —*¿el elemento existe y el selector
está mal, o el elemento no tiene nombre accesible y por eso no se lo puede nombrar?*— y si es lo
segundo, **el arreglo va en el producto**, que es donde faltaba la semántica.

Si el selector está mal, **vos no lo tocás**: el test está congelado. Reportalo con el archivo, la
línea y la corrección mínima, y seguí el protocolo de recongelamiento del paso 6.

*Medido: una corrida dejó seis escenarios en rojo con un selector por rol ARIA que **nunca lleva
nombre accesible**, así que no encontraba nada haga lo que haga la app. El equivalente acá es
buscar por etiqueta semántica un widget que no la expone. El test estaba mal desde el paso 4 y pasó el «tiene que fallar» de ese
paso porque en ese momento fallar era lo correcto.* **Un selector imposible se ve igual que una
funcionalidad que falta, hasta que la funcionalidad está.**

## 2 · Las revisiones built-in, en este orden

`/simplify` (limpieza: reuso, simplificación, eficiencia — **no busca bugs**) y después
`/code-review` (bugs sobre el diff). Trabajan sobre lo mismo desde ángulos distintos; correr sólo
uno deja la mitad sin mirar.

Si el diff toca UI, sumá `design-review` y `accessibility-audit`. **Las dos leen código, no
pantalla:** sirven para lo que se decide escribiendo el componente, y **no reemplazan el paso 9**,
que existe justamente porque lo que rompe una pantalla no está en el código.

## 3 · Las salidas de emergencia del diff

```
grep -nE "[)\]]!|\bas dynamic\b|// *ignore(_for_file)?:|catch *\([^)]*\) *\{ *\}" \
  $(git diff --name-only main...HEAD -- '*.dart')
grep -nE "# *type: *ignore|# *noqa|except[^:]*: *pass|\bcast\(" \
  $(git diff --name-only main...HEAD -- '*.py')
```

Cada una se saca o lleva una línea diciendo por qué. Son lugares donde alguien le dijo al
compilador que se callara. A veces tiene razón, pero **un `!` es una promesa de que nunca es nulo
que nadie verificó**. Medido: una corrida resolvía la etapa con `.find(…)!` en dos lugares; el día
que llegue una etapa que no está en la tabla eso no es un error con mensaje, es un `undefined` que
viaja tres funciones y explota lejos. *El caso que el `!` tapa es exactamente el que la
enumeración va a tener cuando crezca.*

**Un tipo de resultado no carga valor cuando falla.** Si el fallo puede traer un valor —un
`Resultado` con `ok: false` y además un `valor` de relleno, un objeto con `error` y `datos` a la
vez— entonces existe un camino donde alguien lee el relleno y sigue como si nada. Medido: una
validación devolvía `tipo: tipo ?? 'llamada'` junto con el error, así que el valor por defecto
viajaba aunque la validación hubiera fallado. *No alcanza con no leerlo: el tipo tiene que hacer
imposible leerlo.*

**Una herramienta instalada que nadie corre es peor que no tenerla**, porque el repo aparenta un
control que no existe. Medido: `typescript` estaba en `devDependencies`, con su `tsconfig` y con
JSDoc escrito en todo el código — y `npm test` nunca lo ejecutaba. Acá, cada herramienta de
desarrollo de la app y de la API tiene que aparecer en `scripts/test.sh` o en
`analysis_options.yaml`:
```
for d in ruff mypy pytest flutter_lints; do grep -q "$d" scripts/test.sh apps/mobile/analysis_options.yaml 2>/dev/null || echo "nadie corre: $d"; done
```

**Y un default no puede tapar una clave que falta.** `TABLA[clave] ?? [0, 0]` convierte «me olvidé
una etapa» en un cero que se propaga sin ruido. Cuando el índice es un miembro de una enumeración
cerrada, la búsqueda **tira**; el `??` se reserva para lo que de verdad puede no estar.

**Y el peso muerto se cuenta.** Una exportación que nadie importa es código que se mantiene sin que
nadie lo use, y es el residuo típico de un refactor: se movió la regla a otro lado y la vieja
quedó.
```
for f in $(git ls-files 'apps/*.py' 'apps/*.dart' | grep -vE '(^|/)tests?/|_test\.dart$|integration_test/'); do
  grep -ohE '^(async )?def [A-Za-z_][A-Za-z0-9_]*|^class [A-Za-z_][A-Za-z0-9_]*' "$f" | awk '{print $NF}' |
  while read n; do [ "$(git grep -wl "$n" | wc -l)" -le 1 ] && echo "nadie usa: $n ($f)"; done
done
```
Tiene que dar vacío. Medido: tres corridas del método, **cero sobre 276 exportaciones**; el único
entregable con código muerto fue el que revisó una persona, que dejó `ETAPAS_CERRADAS` y
`COLOR_ETAPA` colgados al juntar las etapas en un solo lugar.

*Lo que no cuenta como peso muerto:* la validación del borde, el manejo de errores y los tests.
Son comportamiento, y el método los exige. **Menos líneas no es la meta; menos líneas que no
hacen nada, sí.*

## 4 · La accesibilidad se afirma con tests, no se revisa

Una revisión deja ocho decisiones correctas que el próximo que toque la vista puede deshacer sin
que nada falle. Tres tests, uno por clase de problema:

| | |
|---|---|
| Guías de Flutter por pantalla | `meetsGuideline(androidTapTargetGuideline)`, `labeledTapTargetGuideline` y `textContrastGuideline` en cada pantalla. Si alguna se deja afuera, **se lista con su motivo** — un filtro sin lista es una suite que pasa por lo que no mira |
| Recorrido con lector de pantalla | el orden semántico llega al contenido y al primer control en el orden en que se lee la pantalla |
| Obligatoriedad anunciada | cada campo requerido lo dice en su etiqueta y en su `Semantics`, **y hay un test propio que lo afirma**: las guías no lo marcan, así que ésta se escapa entera de la pasada automática |
| Contraste calculado | lee los pares tinta/lienzo del tema, en modo claro **y** oscuro, y afirma ≥ 4,5:1. **Se escribe a mano, sin dependencia** — son quince líneas |
| Texto agrandado del sistema | con `textScaler` en 2.0 ningún texto se corta ni se superpone y todo sigue alcanzable |

Medido: una corrida tenía skip link, `:focus-visible`, `aria-invalid` cableado a
`aria-describedby`, targets de 44 px y `prefers-reduced-motion` —todo bien decidido— y **una sola
aserción de accesibilidad en toda la suite**. *Las decisiones correctas que nadie afirma duran
hasta el próximo apuro.*

**Lo que no se mecaniza:** `axe` cubre cerca de un tercio de WCAG. No detecta un nombre accesible
que es correcto pero incomprensible, ni un orden de lectura que confunde, ni si el tablero se
entiende navegándolo de a saltos. Eso es el paso 9 y **necesita a una persona con un lector de
pantalla** — que no es un techo del producto, es el mismo paso 9 que ya pide que alguien mire.

## 5 · El repaso de seguridad, probado contra la app levantada

Ocho filas, se contestan todas, igual que las diez preguntas del paso 2 — y por el mismo motivo:
*lo que se deja a que alguien se acuerde sale distinto cada vez.*

| | Qué se prueba, no qué se lee |
|---|---|
| Inyección | Mandá `<script>` y `"><img onerror>` por **cada campo que se guarda y se vuelve a mostrar**, y mirá el HTML servido. Incluí `<title>`, atributos y `data-`, no sólo el cuerpo |
| El borde | Tipo y rango equivocados, campo desconocido, JSON roto, string vacío donde va un número, y **un cuerpo enorme**: tiene que volver un código, no morirse la conexión |
| Rutas | Si algo de la URL toca el disco, pedí `../` y variantes codificadas. La defensa es lista blanca, no filtro de `..` |
| Acceso | Si no hay auth, es un `SUP-NN` escrito, en el comentario de cierre **y donde lo ve el que arranca la app**. Si la hay, pedí el recurso de otro cambiando el id |
| Fuga | Provocá un 500 y leé lo que llega al cliente: ni stack, ni ruta, ni mensaje del motor. Y mirá qué campos de más trae cada respuesta |
| Cabeceras | Respuestas con datos `no-store`; tipo de contenido declarado; CSP si hay HTML; `Permissions-Policy` |
| Aguante del socket | `requestTimeout` y `headersTimeout` fijados **y probados**: un cliente que manda las cabeceras de a un byte tiene que ver cortada la conexión. Medido: una corrida declaraba `headersTimeout` de 10 s y la conexión seguía abierta a los 25 — *un timeout escrito no es un timeout que funciona*. Y un `Content-Length` mentido de 500 MB se rechaza **por lo que declara**, antes de leer un byte: dos corridas lo dejaban colgado veinte segundos esperando datos que nunca iban a llegar. Y **validá el `Host`** — con `nc`, un `Host: evil.example` que devuelve 200 es la puerta del DNS rebinding |
| Petición de otro sitio | Un `POST` desde un origen ajeno tiene que dar 403, **y uno sin `Origin` ni `Sec-Fetch-Site` también**. Si la defensa es un token, **mandá el mismo dos veces, y después tres a la vez**: el primero encuentra un token que se emite y nunca se marca usado; el segundo, uno que se consulta antes de un `await` y se marca después. Medido: una defensa pasaba el envío repetido con un 409 y **tres envíos simultáneos crearon tres registros**. *Consultar y marcar separados por una espera es una carrera, aunque cada mitad esté bien escrita.* Medido: una defensa que leía esas cabeceras dejaba pasar a cualquier cliente que no las mandara — *la ausencia de una cabecera no prueba que la petición sea propia*. Un HMAC en el formulario cierra eso sin sumar dependencias |
| Dependencias | Qué se instaló, de quién, y si hacía falta |

**Y un test tuyo por cada cosa que rompiste**, porque un arreglo sin test vuelve en la card que
viene. Medido, tres de éstos aparecieron en corridas reales y **ninguno lo veía un test**: un
`<title>` interpolado sin escapar —XSS almacenado desde un alta—, un cuerpo de 1 MB que devolvía
`ECONNRESET` en vez de un 413, y una API servida cacheable, que detrás de un proxy compartido le
entrega a uno la respuesta de otro.

**Un supuesto de seguridad que vive sólo en `specs/` no protege a nadie.** El que clona el repo y
corre `npm start` no lee la carpeta de la card. Los que tienen consecuencia —no hay
autenticación, los datos no se cifran, el archivo queda legible— van también al README **y a lo
que la app imprime al arrancar**; y si el riesgo depende de cómo se levante, el arranque **falla
hasta que alguien elija**, en vez de tomar el default peligroso. Medido, los dos lados: una app
escuchaba en loopback y exigía el puerto por entorno, y la otra caía a `0.0.0.0:3000` sola — un
CRM con datos de clientes publicado en toda la red al primer `npm start`. *El mismo hueco
declarado, contenido en un caso y amplificado en el otro.*

## 6 · Lo que los tests no prueban aunque estén verdes

**Un test que valida con la misma función que generó el dato no valida nada.** Medido: la semilla
fabricaba CUIT con un dígito verificador mal calculado y el test los daba por buenos porque usaba
esa misma función — el mismo repo tenía la versión correcta en otro archivo. Cuando lo que se
prueba es una regla de un tercero —un dígito verificador, un checksum, un formato de norma—, el
test afirma contra **valores conocidos escritos a mano**, no contra el generador.

**El corte fino, que parece una contradicción con lo de arriba y no lo es:**

> **Derivá lo que recorrés; nunca derives contra qué afirmás.**

El bucle sale de la enumeración —`for (const e of ETAPAS)`— para que el miembro nuevo entre solo.
**Lo que afirmás adentro sale de otro lado**: de un valor escrito a mano, de una cuenta hecha en
el test, de una implementación independiente. Medido, los dos lados del mismo error: una corrida
validó los CUIT sembrados con la misma función que los generó —derivó contra qué afirmaba, y tapó
un bug real— y otra escribió las seis etapas a mano en el bucle del test de semilla, así que al
agregar la séptima **perdió cobertura en silencio y siguió en verde**.

El chequeo: **el test de la semilla no importa los módulos de reglas que la semilla usa para
calcular.** Si los importa, está comprobando que una función coincide consigo misma.
```
comm -12 <(grep -ohE "from '[^']+'" <semilla> | sort -u) <(grep -ohE "from '[^']+'" <test-de-semilla> | sort -u)
```
Lo que salga en común es una tautología o está por serlo. *Medido con dos corridas del mismo kit:
de nueve mecanismos, los ocho que tenían comando salieron iguales en las dos; **el único que era
sólo una frase salió en una y no en la otra.***

**Cada regla de negocio tiene un test que no levanta navegador.** Los tagueados del paso 4 prueban
el escenario; el unitario prueba la regla, y son cosas distintas: el escenario dice «el tablero no
muestra las cerradas», el unitario dice qué contesta la función con cada etapa, con el borde y con
el caso vacío. Medido: una corrida entregó **24 casos e2e y ni un unitario** — el dominio estaba
bien separado y aun así sólo se ejercitaba por la pantalla. *El unitario es del implementador y no
lo congela nadie: por eso es el primero que no se escribe si no se pide acá.*

**Una aserción que se satisface sola no es una aserción.** `assert(imports.length > 0)` pasa con
uno; `toHaveCount(n)` con `n` calculado por la misma función que produjo la lista pasa siempre; y
`assert(motivo.length > 0)` pasa con la palabra «x» cuando lo que querías era que el motivo
estuviera en el catálogo. *«No vacío» es lo que se escribe cuando no se decidió qué tenía que
valer.*

Dos primas de la misma familia. **Una aserción detrás de un `if` no se ejecutó**: `if (x.length)
assert(...)` pasa en verde el día que la rama no se da, que es justo el día en que querrías
enterarte. Y **el nombre del test promete lo que la aserción no cubre**: uno llamado «el CSS no
codifica la cantidad de etapas» que sólo hace `doesNotMatch(/repeat\(6/)` no ve una grilla con
seis anchos escritos ni un selector por nombre. *Leé el nombre, leé la aserción, y preguntate si
alguien que sólo leyó el nombre quedaría tranquilo con razón.*
Medido: un test de arquitectura afirmaba que la interfaz usaba «más de cero» símbolos del
dominio — y habría pasado con un producto que copió todas las reglas menos una. *Si el test pasa
con el caso que querías prohibir, no está probando nada.*

**Las fechas siguen la cadena causal, no el calendario.** Un registro derivado cae **dentro de
la vida del que lo originó**: una interacción de una oportunidad no puede ser anterior a la
oportunidad, ni posterior a su cierre. Medido: la semilla fechaba las interacciones contra la
empresa en vez de contra la oportunidad, así que había llamadas de seguimiento de negocios que
todavía no existían. *Cada campo era plausible; la línea de tiempo del registro completo era
imposible.*

**Y un número prometido en prosa lo fija un test, o no se promete.** Medido: el README decía
«unas 150 interacciones» y la semilla generaba 143, sin ningún test que fijara el total. No es
grave hoy; lo grave es que **la prosa y el código ya divergieron y nadie se enteró**, que es como
empiezan todos los README que nadie cree.

**La misma regla, contestada igual en todas las pantallas donde aparece.** Por cada regla que se
decidió en esta card, listá **todas** las pantallas donde se manifiesta y verificá que den la
misma respuesta. *Medido, y lo encontró un evaluador externo, no el método:* una corrida ocultaba
las oportunidades cerradas en el tablero y **las mostraba siempre en el listado**. Cada pantalla
tenía su test y los dos pasaban. Un test por pantalla no detecta que dos pantallas se contradicen:
hace falta preguntarlo.

## 7 · El cambio de prueba, y el test que lo reemplaza

Elegí el cambio más plausible que va a pedir esta card dentro de dos meses —una etapa más, un
campo más, un filtro más— y contá en cuántos archivos hay que tocarlo. No lo implementes: contalo.

| Cuántos archivos | Qué significa |
|---|---|
| **1** | la regla vive en un lugar |
| **2-3** | dominio + vista + test: normal |
| **4 o más** | la regla está copiada, y la copia va a divergir |

**El número sale de un comando y se pega, no se recuerda.** Medido: una corrida cerró diciendo
*«agregar una etapa = 2 archivos»* y un conteo de afuera dio **7**. Nadie mintió — contó los
archivos que había tocado, no los que habría que tocar. *Un número que el implementador estima
sobre su propio trabajo siempre da menos.*

**Y una enumeración se filtra de dos formas:** por nombre y **por cantidad**. Buscar los nombres
encuentra el dominio y las vistas; deja afuera el CSS con `repeat(4,…) repeat(2,…)`, que codifica
el seis sin nombrar ninguna etapa — y **ningún test lo mira**, porque el tablero pasa igual con
las columnas mal.

```
grep -rln -E "'(miembro1|miembro2|…)'" --exclude-dir=node_modules .    # por nombre
grep -rn -E "repeat\( *N|\.length *[=!]== *N|Array\( *N" --include=*.css --include=*.ts .   # por cantidad
```

El resultado de las dos, sin el archivo que define la enumeración, **es el número**. Si da 4 o
más, el arreglo entra en esta card: la enumeración baja entera desde el dominio y las pantallas
la reciben, no la repiten. El CSS se deriva de su tamaño, no de un número escrito.

**Lo que la interfaz le pone encima a cada miembro sale de su posición, no de su nombre.** Ésta
es la decisión que más mueve el número. Medido, dos corridas del mismo kit sobre el mismo
requerimiento: la que escribió `[data-etapa="prospecto"] { --etapa: #7d889b }` seis veces necesitó
**4 archivos** para la etapa nueva y fallaba en silencio si te olvidabas del CSS —la columna salía
gris—; la que derivó el color del índice contra una escala de tonos, con un `throw` si la
enumeración crece más que la escala, necesitó **una línea** y la suite entera quedó en verde.
*Mismo método, mismo día: 6 y 10 en mantenibilidad, y toda la diferencia es si el color se elige
por nombre o por lugar.*

**Una tabla indexada por una enumeración se tipa por esa enumeración.** `Record<string, …>`
deja el compilador en verde con una clave faltante y el problema aparece recién corriendo;
`Record<EtapaId, …>` no compila hasta que la completás. Medido, las dos caras: una corrida se
enteró del hueco por un «42 contra 40» en un test, y la otra por un error de tipos en segundos
que le nombró los tres archivos.

**Y los datos escritos a mano que nombran un miembro son un sitio más que ningún tipo ve.**
Cuarenta oportunidades con su etapa literal en la semilla: la etapa nueva queda sin datos, el
compilador no dice nada, y lo descubre el e2e seis minutos después. Si la enumeración va a
crecer, los datos se generan **recorriéndola**, no enumerándolos.

**Después el conteo se reemplaza por un test, que es lo único que impide que se degrade.** Un grep
dice cómo está hoy; un test dice que va a seguir estando así. El test agrega **un miembro más a la
enumeración en memoria** y afirma que las pantallas lo absorben: que el tablero dibuja la columna
nueva, que el filtro la ofrece, que los totales la cuentan.

```
@extensible:<la enumeración>   — un test por enumeración que el negocio vaya a ampliar
```

*Ése es el único chequeo de esta lista que sobrevive a la card que viene.*

**Y el test que afirma sobre la enumeración la deriva entera —la lista y su tamaño—, también en los e2e.** Medido: dos corridas derivaban las etapas del dominio en los unitarios y **las repetían a mano en los e2e**, tres veces una y dos la otra. Es el mismo defecto con otra ropa: el e2e está en otro paquete, importar el dominio cuesta una línea de configuración, y esa línea es más barata que el día que alguien agregue una etapa y el tablero muestre seis de siete con la suite en verde. Medido: al agregar
una etapa de prueba, el producto aguantó y **rompieron dos tests** que decían «cuatro abiertas,
seis con cerradas». Fallaron por la razón equivocada — no porque algo dejara de andar, sino
porque el número estaba escrito a mano. `ETAPAS.filter(e => e.abierta).length` no se rompe nunca.
*Un test que hay que editar cada vez que crece la enumeración es otra copia de la regla, y encima
en rojo.*

## 8 · Estructura

**El frontend importa el dominio, o no hay dominio.** `grep -r "from.*dominio" <frontend>`. Medido:
la corrida que lo reusaba tenía 18 imports; las otras dos, cero — y las dos tenían la regla de
negocio copiada. *Un dominio puro que nadie del lado cliente reusa quedó puro y decorativo.*

**Lo que entra del exterior se valida al entrar.** Un `JSON.parse` de `localStorage`, de un archivo
o de una respuesta: **parsear no es validar.** Un JSON sintácticamente válido con la forma vieja no
lanza excepción y se propaga entero. Medido, el peor defecto de cuatro corridas: una app parseaba
`localStorage` sin validar y sin límite de error; el dato viejo no rompía al parsear, rompía el
primer `.map` río abajo, dejaba pantalla en blanco y **se repetía en cada recarga**. *Un error que
deja pantalla en blanco y persiste al recargar no es un bug: es una app perdida.*

**La dirección de dependencias se afirma con un test, y el test existe o esto no pasa.** Lee los
imports de cada capa y falla si apuntan para afuera: `dominio/` no importa nada de fuera de
`dominio/`; `aplicacion/` no importa de `infra/` ni de `interfaz/`. Son diez líneas y ninguna
dependencia.

*No lo dejes en manos de `.claude/rules/arquitectura.md`: esa regla se carga por ruta, y si el
repo no usa las rutas que ella espera, no se carga y nadie avisa.* El detalle de las cinco
reglas está ahí; **la obligación de que el test exista está acá.**

## 9 · Lo último, antes del cierre

**Mirá el diff contra la card con una sola pregunta: ¿qué hay acá que no se pidió?**

Y la otra, que es la que mantiene la vara arriba: **¿qué le falta a esto para estar impecable?**
Lo que salga de ahí tiene exactamente **dos destinos, y ninguno es una lista de pendientes**:

| Se arregla en esta card | Se le pregunta al usuario |
|---|---|
| Todo lo que se verifica con un comando y depende de nosotros: un test que falta, una regla copiada, una cabecera, un `!` | Lo que exige una decisión de producto: si hay usuarios y roles, si el alcance incluye auditoría, qué pasa con un caso que el CU no cubre |

Lo segundo entra como `$1-AMB-NN` y sigue el ciclo del paso 2. **Un techo sólo es techo si lo
puso el negocio.** *«Es un proyecto chico», «son datos sembrados» o «no da el tiempo» no son
limitantes: son la decisión de no hacerlo, y esa decisión no se escribe en un registro de deuda —
se toma, se arregla, o se pregunta.*

*Porque una lista de lo que no hicimos, mantenida card tras card, es un método que enseña a no
hacerlo.*
