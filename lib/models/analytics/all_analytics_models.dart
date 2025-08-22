/// Modele danych dla wszystkich pozostałych tabów analityki
/// Risk Tab, Employees Tab, Geographic Tab, Trends Tab
library;

// ============= RISK ANALYTICS MODELS =============

/// Główna klasa analityki ryzyka
class RiskAnalytics {
  final RiskOverviewData overview;
  final List<RiskFactorItem> riskFactors;
  final List<ScenarioAnalysisItem> scenarioAnalysis;
  final RiskDistributionData riskDistribution;
  final List<CorrelationItem> correlationMatrix;
  final DateTime calculatedAt;

  RiskAnalytics({
    required this.overview,
    required this.riskFactors,
    required this.scenarioAnalysis,
    required this.riskDistribution,
    required this.correlationMatrix,
    required this.calculatedAt,
  });
}

class RiskOverviewData {
  final double portfolioVolatility;
  final double valueAtRisk95;
  final double valueAtRisk99;
  final double conditionalVaR;
  final double maxDrawdown;
  final double stressTestResult;
  final String riskGrade; // A, B, C, D, E
  final double concentrationRisk;

  RiskOverviewData({
    required this.portfolioVolatility,
    required this.valueAtRisk95,
    required this.valueAtRisk99,
    required this.conditionalVaR,
    required this.maxDrawdown,
    required this.stressTestResult,
    required this.riskGrade,
    required this.concentrationRisk,
  });
}

class RiskFactorItem {
  final String factorName;
  final double contribution;
  final double volatility;
  final String category;
  final String description;

  RiskFactorItem({
    required this.factorName,
    required this.contribution,
    required this.volatility,
    required this.category,
    required this.description,
  });
}

class ScenarioAnalysisItem {
  final String scenarioName;
  final String description;
  final double probability;
  final double impact;
  final double portfolioEffect;

  ScenarioAnalysisItem({
    required this.scenarioName,
    required this.description,
    required this.probability,
    required this.impact,
    required this.portfolioEffect,
  });
}

class RiskDistributionData {
  final List<double> returns;
  final List<int> frequency;
  final double mean;
  final double stdDev;
  final double skewness;
  final double kurtosis;

  RiskDistributionData({
    required this.returns,
    required this.frequency,
    required this.mean,
    required this.stdDev,
    required this.skewness,
    required this.kurtosis,
  });
}

class CorrelationItem {
  final String asset1;
  final String asset2;
  final double correlation;

  CorrelationItem({
    required this.asset1,
    required this.asset2,
    required this.correlation,
  });
}

// ============= EMPLOYEES ANALYTICS MODELS =============

/// Główna klasa analityki pracowników
class EmployeesAnalytics {
  final EmployeeOverviewData overview;
  final List<EmployeePerformanceItem> employeePerformance;
  final List<TeamMetricsItem> teamMetrics;
  final EmployeeRankingData ranking;
  final List<SalesChannelData> salesChannels;
  final DateTime calculatedAt;

  EmployeesAnalytics({
    required this.overview,
    required this.employeePerformance,
    required this.teamMetrics,
    required this.ranking,
    required this.salesChannels,
    required this.calculatedAt,
  });
}

class EmployeeOverviewData {
  final int totalEmployees;
  final int activeEmployees;
  final double totalSalesVolume;
  final double averageSalesPerEmployee;
  final int totalClients;
  final double averageClientsPerEmployee;
  final double topPerformerVolume;

  EmployeeOverviewData({
    required this.totalEmployees,
    required this.activeEmployees,
    required this.totalSalesVolume,
    required this.averageSalesPerEmployee,
    required this.totalClients,
    required this.averageClientsPerEmployee,
    required this.topPerformerVolume,
  });
}

class EmployeePerformanceItem {
  final String employeeId;
  final String fullName;
  final String branchCode;
  final double totalVolume;
  final int clientCount;
  final int transactionCount;
  final double averageReturn;
  final double conversionRate;
  final double clientRetention;
  final int rank;

  EmployeePerformanceItem({
    required this.employeeId,
    required this.fullName,
    required this.branchCode,
    required this.totalVolume,
    required this.clientCount,
    required this.transactionCount,
    required this.averageReturn,
    required this.conversionRate,
    required this.clientRetention,
    required this.rank,
  });
}

class TeamMetricsItem {
  final String branchCode;
  final String branchName;
  final int employeeCount;
  final double totalVolume;
  final int totalClients;
  final double averagePerformance;
  final double teamSynergy;

  TeamMetricsItem({
    required this.branchCode,
    required this.branchName,
    required this.employeeCount,
    required this.totalVolume,
    required this.totalClients,
    required this.averagePerformance,
    required this.teamSynergy,
  });
}

class EmployeeRankingData {
  final List<EmployeePerformanceItem> topPerformers;
  final List<EmployeePerformanceItem> improvingEmployees;
  final List<EmployeePerformanceItem> needsAttention;

  EmployeeRankingData({
    required this.topPerformers,
    required this.improvingEmployees,
    required this.needsAttention,
  });
}

class SalesChannelData {
  final String channelName;
  final double volume;
  final int transactionCount;
  final double averageTransactionSize;
  final double marketShare;

