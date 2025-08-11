import 'dart:math' as math;
import '../../models/analytics/performance_analytics_models.dart';
import '../base_service.dart';
import '../../models/investment.dart';
import '../../models/product.dart';

/// Serwis analityki wydajności
class PerformanceAnalyticsService extends BaseService {
  /// Pobiera dane analityki wydajności
  Future<PerformanceAnalytics> getPerformanceAnalytics({
    int timeRangeMonths = 12,
  }) async {
    final cacheKey = 'performance_analytics_${timeRangeMonths}';

    return getCachedData(
      cacheKey,
      () => _calculatePerformanceAnalytics(timeRangeMonths),
    );
  }

  /// Oblicza kompletną analitykę wydajności
  Future<PerformanceAnalytics> _calculatePerformanceAnalytics(
    int timeRangeMonths,
  ) async {
    try {
      print('🔍 [PerformanceAnalytics] Rozpoczynam obliczenia...');

      final investments = await _getAllInvestments(timeRangeMonths);
      print(
        '🔍 [PerformanceAnalytics] Pobrano ${investments.length} inwestycji',
      );

      final overview = _calculatePerformanceOverview(investments);
      final benchmarkComparison = _calculateBenchmarkComparison(investments);
      final topPerformers = _getTopPerformingInvestments(investments);
      final performanceHistory = _calculatePerformanceHistory(investments);
      final productPerformance = _calculateProductPerformance(investments);
      final riskAdjustedMetrics = _calculateRiskAdjustedMetrics(investments);

      return PerformanceAnalytics(
        overview: overview,
        benchmarkComparison: benchmarkComparison,
        topPerformers: topPerformers,
        performanceHistory: performanceHistory,
        productPerformance: productPerformance,
        riskAdjustedMetrics: riskAdjustedMetrics,
        calculatedAt: DateTime.now(),
      );
    } catch (e) {
      logError('_calculatePerformanceAnalytics', e);
      throw Exception('Błąd podczas obliczania analityki wydajności: $e');
    }
  }

  /// Pobiera inwestycje w określonym przedziale czasowym
  Future<List<Investment>> _getAllInvestments(int timeRangeMonths) async {
    try {
      final query = firestore.collection('investments');

      if (timeRangeMonths > 0) {
        final startDate = DateTime.now().subtract(
          Duration(days: timeRangeMonths * 30),
        );
        final snapshot = await query
            .where('signedDate', isGreaterThan: startDate.toIso8601String())
            .get();
        return snapshot.docs
            .map((doc) => _convertInvestmentFromDocument(doc))
            .toList();
      } else {
        final snapshot = await query.get();
        return snapshot.docs
            .map((doc) => _convertInvestmentFromDocument(doc))
            .toList();
      }
    } catch (e) {
      logError('_getAllInvestments', e);
      throw Exception('Błąd pobierania inwestycji: $e');
    }
  }

  /// Oblicza przegląd wydajności
  PerformanceOverviewData _calculatePerformanceOverview(
    List<Investment> investments,
  ) {
    if (investments.isEmpty) {
      return PerformanceOverviewData(
        totalReturn: 0,
        annualizedReturn: 0,
        benchmarkReturn: 0,
        excessReturn: 0,
        successRate: 0,
        averageHoldingPeriod: 0,
        winLossRatio: 0,
      );
    }

    // Oblicz całkowity zwrot
    final totalInvested = investments.fold<double>(
      0,
      (sum, inv) => sum + inv.investmentAmount,
    );
    final totalCurrent = investments.fold<double>(
      0,
      (sum, inv) => sum + inv.totalValue,
    );
    final totalReturn = totalInvested > 0
        ? ((totalCurrent - totalInvested) / totalInvested) * 100
        : 0.0;

    // Oblicz zwrot roczny (CAGR)
    final annualizedReturn = _calculateAnnualizedReturn(investments);

    // Benchmark (zakładamy 5% rocznie dla obligacji)
    const benchmarkReturn = 5.0;
    final excessReturn = annualizedReturn - benchmarkReturn;

    // Oblicz success rate (procent zyskownych inwestycji)
    final profitableInvestments = investments
        .where((inv) => inv.profitLoss > 0)
        .length;
    final successRate = investments.isNotEmpty
        ? (profitableInvestments / investments.length) * 100
        : 0.0; // Oblicz średni okres utrzymywania
    final averageHoldingPeriod = _calculateAverageHoldingPeriod(investments);

    // Oblicz stosunek zysków do strat
    final winLossRatio = _calculateWinLossRatio(investments);

    return PerformanceOverviewData(
      totalReturn: totalReturn,
      annualizedReturn: annualizedReturn,
      benchmarkReturn: benchmarkReturn,
      excessReturn: excessReturn,
      successRate: successRate,
      averageHoldingPeriod: averageHoldingPeriod,
      winLossRatio: winLossRatio,
    );
  }

