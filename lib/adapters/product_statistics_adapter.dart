import '../services/firebase_functions_products_service.dart' as fb;
import '../services/unified_product_service.dart' as unified;
import '../models/unified_product.dart';

/// Adapter do konwersji ProductStatistics z Firebase Functions na format używany przez widgety
class ProductStatisticsAdapter {
  /// Konwertuje ProductStatistics z Firebase Functions do formatu unified_product_service
  static unified.ProductStatistics adaptToUnified(
    fb.ProductStatistics fbStats,
  ) {
    // Konwertuj typeDistribution z List<ProductTypeStats> na Map<UnifiedProductType, int>
    final Map<UnifiedProductType, int> typeDistribution = {};
    for (final typeStat in fbStats.typeDistribution) {
      final unifiedType = _mapStringToUnifiedProductType(typeStat.productType);
      if (unifiedType != null) {
        typeDistribution[unifiedType] = typeStat.count;
      }
    }

    // Konwertuj statusDistribution z List<ProductStatusStats> na Map<ProductStatus, int>
    final Map<ProductStatus, int> statusDistribution = {};
    for (final statusStat in fbStats.statusDistribution) {
      final productStatus = _mapStringToProductStatus(statusStat.status);
      if (productStatus != null) {
        statusDistribution[productStatus] = statusStat.count;
      }
    }

    // Mapuj mostValuableType z String na UnifiedProductType
    final mostValuableType =
        _mapStringToUnifiedProductType(fbStats.mostValuableType) ??
        UnifiedProductType.bonds;

    return unified.ProductStatistics(
      totalProducts: fbStats.totalProducts,
      activeProducts: fbStats.activeProducts,
      inactiveProducts: fbStats.inactiveProducts,
      totalInvestmentAmount: fbStats.totalInvestmentAmount,
      totalValue: fbStats.totalValue,
      averageInvestmentAmount: fbStats.averageInvestmentAmount,
      averageValue: fbStats.averageValue,
      typeDistribution: typeDistribution,
      statusDistribution: statusDistribution,
      mostValuableType: mostValuableType,
    );
  }

  /// Konwertuje ProductStatistics z unified_product_service do formatu Firebase Functions
  static fb.ProductStatistics adaptFromUnifiedToFB(
    unified.ProductStatistics unifiedStats,
  ) {
    // Konwertuj typeDistribution z Map<UnifiedProductType, int> na List<ProductTypeStats>
    final List<fb.ProductTypeStats> typeDistribution = [];
    final totalProducts = unifiedStats.totalProducts;

    for (final entry in unifiedStats.typeDistribution.entries) {
      final percentage = totalProducts > 0
          ? (entry.value / totalProducts) * 100
          : 0.0;
      typeDistribution.add(
        fb.ProductTypeStats(
          productType: _mapUnifiedProductTypeToString(entry.key),
          productTypeName: entry.key.displayName,
          count: entry.value,
          totalInvestment: 0.0, // Nie mamy tej informacji w unified
          totalValue: 0.0, // Nie mamy tej informacji w unified
          percentage: percentage,
        ),
      );
    }

    // Konwertuj statusDistribution z Map<ProductStatus, int> na List<ProductStatusStats>
    final List<fb.ProductStatusStats> statusDistribution = [];
    for (final entry in unifiedStats.statusDistribution.entries) {
      final percentage = totalProducts > 0
          ? (entry.value / totalProducts) * 100
          : 0.0;
      statusDistribution.add(
        fb.ProductStatusStats(
          status: _mapProductStatusToString(entry.key),
          statusName: entry.key.displayName,
          count: entry.value,
          percentage: percentage,
        ),
      );
    }

    final activePercentage = totalProducts > 0
        ? (unifiedStats.activeProducts / totalProducts) * 100
        : 0.0;

    return fb.ProductStatistics(
      totalProducts: unifiedStats.totalProducts,
      totalInvestments: unifiedStats.totalProducts, // 🚀 DODANE - aproximacja
      uniqueInvestors: unifiedStats.totalProducts, // 🚀 DODANE - aproximacja
      activeProducts: unifiedStats.activeProducts,
      inactiveProducts: unifiedStats.inactiveProducts,
      totalInvestmentAmount: unifiedStats.totalInvestmentAmount,
      totalRemainingCapital: unifiedStats.totalValue, // 🚀 DODANE - aproximacja
      totalValue: unifiedStats.totalValue,
      averageInvestmentAmount: unifiedStats.averageInvestmentAmount,
      averageValue: unifiedStats.averageValue,
      profitLoss: 0.0, // Nie mamy tej informacji w unified
      profitLossPercentage: 0.0, // Nie mamy tej informacji w unified
      activePercentage: activePercentage,
      typeDistribution: typeDistribution,
      statusDistribution: statusDistribution,
      mostValuableType: _mapUnifiedProductTypeToString(
        unifiedStats.mostValuableType,
      ),
      mostValuableTypeValue: 0.0, // Nie mamy tej informacji w unified
      topCompaniesByValue: const [], // Nie mamy tej informacji w unified
      interestRateStats: fb.InterestRateStats.empty(),
      recentProducts: fb.RecentProductsStats.empty(),
      timestamp: DateTime.now(),
      cacheUsed: false,
    );
  }

  /// Mapuje UnifiedProductType na string używany w Firebase Functions
  static String _mapUnifiedProductTypeToString(UnifiedProductType type) {
    switch (type) {
      case UnifiedProductType.bonds:
        return 'bonds';
      case UnifiedProductType.shares:
        return 'shares';
      case UnifiedProductType.loans:
        return 'loans';
      case UnifiedProductType.apartments:
        return 'apartments';
      case UnifiedProductType.other:
        return 'other';
    }
  }

  /// Mapuje ProductStatus na string używany w Firebase Functions
  static String _mapProductStatusToString(ProductStatus status) {
    switch (status) {
      case ProductStatus.active:
        return 'active';
      case ProductStatus.inactive:
        return 'inactive';
      case ProductStatus.pending:
        return 'pending';
      case ProductStatus.suspended:
        return 'suspended';
    }
  }

  /// Mapuje string z serwera na UnifiedProductType
  static UnifiedProductType? _mapStringToUnifiedProductType(String type) {
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
        return null;
    }
  }

  /// Mapuje string z serwera na ProductStatus
  static ProductStatus? _mapStringToProductStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'aktywny':
        return ProductStatus.active;
      case 'inactive':
      case 'nieaktywny':
        return ProductStatus.inactive;
      case 'pending':
      case 'oczekujacy':
        return ProductStatus.pending;
      case 'suspended':
      case 'zawieszony':
        return ProductStatus.suspended;
      default:
        return null;
    }
  }
}
