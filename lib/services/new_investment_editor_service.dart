import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';

/// 🆕 NOWY SYSTEM EDYCJI INWESTYCJI
/// 
/// Całkowicie przepisany od podstaw aby rozwiązać problem z znikającymi inwestorami.
/// 
/// KLUCZOWE ZASADY:
/// 1. Zachowanie integralności danych klienta (clientId, clientName)
/// 2. Atomowe operacje na Firebase
/// 3. Weryfikacja przed i po edycji
/// 4. Rollback w przypadku błędów
/// 5. Szczegółowe logowanie każdego kroku
class NewInvestmentEditorService extends BaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InvestmentChangeHistoryService _historyService;
  
  NewInvestmentEditorService({
    InvestmentChangeHistoryService? historyService,
  }) : _historyService = historyService ?? InvestmentChangeHistoryService(),
       super();

  /// 🎯 GŁÓWNA METODA: Edytuj pojedynczą inwestycję
  /// 
  /// Zachowuje wszystkie dane klienta i wykonuje atomową operację
  Future<InvestmentEditResult> editInvestment({
    required String investmentId,
    required InvestmentEditRequest request,
    required String editorName,
    required String editorEmail,
  }) async {
    final startTime = DateTime.now();
    debugPrint('🚀 [NewInvestmentEditor] Rozpoczynam edycję inwestycji: $investmentId');
    debugPrint('📝 [NewInvestmentEditor] Żądanie edycji: ${request.toString()}');

    try {
      // KROK 1: Pobierz aktualną inwestycję z pełną weryfikacją
      final currentInvestment = await _getInvestmentWithValidation(investmentId);
      if (currentInvestment == null) {
        return InvestmentEditResult.failure(
          'Nie znaleziono inwestycji o ID: $investmentId',
          duration: DateTime.now().difference(startTime),
        );
      }

      debugPrint('✅ [NewInvestmentEditor] Znaleziono inwestycję dla klienta: ${currentInvestment.clientName}');
      debugPrint('🔍 [NewInvestmentEditor] Aktualne dane klienta:');
      debugPrint('   - clientId: ${currentInvestment.clientId}');
      debugPrint('   - clientName: ${currentInvestment.clientName}');
      debugPrint('   - remainingCapital: ${currentInvestment.remainingCapital}');

      // KROK 2: Przygotuj nowe dane zachowując integralność klienta
      final updatedInvestment = _buildUpdatedInvestment(currentInvestment, request);
      
      // KROK 3: Walidacja biznesowa
      final validationResult = _validateBusinessRules(currentInvestment, updatedInvestment);
      if (!validationResult.isValid) {
        return InvestmentEditResult.failure(
          'Błąd walidacji: ${validationResult.error}',
          duration: DateTime.now().difference(startTime),
        );
      }

      // KROK 4: Atomowa aktualizacja w Firebase
      final updateResult = await _performAtomicUpdate(
        investmentId: investmentId,
        currentInvestment: currentInvestment,
        updatedInvestment: updatedInvestment,
        editorName: editorName,
        editorEmail: editorEmail,
      );

      if (!updateResult.success) {
        return InvestmentEditResult.failure(
          updateResult.error ?? 'Nieznany błąd podczas aktualizacji',
          duration: DateTime.now().difference(startTime),
        );
      }

      // KROK 5: Weryfikacja po aktualizacji
      final verificationResult = await _verifyUpdateSuccess(investmentId, updatedInvestment);
      if (!verificationResult.success) {
        debugPrint('❌ [NewInvestmentEditor] Weryfikacja nieudana - próba rollback...');
        await _attemptRollback(investmentId, currentInvestment);
        return InvestmentEditResult.failure(
          'Weryfikacja po aktualizacji nieudana: ${verificationResult.error}',
          duration: DateTime.now().difference(startTime),
        );
      }

      debugPrint('✅ [NewInvestmentEditor] Edycja zakończona pomyślnie w ${DateTime.now().difference(startTime).inMilliseconds}ms');
      
      return InvestmentEditResult.success(
        originalInvestment: currentInvestment,
        updatedInvestment: updatedInvestment,
        changesApplied: _getChangesApplied(currentInvestment, updatedInvestment),
        duration: DateTime.now().difference(startTime),
      );

    } catch (e, stackTrace) {
      debugPrint('💥 [NewInvestmentEditor] Krytyczny błąd: $e');
      debugPrint('📍 [NewInvestmentEditor] Stack trace: $stackTrace');
      
      return InvestmentEditResult.failure(
        'Krytyczny błąd: ${e.toString()}',
        duration: DateTime.now().difference(startTime),
      );
    }
  }

  /// 🔍 KROK 1: Pobierz inwestycję z pełną walidacją
  Future<Investment?> _getInvestmentWithValidation(String investmentId) async {
    debugPrint('🔍 [NewInvestmentEditor] Wyszukuję inwestycję: $investmentId');

    try {
      // Strategia 1: Szukaj po logicznym ID w polu 'id'
      final querySnapshot = await _firestore
          .collection('investments')
          .where('id', isEqualTo: investmentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        
        debugPrint('✅ [NewInvestmentEditor] Znaleziono przez query po id');
        debugPrint('📄 [NewInvestmentEditor] Document UUID: ${doc.id}');
        
        return Investment.fromFirestore(doc);
      }

      // Strategia 2: Szukaj po UUID dokumentu (fallback)
      final docSnapshot = await _firestore
          .collection('investments')
          .doc(investmentId)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        debugPrint('✅ [NewInvestmentEditor] Znaleziono przez UUID dokumentu');
        return Investment.fromFirestore(docSnapshot);
      }

      debugPrint('❌ [NewInvestmentEditor] Nie znaleziono inwestycji: $investmentId');
      return null;

    } catch (e) {
      debugPrint('💥 [NewInvestmentEditor] Błąd podczas pobierania inwestycji: $e');
      rethrow;
    }
  }

  /// 🏗️ KROK 2: Zbuduj zaktualizowaną inwestycję zachowując integralność
  Investment _buildUpdatedInvestment(Investment current, InvestmentEditRequest request) {
    debugPrint('🏗️ [NewInvestmentEditor] Buduję zaktualizowaną inwestycję...');

    return Investment(
      // 🔒 ZACHOWAJ NIEZMIENNE DANE KLIENTA
      id: current.id,
      clientId: current.clientId, // 🚨 KLUCZOWE: NIE ZMIENIAJ clientId!
      clientName: current.clientName, // 🚨 KLUCZOWE: NIE ZMIENIAJ clientName!
      
      // 🔒 ZACHOWAJ NIEZMIENNE DANE PRODUKTU
      productId: current.productId,
      productName: current.productName,
      productType: current.productType,
      companyId: current.companyId,
      creditorCompany: current.creditorCompany,
      
      // 🔒 ZACHOWAJ NIEZMIENNE DANE PRACOWNIKA
      employeeId: current.employeeId,
      employeeFirstName: current.employeeFirstName,
      employeeLastName: current.employeeLastName,
      branchCode: current.branchCode,
      
      // 🔒 ZACHOWAJ NIEZMIENNE DANE SYSTEMOWE
      isAllocated: current.isAllocated,
      marketType: current.marketType,
      proposalId: current.proposalId,
      createdAt: current.createdAt,
      
      // 🔒 ZACHOWAJ NIEZMIENNE DATY
      signedDate: current.signedDate,
      entryDate: current.entryDate,
      exitDate: current.exitDate,
      issueDate: current.issueDate,
      redemptionDate: current.redemptionDate,
      
      // 📝 AKTUALIZUJ TYLKO EDYTOWALNE POLA
      remainingCapital: request.remainingCapital ?? current.remainingCapital,
      investmentAmount: request.investmentAmount ?? current.investmentAmount,
      capitalForRestructuring: request.capitalForRestructuring ?? current.capitalForRestructuring,
      capitalSecuredByRealEstate: request.capitalSecuredByRealEstate ?? current.capitalSecuredByRealEstate,
      status: request.status ?? current.status,
      
      // 🔒 ZACHOWAJ POZOSTAŁE FINANSE
      paidAmount: current.paidAmount,
      realizedCapital: current.realizedCapital,
      realizedInterest: current.realizedInterest,
      transferToOtherProduct: current.transferToOtherProduct,
      remainingInterest: current.remainingInterest,
      plannedTax: current.plannedTax,
      realizedTax: current.realizedTax,
      currency: current.currency,
      exchangeRate: current.exchangeRate,
      sharesCount: current.sharesCount,
      
      // 🕒 AKTUALIZUJ CZAS MODYFIKACJI
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...current.additionalInfo,
        'sourceFile': current.additionalInfo['sourceFile'] ?? 'manual_entry',
      },
    );
  }

  /// ✅ KROK 3: Walidacja biznesowa
  ValidationResult _validateBusinessRules(Investment current, Investment updated) {
    debugPrint('✅ [NewInvestmentEditor] Walidacja biznesowa...');

    // Sprawdź czy kluczowe dane klienta się nie zmieniły
    if (current.clientId != updated.clientId) {
      return ValidationResult.invalid('clientId nie może być zmieniany! (${current.clientId} → ${updated.clientId})');
    }

    if (current.clientName != updated.clientName) {
      return ValidationResult.invalid('clientName nie może być zmieniany! (${current.clientName} → ${updated.clientName})');
    }

    // Sprawdź czy kwoty są dodatnie
    if (updated.remainingCapital < 0) {
      return ValidationResult.invalid('Kapitał pozostały nie może być ujemny: ${updated.remainingCapital}');
    }

    if (updated.investmentAmount < 0) {
      return ValidationResult.invalid('Kwota inwestycji nie może być ujemna: ${updated.investmentAmount}');
    }

    if (updated.capitalForRestructuring < 0) {
      return ValidationResult.invalid('Kapitał do restrukturyzacji nie może być ujemny: ${updated.capitalForRestructuring}');
    }

    if (updated.capitalSecuredByRealEstate < 0) {
      return ValidationResult.invalid('Kapitał zabezpieczony nie może być ujemny: ${updated.capitalSecuredByRealEstate}');
    }

    // Sprawdź logikę biznesową
    if (updated.capitalSecuredByRealEstate > updated.remainingCapital) {
      return ValidationResult.invalid(
        'Kapitał zabezpieczony (${updated.capitalSecuredByRealEstate}) '
        'nie może być większy od kapitału pozostałego (${updated.remainingCapital})'
      );
    }

    debugPrint('✅ [NewInvestmentEditor] Walidacja biznesowa zakończona pomyślnie');
    return ValidationResult.valid();
  }

  /// 💾 KROK 4: Atomowa aktualizacja w Firebase  
  Future<AtomicUpdateResult> _performAtomicUpdate({
    required String investmentId,
    required Investment currentInvestment,
    required Investment updatedInvestment,
    required String editorName,
    required String editorEmail,
  }) async {
    debugPrint('💾 [NewInvestmentEditor] Wykonuję atomową aktualizację...');

    try {
      // Znajdź UUID dokumentu
      final querySnapshot = await _firestore
          .collection('investments')
          .where('id', isEqualTo: investmentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return AtomicUpdateResult.failure('Nie znaleziono dokumentu do aktualizacji');
      }

      final documentId = querySnapshot.docs.first.id;
      debugPrint('📄 [NewInvestmentEditor] Aktualizuję dokument UUID: $documentId');

      // Przygotuj dane do aktualizacji
      final updateData = updatedInvestment.toFirestore();
      
      // 🔒 DOUBLE-CHECK: Upewnij się że kluczowe dane klienta są zachowane
      // Jeśli current investment ma clientId, zachowaj go. Jeśli nie, nie nadpisuj pustym stringiem
      if (currentInvestment.clientId.isNotEmpty) {
        updateData['clientId'] = currentInvestment.clientId;
      }
      if (currentInvestment.clientName.isNotEmpty) {
        updateData['clientName'] = currentInvestment.clientName;
      }
      
      debugPrint('🔒 [NewInvestmentEditor] Client data preservation:');
      debugPrint('   - Original clientId: "${currentInvestment.clientId}"');
      debugPrint('   - Original clientName: "${currentInvestment.clientName}"');
      debugPrint('   - Will preserve clientId: ${currentInvestment.clientId.isNotEmpty}');
      debugPrint('   - Will preserve clientName: ${currentInvestment.clientName.isNotEmpty}');
      
      debugPrint('📝 [NewInvestmentEditor] Dane do aktualizacji:');
      updateData.forEach((key, value) {
        if (['clientId', 'clientName', 'remainingCapital', 'investmentAmount'].contains(key)) {
          debugPrint('   - $key: $value');
        }
      });

      // Wykonaj aktualizację
      await _firestore
          .collection('investments')
          .doc(documentId)
          .update(updateData);

      debugPrint('✅ [NewInvestmentEditor] Aktualizacja Firebase zakończona pomyślnie');

      // Zapisz historię zmian
      await _recordChangeHistory(
        investmentId: investmentId,
        currentInvestment: currentInvestment,
        updatedInvestment: updatedInvestment,
        editorName: editorName,
        editorEmail: editorEmail,
      );

      return AtomicUpdateResult.success();

    } catch (e) {
      debugPrint('💥 [NewInvestmentEditor] Błąd atomowej aktualizacji: $e');
      return AtomicUpdateResult.failure('Błąd podczas aktualizacji Firebase: $e');
    }
  }

  /// 🔍 KROK 5: Weryfikacja po aktualizacji
  Future<VerificationResult> _verifyUpdateSuccess(String investmentId, Investment expectedInvestment) async {
    debugPrint('🔍 [NewInvestmentEditor] Weryfikacja po aktualizacji...');

    try {
      // Pobierz dane po aktualizacji
      await Future.delayed(Duration(milliseconds: 500)); // Daj czas na propagację
      
      final verificationInvestment = await _getInvestmentWithValidation(investmentId);
      if (verificationInvestment == null) {
        return VerificationResult.failure('Nie można pobrać inwestycji po aktualizacji');
      }

      // Sprawdź kluczowe pola
      final checks = <String, bool>{
        'clientId': verificationInvestment.clientId == expectedInvestment.clientId,
        'clientName': verificationInvestment.clientName == expectedInvestment.clientName,
        'remainingCapital': (verificationInvestment.remainingCapital - expectedInvestment.remainingCapital).abs() < 0.01,
        'investmentAmount': (verificationInvestment.investmentAmount - expectedInvestment.investmentAmount).abs() < 0.01,
      };

      final failures = checks.entries.where((e) => !e.value).map((e) => e.key).toList();
      
      if (failures.isNotEmpty) {
        debugPrint('❌ [NewInvestmentEditor] Weryfikacja nieudana dla pól: ${failures.join(", ")}');
        debugPrint('📊 [NewInvestmentEditor] Szczegóły weryfikacji:');
        debugPrint('   - Expected clientId: ${expectedInvestment.clientId}');
        debugPrint('   - Actual clientId: ${verificationInvestment.clientId}');
        debugPrint('   - Expected clientName: ${expectedInvestment.clientName}');
        debugPrint('   - Actual clientName: ${verificationInvestment.clientName}');
        debugPrint('   - Expected remainingCapital: ${expectedInvestment.remainingCapital}');
        debugPrint('   - Actual remainingCapital: ${verificationInvestment.remainingCapital}');
        
        return VerificationResult.failure('Weryfikacja nieudana dla pól: ${failures.join(", ")}');
      }

      debugPrint('✅ [NewInvestmentEditor] Weryfikacja zakończona pomyślnie');
      return VerificationResult.success();

    } catch (e) {
      debugPrint('💥 [NewInvestmentEditor] Błąd weryfikacji: $e');
      return VerificationResult.failure('Błąd podczas weryfikacji: $e');
    }
  }

  /// 🔄 ROLLBACK: Przywróć poprzednie dane w przypadku błędu
  Future<void> _attemptRollback(String investmentId, Investment originalInvestment) async {
    debugPrint('🔄 [NewInvestmentEditor] Próba rollback...');

    try {
      final querySnapshot = await _firestore
          .collection('investments')
          .where('id', isEqualTo: investmentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final documentId = querySnapshot.docs.first.id;
        await _firestore
            .collection('investments')
            .doc(documentId)
            .update(originalInvestment.toFirestore());
        
        debugPrint('✅ [NewInvestmentEditor] Rollback zakończony pomyślnie');
      }
    } catch (e) {
      debugPrint('💥 [NewInvestmentEditor] Błąd rollback: $e');
    }
  }

  /// 📝 Zapisz historię zmian
  Future<void> _recordChangeHistory({
    required String investmentId,
    required Investment currentInvestment,
    required Investment updatedInvestment,
    required String editorName,
    required String editorEmail,
  }) async {
    try {
      final changes = _getChangesApplied(currentInvestment, updatedInvestment);
      
      if (changes.isNotEmpty) {
        await _historyService.recordChange(
          investmentId: investmentId,
          oldValues: _buildOldValues(currentInvestment, changes),
          newValues: _buildNewValues(updatedInvestment, changes),
          changeType: InvestmentChangeType.fieldUpdate,
          customDescription: 'Edycja przez $editorName: ${changes.join(", ")}',
        );
        
        debugPrint('📝 [NewInvestmentEditor] Historia zmian zapisana: ${changes.join(", ")}');
      }
    } catch (e) {
      debugPrint('⚠️ [NewInvestmentEditor] Błąd zapisywania historii: $e');
      // Nie przerywaj procesu głównego
    }
  }

  /// 🔍 Pobierz listę zmian
  List<String> _getChangesApplied(Investment current, Investment updated) {
    final changes = <String>[];
    
    if ((current.remainingCapital - updated.remainingCapital).abs() > 0.01) {
      changes.add('remainingCapital: ${current.remainingCapital} → ${updated.remainingCapital}');
    }
    
    if ((current.investmentAmount - updated.investmentAmount).abs() > 0.01) {
      changes.add('investmentAmount: ${current.investmentAmount} → ${updated.investmentAmount}');
    }
    
    if ((current.capitalForRestructuring - updated.capitalForRestructuring).abs() > 0.01) {
      changes.add('capitalForRestructuring: ${current.capitalForRestructuring} → ${updated.capitalForRestructuring}');
    }
    
    if ((current.capitalSecuredByRealEstate - updated.capitalSecuredByRealEstate).abs() > 0.01) {
      changes.add('capitalSecuredByRealEstate: ${current.capitalSecuredByRealEstate} → ${updated.capitalSecuredByRealEstate}');
    }
    
    if (current.status != updated.status) {
      changes.add('status: ${current.status} → ${updated.status}');
    }
    
    return changes;
  }

  Map<String, dynamic> _buildOldValues(Investment investment, List<String> changes) {
    final result = <String, dynamic>{};
    
    for (final change in changes) {
      if (change.contains('remainingCapital')) result['remainingCapital'] = investment.remainingCapital;
      if (change.contains('investmentAmount')) result['investmentAmount'] = investment.investmentAmount;
      if (change.contains('capitalForRestructuring')) result['capitalForRestructuring'] = investment.capitalForRestructuring;
      if (change.contains('capitalSecuredByRealEstate')) result['capitalSecuredByRealEstate'] = investment.capitalSecuredByRealEstate;
      if (change.contains('status')) result['status'] = investment.status.toString();
    }
    
    return result;
  }

  Map<String, dynamic> _buildNewValues(Investment investment, List<String> changes) {
    final result = <String, dynamic>{};
    
    for (final change in changes) {
      if (change.contains('remainingCapital')) result['remainingCapital'] = investment.remainingCapital;
      if (change.contains('investmentAmount')) result['investmentAmount'] = investment.investmentAmount;
      if (change.contains('capitalForRestructuring')) result['capitalForRestructuring'] = investment.capitalForRestructuring;
      if (change.contains('capitalSecuredByRealEstate')) result['capitalSecuredByRealEstate'] = investment.capitalSecuredByRealEstate;
      if (change.contains('status')) result['status'] = investment.status.toString();
    }
    
    return result;
  }

  /// 🧹 Wyczyść cache po edycji
  @override
  Future<void> clearAllCache() async {
    // Implementacja czyszczenia cache
    debugPrint('🧹 [NewInvestmentEditor] Czyszczenie cache...');
  }
}

