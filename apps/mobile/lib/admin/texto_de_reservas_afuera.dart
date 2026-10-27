import '../comun/fechas.dart';
import '../sedes/sede.dart';
import 'reglas_de_sede.dart';

/// «2 reservas futuras de Sede Morón empiezan antes de las 09:00…», según qué se achicó de
/// la sede [antes] al cambiarla a [apertura], [cierre] y [dias].
String textoDeReservasAfuera(
  int n, {
  required Sede? antes,
  required int apertura,
  required int cierre,
  required List<int> dias,
}) {
  final una = n == 1;
  final sujeto =
      '$n ${una ? 'reserva futura' : 'reservas futuras'} de ${antes?.nombre}';
  final hasta = cierre == 0 ? 24 : cierre;
  final antesApertura = antes == null ? null : deHora(antes.apertura);
  final antesCierre = switch (antes == null ? null : deHora(antes.cierre)) {
    0 => 24,
    final c => c,
  };
  final motivos = [
    if (antesApertura != null && apertura > antesApertura)
      '${una ? 'empieza' : 'empiezan'} antes de las ${horaCerrada(apertura)}',
    if (antesCierre != null && hasta < antesCierre)
      '${una ? 'termina' : 'terminan'} después de las ${horaCerrada(cierre)}',
    if (antes != null && antes.dias.any((d) => !dias.contains(d)))
      '${una ? 'cae' : 'caen'} en un día que la sede deja de abrir',
  ];
  final motivo = motivos.length == 1
      ? motivos.single
      : '${una ? 'queda' : 'quedan'} fuera del horario nuevo';
  return '$sujeto $motivo. Si guardás, ${una ? 'se mantiene' : 'se mantienen'} '
      'en su horario original: el cambio rige para las reservas nuevas.';
}
