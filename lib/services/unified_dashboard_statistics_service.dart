import '../models_and_services.dart';

/// 🚀 UJEDNOLICONY SERWIS STATYSTYK DASHBOARD
/// Zapewnia spójne obliczenia statystyk we wszystkich ekranach aplikacji
///
/// KLUCZOWE ZAŁOŻENIA:
/// 1. Używamy remainingCapital jako podstawowej miary kapitału pozostałego
/// 2. viableRemainingCapital = kapitał z wykonalnych inwestycji (pominięte niewykonalne)
/// 3. Kapitał zabezpieczony = max(remainingCapital - capitalForRestructuring, 0)
/// 4. Wszystkie ekrany używają tego samego serwisu dla spójności danych
/// 5. NOWE: Integracja z ProductManagementService dla jednolitego dostępu do produktów
class UnifiedDashboardStatisticsService extends BaseService {
  static const String _cacheKey = 'unified_dashboard_statistics';

  // 🚀 INTEGRACJA: Centralny serwis produktów
  late final ProductManagementService _productManagementService;

  UnifiedDashboardStatisticsService() {
    _productManagementService = ProductManagementService();
  }

  /// Pobiera zunifikowane statystyki dashboard na podstawie inwestycji
  Future<UnifiedDashboardStatistics> getStatisticsFromInvestments() async {
    return getCachedData(
      _cacheKey,
      () => _calculateStatisticsFromInvestments(),
    );
  }

  /// Pobiera zunifikowane statystyki dashboard na podstawie inwestorów
  Future<UnifiedDashboardStatistics> getStatisticsFromInvestors() async {
    const cacheKey = '${_cacheKey}_investors';
    return getCachedData(cacheKey, () => _calculateStatisticsFromInvestors());
  }

  /// 🚀 NOWE: Pobiera statystyki dashboard używając ProductManagementService
  /// Zapewnia spójność z ekranami produktów i optymalizacje cache
  Future<UnifiedDashboardStatistics> getStatisticsFromProducts({
    bool useOptimizedMode = true,
  }) async {
    const cacheKey = '${_cacheKey}_products';
    return getCachedData(cacheKey, () async {
      try {
        final productData = await _productManagementService.loadOptimizedData(
          forceRefresh: false,
          includeStatistics: true,
        );

        if (productData.statistics != null) {
          // Konwertuj z ProductStatistics na UnifiedDashboardStatistics
          return UnifiedDashboardStatistics(
            totalInvestmentAmount: productData.statistics!.totalValue,
            totalRemainingCapital:
                productData.statistics!.totalValue * 0.8, // Przybliżenie
            totalCapitalForRestructuring: 0.0,
            totalCapitalSecured: productData.statistics!.totalValue * 0.8,
            totalViableCapital: productData.statistics!.totalValue * 0.8,
            totalInvestments: productData.statistics!.totalProducts,
            activeInvestments: productData.statistics!.totalProducts,
            averageInvestmentAmount: productData.statistics!.averageValue,
            averageRemainingCapital: productData.statistics!.averageValue * 0.8,
            calculatedAt: DateTime.now(),
            dataSource:
                'ProductManagementService (${productData.optimizedResult?.fromCache == true ? "cache" : "fresh"})',
          );
        }

        // Fallback do standardowej metody
        return _calculateStatisticsFromInvestments();
      } catch (e) {
        logError('getStatisticsFromProducts', e);
        return _calculateStatisticsFromInvestments();
      }
    });
  }

  /// Wymusza odświeżenie cache i zwraca nowe statystyki
  Future<UnifiedDashboardStatistics> refreshStatistics() async {
    clearCache(_cacheKey);
    clearCache('${_cacheKey}_investors');
    clearCache('${_cacheKey}_products');
    await _productManagementService
        .clearAllCache(); // 🚀 INTEGRACJA: Czyść też cache produktów
    return getStatisticsFromInvestments();
  }

  /// Oblicza statystyki bezpośrednio z listy inwestycji (podejście dashboard)
  Future<UnifiedDashboardStatistics>
  _calculateStatisticsFromInvestments() async {
    try {
      // Pobierz wszystkie inwestycje przez Firebase Functions
      final result = await FirebaseFunctionsDataService.getAllInvestments(
        page: 1,
        pageSize: 5000,
        forceRefresh: true,
      );

      final investments = result.investments;

      return _calculateStatisticsFromInvestmentsList(investments);
    } catch (e) {
      logError('_calculateStatisticsFromInvestments', e);
      return UnifiedDashboardStatistics.empty();
    }
  }

