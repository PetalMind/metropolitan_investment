import 'package:intl/intl.dart';

/// Klasa pomocnicza do formatowania walut i liczb z separatorami tysięcznymi
class CurrencyFormatter {
  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'pl_PL');
  static final NumberFormat _integerFormat = NumberFormat('#,##0', 'pl_PL');
  static final NumberFormat _decimalFormat = NumberFormat('#,##0.0', 'pl_PL');

  /// Formatuje kwotę z separatorami tysięcznymi i sufiksem PLN
  /// [amount] - kwota do sformatowania
  /// [showDecimals] - czy pokazywać część dziesiętną (domyślnie true)
  static String formatCurrency(double amount, {bool showDecimals = true}) {
    if (showDecimals) {
      return '${_currencyFormat.format(amount).replaceAll(',', ' ')} PLN';
    } else {
      return '${_integerFormat.format(amount).replaceAll(',', ' ')} PLN';
    }
  }

  /// Formatuje kwotę w skróconej formie (K, M, B)
  /// [amount] - kwota do sformatowania
  static String formatCurrencyShort(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B PLN';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M PLN';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K PLN';
    }
    return '${amount.toStringAsFixed(0)} PLN';
  }

  /// Formatuje liczbę z separatorami tysięcznymi bez waluty
  /// [number] - liczba do sformatowania
  /// [decimals] - liczba miejsc po przecinku (domyślnie 0)
  static String formatNumber(double number, {int decimals = 0}) {
    if (decimals == 0) {
      return _integerFormat.format(number).replaceAll(',', ' ');
    } else if (decimals == 1) {
      return _decimalFormat.format(number).replaceAll(',', ' ');
    } else {
      final format = NumberFormat('#,##0.${'0' * decimals}', 'pl_PL');
      return format.format(number).replaceAll(',', ' ');
    }
  }

  /// Formatuje procent z odpowiednią liczbą miejsc po przecinku
  /// [percentage] - wartość procentowa
  /// [decimals] - liczba miejsc po przecinku (domyślnie 1)
  static String formatPercentage(double percentage, {int decimals = 1}) {
    return '${percentage.toStringAsFixed(decimals)}%';
  }

  /// Format currency with email-specific formatting (spaces as separators)
  /// Used in email templates for consistent PLN formatting
  static String formatCurrencyForEmail(double amount) {
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    // Add spaces every 3 digits from the right
    final reversed = integerPart.split('').reversed.join();
    final spaced = reversed.replaceAllMapped(
      RegExp(r'.{3}'),
      (match) => '${match.group(0)} ',
    );
    final result = spaced.split('').reversed.join().trim();

    return '$result,$decimalPart PLN';
  }
}
