import 'package:clock/clock.dart';

/// El club está en la hora de Argentina: UTC−3, sin horario de verano.
const _diferenciaDelClub = Duration(hours: 3);

/// El momento actual en el club, sea cual sea la zona del teléfono. Es el único lugar que
/// lee el reloj: los tests y las capturas lo fijan con `withClock`.
DateTime ahoraEnElClub() => clock.now().toUtc().subtract(_diferenciaDelClub);
