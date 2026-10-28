// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';

/// Who booked, with their icon.
class BookingUser extends StatelessWidget {
  const BookingUser({super.key, required this.user});

  final String user;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Icon(Icons.person_outline, size: 16, color: p.textSecondary),
        const SizedBox(width: Spacing.s8),
        Expanded(
          child: Text(user, style: Texts.body.copyWith(color: p.textPrimary)),
        ),
      ],
    );
  }
}

/// The day and the time slot of a booking, each with its icon; both go on the same line
/// and wrap to the next one if they do not fit.
class BookingDateAndTime extends StatelessWidget {
  const BookingDateAndTime({
    super.key,
    required this.date,
    required this.time,
    this.verticalGap = Spacing.s8,
    this.alignment = WrapCrossAlignment.center,
  });

  final String date;
  final String time;

  /// The space between the two lines when they do not fit together.
  final double verticalGap;
  final WrapCrossAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Wrap(
      spacing: Spacing.s16,
      runSpacing: verticalGap,
      crossAxisAlignment: alignment,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: p.textSecondary,
            ),
            const SizedBox(width: Spacing.s8),
            Flexible(
              child: Text(
                date,
                style: Texts.caption.copyWith(color: p.textSecondary),
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 18, color: p.accentInk),
            const SizedBox(width: Spacing.s8),
            Flexible(
              child: Text(
                time,
                style: Texts.bodyStrong.copyWith(color: p.accentInk),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