  /// Oblicza porównanie z benchmarkiem
  List<BenchmarkComparisonItem> _calculateBenchmarkComparison(
    List<Investment> investments,
  ) {
    const benchmark = 5.0; // 5% benchmark
    final comparisons = <BenchmarkComparisonItem>[];

    // Porównania dla różnych okresów
    final periods = [
      {'name': '1M', 'months': 1},
      {'name': '3M', 'months': 3},
      {'name': '6M', 'months': 6},
      {'name': '1Y', 'months': 12},
      {'name': 'YTD', 'months': -1}, // Year to date
    ];

    for (final period in periods) {
      final periodInvestments = _getInvestmentsForPeriod(
        investments,
        period['months'] as int,
      );
      if (periodInvestments.isEmpty) continue;

      final portfolioReturn = _calculatePeriodReturn(periodInvestments);
      final outperformance = portfolioReturn - benchmark;
      final trackingError = _calculateTrackingError(
        periodInvestments,
        benchmark,
      );

      comparisons.add(
        BenchmarkComparisonItem(
          period: period['name'] as String,
          portfolioReturn: portfolioReturn,
          benchmarkReturn: benchmark,
          outperformance: outperformance,
          trackingError: trackingError,
        ),
      );
    }

    return comparisons;
  }

  /// Pobiera top wykonujące inwestycje
  List<TopPerformingInvestmentItem> _getTopPerformingInvestments(
    List<Investment> investments,
  ) {
    final sortedInvestments = [
      ...investments,
    ]..sort((a, b) => b.profitLossPercentage.compareTo(a.profitLossPercentage));

    return sortedInvestments
        .take(10)
        .map(
          (investment) => TopPerformingInvestmentItem(
            investmentId: investment.id,
            clientName: investment.clientName,
            productName: investment.productName,
            return_: investment.profitLossPercentage,
            investmentAmount: investment.investmentAmount,
            startDate: investment.signedDate,
            endDate: investment.exitDate,
          ),
        )
        .toList();
  }

  /// Oblicza historię wydajności
  List<PerformanceHistoryItem> _calculatePerformanceHistory(
    List<Investment> investments,
  ) {
    if (investments.isEmpty) return [];

    final sortedInvestments = [...investments]
      ..sort((a, b) => a.signedDate.compareTo(b.signedDate));

    final history = <PerformanceHistoryItem>[];
    final monthlyData = <String, List<Investment>>{};

    // Grupuj według miesięcy
    for (final investment in sortedInvestments) {
      final monthKey =
          '${investment.signedDate.year}-${investment.signedDate.month.toString().padLeft(2, '0')}';
      monthlyData.putIfAbsent(monthKey, () => []).add(investment);
    }

    double cumulativeReturn = 0;
    for (final entry in monthlyData.entries) {
      final monthInvestments = entry.value;
      final periodReturn = _calculatePeriodReturn(monthInvestments);
      cumulativeReturn += periodReturn;

      final returns = monthInvestments
          .map((inv) => inv.profitLossPercentage)
          .toList();
      final volatility = _calculateVolatility(returns);
      final sharpeRatio = _calculateSharpeRatio(returns);

      history.add(
        PerformanceHistoryItem(
          date: DateTime.parse('${entry.key}-01'),
          cumulativeReturn: cumulativeReturn,
          periodReturn: periodReturn,
          volatility: volatility,
          sharpeRatio: sharpeRatio,
        ),
      );
    }

    return history;
  }

