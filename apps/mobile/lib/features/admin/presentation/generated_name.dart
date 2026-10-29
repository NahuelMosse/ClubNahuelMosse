import 'package:flutter/material.dart';
import '../../../common/button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// `Card-PreviewNombre`: the name the space will have, or what is missing to build it.
class GeneratedName extends StatelessWidget {
  const GeneratedName({
    super.key,
    required this.name,
    this.computing = false,
    this.missing = '',
    this.onRetry,
  });

  final String? name;
  final bool computing;
  final String missing;

  /// If the name could not be computed, the action to request it again.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final ready = name;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.s16,
          vertical: Spacing.s16,
        ),
        decoration: BoxDecoration(
          color: p.bgSurface,
          borderRadius: BorderRadius.circular(Spacing.radiusMd),
          border: Border.all(
            color: ready == null ? p.borderControl : p.accentInk,
            width: ready == null ? 1 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              l10n.adminGeneratedName,
              textAlign: TextAlign.center,
              style: Texts.overline.copyWith(color: p.accentInk),
            ),
            const SizedBox(height: Spacing.s8),
            if (computing)
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (onRetry case final retry?) ...[
              Text(
                l10n.adminNameFailed,
                textAlign: TextAlign.center,
                style: Texts.caption.copyWith(color: p.stateDangerInk),
              ),
              TextActionButton(label: l10n.adminRetry, onTap: retry),
            ] else
              Text(
                ready ?? missing,
                textAlign: TextAlign.center,
                style: ready == null
                    ? Texts.caption.copyWith(color: p.textMuted)
                    : Texts.mono.copyWith(color: p.textPrimary),
              ),
          ],
        ),
      ),
    );
  }
}
