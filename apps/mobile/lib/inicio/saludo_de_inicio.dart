import 'package:flutter/material.dart';

import '../comun/zona_club.dart';
import '../sesion/sesion.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// El saludo de la hora del club y el nombre del socio, que se actualiza con la [sesion].
class SaludoDeInicio extends StatelessWidget {
  const SaludoDeInicio({super.key, required this.sesion});

  final Sesion sesion;

  static const _empiezanLasTardes = 12;
  static const _empiezanLasNoches = 20;
  static const _terminanLasNoches = 6;

  /// «BUENOS DÍAS,», «BUENAS TARDES,» o «BUENAS NOCHES,» para una [horaDelClub].
  static String paraLaHora(DateTime horaDelClub) {
    final hora = horaDelClub.hour;
    if (hora < _terminanLasNoches || hora >= _empiezanLasNoches) {
      return 'BUENAS NOCHES,';
    }
    return hora < _empiezanLasTardes ? 'BUENOS DÍAS,' : 'BUENAS TARDES,';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          paraLaHora(ahoraEnElClub()),
          style: Textos.sobretitulo.copyWith(color: p.accentOnMedia),
        ),
        const SizedBox(height: Medidas.s4),
        ListenableBuilder(
          listenable: sesion,
          builder: (context, _) => Text(
            sesion.perfil?.nombre ?? '',
            style: Textos.h1.copyWith(color: p.textOnMedia),
          ),
        ),
      ],
    );
  }
}
