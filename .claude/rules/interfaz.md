---
paths: ["**/*.css", "**/*.tsx", "**/*.jsx", "**/*.vue", "**/*.svelte", "**/*.html"]
---

# Interfaz: lo que se decide antes, y lo que se mira después

Esta regla se carga sola cuando tocás un archivo de pantalla. No hay que acordarse de ella.

Todo lo que sigue salió de corridas medidas, no de criterio. Cada bloque dice qué se observó.

## Antes de escribir la pantalla: el `## Brief visual` del plan

- `## Brief visual` — **sólo si la card toca una pantalla.** Qué tiene que poder hacer y leer el
usuario en cada vista, en prosa corta. No es diseño: es qué se va a poder comprobar mirando.
**Para escribirlo, invocá `interface-design`**, que es la única skill del kit que entra *antes*
de la pantalla: fuerza elegir dominio, foco y firma visual en vez de caer en el template. Su
premisa es la de este paso — *"vas a generar output genérico; los patrones de tu entrenamiento
son fuertes"*—, así que el brief no es documentación del diseño, **es la decisión de no ser
genérico tomada por escrito y antes**.

**Y el brief dice desde dónde se hace cada cosa.** Por cada acción que la card pide, escribí en
qué pantalla está parada la persona cuando la necesita. Medido: una corrida puso el alta de
interacción sólo en la pantalla de altas, con un selector que listaba **todos** los contactos de
todas las empresas; desde la ficha de la empresa que estás mirando no había forma de registrar
una. Todos los escenarios de la card pasaban. *Una acción que existe pero obliga a salir de
donde estás es, para quien la usa todos los días, una acción que no existe* — y no hay test de
escenario que lo detecte, porque el escenario dice qué se puede hacer, no desde dónde.

**Antes de buscar firma, calibrá cuánta corresponde.** `interface-design` empuja a diferenciarse
sin preguntar de qué pantalla se trata, y no todas toleran lo mismo. El brief abre declarando
dos números, con una línea de por qué:

| | 1 | 5 | 10 |
|---|---|---|---|
| **Invención** — cuánto se aparta de lo convencional | lo que el usuario ya sabe usar | — | pieza de autor |
| **Densidad** — cuánto dato por pantalla | una cosa a la vez | — | cabina de avión |

Un tablero de ventas que se lee parado a la mañana es **invención baja, densidad alta**. Un
portfolio es lo contrario. Sin esos dos números, la skill optimiza para el portfolio siempre.

**Invención baja es sobre la estructura, no sobre el carácter.** El dial dice qué tan
convencional es *la forma* —un tablero por etapas se ve como un tablero por etapas— y no
autoriza a que la ejecución quede sin decidir. Medido: una pantalla con invención 2 quedó
correcta y se leyó de inmediato como *«excesivamente hecha con IA»*. **Estructura convencional
y ejecución sin carácter no es lo mismo que invención baja: es no haber decidido.** La escala
tipográfica, la profundidad, el ritmo del espacio y el peso de la cifra que domina se eligen
igual, y con el mismo cuidado, en invención 2 que en invención 8.

**Y no inventes lo que ya está resuelto.** Antes de diseñar desde cero, mirá si el tipo de
pantalla tiene patrones maduros: una grilla de datos, un tablero por estados, una tabla con
filtros. **Apartarse de eso es una decisión que se declara y se justifica**, no el default.
*Porque el usuario no viene a conocer tu sistema: viene a leer un número.*

**Dos cosas más que el brief tiene que decir, o el paso 9 no las puede verificar:**

**Qué hace cada vista con el ancho de escritorio.** Una línea por vista. Se construye
mobile-first porque cubrir los dos sale más barato, pero el escritorio es donde se trabaja la
jornada entera: tiene que mostrar algo que en el teléfono no entra, no ser el teléfono estirado.

