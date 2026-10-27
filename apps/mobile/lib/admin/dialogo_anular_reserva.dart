import 'package:flutter/material.dart';

import '../comun/boton.dart';
import '../comun/campo_texto.dart';
import '../comun/dialogo_error.dart';
import '../comun/fechas.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'campo_de_motivo.dart';
import 'datos_de_reserva_a_anular.dart';
import 'historial_reservas.dart';

/// El largo máximo del motivo de una anulación: el mismo que acepta la API.
const motivoMaximo = 500;

const motivoObligatorio = 'El motivo es obligatorio para anular';

/// La confirmación «¿Anular esta reserva?»: los datos de [reserva] y el motivo. Devuelve el
/// motivo escrito (recortado) si se confirmó, o `null` si se eligió VOLVER.
Future<String?> pedirMotivoDeAnulacion(
  BuildContext context,
  ReservaHistorial reserva,
) => showDialog<String>(
  context: context,
  barrierColor: context.paleta.bgScrim,
  builder: (context) => _DialogoAnular(reserva: reserva),
);

class _DialogoAnular extends StatefulWidget {
  const _DialogoAnular({required this.reserva});

  final ReservaHistorial reserva;

  @override
  State<_DialogoAnular> createState() => _DialogoAnularState();
}

class _DialogoAnularState extends State<_DialogoAnular> {
  final _motivo = TextEditingController();
  bool _sinMotivo = false;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  void _confirmar() {
    final motivo = _motivo.text.trim();
    if (motivo.isEmpty) {
      setState(() => _sinMotivo = true);
      return;
    }
    Navigator.of(context).pop(motivo);
  }

  String get _horario =>
      rangoDeHoras(widget.reserva.inicio, widget.reserva.fin);

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return MarcoDeDialogo(
      anchoMaximo: 360,
      hijos: [
        CirculoDeIcono(
          icono: Icons.warning_amber_rounded,
          fondo: p.stateDangerMuted,
          tinta: p.stateDangerInk,
        ),
        const SizedBox(height: Medidas.s12),
        Semantics(
          header: true,
          child: Text(
            '¿Anular esta reserva?',
            textAlign: TextAlign.center,
            style: Textos.h2.copyWith(color: p.textPrimary),
          ),
        ),
        const SizedBox(height: Medidas.s16),
        DatosDeReservaAAnular(reserva: widget.reserva, horario: _horario),
        const SizedBox(height: Medidas.s16),
        ExcludeSemantics(
          child: Text(
            'MOTIVO DE LA ANULACIÓN',
            style: Textos.sobretitulo.copyWith(color: p.textSecondary),
          ),
        ),
        const SizedBox(height: Medidas.s8),
        CampoDeMotivo(
          controller: _motivo,
          largoMaximo: motivoMaximo,
          sinMotivo: _sinMotivo,
          alCambiar: (_) {
            if (_sinMotivo) setState(() => _sinMotivo = false);
          },
        ),
        if (_sinMotivo) ...[
          const SizedBox(height: Medidas.s8),
          const MensajeDeCampo(motivoObligatorio),
        ],
        const SizedBox(height: Medidas.s16),
        BotonPeligro(texto: 'CONFIRMAR ANULACIÓN', alTocar: _confirmar),
        const SizedBox(height: Medidas.s8),
        BotonContorno(
          texto: 'VOLVER',
          alTocar: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
