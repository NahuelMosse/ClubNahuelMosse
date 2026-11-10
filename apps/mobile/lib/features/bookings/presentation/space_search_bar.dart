import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/fixed_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';

class SpaceSearchBar extends StatelessWidget {
  const SpaceSearchBar({
    super.key,
    required this.onClear,
    required this.onSearch,
    required this.searching,
  });

  final VoidCallback? onClear;
  final VoidCallback? onSearch;
  final bool searching;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return FixedBar(
      color: p.bgSurface,
      child: Row(
        children: [
          TextActionButton(label: l.spaceSearchClear, onTap: onClear),
          const SizedBox(width: Spacing.s12),
          Expanded(
            child: PrimaryButton(
              label: l.spaceSearchRun,
              onTap: onSearch,
              loading: searching,
            ),
          ),
        ],
      ),
    );
  }
}
