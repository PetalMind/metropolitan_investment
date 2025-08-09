import 'package:cloud_functions/cloud_functions.dart';
import '../models/unified_product.dart';
import '../models/investor_summary.dart';
import '../models/client.dart';

/// Zoptymalizowany serwis do pobierania inwestorów produktów
/// Wykorzystuje Firebase Functions dla maksymalnej wydajności
class OptimizedProductInvestorsService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  /// Pobiera inwestorów dla produktu używając zoptymalizowanej Firebase Function
  Future<List<InvestorSummary>> getInvestorsForProduct(
    UnifiedProduct product, {
    bool forceRefresh = false,
  }) async {
    try {
      print('🚀 [OptimizedProductInvestors] Wywołuję Firebase Function...');
      print('  - Nazwa produktu: "${product.name}"');
      print('  - Typ produktu: ${product.productType.displayName}');

      final startTime = DateTime.now().millisecondsSinceEpoch;

      // Wywołaj zoptymalizowaną Firebase Function
      final result = await _functions
          .httpsCallable('getProductInvestorsOptimized')
          .call({
            'productName': product.name.isNotEmpty ? product.name : null,
            'productType': _mapProductTypeToString(product.productType),
            'searchStrategy': 'comprehensive', // Użyj komprehensywnej strategii
            'forceRefresh': forceRefresh,
          });

      final data = result.data as Map<String, dynamic>;
      final executionTime = DateTime.now().millisecondsSinceEpoch - startTime;

      print(
        '✅ [OptimizedProductInvestors] Odpowiedź otrzymana w ${executionTime}ms',
      );
      print('  - Znaleziono inwestorów: ${data['totalCount']}');
      print('  - Strategia wyszukiwania: ${data['searchStrategy']}');
      print('  - Z cache: ${data['fromCache'] == true}');
      print('  - Czas wykonania serwera: ${data['executionTime']}ms');

      // Konwertuj dane na obiekty InvestorSummary
      final investorsData = data['investors'] as List<dynamic>;
      final investors = investorsData.map((investorData) {
        return _convertToInvestorSummary(investorData);
      }).toList();

      // Wyloguj statystyki jeśli dostępne
      if (data['statistics'] != null) {
        final stats = data['statistics'] as Map<String, dynamic>;
        print('📊 [OptimizedProductInvestors] Statystyki:');
        print('  - Łączny kapitał: ${stats['totalCapital']}');
        print('  - Łączne inwestycje: ${stats['totalInvestments']}');
        print('  - Średni kapitał: ${stats['averageCapital']}');
        print('  - Aktywni inwestorzy: ${stats['activeInvestors']}');
      }

      // Wyloguj debug info jeśli dostępne
      if (data['debugInfo'] != null) {
        final debug = data['debugInfo'] as Map<String, dynamic>;
        print('🔍 [OptimizedProductInvestors] Debug:');
        print(
          '  - Przeskanowanych inwestycji: ${debug['totalInvestmentsScanned']}',
        );
        print('  - Dopasowanych inwestycji: ${debug['matchingInvestments']}');
        print('  - Klientów w bazie: ${debug['totalClients']}');
      }

      return investors;
    } catch (e) {
      print('❌ [OptimizedProductInvestors] Błąd: $e');

      // Fallback - zwróć pustą listę zamiast rzucać błąd
      if (e.toString().contains('Functions')) {
        print(
          '⚠️ [OptimizedProductInvestors] Problem z Firebase Functions - zwracam pustą listę',
        );
        return [];
      }

      rethrow;
    }
  }

  /// Pobiera inwestorów tylko po nazwie produktu (szybsza opcja)
  Future<List<InvestorSummary>> getInvestorsByProductName(
    String productName, {
    bool forceRefresh = false,
  }) async {
    try {
      print(
        '🎯 [OptimizedProductInvestors] Wyszukiwanie po nazwie: "$productName"',
      );

      final result = await _functions
          .httpsCallable('getProductInvestorsOptimized')
          .call({
            'productName': productName,
            'productType': null,
            'searchStrategy': 'exact', // Użyj dokładnego dopasowania
            'forceRefresh': forceRefresh,
          });

      final data = result.data as Map<String, dynamic>;
      final investorsData = data['investors'] as List<dynamic>;

      final investors = investorsData.map((investorData) {
        return _convertToInvestorSummary(investorData);
      }).toList();

      print(
        '✅ [OptimizedProductInvestors] Znaleziono ${investors.length} inwestorów po nazwie',
      );
      return investors;
    } catch (e) {
      print('❌ [OptimizedProductInvestors] Błąd wyszukiwania po nazwie: $e');
      return [];
    }
  }

  /// Pobiera inwestorów tylko po typie produktu
  Future<List<InvestorSummary>> getInvestorsByProductType(
    UnifiedProductType productType, {
    bool forceRefresh = false,
  }) async {
    try {
      print(
        '📊 [OptimizedProductInvestors] Wyszukiwanie po typie: ${productType.displayName}',
      );

      final result = await _functions
          .httpsCallable('getProductInvestorsOptimized')
          .call({
            'productName': null,
            'productType': _mapProductTypeToString(productType),
            'searchStrategy': 'type', // Użyj wyszukiwania po typie
            'forceRefresh': forceRefresh,
          });

      final data = result.data as Map<String, dynamic>;
      final investorsData = data['investors'] as List<dynamic>;

      final investors = investorsData.map((investorData) {
        return _convertToInvestorSummary(investorData);
      }).toList();

      print(
        '✅ [OptimizedProductInvestors] Znaleziono ${investors.length} inwestorów po typie',
      );
      return investors;
    } catch (e) {
      print('❌ [OptimizedProductInvestors] Błąd wyszukiwania po typie: $e');
      return [];
    }
  }

  /// Wyczyść cache dla konkretnego produktu
  Future<void> clearCacheForProduct(UnifiedProduct product) async {
    try {
      print(
        '🗑️ [OptimizedProductInvestors] Czyszczenie cache dla: "${product.name}"',
      );

      // Wywołaj funkcję z forceRefresh=true żeby odświeżyć cache
      await getInvestorsForProduct(product, forceRefresh: true);

      print('✅ [OptimizedProductInvestors] Cache wyczyszczony');
    } catch (e) {
      print('❌ [OptimizedProductInvestors] Błąd czyszczenia cache: $e');
    }
  }

  /// Konwertuje typ produktu na string używany przez Firebase Function
  String _mapProductTypeToString(UnifiedProductType type) {
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

  /// Konwertuje dane z Firebase Function na obiekt InvestorSummary
  InvestorSummary _convertToInvestorSummary(Map<String, dynamic> data) {
    // Konwertuj dane klienta
    final clientData = data['client'] as Map<String, dynamic>;
    final client = Client(
      id: clientData['id'] as String,
      name: clientData['name'] as String,
      email: clientData['email'] as String? ?? '',
      phone: clientData['phone'] as String? ?? '',
      address: '', // Domyślnie pusty dla uproszczenia
      companyName: clientData['companyName'] as String?,
      isActive: clientData['isActive'] as bool? ?? true,
      votingStatus: _parseVotingStatus(clientData['votingStatus'] as String?),
      createdAt: DateTime.now(), // Domyślna wartość
      updatedAt: DateTime.now(), // Domyślna wartość
    );

    // Wyciągnij kluczowe metryki
    final viableRemainingCapital =
        (data['viableRemainingCapital'] as num?)?.toDouble() ?? 0.0;
    final totalInvestmentAmount =
        (data['totalInvestmentAmount'] as num?)?.toDouble() ?? 0.0;
    final totalRealizedCapital =
        (data['totalRealizedCapital'] as num?)?.toDouble() ?? 0.0;
    final investmentCount = data['investmentCount'] as int? ?? 0;

    // Utwórz InvestorSummary z minimalnym konstruktorem
    return InvestorSummary(
      client: client,
      investments: const [], // Pusta lista dla uproszczenia
      totalRemainingCapital: viableRemainingCapital,
      totalSharesValue: 0.0, // Domyślnie 0
      totalValue: viableRemainingCapital,
      totalInvestmentAmount: totalInvestmentAmount,
      totalRealizedCapital: totalRealizedCapital,
      capitalSecuredByRealEstate: 0.0, // Domyślnie 0
      capitalForRestructuring: 0.0, // Domyślnie 0
      investmentCount: investmentCount,
    );
  }

  /// Parsuje status głosowania ze stringa
  VotingStatus _parseVotingStatus(String? status) {
    if (status == null) return VotingStatus.undecided;

    switch (status.toLowerCase()) {
      case 'yes':
      case 'tak':
        return VotingStatus.yes;
      case 'no':
      case 'nie':
        return VotingStatus.no;
      case 'abstain':
      case 'wstrzymuje':
        return VotingStatus.abstain;
      default:
        return VotingStatus.undecided;
    }
  }

  /// Pobiera statystyki wydajności serwisu
  Map<String, dynamic> getPerformanceStats() {
    return {
      'service': 'OptimizedProductInvestorsService',
      'version': '1.0.0',
      'backend': 'Firebase Functions (europe-west1)',
      'features': [
        'Server-side processing',
        'Intelligent caching',
        'Comprehensive search strategies',
        'Multi-collection support',
        'Real-time statistics',
      ],
      'advantages': [
        'Szybsze wyszukiwanie (server-side)',
        'Mniejsze obciążenie urządzenia',
        'Cache na poziomie serwera',
        'Lepsze skalowanie',
        'Zaawansowane strategie wyszukiwania',
      ],
    };
  }
}
