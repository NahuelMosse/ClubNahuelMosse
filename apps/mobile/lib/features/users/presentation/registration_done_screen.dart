import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/result.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';

class RegistrationDoneScreen extends StatelessWidget {
  const RegistrationDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ResultScreen(
      icon: Icons.check_circle_outline_rounded,
      tone: ResultTone.success,
      title: l10n.registerDoneTitle,
      text: l10n.registerDoneText,
      primary: l10n.accountBackToSignIn,
      onPrimaryTap: () => context.go('/'),
      diameter: 100,
      iconSize: 44,
      iconGap: Spacing.s20,
      titleGap: Spacing.s20,
      actionsGap: 36,
    );
  }
}
