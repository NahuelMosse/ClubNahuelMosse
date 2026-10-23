# Red review · REV-05 · Básquet en el catálogo

Fuente: `card.snapshot.md` (escenarios H19-01 a H19-04); del plan, `## Assumptions` y `## Perimeter`.
Tests: `apps/api/tests/escenarios/test_basquet.py` (4) y `apps/mobile/test/basquet_test.dart` (2). Los 6 fallan
por la razón correcta (logs: catálogo sin `Basquet`, alta 422 por `deporte`, `KeyError 'tipo'`, `KeyError 'id'`,
ícono genérico `sports_rounded`, foto `portada_4` igual a la de Fútbol).

## Hallazgos que cambian si un escenario queda probado

| # | Escenario / test | Qué falta | Gravedad |
|---|---|---|---|
| 1 | H19-04 · `la foto de Básquet no es la de una cancha de fútbol` (@assumption:REV-05-ASM-02) | ASM-02 dice «la portada 1 del club, que no es de ningún otro deporte». El test sólo pide `!= fotoDeDeporte('Futbol')`: devolver `portada_2` (la de Tenis/Pádel/Vóley) o `portada_3` (Golf) lo pone en verde y contradice la ASM. Hockey también comparte `portada_4`. El test no prueba la suposición que dice probar. | M |
| 2 | H19-04 · «la app muestra Básquet con su ícono y su foto» | Los dos tests llaman a las funciones `iconoDeDeporte` / `fotoDeDeporte`; ninguno ve Básquet en una pantalla (chip del filtro de la sede, tarjeta de cancha, deportes del Home) ni que `Catalogo` lea el deporte nuevo con `3X3`. El escenario queda probado a nivel de mapeo, no de lo que ve el socio. | L |
| 3 | ASM-03 (Básquet va después de Vóley) | No hay test con `@assumption:REV-05-ASM-03`; el test del catálogo busca con `next(...)`, así que el orden no se afirma. Una suposición sin test que la etiquete. | L |

## Sin hallazgo

- H19-01: afirma el deporte entero (clave, nombre, tipos B5 y 3X3) contra la API real con sesión de socio.
- H19-02: alta 201, `deporte` y nombre `…_Basquet_B5_1`; borde de tipo ajeno (F5) con 422 y el mensaje existente del dominio (`dominio/espacios.py:210`).
- H19-03: filtro por `deporte=Basquet` sobre el parámetro que ya expone `GET /espacios`; la ausencia de la cancha de Fútbol se afirma en la misma respuesta que la presencia de la de Básquet, sin reintento.
- Formas de entrada (faltante, null, tipo erróneo) y dinero: no aplican; la card no toca validación ni precios.
