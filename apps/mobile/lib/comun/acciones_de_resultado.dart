import 'package:flutter/material.dart';

import '../tema/tokens.dart';
import 'boton.dart';

/// El botón principal de una [PantallaResultado] y, si lo hay, el texto secundario, que
/// se cambia por un indicador de carga mientras [cargandoSecundaria].
class AccionesDeResultado extends StatelessWidget {
  const AccionesDeResultado({
    super.key,
    required this.principal,
    required this.alTocarPrincipal,
    this.secundaria,
    this.alTocarSecundaria,
    this.cargandoSecundaria = false,
  });

  final String principal;
  final VoidCallback alTocarPrincipal;
  final String? secundaria;
  final VoidCallback? alTocarSecundaria;
  final bool cargandoSecundaria;

  @override
  Widget build(BuildContext context) {
    final textoSecundario = secundaria;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BotonPrimario(texto: principal, alTocar: alTocarPrincipal),
        if (textoSecundario != null) ...[
          const SizedBox(height: Medidas.s8),
          Center(
            child: cargandoSecundaria
                ? const SizedBox(
                    height: Medidas.altoControl,
                    child: Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  )
                : BotonTexto(
                    texto: textoSecundario,
                    alTocar: alTocarSecundaria,
                  ),
          ),
        ],
      ],
    );
  }
}
