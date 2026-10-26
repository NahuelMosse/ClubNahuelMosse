import 'package:flutter/material.dart';
import '../comun/marco_de_tarjeta.dart';
import '../sedes/fotos.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'eleccion.dart';
import 'fila_de_total.dart';

/// La tarjeta de la elección: la foto con el tipo y la sede, las [filas] y el total.
class TarjetaDeEleccion extends StatelessWidget {
  const TarjetaDeEleccion({
    super.key,
    required this.eleccion,
    required this.filas,
  });

  final Eleccion eleccion;
  final List<Widget> filas;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final e = eleccion;
    return MarcoDeTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: FotoConVelo(
              imagen: fotoDeDeporte(e.cancha.deporte),
              child: Padding(
                padding: const EdgeInsets.all(Medidas.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e.tipo,
                      style: Textos.sobretitulo.copyWith(
                        color: p.accentOnMedia,
                      ),
                    ),
                    Text(
                      e.sede.nombre.toUpperCase(),
                      style: Textos.h2.copyWith(color: p.textOnMedia),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Medidas.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...filas,
                Divider(height: 1, color: p.borderDefault),
                const SizedBox(height: Medidas.s16),
                FilaDeTotal(total: e.total),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
