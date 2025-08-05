import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import 'base_service.dart';

/// Serwis do zarządzania produktami przez Firebase Functions
/// Wykorzystuje serwer-side przetwarzanie dla optymalnej wydajności
class FirebaseFunctionsProductsService extends BaseService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  static final Map<String, dynamic> _staticCache = {};
  static final Map<String, DateTime> _staticCacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 2);

  /// Loguje informacje w trybie debug
  void _logInfo(String message) {
    if (kDebugMode) {
      print('[$runtimeType] $message');
    }
  }

  /// Pobiera produkty z zaawansowanym filtrowaniem i paginacją
  ///
  /// [page] - numer strony (zaczyna od 1)
  /// [pageSize] - ilość elementów na stronę (max 250)
  /// [sortBy] - pole sortowania: 'name', 'createdAt'
  /// [sortAscending] - kierunek sortowania
  /// [searchQuery] - wyszukiwanie w nazwie, firmie, typie
  /// [productType] - filtr według typu produktu
  /// [clientId] - filtr produktów powiązanych z klientem
  /// [forceRefresh] - wymusza pominięcie cache
  Future<ProductsResult> getOptimizedProducts({
    int page = 1,
    int pageSize = 250,
    String sortBy = 'name',
    bool sortAscending = true,
    String? searchQuery,
    ProductType? productType,
    String? clientId,
    bool forceRefresh = false,
  }) async {
    try {
      // Sprawdź cache
      final cacheKey =
          'products_${page}_${pageSize}_${sortBy}_'
          '${sortAscending}_${searchQuery}_${productType?.name}_$clientId';

      if (!forceRefresh && _staticCache.containsKey(cacheKey)) {
        final timestamp = _staticCacheTimestamps[cacheKey];
        if (timestamp != null &&
            DateTime.now().difference(timestamp) < _cacheDuration) {
          _logInfo('Zwracam z cache');
          return _staticCache[cacheKey];
        }
      }

      _logInfo('Wywołuję getOptimizedProducts');

      final callable = _functions.httpsCallable('getOptimizedProducts');
      final result = await callable.call({
        'page': page,
        'pageSize': pageSize,
        'sortBy': sortBy,
        'sortAscending': sortAscending,
        'searchQuery': searchQuery,
        'productType': productType?.name,
        'clientId': clientId,
        'forceRefresh': forceRefresh,
      });

      final data = result.data as Map<String, dynamic>;
      final productsResult = ProductsResult.fromMap(data);

      // Cache wyników
      _staticCache[cacheKey] = productsResult;
      _staticCacheTimestamps[cacheKey] = DateTime.now();

      _logInfo('Pobrano ${productsResult.products.length} produktów');
      return productsResult;
    } catch (e) {
      logError('getOptimizedProducts', e);
      throw Exception('Nie udało się pobrać produktów: $e');
    }
  }

  /// Pobiera statystyki produktów
  Future<ProductStatsResult> getProductStats({
    bool forceRefresh = false,
  }) async {
    try {
      // Sprawdź cache
      const cacheKey = 'product_stats';

      if (!forceRefresh && _staticCache.containsKey(cacheKey)) {
        final timestamp = _staticCacheTimestamps[cacheKey];
        if (timestamp != null &&
            DateTime.now().difference(timestamp) < _cacheDuration) {
          _logInfo('Statystyki z cache');
          return _staticCache[cacheKey];
        }
      }

      _logInfo('Wywołuję getProductStats');

      final callable = _functions.httpsCallable('getProductStats');
      final result = await callable.call({'forceRefresh': forceRefresh});

      final data = result.data as Map<String, dynamic>;
      final statsResult = ProductStatsResult.fromMap(data);

      // Cache wyników
      _staticCache[cacheKey] = statsResult;
      _staticCacheTimestamps[cacheKey] = DateTime.now();

      _logInfo('Pobrano statystyki produktów');
      return statsResult;
    } catch (e) {
      logError('getProductStats', e);
      throw Exception('Nie udało się pobrać statystyk produktów: $e');
    }
  }

  /// Czyści cache - przydatne po dodaniu/edycji produktów
  static void clearProductCache() {
    _staticCache.clear();
    _staticCacheTimestamps.clear();
  }
}

