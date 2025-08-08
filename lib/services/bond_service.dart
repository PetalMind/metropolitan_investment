import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bond.dart';
import 'base_service.dart';

class BondService extends BaseService {
  final String _collection = 'bonds';

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
    } catch (e) {
      logError('deleteBond', e);
      throw Exception('Failed to delete bond: $e');
    }
  }

  // Get bonds statistics
  Future<Map<String, dynamic>> getBondsStatistics() async {
    return getCachedData('bonds_stats', () async {
      try {
        final snapshot = await firestore.collection(_collection).get();

        double totalRealizedCapital = 0;
        double totalRemainingCapital = 0;
        double totalRealizedInterest = 0;
        double totalRemainingInterest = 0;
        double totalRealizedTax = 0;
        double totalRemainingTax = 0;
        double totalTransferToOtherProduct = 0;

        Map<String, int> productTypeCounts = {};
        Map<String, double> productTypeValues = {};

        for (var doc in snapshot.docs) {
          final bond = Bond.fromFirestore(doc);

          totalRealizedCapital += bond.realizedCapital;
          totalRemainingCapital += bond.remainingCapital;
          totalRealizedInterest += bond.realizedInterest;
          totalRemainingInterest += bond.remainingInterest;
          totalRealizedTax += bond.realizedTax;
          totalRemainingTax += bond.remainingTax;
          totalTransferToOtherProduct += bond.transferToOtherProduct;

          // Count by product type
          productTypeCounts[bond.productType] =
              (productTypeCounts[bond.productType] ?? 0) + 1;
          productTypeValues[bond.productType] =
              (productTypeValues[bond.productType] ?? 0) +
              bond.remainingCapital; // zmienione na kapital_pozostaly
        }

        return {
          'total_count': snapshot.docs.length,
          'total_investment_amount':
              totalRemainingCapital, // zmienione na kapital_pozostaly
          'total_realized_capital': totalRealizedCapital,
          'total_remaining_capital': totalRemainingCapital,
          'total_realized_interest': totalRealizedInterest,
          'total_remaining_interest': totalRemainingInterest,
          'total_realized_tax': totalRealizedTax,
          'total_remaining_tax': totalRemainingTax,
          'total_transfer_to_other_product': totalTransferToOtherProduct,
          'product_type_counts': productTypeCounts,
          'product_type_values': productTypeValues,
          'total_current_value':
              totalRemainingCapital, // tylko kapital_pozostaly
          'total_profit_loss': 0.0, // nie uwzględniamy profit/loss
        };
      } catch (e) {
        logError('getBondsStatistics', e);
        return {};
      }
    });
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

  // Get bonds with remaining capital
  Stream<List<Bond>> getBondsWithRemainingCapital() {
    return firestore
        .collection(_collection)
        .where('kapital_pozostaly', isGreaterThan: 0)
        .orderBy('kapital_pozostaly', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Bond.fromFirestore(doc)).toList(),
        );
  }

  // Get bonds with capital for restructuring
  Stream<List<Bond>> getBondsWithRestructuringCapital() {
    return firestore
        .collection(_collection)
        .where('kapital_do_restrukturyzacji', isGreaterThan: 0)
        .orderBy('kapital_do_restrukturyzacji', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Bond.fromFirestore(doc)).toList(),
        );
  }

  // Get bonds with capital secured by real estate
  Stream<List<Bond>> getBondsWithSecuredCapital() {
    return firestore
        .collection(_collection)
        .where('kapital_zabezpieczony_nieruchomoscia', isGreaterThan: 0)
        .orderBy('kapital_zabezpieczony_nieruchomoscia', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Bond.fromFirestore(doc)).toList(),
        );
  }

  // Batch create bonds for data import
  Future<void> createBondsBatch(List<Bond> bonds) async {
    try {
      final batch = firestore.batch();

      for (final bond in bonds) {
        final docRef = firestore.collection(_collection).doc();
        batch.set(docRef, bond.copyWith(id: docRef.id).toFirestore());
      }

      await batch.commit();
      clearCache('bonds_stats');
      print('✅ Successfully created ${bonds.length} bonds in batch');
    } catch (e) {
      logError('createBondsBatch', e);
      throw Exception('Failed to create bonds batch: $e');
    }
  }

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

  // Get top performing bonds
  Future<List<Bond>> getTopPerformingBonds({int limit = 10}) async {
    try {
      final snapshot = await firestore
          .collection(_collection)
          .limit(100) // Get more to calculate performance
          .get();

      final bonds = snapshot.docs
          .map((doc) => Bond.fromFirestore(doc))
          .toList();

      // Sort by remaining capital (highest first) - zmienione z profit/loss
      bonds.sort((a, b) => b.remainingCapital.compareTo(a.remainingCapital));

      return bonds.take(limit).toList();
    } catch (e) {
      logError('getTopPerformingBonds', e);
      throw Exception('Failed to get top performing bonds: $e');
    }
  }
}
