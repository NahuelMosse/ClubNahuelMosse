import 'package:flutter/material.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'fotos.dart';

/// La foto con velo y, encima, el camino de vuelta, un sobretítulo, el nombre de la sede y
/// lo que cada pantalla agregue debajo ([extra]).
class PortadaConTitulo extends StatelessWidget {
  const PortadaConTitulo({
    super.key,
    required this.imagen,
    required this.volverA,
    required this.alVolver,
    required this.separacion,
    required this.sobretitulo,
    required this.nombre,
    this.extra = const [],
  });

  final ImageProvider imagen;

  /// El nombre de la pantalla a la que se vuelve.
  final String volverA;
  final VoidCallback alVolver;

  /// El alto entre el camino de vuelta y el sobretítulo.
  final double separacion;
  final String sobretitulo;
  final String nombre;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return FotoConVelo(
      imagen: imagen,
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
              SizedBox(height: separacion),
              Padding(
                padding: const EdgeInsets.only(left: Medidas.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sobretitulo,
                      style: Textos.sobretitulo.copyWith(
                        color: p.accentOnMedia,
                      ),
                    ),
                    const SizedBox(height: Medidas.s4),
                    Semantics(
                      header: true,
                      child: Text(
                        nombre.toUpperCase(),
                        style: Textos.display.copyWith(color: p.textOnMedia),
                      ),
                    ),
                    ...extra,
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
