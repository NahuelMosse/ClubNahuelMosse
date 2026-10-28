- ACT-01 · M · L1 «Todo, base y API incluidas» no tiene S# ni ASM: la card cubre sólo la base de la app (S1 deja `lib/api` «al final», ASM-01 sólo las funcionalidades de la app); falta declarar en qué card pasan `apps/api` y la base, o que quedan fuera · card.md L1, S1, ENG-08-ASM-01 · lenses.md interpretation «Is there a sentence of L1 that no S# covers?» · plan · closed · ENG-08-ASM-05
- ACT-02 · M · S2 «las claves JSON no cambian» no tiene test planeado: `lib/comun/errores_de_campo.dart` lee `cuerpo['errores']`, y el test de S2 («nombres y comentarios … en inglés») empuja a traducir esa clave; renombrarla a `errors` rompe los errores por campo contra la API · card.md S2, T1 tests · lenses.md interpretation «Does a quantifier name its members, and does each member have a test?» · plan · closed · ENG-08-ASM-06

## Verified

- interpretation: fails (ACT-01, ACT-02)
- security: meets · la card no toca rutas, cuerpos ni logs (L3 declara attacks); mover `password_rules`/`registration_rules` no cambia qué se valida (S4, T2)
- overdesign: meets · `features/users/domain` aísla la regla que nombra `why-layer:` (validación del alta); no hay interfaces, fábricas ni carpetas vacías planeadas
