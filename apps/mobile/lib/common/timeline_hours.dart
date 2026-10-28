// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'dates.dart';

/// The hours written below the [DayTimeline], one every four cells.
class TimelineHours extends StatelessWidget {
  const TimelineHours({super.key, required this.count, required this.from});

  final int count;
  final int from;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final mark = Texts.mono.copyWith(fontSize: 11, color: p.textPrimary);
    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: i % 4 == 0
                    ? Text(
                        twoDigits(from + i),
                        style: mark,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                      )
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
