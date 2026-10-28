import 'package:flutter/material.dart';

import '../../../common/clock.dart';
import '../../../common/dates.dart';
import '../../../common/die_cut.dart';
import '../../../common/in_progress.dart';
import '../../../common/price_format.dart';
import '../../../theme/tokens.dart';
import '../../spaces/domain/space.dart';
import '../domain/booking.dart';
import '../domain/booking_status.dart';
import 'booking_actions.dart';
import 'booking_detail.dart';
import 'booking_header.dart';
import 'booking_price_and_status.dart';

/// `Card-Reserva`: deporte, sede y dirección, precio y estado arriba; el espacio, la fecha
/// y el horario abajo, con el porqué si se canceló o se anuló.
class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.reserva,
    required this.catalogo,
    this.resaltada = false,
    this.cancelable = false,
    this.cancelando = false,
    this.cuentaRegresiva = false,
    this.alCancelar,
    this.alModificar,
  });

  final Booking reserva;
  final Catalog catalogo;

  /// Suma «HOY», «MAÑANA» o «FALTAN N DÍAS» a una reserva activa.
  final bool cuentaRegresiva;

  /// Viene de un aviso: se marca con el borde de acento.
  final bool resaltada;

  /// Muestra CANCELAR: una próxima que todavía no empezó.
  final bool cancelable;

  /// La cancelación de esta reserva está en camino.
  final bool cancelando;

  /// `null` deshabilita CANCELAR (hay otra cancelación en camino).
  final VoidCallback? alCancelar;

  /// `null` deshabilita MODIFICAR.
  final VoidCallback? alModificar;

  String get _horario => horarioDe(reserva);

  String? get _porque => switch (reserva.status) {
    BookingStatus.canceled => switch (reserva.reason) {
      final m? when m.trim().isNotEmpty =>
        'Cancelada por vos · el horario quedó liberado · $m',
      _ => 'Cancelada por vos · el horario quedó liberado',
    },
    BookingStatus.voided => switch (reserva.reason) {
      final m? when m.trim().isNotEmpty => 'Anulada por el administrador · $m',
      _ => 'Anulada por el administrador',
    },
    _ => null,
  };

  /// Los días de calendario del club que faltan para el inicio, sin mirar la hora.
  String? get _cuenta {
    if (!cuentaRegresiva || reserva.status != BookingStatus.active) {
      return null;
    }
    final hoy = clubNow();
    final i = reserva.startsAt;
    final dias = DateTime(
      i.year,
      i.month,
      i.day,
    ).difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
    return switch (dias) {
      <= 0 => 'HOY',
      1 => 'MAÑANA',
      _ => 'FALTAN $dias DÍAS',
    };
  }

  /// La tarjeta se lee entera como un dato; MODIFICAR y CANCELAR quedan afuera, como
  /// botones propios.
  String _etiqueta(String? porque, String? cuenta) {
    final r = reserva;
    return [
      catalogo.shortKind(r.sport, r.kind),
      '${r.venue}, ${r.address}',
      r.status.apiValue,
      longDate(r.startsAt),
      _horario,
      '${formatPesos(r.total).replaceFirst('\$ ', '')} pesos',
      r.space,
      ?porque,
      ?cuenta?.toLowerCase(),
    ].join(', ');
  }

  Widget _datos(Palette p, bool grande) {
    final r = reserva;
    final porque = _porque;
    final cuenta = _cuenta;
    return Semantics(
      container: true,
      selected: resaltada,
      excludeSemantics: true,
      label: _etiqueta(porque, cuenta),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BookingHeader(reserva: r, catalogo: catalogo, grande: grande),
          if (grande)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.s16,
                0,
                Spacing.s16,
                Spacing.s16,
              ),
              child: BookingPriceAndStatus(reserva: r, grande: grande),
            ),
          DieCut(background: p.bgBase),
          BookingDetail(reserva: r, cuenta: cuenta, porque: porque),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = reserva;
    final activa = r.status == BookingStatus.active;
    final grande = MediaQuery.textScalerOf(context).scale(10) > 13;
    final deQue =
        '${catalogo.shortKind(r.sport, r.kind)}, '
        '${shortDay(r.startsAt)}, $_horario';
    final datos = _datos(p, grande);
    final borde = resaltada ? 2.0 : 1.0;
    return Container(
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        borderRadius: BorderRadius.circular(Spacing.radiusLg),
        border: Border.all(
          color: resaltada ? p.borderFocus : p.borderDefault,
          width: borde,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Spacing.radiusLg - borde),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                datos,
                if (cancelable)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.s16,
                      0,
                      Spacing.s16,
                      Spacing.s16,
                    ),
                    child: cancelando
                        ? const InProgress('Cancelando la reserva')
                        : BookingActions(
                            deQue: deQue,
                            grande: grande,
                            alModificar: alModificar,
                            alCancelar: alCancelar,
                          ),
                  ),
              ],
            ),
            if (activa)
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
String horarioDe(Booking r) => timeRange(r.startsAt, r.endsAt);
