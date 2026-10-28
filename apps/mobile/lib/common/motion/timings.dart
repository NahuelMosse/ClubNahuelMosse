import 'dart:async';

import 'package:flutter/material.dart';

/// Durations and curves of the app's motion. Each animation runs once, with its own
/// `AnimationController`, and with reduced motion it shows its final state.
abstract final class AppMotion {
  static const Curve out = Curves.easeOut;
  static const Curve smooth = Curves.easeOutCubic;
  static const Curve fast = Curves.easeOutQuart;
  static const Curve bounce = Curves.easeOutBack;

  static const forward = Duration(milliseconds: 320);
  static const back = Duration(milliseconds: 280);
  static const fade = Duration(milliseconds: 250);
  static const listChange = Duration(milliseconds: 150);
  static const shake = Duration(milliseconds: 360);
  static const heartbeat = Duration(milliseconds: 500);
  static const press = Duration(milliseconds: 80);
  static const entrance = Duration(milliseconds: 400);
  static const step = Duration(milliseconds: 80);
  static const rise = Duration(milliseconds: 450);
}

/// Starts [controller] once, except with reduced motion: then it stays at its end.
void startOnce(AnimationController controller, BuildContext context) {
  if (MediaQuery.disableAnimationsOf(context)) {
    controller.value = 1;
  } else {
    unawaited(controller.forward());
  }
}
