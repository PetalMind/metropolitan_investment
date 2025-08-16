/// 🚀 PRODUCT TYPE CONVERTERS - Standaryzacja konwersji między typami produktów
///
/// Centralny system konwersji między wszystkimi typami produktów:
/// - UnifiedProduct ↔ OptimizedProduct ↔ DeduplicatedProduct
/// - Wsparcie dla dwukierunkowej konwersji
/// - Zachowanie wszystkich danych podczas konwersji
/// - Zgodność z `models_and_services.dart`

import '../models_and_services.dart';

/// 🎯 CENTRALNY KONWERTER PRODUKTÓW
/// Zapewnia spójność danych między wszystkimi komponentami systemu
class ProductTypeConverters {
  // ============================================================================
  // 🚀 OPTIMIZED PRODUCT CONVERTERS
  // ============================================================================

  /// Konwertuje OptimizedProduct na UnifiedProduct
  static UnifiedProduct optimizedToUnified(OptimizedProduct opt) {
    return UnifiedProduct(
      id: opt.id,
      name: opt.name,
      productType: opt.productType,
      companyId: opt.companyId,
      companyName: opt.companyName,
      totalValue: opt.totalValue,
      investmentAmount:
          opt.totalValue, // OptimizedProduct używa totalValue jako kwotę bazową
      remainingCapital: opt.totalRemainingCapital,
      clientCount: opt.uniqueInvestors,
      status: opt.status,
      interestRate: opt.interestRate,
      createdAt: opt.earliestInvestmentDate,
      uploadedAt: opt.latestInvestmentDate,
      maturityDate: null, // OptimizedProduct nie przechowuje maturityDate
      sourceFile: 'OptimizedProduct',
      currency: 'PLN',

      // Zachowaj metadane
      originalProduct: opt,
      additionalInfo: {
        'source': 'optimized_product',
        'totalInvestments': opt.totalInvestments,
        'actualInvestorCount': opt.actualInvestorCount,
        'averageInvestment': opt.averageInvestment,
        'topInvestors': opt.topInvestors.map((inv) => inv.toMap()).toList(),
        ...opt.metadata,
      },
    );
  }

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
      maturityDate: null, // OptimizedProduct nie ma maturityDate
      originalInvestmentIds:
          [], // OptimizedProduct nie przechowuje oryginalnych IDs
      metadata: opt.metadata,
    );
  }

  // ============================================================================
  // 🎯 DEDUPLICATED PRODUCT CONVERTERS
  // ============================================================================

  /// Konwertuje DeduplicatedProduct na UnifiedProduct
  static UnifiedProduct deduplicatedToUnified(DeduplicatedProduct deduped) {
    return UnifiedProduct(
      id: deduped.id,
      name: deduped.name,
      productType: deduped.productType,
      investmentAmount: deduped.totalValue,
      createdAt: deduped.earliestInvestmentDate,
      uploadedAt: deduped.latestInvestmentDate,
      sourceFile:
          'DeduplicatedProduct (${deduped.totalInvestments} inwestycji)',
      status: deduped.status,
      companyName: deduped.companyName,
      companyId: deduped.companyId,
      maturityDate: deduped.maturityDate,
      interestRate: deduped.interestRate,
      remainingCapital: deduped.totalRemainingCapital,
      clientCount: deduped.uniqueInvestors,
      totalValue: deduped.totalValue,
      currency: 'PLN',

      // Zachowaj oryginalne dane
      originalProduct: deduped,
      additionalInfo: {
        'source': 'deduplicated_product',
        'totalInvestments': deduped.totalInvestments,
        'actualInvestorCount': deduped.actualInvestorCount,
        'averageInvestment': deduped.averageInvestment,
        'originalInvestmentIds': deduped.originalInvestmentIds,
        ...deduped.metadata,
      },
    );
  }

  /// Konwertuje DeduplicatedProduct na OptimizedProduct
  static OptimizedProduct deduplicatedToOptimized(DeduplicatedProduct deduped) {
    return OptimizedProduct(
      id: deduped.id,
      name: deduped.name,
      productType: deduped.productType,
      companyName: deduped.companyName,
      companyId: deduped.companyId,
      totalValue: deduped.totalValue,
      totalRemainingCapital: deduped.totalRemainingCapital,
      totalInvestments: deduped.totalInvestments,
      uniqueInvestors: deduped.uniqueInvestors,
      actualInvestorCount: deduped.actualInvestorCount,
      averageInvestment: deduped.averageInvestment,
      interestRate: deduped.interestRate,
      earliestInvestmentDate: deduped.earliestInvestmentDate,
      latestInvestmentDate: deduped.latestInvestmentDate,
      status: deduped.status,
      topInvestors:
          [], // DeduplicatedProduct nie ma topInvestors - można by dodać konwersję
      metadata: deduped.metadata,
    );
  }

  // ============================================================================
  // 🔄 UNIFIED PRODUCT CONVERTERS
  // ============================================================================

  /// Konwertuje UnifiedProduct na OptimizedProduct (gdy to możliwe)
  /// UWAGA: Może prowadzić do utraty niektórych danych specificznych dla UnifiedProduct
  static OptimizedProduct? unifiedToOptimized(UnifiedProduct unified) {
    // Sprawdź czy UnifiedProduct ma wystarczające dane
    if (unified.additionalInfo['source'] == 'optimized_product' &&
        unified.originalProduct is OptimizedProduct) {
      return unified.originalProduct as OptimizedProduct;
    }

    // Utwórz nowy OptimizedProduct na podstawie dostępnych danych
    return OptimizedProduct(
      id: unified.id,
      name: unified.name,
      productType: unified.productType,
      companyName: unified.companyName ?? '',
      companyId: unified.companyId ?? '',
      totalValue: unified.totalValue,
      totalRemainingCapital: unified.remainingCapital ?? 0.0,
      totalInvestments: unified.additionalInfo['totalInvestments'] as int? ?? 1,
      uniqueInvestors: unified.clientCount ?? 1,
      actualInvestorCount:
          unified.additionalInfo['actualInvestorCount'] as int? ?? 1,
      averageInvestment:
          unified.additionalInfo['averageInvestment'] as double? ??
          unified.investmentAmount,
      interestRate: unified.interestRate ?? 0.0,
      earliestInvestmentDate: unified.createdAt,
      latestInvestmentDate: unified.uploadedAt,
      status: unified.status,
      topInvestors: [], // Brak danych w UnifiedProduct
      metadata: unified.additionalInfo,
    );
  }

  /// Konwertuje UnifiedProduct na DeduplicatedProduct (gdy to możliwe)
  static DeduplicatedProduct? unifiedToDeduplicatedProduct(
    UnifiedProduct unified,
  ) {
    // Sprawdź czy UnifiedProduct ma wystarczające dane
    if (unified.additionalInfo['source'] == 'deduplicated_product' &&
        unified.originalProduct is DeduplicatedProduct) {
      return unified.originalProduct as DeduplicatedProduct;
    }

    // Utwórz nowy DeduplicatedProduct na podstawie dostępnych danych
    return DeduplicatedProduct(
      id: unified.id,
      name: unified.name,
      productType: unified.productType,
      companyId: unified.companyId ?? '',
      companyName: unified.companyName ?? '',
      totalValue: unified.totalValue,
      totalRemainingCapital: unified.remainingCapital ?? 0.0,
      totalInvestments: unified.additionalInfo['totalInvestments'] as int? ?? 1,
      uniqueInvestors: unified.clientCount ?? 1,
      actualInvestorCount:
          unified.additionalInfo['actualInvestorCount'] as int? ?? 1,
      averageInvestment:
          unified.additionalInfo['averageInvestment'] as double? ??
          unified.investmentAmount,
      earliestInvestmentDate: unified.createdAt,
      latestInvestmentDate: unified.uploadedAt,
      status: unified.status,
      interestRate: unified.interestRate ?? 0.0,
      maturityDate: unified.maturityDate,
      originalInvestmentIds:
          unified.additionalInfo['originalInvestmentIds'] as List<String>? ??
          [],
      metadata: unified.additionalInfo,
    );
  }

  // ============================================================================
  // 🧩 BATCH CONVERTERS - Konwersje list
  // ============================================================================

  /// Konwertuje listę OptimizedProduct na listę UnifiedProduct
  static List<UnifiedProduct> optimizedListToUnified(
    List<OptimizedProduct> optimizedProducts,
  ) {
    return optimizedProducts.map(optimizedToUnified).toList();
  }

  /// Konwertuje listę OptimizedProduct na listę DeduplicatedProduct
  static List<DeduplicatedProduct> optimizedListToDeduplicatedProducts(
    List<OptimizedProduct> optimizedProducts,
  ) {
    return optimizedProducts.map(optimizedToDeduplicatedProduct).toList();
  }

  /// Konwertuje listę DeduplicatedProduct na listę UnifiedProduct
  static List<UnifiedProduct> deduplicatedListToUnified(
    List<DeduplicatedProduct> deduplicatedProducts,
  ) {
    return deduplicatedProducts.map(deduplicatedToUnified).toList();
  }

  /// Konwertuje listę DeduplicatedProduct na listę OptimizedProduct
  static List<OptimizedProduct> deduplicatedListToOptimized(
    List<DeduplicatedProduct> deduplicatedProducts,
  ) {
    return deduplicatedProducts.map(deduplicatedToOptimized).toList();
  }

  /// Konwertuje listę UnifiedProduct na listę OptimizedProduct (gdzie możliwe)
  static List<OptimizedProduct> unifiedListToOptimized(
    List<UnifiedProduct> unifiedProducts,
  ) {
    return unifiedProducts
        .map(unifiedToOptimized)
        .where((opt) => opt != null)
        .cast<OptimizedProduct>()
        .toList();
  }

  /// Konwertuje listę UnifiedProduct na listę DeduplicatedProduct (gdzie możliwe)
  static List<DeduplicatedProduct> unifiedListToDeduplicatedProducts(
    List<UnifiedProduct> unifiedProducts,
  ) {
    return unifiedProducts
        .map(unifiedToDeduplicatedProduct)
        .where((dedup) => dedup != null)
        .cast<DeduplicatedProduct>()
        .toList();
  }

  // ============================================================================
  // 🔍 UTILITY METHODS
  // ============================================================================

  /// Sprawdza czy produkt można bezpiecznie skonwertować na OptimizedProduct
  static bool canConvertToOptimized(dynamic product) {
    if (product is OptimizedProduct) return true;
    if (product is DeduplicatedProduct) return true;
    if (product is UnifiedProduct) {
      return product.additionalInfo.containsKey('totalInvestments');
    }
    return false;
  }

  /// Sprawdza czy produkt można bezpiecznie skonwertować na DeduplicatedProduct
  static bool canConvertToDeduplicatedProduct(dynamic product) {
    if (product is DeduplicatedProduct) return true;
    if (product is OptimizedProduct) return true;
    if (product is UnifiedProduct) {
      return product.additionalInfo.containsKey('totalInvestments');
    }
    return false;
  }

  /// Sprawdza czy produkt można bezpiecznie skonwertować na UnifiedProduct
  static bool canConvertToUnified(dynamic product) {
    return product is OptimizedProduct ||
        product is DeduplicatedProduct ||
        product is UnifiedProduct;
  }

  /// Automatycznie wybiera najlepszy typ konwersji na podstawie źródła
  static UnifiedProduct convertToUnifiedAuto(dynamic product) {
    if (product is UnifiedProduct) return product;
    if (product is OptimizedProduct) return optimizedToUnified(product);
    if (product is DeduplicatedProduct) return deduplicatedToUnified(product);

    throw ArgumentError('Nieobsługiwany typ produktu: ${product.runtimeType}');
  }

  /// Automatycznie wybiera najlepszy typ konwersji na OptimizedProduct
  static OptimizedProduct? convertToOptimizedAuto(dynamic product) {
    if (product is OptimizedProduct) return product;
    if (product is DeduplicatedProduct) return deduplicatedToOptimized(product);
    if (product is UnifiedProduct) return unifiedToOptimized(product);

    return null;
  }

  /// Automatycznie wybiera najlepszy typ konwersji na DeduplicatedProduct
  static DeduplicatedProduct? convertToDeduplicatedProductAuto(
    dynamic product,
  ) {
    if (product is DeduplicatedProduct) return product;
    if (product is OptimizedProduct)
      return optimizedToDeduplicatedProduct(product);
    if (product is UnifiedProduct) return unifiedToDeduplicatedProduct(product);

    return null;
  }
}

