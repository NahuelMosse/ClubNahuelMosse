/// Las reglas de un rango consultado que también valida la API
/// (`GET /espacios/disponibles`), para bloquear la consulta antes de llamarla. Los
/// mensajes son los mismos.
library;

import '../sedes/sede.dart';

const minHoras = 1;
const maxHoras = 4;
const diasALaVista = 7;

/// El momento actual en el club, que está en la hora de Argentina (UTC−3, sin horario de
/// verano), sea cual sea la zona del teléfono.
DateTime ahoraEnElClub() =>
    DateTime.now().toUtc().subtract(const Duration(hours: 3));

/// La hora en punto de `HH:MM`; `null` si no lo es.
int? horaEnPunto(String hhmm) {
  final partes = hhmm.split(':');
  if (partes.length != 2 || partes[1] != '00') return null;
  return int.tryParse(partes[0]);
}

/// «18:00».
String hhmm(int hora) => '${(hora % 24).toString().padLeft(2, '0')}:00';

/// El error de [dia] que no depende de la sede: pasado o fuera de los próximos días.
Map<String, String> erroresDeLaFecha({
  required DateTime dia,
  required DateTime ahora,
}) {
  final hoy = DateTime.utc(ahora.year, ahora.month, ahora.day);
  final fecha = DateTime.utc(dia.year, dia.month, dia.day);
  if (fecha.isBefore(hoy)) return {'fecha': 'La fecha tiene que ser futura'};
  if (!fecha.isBefore(hoy.add(const Duration(days: diasALaVista)))) {
    return {'fecha': 'Elegí un día de los próximos $diasALaVista'};
  }
  return {};
}

/// Los errores por campo (`fecha`, `desde`, `hasta`) del rango [desde] a [hasta] (horas en
/// punto; [hasta] 0 es la medianoche) el [dia] en [sede], con [ahora] en la hora del club.
Map<String, String> erroresDelRango({
  required Sede sede,
  required DateTime dia,
  required int desde,
  required int hasta,
  required DateTime ahora,
}) {
  final errores = erroresDeLaFecha(dia: dia, ahora: ahora);
  final hoy = DateTime.utc(ahora.year, ahora.month, ahora.day);
  final fecha = DateTime.utc(dia.year, dia.month, dia.day);
  if (errores.isEmpty && !sede.dias.contains(fecha.weekday)) {
    errores['fecha'] = 'La sede no abre ese día';
  }
  final fin = hasta == 0 ? 24 : hasta;
  final apertura = horaEnPunto(sede.apertura) ?? 0;
  final cierre = switch (horaEnPunto(sede.cierre)) {
    0 || null => 24,
    final h => h,
  };
  if (fin - desde < minHoras) {
    errores['hasta'] = 'La duración mínima es de una hora';
  } else if (fin - desde > maxHoras) {
    errores['hasta'] = 'La duración máxima es de $maxHoras horas';
  } else if (fin > cierre) {
    errores['hasta'] = 'La sede cierra a las ${sede.cierre}';
  }
  if (desde < apertura) {
    errores['desde'] = 'La sede abre a las ${sede.apertura}';
  } else if (!errores.containsKey('fecha') &&
      fecha == hoy &&
      desde <= ahora.hour) {
    errores['desde'] = 'El horario tiene que ser futuro';
  }
  return errores;
}
