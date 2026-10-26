import 'package:flutter/material.dart';

import '../comun/reserva_pendiente.dart';
import '../tema/tema.dart';
import 'sesion.dart';
import 'formulario_de_inicio_sesion.dart';

export 'formulario_de_inicio_sesion.dart' show mensajeCredencialesInvalidas;

/// Inicio de sesión sobre la foto del club. Va siempre en oscuro: el texto se apoya en la
/// foto oscurecida, no en el fondo del tema.
class PantallaInicioSesion extends StatelessWidget {
  const PantallaInicioSesion({
    super.key,
    required this.sesion,
    required this.pendiente,
  });

  final Sesion sesion;

  /// La reserva que se estaba confirmando cuando venció la sesión.
  final ReservaPendiente pendiente;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: temaOscuro,
      child: FormularioDeInicioSesion(sesion: sesion, pendiente: pendiente),
    );
  }
}
