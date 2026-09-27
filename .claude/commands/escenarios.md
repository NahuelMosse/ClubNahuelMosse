---
description: Convierte cada escenario del snapshot en un test tagueado, en rojo, en su propio commit.
argument-hint: <CARD-ID>
---

Card: `$1`. Ubicá la carpeta de la feature bajo `specs/` —la que creó spec-kit para este trabajo—
y leé ahí `card.snapshot.md` — la sección `## Escenarios` es la lista de trabajo.

**En este repo los tests son Flutter (`integration_test`) y pytest.** Rutas, comandos y
equivalencias de selectores están en `.claude/STACK.md`; los ejemplos de abajo ya están en Dart.

## Cómo se escribe un test de esta suite

 
`/escenarios <ID>` escribe un test por escenario, tagueado `@<ID>-H<NN>-<NN>`.

→ **El archivo va por pantalla, no por card.** `apps/mobile/integration_test/<área>/<pantalla>_test.dart`. Un test nuevo va
donde está la pantalla que ejercita, al lado de los que ya la prueban, **aunque su card sea otra**.

*Medido en un repo real que hizo lo contrario durante meses: 58 archivos tocaban la misma entidad,
y un solo tab tenía 12 tests repartidos en 5 archivos, cada uno archivado bajo la card que lo pidió.
Escribir el test 13 sin enterarse de los 12 anteriores era lo normal.* Archivar por card esconde la
cobertura justo de quien va a agregarle algo.

→ **El título dice el comportamiento, en lenguaje de dominio y en minúscula.** *«la composición
accionaria no avanza si no suma 100 %»*. La suite se lee como la lista de lo que el producto hace.
El tag de card va igual —es lo que hace posible la validación de arriba— pero **nunca adelante del
título**: un nombre que empieza con el número de un artefacto envejece con el artefacto.

→ **Todo por interfaz: la precondición se arma clickeando.** No se pega a un endpoint, no se
escribe en la base, no se guarda la sesión para saltear el login. Armar el estado por pantalla
prueba de paso que el flujo que lleva a ese estado existe y funciona; un `INSERT` que lo fabrica
saltea eso y nadie se entera.

**La regla es sobre armar, no sobre ejercitar.** Para provocar el comportamiento bajo prueba se usa
el vector que corresponda, y a veces la interfaz **no ofrece ninguno a propósito**: si el listado
filtra bien, a un recurso ajeno no se llega clickeando. Ahí **la URL directa es el vector** —es la
que usa quien reenvía un link o copia un id de un ticket—, y se escribe con un comentario diciendo
que es deliberada. *Si alguien después lo «corrige» a un clic, el test deja de probar lo que
probaba y pasa igual.*

→ **Rol real, nunca `admin`.** Se prueba con el usuario que haría eso en la vida real. *Un test que
usa `admin` para pasar los gates de rol no está probando la pantalla: está tapando el gating, que
suele ser justo lo que hay que verificar.* Y se prueba también lo que un rol **no** puede: que el
control no se renderice, no sólo que la API devuelva 403.

→ **Validá, en las dos direcciones, siempre junto con el denominador:**
- Por cada ID del snapshot: `grep -rl "@<ID>-H01-01" $E2E` devuelve al menos un archivo.
- Al revés: `grep -rhoE "@[A-Z]+-[0-9]+[a-z]?(\.[0-9]+)?-H[0-9]+-[0-9]+" $E2E | sort -u` — todo tag que salga tiene
  que existir en `## Escenarios` del snapshot. Un tag de un escenario que no existe es un test
  huérfano o un ID mal escrito.
- `find $E2E -name '*_test.dart' -o -name 'test_*.py' | wc -l` — archivos escaneados. Un grep en cero **no es verde si
  el denominador también es cero**: es "no se pudo verificar" (ver los tres estados, paso 8). Cero
  sobre una carpeta con archivos sí es verde.

→ **Dato centinela — el único chequeo que queda a ojo. No hay comando que lo valide.**
Leé cada test tagueado y confirmá que el valor sobre el que afirma es un valor que **ese mismo
test creó**, no un fixture compartido ni un dato que ya estaba en la base. Así un test no puede
pasar por accidente. El valor único se genera inline, sin archivo de fixtures:

```dart
final sede = 'Sede Prueba ${DateTime.now().millisecondsSinceEpoch}';
await altaDeSede(tester, nombre: sede, direccion: 'Av. Siempreviva 742');
```

