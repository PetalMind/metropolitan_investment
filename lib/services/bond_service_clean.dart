import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bond.dart';
import '../models/investment.dart';
import '../models/product.dart';
import 'base_service.dart';
import 'data_cache_service.dart';

class BondService extends BaseService {
  final String _collection = 'bonds';
  final DataCacheService _dataCacheService = DataCacheService();

  // Get all bonds
  Stream<List<Bond>> getAllBonds({int? limit}) {
    Query query = firestore
        .collection(_collection)
        .orderBy('created_at', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Bond.fromFirestore(doc)).toList(),
    );
  }

  // Get bond by ID
  Future<Bond?> getBond(String id) async {
    try {
      final doc = await firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Bond.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      logError('getBond', e);
      throw Exception('Failed to get bond: $e');
    }
  }

  // Create bond
  Future<String> createBond(Bond bond) async {
    try {
      final docRef = await firestore
          .collection(_collection)
          .add(bond.toFirestore());
      clearCache('bonds_stats');
      _dataCacheService.invalidateCollectionCache('bonds');
      return docRef.id;
    } catch (e) {
      logError('createBond', e);
      throw Exception('Failed to create bond: $e');
    }
  }

  // Update bond
  Future<void> updateBond(String id, Bond bond) async {
    try {
      await firestore
          .collection(_collection)
          .doc(id)
          .update(bond.toFirestore());
      clearCache('bonds_stats');
      _dataCacheService.invalidateCollectionCache('bonds');
    } catch (e) {
      logError('updateBond', e);
      throw Exception('Failed to update bond: $e');
    }
  }

  // Delete bond
  Future<void> deleteBond(String id) async {
    try {
      await firestore.collection(_collection).doc(id).delete();
      clearCache('bonds_stats');
      _dataCacheService.invalidateCollectionCache('bonds');
    } catch (e) {
      logError('deleteBond', e);
      throw Exception('Failed to delete bond: $e');
    }
  }

  // Get bonds statistics - ZOPTYMALIZOWANA WERSJA (używa cache)
  Future<Map<String, dynamic>> getBondsStatistics() async {
    return getCachedData('bonds_stats', () async {
      try {
        // Pobierz wszystkie inwestycje z cache'a i filtruj obligacje
        final allInvestments = await _dataCacheService.getAllInvestments();
        final bondInvestments = allInvestments
            .where((inv) => inv.productType == ProductType.bonds)
            .toList();

        if (bondInvestments.isEmpty) {
          return {
            'total_count': 0,
            'total_investment_amount': 0.0,
            'total_remaining_capital': 0.0,
            'total_remaining_interest': 0.0,
            'total_realized_capital': 0.0,
            'total_realized_interest': 0.0,
            'average_investment_amount': 0.0,
            'product_type_counts': <String, int>{},
            'monthly_stats': <String, Map<String, dynamic>>{},
          };
        }

        // Oblicz statystyki
        final totalCount = bondInvestments.length;
        final totalInvestmentAmount = bondInvestments.fold<double>(
          0.0,
          (sum, inv) => sum + inv.investmentAmount,
        );
        final totalRemainingCapital = bondInvestments.fold<double>(
          0.0,
          (sum, inv) => sum + inv.remainingCapital,
        );
        final totalRemainingInterest = bondInvestments.fold<double>(
          0.0,
          (sum, inv) => sum + inv.remainingInterest,
        );
        final totalRealizedCapital = bondInvestments.fold<double>(
          0.0,
          (sum, inv) => sum + inv.realizedCapital,
        );
        final totalRealizedInterest = bondInvestments.fold<double>(
          0.0,
          (sum, inv) => sum + inv.realizedInterest,
        );

        // Grupuj według nazwy produktu
        final productTypeCounts = <String, int>{};
        for (final investment in bondInvestments) {
          final productName = investment.productName.isNotEmpty
              ? investment.productName
              : 'Nieznany';
          productTypeCounts[productName] =
              (productTypeCounts[productName] ?? 0) + 1;
        }

        // Statystyki miesięczne
        final monthlyStats = <String, Map<String, dynamic>>{};
        final now = DateTime.now();

        for (int i = 0; i < 12; i++) {
          final month = DateTime(now.year, now.month - i, 1);
          final monthKey =
              '${month.year}-${month.month.toString().padLeft(2, '0')}';

          final monthBonds = bondInvestments.where((inv) {
            return inv.signedDate.year == month.year &&
                inv.signedDate.month == month.month;
          }).toList();

          monthlyStats[monthKey] = {
            'count': monthBonds.length,
            'total_amount': monthBonds.fold<double>(
              0.0,
              (sum, inv) => sum + inv.investmentAmount,
            ),
          };
        }

        print(
          '📊 [BondService] Statystyki obligacji: ${totalCount} pozycji, ${totalInvestmentAmount.toStringAsFixed(0)} PLN',
        );

        return {
          'total_count': totalCount,
          'total_investment_amount': totalInvestmentAmount,
          'total_remaining_capital': totalRemainingCapital,
          'total_remaining_interest': totalRemainingInterest,
          'total_realized_capital': totalRealizedCapital,
          'total_realized_interest': totalRealizedInterest,
          'average_investment_amount': totalCount > 0
              ? totalInvestmentAmount / totalCount
              : 0.0,
          'product_type_counts': productTypeCounts,
          'monthly_stats': monthlyStats,
        };
      } catch (e) {
        logError('getBondsStatistics', e);
        return {
          'total_count': 0,
          'total_investment_amount': 0.0,
          'total_remaining_capital': 0.0,
          'total_remaining_interest': 0.0,
          'total_realized_capital': 0.0,
          'total_realized_interest': 0.0,
          'average_investment_amount': 0.0,
          'product_type_counts': <String, int>{},
          'monthly_stats': <String, Map<String, dynamic>>{},
        };
      }
    });
  }

  // Get top performing bonds - ZOPTYMALIZOWANA WERSJA (używa cache)
  Future<List<Map<String, dynamic>>> getTopPerformingBonds({
    int limit = 10,
  }) async {
    try {
      final allInvestments = await _dataCacheService.getAllInvestments();
      final bondInvestments = allInvestments
          .where((inv) => inv.productType == ProductType.bonds)
          .toList();

      // Sortuj według pozostałego kapitału
      bondInvestments.sort(
        (a, b) => b.remainingCapital.compareTo(a.remainingCapital),
      );

      return bondInvestments
          .take(limit)
          .map(
            (investment) => {
              'id': investment.id,
              'client_name': investment.clientName,
              'product_name': investment.productName,
              'investment_amount': investment.investmentAmount,
              'remaining_capital': investment.remainingCapital,
              'realized_capital': investment.realizedCapital,
              'profit_rate': investment.investmentAmount > 0
                  ? ((investment.realizedCapital +
                                investment.remainingCapital -
                                investment.investmentAmount) /
                            investment.investmentAmount) *
                        100
                  : 0.0,
            },
          )
          .toList();
    } catch (e) {
      logError('getTopPerformingBonds', e);
      return [];
    }
  }

  // Get bonds by product type
  Stream<List<Bond>> getBondsByProductType(String productType) {
    return firestore
        .collection(_collection)
        .where('typ_produktu', isEqualTo: productType)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Bond.fromFirestore(doc)).toList(),
        );
  }

  // Search bonds
  Stream<List<Bond>> searchBonds(String query) {
    if (query.isEmpty) return getAllBonds();

    return firestore
        .collection(_collection)
        .where('typ_produktu', isGreaterThanOrEqualTo: query)
        .where('typ_produktu', isLessThan: query + '\uf8ff')
        .orderBy('typ_produktu')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Bond.fromFirestore(doc)).toList(),
        );
  }

  // Invalidate cache when data changes
  void invalidateCache() {
    clearCache('bonds_stats');
    _dataCacheService.invalidateCollectionCache('bonds');
  }
}
