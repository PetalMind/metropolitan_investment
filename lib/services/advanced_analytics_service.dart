import 'dart:math' as math;
import '../models/investment.dart';
import '../models/product.dart';
import 'base_service.dart';

/// Zaawansowany serwis analityczny z głębokimi statystykami
class AdvancedAnalyticsService extends BaseService {
  /// Pobiera zaawansowane metryki dashboard z cache'owaniem
  Future<AdvancedDashboardMetrics> getAdvancedDashboardMetrics() async {
    return getCachedData(
      'advanced_dashboard_metrics',
      () => _calculateAdvancedMetrics(),
    );
  }

  /// Czyści cache zaawansowanych metryk
  void clearAdvancedMetricsCache() {
    clearCache('advanced_dashboard_metrics');
  }

  /// Oblicza zaawansowane metryki
  Future<AdvancedDashboardMetrics> _calculateAdvancedMetrics() async {
    try {
      print(
        '🔍 [AdvancedAnalytics] Rozpoczynam obliczanie zaawansowanych metryk...',
      );

      final investments = await _getAllInvestments();
      print('🔍 [AdvancedAnalytics] Pobrano ${investments.length} inwestycji');

      final metrics = AdvancedDashboardMetrics(
        portfolioMetrics: await _calculatePortfolioMetrics(investments),
        riskMetrics: _calculateRiskMetrics(investments),
        performanceMetrics: _calculatePerformanceMetrics(investments),
        clientAnalytics: _calculateClientAnalytics(investments),
        productAnalytics: _calculateProductAnalytics(investments),
        employeeAnalytics: _calculateEmployeeAnalytics(investments),
        geographicAnalytics: _calculateGeographicAnalytics(investments),
        timeSeriesAnalytics: _calculateTimeSeriesAnalytics(investments),
        predictionMetrics: _calculatePredictionMetrics(investments),
        benchmarkMetrics: _calculateBenchmarkMetrics(investments),
      );

      print('🔍 [AdvancedAnalytics] Zakończono obliczanie metryk');
      return metrics;
    } catch (e) {
      logError('_calculateAdvancedMetrics', e);
      throw Exception('Błąd podczas obliczania zaawansowanych metryk: $e');
    }
  }

  /// Pobiera wszystkie inwestycje ze wszystkich kolekcji
  Future<List<Investment>> _getAllInvestments() async {
    try {
      print(
        '🔍 [AdvancedAnalytics] Pobieranie danych ze wszystkich kolekcji...',
      );

      // Pobierz dane równolegle ze wszystkich kolekcji
      final results = await Future.wait([
        firestore.collection('investments').get(),
        firestore.collection('bonds').get(),
        firestore.collection('loans').get(),
        firestore.collection('shares').get(),
      ]);

      final allInvestments = <Investment>[];

      // Konwertuj dane z głównej kolekcji investments
      for (final doc in results[0].docs) {
        final data = doc.data();
        allInvestments.add(_convertExcelDataToInvestment(doc.id, data));
      }
      print('🔍 [AdvancedAnalytics] Investments: ${results[0].docs.length}');

      // Konwertuj dane z kolekcji bonds na Investment
      for (final doc in results[1].docs) {
        final data = doc.data();
        allInvestments.add(_convertBondToInvestment(doc.id, data));
      }
      print('🔍 [AdvancedAnalytics] Bonds: ${results[1].docs.length}');

      // Konwertuj dane z kolekcji loans na Investment
      for (final doc in results[2].docs) {
        final data = doc.data();
        allInvestments.add(_convertLoanToInvestment(doc.id, data));
      }
      print('🔍 [AdvancedAnalytics] Loans: ${results[2].docs.length}');

      // Konwertuj dane z kolekcji shares na Investment
      for (final doc in results[3].docs) {
        final data = doc.data();
        allInvestments.add(_convertShareToInvestment(doc.id, data));
      }
      print('🔍 [AdvancedAnalytics] Shares: ${results[3].docs.length}');

      print(
        '🔍 [AdvancedAnalytics] Łącznie inwestycji: ${allInvestments.length}',
      );
      return allInvestments;
    } catch (e) {
      logError('_getAllInvestments', e);
      return [];
    }
  }

  /// Metryki portfela
  Future<PortfolioMetrics> _calculatePortfolioMetrics(
    List<Investment> investments,
  ) async {
    double totalValue = 0;
    double totalInvested = 0;
    double totalRealized = 0;
    double totalRemaining = 0;
    double totalInterest = 0;
    int activeCount = 0;

    for (final investment in investments) {
      totalValue += investment.totalValue;
      totalInvested += investment.investmentAmount;
      totalRealized += investment.realizedCapital;
      totalRemaining += investment.remainingCapital;
      totalInterest +=
          investment.realizedInterest + investment.remainingInterest;

      if (investment.status == InvestmentStatus.active) {
        activeCount++;
      }
    }

    final totalProfit = totalRealized + totalInterest - totalInvested;
    final roi = totalInvested > 0 ? (totalProfit / totalInvested) * 100 : 0.0;

    return PortfolioMetrics(
      totalValue: totalValue,
      totalInvested: totalInvested,
      totalRealized: totalRealized,
      totalRemaining: totalRemaining,
      totalInterest: totalInterest,
      totalProfit: totalProfit,
      roi: roi,
      activeInvestmentsCount: activeCount,
      totalInvestmentsCount: investments.length,
      averageInvestmentSize: investments.isNotEmpty
          ? totalInvested / investments.length
          : 0,
      medianInvestmentSize: _calculateMedian(
        investments.map((i) => i.investmentAmount).toList(),
      ),
      portfolioGrowthRate: _calculateGrowthRate(investments),
    );
  }

