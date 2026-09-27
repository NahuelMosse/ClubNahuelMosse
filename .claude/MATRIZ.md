# La matriz: qué hay que tener en cuenta, en qué momento, y cómo se sabe que se tuvo

Los nueve pasos de `METODOLOGIA.md` dicen **en qué orden** se trabaja. Esta matriz dice **qué no
se puede olvidar**. Un flujo te dice qué sigue; no te dice qué te salteaste. **Una celda vacía se
ve.**

Cada celda nombra **el artefacto** que tiene que existir y **cómo se comprueba**. El detalle vive en
el comando o la regla que se nombra: acá no se repite, porque un índice que explica todo es el
archivo largo que nadie lee.

| Área | Iniciar | Planificar | Construir | Verificar | Cerrar |
|---|---|---|---|---|---|
| **Alcance** | `card.snapshot.md` congelado · `git diff` vacío | las diez preguntas → `AMB-NN` · el `grep` da 10 | cada archivo nuevo figura en el mapa del plan | diff contra la card: ¿qué hay acá que no se pidió? | supuestos vivos, uno por uno, en el comentario |
| **Diseño** | **la primera card fija layout, capas y forma de las enumeraciones** · ver abajo | mapa de archivos **con sus decisiones de estructura** | capas según `rules/arquitectura.md` | test de dirección de dependencias en `npm test` | — |
| **Comportamiento** | escenarios de la card, uno por línea | cada escenario con su test tagueado, en rojo · `/escenarios` | unitario por cada regla de negocio | suite entera + `@extensible` · la falla se clasifica por su forma | escenarios ↔ tags, en las dos direcciones, contando **escenarios** y no casos |
| **Interfaz** | — | brief visual: diales, material, **desde dónde se hace cada cosa** | apariencia por **posición**, no por nombre | `axe`, teclado, contraste, `forced-colors`, obligatoriedad | la tira de capturas y **quién la miró** |
| **Seguridad** | — | perímetro: auth declarada o `SUP-NN` | el hueco donde lo ve quien arranca la app | las ocho filas **contra la app levantada** · `/validar` §5 | lo que no se probó, nombrado |
| **Datos** | volúmenes pedidos por la card | — | semilla correlacionada, recorriendo la enumeración | cadena causal · sin el generador · **el número prometido lo fija un test** | **con qué datos se verificó** |
| **Evolución** | ver Diseño × Iniciar | — | tabla indexada por enumeración, **tipada por esa enumeración** | cambio de prueba **por nombre y por cantidad**, contado por comando | **el número del cambio de prueba**, para que la próxima card vea si sube |
| **Evidencia** | `fuentes:` y `no_leido:` | — | — | tres estados, exit codes, **nada al fondo de lo que dependa el cierre** | el comentario sale de la salida, no de la memoria |

## La celda que el flujo esconde

**Diseño × Iniciar.** La primera card de un repositorio elige el layout, los nombres de las capas
y la forma de las enumeraciones —si una etapa es una cadena, un objeto con nombre o un índice—, y
**ésas son las decisiones más caras de deshacer de todo el proyecto**. Un método que la trata igual
que a la card número cuarenta la deja pasar sin mirar.

Así que la primera card de un repo nuevo, además de su trabajo, deja escritas en el plan tres
cosas, y cada una con el motivo:

- **Qué capas hay y quién conoce a quién.** Es lo que después afirma el test de dependencias; si no
  está escrito, el test afirma lo que salió.
- **Cómo es una enumeración del negocio**: dónde vive, qué lleva —el nombre sí, la apariencia no—, y
  cómo se recorre.
- **Los `paths:` de `.claude/rules/`**, ajustados a las rutas que se acaban de inventar. Una regla
  que se activa por ruta no avisa cuando no se activa.

## Cómo se usa

Al **cerrar**, se recorre la columna entera y se contesta cada celda con su evidencia o con *no
aplica, porque…*. **Una celda sin contestar es una celda que no se hizo.**

La matriz no reemplaza a los comandos: los ordena. `/card` llena Iniciar, `/escenarios` y el plan
llenan Planificar, `/validar` llena Verificar, `/cerrar` llena Cerrar. Si una celda no tiene comando
que la llene, **esa celda es el próximo mecanismo que falta.**
