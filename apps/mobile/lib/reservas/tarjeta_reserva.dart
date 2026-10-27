import 'package:flutter/material.dart';

import '../comun/en_curso.dart';
import '../comun/fechas.dart';
import '../comun/formato_precio.dart';
import '../comun/reloj.dart';
import '../comun/troquel.dart';
import '../espacios/espacio.dart';
import '../tema/tokens.dart';
import 'acciones_de_reserva.dart';
import 'cabecera_de_reserva.dart';
import 'detalle_de_reserva.dart';
import 'precio_y_estado_de_reserva.dart';
import 'reservas.dart';

/// `Card-Reserva`: deporte, sede y dirección, precio y estado arriba; el espacio, la fecha
/// y el horario abajo, con el porqué si se canceló o se anuló.
class TarjetaReserva extends StatelessWidget {
  const TarjetaReserva({
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

  final Reserva reserva;
  final Catalogo catalogo;

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

  String? get _porque => switch (reserva.estado) {
    EstadoDeReserva.cancelada => switch (reserva.motivo) {
      final m? when m.trim().isNotEmpty =>
        'Cancelada por vos · el horario quedó liberado · $m',
      _ => 'Cancelada por vos · el horario quedó liberado',
    },
    EstadoDeReserva.anulada => switch (reserva.motivo) {
      final m? when m.trim().isNotEmpty => 'Anulada por el administrador · $m',
      _ => 'Anulada por el administrador',
    },
    _ => null,
  };

  /// Los días de calendario del club que faltan para el inicio, sin mirar la hora.
  String? get _cuenta {
    if (!cuentaRegresiva || reserva.estado != EstadoDeReserva.activa) {
      return null;
    }
    final hoy = ahoraEnElClub();
    final i = reserva.inicio;
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
      catalogo.tipoCorto(r.deporte, r.tipo),
      '${r.sede}, ${r.direccion}',
      r.estado.name,
      fechaLarga(r.inicio),
      _horario,
      '${pesos(r.total).replaceFirst('\$ ', '')} pesos',
      r.espacio,
      ?porque,
      ?cuenta?.toLowerCase(),
    ].join(', ');
  }

  Widget _datos(Paleta p, bool grande) {
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
          CabeceraDeReserva(reserva: r, catalogo: catalogo, grande: grande),
          if (grande)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Medidas.s16,
                0,
                Medidas.s16,
                Medidas.s16,
              ),
              child: PrecioYEstadoDeReserva(reserva: r, grande: grande),
            ),
          Troquel(fondo: p.bgBase),
          DetalleDeReserva(reserva: r, cuenta: cuenta, porque: porque),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = reserva;
    final activa = r.estado == EstadoDeReserva.activa;
    final grande = MediaQuery.textScalerOf(context).scale(10) > 13;
    final deQue =
        '${catalogo.tipoCorto(r.deporte, r.tipo)}, '
        '${diaCorto(r.inicio)}, $_horario';
    final datos = _datos(p, grande);
    final borde = resaltada ? 2.0 : 1.0;
    return Container(
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        borderRadius: BorderRadius.circular(Medidas.radioLg),
        border: Border.all(
          color: resaltada ? p.borderFocus : p.borderDefault,
          width: borde,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Medidas.radioLg - borde),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                datos,
                if (cancelable)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Medidas.s16,
                      0,
                      Medidas.s16,
                      Medidas.s16,
                    ),
                    child: cancelando
                        ? const EnCurso('Cancelando la reserva')
                        : AccionesDeReserva(
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
String horarioDe(Reserva r) => rangoDeHoras(r.inicio, r.fin);
