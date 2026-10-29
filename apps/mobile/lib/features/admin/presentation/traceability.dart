// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/card_frame.dart';
import '../../../common/dates.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../bookings/domain/booking_status.dart';
import '../domain/booking_history_entry.dart';
import 'trace_step.dart';

class Traceability extends StatelessWidget {
  const Traceability({super.key, required this.booking});

  final BookingHistoryEntry booking;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final b = booking;
    final reason = b.reason;
    final second = switch (b.cancelledAt) {
      null => null,
      final at => switch (b.status) {
        BookingStatus.voided => (
          'Anulada por el administrador',
          Icons.error_outline_rounded,
          p.stateDangerInk,
          'Por ${b.cancelledByName ?? 'un administrador'} · '
              '${_dateTime(at)}'
              '${reason != null && reason.trim().isNotEmpty ? ' · $reason' : ''}',
        ),
        _ => (
          'Cancelada por el usuario',
          Icons.cancel_outlined,
          p.textSecondary,
          'Por ${b.cancelledByName ?? b.user} · ${_dateTime(at)}',
        ),
      },
    };
    final notice = switch ((b.status, b.noticeDelivery, b.noticeAt)) {
      (BookingStatus.voided, 'sent', final at?) => (
        'Notificación enviada al usuario',
        Icons.notifications_active_outlined,
        p.stateSuccessInk,
        _dateTime(at),
      ),
      (BookingStatus.voided, final String _, _?) => (
        'Aviso en el centro del usuario',
        Icons.notifications_off_outlined,
        p.textSecondary,
        'El push no salió',
      ),
      _ => null,
    };
    return CardFrame(
      clip: Clip.none,
      padding: const EdgeInsets.all(Spacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRAZABILIDAD',
            style: Texts.overline.copyWith(color: p.textMuted),
          ),
          const SizedBox(height: Spacing.s16),
          TraceStep(
            icon: Icons.check_circle_outline_rounded,
            color: p.stateSuccessInk,
            title: 'Reserva creada',
            subtitle: 'Por ${b.user} · ${_dateTime(b.createdAt)}',
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

String _dateTime(DateTime d) => '${readableDate(d)} ${shortTime(d)}';
