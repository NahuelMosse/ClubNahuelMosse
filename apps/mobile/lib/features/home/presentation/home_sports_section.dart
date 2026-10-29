import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import 'home_title.dart';

/// The «Deportes» block of the Home: its title over [child], the row of sports (or of their skeletons).
class HomeSportsSection extends StatelessWidget {
  const HomeSportsSection({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.s32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.s24),
            child: HomeTitle(AppLocalizations.of(context).homeSports),
          ),
          const SizedBox(height: Spacing.s12),
          child,
        ],
      ),
    );
  }
}
