/// Modele danych dla analityki wydajności
/// Zawiera struktury danych dla taba Performance

/// Główna klasa analityki wydajności
class PerformanceAnalytics {
  final PerformanceOverviewData overview;
  final List<BenchmarkComparisonItem> benchmarkComparison;
  final List<TopPerformingInvestmentItem> topPerformers;
  final List<PerformanceHistoryItem> performanceHistory;
  final List<ProductPerformanceData> productPerformance;
  final RiskAdjustedMetrics riskAdjustedMetrics;
  final DateTime calculatedAt;

  PerformanceAnalytics({
    required this.overview,
    required this.benchmarkComparison,
    required this.topPerformers,
    required this.performanceHistory,
    required this.productPerformance,
    required this.riskAdjustedMetrics,
    required this.calculatedAt,
  });
}

/// Przegląd wydajności
class PerformanceOverviewData {
  final double totalReturn;
  final double annualizedReturn;
  final double benchmarkReturn;
  final double excessReturn;
  final double successRate;
  final double averageHoldingPeriod;
  final double winLossRatio;

  PerformanceOverviewData({
    required this.totalReturn,
    required this.annualizedReturn,
    required this.benchmarkReturn,
    required this.excessReturn,
    required this.successRate,
    required this.averageHoldingPeriod,
    required this.winLossRatio,
  });
}

/// Porównanie z benchmarkiem
class BenchmarkComparisonItem {
  final String period;
  final double portfolioReturn;
  final double benchmarkReturn;
  final double outperformance;
  final double trackingError;

  BenchmarkComparisonItem({
    required this.period,
    required this.portfolioReturn,
    required this.benchmarkReturn,
    required this.outperformance,
    required this.trackingError,
  });
}

/// Top wykonujące inwestycje
class TopPerformingInvestmentItem {
  final String investmentId;
  final String clientName;
  final String productName;
  final double return_;
  final double investmentAmount;
  final DateTime startDate;
  final DateTime? endDate;

  TopPerformingInvestmentItem({
    required this.investmentId,
    required this.clientName,
    required this.productName,
    required this.return_,
    required this.investmentAmount,
    required this.startDate,
    this.endDate,
  });
}

/// Historia wydajności
class PerformanceHistoryItem {
  final DateTime date;
  final double cumulativeReturn;
  final double periodReturn;
  final double volatility;
  final double sharpeRatio;

  PerformanceHistoryItem({
    required this.date,
    required this.cumulativeReturn,
    required this.periodReturn,
    required this.volatility,
    required this.sharpeRatio,
  });
}

/// Wydajność produktów
class ProductPerformanceData {
  final String productType;
  final String productName;
  final double averageReturn;
  final double volatility;
  final double sharpeRatio;
  final int investmentCount;
  final double totalValue;
  final double bestReturn;
  final double worstReturn;

  ProductPerformanceData({
    required this.productType,
    required this.productName,
    required this.averageReturn,
    required this.volatility,
    required this.sharpeRatio,
    required this.investmentCount,
    required this.totalValue,
    required this.bestReturn,
    required this.worstReturn,
  });
}

/// Metryki dostosowane do ryzyka
class RiskAdjustedMetrics {
  final double alpha;
  final double beta;
  final double informationRatio;
  final double treynorRatio;
  final double calmarRatio;
  final double sortinoRatio;
  final double maxDrawdown;
  final double valueAtRisk95;
  final double valueAtRisk99;

  RiskAdjustedMetrics({
    required this.alpha,
    required this.beta,
    required this.informationRatio,
    required this.treynorRatio,
    required this.calmarRatio,
    required this.sortinoRatio,
    required this.maxDrawdown,
    required this.valueAtRisk95,
    required this.valueAtRisk99,
  });
}
