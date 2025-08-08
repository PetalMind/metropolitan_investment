import 'package:flutter/foundation.dart';
import '../models/unified_product.dart';
import '../models/bond.dart';
import '../models/share.dart';
import '../models/loan.dart';
import '../models/apartment.dart';
import '../models/product.dart';
import 'base_service.dart';

/// Enhanced serwis do zarządzania zunifikowanymi produktami
/// Obsługuje apartamenty z kolekcji apartments
class EnhancedUnifiedProductService extends BaseService {
  static const String _cacheKeyAll = 'enhanced_products_all';

  /// Pobiera wszystkie produkty ze wszystkich źródeł
  Future<List<UnifiedProduct>> getAllProducts() async {
    return getCachedData(_cacheKeyAll, () => _fetchAllProductsEnhanced());
  }

  /// Enhanced wersja która obsługuje apartamenty z kolekcji apartments
  Future<List<UnifiedProduct>> _fetchAllProductsEnhanced() async {
    try {
      final results = await Future.wait([
        _getBonds(),
        _getShares(),
        _getLoans(),
        _getApartmentsFromApartmentsCollection(),
        _getApartmentsFromProducts(),
        _getOtherProducts(),
      ]);

      final allProducts = <UnifiedProduct>[];
      for (final productList in results) {
        allProducts.addAll(productList);
      }

      // Usuń duplikaty na podstawie nazwy i spółki
      final uniqueProducts = <String, UnifiedProduct>{};
      for (final product in allProducts) {
        final key = '${product.name}_${product.companyName ?? 'unknown'}';
        if (!uniqueProducts.containsKey(key)) {
          uniqueProducts[key] = product;
        }
      }

      return uniqueProducts.values.toList();
    } catch (e) {
      logError('_fetchAllProductsEnhanced', e);
      return [];
    }
  }

  /// Pobiera apartamenty z kolekcji apartments (główne źródło)
  Future<List<UnifiedProduct>> _getApartmentsFromApartmentsCollection() async {
    try {
      final snapshot = await firestore.collection('apartments').get();

      final apartments = snapshot.docs
          .map(
            (doc) => UnifiedProduct.fromApartment(Apartment.fromFirestore(doc)),
          )
          .toList();

      if (kDebugMode && apartments.isNotEmpty) {
        print(
          '[EnhancedUnifiedProductService] Znaleziono ${apartments.length} apartamentów z kolekcji apartments',
        );
      }

      return apartments;
    } catch (e) {
      logError('_getApartmentsFromApartmentsCollection', e);
      return [];
    }
  }

  /// Pobiera apartamenty z kolekcji products (fallback)
  Future<List<UnifiedProduct>> _getApartmentsFromProducts() async {
    try {
      final snapshot = await firestore
          .collection('products')
          .where('type', isEqualTo: 'apartments')
          .get();

      final apartments = snapshot.docs
          .map((doc) => UnifiedProduct.fromProduct(Product.fromFirestore(doc)))
          .toList();

      if (kDebugMode && apartments.isNotEmpty) {
        print(
          '[EnhancedUnifiedProductService] Znaleziono ${apartments.length} apartamentów z kolekcji products',
        );
      }

      return apartments;
    } catch (e) {
      logError('_getApartmentsFromProducts', e);
      return [];
    }
  }

  /// Pobiera obligacje
  Future<List<UnifiedProduct>> _getBonds() async {
    try {
      final snapshot = await firestore.collection('bonds').get();
      return snapshot.docs
          .map((doc) => UnifiedProduct.fromBond(Bond.fromFirestore(doc)))
          .toList();
    } catch (e) {
      logError('_getBonds', e);
      return [];
    }
  }

  /// Pobiera udziały
  Future<List<UnifiedProduct>> _getShares() async {
    try {
      final snapshot = await firestore.collection('shares').get();
      return snapshot.docs
          .map((doc) => UnifiedProduct.fromShare(Share.fromFirestore(doc)))
          .toList();
    } catch (e) {
      logError('_getShares', e);
      return [];
    }
  }

  /// Pobiera pożyczki
  Future<List<UnifiedProduct>> _getLoans() async {
    try {
      final snapshot = await firestore.collection('loans').get();
      return snapshot.docs
          .map((doc) => UnifiedProduct.fromLoan(Loan.fromFirestore(doc)))
          .toList();
    } catch (e) {
      logError('_getLoans', e);
      return [];
    }
  }

  /// Pobiera pozostałe produkty
  Future<List<UnifiedProduct>> _getOtherProducts() async {
    try {
      final snapshot = await firestore
          .collection('products')
          .where('type', whereNotIn: ['apartments'])
          .get();
      return snapshot.docs
          .map((doc) => UnifiedProduct.fromProduct(Product.fromFirestore(doc)))
          .toList();
    } catch (e) {
      logError('_getOtherProducts', e);
      return [];
    }
  }

  /// Sprawdza czy apartamenty są dostępne w kolekcji apartments
  Future<bool> hasApartmentsInCollection() async {
    try {
      final snapshot = await firestore.collection('apartments').limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      logError('hasApartmentsInCollection', e);
      return false;
    }
  }

  /// Sprawdza czy apartamenty są dostępne w kolekcji products
  Future<bool> hasApartmentsInProducts() async {
    try {
      final snapshot = await firestore
          .collection('products')
          .where('type', isEqualTo: 'apartments')
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      logError('hasApartmentsInProducts', e);
      return false;
    }
  }

  /// Pobiera informacje diagnostyczne o źródłach apartamentów
  Future<Map<String, dynamic>> getApartmentsDiagnostics() async {
    return getCachedData('apartments_diagnostics', () async {
      final apartmentsCount = await firestore
          .collection('apartments')
          .get()
          .then((snapshot) => snapshot.docs.length);

      final productsCount = await firestore
          .collection('products')
          .where('type', isEqualTo: 'apartments')
          .get()
          .then((snapshot) => snapshot.docs.length);

      return {
        'apartments_in_apartments_collection': apartmentsCount,
        'apartments_in_products': productsCount,
        'has_apartments_collection': apartmentsCount > 0,
        'has_products_source': productsCount > 0,
        'recommended_action': apartmentsCount > 0
            ? 'Apartamenty są poprawnie skonfigurowane w kolekcji apartments'
            : productsCount > 0
            ? 'Apartamenty dostępne w kolekcji products'
            : 'Brak apartamentów w systemie',
        'timestamp': DateTime.now().toIso8601String(),
      };
    });
  }

  /// Czyści cache
  void clearProductsCache() {
    clearAllCache();
  }

  /// Debug - loguje informacje o źródłach danych
  Future<void> debugLogSources() async {
    if (!kDebugMode) return;

    final diagnostics = await getApartmentsDiagnostics();
    print('=== ENHANCED UNIFIED PRODUCT SERVICE DEBUG ===');
    print(
      'Apartamenty w kolekcji apartments: ${diagnostics['apartments_in_apartments_collection']}',
    );
    print('Apartamenty w products: ${diagnostics['apartments_in_products']}');
    print('Rekomendacja: ${diagnostics['recommended_action']}');
    print('===============================================');
  }
}
