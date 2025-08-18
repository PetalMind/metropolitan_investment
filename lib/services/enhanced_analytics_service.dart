import '../models_and_services.dart';
import 'optimized_data_cache_service.dart' as cache;

/// 🚀 ULEPSZONY SERWIS ANALITYKI
/// Wykorzystuje OptimizedDataCacheService dla maksymalnej wydajności
/// i eliminuje duplikację zapytań do bazy danych
class EnhancedAnalyticsService extends BaseService {
  final cache.OptimizedDataCacheService _cacheService = cache.OptimizedDataCacheService();

  /// Pobiera inwestorów z zaawansowaną paginacją i filtrowaniem
  Future<EnhancedInvestorResult> getOptimizedInvestors({
    int page = 1,
    int pageSize = 250,
    String sortBy = 'viableCapital',
    bool sortAscending = false,
    bool includeInactive = false,
    VotingStatus? votingStatusFilter,
    ClientType? clientTypeFilter,
    bool showOnlyWithUnviableInvestments = false,
    String? searchQuery,
    bool forceRefresh = false,
  }) async {
    final startTime = DateTime.now();
    
    try {
      // Pobierz kompletne dane z cache
      final summary = await _cacheService.getCompleteAnalyticsData(
        forceRefresh: forceRefresh,
        includeInactive: includeInactive,
      );

      // Filtruj inwestorów według kryteriów
      var filteredInvestors = _cacheService.filterInvestors(
        votingStatusFilter: votingStatusFilter,
        clientTypeFilter: clientTypeFilter,
        showOnlyWithUnviableInvestments: showOnlyWithUnviableInvestments,
        searchQuery: searchQuery,
      );

      // Sortowanie
      _sortInvestors(filteredInvestors, sortBy, sortAscending);

      // Oblicz metryki przed paginacją
      final totalViableCapital = filteredInvestors.fold<double>(
        0.0,
        (sum, investor) => sum + investor.viableRemainingCapital,
      );

      // Paginacja
      final totalCount = filteredInvestors.length;
      final totalPages = (totalCount / pageSize).ceil();
      final startIndex = (page - 1) * pageSize;
      final endIndex = (startIndex + pageSize).clamp(0, totalCount);
      final paginatedInvestors = filteredInvestors.sublist(startIndex, endIndex);

      final processingTime = DateTime.now().difference(startTime);

      return EnhancedInvestorResult(
        investors: paginatedInvestors,
        totalCount: totalCount,
        currentPage: page,
        totalPages: totalPages,
        pageSize: pageSize,
        totalViableCapital: totalViableCapital,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
        globalMetrics: {
          'totalInvestorCount': summary.globalMetrics.totalInvestorCount,
          'totalViableCapital': summary.globalMetrics.totalViableCapital,
          'totalInvestmentAmount': summary.globalMetrics.totalInvestmentAmount,
        },
        votingDistribution: summary.globalMetrics.votingDistribution,
        processingTimeMs: processingTime.inMilliseconds,
        cacheSource: summary.cacheSource,
        dataProcessingEfficiency: summary.dataProcessingEfficiency,
      );

    } catch (e) {
      logError('getOptimizedInvestors', e);
      rethrow;
    }
  }

