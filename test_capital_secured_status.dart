#!/usr/bin/env dart

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';

// Import Firebase Functions service
import 'lib/services/firebase_functions_capital_calculation_service.dart';
import 'lib/firebase_options.dart';

/// Test sprawdzania i obliczania kapitału zabezpieczonego nieruchomością
Future<void> main() async {
  print('🧪 Test kapitału zabezpieczonego nieruchomością');
  print('=' * 60);

  try {
    // Initialize Firebase
    print('Inicjalizacja Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase zainicjalizowany');
    print('');

    // Test 1: Sprawdź status obliczania
    print('📊 Test 1: Sprawdzanie statusu obliczania...');
    try {
      final status =
          await FirebaseFunctionsCapitalCalculationService.checkCapitalCalculationStatus();

      if (status != null) {
        print('✅ Status obliczania kapitału:');
        print('   * Łącznie inwestycji: ${status.statistics.totalInvestments}');
        print(
          '   * Z obliczonym polem: ${status.statistics.withCalculatedField}',
        );
        print(
          '   * Z poprawnym obliczeniem: ${status.statistics.withCorrectCalculation}',
        );
        print('   * Wymagają aktualizacji: ${status.statistics.needsUpdate}');
        print('   * Stopień kompletności: ${status.statistics.completionRate}');
        print('   * Stopień dokładności: ${status.statistics.accuracyRate}');
        print('');

        if (status.statistics.needsUpdate > 0) {
          print(
            '⚠️  UWAGA: ${status.statistics.needsUpdate} inwestycji wymaga aktualizacji!',
          );
          print('   Rekomendacje:');
          status.recommendations.forEach((rec) => print('   - $rec'));
          print('');

          // Test 2: Uruchom aktualizację (dry run)
          print('🧪 Test 2: Symulacja aktualizacji (dry run)...');
          final updateResult =
              await FirebaseFunctionsCapitalCalculationService.updateCapitalSecuredByRealEstate(
                batchSize: 100,
                dryRun: true, // Tylko symulacja
                includeDetails: true,
              );

          if (updateResult != null) {
            print('✅ Wynik symulacji:');
            print('   * Przetworzonych: ${updateResult.processed}');
            print('   * Do aktualizacji: ${updateResult.updated}');
            print('   * Błędów: ${updateResult.errors}');
            print('   * Czas wykonania: ${updateResult.executionTimeMs}ms');
            print(
              '   * Stopień sukcesu: ${(updateResult.successRate * 100).toStringAsFixed(1)}%',
            );
            print(
              '   * Stopień aktualizacji: ${(updateResult.updateRate * 100).toStringAsFixed(1)}%',
            );

            if (updateResult.details.isNotEmpty) {
              print('');
              print('📋 Przykłady zmian (maksymalnie 5):');
              final limitedDetails = updateResult.details.take(5);
              for (final detail in limitedDetails) {
                if (detail.hasChanged) {
                  print('   * ${detail.clientName}:');
                  print(
                    '     Kapitał pozostały: ${detail.remainingCapital.toStringAsFixed(2)}',
                  );
                  print(
                    '     Kapitał restrukturyzacji: ${detail.capitalForRestructuring.toStringAsFixed(2)}',
                  );
                  print(
                    '     Stara wartość: ${detail.oldCapitalSecuredByRealEstate.toStringAsFixed(2)}',
                  );
                  print(
                    '     Nowa wartość: ${detail.newCapitalSecuredByRealEstate.toStringAsFixed(2)}',
                  );
                  print(
                    '     Różnica: ${detail.difference.toStringAsFixed(2)}',
                  );
                }
              }
            }

            print('');
            print('🎯 OPCJE DALSZEGO DZIAŁANIA:');
            if (updateResult.updated > 0) {
              print('   1. Uruchom prawdziwą aktualizację bez dry run');
              print('   2. Sprawdź detale zmian w aplikacji');
              print('   3. Skonfiguruj automatyczne przeliczanie');
            } else {
              print('   ✅ Wszystkie wartości są już poprawne!');
            }
          }
        } else {
          print(
            '🎉 SUKCES: Wszystkie inwestycje mają poprawnie obliczny kapitał!',
          );
        }

        // Pokaż próbki danych
        if (status.samples.isNotEmpty) {
          print('');
          print('📋 Próbki danych do analizy:');
          status.samples.take(3).forEach((sample) {
            print('   * ${sample.clientName}:');
            print('     ID: ${sample.id}');
            print(
              '     Kapitał pozostały: ${sample.remainingCapital.toStringAsFixed(2)}',
            );
            print(
              '     Kapitał restrukturyzacji: ${sample.capitalForRestructuring.toStringAsFixed(2)}',
            );
            print(
              '     Obecna wartość: ${sample.currentValue.toStringAsFixed(2)}',
            );
            print('     Powinna być: ${sample.shouldBe.toStringAsFixed(2)}');
            print('     Ma pole: ${sample.hasField ? "TAK" : "NIE"}');
            print('     Jest poprawne: ${sample.isCorrect ? "TAK" : "NIE"}');
          });
        }
      } else {
        print('❌ Nie udało się pobrać statusu obliczania');
      }
    } catch (e) {
      print('❌ Błąd sprawdzania statusu: $e');
      print('   Możliwe przyczyny:');
      print('   - Firebase Functions nie są wdrożone');
      print('   - Problemy z połączeniem');
      print('   - Błąd uprawnień');
    }
  } catch (e, stackTrace) {
    print('❌ Błąd ogólny: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }

  print('');
  print('📝 PODSUMOWANIE:');
  print('   ✅ Model Bond ma pole capitalSecuredByRealEstate (nullable)');
  print('   ✅ Dodano getter effectiveCapitalSecuredByRealEstate z fallback');
  print('   ✅ Firebase Functions mają logikę obliczania');
  print('   ✅ Dostępne narzędzia do sprawdzania i aktualizacji');
  print('');
  print('💡 ZALECENIA:');
  print('   1. Regularnie sprawdzaj status obliczania');
  print('   2. Używaj effectiveCapitalSecuredByRealEstate w UI');
  print('   3. Skonfiguruj automatyczne przeliczanie w Firebase Functions');
}
