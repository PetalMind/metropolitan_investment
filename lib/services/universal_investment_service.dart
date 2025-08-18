import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';

/// 🌟 UNIVERSAL INVESTMENT SERVICE
///
/// JEDYNY SERWIS DO ZARZĄDZANIA DANYMI INWESTYCJI W CAŁEJ APLIKACJI
///
/// Zastępuje wszystkie inne serwisy:
/// - InvestmentService
/// - UltraPreciseProductInvestorsService
/// - InvestorEditService
/// - NewInvestmentEditorService
/// - ProductManagementService (część inwestycyjna)
///
/// GŁÓWNE ZASADY:
/// 1. Jeden source of truth - Firebase collection 'investments'
/// 2. Konsystentne pobieranie/zapisywanie danych
/// 3. Unified cache management
/// 4. Atomic operations z rollback
/// 5. Comprehensive error handling
/// 6. Detailed logging
class UniversalInvestmentService extends BaseService {
  static UniversalInvestmentService? _instance;

  /// Singleton instance - WSZĘDZIE w aplikacji używamy tego samego serwisu
  static UniversalInvestmentService get instance {
    _instance ??= UniversalInvestmentService._internal();
    return _instance!;
  }

  UniversalInvestmentService._internal() : super();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'investments';

  // Cache dla inwestycji (ID → Investment)
  final Map<String, Investment> _investmentCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheTTL = const Duration(minutes: 5);

  /// 🎯 PODSTAWOWE OPERACJE CRUD

  /// Pobiera pojedynczą inwestycję po ID
  Future<Investment?> getInvestment(String investmentId) async {
    try {
      debugPrint('🔍 [UniversalInvestment] Getting investment: $investmentId');

      // Sprawdź cache
      if (_isInCache(investmentId)) {
        debugPrint(
          '✅ [UniversalInvestment] Returning from cache: $investmentId',
        );
        return _investmentCache[investmentId];
      }

      // Pobierz z Firebase
      final investment = await _fetchInvestmentFromFirebase(investmentId);

      if (investment != null) {
        _cacheInvestment(investment);
        debugPrint('✅ [UniversalInvestment] Cached investment: $investmentId');
      }

      return investment;
    } catch (e) {
      debugPrint(
        '❌ [UniversalInvestment] Error getting investment $investmentId: $e',
      );
      return null;
    }
  }

  /// Pobiera multiple inwestycje po ID
  Future<List<Investment>> getInvestments(List<String> investmentIds) async {
    try {
      debugPrint(
        '🔍 [UniversalInvestment] Getting ${investmentIds.length} investments',
      );

      final investments = <Investment>[];
      final uncachedIds = <String>[];

      // Sprawdź cache
      for (final id in investmentIds) {
        if (_isInCache(id)) {
          investments.add(_investmentCache[id]!);
        } else {
          uncachedIds.add(id);
        }
      }

      debugPrint(
        '✅ [UniversalInvestment] Found ${investments.length} in cache, need to fetch ${uncachedIds.length}',
      );

      // Pobierz brakujące z Firebase
      if (uncachedIds.isNotEmpty) {
        final fetchedInvestments = await _fetchMultipleInvestmentsFromFirebase(
          uncachedIds,
        );
        investments.addAll(fetchedInvestments);

        // Cache nowe inwestycje
        for (final investment in fetchedInvestments) {
          _cacheInvestment(investment);
        }
      }

      debugPrint(
        '✅ [UniversalInvestment] Returning ${investments.length} investments',
      );
      return investments;
    } catch (e) {
      debugPrint('❌ [UniversalInvestment] Error getting investments: $e');
      return [];
    }
  }

  /// 🎯 AUTOMATIC CAPITAL CALCULATION
  /// Oblicza kapitał pozostały na podstawie nieruchomości i restrukturyzacji
  double calculateRemainingCapital({
    required double capitalSecuredByRealEstate,
    required double capitalForRestructuring,
  }) {
    return capitalSecuredByRealEstate + capitalForRestructuring;
  }

