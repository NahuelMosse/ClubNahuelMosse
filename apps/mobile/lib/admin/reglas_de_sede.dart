const largoDelNombreDeSede = 60;
const largoDeLaDireccionDeSede = 80;
final _calleYAltura = RegExp(r'^.*\S\s+(\d{1,6})$');

/// `HH:MM` a la hora; `null` si no es una hora en punto.
int? deHora(String hhmm) => switch (hhmm.split(':')) {
  [final h, '00'] => int.tryParse(h),
  _ => null,
};

String? errorDelNombreDeSede(String nombre) =>
    nombre.trim().isEmpty ? 'El nombre es obligatorio' : null;

String? errorDeLaDireccionDeSede(String texto) {
  final direccion = texto.trim();
  if (direccion.isEmpty) return 'La dirección es obligatoria';
  final altura = _calleYAltura.firstMatch(direccion)?.group(1);
  return altura != null && int.parse(altura) > 0
      ? null
      : 'Escribí la calle y la altura';
}

String? errorDeLaApertura(int? apertura) =>
    apertura == null ? 'El horario de apertura es obligatorio' : null;

String? errorDelCierre({required int? cierre, required int? apertura}) {
  if (cierre == null) return 'El horario de cierre es obligatorio';
  // Cerrar a las 00:00 es cerrar a la medianoche.
  if (apertura != null && cierre != 0 && cierre <= apertura) {
    return 'El cierre tiene que ser después de la apertura';
  }
  return null;
}