**Qué dato codifica cada variable visual.** El color, el peso, la densidad: cada uno nombra la
dimensión del dato que transporta —*el color dice la etapa*, *el peso dice la prioridad*— o no
va. **Si una variable visual no puede nombrar qué dato codifica, es disfraz.** Medido: una card
eligió una paleta de metáfora —papel, sello, carpeta, birome— y quedó peor que otra con seis
colores, uno por etapa del pipeline. La firma no está en el clima, está en las variables del
dominio.

**Y el material, que es lo que más delata y lo que nadie declara.** Cinco decisiones, cinco
líneas. **Lo que no se decide sale por default, y el default es reconocible.**

| | Si no se declara, sale |
|---|---|
| **Tipografía** — qué familia, y por qué esa | `system-ui` |
| **Lienzo** — de qué color es el fondo y de qué color la superficie que apoya | gris frío `#f6f7f9` + tarjeta blanca |
| **Separación** — qué separa las cosas: espacio, línea, sombra o cambio de fondo. **Una, no las cuatro** | borde de 1 px **más** sombra **más** radio, en todo |
| **Radio** — cuánto, y si es uno solo o varía por tamaño | 10-12 px en todo |
| **Densidad** — cuánto respira una fila, en píxeles | cómoda, tipo landing |

**Medido, y es el hallazgo más incómodo del kit:** dos corridas independientes —una con el
método entero y otra con spec-kit solo, que nunca se vieron— llegaron al mismo lienzo gris frío,
la misma tarjeta blanca con borde de 1 px más sombra más radio de 10-12 px, las mismas etiquetas
en mayúscula, y **ninguna de las dos eligió tipografía**. El brief de la primera definía con
precisión qué dato codifica cada color y dejaba el soporte entero sin decidir.

*Y `design-deslop` no lo ataja: su lista es jerarquía plana, sin punto focal, tarjetas idénticas,
paleta tímida — y esa pantalla no tenía ninguna. **Se pasa la revisión anti-genérico siendo
reconociblemente default**, porque la lista mira la composición y el tell está en el material.*

### Decidir el material no es alejarse del default

**Esta tabla dice qué hay que decidir, no que haya que ir para el otro lado.** Leerla como «el
gris frío está mal» es el error que produjo las tres corridas siguientes: *lienzo lino*, *papel
crema con serif*, *cartón cálido*. Las tres distintas, las tres peores, y el veredicto fue el
mismo las tres veces — **«se ve antiguo»**.

El gris frío es el default **porque es el registro contemporáneo del software de trabajo**. El
problema de la pantalla que lo usó no era el color: era que **no había decidido nada más**.

> **Se ve antiguo, y lo antiguo da ganas de cambiarlo.** Una herramienta interna que parece de
> hace quince años le dice al cliente que el software está viejo, aunque se haya entregado ayer.
> Para una consultora eso no es una objeción estética: es que el próximo presupuesto sea para
> reemplazarlo.

**El registro tiene que ser el de hoy.** Cinco señales que envejecen una pantalla, y las tres
primeras aparecieron en corridas medidas:

| Envejece | En su lugar |
|---|---|
| Serif en texto de interfaz | serif sólo en una cifra o un título, si hay un motivo |
| Lienzo cálido —crema, lino, cartón— | neutro, frío o verdadero; el calor va en un acento, no en el fondo |
| Textura, papel, metáfora de objeto físico | superficie plana; la identidad va en tipografía, ritmo y color |
| Contraste bajo y bordes ornamentales | contraste alto y separación por espacio |
| Densidad apretada con reglas gruesas | espacio generoso y una sola línea fina donde haga falta |

**Y no es «volvé al default».** En el registro contemporáneo se distingue igual: por la elección
de tipografía, por la escala, por cómo se aplica el color del dominio, por la densidad. *Lo que
hay que evitar es que se note el esfuerzo por ser distinto* — que fue exactamente el primer
veredicto de este experimento: *«se nota que hubo un intento de que no se vea genérico, pero se ve
peor»*.

