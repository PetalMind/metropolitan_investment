import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/unified_product.dart';
import '../models/investment.dart';
import '../models/product.dart'; // Import dla ProductType
import '../services/unified_product_service.dart';
import '../models_and_services.dart'; // Import centralny z ultra-precyzyjnym serwisem
import 'base_service.dart';

/// Serwis deduplikacji produktów z kolekcji investments
///
/// Problem: W kolekcji 'investments' ten sam produkt może mieć wielu inwestorów,
/// co tworzy duplikaty. Ten serwis grupuje inwestycje według produktów i
/// zwraca unikalne produkty z agregowanymi statystykami.
class DeduplicatedProductService extends BaseService {
  static const String _cacheKeyPrefix =
      'deduped_products_v3_'; // ⭐ NOWA WERSJA: używa prawdziwych ID
  static const String _cacheKeyAll =
      'deduped_products_all_v3'; // ⭐ NOWA WERSJA: używa prawdziwych ID

  // ⭐ NOWE: Ultra-precyzyjny serwis do liczenia inwestorów
  final UltraPreciseProductInvestorsService _investorsService =
      UltraPreciseProductInvestorsService();

  /// Pobiera wszystkie unikalne produkty (deduplikowane)
  Future<List<DeduplicatedProduct>> getAllUniqueProducts() async {
    return getCachedData(_cacheKeyAll, () => _fetchUniqueProducts());
  }

  /// Pobiera unikalne produkty określonego typu
  Future<List<DeduplicatedProduct>> getUniqueProductsByType(
    UnifiedProductType type,
  ) async {
    final cacheKey = '${_cacheKeyPrefix}type_${type.name}';

    return getCachedData(cacheKey, () async {
      final allProducts = await getAllUniqueProducts();
      return allProducts
          .where((product) => product.productType == type)
          .toList();
    });
  }

  /// Wyszukuje unikalne produkty po nazwie
  Future<List<DeduplicatedProduct>> searchUniqueProducts(
    String searchQuery,
  ) async {
    if (searchQuery.trim().isEmpty) {
      return getAllUniqueProducts();
    }

    final cacheKey = '${_cacheKeyPrefix}search_${searchQuery.hashCode}';

    return getCachedData(cacheKey, () async {
      final allProducts = await getAllUniqueProducts();
      final searchLower = searchQuery.toLowerCase();

      return allProducts.where((product) {
        return product.name.toLowerCase().contains(searchLower) ||
            product.companyName.toLowerCase().contains(searchLower) ||
            product.productType.displayName.toLowerCase().contains(searchLower);
      }).toList();
    });
  }

  /// Pobiera szczegółowe informacje o produkcie wraz z listą inwestorów
  Future<ProductDetails?> getProductDetails(String productId) async {
    try {
      final allProducts = await getAllUniqueProducts();
      final product = allProducts.where((p) => p.id == productId).firstOrNull;

      if (product == null) return null;

      // Pobierz wszystkie inwestycje dla tego produktu
      final snapshot = await firestore
          .collection('investments')
          .where('productName', isEqualTo: product.name)
          .where('productType', isEqualTo: product.productType.firebaseValue)
          .where('companyId', isEqualTo: product.companyId)
          .get();

      final investments = snapshot.docs
          .map((doc) => Investment.fromFirestore(doc))
          .toList();

      return ProductDetails(
        product: product,
        investments: investments,
        totalInvestors: investments.length,
        uniqueInvestors: investments.map((i) => i.clientId).toSet().length,
      );
    } catch (e) {
      logError('getProductDetails', e);
      return null;
    }
  }

