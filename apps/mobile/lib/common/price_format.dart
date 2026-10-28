// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _thousands = NumberFormat.decimalPattern('es_AR');
final _nonDigit = RegExp(r'\D');
final _digit = RegExp(r'\d');

/// `$ 38.000`: whole pesos with a thousands dot. The space does not break: the sign never
/// ends up alone at the end of a line.
String formatPesos(int amount) => '\$ ${_thousands.format(amount)}';

/// Reads what [PriceInputFormatter] left: only the digits, or `null` if there are none.
int? readPrice(String text) {
  final digits = text.replaceAll(_nonDigit, '');
  return digits.isEmpty ? null : int.tryParse(digits);
}

/// While typing, leaves `$ ` and only digits (up to [max]) with the thousands dots.
/// Pesos are whole numbers: whatever is pasted with cents («1.500,00») is cut at the comma.
class PriceInputFormatter extends TextInputFormatter {
  const PriceInputFormatter({this.max = 7});

  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    var cursor = newValue.selection.isValid
        ? newValue.selection.extentOffset
        : text.length;
    final comma = text.indexOf(',');
    if (comma >= 0) {
      text = text.substring(0, comma);
      if (cursor > comma) cursor = comma;
    }
    // Deleting right over a thousands dot does not change the digits: the previous one goes.
    final deletedSeparator =
        oldValue.text.length == text.length + 1 &&
        text.replaceAll(_nonDigit, '') ==
            oldValue.text.replaceAll(_nonDigit, '');
    if (deletedSeparator && cursor > 0) {
      final previousDigit = text.substring(0, cursor).lastIndexOf(_digit);
      if (previousDigit >= 0) {
        text =
            text.substring(0, previousDigit) +
            text.substring(previousDigit + 1);
        cursor = previousDigit;
      }
    }
    final digitsBefore = text
        .substring(0, cursor.clamp(0, text.length))
        .replaceAll(_nonDigit, '')
        .length;
    final digits = text.replaceAll(_nonDigit, '');
    if (digits.isEmpty) return const TextEditingValue();
    if (digits.length > max) return oldValue;
    final formatted = formatPesos(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: _offsetAfter(formatted, digitsBefore),
      ),
    );
  }

  /// The position in [text] right after its first [n] digits.
  static int _offsetAfter(String text, int n) {
    if (n == 0) return text.indexOf(_digit);
    var seen = 0;
    for (var i = 0; i < text.length; i++) {
      if (_digit.hasMatch(text[i]) && ++seen == n) return i + 1;
    }
    return text.length;
  }
}
