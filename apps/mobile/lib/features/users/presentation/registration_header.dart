import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import 'registration_notice.dart';

/// Lo que va arriba del formulario: el aviso que corresponda, el título y su bajada.
class RegistrationHeader extends StatelessWidget {
  const RegistrationHeader({
    super.key,
    required this.alreadyExists,
    required this.notice,
  });

  final bool alreadyExists;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final notice = this.notice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (alreadyExists) ...[
          RegistrationNotice(text: l10n.registerAlreadyExists),
          TextActionButton(
            label: l10n.loginSignIn,
            onTap: () => context.go('/'),
          ),
          const SizedBox(height: Spacing.s16),
        ] else if (notice != null) ...[
          RegistrationNotice(text: notice),
          const SizedBox(height: Spacing.s16),
        ],
        Text(
          l10n.registerHeading,
          style: Texts.h1.copyWith(color: p.textPrimary),
        ),
        const SizedBox(height: Spacing.s4),
        Text(
          l10n.registerAllRequired,
          style: Texts.caption.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: Spacing.s16),
      ],
    );
  }
}
