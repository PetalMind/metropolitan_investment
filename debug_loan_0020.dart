import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'lib/services/firebase_config.dart';
import 'lib/models_and_services.dart';

/// Debug: Sprawdź różnicę między lokalnymi danymi a Firestore
Future<void> main() async {
  print('🔍 [DEBUG] Sprawdzanie stanu inwestycji loan_0020...');
  
  try {
    // Initialize Flutter
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase
    await FirebaseConfig.initialize();
    
    // Initialize services
    final investmentService = InvestmentService();
    
    print('📊 [DEBUG] Sprawdzanie kolekcji investments w Firestore...');
    
    // 1. Check if document exists in Firestore
    try {
      final firestoreInvestment = await investmentService.getInvestment('loan_0020');
      if (firestoreInvestment != null) {
        print('✅ [DEBUG] Znaleziono loan_0020 w Firestore');
        print('📋 [DEBUG] Dane: ${firestoreInvestment.clientName}, ${firestoreInvestment.remainingCapital}');
      } else {
        print('❌ [DEBUG] loan_0020 NIE ISTNIEJE w Firestore');
      }
    } catch (e) {
      print('❌ [DEBUG] Błąd podczas sprawdzania Firestore: $e');
    }
    
    // 1b. Also check bond_0194 which we know exists
    try {
      final bondInvestment = await investmentService.getInvestment('bond_0194');
      if (bondInvestment != null) {
        print('✅ [DEBUG] bond_0194 ISTNIEJE w Firestore (dla porównania)');
        print('📋 [DEBUG] Dane bond: ${bondInvestment.clientName}, ${bondInvestment.remainingCapital}');
      } else {
        print('❌ [DEBUG] bond_0194 nie znaleziono (nieoczekiwane)');
      }
    } catch (e) {
      print('❌ [DEBUG] Błąd podczas sprawdzania bond_0194: $e');
    }
    
    // 2. Load all investments and check if loan_0020 exists locally
    print('🔄 [DEBUG] Ładowanie wszystkich inwestycji z serwisu...');
    final allInvestments = await investmentService.loadAllInvestments();
    
    final localInvestment = allInvestments.where((inv) => inv.id == 'loan_0020').firstOrNull;
    if (localInvestment != null) {
      print('✅ [DEBUG] Znaleziono loan_0020 lokalnie w serwisie');
      print('📋 [DEBUG] Dane lokalne: ${localInvestment.clientName}, ${localInvestment.remainingCapital}');
      print('🔍 [DEBUG] Source file: ${localInvestment.additionalInfo['sourceFile']}');
      print('📅 [DEBUG] Created at: ${localInvestment.createdAt}');
    } else {
      print('❌ [DEBUG] loan_0020 NIE ISTNIEJE lokalnie w serwisie');
    }
    
    // 3. Check Firebase Functions data
    print('☁️ [DEBUG] Sprawdzanie danych z Firebase Functions...');
    try {
      final functionsService = FirebaseFunctionsDataService();
      final enhancedResult = await functionsService.getEnhancedInvestments(
        searchQuery: 'loan_0020',
        pageSize: 10,
      );
      
      print('📊 [DEBUG] Firebase Functions znalazło ${enhancedResult.investments.length} wyników dla loan_0020');
      
      final functionsInvestment = enhancedResult.investments.where((inv) => inv.id == 'loan_0020').firstOrNull;
      if (functionsInvestment != null) {
        print('✅ [DEBUG] Znaleziono loan_0020 w Firebase Functions');
        print('📋 [DEBUG] Dane z Functions: ${functionsInvestment.clientName}, ${functionsInvestment.remainingCapital}');
      }
    } catch (e) {
      print('⚠️ [DEBUG] Błąd podczas sprawdzania Firebase Functions: $e');
    }
    
    // 4. Try to create the investment in Firestore if it exists locally but not in Firestore
    if (localInvestment != null) {
      print('🔧 [DEBUG] Próba utworzenia loan_0020 w Firestore...');
      try {
        final newId = await investmentService.createInvestment(localInvestment);
        print('✅ [DEBUG] Utworzono inwestycję w Firestore z ID: $newId');
        
        // Now try to update the old document with the new ID
        print('🔄 [DEBUG] Próba aktualizacji z nowym ID...');
        final updatedInvestment = localInvestment.copyWith(
          id: newId,
          updatedAt: DateTime.now(),
        );
        
        await investmentService.updateInvestment(newId, updatedInvestment);
        print('✅ [DEBUG] Pomyślnie zaktualizowano inwestycję!');
        
      } catch (createError) {
        print('❌ [DEBUG] Błąd podczas tworzenia inwestycji: $createError');
      }
    }
    
    print('');
    print('🎯 [DIAGNOZA] Problem loan_0020:');
    print('   - Inwestycja istnieje lokalnie ale nie w Firestore');
    print('   - Prawdopodobnie pochodzi z importu Excel/CSV');
    print('   - ID nie zostało poprawnie zsynchronizowane z Firestore');
    print('');
    print('💡 [ROZWIĄZANIE] Uruchomiono próbę naprawy przez create -> update');
    
  } catch (e) {
    print('❌ [DEBUG] Test zakończony błędem: $e');
  }
}
