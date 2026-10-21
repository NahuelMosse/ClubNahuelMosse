# Ambigüedades — REV-01 · seguridad de la API

## The ten questions

| Empty case    | not applicable: la card no agrega listados ni pantallas que puedan quedar vacías
| Duplicates    | the card says: "`/registro` con un correo ajeno → 409 «Este correo ya está registrado»" y "`PUT /yo` con DNI ajenos … con el 409 «Este DNI ya está registrado»"; CU-03 FA2 pide ese mensaje → REV-01-AMB-01
| Validation    | the card says: "`POST /reservas` con `horas = 10**12` → 500 … Un NUL en nombre, sede, motivo, token o correo → 500"; the card does not say qué largo máximo tiene cada campo ni con qué mensaje se rechaza → REV-01-AMB-02
| Limits        | the card says: "30 `POST /recuperacion` en 0,9 s → 30 × 202; 20 `POST /registro` en 0,4 s → 20 × 422 sin 429"; the card does not say cuántos pedidos se permiten ni en qué ventana → REV-01-AMB-03
| Permissions   | the card says: "`PUT /dispositivos` con el token FCM de otro reasigna el dispositivo" y "una API interna con datos personales expone su mapa"; the card does not say qué pasa con un teléfono compartido ni si la documentación tiene que verse en la nube → REV-01-AMB-04, REV-01-AMB-05
| State         | not applicable: la card no agrega estados; el dispositivo sigue con activo/inactivo y ninguna transición nueva
| Error         | the card says: "contra un SMTP falso con certificado autofirmado … el cliente aceptó el TLS"; the card does not say qué ve la persona cuando el correo no sale, ni qué reemplaza a `/docs` como chequeo de salud → REV-01-AMB-06, REV-01-AMB-07
| Order         | not applicable: la card no ordena nada
| Concurrency   | the card does not say cómo cuentan para el límite los pedidos simultáneos → REV-01-AMB-08
| Trail         | the card says: "Ningún test manda un secreto (contraseña, token, código de recuperación) para verificar que no llegue al log"; the card does not say qué se registra de un pedido frenado o de un Host ajeno → REV-01-AMB-09; y del emulador: "la API no se niega a arrancar si aparece junto a credenciales reales" → REV-01-AMB-10

## Events

REV-01-AMB-00 · 2026-10-20 · snapshot · frozen at c16d271
REV-01-AMB-01 · 2026-10-20 · no channel · ¿Quien se registra con un correo o un DNI que ya tiene cuenta, o pone en su perfil un DNI ajeno, tiene que seguir viendo «ya está registrado», aunque eso deje averiguar quién es socio? → REV-01-ASM-01 · leaves without effect: «no sirve para saber quién tiene cuenta» (el caso aislado sigue respondiendo; lo que se frena es la consulta en serie)
REV-01-AMB-02 · 2026-10-20 · no channel · ¿Qué largo máximo acepta cada dato de texto (correo, contraseña, nombre de sede, motivo, búsqueda, token) y qué mensaje ve quien se pasa o pega un carácter invisible? → REV-01-ASM-02
REV-01-AMB-03 · 2026-10-20 · no channel · ¿Cuántos registros y pedidos de recuperación seguidos se permiten desde un mismo lugar, y cuánto hay que esperar después? → REV-01-ASM-03
REV-01-AMB-04 · 2026-10-20 · no channel · Si dos personas usan el mismo teléfono sin cerrar sesión, ¿los avisos tienen que pasar a la segunda o seguir yendo a la primera? → REV-01-ASM-04 · leaves without effect: nada de la card; deja sin avisos a la segunda persona de un teléfono compartido sin cierre de sesión
REV-01-AMB-05 · 2026-10-20 · no channel · El enunciado pide la API documentada con Swagger/OpenAPI: ¿la página interactiva tiene que estar abierta en la nube, o alcanza con el contrato en el repositorio y la página en el entorno local? → REV-01-ASM-05 · leaves without effect: nada del enunciado; la documentación interactiva queda a una variable de distancia en la nube
REV-01-AMB-06 · 2026-10-20 · no channel · Si el servidor de correo no presenta un certificado válido, ¿qué ve quien pidió recuperar su contraseña? → REV-01-ASM-06
REV-01-AMB-07 · 2026-10-20 · no channel · Al cerrar la documentación en la nube, ¿qué dirección usa el proveedor para saber que la API está viva? → REV-01-ASM-07
REV-01-AMB-08 · 2026-10-20 · no channel · ¿Cómo cuentan para el límite los pedidos que llegan exactamente al mismo tiempo? → REV-01-ASM-08
REV-01-AMB-09 · 2026-10-20 · no channel · ¿Qué queda anotado cuando se frena un pedido por exceso o por venir de un dominio ajeno? → REV-01-ASM-09
REV-01-AMB-10 · 2026-10-20 · no channel · ¿En qué condiciones tiene que negarse a arrancar la API cuando ve configurado el emulador de autenticación? → REV-01-ASM-10
REV-01-TESTS · 2026-10-20 · frozen at 2a31441
