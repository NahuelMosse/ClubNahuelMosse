# Ambigüedades — CU-20 · Filtrar espacios deportivos

Doble lectura (CU asignado al alumno): dos lecturas independientes que no se vieron entre sí, más
la propia. Las dos lecturas coincidieron en los seis flujos y en los siete escenarios mínimos.
Divergencias: una marcó como caso vacío «hay canchas pero ninguna coincide con el filtro»; la otra
lo descartó porque los chips salen de las canchas que existen. Ninguna de las dos vio la
contradicción del paso 1 con el prototipo ni la de FA4 con el paso 3; salieron de la lectura
propia contra Figma.

## Las diez preguntas
| Caso vacío    | la card dice: «El sistema no muestra los chips de filtro y avisa que la sede no tiene canchas disponibles» (FA3); no dice si puede existir un chip cuyo filtro deje la lista vacía → CU-20-AMB-01
| Duplicados    | no aplica: filtro de solo lectura, no crea entidades
| Validación    | no aplica: el usuario sólo toca chips, no hay texto libre
| Error         | la card dice: FA4 alerta de conexión y FA5 error de servidor, en ambos «El listado no cambia»
| Estado        | la card dice: «el filtro se mantiene mientras el usuario siga en la sede»; no dice si se conserva al salir y volver a entrar → CU-20-AMB-02
| Permisos      | la card dice: «El usuario debe estar autenticado»; no dice si el administrador ve también canchas inactivas → CU-20-AMB-03
| Límites       | la card no dice de dónde salen las variantes de cada deporte ni si son un catálogo fijo → CU-20-AMB-04
| Orden         | la card no dice el orden de los chips ni el del listado filtrado → CU-20-AMB-05
| Concurrencia  | no aplica: la card dice «No se modifica ningún dato: la operación es de solo lectura»
| Rastro        | no aplica: no se estampa nada en una consulta

## Eventos
CU-20-AMB-01 · 2026-09-27 · abierta · ¿los chips se derivan sólo de las canchas activas de la sede, de modo que ningún filtro deja la lista vacía?
CU-20-AMB-02 · 2026-09-27 · abierta · al salir de la sede y volver, ¿el filtro se reinicia?
CU-20-AMB-03 · 2026-09-27 · abierta · ¿el administrador filtra sobre las mismas canchas que el usuario o también ve las dadas de baja?
CU-20-AMB-04 · 2026-09-27 · abierta · ¿deporte y variante son dos campos del espacio (Fútbol · F5) con un catálogo fijo, o el tipo del enunciado es uno solo? ¿quién define el catálogo?
CU-20-AMB-05 · 2026-09-27 · abierta · ¿en qué orden van los chips de deporte, los de variante y las canchas filtradas?
CU-20-AMB-06 · 2026-09-27 · abierta · al abrir la sede, ¿viene elegido el primer deporte (CU) o «todos los deportes» (prototipo de Ramos Mejía)?
CU-20-AMB-07 · 2026-09-27 · abierta · ¿hace falta además un listado de espacios de todas las sedes, filtrable por tipo, como pide el enunciado RF 5, o alcanza con filtrar dentro de cada sede?
CU-20-AMB-08 · 2026-09-27 · abierta · ¿filtrar consulta al servidor en cada toque (FA4, FA5) o filtra en el dispositivo lo que ya se cargó?
CU-20-AMB-00 · 2026-09-27 · snapshot · congelado en 50b3637