  /// Pobiera statystyki deduplikowanych produktów
  /// Zwraca ProductStatistics na bazie deduplikowanych danych
  Future<ProductStatistics> getDeduplicatedProductStatistics() async {
    const cacheKey = 'deduplicated_product_statistics';

    return getCachedData(cacheKey, () async {
      try {
        final products = await getAllUniqueProducts();

        if (products.isEmpty) {
          return ProductStatistics(
            totalProducts: 0,
            activeProducts: 0,
            inactiveProducts: 0,
            totalInvestmentAmount: 0.0,
            totalValue: 0.0,
            averageInvestmentAmount: 0.0,
            averageValue: 0.0,
            typeDistribution: {},
            statusDistribution: {},
            mostValuableType: UnifiedProductType.bonds,
          );
        }

        // Oblicz podstawowe statystyki
        final totalProducts = products.length;
        final activeProducts = products
            .where((p) => p.status == ProductStatus.active)
            .length;
        final inactiveProducts = totalProducts - activeProducts;

        final totalValue = products.fold(0.0, (sum, p) => sum + p.totalValue);
        final totalInvestmentAmount = totalValue; // ⭐ ZMIANA: totalInvestmentAmount = suma wszystkich investmentAmount
        final averageValue = totalProducts > 0
            ? totalValue / totalProducts
            : 0.0;
        final averageInvestmentAmount = totalInvestmentAmount / totalProducts; // ⭐ ZMIANA: Oblicz na podstawie totalInvestmentAmount

        // Dystrybucja typów produktów
        final Map<UnifiedProductType, int> typeDistribution = {};
        for (final product in products) {
          typeDistribution[product.productType] =
              (typeDistribution[product.productType] ?? 0) + 1;
        }

        // Dystrybucja statusów
        final Map<ProductStatus, int> statusDistribution = {};
        for (final product in products) {
          statusDistribution[product.status] =
              (statusDistribution[product.status] ?? 0) + 1;
        }

        // Znajdź najbardziej wartościowy typ
        UnifiedProductType mostValuableType = UnifiedProductType.bonds;
        double maxTypeValue = 0.0;

        for (final type in typeDistribution.keys) {
          final typeValue = products
              .where((p) => p.productType == type)
              .fold(0.0, (sum, p) => sum + p.totalValue);

          if (typeValue > maxTypeValue) {
            maxTypeValue = typeValue;
            mostValuableType = type;
          }
        }

        return ProductStatistics(
          totalProducts: totalProducts,
          activeProducts: activeProducts,
          inactiveProducts: inactiveProducts,
          totalInvestmentAmount: totalInvestmentAmount,
          totalValue: totalValue,
          averageInvestmentAmount: averageInvestmentAmount,
          averageValue: averageValue,
          typeDistribution: typeDistribution,
          statusDistribution: statusDistribution,
          mostValuableType: mostValuableType,
        );
      } catch (e) {
        logError('getDeduplicatedProductStatistics', e);
        return ProductStatistics(
          totalProducts: 0,
          activeProducts: 0,
          inactiveProducts: 0,
          totalInvestmentAmount: 0.0,
          totalValue: 0.0,
          averageInvestmentAmount: 0.0,
          averageValue: 0.0,
          typeDistribution: {},
          statusDistribution: {},
          mostValuableType: UnifiedProductType.bonds,
        );
      }
    });
  }

  /// Pobiera statystyki deduplikacji
  Future<DeduplicationStats> getDeduplicationStats() async {
    const cacheKey = 'deduplication_stats';

    return getCachedData(cacheKey, () async {
      try {
        // Policz wszystkie inwestycje
        final investmentsSnapshot = await firestore
            .collection('investments')
            .count()
            .get();
        final totalInvestments = investmentsSnapshot.count ?? 0;

        // Policz unikalne produkty
        final uniqueProducts = await getAllUniqueProducts();
        final totalUniqueProducts = uniqueProducts.length;

        // Oblicz wskaźnik duplikacji
        final duplicationRatio = totalInvestments > 0
            ? (totalInvestments - totalUniqueProducts) / totalInvestments
            : 0.0;

        return DeduplicationStats(
          totalInvestments: totalInvestments,
          uniqueProducts: totalUniqueProducts,
          duplicatedInvestments: totalInvestments - totalUniqueProducts,
          duplicationRatio: duplicationRatio,
          avgInvestorsPerProduct: totalInvestments / totalUniqueProducts,
        );
      } catch (e) {
        logError('getDeduplicationStats', e);
        return DeduplicationStats.empty();
      }
    });
  }

