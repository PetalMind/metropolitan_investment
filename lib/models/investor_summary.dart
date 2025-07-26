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
  final int investmentCount;

  InvestorSummary({
    required this.client,
    required this.investments,
    required this.totalRemainingCapital,
    required this.totalSharesValue,
    required this.totalValue,
    required this.totalInvestmentAmount,
    required this.totalRealizedCapital,
    required this.investmentCount,
  });

  factory InvestorSummary.fromInvestments(
    Client client,
    List<Investment> investments,
  ) {
    double totalRemainingCapital = 0;
    double totalSharesValue = 0;
    double totalInvestmentAmount = 0;
    double totalRealizedCapital = 0;

    for (final investment in investments) {
      if (investment.productType == ProductType.shares) {
        // Dla udziałów liczymy wartość inwestycji
        totalSharesValue += investment.investmentAmount;
      } else {
        // Dla pozostałych produktów liczymy kapitał pozostały
        totalRemainingCapital += investment.remainingCapital;
      }

      totalInvestmentAmount += investment.investmentAmount;
      totalRealizedCapital += investment.realizedCapital;
    }

    final totalValue = totalRemainingCapital + totalSharesValue;

    return InvestorSummary(
      client: client,
      investments: investments,
      totalRemainingCapital: totalRemainingCapital,
      totalSharesValue: totalSharesValue,
      totalValue: totalValue,
      totalInvestmentAmount: totalInvestmentAmount,
      totalRealizedCapital: totalRealizedCapital,
      investmentCount: investments.length,
    );
  }

  // Pomocnicze gettery
  double get percentageOfPortfolio => 0.0; // Będzie obliczane na poziomie listy
  bool get hasUnviableInvestments => client.unviableInvestments.isNotEmpty;

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
      if (investment.productType == ProductType.shares) {
        total += investment.investmentAmount;
      } else {
        total += investment.remainingCapital;
      }
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
