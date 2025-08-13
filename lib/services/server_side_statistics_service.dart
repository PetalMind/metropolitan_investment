import 'package:cloud_functions/cloud_functions.dart';
import '../models/investor_summary.dart';
import 'unified_statistics_service.dart';

class ServerSideStatisticsService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  // 🔧 PRZEŁĄCZNIK ROZWOJOWY - ustaw na false aby wyłączyć Firebase Functions
  static const bool USE_FIREBASE_FUNCTIONS = false;

  /// Oblicza zunifikowane statystyki produktu PO STRONIE SERWERA
  static Future<UnifiedProductStatistics> calculateProductStatistics(
    List<InvestorSummary> investors,
    String productName, {
    bool isLoadingInvestors = false,
  }) async {
    // 🔧 PRZEŁĄCZNIK: Jeśli wyłączone Firebase Functions, użyj od razu fallback
    if (!USE_FIREBASE_FUNCTIONS) {
      return _calculateFallbackStatistics(investors, productName);
    }

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

    // ⚠️ WALIDACJA PRODUKTU: Sprawdź czy productName nie jest pusty
    if (productName.trim().isEmpty) {
      return _calculateFallbackStatistics(investors, productName);
    }

    try {

      // Przygotuj dane inwestycji do przesłania
      final List<Map<String, dynamic>> investmentsData = [];
      int processedInvestors = 0;
      int processedInvestments = 0;

      for (final investor in investors) {
        processedInvestors++;

        for (final investment in investor.investments) {
          if (investment.productName == productName) {
            processedInvestments++;

            // Konwertuj Investment na Map zgodnie z oczekiwaniami serwera
            investmentsData.add({
              'id': investment.id,
              'clientId': investment.clientId,
              'clientName': investment.clientName,
              'productName': investment.productName,
              'investmentAmount': investment.investmentAmount,
              'remainingCapital': investment.remainingCapital,
              'capitalForRestructuring': investment.capitalForRestructuring,
              'capitalSecuredByRealEstate':
                  investment.capitalSecuredByRealEstate,
              'productStatus': investment.status.displayName,
              // Dodatkowe pola potrzebne dla serwera
              'realizedCapital': investment.realizedCapital,
              'remainingInterest': investment.remainingInterest,
              'transferToOtherProduct': investment.transferToOtherProduct,
            });
          }
        }
      }

      // ⚠️ WALIDACJA: Sprawdź czy mamy dane do przesłania
      if (investmentsData.isEmpty) {
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

      print('  - productName.trim().isEmpty: ${productName.trim().isEmpty}');

      // ⚠️ DRUGA WALIDACJA: Sprawdź jeszcze raz przed wywołaniem Firebase
      if (productName.trim().isEmpty) {
        throw Exception('productName nie może być pusty');
      }

      // Wywołaj Firebase Function
      final HttpsCallable callable = _functions.httpsCallable(
        'getProductStatistics',
      );

      final parameters = {
        'productName': productName,
        'investments': investmentsData,
      };

      final result = await callable.call(parameters);

      final Map<String, dynamic> data = result.data;

      if (data['success'] != true) {
        throw Exception('Serwer zwrócił błąd: ${data['error']}');
      }

      final Map<String, dynamic> statistics = data['statistics'];

      return UnifiedProductStatistics(
        totalInvestmentAmount: (statistics['totalInvestmentAmount'] ?? 0)
            .toDouble(),
        totalRemainingCapital: (statistics['totalRemainingCapital'] ?? 0)
            .toDouble(),
        totalCapitalSecuredByRealEstate:
            (statistics['totalCapitalSecuredByRealEstate'] ?? 0).toDouble(),
        totalCapitalForRestructuring:
            (statistics['totalCapitalForRestructuring'] ?? 0).toDouble(),
        viableCapital: (statistics['viableCapital'] ?? 0).toDouble(),
        majorityThreshold: (statistics['majorityThreshold'] ?? 0).toDouble(),
        investorsCount: statistics['investorsCount'] ?? 0,
        activeInvestorsCount: statistics['activeInvestorsCount'] ?? 0,
        majorityVotingCapacity: (statistics['majorityVotingCapacity'] ?? 0.0)
            .toDouble(),
        hasInactiveInvestors: statistics['hasInactiveInvestors'] ?? false,
      );
    } catch (error) {

      // Fallback do lokalnych obliczeń w przypadku błędu serwera
      return _calculateFallbackStatistics(investors, productName);
    }
  }

  /// Fallback - podstawowe obliczenia lokalne w przypadku błędu serwera
  static UnifiedProductStatistics _calculateFallbackStatistics(
    List<InvestorSummary> investors,
    String productName,
  ) {

    double totalInvestmentAmount = 0.0;
    double totalRemainingCapital = 0.0;
    double totalCapitalForRestructuring = 0.0;
    int activeInvestorsCount = 0;
    bool hasInactiveInvestors = false;

    // 🔧 DEDUPLIKACJA - użyj Set do śledzenia przetworzonych inwestycji
    final Set<String> processedInvestmentIds = {};
    final Map<String, double> recordedCapitalForRestructuring = {};

    for (final investor in investors) {
      if (investor.client.votingStatus.name == 'inactive') {
        hasInactiveInvestors = true;
        continue;
      }
      activeInvestorsCount++;

      for (final investment in investor.investments) {
        if (investment.productName == productName) {
          // 🚨 DEDUPLIKACJA - sprawdź czy już przetwarzaliśmy tę inwestycję
          if (processedInvestmentIds.contains(investment.id)) {
            final existing =
                recordedCapitalForRestructuring[investment.id] ?? 0.0;
            final current = investment.capitalForRestructuring;
            if (current > existing) {
              final diff = current - existing;
              totalCapitalForRestructuring += diff;
              recordedCapitalForRestructuring[investment.id] = current;
            } else {
            }
            continue;
          }
          processedInvestmentIds.add(investment.id);

          totalInvestmentAmount += investment.investmentAmount;
          totalRemainingCapital += investment.remainingCapital;
          totalCapitalForRestructuring += investment.capitalForRestructuring;
          recordedCapitalForRestructuring[investment.id] =
              investment.capitalForRestructuring;

        }
      }
    }

    // 🎯 OBLICZ totalCapitalSecuredByRealEstate NA KOŃCU Z WZORU - TAKA SAMA LOGIKA JAK W UNIFIED_STATISTICS_SERVICE
    final totalCapitalSecuredByRealEstate =
        (totalRemainingCapital - totalCapitalForRestructuring).clamp(
          0.0,
          double.infinity,
        );

    final viableCapital = totalRemainingCapital;
    final majorityThreshold = viableCapital * 0.5;
    final majorityVotingCapacity = viableCapital > 0
        ? (majorityThreshold / viableCapital) * 100
        : 0.0;

    return UnifiedProductStatistics(
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
