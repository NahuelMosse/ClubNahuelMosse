import 'package:flutter/material.dart';

import '../comun/boton.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tokens.dart';

/// «Cerrar sesión» y «Eliminar cuenta»; con la baja en curso, ninguno responde.
class AccionesDeCuenta extends StatelessWidget {
  const AccionesDeCuenta({
    super.key,
    required this.sesion,
    required this.dandoDeBaja,
    required this.alConfirmarBaja,
  });

  final Sesion sesion;
  final bool dandoDeBaja;
  final VoidCallback alConfirmarBaja;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BotonContorno(
          texto: 'CERRAR SESIÓN',
          alTocar: dandoDeBaja ? null : () => cerrarSesion(context, sesion),
        ),
        const SizedBox(height: Medidas.s8),
        BotonContorno(
          texto: dandoDeBaja ? 'ELIMINANDO TU CUENTA…' : 'ELIMINAR CUENTA',
          peligro: true,
          alTocar: dandoDeBaja ? null : alConfirmarBaja,
        ),
      ],
    );
  }
}
