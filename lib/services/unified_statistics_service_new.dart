import '../models/investor_summary.dart';

class UnifiedStatisticsService {
  /// Oblicza zunifikowane statystyki produktu
  static UnifiedProductStatistics calculateProductStatistics(
    List<InvestorSummary> investors,
    String productName, {
    bool isLoadingInvestors = false,
  }) {
    if (investors.isEmpty || isLoadingInvestors) {
      print('⚠️ [UnifiedStatisticsService] Brak inwestorów do analizowania');
      return UnifiedProductStatistics(
        totalInvestmentAmount: 0,
        totalRemainingCapital: 0,
        totalCapitalSecuredByRealEstate: 0,
        viableCapital: 0,
        majorityThreshold: 0,
        investorsCount: 0,
        activeInvestorsCount: 0,
        majorityVotingCapacity: 0.0,
        hasInactiveInvestors: false,
      );
    }

    double totalInvestmentAmount = 0.0;
    double totalRemainingCapital = 0.0;
    double totalCapitalSecuredByRealEstate = 0.0;
    int activeInvestorsCount = 0;
    bool hasInactiveInvestors = false;

    print(
      '🔥 [UnifiedStatisticsService] OBLICZANIE STATYSTYK PRODUKTU: $productName',
    );

    for (final investor in investors) {
      if (investor.client.votingStatus.name == 'inactive') {
        hasInactiveInvestors = true;
        continue;
      }
      activeInvestorsCount++;

      for (final investment in investor.investments) {
        // Filtruj tylko inwestycje danego produktu
        if (investment.productName == productName) {
          totalInvestmentAmount += investment.investmentAmount;
          totalRemainingCapital += investment.remainingCapital;

          // 🔥 UŻYWAJ POLA Z GŁÓWNEGO POZIOMU FIREBASE!
          totalCapitalSecuredByRealEstate +=
              investment.capitalSecuredByRealEstate;

          print('  - ${investor.client.name}: ${investment.productName}');
          print('    * investmentAmount: ${investment.investmentAmount}');
          print('    * remainingCapital: ${investment.remainingCapital}');
          print(
            '    * capitalSecuredByRealEstate: ${investment.capitalSecuredByRealEstate}',
          );
        }
      }
    }

    // Oblicz pozostałe metryki
    final viableCapital = totalRemainingCapital;
    final majorityThreshold = viableCapital * 0.5;
    final majorityVotingCapacity = viableCapital > 0
        ? (majorityThreshold / viableCapital) * 100
        : 0.0;

    final statistics = UnifiedProductStatistics(
      totalInvestmentAmount: totalInvestmentAmount,
      totalRemainingCapital: totalRemainingCapital,
      totalCapitalSecuredByRealEstate: totalCapitalSecuredByRealEstate,
      viableCapital: viableCapital,
      majorityThreshold: majorityThreshold,
      investorsCount: investors.length,
      activeInvestorsCount: activeInvestorsCount,
      majorityVotingCapacity: majorityVotingCapacity,
      hasInactiveInvestors: hasInactiveInvestors,
    );

    print('📊 [UnifiedStatisticsService] KOŃCOWE ZUNIFIKOWANE STATYSTYKI:');
    print('  - totalInvestmentAmount: $totalInvestmentAmount');
    print('  - totalRemainingCapital: $totalRemainingCapital');
    print(
      '  - ⭐ totalCapitalSecuredByRealEstate: $totalCapitalSecuredByRealEstate',
    );
    print('  - viableCapital: $viableCapital');
    print('  - investorsCount: ${investors.length}');

    return statistics;
  }

  String formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M PLN';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k PLN';
    }
    return '${amount.toStringAsFixed(0)} PLN';
  }
}

/// Zunifikowane statystyki produktu
class UnifiedProductStatistics {
  final double totalInvestmentAmount;
  final double totalRemainingCapital;
  final double totalCapitalSecuredByRealEstate;
  final double viableCapital;
  final double majorityThreshold;
  final int investorsCount;
  final int activeInvestorsCount;
  final double majorityVotingCapacity;
  final bool hasInactiveInvestors;

  UnifiedProductStatistics({
    required this.totalInvestmentAmount,
    required this.totalRemainingCapital,
    required this.totalCapitalSecuredByRealEstate,
    required this.viableCapital,
    required this.majorityThreshold,
    required this.investorsCount,
    required this.activeInvestorsCount,
    required this.majorityVotingCapacity,
    required this.hasInactiveInvestors,
  });
}
