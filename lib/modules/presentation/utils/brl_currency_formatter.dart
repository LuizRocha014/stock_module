import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Exibe e edita valores em real (pt_BR), ex.: R$ 1.234,56.
class BrlCurrencyInputFormatter extends TextInputFormatter {
  static String formatDouble(double value) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    ).format(value);
  }

  static double parseToDouble(String text) {
    if (text.trim().isEmpty) return 0;
    var s = text.replaceAll('R\$', '').replaceAll(RegExp(r'\s'), '').trim();
    if (s.isEmpty) return 0;
    final lastComma = s.lastIndexOf(',');
    if (lastComma >= 0) {
      final intPart = s.substring(0, lastComma).replaceAll('.', '');
      final dec = s.substring(lastComma + 1);
      s = '$intPart.$dec';
    } else {
      s = s.replaceAll('.', '');
    }
    return double.tryParse(s) ?? 0;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return oldValue;
    }

    final value = int.parse(digits) / 100.0;
    final formatted = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    ).format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