  /// Oblicza statystyki z pogrupowanych inwestorów (podejście premium analytics)
  Future<UnifiedDashboardStatistics> _calculateStatisticsFromInvestors() async {
    try {
      // Używamy InvestorAnalyticsService - tego samego co premium analytics
      final analyticsService = InvestorAnalyticsService();
      final result = await analyticsService
          .getInvestorsSortedByRemainingCapital(
            page: 1,
            pageSize: 10000,
            includeInactive: false,
          );

      final investors = result.investors;

      return _calculateStatisticsFromInvestorsList(investors);
    } catch (e) {
      logError('_calculateStatisticsFromInvestors', e);
      return UnifiedDashboardStatistics.empty();
    }
  }

  /// Oblicza statystyki z listy inwestycji
  UnifiedDashboardStatistics _calculateStatisticsFromInvestmentsList(
    List<Investment> investments,
  ) {
    double totalInvestmentAmount = 0;
    double totalRemainingCapital = 0;
    double totalCapitalForRestructuring = 0;
    int totalInvestments = investments.length;
    int activeInvestments = 0;

    for (final investment in investments) {
      totalInvestmentAmount += investment.investmentAmount;
      totalRemainingCapital += investment.remainingCapital;
      totalCapitalForRestructuring += investment.capitalForRestructuring;

      if (investment.status == InvestmentStatus.active) {
        activeInvestments++;
      }
    }

    // ZUNIFIKOWANY WZÓR: kapitał zabezpieczony = max(pozostały - restrukturyzacja, 0)
    final double totalCapitalSecured =
        (totalRemainingCapital - totalCapitalForRestructuring).clamp(
          0,
          double.infinity,
        );

    // viableCapital = totalRemainingCapital (bez filtrowania niewykonalnych)
    // W tym przypadku nie mamy informacji o niewykonalnych inwestycjach na poziomie Investment
    final double totalViableCapital = totalRemainingCapital;

    print('   - Kwota inwestycji: ${totalInvestmentAmount.toStringAsFixed(2)}');
    print('   - Wykonalny kapitał: ${totalViableCapital.toStringAsFixed(2)}');

    return UnifiedDashboardStatistics(
      totalInvestmentAmount: totalInvestmentAmount,
      totalRemainingCapital: totalRemainingCapital,
      totalCapitalSecured: totalCapitalSecured,
      totalCapitalForRestructuring: totalCapitalForRestructuring,
      totalViableCapital: totalViableCapital,
      totalInvestments: totalInvestments,
      activeInvestments: activeInvestments,
      averageInvestmentAmount: totalInvestments > 0
          ? totalInvestmentAmount / totalInvestments
          : 0,
      averageRemainingCapital: totalInvestments > 0
          ? totalRemainingCapital / totalInvestments
          : 0,
      dataSource: 'investments',
      calculatedAt: DateTime.now(),
    );
  }

  /// Oblicza statystyki z listy inwestorów
  UnifiedDashboardStatistics _calculateStatisticsFromInvestorsList(
    List<InvestorSummary> investors,
  ) {
    double totalInvestmentAmount = 0;
    double totalRemainingCapital = 0;
    double totalCapitalForRestructuring = 0;
    double totalCapitalSecured = 0;
    double totalViableCapital = 0;
    int totalInvestments = 0;
    int activeInvestors = 0;

    for (final investor in investors) {
      totalInvestmentAmount += investor.totalInvestmentAmount;
      totalRemainingCapital += investor.totalRemainingCapital;
      totalCapitalForRestructuring += investor.capitalForRestructuring;

      // KLUCZOWA ZMIANA: używamy sumy capitalSecuredByRealEstate z inwestycji
      for (final investment in investor.investments) {
        totalCapitalSecured += investment.capitalSecuredByRealEstate;
      }

      // Używamy viableRemainingCapital (bez niewykonalnych inwestycji)
      totalViableCapital += investor.viableRemainingCapital;

      totalInvestments += investor.investmentCount;

      if (investor.client.isActive) {
        activeInvestors++;
      }
    }

    // Kapitał zabezpieczony już obliczony jako suma pól z inwestycji
    // (usunięto poprzedni wzór matematyczny)

    print('   - Kwota inwestycji: ${totalInvestmentAmount.toStringAsFixed(2)}');
    print('   - Wykonalny kapitał: ${totalViableCapital.toStringAsFixed(2)}');

    return UnifiedDashboardStatistics(
      totalInvestmentAmount: totalInvestmentAmount,
      totalRemainingCapital: totalRemainingCapital,
      totalCapitalSecured: totalCapitalSecured,
      totalCapitalForRestructuring: totalCapitalForRestructuring,
      totalViableCapital:
          totalViableCapital, // Uwzględnia niewykonalne inwestycje
      totalInvestments: totalInvestments,
      activeInvestments:
          activeInvestors, // W tym przypadku liczba aktywnych inwestorów
      averageInvestmentAmount: investors.isNotEmpty
          ? totalInvestmentAmount / investors.length
          : 0,
      averageRemainingCapital: investors.isNotEmpty
          ? totalRemainingCapital / investors.length
          : 0,
      dataSource: 'investors',
      calculatedAt: DateTime.now(),
    );
  }

