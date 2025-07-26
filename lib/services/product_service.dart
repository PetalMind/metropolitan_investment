import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import 'base_service.dart';

class ProductService extends BaseService {
  final String _collection = 'products';

  // Create
  Future<String> createProduct(Product product) async {
    try {
      final docRef = await firestore
          .collection(_collection)
          .add(product.toFirestore());
      return docRef.id;
    } catch (e) {
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
      throw Exception('Failed to get product: $e');
    }
  }

  // Read all
  Stream<List<Product>> getProducts() {
    return firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
        );
  }

  // Get products by type
  Stream<List<Product>> getProductsByType(ProductType type) {
    return firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .where('type', isEqualTo: type.name)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
        );
  }

  // Get products by company
  Stream<List<Product>> getProductsByCompany(String companyId) {
    return firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .where('companyId', isEqualTo: companyId)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
        );
  }

  // Search products
  Stream<List<Product>> searchProducts(String query) {
    if (query.isEmpty) return getProducts();

    return firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .startAt([query])
        .endAt([query + '\uf8ff'])
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
    } catch (e) {
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
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Hard delete
  Future<void> hardDeleteProduct(String id) async {
    try {
      await firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to hard delete product: $e');
    }
  }

  // Get products count by type
  Future<Map<ProductType, int>> getProductsCountByType() async {
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
      throw Exception('Failed to get products count by type: $e');
    }
  }

  // Get products with pagination
  Future<List<Product>> getProductsPaginated({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    ProductType? type,
  }) async {
    try {
      Query query = firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      query = query.orderBy('name').limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get products with pagination: $e');
    }
  }

  // Get active bonds near maturity
  Future<List<Product>> getBondsNearMaturity(int daysThreshold) async {
    try {
      final threshold = DateTime.now().add(Duration(days: daysThreshold));

      final snapshot = await firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('type', isEqualTo: ProductType.bonds.name)
          .where(
            'maturityDate',
            isLessThanOrEqualTo: Timestamp.fromDate(threshold),
          )
          .where('maturityDate', isGreaterThan: Timestamp.now())
          .orderBy('maturityDate')
          .get();

      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get bonds near maturity: $e');
    }
  }
}