  /// 🎯 SMART UPDATE - automatycznie oblicza powiązane pola
  Future<bool> updateInvestmentFieldsSmart(
    String investmentId, {
    double? investmentAmount,
    double? capitalForRestructuring,
    double? capitalSecuredByRealEstate,
    double? remainingCapital, // można nadpisać automatyczne obliczenie
    bool autoCalculateRemainingCapital = true,
    InvestmentStatus? status,
    String? editorName,
    String? editorEmail,
    String? changeReason,
  }) async {
    try {
      debugPrint(
        '🧮 [UniversalInvestment] SMART UPDATE for investment: $investmentId',
      );

      // 1. Pobierz current state
      final currentInvestment = await getInvestment(investmentId);
      if (currentInvestment == null) {
        debugPrint(
          '❌ [UniversalInvestment] Investment not found: $investmentId',
        );
        return false;
      }

      // 2. Użyj obecnych wartości jako domyślnych jeśli nie podano nowych
      final newCapitalSecured = capitalSecuredByRealEstate ?? currentInvestment.capitalSecuredByRealEstate;
      final newCapitalRestructuring = capitalForRestructuring ?? currentInvestment.capitalForRestructuring;
      final newInvestmentAmount = investmentAmount ?? currentInvestment.investmentAmount;

      // 3. Automatycznie oblicz remainingCapital jeśli nie podano jawnie
      double newRemainingCapital;
      if (remainingCapital != null) {
        // Użytkownik podał jawną wartość
        newRemainingCapital = remainingCapital;
        debugPrint('💡 [UniversalInvestment] Using manual remainingCapital: $remainingCapital');
      } else if (autoCalculateRemainingCapital) {
        // Automatyczne obliczenie
        newRemainingCapital = calculateRemainingCapital(
          capitalSecuredByRealEstate: newCapitalSecured,
          capitalForRestructuring: newCapitalRestructuring,
        );
        debugPrint('🧮 [UniversalInvestment] Auto-calculated remainingCapital: $newCapitalSecured + $newCapitalRestructuring = $newRemainingCapital');
      } else {
        // Zachowaj obecną wartość
        newRemainingCapital = currentInvestment.remainingCapital;
        debugPrint('💾 [UniversalInvestment] Preserving current remainingCapital: $newRemainingCapital');
      }

      // 4. Wykonaj standardową aktualizację z obliczonymi wartościami
      return await updateInvestmentFields(
        investmentId,
        remainingCapital: newRemainingCapital,
        investmentAmount: newInvestmentAmount,
        capitalForRestructuring: newCapitalRestructuring,
        capitalSecuredByRealEstate: newCapitalSecured,
        status: status,
        editorName: editorName,
        editorEmail: editorEmail,
        changeReason: changeReason ?? 'Smart update with automatic capital calculation',
      );

    } catch (e) {
      debugPrint(
        '❌ [UniversalInvestment] Error in smart update for $investmentId: $e',
      );
      return false;
    }
  }

