import 'package:flutter/material.dart';
import '../sedes/fotos.dart';
import '../sedes/sede.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// La foto del deporte con el camino de vuelta, el tipo y la sede.
class PortadaDeHorarios extends StatelessWidget {
  const PortadaDeHorarios({
    super.key,
    required this.sede,
    required this.tipo,
    required this.deporte,
    required this.volverA,
    required this.alVolver,
  });

  final Sede sede;
  final String tipo;
  final String deporte;

  /// El nombre de la pantalla a la que se vuelve.
  final String volverA;
  final VoidCallback alVolver;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return FotoConVelo(
      imagen: fotoDeDeporte(deporte),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Medidas.s12,
            Medidas.s8,
            Medidas.s24,
            Medidas.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: alVolver,
                style: TextButton.styleFrom(
                  foregroundColor: p.textOnMedia,
                  minimumSize: const Size(0, Medidas.tactil),
                  textStyle: Textos.leyenda,
                ),
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                label: Text(volverA),
              ),
              const SizedBox(height: Medidas.s32),
              Padding(
                padding: const EdgeInsets.only(left: Medidas.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tipo,
                      style: Textos.sobretitulo.copyWith(
                        color: p.accentOnMedia,
                      ),
                    ),
                    const SizedBox(height: Medidas.s4),
                    Semantics(
                      header: true,
                      child: Text(
                        sede.nombre.toUpperCase(),
                        style: Textos.display.copyWith(color: p.textOnMedia),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
