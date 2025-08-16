import 'package:flutter/foundation.dart';
import 'deduplicated_product_service.dart';
import 'optimized_product_service.dart';
import '../models_and_services.dart'; // Centralny import z ultra-precyzyjnym serwisem
import '../models/unified_product.dart';
import '../models/investor_summary.dart';
import '../services/firebase_functions_products_service.dart' as fb;
import '../services/unified_product_service.dart' as unified;
import '../adapters/product_statistics_adapter.dart';

/// 🚀 CENTRALNY SERWIS ZARZĄDZANIA PRODUKTAMI
///
/// Ten serwis jest jedynym punktem dostępu do danych produktów dla wszystkich widoków.
/// Automatycznie wybiera optymalną strategię ładowania i zapewnia jednolity interfejs.
///
/// Funkcjonalności:
/// - ✅ Inteligentne wybieranie serwisu (optimized vs legacy)
/// - ✅ Ujednolicone API dla wszystkich ekranów
/// - ✅ Centralne zarządzanie cache
/// - ✅ Filtrowanie i sortowanie
/// - ✅ Wyszukiwanie produktów
/// - ✅ Statystyki i metadata
/// - ✅ Obsługa różnych trybów wyświetlania (unified/deduplicated)
class ProductManagementService {
  late final fb.FirebaseFunctionsProductsService _fbProductService;
  late final unified.UnifiedProductService _unifiedProductService;
  late final DeduplicatedProductService _deduplicatedProductService;
  late final OptimizedProductService _optimizedProductService;

  ProductManagementService() {
    _initializeServices();
  }

  void _initializeServices() {
    _fbProductService = fb.FirebaseFunctionsProductsService();
    _unifiedProductService = unified.UnifiedProductService();
    _deduplicatedProductService = DeduplicatedProductService();
    _optimizedProductService = OptimizedProductService();
  }

  /// Ładuje dane w trybie zoptymalizowanym
  Future<ProductManagementData> loadOptimizedData({
    bool forceRefresh = false,
    bool includeStatistics = true,
  }) async {
    if (kDebugMode) {
      print('⚡ [ProductManagementService] Używam OptimizedProductService...');
    }

    final stopwatch = Stopwatch()..start();

    final optimizedResult = await _optimizedProductService
        .getAllProductsOptimized(
          forceRefresh: forceRefresh,
          includeStatistics: includeStatistics,
        );

    stopwatch.stop();

    // Konwertuj OptimizedProduct na DeduplicatedProduct dla kompatybilności
    final deduplicatedProducts = optimizedResult.products
        .map((opt) => _convertOptimizedToDeduplicatedProduct(opt))
        .toList();

    // Utwórz statystyki z OptimizedProductsResult
    fb.ProductStatistics? statistics;
    if (optimizedResult.statistics != null) {
      statistics = _convertGlobalStatsToFBStatsViAdapter(
        optimizedResult.statistics!,
      );
    }

    if (kDebugMode) {
      print(
        '⚡ [ProductManagementService] Załadowano ${optimizedResult.products.length} produktów w ${stopwatch.elapsedMilliseconds}ms',
      );
    }

    return ProductManagementData(
      allProducts: [],
      optimizedProducts: optimizedResult.products,
      deduplicatedProducts: deduplicatedProducts,
      statistics: statistics,
      metadata: null,
      optimizedResult: optimizedResult,
    );
  }

  /// Główna metoda ładowania danych produktów
  Future<ProductManagementData> loadProductsData({
    required ProductSortField sortField,
    required SortDirection sortDirection,
    required bool showDeduplicatedView,
    required bool useOptimizedMode,
  }) async {
    if (useOptimizedMode) {
      return await loadOptimizedData(
        forceRefresh: false,
        includeStatistics: true,
      );
    } else {
      return await loadLegacyData(
        sortField: sortField,
        sortDirection: sortDirection,
        showDeduplicatedView: showDeduplicatedView,
      );
    }
  }