y se afirma sobre `sede`, no sobre "el primer cliente de la lista". Si el escenario no admite dato
propio (estado vacío, error, permiso denegado), taguealo `@sin-centinela:<motivo>`. Nunca inventes
un dato falso para que el chequeo pase.

**Y cuando hay que afirmar sobre algo global —un contador, un total, un listado completo—: medí
antes, actuá, y afirmá la diferencia.** `de N a N+1`, nunca `toBeGreaterThan(0)`, que con la base
poblada ya es cierto **antes** de que el test haga nada.

→ **Los textos se escriben literales, a propósito.** Un assert que importa la constante del
producto afirma que el texto es igual a sí mismo: **no puede detectar un copy equivocado.** El
literal en el spec es el punto donde se verifica lo que la persona lee. No centralizarlo es una
decisión, no una deuda.

→ **Los selectores van por semántica y texto visible.** `find.bySemanticsLabel('Confirmar
reserva')` o `find.widgetWithText(FilledButton, 'CONFIRMAR RESERVA')` primero; `find.byKey` sólo
cuando la pantalla no da otra cosa, con un comentario.

**Si la pantalla no ofrece un selector estable, la primera pregunta es si al producto le falta
semántica** —un campo sin etiqueta, un ícono tocable sin `Semantics(label:)`, un diálogo sin
título— y se arregla ahí, no en el test. *Buscar por posición en el árbol (`find.byType(...).at(3)`)
es la señal de que ese arreglo no se hizo.* Nunca por tipo de widget de layout: cambia con cualquier
refactor visual y el test se rompe sin que el comportamiento cambie.

→ **Sin reintentos, y es doctrina.** *Un test que sólo pasa a veces es un test que no dice nada.* Y
`tester.pump(Duration(...))` está prohibido como sincronización: un `sleep` que hoy alcanza es un test que el
año que viene falla de a uno. Se espera con aserciones que reintentan, no con tiempo.

→ **El aislamiento es por test, no por archivo.** Cada test parte de un estado que es sólo suyo.
De ahí se sigue una regla fuerte: **no se escriben defensas contra otros tests.** Si uno parece
necesitar un filtro «para no leer lo del vecino» o una espera a que otro termine, el bug está en
otro lado — casi siempre en el propio test.

→ **Cada test declara qué verificó, en idioma de negocio.** Una línea por punto: qué se comprobó,
con qué evidencia, y **qué se rompe en la vida real si eso no funciona**. Un test que llega al
assert y no lo dice obliga a leer el código para saber qué cubre. *En el repo del que sale esta
regla, un test que pasa sin declararlo **falla**.*

→ **Los escenarios de la card son el piso, no el techo.** Antes de dar una pantalla por cubierta se
pasa esta grilla y se escribe lo que aplique:

| | |
|---|---|
| **Validaciones de campo** | vacío, sólo espacios, el límite exacto y ±1, formato inválido, negativo, cero, decimales, número enorme. El mensaje esperado se toma **literal del código** |
| **Errores de negocio** | los que se pueden provocar desde esa pantalla |
| **Estados vacíos** | y distinguir sus causas: sin datos, sin resultados, sin permiso. Ofrecen salidas distintas |
| **Buscadores y filtros** | acentos, mayúsculas, parcial, combinados, limpiar, sin resultados, y orden asc y desc por cada columna |
| **Persistencia y navegación** | qué sobrevive a recargar, qué se pierde al volver atrás, cancelar un modal a mitad |
| **Duplicados** | cada índice único es un caso: crear dos veces lo mismo da un error legible, no un 500 |
| **Baja lógica** | qué pasa con lo ya usado, si desaparece de los combos, si el histórico lo sigue mostrando |
| **Doble click y concurrencia** | doble submit, acción ya ejecutada por otro en otra pestaña, botón deshabilitado mientras guarda |
| **Permisos negados en la UI** | que el control no se renderice |
| **Archivos** | formato equivocado, vacío, grande, nombre raro, eliminar y restaurar |

Y la que las cruza a todas: **si se prueba que algo persiste, se verifica que persistió** —
recargando la pantalla—; **si se cambia una configuración, se verifica su efecto en todas las
pantallas donde pega**, una por una.

→ **Lo que no tiene superficie de pantalla no es un hueco de test.** Una acción sin ningún llamador
en el front se declara como tal y se lleva a negocio. Y lo que un test de integración cubre más
barato —cálculos, snapshots, códigos de error— vive ahí, no acá.



## Reglas