  /// Metryki ryzyka
  RiskMetrics _calculateRiskMetrics(List<Investment> investments) {
    final returns = investments.map((i) => i.profitLossPercentage).toList();

    return RiskMetrics(
      volatility: _calculateVolatility(returns),
      sharpeRatio: _calculateSharpeRatio(returns),
      maxDrawdown: _calculateMaxDrawdown(investments),
      valueAtRisk: _calculateVaR(returns),
      concentrationRisk: _calculateConcentrationRisk(investments),
      diversificationRatio: _calculateDiversificationRatio(investments),
      liquidityRisk: _calculateLiquidityRisk(investments),
      creditRisk: _calculateCreditRisk(investments),
      beta: _calculateBeta(investments),
    );
  }

  /// Metryki wydajności
  PerformanceMetrics _calculatePerformanceMetrics(
    List<Investment> investments,
  ) {
    final returns = investments.map((i) => i.profitLossPercentage).toList();
    final profitableCount = investments.where((i) => i.profitLoss > 0).length;

    // Obliczenie całkowitego ROI
    final totalInvested = investments.fold<double>(
      0,
      (sum, inv) => sum + inv.investmentAmount,
    );
    final totalCurrent = investments.fold<double>(
      0,
      (sum, inv) => sum + inv.totalValue,
    );
    final totalROI = totalInvested > 0
        ? ((totalCurrent - totalInvested) / totalInvested) * 100
        : 0.0;

    // Obliczenie CAGR (roczny zwrot składany)
    final annualizedReturn = _calculateAnnualizedReturn(investments);

    // Obliczenie Sharpe Ratio - przekaż listę zwrotów
    final sharpeRatio = _calculateSharpeRatio(returns);

    // Obliczenie maksymalnego spadku
    final maxDrawdown = _calculateMaxDrawdown(investments);

    // Analiza wydajności według typu produktu
    final productPerformance = _calculateProductPerformanceMap(investments);

    // Top performers
    final topPerformers = _getTopPerformers(investments);

    return PerformanceMetrics(
      averageReturn: returns.isNotEmpty
          ? returns.reduce((a, b) => a + b) / returns.length
          : 0,
      bestPerformingInvestment: _findBestPerformingInvestment(investments),
      worstPerformingInvestment: _findWorstPerformingInvestment(investments),
      successRate: investments.isNotEmpty
          ? (profitableCount / investments.length) * 100
          : 0,
      alpha: _calculateAlpha(investments),
      beta: _calculateBeta(investments),
      informationRatio: _calculateInformationRatio(investments),
      trackingError: _calculateTrackingError(investments),
      totalROI: totalROI,
      annualizedReturn: annualizedReturn,
      sharpeRatio: sharpeRatio,
      maxDrawdown: maxDrawdown,
      productPerformance: productPerformance,
      topPerformers: topPerformers,
    );
  }

  /// Analityka klientów
  ClientAnalytics _calculateClientAnalytics(List<Investment> investments) {
    final clientGroups = <String, List<Investment>>{};

    for (final investment in investments) {
      clientGroups.putIfAbsent(investment.clientName, () => []).add(investment);
    }

    final clientValues = clientGroups.map(
      (name, invs) => MapEntry(
        name,
        invs.fold<double>(0, (sum, inv) => sum + inv.totalValue),
      ),
    );

    final sortedClients = clientValues.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ClientAnalytics(
      totalClients: clientGroups.length,
      topClients: sortedClients
          .take(10)
          .map((e) => TopClient(name: e.key, value: e.value))
          .toList(),
      clientConcentration: _calculateClientConcentration(clientValues),
      averageClientValue: clientValues.isNotEmpty
          ? clientValues.values.reduce((a, b) => a + b) / clientValues.length
          : 0,
      clientRetention: _calculateClientRetention(investments),
      newClientsThisMonth: _calculateNewClientsThisMonth(investments),
    );
  }

  /// Analityka produktów
  ProductAnalytics _calculateProductAnalytics(List<Investment> investments) {
    final productGroups = <ProductType, List<Investment>>{};

    for (final investment in investments) {
      productGroups
          .putIfAbsent(investment.productType, () => [])
          .add(investment);
    }

    final productPerformance = productGroups.map(
      (type, invs) => MapEntry(
        type,
        ProductPerformance(
          totalValue: invs.fold<double>(0, (sum, inv) => sum + inv.totalValue),
          averageReturn: invs.isNotEmpty
              ? invs.fold<double>(
                      0,
                      (sum, inv) => sum + inv.profitLossPercentage,
                    ) /
                    invs.length
              : 0,
          count: invs.length,
          riskLevel: _calculateProductRisk(invs),
        ),
      ),
    );

    return ProductAnalytics(
      productPerformance: productPerformance,
      bestPerformingProduct: _findBestPerformingProduct(productPerformance),
      worstPerformingProduct: _findWorstPerformingProduct(productPerformance),
      productDiversification: _calculateProductDiversification(investments),
    );
  }

  /// Analityka pracowników
  EmployeeAnalytics _calculateEmployeeAnalytics(List<Investment> investments) {
    final employeeGroups = <String, List<Investment>>{};

    for (final investment in investments) {
      final employeeKey =
          '${investment.employeeFirstName} ${investment.employeeLastName}'
              .trim();
      if (employeeKey.isNotEmpty) {
        employeeGroups.putIfAbsent(employeeKey, () => []).add(investment);
      }
    }

    final employeePerformance = employeeGroups.map(
      (name, invs) => MapEntry(
        name,
        EmployeePerformance(
          totalVolume: invs.fold<double>(
            0,
            (sum, inv) => sum + inv.investmentAmount,
          ),
          averageReturn: invs.isNotEmpty
              ? invs.fold<double>(
                      0,
                      (sum, inv) => sum + inv.profitLossPercentage,
                    ) /
                    invs.length
              : 0,
          transactionCount: invs.length,
          clientCount: invs.map((inv) => inv.clientName).toSet().length,
        ),
      ),
    );

    final sortedByVolume = employeePerformance.entries.toList()
      ..sort((a, b) => b.value.totalVolume.compareTo(a.value.totalVolume));

    return EmployeeAnalytics(
      employeePerformance: employeePerformance,
      topPerformers: sortedByVolume
          .take(5)
          .map((e) => TopEmployee(name: e.key, performance: e.value))
          .toList(),
      averageEmployeeVolume: employeePerformance.isNotEmpty
          ? employeePerformance.values.fold<double>(
                  0,
                  (sum, perf) => sum + perf.totalVolume,
                ) /
                employeePerformance.length
          : 0,
    );
  }

