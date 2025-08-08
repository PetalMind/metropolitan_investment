import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/unified_product.dart';
import '../models/bond.dart';
import '../models/share.dart';
import '../models/loan.dart';
import '../models/apartment.dart';
import '../models/product.dart';
import 'base_service.dart';

/// Serwis do zarządzania zunifikowanymi produktami z wszystkich kolekcji
class UnifiedProductService extends BaseService {
  static const String _cacheKeyPrefix = 'unified_products_';
  static const String _cacheKeyAll = 'unified_products_all';
  static const String _cacheKeyStats = 'unified_products_stats';

  /// Pobiera wszystkie produkty ze wszystkich kolekcji
  Future<List<UnifiedProduct>> getAllProducts() async {
    return getCachedData(_cacheKeyAll, () => _fetchAllProducts());
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

      // Zastosuj filtry
      var filteredProducts = allProducts.where(criteria.matches).toList();

      // Sortuj
      _sortProducts(filteredProducts, sortField, sortDirection);

      // Zastosuj paginację
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

  /// Pobiera produkty określonego typu
  Future<List<UnifiedProduct>> getProductsByType(
    UnifiedProductType type,
  ) async {
    final cacheKey = '${_cacheKeyPrefix}type_${type.name}';

    return getCachedData(cacheKey, () async {
      switch (type) {
        case UnifiedProductType.bonds:
          return await _getBonds();
        case UnifiedProductType.shares:
          return await _getShares();
        case UnifiedProductType.loans:
          return await _getLoans();
        case UnifiedProductType.apartments:
          return await _getApartments();
        case UnifiedProductType.other:
          return await _getOtherProducts();
      }
    });
  }

  /// Pobiera statystyki produktów
  Future<ProductStatistics> getProductStatistics() async {
    return getCachedData(_cacheKeyStats, () => _calculateStatistics());
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

  /// Pobiera produkt po ID z odpowiedniej kolekcji
  Future<UnifiedProduct?> getProductById(
    String id,
    UnifiedProductType type,
  ) async {
    try {
      DocumentSnapshot doc;

      switch (type) {
        case UnifiedProductType.bonds:
          doc = await firestore.collection('bonds').doc(id).get();
          if (doc.exists) {
            return UnifiedProduct.fromBond(Bond.fromFirestore(doc));
          }
          break;

        case UnifiedProductType.shares:
          doc = await firestore.collection('shares').doc(id).get();
          if (doc.exists) {
            return UnifiedProduct.fromShare(Share.fromFirestore(doc));
          }
          break;

        case UnifiedProductType.loans:
          doc = await firestore.collection('loans').doc(id).get();
          if (doc.exists) {
            return UnifiedProduct.fromLoan(Loan.fromFirestore(doc));
          }
          break;

        case UnifiedProductType.apartments:
          doc = await firestore.collection('apartments').doc(id).get();
          if (doc.exists) {
            return UnifiedProduct.fromApartment(Apartment.fromFirestore(doc));
          }
          break;

        case UnifiedProductType.other:
          doc = await firestore.collection('products').doc(id).get();
          if (doc.exists) {
            return UnifiedProduct.fromProduct(Product.fromFirestore(doc));
          }
          break;
      }

      return null;
    } catch (e) {
      logError('getProductById', e);
      return null;
    }
  }

  /// Pobiera najpopularniejsze typy produktów
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

  /// Pobiera produkty utworzone w ostatnim okresie
  Future<List<UnifiedProduct>> getRecentProducts({int days = 30}) async {
    final cacheKey = '${_cacheKeyPrefix}recent_$days';

    return getCachedData(cacheKey, () async {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final allProducts = await getAllProducts();

      final recentProducts = allProducts
          .where((product) => product.createdAt.isAfter(cutoffDate))
          .toList();

      recentProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return recentProducts;
    });
  }

  /// Prywatne metody do pobierania danych z poszczególnych kolekcji

  Future<List<UnifiedProduct>> _fetchAllProducts() async {
    try {
      final results = await Future.wait([
        _getBonds(),
        _getShares(),
        _getLoans(),
        _getApartments(),
        _getOtherProducts(),
      ]);

      final allProducts = <UnifiedProduct>[];
      for (final productList in results) {
        allProducts.addAll(productList);
      }

      return allProducts;
    } catch (e) {
      logError('_fetchAllProducts', e);
      return [];
    }
  }

  Future<List<UnifiedProduct>> _getBonds() async {
    try {
      final snapshot = await firestore.collection('bonds').get();
      return snapshot.docs
          .map((doc) => UnifiedProduct.fromBond(Bond.fromFirestore(doc)))
          .toList();
    } catch (e) {
      logError('_getBonds', e);
      return [];
    }
  }

  Future<List<UnifiedProduct>> _getShares() async {
    try {
      final snapshot = await firestore.collection('shares').get();
      return snapshot.docs
          .map((doc) => UnifiedProduct.fromShare(Share.fromFirestore(doc)))
          .toList();
    } catch (e) {
      logError('_getShares', e);
      return [];
    }
  }

  Future<List<UnifiedProduct>> _getLoans() async {
    try {
      final snapshot = await firestore.collection('loans').get();
      return snapshot.docs
          .map((doc) => UnifiedProduct.fromLoan(Loan.fromFirestore(doc)))
          .toList();
    } catch (e) {
      logError('_getLoans', e);
      return [];
    }
  }

  Future<List<UnifiedProduct>> _getApartments() async {
    try {
      final snapshot = await firestore.collection('apartments').get();
      return snapshot.docs
          .map(
            (doc) => UnifiedProduct.fromApartment(Apartment.fromFirestore(doc)),
          )
          .toList();
    } catch (e) {
      logError('_getApartments', e);
      return [];
    }
  }

  Future<List<UnifiedProduct>> _getOtherProducts() async {
    try {
      final snapshot = await firestore
          .collection('products')
          .where('type', whereNotIn: ['apartments'])
          .get();
      return snapshot.docs
          .map((doc) => UnifiedProduct.fromProduct(Product.fromFirestore(doc)))
          .toList();
    } catch (e) {
      logError('_getOtherProducts', e);
      return [];
    }
  }

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

      // Znajdź najbardziej dochodowy typ produktu
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
    clearAllCache(); // Używamy metody z BaseService
  }

  /// Odświeża cache w tle
  Future<void> refreshCache() async {
    try {
      clearProductsCache();

      // Preload najważniejszych danych
      await Future.wait([
        getAllProducts(),
        getProductStatistics(),
        getProductTypeDistribution(),
      ]);

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
