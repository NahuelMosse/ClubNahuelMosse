import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import 'booking_action.dart';

/// «MODIFICAR» and «CANCELAR» of a booking, side by side or one above the other if the
/// font is large.
class BookingActions extends StatelessWidget {
  const BookingActions({
    super.key,
    required this.subject,
    required this.large,
    required this.onModify,
    required this.onCancel,
  });

  /// The description of the booking for the accessible labels.
  final String subject;
  final bool large;
  final VoidCallback? onModify;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Flex(
      direction: large ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: large
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      children: [
        BookingAction(
          expand: !large,
          label: l.bookingModifyLabel(subject),
          onTap: onModify,
          child: OutlineButton(
            label: l.bookingModify,
            onTap: onModify,
            compact: true,
          ),
        ),
        const SizedBox(width: Spacing.s8, height: Spacing.s8),
        BookingAction(
          expand: !large,
          label: l.bookingCancelLabel(subject),
          onTap: onCancel,
          child: OutlineButton(
            label: l.bookingCancel,
            onTap: onCancel,
            danger: true,
            compact: true,
          ),
        ),
      ],
    );
  }
}
