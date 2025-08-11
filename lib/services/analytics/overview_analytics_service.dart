import 'dart:math' as math;
import '../../models/analytics/overview_analytics_models.dart';
import '../base_service.dart';
import '../../models/investment.dart';
import '../../models/client.dart';
import '../firebase_functions_analytics_service.dart';

/// Serwis analityki przeglądu
class OverviewAnalyticsService extends BaseService {
  final FirebaseFunctionsAnalyticsService _functionsService =
      FirebaseFunctionsAnalyticsService();

  /// Pobiera dane analityki przeglądu
  Future<OverviewAnalytics> getOverviewAnalytics({
    int timeRangeMonths = 12,
  }) async {
    final cacheKey = 'overview_analytics_${timeRangeMonths}';

    return getCachedData(
      cacheKey,
      () => _calculateOverviewAnalytics(timeRangeMonths),
    );
  }

  /// Oblicza kompletną analitykę przeglądu
  Future<OverviewAnalytics> _calculateOverviewAnalytics(
    int timeRangeMonths,
  ) async {
    try {
      print('🔍 [OverviewAnalytics] Rozpoczynam obliczenia...');

      // Pobierz surowe dane
      final [investments, clients] = await Future.wait([
        _getAllInvestments(timeRangeMonths),
        _getAllClients(),
      ]);

      print(
        '🔍 [OverviewAnalytics] Pobrano ${investments.length} inwestycji i ${clients.length} klientów',
      );

      // Oblicz poszczególne metryki
      final portfolioMetrics = _calculatePortfolioMetrics(investments);
      final productBreakdown = _calculateProductBreakdown(investments);
      final monthlyPerformance = _calculateMonthlyPerformance(investments);
      final clientMetrics = _calculateClientMetrics(investments, clients);
      final riskMetrics = _calculateRiskMetrics(investments);

      return OverviewAnalytics(
        portfolioMetrics: portfolioMetrics,
        productBreakdown: productBreakdown,
        monthlyPerformance: monthlyPerformance,
        clientMetrics: clientMetrics,
        riskMetrics: riskMetrics,
        calculatedAt: DateTime.now(),
      );
    } catch (e) {
      logError('_calculateOverviewAnalytics', e);
      throw Exception('Błąd podczas obliczania analityki przeglądu: $e');
    }
  }

