import 'package:flutter/services.dart';

export 'dates.dart' show formatDate;

/// Builds `DD / MM / AAAA` as the digits are typed.
class DateInputFormatter extends TextInputFormatter {
  const DateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      if (i == 2 || i == 4) buffer.write(' / ');
      buffer.write(trimmed[i]);
    }
    final result = buffer.toString();
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

/// Keeps only digits and dots, the way a DNI is written.
final dniInputFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));

/// Turns `DD / MM / AAAA` into a date, or `null` if it is not a date that exists.
DateTime? readDate(String value) {
  final parts = value.trim().split(' / ');
  if (parts.length != 3 ||
      parts[0].length != 2 ||
      parts[1].length != 2 ||
      parts[2].length != 4) {
    return null;
  }
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null || year < 1) return null;
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}
