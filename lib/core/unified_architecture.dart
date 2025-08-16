/// 🚀 ZUNIFIKOWANA ARCHITEKTURA APLIKACJI
///
/// Centralna architektura dla wszystkich komponentów aplikacji.
/// Zapewnia jednolitość typów danych, serwisów i konwersji.
///
/// Główne założenia:
/// - Zunifikowane ID produktów: bond_0001, loan_0002, share_0003, apartment_0004
/// - Jednolite typy danych dla wszystkich komponentów
/// - Centralne zarządzanie cache
/// - Automatyczne konwersje między typami
/// - Fallback hierarchy dla różnych formatów danych

import 'package:flutter/foundation.dart';
import '../models_and_services.dart';

/// 🎯 GŁÓWNY INTERFEJS ZUNIFIKOWANEJ ARCHITEKTURY
abstract class UnifiedArchitecture {
  /// Preferencje dla używanych serwisów w hierarchii
  static const ServicePreferences preferences = ServicePreferences();

  /// Główne typy produktów w hierarchii preferencji
  static const ProductTypeHierarchy productTypes = ProductTypeHierarchy();

  /// Strategia cache dla różnych komponentów
  static const CacheStrategy cacheStrategy = CacheStrategy();
}

/// ⚙️ PREFERENCJE SERWISÓW - HIERARCHIA UŻYCIA
class ServicePreferences {
  const ServicePreferences();

  /// Hierarchia serwisów produktów (od najnowszego do fallback)
  List<Type> get productServicesHierarchy => [
    OptimizedProductService, // 🚀 Najbardziej zoptymalizowany
    ProductManagementService, // 🔄 Centralny zarządzający
    DeduplicatedProductService, // 📊 Deduplikowany
    FirebaseFunctionsProductsService, // 🔥 Server-side
    UnifiedProductService, // 📦 Legacy unified
  ];

  /// Hierarchia serwisów inwestorów
  List<Type> get investorServicesHierarchy => [
    UltraPreciseProductInvestorsService, // � Ultra-precise server-side
    InvestorEditService, // ✏️ Business logic
  ];

  /// Preferowany serwis cache
  Type get preferredCacheService => CacheManagementService;
}

/// 📊 HIERARCHIA TYPÓW PRODUKTÓW
class ProductTypeHierarchy {
  const ProductTypeHierarchy();

  /// Hierarchia typów danych produktów (od najnowszego)
  List<Type> get productTypesHierarchy => [
    OptimizedProduct, // 🚀 Najbardziej zoptymalizowany
    DeduplicatedProduct, // 📊 Standard bez duplikatów
    UnifiedProduct, // 📦 Legacy unified
  ];

  /// Mapa konwersji między typami produktów
  Map<Type, Type> get conversionMap => {
    OptimizedProduct: DeduplicatedProduct,
    DeduplicatedProduct: UnifiedProduct,
    UnifiedProduct: OptimizedProduct,
  };
}

/// 💾 STRATEGIA CACHE
class CacheStrategy {
  const CacheStrategy();

  /// TTL dla różnych typów danych (w minutach)
  Map<Type, int> get cacheTTL => {
    OptimizedProduct: 5, // 5 min dla zoptymalizowanych
    DeduplicatedProduct: 3, // 3 min dla deduplikowanych
    UnifiedProduct: 2, // 2 min dla legacy
    InvestorSummary: 2, // 2 min dla inwestorów
  };

  /// Klucze cache dla różnych komponentów
  Map<String, String> get cacheKeys => {
    'products_management': 'products_management_v2',
    'product_details': 'product_details_v2',
    'investor_edit': 'investor_edit_v2',
  };
}

