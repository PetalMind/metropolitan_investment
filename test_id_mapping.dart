import 'package:flutter/material.dart';
import 'lib/models_and_services.dart';

/// 🧪 TEST MAPOWANIA DEDUPLIKOWANYCH ID
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🧪 [TEST] Test mapowania deduplikowanych ID...');

  final service = UltraPreciseProductInvestorsService();

  // Test z deduplikowanym ID
  final deduplikatedId = '780663142';
  print('\n🔍 Test: Wyszukiwanie z deduplikowanym ID "$deduplikatedId"');

  try {
    final result = await service.getProductInvestors(
      productId: deduplikatedId,
      productName: 'Metropolitan Investment A1',
      forceRefresh: true,
    );

    print('✅ Wynik mapowania:');
    print('  - Strategia: ${result.searchStrategy}');
    print('  - Klucz wyszukiwania: ${result.searchKey}');
    print('  - Znaleziono inwestorów: ${result.totalCount}');
    print('  - Błąd: ${result.error ?? "Brak"}');
    print('  - Z cache: ${result.fromCache}');
    print('  - Czas wykonania: ${result.executionTime}ms');
  } catch (e) {
    print('❌ Błąd podczas mapowania: $e');
  }

  print('\n🏁 Test zakończony');
}
