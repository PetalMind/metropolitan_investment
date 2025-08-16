import 'package:cloud_functions/cloud_functions.dart';
import '../models_and_services.dart';

/// 🎯 FIREBASE FUNCTIONS PREMIUM ANALYTICS SERVICE
///
/// Najzaawansowany serwis analityczny dla premium dashboard
/// Wykorzystuje server-side processing dla kompleksowej analizy:
/// • Analiza grupy większościowej (≥51% kapitału)
/// • Zaawansowana analiza głosowania
/// • Metryki wydajnościowe i trendy
/// • Inteligentne insights i predykcje
class FirebaseFunctionsPremiumAnalyticsService extends BaseService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  /// 🎯 GŁÓWNA METODA: Kompleksowa analityka premium
  /// Zwraca pełne dane analityczne gotowe do wyświetlenia w UI
  Future<PremiumAnalyticsResult> getPremiumInvestorAnalytics({
    int page = 1,
    int pageSize = 10000,
    String sortBy = 'viableRemainingCapital',
    bool sortAscending = false,
    bool includeInactive = false,
    VotingStatus? votingStatusFilter,
    ClientType? clientTypeFilter,
    bool showOnlyWithUnviableInvestments = false,
    String? searchQuery,
    double majorityThreshold = 51.0,
    bool forceRefresh = false,
  }) async {
    final startTime = DateTime.now();
    print('🎯 [Premium Analytics] Rozpoczynam kompleksową analizę premium...');

    try {
      final callable = _functions.httpsCallable(
        'getPremiumInvestorAnalytics',
        options: HttpsCallableOptions(
          timeout: const Duration(
            minutes: 10,
          ), // Długszy timeout dla premium analytics
        ),
      );

      final response = await callable.call({
        'page': page,
        'pageSize': pageSize,
        'sortBy': sortBy,
        'sortAscending': sortAscending,
        'includeInactive': includeInactive,
        'votingStatusFilter': votingStatusFilter?.toString().split('.').last,
        'clientTypeFilter': clientTypeFilter?.toString().split('.').last,
        'showOnlyWithUnviableInvestments': showOnlyWithUnviableInvestments,
        'searchQuery': searchQuery,
        'majorityThreshold': majorityThreshold,
        'forceRefresh': forceRefresh,
      });

      final data = response.data;

      if (data == null || data['success'] != true) {
        throw Exception(
          'Firebase Function returned error: ${data?['error'] ?? 'Unknown error'}',
        );
      }

      final processingTime = DateTime.now().difference(startTime);
      print(
        '✅ [Premium Analytics] Analiza zakończona w ${processingTime.inMilliseconds}ms',
      );

      return PremiumAnalyticsResult.fromFirebaseResponse(data['data']);
    } catch (e) {
      print('❌ [Premium Analytics] Błąd: $e');
      rethrow;
    }
  }
}

/// 🎯 MODEL: Wynik kompleksowej analizy premium
class PremiumAnalyticsResult {
  final List<InvestorSummary> investors;
  final int totalCount;
  final PaginationInfo pagination;

  // 🚀 PREMIUM ANALYTICS
  final MajorityAnalysis majorityAnalysis;
  final VotingAnalysis votingAnalysis;
  final PerformanceMetrics performanceMetrics;
  final TrendAnalysis trendAnalysis;
  final List<IntelligentInsight> insights;

  // Metadane
  final int totalProcessingTime;
  final double majorityThreshold;
  final DateTime analysisTimestamp;
  final bool fromCache;

  const PremiumAnalyticsResult({
    required this.investors,
    required this.totalCount,
    required this.pagination,
    required this.majorityAnalysis,
    required this.votingAnalysis,
    required this.performanceMetrics,
    required this.trendAnalysis,
    required this.insights,
    required this.totalProcessingTime,
    required this.majorityThreshold,
    required this.analysisTimestamp,
    required this.fromCache,
  });

