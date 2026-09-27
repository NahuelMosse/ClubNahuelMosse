---
description: Corre las validaciones de la card y redacta el comentario de cierre sólo con lo que dijeron.
argument-hint: <CARD-ID>
---

Card: `$1`. Corré **todo** lo de abajo y pegá la salida cruda de cada comando. No resumas: pegá.

## Antes que nada: esto no es el paso 8

**Si `/validar $1` no corrió en esta sesión, corrélo primero y volvé.** Las validaciones de acá
abajo son de trazabilidad —que el snapshot esté intacto, que cada escenario tenga su test, que
nadie haya tocado lo congelado— y **no miran el código**: no corren `/code-review`, ni
`/simplify`, ni el repaso de seguridad, ni los tests de accesibilidad, ni la coherencia de una
regla entre pantallas.

*Una card que pasa sólo por acá cierra en verde sin que nadie haya mirado lo que se escribió.*
La salida de `/validar` es parte del cierre: va en el comentario junto con lo de abajo.

## Las validaciones

```
git diff --name-only <commit-del-snapshot>..HEAD -- specs/<feature>/card.snapshot.md  # 1. snapshot intacto
grep -rl --include='*_test.dart' --include='test_*.py' "@$1-H<NN>-<NN>" $E2E                         # 2. por cada escenario del snapshot: >= 1 archivo
grep -rhoE --include='*_test.dart' --include='test_*.py' "@[A-Z]+-[0-9]+[a-z]?(\.[0-9]+)?-H[0-9]+-[0-9]+" $E2E|sort -u # 3. ningún tag fuera del snapshot
grep -r --include='*_test.dart' --include='test_*.py' "@supuesto:$1-SUP-" $E2E                       # 4. cada SUP: tagueado...
grep -A99 "## Supuestos sin cobertura" specs/*/plan.md # 4b. ...o declarado sin cobertura
git diff --name-only <commit-de-tests>..HEAD -- $E2E   # 5. vacío: nadie tocó los tests
git diff --name-only main...HEAD                       # 6. vs. `## Mapa de archivos` del plan
sh scripts/test.sh                                     # 7.
flutter analyze && ruff check . && mypy --strict app   # 8.  en apps/mobile y apps/api
flutter test integration_test --name "@$1-" && pytest tests/escenarios --card $1   # 9.  los escenarios de esta card
flutter test integration_test && pytest tests/escenarios                          # 10. suite entera: las regresiones
flutter test test/capturas --tags capturas --update-goldens                       # 11. sólo si el diff toca UI
```

La 10 no es la 9 otra vez: filtrando por `@$1` se corre únicamente lo que esta card agregó, así
que un escenario viejo que esta card rompió queda **excluido** del cierre.

La 11 produce la tira de capturas **a 360 y a 430 de ancho**, en modo claro y oscuro (ver
`.claude/STACK.md`). Que exista es mecánico; que esté bien no. El veredicto lo da alguien mirándolas con el
`## Brief visual` del plan al lado —un modelo barato primero, una persona sobre lo que quede— y
va al comentario con el nombre de quién miró. Si el diff no toca UI, se saltea y se dice.

**Los dos hashes salen de `ambiguedades.md`, nunca de la memoria de la sesión** — que puede ser
otra: el de la validación 1 del evento `$1-AMB-00 · ... · snapshot · congelado en <hash>`, y el
de la 5 del evento `$1-TESTS` más reciente —`congelados` o `recongelados`, el último gana. Si alguno no está registrado, esa
validación es **no se pudo correr** y no cierra.

El 6 se chequea **en las dos direcciones**: archivo en el diff que no está en el plan, y archivo
en el plan que no está en el diff. Más dos que no son comandos:

- **Ambigüedades:** leé `ambiguedades.md` en la carpeta de la feature. Ninguna `AMB-NN` puede tener como último
  evento `abierta`, ni `preguntada` con el plazo vencido.
- **Dato centinela (a ojo, no hay comando):** leé cada test tagueado y confirmá que afirma sobre
  un valor que ese mismo test creó, no sobre un fixture ni un dato preexistente.

## Los tres estados

**Pasó · falló · no se pudo correr.** Si un comando no existe, no se pudo correr, o no lo
corriste — **no digas que pasó.** Decí exactamente cuál no corrió y por qué, y **no cierres la
card.** "No se pudo correr" no es "casi bien": es "no lo sé".

Si apagaste un chequeo por la válvula de escape, decilo acá y en el comentario.

## Nada tuyo queda vivo, y se comprueba

Antes de redactar: **listá cada servidor, puerto, contenedor y shell de background que levantaste
en esta card, y mostrá que está abajo.** Por PID, nunca por nombre de proceso — un `taskkill /IM`
o un `pkill` se lleva puestos los de otros agentes, del editor y del usuario.

Medido: una corrida quedó con tareas de background vivas al terminar y **el proceso se cortó
esperándolas**, con el paso 8 sin correr y la card sin cerrar. No perdió el trabajo de casualidad.

Lo que no puedas bajar, nómbralo: qué es, por qué sigue vivo y cómo se baja. *Un proceso vivo sin
explicación es un proceso colgado.*

## El informe de cierre

Sólo si las once validaciones pasaron. Redactalo **únicamente con lo que la salida dijo** —
nada de la memoria de la sesión. Tiene que incluir: qué escenarios **se ejecutaron y con qué
resultado** —no "se verificaron": lo que el gate sabe es que un test tagueado corrió en verde,
no que ese test corresponda al escenario—, los supuestos
`SUP-NN` que siguen vivos — **arrancando por el conteo y por los que nadie probó, nombrados uno
por uno**: nueve supuestos sobre una card de tres campos es el titular, no un pie —, el perímetro
(`## Perímetro` del plan: qué se mockeó, qué no se cubrió),
y si el snapshot sigue en `estado: propuesta`, que nadie lo revisó.

**Mostráselo al usuario y esperá su aprobación antes de publicarlo.** No pushees.
