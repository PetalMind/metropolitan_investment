import 'package:flutter/foundation.dart';
import '../models/unified_product.dart';
import '../models/product.dart'; // Import dla ProductType
import 'base_service.dart';

/// Prosty zunifikowany serwis produktów używający kolekcji 'investments'
class UnifiedProductService extends BaseService {
  static const String _cacheKeyPrefix = 'unified_products_';
  static const String _cacheKeyAll = 'unified_products_all';
  static const String _cacheKeyStats = 'unified_products_stats';

  /// Pobiera wszystkie produkty z zunifikowanej kolekcji investments
  Future<List<UnifiedProduct>> getAllProducts() async {
    return getCachedData(_cacheKeyAll, () => _fetchAllProducts());
  }

  /// Pobiera produkty określonego typu
  Future<List<UnifiedProduct>> getProductsByType(
    UnifiedProductType type,
  ) async {
    final cacheKey = '${_cacheKeyPrefix}type_${type.name}';

    return getCachedData(cacheKey, () async {
      final allProducts = await getAllProducts();
      return allProducts
          .where((product) => product.productType == type)
          .toList();
    });
  }

  /// Pobiera statystyki produktów
  Future<ProductStatistics> getProductStatistics() async {
    return getCachedData(_cacheKeyStats, () => _calculateStatistics());
  }

  /// Pobiera produkty z filtrowaniem
  Future<List<UnifiedProduct>> getFilteredProducts(
    ProductFilterCriteria criteria, {
    ProductSortField sortField = ProductSortField.name,
    SortDirection sortDirection = SortDirection.ascending,
    int? limit,
    int offset = 0,
  }) async {
    final cacheKey =
        '${_cacheKeyPrefix}filtered_${criteria.hashCode}_${sortField.name}_${sortDirection.name}_${limit ?? 'all'}_$offset';

    return getCachedData(cacheKey, () async {
      final allProducts = await getAllProducts();
      var filteredProducts = allProducts.where(criteria.matches).toList();
      _sortProducts(filteredProducts, sortField, sortDirection);

      if (limit != null) {
        final endIndex = offset + limit;
        if (offset < filteredProducts.length) {
          filteredProducts = filteredProducts.sublist(
            offset,
            endIndex > filteredProducts.length
                ? filteredProducts.length
                : endIndex,
          );
        } else {
          filteredProducts = [];
        }
      }

      return filteredProducts;
    });
  }

  /// Pobiera produkt po ID
  Future<UnifiedProduct?> getProductById(String id) async {
    try {
      final doc = await firestore.collection('investments').doc(id).get();

      if (doc.exists && doc.data() != null) {
        return _convertInvestmentToUnifiedProduct(doc.id, doc.data()!);
      }

      return null;
    } catch (e) {
      logError('getProductById', e);
      return null;
    }
  }

