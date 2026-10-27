- ACT-01 · L · ninguna spec, ASM ni test dice que las capturas (tomadas contra la API de Render) muestren sólo datos de la cuenta de prueba ni que el README no publique credenciales de esa cuenta; hoy 10-perfil.jpg muestra «socio@test.test», DNI y nacimiento ficticios, y ASM-02 sólo aclara el admin · card.md S1 / sources «capturas · tomadas del emulador Android … contra la API de Render» · lenses.md security «Does a log line or an error echo personal data or a secret?» · closed · DOC-05-ASM-03 y su test
- ACT-02 · L · «sin prometer nada que la app no haga hoy» (S2) no tiene test ni línea de Gate: el test de S2 sólo comprueba que estén las secciones · card.md S2 · lenses.md interpretation «Does the product add text, routes or behavior the card does not ask for?» · declared · que cada funcionalidad nombrada exista hoy lo revisa una persona en el PR contra las capturas, que son de la app real

## Verified

- interpretation · fails (ACT-02) · S1 y S2 cubren las dos frases de L1; los miembros del recorrido de S1 están nombrados y los cubre un test
- security · fails (ACT-01) · el resto de las preguntas (rutas, HTML, query, límites) no aplica: la card no toca la API ni la app (L3)
- overdesign · meets · un README y sus imágenes; ninguna capa, interfaz ni patrón
