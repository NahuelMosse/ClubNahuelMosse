# Ambigüedades — CU-23 · Baja de espacio deportivo

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | no aplica: se da de baja un espacio que existe (precondición)
| Duplicados    | la card no dice qué pasa si el espacio ya fue dado de baja en otra sesión → CU-23-AMB-01
| Validación    | la card no dice si se impide la baja con reservas futuras, como CU-19 hace con la sede → CU-23-AMB-02
| Error         | la card no lo dice; el enunciado exige sin conexión y servidor caído → CU-23-AMB-03
| Estado        | la card dice «la acción será permanente»; no dice si es borrado físico o baja lógica → CU-23-AMB-04
| Permisos      | la card dice: el administrador con sesión iniciada; el paso 1 dice «El usuario» → CU-23-AMB-05
| Límites       | la card no dice si se puede dar de baja el último espacio de una sede (que pasaría a CU-16 FA1) → CU-23-AMB-06
| Orden         | no aplica
| Concurrencia  | la card no dice qué pasa si alguien reserva el espacio mientras se confirma la baja → CU-23-AMB-02
| Rastro        | la card no dice que se estampe cuándo y quién dio de baja el espacio → CU-23-AMB-07

## Eventos
CU-23-AMB-01 · 2026-09-27 · abierta · si el espacio ya fue dado de baja en otra sesión, ¿«Esto cambió mientras tanto»?
CU-23-AMB-02 · 2026-09-27 · abierta · con reservas futuras en el espacio, ¿se impide la baja (como CU-19) o se anulan y se avisa con CU-24.2?
CU-23-AMB-03 · 2026-09-27 · abierta · sin conexión o con el servidor caído, ¿overlays compartidos y el espacio queda como estaba?
CU-23-AMB-04 · 2026-09-27 · abierta · ¿baja lógica (el historial sigue mostrando el espacio) o borrado físico?
CU-23-AMB-05 · 2026-09-27 · abierta · ¿sólo el administrador puede dar de baja? (el paso 1 dice «el usuario»)
CU-23-AMB-06 · 2026-09-27 · abierta · ¿se puede dar de baja el último espacio de una sede?
CU-23-AMB-07 · 2026-09-27 · abierta · ¿se guarda fecha de baja y qué administrador la hizo?
CU-23-AMB-00 · 2026-09-27 · snapshot · congelado en e52f6f4
