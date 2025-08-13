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
      print(
        '🔧 [ServerSideStatisticsService] Firebase Functions WYŁĄCZONE - używam fallback',
      );
      return _calculateFallbackStatistics(investors, productName);
    }

    if (investors.isEmpty || isLoadingInvestors) {
      print('⚠️ [ServerSideStatisticsService] Brak inwestorów do analizowania');
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
      print('❌ [ServerSideStatisticsService] productName jest pusty!');
      print('  - Otrzymany productName: "$productName"');
      print('  - Używam fallback do lokalnych obliczeń');
      return _calculateFallbackStatistics(investors, productName);
    }

    try {
      print(
        '🚀 [ServerSideStatisticsService] Wywołuję Firebase Function dla: $productName',
      );
      print('🔍 [ServerSideStatisticsService] Parametry wejściowe:');
      print('  - productName: "$productName"');
      print('  - investors.length: ${investors.length}');
      print('  - isLoadingInvestors: $isLoadingInvestors');

      // Przygotuj dane inwestycji do przesłania
      final List<Map<String, dynamic>> investmentsData = [];
      int processedInvestors = 0;
      int processedInvestments = 0;

      for (final investor in investors) {
        processedInvestors++;
        print(
          '  🧑‍💼 Investor ${processedInvestors}: ${investor.client.name} (${investor.investments.length} inwestycji)',
        );

        for (final investment in investor.investments) {
          if (investment.productName == productName) {
            processedInvestments++;
            print(
              '    ✅ Inwestycja ${processedInvestments}: ${investment.id} - ${investment.productName}',
            );

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

      print('📊 [ServerSideStatisticsService] PODSUMOWANIE PRZETWARZANIA:');
      print('  - Przetworzonych inwestorów: $processedInvestors');
      print(
        '  - Znalezionych inwestycji dla "$productName": $processedInvestments',
      );
      print('  - Przesyłam ${investmentsData.length} inwestycji do serwera');

      // ⚠️ WALIDACJA: Sprawdź czy mamy dane do przesłania
      if (investmentsData.isEmpty) {
        print(
          '⚠️ [ServerSideStatisticsService] Brak inwestycji dla produktu: $productName',
        );
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

      print('🔍 [ServerSideStatisticsService] Debugowanie parametrów:');
      print('  - productName: "$productName"');
      print('  - productName.length: ${productName.length}');
      print('  - productName.trim().isEmpty: ${productName.trim().isEmpty}');
      print('  - investments.length: ${investmentsData.length}');
      print(
        '  - investments[0]: ${investmentsData.isNotEmpty ? investmentsData.first : "N/A"}',
      );

      // ⚠️ DRUGA WALIDACJA: Sprawdź jeszcze raz przed wywołaniem Firebase
      if (productName.trim().isEmpty) {
        print(
          '❌ [ServerSideStatisticsService] STOP! productName jest wciąż pusty przed wywołaniem Firebase',
        );
        throw Exception('productName nie może być pusty');
      }

      // Wywołaj Firebase Function
      final HttpsCallable callable = _functions.httpsCallable(
        'getProductStatistics',
      );

      print(
        '🔥 [ServerSideStatisticsService] Wywołuję Firebase Function z parametrami:',
      );
      final parameters = {
        'productName': productName,
        'investments': investmentsData,
      };
      print('  - Parametry: $parameters');

      final result = await callable.call(parameters);

      final Map<String, dynamic> data = result.data;

      if (data['success'] != true) {
        throw Exception('Serwer zwrócił błąd: ${data['error']}');
      }

      final Map<String, dynamic> statistics = data['statistics'];

      print('✅ [ServerSideStatisticsService] Otrzymano statystyki z serwera');
      print(
        '  - totalCapitalSecuredByRealEstate: ${statistics['totalCapitalSecuredByRealEstate']}',
      );
      print(
        '  - totalRemainingCapital: ${statistics['totalRemainingCapital']}',
      );
      print(
        '  - totalCapitalForRestructuring: ${statistics['totalCapitalForRestructuring']}',
      );

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
      print(
        '❌ [ServerSideStatisticsService] Błąd podczas wywołania Firebase Function: $error',
      );

      // Fallback do lokalnych obliczeń w przypadku błędu serwera
      print('🔄 [ServerSideStatisticsService] Fallback do obliczeń lokalnych');
      return _calculateFallbackStatistics(investors, productName);
    }
  }

  /// Fallback - podstawowe obliczenia lokalne w przypadku błędu serwera
  static UnifiedProductStatistics _calculateFallbackStatistics(
    List<InvestorSummary> investors,
    String productName,
  ) {
    print('🔧 [ServerSideStatisticsService] FALLBACK - obliczenia lokalne');
    print('  - Produkt: "$productName"');
    print('  - Liczba inwestorów: ${investors.length}');

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
              print(
                '    ♻️ FALLBACK UZUPEŁNIONO capitalForRestructuring dla ${investment.id}: +$diff (now $current)',
              );
            } else {
              print(
                '    ⚠️ FALLBACK DUPLIKAT POMINIĘTY (bez zmian): ${investment.id}',
              );
            }
            continue;
          }
          processedInvestmentIds.add(investment.id);

          totalInvestmentAmount += investment.investmentAmount;
          totalRemainingCapital += investment.remainingCapital;
          totalCapitalForRestructuring += investment.capitalForRestructuring;
          recordedCapitalForRestructuring[investment.id] =
              investment.capitalForRestructuring;

          print('  ✅ ${investor.client.name}: ${investment.productName}');
          print('    * investmentAmount: ${investment.investmentAmount}');
          print('    * remainingCapital: ${investment.remainingCapital}');
          print(
            '    * capitalForRestructuring: ${investment.capitalForRestructuring}',
          );
        }
      }
    }

    // 🎯 OBLICZ totalCapitalSecuredByRealEstate NA KOŃCU Z WZORU - TAKA SAMA LOGIKA JAK W UNIFIED_STATISTICS_SERVICE
    final totalCapitalSecuredByRealEstate =
        (totalRemainingCapital - totalCapitalForRestructuring).clamp(
          0.0,
          double.infinity,
        );

    print('🧮 [ServerSideStatisticsService] FALLBACK OBLICZANIE KOŃCOWE:');
    print('  - totalRemainingCapital: $totalRemainingCapital');
    print('  - totalCapitalForRestructuring: $totalCapitalForRestructuring');
    print(
      '  - 🔥 totalCapitalSecuredByRealEstate = $totalRemainingCapital - $totalCapitalForRestructuring = $totalCapitalSecuredByRealEstate',
    );
    print(
      '  - Przetworzono unikalnych inwestycji: ${processedInvestmentIds.length}',
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
