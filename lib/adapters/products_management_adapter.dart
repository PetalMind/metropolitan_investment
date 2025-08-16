import '../models_and_services.dart';

/// 🚀 ZUNIFIKOWANY ADAPTER DLA PRODUCTS MANAGEMENT SCREEN
///
/// Adapter który pozwala ProductsManagementScreen używać zunifikowanej architektury
/// bez zmiany istniejącej implementacji UI
class ProductsManagementAdapter {
  static ProductsManagementAdapter? _instance;
  static ProductsManagementAdapter get instance =>
      _instance ??= ProductsManagementAdapter._();
  ProductsManagementAdapter._();

  final UnifiedDataService _unifiedService = UnifiedDataService.instance;
  bool _initialized = false;

  /// Inicjalizuje adapter
  Future<void> initialize() async {
    if (_initialized) return;
    await _unifiedService.initialize();
    _initialized = true;
  }

  /// 📊 POBIERA PRODUKTY W ZUNIFIKOWANYM FORMACIE
  /// Zwraca dane w formacie zgodnym z ProductsManagementScreen
  Future<ProductsManagementData> getProductsData({
    bool forceRefresh = false,
    bool includeStatistics = true,
    bool useOptimizedMode = true,
    bool showDeduplicatedView = true,
  }) async {
    await initialize();

    // Wybierz poziom danych na podstawie preferencji
    ProductsDataLevel dataLevel;
    if (useOptimizedMode) {
      dataLevel = ProductsDataLevel.optimized;
    } else if (showDeduplicatedView) {
      dataLevel = ProductsDataLevel.deduplicated;
    } else {
      dataLevel = ProductsDataLevel.unified;
    }

    final response = await _unifiedService.getProducts(
      forceRefresh: forceRefresh,
      includeStatistics: includeStatistics,
      dataLevel: dataLevel,
    );

    return ProductsManagementData(
      allProducts: response.products,
      deduplicatedProducts: response.deduplicatedProducts,
      optimizedProducts: response.optimizedProducts,
      statistics: response.statistics,
      dataLevel: response.dataLevel,
      metadata: ProductsManagementMetadata(
        totalCount: response.products.length,
        optimizedCount: response.optimizedProducts.length,
        deduplicatedCount: response.deduplicatedProducts.length,
        loadTime: DateTime.now(),
        fromCache: false, // TODO: Implement cache detection
      ),
    );
  }

  /// 🔍 POBIERA INWESTORÓW DLA PRODUKTU
  /// 🚀 NOWE: Używa ultra-precyzyjnego serwisu dla lepszej dokładności
  Future<ProductInvestorsResult> getProductInvestors({
    required String productId,
    required String productName,
    required String productType,
    bool forceRefresh = false,
  }) async {
    await initialize();

    // Użyj ultra-precyzyjnego serwisu
    final ultraPreciseService = UltraPreciseProductInvestorsService();

    try {
      final ultraResult = await ultraPreciseService.getByProductId(
        productId,
        forceRefresh: forceRefresh,
      );

      if (ultraResult.isSuccess) {
        // Konwertuj UltraPreciseResult na standardowy ProductInvestorsResult
        return ProductInvestorsResult(
          investors: ultraResult.investors,
          totalCount: ultraResult.totalCount,
          statistics: ProductInvestorsStatistics(
            totalCapital: ultraResult.statistics.totalCapital,
            totalInvestments: ultraResult.statistics.totalInvestments,
            averageCapital: ultraResult.statistics.averageCapital,
            activeInvestors: ultraResult.totalCount,
          ),
          searchStrategy: ultraResult.searchStrategy,
          productName: productName,
          productType: productType,
          executionTime: ultraResult.executionTime,
          fromCache: ultraResult.fromCache,
          debugInfo: ProductInvestorsDebugInfo(
            totalInvestmentsScanned: ultraResult.statistics.totalInvestments,
            matchingInvestments: ultraResult.statistics.totalInvestments,
            totalClients: ultraResult.mappingStats.total,
            investmentsByClientGroups: ultraResult.totalCount,
          ),
        );
      }
    } catch (e) {
      print(
        '⚠️ [ProductsManagementAdapter] Ultra-precyzyjny serwis failed: $e',
      );
    }

    // Fallback na standardowy serwis
    return await _unifiedService.getProductInvestors(
      productId: productId,
      productName: productName,
      productType: productType,
      forceRefresh: forceRefresh,
    );
  }

  /// 🔄 KONWERTUJE TYPY PRODUKTÓW
  /// Umożliwia konwersję między różnymi typami bez zmiany UI

  UnifiedProduct convertToUnifiedProduct(dynamic product) {
    if (product is UnifiedProduct) return product;
    if (product is DeduplicatedProduct) {
      return UnifiedTypeConverters.deduplicatedToUnifiedProduct(product);
    }
    if (product is OptimizedProduct) {
      return UnifiedTypeConverters.optimizedToUnifiedProduct(product);
    }
    throw ArgumentError('Nieobsługiwany typ produktu: ${product.runtimeType}');
  }

