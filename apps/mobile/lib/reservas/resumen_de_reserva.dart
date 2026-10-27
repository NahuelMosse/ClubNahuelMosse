import 'package:flutter/material.dart';

import '../comun/fechas.dart';
import '../comun/formato_precio.dart';
import '../comun/marco_de_tarjeta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'horarios.dart';

/// La tarjeta de resumen: el precio, y el total con el horario y la fecha elegidos.
class ResumenDeReserva extends StatelessWidget {
  const ResumenDeReserva({
    super.key,
    required this.tipo,
    required this.precio,
    required this.horas,
    required this.franja,
    required this.fecha,
  });

  final String tipo;
  final int precio;
  final int horas;
  final Franja? franja;
  final DateTime? fecha;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final elegida = franja;
    final dia = fecha;
    return Semantics(
      container: true,
      liveRegion: true,
      child: MarcoDeTarjeta(
        recorte: Clip.none,
        padding: const EdgeInsets.all(Medidas.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Con el texto grande, cada dato baja a su propia línea en vez de cortarse.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: Medidas.s8,
              runSpacing: Medidas.s4,
              children: [
                Text(
                  tipo,
                  style: Textos.cuerpo.copyWith(color: p.textSecondary),
                ),
                Text(
                  elegida == null
                      ? '${pesos(precio)} por hora'
                      : '${pesos(precio)} × $horas',
                  style: Textos.cuerpo.copyWith(color: p.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: Medidas.s12),
            Divider(height: 1, color: p.borderDefault),
            const SizedBox(height: Medidas.s12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: Medidas.s8,
              runSpacing: Medidas.s8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL',
                      style: Textos.sobretitulo.copyWith(color: p.textMuted),
                    ),
                    const SizedBox(height: Medidas.s4),
                    Text(
                      elegida == null ? '—' : pesos(precio * horas),
                      style: Textos.h1.copyWith(color: p.accentInk),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      elegida?.texto ?? 'Sin horario elegido',
                      style: Textos.cuerpoFuerte.copyWith(
                        color: elegida == null
                            ? p.textSecondary
                            : p.textPrimary,
                      ),
                    ),
                    if (dia != null)
                      Text(
                        fechaLarga(dia),
                        style: Textos.leyenda.copyWith(color: p.textMuted),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
