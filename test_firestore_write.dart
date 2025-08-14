import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'lib/services/firebase_config.dart';
import 'lib/models_and_services.dart';

/// Test zapisywania do Firestore po naprawach
Future<void> main() async {
  print('🔧 [TEST] Testowanie zapisu do Firestore po naprawach...');
  
  try {
    // Initialize Flutter
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase
    await FirebaseConfig.initialize();
    
    // Initialize services
    final investmentService = InvestmentService();
    
    print('📊 [TEST] Pobieranie przykładowej inwestycji...');
    
    // Get a sample investment to update
    final investments = await investmentService.loadAllInvestments();
    if (investments.isEmpty) {
      print('❌ [TEST] Brak inwestycji do testowania');
      return;
    }
    
    final sampleInvestment = investments.first;
    print('✅ [TEST] Znaleziono inwestycję: ${sampleInvestment.id}');
    print('📋 [TEST] Dane: remainingCapital=${sampleInvestment.remainingCapital}, investmentAmount=${sampleInvestment.investmentAmount}');
    
    // Create a modified version
    final modifiedInvestment = sampleInvestment.copyWith(
      remainingCapital: sampleInvestment.remainingCapital + 1.0, // Small change
      updatedAt: DateTime.now(),
    );
    
    print('🔄 [TEST] Próba aktualizacji inwestycji...');
    
    // Try to update the investment
    await investmentService.updateInvestment(
      sampleInvestment.id,
      modifiedInvestment,
    );
    
    print('✅ [TEST] Pomyślnie zaktualizowano inwestycję!');
    
    // Test history service too
    print('📝 [TEST] Testowanie serwisu historii...');
    final historyService = InvestmentChangeHistoryService();
    
    await historyService.recordInvestmentChange(
      oldInvestment: sampleInvestment,
      newInvestment: modifiedInvestment,
      changeType: InvestmentChangeType.fieldUpdate,
      customDescription: 'Test update from test_firestore_write.dart',
    );
    
    print('✅ [TEST] Historia zmian zapisana pomyślnie!');
    
    // Revert the change
    print('↩️ [TEST] Przywracanie oryginalnej wartości...');
    await investmentService.updateInvestment(
      sampleInvestment.id,
      sampleInvestment,
    );
    
    print('🎉 [TEST] Wszystkie testy zakończone pomyślnie!');
    print('');
    print('✅ Status: Problemy z zapisem do Firestore zostały rozwiązane');
    print('🔧 Główne naprawy:');
    print('   - Ujednolicono typy danych numerycznych w toFirestore()');
    print('   - Dodano walidację i czyszczenie danych przed zapisem');
    print('   - Ulepszona obsługa błędów z szczegółowym logowaniem');
    print('   - Zaktualizowane reguły Firestore dla investment_change_history');
    
  } catch (e) {
    print('❌ [TEST] Test zakończony błędem: $e');
    print('🔍 Stack trace:');
    print(e.toString());
  }
}