  /// Główna metoda deduplikacji - grupuje inwestycje według produktów
  Future<List<DeduplicatedProduct>> _fetchUniqueProducts() async {
    try {
      final snapshot = await firestore.collection('investments').get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      // Grupuj inwestycje według klucza produktu
      final Map<String, List<Map<String, dynamic>>> groupedInvestments = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        final productKey = _generateProductKey(data);
        groupedInvestments.putIfAbsent(productKey, () => []).add(data);
      }

      if (kDebugMode) {
        print(
          '[DeduplicatedProductService] Pogrupowano ${snapshot.docs.length} inwestycji w ${groupedInvestments.length} unikalnych produktów',
        );
      }

      // ⭐ NOWE: Konwertuj grupy na deduplikowane produkty (asynchronicznie)
      final List<DeduplicatedProduct> uniqueProducts = [];

      // Przetwarzanie w partiach żeby nie przeciążyć Firebase Functions
      final entries = groupedInvestments.entries.toList();
      const batchSize = 10; // Przetwarzaj 10 produktów jednocześnie

      for (int i = 0; i < entries.length; i += batchSize) {
        final batch = entries.skip(i).take(batchSize);

        final batchResults = await Future.wait(
          batch.map((entry) async {
            final productKey = entry.key;
            final investments = entry.value;

            try {
              return await _createDeduplicatedProduct(productKey, investments);
            } catch (e) {
              logError('_createDeduplicatedProduct for key: $productKey', e);
              return null;
            }
          }),
        );

        // Dodaj tylko poprawnie przetworzone produkty
        for (final product in batchResults) {
          if (product != null) {
            uniqueProducts.add(product);
          }
        }

        // Krótka przerwa między partiami
        if (i + batchSize < entries.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      print(
        '🎯 [DeduplicatedProductService] Przetworzono ${uniqueProducts.length} produktów z Firebase Functions',
      );

      // Sortuj według łącznej wartości inwestycji (malejąco)
      uniqueProducts.sort((a, b) => b.totalValue.compareTo(a.totalValue));

      return uniqueProducts;
    } catch (e) {
      logError('_fetchUniqueProducts', e);
      return [];
    }
  }

  /// Generuje unikalny klucz dla produktu na podstawie nazwy, typu i firmy
  String _generateProductKey(Map<String, dynamic> data) {
    final productName =
        data['productName'] ??
        data['projectName'] ??
        data['nazwa_produktu'] ??
        'Nieznany Produkt';

    final productType = data['productType'] ?? data['typ_produktu'] ?? 'bonds';

    final companyId =
        data['companyId'] ??
        data['ID_Spolka'] ??
        data['id_spolka'] ??
        data['creditorCompany'] ??
        data['wierzyciel_spolka'] ??
        'unknown';

    // Normalizuj klucz - usuń specjalne znaki i spacje
    final normalizedKey = '$productName|$productType|$companyId'
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s|]'), '')
        .trim();

    return normalizedKey;
  }

