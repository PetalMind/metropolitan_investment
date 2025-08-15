import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/unified_product.dart';
import '../models/investment.dart';
import '../models/product.dart'; // Import dla ProductStatus
import 'base_service.dart';

/// 🚀 OPTIMIZED PRODUCT SERVICE - Korzysta z batch Firebase Functions
/// Zastępuje powolny DeduplicatedProductService
class OptimizedProductService extends BaseService {
  static const String _cacheKeyPrefix = 'optimized_products_v1_';
  
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// 🚀 GŁÓWNA METODA: Pobiera wszystkie produkty jednym wywołaniem Firebase Functions
  Future<OptimizedProductsResult> getAllProductsOptimized({
    bool forceRefresh = false,
    bool includeStatistics = true,
    int maxProducts = 500,
  }) async {
    try {
      final cacheKey = '${_cacheKeyPrefix}all_$maxProducts';

      if (!forceRefresh) {
        // Spróbuj pobrać z cache
        final cached = _getCacheData<OptimizedProductsResult>(cacheKey);
        if (cached != null) {
          if (kDebugMode) {
            print('⚡ [OptimizedProductService] Zwracam z cache');
          }
          return cached;
        }
      }

      if (kDebugMode) {
        print('🚀 [OptimizedProductService] Wywołuję getAllProductsWithInvestors...');
      }

      final optimizedResult = await _fetchFromFirebase(forceRefresh, includeStatistics, maxProducts);

      // Cache na 5 minut - używaj metody z BaseService
      await _setCacheData(cacheKey, optimizedResult);

      if (kDebugMode) {
        print('🎯 [OptimizedProductService] Pobrano ${optimizedResult.products.length} produktów z cache: ${optimizedResult.fromCache}');
      }

      return optimizedResult;

    } catch (e) {
      logError('getAllProductsOptimized', e);
      
      // Fallback: zwróć pusty wynik zamiast crashować
      return OptimizedProductsResult(
        products: [],
        totalProducts: 0,
        totalInvestments: 0,
        statistics: null,
        executionTime: 0,
        fromCache: false,
        error: 'Błąd pobierania: ${e.toString()}',
      );
    }
  }

  Future<OptimizedProductsResult> _fetchFromFirebase(
    bool forceRefresh, 
    bool includeStatistics, 
    int maxProducts
  ) async {
    final stopwatch = Stopwatch()..start();

    // 🚀 KLUCZ: Jedno wywołanie Firebase Functions zamiast setek
    final HttpsCallable callable = _functions.httpsCallable('getAllProductsWithInvestors');
    final HttpsCallableResult result = await callable.call({
      'forceRefresh': forceRefresh,
      'includeStatistics': includeStatistics,
      'maxProducts': maxProducts,
    });

    stopwatch.stop();

    if (kDebugMode) {
      print('✅ [OptimizedProductService] Firebase Functions zakończone w ${stopwatch.elapsedMilliseconds}ms');
    }

    final data = result.data as Map<String, dynamic>;
    return OptimizedProductsResult.fromMap(data);
  }