  /// Analiza kontroli większościowej z wykorzystaniem cache
  Future<EnhancedMajorityControlAnalysis> analyzeMajorityControl({
    bool includeInactive = false,
    double controlThreshold = 51.0,
  }) async {
    try {
      final summary = await _cacheService.getCompleteAnalyticsData(
        includeInactive: includeInactive,
      );

      final investors = summary.investors;
      if (investors.isEmpty) {
        return EnhancedMajorityControlAnalysis.empty();
      }

      // Sortuj według kapitału pozostałego
      final sortedInvestors = List<InvestorSummary>.from(investors);
      sortedInvestors.sort(
        (a, b) => b.viableRemainingCapital.compareTo(a.viableRemainingCapital),
      );

      final totalViableCapital = summary.globalMetrics.totalViableCapital;
      final controlThresholdAmount = totalViableCapital * (controlThreshold / 100);

      // Znajdź inwestorów tworzących próg kontrolny
      final List<InvestorWithControlInfo> controlInvestors = [];
      final List<InvestorWithControlInfo> allInvestorsWithInfo = [];
      double cumulativeCapital = 0.0;

      for (final investor in sortedInvestors) {
        final previousCumulative = cumulativeCapital;
        cumulativeCapital += investor.viableRemainingCapital;

        final controlPercentage = totalViableCapital > 0
            ? (investor.viableRemainingCapital / totalViableCapital) * 100
            : 0.0;
        final cumulativePercentage = totalViableCapital > 0
            ? (cumulativeCapital / totalViableCapital) * 100
            : 0.0;

        final investorInfo = InvestorWithControlInfo(
          summary: investor,
          controlPercentage: controlPercentage,
          cumulativePercentage: cumulativePercentage,
          isInControlGroup: previousCumulative < controlThresholdAmount,
        );

        allInvestorsWithInfo.add(investorInfo);

        if (previousCumulative < controlThresholdAmount) {
          controlInvestors.add(investorInfo);
        }
      }

      final controlGroupCapital = controlInvestors.fold<double>(
        0.0,
        (sum, investor) => sum + investor.summary.viableRemainingCapital,
      );

      return EnhancedMajorityControlAnalysis(
        allInvestors: allInvestorsWithInfo,
        controlGroupInvestors: controlInvestors,
        totalViableCapital: totalViableCapital,
        controlGroupCapital: controlGroupCapital,
        controlGroupCount: controlInvestors.length,
        controlThreshold: controlThreshold,
        analysisDate: DateTime.now(),
        dataSource: summary.cacheSource,
        votingDistribution: summary.globalMetrics.votingDistribution,
      );

    } catch (e) {
      logError('analyzeMajorityControl', e);
      return EnhancedMajorityControlAnalysis.empty();
    }
  }

  /// Analiza rozkładu kapitału według statusów głosowania
  Future<EnhancedVotingDistribution> analyzeVotingDistribution({
    bool includeInactive = false,
  }) async {
    try {
      final summary = await _cacheService.getCompleteAnalyticsData(
        includeInactive: includeInactive,
      );

      return EnhancedVotingDistribution(
        capitalByStatus: summary.globalMetrics.votingDistribution
            .map((status, info) => MapEntry(status, info.capital)),
        countByStatus: summary.globalMetrics.votingDistribution
            .map((status, info) => MapEntry(status, info.count)),
        totalCapital: summary.globalMetrics.totalViableCapital,
        totalInvestors: summary.investors.length,
        analysisDate: summary.globalMetrics.calculatedAt,
        dataSource: summary.cacheSource,
        averageCapitalPerStatus: _calculateAverageCapitalPerStatus(
          summary.globalMetrics.votingDistribution,
        ),
      );

    } catch (e) {
      logError('analyzeVotingDistribution', e);
      return EnhancedVotingDistribution.empty();
    }
  }

  /// Pobiera statystyki dashboard z cache
  Future<EnhancedDashboardStatistics> getDashboardStatistics({
    bool forceRefresh = false,
  }) async {
    try {
      final summary = await _cacheService.getCompleteAnalyticsData(
        forceRefresh: forceRefresh,
        includeInactive: false,
      );

      final metrics = summary.globalMetrics;

      return EnhancedDashboardStatistics(
        totalInvestorCount: metrics.totalInvestorCount,
        activeInvestorCount: metrics.activeInvestorCount,
        totalInvestmentAmount: metrics.totalInvestmentAmount,
        totalRemainingCapital: metrics.totalRemainingCapital,
        totalViableCapital: metrics.totalViableCapital,
        averageInvestmentPerInvestor: metrics.averageInvestmentPerInvestor,
        averageCapitalPerInvestor: metrics.averageCapitalPerInvestor,
        majorityControlThreshold: metrics.majorityControlThreshold,
        votingDistribution: metrics.votingDistribution,
        calculatedAt: metrics.calculatedAt,
        dataSource: summary.cacheSource,
        processingTimeMs: summary.processingTimeMs,
        dataProcessingEfficiency: summary.dataProcessingEfficiency,
      );

    } catch (e) {
      logError('getDashboardStatistics', e);
      rethrow;
    }
  }

