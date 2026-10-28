import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';

/// `Tag`: informative label 26 high. [onPhoto] makes it solid lime, because the
/// translucent one does not contrast over a photo.
class AppLabel extends StatelessWidget {
  const AppLabel({
    super.key,
    required this.text,
    this.icon,
    this.onPhoto = false,
  });

  final String text;
  final IconData? icon;
  final bool onPhoto;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (background, ink) = onPhoto
        ? (p.accentBase, p.accentOn)
        : (p.bgSurfaceRaised, p.textSecondary);
    final symbol = icon;
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Spacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (symbol != null) ...[
            Icon(symbol, size: 14, color: ink),
            const SizedBox(width: Spacing.s4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Texts.caption.copyWith(color: ink),
            ),
          ),
        ],
      ),
    );
  }
}
