import 'package:flutter/services.dart';

class CardNumberInputFormatter extends TextInputFormatter {
  static const int _maxDigitsNonNumo = 16;
  static const int _maxDigitsNumo = 19;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Determine if this is a NUMO card based on prefix
    final isNumo = isNumoCard(digits);
    final maxDigits = isNumo ? _maxDigitsNumo : _maxDigitsNonNumo;

    final clamped =
        digits.length > maxDigits ? digits.substring(0, maxDigits) : digits;

    // Format: NUMO cards are [0000] [0000] [0000] [0000] [000]
    // Non-NUMO cards are [0000] [0000] [0000] [0000]
    final buffer = StringBuffer();
    for (var i = 0; i < clamped.length; i++) {
      if (isNumo) {
        // NUMO: space after 4, 8, 12, 16 digits
        if (i > 0 && i % 4 == 0 && i < 16) buffer.write(' ');
      } else {
        // Non-NUMO: space after 4, 8, 12 digits
        if (i > 0 && i % 4 == 0) buffer.write(' ');
      }
      buffer.write(clamped[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited =
        digitsOnly.length > 4 ? digitsOnly.substring(0, 4) : digitsOnly;

    String formatted = limited;
    if (limited.length >= 3) {
      formatted = '${limited.substring(0, 2)}/${limited.substring(2)}';
    }

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Detects if a card number is a NUMO card.
/// NUMO cards start with "63" or "8".
bool isNumoCard(String cardNumber) {
  final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return false;
  return RegExp(r'^63\d{0,}$').hasMatch(digits) ||
      RegExp(r'^8\d{0,}$').hasMatch(digits);
}

/// Luhn check on a digits-only PAN.
bool luhnCheck(String digits) {
  if (digits.isEmpty) return false;
  var sum = 0;
  var alt = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    final n = int.tryParse(digits[i]);
    if (n == null) return false;
    var v = n;
    if (alt) {
      v *= 2;
      if (v > 9) v -= 9;
    }
    sum += v;
    alt = !alt;
  }
  return sum % 10 == 0;
}