**Tres escalas, no valores sueltos.** Un token de color no es un sistema de diseño. Lo que hace
sistema es que los valores salgan de una escala corta y nombrada, y que agregar una pantalla no
invente valores nuevos:

- **Tipografía** — cuatro o cinco tamaños con nombre, y el peso y el color como ejes aparte.
- **Espacio** — una unidad y sus múltiplos. Nada de `padding: .85rem` a mano.
- **Color** — los del dominio más una rampa neutra corta. El resto se deriva.

Medido sobre cuatro corridas: **ninguna declaró escala tipográfica.** Una usó 15 tamaños sueltos,
otra 10, otra 6. *Quince tamaños no es una decisión tomada quince veces: es ninguna decisión,
tomada quince veces.*

**Y lo que se repite dos veces es un componente.** Un campo de formulario, una pastilla de
estado, una fila de listado: si el mismo bloque aparece en dos vistas, va a un primitivo con sus
variantes. Medido: las cuatro corridas tenían el mismo select de empresa copiado en dos altas, y
el mismo bloque de monto+etapa+fecha en dos vistas.

## Después de escribir la pantalla: mirarla

**9 · Si la card tocó una pantalla, miralá. El paso 8 no la mira.**
Sólo si el diff toca UI. Si la card es de backend, saltalo y decilo.

Un test tagueado afirma sobre el DOM y el usuario lee píxeles. Medido sobre una pantalla con
cinco defectos reales de teléfono adentro: el chequeo de ancho atrapó **0**, axe atrapó **0**, un
escenario tagueado habría atrapado **0**, y mirar las capturas atrapó **5**. El caso que lo
resume: la etiqueta está entera en el DOM y truncada por CSS, así que `toHaveText("FRÁVEGA")` da
verde mientras la pantalla dice `01 FR…`. No es un test flojo: mide otra cosa que la que importa.

→ **Producí el artefacto** — esto sí es mecánico y binario:
```
npx playwright test --project=capturas
```
Es un archivo propio del repo: un `test('@captura <vista>')` por vista, que navega y hace
`page.screenshot()`. No afirma nada — si afirmara, volveríamos al problema de arriba. Ese archivo
**sí** lo toca el que implementa, porque no está tagueado por card.

**Y no se llama `.spec.ts`.** Va como `capturas.captura.ts`, en su propio *project* de Playwright,
fuera del que corre el gate. *Lo que no es un test no lleva nombre de test: si entra a la suite,
suma casos verdes que no afirman nada y el conteo del cierre miente.* En el repo del que sale esta
regla pasó exactamente eso: una captura archivada como `.spec.ts` contaminó el gate.

→ **Dos anchos, siempre los dos:**
```
{ width: 1280, height: 900 }   // escritorio — es donde se trabaja
{ width:  390, height: 844 }   // teléfono   — es donde se rompe
```
**Medido, y por eso está acá:** una card que capturó sólo a 390 px salió con el teléfono impecable
y la cuarta columna del tablero **cortada por el borde en escritorio**, con 1280 px de ancho
disponible. El agente miró sus capturas, encontró defectos reales y los arregló — todos los del
único ancho que el método le hacía mirar. **Se optimiza lo que se mira y se rompe lo que no.**

**Lo crea la primera card que toca una pantalla**, y cada card que agrega una vista agrega su
`@captura`. No existe de antes: si el paso 9 se queda esperando un spec que nadie tiene
asignado escribir, nunca se ejecuta y el paso entero es decorativo.

**Contra un build de producción, nunca contra el dev server.** Medido: el indicador de dev-tools
aparece en las doce capturas tapando contenido distinto, y se llevó cinco de los seis hallazgos
del revisor. No es que se equivocara —el elemento tapa de verdad— es que no se despacha. Revisar
contra el dev server quema la atención del revisor en algo que el usuario nunca ve.