  /// Pobiera wszystkie inwestycje w określonym przedziale czasowym
  Future<List<Investment>> _getAllInvestments(int timeRangeMonths) async {
    try {
      final query = firestore.collection('investments');

      // Dodaj filtr czasowy jeśli nie "cały okres"
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

  /// Pobiera wszystkich klientów
  Future<List<Client>> _getAllClients() async {
    try {
      final snapshot = await firestore.collection('clients').get();
      return snapshot.docs
          .map((doc) => _convertClientFromDocument(doc))
          .toList();
    } catch (e) {
      logError('_getAllClients', e);
      throw Exception('Błąd pobierania klientów: $e');
    }
  }

  /// Oblicza metryki portfela
  PortfolioMetricsData _calculatePortfolioMetrics(
    List<Investment> investments,
  ) {
    if (investments.isEmpty) {
      return PortfolioMetricsData(
        totalValue: 0,
        totalInvested: 0,
        totalProfit: 0,
        totalROI: 0,
        growthPercentage: 0,
        activeInvestmentsCount: 0,
        totalInvestmentsCount: 0,
        averageReturn: 0,
        monthlyGrowth: 0,
      );
    }

    double totalValue = 0;
    double totalInvested = 0;
    double totalRealized = 0;
    double totalInterest = 0;
    int activeCount = 0;

    for (final investment in investments) {
      totalValue += investment.totalValue;
      totalInvested += investment.investmentAmount;
      totalRealized += investment.realizedCapital;
      totalInterest +=
          investment.realizedInterest + investment.remainingInterest;

      if (investment.status == InvestmentStatus.active) {
        activeCount++;
      }
    }

    final totalProfit = totalRealized + totalInterest - totalInvested;
    final totalROI = totalInvested > 0
        ? (totalProfit / totalInvested) * 100
        : 0.0;

    // Oblicz wzrost procentowy (porównaj z zeszłym okresem)
    final growthPercentage = _calculateGrowthPercentage(investments);

    // Oblicz średni zwrot
    final returns = investments.map((i) => i.profitLossPercentage).toList();
    final averageReturn = returns.isNotEmpty
        ? returns.reduce((a, b) => a + b) / returns.length
        : 0.0;

    // Oblicz miesięczny wzrost
    final monthlyGrowth = _calculateMonthlyGrowth(investments);

    return PortfolioMetricsData(
      totalValue: totalValue,
      totalInvested: totalInvested,
      totalProfit: totalProfit,
      totalROI: totalROI,
      growthPercentage: growthPercentage,
      activeInvestmentsCount: activeCount,
      totalInvestmentsCount: investments.length,
      averageReturn: averageReturn,
      monthlyGrowth: monthlyGrowth,
    );
  }

  /// Oblicza rozkład produktów
  List<ProductBreakdownItem> _calculateProductBreakdown(
    List<Investment> investments,
  ) {
    final productGroups = <String, List<Investment>>{};
    double totalValue = 0;

    // Grupuj według typu produktu
    for (final investment in investments) {
      final productType = investment.productType.name;
      productGroups.putIfAbsent(productType, () => []).add(investment);
      totalValue += investment.totalValue;
    }

    // Oblicz statystyki dla każdego produktu
    final breakdown = <ProductBreakdownItem>[];
    for (final entry in productGroups.entries) {
      final productType = entry.key;
      final investments = entry.value;

      final productValue = investments.fold<double>(
        0,
        (sum, inv) => sum + inv.totalValue,
      );
      final percentage = totalValue > 0 ? (productValue / totalValue) * 100 : 0;
      final averageReturn = investments.isNotEmpty
          ? investments.fold<double>(
                  0,
                  (sum, inv) => sum + inv.profitLossPercentage,
                ) /
                investments.length
          : 0;

      breakdown.add(
        ProductBreakdownItem(
          productType: productType,
          productName: _getProductTypeName(productType),
          value: productValue,
          percentage: percentage,
          count: investments.length,
          averageReturn: averageReturn,
        ),
      );
    }

    // Sortuj według wartości malejąco
    breakdown.sort((a, b) => b.value.compareTo(a.value));
    return breakdown;
  }

  /// Oblicza wydajność miesięczną
  List<MonthlyPerformanceItem> _calculateMonthlyPerformance(
    List<Investment> investments,
  ) {
    final monthlyData = <String, List<Investment>>{};

    // Grupuj według miesięcy
    for (final investment in investments) {
      final monthKey =
          '${investment.signedDate.year}-${investment.signedDate.month.toString().padLeft(2, '0')}';
      monthlyData.putIfAbsent(monthKey, () => []).add(investment);
    }

    // Oblicz statystyki miesięczne
    final performance = <MonthlyPerformanceItem>[];
    final sortedMonths = monthlyData.keys.toList()..sort();

    for (int i = 0; i < sortedMonths.length; i++) {
      final month = sortedMonths[i];
      final monthInvestments = monthlyData[month]!;

      final totalValue = monthInvestments.fold<double>(
        0,
        (sum, inv) => sum + inv.totalValue,
      );
      final totalVolume = monthInvestments.fold<double>(
        0,
        (sum, inv) => sum + inv.investmentAmount,
      );
      final averageReturn = monthInvestments.isNotEmpty
          ? monthInvestments.fold<double>(
                  0,
                  (sum, inv) => sum + inv.profitLossPercentage,
                ) /
                monthInvestments.length
          : 0;

      // Oblicz wzrost w stosunku do poprzedniego miesiąca
      double growthRate = 0;
      if (i > 0) {
        final prevMonth = sortedMonths[i - 1];
        final prevInvestments = monthlyData[prevMonth]!;
        final prevTotalValue = prevInvestments.fold<double>(
          0,
          (sum, inv) => sum + inv.totalValue,
        );

        if (prevTotalValue > 0) {
          growthRate = ((totalValue - prevTotalValue) / prevTotalValue) * 100;
        }
      }

      performance.add(
        MonthlyPerformanceItem(
          month: month,
          totalValue: totalValue,
          totalVolume: totalVolume,
          averageReturn: averageReturn,
          transactionCount: monthInvestments.length,
          growthRate: growthRate,
        ),
      );
    }

    return performance;
  }

  /// Oblicza metryki klientów
  ClientMetricsData _calculateClientMetrics(
    List<Investment> investments,
    List<Client> clients,
  ) {
    // Stwórz mapę klientów z inwestycjami
    final clientInvestmentMap = <String, List<Investment>>{};
    for (final investment in investments) {
      clientInvestmentMap
          .putIfAbsent(investment.clientName, () => [])
          .add(investment);
    }

    // Oblicz top klientów
    final topClients = <TopClientItem>[];
    for (final entry in clientInvestmentMap.entries) {
      final clientName = entry.key;
      final clientInvestments = entry.value;
      final totalValue = clientInvestments.fold<double>(
        0,
        (sum, inv) => sum + inv.totalValue,
      );

      topClients.add(
        TopClientItem(
          name: clientName,
          value: totalValue,
          investmentCount: clientInvestments.length,
        ),
      );
    }

    // Sortuj i weź top 10
    topClients.sort((a, b) => b.value.compareTo(a.value));
    final top10Clients = topClients.take(10).toList();

    // Oblicz nowych klientów w tym miesiącu
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    final newClientsThisMonth = investments
        .where((inv) => inv.signedDate.isAfter(thisMonth))
        .map((inv) => inv.clientName)
        .toSet()
        .length;

    // Oblicz retencję klientów (uproszczone)
    final clientRetentionRate = _calculateClientRetention(investments);

    // Oblicz średnią wartość klienta
    final averageClientValue = clientInvestmentMap.isNotEmpty
        ? topClients.fold<double>(0, (sum, client) => sum + client.value) /
              topClients.length
        : 0;

    return ClientMetricsData(
      totalClients: clientInvestmentMap.length,
      activeClients:
          clientInvestmentMap.length, // Zakładamy, że wszyscy są aktywni
      newClientsThisMonth: newClientsThisMonth,
      clientRetentionRate: clientRetentionRate,
      averageClientValue: averageClientValue,
      topClients: top10Clients,
    );
  }

  /// Oblicza metryki ryzyka
  RiskMetricsData _calculateRiskMetrics(List<Investment> investments) {
    if (investments.isEmpty) {
      return RiskMetricsData(
        volatility: 0,
        sharpeRatio: 0,
        maxDrawdown: 0,
        valueAtRisk: 0,
        diversificationIndex: 0,
        riskLevel: 'low',
        concentrationRisk: 0,
      );
    }

    final returns = investments.map((i) => i.profitLossPercentage).toList();

    final volatility = _calculateVolatility(returns);
    final sharpeRatio = _calculateSharpeRatio(returns);
    final maxDrawdown = _calculateMaxDrawdown(investments);
    final valueAtRisk = _calculateVaR(returns);
    final diversificationIndex = _calculateDiversificationIndex(investments);
    final concentrationRisk = _calculateConcentrationRisk(investments);

    // Określ poziom ryzyka
    String riskLevel = 'medium';
    if (volatility < 5)
      riskLevel = 'low';
    else if (volatility > 15)
      riskLevel = 'high';

    return RiskMetricsData(
      volatility: volatility,
      sharpeRatio: sharpeRatio,
      maxDrawdown: maxDrawdown,
      valueAtRisk: valueAtRisk,
      diversificationIndex: diversificationIndex,
      riskLevel: riskLevel,
      concentrationRisk: concentrationRisk,
    );
  }

  // Metody pomocnicze

  double _calculateGrowthPercentage(List<Investment> investments) {
    // Uproszczona implementacja - porównanie z początkiem roku
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);

    final recentInvestments = investments
        .where((inv) => inv.signedDate.isAfter(yearStart))
        .toList();

    if (recentInvestments.length < 2) return 0;

    final totalCurrent = recentInvestments.fold<double>(
      0,
      (sum, inv) => sum + inv.totalValue,
    );
    final totalInvested = recentInvestments.fold<double>(
      0,
      (sum, inv) => sum + inv.investmentAmount,
    );

    return totalInvested > 0
        ? ((totalCurrent - totalInvested) / totalInvested) * 100
        : 0;
  }

  double _calculateMonthlyGrowth(List<Investment> investments) {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final thisMonth = DateTime(now.year, now.month, 1);

    final lastMonthInvestments = investments
        .where(
          (inv) =>
              inv.signedDate.isAfter(lastMonth) &&
              inv.signedDate.isBefore(thisMonth),
        )
        .toList();

    final thisMonthInvestments = investments
        .where((inv) => inv.signedDate.isAfter(thisMonth))
        .toList();

    if (lastMonthInvestments.isEmpty) return 0;

    final lastMonthValue = lastMonthInvestments.fold<double>(
      0,
      (sum, inv) => sum + inv.totalValue,
    );
    final thisMonthValue = thisMonthInvestments.fold<double>(
      0,
      (sum, inv) => sum + inv.totalValue,
    );

    return lastMonthValue > 0
        ? ((thisMonthValue - lastMonthValue) / lastMonthValue) * 100
        : 0;
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

  double _calculateClientRetention(List<Investment> investments) {
    // Uproszczona kalkulacja retencji
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

  double _calculateDiversificationIndex(List<Investment> investments) {
    final productTypes = investments.map((inv) => inv.productType).toSet();
    return investments.isNotEmpty
        ? (productTypes.length / investments.length) * 100
        : 0;
  }

  double _calculateConcentrationRisk(List<Investment> investments) {
    final productValues = <String, double>{};
    double totalValue = 0;

    for (final investment in investments) {
      final productType = investment.productType.name;
      productValues[productType] =
          (productValues[productType] ?? 0) + investment.totalValue;
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

  // Metody konwersji dokumentów

  Investment _convertInvestmentFromDocument(doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Investment.fromFirestore(doc.id, data);
  }

  Client _convertClientFromDocument(doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Client.fromFirestore(doc.id, data);
  }
}
