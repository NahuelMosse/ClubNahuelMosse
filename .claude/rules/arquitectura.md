---
paths: ["apps/mobile/lib/**", "apps/api/app/**"]
---

# Arquitectura

Con ese frontmatter estas reglas se cargan sólo cuando se toca uno de esos archivos; sin él, se
pagan en cada sesión. Ajustalos a la estructura real del repo — **y en la primera card de un
repo nuevo eso es parte del trabajo**, porque es la card que inventa la estructura.

*Medido, y es el motivo de que esto esté escrito acá arriba y no al final:* el kit venía con
`apps/api/**` y `apps/web/**`, y de seis corridas del propio método **cuatro eligieron
`apps/crm/`**. En esas cuatro la regla nunca se cargó — y nadie se enteró, porque **una regla que
se activa por ruta no avisa cuando no se activa**: no hay error, no hay aviso, simplemente no
pasa nada.

*Lo que sí funcionó, y por eso el contenido crítico no vive sólo acá:* el test de dirección de
dependencias lo escribieron igual las corridas donde esta regla no se cargó, porque la
obligación está también en `/validar`, que se invoca siempre. **Lo que se apoya en una sola
puerta se pierde cuando esa puerta no se abre.**

## Las cinco que importan

Son las que más caro salen y las que ningún linter genérico atrapa.

1. **Un router no habla con el ORM.** Nada bajo `apps/api/app/**/routers/` importa `sqlalchemy`
   ni un modelo de la base. El router recibe, delega a un caso de uso y responde. Del lado de la
   app, **un widget no llama a la API**: la pantalla habla con su estado, y el estado con un
   repositorio.
2. **El dominio no lleva apariencia — pero sí lleva el nombre.** Un color, un ícono, un ancho de
   columna o un formato de fecha dentro de la capa de reglas significa que **una pantalla nueva
   con otra paleta ya no puede usar ese dominio**. Medido: la tabla de etapas traía
   `color: '#7a889c'`.

   **El corte está en «cómo se ve», no en «cómo se llama».** Que la etapa sepa que se llama
   *Negociación* es vocabulario del negocio y ahorra un mapa paralelo que hay que mantener al
   día. Medido con dos corridas del mismo kit: la que sacó el nombre del dominio ganó un punto de
   diseño y **perdió tres de mantenibilidad** —el cambio de prueba le costó 8 archivos contra
   4—, porque cada etapa nueva necesitaba además su entrada en el mapa de rótulos. *Un principio
   que se cobra tres puntos donde gana uno está mal aplicado.*

   La excepción es el texto **traducido**: si hay más de un idioma, el rótulo es presentación y
   sale, porque ahí el mapa existe igual.
3. **El dominio no importa infraestructura.** Nada bajo `**/dominio/**` importa un SDK externo,
   el ORM, HTTP, una cola ni el sistema de archivos. Si una regla de negocio necesita un dato de
   afuera, lo recibe como parámetro.
4. **Los módulos no se importan en círculo.** Si `clientes` importa `solicitudes` y `solicitudes`
   importa `clientes`, hay una tercera cosa que ninguno de los dos vio. Sacala a un módulo
   compartido o invertí la dependencia.
5. **Un servicio hace una cosa.** Si para explicar qué hace usás "y" más de dos veces, son dos
   servicios. No es una regla de líneas: es de motivos para cambiarlo.

## Dirección de dependencias

```
interfaz (routers, pantallas) → aplicación (casos de uso) → dominio (entidades, reglas)
infraestructura (SQLAlchemy, Firebase, HTTP) → dominio
```

Las flechas apuntan hacia adentro y **nunca al revés**. El dominio no conoce a nadie.

## Fronteras de módulo

Se importa el índice público de otro módulo, nunca su interior:
`from app.reservas import crear_reserva` sí; `from app.reservas.infraestructura.modelos import Reserva` no.

## Lo que no hay que hacer en nombre de la arquitectura

Estas pesan tanto como las de arriba, porque el error de sobrediseñar es más caro de deshacer
que el de subdiseñar.

- **No crees una interfaz para satisfacer DIP.** Una interfaz con una sola implementación y sin
  un segundo consumidor a la vista es indirección, no desacoplamiento.
- **No hagas un repositorio genérico** si un repositorio del dominio expresa mejor la intención.
  `reservas_superpuestas(espacio, inicio, fin)` dice algo; `find_one(criteria)` no.
- **No introduzcas una abstracción hasta tener un motivo concreto.** Dos usos no son un patrón.
- **No conviertas un CRUD en hexagonal.** Si la card es un ABM, entregá un ABM.

## Cómo se revisa

`/code-review` para el diff (bugs + limpieza). `/simplify` después de implementar (sólo limpieza,
no busca bugs).

**Y la dirección de dependencias se afirma con un test, no se mira a ojo.** Un repaso en el PR se
cumple mientras alguien se acuerde; la flecha se invierte en el commit apurado de un martes y ahí
ya no hay quién la note. El test es de diez líneas y no necesita ninguna dependencia: lee los
imports de cada capa y falla si apuntan para afuera.

```
dominio/     no importa nada de fuera de dominio/
aplicacion/  no importa de infra/ ni de interfaz/
interfaz/    no importa de infra/
```

Medido: una corrida cumplía las tres por disciplina y **nada la obligaba** — la capa de
aplicación importaba la clase concreta del almacén y las vistas consultaban los datos crudos. Las
dos cosas pasaron todos los tests y las encontró un revisor externo leyendo. *Una propiedad que
sólo se sostiene porque alguien la recuerda ya es una propiedad perdida; la única diferencia es
cuándo te enterás.*

En la API la herramienta es `import-linter` con un contrato de capas que codifique estas mismas
flechas, corriendo en `scripts/test.sh`; en la app, un test que lee los `import` de `lib/`.
Lo que no alcanza es la revisión.

## El compilador en su máxima exigencia

`analysis_options.yaml` con `strict-casts`, `strict-inference` y `strict-raw-types`, y la API con
`mypy --strict`. Son los que atrapan el error que más aparece: un `mapa[k]` que puede ser nulo y un
`dynamic` que viaja sin tipo, y la respuesta a esa mentira suele ser un `!` que la tapa en vez de
manejarla.

**Un `!`, un `as dynamic`, un `// ignore:` o un `# type: ignore` es el analizador avisando y alguien
tapándole la boca.** Se sacan; el que sobreviva lleva una línea diciendo por qué.
