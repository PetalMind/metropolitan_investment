import 'package:flutter/foundation.dart';
import '../models_and_services.dart';
import '../services/firebase_functions_products_service.dart' as fb;
import '../services/unified_product_service.dart' as unified;
import '../services/optimized_product_service.dart';
import '../adapters/product_statistics_adapter.dart';

/// Serwis zarządzający produktami z obsługą różnych trybów i optymalizacji
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

    final productsResult = results[0] as UnifiedProductsResult;
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
}

/// Klasa zawierająca dane produktów
class ProductManagementData {
  final List<UnifiedProduct> allProducts;
  final List<OptimizedProduct> optimizedProducts;
  final List<DeduplicatedProduct> deduplicatedProducts;
  final fb.ProductStatistics? statistics;
  final UnifiedProductsMetadata? metadata;
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