  factory PremiumAnalyticsResult.fromFirebaseResponse(
    Map<String, dynamic> data,
  ) {
    return PremiumAnalyticsResult(
      investors:
          (data['investors'] as List<dynamic>?)
              ?.map((investorData) => InvestorSummary.fromMap(investorData))
              .toList() ??
          [],
      totalCount: data['totalCount'] ?? 0,
      pagination: PaginationInfo.fromMap(data['pagination'] ?? {}),
      majorityAnalysis: MajorityAnalysis.fromMap(
        data['majorityAnalysis'] ?? {},
      ),
      votingAnalysis: VotingAnalysis.fromMap(data['votingAnalysis'] ?? {}),
      performanceMetrics: PerformanceMetrics.fromMap(
        data['performanceMetrics'] ?? {},
      ),
      trendAnalysis: TrendAnalysis.fromMap(data['trendAnalysis'] ?? {}),
      insights:
          (data['insights'] as List<dynamic>?)
              ?.map((insightData) => IntelligentInsight.fromMap(insightData))
              .toList() ??
          [],
      totalProcessingTime: data['metadata']?['totalProcessingTime'] ?? 0,
      majorityThreshold: (data['metadata']?['majorityThreshold'] ?? 51.0)
          .toDouble(),
      analysisTimestamp:
          DateTime.tryParse(data['metadata']?['analysisTimestamp'] ?? '') ??
          DateTime.now(),
      fromCache: data['fromCache'] ?? false,
    );
  }
}

/// 🏆 MODEL: Analiza grupy większościowej
class MajorityAnalysis {
  final double totalCapital;
  final double majorityThreshold;
  final List<InvestorSummary> majorityHolders;
  final double majorityCapital;
  final double majorityPercentage;
  final int holdersCount;
  final double averageHolding;
  final double medianHolding;
  final double concentrationIndex;

  const MajorityAnalysis({
    required this.totalCapital,
    required this.majorityThreshold,
    required this.majorityHolders,
    required this.majorityCapital,
    required this.majorityPercentage,
    required this.holdersCount,
    required this.averageHolding,
    required this.medianHolding,
    required this.concentrationIndex,
  });

  factory MajorityAnalysis.fromMap(Map<String, dynamic> map) {
    return MajorityAnalysis(
      totalCapital: (map['totalCapital'] ?? 0.0).toDouble(),
      majorityThreshold: (map['majorityThreshold'] ?? 51.0).toDouble(),
      majorityHolders:
          (map['majorityHolders'] as List<dynamic>?)
              ?.map((data) => InvestorSummary.fromMap(data))
              .toList() ??
          [],
      majorityCapital: (map['majorityCapital'] ?? 0.0).toDouble(),
      majorityPercentage: (map['majorityPercentage'] ?? 0.0).toDouble(),
      holdersCount: map['holdersCount'] ?? 0,
      averageHolding: (map['averageHolding'] ?? 0.0).toDouble(),
      medianHolding: (map['medianHolding'] ?? 0.0).toDouble(),
      concentrationIndex: (map['concentrationIndex'] ?? 0.0).toDouble(),
    );
  }
}

/// 🗳️ MODEL: Analiza głosowania
class VotingAnalysis {
  final double totalCapital;
  final int totalInvestors;
  final Map<String, double> votingDistribution;
  final Map<String, int> votingCounts;
  final Map<String, double> capitalByVotingStatus;
  final Map<String, double> percentageByVotingStatus;
  final Map<String, double> averageCapitalByStatus;
  final Map<String, VotingPower> votingPower;

  const VotingAnalysis({
    required this.totalCapital,
    required this.totalInvestors,
    required this.votingDistribution,
    required this.votingCounts,
    required this.capitalByVotingStatus,
    required this.percentageByVotingStatus,
    required this.averageCapitalByStatus,
    required this.votingPower,
  });