  /// Odświeża cache
  Future<void> refreshCache() async {
    try {
      await _fbProductService.refreshCache();
      _deduplicatedProductService.clearAllCache();
      _optimizedProductService.clearAllCache();
    } catch (e) {
      if (kDebugMode) {
        print(
          '⚠️ [ProductManagementService] Błąd podczas odświeżania cache: $e',
        );
      }
    }
  }

  /// Metoda ładowania produktów w trybie legacy (istniejąca implementacja)
  Future<ProductManagementData> loadLegacyData({
    ProductSortField sortField = ProductSortField.createdAt,
    SortDirection sortDirection = SortDirection.descending,
    bool showDeduplicatedView = true,
  }) async {
    if (kDebugMode) {
      print('🔄 [ProductManagementService] Używam legacy loading...');
    }

    // TEST: Sprawdź połączenie z Firebase Functions
    if (kDebugMode) {
      try {
        await _fbProductService.testDirectFirestoreAccess();
        await _fbProductService.testConnection();
      } catch (e) {
        if (kDebugMode) {
          print(
            '⚠️ [ProductManagementService] Ostrzeżenie testów Firebase: $e',
          );
        }
      }
    }

    // Pobierz produkty, statystyki i deduplikowane produkty równolegle
    final results = await Future.wait([
      _fbProductService.getUnifiedProducts(
        pageSize: 1000,
        sortBy: sortField.name,
        sortAscending: sortDirection == SortDirection.ascending,
      ),
      _unifiedProductService.getProductStatistics().then(
        (globalStats) =>
            ProductStatisticsAdapter.adaptFromUnifiedToFB(globalStats),
      ),
      _deduplicatedProductService.getAllUniqueProducts(),
    ]);

    final productsResult = results[0] as fb.UnifiedProductsResult;
    final statistics = results[1] as fb.ProductStatistics;
    final deduplicatedProducts = results[2] as List<DeduplicatedProduct>;

    if (kDebugMode) {
      print(
        '🔄 [ProductManagementService] Legacy: Załadowano ${productsResult.products.length} produktów, cache używany: ${productsResult.metadata.cacheUsed}',
      );
    }

    return ProductManagementData(
      allProducts: productsResult.products,
      optimizedProducts: [],
      deduplicatedProducts: deduplicatedProducts,
      statistics: statistics,
      metadata: productsResult.metadata,
      optimizedResult: null,
    );
  }

  /// Odświeża cache produktów
  Future<void> refreshProductsCache(bool useOptimizedMode) async {
    if (useOptimizedMode) {
      await _optimizedProductService.refreshProducts();
    } else {
      await _fbProductService.refreshCache();
    }
  }

  /// Odświeża statystyki
  Future<fb.ProductStatistics> refreshStatistics({
    required bool useOptimizedMode,
    required bool showDeduplicatedView,
    OptimizedProductsResult? optimizedResult,
  }) async {
    if (useOptimizedMode && optimizedResult?.statistics != null) {
      return _convertGlobalStatsToFBStatsViAdapter(
        optimizedResult!.statistics!,
      );
    } else if (showDeduplicatedView) {
      final globalStats = await _deduplicatedProductService
          .getDeduplicatedProductStatistics();
      return ProductStatisticsAdapter.adaptFromUnifiedToFB(globalStats);
    } else {
      final globalStats = await _unifiedProductService.getProductStatistics();
      return ProductStatisticsAdapter.adaptFromUnifiedToFB(globalStats);
    }
  }

  /// Konwertuje OptimizedProduct na DeduplicatedProduct
  DeduplicatedProduct _convertOptimizedToDeduplicatedProduct(
    OptimizedProduct opt,
  ) {
    return DeduplicatedProduct(
      id: opt.id,
      name: opt.name,
      productType: opt.productType,
      companyId: opt.companyId,
      companyName: opt.companyName,
      totalValue: opt.totalValue,
      totalRemainingCapital: opt.totalRemainingCapital,
      totalInvestments: opt.totalInvestments,
      uniqueInvestors: opt.uniqueInvestors,
      actualInvestorCount: opt.actualInvestorCount,
      averageInvestment: opt.averageInvestment,
      earliestInvestmentDate: opt.earliestInvestmentDate,
      latestInvestmentDate: opt.latestInvestmentDate,
      status: opt.status,
      interestRate: opt.interestRate,
      maturityDate: null,
      originalInvestmentIds: [],
      metadata: opt.metadata,
    );
  }

