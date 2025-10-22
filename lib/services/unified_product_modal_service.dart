import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';

/// 🎯 NOWY CENTRALNY SERWIS DLA MODALU PRODUKTU
/// 
/// Konsoliduje wszystkie operacje dotyczące modalów produktu:
/// - Pobieranie inwestorów
/// - Statystyki produktu  
/// - Cache management
/// - Synchronizacja między zakładkami
/// 
/// Zastępuje:
/// - UltraPreciseProductInvestorsService (w modal)
/// - ProductDetailsService (w tab)
/// - UnifiedProductService (częściowo)
/// - UnifiedInvestorCountService (częściowo)
class UnifiedProductModalService extends BaseService {
  final UltraPreciseProductInvestorsService _investorsService;
  final UnifiedProductService _productService;
  
  // Cache dla danych modalów
  final Map<String, ProductModalData> _modalCache = {};
  
  UnifiedProductModalService({
    UltraPreciseProductInvestorsService? investorsService,
    UnifiedProductService? productService,
  }) : _investorsService = investorsService ?? UltraPreciseProductInvestorsService(),
       _productService = productService ?? UnifiedProductService(),
       super();

  /// Pobiera pełne dane dla modalu produktu
  /// 
  /// Zwraca zsynchronizowane dane ze wszystkich źródeł:
  /// - Lista inwestorów
  /// - Statystyki obliczone
  /// - Świeże dane produktu
  /// - Cache metadata
  Future<ProductModalData> getProductModalData({
    required UnifiedProduct product,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'modal_${product.id}';
    
    // Sprawdź cache jeśli nie wymuszamy odświeżenia
    if (!forceRefresh && _modalCache.containsKey(cacheKey)) {
      final cached = _modalCache[cacheKey]!;
      if (cached.isValid) {
        return cached;
      }
    }
    
    try {
      // 1. Znajdź prawdziwy productId
      final realProductId = await _findRealProductId(product);
      
      // 2. Pobierz inwestorów
      final investorsResult = await _investorsService.getProductInvestors(
        productId: realProductId,
        productName: product.name,
        searchStrategy: 'productId',
        forceRefresh: forceRefresh,
      );
      
      // 3. Pobierz świeże dane produktu
      final freshProduct = await _productService.getProductById(product.id) ?? product;
      
      // 4. Oblicz statystyki
      final statistics = _calculateStatistics(investorsResult.investors);
      
      // 5. Utwórz dane modalu
      final modalData = ProductModalData(
        product: freshProduct,
        originalProduct: product,
        investors: investorsResult.investors,
        statistics: statistics,
        realProductId: realProductId,
        searchStrategy: investorsResult.searchStrategy,
        executionTime: investorsResult.executionTime,
        fromCache: investorsResult.fromCache,
        lastUpdated: DateTime.now(),
      );
      
      // 6. Zapisz w cache
      _modalCache[cacheKey] = modalData;
      
      return modalData;
      
    } catch (e) {
      rethrow;
    }
  }
  
  /// Odnajduje prawdziwy productId z Firebase
  Future<String> _findRealProductId(UnifiedProduct product) async {
    try {
      // Użyj Firebase bezpośrednio
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('investments')
          .where('productName', isEqualTo: product.name)
          .where('companyId', isEqualTo: product.companyId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        final productId = data['productId'] as String?;

        if (productId?.isNotEmpty == true) {
          return productId!;
        } else {
          return doc.id;
        }
      } else {
        return product.id;
      }
    } catch (e) {
      return product.id;
    }
  }
  
  /// Oblicza statystyki z danych inwestorów
  ProductModalStatistics _calculateStatistics(List<InvestorSummary> investors) {
    final totalInvestmentAmount = investors.fold<double>(
      0.0,
      (accumulator, investor) => accumulator + investor.totalInvestmentAmount,
    );
    
    final totalRemainingCapital = investors.fold<double>(
      0.0,
      (accumulator, investor) => accumulator + investor.totalRemainingCapital,
    );
    
    final totalCapitalSecuredByRealEstate = investors.fold<double>(
      0.0,
      (accumulator, investor) => accumulator + investor.capitalSecuredByRealEstate,
    );
    
    final profitLoss = totalRemainingCapital - totalInvestmentAmount;
    final profitLossPercentage = totalInvestmentAmount > 0
        ? (profitLoss / totalInvestmentAmount) * 100
        : 0.0;
    
    final activeInvestors = investors.where((i) => i.client.isActive).length;
    final inactiveInvestors = investors.length - activeInvestors;
    
    return ProductModalStatistics(
      totalInvestmentAmount: totalInvestmentAmount,
      totalRemainingCapital: totalRemainingCapital,
      totalCapitalSecuredByRealEstate: totalCapitalSecuredByRealEstate,
      profitLoss: profitLoss,
      profitLossPercentage: profitLossPercentage,
      totalInvestors: investors.length,
      activeInvestors: activeInvestors,
      inactiveInvestors: inactiveInvestors,
      averageCapitalPerInvestor: investors.isNotEmpty 
          ? totalRemainingCapital / investors.length 
          : 0.0,
    );
  }
  
  /// Wyczyść cache dla produktu
  Future<void> clearProductCache(String productId) async {
    final cacheKey = 'modal_$productId';
    _modalCache.remove(cacheKey);
    
    // Wyczyść cache w serwisach zależnych
    await _investorsService.clearCacheForProduct(productId);
    // _productService dziedziczy po BaseService ale nie ma metody clearCache
    // więc pomijamy tą część
  }
  
  /// Wyczyść cały cache
  @override
  Future<void> clearAllCache() async {
    _modalCache.clear();
    await _investorsService.clearAllCache();
  }
  
  /// Odśwież dane po edycji inwestycji
  Future<ProductModalData> refreshAfterEdit({
    required UnifiedProduct product,
  }) async {
    // Wyczyść cache
    clearProductCache(product.id);
    
    // Wymusz ponowne pobranie
    return await getProductModalData(
      product: product,
      forceRefresh: true,
    );
  }
}

/// Model danych dla modalu produktu
class ProductModalData {
  final UnifiedProduct product;
  final UnifiedProduct originalProduct;
  final List<InvestorSummary> investors;
  final ProductModalStatistics statistics;
  final String realProductId;
  final String searchStrategy;
  final int executionTime;
  final bool fromCache;
  final DateTime lastUpdated;
  
  ProductModalData({
    required this.product,
    required this.originalProduct,
    required this.investors,
    required this.statistics,
    required this.realProductId,
    required this.searchStrategy,
    required this.executionTime,
    required this.fromCache,
    required this.lastUpdated,
  });
  
  /// Sprawdza czy cache jest nadal ważny (5 minut TTL)
  bool get isValid {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    return difference.inMinutes < 5;
  }
}

/// Model statystyk produktu
class ProductModalStatistics {
  final double totalInvestmentAmount;
  final double totalRemainingCapital;
  final double totalCapitalSecuredByRealEstate;
  final double profitLoss;
  final double profitLossPercentage;
  final int totalInvestors;
  final int activeInvestors;
  final int inactiveInvestors;
  final double averageCapitalPerInvestor;
  
  ProductModalStatistics({
    required this.totalInvestmentAmount,
    required this.totalRemainingCapital,
    required this.totalCapitalSecuredByRealEstate,
    required this.profitLoss,
    required this.profitLossPercentage,
    required this.totalInvestors,
    required this.activeInvestors,
    required this.inactiveInvestors,
    required this.averageCapitalPerInvestor,
  });
}