  /// Wyszukuje produkty po tekście
  Future<List<UnifiedProduct>> searchProducts(String searchText) async {
    if (searchText.trim().isEmpty) {
      return getAllProducts();
    }

    final cacheKey = '${_cacheKeyPrefix}search_${searchText.hashCode}';

    return getCachedData(cacheKey, () async {
      final allProducts = await getAllProducts();
      final searchLower = searchText.toLowerCase();

      return allProducts.where((product) {
        return product.name.toLowerCase().contains(searchLower) ||
            product.description.toLowerCase().contains(searchLower) ||
            product.productType.displayName.toLowerCase().contains(
              searchLower,
            ) ||
            (product.companyName?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    });
  }

  /// Pobiera ostatnie produkty
  Future<List<UnifiedProduct>> getRecentProducts({int days = 30}) async {
    final cacheKey = '${_cacheKeyPrefix}recent_$days';

    return getCachedData(cacheKey, () async {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final allProducts = await getAllProducts();

      return allProducts
          .where((product) => product.createdAt.isAfter(cutoffDate))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// Pobiera rozkład typów produktów
  Future<List<MapEntry<UnifiedProductType, int>>>
  getProductTypeDistribution() async {
    final cacheKey = '${_cacheKeyPrefix}type_distribution';

    return getCachedData(cacheKey, () async {
      final allProducts = await getAllProducts();
      final distribution = <UnifiedProductType, int>{};

      for (final product in allProducts) {
        distribution[product.productType] =
            (distribution[product.productType] ?? 0) + 1;
      }

      final entries = distribution.entries.toList();
      entries.sort((a, b) => b.value.compareTo(a.value));

      return entries;
    });
  }

  /// Prywatna metoda do pobierania wszystkich produktów
  Future<List<UnifiedProduct>> _fetchAllProducts() async {
    try {
      final snapshot = await firestore.collection('investments').get();

      return snapshot.docs.map((doc) {
        return _convertInvestmentToUnifiedProduct(doc.id, doc.data());
      }).toList();
    } catch (e) {
      logError('_fetchAllProducts', e);
      return [];
    }
  }

  /// Konwertuje dokument investment na UnifiedProduct
  UnifiedProduct _convertInvestmentToUnifiedProduct(
    String id,
    Map<String, dynamic> data,
  ) {
    double safeToDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final cleaned = value.replaceAll(',', '');
        final parsed = double.tryParse(cleaned);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    }

    DateTime? parseDate(dynamic dateValue) {
      if (dateValue == null) return null;
      if (dateValue is String && dateValue.isEmpty) return null;

      try {
        if (dateValue is String) {
          return DateTime.parse(dateValue);
        }
        return null;
      } catch (e) {
        return null;
      }
    }

    UnifiedProductType _mapProductType(dynamic productType) {
      if (productType == null) return UnifiedProductType.bonds;
      
      print('🔧 [UnifiedProductService] Mapowanie typu produktu: $productType (${productType.runtimeType})');
      
      // Sprawdź czy to enum ProductType
      if (productType is ProductType) {
        print('🔧 [UnifiedProductService] To jest ProductType enum: $productType');
        switch (productType) {
          case ProductType.bonds:
            return UnifiedProductType.bonds;
          case ProductType.shares:
            return UnifiedProductType.shares;
          case ProductType.loans:
            return UnifiedProductType.loans;
          case ProductType.apartments:
            return UnifiedProductType.apartments;
        }
      }
      
      // Jeśli to string, sprawdź różne warianty
      final typeStr = productType.toString().toLowerCase();

      // Sprawdź angielskie nazwy
      if (typeStr == 'loans' || typeStr == 'loan' || typeStr.contains('loans'))
        return UnifiedProductType.loans;
      if (typeStr == 'shares' || typeStr == 'share' || typeStr.contains('shares'))
        return UnifiedProductType.shares;
      if (typeStr == 'apartments' || typeStr == 'apartment' || typeStr.contains('apartments'))
        return UnifiedProductType.apartments;
      if (typeStr == 'bonds' || typeStr == 'bond' || typeStr.contains('bonds'))
        return UnifiedProductType.bonds;
        
      // Sprawdź polskie nazwy
      if (typeStr.contains('pożyczk') || typeStr.contains('pozyczk'))
        return UnifiedProductType.loans;
      if (typeStr.contains('udział') || typeStr.contains('udzial'))
        return UnifiedProductType.shares;
      if (typeStr.contains('apartament'))
        return UnifiedProductType.apartments;
      if (typeStr.contains('obligacj'))
        return UnifiedProductType.bonds;
        
      // Sprawdź enum toString format (ProductType.bonds -> bonds)
      if (typeStr.contains('.bonds'))
        return UnifiedProductType.bonds;
      if (typeStr.contains('.shares'))
        return UnifiedProductType.shares;
      if (typeStr.contains('.loans'))
        return UnifiedProductType.loans;
      if (typeStr.contains('.apartments'))
        return UnifiedProductType.apartments;

      return UnifiedProductType.bonds;
    }

    ProductStatus _mapProductStatus(dynamic status) {
      if (status == null) return ProductStatus.active;
      final statusStr = status.toString().toLowerCase();

      if (statusStr.contains('active')) return ProductStatus.active;
      if (statusStr.contains('inactive')) return ProductStatus.inactive;
      if (statusStr.contains('pending')) return ProductStatus.pending;
      if (statusStr.contains('suspended')) return ProductStatus.suspended;

      return ProductStatus.active;
    }

    return UnifiedProduct(
      id: id,
      name:
          data['productName']?.toString() ??
          data['produkt_nazwa']?.toString() ??
          data['clientName']?.toString() ??
          'Unnamed Product',
      productType: _mapProductType(data['productType']),
      investmentAmount: () {
        final value = safeToDouble(data['kwota_inwestycji'] ?? data['investmentAmount']);
        debugPrint('🔍 [UnifiedProductService] Investment amount for $id: kwota_inwestycji=${data['kwota_inwestycji']}, investmentAmount=${data['investmentAmount']}, result=$value');
        return value;
      }(),
      createdAt: parseDate(data['createdAt']) ?? DateTime.now(),
      uploadedAt: parseDate(data['updatedAt']) ?? DateTime.now(),
      sourceFile:
          data['additionalInfo']?['source_file']?.toString() ?? 'investments',
      status: _mapProductStatus(data['status']),
      additionalInfo: {
        'clientId': data['clientId']?.toString() ?? '',
        'clientName': data['clientName']?.toString() ?? '',
        'productType': data['productType']?.toString() ?? '',
        'signedDate': data['signedDate']?.toString() ?? '',
        'employeeFirstName': data['employeeFirstName']?.toString() ?? '',
        'employeeLastName': data['employeeLastName']?.toString() ?? '',
        'branchCode': data['branchCode']?.toString() ?? '',
      },
      realizedCapital: safeToDouble(data['kapital_zrealizowany'] ?? data['realizedCapital']),
      remainingCapital: () {
        final value = safeToDouble(data['kapital_pozostaly'] ?? data['remainingCapital']);
        debugPrint('🔍 [UnifiedProductService] Remaining capital for $id: kapital_pozostaly=${data['kapital_pozostaly']}, remainingCapital=${data['remainingCapital']}, result=$value');
        return value;
      }(),
      realizedInterest: safeToDouble(data['odsetki_zrealizowane'] ?? data['realizedInterest']),
      remainingInterest: safeToDouble(data['remainingInterest']),
      realizedTax: safeToDouble(data['zrealizowany_podatek'] ?? data['realizedTax']),
      transferToOtherProduct: safeToDouble(data['transferToOtherProduct']),
      sharesCount: data['sharesCount'] != null
          ? int.tryParse(data['sharesCount'].toString())
          : null,
      maturityDate: parseDate(data['redemptionDate']),
      companyName: data['creditorCompany']?.toString(),
      companyId: data['companyId']?.toString(),
      currency: data['currency']?.toString() ?? 'PLN',
    );
  }

  /// Sortuje produkty według wybranego kryterium
  void _sortProducts(
    List<UnifiedProduct> products,
    ProductSortField sortField,
    SortDirection direction,
  ) {
    products.sort((a, b) {
      int comparison;

      switch (sortField) {
        case ProductSortField.name:
          comparison = a.name.compareTo(b.name);
          break;
        case ProductSortField.type:
          comparison = a.productType.displayName.compareTo(
            b.productType.displayName,
          );
          break;
        case ProductSortField.investmentAmount:
          comparison = a.investmentAmount.compareTo(b.investmentAmount);
          break;
        case ProductSortField.totalValue:
          comparison = a.totalValue.compareTo(b.totalValue);
          break;
        case ProductSortField.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case ProductSortField.uploadedAt:
          comparison = a.uploadedAt.compareTo(b.uploadedAt);
          break;
        case ProductSortField.status:
          comparison = a.status.displayName.compareTo(b.status.displayName);
          break;
        case ProductSortField.companyName:
          comparison = (a.companyName ?? '').compareTo(b.companyName ?? '');
          break;
        case ProductSortField.interestRate:
          comparison = (a.interestRate ?? 0.0).compareTo(b.interestRate ?? 0.0);
          break;
      }

      return direction == SortDirection.ascending ? comparison : -comparison;
    });
  }

  /// Oblicza statystyki produktów
  Future<ProductStatistics> _calculateStatistics() async {
    try {
      final allProducts = await getAllProducts();

      if (allProducts.isEmpty) {
        return ProductStatistics.empty();
      }

      final totalProducts = allProducts.length;
      final totalInvestmentAmount = allProducts.fold<double>(
        0.0,
        (total, product) => total + product.investmentAmount,
      );
      final totalValue = allProducts.fold<double>(
        0.0,
        (total, product) => total + product.totalValue,
      );

      final activeProducts = allProducts.where((p) => p.isActive).length;
      final typeDistribution = <UnifiedProductType, int>{};
      final statusDistribution = <ProductStatus, int>{};

      for (final product in allProducts) {
        typeDistribution[product.productType] =
            (typeDistribution[product.productType] ?? 0) + 1;
        statusDistribution[product.status] =
            (statusDistribution[product.status] ?? 0) + 1;
      }

      final averageInvestmentAmount = totalInvestmentAmount / totalProducts;
      final averageValue = totalValue / totalProducts;

      final typeValueMap = <UnifiedProductType, double>{};
      for (final product in allProducts) {
        typeValueMap[product.productType] =
            (typeValueMap[product.productType] ?? 0.0) + product.totalValue;
      }

      final mostValuableType = typeValueMap.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      return ProductStatistics(
        totalProducts: totalProducts,
        activeProducts: activeProducts,
        inactiveProducts: totalProducts - activeProducts,
        totalInvestmentAmount: totalInvestmentAmount,
        totalValue: totalValue,
        averageInvestmentAmount: averageInvestmentAmount,
        averageValue: averageValue,
        typeDistribution: typeDistribution,
        statusDistribution: statusDistribution,
        mostValuableType: mostValuableType,
      );
    } catch (e) {
      logError('_calculateStatistics', e);
      return ProductStatistics.empty();
    }
  }

  /// Czyści cache dla produktów
  void clearProductsCache() {
    clearAllCache();
  }

  /// Odświeża cache w tle
  Future<void> refreshCache() async {
    try {
      clearProductsCache();

      await Future.wait([getAllProducts(), getProductStatistics()]);

      if (kDebugMode) {
        print('[UnifiedProductService] Cache refreshed successfully');
      }
    } catch (e) {
      logError('refreshCache', e);
    }
  }
}

/// Klasa zawierająca statystyki produktów
class ProductStatistics {
  final int totalProducts;
  final int activeProducts;
  final int inactiveProducts;
  final double totalInvestmentAmount;
  final double totalValue;
  final double averageInvestmentAmount;
  final double averageValue;
  final Map<UnifiedProductType, int> typeDistribution;
  final Map<ProductStatus, int> statusDistribution;
  final UnifiedProductType mostValuableType;

  const ProductStatistics({
    required this.totalProducts,
    required this.activeProducts,
    required this.inactiveProducts,
    required this.totalInvestmentAmount,
    required this.totalValue,
    required this.averageInvestmentAmount,
    required this.averageValue,
    required this.typeDistribution,
    required this.statusDistribution,
    required this.mostValuableType,
  });

  factory ProductStatistics.empty() {
    return const ProductStatistics(
      totalProducts: 0,
      activeProducts: 0,
      inactiveProducts: 0,
      totalInvestmentAmount: 0.0,
      totalValue: 0.0,
      averageInvestmentAmount: 0.0,
      averageValue: 0.0,
      typeDistribution: {},
      statusDistribution: {},
      mostValuableType: UnifiedProductType.bonds,
    );
  }

  double get profitLoss => totalValue - totalInvestmentAmount;
  double get profitLossPercentage => totalInvestmentAmount > 0
      ? (profitLoss / totalInvestmentAmount) * 100
      : 0.0;
  double get activePercentage =>
      totalProducts > 0 ? (activeProducts / totalProducts) * 100 : 0.0;
}
