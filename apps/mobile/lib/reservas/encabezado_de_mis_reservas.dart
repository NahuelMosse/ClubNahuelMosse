import 'package:flutter/material.dart';

import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// El título «Mis reservas» con el botón de la cuenta.
class EncabezadoDeMisReservas extends StatelessWidget {
  const EncabezadoDeMisReservas({super.key, required this.sesion});

  final Sesion sesion;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              'Mis reservas',
              style: Textos.h1.copyWith(color: p.textPrimary),
            ),
          ),
        ),
        BotonCuenta(sesion: sesion),
      ],
    );
  }
}