  /// Sortuje inwestorów według wybranego kryterium
  void _sortInvestors(
    List<InvestorSummary> investors,
    String sortBy,
    bool sortAscending,
  ) {
    investors.sort((a, b) {
      late final int comparison;

      switch (sortBy) {
        case 'name':
          comparison = a.client.name.compareTo(b.client.name);
          break;
        case 'totalValue':
        case 'viableCapital':
        case 'viableRemainingCapital':
          comparison = a.viableRemainingCapital.compareTo(b.viableRemainingCapital);
          break;
        case 'investmentCount':
          comparison = a.investments.length.compareTo(b.investments.length);
          break;
        case 'votingStatus':
          comparison = a.client.votingStatus.index.compareTo(b.client.votingStatus.index);
          break;
        case 'totalInvestmentAmount':
          comparison = a.totalInvestmentAmount.compareTo(b.totalInvestmentAmount);
          break;
        case 'capitalSecuredByRealEstate':
          comparison = a.capitalSecuredByRealEstate.compareTo(b.capitalSecuredByRealEstate);
          break;
        case 'capitalForRestructuring':
          comparison = a.capitalForRestructuring.compareTo(b.capitalForRestructuring);
          break;
        default:
          comparison = a.viableRemainingCapital.compareTo(b.viableRemainingCapital);
      }

      return sortAscending ? comparison : -comparison;
    });
  }

  /// Oblicza średni kapitał na status głosowania
  Map<VotingStatus, double> _calculateAverageCapitalPerStatus(
    Map<VotingStatus, VotingCapitalInfo> distribution,
  ) {
    return distribution.map((status, info) {
      final average = info.count > 0 ? info.capital / info.count : 0.0;
      return MapEntry(status, average);
    });
  }

  /// Aktualizuje status głosowania inwestora
  Future<bool> updateInvestorVotingStatus(
    String clientId,
    VotingStatus newStatus, {
    String? reason,
    String? editedBy,
  }) async {
    try {
      final clientService = ClientService();
      await clientService.updateClientFields(clientId, {
        'votingStatus': newStatus.name,
      });

      // Wyczyść cache aby wymusić odświeżenie danych
      _cacheService.clearAllCache();

      return true;
    } catch (e) {
      logError('updateInvestorVotingStatus', e);
      return false;
    }
  }

  /// Czyści cache i wymusza odświeżenie
  Future<void> refreshCache() async {
    _cacheService.clearAllCache();
    await _cacheService.getCompleteAnalyticsData(forceRefresh: true);
  }

  /// Zwraca status cache
  Map<String, dynamic> getCacheStatus() {
    return _cacheService.getCacheStatus();
  }

  /// Stream reaktywnych aktualizacji
  Stream<cache.InvestorAnalyticsSummary> get analyticsUpdates => 
      _cacheService.analyticsStream;
}

/// Ulepszony model wyników analizy inwestorów
class EnhancedInvestorResult {
  final List<InvestorSummary> investors;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final double totalViableCapital;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final Map<String, dynamic> globalMetrics;
  final Map<VotingStatus, VotingCapitalInfo> votingDistribution;
  final int processingTimeMs;
  final String cacheSource;
  final double dataProcessingEfficiency;

  const EnhancedInvestorResult({
    required this.investors,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.totalViableCapital,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.globalMetrics,
    required this.votingDistribution,
    required this.processingTimeMs,
    required this.cacheSource,
    required this.dataProcessingEfficiency,
  });

  double get averageViableCapital =>
      investors.isNotEmpty ? totalViableCapital / investors.length : 0.0;

  bool get isFromCache => cacheSource == 'cache';
}

