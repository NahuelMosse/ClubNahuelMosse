import 'package:flutter/material.dart';
import '../comun/isotipo.dart';
import '../comun/movimiento.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

class MarcaDeInicioSesion extends StatelessWidget {
  const MarcaDeInicioSesion({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Aparecer(
          duracion: Duration(milliseconds: 700),
          desdeY: -70,
          giro: 25 / 360,
          curva: Movimiento.rebote,
          child: Isotipo(tamano: 40, decorativo: true),
        ),
        const SizedBox(height: Medidas.s16),
        Text(
          'BIENVENIDO A',
          style: Textos.sobretitulo.copyWith(color: p.accentOnMedia),
        ),
        const SizedBox(height: Medidas.s8),
        Semantics(
          header: true,
          label: 'Club Nahuel Mosse',
          child: ExcludeSemantics(
            // En el teléfono chico la marca se achica antes que partirse en dos líneas.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'CLUB ',
                      style: TextStyle(color: p.textOnMedia),
                    ),
                    TextSpan(
                      text: 'NAHUELMOSSE',
                      style: TextStyle(color: p.accentOnMedia),
                    ),
                  ],
                ),
                style: Textos.display,
              ),
            ),
          ),
        ),
        const SizedBox(height: Medidas.s8),
        Text(
          'Gestión de espacios deportivos',
          style: Textos.cuerpo.copyWith(color: p.textOnMediaMuted),
        ),
      ],
    );
  }
}
