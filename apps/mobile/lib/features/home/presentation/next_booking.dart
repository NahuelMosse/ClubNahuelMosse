import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/button.dart';
import '../../../theme/tokens.dart';
import '../../bookings/domain/booking.dart';
import '../../bookings/presentation/booking_card.dart';
import '../../spaces/domain/space.dart';
import 'home_title.dart';

/// «Tu próxima reserva»: la tarjeta de Mis reservas, con sus dos acciones.
class NextBooking extends StatelessWidget {
  const NextBooking({
    super.key,
    required this.reserva,
    required this.catalogo,
    required this.cancelando,
    required this.alCancelar,
    required this.alModificar,
  });

  final Booking reserva;
  final Catalog catalogo;
  final bool cancelando;
  final VoidCallback? alCancelar;
  final VoidCallback? alModificar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Spacing.s24,
      Spacing.s24,
      Spacing.s24,
      0,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: HomeTitle('TU PRÓXIMA RESERVA')),
            TextActionButton(
              label: 'VER TODAS →',
              onTap: () => context.go('/reservas'),
            ),
          ],
        ),
        const SizedBox(height: Spacing.s12),
        BookingCard(
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