- **Un test por escenario, como mínimo**, tagueado con el ID exacto: `@$1-H01-01`.
  El tag va en el título, porque `--grep` matchea ahí — pero **al final, nunca adelante**:

  ```dart
  testWidgets('la reserva superpuesta no se confirma @$1-H01-01', (tester) async { … });
  ```

  El título empieza por el comportamiento, en minúscula y en lenguaje de dominio, para que la
  suite se lea como la lista de lo que el producto hace. *Un título que arranca con el número de
  un artefacto envejece con el artefacto: en un repo real el 72 % de los títulos empezaba con la
  referencia de un documento que ya nadie mantenía.*

- **El archivo va por pantalla, no por card**: `<área>/<pantalla>_test.dart`; en la API, `test_<recurso>.py`. Un test nuevo va donde
  está la pantalla que ejercita, al lado de los que ya la prueban, aunque su card sea otra.
  *Archivar por card esconde la cobertura de quien va a agregarle algo.*
- **En rojo.** Se escriben antes del código y se commitean fallando, en un commit propio que no
  toca nada más. **Registrá el hash en `ambiguedades.md`**, como evento, al lado del del
  snapshot:

  ```
  $1-TESTS · <fecha> · congelados en <hash>
  ```

  No alcanza con acordarse: el paso 6 y la validación 5 del cierre necesitan ese hash, y para
  entonces puede ser otra sesión la que esté corriendo. Un hash que sólo vive en la memoria de
  quien lo generó no existe.
- **Cada test crea su propio dato y afirma sobre ese dato.** Nada de fixtures compartidos ni de
  datos que ya estaban en la base:

  ```dart
  final sede = 'Sede Prueba ${DateTime.now().millisecondsSinceEpoch}';
  await altaDeSede(tester, nombre: sede, direccion: 'Av. Siempreviva 742');
  // ...y la aserción es sobre `sede`, no sobre "el primer resultado"
  ```

  Si el escenario no lo admite —estado vacío, error, permiso denegado— taguealo
  `@sin-centinela:<motivo>`. Nunca inventes un dato para que el chequeo pase.
- Si el escenario encoda un supuesto del plan, agregale también `@supuesto:$1-SUP-NN`.
- **No escribas código de producción en este comando.** Sólo tests.

## Validar antes de commitear

```
grep -rl "@$1-H01-01" $E2E                          # por cada ID del snapshot: >= 1 archivo
grep -rhoE "@[A-Z]+-[0-9]+[a-z]?(\.[0-9]+)?-H[0-9]+-[0-9]+" $E2E | sort -u   # todo tag existe en el snapshot
cd apps/mobile && flutter test integration_test --name "@$1-"   # tienen que fallar, no romper
cd apps/api && pytest tests/escenarios --card $1
```

Fallan por la aserción, no por un import roto ni por un selector inexistente: un test que
explota no es un test en rojo.

**Pero acá eso no se puede distinguir, y hay que saberlo.** Antes de implementar, un selector que
no encuentra nada y una funcionalidad que todavía no existe **producen exactamente el mismo
error**. Por eso el rol y el nombre que elegís tienen que ser posibles *por la especificación*,
no por lo que se vea: `find.bySemanticsLabel` sobre un widget que no expone etiqueta —un `Icon`
suelto, un `Container` tocable— no encuentra nunca nada. Antes de buscar por etiqueta, verificá
que ese widget la exponga.

*El paso 8 lo vuelve a chequear cuando el código ya está, que es el único momento en que la
diferencia se ve. Pero para entonces el test está congelado y arreglarlo cuesta un
recongelamiento: acá es gratis.*

**Y un selector que nombra un valor del negocio se acota a su contenedor.** `find.text('Fútbol')`
parece preciso hasta que la pantalla muestra el chip de deporte y una tarjeta cuyo título también
dice *«Fútbol 5»*: ahí el selector matchea dos cosas y la suite se cae por *Too many elements*. Medido, y es la segunda causa de rojo de este
método. El nombre de una etapa, de un estado o de una categoría **va a aparecer dentro de los
datos**, porque los datos hablan del mismo negocio. Acotá al `<section>`, a la columna o a la
fila (`find.descendant(of: ..., matching: ...)`), y recién ahí buscá por texto.

## Reportar

Escenarios del snapshot / tests escritos / tests en rojo / escenarios con `@sin-centinela` y por qué.
Si un comando no lo pudiste correr, decí cuál y por qué. No lo cuentes como pasado.
