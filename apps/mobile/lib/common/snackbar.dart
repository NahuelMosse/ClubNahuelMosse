// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';

/// The prototype `Snackbar/Type=Error`: a notice that does not block the screen and closes with the X.
class ErrorSnackbar extends StatelessWidget {
  const ErrorSnackbar({
    super.key,
    required this.message,
    required this.onClose,
  });

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          Spacing.s12,
          Spacing.s4,
          Spacing.s4,
          Spacing.s4,
        ),
        decoration: BoxDecoration(
          color: Color.alphaBlend(p.stateDangerMuted, p.bgBase),
          borderRadius: BorderRadius.circular(Spacing.radiusMd),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: p.stateDangerInk,
            ),
            const SizedBox(width: Spacing.s8),
            Expanded(
              child: Text(
                message,
                style: Texts.caption.copyWith(color: p.stateDangerInk),
              ),
            ),
            IconButton(
              tooltip: AppLocalizations.of(context).commonCloseNotice,
              onPressed: onClose,
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: p.stateDangerInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
