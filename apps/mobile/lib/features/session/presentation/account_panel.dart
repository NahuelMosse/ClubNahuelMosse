import 'package:flutter/material.dart';

import '../../../common/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../domain/profile.dart';
import '../domain/role.dart';
import 'account_header.dart';
import 'account_option.dart';

/// El panel flotante de la cuenta: la cabecera y sus accesos.
class AccountPanel extends StatelessWidget {
  const AccountPanel({
    super.key,
    required this.profile,
    required this.onNavigate,
    required this.onSignOut,
  });

  final Profile profile;
  final ValueChanged<String> onNavigate;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final isUser = profile.role == Role.user;
    return FadeIn(
      fromY: -16,
      duration: const Duration(milliseconds: 350),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Spacing.radiusLg),
          boxShadow: const [
            BoxShadow(
              color: Color(0x8C000000),
              offset: Offset(0, 14),
              blurRadius: 34,
            ),
          ],
        ),
        child: Material(
          color: p.bgSurfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Spacing.radiusLg),
            side: BorderSide(color: p.borderDefault),
          ),
          clipBehavior: Clip.antiAlias,
          // Con el teléfono apaisado o el texto grande no entra en el alto.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AccountHeader(profile: profile),
                Divider(height: 1, color: p.borderDefault),
                const SizedBox(height: Spacing.s8),
                if (isUser) ...[
                  AccountOption(
                    icon: Icons.person_outline_rounded,
                    text: l10n.accountFullProfile,
                    onTap: () => onNavigate('/perfil'),
                  ),
                  AccountOption(
                    icon: Icons.calendar_today_outlined,
                    text: l10n.accountMyBookings,
                    onTap: () => onNavigate('/reservas'),
                  ),
                ],
                AccountOption(
                  icon: Icons.logout_rounded,
                  text: l10n.accountSignOut,
                  danger: true,
                  onTap: onSignOut,
                ),
                const SizedBox(height: Spacing.s8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
