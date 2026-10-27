import 'package:flutter/material.dart';

import '../comun/boton.dart';
import '../comun/en_curso.dart';
import '../comun/fechas.dart';
import '../comun/formato_precio.dart';
import '../comun/reloj.dart';
import '../comun/tarjeta_reserva.dart';
import '../comun/troquel.dart';
import '../espacios/espacio.dart';
import '../espacios/iconos.dart';
import '../sedes/fotos.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'accion_de_reserva.dart';
import 'etiqueta_de_estado.dart';
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

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = reserva;
    final porque = _porque;
    final cuenta = _cuenta;
    final activa = r.estado == EstadoDeReserva.activa;
    final anulada = r.estado == EstadoDeReserva.anulada;
    final grande = MediaQuery.textScalerOf(context).scale(10) > 13;
    final precioYEstado = Column(
      crossAxisAlignment: grande
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          pesos(r.total),
          style: Textos.cuerpoFuerte.copyWith(color: p.accentInk),
        ),
        const SizedBox(height: Medidas.s8),
        EtiquetaDeEstado(estado: r.estado),
      ],
    );
    final cancelar = alCancelar;
    final modificar = alModificar;
    final deQue =
        '${catalogo.tipoCorto(r.deporte, r.tipo)}, '
        '${diaCorto(r.inicio)}, $_horario';
    // La tarjeta se lee entera como un dato; MODIFICAR y CANCELAR quedan afuera, como
    // botones propios.
    final datos = Semantics(
      container: true,
      selected: resaltada,
      excludeSemantics: true,
      label: [
        catalogo.tipoCorto(r.deporte, r.tipo),
        '${r.sede}, ${r.direccion}',
        r.estado.name,
        fechaLarga(r.inicio),
        _horario,
        '${pesos(r.total).replaceFirst('\$\u00A0', '')} pesos',
        r.espacio,
        ?porque,
        ?cuenta?.toLowerCase(),
      ].join(', '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(Medidas.s16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Medidas.radioMd),
                  child: Image(
                    image: fotoDeDeporte(r.deporte),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(width: Medidas.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            iconoDeDeporte(r.deporte),
                            size: 16,
                            color: p.textSecondary,
                          ),
                          const SizedBox(width: Medidas.s4),
                          Flexible(
                            child: Text(
                              catalogo.tipoCorto(r.deporte, r.tipo),
                              style: Textos.titulo.copyWith(
                                color: p.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Medidas.s4),
                      Text(
                        '${r.sede} · ${r.direccion}',
                        style: Textos.leyenda.copyWith(color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (!grande) ...[
                  const SizedBox(width: Medidas.s8),
                  precioYEstado,
                ],
              ],
            ),
          ),
          if (grande)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Medidas.s16,
                0,
                Medidas.s16,
                Medidas.s16,
              ),
              child: precioYEstado,
            ),
          Troquel(fondo: p.bgBase),
          Padding(
            padding: const EdgeInsets.all(Medidas.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cuenta != null) ...[
                  Text(
                    cuenta,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 11 * 0.08,
                      color: p.accentInk,
                    ),
                  ),
                  const SizedBox(height: Medidas.s4),
                ],
                Text(
                  r.espacio,
                  style: Textos.mono.copyWith(color: p.textMuted),
                ),
                const SizedBox(height: Medidas.s8),
                FechaYHorario(fecha: fechaLarga(r.inicio), horario: _horario),
                if (porque != null) ...[
                  const SizedBox(height: Medidas.s8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: anulada ? p.stateDangerInk : p.textSecondary,
                      ),
                      const SizedBox(width: Medidas.s8),
                      Expanded(
                        child: Text(
                          porque,
                          style: Textos.leyenda.copyWith(
                            color: anulada ? p.stateDangerInk : p.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
                        : Flex(
                            direction: grande ? Axis.vertical : Axis.horizontal,
                            crossAxisAlignment: grande
                                ? CrossAxisAlignment.stretch
                                : CrossAxisAlignment.center,
                            children: [
                              AccionDeReserva(
                                expandir: !grande,
                                etiqueta: 'Modificar la reserva de $deQue',
                                alTocar: modificar,
                                child: BotonContorno(
                                  texto: 'MODIFICAR',
                                  alTocar: modificar,
                                  compacto: true,
                                ),
                              ),
                              const SizedBox(
                                width: Medidas.s8,
                                height: Medidas.s8,
                              ),
                              AccionDeReserva(
                                expandir: !grande,
                                etiqueta: 'Cancelar la reserva de $deQue',
                                alTocar: cancelar,
                                child: BotonContorno(
                                  texto: 'CANCELAR',
                                  alTocar: cancelar,
                                  peligro: true,
                                  compacto: true,
                                ),
                              ),
                            ],
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