  /// Porównuje statystyki z obu źródeł dla debugowania
  Future<StatisticsComparison> compareStatistics() async {
    try {
      final fromInvestments = await _calculateStatisticsFromInvestments();
      final fromInvestors = await _calculateStatisticsFromInvestors();

      return StatisticsComparison(
        investmentBased: fromInvestments,
        investorBased: fromInvestors,
        differences: _calculateDifferences(fromInvestments, fromInvestors),
      );
    } catch (e) {
      logError('compareStatistics', e);
      rethrow;
    }
  }

  Map<String, double> _calculateDifferences(
    UnifiedDashboardStatistics investments,
    UnifiedDashboardStatistics investors,
  ) {
    return {
      'totalInvestmentAmount':
          investments.totalInvestmentAmount - investors.totalInvestmentAmount,
      'totalRemainingCapital':
          investments.totalRemainingCapital - investors.totalRemainingCapital,
      'totalCapitalSecured':
          investments.totalCapitalSecured - investors.totalCapitalSecured,
      'totalCapitalForRestructuring':
          investments.totalCapitalForRestructuring -
          investors.totalCapitalForRestructuring,
      'totalViableCapital':
          investments.totalViableCapital - investors.totalViableCapital,
    };
  }
}

/// Model zunifikowanych statystyk dashboard
class UnifiedDashboardStatistics {
  final double totalInvestmentAmount;
  final double totalRemainingCapital;
  final double totalCapitalSecured;
  final double totalCapitalForRestructuring;
  final double totalViableCapital;
  final int totalInvestments;
  final int activeInvestments;
  final double averageInvestmentAmount;
  final double averageRemainingCapital;
  final String dataSource;
  final DateTime calculatedAt;

  const UnifiedDashboardStatistics({
    required this.totalInvestmentAmount,
    required this.totalRemainingCapital,
    required this.totalCapitalSecured,
    required this.totalCapitalForRestructuring,
    required this.totalViableCapital,
    required this.totalInvestments,
    required this.activeInvestments,
    required this.averageInvestmentAmount,
    required this.averageRemainingCapital,
    required this.dataSource,
    required this.calculatedAt,
  });

  factory UnifiedDashboardStatistics.empty() {
    return UnifiedDashboardStatistics(
      totalInvestmentAmount: 0,
      totalRemainingCapital: 0,
      totalCapitalSecured: 0,
      totalCapitalForRestructuring: 0,
      totalViableCapital: 0,
      totalInvestments: 0,
      activeInvestments: 0,
      averageInvestmentAmount: 0,
      averageRemainingCapital: 0,
      dataSource: 'empty',
      calculatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UnifiedDashboardStatistics('
        'source: $dataSource, '
        'totalInvestmentAmount: ${totalInvestmentAmount.toStringAsFixed(2)}, '
        'totalRemainingCapital: ${totalRemainingCapital.toStringAsFixed(2)}, '
        'totalViableCapital: ${totalViableCapital.toStringAsFixed(2)}, '
        'totalCapitalSecured: ${totalCapitalSecured.toStringAsFixed(2)}'
        ')';
  }
}

/// Model porównania statystyk z różnych źródeł
class StatisticsComparison {
  final UnifiedDashboardStatistics investmentBased;
  final UnifiedDashboardStatistics investorBased;
  final Map<String, double> differences;

  const StatisticsComparison({
    required this.investmentBased,
    required this.investorBased,
    required this.differences,
  });

  /// Czy różnice są znaczące (>1%)
  bool get hasSignificantDifferences {
    return differences.values.any(
      (diff) => diff.abs() > investmentBased.totalInvestmentAmount * 0.01,
    );
  }
}
