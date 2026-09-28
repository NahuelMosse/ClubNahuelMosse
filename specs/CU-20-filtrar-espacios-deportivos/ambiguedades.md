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
CU-20-AMB-04 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-20-AMB-04 · 2026-09-27 · resuelta · cada cancha es un espacio; deporte y tipo salen de un catálogo fijo; el nombre lleva la altura, sin tildes ni espacios; el número no se reutiliza; el nombre no cambia si se edita la sede; el alta pide techada o al aire libre e iluminación (decisión 8)
CU-20-AMB-09 · 2026-09-28 · abierta · ¿tocar el chip del deporte que ya está elegido lo quita, o sólo se cambia de deporte?
CU-20-AMB-10 · 2026-09-28 · abierta · el prototipo de golf dice «2 ESPACIOS · GOLF» y el resto «CANCHAS»: ¿el contador cambia de palabra según el deporte?
CU-20-AMB-01 · 2026-09-28 · vencida → CU-20-SUP-01 · los chips salen de las canchas activas de la sede: sólo aparecen los deportes y tipos que tienen al menos una, así que ningún filtro deja la lista vacía
CU-20-AMB-02 · 2026-09-28 · vencida → CU-20-SUP-02 · el filtro vive mientras el usuario sigue en la sede (y en los horarios que abre desde ahí); al salir al listado de sedes y volver a entrar, arranca sin filtro
CU-20-AMB-03 · 2026-09-28 · vencida → CU-20-SUP-03 · el filtro es de la pantalla de sede del usuario; el panel del administrador no filtra en esta card
CU-20-AMB-05 · 2026-09-28 · vencida → CU-20-SUP-04 · deportes y tipos en el orden del catálogo (CU-21-SUP-04); las canchas filtradas por deporte, tipo y número (CU-16-SUP-04)
CU-20-AMB-06 · 2026-09-28 · vencida → CU-20-SUP-05 · la sede abre con todos los deportes, como el prototipo (decisión 12): «N CANCHAS · TODOS LOS DEPORTES», sin chip elegido
CU-20-AMB-07 · 2026-09-28 · vencida → CU-20-SUP-06 · esta card filtra dentro de una sede; el listado de espacios de todas las sedes filtrable por tipo que pide el enunciado (RF 5) es el de CU-13
CU-20-AMB-08 · 2026-09-28 · vencida → CU-20-SUP-07 · cada filtro pide a la API las canchas de la sede con ese deporte y tipo, como piden FA4 y FA5; si falla, el aviso de conexión o de servidor y el listado y los chips quedan como estaban
CU-20-AMB-09 · 2026-09-28 · vencida → CU-20-SUP-08 · tocar el deporte elegido lo quita y vuelve a todos los deportes; «Todos» quita el tipo sin cambiar el deporte (FA2)
CU-20-AMB-10 · 2026-09-28 · vencida → CU-20-SUP-09 · el contador dice siempre «canchas» (o «cancha»), para cualquier deporte
CU-20-TESTS · 2026-09-28 · congelados en 6f7f4d3 · 8 escenarios de pantalla en rojo porque la sede no tiene filtros ni el contador «N CANCHAS · TODOS LOS DEPORTES»; H04-01 nace en verde: la sede sin canchas ya no mostraba filtros desde CU-16
