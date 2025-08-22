import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/unified_product.dart';
import 'base_service.dart';

/// Serwis do zarządzania produktami przez Firebase Functions
/// Wykorzystuje server-side processing dla optymalizacji wydajności
///
/// UWAGA: Pobiera dane TYLKO z kolekcji 'investments'
/// Stare kolekcje (bonds, shares, loans, apartments, products) są deprecated
class FirebaseFunctionsProductsService extends BaseService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  /// TEST: Sprawdza dostęp do głównej kolekcji investments
  Future<void> testDirectFirestoreAccess() async {
    try {
      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductsService] 🧪 SPRAWDZANIE DOSTĘPU DO KOLEKCJI INVESTMENTS',
        );
      }

      final firestore = FirebaseFirestore.instance;

      // Sprawdź tylko kolekcję 'investments' - jedyne źródło danych
      final investmentsSnapshot = await firestore
          .collection('investments')
          .limit(5)
          .get();

      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductsService] Kolekcja "investments": ${investmentsSnapshot.docs.length} dokumentów',
        );

      
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductsService] ❌ Błąd dostępu do Firestore: $e',
        );
      }
    }
  }

  /// TEST: Testuje połączenie z Firebase Functions
  Future<void> testConnection() async {
    try {
      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductsService] 🧪 ROZPOCZYNAM TEST POŁĄCZENIA',
        );
        print(
          '[FirebaseFunctionsProductsService] Region: ${_functions.app.options.projectId} -> europe-west1',
        );
      }

      // Wywołaj prostą funkcję testową
      final callable = _functions.httpsCallable('getUnifiedProducts');
      final result = await callable.call({
        'page': 1,
        'pageSize': 5,
        'forceRefresh': true,
      });

      if (kDebugMode) {
        print('[FirebaseFunctionsProductsService] ✅ Test zakończony pomyślnie');
        print(
          '[FirebaseFunctionsProductsService] Response type: ${result.data.runtimeType}',
        );

        if (result.data is Map) {
          final data = result.data as Map<String, dynamic>;
          print(
            '[FirebaseFunctionsProductsService] Response keys: ${data.keys.toList()}',
          );

          if (data.containsKey('products')) {
            final products = data['products'] as List?;
            print(
              '[FirebaseFunctionsProductsService] Products count: ${products?.length ?? 0}',
            );
          }

          if (data.containsKey('metadata')) {
            final metadata = data['metadata'] as Map?;
            print('[FirebaseFunctionsProductsService] Metadata: $metadata');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FirebaseFunctionsProductsService] ❌ Test nie powiódł się:');
        print('[FirebaseFunctionsProductsService] Error: $e');
      }
      rethrow;
    }
  }

  /// Pobiera zunifikowane produkty ze wszystkich kolekcji przez Firebase Functions
  /// W przypadku błędu CORS używa fallback do bezpośredniego pobierania z Firestore
  Future<UnifiedProductsResult> getUnifiedProducts({
    int page = 1,
    int pageSize = 250,
    String sortBy = 'createdAt',
    bool sortAscending = false,
    String? searchQuery,
    List<String>? productTypes,
    List<String>? statuses,
    double? minInvestmentAmount,
    double? maxInvestmentAmount,
    DateTime? createdAfter,
    DateTime? createdBefore,
    String? companyName,
    double? minInterestRate,
    double? maxInterestRate,
    bool forceRefresh = false,
  }) async {
    try {
      return await _getUnifiedProductsFromFirebaseFunctions(
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        sortAscending: sortAscending,
        searchQuery: searchQuery,
        productTypes: productTypes,
        statuses: statuses,
        minInvestmentAmount: minInvestmentAmount,
        maxInvestmentAmount: maxInvestmentAmount,
        createdAfter: createdAfter,
        createdBefore: createdBefore,
        companyName: companyName,
        minInterestRate: minInterestRate,
        maxInterestRate: maxInterestRate,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductsService] ⚠️ Firebase Functions failed, using Firestore fallback: $e',
        );
      }

      // Fallback: Pobierz dane bezpośrednio z Firestore
      return await _getUnifiedProductsFromFirestore(
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        sortAscending: sortAscending,
        searchQuery: searchQuery,
        productTypes: productTypes,
        statuses: statuses,
        minInvestmentAmount: minInvestmentAmount,
        maxInvestmentAmount: maxInvestmentAmount,
      );
    }
  }

  /// Pobiera produkty przez Firebase Functions (główna metoda)
  Future<UnifiedProductsResult> _getUnifiedProductsFromFirebaseFunctions({
    int page = 1,
    int pageSize = 250,
    String sortBy = 'createdAt',
    bool sortAscending = false,
    String? searchQuery,
    List<String>? productTypes,
    List<String>? statuses,
    double? minInvestmentAmount,
    double? maxInvestmentAmount,
    DateTime? createdAfter,
    DateTime? createdBefore,
    String? companyName,
    double? minInterestRate,
    double? maxInterestRate,
    bool forceRefresh = false,
  }) async {
    try {
      // Przygotuj parametry dla funkcji Firebase
      final parameters = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        'sortBy': sortBy,
        'sortAscending': sortAscending,
        'forceRefresh': forceRefresh,
      };

      // Dodaj opcjonalne parametry
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        parameters['searchQuery'] = searchQuery.trim();
      }
      if (productTypes != null && productTypes.isNotEmpty) {
        parameters['productTypes'] = productTypes;
      }
      if (statuses != null && statuses.isNotEmpty) {
        parameters['statuses'] = statuses;
      }
      if (minInvestmentAmount != null) {
        parameters['minInvestmentAmount'] = minInvestmentAmount;
      }
      if (maxInvestmentAmount != null) {
        parameters['maxInvestmentAmount'] = maxInvestmentAmount;
      }
      if (createdAfter != null) {
        parameters['createdAfter'] = createdAfter.toIso8601String();
      }
      if (createdBefore != null) {
        parameters['createdBefore'] = createdBefore.toIso8601String();
      }
      if (companyName != null && companyName.trim().isNotEmpty) {
        parameters['companyName'] = companyName.trim();
      }
      if (minInterestRate != null) {
        parameters['minInterestRate'] = minInterestRate;
      }
      if (maxInterestRate != null) {
        parameters['maxInterestRate'] = maxInterestRate;
      }

      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductsService] Wywołuję getUnifiedProducts z parametrami: $parameters',
        );
        print(
          '[FirebaseFunctionsProductsService] Funkcja: getUnifiedProducts, region: europe-west1',
        );
      }

      // Wywołaj funkcję Firebase
      final callable = _functions.httpsCallable('getUnifiedProducts');
      final result = await callable.call(parameters);

      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductsService] Otrzymano odpowiedź z Firebase Functions',
        );
        print(
          '[FirebaseFunctionsProductsService] result.data type: ${result.data.runtimeType}',
        );
        print(
          '[FirebaseFunctionsProductsService] result.data keys: ${result.data is Map ? (result.data as Map).keys.toList() : 'NIE MAP'}',
        );
      }

      if (result.data == null) {
        throw Exception('Brak danych w odpowiedzi Firebase Functions');
      }

      final data = result.data as Map<String, dynamic>;

      // Konwertuj produkty z odpowiedzi
      final productsData = data['products'] as List<dynamic>?;
      if (productsData == null) {
        throw Exception('Brak listy produktów w odpowiedzi');
      }

      final products = productsData
          .map(
            (productData) => UnifiedProduct.fromServerData(
              productData as Map<String, dynamic>,
            ),
          )
          .toList();

      // Parsuj metadane paginacji
      final paginationData = data['pagination'] as Map<String, dynamic>?;
      final pagination = paginationData != null
          ? PaginationInfo.fromMap(paginationData)
          : PaginationInfo.empty();

      // Parsuj metadane
      final metadataData = data['metadata'] as Map<String, dynamic>?;
      final metadata = metadataData != null
          ? UnifiedProductsMetadata.fromMap(metadataData)
          : UnifiedProductsMetadata.empty();

      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductsService] Otrzymano ${products.length} produktów',
        );
      }

      return UnifiedProductsResult(
        products: products,
        pagination: pagination,
        metadata: metadata,
      );
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        print('[FirebaseFunctionsProductsService] Firebase Functions błąd:');
        print('[FirebaseFunctionsProductsService] Kod: ${e.code}');
        print('[FirebaseFunctionsProductsService] Wiadomość: ${e.message}');
        print('[FirebaseFunctionsProductsService] Szczegóły: ${e.details}');
      }

      // Lepszy komunikat dla użytkownika
      String userMessage = 'Błąd pobierania produktów';
      if (e.code == 'cors') {
        userMessage = 'Błąd CORS - sprawdź konfigurację serwera';
      } else if (e.code == 'unavailable') {
        userMessage =
            'Firebase Functions niedostępne - spróbuj ponownie później';
      } else if (e.code == 'internal') {
        userMessage =
            'Błąd wewnętrzny serwera - skontaktuj się z administratorem';
      }

      throw Exception('$userMessage: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductsService] Błąd w getUnifiedProducts: $e',
        );
      }
      rethrow;
    }
  }

  /// Pobiera statystyki produktów przez Firebase Functions
  Future<ProductStatistics> getProductStatistics({
    bool forceRefresh = false,
  }) async {
    try {
      return await _getProductStatisticsFromFirebaseFunctions(
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductsService] ⚠️ Statistics Firebase Functions failed, using Firestore fallback: $e',
        );
      }

      // Fallback: Zwróć podstawowe statystyki
      return _getBasicStatisticsFromFirestore();
    }
  }

  /// Pobiera statystyki przez Firebase Functions (główna metoda)
  Future<ProductStatistics> _getProductStatisticsFromFirebaseFunctions({
    bool forceRefresh = false,
  }) async {
    try {
      final parameters = <String, dynamic>{'forceRefresh': forceRefresh};

      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductsService] Wywołuję getUnifiedProductStatistics',
        );
      }

      final callable = _functions.httpsCallable('getUnifiedProductStatistics');
      final result = await callable.call(parameters);

      if (result.data == null) {
        throw Exception('Brak danych w odpowiedzi Firebase Functions');
      }

      final data = result.data as Map<String, dynamic>;

      return ProductStatistics.fromServerData(data);
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductsService] Firebase Functions błąd (statystyki):',
        );
        print('[FirebaseFunctionsProductsService] Kod: ${e.code}');
        print('[FirebaseFunctionsProductsService] Wiadomość: ${e.message}');
        print('[FirebaseFunctionsProductsService] Szczegóły: ${e.details}');
      }

      String userMessage = 'Błąd pobierania statystyk';
      if (e.code == 'cors') {
        userMessage = 'Błąd CORS - sprawdź konfigurację serwera';
      } else if (e.code == 'unavailable') {
        userMessage =
            'Firebase Functions niedostępne - spróbuj ponownie później';
      } else if (e.code == 'internal') {
        userMessage =
            'Błąd wewnętrzny serwera - skontaktuj się z administratorem';
      }

      throw Exception('$userMessage: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductsService] Błąd w getProductStatistics: $e',
        );
      }
      rethrow;
    }
  }

  /// Wyszukuje produkty - wykorzystuje główną funkcję z filtrem
  Future<UnifiedProductsResult> searchProducts(
    String searchQuery, {
    int page = 1,
    int pageSize = 100,
    String sortBy = 'name',
    bool sortAscending = true,
  }) async {
    return getUnifiedProducts(
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      sortAscending: sortAscending,
      searchQuery: searchQuery,
    );
  }

  /// Pobiera produkty określonego typu
  Future<UnifiedProductsResult> getProductsByType(
    String productType, {
    int page = 1,
    int pageSize = 250,
    String sortBy = 'name',
    bool sortAscending = true,
  }) async {
    return getUnifiedProducts(
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      sortAscending: sortAscending,
      productTypes: [productType],
    );
  }

  /// Pobiera najnowsze produkty
  Future<UnifiedProductsResult> getRecentProducts({
    int days = 30,
    int pageSize = 50,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    return getUnifiedProducts(
      pageSize: pageSize,
      sortBy: 'createdAt',
      sortAscending: false,
      createdAfter: cutoffDate,
    );
  }

  /// Pobiera produkty z określonym oprocentowaniem
  Future<UnifiedProductsResult> getProductsByInterestRate({
    double? minRate,
    double? maxRate,
    int page = 1,
    int pageSize = 250,
  }) async {
    return getUnifiedProducts(
      page: page,
      pageSize: pageSize,
      minInterestRate: minRate,
      maxInterestRate: maxRate,
      sortBy: 'interestRate',
      sortAscending: false,
    );
  }

  /// Pobiera produkty określonej spółki
  Future<UnifiedProductsResult> getProductsByCompany(
    String companyName, {
    int page = 1,
    int pageSize = 250,
  }) async {
    return getUnifiedProducts(
      page: page,
      pageSize: pageSize,
      companyName: companyName,
      sortBy: 'name',
      sortAscending: true,
    );
  }

  /// Odświeża cache na serwerze
  Future<void> refreshCache() async {
    try {
      if (kDebugMode) {
        print('[FirebaseFunctionsProductsService] Odświeżam cache na serwerze');
      }

      // Wymuś odświeżenie cache przez pobranie danych
      await getUnifiedProducts(forceRefresh: true, pageSize: 1);
      await getProductStatistics(forceRefresh: true);

      if (kDebugMode) {
        print('[FirebaseFunctionsProductsService] Cache odświeżony');
      }
    } catch (e) {
      logError('refreshCache', e);
      rethrow;
    }
  }
}

