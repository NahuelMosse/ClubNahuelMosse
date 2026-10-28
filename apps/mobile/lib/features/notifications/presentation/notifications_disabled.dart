import 'package:flutter/material.dart';
import '../../../common/button.dart';
import '../../../common/card_frame.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

const disabledTitle = 'Notificaciones desactivadas';
const disabledText =
    'Activá los avisos para que te recordemos tus reservas una hora antes.';

/// La franja de arriba cuando hay avisos pero el sistema no deja mostrarlos.
class NotificationsDisabled extends StatelessWidget {
  const NotificationsDisabled({super.key, required this.onEnable});

  final Future<bool> Function() onEnable;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CardFrame(
      clip: Clip.none,
      padding: const EdgeInsets.all(Spacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            disabledTitle,
            style: Texts.title.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: Spacing.s4),
          Text(
            disabledText,
            style: Texts.caption.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: Spacing.s16),
          PrimaryButton(label: 'ACTIVAR NOTIFICACIONES', onTap: onEnable),
        ],
      ),
    );
  }
}
