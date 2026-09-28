const _dias = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// «Jueves».
String diaDeLaSemana(DateTime dia) => _dias[dia.weekday - 1];

/// «JUE».
String diaAbreviado(DateTime dia) =>
    diaDeLaSemana(dia).substring(0, 3).toUpperCase();

/// «Jue 12 de noviembre».
String fechaLarga(DateTime dia) =>
    '${diaDeLaSemana(dia).substring(0, 3)} ${dia.day} de ${_meses[dia.month - 1]}';

/// «1 hora», «3 horas».
String duracion(int horas) => horas == 1 ? '1 hora' : '$horas horas';