/// 📝 Żądanie edycji inwestycji
class InvestmentEditRequest {
  final double? remainingCapital;
  final double? investmentAmount;
  final double? capitalForRestructuring;
  final double? capitalSecuredByRealEstate;
  final InvestmentStatus? status;

  InvestmentEditRequest({
    this.remainingCapital,
    this.investmentAmount,
    this.capitalForRestructuring,
    this.capitalSecuredByRealEstate,
    this.status,
  });

  @override
  String toString() {
    final fields = <String>[];
    if (remainingCapital != null) fields.add('remainingCapital: $remainingCapital');
    if (investmentAmount != null) fields.add('investmentAmount: $investmentAmount');
    if (capitalForRestructuring != null) fields.add('capitalForRestructuring: $capitalForRestructuring');
    if (capitalSecuredByRealEstate != null) fields.add('capitalSecuredByRealEstate: $capitalSecuredByRealEstate');
    if (status != null) fields.add('status: $status');
    return 'InvestmentEditRequest(${fields.join(', ')})';
  }
}

/// 📊 Wynik edycji inwestycji
class InvestmentEditResult {
  final bool success;
  final String? error;
  final Investment? originalInvestment;
  final Investment? updatedInvestment;
  final List<String> changesApplied;
  final Duration duration;

  InvestmentEditResult._({
    required this.success,
    this.error,
    this.originalInvestment,
    this.updatedInvestment,
    this.changesApplied = const [],
    required this.duration,
  });

