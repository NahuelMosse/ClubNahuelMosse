import 'package:flutter/material.dart';
import '../comun/fechas.dart';
import '../comun/formato_precio.dart';
import '../comun/marco_de_tarjeta.dart';
import '../comun/tarjeta_reserva.dart';
import '../espacios/iconos.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'estado_reserva_chip.dart';
import 'historial_reservas.dart';

class TarjetaDatosDeReserva extends StatelessWidget {
  const TarjetaDatosDeReserva({
    super.key,
    required this.reserva,
    required this.horario,
    required this.nombreDeporte,
  });

  final ReservaHistorial reserva;
  final String horario;
  final String nombreDeporte;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = reserva;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '$nombreDeporte, sede ${r.sede}, ${r.direccion}, ${pesos(r.total)}, '
          '${r.estado.name}, usuario ${r.usuario}, ${r.espacio}, '
          '${fechaLarga(r.inicio)}, $horario',
      child: MarcoDeTarjeta(
        recorte: Clip.none,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      pesos(r.total),
                      style: Textos.cuerpoFuerte.copyWith(color: p.accentInk),
                    ),
                    const SizedBox(height: Medidas.s8),
                    EstadoReservaChip(estado: r.estado),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Medidas.s8),
            Text(
              '${r.sede} · ${r.direccion}',
              style: Textos.leyenda.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: Medidas.s12),
            UsuarioDeReserva(usuario: r.usuario),
            const SizedBox(height: Medidas.s8),
            Text(r.espacio, style: Textos.mono.copyWith(color: p.textMuted)),
            const SizedBox(height: Medidas.s8),
            FechaYHorario(
              fecha: fechaLarga(r.inicio),
              horario: horario,
              alineacion: WrapCrossAlignment.start,
            ),
          ],
        ),
      ),
    );
  }
}