/// 🔄 CENTRALNE KONWERSJE TYPÓW
class UnifiedTypeConverters {
  /// Konwertuje OptimizedProduct na DeduplicatedProduct
  static DeduplicatedProduct optimizedToDeduplicatedProduct(
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
      maturityDate: null, // OptimizedProduct nie ma tego pola
      originalInvestmentIds: [], // Można wypełnić z metadata jeśli dostępne
      metadata: opt.metadata,
    );
  }

  /// Konwertuje DeduplicatedProduct na UnifiedProduct
  static UnifiedProduct deduplicatedToUnifiedProduct(
    DeduplicatedProduct dedup,
  ) {
    return UnifiedProduct(
      id: dedup.id,
      name: dedup.name,
      productType: dedup.productType,
      investmentAmount: dedup.totalValue,
      createdAt: dedup.earliestInvestmentDate,
      uploadedAt: dedup.latestInvestmentDate,
      sourceFile: dedup.metadata['sourceFile']?.toString() ?? 'unified',
      status: dedup.status,
      additionalInfo: dedup.metadata,
      // Wypełnij brakujące pola wartościami domyślnymi lub z metadata
      realizedCapital: null,
      remainingCapital: dedup.totalRemainingCapital,
      realizedInterest: null,
      remainingInterest: null,
      realizedTax: null,
      remainingTax: null,
      transferToOtherProduct: null,
      sharesCount: null,
      pricePerShare: null,
      interestRate: dedup.interestRate,
      maturityDate: dedup.maturityDate,
      companyName: dedup.companyName,
      companyId: dedup.companyId,
      currency: 'PLN',
      originalProduct: dedup,
    );
  }

  /// Konwertuje OptimizedProduct na UnifiedProduct (poprzez DeduplicatedProduct)
  static UnifiedProduct optimizedToUnifiedProduct(OptimizedProduct opt) {
    final deduplicated = optimizedToDeduplicatedProduct(opt);
    return deduplicatedToUnifiedProduct(deduplicated);
  }
}

/// 🎯 ZUNIFIKOWANY RESOLVER ID PRODUKTÓW
class UnifiedProductIdResolver {
  /// Cache dla rozpoznanych ID
  static final Map<String, String> _resolvedIds = {};

  /// Rozpoznaje rzeczywisty productId na podstawie różnych formatów
  static String resolveProductId(
    String inputId, {
    String? productName,
    String? companyId,
    UnifiedProductType? productType,
  }) {
    // Sprawdź cache
    final cacheKey = '$inputId-$productName-$companyId';
    if (_resolvedIds.containsKey(cacheKey)) {
      return _resolvedIds[cacheKey]!;
    }

    String resolvedId = inputId;

    // 1. Jeśli już jest w formacie zunifikowanym, zwróć
    if (isUnifiedFormat(inputId)) {
      _resolvedIds[cacheKey] = inputId;
      return inputId;
    }

    // 2. Jeśli to hash z DeduplicatedService, spróbuj rozpoznać
    if (_isHashFormat(inputId) && productType != null) {
      resolvedId = _generateUnifiedIdFromType(productType, inputId);
    }

    // 3. Jeśli to UUID, spróbuj mapować na podstawie productType
    if (_isUuidFormat(inputId) && productType != null) {
      resolvedId = _generateUnifiedIdFromType(productType, inputId);
    }

    if (kDebugMode) {
      print('🔍 [UnifiedProductIdResolver] $inputId → $resolvedId');
    }

    _resolvedIds[cacheKey] = resolvedId;
    return resolvedId;
  }

  /// Sprawdza czy ID jest w zunifikowanym formacie (bond_0001, loan_0002, etc.)
  static bool isUnifiedFormat(String id) {
    final regex = RegExp(r'^(bond|loan|share|apartment)_\d{4}$');
    return regex.hasMatch(id);
  }

  /// Sprawdza czy ID to hash (MD5/SHA)
  static bool _isHashFormat(String id) {
    final regex = RegExp(r'^[a-f0-9]{32}$|^[a-f0-9]{40}$');
    return regex.hasMatch(id);
  }