  /// Cache data using a simple in-memory approach
  static final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};

  Future<void> _setCacheData(String key, OptimizedProductsResult data) async {
    _cache[key] = _CacheEntry(data, DateTime.now().add(const Duration(minutes: 5)));
  }

  T? _getCacheData<T>(String key) {
    final entry = _cache[key] as _CacheEntry?;
    if (entry != null && DateTime.now().isBefore(entry.expiryTime)) {
      return entry.data as T?;
    }
    _cache.remove(key); // Remove expired entry
    return null;
  }

  /// Pobiera produkty określonego typu (filtruje lokalnie)
  Future<List<OptimizedProduct>> getProductsByType(UnifiedProductType type) async {
    try {
      final allProducts = await getAllProductsOptimized();
      return allProducts.products.where((p) => p.productType == type).toList();
    } catch (e) {
      logError('getProductsByType', e);
      return [];
    }
  }

  /// Wyszukuje produkty po nazwie (filtruje lokalnie)
  Future<List<OptimizedProduct>> searchProducts(String query) async {
    try {
      if (query.trim().isEmpty) {
        final allProducts = await getAllProductsOptimized();
        return allProducts.products;
      }

      final allProducts = await getAllProductsOptimized();
      final searchLower = query.toLowerCase();

      return allProducts.products.where((product) {
        return product.name.toLowerCase().contains(searchLower) ||
            product.companyName.toLowerCase().contains(searchLower) ||
            product.productType.displayName.toLowerCase().contains(searchLower);
      }).toList();
    } catch (e) {
      logError('searchProducts', e);
      return [];
    }
  }

  /// Pobiera top produkty według wartości
  Future<List<OptimizedProduct>> getTopProductsByValue({int limit = 10}) async {
    try {
      final allProducts = await getAllProductsOptimized();
      final sorted = List<OptimizedProduct>.from(allProducts.products);
      sorted.sort((a, b) => b.totalValue.compareTo(a.totalValue));
      return sorted.take(limit).toList();
    } catch (e) {
      logError('getTopProductsByValue', e);
      return [];
    }
  }

  /// Pobiera szczegóły produktu (z listy załadowanych produktów)
  Future<OptimizedProduct?> getProductDetails(String productId) async {
    try {
      final allProducts = await getAllProductsOptimized();
      return allProducts.products.where((p) => p.id == productId).firstOrNull;
    } catch (e) {
      logError('getProductDetails', e);
      return null;
    }
  }

  /// Odświeża cache (wymusza pobranie z serwera)
  Future<OptimizedProductsResult> refreshProducts() async {
    return await getAllProductsOptimized(forceRefresh: true);
  }
}

/// Model wyniku z Firebase Functions
class OptimizedProductsResult {
  final List<OptimizedProduct> products;
  final int totalProducts;
  final int totalInvestments;
  final GlobalProductStatistics? statistics;
  final int executionTime;
  final bool fromCache;
  final String? error;

  OptimizedProductsResult({
    required this.products,
    required this.totalProducts,
    required this.totalInvestments,
    this.statistics,
    required this.executionTime,
    required this.fromCache,
    this.error,
  });

  factory OptimizedProductsResult.fromMap(Map<String, dynamic> map) {
    return OptimizedProductsResult(
      products: (map['products'] as List<dynamic>?)
          ?.map((p) => OptimizedProduct.fromMap(p as Map<String, dynamic>))
          .toList() ?? [],
      totalProducts: map['totalProducts'] as int? ?? 0,
      totalInvestments: map['totalInvestments'] as int? ?? 0,
      statistics: map['statistics'] != null 
          ? GlobalProductStatistics.fromMap(map['statistics'] as Map<String, dynamic>)
          : null,
      executionTime: map['executionTime'] as int? ?? 0,
      fromCache: map['fromCache'] as bool? ?? false,
      error: map['error'] as String?,
    );
  }
}

/// Model zoptymalizowanego produktu
class OptimizedProduct {
  final String id;
  final String name;
  final UnifiedProductType productType;
  final String companyName;
  final String companyId;
  final double totalValue;
  final double totalRemainingCapital;
  final int totalInvestments;
  final int uniqueInvestors;
  final int actualInvestorCount;
  final double averageInvestment;
  final double interestRate;
  final DateTime earliestInvestmentDate;
  final DateTime latestInvestmentDate;
  final ProductStatus status;
  final List<OptimizedInvestor> topInvestors;
  final Map<String, dynamic> metadata;

  OptimizedProduct({
    required this.id,
    required this.name,
    required this.productType,
    required this.companyName,
    required this.companyId,
    required this.totalValue,
    required this.totalRemainingCapital,
    required this.totalInvestments,
    required this.uniqueInvestors,
    required this.actualInvestorCount,
    required this.averageInvestment,
    required this.interestRate,
    required this.earliestInvestmentDate,
    required this.latestInvestmentDate,
    required this.status,
    required this.topInvestors,
    required this.metadata,
  });