  DeduplicatedProduct convertToDeduplicatedProduct(dynamic product) {
    if (product is DeduplicatedProduct) return product;
    if (product is OptimizedProduct) {
      return UnifiedTypeConverters.optimizedToDeduplicatedProduct(product);
    }
    if (product is UnifiedProduct) {
      // Konwersja z UnifiedProduct do DeduplicatedProduct wymaga dodatkowej logiki
      return DeduplicatedProduct(
        id: product.id,
        name: product.name,
        productType: product.productType,
        companyId: product.companyId ?? '',
        companyName: product.companyName ?? product.companyId ?? '',
        totalValue: product.investmentAmount,
        totalRemainingCapital:
            product.remainingCapital ?? product.investmentAmount,
        totalInvestments: 1, // Placeholder - wymaga wyliczenia
        uniqueInvestors: 1, // Placeholder - wymaga wyliczenia
        actualInvestorCount: 1, // Placeholder - wymaga wyliczenia
        averageInvestment: product.investmentAmount,
        earliestInvestmentDate: product.createdAt,
        latestInvestmentDate: product.uploadedAt,
        status: product.status,
        interestRate: product.interestRate,
        maturityDate: product.maturityDate,
        originalInvestmentIds: [product.id],
        metadata: product.additionalInfo,
      );
    }
    throw ArgumentError('Nieobsługiwany typ produktu: ${product.runtimeType}');
  }

  /// 📋 FILTRUJE PRODUKTY
  /// Implementuje logikę filtrowania zgodną z ProductsManagementScreen
  List<T> filterProducts<T>(
    List<T> products,
    ProductFilterCriteria criteria,
    String searchText,
  ) {
    List<T> filtered = List.from(products);

    // Filtrowanie tekstowe
    if (searchText.isNotEmpty) {
      filtered = filtered.where((product) {
        final productName = _getProductName(product).toLowerCase();
        final companyName = _getCompanyName(product).toLowerCase();
        final productType = _getProductType(product).toLowerCase();

        return productName.contains(searchText.toLowerCase()) ||
            companyName.contains(searchText.toLowerCase()) ||
            productType.contains(searchText.toLowerCase());
      }).toList();
    }

    // Filtry kryteriów (placeholder - można rozszerzyć)
    // TODO: Implementuj szczegółowe filtry na podstawie criteria

    return filtered;
  }

  /// 🔧 METODY POMOCNICZE

  String _getProductName(dynamic product) {
    if (product is UnifiedProduct) return product.name;
    if (product is DeduplicatedProduct) return product.name;
    if (product is OptimizedProduct) return product.name;
    return '';
  }

  String _getCompanyName(dynamic product) {
    if (product is UnifiedProduct) return product.companyName ?? '';
    if (product is DeduplicatedProduct) return product.companyName;
    if (product is OptimizedProduct) return product.companyName;
    return '';
  }

  String _getProductType(dynamic product) {
    if (product is UnifiedProduct) return product.productType.displayName;
    if (product is DeduplicatedProduct) return product.productType.displayName;
    if (product is OptimizedProduct) return product.productType.displayName;
    return '';
  }

  /// 🎯 RESOLVE PRODUCT ID
  String resolveProductId(
    String productId, {
    String? productName,
    String? companyId,
    UnifiedProductType? productType,
  }) {
    return UnifiedProductIdResolver.resolveProductId(
      productId,
      productName: productName,
      companyId: companyId,
      productType: productType,
    );
  }
}

/// 📊 DANE DLA PRODUCTS MANAGEMENT SCREEN
class ProductsManagementData {
  final List<UnifiedProduct> allProducts;
  final List<DeduplicatedProduct> deduplicatedProducts;
  final List<OptimizedProduct> optimizedProducts;
  final dynamic statistics;
  final ProductsDataLevel dataLevel;
  final ProductsManagementMetadata metadata;

  const ProductsManagementData({
    required this.allProducts,
    required this.deduplicatedProducts,
    required this.optimizedProducts,
    required this.statistics,
    required this.dataLevel,
    required this.metadata,
  });

  /// Zwraca produkty w preferowanym formacie
  List<dynamic> getProductsForDisplay() {
    switch (dataLevel) {
      case ProductsDataLevel.optimized:
        return optimizedProducts;
      case ProductsDataLevel.deduplicated:
        return deduplicatedProducts;
      case ProductsDataLevel.unified:
        return allProducts;
    }
  }
}

/// 📈 METADATA DLA PRODUCTS MANAGEMENT
class ProductsManagementMetadata {
  final int totalCount;
  final int optimizedCount;
  final int deduplicatedCount;
  final DateTime loadTime;
  final bool fromCache;

  const ProductsManagementMetadata({
    required this.totalCount,
    required this.optimizedCount,
    required this.deduplicatedCount,
    required this.loadTime,
    required this.fromCache,
  });
}
