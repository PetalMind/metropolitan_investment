import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/share.dart';
import '../models/product.dart';
import 'base_service.dart';
import 'data_cache_service.dart';

class ShareService extends BaseService {
  final String _collection = 'shares';
  final DataCacheService _dataCacheService = DataCacheService();

  // Get all shares
  Stream<List<Share>> getAllShares({int? limit}) {
    Query query = firestore
        .collection(_collection)
        .orderBy('created_at', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Share.fromFirestore(doc)).toList(),
    );
  }

  // Get share by ID
  Future<Share?> getShare(String id) async {
    try {
      final doc = await firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Share.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      logError('getShare', e);
      throw Exception('Failed to get share: $e');
    }
  }

  // Create share
  Future<String> createShare(Share share) async {
    try {
      final docRef = await firestore
          .collection(_collection)
          .add(share.toFirestore());
      clearCache('shares_stats');
      _dataCacheService.invalidateCollectionCache('shares');
      return docRef.id;
    } catch (e) {
      logError('createShare', e);
      throw Exception('Failed to create share: $e');
    }
  }

  // Update share
  Future<void> updateShare(String id, Share share) async {
    try {
      await firestore
          .collection(_collection)
          .doc(id)
          .update(share.toFirestore());
      clearCache('shares_stats');
      _dataCacheService.invalidateCollectionCache('shares');
    } catch (e) {
      logError('updateShare', e);
      throw Exception('Failed to update share: $e');
    }
  }

  // Delete share
  Future<void> deleteShare(String id) async {
    try {
      await firestore.collection(_collection).doc(id).delete();
      clearCache('shares_stats');
      _dataCacheService.invalidateCollectionCache('shares');
    } catch (e) {
      logError('deleteShare', e);
      throw Exception('Failed to delete share: $e');
    }
  }

  // Get shares statistics - ZOPTYMALIZOWANA WERSJA (używa cache)
  Future<Map<String, dynamic>> getSharesStatistics() async {
    return getCachedData('shares_stats', () async {
      try {
        // Pobierz wszystkie inwestycje z cache'a i filtruj akcje
        final allInvestments = await _dataCacheService.getAllInvestments();
        final shareInvestments = allInvestments
            .where((inv) => inv.productType == ProductType.shares)
            .toList();

        if (shareInvestments.isEmpty) {
          return {
            'total_count': 0,
            'total_investment_amount': 0.0,
            'total_shares_count': 0,
            'product_type_counts': <String, int>{},
            'product_type_values': <String, double>{},
            'average_investment_amount': 0.0,
            'monthly_stats': <String, Map<String, dynamic>>{},
          };
        }

        // Oblicz statystyki
        final totalCount = shareInvestments.length;
        final totalInvestmentAmount = shareInvestments.fold<double>(
          0.0,
          (sum, inv) => sum + inv.investmentAmount,
        );

        // Grupuj według nazwy produktu
        final productTypeCounts = <String, int>{};
        final productTypeValues = <String, double>{};
        for (final investment in shareInvestments) {
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

          final monthShares = shareInvestments.where((inv) {
            return inv.signedDate.year == month.year &&
                inv.signedDate.month == month.month;
          }).toList();

          monthlyStats[monthKey] = {
            'count': monthShares.length,
            'total_amount': monthShares.fold<double>(
              0.0,
              (sum, inv) => sum + inv.investmentAmount,
            ),
          };
        }

        print(
          '📊 [ShareService] Statystyki akcji: ${totalCount} pozycji, ${totalInvestmentAmount.toStringAsFixed(0)} PLN',
        );

        return {
          'total_count': totalCount,
          'total_investment_amount': totalInvestmentAmount,
          'product_type_counts': productTypeCounts,
          'product_type_values': productTypeValues,
          'average_investment_amount': totalCount > 0
              ? totalInvestmentAmount / totalCount
              : 0.0,
          'monthly_stats': monthlyStats,
        };
      } catch (e) {
        logError('getSharesStatistics', e);
        return {
          'total_count': 0,
          'total_investment_amount': 0.0,
          'product_type_counts': <String, int>{},
          'product_type_values': <String, double>{},
          'average_investment_amount': 0.0,
          'monthly_stats': <String, Map<String, dynamic>>{},
        };
      }
    });
  }

  // Get shares by product type
  Stream<List<Share>> getSharesByProductType(String productType) {
    return firestore
        .collection(_collection)
        .where('typ_produktu', isEqualTo: productType)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Share.fromFirestore(doc)).toList(),
        );
  }

  // Search shares
  Stream<List<Share>> searchShares(String query) {
    if (query.isEmpty) return getAllShares();

    return firestore
        .collection(_collection)
        .where('typ_produktu', isGreaterThanOrEqualTo: query)
        .where('typ_produktu', isLessThan: query + '\uf8ff')
        .orderBy('typ_produktu')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Share.fromFirestore(doc)).toList(),
        );
  }

  // Get shares with highest value - ZOPTYMALIZOWANA WERSJA (używa cache)
  Future<List<Map<String, dynamic>>> getSharesWithHighestValue({
    int limit = 10,
  }) async {
    try {
      final allInvestments = await _dataCacheService.getAllInvestments();
      final shareInvestments = allInvestments
          .where((inv) => inv.productType == ProductType.shares)
          .toList();

      // Sortuj według kwoty inwestycji
      shareInvestments.sort(
        (a, b) => b.investmentAmount.compareTo(a.investmentAmount),
      );

      return shareInvestments
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
      logError('getSharesWithHighestValue', e);
      return [];
    }
  }

  // Invalidate cache when data changes
  void invalidateCache() {
    clearCache('shares_stats');
    _dataCacheService.invalidateCollectionCache('shares');
  }
}