/// Wynik zapytania o produkty z paginacją
class ProductsResult {
  final List<Product> products;
  final ProductsStats stats;
  final Map<String, dynamic> metadata;

  ProductsResult({
    required this.products,
    required this.stats,
    required this.metadata,
  });

  factory ProductsResult.fromMap(Map<String, dynamic> map) {
    return ProductsResult(
      products: (map['products'] as List<dynamic>)
          .map((item) => Product.fromMap(item as Map<String, dynamic>))
          .toList(),
      stats: ProductsStats.fromMap(map['stats'] as Map<String, dynamic>),
      metadata: map['metadata'] as Map<String, dynamic>,
    );
  }
}

/// Statystyki produktów z paginacją
class ProductsStats {
  final int totalProducts;
  final int currentPage;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final List<String> productTypes;

  ProductsStats({
    required this.totalProducts,
    required this.currentPage,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.productTypes,
  });

  factory ProductsStats.fromMap(Map<String, dynamic> map) {
    return ProductsStats(
      totalProducts: map['totalProducts'] as int,
      currentPage: map['currentPage'] as int,
      totalPages: map['totalPages'] as int,
      hasNextPage: map['hasNextPage'] as bool,
      hasPreviousPage: map['hasPreviousPage'] as bool,
      productTypes: List<String>.from(map['productTypes'] as List<dynamic>),
    );
  }
}

/// Wynik statystyk produktów
class ProductStatsResult {
  final int totalProducts;
  final List<ProductTypeBreakdown> productTypeBreakdown;
  final List<ProductInvestmentStats> topProductsByInvestments;
  final Map<String, dynamic> metadata;

  ProductStatsResult({
    required this.totalProducts,
    required this.productTypeBreakdown,
    required this.topProductsByInvestments,
    required this.metadata,
  });

  factory ProductStatsResult.fromMap(Map<String, dynamic> map) {
    return ProductStatsResult(
      totalProducts: map['totalProducts'] as int,
      productTypeBreakdown: (map['productTypeBreakdown'] as List<dynamic>)
          .map(
            (item) =>
                ProductTypeBreakdown.fromMap(item as Map<String, dynamic>),
          )
          .toList(),
      topProductsByInvestments:
          (map['topProductsByInvestments'] as List<dynamic>)
              .map(
                (item) => ProductInvestmentStats.fromMap(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
      metadata: map['metadata'] as Map<String, dynamic>,
    );
  }
}

/// Statystyki według typu produktu
class ProductTypeBreakdown {
  final String type;
  final int count;
  final List<String> products;

  ProductTypeBreakdown({
    required this.type,
    required this.count,
    required this.products,
  });

  factory ProductTypeBreakdown.fromMap(Map<String, dynamic> map) {
    return ProductTypeBreakdown(
      type: map['type'] as String,
      count: map['count'] as int,
      products: List<String>.from(map['products'] as List<dynamic>),
    );
  }
}

/// Statystyki inwestycji według produktu
class ProductInvestmentStats {
  final String productName;
  final int investmentCount;
  final double totalValue;
  final double remainingCapital;

  ProductInvestmentStats({
    required this.productName,
    required this.investmentCount,
    required this.totalValue,
    required this.remainingCapital,
  });

  factory ProductInvestmentStats.fromMap(Map<String, dynamic> map) {
    return ProductInvestmentStats(
      productName: map['productName'] as String,
      investmentCount: map['investmentCount'] as int,
      totalValue: (map['totalValue'] as num).toDouble(),
      remainingCapital: (map['remainingCapital'] as num).toDouble(),
    );
  }
}