  /// Oblicza wydajność produktów
  List<ProductPerformanceData> _calculateProductPerformance(
    List<Investment> investments,
  ) {
    final productGroups = <String, List<Investment>>{};

    // Grupuj według typu produktu
    for (final investment in investments) {
      final productType = investment.productType.name;
      productGroups.putIfAbsent(productType, () => []).add(investment);
    }

    final productPerformance = <ProductPerformanceData>[];
    for (final entry in productGroups.entries) {
      final productType = entry.key;
      final productInvestments = entry.value;

      final returns = productInvestments
          .map((inv) => inv.profitLossPercentage)
          .toList();
      final averageReturn = returns.isNotEmpty
          ? (returns.reduce((a, b) => a + b) / returns.length).toDouble()
          : 0.0;
      final volatility = _calculateVolatility(returns);
      final sharpeRatio = _calculateSharpeRatio(returns);
      final totalValue = productInvestments.fold<double>(
        0,
        (sum, inv) => sum + inv.totalValue,
      );
      final bestReturn = returns.isNotEmpty
          ? returns.reduce((a, b) => a > b ? a : b).toDouble()
          : 0.0;
      final worstReturn = returns.isNotEmpty
          ? returns.reduce((a, b) => a < b ? a : b).toDouble()
          : 0.0;

      productPerformance.add(
        ProductPerformanceData(
          productType: productType,
          productName: _getProductTypeName(productType),
          averageReturn: averageReturn,
          volatility: volatility,
          sharpeRatio: sharpeRatio,
          investmentCount: productInvestments.length,
          totalValue: totalValue,
          bestReturn: bestReturn,
          worstReturn: worstReturn,
        ),
      );
    }

    // Sortuj według średniego zwrotu
    productPerformance.sort(
      (a, b) => b.averageReturn.compareTo(a.averageReturn),
    );
    return productPerformance;
  }

  /// Oblicza metryki dostosowane do ryzyka
  RiskAdjustedMetrics _calculateRiskAdjustedMetrics(
    List<Investment> investments,
  ) {
    if (investments.isEmpty) {
      return RiskAdjustedMetrics(
        alpha: 0,
        beta: 0,
        informationRatio: 0,
        treynorRatio: 0,
        calmarRatio: 0,
        sortinoRatio: 0,
        maxDrawdown: 0,
        valueAtRisk95: 0,
        valueAtRisk99: 0,
      );
    }

    final returns = investments.map((inv) => inv.profitLossPercentage).toList();
    const riskFreeRate = 2.0;
    const marketReturn = 5.0; // Benchmark

    final alpha = _calculateAlpha(returns, marketReturn);
    final beta = _calculateBeta(returns);
    final informationRatio = _calculateInformationRatio(returns, marketReturn);
    final treynorRatio = _calculateTreynorRatio(returns, riskFreeRate, beta);
    final calmarRatio = _calculateCalmarRatio(investments);
    final sortinoRatio = _calculateSortinoRatio(returns, riskFreeRate);
    final maxDrawdown = _calculateMaxDrawdown(investments);
    final valueAtRisk95 = _calculateVaR(returns, 0.05);
    final valueAtRisk99 = _calculateVaR(returns, 0.01);

    return RiskAdjustedMetrics(
      alpha: alpha,
      beta: beta,
      informationRatio: informationRatio,
      treynorRatio: treynorRatio,
      calmarRatio: calmarRatio,
      sortinoRatio: sortinoRatio,
      maxDrawdown: maxDrawdown,
      valueAtRisk95: valueAtRisk95,
      valueAtRisk99: valueAtRisk99,
    );
  }

  // Metody pomocnicze

  double _calculateAnnualizedReturn(List<Investment> investments) {
    if (investments.isEmpty) return 0.0;

    final totalInvested = investments.fold<double>(
      0,
      (sum, inv) => sum + inv.investmentAmount,
    );
    final totalCurrent = investments.fold<double>(
      0,
      (sum, inv) => sum + inv.totalValue,
    );

    if (totalInvested <= 0) return 0.0;

    // Oblicz średni czas trwania inwestycji w latach
    final now = DateTime.now();
    final averageYears =
        investments
            .map((inv) {
              final daysDiff = now.difference(inv.signedDate).inDays;
              return daysDiff / 365.25;
            })
            .reduce((a, b) => a + b) /
        investments.length;

    if (averageYears <= 0) return 0.0;

    // CAGR = (End Value / Begin Value)^(1/years) - 1
    return (math.pow(totalCurrent / totalInvested, 1 / averageYears) - 1) * 100;
  }

  double _calculateAverageHoldingPeriod(List<Investment> investments) {
    if (investments.isEmpty) return 0;

    final now = DateTime.now();
    final totalDays = investments.fold<int>(0, (sum, inv) {
      final endDate = inv.exitDate ?? now;
      return sum + endDate.difference(inv.signedDate).inDays;
    });

    return totalDays / investments.length;
  }

  double _calculateWinLossRatio(List<Investment> investments) {
    final winners = investments.where((inv) => inv.profitLoss > 0).toList();
    final losers = investments.where((inv) => inv.profitLoss < 0).toList();

    if (losers.isEmpty) return double.infinity;
    if (winners.isEmpty) return 0;

    final avgWin =
        winners.fold<double>(0, (sum, inv) => sum + inv.profitLoss) /
        winners.length;
    final avgLoss =
        losers.fold<double>(0, (sum, inv) => sum + inv.profitLoss.abs()) /
        losers.length;

    return avgLoss > 0 ? avgWin / avgLoss : 0;
  }

