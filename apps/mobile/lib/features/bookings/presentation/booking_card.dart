// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/clock.dart';
import '../../../common/dates.dart';
import '../../../common/die_cut.dart';
import '../../../common/in_progress.dart';
import '../../../common/price_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../spaces/domain/space.dart';
import '../domain/booking.dart';
import '../domain/booking_status.dart';
import 'booking_actions.dart';
import 'booking_detail.dart';
import 'booking_header.dart';
import 'booking_price_and_status.dart';
import 'booking_status_text.dart';

/// `Card-Reserva`: sport, venue and address, price and status on top; the space, the date
/// and the time below, with the reason if it was cancelled or voided.
class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    required this.catalog,
    this.highlighted = false,
    this.cancelable = false,
    this.cancelling = false,
    this.countdown = false,
    this.onCancel,
    this.onModify,
  });

  final Booking booking;
  final Catalog catalog;

  /// Adds «HOY», «MAÑANA» or «FALTAN N DÍAS» to an active booking.
  final bool countdown;

  /// Comes from a notice: it is marked with the accent border.
  final bool highlighted;

  /// Shows «CANCELAR»: an upcoming one that has not started yet.
  final bool cancelable;

  /// The cancellation of this booking is on its way.
  final bool cancelling;

  /// `null` disables «CANCELAR» (another cancellation is on its way).
  final VoidCallback? onCancel;

  /// `null` disables «MODIFICAR».
  final VoidCallback? onModify;

  String get _schedule => scheduleOf(booking);

  String? _reason(AppLocalizations l) => switch (booking.status) {
    BookingStatus.canceled => switch (booking.reason) {
      final m? when m.trim().isNotEmpty => l.bookingCanceledByYouWithReason(m),
      _ => l.bookingCanceledByYou,
    },
    BookingStatus.voided => switch (booking.reason) {
      final m? when m.trim().isNotEmpty => l.bookingVoidedByAdminWithReason(m),
      _ => l.bookingVoidedByAdmin,
    },
    _ => null,
  };

  /// The club's calendar days left before the start, without looking at the time.
  String? _countdown(AppLocalizations l) {
    if (!countdown || booking.status != BookingStatus.active) {
      return null;
    }
    final today = clubNow();
    final i = booking.startsAt;
    final days = DateTime(
      i.year,
      i.month,
      i.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
    return switch (days) {
      <= 0 => l.bookingToday,
      1 => l.bookingTomorrow,
      _ => l.bookingInDays(days),
    };
  }

  /// The card is read whole as one piece of data; «MODIFICAR» and «CANCELAR» stay
  /// outside, as buttons of their own.
  String _label(AppLocalizations l, String? reason, String? account) {
    final r = booking;
    return [
      catalog.shortKind(r.sport, r.kind),
      '${r.venue}, ${r.address}',
      bookingStatusText(l, r.status).toLowerCase(),
      longDate(r.startsAt),
      _schedule,
      l.bookingSpokenPrice(formatPesos(r.total).replaceFirst('\$ ', '')),
      r.space,
      ?reason,
      ?account?.toLowerCase(),
    ].join(', ');
  }

  Widget _data(AppLocalizations l, Palette p, bool large) {
    final r = booking;
    final reason = _reason(l);
    final account = _countdown(l);
    return Semantics(
      container: true,
      selected: highlighted,
      excludeSemantics: true,
      label: _label(l, reason, account),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BookingHeader(booking: r, catalog: catalog, large: large),
          if (large)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.s16,
                0,
                Spacing.s16,
                Spacing.s16,
              ),
              child: BookingPriceAndStatus(booking: r, large: large),
            ),
          const DieCut(),
          BookingDetail(booking: r, account: account, reason: reason),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final r = booking;
    final active = r.status == BookingStatus.active;
    final large = MediaQuery.textScalerOf(context).scale(10) > 13;
    final subject =
        '${catalog.shortKind(r.sport, r.kind)}, '
        '${shortDay(r.startsAt)}, $_schedule';
    final data = _data(l, p, large);
    final border = highlighted ? 2.0 : 1.0;
    return Container(
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        borderRadius: BorderRadius.circular(Spacing.radiusLg),
        border: Border.all(
          color: highlighted ? p.borderFocus : p.borderDefault,
          width: border,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Spacing.radiusLg - border),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                data,
                if (cancelable)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.s16,
                      0,
                      Spacing.s16,
                      Spacing.s16,
                    ),
                    child: cancelling
                        ? InProgress(l.bookingCanceling)
                        : BookingActions(
                            subject: subject,
                            large: large,
                            onModify: onModify,
                            onCancel: onCancel,
                          ),
                  ),
              ],
            ),
            if (active)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: ColoredBox(
                  key: const ValueKey('borde-reserva-activa'),
                  color: p.accentBase,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// «21:00 – 22:00».
String scheduleOf(Booking r) => timeRange(r.startsAt, r.endsAt);