  SalesChannelData({
    required this.channelName,
    required this.volume,
    required this.transactionCount,
    required this.averageTransactionSize,
    required this.marketShare,
  });
}

// ============= GEOGRAPHIC ANALYTICS MODELS =============

/// Główna klasa analityki geograficznej
class GeographicAnalytics {
  final GeographicOverviewData overview;
  final List<BranchPerformanceItem> branchPerformance;
  final List<RegionalData> regionalData;
  final GeographicDistributionData distribution;
  final DateTime calculatedAt;

  GeographicAnalytics({
    required this.overview,
    required this.branchPerformance,
    required this.regionalData,
    required this.distribution,
    required this.calculatedAt,
  });
}

class GeographicOverviewData {
  final int totalBranches;
  final int activeBranches;
  final double totalVolume;
  final String topPerformingBranch;
  final double branchVolumeVariance;
  final double geographicDiversification;

  GeographicOverviewData({
    required this.totalBranches,
    required this.activeBranches,
    required this.totalVolume,
    required this.topPerformingBranch,
    required this.branchVolumeVariance,
    required this.geographicDiversification,
  });
}

class BranchPerformanceItem {
  final String branchCode;
  final String branchName;
  final String region;
  final double totalVolume;
  final int clientCount;
  final int employeeCount;
  final double averageReturn;
  final double marketShare;
  final double growthRate;

  BranchPerformanceItem({
    required this.branchCode,
    required this.branchName,
    required this.region,
    required this.totalVolume,
    required this.clientCount,
    required this.employeeCount,
    required this.averageReturn,
    required this.marketShare,
    required this.growthRate,
  });
}

class RegionalData {
  final String regionName;
  final double totalVolume;
  final int branchCount;
  final int clientCount;
  final double averageReturn;
  final double penetrationRate;

  RegionalData({
    required this.regionName,
    required this.totalVolume,
    required this.branchCount,
    required this.clientCount,
    required this.averageReturn,
    required this.penetrationRate,
  });
}

class GeographicDistributionData {
  final Map<String, double> volumeByRegion;
  final Map<String, int> clientsByRegion;
  final Map<String, double> performanceByRegion;

  GeographicDistributionData({
    required this.volumeByRegion,
    required this.clientsByRegion,
    required this.performanceByRegion,
  });
}

// ============= TRENDS ANALYTICS MODELS =============

/// Główna klasa analityki trendów
class TrendsAnalytics {
  final TrendsOverviewData overview;
  final List<TrendItem> shortTermTrends;
  final List<TrendItem> longTermTrends;
  final SeasonalityData seasonality;
  final List<PredictionItem> predictions;
  final MarketTrendsData marketTrends;
  final DateTime calculatedAt;

  TrendsAnalytics({
    required this.overview,
    required this.shortTermTrends,
    required this.longTermTrends,
    required this.seasonality,
    required this.predictions,
    required this.marketTrends,
    required this.calculatedAt,
  });
}

class TrendsOverviewData {
  final double overallTrendDirection; // -1 to 1
  final double volatilityTrend;
  final double volumeTrend;
  final double seasonalStrength;
  final String dominantPattern;

  TrendsOverviewData({
    required this.overallTrendDirection,
    required this.volatilityTrend,
    required this.volumeTrend,
    required this.seasonalStrength,
    required this.dominantPattern,
  });
}

class TrendItem {
  final String trendName;
  final String category;
  final double strength;
  final double confidence;
  final String direction; // up, down, stable
  final String description;
  final DateTime startDate;
  final DateTime? expectedEndDate;

  TrendItem({
    required this.trendName,
    required this.category,
    required this.strength,
    required this.confidence,
    required this.direction,
    required this.description,
    required this.startDate,
    this.expectedEndDate,
  });
}

class SeasonalityData {
  final Map<int, double> monthlyPatterns; // month -> multiplier
  final Map<int, double> quarterlyPatterns; // quarter -> multiplier
  final Map<int, double> yearlyPatterns; // year -> growth
  final double seasonalStrength;

  SeasonalityData({
    required this.monthlyPatterns,
    required this.quarterlyPatterns,
    required this.yearlyPatterns,
    required this.seasonalStrength,
  });
}

class PredictionItem {
  final DateTime date;
  final double predictedVolume;
  final double confidenceInterval;
  final double upperBound;
  final double lowerBound;
  final String methodology;

  PredictionItem({
    required this.date,
    required this.predictedVolume,
    required this.confidenceInterval,
    required this.upperBound,
    required this.lowerBound,
    required this.methodology,
  });
}

class MarketTrendsData {
  final double marketGrowthRate;
  final double competitorPerformance;
  final double marketShare;
  final List<MarketIndicator> indicators;

  MarketTrendsData({
    required this.marketGrowthRate,
    required this.competitorPerformance,
    required this.marketShare,
    required this.indicators,
  });
}

class MarketIndicator {
  final String name;
  final double currentValue;
  final double previousValue;
  final double change;
  final String impact; // positive, negative, neutral

  MarketIndicator({
    required this.name,
    required this.currentValue,
    required this.previousValue,
    required this.change,
    required this.impact,
  });
}