  /// 🎯 PARTIAL UPDATE - aktualizuje tylko wybrane pola bez nadpisywania reszty
  Future<bool> updateInvestmentFields(
    String investmentId, {
    double? remainingCapital,
    double? investmentAmount,
    double? capitalForRestructuring,
    double? capitalSecuredByRealEstate,
    InvestmentStatus? status,
    String? editorName,
    String? editorEmail,
    String? changeReason,
  }) async {
    try {
      debugPrint(
        '💾 [UniversalInvestment] PARTIAL UPDATE for investment: $investmentId',
      );
      debugPrint('🔍 [UniversalInvestment] Input values:');
      if (remainingCapital != null) {
        debugPrint('   - remainingCapital: $remainingCapital');
      }
      if (investmentAmount != null) {
        debugPrint('   - investmentAmount: $investmentAmount');
      }
      if (capitalForRestructuring != null) {
        debugPrint('   - capitalForRestructuring: $capitalForRestructuring');
      }
      if (capitalSecuredByRealEstate != null) {
        debugPrint(
          '   - capitalSecuredByRealEstate: $capitalSecuredByRealEstate',
        );
      }
      if (status != null) {
        debugPrint('   - status: $status');
      }

      // 1. Pobierz current state
      final currentInvestment = await getInvestment(investmentId);
      if (currentInvestment == null) {
        debugPrint(
          '❌ [UniversalInvestment] Investment not found: $investmentId',
        );
        return false;
      }

      debugPrint('🔍 [UniversalInvestment] Current values:');
      debugPrint(
        '   - remainingCapital: ${currentInvestment.remainingCapital}',
      );
      debugPrint(
        '   - investmentAmount: ${currentInvestment.investmentAmount}',
      );
      debugPrint(
        '   - capitalForRestructuring: ${currentInvestment.capitalForRestructuring}',
      );
      debugPrint(
        '   - capitalSecuredByRealEstate: ${currentInvestment.capitalSecuredByRealEstate}',
      );
      debugPrint('   - status: ${currentInvestment.status}');

      // 2. Przygotuj tylko te pola które się zmieniają
      final fieldsToUpdate = <String, dynamic>{};
      final oldValues = <String, dynamic>{};
      final newValues = <String, dynamic>{};

      if (remainingCapital != null &&
          (remainingCapital - currentInvestment.remainingCapital).abs() >
              0.01) {
        fieldsToUpdate['remainingCapital'] = remainingCapital;
        oldValues['remainingCapital'] = currentInvestment.remainingCapital;
        newValues['remainingCapital'] = remainingCapital;
        debugPrint(
          '📝 [UniversalInvestment] Will update remainingCapital: ${currentInvestment.remainingCapital} → $remainingCapital',
        );
      }

      if (investmentAmount != null &&
          (investmentAmount - currentInvestment.investmentAmount).abs() >
              0.01) {
        fieldsToUpdate['investmentAmount'] = investmentAmount;
        oldValues['investmentAmount'] = currentInvestment.investmentAmount;
        newValues['investmentAmount'] = investmentAmount;
        debugPrint(
          '📝 [UniversalInvestment] Will update investmentAmount: ${currentInvestment.investmentAmount} → $investmentAmount',
        );
      }

      if (capitalForRestructuring != null &&
          (capitalForRestructuring - currentInvestment.capitalForRestructuring)
                  .abs() >
              0.01) {
        fieldsToUpdate['capitalForRestructuring'] = capitalForRestructuring;
        oldValues['capitalForRestructuring'] =
            currentInvestment.capitalForRestructuring;
        newValues['capitalForRestructuring'] = capitalForRestructuring;
        debugPrint(
          '📝 [UniversalInvestment] Will update capitalForRestructuring: ${currentInvestment.capitalForRestructuring} → $capitalForRestructuring',
        );
      }

      if (capitalSecuredByRealEstate != null &&
          (capitalSecuredByRealEstate -
                      currentInvestment.capitalSecuredByRealEstate)
                  .abs() >
              0.01) {
        fieldsToUpdate['capitalSecuredByRealEstate'] =
            capitalSecuredByRealEstate;
        oldValues['capitalSecuredByRealEstate'] =
            currentInvestment.capitalSecuredByRealEstate;
        newValues['capitalSecuredByRealEstate'] = capitalSecuredByRealEstate;
        debugPrint(
          '📝 [UniversalInvestment] Will update capitalSecuredByRealEstate: ${currentInvestment.capitalSecuredByRealEstate} → $capitalSecuredByRealEstate',
        );
      }

      if (status != null && status != currentInvestment.status) {
        fieldsToUpdate['productStatus'] = status.displayName;
        oldValues['status'] = currentInvestment.status.toString();
        newValues['status'] = status.toString();
        debugPrint(
          '📝 [UniversalInvestment] Will update status: ${currentInvestment.status} → $status',
        );
      }

      // Dodaj timestamp aktualizacji
      fieldsToUpdate['updatedAt'] = DateTime.now().toIso8601String();

      if (fieldsToUpdate.isEmpty) {
        debugPrint(
          'ℹ️ [UniversalInvestment] No changes detected for $investmentId',
        );
        return true;
      }

      debugPrint(
        '💾 [UniversalInvestment] Updating ${fieldsToUpdate.length} fields for $investmentId',
      );

      // 3. Walidacja tylko zmienianych pól
      final validation = _validatePartialUpdate(fieldsToUpdate);
      if (!validation.isValid) {
        debugPrint(
          '❌ [UniversalInvestment] Partial validation failed: ${validation.error}',
        );
        return false;
      }

      // 4. Atomic partial update
      final success = await _performPartialUpdate(investmentId, fieldsToUpdate);

      if (success) {
        // 5. Update cache (merge changes into cached investment)
        _updateCachedInvestment(investmentId, fieldsToUpdate);

        // 6. Record change history
        if (oldValues.isNotEmpty) {
          await _recordSimpleChangeHistory(
            investmentId: investmentId,
            oldValues: oldValues,
            newValues: newValues,
            editorName: editorName,
            editorEmail: editorEmail,
            changeReason: changeReason,
          );
        }

        debugPrint(
          '✅ [UniversalInvestment] Successfully updated fields for: $investmentId',
        );
        debugPrint('🔍 [UniversalInvestment] Final result:');
        debugPrint('   - Changed fields: ${fieldsToUpdate.keys.join(", ")}');
        debugPrint('   - Timestamp: ${fieldsToUpdate['updatedAt']}');

        return true;
      } else {
        debugPrint(
          '❌ [UniversalInvestment] Failed to update fields for: $investmentId',
        );
        return false;
      }
    } catch (e) {
      debugPrint(
        '❌ [UniversalInvestment] Error in partial update for $investmentId: $e',
      );
      return false;
    }
  }

