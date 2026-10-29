import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// The filter panel title and its close button.
class FiltersHeader extends StatelessWidget {
  const FiltersHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.s24,
        Spacing.s16,
        Spacing.s16,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                l10n.adminFilters,
                style: Texts.h2.copyWith(color: p.textPrimary),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: l10n.adminClose,
            icon: const Icon(Icons.close_rounded),
            color: p.textSecondary,
          ),
        ],
      ),
    );
  }
}
