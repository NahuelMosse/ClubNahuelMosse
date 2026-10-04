import 'package:flutter/material.dart';

import '../comun/boton.dart';
import '../comun/formato_precio.dart';
import '../reservas/fechas.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
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

  String get _horario {
    String dos(int n) => n.toString().padLeft(2, '0');
    final r = widget.reserva;
    return '${dos(r.inicio.hour)}:${dos(r.inicio.minute)} – '
        '${dos(r.fin.hour)}:${dos(r.fin.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = widget.reserva;
    OutlineInputBorder borde(Color color, double ancho) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(Medidas.radioMd),
      borderSide: BorderSide(color: color, width: ancho),
    );
    return Dialog(
      backgroundColor: p.bgSurfaceRaised,
      insetPadding: const EdgeInsets.symmetric(horizontal: Medidas.s24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Medidas.radioLg),
        side: BorderSide(color: p.borderDefault),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Medidas.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: p.stateDangerMuted,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 28,
                    color: p.stateDangerInk,
                  ),
                ),
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
              Container(
                padding: const EdgeInsets.all(Medidas.s16),
                decoration: BoxDecoration(
                  color: p.bgSurface,
                  borderRadius: BorderRadius.circular(Medidas.radioMd),
                ),
                child: Column(
                  children: [
                    _Dato('Usuario', r.usuario),
                    _Dato('Sede', r.sede),
                    _Dato('Cancha', r.espacio, tecnico: true),
                    _Dato('Cuándo', '${fechaLarga(r.inicio)}\n$_horario'),
                    _Dato('Importe', pesos(r.total)),
                  ],
                ),
              ),
              const SizedBox(height: Medidas.s16),
              ExcludeSemantics(
                child: Text(
                  'MOTIVO DE LA ANULACIÓN',
                  style: Textos.sobretitulo.copyWith(color: p.textSecondary),
                ),
              ),
              const SizedBox(height: Medidas.s8),
              Semantics(
                container: true,
                label: 'Motivo de la anulación',
                child: TextField(
                  controller: _motivo,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: motivoMaximo,
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required isFocused,
                        required maxLength,
                      }) => null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) {
                    if (_sinMotivo) setState(() => _sinMotivo = false);
                  },
                  style: Textos.cuerpo.copyWith(color: p.textPrimary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: p.bgSurface,
                    contentPadding: const EdgeInsets.all(Medidas.s16),
                    enabledBorder: _sinMotivo
                        ? borde(p.borderError, 1.5)
                        : borde(p.borderControl, 1),
                    focusedBorder: _sinMotivo
                        ? borde(p.borderError, 1.5)
                        : borde(p.borderFocus, 1.5),
                    border: borde(p.borderControl, 1),
                  ),
                ),
              ),
              if (_sinMotivo) ...[
                const SizedBox(height: Medidas.s8),
                Semantics(
                  liveRegion: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: p.stateDangerInk,
                        ),
                      ),
                      const SizedBox(width: Medidas.s8),
                      Expanded(
                        child: Text(
                          motivoObligatorio,
                          style: Textos.leyenda.copyWith(
                            color: p.stateDangerInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: Medidas.s16),
              BotonPeligro(texto: 'CONFIRMAR ANULACIÓN', alTocar: _confirmar),
              const SizedBox(height: Medidas.s8),
              BotonContorno(
                texto: 'VOLVER',
                alTocar: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una fila «etiqueta — valor» de la tabla de datos de la reserva.
class _Dato extends StatelessWidget {
  const _Dato(this.etiqueta, this.valor, {this.tecnico = false});

  final String etiqueta;
  final String valor;

  /// El valor es el nombre técnico del espacio.
  final bool tecnico;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '$etiqueta, $valor',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Medidas.s4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              etiqueta,
              style: Textos.leyenda.copyWith(color: p.textSecondary),
            ),
            const SizedBox(width: Medidas.s12),
            Expanded(
              child: Text(
                valor,
                textAlign: TextAlign.end,
                style: tecnico
                    ? Textos.mono.copyWith(color: p.textPrimary)
                    : Textos.cuerpoFuerte.copyWith(color: p.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
