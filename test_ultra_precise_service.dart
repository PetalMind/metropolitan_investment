import 'package:flutter/material.dart';
import 'lib/models_and_services.dart';

/// 🧪 TEST ULTRA PRECISE SERVICE
/// Test działania z rzeczywistymi danymi Firebase
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🧪 [TEST] Rozpoczynam test UltraPreciseProductInvestorsService...');

  final service = UltraPreciseProductInvestorsService();

  try {
    // Test 1: Połączenie
    print('\n🔗 [TEST 1] Sprawdzanie połączenia...');
    final connectionOk = await service.testConnection();
    print('Połączenie: ${connectionOk ? "✅ OK" : "❌ BŁĄD"}');

    // Test 2: Wyszukiwanie po productId (przykład z twoich danych)
    print('\n🎯 [TEST 2] Wyszukiwanie po productId: apartment_0001...');
    final result1 = await service.getByProductId('apartment_0001');

    if (result1.isSuccess) {
      print('✅ Sukces! Znaleziono ${result1.totalCount} inwestorów');
      for (final investor in result1.investors.take(3)) {
        print(
          '  - ${investor.client.name}: ${investor.totalRemainingCapital} PLN',
        );
      }
    } else if (result1.hasError) {
      print('❌ Błąd: ${result1.error}');
    } else {
      print('⚠️ Brak inwestorów dla apartment_0001');
    }

    // Test 3: Wyszukiwanie po productName
    print('\n🏢 [TEST 3] Wyszukiwanie po productName: "Gdański Harward"...');
    final result2 = await service.getByProductName('Gdański Harward');

    if (result2.isSuccess) {
      print('✅ Sukces! Znaleziono ${result2.totalCount} inwestorów');
      print('📊 Statystyki:');
      print('  - Całkowity kapitał: ${result2.statistics.totalCapital} PLN');
      print(
        '  - Średni kapitał: ${result2.statistics.averageCapital.toStringAsFixed(2)} PLN',
      );
      print(
        '  - Mapowanie: ${result2.mappingStats.successPercentage.toStringAsFixed(1)}%',
      );
    } else if (result2.hasError) {
      print('❌ Błąd: ${result2.error}');
    } else {
      print('⚠️ Brak inwestorów dla "Gdański Harward"');
    }

    // Test 4: Sprawdź cache
    print('\n💾 [TEST 4] Test cache - ponowne zapytanie...');
    final result3 = await service.getByProductId('apartment_0001');
    print('Z cache: ${result3.fromCache ? "✅ TAK" : "❌ NIE"}');
    print('Czas wykonania: ${result3.executionTime}ms');
  } catch (e) {
    print('❌ [TEST] Błąd podczas testów: $e');
  }

  print('\n🏁 [TEST] Zakończono testy UltraPreciseProductInvestorsService');
}
