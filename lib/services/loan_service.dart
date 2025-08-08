import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/loan.dart';
import '../models/product.dart';
import 'base_service.dart';
import 'data_cache_service.dart';

class LoanService extends BaseService {
  final String _collection = 'loans';
  final DataCacheService _dataCacheService = DataCacheService();

  // Get all loans
  Stream<List<Loan>> getAllLoans({int? limit}) {
    Query query = firestore
        .collection(_collection)
        .orderBy('created_at', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Loan.fromFirestore(doc)).toList(),
    );
  }

  // Get loan by ID
  Future<Loan?> getLoan(String id) async {
    try {
      final doc = await firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Loan.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      logError('getLoan', e);
      throw Exception('Failed to get loan: $e');
    }
  }

  // Create loan
  Future<String> createLoan(Loan loan) async {
    try {
      final docRef = await firestore
          .collection(_collection)
          .add(loan.toFirestore());
      clearCache('loans_stats');
      _dataCacheService.invalidateCollectionCache('loans');
      return docRef.id;
    } catch (e) {
      logError('createLoan', e);
      throw Exception('Failed to create loan: $e');
    }
  }

  // Update loan
  Future<void> updateLoan(String id, Loan loan) async {
    try {
      await firestore
          .collection(_collection)
          .doc(id)
          .update(loan.toFirestore());
      clearCache('loans_stats');
      _dataCacheService.invalidateCollectionCache('loans');
    } catch (e) {
      logError('updateLoan', e);
      throw Exception('Failed to update loan: $e');
    }
  }

  // Delete loan
  Future<void> deleteLoan(String id) async {
    try {
      await firestore.collection(_collection).doc(id).delete();
      clearCache('loans_stats');
      _dataCacheService.invalidateCollectionCache('loans');
    } catch (e) {
      logError('deleteLoan', e);
      throw Exception('Failed to delete loan: $e');
    }
  }

  // Get loans statistics - ZOPTYMALIZOWANA WERSJA (używa cache)
  Future<Map<String, dynamic>> getLoansStatistics() async {
    return getCachedData('loans_stats', () async {
      try {
        // Pobierz wszystkie inwestycje z cache'a i filtruj pożyczki
        final allInvestments = await _dataCacheService.getAllInvestments();
        final loanInvestments = allInvestments
            .where((inv) => inv.productType == ProductType.loans)
            .toList();

        if (loanInvestments.isEmpty) {
          return {
            'total_count': 0,
            'total_investment_amount': 0.0,
            'product_type_counts': <String, int>{},
            'product_type_values': <String, double>{},
            'average_loan_amount': 0.0,
            'monthly_stats': <String, Map<String, dynamic>>{},
          };
        }

        // Oblicz statystyki
        final totalCount = loanInvestments.length;
        final totalInvestmentAmount = loanInvestments.fold<double>(
          0.0,
          (sum, inv) => sum + inv.investmentAmount,
        );

        // Grupuj według nazwy produktu
        final productTypeCounts = <String, int>{};
        final productTypeValues = <String, double>{};
        for (final investment in loanInvestments) {
          final productName = investment.productName.isNotEmpty
              ? investment.productName
              : 'Nieznany';
          productTypeCounts[productName] =
              (productTypeCounts[productName] ?? 0) + 1;
          productTypeValues[productName] =
              (productTypeValues[productName] ?? 0.0) +
              investment.investmentAmount;
        }

        // Statystyki miesięczne
        final monthlyStats = <String, Map<String, dynamic>>{};
        final now = DateTime.now();

        for (int i = 0; i < 12; i++) {
          final month = DateTime(now.year, now.month - i, 1);
          final monthKey =
              '${month.year}-${month.month.toString().padLeft(2, '0')}';

          final monthLoans = loanInvestments.where((inv) {
            return inv.signedDate.year == month.year &&
                inv.signedDate.month == month.month;
          }).toList();

          monthlyStats[monthKey] = {
            'count': monthLoans.length,
            'total_amount': monthLoans.fold<double>(
              0.0,
              (sum, inv) => sum + inv.investmentAmount,
            ),
          };
        }

        print(
          '📊 [LoanService] Statystyki pożyczek: ${totalCount} pozycji, ${totalInvestmentAmount.toStringAsFixed(0)} PLN',
        );

        return {
          'total_count': totalCount,
          'total_investment_amount': totalInvestmentAmount,
          'product_type_counts': productTypeCounts,
          'product_type_values': productTypeValues,
          'average_loan_amount': totalCount > 0
              ? totalInvestmentAmount / totalCount
              : 0.0,
          'monthly_stats': monthlyStats,
        };
      } catch (e) {
        logError('getLoansStatistics', e);
        return {
          'total_count': 0,
          'total_investment_amount': 0.0,
          'product_type_counts': <String, int>{},
          'product_type_values': <String, double>{},
          'average_loan_amount': 0.0,
          'monthly_stats': <String, Map<String, dynamic>>{},
        };
      }
    });
  }

  // Get loans by product type
  Stream<List<Loan>> getLoansByProductType(String productType) {
    return firestore
        .collection(_collection)
        .where('typ_produktu', isEqualTo: productType)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Loan.fromFirestore(doc)).toList(),
        );
  }

  // Search loans
  Stream<List<Loan>> searchLoans(String query) {
    if (query.isEmpty) return getAllLoans();

    return firestore
        .collection(_collection)
        .where('typ_produktu', isGreaterThanOrEqualTo: query)
        .where('typ_produktu', isLessThan: query + '\uf8ff')
        .orderBy('typ_produktu')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Loan.fromFirestore(doc)).toList(),
        );
  }

  // Get largest loans - ZOPTYMALIZOWANA WERSJA (używa cache)
  Future<List<Map<String, dynamic>>> getLargestLoans({int limit = 10}) async {
    try {
      final allInvestments = await _dataCacheService.getAllInvestments();
      final loanInvestments = allInvestments
          .where((inv) => inv.productType == ProductType.loans)
          .toList();

      // Sortuj według kwoty inwestycji
      loanInvestments.sort(
        (a, b) => b.investmentAmount.compareTo(a.investmentAmount),
      );

      return loanInvestments
          .take(limit)
          .map(
            (investment) => {
              'id': investment.id,
              'client_name': investment.clientName,
              'product_name': investment.productName,
              'investment_amount': investment.investmentAmount,
              'remaining_capital': investment.remainingCapital,
              'realized_capital': investment.realizedCapital,
            },
          )
          .toList();
    } catch (e) {
      logError('getLargestLoans', e);
      return [];
    }
  }

  // Invalidate cache when data changes
  void invalidateCache() {
    clearCache('loans_stats');
    _dataCacheService.invalidateCollectionCache('loans');
  }

  // Get loans with remaining capital
  Stream<List<Loan>> getLoansWithRemainingCapital() {
    return firestore
        .collection(_collection)
        .where('kapital_pozostaly', isGreaterThan: 0)
        .orderBy('kapital_pozostaly', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Loan.fromFirestore(doc)).toList(),
        );
  }

  // Get loans by status
  Stream<List<Loan>> getLoansByStatus(String status) {
    return firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Loan.fromFirestore(doc)).toList(),
        );
  }

  // Get loans by borrower
  Stream<List<Loan>> getLoansByBorrower(String borrower) {
    return firestore
        .collection(_collection)
        .where('pozyczkobiorca', isEqualTo: borrower)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Loan.fromFirestore(doc)).toList(),
        );
  }

  // Get loans with capital for restructuring
  Stream<List<Loan>> getLoansWithRestructuringCapital() {
    return firestore
        .collection(_collection)
        .where('kapital_do_restrukturyzacji', isGreaterThan: 0)
        .orderBy('kapital_do_restrukturyzacji', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Loan.fromFirestore(doc)).toList(),
        );
  }

  // Get loans with capital secured by real estate
  Stream<List<Loan>> getLoansWithSecuredCapital() {
    return firestore
        .collection(_collection)
        .where('kapital_zabezpieczony_nieruchomoscia', isGreaterThan: 0)
        .orderBy('kapital_zabezpieczony_nieruchomoscia', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Loan.fromFirestore(doc)).toList(),
        );
  }

  // Batch create loans for data import
  Future<void> createLoansBatch(List<Loan> loans) async {
    try {
      final batch = firestore.batch();

      for (final loan in loans) {
        final docRef = firestore.collection(_collection).doc();
        batch.set(docRef, loan.copyWith(id: docRef.id).toFirestore());
      }

      await batch.commit();
      invalidateCache();
      print('✅ Successfully created ${loans.length} loans in batch');
    } catch (e) {
      logError('createLoansBatch', e);
      throw Exception('Failed to create loans batch: $e');
    }
  }
}