  /// Zapisuje/aktualizuje inwestycję z pełną walidacją
  Future<bool> saveInvestment(
    Investment investment, {
    String? editorName,
    String? editorEmail,
    String? changeReason,
  }) async {
    try {
      debugPrint(
        '💾 [UniversalInvestment] Saving investment: ${investment.id}',
      );
      debugPrint(
        '📊 [UniversalInvestment] Data: remainingCapital=${investment.remainingCapital}, investmentAmount=${investment.investmentAmount}',
      );

      // 1. Pobierz current state dla historii zmian
      final currentInvestment = await getInvestment(investment.id);

      // 2. Walidacja biznesowa
      final validationResult = _validateInvestmentData(investment);
      if (!validationResult.isValid) {
        debugPrint(
          '❌ [UniversalInvestment] Validation failed: ${validationResult.error}',
        );
        return false;
      }

      // 3. Przygotuj dane do zapisania
      final dataToSave = _prepareDataForFirebase(investment);

      // 4. Atomic update/create
      final success = await _performAtomicSave(investment.id, dataToSave);

      if (success) {
        // 5. Update cache
        _cacheInvestment(investment);

        // 6. Record change history
        if (currentInvestment != null) {
          await _recordChangeHistory(
            currentInvestment: currentInvestment,
            newInvestment: investment,
            editorName: editorName,
            editorEmail: editorEmail,
            changeReason: changeReason,
          );
        }

        debugPrint(
          '✅ [UniversalInvestment] Successfully saved investment: ${investment.id}',
        );
        return true;
      } else {
        debugPrint(
          '❌ [UniversalInvestment] Failed to save investment: ${investment.id}',
        );
        return false;
      }
    } catch (e) {
      debugPrint(
        '❌ [UniversalInvestment] Error saving investment ${investment.id}: $e',
      );
      return false;
    }
  }

  /// 🎯 SPECIALIZED QUERIES

  /// Pobiera inwestycje dla konkretnego produktu
  Future<List<Investment>> getInvestmentsForProduct(String productId) async {
    try {
      debugPrint(
        '🔍 [UniversalInvestment] Getting investments for product: $productId',
      );

      final cacheKey = 'product_$productId';
      if (_isInCache(cacheKey)) {
        // Zwróć cached list
        final cachedData = _investmentCache[cacheKey];
        if (cachedData?.additionalInfo['investments'] is List<Investment>) {
          return cachedData!.additionalInfo['investments'] as List<Investment>;
        }
      }

      // Query Firebase
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('productId', isEqualTo: productId)
          .get();

      final investments = querySnapshot.docs
          .map((doc) => Investment.fromFirestore(doc))
          .toList();

      debugPrint(
        '✅ [UniversalInvestment] Found ${investments.length} investments for product $productId',
      );

      // Cache result
      final cacheEntry = Investment(
        id: cacheKey,
        clientId: 'cache',
        clientName: 'cache',
        employeeId: 'cache',
        employeeFirstName: 'cache',
        employeeLastName: 'cache',
        branchCode: 'cache',
        status: InvestmentStatus.active,
        marketType: MarketType.primary,
        signedDate: DateTime.now(),
        proposalId: 'cache',
        productType: ProductType.bonds,
        productName: 'cache',
        creditorCompany: 'cache',
        companyId: 'cache',
        investmentAmount: 0,
        paidAmount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        additionalInfo: {'investments': investments},
      );
      _cacheInvestment(cacheEntry);

      return investments;
    } catch (e) {
      debugPrint(
        '❌ [UniversalInvestment] Error getting investments for product $productId: $e',
      );
      return [];
    }
  }

