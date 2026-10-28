// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'button.dart';

/// `Empty-State`: icon in a circle, title and text, in place of an empty listing.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.text,
    this.action,
    this.onTap,
    this.icon = Icons.grid_view_outlined,
  });

  final String title;
  final String text;
  final String? action;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.s40),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: p.bgSurfaceRaised,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: p.textMuted),
          ),
          const SizedBox(height: Spacing.s16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Texts.title.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: Spacing.s8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Texts.caption.copyWith(color: p.textMuted),
          ),
          if (action case final label?) ...[
            const SizedBox(height: Spacing.s8),
            TextActionButton(label: label, onTap: onTap),
          ],
        ],
      ),
    );
  }
}