/// Klasa reprezentująca wynik zapytania o produkty
class UnifiedProductsResult {
  final List<UnifiedProduct> products;
  final PaginationInfo pagination;
  final UnifiedProductsMetadata metadata;

  const UnifiedProductsResult({
    required this.products,
    required this.pagination,
    required this.metadata,
  });

  bool get isEmpty => products.isEmpty;
  bool get isNotEmpty => products.isNotEmpty;
  int get length => products.length;
}

/// Informacje o paginacji
class PaginationInfo {
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  const PaginationInfo({
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginationInfo.fromMap(Map<String, dynamic> map) {
    return PaginationInfo(
      currentPage: map['currentPage'] ?? 1,
      pageSize: map['pageSize'] ?? 250,
      totalItems: map['totalItems'] ?? 0,
      totalPages: map['totalPages'] ?? 0,
      hasNext: map['hasNext'] ?? false,
      hasPrevious: map['hasPrevious'] ?? false,
    );
  }

  factory PaginationInfo.empty() {
    return const PaginationInfo(
      currentPage: 1,
      pageSize: 0,
      totalItems: 0,
      totalPages: 0,
      hasNext: false,
      hasPrevious: false,
    );
  }
}

/// Metadane zapytania
class UnifiedProductsMetadata {
  final DateTime timestamp;
  final int executionTime;
  final bool cacheUsed;
  final Map<String, dynamic> filters;

  const UnifiedProductsMetadata({
    required this.timestamp,
    required this.executionTime,
    required this.cacheUsed,
    required this.filters,
  });

  factory UnifiedProductsMetadata.fromMap(Map<String, dynamic> map) {
    return UnifiedProductsMetadata(
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      executionTime: map['executionTime'] ?? 0,
      cacheUsed: map['cacheUsed'] ?? false,
      filters: Map<String, dynamic>.from(map['filters'] ?? {}),
    );
  }

  factory UnifiedProductsMetadata.empty() {
    return UnifiedProductsMetadata(
      timestamp: DateTime.now(),
      executionTime: 0,
      cacheUsed: false,
      filters: const {},
    );
  }
}

/// Rozszerzone statystyki produktów z danymi serwera
class ProductStatistics {
  // Podstawowe statystyki
  final int totalProducts;
  final int totalInvestments; // 🚀 DODANE
  final int uniqueInvestors; // 🚀 DODANE
  final int activeProducts;
  final int inactiveProducts;
  final double totalInvestmentAmount;
  final double totalRemainingCapital; // 🚀 DODANE dla optymalizacji
  final double totalValue;
  final double averageInvestmentAmount;
  final double averageValue;
  final double profitLoss;
  final double profitLossPercentage;
  final double activePercentage;

  // Rozkład według typu
  final List<ProductTypeStats> typeDistribution;

  // Rozkład według statusu
  final List<ProductStatusStats> statusDistribution;

  // Najbardziej wartościowy typ
  final String mostValuableType;
  final double mostValuableTypeValue;

  // Top spółki
  final List<CompanyStats> topCompaniesByValue;

  // Statystyki oprocentowania
  final InterestRateStats interestRateStats;

  // Statystyki czasowe
  final RecentProductsStats recentProducts;

  // Metadane
  final DateTime timestamp;
  final bool cacheUsed;

  const ProductStatistics({
    required this.totalProducts,
    required this.totalInvestments, // 🚀 DODANE
    required this.uniqueInvestors, // 🚀 DODANE
    required this.activeProducts,
    required this.inactiveProducts,
    required this.totalInvestmentAmount,
    required this.totalRemainingCapital, // 🚀 DODANE
    required this.totalValue,
    required this.averageInvestmentAmount,
    required this.averageValue,
    required this.profitLoss,
    required this.profitLossPercentage,
    required this.activePercentage,
    required this.typeDistribution,
    required this.statusDistribution,
    required this.mostValuableType,
    required this.mostValuableTypeValue,
    required this.topCompaniesByValue,
    required this.interestRateStats,
    required this.recentProducts,
    required this.timestamp,
    required this.cacheUsed,
  });

  factory ProductStatistics.fromServerData(Map<String, dynamic> data) {
    return ProductStatistics(
      totalProducts: data['totalProducts'] ?? 0,
      totalInvestments: data['totalInvestments'] ?? 0, // 🚀 DODANE
      uniqueInvestors: data['uniqueInvestors'] ?? 0, // 🚀 DODANE
      activeProducts: data['activeProducts'] ?? 0,
      inactiveProducts: data['inactiveProducts'] ?? 0,
      totalInvestmentAmount: (data['totalInvestmentAmount'] ?? 0).toDouble(),
      totalRemainingCapital: (data['totalRemainingCapital'] ?? 0).toDouble(), // 🚀 DODANE
      totalValue: (data['totalValue'] ?? 0).toDouble(),
      averageInvestmentAmount: (data['averageInvestmentAmount'] ?? 0)
          .toDouble(),
      averageValue: (data['averageValue'] ?? 0).toDouble(),
      profitLoss: (data['profitLoss'] ?? 0).toDouble(),
      profitLossPercentage: (data['profitLossPercentage'] ?? 0).toDouble(),
      activePercentage: (data['activePercentage'] ?? 0).toDouble(),

      typeDistribution: (data['typeDistribution'] as List<dynamic>? ?? [])
          .map((item) => ProductTypeStats.fromMap(item as Map<String, dynamic>))
          .toList(),

      statusDistribution: (data['statusDistribution'] as List<dynamic>? ?? [])
          .map(
            (item) => ProductStatusStats.fromMap(item as Map<String, dynamic>),
          )
          .toList(),

      mostValuableType: data['mostValuableType'] ?? 'bonds',
      mostValuableTypeValue: (data['mostValuableTypeValue'] ?? 0).toDouble(),

      topCompaniesByValue: (data['topCompaniesByValue'] as List<dynamic>? ?? [])
          .map((item) => CompanyStats.fromMap(item as Map<String, dynamic>))
          .toList(),

      interestRateStats: InterestRateStats.fromMap(
        data['interestRateStats'] as Map<String, dynamic>? ?? {},
      ),

      recentProducts: RecentProductsStats.fromMap(
        data['recentProducts'] as Map<String, dynamic>? ?? {},
      ),

      timestamp:
          DateTime.tryParse(data['metadata']?['timestamp'] ?? '') ??
          DateTime.now(),
      cacheUsed: data['metadata']?['cacheUsed'] ?? false,
    );
  }

  factory ProductStatistics.empty() {
    return ProductStatistics(
      totalProducts: 0,
      totalInvestments: 0, // 🚀 DODANE
      uniqueInvestors: 0, // 🚀 DODANE
      activeProducts: 0,
      inactiveProducts: 0,
      totalInvestmentAmount: 0.0,
      totalRemainingCapital: 0.0, // 🚀 DODANE
      totalValue: 0.0,
      averageInvestmentAmount: 0.0,
      averageValue: 0.0,
      profitLoss: 0.0,
      profitLossPercentage: 0.0,
      activePercentage: 0.0,
      typeDistribution: const [],
      statusDistribution: const [],
      mostValuableType: 'bonds',
      mostValuableTypeValue: 0.0,
      topCompaniesByValue: const [],
      interestRateStats: InterestRateStats.empty(),
      recentProducts: RecentProductsStats.empty(),
      timestamp: DateTime.now(),
      cacheUsed: false,
    );
  }
}

/// Statystyki według typu produktu
class ProductTypeStats {
  final String productType;
  final String productTypeName;
  final int count;
  final double totalInvestment;
  final double totalValue;
  final double percentage;

  const ProductTypeStats({
    required this.productType,
    required this.productTypeName,
    required this.count,
    required this.totalInvestment,
    required this.totalValue,
    required this.percentage,
  });

  factory ProductTypeStats.fromMap(Map<String, dynamic> map) {
    return ProductTypeStats(
      productType: map['productType'] ?? '',
      productTypeName: map['productTypeName'] ?? '',
      count: map['count'] ?? 0,
      totalInvestment: (map['totalInvestment'] ?? 0).toDouble(),
      totalValue: (map['totalValue'] ?? 0).toDouble(),
      percentage: (map['percentage'] ?? 0).toDouble(),
    );
  }
}

/// Statystyki według statusu
class ProductStatusStats {
  final String status;
  final String statusName;
  final int count;
  final double percentage;

  const ProductStatusStats({
    required this.status,
    required this.statusName,
    required this.count,
    required this.percentage,
  });

  factory ProductStatusStats.fromMap(Map<String, dynamic> map) {
    return ProductStatusStats(
      status: map['status'] ?? '',
      statusName: map['statusName'] ?? '',
      count: map['count'] ?? 0,
      percentage: (map['percentage'] ?? 0).toDouble(),
    );
  }
}

/// Statystyki spółki
class CompanyStats {
  final String companyName;
  final int productCount;
  final double totalInvestment;
  final double totalValue;
  final List<String> productTypes;
  final int diversification;

  const CompanyStats({
    required this.companyName,
    required this.productCount,
    required this.totalInvestment,
    required this.totalValue,
    required this.productTypes,
    required this.diversification,
  });

  factory CompanyStats.fromMap(Map<String, dynamic> map) {
    return CompanyStats(
      companyName: map['companyName'] ?? '',
      productCount: map['productCount'] ?? 0,
      totalInvestment: (map['totalInvestment'] ?? 0).toDouble(),
      totalValue: (map['totalValue'] ?? 0).toDouble(),
      productTypes: List<String>.from(map['productTypes'] ?? []),
      diversification: map['diversification'] ?? 0,
    );
  }
}

/// Statystyki oprocentowania
class InterestRateStats {
  final double average;
  final double min;
  final double max;
  final int productsCount;

  const InterestRateStats({
    required this.average,
    required this.min,
    required this.max,
    required this.productsCount,
  });

  factory InterestRateStats.fromMap(Map<String, dynamic> map) {
    return InterestRateStats(
      average: (map['average'] ?? 0).toDouble(),
      min: (map['min'] ?? 0).toDouble(),
      max: (map['max'] ?? 0).toDouble(),
      productsCount: map['productsCount'] ?? 0,
    );
  }

  factory InterestRateStats.empty() {
    return const InterestRateStats(
      average: 0.0,
      min: 0.0,
      max: 0.0,
      productsCount: 0,
    );
  }
}

/// Statystyki najnowszych produktów
class RecentProductsStats {
  final int last30Days;
  final int last90Days;
  final int lastYear;

  const RecentProductsStats({
    required this.last30Days,
    required this.last90Days,
    required this.lastYear,
  });

  factory RecentProductsStats.fromMap(Map<String, dynamic> map) {
    return RecentProductsStats(
      last30Days: map['last30Days'] ?? 0,
      last90Days: map['last90Days'] ?? 0,
      lastYear: map['lastYear'] ?? 0,
    );
  }

  factory RecentProductsStats.empty() {
    return const RecentProductsStats(last30Days: 0, last90Days: 0, lastYear: 0);
  }
}

extension FirebaseFunctionsProductsServiceFallback
    on FirebaseFunctionsProductsService {
  /// Fallback metoda - pobiera produkty bezpośrednio z Firestore
  /// Używana gdy Firebase Functions są niedostępne (CORS, deployment itp.)
  Future<UnifiedProductsResult> _getUnifiedProductsFromFirestore({
    int page = 1,
    int pageSize = 250,
    String sortBy = 'createdAt',
    bool sortAscending = false,
    String? searchQuery,
    List<String>? productTypes,
    List<String>? statuses,
    double? minInvestmentAmount,
    double? maxInvestmentAmount,
  }) async {
    try {
      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductsService] 🔄 Používam Firestore fallback...',
        );
      }

      final firestore = FirebaseFirestore.instance;

      // Pobierz wszystkie dokumenty z kolekcji investments
      Query query = firestore.collection('investments');

      // Podstawowe sortowanie
      if (sortBy == 'createdAt' || sortBy == 'uploadedAt') {
        query = query.orderBy('createdAt', descending: !sortAscending);
      } else if (sortBy == 'investmentAmount') {
        query = query.orderBy('investmentAmount', descending: !sortAscending);
      } else {
        // Default sorting
        query = query.orderBy('createdAt', descending: true);
      }

      final snapshot = await query.get();

      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductsService] Pobrano ${snapshot.docs.length} dokumentów z Firestore',
        );
      }

      // Konwertuj dokumenty na UnifiedProduct
      List<UnifiedProduct> allProducts = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final product = UnifiedProduct.fromServerData({
            'id': doc.id,
            'name':
                data['productName'] ??
                data['projectName'] ??
                'Produkt ${doc.id}',
            'productType': _mapProductType(data['productType']),
            'investmentAmount':
                _safeToDouble(data['investmentAmount'] ?? data['paidAmount']) ??
                0.0,
            'totalValue': _calculateTotalValue(data),
            'createdAt': _parseDate(data['createdAt'] ?? data['signingDate']),
            'uploadedAt': _parseDate(data['uploadedAt']),
            'sourceFile': data['sourceFile'] ?? 'firestore_fallback',
            'status': _mapStatus(data['status'] ?? data['productStatus']),
            'companyName': data['companyId'] ?? data['creditorCompany'],
            'clientId': data['clientId'],
            'clientName': data['clientName'],
            'additionalInfo': data,
          });
          allProducts.add(product);
        } catch (e) {
          if (kDebugMode) {
            print(
              '[FirebaseFunctionsProductsService] ⚠️ Błąd konwersji dokumentu ${doc.id}: $e',
            );
          }
        }
      }

      // Zastosuj filtry client-side
      List<UnifiedProduct> filteredProducts = allProducts;

      // Filtr wyszukiwania
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        filteredProducts = filteredProducts.where((product) {
          return product.name.toLowerCase().contains(searchLower) ||
              (product.companyName?.toLowerCase().contains(searchLower) ??
                  false) ||
              product.id.toLowerCase().contains(searchLower);
        }).toList();
      }

      // Filtr typu produktu
      if (productTypes != null && productTypes.isNotEmpty) {
        filteredProducts = filteredProducts.where((product) {
          return productTypes.contains(product.productType.name);
        }).toList();
      }

      // Zastosuj paginację
      final totalCount = filteredProducts.length;
      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;
      final paginatedProducts = filteredProducts.sublist(
        startIndex,
        endIndex > totalCount ? totalCount : endIndex,
      );

      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductsService] Fallback zakończony: ${paginatedProducts.length} z $totalCount produktów',
        );
      }

      return UnifiedProductsResult(
        products: paginatedProducts,
        pagination: PaginationInfo(
          currentPage: page,
          pageSize: pageSize,
          totalItems: totalCount,
          totalPages: (totalCount / pageSize).ceil(),
          hasNext: endIndex < totalCount,
          hasPrevious: page > 1,
        ),
        metadata: UnifiedProductsMetadata(
          timestamp: DateTime.now(),
          executionTime: 0,
          cacheUsed: false,
          filters: {
            'searchQuery': searchQuery,
            'productTypes': productTypes,
            'fallbackUsed': true,
          },
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductsService] ❌ Fallback też nie powiódł się: $e',
        );
      }
      rethrow;
    }
  }

  /// Pomocnicze metody dla fallback
  String _mapProductType(dynamic type) {
    final typeStr = type?.toString().toLowerCase() ?? '';
    switch (typeStr) {
      case 'apartment':
      case 'apartments':
        return 'apartments';
      case 'bond':
      case 'bonds':
        return 'bonds';
      case 'share':
      case 'shares':
        return 'shares';
      case 'loan':
      case 'loans':
        return 'loans';
      default:
        return 'other';
    }
  }

  String _mapStatus(dynamic status) {
    final statusStr = status?.toString().toLowerCase() ?? '';
    switch (statusStr) {
      case 'active':
        return 'active';
      case 'inactive':
        return 'inactive';
      case 'pending':
        return 'pending';
      case 'suspended':
        return 'suspended';
      default:
        return 'active';
    }
  }

  double? _safeToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  double _calculateTotalValue(Map<String, dynamic> data) {
    final investmentAmount =
        _safeToDouble(data['investmentAmount'] ?? data['paidAmount']) ?? 0.0;
    final remainingCapital =
        _safeToDouble(
          data['remainingCapital'] ?? data['realEstateSecuredCapital'],
        ) ??
        0.0;
    final realizedCapital = _safeToDouble(data['realizedCapital']) ?? 0.0;

    if (remainingCapital > 0) {
      return remainingCapital + realizedCapital;
    }
    return investmentAmount;
  }

  String _parseDate(dynamic date) {
    if (date == null) return DateTime.now().toIso8601String();
    if (date is String && date.isNotEmpty) return date;
    if (date is DateTime) return date.toIso8601String();
    return DateTime.now().toIso8601String();
  }

  /// Fallback metoda dla statystyk - podstawowe statystyki z Firestore
  Future<ProductStatistics> _getBasicStatisticsFromFirestore() async {
    try {
      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductsService] 🔄 Używam podstawowych statystyk z Firestore...',
        );
      }

      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('investments').get();

      final totalProducts = snapshot.docs.length;
      final totalInvestments = snapshot.docs.length; // 🚀 DODANE - każdy dokument to inwestycja
      double totalInvestmentAmount = 0.0;
      double totalRemainingCapital = 0.0; // 🚀 DODANE
      final Set<String> uniqueClientIds = <String>{}; // 🚀 DODANE - dla unique investors
      final Map<String, int> typeDistribution = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalInvestmentAmount +=
            _safeToDouble(data['investmentAmount'] ?? data['paidAmount']) ??
            0.0;
        
        // 🚀 DODANE: Dodaj remaining capital
        totalRemainingCapital +=
            _safeToDouble(data['remainingCapital'] ?? data['kapital_pozostaly']) ?? 0.0;

        // 🚀 DODANE: Zbierz unique client IDs
        final clientId = data['clientId'] ?? data['klient'] ?? data['ID_Klient'];
        if (clientId != null) {
          uniqueClientIds.add(clientId.toString());
        }

        final productType = _mapProductType(data['productType']);
        typeDistribution[productType] =
            (typeDistribution[productType] ?? 0) + 1;
      }

      return ProductStatistics(
        totalProducts: totalProducts,
        totalInvestments: totalInvestments, // 🚀 DODANE
        uniqueInvestors: uniqueClientIds.length, // 🚀 DODANE - liczba unikalnych klientów
        activeProducts: totalProducts, // Wszystkie jako aktywne w fallback
        inactiveProducts: 0,
        totalInvestmentAmount: totalInvestmentAmount,
        totalRemainingCapital: totalRemainingCapital, // 🚀 DODANE
        totalValue: totalInvestmentAmount,
        averageInvestmentAmount: totalProducts > 0
            ? totalInvestmentAmount / totalProducts
            : 0.0,
        averageValue: totalProducts > 0
            ? totalInvestmentAmount / totalProducts
            : 0.0,
        profitLoss: 0.0,
        profitLossPercentage: 0.0,
        activePercentage: 100.0,
        typeDistribution: typeDistribution.entries
            .map(
              (e) => ProductTypeStats(
                productType: e.key,
                productTypeName: _getProductTypeName(e.key),
                count: e.value,
                totalInvestment: 0.0,
                totalValue: 0.0,
                percentage: totalProducts > 0
                    ? (e.value / totalProducts) * 100
                    : 0.0,
              ),
            )
            .toList(),
        statusDistribution: [
          ProductStatusStats(
            status: 'active',
            statusName: 'Aktywny',
            count: totalProducts,
            percentage: 100.0,
          ),
        ],
        mostValuableType: 'apartments',
        mostValuableTypeValue: totalInvestmentAmount,
        topCompaniesByValue: const [],
        interestRateStats: InterestRateStats.empty(),
        recentProducts: RecentProductsStats.empty(),
        timestamp: DateTime.now(),
        cacheUsed: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductsService] ❌ Fallback statystyki nie powiodły się: $e',
        );
      }
      return ProductStatistics.empty();
    }
  }

  String _getProductTypeName(String productType) {
    switch (productType) {
      case 'apartments':
        return 'Apartamenty';
      case 'bonds':
        return 'Obligacje';
      case 'shares':
        return 'Udziały';
      case 'loans':
        return 'Pożyczki';
      default:
        return 'Inne';
    }
  }
}