  factory OptimizedProduct.fromMap(Map<String, dynamic> map) {
    return OptimizedProduct(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      productType: _mapProductType(map['productType'] as String?),
      companyName: map['companyName'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      totalValue: (map['totalValue'] as num?)?.toDouble() ?? 0.0,
      totalRemainingCapital: (map['totalRemainingCapital'] as num?)?.toDouble() ?? 0.0,
      totalInvestments: map['totalInvestments'] as int? ?? 0,
      uniqueInvestors: map['uniqueInvestors'] as int? ?? 0,
      actualInvestorCount: map['actualInvestorCount'] as int? ?? 0,
      averageInvestment: (map['averageInvestment'] as num?)?.toDouble() ?? 0.0,
      interestRate: (map['interestRate'] as num?)?.toDouble() ?? 0.0,
      earliestInvestmentDate: _parseDate(map['earliestInvestmentDate']) ?? DateTime.now(),
      latestInvestmentDate: _parseDate(map['latestInvestmentDate']) ?? DateTime.now(),
      status: _mapProductStatus(map['status'] as String?),
      topInvestors: (map['topInvestors'] as List<dynamic>?)
          ?.map((i) => OptimizedInvestor.fromMap(i as Map<String, dynamic>))
          .toList() ?? [],
      metadata: map['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  static UnifiedProductType _mapProductType(String? type) {
    switch (type?.toLowerCase()) {
      case 'apartments':
        return UnifiedProductType.apartments;
      case 'shares':
        return UnifiedProductType.shares;
      case 'loans':
        return UnifiedProductType.loans;
      case 'bonds':
      default:
        return UnifiedProductType.bonds;
    }
  }

  static ProductStatus _mapProductStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return ProductStatus.active;
      case 'pending':
        return ProductStatus.pending;
      case 'inactive':
      default:
        return ProductStatus.inactive;
    }
  }

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is DateTime) return date;
    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}

/// Model zoptymalizowanego inwestora
class OptimizedInvestor {
  final String clientId;
  final String clientName;
  final int investmentCount;
  final double totalAmount;
  final double totalRemaining;

  OptimizedInvestor({
    required this.clientId,
    required this.clientName,
    required this.investmentCount,
    required this.totalAmount,
    required this.totalRemaining,
  });

  factory OptimizedInvestor.fromMap(Map<String, dynamic> map) {
    return OptimizedInvestor(
      clientId: map['clientId'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      investmentCount: map['investments']?.length ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      totalRemaining: (map['totalRemaining'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Model globalnych statystyk
class GlobalProductStatistics {
  final int totalProducts;
  final double totalValue;
  final double totalRemainingCapital;
  final int totalInvestors;
  final double averageValuePerProduct;
  final double averageInvestorsPerProduct;
  final Map<String, int> productTypeDistribution;
  final List<TopProductSummary> topProductsByValue;

  GlobalProductStatistics({
    required this.totalProducts,
    required this.totalValue,
    required this.totalRemainingCapital,
    required this.totalInvestors,
    required this.averageValuePerProduct,
    required this.averageInvestorsPerProduct,
    required this.productTypeDistribution,
    required this.topProductsByValue,
  });

  factory GlobalProductStatistics.fromMap(Map<String, dynamic> map) {
    return GlobalProductStatistics(
      totalProducts: map['totalProducts'] as int? ?? 0,
      totalValue: (map['totalValue'] as num?)?.toDouble() ?? 0.0,
      totalRemainingCapital: (map['totalRemainingCapital'] as num?)?.toDouble() ?? 0.0,
      totalInvestors: map['totalInvestors'] as int? ?? 0,
      averageValuePerProduct: (map['averageValuePerProduct'] as num?)?.toDouble() ?? 0.0,
      averageInvestorsPerProduct: (map['averageInvestorsPerProduct'] as num?)?.toDouble() ?? 0.0,
      productTypeDistribution: Map<String, int>.from(map['productTypeDistribution'] as Map? ?? {}),
      topProductsByValue: (map['topProductsByValue'] as List<dynamic>?)
          ?.map((t) => TopProductSummary.fromMap(t as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

/// Model podsumowania top produktu
class TopProductSummary {
  final String name;
  final double value;
  final int investors;

  TopProductSummary({
    required this.name,
    required this.value,
    required this.investors,
  });

  factory TopProductSummary.fromMap(Map<String, dynamic> map) {
    return TopProductSummary(
      name: map['name'] as String? ?? '',
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      investors: map['investors'] as int? ?? 0,
    );
  }
}

/// Klasa pomocnicza dla cache
class _CacheEntry {
  final dynamic data;
  final DateTime expiryTime;

  _CacheEntry(this.data, this.expiryTime);
}
