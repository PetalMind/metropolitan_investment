import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/unified_product.dart';
import '../models/bond.dart';
import '../models/share.dart';
import '../models/loan.dart';
import '../models/product.dart';
import '../models/investment.dart';
import 'base_service.dart';

/// Enhanced serwis do zarządzania zunifikowanymi produktami
/// Obsługuje apartamenty zarówno z kolekcji products jak i investments
class EnhancedUnifiedProductService extends BaseService {
  static const String _cacheKeyPrefix = 'enhanced_products_';
  static const String _cacheKeyAll = 'enhanced_products_all';
  static const String _cacheKeyStats = 'enhanced_products_stats';

  /// Pobiera wszystkie produkty ze wszystkich źródeł
  Future<List<UnifiedProduct>> getAllProducts() async {
    return getCachedData(
      _cacheKeyAll,
      () => _fetchAllProductsEnhanced(),
    );
  }

  /// Enhanced wersja która obsługuje apartamenty z różnych źródeł
  Future<List<UnifiedProduct>> _fetchAllProductsEnhanced() async {
    try {
      final results = await Future.wait([
        _getBonds(),
        _getShares(),
        _getLoans(),
        _getApartmentsFromProducts(), // Z kolekcji products
        _getApartmentsFromInvestments(), // Z kolekcji investments jako fallback
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

  /// Pobiera apartamenty z kolekcji products (właściwe źródło)
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
        print('[EnhancedUnifiedProductService] Znaleziono ${apartments.length} apartamentów z kolekcji products');
      }
      
      return apartments;
    } catch (e) {
      logError('_getApartmentsFromProducts', e);
      return [];
    }
  }

  /// Pobiera apartamenty z kolekcji investments jako fallback
  /// Używane gdy apartamenty nie zostały jeszcze przeniesione do kolekcji products
  Future<List<UnifiedProduct>> _getApartmentsFromInvestments() async {
    try {
      final snapshot = await firestore
          .collection('investments')
          .where('typ_produktu', isEqualTo: 'Apartamenty')
          .get();

      if (snapshot.docs.isEmpty) {
        if (kDebugMode) {
          print('[EnhancedUnifiedProductService] Brak apartamentów w kolekcji investments');
        }
        return [];
      }

      // Grupuj po nazwie produktu i spółce aby stworzyć unikalne produkty
      final Map<String, List<QueryDocumentSnapshot>> groupedInvestments = {};
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final productName = data['produkt_nazwa']?.toString() ?? 'Nieznany Apartament';
        final companyName = data['id_spolka']?.toString() ?? 'Nieznana Spółka';
        final key = '${productName}_${companyName}';
        
        if (!groupedInvestments.containsKey(key)) {
          groupedInvestments[key] = [];
        }
        groupedInvestments[key]!.add(doc);
      }

      final apartments = <UnifiedProduct>[];
      
      for (final entry in groupedInvestments.entries) {
        final investments = entry.value;
        final firstInvestment = investments.first.data() as Map<String, dynamic>;
        
        // Oblicz agregowane wartości
        final totalAmount = investments.fold<double>(0.0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          return sum + (data['kwota_inwestycji']?.toDouble() ?? 0.0);
        });
        
        final totalRealized = investments.fold<double>(0.0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          return sum + (data['kapital_zrealizowany']?.toDouble() ?? 0.0);
        });

        // Znajdź najwcześniejszą datę
        DateTime? earliestDate;
        for (final doc in investments) {
          final data = doc.data() as Map<String, dynamic>;
          final dateStr = data['data_podpisania']?.toString();
          if (dateStr != null && dateStr.isNotEmpty) {
            try {
              final date = DateTime.parse(dateStr);
              if (earliestDate == null || date.isBefore(earliestDate)) {
                earliestDate = date;
              }
            } catch (e) {
              // Ignoruj nieprawidłowe daty
            }
          }
        }

        // Stwórz UnifiedProduct z danych inwestycji
        final apartment = UnifiedProduct(
          id: 'apartment_investment_${investments.first.id}',
          name: firstInvestment['produkt_nazwa']?.toString() ?? 'Nieznany Apartament',
          productType: UnifiedProductType.apartments,
          investmentAmount: totalAmount,
          createdAt: earliestDate ?? DateTime.now(),
          uploadedAt: DateTime.now(),
          sourceFile: 'investments_collection_fallback',
          status: ProductStatus.active,
          companyName: firstInvestment['id_spolka']?.toString(),
          additionalInfo: {
            'total_investments': investments.length,
            'total_realized': totalRealized,
            'average_investment': totalAmount / investments.length,
            'migration_source': 'investments_fallback',
            'sample_investment_ids': investments.take(3).map((doc) => doc.id).toList(),
          },
        );

        apartments.add(apartment);
      }

      if (kDebugMode) {
        print('[EnhancedUnifiedProductService] Utworzono ${apartments.length} apartamentów z ${snapshot.docs.length} inwestycji');
      }

      return apartments;
    } catch (e) {
      logError('_getApartmentsFromInvestments', e);
      return [];
    }
  }

  /// Pobiera pozostałe metody z base service
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

  /// Sprawdza czy apartamenty są dostępne w kolekcji investments
  Future<bool> hasApartmentsInInvestments() async {
    try {
      final snapshot = await firestore
          .collection('investments')
          .where('typ_produktu', isEqualTo: 'Apartamenty')
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      logError('hasApartmentsInInvestments', e);
      return false;
    }
  }

  /// Pobiera informacje diagnostyczne o źródłach apartamentów
  Future<Map<String, dynamic>> getApartmentsDiagnostics() async {
    return getCachedData('apartments_diagnostics', () async {
      final productsCount = await firestore
          .collection('products')
          .where('type', isEqualTo: 'apartments')
          .get()
          .then((snapshot) => snapshot.docs.length);

      final investmentsCount = await firestore
          .collection('investments')
          .where('typ_produktu', isEqualTo: 'Apartamenty')
          .get()
          .then((snapshot) => snapshot.docs.length);

      return {
        'apartments_in_products': productsCount,
        'apartments_in_investments': investmentsCount,
        'has_products_source': productsCount > 0,
        'has_investments_source': investmentsCount > 0,
        'recommended_action': productsCount == 0 && investmentsCount > 0
            ? 'Uruchom migrację apartamentów z kolekcji investments do products'
            : productsCount > 0
                ? 'Apartamenty są poprawnie skonfigurowane w kolekcji products'
                : 'Brak apartamentów w systemie',
        'timestamp': DateTime.now().toIso8601String(),
      };
    });
  }

  /// Czyści cache
  void clearCache() {
    clearAllCache();
  }

  /// Debug - loguje informacje o źródłach danych
  Future<void> debugLogSources() async {
    if (!kDebugMode) return;
    
    final diagnostics = await getApartmentsDiagnostics();
    print('=== ENHANCED UNIFIED PRODUCT SERVICE DEBUG ===');
    print('Apartamenty w products: ${diagnostics['apartments_in_products']}');
    print('Apartamenty w investments: ${diagnostics['apartments_in_investments']}');
    print('Rekomendacja: ${diagnostics['recommended_action']}');
    print('===============================================');
  }
}