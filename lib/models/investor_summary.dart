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
    // � DEBUG - wyłączone dla lepszej wydajności (włącz tylko gdy potrzebne)
    // print('🔍 [InvestorSummary.fromInvestments] Obliczanie dla klienta: ${client.name}');
    // print('  - Liczba inwestycji: ${investments.length}');

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
    double capitalForRestructuring =
        0; // Teraz traktowane identycznie jak remainingCapital – bez dodatkowych fallbacków tutaj

    for (final investment in investments) {
      // � DEBUG - wyłączone dla lepszej wydajności (włącz tylko gdy potrzebne)
      // print('    - Inwestycja ${investment.id}: ${investment.productName}');
      // print('      * remainingCapital: ${investment.remainingCapital}');
      // print('      * investmentAmount: ${investment.investmentAmount}');

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
        final capitalForRestructuringValue = investment.capitalForRestructuring;
        final result =
            investment.remainingCapital - capitalForRestructuringValue;
        investmentCapitalSecured = result > 0 ? result : 0.0;
      }

      capitalSecuredByRealEstate += investmentCapitalSecured;

      // Sumowanie capitalForRestructuring bez dodatkowych lokalnych fallbacków (logika fallback w Investment.fromFirestore)
      capitalForRestructuring += investment.capitalForRestructuring;
    }

    // ⭐ WARTOŚĆ CAŁKOWITA = TYLKO kapitał pozostały
    final totalValue = totalRemainingCapital;

    // � DEBUG - wyłączone dla lepszej wydajności (włącz tylko gdy potrzebne)
    // print('  ⭐ OBLICZONE SUMY:');
    // print('    - totalInvestmentAmount: $totalInvestmentAmount');
    // print('    - totalRemainingCapital: $totalRemainingCapital');
    // print('    - totalValue: $totalValue');
    // print('    - capitalSecuredByRealEstate: $capitalSecuredByRealEstate');
    // print('    - capitalForRestructuring: $capitalForRestructuring');

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

  /// 🚀 NOWY: Tylko zbiera dane bez obliczeń - obliczenia na końcu dla wszystkich inwestorów
  /// Używaj tej metody zamiast fromInvestments() gdy chcesz unikać obliczeń dla każdego klienta
  factory InvestorSummary.withoutCalculations(
    Client client,
    List<Investment> investments,
  ) {
    print(
      '✅ [InvestorSummary.withoutCalculations] Zbieranie danych dla: ${client.name} (${investments.length} inwestycji)',
    );

    // ✅ TYLKO ZBIERANIE DANYCH - bez obliczeń zabezpieczonego kapitału
    double totalRemainingCapital = 0;
    double totalInvestmentAmount = 0;
    double totalRealizedCapital = 0;
    double capitalForRestructuring =
        0; // identyczne traktowanie jak remainingCapital

    for (final investment in investments) {
      // Podstawowe sumy - bez skomplikowanych obliczeń
      totalRemainingCapital += investment.remainingCapital;
      totalInvestmentAmount += investment.investmentAmount;
      totalRealizedCapital += investment.realizedCapital;

      // Sumowanie direct – analogicznie do remainingCapital
      capitalForRestructuring += investment.capitalForRestructuring;
    }

    print(
      '  💰 Zebrane kwoty: remainingCapital=${totalRemainingCapital}, capitalForRestructuring=${capitalForRestructuring}',
    );

    // Automatyczne obliczenie jako fallback
    // Na razie zwracamy tylko zebrane dane z Firebase
    return InvestorSummary(
      client: client,
      investments: investments,
      totalRemainingCapital: totalRemainingCapital,
      totalSharesValue: 0, // Zawsze 0 dla kompatybilności
      totalValue: totalRemainingCapital, // Prosta wartość bez obliczeń
      totalInvestmentAmount: totalInvestmentAmount,
      totalRealizedCapital: totalRealizedCapital,
      capitalSecuredByRealEstate:
          0, // ⚠️ NIE OBLICZANE - będzie obliczone na końcu
      capitalForRestructuring: capitalForRestructuring,
      investmentCount: investments.length,
    );
  }

  /// 🧮 OBLICZENIA NA KOŃCU: Oblicza capitalSecuredByRealEstate dla wszystkich inwestorów jednocześnie
  /// Używaj po utworzeniu wszystkich InvestorSummary za pomocą withoutCalculations()
  static List<InvestorSummary> calculateSecuredCapitalForAll(
    List<InvestorSummary> investors,
  ) {
    print(
      '🧮 [InvestorSummary.calculateSecuredCapitalForAll] Obliczanie dla ${investors.length} inwestorów',
    );

    // Zsumuj wszystkie kwoty
    double totalRemainingCapital = 0;
    double totalCapitalForRestructuring = 0;

    for (final investor in investors) {
      totalRemainingCapital += investor.totalRemainingCapital;
      totalCapitalForRestructuring += investor.capitalForRestructuring;
    }

    // JEDYNE OBLICZENIE - NA KOŃCU dla wszystkich zsumowanych kwot
    final totalCapitalSecuredByRealEstate =
        (totalRemainingCapital - totalCapitalForRestructuring).clamp(
          0.0,
          double.infinity,
        );

    print('  📊 WYNIKI OBLICZEŃ:');
    print('    - Zsumowany remainingCapital: ${totalRemainingCapital}');
    print(
      '    - Zsumowany capitalForRestructuring: ${totalCapitalForRestructuring}',
    );
    print(
      '    - 🎯 Obliczony capitalSecuredByRealEstate: ${totalCapitalSecuredByRealEstate}',
    );

    // Teraz oblicz proporcjonalnie dla każdego inwestora
    final List<InvestorSummary> updatedInvestors = [];

    for (final investor in investors) {
      // Oblicz proporcję tego inwestora w całości
      final proportion = totalRemainingCapital > 0
          ? investor.totalRemainingCapital / totalRemainingCapital
          : 0.0;

      final investorSecuredCapital =
          totalCapitalSecuredByRealEstate * proportion;

      print(
        '    - ${investor.client.name}: ${investor.totalRemainingCapital} PLN (${(proportion * 100).toStringAsFixed(1)}%) → secured: ${investorSecuredCapital.toStringAsFixed(2)}',
      );

      // Stwórz nowy obiekt z obliczonym capitalSecuredByRealEstate
      updatedInvestors.add(
        InvestorSummary(
          client: investor.client,
          investments: investor.investments,
          totalRemainingCapital: investor.totalRemainingCapital,
          totalSharesValue: investor.totalSharesValue,
          totalValue: investor.totalValue,
          totalInvestmentAmount: investor.totalInvestmentAmount,
          totalRealizedCapital: investor.totalRealizedCapital,
          capitalSecuredByRealEstate:
              investorSecuredCapital, // ⭐ OBLICZONE PROPORCJONALNIE
          capitalForRestructuring: investor.capitalForRestructuring,
          investmentCount: investor.investmentCount,
        ),
      );
    }

    return updatedInvestors;
  }

  // Pomocnicze gettery
  double get percentageOfPortfolio => 0.0; // Będzie obliczane na poziomie listy
  bool get hasUnviableInvestments => client.unviableInvestments.isNotEmpty;

  // Sformatowana lista inwestycji do wyświetlenia
  String get formattedInvestmentList {
    if (investments.isEmpty) return 'Brak inwestycji';

    return investments
        .map((investment) {
          final remaining = investment.remainingCapital;
          final restructuring = investment.capitalForRestructuring;
          return '${investment.productName}: pozostały=${remaining.toStringAsFixed(2)} PLN | restrukt.=${restructuring.toStringAsFixed(2)} PLN';
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
    final client = Client.fromServerMap(
      map['client'] as Map<String, dynamic>? ?? {},
    );
    final investments = (map['investments'] as List<dynamic>? ?? [])
        .map((item) => Investment.fromServerMap(item as Map<String, dynamic>))
        .toList();

    // ⭐ ZAWSZE oblicz wartości na podstawie rzeczywistych inwestycji
    // Ignoruj błędne dane z Firebase Functions serwera
    return InvestorSummary.fromInvestments(client, investments);
  }
}
