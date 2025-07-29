import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/loan.dart';
import 'base_service.dart';

class LoanService extends BaseService {
  final String _collection = 'loans';

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
    } catch (e) {
      logError('deleteLoan', e);
      throw Exception('Failed to delete loan: $e');
    }
  }

  // Get loans statistics
  Future<Map<String, dynamic>> getLoansStatistics() async {
    return getCachedData('loans_stats', () async {
      try {
        final snapshot = await firestore.collection(_collection).get();

        double totalInvestmentAmount = 0;
        Map<String, int> productTypeCounts = {};
        Map<String, double> productTypeValues = {};

        for (var doc in snapshot.docs) {
          final loan = Loan.fromFirestore(doc);

          totalInvestmentAmount += loan.investmentAmount;

          // Count by product type
          productTypeCounts[loan.productType] =
              (productTypeCounts[loan.productType] ?? 0) + 1;
          productTypeValues[loan.productType] =
              (productTypeValues[loan.productType] ?? 0) +
              loan.investmentAmount;
        }

        return {
          'total_count': snapshot.docs.length,
          'total_investment_amount': totalInvestmentAmount,
          'product_type_counts': productTypeCounts,
          'product_type_values': productTypeValues,
          'average_loan_amount': snapshot.docs.isNotEmpty
              ? totalInvestmentAmount / snapshot.docs.length
              : 0.0,
        };
      } catch (e) {
        logError('getLoansStatistics', e);
        return {};
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

  // Get largest loans
  Future<List<Loan>> getLargestLoans({int limit = 10}) async {
    try {
      final snapshot = await firestore
          .collection(_collection)
          .limit(100) // Get more to sort properly
          .get();

      final loans = snapshot.docs
          .map((doc) => Loan.fromFirestore(doc))
          .toList();

      // Sort by investment amount
      loans.sort((a, b) => b.investmentAmount.compareTo(a.investmentAmount));

      return loans.take(limit).toList();
    } catch (e) {
      logError('getLargestLoans', e);
      throw Exception('Failed to get largest loans: $e');
    }
  }
}
