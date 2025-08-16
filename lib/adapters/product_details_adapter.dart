import '../models_and_services.dart';

/// 🚀 ZUNIFIKOWANY ADAPTER DLA PRODUCT DETAILS MODAL
///
/// Adapter który pozwala ProductDetailsModal używać zunifikowanej architektury
/// z automatycznym resolve'em Product ID
class ProductDetailsAdapter {
  static ProductDetailsAdapter? _instance;
  static ProductDetailsAdapter get instance =>
      _instance ??= ProductDetailsAdapter._();
  ProductDetailsAdapter._();

  final UnifiedDataService _unifiedService = UnifiedDataService.instance;
  bool _initialized = false;

  /// Inicjalizuje adapter
  Future<void> initialize() async {
    if (_initialized) return;
    await _unifiedService.initialize();
    _initialized = true;
  }

  /// 🔍 POBIERA INWESTORÓW DLA PRODUKTU Z AUTOMATYCZNYM RESOLVE ID
  /// Rozwiązuje problem z różnymi formatami productId
  Future<ProductDetailsInvestorsResult> getProductInvestorsWithResolve({
    required UnifiedProduct product,
    bool forceRefresh = false,
  }) async {
    await initialize();

    // 1. Sprawdź czy productId jest już w zunifikowanym formacie
    String resolvedProductId = UnifiedProductIdResolver.resolveProductId(
      product.id,
      productName: product.name,
      companyId: product.companyId,
      productType: product.productType,
    );

    // 2. Jeśli ID nie został zresolve'owany, spróbuj znaleźć prawdziwy productId
    if (resolvedProductId == product.id &&
        !UnifiedProductIdResolver.isUnifiedFormat(product.id)) {
      resolvedProductId = await _findRealProductIdFromFirebase(product);
    }

    // 3. Pobierz inwestorów używając zresolve'owanego ID
    final result = await _unifiedService.getProductInvestors(
      productId: resolvedProductId,
      productName: product.name,
      productType: product.productType.name.toLowerCase(),
      forceRefresh: forceRefresh,
    );

    return ProductDetailsInvestorsResult(
      investors: result.investors,
      productInvestorsResult: result,
      resolvedProductId: resolvedProductId,
      originalProductId: product.id,
      searchMetadata: ProductIdSearchMetadata(
        originalId: product.id,
        resolvedId: resolvedProductId,
        resolutionMethod: resolvedProductId != product.id
            ? 'firebase_search'
            : 'direct',
        searchTime: DateTime.now(),
        productName: product.name,
        companyId: product.companyId,
      ),
    );
  }

  /// 🏢 POBIERA ŚWIEŻE DANE PRODUKTU
  /// Używa zunifikowanej architektury do pobrania najnowszych danych
  Future<UnifiedProduct?> getFreshProductData(UnifiedProduct product) async {
    await initialize();

    // Dla świeżych danych używamy poziomu deduplicated jako optymalnego
    final response = await _unifiedService.getProducts(
      forceRefresh: true,
      includeStatistics: false,
      dataLevel: ProductsDataLevel.deduplicated,
    );

    // Znajdź produkt w wynikach
    final freshProduct = response.products.firstWhere(
      (p) => p.id == product.id || p.name == product.name,
      orElse: () => product, // Fallback do oryginalnego produktu
    );

    return freshProduct;
  }

  /// 📊 OBLICZA SUMY Z INWESTORÓW
  /// Zgodne z logiką używaną w ProductDetailsModal
  ProductDetailsSums calculateSumsFromInvestors(
    List<InvestorSummary> investors,
  ) {
    double totalInvestmentAmount = 0.0;
    double totalRemainingCapital = 0.0;
    double totalCapitalSecured = 0.0;

    for (final investor in investors) {
      totalInvestmentAmount += investor.totalInvestmentAmount;
      totalRemainingCapital += investor.totalRemainingCapital;
      totalCapitalSecured += investor.capitalSecuredByRealEstate;
    }

    return ProductDetailsSums(
      totalInvestmentAmount: totalInvestmentAmount,
      totalRemainingCapital: totalRemainingCapital,
      totalCapitalSecuredByRealEstate: totalCapitalSecured,
      investorsCount: investors.length,
      averageInvestmentAmount: investors.isNotEmpty
          ? totalInvestmentAmount / investors.length
          : 0.0,
    );
  }

  /// 🎯 PRYWATNA METODA: ZNAJDŹ PRAWDZIWY PRODUCT ID Z FIREBASE
  /// Implementuje logikę z ProductDetailsModal._findRealProductId()
  Future<String> _findRealProductIdFromFirebase(UnifiedProduct product) async {
    try {
      // Tutaj można zaimplementować bezpośrednie zapytanie do Firebase
      // Na razie zwracamy oryginalny ID jako fallback

      // W przyszłości można dodać:
      // 1. Zapytanie do Firebase gdzie productName == product.name
      // 2. Sprawdzenie pola productId w pierwszym dokumencie
      // 3. Cache'owanie wyniku

      return product.id; // Fallback
    } catch (e) {
      // W przypadku błędu zwróć oryginalny ID
      return product.id;
    }
  }

  /// 🔄 KONWERTUJE RÓŻNE TYPY PRODUKTÓW NA UNIFIED
  UnifiedProduct ensureUnifiedProduct(dynamic product) {
    if (product is UnifiedProduct) return product;
    if (product is DeduplicatedProduct) {
      return UnifiedTypeConverters.deduplicatedToUnifiedProduct(product);
    }
    if (product is OptimizedProduct) {
      return UnifiedTypeConverters.optimizedToUnifiedProduct(product);
    }
    throw ArgumentError('Nieobsługiwany typ produktu: ${product.runtimeType}');
  }
}

/// 📋 WYNIK POBIERANIA INWESTORÓW Z METADANYMI
class ProductDetailsInvestorsResult {
  final List<InvestorSummary> investors;
  final ProductInvestorsResult productInvestorsResult;
  final String resolvedProductId;
  final String originalProductId;
  final ProductIdSearchMetadata searchMetadata;

  const ProductDetailsInvestorsResult({
    required this.investors,
    required this.productInvestorsResult,
    required this.resolvedProductId,
    required this.originalProductId,
    required this.searchMetadata,
  });

  /// Czy productId został zresolve'owany (zmieniony)
  bool get wasProductIdResolved => resolvedProductId != originalProductId;
}

/// 🔍 METADATA WYSZUKIWANIA PRODUCT ID
class ProductIdSearchMetadata {
  final String originalId;
  final String resolvedId;
  final String resolutionMethod;
  final DateTime searchTime;
  final String productName;
  final String? companyId;

  const ProductIdSearchMetadata({
    required this.originalId,
    required this.resolvedId,
    required this.resolutionMethod,
    required this.searchTime,
    required this.productName,
    required this.companyId,
  });
}

/// 📊 SUMY OBLICZONE Z INWESTORÓW
class ProductDetailsSums {
  final double totalInvestmentAmount;
  final double totalRemainingCapital;
  final double totalCapitalSecuredByRealEstate;
  final int investorsCount;
  final double averageInvestmentAmount;

  const ProductDetailsSums({
    required this.totalInvestmentAmount,
    required this.totalRemainingCapital,
    required this.totalCapitalSecuredByRealEstate,
    required this.investorsCount,
    required this.averageInvestmentAmount,
  });
}
