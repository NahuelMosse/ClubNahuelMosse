// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/result.dart';
import '../../spaces/domain/space.dart';

/// The creation success: the name of the saved space, and back to the list or create another.
class SpaceCreatedScreen extends StatelessWidget {
  const SpaceCreatedScreen({super.key, required this.space});

  final Space space;

  @override
  Widget build(BuildContext context) {
    return ResultScreen(
      icon: Icons.check_circle_outline_rounded,
      tone: ResultTone.success,
      title: '¡Espacio deportivo creado!',
      text: 'Ya está disponible para que los usuarios lo reserven.',
      detail: space.name,
      primary: 'IR AL LISTADO',
      onPrimaryTap: () => context.go('/admin/espacios'),
      secondary: 'Crear otro',
      onSecondaryTap: () => context.go('/admin/espacios/nuevo'),
    );
  }
}