  factory VotingAnalysis.fromMap(Map<String, dynamic> map) {
    return VotingAnalysis(
      totalCapital: (map['totalCapital'] ?? 0.0).toDouble(),
      totalInvestors: map['totalInvestors'] ?? 0,
      votingDistribution: Map<String, double>.from(
        map['votingDistribution'] ?? {},
      ),
      votingCounts: Map<String, int>.from(map['votingCounts'] ?? {}),
      capitalByVotingStatus: Map<String, double>.from(
        map['capitalByVotingStatus'] ?? {},
      ),
      percentageByVotingStatus: Map<String, double>.from(
        map['percentageByVotingStatus'] ?? {},
      ),
      averageCapitalByStatus: Map<String, double>.from(
        map['averageCapitalByStatus'] ?? {},
      ),
      votingPower:
          (map['votingPower'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, VotingPower.fromMap(value)),
          ) ??
          {},
    );
  }
}

/// 🗳️ MODEL: Siła głosowania
class VotingPower {
  final int votes;
  final double capital;
  final double percentage;
  final double averageCapital;

  const VotingPower({
    required this.votes,
    required this.capital,
    required this.percentage,
    required this.averageCapital,
  });

  factory VotingPower.fromMap(Map<String, dynamic> map) {
    return VotingPower(
      votes: map['votes'] ?? 0,
      capital: (map['capital'] ?? 0.0).toDouble(),
      percentage: (map['percentage'] ?? 0.0).toDouble(),
      averageCapital: (map['averageCapital'] ?? 0.0).toDouble(),
    );
  }
}

/// 📊 MODEL: Metryki wydajnościowe
class PerformanceMetrics {
  final int totalInvestors;
  final double totalCapital;
  final double averageInvestment;
  final double medianInvestment;
  final double capitalConcentration;
  final double top10Percentage;
  final double diversificationIndex;
  final RiskMetrics riskMetrics;

  const PerformanceMetrics({
    required this.totalInvestors,
    required this.totalCapital,
    required this.averageInvestment,
    required this.medianInvestment,
    required this.capitalConcentration,
    required this.top10Percentage,
    required this.diversificationIndex,
    required this.riskMetrics,
  });

  factory PerformanceMetrics.fromMap(Map<String, dynamic> map) {
    return PerformanceMetrics(
      totalInvestors: map['totalInvestors'] ?? 0,
      totalCapital: (map['totalCapital'] ?? 0.0).toDouble(),
      averageInvestment: (map['averageInvestment'] ?? 0.0).toDouble(),
      medianInvestment: (map['medianInvestment'] ?? 0.0).toDouble(),
      capitalConcentration: (map['capitalConcentration'] ?? 0.0).toDouble(),
      top10Percentage: (map['top10Percentage'] ?? 0.0).toDouble(),
      diversificationIndex: (map['diversificationIndex'] ?? 0.0).toDouble(),
      riskMetrics: RiskMetrics.fromMap(map['riskMetrics'] ?? {}),
    );
  }
}

/// 📊 MODEL: Metryki ryzyka
class RiskMetrics {
  final double variance;
  final double standardDeviation;
  final double coefficientOfVariation;
  final double range;

  const RiskMetrics({
    required this.variance,
    required this.standardDeviation,
    required this.coefficientOfVariation,
    required this.range,
  });

  factory RiskMetrics.fromMap(Map<String, dynamic> map) {
    return RiskMetrics(
      variance: (map['variance'] ?? 0.0).toDouble(),
      standardDeviation: (map['standardDeviation'] ?? 0.0).toDouble(),
      coefficientOfVariation: (map['coefficientOfVariation'] ?? 0.0).toDouble(),
      range: (map['range'] ?? 0.0).toDouble(),
    );
  }
}

/// 📈 MODEL: Analiza trendów
class TrendAnalysis {
  final GrowthTrend growth;
  final VolatilityMetric volatility;
  final MomentumIndicator momentum;
  final CyclicalPhase cyclical;
  final MarketForecast forecast;

