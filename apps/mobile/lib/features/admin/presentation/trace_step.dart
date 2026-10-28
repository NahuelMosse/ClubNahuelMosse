import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

class TraceStep extends StatelessWidget {
  const TraceStep({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '$title, $subtitle',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: Spacing.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Texts.bodyStrong.copyWith(color: p.textPrimary),
                ),
                const SizedBox(height: Spacing.s4),
                Text(
                  subtitle,
                  style: Texts.caption.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
