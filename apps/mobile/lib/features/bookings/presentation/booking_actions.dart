import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../l10n/app_localizations.dart';
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
    final l = AppLocalizations.of(context);
    return Flex(
      direction: grande ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: grande
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      children: [
        BookingAction(
          expandir: !grande,
          etiqueta: l.bookingModifyLabel(deQue),
          alTocar: alModificar,
          child: OutlineButton(
            label: l.bookingModify,
            onTap: alModificar,
            compact: true,
          ),
        ),
        const SizedBox(width: Spacing.s8, height: Spacing.s8),
        BookingAction(
          expandir: !grande,
          etiqueta: l.bookingCancelLabel(deQue),
          alTocar: alCancelar,
          child: OutlineButton(
            label: l.bookingCancel,
            onTap: alCancelar,
            danger: true,
            compact: true,
          ),
        ),
      ],
    );
  }
}
