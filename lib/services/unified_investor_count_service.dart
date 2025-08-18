import 'package:flutter/foundation.dart';
import '../models_and_services.dart';

/// 🎯 UJEDNOLICONY SERWIS LICZBY INWESTORÓW
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
      if (kDebugMode) {
        print(
          '[UnifiedInvestorCount] Pobieranie liczby inwestorów dla: ${product.name}',
        );
      }

      // 🎯 NOWE: Znajdź prawdziwy productId tak samo jak w UnifiedProductModalService
      String realProductId = await _findRealProductId(product);

      // Strategia 1: Użyj UltraPreciseProductInvestorsService z prawdziwym productId
      try {
        final result = await _ultraPreciseService.getProductInvestors(
          productId: realProductId,
          productName: product.name,
          searchStrategy: 'productId',
        );

        final count = result.investors.length;

        if (kDebugMode) {
          print(
            '[UnifiedInvestorCount] UltraPrecise zwrócił: $count inwestorów',
          );
          print('[UnifiedInvestorCount] Użyty productId: $realProductId');
        }

        return count;
      } catch (e) {
        if (kDebugMode) {
          print('[UnifiedInvestorCount] UltraPrecise failed: $e');
        }
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

        if (kDebugMode) {
          print(
            '[UnifiedInvestorCount] Fallback zwrócił: $uniqueClients inwestorów',
          );
        }

        return uniqueClients;
      } catch (e) {
        if (kDebugMode) {
          print('[UnifiedInvestorCount] Fallback failed: $e');
        }
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

  /// 🎯 NOWE: Znajdź prawdziwy productId w Firebase (skopiowane z UnifiedProductModalService)
  Future<String> _findRealProductId(UnifiedProduct product) async {
    try {
      if (kDebugMode) {
        print('[UnifiedInvestorCount] Szukam prawdziwego productId...');
      }

      // Użyj Firebase bezpośrednio
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
          if (kDebugMode) {
            print('[UnifiedInvestorCount] Prawdziwy productId: $productId');
          }
          return productId!;
        } else {
          if (kDebugMode) {
            print('[UnifiedInvestorCount] Używam ID dokumentu: ${doc.id}');
          }
          return doc.id;
        }
      } else {
        if (kDebugMode) {
          print('[UnifiedInvestorCount] Fallback na oryginalny ID');
        }
        return product.id;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[UnifiedInvestorCount] Błąd szukania productId: $e');
      }
      return product.id;
    }
  }

  /// Czyści cały cache
  @override
  void clearAllCache() {
    // Ta metoda wyczyści cache dla wszystkich produktów
    super.clearAllCache();

    // Async clear dla _ultraPreciseService (bez czekania)
    _ultraPreciseService.clearAllCache().catchError((e) {
      if (kDebugMode) {
        print('[UnifiedInvestorCount] Error clearing UltraPrecise cache: $e');
      }
    });

    if (kDebugMode) {
      print('[UnifiedInvestorCount] Clearing all cache');
    }
  }

  /// 🎯 NOWE: Force refresh dla konkretnego produktu
  /// Wyczyści cache i ponownie pobierze dane
  Future<int> forceRefreshProductInvestorCount(UnifiedProduct product) async {
    clearProductCache(product.id);
    return await getProductInvestorCount(product);
  }
}