  /// Tworzy deduplikowany produkt z grupy inwestycji
  /// ⭐ NOWE: Używa Firebase Functions do zsynchronizowanego liczenia inwestorów
  Future<DeduplicatedProduct> _createDeduplicatedProduct(
    String productKey,
    List<Map<String, dynamic>> investments,
  ) async {
    if (investments.isEmpty) {
      throw ArgumentError('Lista inwestycji nie może być pusta');
    }

    // Użyj pierwszej inwestycji jako wzorca
    final firstInvestment = investments.first;

    // Oblicz agregowane statystyki
    double totalValue = 0.0; // ⭐ SUMA investmentAmount - nie będzie zastępowana
    double totalRemainingCapital = 0.0;
    int totalInvestors = investments.length;
    Set<String> uniqueClientIds = {};

    for (final investment in investments) {
      totalValue += _safeToDouble(
        investment['investmentAmount'] ?? investment['kwota_inwestycji'],
      );
      totalRemainingCapital += _safeToDouble(
        investment['remainingCapital'] ?? investment['kapital_pozostaly'],
      );

      final clientId = investment['clientId'] ?? investment['id_klient'];
      if (clientId != null) {
        uniqueClientIds.add(clientId.toString());
      }
    }

    final uniqueInvestorsCount = uniqueClientIds.length;

    // ⭐ NOWE: Używaj Firebase Functions do precyzyjnego liczenia inwestorów
    int actualInvestorCount = 0;
    try {
      final productName =
          firstInvestment['productName'] ??
          firstInvestment['projectName'] ??
          firstInvestment['nazwa_produktu'] ??
          'Nieznany Produkt';

      print('🔧 [DeduplicatedProduct] Tworzenie produktu dla: $productName');

      // ⭐ KLUCZOWA ZMIANA: Używaj productId z inwestycji, NIE ID dokumentu
      final productId =
          firstInvestment['productId'] ??
          firstInvestment['id']; // fallback do ID dokumentu

      print('🔧 [DeduplicatedProduct] productId: $productId');
      print('🔧 [DeduplicatedProduct] productName: $productName');

      print(
        '🔄 [DeduplicatedProduct] Pobieranie rzeczywistej liczby inwestorów...',
      );

      final result = await _investorsService.getProductInvestors(
        productId: productId?.toString(), // ⭐ UŻYWAMY RZECZYWISTEGO PRODUCT ID
        productName: productName,
        searchStrategy: productId != null
            ? 'productId'
            : 'productName', // Strategia zależna od dostępności productId
      );

      actualInvestorCount = result.totalCount;

      // 🚀 NOWE: Pobierz rzeczywistą liczbę inwestorów z Firebase Functions (ale zachowaj lokalną totalValue)
      if (result.investors.isNotEmpty) {
        double realTotalRemainingCapital = 0.0;

        for (final investor in result.investors) {
          realTotalRemainingCapital += investor.totalRemainingCapital;
        }

        // Zastąp TYLKO kapitał pozostały rzeczywistymi danymi (totalValue pozostaje lokalna)
        totalRemainingCapital = realTotalRemainingCapital;

        print('💰 [DeduplicatedProduct] Kapitał pozostały zsynchronizowany:');
        print('   - Lokalny kapitał pozostały: -> zastąpiony');
        print('   - Rzeczywisty kapitał: $realTotalRemainingCapital');
        print('   - TotalValue (zachowana lokalna): $totalValue');
      }

      print('✅ [DeduplicatedProduct] $productName:');
      print('   - ProductId: $productId');
      print('   - Lokalne liczenie: $uniqueInvestorsCount');
      print('   - Firebase Functions: $actualInvestorCount');
      print('   - Różnica: ${actualInvestorCount - uniqueInvestorsCount}');
      print('   - Strategia: ${result.searchStrategy}');
      print('   - Z cache: ${result.fromCache}');
    } catch (e) {
      print(
        '⚠️ [DeduplicatedProduct] Błąd Firebase Functions dla $productKey: $e',
      );
      // Fallback: użyj lokalne liczenie
      actualInvestorCount = uniqueInvestorsCount;
    }

    // Znajdź najwcześniejszą i najnowszą datę
    DateTime? earliestDate;
    DateTime? latestDate;

    for (final investment in investments) {
      final createdAt = _parseDate(
        investment['createdAt'] ??
            investment['signedDate'] ??
            investment['data_podpisania'],
      );

      if (createdAt != null) {
        if (earliestDate == null || createdAt.isBefore(earliestDate)) {
          earliestDate = createdAt;
        }
        if (latestDate == null || createdAt.isAfter(latestDate)) {
          latestDate = createdAt;
        }
      }
    }

    // ⭐ NOWE: ID produktu oparte na productId z pierwszej inwestycji
    final deduplicatedId =
        firstInvestment['productId']?.toString() ??
        productKey.hashCode.abs().toString();

    return DeduplicatedProduct(
      id: deduplicatedId, // ⭐ UŻYWAMY RZECZYWISTEGO PRODUCT ID
      name:
          firstInvestment['productName'] ??
          firstInvestment['projectName'] ??
          firstInvestment['nazwa_produktu'] ??
          'Nieznany Produkt',
      productType: _mapProductType(
        firstInvestment['productType'] ?? firstInvestment['typ_produktu'],
      ),
      companyId:
          firstInvestment['companyId'] ??
          firstInvestment['id_spolka'] ??
          'unknown',
      companyName:
          firstInvestment['creditorCompany'] ??
          firstInvestment['wierzyciel_spolka'] ??
          firstInvestment['companyName'] ??
          firstInvestment['nazwa_firmy'] ??
          firstInvestment['nazwa_spolki'] ??
          firstInvestment['emitent'] ??
          firstInvestment['developer'] ??
          firstInvestment['issuer'] ??
          firstInvestment['Emitent'] ??
          firstInvestment['Developer'] ??
          firstInvestment['companyId'] ??
          'Nieznana Firma',
      totalValue: totalValue,
      totalRemainingCapital: totalRemainingCapital,
      totalInvestments: totalInvestors,
      uniqueInvestors: uniqueInvestorsCount,
      actualInvestorCount: actualInvestorCount, // ⭐ NOWE
      averageInvestment: totalValue / totalInvestors,
      earliestInvestmentDate: earliestDate ?? DateTime.now(),
      latestInvestmentDate: latestDate ?? DateTime.now(),
      status: _determineProductStatus(investments),
      interestRate: _safeToDouble(firstInvestment['interestRate']),
      maturityDate: _parseDate(firstInvestment['maturityDate']),
      originalInvestmentIds: investments
          .map((inv) => inv['id'].toString())
          .toList(),
      metadata: {
        'productKey': productKey,
        'sourceInvestments': investments.length,
        'deduplicationTimestamp': DateTime.now().toIso8601String(),
        'sampleInvestmentIds': investments
            .take(3)
            .map((inv) => inv['id'])
            .toList(),
        'actualInvestorCount': actualInvestorCount, // ⭐ NOWE
        'uniqueInvestorsLocal': uniqueInvestorsCount,
        'realProductId':
            firstInvestment['productId'], // ⭐ DODANO: rzeczywisty productId
        'deduplicatedId':
            deduplicatedId, // ⭐ DODANO: ID używane przez deduplikację
      },
    );
  }

