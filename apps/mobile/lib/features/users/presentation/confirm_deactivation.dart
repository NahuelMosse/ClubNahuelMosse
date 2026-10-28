import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/error_dialog.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

class ConfirmDeactivation extends StatelessWidget {
  const ConfirmDeactivation({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DialogFrame(
      children: [
        IconCircle(
          icon: Icons.warning_amber_rounded,
          background: p.stateDangerMuted,
          ink: p.stateDangerInk,
        ),
        const SizedBox(height: Spacing.s12),
        Text(
          '¿Eliminar tu cuenta?',
          textAlign: TextAlign.center,
          style: Texts.h2.copyWith(color: p.textPrimary),
        ),
        const SizedBox(height: Spacing.s12),
        Text(
          'Esta acción es permanente. Se eliminarán tus datos y tus reservas '
          'vigentes.',
          textAlign: TextAlign.center,
          style: Texts.body.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: Spacing.s12),
        DangerButton(
          label: 'ELIMINAR CUENTA',
          onTap: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: Spacing.s8),
        OutlineButton(
          label: 'CANCELAR',
          onTap: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