  factory InvestmentEditResult.success({
    required Investment originalInvestment,
    required Investment updatedInvestment,
    required List<String> changesApplied,
    required Duration duration,
  }) {
    return InvestmentEditResult._(
      success: true,
      originalInvestment: originalInvestment,
      updatedInvestment: updatedInvestment,
      changesApplied: changesApplied,
      duration: duration,
    );
  }

  factory InvestmentEditResult.failure(String error, {required Duration duration}) {
    return InvestmentEditResult._(
      success: false,
      error: error,
      duration: duration,
    );
  }
}

/// ✅ Wynik walidacji
class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult._(this.isValid, this.error);

  factory ValidationResult.valid() => ValidationResult._(true, null);
  factory ValidationResult.invalid(String error) => ValidationResult._(false, error);
}

/// 💾 Wynik atomowej aktualizacji
class AtomicUpdateResult {
  final bool success;
  final String? error;

  AtomicUpdateResult._(this.success, this.error);

  factory AtomicUpdateResult.success() => AtomicUpdateResult._(true, null);
  factory AtomicUpdateResult.failure(String error) => AtomicUpdateResult._(false, error);
}

/// 🔍 Wynik weryfikacji
class VerificationResult {
  final bool success;
  final String? error;

  VerificationResult._(this.success, this.error);

  factory VerificationResult.success() => VerificationResult._(true, null);
  factory VerificationResult.failure(String error) => VerificationResult._(false, error);
}