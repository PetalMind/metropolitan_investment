#!/usr/bin/env dart

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';

// Dodaj ścieżkę do lib
import 'lib/services/integrated_client_service.dart';
import 'lib/services/unified_statistics_utils.dart';
import 'lib/firebase_options.dart';

/// Test naprawy statystyk klientów
Future<void> main() async {
  print('🧪 Test naprawy statystyk klientów');
  print('=' * 50);
  
  try {
    // Initialize Firebase
    print('Inicjalizacja Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase zainicjalizowany');
    print('');
    
    print('1. Testowanie IntegratedClientService...');
    final clientService = IntegratedClientService();
    
    print('   - Pobieranie statystyk klientów...');
    final stats = await clientService.getClientStats();
    
    print('✅ Statystyki klientów:');
    print('   * Liczba klientów: ${stats.totalClients}');
    print('   * Liczba inwestycji: ${stats.totalInvestments}');
    print('   * Kapitał pozostały: ${stats.totalRemainingCapital.toStringAsFixed(2)} PLN');
    print('   * Średni kapitał na klienta: ${stats.averageCapitalPerClient.toStringAsFixed(2)} PLN');
    print('   * Źródło danych: ${stats.source}');
    print('   * Ostatnia aktualizacja: ${stats.lastUpdated}');
    
    print('');
    print('2. Testowanie UnifiedStatisticsUtils...');
    
    // Przykład testowy - można rozszerzyć
    final testInvestments = [
      {
        'kapital_pozostaly': 100000.0,
        'odsetki_pozostale': 5000.0,
        'productStatus': 'Aktywny',
      },
      {
        'kapital_pozostaly': 50000.0,
        'odsetki_pozostale': 2000.0,
        'productStatus': 'Nieaktywny',
      },
    ];
    
    final unifiedStats = UnifiedSystemStats.fromInvestments(testInvestments);
    print('✅ Zunifikowane statystyki (test):');
    print('   * Total Value: ${unifiedStats.totalValue}');
    print('   * Viable Capital: ${unifiedStats.viableCapital}');
    print('   * Majority Threshold: ${unifiedStats.majorityThreshold}');
    
    print('');
    print('✅ Test zakończony pomyślnie!');
    
  } catch (e, stackTrace) {
    print('❌ Błąd podczas testowania: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
