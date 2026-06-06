import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return const TextEditingValue(text: '');

    final formatted = _formatWithDots(digitsOnly);

    final cursorPos = formatted.length -
        (digitsOnly.length - _cursorOffset(newValue));

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: cursorPos.clamp(0, formatted.length),
      ),
    );
  }

  String _formatWithDots(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  int _cursorOffset(TextEditingValue value) {
    final beforeCursor = value.text.substring(0, value.selection.start);
    return beforeCursor.replaceAll('.', '').length;
  }
}
