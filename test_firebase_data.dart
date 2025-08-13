import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../lib/models_and_services.dart';

/// Test dla sprawdzenia danych Firebase
void main() async {
  print('🔍 [TEST] Sprawdzenie danych Firebase...');

  try {
    // Użyj serwisu do pobrania danych bezpośrednio z Firebase
    final analyticsService = FirebaseFunctionsAnalyticsServiceUpdated();

    print('📊 [TEST] Pobieranie danych...');
    final result = await analyticsService.getOptimizedInvestorAnalytics(
      pageSize: 5, // Tylko pierwsze 5 inwestorów
      forceRefresh: true,
    );

    print('✅ [TEST] Otrzymano ${result.investors.length} inwestorów');

    for (int i = 0; i < result.investors.length; i++) {
      final investor = result.investors[i];
      print('🔍 [TEST] Inwestor ${i + 1}: ${investor.client.name}');
      print('  - capitalForRestructuring: ${investor.capitalForRestructuring}');
      print(
        '  - capitalSecuredByRealEstate: ${investor.capitalSecuredByRealEstate}',
      );
      print('  - viableRemainingCapital: ${investor.viableRemainingCapital}');
      print('  - investmentCount: ${investor.investmentCount}');

      // Sprawdź każdą inwestycję
      for (int j = 0; j < investor.investments.length; j++) {
        final investment = investor.investments[j];
        print('    Investment ${j + 1}: ${investment.productName}');
        print('      - remainingCapital: ${investment.remainingCapital}');
        print(
          '      - capitalForRestructuring: ${investment.capitalForRestructuring}',
        );
        print(
          '      - capitalSecuredByRealEstate: ${investment.capitalSecuredByRealEstate}',
        );
        print(
          '      - additionalInfo keys: ${investment.additionalInfo.keys.toList()}',
        );
      }

      print(''); // Empty line for clarity
      if (i >= 2) break; // Stop after 3 investors for readability
    }

    print('🎯 [TEST] Test zakończony');
  } catch (e) {
    print('❌ [TEST] Błąd: $e');
  }
}
