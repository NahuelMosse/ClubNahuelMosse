import 'package:flutter/services.dart';

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
