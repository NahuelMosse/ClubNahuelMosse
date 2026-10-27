import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/boton.dart';
import '../espacios/espacio.dart';
import '../reservas/reservas.dart';
import '../reservas/tarjeta_reserva.dart';
import '../tema/tokens.dart';
import 'titulo_de_inicio.dart';

/// «Tu próxima reserva»: la tarjeta de Mis reservas, con sus dos acciones.
class ProximaReserva extends StatelessWidget {
  const ProximaReserva({
    super.key,
    required this.reserva,
    required this.catalogo,
    required this.cancelando,
    required this.alCancelar,
    required this.alModificar,
  });

  final Reserva reserva;
  final Catalogo catalogo;
  final bool cancelando;
  final VoidCallback? alCancelar;
  final VoidCallback? alModificar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Medidas.s24,
      Medidas.s24,
      Medidas.s24,
      0,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: TituloDeInicio('TU PRÓXIMA RESERVA')),
            BotonTexto(
              texto: 'VER TODAS →',
              alTocar: () => context.go('/reservas'),
            ),
          ],
        ),
        const SizedBox(height: Medidas.s12),
        TarjetaReserva(
          reserva: reserva,
          catalogo: catalogo,
          cancelable: reserva.cancelable,
          cancelando: cancelando,
          cuentaRegresiva: true,
          alCancelar: alCancelar,
          alModificar: alModificar,
        ),
      ],
    ),
  );
}