  /// Analityka geograficzna
  GeographicAnalytics _calculateGeographicAnalytics(
    List<Investment> investments,
  ) {
    final branchGroups = <String, List<Investment>>{};

    for (final investment in investments) {
      final branch = investment.branchCode.isNotEmpty
          ? investment.branchCode
          : 'Nieznany';
      branchGroups.putIfAbsent(branch, () => []).add(investment);
    }

    final branchPerformance = branchGroups.map(
      (code, invs) => MapEntry(
        code,
        BranchPerformance(
          totalVolume: invs.fold<double>(
            0,
            (sum, inv) => sum + inv.investmentAmount,
          ),
          averageReturn: invs.isNotEmpty
              ? invs.fold<double>(
                      0,
                      (sum, inv) => sum + inv.profitLossPercentage,
                    ) /
                    invs.length
              : 0,
          transactionCount: invs.length,
          clientCount: invs.map((inv) => inv.clientName).toSet().length,
        ),
      ),
    );

    return GeographicAnalytics(
      branchPerformance: branchPerformance,
      topBranches: branchPerformance.entries.toList()
        ..sort((a, b) => b.value.totalVolume.compareTo(a.value.totalVolume)),
      geographicDiversification: _calculateGeographicDiversification(
        investments,
      ),
    );
  }

  /// Analityka szeregów czasowych
  TimeSeriesAnalytics _calculateTimeSeriesAnalytics(
    List<Investment> investments,
  ) {
    final monthlyData = <String, MonthlyData>{};

    for (final investment in investments) {
      final monthKey =
          '${investment.signedDate.year}-${investment.signedDate.month.toString().padLeft(2, '0')}';

      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = MonthlyData(
          month: monthKey,
          totalInvestments: 0,
          totalVolume: 0,
          averageReturn: 0,
          transactionCount: 0,
        );
      }

      monthlyData[monthKey] = monthlyData[monthKey]!.copyWith(
        totalVolume:
            monthlyData[monthKey]!.totalVolume + investment.investmentAmount,
        transactionCount: monthlyData[monthKey]!.transactionCount + 1,
      );
    }

    // Oblicz średnie zwroty dla każdego miesiąca
    for (final entry in monthlyData.entries) {
      final monthInvestments = investments
          .where(
            (inv) =>
                '${inv.signedDate.year}-${inv.signedDate.month.toString().padLeft(2, '0')}' ==
                entry.key,
          )
          .toList();

      final avgReturn = monthInvestments.isNotEmpty
          ? monthInvestments.fold<double>(
                  0,
                  (sum, inv) => sum + inv.profitLossPercentage,
                ) /
                monthInvestments.length
          : 0.0;

      monthlyData[entry.key] = entry.value.copyWith(averageReturn: avgReturn);
    }

    final sortedMonths = monthlyData.values.toList()
      ..sort((a, b) => a.month.compareTo(b.month));

