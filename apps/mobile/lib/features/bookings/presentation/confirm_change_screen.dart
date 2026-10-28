import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/dates.dart';
import '../../../common/error_dialog.dart';
import '../../../theme/tokens.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
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
  modificada,

  /// El horario nuevo se ocupó o dejó de valer: se vuelve a la grilla releída.
  ocupado,

  /// La reserva ya no se puede modificar: se vuelve a Mis reservas.
  cambio,

  /// Se desistió: la reserva queda como estaba.
  desistida,
}

/// «Confirmá el cambio»: el horario de antes, el de ahora y el total nuevo, y GUARDAR EL
/// CAMBIO, que mueve la reserva.
class ConfirmChangeScreen extends StatefulWidget {
  const ConfirmChangeScreen({
    super.key,
    required this.reserva,
    required this.eleccion,
    required this.reservas,
    required this.sesion,
  });

  final Booking reserva;
  final BookingChoice eleccion;
  final Bookings reservas;
  final Session sesion;

  @override
  State<ConfirmChangeScreen> createState() => _ConfirmChangeScreenState();
}

class _ConfirmChangeScreenState extends State<ConfirmChangeScreen> {
  bool _enviando = false;

  void _volver([ModifyResult? resultado]) {
    if (_enviando) return;
    if (context.canPop()) {
      context.pop(resultado);
    } else {
      context.go('/reservas');
    }
  }

  Future<void> _guardar() async {
    if (_enviando) return;
    setState(() => _enviando = true);
    Object? fallo;
    ModifyResult? cambio;
    try {
      await widget.reservas.modify(widget.reserva, widget.eleccion);
      if (!mounted) return;
      setState(() => _enviando = false);
      _volver(ModifyResult.modificada);
      return;
    } on SlotTaken {
      cambio = ModifyResult.ocupado;
    } on BookingChanged {
      cambio = ModifyResult.cambio;
    } on SpaceUnavailable {
      cambio = ModifyResult.cambio;
    } on BookingRejected catch (r) {
      if (!mounted) return;
      setState(() => _enviando = false);
      await showTimeSlotRejected(context, r.errors.values.first);
      if (mounted) _volver(ModifyResult.ocupado);
      return;
    } on SessionExpired {
      if (!mounted) return;
      setState(() => _enviando = false);
      await avisarSesionVencida(context, widget.sesion);
      return;
    } on FalloDeRed catch (x) {
      fallo = x;
    }
    if (!mounted) return;
    setState(() => _enviando = false);
    if (fallo != null) {
      await avisarFalloDeEnvio(
        context,
        session: widget.sesion,
        expired: false,
        error: fallo,
        reintentar: _guardar,
      );
      return;
    }
    await showChangedMeanwhile(context);
    if (mounted) _volver(cambio);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = widget.reserva;
    final e = widget.eleccion;
    final antes =
        '${shortDay(r.startsAt)} · ${timeRange(r.startsAt, r.endsAt)}';
    final ahora = '${shortDay(e.date)} · ${e.start} – ${e.end}';
    // Mientras se guarda no se sale: el cambio podría quedar hecho sin que se vea.
    return ConfirmationSkeleton(
      titulo: 'Confirmá el cambio',
      enviando: _enviando,
      alVolver: _volver,
      textoPrimario: 'GUARDAR EL CAMBIO',
      alPrimario: _guardar,
      textoSecundario: 'DEJAR LA RESERVA COMO ESTÁ',
      alSecundario: () => _volver(ModifyResult.desistida),
      tarjeta: BookingChoiceCard(
        eleccion: e,
        filas: [
          ChangeSlot(titulo: 'ANTES', valor: antes, nuevo: false),
          ChangeSlot(titulo: 'AHORA', valor: ahora, nuevo: true),
          Divider(height: Spacing.s16, color: p.borderDefault),
          DetailRow(
            dato: 'Cancha',
            valor: 'Cancha ${e.space.number} · ${e.space.condition}',
          ),
          DetailRow(dato: 'Fecha', valor: longDate(e.date)),
          const SizedBox(height: Spacing.s8),
        ],
      ),
    );
  }
}
