import 'package:flutter/material.dart';

import '../../../common/dates.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/search_rules.dart';
import 'selectable_frame.dart';

/// The next seven days from today, in a row that slides.
class DateStrip extends StatelessWidget {
  const DateStrip({
    super.key,
    required this.today,
    required this.chosen,
    required this.onSelect,
  });

  final DateTime today;
  final DateTime? chosen;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < daysInView; i++) ...[
            if (i > 0) const SizedBox(width: Spacing.s8),
            Builder(
              builder: (context) {
                final day = DateTime.utc(
                  today.year,
                  today.month,
                  today.day + i,
                );
                final isSelected = day == chosen;
                final ink = isSelected ? p.accentOn : p.textPrimary;
                return ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 56,
                    minHeight: 64,
                  ),
                  child: SelectableFrame(
                    label: '${weekdayName(day)} ${day.day}',
                    selected: isSelected,
                    onTap: () => onSelect(day),
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.s8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            weekdayAbbreviation(day),
                            style: Texts.overline.copyWith(
                              color: isSelected ? p.accentOn : p.textMuted,
                            ),
                          ),
                          Text(
                            '${day.day}',
                            style: Texts.h2.copyWith(color: ink),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
