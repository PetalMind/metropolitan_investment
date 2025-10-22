import '../models_and_services.dart';

/// 🎯 UJEDNOLICONY SERWIS LICZBY INWESTORÓW
///
/// ⚠️ PROBLEM ROZWIĄZANY: Synchronizacja z ProductDetailsService
/// 
/// PRZED: UnifiedInvestorCountService używał _findRealProductId() aby znaleźć "prawdziwy" 
/// productId z Firebase, podczas gdy ProductDetailsService używał bezpośrednio product.id.
/// To powodowało rozbieżności w liczbie inwestorów między kartą produktu a modalem.
///
/// PO: Oba serwisy używają tej samej logiki - bezpośrednio product.id bez dodatkowego
/// mapowania, co zapewnia spójność danych.
///
/// Centralizuje logikę pobierania liczby inwestorów dla produktów
/// Zapewnia spójność między różnymi miejscami w aplikacji
class UnifiedInvestorCountService extends BaseService {
  static const String _cacheKeyPrefix = 'investor_count_v1_';

  final UltraPreciseProductInvestorsService _ultraPreciseService;

  UnifiedInvestorCountService()
    : _ultraPreciseService = UltraPreciseProductInvestorsService();

  /// Pobiera liczbę inwestorów dla produktu
  ///
  /// Strategia:
  /// 1. Sprawdź cache
  /// 2. Użyj UltraPreciseProductInvestorsService
  /// 3. Fallback na liczenie z investments collection
  Future<int> getProductInvestorCount(UnifiedProduct product) async {
    final cacheKey = '$_cacheKeyPrefix${product.id}';

    return getCachedData(cacheKey, () => _fetchInvestorCount(product));
  }

  /// Pobiera liczbę inwestorów dla wielu produktów jednocześnie
  Future<Map<String, int>> getMultipleProductInvestorCounts(
    List<UnifiedProduct> products,
  ) async {
    final Map<String, int> results = {};

    // Pobierz w batch'ach aby nie przeciążyć systemu
    const batchSize = 10;
    for (int i = 0; i < products.length; i += batchSize) {
      final batch = products.skip(i).take(batchSize).toList();

      final batchResults = await Future.wait(
        batch.map((product) => getProductInvestorCount(product)),
      );

      for (int j = 0; j < batch.length; j++) {
        results[batch[j].id] = batchResults[j];
      }

      // Króoka przerwa między batch'ami
      if (i + batchSize < products.length) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    return results;
  }

  /// Wewnętrzna metoda pobierania liczby inwestorów
  Future<int> _fetchInvestorCount(UnifiedProduct product) async {
    try {
      // ⭐ ZSYNCHRONIZOWANE: Używaj bezpośrednio product.id tak jak ProductDetailsService
      
      // Strategia 1: Użyj UltraPreciseProductInvestorsService z tym samym ID co ProductDetailsService
      try {
        final result = await _ultraPreciseService.getProductInvestors(
          productId: product.id, // ⭐ ZSYNCHRONIZOWANE: Używamy product.id bezpośrednio
          productName: product.name,
          searchStrategy: 'productId', // Ultra-precyzyjne wyszukiwanie po ID
        );

        final count = result.investors.length;

        return count;
      } catch (e) {
        // Continue to fallback
      }

      // Strategia 2: Fallback - bezpośrednie zapytanie do Firebase
      try {
        final snapshot = await firestore
            .collection('investments')
            .where('productName', isEqualTo: product.name)
            .where('companyId', isEqualTo: product.companyId ?? '')
            .get();

        // Policz unikalne clientId
        final uniqueClients = snapshot.docs
            .map((doc) => doc.data()['clientId'] as String?)
            .where((clientId) => clientId != null && clientId.isNotEmpty)
            .toSet()
            .length;

        return uniqueClients;
      } catch (e) {
        // Continue to return 0
      }

      return 0;
    } catch (e) {
      logError('_fetchInvestorCount for ${product.id}', e);
      return 0;
    }
  }

  /// Czyści cache dla konkretnego produktu
  void clearProductCache(String productId) {
    clearCache('$_cacheKeyPrefix$productId');
  }

  /// Czyści cały cache
  @override
  void clearAllCache() {
    // Ta metoda wyczyści cache dla wszystkich produktów
    super.clearAllCache();

    // Async clear dla _ultraPreciseService (bez czekania)
    _ultraPreciseService.clearAllCache().catchError((e) {
      // Ignore errors in cache clearing
    });
  }

  /// 🎯 NOWE: Force refresh dla konkretnego produktu
  /// Wyczyści cache i ponownie pobierze dane
  Future<int> forceRefreshProductInvestorCount(UnifiedProduct product) async {
    clearProductCache(product.id);
    return await getProductInvestorCount(product);
  }
}
