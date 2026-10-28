// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'dates.dart';
import 'timeline_hours.dart';

/// State of an hour in the [DayTimeline].
enum SlotState { free, taken, chosen }

/// Strip of cells, one per hour, with the state of each slot of the day.
class DayTimeline extends StatelessWidget {
  const DayTimeline({super.key, required this.slots, this.from = 8});

  final List<SlotState> slots;
  final int from;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 4,
            children: [
              Text(
                'TU DÍA EN LA CANCHA',
                style: Texts.overline.copyWith(
                  fontSize: 11,
                  letterSpacing: 0.88,
                  color: p.textSecondary,
                ),
              ),
              _LegendItem(color: p.accentFree, text: 'Libre'),
              _LegendItem(color: p.stateDisabled, text: 'Ocupado'),
              _LegendItem(color: p.accentInk, text: 'Elegido'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < slots.length; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey('franja-${twoDigits(from + i)}'),
                    child: Semantics(
                      label:
                          '${twoDigits(from + i)} h ${switch (slots[i]) {
                            SlotState.free => 'libre',
                            SlotState.taken => 'ocupada',
                            SlotState.chosen => 'elegida',
                          }}',
                      child: ExcludeSemantics(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: switch (slots[i]) {
                                SlotState.free => p.accentFree,
                                SlotState.taken => p.stateDisabled,
                                SlotState.chosen => p.accentInk,
                              },
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TimelineHours(count: slots.length, from: from),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: const SizedBox(width: 8, height: 8),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: Texts.caption.copyWith(
            fontSize: 11,
            height: 14 / 11,
            color: p.textPrimary,
          ),
        ),
      ],
    );
  }
}
