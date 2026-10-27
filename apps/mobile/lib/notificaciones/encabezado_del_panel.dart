import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// La fila de arriba del panel de avisos: el título y «MARCAR TODAS».
class EncabezadoDelPanel extends StatelessWidget {
  const EncabezadoDelPanel({super.key, required this.alMarcarTodas});

  final VoidCallback alMarcarTodas;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Row(
      children: [
        Expanded(
          // Un lector de pantalla anuncia el panel cuando aparece.
          child: Semantics(
            header: true,
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(left: Medidas.s4),
              child: Text(
                'NOTIFICACIONES',
                style: Textos.sobretitulo.copyWith(color: p.textMuted),
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: 'MARCAR TODAS',
          excludeSemantics: true,
          onTap: alMarcarTodas,
          child: InkWell(
            onTap: alMarcarTodas,
            borderRadius: BorderRadius.circular(Medidas.radioMd),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: kMinInteractiveDimension,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Medidas.s8),
                child: Center(
                  child: Text(
                    'MARCAR TODAS',
                    style: Textos.sobretitulo.copyWith(color: p.accentInk),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
