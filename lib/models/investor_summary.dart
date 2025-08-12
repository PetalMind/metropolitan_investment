import 'client.dart';
import 'investment.dart';

class InvestorSummary {
  final Client client;
  final List<Investment> investments;
  final double totalRemainingCapital;
  final double totalSharesValue;
  final double totalValue; // Suma kapitału pozostałego + udziały
  final double totalInvestmentAmount;
  final double totalRealizedCapital;
  final double
  capitalSecuredByRealEstate; // kapital_zabezpieczony_nieruchomoscia
  final double capitalForRestructuring; // kapital_na_restrukturyzacje
  final int investmentCount;

  InvestorSummary({
    required this.client,
    required this.investments,
    required this.totalRemainingCapital,
    required this.totalSharesValue,
    required this.totalValue,
    required this.totalInvestmentAmount,
    required this.totalRealizedCapital,
    required this.capitalSecuredByRealEstate,
    required this.capitalForRestructuring,
    required this.investmentCount,
  });

  factory InvestorSummary.fromInvestments(
    Client client,
    List<Investment> investments,
  ) {
    // Helper function to parse capital values with commas
    double parseCapitalValue(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        // Handle string values like "200,000.00" from Firebase
        final cleaned = value.toString().replaceAll(',', '');
        final parsed = double.tryParse(cleaned);
        return parsed ?? 0.0;
      }
      return 0.0;
    }

    double totalRemainingCapital = 0;
    double totalSharesValue =
        0; // Zachowujemy dla kompatybilności, ale zawsze = 0
    double totalInvestmentAmount = 0;
    double totalRealizedCapital = 0;
    double capitalSecuredByRealEstate = 0;
    double capitalForRestructuring = 0;

    for (final investment in investments) {
      // ⭐ TYLKO KAPITAŁ POZOSTAŁY - dla wszystkich typów produktów
      totalRemainingCapital += investment.remainingCapital;

      // Zachowujemy inne pola dla kompatybilności wstecznej
      totalInvestmentAmount += investment.investmentAmount;
      totalRealizedCapital += investment.realizedCapital;

      // 🏗️ POBIERZ DODATKOWE POLA - sprawdź główny poziom PIERWSZE, potem additionalInfo
      // Mapowanie dla kapitału zabezpieczonego nieruchomością - z automatycznym fallback
      double investmentCapitalSecured = 0.0;

      // Najpierw sprawdź bezpośrednie pola na głównym poziomie
      if (investment.additionalInfo.containsKey('capitalSecuredByRealEstate')) {
        investmentCapitalSecured = parseCapitalValue(
          investment.additionalInfo['capitalSecuredByRealEstate'],
        );
      } else if (investment.additionalInfo['realEstateSecuredCapital'] !=
          null) {
        investmentCapitalSecured = parseCapitalValue(
          investment.additionalInfo['realEstateSecuredCapital'],
        );
      } else if (investment
              .additionalInfo['Kapitał zabezpieczony nieruchomością'] !=
          null) {
        investmentCapitalSecured = parseCapitalValue(
          investment.additionalInfo['Kapitał zabezpieczony nieruchomością'],
        );
      } else if (investment
              .additionalInfo['kapital_zabezpieczony_nieruchomoscia'] !=
          null) {
        investmentCapitalSecured = parseCapitalValue(
          investment.additionalInfo['kapital_zabezpieczony_nieruchomoscia'],
        );
      } else {
        // Automatyczne obliczenie jako fallback
        final capitalForRestructuringValue = parseCapitalValue(
          investment.additionalInfo['capitalForRestructuring'] ??
              investment.additionalInfo['Kapitał do restrukturyzacji'] ??
              investment.additionalInfo['kapital_do_restrukturyzacji'],
        );
        final result =
            investment.remainingCapital - capitalForRestructuringValue;
        investmentCapitalSecured = result > 0 ? result : 0.0;
      }

      capitalSecuredByRealEstate += investmentCapitalSecured;

      // Mapowanie dla kapitału do restrukturyzacji
      if (investment.additionalInfo['capitalForRestructuring'] != null) {
        final value = investment.additionalInfo['capitalForRestructuring'];
        capitalForRestructuring += parseCapitalValue(value);
      } else if (investment.additionalInfo['Kapitał do restrukturyzacji'] !=
          null) {
        final value = investment.additionalInfo['Kapitał do restrukturyzacji'];
        capitalForRestructuring += parseCapitalValue(value);
      } else if (investment.additionalInfo['kapital_do_restrukturyzacji'] !=
          null) {
        final value = investment.additionalInfo['kapital_do_restrukturyzacji'];
        capitalForRestructuring += parseCapitalValue(value);
      }
    }

