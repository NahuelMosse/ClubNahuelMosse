import 'package:flutter/material.dart';
import '../comun/boton.dart';
import '../comun/fechas.dart';
import '../comun/formato_precio.dart';
import '../espacios/espacio.dart';
import '../tema/tokens.dart';
import 'cuerpo_de_reserva_admin.dart';
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
              child: CuerpoDeReservaAdmin(
                reserva: r,
                nombreDeporte: nombreDeporte,
                horario: _horario,
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
