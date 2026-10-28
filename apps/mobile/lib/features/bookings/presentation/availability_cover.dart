// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import '../../../theme/tokens.dart';
import '../../venues/domain/venue.dart';
import '../../venues/presentation/cover_with_title.dart';
import '../../venues/presentation/photos.dart';

/// La foto del deporte con el camino de vuelta, el tipo y la sede.
class AvailabilityCover extends StatelessWidget {
  const AvailabilityCover({
    super.key,
    required this.sede,
    required this.tipo,
    required this.deporte,
    required this.volverA,
    required this.alVolver,
  });

  final Venue sede;
  final String tipo;
  final String deporte;

  /// El nombre de la pantalla a la que se vuelve.
  final String volverA;
  final VoidCallback alVolver;

  @override
  Widget build(BuildContext context) {
    return CoverWithTitle(
      image: sportPhoto(deporte),
      backTo: volverA,
      onBack: alVolver,
      gap: Spacing.s32,
      overline: tipo,
      name: sede.name,
    );
  }
}
