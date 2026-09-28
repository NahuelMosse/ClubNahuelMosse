import 'package:flutter/material.dart';

import '../comun/barra_inferior.dart';
import '../comun/barra_superior.dart';

/// Mis reservas, a la que se llega desde la tarjeta de la cuenta.
class PantallaMisReservas extends StatelessWidget {
  const PantallaMisReservas({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: BarraSuperior(titulo: 'Mis reservas'),
      bottomNavigationBar: BarraInferior(actual: Seccion.reservas),
    );
  }
}
