import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/result.dart';
import '../../venues/domain/venue.dart';

/// The creation success: the venue that was saved, and back to the list or create another.
class VenueCreatedScreen extends StatelessWidget {
  const VenueCreatedScreen({super.key, required this.venue});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    return ResultScreen(
      icon: Icons.check_circle_outline_rounded,
      tone: ResultTone.success,
      title: '¡Sede creada!',
      text:
          'La sede ya aparece en el listado y podés empezar a cargarle '
          'espacios deportivos.',
      detail: '${venue.name} · ${venue.address}',
      primary: 'IR AL LISTADO',
      onPrimaryTap: () => context.go('/admin/sedes'),
      secondary: 'Crear otra sede',
      onSecondaryTap: () => context.go('/admin/sedes/nueva'),
    );
  }
}
