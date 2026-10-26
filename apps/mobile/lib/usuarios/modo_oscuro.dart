import 'package:flutter/material.dart';
import '../comun/apariencia.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

class ModoOscuro extends StatelessWidget {
  const ModoOscuro({super.key, required this.apariencia});

  final Apariencia apariencia;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return ListenableBuilder(
      listenable: apariencia,
      builder: (context, _) {
        void alternar() => apariencia.cambiar(oscuro: !apariencia.oscuro);
        // Toda la fila alterna el tema, no sólo el interruptor.
        return Semantics(
          container: true,
          label: 'Modo oscuro',
          toggled: apariencia.oscuro,
          onTap: alternar,
          excludeSemantics: true,
          child: InkWell(
            onTap: alternar,
            borderRadius: BorderRadius.circular(Medidas.radioMd),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: Medidas.altoControl),
              child: Row(
                children: [
                  Icon(
                    Icons.dark_mode_outlined,
                    size: 20,
                    color: p.textSecondary,
                  ),
                  const SizedBox(width: Medidas.s12),
                  Expanded(
                    child: Text(
                      'Modo oscuro',
                      style: Textos.cuerpoFuerte.copyWith(color: p.textPrimary),
                    ),
                  ),
                  Switch(
                    value: apariencia.oscuro,
                    activeTrackColor: p.accentBase,
                    activeThumbColor: p.accentOn,
                    onChanged: (oscuro) => apariencia.cambiar(oscuro: oscuro),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
