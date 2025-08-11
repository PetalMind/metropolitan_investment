/// Modele danych dla analityki przeglądu
/// Zawiera wszystkie struktury danych dla taba Overview

/// Główna klasa przeglądu analityki
class OverviewAnalytics {
  final PortfolioMetricsData portfolioMetrics;
  final List<ProductBreakdownItem> productBreakdown;
  final List<MonthlyPerformanceItem> monthlyPerformance;
  final ClientMetricsData clientMetrics;
  final RiskMetricsData riskMetrics;
  final DateTime calculatedAt;

  OverviewAnalytics({
    required this.portfolioMetrics,
    required this.productBreakdown,
    required this.monthlyPerformance,
    required this.clientMetrics,
    required this.riskMetrics,
    required this.calculatedAt,
  });

  factory OverviewAnalytics.fromJson(Map<String, dynamic> json) {
    return OverviewAnalytics(
      portfolioMetrics: PortfolioMetricsData.fromJson(
        json['portfolioMetrics'] ?? {},
      ),
      productBreakdown:
          (json['productBreakdown'] as List<dynamic>?)
              ?.map((item) => ProductBreakdownItem.fromJson(item))
              .toList() ??
          [],
      monthlyPerformance:
          (json['monthlyPerformance'] as List<dynamic>?)
              ?.map((item) => MonthlyPerformanceItem.fromJson(item))
              .toList() ??
          [],
      clientMetrics: ClientMetricsData.fromJson(json['clientMetrics'] ?? {}),
      riskMetrics: RiskMetricsData.fromJson(json['riskMetrics'] ?? {}),
      calculatedAt: json['calculatedAt'] != null
          ? DateTime.parse(json['calculatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'portfolioMetrics': portfolioMetrics.toJson(),
      'productBreakdown': productBreakdown
          .map((item) => item.toJson())
          .toList(),
      'monthlyPerformance': monthlyPerformance
          .map((item) => item.toJson())
          .toList(),
      'clientMetrics': clientMetrics.toJson(),
      'riskMetrics': riskMetrics.toJson(),
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }
}

/// Metryki portfela
class PortfolioMetricsData {
  final double totalValue;
  final double totalInvested;
  final double totalProfit;
  final double totalROI;
  final double growthPercentage;
  final int activeInvestmentsCount;
  final int totalInvestmentsCount;
  final double averageReturn;
  final double monthlyGrowth;

  PortfolioMetricsData({
    required this.totalValue,
    required this.totalInvested,
    required this.totalProfit,
    required this.totalROI,
    required this.growthPercentage,
    required this.activeInvestmentsCount,
    required this.totalInvestmentsCount,
    required this.averageReturn,
    required this.monthlyGrowth,
  });

  factory PortfolioMetricsData.fromJson(Map<String, dynamic> json) {
    return PortfolioMetricsData(
      totalValue: (json['totalValue'] ?? 0).toDouble(),
      totalInvested: (json['totalInvested'] ?? 0).toDouble(),
      totalProfit: (json['totalProfit'] ?? 0).toDouble(),
      totalROI: (json['totalROI'] ?? 0).toDouble(),
      growthPercentage: (json['growthPercentage'] ?? 0).toDouble(),
      activeInvestmentsCount: json['activeInvestmentsCount'] ?? 0,
      totalInvestmentsCount: json['totalInvestmentsCount'] ?? 0,
      averageReturn: (json['averageReturn'] ?? 0).toDouble(),
      monthlyGrowth: (json['monthlyGrowth'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalValue': totalValue,
      'totalInvested': totalInvested,
      'totalProfit': totalProfit,
      'totalROI': totalROI,
      'growthPercentage': growthPercentage,
      'activeInvestmentsCount': activeInvestmentsCount,
      'totalInvestmentsCount': totalInvestmentsCount,
      'averageReturn': averageReturn,
      'monthlyGrowth': monthlyGrowth,
    };
  }
}

/// Rozkład produktów w portfelu
class ProductBreakdownItem {
  final String productType;
  final String productName;
  final double value;
  final double percentage;
  final int count;
  final double averageReturn;

  ProductBreakdownItem({
    required this.productType,
    required this.productName,
    required this.value,
    required this.percentage,
    required this.count,
    required this.averageReturn,
  });

  factory ProductBreakdownItem.fromJson(Map<String, dynamic> json) {
    return ProductBreakdownItem(
      productType: json['productType'] ?? '',
      productName: json['productName'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
      averageReturn: (json['averageReturn'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productType': productType,
      'productName': productName,
      'value': value,
      'percentage': percentage,
      'count': count,
      'averageReturn': averageReturn,
    };
  }
}

/// Wydajność miesięczna
class MonthlyPerformanceItem {
  final String month;
  final double totalValue;
  final double totalVolume;
  final double averageReturn;
  final int transactionCount;
  final double growthRate;

  MonthlyPerformanceItem({
    required this.month,
    required this.totalValue,
    required this.totalVolume,
    required this.averageReturn,
    required this.transactionCount,
    required this.growthRate,
  });

  factory MonthlyPerformanceItem.fromJson(Map<String, dynamic> json) {
    return MonthlyPerformanceItem(
      month: json['month'] ?? '',
      totalValue: (json['totalValue'] ?? 0).toDouble(),
      totalVolume: (json['totalVolume'] ?? 0).toDouble(),
      averageReturn: (json['averageReturn'] ?? 0).toDouble(),
      transactionCount: json['transactionCount'] ?? 0,
      growthRate: (json['growthRate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'totalValue': totalValue,
      'totalVolume': totalVolume,
      'averageReturn': averageReturn,
      'transactionCount': transactionCount,
      'growthRate': growthRate,
    };
  }
}

/// Metryki klientów
class ClientMetricsData {
  final int totalClients;
  final int activeClients;
  final int newClientsThisMonth;
  final double clientRetentionRate;
  final double averageClientValue;
  final List<TopClientItem> topClients;

  ClientMetricsData({
    required this.totalClients,
    required this.activeClients,
    required this.newClientsThisMonth,
    required this.clientRetentionRate,
    required this.averageClientValue,
    required this.topClients,
  });

  factory ClientMetricsData.fromJson(Map<String, dynamic> json) {
    return ClientMetricsData(
      totalClients: json['totalClients'] ?? 0,
      activeClients: json['activeClients'] ?? 0,
      newClientsThisMonth: json['newClientsThisMonth'] ?? 0,
      clientRetentionRate: (json['clientRetentionRate'] ?? 0).toDouble(),
      averageClientValue: (json['averageClientValue'] ?? 0).toDouble(),
      topClients:
          (json['topClients'] as List<dynamic>?)
              ?.map((item) => TopClientItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalClients': totalClients,
      'activeClients': activeClients,
      'newClientsThisMonth': newClientsThisMonth,
      'clientRetentionRate': clientRetentionRate,
      'averageClientValue': averageClientValue,
      'topClients': topClients.map((item) => item.toJson()).toList(),
    };
  }
}

/// Top klient
class TopClientItem {
  final String name;
  final double value;
  final int investmentCount;

  TopClientItem({
    required this.name,
    required this.value,
    required this.investmentCount,
  });

  factory TopClientItem.fromJson(Map<String, dynamic> json) {
    return TopClientItem(
      name: json['name'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      investmentCount: json['investmentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'value': value, 'investmentCount': investmentCount};
  }
}

/// Metryki ryzyka
class RiskMetricsData {
  final double volatility;
  final double sharpeRatio;
  final double maxDrawdown;
  final double valueAtRisk;
  final double diversificationIndex;
  final String riskLevel; // low, medium, high
  final double concentrationRisk;

  RiskMetricsData({
    required this.volatility,
    required this.sharpeRatio,
    required this.maxDrawdown,
    required this.valueAtRisk,
    required this.diversificationIndex,
    required this.riskLevel,
    required this.concentrationRisk,
  });

  factory RiskMetricsData.fromJson(Map<String, dynamic> json) {
    return RiskMetricsData(
      volatility: (json['volatility'] ?? 0).toDouble(),
      sharpeRatio: (json['sharpeRatio'] ?? 0).toDouble(),
      maxDrawdown: (json['maxDrawdown'] ?? 0).toDouble(),
      valueAtRisk: (json['valueAtRisk'] ?? 0).toDouble(),
      diversificationIndex: (json['diversificationIndex'] ?? 0).toDouble(),
      riskLevel: json['riskLevel'] ?? 'medium',
      concentrationRisk: (json['concentrationRisk'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'volatility': volatility,
      'sharpeRatio': sharpeRatio,
      'maxDrawdown': maxDrawdown,
      'valueAtRisk': valueAtRisk,
      'diversificationIndex': diversificationIndex,
      'riskLevel': riskLevel,
      'concentrationRisk': concentrationRisk,
    };
  }
}