  /// Pobiera inwestycje dla konkretnego klienta
  Future<List<Investment>> getInvestmentsForClient(String clientId) async {
    try {
      debugPrint(
        '🔍 [UniversalInvestment] Getting investments for client: $clientId',
      );

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('clientId', isEqualTo: clientId)
          .get();

      final investments = querySnapshot.docs
          .map((doc) => Investment.fromFirestore(doc))
          .toList();

      debugPrint(
        '✅ [UniversalInvestment] Found ${investments.length} investments for client $clientId',
      );

      // Cache individual investments
      for (final investment in investments) {
        _cacheInvestment(investment);
      }

      return investments;
    } catch (e) {
      debugPrint(
        '❌ [UniversalInvestment] Error getting investments for client $clientId: $e',
      );
      return [];
    }
  }

  /// 🎯 CACHE MANAGEMENT

  bool _isInCache(String key) {
    if (!_investmentCache.containsKey(key)) return false;

    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;

    final age = DateTime.now().difference(timestamp);
    if (age > _cacheTTL) {
      _investmentCache.remove(key);
      _cacheTimestamps.remove(key);
      return false;
    }

    return true;
  }

  void _cacheInvestment(Investment investment) {
    _investmentCache[investment.id] = investment;
    _cacheTimestamps[investment.id] = DateTime.now();
  }

  /// Wyczyść cały cache
  @override
  Future<void> clearAllCache() async {
    _investmentCache.clear();
    _cacheTimestamps.clear();
    debugPrint('🧹 [UniversalInvestment] All cache cleared');
  }

  /// 🎯 PRIVATE HELPERS

