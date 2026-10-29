// kit-shape: the widget and its State are a single Flutter piece
import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/dates.dart';
import '../../../common/error_dialog.dart';
import '../../../common/text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/booking_history_entry.dart';
import 'booking_to_void_details.dart';
import 'reason_field.dart';

/// The maximum length of a voiding reason: the same the API accepts.
const reasonMaxLength = 500;

/// The «¿Anular esta reserva?» confirmation: the data of [booking] and the reason.
/// Returns the typed reason (trimmed) if confirmed, or `null` if VOLVER was chosen.
Future<String?> askVoidReason(
  BuildContext context,
  BookingHistoryEntry booking,
) => showDialog<String>(
  context: context,
  barrierColor: context.palette.bgScrim,
  builder: (context) => _VoidDialog(booking: booking),
);

class _VoidDialog extends StatefulWidget {
  const _VoidDialog({required this.booking});

  final BookingHistoryEntry booking;

  @override
  State<_VoidDialog> createState() => _VoidDialogState();
}

class _VoidDialogState extends State<_VoidDialog> {
  final _reason = TextEditingController();
  bool _missingReason = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      setState(() => _missingReason = true);
      return;
    }
    Navigator.of(context).pop(reason);
  }

  String get _schedule =>
      timeRange(widget.booking.startsAt, widget.booking.endsAt);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return DialogFrame(
      maxWidth: 360,
      children: [
        IconCircle(
          icon: Icons.warning_amber_rounded,
          background: p.stateDangerMuted,
          ink: p.stateDangerInk,
        ),
        const SizedBox(height: Spacing.s12),
        Semantics(
          header: true,
          child: Text(
            l10n.adminVoidDialogTitle,
            textAlign: TextAlign.center,
            style: Texts.h2.copyWith(color: p.textPrimary),
          ),
        ),
        const SizedBox(height: Spacing.s16),
        BookingToVoidDetails(booking: widget.booking, schedule: _schedule),
        const SizedBox(height: Spacing.s16),
        ExcludeSemantics(
          child: Text(
            l10n.adminVoidReasonLabel,
            style: Texts.overline.copyWith(color: p.textSecondary),
          ),
        ),
        const SizedBox(height: Spacing.s8),
        ReasonField(
          controller: _reason,
          maxLength: reasonMaxLength,
          missingReason: _missingReason,
          onChanged: (_) {
            if (_missingReason) setState(() => _missingReason = false);
          },
        ),
        if (_missingReason) ...[
          const SizedBox(height: Spacing.s8),
          FieldMessage(l10n.adminVoidReasonRequired),
        ],
        const SizedBox(height: Spacing.s16),
        DangerButton(label: l10n.adminVoidConfirm, onTap: _confirm),
        const SizedBox(height: Spacing.s8),
        OutlineButton(
          label: l10n.adminBackUpper,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
