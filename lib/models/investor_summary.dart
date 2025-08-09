import 'client.dart';
import 'investment.dart';
import 'product.dart';

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

      // 🏗️ PRÓBUJ POBRAĆ DODATKOWE POLA Z ADDITIONALINFO - dla aparamentów i innych produktów
      if (investment.additionalInfo['kapital_zabezpieczony_nieruchomoscia'] !=
          null) {
        final value =
            investment.additionalInfo['kapital_zabezpieczony_nieruchomoscia'];
        if (value is num) {
          capitalSecuredByRealEstate += value.toDouble();
        } else if (value is String) {
          capitalSecuredByRealEstate += double.tryParse(value) ?? 0;
        }
      }

      if (investment.additionalInfo['kapital_do_restrukturyzacji'] != null) {
        final value = investment.additionalInfo['kapital_do_restrukturyzacji'];
        if (value is num) {
          capitalForRestructuring += value.toDouble();
        } else if (value is String) {
          capitalForRestructuring += double.tryParse(value) ?? 0;
        }
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
}
