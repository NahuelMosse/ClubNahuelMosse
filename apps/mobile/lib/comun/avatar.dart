import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

enum TamanoAvatar {
  chico(40, 15),
  mediano(48, 17),
  grande(76, 24);

  const TamanoAvatar(this.lado, this.letra);
  final double lado;
  final double letra;
}

/// `Avatar-Iniciales` del prototipo: círculo lima con la inicial del nombre y la del apellido.
class AvatarIniciales extends StatelessWidget {
  const AvatarIniciales({
    super.key,
    required this.nombre,
    required this.apellido,
    this.tamano = TamanoAvatar.mediano,
  });

  final String nombre;
  final String apellido;
  final TamanoAvatar tamano;

  static String iniciales(String nombre, String apellido) => [nombre, apellido]
      .map((parte) => parte.trim())
      .where((parte) => parte.isNotEmpty)
      .map((parte) => String.fromCharCode(parte.runes.first).toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final grande = tamano == TamanoAvatar.grande;
    return ExcludeSemantics(
      child: Container(
        width: tamano.lado,
        height: tamano.lado,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: p.accentBase, shape: BoxShape.circle),
        child: Text(
          iniciales(nombre, apellido),
          textScaler: TextScaler.noScaling,
          style: (grande ? Textos.h1 : Textos.titulo).copyWith(
            color: p.accentOn,
            fontSize: tamano.letra,
          ),
        ),
      ),
    );
  }
}
