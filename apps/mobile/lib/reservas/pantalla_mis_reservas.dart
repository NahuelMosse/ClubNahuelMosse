import 'package:flutter/material.dart';

import '../comun/barra_superior.dart';

/// Mis reservas, a la que se llega desde la tarjeta de la cuenta.
class PantallaMisReservas extends StatelessWidget {
  const PantallaMisReservas({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: const BarraSuperior(titulo: 'Mis reservas'));
  }
}