  List<Investment> _getInvestmentsForPeriod(
    List<Investment> investments,
    int months,
  ) {
    final now = DateTime.now();

    if (months == -1) {
      // Year to date
      final yearStart = DateTime(now.year, 1, 1);
      return investments
          .where((inv) => inv.signedDate.isAfter(yearStart))
          .toList();
    } else {
      final startDate = now.subtract(Duration(days: months * 30));
      return investments
          .where((inv) => inv.signedDate.isAfter(startDate))
          .toList();
    }
  }

  double _calculatePeriodReturn(List<Investment> investments) {
    if (investments.isEmpty) return 0;

    final returns = investments.map((inv) => inv.profitLossPercentage).toList();
    return returns.reduce((a, b) => a + b) / returns.length;
  }

  double _calculateTrackingError(
    List<Investment> investments,
    double benchmark,
  ) {
    final returns = investments.map((inv) => inv.profitLossPercentage).toList();
    final excessReturns = returns.map((r) => r - benchmark).toList();
    return _calculateVolatility(excessReturns);
  }

  double _calculateVolatility(List<double> returns) {
    if (returns.isEmpty) return 0;
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance =
        returns.map((r) => math.pow(r - mean, 2)).reduce((a, b) => a + b) /
        returns.length;
    return math.sqrt(variance);
  }

  double _calculateSharpeRatio(List<double> returns) {
    if (returns.isEmpty) return 0;
    const riskFreeRate = 2.0;
    final avgReturn = returns.reduce((a, b) => a + b) / returns.length;
    final volatility = _calculateVolatility(returns);
    return volatility > 0 ? (avgReturn - riskFreeRate) / volatility : 0;
  }

  double _calculateAlpha(List<double> returns, double marketReturn) {
    if (returns.isEmpty) return 0;
    final avgReturn = returns.reduce((a, b) => a + b) / returns.length;
    return avgReturn - marketReturn;
  }

  double _calculateBeta(List<double> returns) {
    // Uproszczona implementacja - w rzeczywistości wymagałaby danych rynkowych
    return 1.0;
  }

  double _calculateInformationRatio(List<double> returns, double benchmark) {
    final excessReturns = returns.map((r) => r - benchmark).toList();
    final avgExcessReturn =
        excessReturns.reduce((a, b) => a + b) / excessReturns.length;
    final trackingError = _calculateVolatility(excessReturns);
    return trackingError > 0 ? avgExcessReturn / trackingError : 0;
  }

  double _calculateTreynorRatio(
    List<double> returns,
    double riskFreeRate,
    double beta,
  ) {
    if (returns.isEmpty || beta == 0) return 0;
    final avgReturn = returns.reduce((a, b) => a + b) / returns.length;
    return (avgReturn - riskFreeRate) / beta;
  }

  double _calculateCalmarRatio(List<Investment> investments) {
    final annualizedReturn = _calculateAnnualizedReturn(investments);
    final maxDrawdown = _calculateMaxDrawdown(investments);
    return maxDrawdown > 0 ? annualizedReturn / maxDrawdown : 0;
  }

  double _calculateSortinoRatio(List<double> returns, double riskFreeRate) {
    if (returns.isEmpty) return 0;

    final avgReturn = returns.reduce((a, b) => a + b) / returns.length;
    final downwardReturns = returns.where((r) => r < riskFreeRate).toList();

    if (downwardReturns.isEmpty) return double.infinity;

    final downwardDeviation = math.sqrt(
      downwardReturns
              .map((r) => math.pow(r - riskFreeRate, 2))
              .reduce((a, b) => a + b) /
          downwardReturns.length,
    );

    return downwardDeviation > 0
        ? (avgReturn - riskFreeRate) / downwardDeviation
        : 0;
  }

  double _calculateMaxDrawdown(List<Investment> investments) {
    if (investments.isEmpty) return 0;

    final sortedByDate = [...investments]
      ..sort((a, b) => a.signedDate.compareTo(b.signedDate));

    double peak = 0;
    double maxDrawdown = 0;
    double runningValue = 0;

    for (final investment in sortedByDate) {
      runningValue += investment.totalValue;
      if (runningValue > peak) peak = runningValue;
      final drawdown = (peak - runningValue) / peak * 100;
      if (drawdown > maxDrawdown) maxDrawdown = drawdown;
    }

    return maxDrawdown;
  }

