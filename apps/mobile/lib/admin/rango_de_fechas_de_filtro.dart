import 'package:flutter/material.dart';

import '../comun/campo_texto.dart';
import '../comun/formato_fecha.dart';
import '../tema/tokens.dart';

/// Los campos «Desde» y «Hasta» del panel de filtros: lado a lado, o apilados si no entran.
class RangoDeFechasDeFiltro extends StatelessWidget {
  const RangoDeFechasDeFiltro({
    super.key,
    required this.desde,
    required this.hasta,
    required this.desdeInvalida,
    required this.hastaInvalida,
    required this.rangoInvalido,
  });

  final TextEditingController desde;
  final TextEditingController hasta;

  /// Hay texto en el campo y no es una fecha que exista.
  final bool desdeInvalida;
  final bool hastaInvalida;

  /// «Desde» es posterior a «Hasta».
  final bool rangoInvalido;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return LayoutBuilder(
      builder: (context, caja) {
        final campoDesde = CampoTexto(
          etiqueta: 'Desde',
          etiquetaAccesible: 'Desde',
          placeholder: 'DD / MM / AAAA',
          controlador: desde,
          teclado: TextInputType.number,
          formateadores: const [FormatoFecha()],
          accionFinal: Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: p.textMuted,
          ),
          error: desdeInvalida
              ? 'Fecha inválida'
              : rangoInvalido
              ? 'Desde no puede ser posterior a Hasta'
              : null,
        );
        final campoHasta = CampoTexto(
          etiqueta: 'Hasta',
          etiquetaAccesible: 'Hasta',
          placeholder: 'DD / MM / AAAA',
          controlador: hasta,
          teclado: TextInputType.number,
          formateadores: const [FormatoFecha()],
          accionFinal: Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: p.textMuted,
          ),
          error: hastaInvalida
              ? 'Fecha inválida'
              : rangoInvalido
              ? (caja.maxWidth < 330
                    ? 'Hasta no puede ser anterior a Desde'
                    : ' ')
              : null,
        );
        if (caja.maxWidth < 330) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              campoDesde,
              const SizedBox(height: Medidas.s12),
              campoHasta,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: campoDesde),
            const SizedBox(width: Medidas.s12),
            Expanded(child: campoHasta),
          ],
        );
      },
    );
  }
}
