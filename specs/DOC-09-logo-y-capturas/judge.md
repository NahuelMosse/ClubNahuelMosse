- ACT-01 · L · S1 agrega «centrado, arriba del nombre» (y el README fija `width="96"`) sin que L1 lo diga ni un ASM lo declare: «el logo lo podes poner en el readme» no fija lugar ni tamaño; lenses.md/interpretation «Does each `S#` say the same as the sentence it quotes, no less and no more» y «What does the card leave to the default…, and is it written down?» · card.md S1 · plan · declared · «el logo lo podes poner en el readme» no fija lugar ni tamaño: va centrado arriba del nombre como el resto del encabezado del README, ya centrado, a 96 px para que no compita con el título; se deshace moviendo una línea del README

## Verified

- interpretation · fails (ACT-01) · S2 queda cubierta por DOC-09-ASM-01 con su test; «el mismo ícono del launcher» se prueba por bytes contra apps/mobile/assets/icono/icono.png; «ninguna sin usar» tiene test
- security · meets · la card no inserta texto de la persona; 01-login.jpg y 03-sedes.jpg no muestran correo, nombre ni dato personal (campos vacíos, sedes públicas)
- overdesign · meets · una tarea, sin capas, interfaces ni patrones; solo README, imágenes y un test
