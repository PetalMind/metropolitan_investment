import 'package:flutter/services.dart';

/// Klasa formatera dla pól kwot z separatorami tysięcznymi
///
/// Obsługuje:
/// - Automatyczne formatowanie z separatorami tysięcznymi (spacje)
/// - Obsługę przecinków i kropek jako separatorów dziesiętnych
/// - Inteligentne pozycjonowanie kursora
/// - Walidację maksymalnej liczby miejsc po przecinku (2)
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Jeśli tekst został usunięty, pozwól na to
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Usuń wszystkie znaki niebędące cyframi, kropkami, przecinkami lub spacjami
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9., ]'), '');

    // Usuń spacje i zamień przecinki na kropki dla jednorodności
    String cleanText = newText.replaceAll(' ', '').replaceAll(',', '.');

    // Sprawdź czy jest więcej niż jedna kropka
    final dotCount = cleanText.split('.').length - 1;
    if (dotCount > 1) {
      return oldValue;
    }

    // Sprawdź czy po kropce jest więcej niż 2 cyfry
    final parts = cleanText.split('.');
    if (parts.length == 2 && parts[1].length > 2) {
      cleanText = '${parts[0]}.${parts[1].substring(0, 2)}';
    }

    // Formatuj z separatorami tysięcznymi
    final formattedText = _formatWithThousandsSeparator(cleanText);

    // Oblicz nową pozycję kursora
    final newCursorPosition = _calculateSmartCursorPosition(
      oldValue: oldValue,
      newValue: newValue,
      formattedText: formattedText,
      cleanText: cleanText,
    );

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(
        offset: newCursorPosition.clamp(0, formattedText.length),
      ),
    );
  }

  /// Oblicza inteligentną pozycję kursora po formatowaniu
  int _calculateSmartCursorPosition({
    required TextEditingValue oldValue,
    required TextEditingValue newValue,
    required String formattedText,
    required String cleanText,
  }) {
    final newCursorPos = newValue.selection.baseOffset;

    // Jeśli usuwamy znaki (Backspace lub Delete)
    if (newValue.text.length < oldValue.text.length) {
      // Znajdź pozycję względem cyfr (bez spacji)
      final textBeforeCursor = newValue.text.substring(
        0,
        newCursorPos.clamp(0, newValue.text.length),
      );
      final digitsBeforeCursor = textBeforeCursor
          .replaceAll(RegExp(r'[^0-9.]'), '')
          .length;

      // Znajdź odpowiadającą pozycję w sformatowanym tekście
      return _findPositionAfterNDigits(formattedText, digitsBeforeCursor);
    }

    // Jeśli dodajemy znaki
    if (newValue.text.length > oldValue.text.length) {
      // Pozycjonuj kursor po ostatnio dodanej cyfrze
      final textBeforeCursor = newValue.text.substring(
        0,
        newCursorPos.clamp(0, newValue.text.length),
      );
      final digitsBeforeCursor = textBeforeCursor
          .replaceAll(RegExp(r'[^0-9.]'), '')
          .length;

      return _findPositionAfterNDigits(formattedText, digitsBeforeCursor);
    }

    // Jeśli nie ma zmiany długości (np. zastąpienie znaku)
    // Zachowaj obecną pozycję jeśli jest sensowna
    final proposedPosition = newCursorPos.clamp(0, formattedText.length);

    // Sprawdź czy pozycja nie jest w środku spacji - jeśli tak, przesuń za spację
    if (proposedPosition < formattedText.length &&
        formattedText[proposedPosition] == ' ') {
      return (proposedPosition + 1).clamp(0, formattedText.length);
    }

    return proposedPosition;
  }

  /// Znajduje pozycję w tekście po N cyfrach/kropkach
  int _findPositionAfterNDigits(String text, int targetDigitCount) {
    int digitCount = 0;

    for (int i = 0; i < text.length; i++) {
      if (RegExp(r'[0-9.]').hasMatch(text[i])) {
        digitCount++;
        if (digitCount >= targetDigitCount) {
          return i + 1;
        }
      }
    }

    return text.length; // Jeśli nie znaleziono, idź na koniec
  }

  /// Formatuje wartość z separatorami tysięcznymi (spacje)
  String _formatWithThousandsSeparator(String value) {
    if (value.isEmpty) return '';

    final parts = value.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    // Dodaj separatory tysięczne (spacje)
    String formatted = '';
    for (int i = integerPart.length - 1; i >= 0; i--) {
      formatted = integerPart[i] + formatted;
      if ((integerPart.length - i) % 3 == 0 && i != 0) {
        formatted = ' $formatted';
      }
    }

    return formatted + decimalPart;
  }
}
