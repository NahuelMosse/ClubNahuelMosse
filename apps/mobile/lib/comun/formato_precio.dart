import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _miles = NumberFormat.decimalPattern('es_AR');
final _noDigito = RegExp(r'\D');
final _digito = RegExp(r'\d');

/// `$ 38.000`: pesos enteros con punto de miles. El espacio no se corta: el signo no
/// queda solo al final de una línea.
String pesos(int monto) => '\$ ${_miles.format(monto)}';

/// Lee lo que dejó [FormatoPrecio]: sólo los dígitos, o `null` si no hay ninguno.
int? leerPrecio(String texto) {
  final digitos = texto.replaceAll(_noDigito, '');
  return digitos.isEmpty ? null : int.tryParse(digitos);
}

/// Mientras se escribe, deja `$ ` y sólo dígitos (hasta [maximo]) con los puntos de miles.
/// Los pesos son enteros: lo que se pega con centavos («1.500,00») se corta en la coma.
class FormatoPrecio extends TextInputFormatter {
  const FormatoPrecio({this.maximo = 7});

  final int maximo;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) {
    var texto = nuevo.text;
    var cursor = nuevo.selection.isValid
        ? nuevo.selection.extentOffset
        : texto.length;
    final coma = texto.indexOf(',');
    if (coma >= 0) {
      texto = texto.substring(0, coma);
      if (cursor > coma) cursor = coma;
    }
    // Borrar justo sobre un punto de miles no cambia los dígitos: se borra el anterior.
    final borroUnSeparador =
        anterior.text.length == texto.length + 1 &&
        texto.replaceAll(_noDigito, '') ==
            anterior.text.replaceAll(_noDigito, '');
    if (borroUnSeparador && cursor > 0) {
      final anteriorDigito = texto.substring(0, cursor).lastIndexOf(_digito);
      if (anteriorDigito >= 0) {
        texto =
            texto.substring(0, anteriorDigito) +
            texto.substring(anteriorDigito + 1);
        cursor = anteriorDigito;
      }
    }
    final digitosAntes = texto
        .substring(0, cursor.clamp(0, texto.length))
        .replaceAll(_noDigito, '')
        .length;
    final digitos = texto.replaceAll(_noDigito, '');
    if (digitos.isEmpty) return const TextEditingValue();
    if (digitos.length > maximo) return anterior;
    final formateado = pesos(int.parse(digitos));
    return TextEditingValue(
      text: formateado,
      selection: TextSelection.collapsed(
        offset: _despuesDe(formateado, digitosAntes),
      ),
    );
  }

  /// La posición en [texto] que queda justo después de sus primeros [n] dígitos.
  static int _despuesDe(String texto, int n) {
    if (n == 0) return texto.indexOf(_digito);
    var vistos = 0;
    for (var i = 0; i < texto.length; i++) {
      if (_digito.hasMatch(texto[i]) && ++vistos == n) return i + 1;
    }
    return texto.length;
  }
}
