// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';

/// A big figure with its label, for the [AppMarker].
class MarkerCell {
  const MarkerCell({
    required this.figure,
    required this.label,
    this.highlighted = false,
  });

  final String figure;
  final String label;
  final bool highlighted;
}

/// Scoreboard of figures over a photo: dark glass with an accent border and one cell per datum.
class AppMarker extends StatelessWidget {
  const AppMarker({super.key, required this.cells});

  final List<MarkerCell> cells;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.bgScrim.withValues(alpha: 0.66),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.accentBase, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  for (var i = 0; i < cells.length; i++) ...[
                    if (i > 0)
                      Container(width: 1, height: 40, color: p.borderDefault),
                    Expanded(child: _Cell(cell: cells[i])),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.cell});

  final MarkerCell cell;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: '${cell.figure} ${cell.label.toLowerCase()}',
      container: true,
      child: ExcludeSemantics(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              cell.figure,
              style: TextStyle(
                fontFamily: 'Archivo Black',
                fontSize: 28,
                letterSpacing: -1,
                height: 1.2,
                color: cell.highlighted ? p.accentOnMedia : p.textOnMedia,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              cell.label.toUpperCase(),
              style: Texts.overline.copyWith(color: p.textOnMediaMuted),
            ),
          ],
        ),
      ),
    );
  }
}
