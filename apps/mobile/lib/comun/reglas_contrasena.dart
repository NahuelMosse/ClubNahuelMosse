import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'reglas_registro.dart';

/// Las tres reglas de la contraseña, cada una en verde si se cumple y en rojo si falta.
/// Se muestra mientras la contraseña escrita no las cumple todas.
class ReglasContrasena extends StatelessWidget {
  const ReglasContrasena({super.key, required this.contrasena});

  final String contrasena;

  static const _todas = [
    'Al menos 8 caracteres',
    'Una letra mayúscula',
    'Al menos un número',
  ];

  @override
  Widget build(BuildContext context) {
    final faltan = problemasContrasena(contrasena);
    if (contrasena.isEmpty || faltan.isEmpty) return const SizedBox.shrink();
    final p = context.paleta;
    return Padding(
      padding: const EdgeInsets.only(top: Medidas.s16),
      child: Semantics(
        liveRegion: true,
        container: true,
        child: Container(
          padding: const EdgeInsets.all(Medidas.s16),
          decoration: BoxDecoration(
            color: p.bgSurface,
            borderRadius: BorderRadius.circular(Medidas.radioMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, regla) in _todas.indexed) ...[
                if (i > 0) const SizedBox(height: Medidas.s8),
                _Regla(texto: regla, cumplida: !faltan.contains(regla)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Regla extends StatelessWidget {
  const _Regla({required this.texto, required this.cumplida});

  final String texto;
  final bool cumplida;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      container: true,
      label: '$texto: ${cumplida ? 'cumplida' : 'falta'}',
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(
            cumplida
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            size: 17,
            color: cumplida ? p.stateSuccessInk : p.stateDangerInk,
          ),
          const SizedBox(width: Medidas.s8),
          Expanded(
            child: Text(
              texto,
              style: Textos.leyenda.copyWith(
                color: cumplida ? p.textSecondary : p.stateDangerInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
