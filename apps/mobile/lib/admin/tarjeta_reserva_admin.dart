import 'package:flutter/material.dart';
import '../comun/boton.dart';
import '../comun/fechas.dart';
import '../comun/formato_precio.dart';
import '../comun/tarjeta_reserva.dart';
import '../espacios/espacio.dart';
import '../espacios/iconos.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'estado_reserva_chip.dart';
import 'historial_reservas.dart';

class TarjetaReservaAdmin extends StatelessWidget {
  const TarjetaReservaAdmin({
    super.key,
    required this.reserva,
    required this.catalogo,
    required this.alTocar,
    required this.alAnular,
  });

  final ReservaHistorial reserva;
  final Catalogo? catalogo;
  final VoidCallback alTocar;

  /// `null` deshabilita ANULAR RESERVA (hay otra anulación en camino).
  final VoidCallback? alAnular;

  String get _horario => rangoDeHoras(reserva.inicio, reserva.fin);

  // Con cualquier agrandado del texto, precio y estado ya no entran junto al nombre en 360.
  bool _grande(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(10) > 13;

  Widget _precioYEstado(Paleta p) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        pesos(reserva.total),
        style: Textos.cuerpoFuerte.copyWith(color: p.accentInk),
      ),
      const SizedBox(height: Medidas.s4),
      EstadoReservaChip(estado: reserva.estado),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = reserva;
    final nombreDeporte = catalogo?.deporte(r.deporte)?.nombre ?? r.deporte;
    final semantica =
        '$nombreDeporte, ${r.sede}, ${r.usuario}, '
        '${fechaLarga(r.inicio)}, $_horario, ${pesos(r.total)}, '
        '${r.estado.name}'
        '${r.espacioDeBaja ? ', baja del espacio deportivo' : ''}';
    final anular = alAnular;
    return Material(
      color: p.bgSurfaceRaised,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Medidas.radioLg),
        side: BorderSide(color: p.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: semantica,
            excludeSemantics: true,
            child: InkWell(
              onTap: alTocar,
              child: Padding(
                padding: const EdgeInsets.all(Medidas.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          iconoDeDeporte(r.deporte),
                          size: 20,
                          color: p.textSecondary,
                        ),
                        const SizedBox(width: Medidas.s8),
                        Expanded(
                          child: Text(
                            nombreDeporte,
                            style: Textos.titulo.copyWith(color: p.textPrimary),
                          ),
                        ),
                        // Con el texto muy agrandado, precio y estado bajan debajo del
                        // nombre en vez de disputarle el ancho.
                        if (!_grande(context)) ...[
                          const SizedBox(width: Medidas.s8),
                          _precioYEstado(p),
                        ],
                      ],
                    ),
                    if (_grande(context)) ...[
                      const SizedBox(height: Medidas.s8),
                      _precioYEstado(p),
                    ],
                    const SizedBox(height: Medidas.s4),
                    Text(
                      '${r.sede} · ${r.direccion}',
                      style: Textos.leyenda.copyWith(color: p.textSecondary),
                    ),
                    const SizedBox(height: Medidas.s12),
                    UsuarioDeReserva(usuario: r.usuario),
                    const SizedBox(height: Medidas.s8),
                    Text(
                      r.espacio,
                      style: Textos.mono.copyWith(color: p.textMuted),
                    ),
                    const SizedBox(height: Medidas.s8),
                    FechaYHorario(
                      fecha: fechaLarga(r.inicio),
                      horario: _horario,
                      separacionVertical: Medidas.s4,
                      alineacion: WrapCrossAlignment.start,
                    ),
                    if (r.espacioDeBaja) ...[
                      const SizedBox(height: Medidas.s8),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: p.textMuted,
                          ),
                          const SizedBox(width: Medidas.s4),
                          Flexible(
                            child: Text(
                              'Baja del espacio deportivo',
                              style: Textos.leyenda.copyWith(
                                color: p.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (r.anulable)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Medidas.s16,
                0,
                Medidas.s16,
                Medidas.s16,
              ),
              child: BotonContorno(
                texto: 'ANULAR RESERVA',
                peligro: true,
                etiquetaAccesible:
                    'Anular la reserva de ${r.usuario}, $nombreDeporte, '
                    '${fechaLarga(r.inicio)}, $_horario',
                alTocar: anular,
              ),
            ),
        ],
      ),
    );
  }
}
