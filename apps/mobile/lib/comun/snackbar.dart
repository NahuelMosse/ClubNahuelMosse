import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// `Snackbar/Type=Error` del prototipo: aviso que no bloquea la pantalla y se cierra con la X.
class SnackbarError extends StatelessWidget {
  const SnackbarError({super.key, required this.texto, required this.alCerrar});

  final String texto;
  final VoidCallback alCerrar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          Medidas.s12,
          Medidas.s4,
          Medidas.s4,
          Medidas.s4,
        ),
        decoration: BoxDecoration(
          color: Color.alphaBlend(p.stateDangerMuted, p.bgBase),
          borderRadius: BorderRadius.circular(Medidas.radioMd),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: p.stateDangerInk,
            ),
            const SizedBox(width: Medidas.s8),
            Expanded(
              child: Text(
                texto,
                style: Textos.leyenda.copyWith(color: p.stateDangerInk),
              ),
            ),
            IconButton(
              tooltip: 'Cerrar aviso',
              onPressed: alCerrar,
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: p.stateDangerInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