/// 🔧 EXTENSION METHODS dla łatwiejszej konwersji
extension OptimizedProductConverterExtension on OptimizedProduct {
  UnifiedProduct toUnified() => ProductTypeConverters.optimizedToUnified(this);
  DeduplicatedProduct toDeduplicatedProduct() =>
      ProductTypeConverters.optimizedToDeduplicatedProduct(this);
}

extension DeduplicatedProductConverterExtension on DeduplicatedProduct {
  UnifiedProduct toUnified() =>
      ProductTypeConverters.deduplicatedToUnified(this);
  OptimizedProduct toOptimized() =>
      ProductTypeConverters.deduplicatedToOptimized(this);
}

extension UnifiedProductConverterExtension on UnifiedProduct {
  OptimizedProduct? toOptimized() =>
      ProductTypeConverters.unifiedToOptimized(this);
  DeduplicatedProduct? toDeduplicatedProduct() =>
      ProductTypeConverters.unifiedToDeduplicatedProduct(this);
}

extension ProductListConverterExtension<T> on List<T> {
  List<UnifiedProduct> toUnifiedProducts() {
    if (T == OptimizedProduct) {
      return ProductTypeConverters.optimizedListToUnified(
        cast<OptimizedProduct>(),
      );
    } else if (T == DeduplicatedProduct) {
      return ProductTypeConverters.deduplicatedListToUnified(
        cast<DeduplicatedProduct>(),
      );
    } else if (T == UnifiedProduct) {
      return cast<UnifiedProduct>();
    }
    throw ArgumentError('Nieobsługiwany typ listy: $T');
  }

  List<OptimizedProduct> toOptimizedProducts() {
    if (T == OptimizedProduct) {
      return cast<OptimizedProduct>();
    } else if (T == DeduplicatedProduct) {
      return ProductTypeConverters.deduplicatedListToOptimized(
        cast<DeduplicatedProduct>(),
      );
    } else if (T == UnifiedProduct) {
      return ProductTypeConverters.unifiedListToOptimized(
        cast<UnifiedProduct>(),
      );
    }
    throw ArgumentError('Nieobsługiwany typ listy: $T');
  }

  List<DeduplicatedProduct> toDeduplicatedProducts() {
    if (T == DeduplicatedProduct) {
      return cast<DeduplicatedProduct>();
    } else if (T == OptimizedProduct) {
      return ProductTypeConverters.optimizedListToDeduplicatedProducts(
        cast<OptimizedProduct>(),
      );
    } else if (T == UnifiedProduct) {
      return ProductTypeConverters.unifiedListToDeduplicatedProducts(
        cast<UnifiedProduct>(),
      );
    }
    throw ArgumentError('Nieobsługiwany typ listy: $T');
  }
}
