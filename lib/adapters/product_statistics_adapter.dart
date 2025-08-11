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
