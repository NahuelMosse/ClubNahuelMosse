# Ambigüedades — REV-08 · tests

## The ten questions

| Empty case    | not applicable: la card cambia tests, no listados
| Duplicates    | the card says: "Los dos se difirieron a CU-15 a propósito (CU-14-SUP-04) … ningún test ejercita la anulación desde el detalle de CU-14 con su tag" → REV-08-AMB-01
| Validation    | the card says: "`test_la_reserva_dura_entre_una_y_cuatro_horas` sólo prueba 5 h, y `test_la_baja_libera_el_correo_y_el_dni` nunca muestra el DNI bloqueado"
| Limits        | the card says: "a81ce1c bajó la cota de RNF-01-H06-02 de `>= 30` a `>= 25` con 28 medidas"; el pedido dice «recongelada a 28» → REV-08-AMB-02
| Permissions   | not applicable: la card no cambia permisos
| State         | not applicable: la card no agrega estados
| Error         | the card says: "sin el emulador de Auth los tests de API se saltan y la corrida sale verde"; the card does not say qué tiene que pasar entonces → REV-08-AMB-03
| Order         | not applicable
| Concurrency   | not applicable
| Trail         | the card says: "RNF-01-H04-01 lee el código Dart y el README con regex"; the card does not say con qué se reemplaza → REV-08-AMB-04; y "ningún test cuenta consultas por pedido" sin decir qué pedidos → REV-08-AMB-05

## Events

REV-08-AMB-00 · 2026-10-20 · snapshot · frozen at bad92cc
REV-08-AMB-01 · 2026-10-20 · no channel · La anulación desde el detalle del historial se dejó para el caso de uso de anular: ¿se prueba igual desde el detalle, aunque ya ande? → REV-08-ASM-01
REV-08-AMB-02 · 2026-10-20 · no channel · El control de que cada operación pide sesión exigía al menos 30 y después 25, con 28 operaciones reales: ¿tiene que exigir exactamente todas las que existen? → REV-08-ASM-02
REV-08-AMB-03 · 2026-10-20 · no channel · Si falta el servicio de autenticación de prueba, ¿la corrida tiene que fallar, o alcanza con avisar que se saltaron pruebas? → REV-08-ASM-03
REV-08-AMB-04 · 2026-10-20 · no channel · Para comprobar que la API publica todo lo que usa la app, ¿alcanza con que la app declare sus rutas en un solo lugar y sus propios tests fallen si pide otra? → REV-08-ASM-04
REV-08-AMB-05 · 2026-10-20 · no channel · ¿Qué pantallas de uso diario tienen que tener un número fijo de consultas a la base, sin importar cuántas reservas haya? → REV-08-ASM-05