/// Ulepszony model analizy kontroli większościowej
class EnhancedMajorityControlAnalysis {
  final List<InvestorWithControlInfo> allInvestors;
  final List<InvestorWithControlInfo> controlGroupInvestors;
  final double totalViableCapital;
  final double controlGroupCapital;
  final int controlGroupCount;
  final double controlThreshold;
  final DateTime analysisDate;
  final String dataSource;
  final Map<VotingStatus, VotingCapitalInfo> votingDistribution;

  const EnhancedMajorityControlAnalysis({
    required this.allInvestors,
    required this.controlGroupInvestors,
    required this.totalViableCapital,
    required this.controlGroupCapital,
    required this.controlGroupCount,
    required this.controlThreshold,
    required this.analysisDate,
    required this.dataSource,
    required this.votingDistribution,
  });

  factory EnhancedMajorityControlAnalysis.empty() {
    return EnhancedMajorityControlAnalysis(
      allInvestors: [],
      controlGroupInvestors: [],
      totalViableCapital: 0.0,
      controlGroupCapital: 0.0,
      controlGroupCount: 0,
      controlThreshold: 51.0,
      analysisDate: DateTime.now(),
      dataSource: 'empty',
      votingDistribution: {},
    );
  }

  double get controlGroupPercentage => totalViableCapital > 0
      ? (controlGroupCapital / totalViableCapital) * 100
      : 0.0;

  bool get hasControlGroup => controlGroupCount > 0;
}

/// Ulepszony model rozkładu głosowania
class EnhancedVotingDistribution {
  final Map<VotingStatus, double> capitalByStatus;
  final Map<VotingStatus, int> countByStatus;
  final double totalCapital;
  final int totalInvestors;
  final DateTime analysisDate;
  final String dataSource;
  final Map<VotingStatus, double> averageCapitalPerStatus;

  const EnhancedVotingDistribution({
    required this.capitalByStatus,
    required this.countByStatus,
    required this.totalCapital,
    required this.totalInvestors,
    required this.analysisDate,
    required this.dataSource,
    required this.averageCapitalPerStatus,
  });

  factory EnhancedVotingDistribution.empty() {
    return EnhancedVotingDistribution(
      capitalByStatus: {},
      countByStatus: {},
      totalCapital: 0.0,
      totalInvestors: 0,
      analysisDate: DateTime.now(),
      dataSource: 'empty',
      averageCapitalPerStatus: {},
    );
  }

  double getCapitalPercentage(VotingStatus status) {
    final capital = capitalByStatus[status] ?? 0.0;
    return totalCapital > 0 ? (capital / totalCapital) * 100 : 0.0;
  }

  double getCountPercentage(VotingStatus status) {
    final count = countByStatus[status] ?? 0;
    return totalInvestors > 0 ? (count / totalInvestors) * 100 : 0.0;
  }
}

/// Model ulepszonych statystyk dashboard
class EnhancedDashboardStatistics {
  final int totalInvestorCount;
  final int activeInvestorCount;
  final double totalInvestmentAmount;
  final double totalRemainingCapital;
  final double totalViableCapital;
  final double averageInvestmentPerInvestor;
  final double averageCapitalPerInvestor;
  final double majorityControlThreshold;
  final Map<VotingStatus, VotingCapitalInfo> votingDistribution;
  final DateTime calculatedAt;
  final String dataSource;
  final int processingTimeMs;
  final double dataProcessingEfficiency;

  const EnhancedDashboardStatistics({
    required this.totalInvestorCount,
    required this.activeInvestorCount,
    required this.totalInvestmentAmount,
    required this.totalRemainingCapital,
    required this.totalViableCapital,
    required this.averageInvestmentPerInvestor,
    required this.averageCapitalPerInvestor,
    required this.majorityControlThreshold,
    required this.votingDistribution,
    required this.calculatedAt,
    required this.dataSource,
    required this.processingTimeMs,
    required this.dataProcessingEfficiency,
  });

  double get totalCapitalUtilization => totalInvestmentAmount > 0
      ? (totalViableCapital / totalInvestmentAmount) * 100
      : 0.0;

  double get activeInvestorPercentage => totalInvestorCount > 0
      ? (activeInvestorCount / totalInvestorCount) * 100
      : 0.0;
}