→ **Escritorio no es el teléfono estirado.** Se construye mobile-first porque sale más barato
cubrir los dos, pero **el escritorio es el destino principal**: es donde se trabaja la jornada
entera. Con las dos tiras al lado, la pregunta es qué hace el escritorio con el espacio de más.

| | No pasa |
|---|---|
| Misma disposición en los dos anchos, sólo más grande | una columna que se estira, tarjetas que crecen y nada más |
| El espacio de más va todo a márgenes | el contenido ocupa lo mismo y sobra aire a los costados |
| Un patrón de teléfono servido en escritorio | un carrusel horizontal donde entraban todas las columnas |

El escritorio tiene que **mostrar algo que en el teléfono no entra**: más columnas a la vez, una
tabla en vez de tarjetas apiladas, el detalle al lado del listado en vez de en otra pantalla.
Si las dos capturas se distinguen sólo por la escala, el escritorio no está diseñado.

**El `## Brief visual` lo dice antes:** una línea de qué hace cada vista con el ancho de más. Si
no está escrita, se decide mirando el diff y el paso se confirma a sí mismo.

Existe la tira o no existe. Si el server no levanta, es **no se pudo correr** y no cierra.

→ **El veredicto lo da alguien mirando, con el `## Brief visual` del plan al lado.** Primero un
modelo barato: con el brief saca 3 de 5 sin ensuciar la salida. Después una persona sobre lo que
quedó, que ya no arranca de cero.

**El brief, no una lista de defectos.** El brief dice qué tiene que poder hacer y leer el
usuario; una lista de defectos es la respuesta, y darla invalida la medición. La diferencia es la
misma que entre la card y el test.

Lo que este filtro resuelve es *¿está obstruido o ilegible?* — verificable contra algo escrito.
Lo que **no** resuelve es *¿está bien?*: en la medición se le escaparon el juicio tipográfico y
el caso de dos interfaces anidadas donde hay que saber cuál controla a cuál. Eso queda para la
persona, y por eso el paso no se cierra solo.

→ **Con las capturas a la vista, corré `/design-deslop`.** Es la otra pregunta de este paso, y no
la contesta el brief: no *¿está roto?* sino *¿se nota que lo generó un modelo?* —jerarquía
plana, ningún punto focal, doce tarjetas idénticas, un acento embadurnado, estructura hecha de
bordes en vez de espacio—. Va acá y no en el paso 8 por la misma razón que todo lo demás de este
paso: **la slop es compositiva y es invisible en un diff.** Su primer pase es mirar el render con
los ojos entrecerrados; el segundo, recién, la línea. Trae su propia sección de qué **no** tocar,
que es lo que evita que la corrección quede peor que el defecto.

**Ojo con lo que `design-deslop` no hace, dicho por ella misma:** *«no es una design review
completa; acá tenés un solo trabajo: que deje de parecer generado»* y *«una limpieza que borra la
intención es peor que la slop»*. **No elige dirección ni la repara.** Si la pantalla quedó mal
porque la dirección estaba mal, esta skill no lo va a decir — y pedirle que lo arregle es pedirle
lo que su propio archivo declara fuera de alcance.

→ **Y la slop más visible no está en el CSS: está en los datos.** `design-deslop` mira
composición. Lo primero que delata a un ojo humano es el contenido sintético, y eso no lo mira
nadie. Medido: una pantalla con el diseño corregido y las once validaciones en verde se leyó de
inmediato como *«excesivamente hecha con IA»* — y la causa eran diez títulos ciclados con
`TRABAJOS[i % TRABAJOS.length]` sobre cuarenta oportunidades, repartidas **7/7/7/7 exactas** entre
las etapas.

| Señal | Qué se ve en pantalla |
|---|---|
| `array[i % array.length]` | el mismo título cuatro veces, en el mismo orden en cada columna |
| Reparto perfectamente parejo | siete oportunidades en cada una de las cuatro etapas |
| Montos redondos o en progresión | `$ 1.000.000`, `$ 2.000.000`, `$ 3.000.000` |
| Un solo eje de variación | todos los nombres del mismo largo, todas las fechas del mismo mes |

