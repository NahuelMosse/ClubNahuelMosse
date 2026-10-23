/// El club está en UTC−3, sin horario de verano: las horas y los días se cuentan así sea cual
/// sea la zona del teléfono.
const _desfase = Duration(hours: 3);

/// El [momento] visto desde el club.
DateTime enElClub(DateTime momento) => momento.toUtc().subtract(_desfase);

/// El instante real de una hora del club.
DateTime instanteDelClub(DateTime horaDelClub) => horaDelClub.add(_desfase);

/// El momento actual en el club.
DateTime ahoraEnElClub() => enElClub(DateTime.now());
