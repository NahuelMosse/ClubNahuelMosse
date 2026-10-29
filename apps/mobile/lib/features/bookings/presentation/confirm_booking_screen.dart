// kit-shape: a screen or error family kept with its private parts.
// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/dates.dart';
import '../../../common/error_dialog.dart';
import '../../../common/pending_booking.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../spaces/presentation/space_texts.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../data/api_errors.dart';
import '../domain/availability_exceptions.dart';
import '../domain/booking_choice.dart';
import '../domain/booking_exceptions.dart';
import 'booking_choice_card.dart';
import 'bookings.dart';
import 'confirmation_skeleton.dart';
import 'detail_row.dart';

/// Lo que la confirmación le devuelve a los horarios al cerrarse: si el horario se ocupó,
/// la grilla se vuelve a leer.
enum ConfirmResult { ocupado }

/// «Confirmá tu reserva»: la cancha, la fecha, el horario y el total que se eligieron, y
/// CONFIRMAR RESERVA, que la guarda.
class ConfirmBookingScreen extends StatefulWidget {
  const ConfirmBookingScreen({
    super.key,
    required this.eleccion,
    required this.reservas,
    required this.pendiente,
    required this.sesion,
  });

  final BookingChoice eleccion;
  final Bookings reservas;
  final PendingBooking<BookingChoice> pendiente;
  final Session sesion;

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  bool _enviando = false;

  /// Vuelve a los horarios tal como quedaron. Sin nada debajo (se llegó al volver a
  /// iniciar sesión), a los horarios de esa cancha si hay que elegir otro, o a la sede.
  void _volver([ConfirmResult? resultado]) {
    if (_enviando) return;
    final e = widget.eleccion;
    if (context.canPop()) {
      context.pop(resultado);
    } else if (resultado == ConfirmResult.ocupado) {
      context.go('/sedes/${e.venue.id}/canchas/${e.space.id}');
    } else {
      context.go('/sedes/${e.venue.id}');
    }
  }

  Future<void> _confirmar() async {
    if (_enviando) return;
    setState(() => _enviando = true);
    final e = widget.eleccion;
    Object? fallo;
    try {
      final booking = await widget.reservas.book(e);
      if (mounted) context.go('/reservas/confirmada', extra: booking);
      return;
    } on SlotTaken {
      if (!mounted) return;
      setState(() => _enviando = false);
      await showTimeSlotTaken(
        context,
        AppLocalizations.of(context).bookingTaken(
          shortDay(e.date),
          e.end,
          e.space.number,
          e.start,
        ),
      );
      if (mounted) _volver(ConfirmResult.ocupado);
      return;
    } on SpaceUnavailable {
      if (!mounted) return;
      setState(() => _enviando = false);
      await showChangedMeanwhile(context);
      if (!mounted) return;
      context.go('/sedes/${e.venue.id}');
      return;
    } on BookingRejected catch (r) {
      if (!mounted) return;
      setState(() => _enviando = false);
      await showTimeSlotRejected(context, r.errors.values.first);
      if (mounted) _volver(ConfirmResult.ocupado);
      return;
    } on SessionExpired {
      final email = widget.sesion.profile?.email;
      if (email != null) widget.pendiente.save(e, email);
      if (!mounted) return;
      setState(() => _enviando = false);
      await avisarSesionVencida(context, widget.sesion);
      return;
    } on FalloDeRed catch (x) {
      fallo = x;
    }
    if (!mounted) return;
    setState(() => _enviando = false);
    await avisarFalloDeEnvio(
      context,
      session: widget.sesion,
      expired: false,
      error: fallo,
      reintentar: _confirmar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.eleccion;
    final l = AppLocalizations.of(context);
    // Mientras se guarda no se sale: la reserva podría quedar hecha sin comprobante.
    return ConfirmationSkeleton(
      titulo: l.bookingConfirmTitle,
      enviando: _enviando,
      alVolver: _volver,
      textoPrimario: l.bookingConfirmButton,
      alPrimario: _confirmar,
      textoSecundario: l.bookingCancel,
      alSecundario: _volver,
      peligro: true,
      tarjeta: BookingChoiceCard(
        eleccion: e,
        filas: [
          DetailRow(
            dato: l.bookingRowCourt,
            valor: l.bookingCourtValue(
              conditionText(l, e.space),
              e.space.number,
            ),
          ),
          DetailRow(dato: l.bookingRowDate, valor: longDate(e.date)),
          DetailRow(
            dato: l.bookingRowTime,
            valor: e.timeRange,
            destacado: true,
          ),
          const SizedBox(height: Spacing.s8),
        ],
      ),
    );
  }
}