    return TimeSeriesAnalytics(
      monthlyData: sortedMonths,
      growthTrend: _calculateGrowthTrend(sortedMonths),
      seasonality: _calculateSeasonality(sortedMonths),
      momentum: _calculateMomentum(sortedMonths),
    );
  }

  /// Metryki predykcyjne
  PredictionMetrics _calculatePredictionMetrics(List<Investment> investments) {
    final activeInvestments = investments
        .where((inv) => inv.status == InvestmentStatus.active)
        .toList();

    return PredictionMetrics(
      projectedReturns: _projectReturns(activeInvestments),
      expectedMaturityValue: _calculateExpectedMaturityValue(activeInvestments),
      riskAdjustedReturns: _calculateRiskAdjustedReturns(activeInvestments),
      portfolioOptimization: _calculatePortfolioOptimization(investments),
    );
  }

  /// Metryki benchmarkowe
  BenchmarkMetrics _calculateBenchmarkMetrics(List<Investment> investments) {
    // Zakładamy benchmark 5% rocznie dla rynku obligacji
    const marketBenchmark = 5.0;

    final portfolioReturn = investments.isNotEmpty
        ? investments.fold<double>(
                0,
                (sum, inv) => sum + inv.profitLossPercentage,
              ) /
              investments.length
        : 0;

    return BenchmarkMetrics(
      vsMarketReturn: portfolioReturn - marketBenchmark,
      relativePerfomance: marketBenchmark != 0
          ? (portfolioReturn / marketBenchmark) * 100
          : 0,
      outperformingInvestments: investments
          .where((inv) => inv.profitLossPercentage > marketBenchmark)
          .length,
      benchmarkCorrelation: _calculateBenchmarkCorrelation(
        investments,
        marketBenchmark,
      ),
    );
  }

  // Metody pomocnicze

  double _calculateMedian(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    }
    return sorted[middle];
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
    const riskFreeRate = 2.0; // 2% stopa wolna od ryzyka
    final avgReturn = returns.reduce((a, b) => a + b) / returns.length;
    final volatility = _calculateVolatility(returns);
    return volatility > 0 ? (avgReturn - riskFreeRate) / volatility : 0;
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

  double _calculateVaR(List<double> returns, {double confidence = 0.05}) {
    if (returns.isEmpty) return 0;
    final sorted = [...returns]..sort();
    final index = (returns.length * confidence).floor();
    return index < sorted.length ? sorted[index] : sorted.last;
  }

  double _calculateConcentrationRisk(List<Investment> investments) {
    final productValues = <ProductType, double>{};
    double totalValue = 0;

    for (final investment in investments) {
      productValues[investment.productType] =
          (productValues[investment.productType] ?? 0) + investment.totalValue;
      totalValue += investment.totalValue;
    }

    if (totalValue == 0) return 0;

    double hhi = 0;
    for (final value in productValues.values) {
      final share = value / totalValue;
      hhi += share * share;
    }

    return hhi * 10000; // HHI w skali 0-10000
  }

  // Dodatkowe metody pomocnicze będą kontynuowane...
  double _calculateGrowthRate(List<Investment> investments) {
    // Implementacja kalkulacji stopy wzrostu
    if (investments.length < 2) return 0;

    final sortedByDate = [...investments]
      ..sort((a, b) => a.signedDate.compareTo(b.signedDate));
    final firstValue = sortedByDate.first.investmentAmount;
    final lastValue = sortedByDate.last.totalValue;

    if (firstValue <= 0) return 0;
    return ((lastValue / firstValue) - 1) * 100;
  }

  double _calculateDiversificationRatio(List<Investment> investments) {
    // Wskaźnik dywersyfikacji portfela
    final productTypes = investments.map((inv) => inv.productType).toSet();
    final totalInvestments = investments.length;

    if (totalInvestments == 0) return 0;
    return (productTypes.length / totalInvestments) * 100;
  }

  double _calculateLiquidityRisk(List<Investment> investments) {
    // Ryzyko płynności - procent inwestycji długoterminowych
    final longTermInvestments = investments.where((inv) {
      if (inv.redemptionDate == null) return false;
      final duration = inv.redemptionDate!.difference(DateTime.now()).inDays;
      return duration > 365; // więcej niż rok
    }).length;

    return investments.isNotEmpty
        ? (longTermInvestments / investments.length) * 100
        : 0;
  }

  double _calculateCreditRisk(List<Investment> investments) {
    // Uproszczone ryzyko kredytowe - bazowane na typie produktu
    double riskScore = 0;
    for (final investment in investments) {
      switch (investment.productType) {
        case ProductType.bonds:
          riskScore += 1; // niskie ryzyko
          break;
        case ProductType.shares:
          riskScore += 3; // wysokie ryzyko
          break;
        case ProductType.apartments:
          riskScore += 2; // średnie ryzyko
          break;
        case ProductType.loans:
          riskScore += 4; // bardzo wysokie ryzyko
          break;
      }
    }

    return investments.isNotEmpty ? riskScore / investments.length : 0;
  }

  Investment? _findBestPerformingInvestment(List<Investment> investments) {
    if (investments.isEmpty) return null;
    return investments.reduce(
      (current, next) =>
          next.profitLossPercentage > current.profitLossPercentage
          ? next
          : current,
    );
  }

  Investment? _findWorstPerformingInvestment(List<Investment> investments) {
    if (investments.isEmpty) return null;
    return investments.reduce(
      (current, next) =>
          next.profitLossPercentage < current.profitLossPercentage
          ? next
          : current,
    );
  }

  double _calculateAlpha(List<Investment> investments) {
    // Uproszczona kalkulacja alpha (nadwyżka nad benchmark)
    const benchmark = 5.0;
    final portfolioReturn = investments.isNotEmpty
        ? investments.fold<double>(
                0,
                (sum, inv) => sum + inv.profitLossPercentage,
              ) /
              investments.length
        : 0;
    return portfolioReturn - benchmark;
  }

  double _calculateBeta(List<Investment> investments) {
    // Uproszczona kalkulacja beta (wrażliwość na rynek)
    // W rzeczywistej implementacji wymagałaby danych rynkowych
    return 1.0; // neutralna beta
  }

  double _calculateInformationRatio(List<Investment> investments) {
    const benchmark = 5.0;
    final returns = investments.map((inv) => inv.profitLossPercentage).toList();
    if (returns.isEmpty) return 0;

    final excessReturns = returns.map((r) => r - benchmark).toList();
    final avgExcessReturn =
        excessReturns.reduce((a, b) => a + b) / excessReturns.length;
    final trackingError = _calculateVolatility(excessReturns);

    return trackingError > 0 ? avgExcessReturn / trackingError : 0;
  }

  double _calculateTrackingError(List<Investment> investments) {
    const benchmark = 5.0;
    final returns = investments.map((inv) => inv.profitLossPercentage).toList();
    final excessReturns = returns.map((r) => r - benchmark).toList();
    return _calculateVolatility(excessReturns);
  }

  double _calculateClientConcentration(Map<String, double> clientValues) {
    if (clientValues.isEmpty) return 0;

    final totalValue = clientValues.values.reduce((a, b) => a + b);
    if (totalValue == 0) return 0;

    double hhi = 0;
    for (final value in clientValues.values) {
      final share = value / totalValue;
      hhi += share * share;
    }

    return hhi * 10000;
  }

  double _calculateClientRetention(List<Investment> investments) {
    // Uproszczona kalkulacja retencji klientów
    final now = DateTime.now();
    final lastYear = now.subtract(const Duration(days: 365));

    final oldClients = investments
        .where((inv) => inv.signedDate.isBefore(lastYear))
        .map((inv) => inv.clientName)
        .toSet();

    final recentClients = investments
        .where((inv) => inv.signedDate.isAfter(lastYear))
        .map((inv) => inv.clientName)
        .toSet();

    final retainedClients = oldClients.intersection(recentClients);

    return oldClients.isNotEmpty
        ? (retainedClients.length / oldClients.length) * 100
        : 0;
  }

  int _calculateNewClientsThisMonth(List<Investment> investments) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);

    return investments
        .where((inv) => inv.signedDate.isAfter(thisMonth))
        .map((inv) => inv.clientName)
        .toSet()
        .length;
  }

  double _calculateProductRisk(List<Investment> investments) {
    final returns = investments.map((inv) => inv.profitLossPercentage).toList();
    return _calculateVolatility(returns);
  }

  ProductType? _findBestPerformingProduct(
    Map<ProductType, ProductPerformance> productPerformance,
  ) {
    if (productPerformance.isEmpty) return null;

    final sortedProducts = productPerformance.entries.toList()
      ..sort((a, b) => b.value.averageReturn.compareTo(a.value.averageReturn));

    return sortedProducts.first.key;
  }

  ProductType? _findWorstPerformingProduct(
    Map<ProductType, ProductPerformance> productPerformance,
  ) {
    if (productPerformance.isEmpty) return null;

    final sortedProducts = productPerformance.entries.toList()
      ..sort((a, b) => a.value.averageReturn.compareTo(b.value.averageReturn));

    return sortedProducts.first.key;
  }

  double _calculateProductDiversification(List<Investment> investments) {
    final productCounts = <ProductType, int>{};
    for (final investment in investments) {
      productCounts[investment.productType] =
          (productCounts[investment.productType] ?? 0) + 1;
    }

    if (productCounts.isEmpty) return 0;

    final totalInvestments = investments.length;
    double entropy = 0;

    for (final count in productCounts.values) {
      final probability = count / totalInvestments;
      if (probability > 0) {
        entropy -= probability * math.log(probability) / math.ln2;
      }
    }

    return entropy;
  }

  double _calculateGeographicDiversification(List<Investment> investments) {
    final branchCounts = <String, int>{};
    for (final investment in investments) {
      final branch = investment.branchCode.isNotEmpty
          ? investment.branchCode
          : 'Nieznany';
      branchCounts[branch] = (branchCounts[branch] ?? 0) + 1;
    }

    return branchCounts.length.toDouble();
  }

  double _calculateGrowthTrend(List<MonthlyData> monthlyData) {
    if (monthlyData.length < 2) return 0;

    final volumes = monthlyData.map((data) => data.totalVolume).toList();
    double trend = 0;

    for (int i = 1; i < volumes.length; i++) {
      if (volumes[i - 1] > 0) {
        trend += (volumes[i] - volumes[i - 1]) / volumes[i - 1];
      }
    }

    return trend / (volumes.length - 1) * 100;
  }

  Map<int, double> _calculateSeasonality(List<MonthlyData> monthlyData) {
    final monthlyAverages = <int, List<double>>{};

    for (final data in monthlyData) {
      final month = int.parse(data.month.split('-')[1]);
      monthlyAverages.putIfAbsent(month, () => []).add(data.totalVolume);
    }

    return monthlyAverages.map(
      (month, volumes) => MapEntry(
        month,
        volumes.isNotEmpty
            ? volumes.reduce((a, b) => a + b) / volumes.length
            : 0,
      ),
    );
  }

  double _calculateMomentum(List<MonthlyData> monthlyData) {
    if (monthlyData.length < 3) return 0;

    final recentData = monthlyData.takeLast(3).toList();
    final volumes = recentData.map((data) => data.totalVolume).toList();

    return (volumes.last - volumes.first) / volumes.first * 100;
  }

  double _projectReturns(List<Investment> activeInvestments) {
    if (activeInvestments.isEmpty) return 0;

    final avgReturn =
        activeInvestments
            .map((inv) => inv.profitLossPercentage)
            .reduce((a, b) => a + b) /
        activeInvestments.length;

    return avgReturn * 1.2; // Projekcja z 20% buforem
  }

  double _calculateExpectedMaturityValue(List<Investment> activeInvestments) {
    return activeInvestments.fold<double>(
      0,
      (sum, inv) => sum + inv.remainingCapital + inv.remainingInterest,
    );
  }

  double _calculateRiskAdjustedReturns(List<Investment> activeInvestments) {
    if (activeInvestments.isEmpty) return 0;

    final returns = activeInvestments
        .map((inv) => inv.profitLossPercentage)
        .toList();
    final avgReturn = returns.reduce((a, b) => a + b) / returns.length;
    final volatility = _calculateVolatility(returns);

    return volatility > 0 ? avgReturn / volatility : 0;
  }

  String _calculatePortfolioOptimization(List<Investment> investments) {
    final productPerformance = <ProductType, double>{};
    final productCounts = <ProductType, int>{};

    for (final investment in investments) {
      productPerformance[investment.productType] =
          (productPerformance[investment.productType] ?? 0) +
          investment.profitLossPercentage;
      productCounts[investment.productType] =
          (productCounts[investment.productType] ?? 0) + 1;
    }

    ProductType? bestProduct;
    double bestAvgReturn = double.negativeInfinity;

    for (final type in productPerformance.keys) {
      final avgReturn = productPerformance[type]! / productCounts[type]!;
      if (avgReturn > bestAvgReturn) {
        bestAvgReturn = avgReturn;
        bestProduct = type;
      }
    }

    return bestProduct != null
        ? 'Zwiększ alokację w ${_getProductTypeName(bestProduct)}'
        : 'Brak rekomendacji';
  }

  double _calculateBenchmarkCorrelation(
    List<Investment> investments,
    double benchmark,
  ) {
    // Uproszczona korelacja z benchmarkiem
    final returns = investments.map((inv) => inv.profitLossPercentage).toList();
    if (returns.isEmpty) return 0;

    final avgReturn = returns.reduce((a, b) => a + b) / returns.length;
    return (avgReturn / benchmark).clamp(-1.0, 1.0);
  }

  String _getProductTypeName(ProductType type) {
    switch (type) {
      case ProductType.bonds:
        return 'Obligacje';
      case ProductType.shares:
        return 'Udziały';
      case ProductType.apartments:
        return 'Apartamenty';
      case ProductType.loans:
        return 'Pożyczki';
    }
  }

  /// Konwersja danych Excel do Investment
  Investment _convertExcelDataToInvestment(
    String id,
    Map<String, dynamic> data,
  ) {
    InvestmentStatus status = InvestmentStatus.active;
    final statusStr = data['status_produktu']?.toString() ?? '';
    if (statusStr == 'Nieaktywny' || statusStr == 'Nieaktywowany') {
      status = InvestmentStatus.inactive;
    } else if (statusStr == 'Wykup wczesniejszy') {
      status = InvestmentStatus.earlyRedemption;
    }

    ProductType productType = ProductType.bonds;
    final typeStr = data['typ_produktu']?.toString() ?? '';
    if (typeStr == 'Udziały') productType = ProductType.shares;
    if (typeStr == 'Apartamenty') productType = ProductType.apartments;
    if (typeStr == 'Pożyczka') productType = ProductType.loans;

    // Mapowanie zgodne z JSON z investments_data.json
    MarketType marketType = MarketType.primary;
    final marketStr = data['produkt_status_wejscie']?.toString() ?? '';
    if (marketStr == 'Rynek wtórny') marketType = MarketType.secondary;
    if (marketStr == 'Odkup od Klienta')
      marketType = MarketType.clientRedemption;

    return Investment(
      id: id,
      clientId: data['id_klient']?.toString() ?? '',
      clientName: data['klient']?.toString() ?? '',
      employeeId: data['id_klient']?.toString() ?? '',
      employeeFirstName: data['praconwnik_imie']?.toString() ?? '',
      employeeLastName: data['pracownik_nazwisko']?.toString() ?? '',
      branchCode: data['oddzial']?.toString() ?? '',
      status: status,
      isAllocated:
          (data['przydzial']?.toString() == '1') || (data['przydzial'] == 1.0),
      marketType: marketType,
      signedDate:
          DateTime.tryParse(data['data_podpisania']?.toString() ?? '') ??
          DateTime.now(),
      entryDate: DateTime.tryParse(
        data['data_wejscia_do_inwestycji']?.toString() ?? '',
      ),
      exitDate: DateTime.tryParse(
        data['data_wyjscia_z_inwestycji']?.toString() ?? '',
      ),
      proposalId: data['id_propozycja_nabycia']?.toString() ?? '',
      productType: productType,
      productName: data['produkt_nazwa']?.toString() ?? '',
      creditorCompany: data['wierzyciel_spolka']?.toString() ?? '',
      companyId: data['id_spolka']?.toString() ?? '',
      issueDate: DateTime.tryParse(data['data_emisji']?.toString() ?? ''),
      redemptionDate: DateTime.tryParse(data['data_wykupu']?.toString() ?? ''),
      sharesCount: data['ilosc_udzialow']?.toInt(),
      investmentAmount: (data['kwota_inwestycji']?.toDouble() ?? 0.0),
      paidAmount: (data['kwota_wplat']?.toDouble() ?? 0.0),
      realizedCapital: (data['kapital_zrealizowany']?.toDouble() ?? 0.0),
      realizedInterest: (data['odsetki_zrealizowane']?.toDouble() ?? 0.0),
      transferToOtherProduct:
          (data['przekaz_na_inny_produkt']?.toDouble() ?? 0.0),
      remainingCapital: (data['kapital_pozostaly']?.toDouble() ?? 0.0),
      remainingInterest: (data['odsetki_pozostale']?.toDouble() ?? 0.0),
      plannedTax: (data['planowany_podatek']?.toDouble() ?? 0.0),
      realizedTax: (data['zrealizowany_podatek']?.toDouble() ?? 0.0),
      currency: 'PLN', // Domyślnie PLN
      exchangeRate: null,
      createdAt:
          DateTime.tryParse(data['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.now(),
      additionalInfo: {
        'id_sprzedaz': data['id_sprzedaz']?.toString() ?? '',
        'wierzyciel_spolka': data['wierzyciel_spolka']?.toString() ?? '',
      },
    );
  }

  /// Konwertuje dokument z kolekcji bonds na Investment
  Investment _convertBondToInvestment(String id, Map<String, dynamic> data) {
    return Investment(
      id: id,
      clientId: '', // Bonds nie mają bezpośredniego ID klienta
      clientName: '',
      employeeId: '',
      employeeFirstName: '',
      employeeLastName: '',
      branchCode: '',
      status: InvestmentStatus.active,
      isAllocated: false,
      marketType: MarketType.primary,
      signedDate:
          DateTime.tryParse(data['created_at']?.toString() ?? '') ??
          DateTime.now(),
      entryDate: null,
      exitDate: null,
      proposalId: '',
      productType: ProductType.bonds,
      productName: data['typ_produktu']?.toString() ?? '',
      creditorCompany: '',
      companyId: '',
      issueDate: null,
      redemptionDate: null,
      sharesCount: null,
      investmentAmount: data['kwota_inwestycji']?.toDouble() ?? 0.0,
      paidAmount: data['kwota_inwestycji']?.toDouble() ?? 0.0,
      realizedCapital: data['kapital_zrealizowany']?.toDouble() ?? 0.0,
      realizedInterest: data['odsetki_zrealizowane']?.toDouble() ?? 0.0,
      transferToOtherProduct:
          data['przekaz_na_inny_produkt']?.toDouble() ?? 0.0,
      remainingCapital: data['kapital_pozostaly']?.toDouble() ?? 0.0,
      remainingInterest: data['odsetki_pozostale']?.toDouble() ?? 0.0,
      plannedTax: 0.0,
      realizedTax: data['podatek_zrealizowany']?.toDouble() ?? 0.0,
      currency: 'PLN',
      exchangeRate: null,
      createdAt:
          DateTime.tryParse(data['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.now(),
      additionalInfo: {
        'source': 'bonds_collection',
        'podatek_pozostaly': data['podatek_pozostaly']?.toString() ?? '',
      },
    );
  }

  /// Konwertuje dokument z kolekcji loans na Investment
  Investment _convertLoanToInvestment(String id, Map<String, dynamic> data) {
    return Investment(
      id: id,
      clientId: '',
      clientName: '',
      employeeId: '',
      employeeFirstName: '',
      employeeLastName: '',
      branchCode: '',
      status: InvestmentStatus.active,
      isAllocated: false,
      marketType: MarketType.primary,
      signedDate:
          DateTime.tryParse(data['created_at']?.toString() ?? '') ??
          DateTime.now(),
      entryDate: null,
      exitDate: null,
      proposalId: '',
      productType: ProductType.loans, // Pożyczki jako osobny typ produktu
      productName: data['typ_produktu']?.toString() ?? '',
      creditorCompany: '',
      companyId: '',
      issueDate: null,
      redemptionDate: null,
      sharesCount: null,
      investmentAmount: data['kwota_inwestycji']?.toDouble() ?? 0.0,
      paidAmount: data['kwota_inwestycji']?.toDouble() ?? 0.0,
      realizedCapital: 0.0,
      realizedInterest: 0.0,
      transferToOtherProduct: 0.0,
      remainingCapital: data['kwota_inwestycji']?.toDouble() ?? 0.0,
      remainingInterest: 0.0,
      plannedTax: 0.0,
      realizedTax: 0.0,
      currency: 'PLN',
      exchangeRate: null,
      createdAt:
          DateTime.tryParse(data['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.now(),
      additionalInfo: {'source': 'loans_collection'},
    );
  }

  /// Konwertuje dokument z kolekcji shares na Investment
  Investment _convertShareToInvestment(String id, Map<String, dynamic> data) {
    return Investment(
      id: id,
      clientId: '',
      clientName: '',
      employeeId: '',
      employeeFirstName: '',
      employeeLastName: '',
      branchCode: '',
      status: InvestmentStatus.active,
      isAllocated: false,
      marketType: MarketType.primary,
      signedDate:
          DateTime.tryParse(data['created_at']?.toString() ?? '') ??
          DateTime.now(),
      entryDate: null,
      exitDate: null,
      proposalId: '',
      productType: ProductType.shares,
      productName: data['typ_produktu']?.toString() ?? '',
      creditorCompany: '',
      companyId: '',
      issueDate: null,
      redemptionDate: null,
      sharesCount: (data['ilosc_udzialow']?.toDouble() ?? 0.0).toInt(),
      investmentAmount: data['kwota_inwestycji']?.toDouble() ?? 0.0,
      paidAmount: data['kwota_inwestycji']?.toDouble() ?? 0.0,
      realizedCapital: 0.0,
      realizedInterest: 0.0,
      transferToOtherProduct: 0.0,
      remainingCapital: data['kwota_inwestycji']?.toDouble() ?? 0.0,
      remainingInterest: 0.0,
      plannedTax: 0.0,
      realizedTax: 0.0,
      currency: 'PLN',
      exchangeRate: null,
      createdAt:
          DateTime.tryParse(data['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.now(),
      additionalInfo: {
        'source': 'shares_collection',
        'ilosc_udzialow': data['ilosc_udzialow']?.toString() ?? '0',
      },
    );
  }

  // === POMOCNICZE METODY OBLICZENIOWE ===

  /// Oblicza roczny zwrot składany (CAGR)
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
              return daysDiff / 365.25; // uwzględnia lata przestępne
            })
            .reduce((a, b) => a + b) /
        investments.length;

    if (averageYears <= 0) return 0.0;

    // CAGR = (Wartość końcowa / Wartość początkowa)^(1/lata) - 1
    return (math.pow(totalCurrent / totalInvested, 1 / averageYears) - 1) * 100;
  }

  /// Oblicza wydajność według typu produktu
  Map<String, double> _calculateProductPerformanceMap(
    List<Investment> investments,
  ) {
    final productGroups = <String, List<Investment>>{};

    for (final investment in investments) {
      final productType = investment.productType.name;
      productGroups.putIfAbsent(productType, () => []).add(investment);
    }

    return productGroups.map((type, invs) {
      final avgReturn = invs.isEmpty
          ? 0.0
          : invs.map((i) => i.profitLossPercentage).reduce((a, b) => a + b) /
                invs.length;
      return MapEntry(type, avgReturn);
    });
  }

  /// Pobiera top wykonawców
  List<Investment> _getTopPerformers(List<Investment> investments) {
    final sorted = List<Investment>.from(
      investments,
    )..sort((a, b) => b.profitLossPercentage.compareTo(a.profitLossPercentage));
    return sorted.take(10).toList();
  }
}

// Modele danych dla zaawansowanych metryk

class AdvancedDashboardMetrics {
  final PortfolioMetrics portfolioMetrics;
  final RiskMetrics riskMetrics;
  final PerformanceMetrics performanceMetrics;
  final ClientAnalytics clientAnalytics;
  final ProductAnalytics productAnalytics;
  final EmployeeAnalytics employeeAnalytics;
  final GeographicAnalytics geographicAnalytics;
  final TimeSeriesAnalytics timeSeriesAnalytics;
  final PredictionMetrics predictionMetrics;
  final BenchmarkMetrics benchmarkMetrics;

  AdvancedDashboardMetrics({
    required this.portfolioMetrics,
    required this.riskMetrics,
    required this.performanceMetrics,
    required this.clientAnalytics,
    required this.productAnalytics,
    required this.employeeAnalytics,
    required this.geographicAnalytics,
    required this.timeSeriesAnalytics,
    required this.predictionMetrics,
    required this.benchmarkMetrics,
  });
}

class PortfolioMetrics {
  final double totalValue;
  final double totalInvested;
  final double totalRealized;
  final double totalRemaining;
  final double totalInterest;
  final double totalProfit;
  final double roi;
  final int activeInvestmentsCount;
  final int totalInvestmentsCount;
  final double averageInvestmentSize;
  final double medianInvestmentSize;
  final double portfolioGrowthRate;

  PortfolioMetrics({
    required this.totalValue,
    required this.totalInvested,
    required this.totalRealized,
    required this.totalRemaining,
    required this.totalInterest,
    required this.totalProfit,
    required this.roi,
    required this.activeInvestmentsCount,
    required this.totalInvestmentsCount,
    required this.averageInvestmentSize,
    required this.medianInvestmentSize,
    required this.portfolioGrowthRate,
  });
}

class RiskMetrics {
  final double volatility;
  final double sharpeRatio;
  final double maxDrawdown;
  final double valueAtRisk;
  final double concentrationRisk;
  final double diversificationRatio;
  final double liquidityRisk;
  final double creditRisk;
  final double beta;

  RiskMetrics({
    required this.volatility,
    required this.sharpeRatio,
    required this.maxDrawdown,
    required this.valueAtRisk,
    required this.concentrationRisk,
    required this.diversificationRatio,
    required this.liquidityRisk,
    required this.creditRisk,
    required this.beta,
  });
}

class PerformanceMetrics {
  final double averageReturn;
  final Investment? bestPerformingInvestment;
  final Investment? worstPerformingInvestment;
  final double successRate;
  final double alpha;
  final double beta;
  final double informationRatio;
  final double trackingError;

  // Dodatkowe metryki wydajności
  final double totalROI;
  final double annualizedReturn;
  final double sharpeRatio;
  final double maxDrawdown;
  final Map<String, double> productPerformance;
  final List<Investment> topPerformers;

  PerformanceMetrics({
    required this.averageReturn,
    this.bestPerformingInvestment,
    this.worstPerformingInvestment,
    required this.successRate,
    required this.alpha,
    required this.beta,
    required this.informationRatio,
    required this.trackingError,
    required this.totalROI,
    required this.annualizedReturn,
    required this.sharpeRatio,
    required this.maxDrawdown,
    required this.productPerformance,
    required this.topPerformers,
  });
}

class ClientAnalytics {
  final int totalClients;
  final List<TopClient> topClients;
  final double clientConcentration;
  final double averageClientValue;
  final double clientRetention;
  final int newClientsThisMonth;

  ClientAnalytics({
    required this.totalClients,
    required this.topClients,
    required this.clientConcentration,
    required this.averageClientValue,
    required this.clientRetention,
    required this.newClientsThisMonth,
  });
}

class TopClient {
  final String name;
  final double value;

  TopClient({required this.name, required this.value});
}

class ProductAnalytics {
  final Map<ProductType, ProductPerformance> productPerformance;
  final ProductType? bestPerformingProduct;
  final ProductType? worstPerformingProduct;
  final double productDiversification;

  ProductAnalytics({
    required this.productPerformance,
    this.bestPerformingProduct,
    this.worstPerformingProduct,
    required this.productDiversification,
  });
}

class ProductPerformance {
  final double totalValue;
  final double averageReturn;
  final int count;
  final double riskLevel;

  ProductPerformance({
    required this.totalValue,
    required this.averageReturn,
    required this.count,
    required this.riskLevel,
  });
}

class EmployeeAnalytics {
  final Map<String, EmployeePerformance> employeePerformance;
  final List<TopEmployee> topPerformers;
  final double averageEmployeeVolume;

  EmployeeAnalytics({
    required this.employeePerformance,
    required this.topPerformers,
    required this.averageEmployeeVolume,
  });
}

class EmployeePerformance {
  final double totalVolume;
  final double averageReturn;
  final int transactionCount;
  final int clientCount;

  EmployeePerformance({
    required this.totalVolume,
    required this.averageReturn,
    required this.transactionCount,
    required this.clientCount,
  });
}

class TopEmployee {
  final String name;
  final EmployeePerformance performance;

  TopEmployee({required this.name, required this.performance});
}

class GeographicAnalytics {
  final Map<String, BranchPerformance> branchPerformance;
  final List<MapEntry<String, BranchPerformance>> topBranches;
  final double geographicDiversification;

  GeographicAnalytics({
    required this.branchPerformance,
    required this.topBranches,
    required this.geographicDiversification,
  });
}

class BranchPerformance {
  final double totalVolume;
  final double averageReturn;
  final int transactionCount;
  final int clientCount;

  BranchPerformance({
    required this.totalVolume,
    required this.averageReturn,
    required this.transactionCount,
    required this.clientCount,
  });
}

class TimeSeriesAnalytics {
  final List<MonthlyData> monthlyData;
  final double growthTrend;
  final Map<int, double> seasonality;
  final double momentum;

  TimeSeriesAnalytics({
    required this.monthlyData,
    required this.growthTrend,
    required this.seasonality,
    required this.momentum,
  });
}

class MonthlyData {
  final String month;
  final double totalInvestments;
  final double totalVolume;
  final double averageReturn;
  final int transactionCount;

  MonthlyData({
    required this.month,
    required this.totalInvestments,
    required this.totalVolume,
    required this.averageReturn,
    required this.transactionCount,
  });

  MonthlyData copyWith({
    String? month,
    double? totalInvestments,
    double? totalVolume,
    double? averageReturn,
    int? transactionCount,
  }) {
    return MonthlyData(
      month: month ?? this.month,
      totalInvestments: totalInvestments ?? this.totalInvestments,
      totalVolume: totalVolume ?? this.totalVolume,
      averageReturn: averageReturn ?? this.averageReturn,
      transactionCount: transactionCount ?? this.transactionCount,
    );
  }
}

class PredictionMetrics {
  final double projectedReturns;
  final double expectedMaturityValue;
  final double riskAdjustedReturns;
  final String portfolioOptimization;

  PredictionMetrics({
    required this.projectedReturns,
    required this.expectedMaturityValue,
    required this.riskAdjustedReturns,
    required this.portfolioOptimization,
  });
}

class BenchmarkMetrics {
  final double vsMarketReturn;
  final double relativePerfomance;
  final int outperformingInvestments;
  final double benchmarkCorrelation;

  BenchmarkMetrics({
    required this.vsMarketReturn,
    required this.relativePerfomance,
    required this.outperformingInvestments,
    required this.benchmarkCorrelation,
  });
}

extension ListExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (count >= length) return this;
    return sublist(length - count);
  }
}
