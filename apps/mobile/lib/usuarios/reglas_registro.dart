/// Las mismas reglas del registro que valida la API, para avisar mientras se escribe.
/// Los mensajes son idénticos a los que devuelve `POST /registro`.
library;

const largoMaximoNombre = 60;

String? validarNombre(String valor, {required String obligatorio}) {
  final limpio = valor.trim();
  if (limpio.isEmpty) return obligatorio;
  if (limpio.runes.length > largoMaximoNombre) {
    return 'Máximo $largoMaximoNombre caracteres';
  }
  return null;
}

String normalizarDni(String dni) => dni.replaceAll(RegExp(r'[.\s]'), '');

String? validarDni(String valor) {
  final dni = normalizarDni(valor.trim());
  if (dni.isEmpty) return 'El DNI es obligatorio';
  if (!RegExp(r'^[0-9]{7,8}$').hasMatch(dni)) {
    return 'El DNI tiene 7 u 8 números';
  }
  return null;
}

/// Convierte `DD / MM / AAAA` en fecha, o `null` si no es una fecha que exista.
DateTime? leerFecha(String valor) {
  final partes = valor.trim().split(' / ');
  if (partes.length != 3 ||
      partes[0].length != 2 ||
      partes[1].length != 2 ||
      partes[2].length != 4) {
    return null;
  }
  final dia = int.tryParse(partes[0]);
  final mes = int.tryParse(partes[1]);
  final anio = int.tryParse(partes[2]);
  if (dia == null || mes == null || anio == null || anio < 1) return null;
  final fecha = DateTime(anio, mes, dia);
  if (fecha.year != anio || fecha.month != mes || fecha.day != dia) return null;
  return fecha;
}

String? validarFechaNacimiento(String valor, DateTime hoy) {
  if (valor.trim().isEmpty) return 'La fecha de nacimiento es obligatoria';
  final fecha = leerFecha(valor);
  if (fecha == null) return 'La fecha no es válida';
  if (!fecha.isBefore(DateTime(hoy.year, hoy.month, hoy.day))) {
    return 'La fecha tiene que ser anterior a hoy';
  }
  return null;
}

String? validarCorreo(String valor) {
  final correo = valor.trim().toLowerCase();
  if (correo.isEmpty) return 'El correo es obligatorio';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo)) {
    return 'Revisá el formato del correo';
  }
  return null;
}

/// Las reglas que no cumple, en el orden en que las muestra la app.
List<String> problemasContrasena(String contrasena) => [
  if (contrasena.runes.length < 8) 'Al menos 8 caracteres',
  if (!RegExp(r'[A-ZÁÉÍÓÚÑ]').hasMatch(contrasena)) 'Una letra mayúscula',
  if (!RegExp(r'[0-9]').hasMatch(contrasena)) 'Al menos un número',
];

String? validarContrasena(String valor) {
  if (valor.isEmpty) return 'La contraseña es obligatoria';
  final faltan = problemasContrasena(valor);
  return faltan.isEmpty ? null : faltan.first;
}

String _dos(int n) => n.toString().padLeft(2, '0');

/// La fecha en el formato que espera la API (`AAAA-MM-DD`).
String fechaIso(DateTime fecha) =>
    '${fecha.year.toString().padLeft(4, '0')}-${_dos(fecha.month)}-${_dos(fecha.day)}';

/// La fecha como se escribe en el campo (`DD / MM / AAAA`), la inversa de [leerFecha].
String formatearFecha(DateTime fecha) =>
    '${_dos(fecha.day)} / ${_dos(fecha.month)} / ${fecha.year}';

/// La fecha para leer, como en el perfil (`DD/MM/AAAA`).
String fechaLegible(DateTime fecha) =>
    '${_dos(fecha.day)}/${_dos(fecha.month)}/${fecha.year}';

/// El DNI con los puntos de mil, como se lee en el documento: `42.118.507`.
String dniLegible(String dni) {
  final digitos = normalizarDni(dni);
  final grupos = <String>[];
  for (var fin = digitos.length; fin > 0; fin -= 3) {
    grupos.insert(0, digitos.substring(fin - 3 < 0 ? 0 : fin - 3, fin));
  }
  return grupos.join('.');
}