**Los datos sembrados se combinan, no se ciclan**, y las distribuciones salen desparejas a
propósito: una etapa con dos y otra con once es lo que pasa de verdad. Si la card pidió que
«parezcan reales», eso es un requisito y se verifica como cualquier otro — no es decoración del
seed.

`grep -rn "\[i % " <semilla>` es el chequeo más barato de este paso entero.

**Y los campos de un mismo registro se correlacionan, no se sortean por separado.** Ésta es la
señal que sobrevive a todas las anteriores: cada campo puede ser variado y creíble por su cuenta
y el registro completo seguir siendo imposible. Medido, dos corridas del mismo requerimiento: una
eligió el título de la oportunidad de un catálogo barajado y le tocó *«provisión de uniformes de
planta»* a un estudio contable; la otra escribió los cuarenta títulos atados al rubro de su
empresa —el túnel de congelado al frigorífico, las luminarias al municipio— y **sacó un punto más
en la evaluación a ciegas que la que ganó todas las demás dimensiones.**

Lo mismo con el tiempo: una oportunidad en Negociación lleva más interacciones que una en
Prospecto. *Si el volumen de actividad no sabe en qué etapa está el negocio, la pantalla muestra
ruido con forma de datos.*

→ **Y el material contra lo declarado.** Las cinco líneas del brief —tipografía, lienzo,
separación, radio, densidad— se contrastan contra lo que se ve. **El default no falla por feo,
falla por reconocible**, y por eso no lo marca ninguna revisión: cada decisión suelta es
defendible y el conjunto es el mismo que produce cualquier agente.

```
grep -hoE "font-family: *[^;]+" <estilos>
```

**No alcanza con que esté declarada: hay que leer qué dice.** Medido sobre cuatro corridas —dos
sin declarar nada, una declarando `ui-sans-serif, system-ui, …`, que es el default escrito a
mano, y una sola eligiendo de verdad—. Un `grep -c` habría dado verde en la que escribió el
default. **La pregunta no es si hay una línea, es si hay una decisión.**

Vale igual para las otras cuatro del material: un `--radio: 12px` declarado y un radio de 12 px
por default se ven igual en pantalla. El brief dice qué se eligió y por qué; el paso 9 mira si
eso es lo que está.

→ **La pregunta que ninguna skill contesta: ¿quedó mejor?**

Las tres juzgan el resultado contra una barra. Ninguna compara contra la versión anterior, y el
veredicto de este paso compara contra el brief — que es el documento que eligió la dirección. **Si
la dirección estaba mal, el paso se valida a sí mismo.**

El único contrapeso disponible es barato y hay que hacerlo a mano: **antes de cerrar, mirá la
tira al lado de la pantalla anterior** —o de una pantalla del mismo producto que ya funcionaba— y
contestá si esto es mejor o sólo distinto. Medido: una card produjo una pantalla más distintiva y
peor, con todas las revisiones en verde. *Distinto no es mejor, y ninguna validación de las que
corren lo distingue.*

→ **Y la pregunta que va antes que todas: ¿de qué año parece?**

Con la tira a la vista, sin mirar el código: **¿esto parece software que se entregó este año, o
parece de hace diez?** Si la respuesta es «de hace diez», no importa que el resto esté bien —
*lo antiguo da ganas de reemplazarlo*, y una herramienta que parece vieja el día que se entrega
ya nació con fecha de vencimiento.

Es la pregunta más fácil de contestar de todas las de este paso y la única que nadie hace. En
este experimento tardó **tres iteraciones** en aparecer, y las tres pantallas intermedias la
habrían fallado: lino, papel crema con serif, cartón. Cada una pasó todas las revisiones.

→ La tira va adjunta al comentario de cierre, junto con quién la miró.