  double _calculateVaR(List<double> returns, double confidence) {
    if (returns.isEmpty) return 0;
    final sorted = [...returns]..sort();
    final index = (returns.length * confidence).floor();
    return index < sorted.length ? sorted[index] : sorted.last;
  }

  String _getProductTypeName(String productType) {
    switch (productType.toLowerCase()) {
      case 'bonds':
        return 'Obligacje';
      case 'shares':
        return 'Udziały';
      case 'apartments':
        return 'Apartamenty';
      case 'loans':
        return 'Pożyczki';
      default:
        return productType;
    }
  }

  // Metoda konwersji dokumentu
  Investment _convertInvestmentFromDocument(doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Investment(
      id: doc.id,
      clientId: data['clientId']?.toString() ?? '',
      clientName: data['clientName']?.toString() ?? '',
      employeeId: data['employeeId']?.toString() ?? '',
      employeeFirstName: data['employeeFirstName']?.toString() ?? '',
      employeeLastName: data['employeeLastName']?.toString() ?? '',
      branchCode: data['branchCode']?.toString() ?? '',
      status: _mapInvestmentStatus(data['status']),
      isAllocated: data['isAllocated'] == true,
      marketType: _mapMarketType(data['marketType']),
      signedDate: _parseDate(data['signedDate']) ?? DateTime.now(),
      entryDate: _parseDate(data['entryDate']),
      exitDate: _parseDate(data['exitDate']),
      proposalId: data['proposalId']?.toString() ?? '',
      productType: _mapProductType(data['productType']),
      productName: data['productName']?.toString() ?? '',
      creditorCompany: data['creditorCompany']?.toString() ?? '',
      companyId: data['companyId']?.toString() ?? '',
      issueDate: _parseDate(data['issueDate']),
      redemptionDate: _parseDate(data['redemptionDate']),
      sharesCount: data['sharesCount'] != null
          ? int.tryParse(data['sharesCount'].toString())
          : null,
      investmentAmount: _safeToDouble(data['investmentAmount']),
      paidAmount: _safeToDouble(data['paidAmount']),
      realizedCapital: _safeToDouble(data['realizedCapital']),
      realizedInterest: _safeToDouble(data['realizedInterest']),
      transferToOtherProduct: _safeToDouble(data['transferToOtherProduct']),
      remainingCapital: _safeToDouble(data['remainingCapital']),
      remainingInterest: _safeToDouble(data['remainingInterest']),
      plannedTax: _safeToDouble(data['plannedTax']),
      realizedTax: _safeToDouble(data['realizedTax']),
      currency: data['currency']?.toString() ?? 'PLN',
      exchangeRate: data['exchangeRate'] != null
          ? _safeToDouble(data['exchangeRate'])
          : null,
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(data['updatedAt']) ?? DateTime.now(),
      additionalInfo: data['additionalInfo'] as Map<String, dynamic>? ?? {},
    );
  }

  double _safeToDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(',', '');
      final parsed = double.tryParse(cleaned);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    if (dateValue is String && dateValue.isEmpty) return null;
    try {
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  InvestmentStatus _mapInvestmentStatus(dynamic status) {
    if (status == null) return InvestmentStatus.active;
    final statusStr = status.toString().toLowerCase();
    if (statusStr.contains('active')) return InvestmentStatus.active;
    if (statusStr.contains('inactive')) return InvestmentStatus.inactive;
    if (statusStr.contains('completed')) return InvestmentStatus.completed;
    if (statusStr.contains('early')) return InvestmentStatus.earlyRedemption;
    return InvestmentStatus.active;
  }

  MarketType _mapMarketType(dynamic marketType) {
    if (marketType == null) return MarketType.primary;
    final typeStr = marketType.toString().toLowerCase();
    if (typeStr.contains('secondary')) return MarketType.secondary;
    if (typeStr.contains('redemption')) return MarketType.clientRedemption;
    return MarketType.primary;
  }

  ProductType _mapProductType(dynamic productType) {
    if (productType == null) return ProductType.bonds;
    final typeStr = productType.toString().toLowerCase();
    if (typeStr == 'loans' || typeStr == 'loan') return ProductType.loans;
    if (typeStr == 'shares' || typeStr == 'share') return ProductType.shares;
    if (typeStr == 'apartments' || typeStr == 'apartment')
      return ProductType.apartments;
    if (typeStr == 'bonds' || typeStr == 'bond') return ProductType.bonds;
    return ProductType.bonds;
  }
}
