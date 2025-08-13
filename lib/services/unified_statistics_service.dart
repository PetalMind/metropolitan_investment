import '../models/investor_summary.dart';

class UnifiedStatisticsService {
  /// Oblicza zunifikowane statystyki produktu
  static UnifiedProductStatistics calculateProductStatistics(
    List<InvestorSummary> investors,
    String productName, {
    bool isLoadingInvestors = false,
  }) {
    if (investors.isEmpty || isLoadingInvestors) {
      return UnifiedProductStatistics(
        totalInvestmentAmount: 0,
        totalRemainingCapital: 0,
        totalCapitalSecuredByRealEstate: 0,
        totalCapitalForRestructuring: 0,
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
    double totalCapitalForRestructuring = 0.0; // 🔧 NOWE POLE
    int activeInvestorsCount = 0;
    bool hasInactiveInvestors = false;

    // 🔧 DEDUPLIKACJA - użyj Set do śledzenia przetworzonych inwestycji (GLOBALNIE dla wszystkich inwestorów)
    final Set<String> processedInvestmentIds = {};
    final Map<String, double> recordedCapitalForRestructuring =
        {}; // śledzi wartości by móc uzupełniać przy duplikatach

    for (final investor in investors) {
      if (investor.client.votingStatus.name == 'inactive') {
        hasInactiveInvestors = true;
        continue;
      }
      activeInvestorsCount++;

      for (final investment in investor.investments) {
        // Filtruj tylko inwestycje danego produktu
        if (investment.productName == productName) {
          // 🚨 DEDUPLIKACJA - sprawdź czy już przetwarzaliśmy tę inwestycję
          if (processedInvestmentIds.contains(investment.id)) {
            // 🚧 ULEPSZONE SCALANIE: jeśli pierwotnie capitalForRestructuring było 0 a nowy duplikat ma >0, zaktualizuj sumę różnicą
            final existing =
                recordedCapitalForRestructuring[investment.id] ?? 0.0;
            final current = investment.capitalForRestructuring;
            if (current > existing) {
              final diff = current - existing;
              totalCapitalForRestructuring += diff;
              recordedCapitalForRestructuring[investment.id] = current;
            } else {
              print('    ⚠️ DUPLIKAT POMINIĘTY (bez zmian): ${investment.id}');
            }
            continue;
          }
          processedInvestmentIds.add(investment.id);

          // 📊 SUMUJ TYLKO PODSTAWOWE WARTOŚCI (pierwsze wystąpienie)
          totalInvestmentAmount += investment.investmentAmount;
          totalRemainingCapital += investment.remainingCapital;
          totalCapitalForRestructuring += investment.capitalForRestructuring;
          recordedCapitalForRestructuring[investment.id] =
              investment.capitalForRestructuring;

        }
      }
    }

    // 🎯 OBLICZ totalCapitalSecuredByRealEstate NA KOŃCU Z WZORU
    final totalCapitalSecuredByRealEstate =
        (totalRemainingCapital - totalCapitalForRestructuring).clamp(
          0.0,
          double.infinity,
        );

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
      totalCapitalForRestructuring: totalCapitalForRestructuring,
      viableCapital: viableCapital,
      majorityThreshold: majorityThreshold,
      investorsCount: investors.length,
      activeInvestorsCount: activeInvestorsCount,
      majorityVotingCapacity: majorityVotingCapacity,
      hasInactiveInvestors: hasInactiveInvestors,
    );

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
  final double totalCapitalForRestructuring; // NOWE
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
    required this.totalCapitalForRestructuring,
    required this.viableCapital,
    required this.majorityThreshold,
    required this.investorsCount,
    required this.activeInvestorsCount,
    required this.majorityVotingCapacity,
    required this.hasInactiveInvestors,
  });
}