  Future<Investment?> _fetchInvestmentFromFirebase(String investmentId) async {
    try {
      // Strategia 1: Szukaj po logicznym ID w polu 'id'
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('id', isEqualTo: investmentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return Investment.fromFirestore(doc);
      }

      // Strategia 2: Szukaj po UUID dokumentu (fallback)
      final docSnapshot = await _firestore
          .collection(_collection)
          .doc(investmentId)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return Investment.fromFirestore(docSnapshot);
      }

      return null;
    } catch (e) {
      debugPrint('❌ [UniversalInvestment] Error fetching from Firebase: $e');
      return null;
    }
  }

  Future<List<Investment>> _fetchMultipleInvestmentsFromFirebase(
    List<String> investmentIds,
  ) async {
    final investments = <Investment>[];

    for (final id in investmentIds) {
      final investment = await _fetchInvestmentFromFirebase(id);
      if (investment != null) {
        investments.add(investment);
      }
    }

    return investments;
  }

  ValidationResult _validateInvestmentData(Investment investment) {
    if (investment.remainingCapital < 0) {
      return ValidationResult.invalid('Kapitał pozostały nie może być ujemny');
    }

    if (investment.investmentAmount < 0) {
      return ValidationResult.invalid('Kwota inwestycji nie może być ujemna');
    }

    if (investment.capitalForRestructuring < 0) {
      return ValidationResult.invalid(
        'Kapitał do restrukturyzacji nie może być ujemny',
      );
    }

    if (investment.capitalSecuredByRealEstate < 0) {
      return ValidationResult.invalid(
        'Kapitał zabezpieczony nie może być ujemny',
      );
    }

    return ValidationResult.valid();
  }

  Map<String, dynamic> _prepareDataForFirebase(Investment investment) {
    final data = investment.toFirestore();

    // Remove null values
    data.removeWhere((key, value) => value == null);

    // Ensure numeric fields are properly formatted
    if (data['remainingCapital'] is double) {
      data['remainingCapital'] = (data['remainingCapital'] as double);
    }
    if (data['investmentAmount'] is double) {
      data['investmentAmount'] = (data['investmentAmount'] as double);
    }
    if (data['capitalForRestructuring'] is double) {
      data['capitalForRestructuring'] =
          (data['capitalForRestructuring'] as double);
    }
    if (data['capitalSecuredByRealEstate'] is double) {
      data['capitalSecuredByRealEstate'] =
          (data['capitalSecuredByRealEstate'] as double);
    }

    return data;
  }

  ValidationResult _validatePartialUpdate(Map<String, dynamic> fields) {
    if (fields.containsKey('remainingCapital')) {
      final value = fields['remainingCapital'];
      if (value is double && value < 0) {
        return ValidationResult.invalid(
          'Kapitał pozostały nie może być ujemny',
        );
      }
    }

    if (fields.containsKey('investmentAmount')) {
      final value = fields['investmentAmount'];
      if (value is double && value < 0) {
        return ValidationResult.invalid('Kwota inwestycji nie może być ujemna');
      }
    }

    if (fields.containsKey('capitalForRestructuring')) {
      final value = fields['capitalForRestructuring'];
      if (value is double && value < 0) {
        return ValidationResult.invalid(
          'Kapitał do restrukturyzacji nie może być ujemny',
        );
      }
    }

    if (fields.containsKey('capitalSecuredByRealEstate')) {
      final value = fields['capitalSecuredByRealEstate'];
      if (value is double && value < 0) {
        return ValidationResult.invalid(
          'Kapitał zabezpieczony nie może być ujemny',
        );
      }
    }

    return ValidationResult.valid();
  }

  Future<bool> _performPartialUpdate(
    String investmentId,
    Map<String, dynamic> fieldsToUpdate,
  ) async {
    try {
      debugPrint(
        '💾 [UniversalInvestment] Performing partial update for $investmentId with ${fieldsToUpdate.length} fields',
      );
      debugPrint(
        '🔍 [UniversalInvestment] Fields to update: ${fieldsToUpdate.keys.join(", ")}',
      );

      // Znajdź dokument
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('id', isEqualTo: investmentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Update existing - PARTIAL UPDATE (nie zastępuje całego dokumentu)
        final documentId = querySnapshot.docs.first.id;
        final currentData = querySnapshot.docs.first.data();

        debugPrint('📋 [UniversalInvestment] Found document: $documentId');
        debugPrint(
          '🔍 [UniversalInvestment] Current investmentAmount in DB: ${currentData['investmentAmount']}',
        );
        debugPrint(
          '🔍 [UniversalInvestment] Current remainingCapital in DB: ${currentData['remainingCapital']}',
        );

        await _firestore
            .collection(_collection)
            .doc(documentId)
            .update(
              fieldsToUpdate,
            ); // ← To jest kluczowe - update() zamiast set()

        // 🔍 Verify the update by re-reading the document
        final updatedDoc = await _firestore
            .collection(_collection)
            .doc(documentId)
            .get();

        if (updatedDoc.exists) {
          final updatedData = updatedDoc.data()!;
          debugPrint(
            '✅ [UniversalInvestment] Verification - Updated data in DB:',
          );
          debugPrint(
            '   - investmentAmount: ${updatedData['investmentAmount']}',
          );
          debugPrint(
            '   - remainingCapital: ${updatedData['remainingCapital']}',
          );
          debugPrint(
            '   - capitalForRestructuring: ${updatedData['capitalForRestructuring']}',
          );
          debugPrint(
            '   - capitalSecuredByRealEstate: ${updatedData['capitalSecuredByRealEstate']}',
          );
          debugPrint('   - updatedAt: ${updatedData['updatedAt']}');
        }

        debugPrint(
          '✅ [UniversalInvestment] Partial update successful for document: $documentId',
        );
        return true;
      } else {
        debugPrint(
          '❌ [UniversalInvestment] Document not found for partial update: $investmentId',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ [UniversalInvestment] Partial update failed: $e');
      return false;
    }
  }

  void _updateCachedInvestment(
    String investmentId,
    Map<String, dynamic> updatedFields,
  ) {
    if (_investmentCache.containsKey(investmentId)) {
      final cached = _investmentCache[investmentId]!;

      // Create updated investment by merging changes
      final updatedInvestment = cached.copyWith(
        remainingCapital: updatedFields.containsKey('remainingCapital')
            ? updatedFields['remainingCapital'] as double
            : cached.remainingCapital,
        investmentAmount: updatedFields.containsKey('investmentAmount')
            ? updatedFields['investmentAmount'] as double
            : cached.investmentAmount,
        capitalForRestructuring:
            updatedFields.containsKey('capitalForRestructuring')
            ? updatedFields['capitalForRestructuring'] as double
            : cached.capitalForRestructuring,
        capitalSecuredByRealEstate:
            updatedFields.containsKey('capitalSecuredByRealEstate')
            ? updatedFields['capitalSecuredByRealEstate'] as double
            : cached.capitalSecuredByRealEstate,
        updatedAt: DateTime.now(),
      );

      _cacheInvestment(updatedInvestment);
      debugPrint(
        '✅ [UniversalInvestment] Updated cached investment: $investmentId',
      );
    }
  }

  Future<void> _recordSimpleChangeHistory({
    required String investmentId,
    required Map<String, dynamic> oldValues,
    required Map<String, dynamic> newValues,
    String? editorName,
    String? editorEmail,
    String? changeReason,
  }) async {
    try {
      final historyService = InvestmentChangeHistoryService();

      await historyService.recordChange(
        investmentId: investmentId,
        oldValues: oldValues,
        newValues: newValues,
        changeType: InvestmentChangeType.fieldUpdate,
        customDescription:
            changeReason ?? 'Universal Investment Service partial update',
      );

      debugPrint(
        '✅ [UniversalInvestment] Change history recorded for: $investmentId',
      );
    } catch (e) {
      debugPrint(
        '⚠️ [UniversalInvestment] Failed to record change history: $e',
      );
      // Don't fail the main operation
    }
  }

  Future<bool> _performAtomicSave(
    String investmentId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Znajdź dokument
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('id', isEqualTo: investmentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Update existing
        final documentId = querySnapshot.docs.first.id;
        await _firestore.collection(_collection).doc(documentId).update(data);
        return true;
      } else {
        // Create new
        await _firestore.collection(_collection).doc().set(data);
        return true;
      }
    } catch (e) {
      debugPrint('❌ [UniversalInvestment] Atomic save failed: $e');
      return false;
    }
  }

  Future<void> _recordChangeHistory({
    required Investment currentInvestment,
    required Investment newInvestment,
    String? editorName,
    String? editorEmail,
    String? changeReason,
  }) async {
    try {
      final historyService = InvestmentChangeHistoryService();

      final oldValues = <String, dynamic>{};
      final newValues = <String, dynamic>{};

      // Compare fields
      if ((currentInvestment.remainingCapital - newInvestment.remainingCapital)
              .abs() >
          0.01) {
        oldValues['remainingCapital'] = currentInvestment.remainingCapital;
        newValues['remainingCapital'] = newInvestment.remainingCapital;
      }

      if ((currentInvestment.investmentAmount - newInvestment.investmentAmount)
              .abs() >
          0.01) {
        oldValues['investmentAmount'] = currentInvestment.investmentAmount;
        newValues['investmentAmount'] = newInvestment.investmentAmount;
      }

      if ((currentInvestment.capitalForRestructuring -
                  newInvestment.capitalForRestructuring)
              .abs() >
          0.01) {
        oldValues['capitalForRestructuring'] =
            currentInvestment.capitalForRestructuring;
        newValues['capitalForRestructuring'] =
            newInvestment.capitalForRestructuring;
      }

      if ((currentInvestment.capitalSecuredByRealEstate -
                  newInvestment.capitalSecuredByRealEstate)
              .abs() >
          0.01) {
        oldValues['capitalSecuredByRealEstate'] =
            currentInvestment.capitalSecuredByRealEstate;
        newValues['capitalSecuredByRealEstate'] =
            newInvestment.capitalSecuredByRealEstate;
      }

      if (currentInvestment.status != newInvestment.status) {
        oldValues['status'] = currentInvestment.status.toString();
        newValues['status'] = newInvestment.status.toString();
      }

      if (oldValues.isNotEmpty) {
        await historyService.recordChange(
          investmentId: currentInvestment.id,
          oldValues: oldValues,
          newValues: newValues,
          changeType: InvestmentChangeType.fieldUpdate,
          customDescription:
              changeReason ?? 'Universal Investment Service update',
        );
      }
    } catch (e) {
      debugPrint(
        '⚠️ [UniversalInvestment] Failed to record change history: $e',
      );
      // Don't fail the main operation
    }
  }
}

/// Validation result helper
class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult._(this.isValid, this.error);

  factory ValidationResult.valid() => ValidationResult._(true, null);
  factory ValidationResult.invalid(String error) =>
      ValidationResult._(false, error);
}
