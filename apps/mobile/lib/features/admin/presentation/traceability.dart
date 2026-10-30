// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/card_frame.dart';
import '../../../common/dates.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../bookings/domain/booking_status.dart';
import '../domain/booking_history_entry.dart';
import 'trace_step.dart';

/// What a step of the history shows: its title, icon, color and subtitle.
typedef _Step = (String, IconData, Color, String);

class Traceability extends StatelessWidget {
  const Traceability({super.key, required this.booking});

  final BookingHistoryEntry booking;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final b = booking;
    final second = _cancellationStep(l10n, p, b);
    final notice = _noticeStep(l10n, p, b);
    return CardFrame(
      clip: Clip.none,
      padding: const EdgeInsets.all(Spacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adminTraceTitle,
            style: Texts.overline.copyWith(color: p.textMuted),
          ),
          const SizedBox(height: Spacing.s16),
          TraceStep(
            icon: Icons.check_circle_outline_rounded,
            color: p.stateSuccessInk,
            title: l10n.adminTraceCreated,
            subtitle: l10n.adminTraceBy(b.user, _dateTime(b.createdAt)),
          ),
          if (second != null) ...[
            const SizedBox(height: Spacing.s12),
            TraceStep(
              icon: second.$2,
              color: second.$3,
              title: second.$1,
              subtitle: second.$4,
            ),
          ],
          if (notice != null) ...[
            const SizedBox(height: Spacing.s12),
            TraceStep(
              icon: notice.$2,
              color: notice.$3,
              title: notice.$1,
              subtitle: notice.$4,
            ),
          ],
        ],
      ),
    );
  }
}

_Step? _cancellationStep(
  AppLocalizations l10n,
  Palette p,
  BookingHistoryEntry b,
) {
  final at = b.cancelledAt;
  if (at == null) return null;
  if (b.status != BookingStatus.voided) {
    return (
      l10n.adminTraceCanceled,
      Icons.cancel_outlined,
      p.textSecondary,
      l10n.adminTraceBy(b.cancelledByName ?? b.user, _dateTime(at)),
    );
  }
  final who = b.cancelledByName ?? l10n.adminTraceAnAdmin;
  final reason = b.reason;
  return (
    l10n.adminTraceVoided,
    Icons.error_outline_rounded,
    p.stateDangerInk,
    reason != null && reason.trim().isNotEmpty
        ? l10n.adminTraceByReason(who, _dateTime(at), reason)
        : l10n.adminTraceBy(who, _dateTime(at)),
  );
}

_Step? _noticeStep(AppLocalizations l10n, Palette p, BookingHistoryEntry b) =>
    switch ((b.status, b.noticeDelivery, b.noticeAt)) {
      (BookingStatus.voided, 'sent', final at?) => (
        l10n.adminTraceNoticeSent,
        Icons.notifications_active_outlined,
        p.stateSuccessInk,
        _dateTime(at),
      ),
      (BookingStatus.voided, final String _, _?) => (
        l10n.adminTraceNoticeInbox,
        Icons.notifications_off_outlined,
        p.textSecondary,
        l10n.adminTracePushFailed,
      ),
      _ => null,
    };

String _dateTime(DateTime d) => '${readableDate(d)} ${shortTime(d)}';
