import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/resultado.dart';
import '../espacios/espacio.dart';

/// El éxito del alta: el nombre del espacio guardado, y volver al listado o cargar otro.
class PantallaEspacioCreado extends StatelessWidget {
  const PantallaEspacioCreado({super.key, required this.espacio});

  final Espacio espacio;

  @override
  Widget build(BuildContext context) {
    return PantallaResultado(
      icono: Icons.check_circle_outline_rounded,
      tono: TonoResultado.exito,
      titulo: '¡Espacio deportivo creado!',
      texto: 'Ya está disponible para que los usuarios lo reserven.',
      detalle: espacio.nombre,
      principal: 'IR AL LISTADO',
      alTocarPrincipal: () => context.go('/admin/espacios'),
      secundaria: 'Crear otro',
      alTocarSecundaria: () => context.go('/admin/espacios/nuevo'),
    );
  }
}
