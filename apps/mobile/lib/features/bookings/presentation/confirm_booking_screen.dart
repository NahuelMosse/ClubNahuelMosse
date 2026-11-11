// kit-shape: a screen or error family kept with its private parts.
// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/dates.dart';
import '../../../common/error_dialog.dart';
import '../../../common/pending_booking.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../../spaces/presentation/space_texts.dart';
import '../data/api_errors.dart';
import '../domain/availability_exceptions.dart';
import '../domain/booking_choice.dart';
import '../domain/booking_exceptions.dart';
import 'booking_choice_card.dart';
import 'bookings.dart';
import 'confirmation_skeleton.dart';
import 'detail_row.dart';

/// What the confirmation returns to the times when it closes: if the time was taken, the
/// grid is read again.
enum ConfirmResult { taken }

/// «Confirmá tu reserva»: the court, the date, the time and the total that were chosen,
/// and «CONFIRMAR RESERVA», which saves it.
class ConfirmBookingScreen extends StatefulWidget {
  const ConfirmBookingScreen({
    super.key,
    required this.choice,
    required this.bookings,
    required this.pending,
    required this.session,
  });

  final BookingChoice choice;
  final Bookings bookings;
  final PendingBooking<BookingChoice> pending;
  final Session session;

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  bool _sending = false;

  /// Goes back to the times as they were left. With nothing below (it arrived after
  /// signing in again), to the times of that court if another must be chosen, or to the
  /// venue.
  void _goBack([ConfirmResult? result]) {
    if (_sending) return;
    final e = widget.choice;
    if (context.canPop()) {
      context.pop(result);
    } else if (result == ConfirmResult.taken) {
      context.go('/venues/${e.venue.id}/spaces/${e.space.id}');
    } else {
      context.go('/venues/${e.venue.id}');
    }
  }

  Future<void> _confirm() async {
    if (_sending) return;
    setState(() => _sending = true);
    final e = widget.choice;
    Object? failure;
    try {
      final booking = await widget.bookings.book(e);
      if (mounted) context.go('/bookings/confirmed', extra: booking);
      return;
    } on SlotTaken {
      if (!mounted) return;
      setState(() => _sending = false);
      await showTimeSlotTaken(
        context,
        AppLocalizations.of(
          context,
        ).bookingTaken(shortDay(e.date), e.end, e.space.number, e.start),
      );
      if (mounted) _goBack(ConfirmResult.taken);
      return;
    } on SpaceUnavailable {
      if (!mounted) return;
      setState(() => _sending = false);
      await showChangedMeanwhile(context);
      if (!mounted) return;
      context.go('/venues/${e.venue.id}');
      return;
    } on BookingRejected catch (r) {
      if (!mounted) return;
      setState(() => _sending = false);
      await showTimeSlotRejected(context, r.errors.values.first);
      if (mounted) _goBack(ConfirmResult.taken);
      return;
    } on SessionExpired {
      final email = widget.session.profile?.email;
      if (email != null) widget.pending.save(e, email);
      if (!mounted) return;
      setState(() => _sending = false);
      await notifySessionExpired(context, widget.session);
      return;
    } on NetworkFailure catch (x) {
      failure = x;
    }
    if (!mounted) return;
    setState(() => _sending = false);
    await notifySendFailure(
      context,
      session: widget.session,
      expired: false,
      error: failure,
      retry: _confirm,
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.choice;
    final l = AppLocalizations.of(context);
    // It cannot be left while saving: the booking could be made without a receipt.
    return ConfirmationSkeleton(
      title: l.bookingConfirmTitle,
      sending: _sending,
      onBack: _goBack,
      primaryText: l.bookingConfirmButton,
      onPrimary: _confirm,
      secondaryText: l.bookingCancel,
      onSecondary: _goBack,
      danger: true,
      card: BookingChoiceCard(
        choice: e,
        rows: [
          DetailRow(
            label: l.bookingRowCourt,
            value: l.bookingCourtValue(
              conditionText(l, e.space),
              e.space.number,
            ),
          ),
          DetailRow(label: l.bookingRowDate, value: longDate(e.date)),
          DetailRow(
            label: l.bookingRowTime,
            value: e.timeRange,
            emphasized: true,
          ),
          const SizedBox(height: Spacing.s8),
        ],
      ),
    );
  }
}
