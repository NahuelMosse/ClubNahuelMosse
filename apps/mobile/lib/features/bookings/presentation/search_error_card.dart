import 'package:flutter/material.dart';
import '../../../common/button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// `Card-Error` of the prototype: the query failed and the filters stay loaded.
class SearchErrorCard extends StatelessWidget {
  const SearchErrorCard({
    super.key,
    required this.noConnection,
    required this.onBack,
    required this.onRetry,
  });

  final bool noConnection;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(Spacing.s16),
        decoration: BoxDecoration(
          color: p.stateDangerMuted,
          borderRadius: BorderRadius.circular(Spacing.radiusLg),
          border: Border.all(color: p.stateDanger),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.spaceSearchErrorOverline,
              style: Texts.overline.copyWith(color: p.stateDangerInk),
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              l.spaceSearchErrorTitle,
              style: Texts.title.copyWith(color: p.textPrimary),
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              '${noConnection ? l.spaceSearchOffline : l.spaceSearchServerDown}'
              ' ${l.spaceSearchFiltersKept}',
              style: Texts.body.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: Spacing.s12),
            Row(
              children: [
                TextActionButton(label: l.spaceSearchBack, onTap: onBack),
                const SizedBox(width: Spacing.s8),
                Expanded(
                  child: OutlineButton(
                    label: l.bookingRetry,
                    onTap: onRetry,
                    danger: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
