import 'package:flutter/material.dart';

import '../comun/movimiento.dart';
import '../comun/snackbar.dart';
import '../tema/tokens.dart';

/// El aviso de error al pie de la pantalla; tiembla cada vez que [avisos] sube.
class AvisoDeInicioSesion extends StatelessWidget {
  const AvisoDeInicioSesion({
    super.key,
    required this.aviso,
    required this.avisos,
    required this.alCerrar,
  });

  final String? aviso;
  final int avisos;
  final VoidCallback alCerrar;

  @override
  Widget build(BuildContext context) {
    final texto = aviso;
    return Positioned(
      left: Medidas.s24,
      right: Medidas.s24,
      bottom: Medidas.s24 + MediaQuery.viewInsetsOf(context).bottom,
      child: SafeArea(
        top: false,
        child: Temblor(
          disparador: avisos,
          child: texto == null
              ? const SizedBox.shrink()
              : SnackbarError(texto: texto, alCerrar: alCerrar),
        ),
      ),
    );
  }
}
