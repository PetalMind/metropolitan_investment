import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import 'base_service.dart';

class OptimizedProductService extends BaseService {
  final String _collection = 'products';

  // Create
  Future<String> createProduct(Product product) async {
    try {
      final docRef = await firestore
          .collection(_collection)
          .add(product.toFirestore());
      clearCache('products_list');
      clearCache('products_count_by_type');
      return docRef.id;
    } catch (e) {
      logError('createProduct', e);
      throw Exception('Failed to create product: $e');
    }
  }

  // Read
  Future<Product?> getProduct(String id) async {
    try {
      final doc = await firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Product.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      logError('getProduct', e);
      throw Exception('Failed to get product: $e');
    }
  }

  // Read all z limitami
  Stream<List<Product>> getProducts({int? limit}) {
    Query query = firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name');

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
    );
  }

  // Paginacja produktów
  Future<PaginationResult<Product>> getProductsPaginated({
    PaginationParams params = const PaginationParams(),
    ProductType? type,
  }) async {
    try {
      Query query = firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      query = query
          .orderBy(params.orderBy ?? 'name', descending: params.descending)
          .limit(params.limit);

      if (params.startAfter != null) {
        query = query.startAfterDocument(params.startAfter!);
      }

      final snapshot = await query.get();
      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();

      return PaginationResult<Product>(
        items: products,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == params.limit,
      );
    } catch (e) {
      logError('getProductsPaginated', e);
      throw Exception('Failed to get products with pagination: $e');
    }
  }

  // Get products by type z limitami - WYKORZYSTUJE indeks isActive + type + name
  Stream<List<Product>> getProductsByType(ProductType type, {int? limit}) {
    Query query = firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .where('type', isEqualTo: type.name)
        .orderBy('name');

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
    );
  }

  // Get products by company z limitami - WYKORZYSTUJE indeks isActive + companyId + name
  Stream<List<Product>> getProductsByCompany(String companyId, {int? limit}) {
    Query query = firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .where('companyId', isEqualTo: companyId)
        .orderBy('name');

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
    );
  }

  // Search products z optimalizacją
  Stream<List<Product>> searchProducts(String query, {int limit = 30}) {
    if (query.isEmpty) return getProducts(limit: limit);

    return firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
        );
  }

  // Update
  Future<void> updateProduct(String id, Product product) async {
    try {
      await firestore
          .collection(_collection)
          .doc(id)
          .update(product.toFirestore());
      clearCache('products_list');
      clearCache('products_count_by_type');
    } catch (e) {
      logError('updateProduct', e);
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete (soft delete)
  Future<void> deleteProduct(String id) async {
    try {
      await firestore.collection(_collection).doc(id).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
      clearCache('products_list');
      clearCache('products_count_by_type');
    } catch (e) {
      logError('deleteProduct', e);
      throw Exception('Failed to delete product: $e');
    }
  }

  // Hard delete
  Future<void> hardDeleteProduct(String id) async {
    try {
      await firestore.collection(_collection).doc(id).delete();
      clearCache('products_list');
      clearCache('products_count_by_type');
    } catch (e) {
      logError('hardDeleteProduct', e);
      throw Exception('Failed to hard delete product: $e');
    }
  }

  // Get products count by type z cache
  Future<Map<ProductType, int>> getProductsCountByType() async {
    return getCachedData('products_count_by_type', () async {
      try {
        final Map<ProductType, int> counts = {};

        for (final type in ProductType.values) {
          final snapshot = await firestore
              .collection(_collection)
              .where('isActive', isEqualTo: true)
              .where('type', isEqualTo: type.name)
              .count()
              .get();
          counts[type] = snapshot.count ?? 0;
        }

        return counts;
      } catch (e) {
        logError('getProductsCountByType', e);
        throw Exception('Failed to get products count by type: $e');
      }
    });
  }

  // Obligacje bliskie wykupu z limitem - WYKORZYSTUJE indeks type + maturityDate + isActive
  Future<List<Product>> getBondsNearMaturity(
    int daysThreshold, {
    int limit = 50,
  }) async {
    try {
      final threshold = DateTime.now().add(Duration(days: daysThreshold));

      final snapshot = await firestore
          .collection(_collection)
          .where('type', isEqualTo: ProductType.bonds.name)
          .where(
            'maturityDate',
            isLessThanOrEqualTo: Timestamp.fromDate(threshold),
          )
          .where('isActive', isEqualTo: true)
          .orderBy('maturityDate')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    } catch (e) {
      logError('getBondsNearMaturity', e);
      throw Exception('Failed to get bonds near maturity: $e');
    }
  }

  // ===== NOWE METODY WYKORZYSTUJĄCE INDEKSY =====

  // Produkty według daty zapadalności - wykorzystuje indeks isActive + maturityDate
  Stream<List<Product>> getProductsByMaturityRange(
    DateTime startDate,
    DateTime endDate, {
    int limit = 50,
  }) {
    return firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .where(
          'maturityDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('maturityDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('maturityDate')
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
        );
  }

  // Produkty sortowane według daty zapadalności - wykorzystuje indeks isActive + maturityDate
  Stream<List<Product>> getProductsByMaturityDate({
    bool ascending = true,
    int limit = 100,
  }) {
    return firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('maturityDate', descending: !ascending)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
        );
  }
}