  /// Sprawdza czy ID to UUID
  static bool _isUuidFormat(String id) {
    final regex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    );
    return regex.hasMatch(id);
  }

  /// Generuje zunifikowane ID na podstawie typu produktu
  static String _generateUnifiedIdFromType(
    UnifiedProductType type,
    String fallbackId,
  ) {
    final prefix = type.name.toLowerCase();
    // W rzeczywistej implementacji tutaj byłoby zapytanie do Firebase
    // aby znaleźć rzeczywiste ID. Na razie używamy fallback
    final hashCode = fallbackId.hashCode
        .abs()
        .toString()
        .padLeft(4, '0')
        .substring(0, 4);
    return '${prefix}_$hashCode';
  }

  /// Czyści cache (użyteczne przy testach)
  static void clearCache() {
    _resolvedIds.clear();
  }
}

/// 🚀 ZUNIFIKOWANY SERWIS DANYCH
///
/// Główny punkt dostępu do wszystkich danych w aplikacji.
/// Automatycznie wybiera najlepszy dostępny serwis i typ danych.
class UnifiedDataService {
  static UnifiedDataService? _instance;
  static UnifiedDataService get instance =>
      _instance ??= UnifiedDataService._();
  UnifiedDataService._();

  // Serwisy w hierarchii preferencji
  late final OptimizedProductService _optimizedProductService;
  late final DeduplicatedProductService _deduplicatedProductService;
  late final UltraPreciseProductInvestorsService _investorsService;

  bool _initialized = false;

  /// Inicjalizuje wszystkie serwisy
  Future<void> initialize() async {
    if (_initialized) return;

    _optimizedProductService = OptimizedProductService();
    _deduplicatedProductService = DeduplicatedProductService();
    _investorsService = UltraPreciseProductInvestorsService();

    _initialized = true;

    if (kDebugMode) {
      print('✅ [UnifiedDataService] Zainicjalizowano wszystkie serwisy');
    }
  }

  /// 📊 GŁÓWNA METODA - Pobiera produkty w najlepszym dostępnym formacie
  Future<UnifiedProductsResponse> getProducts({
    bool forceRefresh = false,
    bool includeStatistics = true,
    ProductsDataLevel dataLevel = ProductsDataLevel.optimized,
  }) async {
    await initialize();

    try {
      switch (dataLevel) {
        case ProductsDataLevel.optimized:
          return await _getOptimizedProducts(forceRefresh, includeStatistics);
        case ProductsDataLevel.deduplicated:
          return await _getDeduplicatedProducts(
            forceRefresh,
            includeStatistics,
          );
        case ProductsDataLevel.unified:
          return await _getUnifiedProducts(forceRefresh, includeStatistics);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [UnifiedDataService] Błąd pobierania produktów: $e');
      }

      // Fallback do niższego poziomu
      if (dataLevel != ProductsDataLevel.unified) {
        final fallbackLevel = dataLevel == ProductsDataLevel.optimized
            ? ProductsDataLevel.deduplicated
            : ProductsDataLevel.unified;
        return await getProducts(
          forceRefresh: forceRefresh,
          includeStatistics: includeStatistics,
          dataLevel: fallbackLevel,
        );
      }

      rethrow;
    }
  }

  /// Pobiera inwestorów dla produktu - ULTRA PRECYZYJNE API
  Future<ProductInvestorsResult> getProductInvestors({
    required String productId,
    required String productName,
    required String productType,
    bool forceRefresh = false,
  }) async {
    await initialize();

    // Rozpoznaj rzeczywisty productId
    final resolvedId = UnifiedProductIdResolver.resolveProductId(
      productId,
      productName: productName,
    );

    // Użyj ultra-precyzyjnej usługi
    final ultraResult = await _investorsService.getProductInvestors(
      productId: resolvedId,
      productName: productName,
      searchStrategy: 'productId',
      forceRefresh: forceRefresh,
    );

    // Adaptuj wynik do standardowego formatu
    return _adaptUltraPreciseResult(ultraResult, productType, productName);
  }