  /// Konwertuje GlobalProductStatistics na fb.ProductStatistics przez adapter
  fb.ProductStatistics _convertGlobalStatsToFBStatsViAdapter(
    GlobalProductStatistics global,
  ) {
    final unifiedStats = unified.ProductStatistics(
      totalProducts: global.totalProducts,
      activeProducts: global.totalProducts,
      inactiveProducts: 0,
      totalInvestmentAmount: global.totalValue,
      totalValue: global.totalValue,
      averageInvestmentAmount: global.averageValuePerProduct,
      averageValue: global.averageValuePerProduct,
      typeDistribution: _convertTypeDistribution(
        global.productTypeDistribution,
      ),
      statusDistribution: const {ProductStatus.active: 1},
      mostValuableType: UnifiedProductType.bonds,
    );

    return ProductStatisticsAdapter.adaptFromUnifiedToFB(unifiedStats);
  }

  /// Konwertuje Map<String, int> na Map<UnifiedProductType, int>
  Map<UnifiedProductType, int> _convertTypeDistribution(
    Map<String, int> typeDistribution,
  ) {
    final Map<UnifiedProductType, int> result = {};

    for (final entry in typeDistribution.entries) {
      final unifiedType = _mapStringToUnifiedProductType(entry.key);
      if (unifiedType != null) {
        result[unifiedType] = entry.value;
      }
    }

    return result;
  }

  /// Mapuje string na UnifiedProductType
  UnifiedProductType? _mapStringToUnifiedProductType(String type) {
    switch (type.toLowerCase()) {
      case 'bonds':
      case 'obligacje':
        return UnifiedProductType.bonds;
      case 'shares':
      case 'akcje':
        return UnifiedProductType.shares;
      case 'loans':
      case 'pozyczki':
        return UnifiedProductType.loans;
      case 'apartments':
      case 'mieszkania':
        return UnifiedProductType.apartments;
      case 'other':
      case 'inne':
        return UnifiedProductType.other;
      default:
        return UnifiedProductType.bonds;
    }
  }

  // 🚀 DODATKOWE METODY DLA CENTRALNEGO ZARZĄDZANIA

