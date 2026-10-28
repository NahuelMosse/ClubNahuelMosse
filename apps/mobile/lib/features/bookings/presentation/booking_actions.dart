import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../theme/tokens.dart';
import 'booking_action.dart';

/// MODIFICAR y CANCELAR de una reserva, lado a lado o uno sobre otro si la letra es grande.
class BookingActions extends StatelessWidget {
  const BookingActions({
    super.key,
    required this.deQue,
    required this.grande,
    required this.alModificar,
    required this.alCancelar,
  });

  /// La descripción de la reserva para las etiquetas accesibles.
  final String deQue;
  final bool grande;
  final VoidCallback? alModificar;
  final VoidCallback? alCancelar;

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: grande ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: grande
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      children: [
        BookingAction(
          expandir: !grande,
          etiqueta: 'Modificar la reserva de $deQue',
          alTocar: alModificar,
          child: OutlineButton(
            label: 'MODIFICAR',
            onTap: alModificar,
            compact: true,
          ),
        ),
        const SizedBox(width: Spacing.s8, height: Spacing.s8),
        BookingAction(
          expandir: !grande,
          etiqueta: 'Cancelar la reserva de $deQue',
          alTocar: alCancelar,
          child: OutlineButton(
            label: 'CANCELAR',
            onTap: alCancelar,
            danger: true,
            compact: true,
          ),
        ),
      ],
    );
  }
}