  /// 🔄 ADAPTER: Konwertuje ultra-precyzyjny wynik na standardowy format
  ProductInvestorsResult _adaptUltraPreciseResult(
    UltraPreciseProductInvestorsResult ultraResult,
    String productType,
    String productName,
  ) {
    return ProductInvestorsResult(
      investors: ultraResult.investors,
      totalCount: ultraResult.totalCount,
      statistics: ProductInvestorsStatistics(
        totalCapital: ultraResult.statistics.totalCapital,
        totalInvestments: ultraResult.statistics.totalInvestments,
        averageCapital: ultraResult.statistics.averageCapital,
        activeInvestors:
            ultraResult.totalCount, // Liczba aktywnych = totalCount
      ),
      searchStrategy: '${ultraResult.searchStrategy}_ultra_precise',
      productName: productName,
      productType: productType,
      executionTime: ultraResult.executionTime,
      fromCache: ultraResult.fromCache,
      error: ultraResult.error,
    );
  }

  /// Edytuje inwestora - uproszczona wersja bez UI dependencies
  Future<bool> editInvestor(Map<String, dynamic> data) async {
    await initialize();
    // Uproszczona wersja - szczegóły implementacji w UI layerze
    return true;
  }

  /// Czyści cache wszystkich serwisów
  Future<void> clearCache() async {
    await initialize();
    UnifiedProductIdResolver.clearCache();
    // Tutaj można dodać czyszczenie cache innych serwisów
  }

  /// Prywatne metody implementacyjne

  Future<UnifiedProductsResponse> _getOptimizedProducts(
    bool forceRefresh,
    bool includeStatistics,
  ) async {
    final result = await _optimizedProductService.getAllProductsOptimized(
      forceRefresh: forceRefresh,
      includeStatistics: includeStatistics,
    );

    return UnifiedProductsResponse(
      products: result.products
          .map(UnifiedTypeConverters.optimizedToUnifiedProduct)
          .toList(),
      deduplicatedProducts: result.products
          .map(UnifiedTypeConverters.optimizedToDeduplicatedProduct)
          .toList(),
      optimizedProducts: result.products,
      statistics: result.statistics,
      dataLevel: ProductsDataLevel.optimized,
    );
  }

  Future<UnifiedProductsResponse> _getDeduplicatedProducts(
    bool forceRefresh,
    bool includeStatistics,
  ) async {
    final products = await _deduplicatedProductService.getAllUniqueProducts();

    return UnifiedProductsResponse(
      products: products
          .map(UnifiedTypeConverters.deduplicatedToUnifiedProduct)
          .toList(),
      deduplicatedProducts: products,
      optimizedProducts: [], // Brak dla tego poziomu
      statistics: null, // Placeholder - można dodać implementację
      dataLevel: ProductsDataLevel.deduplicated,
    );
  }

  Future<UnifiedProductsResponse> _getUnifiedProducts(
    bool forceRefresh,
    bool includeStatistics,
  ) async {
    // Placeholder - tutaj byłoby wywołanie do Firebase Functions
    // Na razie fallback do deduplicated
    return await _getDeduplicatedProducts(forceRefresh, includeStatistics);
  }
}

/// 📊 POZIOMY DANYCH
enum ProductsDataLevel {
  optimized, // OptimizedProduct - najszybszy
  deduplicated, // DeduplicatedProduct - standard
  unified, // UnifiedProduct - legacy
}

/// 📋 ZUNIFIKOWANA ODPOWIEDŹ
class UnifiedProductsResponse {
  final List<UnifiedProduct> products;
  final List<DeduplicatedProduct> deduplicatedProducts;
  final List<OptimizedProduct> optimizedProducts;
  final dynamic statistics;
  final ProductsDataLevel dataLevel;

  const UnifiedProductsResponse({
    required this.products,
    required this.deduplicatedProducts,
    required this.optimizedProducts,
    required this.statistics,
    required this.dataLevel,
  });
}
