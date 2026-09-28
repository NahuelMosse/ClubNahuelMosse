import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/resultado.dart';
import '../sedes/sede.dart';

/// El éxito del alta: la sede que quedó guardada, y volver al listado o cargar otra.
class PantallaSedeCreada extends StatelessWidget {
  const PantallaSedeCreada({super.key, required this.sede});

  final Sede sede;

  @override
  Widget build(BuildContext context) {
    return PantallaResultado(
      icono: Icons.check_circle_outline_rounded,
      tono: TonoResultado.exito,
      titulo: '¡Sede creada!',
      texto:
          'La sede ya aparece en el listado y podés empezar a cargarle '
          'espacios deportivos.',
      detalle: '${sede.nombre} · ${sede.direccion}',
      principal: 'IR AL LISTADO',
      alTocarPrincipal: () => context.go('/admin/sedes'),
      secundaria: 'Crear otra sede',
      alTocarSecundaria: () => context.go('/admin/sedes/nueva'),
    );
  }
}
