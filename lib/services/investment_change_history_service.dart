import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/investment_change_history.dart';
import '../models/investment.dart';
import 'base_service.dart';

/// Serwis do zarządzania historią zmian inwestycji
class InvestmentChangeHistoryService extends BaseService {
  static const String _collectionName = 'investment_change_history';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Zapisuje historię zmian inwestycji
  Future<void> recordChange({
    required String investmentId,
    required Map<String, dynamic> oldValues,
    required Map<String, dynamic> newValues,
    InvestmentChangeType changeType = InvestmentChangeType.fieldUpdate,
    String? customDescription,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        logError(
          'recordChange',
          'Brak zalogowanego użytkownika - nie można zapisać historii zmian',
        );
        return;
      }

      // Sprawdź czy faktycznie są jakieś zmiany
      final hasChanges = _hasAnyChanges(oldValues, newValues);
      if (!hasChanges) {
        return;
      }

      final changeHistory = InvestmentChangeHistory.fromChanges(
        investmentId: investmentId,
        userId: user.uid,
        userEmail: user.email ?? 'Nieznany email',
        userName: user.displayName ?? user.email ?? 'Nieznany użytkownik',
        oldValues: oldValues,
        newValues: newValues,
        changeType: changeType.value,
        customDescription: customDescription,
        metadata: metadata ?? {},
      );

      await _firestore
          .collection(_collectionName)
          .add(changeHistory.toFirestore());

    } catch (e) {
      logError('recordChange', 'Błąd podczas zapisywania historii zmian: $e');
    }
  }

  /// Pobiera historię zmian dla konkretnej inwestycji
  Future<List<InvestmentChangeHistory>> getInvestmentHistory(
    String investmentId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('investmentId', isEqualTo: investmentId)
          .orderBy('changedAt', descending: true)
          .limit(100) // Ograniczenie do 100 ostatnich zmian
          .get();

      return snapshot.docs
          .map((doc) => InvestmentChangeHistory.fromFirestore(doc))
          .toList();
    } catch (e) {
      logError(
        'getInvestmentHistory',
        'Błąd podczas pobierania historii zmian: $e',
      );
      return [];
    }
  }

  /// Pobiera historię zmian dla klienta (wszystkich jego inwestycji)
  Future<List<InvestmentChangeHistory>> getClientHistory(
    String clientId,
  ) async {
    try {
      // Najpierw pobierz wszystkie inwestycje klienta
      final investmentsSnapshot = await _firestore
          .collection('investments')
          .where('clientId', isEqualTo: clientId)
          .get();

      final investmentIds = investmentsSnapshot.docs
          .map((doc) => doc.id)
          .toList();

      if (investmentIds.isEmpty) {
        return [];
      }

      // Pobierz historię dla wszystkich inwestycji klienta
      final historySnapshot = await _firestore
          .collection(_collectionName)
          .where('investmentId', whereIn: investmentIds)
          .orderBy('changedAt', descending: true)
          .limit(200)
          .get();

      return historySnapshot.docs
          .map((doc) => InvestmentChangeHistory.fromFirestore(doc))
          .toList();
    } catch (e) {
      logError(
        'getClientHistory',
        'Błąd podczas pobierania historii klienta: $e',
      );
      return [];
    }
  }

  /// Pobiera ostatnie zmiany w systemie (dla administratorów)
  Future<List<InvestmentChangeHistory>> getRecentChanges({
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('changedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => InvestmentChangeHistory.fromFirestore(doc))
          .toList();
    } catch (e) {
      logError(
        'getRecentChanges',
        'Błąd podczas pobierania ostatnich zmian: $e',
      );
      return [];
    }
  }

  /// Pobiera historię zmian dla użytkownika
  Future<List<InvestmentChangeHistory>> getUserHistory(
    String userId, {
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('changedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => InvestmentChangeHistory.fromFirestore(doc))
          .toList();
    } catch (e) {
      logError(
        'getUserHistory',
        'Błąd podczas pobierania historii użytkownika: $e',
      );
      return [];
    }
  }

  /// Zapisuje historię zmian na podstawie porównania obiektów Investment
  Future<void> recordInvestmentChange({
    required Investment oldInvestment,
    required Investment newInvestment,
    InvestmentChangeType changeType = InvestmentChangeType.fieldUpdate,
    String? customDescription,
    Map<String, dynamic>? metadata,
  }) async {
    final oldValues = _investmentToComparableMap(oldInvestment);
    final newValues = _investmentToComparableMap(newInvestment);

    await recordChange(
      investmentId: newInvestment.id,
      oldValues: oldValues,
      newValues: newValues,
      changeType: changeType,
      customDescription: customDescription,
      metadata: metadata,
    );
  }

  /// Zapisuje historię zmian dla wielu inwestycji (bulk update)
  Future<void> recordBulkChanges({
    required List<Investment> oldInvestments,
    required List<Investment> newInvestments,
    String? customDescription,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final batch = _firestore.batch();
      final user = _auth.currentUser;

      if (user == null) {
        logError(
          'recordBulkChanges',
          'Brak zalogowanego użytkownika - nie można zapisać historii zmian',
        );
        return;
      }

      int changesCount = 0;

      for (
        int i = 0;
        i < oldInvestments.length && i < newInvestments.length;
        i++
      ) {
        final oldInvestment = oldInvestments[i];
        final newInvestment = newInvestments[i];

        final oldValues = _investmentToComparableMap(oldInvestment);
        final newValues = _investmentToComparableMap(newInvestment);

        if (_hasAnyChanges(oldValues, newValues)) {
          final changeHistory = InvestmentChangeHistory.fromChanges(
            investmentId: newInvestment.id,
            userId: user.uid,
            userEmail: user.email ?? 'Nieznany email',
            userName: user.displayName ?? user.email ?? 'Nieznany użytkownik',
            oldValues: oldValues,
            newValues: newValues,
            changeType: InvestmentChangeType.bulkUpdate.value,
            customDescription: customDescription,
            metadata: metadata ?? {},
          );

          final docRef = _firestore.collection(_collectionName).doc();
          batch.set(docRef, changeHistory.toFirestore());
          changesCount++;
        }
      }

      if (changesCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      logError(
        'recordBulkChanges',
        'Błąd podczas zapisywania historii zmian masowych: $e',
      );
    }
  }

  /// Sprawdza czy między dwoma mapami są jakieś różnice
  bool _hasAnyChanges(
    Map<String, dynamic> oldValues,
    Map<String, dynamic> newValues,
  ) {
    for (final key in newValues.keys) {
      if (oldValues[key] != newValues[key]) {
        return true;
      }
    }
    return false;
  }

  /// Konwertuje Investment na mapę dla porównywania
  Map<String, dynamic> _investmentToComparableMap(Investment investment) {
    return {
      'investmentAmount': investment.investmentAmount,
      'paidAmount': investment.paidAmount,
      'remainingCapital': investment.remainingCapital,
      'realizedCapital': investment.realizedCapital,
      'realizedInterest': investment.realizedInterest,
      'remainingInterest': investment.remainingInterest,
      'transferToOtherProduct': investment.transferToOtherProduct,
      'capitalForRestructuring': investment.capitalForRestructuring,
      'capitalSecuredByRealEstate': investment.capitalSecuredByRealEstate,
      'plannedTax': investment.plannedTax,
      'realizedTax': investment.realizedTax,
      'status': investment.status.displayName,
      'marketType': investment.marketType.displayName,
      'productName': investment.productName,
      'clientName': investment.clientName,
      'branchCode': investment.branchCode,
    };
  }

  /// Usuwa starą historię (dla optymalizacji bazy danych)
  Future<void> cleanupOldHistory({int keepDays = 365}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('changedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      logError(
        'cleanupOldHistory',
        'Błąd podczas czyszczenia starej historii: $e',
      );
    }
  }
}
