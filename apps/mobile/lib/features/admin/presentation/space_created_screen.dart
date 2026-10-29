// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/result.dart';
import '../../../l10n/app_localizations.dart';
import '../../spaces/domain/space.dart';

/// The creation success: the name of the saved space, and back to the list or create another.
class SpaceCreatedScreen extends StatelessWidget {
  const SpaceCreatedScreen({super.key, required this.space});

  final Space space;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ResultScreen(
      icon: Icons.check_circle_outline_rounded,
      tone: ResultTone.success,
      title: l10n.adminSpaceCreatedTitle,
      text: l10n.adminSpaceCreatedText,
      detail: space.name,
      primary: l10n.adminGoToList,
      onPrimaryTap: () => context.go('/admin/espacios'),
      secondary: l10n.adminCreateAnother,
      onSecondaryTap: () => context.go('/admin/espacios/nuevo'),
    );
  }
}