  /// Mapuje typ produktu z różnych formatów
  UnifiedProductType _mapProductType(dynamic productType) {
    if (productType == null) return UnifiedProductType.bonds;

    print(
      '🔧 [DeduplicatedProductService] Mapowanie typu produktu: $productType (${productType.runtimeType})',
    );

    // Sprawdź czy to enum ProductType
    if (productType is ProductType) {
      print(
        '🔧 [DeduplicatedProductService] To jest ProductType enum: $productType',
      );
      switch (productType) {
        case ProductType.bonds:
          return UnifiedProductType.bonds;
        case ProductType.shares:
          return UnifiedProductType.shares;
        case ProductType.loans:
          return UnifiedProductType.loans;
        case ProductType.apartments:
          return UnifiedProductType.apartments;
      }
    }

    final typeStr = productType.toString().toLowerCase();

    // Sprawdź enum toString format (ProductType.bonds -> bonds)
    if (typeStr.contains('.bonds')) return UnifiedProductType.bonds;
    if (typeStr.contains('.shares')) return UnifiedProductType.shares;
    if (typeStr.contains('.loans')) return UnifiedProductType.loans;
    if (typeStr.contains('.apartments')) return UnifiedProductType.apartments;

    if (typeStr.contains('apartment') || typeStr.contains('apartament')) {
      return UnifiedProductType.apartments;
    }
    if (typeStr.contains('share') || typeStr.contains('udział')) {
      return UnifiedProductType.shares;
    }
    if (typeStr.contains('loan') || typeStr.contains('pożyczk')) {
      return UnifiedProductType.loans;
    }
    if (typeStr.contains('bond') || typeStr.contains('obligacj')) {
      return UnifiedProductType.bonds;
    }

    return UnifiedProductType.bonds;
  }

  /// Określa status produktu na podstawie inwestycji
  ProductStatus _determineProductStatus(
    List<Map<String, dynamic>> investments,
  ) {
    final activeCount = investments
        .where(
          (inv) =>
              (inv['status'] ?? inv['status_produktu'] ?? 'active')
                  .toString()
                  .toLowerCase()
                  .contains('active') ||
              (inv['status'] ?? inv['status_produktu'] ?? 'aktywny')
                  .toString()
                  .toLowerCase()
                  .contains('aktywny'),
        )
        .length;

    final activeRatio = activeCount / investments.length;

    if (activeRatio > 0.8) return ProductStatus.active;
    if (activeRatio > 0.2) return ProductStatus.pending;
    return ProductStatus.inactive;
  }

  /// Bezpieczna konwersja na double
  double _safeToDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(',', '').replaceAll(' ', '');
      final parsed = double.tryParse(cleaned);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  /// Parsuje datę z różnych formatów
  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;

    if (dateValue is Timestamp) {
      return dateValue.toDate();
    }

