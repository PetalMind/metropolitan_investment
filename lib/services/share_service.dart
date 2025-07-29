import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/share.dart';
import 'base_service.dart';

class ShareService extends BaseService {
  final String _collection = 'shares';

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
    } catch (e) {
      logError('deleteShare', e);
      throw Exception('Failed to delete share: $e');
    }
  }

  // Get shares statistics
  Future<Map<String, dynamic>> getSharesStatistics() async {
    return getCachedData('shares_stats', () async {
      try {
        final snapshot = await firestore.collection(_collection).get();

        double totalInvestmentAmount = 0;
        int totalSharesCount = 0;
        Map<String, int> productTypeCounts = {};
        Map<String, double> productTypeValues = {};
        Map<String, int> productTypeShares = {};

        for (var doc in snapshot.docs) {
          final share = Share.fromFirestore(doc);

          totalInvestmentAmount += share.investmentAmount;
          totalSharesCount += share.sharesCount;

          // Count by product type
          productTypeCounts[share.productType] =
              (productTypeCounts[share.productType] ?? 0) + 1;
          productTypeValues[share.productType] =
              (productTypeValues[share.productType] ?? 0) +
              share.investmentAmount;
          productTypeShares[share.productType] =
              (productTypeShares[share.productType] ?? 0) + share.sharesCount;
        }

        return {
          'total_count': snapshot.docs.length,
          'total_investment_amount': totalInvestmentAmount,
          'total_shares_count': totalSharesCount,
          'product_type_counts': productTypeCounts,
          'product_type_values': productTypeValues,
          'product_type_shares': productTypeShares,
          'average_investment_amount': snapshot.docs.isNotEmpty
              ? totalInvestmentAmount / snapshot.docs.length
              : 0.0,
          'average_shares_count': snapshot.docs.isNotEmpty
              ? totalSharesCount / snapshot.docs.length
              : 0.0,
          'average_price_per_share': totalSharesCount > 0
              ? totalInvestmentAmount / totalSharesCount
              : 0.0,
        };
      } catch (e) {
        logError('getSharesStatistics', e);
        return {};
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

  // Get shares with highest count
  Future<List<Share>> getSharesWithHighestCount({int limit = 10}) async {
    try {
      final snapshot = await firestore
          .collection(_collection)
          .limit(100) // Get more to sort properly
          .get();

      final shares = snapshot.docs
          .map((doc) => Share.fromFirestore(doc))
          .toList();

      // Sort by shares count
      shares.sort((a, b) => b.sharesCount.compareTo(a.sharesCount));

      return shares.take(limit).toList();
    } catch (e) {
      logError('getSharesWithHighestCount', e);
      throw Exception('Failed to get shares with highest count: $e');
    }
  }

  // Get shares with highest value
  Future<List<Share>> getSharesWithHighestValue({int limit = 10}) async {
    try {
      final snapshot = await firestore
          .collection(_collection)
          .limit(100) // Get more to sort properly
          .get();

      final shares = snapshot.docs
          .map((doc) => Share.fromFirestore(doc))
          .toList();

      // Sort by investment amount
      shares.sort((a, b) => b.investmentAmount.compareTo(a.investmentAmount));

      return shares.take(limit).toList();
    } catch (e) {
      logError('getSharesWithHighestValue', e);
      throw Exception('Failed to get shares with highest value: $e');
    }
  }
}