  const TrendAnalysis({
    required this.growth,
    required this.volatility,
    required this.momentum,
    required this.cyclical,
    required this.forecast,
  });

  factory TrendAnalysis.fromMap(Map<String, dynamic> map) {
    return TrendAnalysis(
      growth: GrowthTrend.fromMap(map['growth'] ?? {}),
      volatility: VolatilityMetric.fromMap(map['volatility'] ?? {}),
      momentum: MomentumIndicator.fromMap(map['momentum'] ?? {}),
      cyclical: CyclicalPhase.fromMap(map['cyclical'] ?? {}),
      forecast: MarketForecast.fromMap(map['forecast'] ?? {}),
    );
  }
}

/// 📈 MODEL: Trend wzrostu
class GrowthTrend {
  final double rate;
  final String trend;

  const GrowthTrend({required this.rate, required this.trend});

  factory GrowthTrend.fromMap(Map<String, dynamic> map) {
    return GrowthTrend(
      rate: (map['rate'] ?? 0.0).toDouble(),
      trend: map['trend'] ?? 'neutral',
    );
  }
}

/// 📊 MODEL: Metryka zmienności
class VolatilityMetric {
  final String level;
  final double index;

  const VolatilityMetric({required this.level, required this.index});

  factory VolatilityMetric.fromMap(Map<String, dynamic> map) {
    return VolatilityMetric(
      level: map['level'] ?? 'low',
      index: (map['index'] ?? 0.0).toDouble(),
    );
  }
}

/// 📈 MODEL: Wskaźnik momentum
class MomentumIndicator {
  final String direction;
  final double strength;

  const MomentumIndicator({required this.direction, required this.strength});

  factory MomentumIndicator.fromMap(Map<String, dynamic> map) {
    return MomentumIndicator(
      direction: map['direction'] ?? 'neutral',
      strength: (map['strength'] ?? 0.0).toDouble(),
    );
  }
}

/// 📊 MODEL: Faza cykliczna
class CyclicalPhase {
  final String phase;
  final double confidence;

  const CyclicalPhase({required this.phase, required this.confidence});

  factory CyclicalPhase.fromMap(Map<String, dynamic> map) {
    return CyclicalPhase(
      phase: map['phase'] ?? 'unknown',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
    );
  }
}

/// 🔮 MODEL: Prognoza rynkowa
class MarketForecast {
  final String shortTerm;
  final String longTerm;

  const MarketForecast({required this.shortTerm, required this.longTerm});

  factory MarketForecast.fromMap(Map<String, dynamic> map) {
    return MarketForecast(
      shortTerm: map['shortTerm'] ?? 'stable',
      longTerm: map['longTerm'] ?? 'stable',
    );
  }
}

/// 🔍 MODEL: Inteligentne spostrzeżenia
class IntelligentInsight {
  final String type;
  final String category;
  final String title;
  final String message;
  final String severity;
  final bool actionable;

  const IntelligentInsight({
    required this.type,
    required this.category,
    required this.title,
    required this.message,
    required this.severity,
    required this.actionable,
  });

  factory IntelligentInsight.fromMap(Map<String, dynamic> map) {
    return IntelligentInsight(
      type: map['type'] ?? 'info',
      category: map['category'] ?? 'general',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      severity: map['severity'] ?? 'low',
      actionable: map['actionable'] ?? false,
    );
  }
}

/// 📄 MODEL: Informacje o paginacji (reused from existing service)
class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginationInfo.fromMap(Map<String, dynamic> map) {
    return PaginationInfo(
      currentPage: map['currentPage'] ?? 1,
      totalPages: map['totalPages'] ?? 1,
      pageSize: map['pageSize'] ?? 250,
      hasNextPage: map['hasNextPage'] ?? false,
      hasPreviousPage: map['hasPreviousPage'] ?? false,
    );
  }
}
