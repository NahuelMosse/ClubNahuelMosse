import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/button.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// «¿No tenés cuenta? COMENZAR», sobre la foto del inicio de sesión.
class RegisterLink extends StatelessWidget {
  const RegisterLink({super.key, required this.submitting});

  final bool submitting;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '¿No tenés cuenta?',
          style: Texts.caption.copyWith(color: p.textOnMediaMuted),
        ),
        TextActionButton(
          label: 'COMENZAR',
          icon: Icons.arrow_forward_rounded,
          overPhoto: true,
          onTap: submitting ? null : () => context.go('/registro'),
        ),
      ],
    );
  }
}
