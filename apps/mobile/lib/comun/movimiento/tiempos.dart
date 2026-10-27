import 'dart:async';

import 'package:flutter/material.dart';

/// Duraciones y curvas del movimiento de la app. Cada animación corre una vez, con un
/// `AnimationController` propio, y con reducir movimiento muestra su estado final.
abstract final class Movimiento {
  static const Curve salida = Curves.easeOut;
  static const Curve suave = Curves.easeOutCubic;
  static const Curve rapida = Curves.easeOutQuart;
  static const Curve rebote = Curves.easeOutBack;

  static const avanzar = Duration(milliseconds: 320);
  static const volver = Duration(milliseconds: 280);
  static const fundido = Duration(milliseconds: 250);
  static const cambioDeLista = Duration(milliseconds: 150);
  static const temblor = Duration(milliseconds: 360);
  static const latido = Duration(milliseconds: 500);
  static const presion = Duration(milliseconds: 80);
  static const entrada = Duration(milliseconds: 400);
  static const paso = Duration(milliseconds: 80);
  static const subida = Duration(milliseconds: 450);
}

/// Arranca [controlador] una vez, salvo con reducir movimiento: ahí queda en su final.
void arrancarUnaVez(AnimationController controlador, BuildContext context) {
  if (MediaQuery.disableAnimationsOf(context)) {
    controlador.value = 1;
  } else {
    unawaited(controlador.forward());
  }
}
