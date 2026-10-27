import 'package:flutter/services.dart';

export 'fechas.dart' show formatearFecha;

/// Arma `DD / MM / AAAA` a medida que se escriben los dígitos.
class FormatoFecha extends TextInputFormatter {
  const FormatoFecha();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) {
    final digitos = nuevo.text.replaceAll(RegExp(r'\D'), '');
    final recorte = digitos.length > 8 ? digitos.substring(0, 8) : digitos;
    final texto = StringBuffer();
    for (var i = 0; i < recorte.length; i++) {
      if (i == 2 || i == 4) texto.write(' / ');
      texto.write(recorte[i]);
    }
    final resultado = texto.toString();
    return TextEditingValue(
      text: resultado,
      selection: TextSelection.collapsed(offset: resultado.length),
    );
  }
}

/// Deja sólo dígitos y puntos, como se escribe un DNI.
final formatoDni = FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));

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
