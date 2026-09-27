# Ambigüedades — CU-21 · Alta de espacio deportivo

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | la card dice: la precondición exige «al menos una sede cargada»; no dice qué ve el administrador si no hay ninguna → CU-21-AMB-01
| Duplicados    | la card dice: «Ya existe un espacio deportivo con ese nombre en la sede seleccionada» y recalcula el número (FA1)
| Validación    | la card dice: sede, deporte, tipo y precio obligatorios (FA2) y «validación numérica» del precio; no dice si el precio puede ser cero → CU-21-AMB-02
| Error         | la card dice: FA3 «No se pudo guardar el espacio deportivo. Verifique su conexión e intente nuevamente», conserva los datos
| Estado        | la card dice: el espacio nace «con estado activo»
| Permisos      | la card dice: administrador autenticado con permisos para gestionar espacios
| Límites       | la card no dice si los números se reutilizan después de una baja ni cuántos espacios admite una sede → CU-21-AMB-03
| Orden         | la card no dice en qué orden aparece el espacio nuevo en los listados → CU-21-AMB-04
| Concurrencia  | la card dice: FA1 recalcula el número si el nombre ya existe al guardar
| Rastro        | la card no dice que se estampe cuándo y qué administrador creó el espacio → CU-21-AMB-05

## Eventos
CU-21-AMB-01 · 2026-09-27 · abierta · sin sedes cargadas, ¿el botón «+ Alta espacio» se deshabilita o se muestra un aviso?
CU-21-AMB-02 · 2026-09-27 · abierta · ¿el precio tiene que ser mayor a cero y en pesos enteros?
CU-21-AMB-03 · 2026-09-27 · abierta · ¿el número se reutiliza después de una baja (CU-23) o siempre avanza? ¿hay tope de espacios por sede?
CU-21-AMB-04 · 2026-09-27 · abierta · ¿en qué orden se listan los espacios en el panel?
CU-21-AMB-05 · 2026-09-27 · abierta · ¿se guarda fecha de alta y qué administrador lo creó?
CU-21-AMB-06 · 2026-09-27 · abierta · ¿qué formato de nombre manda: con altura como el enunciado y el prototipo, o sin altura como el CU? ¿cómo se normalizan espacios y tildes («Ramos Mejía» → «RamosMejia»)?
CU-21-AMB-07 · 2026-09-27 · abierta · ¿el alta pide también techada o al aire libre, iluminación y descripción, que CU-16 y el prototipo muestran por cancha?
CU-21-AMB-08 · 2026-09-27 · abierta · ¿cuál es el catálogo cerrado de deportes y tipos, y quién lo mantiene? (ver CU-13-AMB-09 y CU-20-AMB-04)
CU-21-AMB-00 · 2026-09-27 · snapshot · congelado en ac68af4