    if (dateValue is DateTime) {
      return dateValue;
    }

    if (dateValue is String) {
      return DateTime.tryParse(dateValue);
    }

    return null;
  }

  /// Czyści cache deduplikacji
  void clearDeduplicationCache() {
    clearCache(_cacheKeyAll);

    for (final type in UnifiedProductType.values) {
      clearCache('${_cacheKeyPrefix}type_${type.name}');
    }

    clearCache('deduplication_stats');
  }
}

/// Model deduplikowanego produktu
class DeduplicatedProduct {
  final String id;
  final String name;
  final UnifiedProductType productType;
  final String companyId;
  final String companyName;
  final double totalValue; // ⭐ Suma investmentAmount ze wszystkich inwestycji
  final double totalRemainingCapital;
  final int totalInvestments;
  final int uniqueInvestors;
  final int
  actualInvestorCount; // ⭐ NOWE: liczba inwestorów z Firebase Functions
  final double averageInvestment;
  final DateTime earliestInvestmentDate;
  final DateTime latestInvestmentDate;
  final ProductStatus status;
  final double? interestRate;
  final DateTime? maturityDate;
  final List<String> originalInvestmentIds;
  final Map<String, dynamic> metadata;

  const DeduplicatedProduct({
    required this.id,
    required this.name,
    required this.productType,
    required this.companyId,
    required this.companyName,
    required this.totalValue,
    required this.totalRemainingCapital,
    required this.totalInvestments,
    required this.uniqueInvestors,
    required this.actualInvestorCount,
    required this.averageInvestment,
    required this.earliestInvestmentDate,
    required this.latestInvestmentDate,
    required this.status,
    this.interestRate,
    this.maturityDate,
    required this.originalInvestmentIds,
    this.metadata = const {},
  });

  /// Wskaźnik duplikacji dla tego produktu
  double get duplicationRatio => totalInvestments > uniqueInvestors
      ? (totalInvestments - uniqueInvestors) / totalInvestments
      : 0.0;

  /// Czy produkt ma duplikaty
  bool get hasDuplicates => totalInvestments > uniqueInvestors;

  /// ⭐ NOWE: Zwraca właściwą liczbę inwestorów (preferuje actualInvestorCount)
  int get investorCount =>
      actualInvestorCount > 0 ? actualInvestorCount : uniqueInvestors;

  /// Procent zwrotu kapitału
  double get capitalReturnPercentage {
    if (totalValue == 0) return 0.0;
    return ((totalValue - totalRemainingCapital) / totalValue) * 100;
  }
}

/// Szczegółowe informacje o produkcie z listą inwestycji
class ProductDetails {
  final DeduplicatedProduct product;
  final List<Investment> investments;
  final int totalInvestors;
  final int uniqueInvestors;

  const ProductDetails({
    required this.product,
    required this.investments,
    required this.totalInvestors,
    required this.uniqueInvestors,
  });
}

/// Statystyki deduplikacji
class DeduplicationStats {
  final int totalInvestments;
  final int uniqueProducts;
  final int duplicatedInvestments;
  final double duplicationRatio;
  final double avgInvestorsPerProduct;

  const DeduplicationStats({
    required this.totalInvestments,
    required this.uniqueProducts,
    required this.duplicatedInvestments,
    required this.duplicationRatio,
    required this.avgInvestorsPerProduct,
  });

  factory DeduplicationStats.empty() {
    return const DeduplicationStats(
      totalInvestments: 0,
      uniqueProducts: 0,
      duplicatedInvestments: 0,
      duplicationRatio: 0.0,
      avgInvestorsPerProduct: 0.0,
    );
  }

  /// Procent deduplikacji
  double get deduplicationPercentage => duplicationRatio * 100;
}

/// Rozszerzenie dla UnifiedProductType
extension UnifiedProductTypeExtension on UnifiedProductType {
  /// Wartość używana w Firebase
  String get firebaseValue {
    switch (this) {
      case UnifiedProductType.apartments:
        return 'Apartamenty';
      case UnifiedProductType.bonds:
        return 'Obligacje';
      case UnifiedProductType.shares:
        return 'Udziały';
      case UnifiedProductType.loans:
        return 'Pożyczki';
      default:
        return 'Obligacje';
    }
  }
}