  /// Wyszukuje produkty po nazwie lub ID
  Future<ProductSearchResult> searchProducts({
    required String query,
    UnifiedProductType? filterType,
    bool useOptimizedMode = true,
    int maxResults = 50,
  }) async {
    if (kDebugMode) {
      print('🔍 [ProductManagementService] Wyszukiwanie: "$query"');
    }

    if (query.trim().isEmpty) {
      final data = await loadOptimizedData();
      return ProductSearchResult(
        query: query,
        products: data.optimizedProducts.take(maxResults).toList(),
        deduplicatedProducts: data.deduplicatedProducts
            .take(maxResults)
            .toList(),
        totalResults: data.optimizedProducts.length,
        searchTime: 0,
      );
    }

    final stopwatch = Stopwatch()..start();

    if (useOptimizedMode) {
      final data = await loadOptimizedData();
      final filteredOptimized = data.optimizedProducts
          .where((product) {
            final matchesQuery =
                product.name.toLowerCase().contains(query.toLowerCase()) ||
                product.id.toLowerCase().contains(query.toLowerCase());
            final matchesType =
                filterType == null || product.productType == filterType;
            return matchesQuery && matchesType;
          })
          .take(maxResults)
          .toList();

      final filteredDeduplicated = data.deduplicatedProducts
          .where((product) {
            final matchesQuery =
                product.name.toLowerCase().contains(query.toLowerCase()) ||
                product.id.toLowerCase().contains(query.toLowerCase());
            final matchesType =
                filterType == null || product.productType == filterType;
            return matchesQuery && matchesType;
          })
          .take(maxResults)
          .toList();

      stopwatch.stop();

      return ProductSearchResult(
        query: query,
        products: filteredOptimized,
        deduplicatedProducts: filteredDeduplicated,
        totalResults: filteredOptimized.length,
        searchTime: stopwatch.elapsedMilliseconds,
      );
    } else {
      // Legacy search
      final deduplicatedProducts = await _deduplicatedProductService
          .searchUniqueProducts(query);
      final filtered = filterType != null
          ? deduplicatedProducts
                .where((p) => p.productType == filterType)
                .toList()
          : deduplicatedProducts;

      stopwatch.stop();

      return ProductSearchResult(
        query: query,
        products: [],
        deduplicatedProducts: filtered.take(maxResults).toList(),
        totalResults: filtered.length,
        searchTime: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Pobiera szczegóły pojedynczego produktu
  Future<ProductDetails?> getProductDetails(String productId) async {
    if (kDebugMode) {
      print(
        '📋 [ProductManagementService] Pobieranie szczegółów produktu: $productId',
      );
    }

    try {
      // Próbuj z optimized najpierw
      final data = await loadOptimizedData();
      final optimizedProduct = data.optimizedProducts
          .where((p) => p.id == productId)
          .firstOrNull;

      if (optimizedProduct != null) {
        // Pobierz dodatkowe szczegóły z ultra-precyzyjnego serwisu
        final ultraResult = await UltraPreciseProductInvestorsService()
            .getByProductId(productId);

        // Konwertuj na standardowy format
        final investorsResult = ProductInvestorsResult(
          investors: ultraResult.investors,
          totalCount: ultraResult.totalCount,
          statistics: ProductInvestorsStatistics(
            totalCapital: ultraResult.statistics.totalCapital,
            totalInvestments: ultraResult.statistics.totalInvestments,
            averageCapital: ultraResult.statistics.averageCapital,
            activeInvestors: ultraResult.totalCount,
          ),
          searchStrategy: 'ultra_precise_product_id',
          productName: optimizedProduct.name,
          productType: optimizedProduct.productType.name.toLowerCase(),
          executionTime: ultraResult.executionTime,
          fromCache: ultraResult.fromCache,
          error: ultraResult.error,
        );

        return ProductDetails(
          product: optimizedProduct,
          deduplicatedProduct: _convertOptimizedToDeduplicatedProduct(
            optimizedProduct,
          ),
          investors: investorsResult.investors,
          totalInvestors: investorsResult.totalCount,
          metadata: {
            'searchStrategy': investorsResult.searchStrategy,
            'fromCache': investorsResult.fromCache,
          },
        );
      }

      // Fallback - sprawdź w deduplicated
      final deduplicatedProducts = await _deduplicatedProductService
          .getAllUniqueProducts();
      final deduplicatedProduct = deduplicatedProducts
          .where((p) => p.id == productId)
          .firstOrNull;

      if (deduplicatedProduct != null) {
        final ultraResult = await UltraPreciseProductInvestorsService()
            .getByProductId(productId);

        // Konwertuj na standardowy format
        final investorsResult = ProductInvestorsResult(
          investors: ultraResult.investors,
          totalCount: ultraResult.totalCount,
          statistics: ProductInvestorsStatistics(
            totalCapital: ultraResult.statistics.totalCapital,
            totalInvestments: ultraResult.statistics.totalInvestments,
            averageCapital: ultraResult.statistics.averageCapital,
            activeInvestors: ultraResult.totalCount,
          ),
          searchStrategy: 'ultra_precise_deduplicated',
          productName: deduplicatedProduct.name,
          productType: deduplicatedProduct.productType.name.toLowerCase(),
          executionTime: ultraResult.executionTime,
          fromCache: ultraResult.fromCache,
          error: ultraResult.error,
        );

        return ProductDetails(
          product: null,
          deduplicatedProduct: deduplicatedProduct,
          investors: investorsResult.investors,
          totalInvestors: investorsResult.totalCount,
          metadata: {
            'searchStrategy': investorsResult.searchStrategy,
            'fromCache': investorsResult.fromCache,
          },
        );
      }

      if (kDebugMode) {
        print(
          '⚠️ [ProductManagementService] Nie znaleziono produktu: $productId',
        );
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ [ProductManagementService] Błąd pobierania szczegółów produktu $productId: $e',
        );
      }
      return null;
    }
  }

  /// Filtruje produkty według kryteriów
  Future<ProductFilterResult> filterProducts({
    UnifiedProductType? productType,
    ProductStatus? status,
    double? minValue,
    double? maxValue,
    int? minInvestors,
    int? maxInvestors,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool useOptimizedMode = true,
  }) async {
    if (kDebugMode) {
      print('🔽 [ProductManagementService] Filtrowanie produktów');
    }

    final stopwatch = Stopwatch()..start();
    final data = await loadOptimizedData();

    List<OptimizedProduct> filteredOptimized = data.optimizedProducts;
    List<DeduplicatedProduct> filteredDeduplicated = data.deduplicatedProducts;

    // Filtruj optimized
    if (productType != null) {
      filteredOptimized = filteredOptimized
          .where((p) => p.productType == productType)
          .toList();
      filteredDeduplicated = filteredDeduplicated
          .where((p) => p.productType == productType)
          .toList();
    }

    if (status != null) {
      filteredOptimized = filteredOptimized
          .where((p) => p.status == status)
          .toList();
      filteredDeduplicated = filteredDeduplicated
          .where((p) => p.status == status)
          .toList();
    }

    if (minValue != null) {
      filteredOptimized = filteredOptimized
          .where((p) => p.totalValue >= minValue)
          .toList();
      filteredDeduplicated = filteredDeduplicated
          .where((p) => p.totalValue >= minValue)
          .toList();
    }

    if (maxValue != null) {
      filteredOptimized = filteredOptimized
          .where((p) => p.totalValue <= maxValue)
          .toList();
      filteredDeduplicated = filteredDeduplicated
          .where((p) => p.totalValue <= maxValue)
          .toList();
    }

    if (minInvestors != null) {
      filteredOptimized = filteredOptimized
          .where((p) => p.actualInvestorCount >= minInvestors)
          .toList();
      filteredDeduplicated = filteredDeduplicated
          .where((p) => p.actualInvestorCount >= minInvestors)
          .toList();
    }

    if (maxInvestors != null) {
      filteredOptimized = filteredOptimized
          .where((p) => p.actualInvestorCount <= maxInvestors)
          .toList();
      filteredDeduplicated = filteredDeduplicated
          .where((p) => p.actualInvestorCount <= maxInvestors)
          .toList();
    }

    stopwatch.stop();

    return ProductFilterResult(
      optimizedProducts: filteredOptimized,
      deduplicatedProducts: filteredDeduplicated,
      totalResults: filteredOptimized.length,
      filterTime: stopwatch.elapsedMilliseconds,
      appliedFilters: {
        'productType': productType?.name,
        'status': status?.name,
        'minValue': minValue,
        'maxValue': maxValue,
        'minInvestors': minInvestors,
        'maxInvestors': maxInvestors,
      },
    );
  }

  /// Sortuje produkty według wybranego kryterium
  List<T> sortProducts<T>({
    required List<T> products,
    required ProductSortField sortField,
    required SortDirection direction,
  }) {
    final sortedProducts = List<T>.from(products);

    sortedProducts.sort((a, b) {
      dynamic valueA, valueB;

      if (a is OptimizedProduct && b is OptimizedProduct) {
        switch (sortField) {
          case ProductSortField.name:
            valueA = a.name;
            valueB = b.name;
            break;
          case ProductSortField.totalValue:
            valueA = a.totalValue;
            valueB = b.totalValue;
            break;
          case ProductSortField.investmentAmount:
            valueA = a.totalValue; // Używamy totalValue jako proxy
            valueB = b.totalValue;
            break;
          case ProductSortField.createdAt:
            valueA = a.earliestInvestmentDate;
            valueB = b.earliestInvestmentDate;
            break;
          case ProductSortField.type:
            valueA = a.productType.name;
            valueB = b.productType.name;
            break;
          case ProductSortField.companyName:
            valueA = a.companyName;
            valueB = b.companyName;
            break;
          case ProductSortField.interestRate:
            valueA = a.interestRate;
            valueB = b.interestRate;
            break;
          default:
            valueA = a.name;
            valueB = b.name;
        }
      } else if (a is DeduplicatedProduct && b is DeduplicatedProduct) {
        switch (sortField) {
          case ProductSortField.name:
            valueA = a.name;
            valueB = b.name;
            break;
          case ProductSortField.totalValue:
            valueA = a.totalValue;
            valueB = b.totalValue;
            break;
          case ProductSortField.investmentAmount:
            valueA = a.totalValue; // Używamy totalValue jako proxy
            valueB = b.totalValue;
            break;
          case ProductSortField.createdAt:
            valueA = a.earliestInvestmentDate;
            valueB = b.earliestInvestmentDate;
            break;
          case ProductSortField.type:
            valueA = a.productType.name;
            valueB = b.productType.name;
            break;
          case ProductSortField.companyName:
            valueA = a.companyName;
            valueB = b.companyName;
            break;
          case ProductSortField.interestRate:
            valueA = a.interestRate ?? 0.0;
            valueB = b.interestRate ?? 0.0;
            break;
          default:
            valueA = a.name;
            valueB = b.name;
        }
      }

      int comparison;
      if (valueA is String && valueB is String) {
        comparison = valueA.compareTo(valueB);
      } else if (valueA is num && valueB is num) {
        comparison = valueA.compareTo(valueB);
      } else if (valueA is DateTime && valueB is DateTime) {
        comparison = valueA.compareTo(valueB);
      } else {
        comparison = valueA.toString().compareTo(valueB.toString());
      }

      return direction == SortDirection.ascending ? comparison : -comparison;
    });

    return sortedProducts;
  }

  /// Pobiera statystyki produktów według typu
  Future<Map<UnifiedProductType, ProductTypeStats>>
  getProductTypeStatistics() async {
    final data = await loadOptimizedData();
    final Map<UnifiedProductType, ProductTypeStats> stats = {};

    for (final type in UnifiedProductType.values) {
      final typeProducts = data.optimizedProducts
          .where((p) => p.productType == type)
          .toList();

      if (typeProducts.isNotEmpty) {
        final totalValue = typeProducts.fold<double>(
          0,
          (sum, p) => sum + p.totalValue,
        );
        final totalInvestors = typeProducts.fold<int>(
          0,
          (sum, p) => sum + p.actualInvestorCount,
        );

        stats[type] = ProductTypeStats(
          type: type,
          productCount: typeProducts.length,
          totalValue: totalValue,
          averageValue: totalValue / typeProducts.length,
          totalInvestors: totalInvestors,
          averageInvestorsPerProduct: totalInvestors / typeProducts.length,
        );
      }
    }

    return stats;
  }

  /// Czyści wszystkie cache
  Future<void> clearAllCache() async {
    if (kDebugMode) {
      print('🧹 [ProductManagementService] Czyszczenie wszystkich cache');
    }

    await Future.wait([
      _fbProductService.refreshCache(),
      Future.sync(() => _deduplicatedProductService.clearAllCache()),
      Future.sync(() => _optimizedProductService.clearAllCache()),
    ]);
  }

  /// Pobiera status cache (dla diagnostyki)
  Future<CacheStatus> getCacheStatus() async {
    try {
      // Test różnych cache
      final optimizedCache = await _optimizedProductService
          .getAllProductsOptimized(forceRefresh: false);
      final deduplicatedCache = await _deduplicatedProductService
          .getAllUniqueProducts();

      return CacheStatus(
        optimizedCacheHit: optimizedCache.fromCache,
        deduplicatedCacheActive: deduplicatedCache.isNotEmpty,
        lastRefresh: DateTime.now(),
        cacheVersion: 'v3',
      );
    } catch (e) {
      return CacheStatus(
        optimizedCacheHit: false,
        deduplicatedCacheActive: false,
        lastRefresh: null,
        cacheVersion: 'unknown',
        error: e.toString(),
      );
    }
  }
}

/// Klasa zawierająca dane produktów
class ProductManagementData {
  final List<UnifiedProduct> allProducts;
  final List<OptimizedProduct> optimizedProducts;
  final List<DeduplicatedProduct> deduplicatedProducts;
  final fb.ProductStatistics? statistics;
  final fb.UnifiedProductsMetadata? metadata;
  final OptimizedProductsResult? optimizedResult;

  ProductManagementData({
    required this.allProducts,
    required this.optimizedProducts,
    required this.deduplicatedProducts,
    this.statistics,
    this.metadata,
    this.optimizedResult,
  });
}

// 🚀 DODATKOWE KLASY POMOCNICZE

/// Rezultat wyszukiwania produktów
class ProductSearchResult {
  final String query;
  final List<OptimizedProduct> products;
  final List<DeduplicatedProduct> deduplicatedProducts;
  final int totalResults;
  final int searchTime;

  ProductSearchResult({
    required this.query,
    required this.products,
    required this.deduplicatedProducts,
    required this.totalResults,
    required this.searchTime,
  });
}

/// Szczegóły pojedynczego produktu
class ProductDetails {
  final OptimizedProduct? product;
  final DeduplicatedProduct? deduplicatedProduct;
  final List<InvestorSummary> investors;
  final int totalInvestors;
  final Map<String, dynamic>? metadata;

  ProductDetails({
    this.product,
    this.deduplicatedProduct,
    required this.investors,
    required this.totalInvestors,
    this.metadata,
  });

  /// Zwraca nazwę produktu z dostępnego źródła
  String get name =>
      product?.name ?? deduplicatedProduct?.name ?? 'Nieznany Produkt';

  /// Zwraca ID produktu z dostępnego źródła
  String get id => product?.id ?? deduplicatedProduct?.id ?? '';

  /// Zwraca typ produktu z dostępnego źródła
  UnifiedProductType get productType =>
      product?.productType ??
      deduplicatedProduct?.productType ??
      UnifiedProductType.other;
}

/// Rezultat filtrowania produktów
class ProductFilterResult {
  final List<OptimizedProduct> optimizedProducts;
  final List<DeduplicatedProduct> deduplicatedProducts;
  final int totalResults;
  final int filterTime;
  final Map<String, dynamic> appliedFilters;

  ProductFilterResult({
    required this.optimizedProducts,
    required this.deduplicatedProducts,
    required this.totalResults,
    required this.filterTime,
    required this.appliedFilters,
  });
}

/// Statystyki typu produktu
class ProductTypeStats {
  final UnifiedProductType type;
  final int productCount;
  final double totalValue;
  final double averageValue;
  final int totalInvestors;
  final double averageInvestorsPerProduct;

  ProductTypeStats({
    required this.type,
    required this.productCount,
    required this.totalValue,
    required this.averageValue,
    required this.totalInvestors,
    required this.averageInvestorsPerProduct,
  });
}

/// Status cache
class CacheStatus {
  final bool optimizedCacheHit;
  final bool deduplicatedCacheActive;
  final DateTime? lastRefresh;
  final String cacheVersion;
  final String? error;

  CacheStatus({
    required this.optimizedCacheHit,
    required this.deduplicatedCacheActive,
    this.lastRefresh,
    required this.cacheVersion,
    this.error,
  });
}
