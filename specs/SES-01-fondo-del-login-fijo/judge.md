- ACT-01 · M · el aviso de credenciales inválidas (`AvisoDeInicioSesion`, `Positioned(bottom: Medidas.s24)` dentro del mismo `Stack`) queda tapado por el teclado si la foto se fija sin achicar el `Scaffold` y la persona vuelve a tocar un campo con el aviso visible; ningún S#, ASM ni test dice dónde queda el aviso con el teclado abierto · card.md S1 «ocupa la misma área que con el teclado cerrado» + Changes «el formulario se desplaza sobre ella» · lenses.md interpretation «Does each `S#` say the same as the sentence it quotes, no less and no more?» · plan · closed · SES-01-ASM-02, T1 «con el teclado abierto el aviso de credenciales inválidas queda por encima del teclado»

## Verified

- interpretation · fails (ACT-01) · S1 y S2 cubren L1; SES-01-ASM-01 se sostiene: `FondoDeInicioSesion` sólo se usa en `formulario_de_inicio_sesion.dart`
- security · meets · la card no cambia cómo se trata el texto de la persona, ni rutas, encabezados o logs; ninguna pregunta de la lente queda abierta
- overdesign · meets · un archivo de presentación, sin capas, interfaces ni patrones nuevos
