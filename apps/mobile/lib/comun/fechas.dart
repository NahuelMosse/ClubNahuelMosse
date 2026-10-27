/// Las fechas, las horas, los días y el DNI como se muestran en la app. `intl` da los
/// nombres en minúscula; acá se les pone la mayúscula inicial o se pasan a mayúsculas.
/// Los datos de `es` los carga `initializeDateFormatting` al arrancar y en los tests.
library;

import 'package:intl/intl.dart';

import 'reglas_registro.dart' show normalizarDni;

const _idioma = 'es';

String _inicial(String texto) => toBeginningOfSentenceCase(texto, _idioma)!;

/// «Jueves».
String diaDeLaSemana(DateTime dia) =>
    _inicial(DateFormat.EEEE(_idioma).format(dia));

/// «JUE».
String diaAbreviado(DateTime dia) =>
    DateFormat.E(_idioma).format(dia).toUpperCase();

/// «Jue» para el día de la semana [dia], de 1 (lunes) a 7 (domingo).
String diaDeLaSemanaCorto(int dia) =>
    _inicial(DateFormat.E(_idioma).format(DateTime(2024, 1, dia)));

/// «Jue 12».
String diaCorto(DateTime dia) =>
    _inicial(DateFormat('E d', _idioma).format(dia));

/// «Jue 12 nov». El mes abreviado de `intl` es «sept» para septiembre; acá siempre son tres letras.
String fechaCorta(DateTime dia) =>
    '${diaCorto(dia)} ${DateFormat.MMMM(_idioma).format(dia).substring(0, 3)}';

/// «Jue 12 de noviembre».
String fechaLarga(DateTime dia) =>
    _inicial(DateFormat("E d 'de' MMMM", _idioma).format(dia));

/// «1 hora», «3 horas».
String duracion(int horas) => horas == 1 ? '1 hora' : '$horas horas';

/// «09:05».
String horaCorta(DateTime momento) =>
    DateFormat('HH:mm', _idioma).format(momento);

/// «21:00 – 22:00».
String rangoDeHoras(DateTime inicio, DateTime fin) =>
    '${horaCorta(inicio)} – ${horaCorta(fin)}';

/// «18:00»; [hora] 24 es la medianoche.
String horaCerrada(int hora) => horaCorta(DateTime(2000, 1, 1, hora % 24));

/// «04», «12»: la cifra con dos dígitos.
String dosCifras(int n) => NumberFormat('00', _idioma).format(n);

/// La fecha en el formato que espera la API (`AAAA-MM-DD`).
String fechaIso(DateTime fecha) =>
    DateFormat('yyyy-MM-dd', _idioma).format(fecha);

/// La fecha para leer, como en el perfil (`DD/MM/AAAA`).
String fechaLegible(DateTime fecha) =>
    DateFormat('dd/MM/yyyy', _idioma).format(fecha);

/// El día y el mes de la fecha (`DD/MM`).
String diaYMes(DateTime fecha) => DateFormat('dd/MM', _idioma).format(fecha);

/// La fecha como se escribe en el campo (`DD / MM / AAAA`).
String formatearFecha(DateTime fecha) =>
    DateFormat('dd / MM / yyyy', _idioma).format(fecha);

/// El DNI con los puntos de mil, como se lee en el documento: `42.118.507`. Si no son
/// sólo números se muestra como llega.
String dniLegible(String dni) {
  final digitos = normalizarDni(dni);
  final numero = RegExp(r'^[0-9]+$').hasMatch(digitos)
      ? int.tryParse(digitos)
      : null;
  if (numero == null) return dni;
  return NumberFormat.decimalPattern(_idioma).format(numero);
}
