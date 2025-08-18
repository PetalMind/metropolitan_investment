import '../models_and_services.dart';
import 'enhanced_analytics_service.dart';
import 'investor_analytics_service.dart' as legacy;

/// 🚀 SERWIS MIGRACJI ANALITYKI
/// Umożliwia stopniowe przejście z starych serwisów na zoptymalizowane wersje
/// z zachowaniem kompatybilności wstecznej
class AnalyticsMigrationService {
  static final AnalyticsMigrationService _instance = AnalyticsMigrationService._internal();
  factory AnalyticsMigrationService() => _instance;
  AnalyticsMigrationService._internal();

  final EnhancedAnalyticsService _enhancedService = EnhancedAnalyticsService();
  final legacy.InvestorAnalyticsService _legacyService = legacy.InvestorAnalyticsService();
  
  // Flaga kontrolująca które serwisy używać
  bool useEnhancedServices = true;

  /// Adapter dla getInvestorsSortedByRemainingCapital
  /// Automatycznie przekierowuje na zoptymalizowany serwis lub legacy
  Future<legacy.InvestorAnalyticsResult> getInvestorsSortedByRemainingCapital({
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
    if (useEnhancedServices) {
      try {
        // Użyj nowego serwisu
        final enhancedResult = await _enhancedService.getOptimizedInvestors(
          page: page,
          pageSize: pageSize,
          sortBy: sortBy,
          sortAscending: sortAscending,
          includeInactive: includeInactive,
          votingStatusFilter: votingStatusFilter,
          clientTypeFilter: clientTypeFilter,
          showOnlyWithUnviableInvestments: showOnlyWithUnviableInvestments,
          searchQuery: searchQuery,
          forceRefresh: forceRefresh,
        );

        // Konwertuj na format legacy
        return legacy.InvestorAnalyticsResult(
          investors: enhancedResult.investors,
          totalCount: enhancedResult.totalCount,
          currentPage: enhancedResult.currentPage,
          totalPages: enhancedResult.totalPages,
          pageSize: enhancedResult.pageSize,
          totalViableCapital: enhancedResult.totalViableCapital,
          hasNextPage: enhancedResult.hasNextPage,
          hasPreviousPage: enhancedResult.hasPreviousPage,
        );
      } catch (e) {
        print('⚠️ [Migration] Enhanced service failed, falling back to legacy: $e');
        useEnhancedServices = false; // Automatic fallback
      }
    }

    // Fallback do legacy serwisu
    return _legacyService.getInvestorsSortedByRemainingCapital(
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      sortAscending: sortAscending,
      includeInactive: includeInactive,
      votingStatusFilter: votingStatusFilter,
      clientTypeFilter: clientTypeFilter,
      showOnlyWithUnviableInvestments: showOnlyWithUnviableInvestments,
    );
  }

  /// Adapter dla analyzeMajorityControl
  Future<MajorityControlAnalysis> analyzeMajorityControl({
    bool includeInactive = false,
    double controlThreshold = 51.0,
  }) async {
    if (useEnhancedServices) {
      try {
        final enhancedResult = await _enhancedService.analyzeMajorityControl(
          includeInactive: includeInactive,
          controlThreshold: controlThreshold,
        );

        // Konwertuj na format legacy
        return MajorityControlAnalysis(
          allInvestors: enhancedResult.allInvestors,
          controlGroupInvestors: enhancedResult.controlGroupInvestors,
          totalViableCapital: enhancedResult.totalViableCapital,
          controlGroupCapital: enhancedResult.controlGroupCapital,
          controlGroupCount: enhancedResult.controlGroupCount,
          controlThreshold: enhancedResult.controlThreshold,
          analysisDate: enhancedResult.analysisDate,
        );
      } catch (e) {
        print('⚠️ [Migration] Enhanced majority analysis failed, falling back: $e');
        useEnhancedServices = false;
      }
    }

    return await _legacyService.analyzeMajorityControl(
      includeInactive: includeInactive,
      controlThreshold: controlThreshold,
    );
  }

  /// Adapter dla analyzeVotingDistribution
  Future<VotingCapitalDistribution> analyzeVotingDistribution({
    bool includeInactive = false,
  }) async {
    if (useEnhancedServices) {
      try {
        final enhancedResult = await _enhancedService.analyzeVotingDistribution(
          includeInactive: includeInactive,
        );

        // Konwertuj na format legacy
        return VotingCapitalDistribution(
          capitalByStatus: enhancedResult.capitalByStatus,
          countByStatus: enhancedResult.countByStatus,
          totalCapital: enhancedResult.totalCapital,
          totalInvestors: enhancedResult.totalInvestors,
          analysisDate: enhancedResult.analysisDate,
        );
      } catch (e) {
        print('⚠️ [Migration] Enhanced voting analysis failed, falling back: $e');
        useEnhancedServices = false;
      }
    }

    return await _legacyService.analyzeVotingDistribution(
      includeInactive: includeInactive,
    );
  }

  /// Adapter dla updateInvestorDetails
  Future<void> updateInvestorDetails(
    String clientId, {
    VotingStatus? votingStatus,
    String? notes,
    String? colorCode,
    ClientType? type,
    bool? isActive,
    String? updateReason,
    String? editedBy,
    String? editedByEmail,
    String? editedByName,
    String? userId,
    String? updatedVia,
  }) async {
    if (useEnhancedServices && votingStatus != null) {
      try {
        final success = await _enhancedService.updateInvestorVotingStatus(
          clientId,
          votingStatus,
          reason: updateReason,
          editedBy: editedBy,
        );
        
        if (success) {
          // Jeśli tylko voting status, zakończ
          if (notes == null && colorCode == null && type == null && isActive == null) {
            return;
          }
        }
      } catch (e) {
        print('⚠️ [Migration] Enhanced update failed, falling back: $e');
      }
    }

    // Użyj legacy serwisu dla pełnej aktualizacji
    return await _legacyService.updateInvestorDetails(
      clientId,
      votingStatus: votingStatus,
      notes: notes,
      colorCode: colorCode,
      type: type,
      isActive: isActive,
      updateReason: updateReason,
      editedBy: editedBy,
      editedByEmail: editedByEmail,
      editedByName: editedByName,
      userId: userId,
      updatedVia: updatedVia,
    );
  }

  /// Uniwersalna metoda czyszczenia cache
  void clearAllCache() {
    _legacyService.clearAnalyticsCache();
    if (useEnhancedServices) {
      _enhancedService.refreshCache().catchError((e) {
        print('⚠️ [Migration] Failed to clear enhanced cache: $e');
      });
    }
  }

  /// Porównanie wydajności między serwisami
  Future<PerformanceComparison> comparePerformance({
    int testIterations = 3,
    int pageSize = 100,
  }) async {
    final legacyTimes = <int>[];
    final enhancedTimes = <int>[];

    print('📊 [Migration] Rozpoczynam porównanie wydajności...');

    // Test legacy serwisu
    for (int i = 0; i < testIterations; i++) {
      final stopwatch = Stopwatch()..start();
      try {
        await _legacyService.getInvestorsSortedByRemainingCapital(
          page: 1,
          pageSize: pageSize,
        );
        stopwatch.stop();
        legacyTimes.add(stopwatch.elapsedMilliseconds);
      } catch (e) {
        print('⚠️ [Migration] Legacy test failed: $e');
        legacyTimes.add(999999); // Penalty for failure
      }
      
      await Future.delayed(Duration(milliseconds: 100)); // Przerwa między testami
    }

    // Test enhanced serwisu
    for (int i = 0; i < testIterations; i++) {
      final stopwatch = Stopwatch()..start();
      try {
        await _enhancedService.getOptimizedInvestors(
          page: 1,
          pageSize: pageSize,
          forceRefresh: i == 0, // Pierwszy test bez cache
        );
        stopwatch.stop();
        enhancedTimes.add(stopwatch.elapsedMilliseconds);
      } catch (e) {
        print('⚠️ [Migration] Enhanced test failed: $e');
        enhancedTimes.add(999999); // Penalty for failure
      }
      
      await Future.delayed(Duration(milliseconds: 100)); // Przerwa między testami
    }

    final avgLegacy = legacyTimes.reduce((a, b) => a + b) / legacyTimes.length;
    final avgEnhanced = enhancedTimes.reduce((a, b) => a + b) / enhancedTimes.length;

    final improvement = avgLegacy > 0 ? ((avgLegacy - avgEnhanced) / avgLegacy) * 100 : 0.0;

    print('📊 [Migration] Wyniki porównania:');
    print('  - Legacy average: ${avgLegacy.toStringAsFixed(0)}ms');
    print('  - Enhanced average: ${avgEnhanced.toStringAsFixed(0)}ms');
    print('  - Improvement: ${improvement.toStringAsFixed(1)}%');

    return PerformanceComparison(
      legacyAverageMs: avgLegacy,
      enhancedAverageMs: avgEnhanced,
      improvementPercentage: improvement,
      legacyTimes: legacyTimes,
      enhancedTimes: enhancedTimes,
      testIterations: testIterations,
      testDate: DateTime.now(),
    );
  }

  /// Włącza lub wyłącza enhanced services
  void setEnhancedServicesEnabled(bool enabled) {
    useEnhancedServices = enabled;
    print('🔧 [Migration] Enhanced services: ${enabled ? "ENABLED" : "DISABLED"}');
  }

  /// Status migracji
  Map<String, dynamic> getMigrationStatus() {
    return {
      'useEnhancedServices': useEnhancedServices,
      'cacheStatus': useEnhancedServices ? _enhancedService.getCacheStatus() : null,
      'legacyServiceActive': true,
      'migrationDate': DateTime.now().toIso8601String(),
    };
  }
}

/// Model porównania wydajności
class PerformanceComparison {
  final double legacyAverageMs;
  final double enhancedAverageMs;
  final double improvementPercentage;
  final List<int> legacyTimes;
  final List<int> enhancedTimes;
  final int testIterations;
  final DateTime testDate;

  const PerformanceComparison({
    required this.legacyAverageMs,
    required this.enhancedAverageMs,
    required this.improvementPercentage,
    required this.legacyTimes,
    required this.enhancedTimes,
    required this.testIterations,
    required this.testDate,
  });

  bool get enhancedIsFaster => enhancedAverageMs < legacyAverageMs;
  
  String get summary {
    if (enhancedIsFaster) {
      return 'Enhanced service is ${improvementPercentage.toStringAsFixed(1)}% faster';
    } else {
      return 'Legacy service is ${(-improvementPercentage).toStringAsFixed(1)}% faster';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'legacyAverageMs': legacyAverageMs,
      'enhancedAverageMs': enhancedAverageMs,
      'improvementPercentage': improvementPercentage,
      'enhancedIsFaster': enhancedIsFaster,
      'summary': summary,
      'testIterations': testIterations,
      'testDate': testDate.toIso8601String(),
    };
  }
}