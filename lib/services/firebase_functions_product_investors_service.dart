import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/investor_summary.dart';

/// Firebase Functions service dla wyszukiwania inwestorów produktów
/// Wykonuje server-side processing dla lepszej wydajności
class FirebaseFunctionsProductInvestorsService {
  late final FirebaseFunctions _functions;

  FirebaseFunctionsProductInvestorsService() {
    _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
  }

  /// Pobiera inwestorów dla danego produktu z Firebase Functions
  /// Wykorzystuje server-side processing dla optymalnej wydajności
  Future<ProductInvestorsResult> getProductInvestors({
    String? productName,
    String?
    productId, // Dodane nowe pole - ID produktu dla dokładnego wyszukiwania
    String? productType,
    String searchStrategy = 'comprehensive',
    bool forceRefresh = false,
  }) async {
    try {
      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductInvestorsService] 🔄 Pobieranie inwestorów produktu...',
        );
        print(
          '[FirebaseFunctionsProductInvestorsService] - productName: $productName',
        );
        print(
          '[FirebaseFunctionsProductInvestorsService] - productId: $productId',
        );
        print(
          '[FirebaseFunctionsProductInvestorsService] - productType: $productType',
        );
        print(
          '[FirebaseFunctionsProductInvestorsService] - searchStrategy: $searchStrategy',
        );
      }

      final callable = _functions.httpsCallable('getProductInvestorsOptimized');

      final result = await callable.call({
        'productName': productName,
        'productId': productId, // Dodane nowe pole
        'productType': productType,
        'searchStrategy': searchStrategy,
        'forceRefresh': forceRefresh,
      });

      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductInvestorsService] ✅ Pobrano dane z Firebase Functions',
        );
      }

      return ProductInvestorsResult.fromMap(result.data);
    } catch (e) {
      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductInvestorsService] ❌ Błąd Firebase Functions: $e',
        );
      }

      // Fallback - zwróć pustą listę
      return ProductInvestorsResult.empty(
        productName: productName,
        productType: productType,
        error: e.toString(),
      );
    }
  }

  /// Test połączenia z Firebase Functions
  Future<bool> testConnection() async {
    try {
      await getProductInvestors(
        productName: 'test',
        searchStrategy: 'exact',
        forceRefresh: true,
      );

      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductInvestorsService] ✅ Test połączenia udany',
        );
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[FirebaseFunctionsProductInvestorsService] ❌ Test połączenia nieudany: $e',
        );
      }
      return false;
    }
  }
}

/// Wynik wyszukiwania inwestorów produktu z Firebase Functions
class ProductInvestorsResult {
  final List<InvestorSummary> investors;
  final int totalCount;
  final ProductInvestorsStatistics statistics;
  final String searchStrategy;
  final String productName;
  final String productType;
  final int executionTime;
  final bool fromCache;
  final ProductInvestorsDebugInfo? debugInfo;
  final String? error;

  const ProductInvestorsResult({
    required this.investors,
    required this.totalCount,
    required this.statistics,
    required this.searchStrategy,
    required this.productName,
    required this.productType,
    required this.executionTime,
    required this.fromCache,
    this.debugInfo,
    this.error,
  });

  factory ProductInvestorsResult.fromMap(Map<String, dynamic> map) {
    return ProductInvestorsResult(
      investors: (map['investors'] as List<dynamic>? ?? [])
          .map((item) => InvestorSummary.fromMap(item as Map<String, dynamic>))
          .toList(),
      totalCount: map['totalCount'] as int? ?? 0,
      statistics: ProductInvestorsStatistics.fromMap(
        map['statistics'] as Map<String, dynamic>? ?? {},
      ),
      searchStrategy: map['searchStrategy'] as String? ?? 'comprehensive',
      productName: map['productName'] as String? ?? '',
      productType: map['productType'] as String? ?? '',
      executionTime: map['executionTime'] as int? ?? 0,
      fromCache: map['fromCache'] as bool? ?? false,
      debugInfo: map['debugInfo'] != null
          ? ProductInvestorsDebugInfo.fromMap(
              map['debugInfo'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  factory ProductInvestorsResult.empty({
    String? productName,
    String? productType,
    String? error,
  }) {
    return ProductInvestorsResult(
      investors: const [],
      totalCount: 0,
      statistics: ProductInvestorsStatistics.empty(),
      searchStrategy: 'empty',
      productName: productName ?? '',
      productType: productType ?? '',
      executionTime: 0,
      fromCache: false,
      error: error,
    );
  }
}

/// Statystyki wyszukiwania inwestorów
class ProductInvestorsStatistics {
  final double totalCapital;
  final int totalInvestments;
  final double averageCapital;
  final int activeInvestors;

  const ProductInvestorsStatistics({
    required this.totalCapital,
    required this.totalInvestments,
    required this.averageCapital,
    required this.activeInvestors,
  });

  factory ProductInvestorsStatistics.fromMap(Map<String, dynamic> map) {
    return ProductInvestorsStatistics(
      totalCapital: (map['totalCapital'] as num?)?.toDouble() ?? 0.0,
      totalInvestments: map['totalInvestments'] as int? ?? 0,
      averageCapital: (map['averageCapital'] as num?)?.toDouble() ?? 0.0,
      activeInvestors: map['activeInvestors'] as int? ?? 0,
    );
  }

  factory ProductInvestorsStatistics.empty() {
    return const ProductInvestorsStatistics(
      totalCapital: 0.0,
      totalInvestments: 0,
      averageCapital: 0.0,
      activeInvestors: 0,
    );
  }
}

/// Informacje debugowania
class ProductInvestorsDebugInfo {
  final int totalInvestmentsScanned;
  final int matchingInvestments;
  final int totalClients;
  final int investmentsByClientGroups;

  const ProductInvestorsDebugInfo({
    required this.totalInvestmentsScanned,
    required this.matchingInvestments,
    required this.totalClients,
    required this.investmentsByClientGroups,
  });

  factory ProductInvestorsDebugInfo.fromMap(Map<String, dynamic> map) {
    return ProductInvestorsDebugInfo(
      totalInvestmentsScanned: map['totalInvestmentsScanned'] as int? ?? 0,
      matchingInvestments: map['matchingInvestments'] as int? ?? 0,
      totalClients: map['totalClients'] as int? ?? 0,
      investmentsByClientGroups: map['investmentsByClientGroups'] as int? ?? 0,
    );
  }
}
