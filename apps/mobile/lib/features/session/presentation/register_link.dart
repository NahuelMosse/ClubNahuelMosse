import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// «¿No tenés cuenta? COMENZAR», sobre la foto del inicio de sesión.
class RegisterLink extends StatelessWidget {
  const RegisterLink({super.key, required this.submitting});

  final bool submitting;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          l10n.loginNoAccount,
          style: Texts.caption.copyWith(color: p.textOnMediaMuted),
        ),
        TextActionButton(
          label: l10n.loginStart,
          icon: Icons.arrow_forward_rounded,
          overPhoto: true,
          onTap: submitting ? null : () => context.go('/registro'),
        ),
      ],
    );
  }
}
