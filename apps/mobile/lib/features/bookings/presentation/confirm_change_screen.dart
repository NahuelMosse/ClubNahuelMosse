// kit-shape: a screen or error family kept with its private parts.
// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/dates.dart';
import '../../../common/error_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../../spaces/presentation/space_texts.dart';
import '../data/api_errors.dart';
import '../domain/availability_exceptions.dart';
import '../domain/booking.dart';
import '../domain/booking_choice.dart';
import '../domain/booking_exceptions.dart';
import 'booking_choice_card.dart';
import 'bookings.dart';
import 'change_slot.dart';
import 'confirmation_skeleton.dart';
import 'detail_row.dart';

/// Cómo terminó la modificación, para los horarios y Mis reservas, que quedan debajo.
enum ModifyResult {
  /// Se guardó el horario nuevo.
  modified,

  /// El horario nuevo se ocupó o dejó de valer: se vuelve a la grilla releída.
  taken,

  /// La reserva ya no se puede modificar: se vuelve a Mis reservas.
  change,

  /// Se desistió: la reserva queda como estaba.
  abandoned,
}

/// «Confirmá el cambio»: el horario de antes, el de ahora y el total nuevo, y GUARDAR EL
/// CAMBIO, que mueve la reserva.
class ConfirmChangeScreen extends StatefulWidget {
  const ConfirmChangeScreen({
    super.key,
    required this.booking,
    required this.choice,
    required this.bookings,
    required this.session,
  });

  final Booking booking;
  final BookingChoice choice;
  final Bookings bookings;
  final Session session;

  @override
  State<ConfirmChangeScreen> createState() => _ConfirmChangeScreenState();
}

class _ConfirmChangeScreenState extends State<ConfirmChangeScreen> {
  bool _sending = false;

  void _goBack([ModifyResult? result]) {
    if (_sending) return;
    if (context.canPop()) {
      context.pop(result);
    } else {
      context.go('/bookings');
    }
  }

  Future<void> _save() async {
    if (_sending) return;
    setState(() => _sending = true);
    Object? failure;
    ModifyResult? change;
    try {
      await widget.bookings.modify(widget.booking, widget.choice);
      if (!mounted) return;
      setState(() => _sending = false);
      _goBack(ModifyResult.modified);
      return;
    } on SlotTaken {
      change = ModifyResult.taken;
    } on BookingChanged {
      change = ModifyResult.change;
    } on SpaceUnavailable {
      change = ModifyResult.change;
    } on BookingRejected catch (r) {
      if (!mounted) return;
      setState(() => _sending = false);
      await showTimeSlotRejected(context, r.errors.values.first);
      if (mounted) _goBack(ModifyResult.taken);
      return;
    } on SessionExpired {
      if (!mounted) return;
      setState(() => _sending = false);
      await notifySessionExpired(context, widget.session);
      return;
    } on NetworkFailure catch (x) {
      failure = x;
    }
    if (!mounted) return;
    setState(() => _sending = false);
    if (failure != null) {
      await notifySendFailure(
        context,
        session: widget.session,
        expired: false,
        error: failure,
        retry: _save,
      );
      return;
    }
    await showChangedMeanwhile(context);
    if (mounted) _goBack(change);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = widget.booking;
    final e = widget.choice;
    final l = AppLocalizations.of(context);
    final before =
        '${shortDay(r.startsAt)} · ${timeRange(r.startsAt, r.endsAt)}';
    final now = '${shortDay(e.date)} · ${e.start} – ${e.end}';
    // Mientras se guarda no se sale: el cambio podría quedar hecho sin que se vea.
    return ConfirmationSkeleton(
      title: l.bookingChangeTitle,
      sending: _sending,
      onBack: _goBack,
      primaryText: l.bookingChangeSave,
      onPrimary: _save,
      secondaryText: l.bookingChangeKeep,
      onSecondary: () => _goBack(ModifyResult.abandoned),
      card: BookingChoiceCard(
        choice: e,
        rows: [
          ChangeSlot(title: l.bookingBefore, value: before, isNew: false),
          ChangeSlot(title: l.bookingNow, value: now, isNew: true),
          Divider(height: Spacing.s16, color: p.borderDefault),
          DetailRow(
            label: l.bookingRowCourt,
            value: l.bookingCourtValue(
              conditionText(l, e.space),
              e.space.number,
            ),
          ),
          DetailRow(label: l.bookingRowDate, value: longDate(e.date)),
          const SizedBox(height: Spacing.s8),
        ],
      ),
    );
  }
}