    // ⭐ WARTOŚĆ CAŁKOWITA = TYLKO kapitał pozostały
    final totalValue = totalRemainingCapital;

    return InvestorSummary(
      client: client,
      investments: investments,
      totalRemainingCapital: totalRemainingCapital,
      totalSharesValue: totalSharesValue,
      totalValue: totalValue,
      totalInvestmentAmount: totalInvestmentAmount,
      totalRealizedCapital: totalRealizedCapital,
      capitalSecuredByRealEstate: capitalSecuredByRealEstate,
      capitalForRestructuring: capitalForRestructuring,
      investmentCount: investments.length,
    );
  }

  // Pomocnicze gettery
  double get percentageOfPortfolio => 0.0; // Będzie obliczane na poziomie listy
  bool get hasUnviableInvestments => client.unviableInvestments.isNotEmpty;

  // Sformatowana lista inwestycji do wyświetlenia
  String get formattedInvestmentList {
    if (investments.isEmpty) return 'Brak inwestycji';

    return investments
        .map((investment) {
          // ⭐ TYLKO KAPITAŁ POZOSTAŁY - dla wszystkich typów produktów
          final amount = investment.remainingCapital;
          return '${investment.productName}: ${amount.toStringAsFixed(2)} PLN';
        })
        .join('\n');
  }

  // Produkty które są niewykonalne
  List<Investment> get unviableInvestments => investments
      .where((inv) => client.unviableInvestments.contains(inv.id))
      .toList();

  // Produkty wykonalne
  List<Investment> get viableInvestments => investments
      .where((inv) => !client.unviableInvestments.contains(inv.id))
      .toList();

  double get viableRemainingCapital {
    double total = 0;
    for (final investment in viableInvestments) {
      // ⭐ TYLKO KAPITAŁ POZOSTAŁY - dla wszystkich typów produktów
      total += investment.remainingCapital;
    }
    return total;
  }

  // Grupowanie inwestycji według firmy
  Map<String, List<Investment>> get investmentsByCompany {
    final Map<String, List<Investment>> grouped = {};
    for (final investment in investments) {
      final company = investment.creditorCompany.isNotEmpty
          ? investment.creditorCompany
          : investment.companyId;
      grouped.putIfAbsent(company, () => []).add(investment);
    }
    return grouped;
  }

  /// Tworzy obiekt InvestorSummary z mapy danych
  factory InvestorSummary.fromMap(Map<String, dynamic> map) {
    // Helper function to parse capital values with commas
    double parseCapitalValue(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        // Handle empty strings and NULL values
        if (value.isEmpty ||
            value.trim().isEmpty ||
            value.toUpperCase() == 'NULL') {
          return 0.0;
        }

        // Debug logging for problematic values
        if (value.contains(',')) {
          print(
            '🔍 [InvestorSummary] Parsowanie wartości z przecinkiem: "$value"',
          );
        }
        // Handle string values like "200,000.00" from Firebase
        final cleaned = value.toString().replaceAll(',', '');
        final parsed = double.tryParse(cleaned);
        if (parsed == null) {
          print(
            '❌ [InvestorSummary] Nie można sparsować: "$value" -> "$cleaned"',
          );
        }
        return parsed ?? 0.0;
      }
      return 0.0;
    }

    return InvestorSummary(
      client: Client.fromServerMap(
        map['client'] as Map<String, dynamic>? ?? {},
      ),
      investments: (map['investments'] as List<dynamic>? ?? [])
          .map((item) => Investment.fromServerMap(item as Map<String, dynamic>))
          .toList(),
      totalRemainingCapital: parseCapitalValue(map['totalRemainingCapital']),
      totalSharesValue: parseCapitalValue(map['totalSharesValue']),
      totalValue: parseCapitalValue(map['totalValue']),
      totalInvestmentAmount: parseCapitalValue(map['totalInvestmentAmount']),
      totalRealizedCapital: parseCapitalValue(map['totalRealizedCapital']),
      capitalSecuredByRealEstate: parseCapitalValue(
        map['capitalSecuredByRealEstate'],
      ),
      capitalForRestructuring: parseCapitalValue(
        map['capitalForRestructuring'],
      ),
      investmentCount: map['investmentCount'] as int? ?? 0,
    );
  }
}
