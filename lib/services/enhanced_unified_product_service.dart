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

  /// Aktualizuje produkt w odpowiedniej kolekcji na podstawie typu
  Future<void> updateUnifiedProduct(UnifiedProduct product) async {
    try {
      print(
        '🔧 [EnhancedUnifiedProductService] Aktualizacja produktu: ${product.name}',
      );
      print('  - ID: ${product.id}');
      print('  - Typ: ${product.productType.displayName}');

      if (product.id.isEmpty) {
        throw Exception('ID produktu nie może być puste');
      }

      // Wybierz odpowiednią kolekcję na podstawie typu produktu
      String collection;
      Map<String, dynamic> data;

      switch (product.productType) {
        case UnifiedProductType.bonds:
          collection = 'bonds';
          // Konwertuj UnifiedProduct z powrotem do Bond
          data = _convertUnifiedProductToBondData(product);
          break;
        case UnifiedProductType.shares:
          collection = 'shares';
          // Konwertuj UnifiedProduct z powrotem do Share
          data = _convertUnifiedProductToShareData(product);
          break;
        case UnifiedProductType.loans:
          collection = 'loans';
          // Konwertuj UnifiedProduct z powrotem do Loan
          data = _convertUnifiedProductToLoanData(product);
          break;
        case UnifiedProductType.apartments:
          // Sprawdź czy apartament istnieje w kolekcji apartments czy products
          final existsInApartments = await firestore
              .collection('apartments')
              .doc(product.id)
              .get()
              .then((doc) => doc.exists);

          if (existsInApartments) {
            collection = 'apartments';
            data = _convertUnifiedProductToApartmentData(product);
          } else {
            collection = 'products';
            data = _convertUnifiedProductToProductData(product);
          }
          break;
        case UnifiedProductType.other:
          collection = 'products';
          data = _convertUnifiedProductToProductData(product);
          break;
      }

      // Dodaj timestamp aktualizacji
      data['updatedAt'] = DateTime.now();

      // Wykonaj aktualizację
      await firestore.collection(collection).doc(product.id).update(data);

      print(
        '✅ [EnhancedUnifiedProductService] Produkt zaktualizowany w kolekcji: $collection',
      );

      // Wyczyść cache aby wymusić odświeżenie danych
      clearProductsCache();
    } catch (e) {
      print(
        '❌ [EnhancedUnifiedProductService] Błąd podczas aktualizacji produktu: $e',
      );
      logError('updateUnifiedProduct', e);
      rethrow;
    }
  }

  /// Konwertuje UnifiedProduct do danych Bond
  Map<String, dynamic> _convertUnifiedProductToBondData(
    UnifiedProduct product,
  ) {
    return {
      'name': product.name,
      'companyName': product.companyName,
      'interestRate': product.interestRate,
      'maturityDate': product.maturityDate,
      'investmentAmount': product.investmentAmount,
      'currentValue': product.totalValue,
      'currency': product.currency,
      'status': product.status.name,
    };
  }

  /// Konwertuje UnifiedProduct do danych Share
  Map<String, dynamic> _convertUnifiedProductToShareData(
    UnifiedProduct product,
  ) {
    return {
      'name': product.name,
      'companyName': product.companyName,
      'sharesCount': product.sharesCount,
      'sharePrice':
          product.pricePerShare, // Używamy pricePerShare zamiast sharePrice
      'investmentAmount': product.investmentAmount,
      'currentValue': product.totalValue,
      'currency': product.currency,
      'status': product.status.name,
      // Dodatkowe pola z originalProduct jeśli dostępne
      ...?_extractAdditionalFields(product.originalProduct),
    };
  }

  /// Konwertuje UnifiedProduct do danych Loan
  Map<String, dynamic> _convertUnifiedProductToLoanData(
    UnifiedProduct product,
  ) {
    return {
      'name': product.name,
      'borrower': product.additionalInfo['borrower'] ?? '',
      'creditorCompany':
          product.companyName ??
          product.additionalInfo['creditorCompany'] ??
          '',
      'investmentAmount': product.investmentAmount,
      'currentValue': product.totalValue,
      'interestRate': product.interestRate,
      'maturityDate': product.maturityDate,
      'collateral': product.additionalInfo['collateral'] ?? '',
      'status': product.status.name,
      // Dodatkowe pola z originalProduct jeśli dostępne
      ...?_extractAdditionalFields(product.originalProduct),
    };
  }

  /// Konwertuje UnifiedProduct do danych Apartment
  Map<String, dynamic> _convertUnifiedProductToApartmentData(
    UnifiedProduct product,
  ) {
    return {
      'projectName': product.name,
      'apartmentNumber': product.additionalInfo['apartmentNumber'] ?? '',
      'building': product.additionalInfo['building'] ?? '',
      'area': product.additionalInfo['area'] ?? 0.0,
      'roomCount': product.additionalInfo['roomCount'] ?? 0,
      'floor': product.additionalInfo['floor'] ?? 0,
      'apartmentType': product.additionalInfo['apartmentType'] ?? '',
      'pricePerSquareMeter':
          product.additionalInfo['pricePerSquareMeter'] ?? 0.0,
      'investmentAmount': product.investmentAmount,
      'currentValue': product.totalValue,
      'address': product.additionalInfo['address'] ?? '',
      'hasBalcony': product.additionalInfo['hasBalcony'] ?? false,
      'hasParkingSpace': product.additionalInfo['hasParkingSpace'] ?? false,
      'hasStorage': product.additionalInfo['hasStorage'] ?? false,
      'status': product.status.name,
      // Dodatkowe pola z originalProduct jeśli dostępne
      ...?_extractAdditionalFields(product.originalProduct),
    };
  }

  /// Konwertuje UnifiedProduct do danych Product
  Map<String, dynamic> _convertUnifiedProductToProductData(
    UnifiedProduct product,
  ) {
    return {
      'name': product.name,
      'type': product.productType.name,
      'companyName': product.companyName,
      'investmentAmount': product.investmentAmount,
      'currentValue': product.totalValue,
      'currency': product.currency,
      'interestRate': product.interestRate,
      'maturityDate': product.maturityDate,
      'sharesCount': product.sharesCount,
      'sharePrice': product.pricePerShare, // Używamy pricePerShare
      'status': product.status.name,
      // Dodatkowe pola z originalProduct jeśli dostępne
      ...?_extractAdditionalFields(product.originalProduct),
    };
  }

  /// Ekstraktuje dodatkowe pola z originalProduct
  Map<String, dynamic>? _extractAdditionalFields(dynamic originalProduct) {
    if (originalProduct == null) return null;

    try {
      if (originalProduct is Bond) {
        return {
          'realizedCapital': originalProduct.realizedCapital,
          'remainingCapital': originalProduct.remainingCapital,
          'realizedInterest': originalProduct.realizedInterest,
          'remainingInterest': originalProduct.remainingInterest,
        };
      } else if (originalProduct is Share) {
        return {
          'sharesCount': originalProduct.sharesCount,
          'pricePerShare': originalProduct.pricePerShare,
        };
      } else if (originalProduct is Loan) {
        return {
          'borrower': originalProduct.borrower,
          'creditorCompany': originalProduct.creditorCompany,
          'collateral': originalProduct.collateral,
        };
      } else if (originalProduct is Apartment) {
        return {
          'apartmentNumber': originalProduct.apartmentNumber,
          'building': originalProduct.building,
          'area': originalProduct.area,
          'roomCount': originalProduct.roomCount,
          'floor': originalProduct.floor,
        };
      }
    } catch (e) {
      logError('_extractAdditionalFields', e);
    }

    return null;
  }
}
