import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../services/investment_service.dart';
import '../services/client_service.dart';
import '../models/product.dart';
import '../utils/currency_formatter.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final InvestmentService _investmentService = InvestmentService();
  final ClientService _clientService = ClientService();

  Map<String, dynamic>? _investmentSummary;
  Map<String, dynamic>? _clientStats;
  Map<String, dynamic>? _performanceAnalytics;
  Map<String, dynamic>? _timeSeriesData;
  Map<String, dynamic>? _geographicAnalytics;
  Map<String, dynamic>? _employeePerformance;
  Map<String, dynamic>? _riskAnalytics;
  Map<String, dynamic>? _profitabilityAnalytics;
  List<Map<String, dynamic>> _topProducts = [];
  bool _isLoading = true;
  int _selectedTimeRange = 12; // ostatnie 12 miesięcy
  String _selectedAnalyticsTab = 'overview';

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      final summary = await _investmentService.getInvestmentSummary();
      final clientStats = await _clientService.getClientStats();
      final topProducts = await _getTopProducts();
      final performanceAnalytics = await _getPerformanceAnalytics();
      final timeSeriesData = await _getTimeSeriesData();
      final geographicAnalytics = await _getGeographicAnalytics();
      final employeePerformance = await _getEmployeePerformance();
      final riskAnalytics = await _getRiskAnalytics();
      final profitabilityAnalytics = await _getProfitabilityAnalytics();

      setState(() {
        _investmentSummary = summary;
        _clientStats = clientStats;
        _topProducts = topProducts;
        _performanceAnalytics = performanceAnalytics;
        _timeSeriesData = timeSeriesData;
        _geographicAnalytics = geographicAnalytics;
        _employeePerformance = employeePerformance;
        _riskAnalytics = riskAnalytics;
        _profitabilityAnalytics = profitabilityAnalytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd podczas ładowania analityki: $e')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _getTopProducts() async {
    final summary = await _investmentService.getInvestmentSummary();
    final amountByProduct =
        summary['amountByProduct'] as Map<ProductType, double>? ?? {};

    final topProducts = amountByProduct.entries
        .map((e) => {'name': _getProductTypeName(e.key), 'amount': e.value})
        .toList();

    topProducts.sort(
      (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
    );
    return topProducts.take(4).toList();
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

  // Zaawansowana analiza wydajności inwestycji
  Future<Map<String, dynamic>> _getPerformanceAnalytics() async {
    final summary = await _investmentService.getInvestmentSummary();
    final investments = summary['investments'] as List<dynamic>? ?? [];

    double totalROI = 0;
    double totalRealizedProfit = 0;
    double totalUnrealizedGains = 0;
    int profitableInvestments = 0;
    int lossInvestments = 0;
    Map<String, double> performanceByProduct = {};
    Map<String, double> performanceByMarket = {};

    for (var investment in investments) {
      final profitLoss = investment['profitLoss'] ?? 0.0;
      final profitLossPercentage = investment['profitLossPercentage'] ?? 0.0;
      final productType = investment['productType'] ?? '';
      final marketType = investment['marketType'] ?? '';

      totalROI += profitLossPercentage;
      totalRealizedProfit += investment['realizedCapital'] ?? 0.0;
      totalUnrealizedGains += investment['remainingCapital'] ?? 0.0;

      if (profitLoss > 0) profitableInvestments++;
      if (profitLoss < 0) lossInvestments++;

      performanceByProduct[productType] =
          (performanceByProduct[productType] ?? 0) + profitLossPercentage;
      performanceByMarket[marketType] =
          (performanceByMarket[marketType] ?? 0) + profitLossPercentage;
    }

    return {
      'averageROI': investments.isNotEmpty ? totalROI / investments.length : 0,
      'totalRealizedProfit': totalRealizedProfit,
      'totalUnrealizedGains': totalUnrealizedGains,
      'profitableInvestments': profitableInvestments,
      'lossInvestments': lossInvestments,
      'successRate': investments.isNotEmpty
          ? (profitableInvestments / investments.length * 100)
          : 0,
      'performanceByProduct': performanceByProduct,
      'performanceByMarket': performanceByMarket,
    };
  }

  // Analiza czasowa (trendy w czasie)
  Future<Map<String, dynamic>> _getTimeSeriesData() async {
    final summary = await _investmentService.getInvestmentSummary();
    final investments = summary['investments'] as List<dynamic>? ?? [];

    Map<String, double> monthlyInvestments = {};
    Map<String, double> monthlyReturns = {};
    Map<String, int> monthlyCount = {};

    for (var investment in investments) {
      final signedDate = investment['signedDate'] as DateTime?;
      if (signedDate != null) {
        final monthKey =
            '${signedDate.year}-${signedDate.month.toString().padLeft(2, '0')}';
        monthlyInvestments[monthKey] =
            (monthlyInvestments[monthKey] ?? 0) +
            (investment['investmentAmount'] ?? 0.0);
        monthlyReturns[monthKey] =
            (monthlyReturns[monthKey] ?? 0) + (investment['profitLoss'] ?? 0.0);
        monthlyCount[monthKey] = (monthlyCount[monthKey] ?? 0) + 1;
      }
    }

    return {
      'monthlyInvestments': monthlyInvestments,
      'monthlyReturns': monthlyReturns,
      'monthlyCount': monthlyCount,
      'trend': _calculateTrend(monthlyInvestments.values.toList()),
    };
  }

  // Analiza geograficzna (według oddziałów)
  Future<Map<String, dynamic>> _getGeographicAnalytics() async {
    final summary = await _investmentService.getInvestmentSummary();
    final investments = summary['investments'] as List<dynamic>? ?? [];

    Map<String, double> branchPerformance = {};
    Map<String, int> branchCount = {};
    Map<String, double> branchVolume = {};

    for (var investment in investments) {
      final branchCode = investment['branchCode'] ?? 'Nieznany';
      final amount = investment['investmentAmount'] ?? 0.0;
      final profit = investment['profitLoss'] ?? 0.0;

      branchPerformance[branchCode] =
          (branchPerformance[branchCode] ?? 0) + profit;
      branchCount[branchCode] = (branchCount[branchCode] ?? 0) + 1;
      branchVolume[branchCode] = (branchVolume[branchCode] ?? 0) + amount;
    }

    return {
      'branchPerformance': branchPerformance,
      'branchCount': branchCount,
      'branchVolume': branchVolume,
      'topPerformingBranch': _getTopBranch(branchPerformance),
      'highestVolumeBranch': _getTopBranch(branchVolume),
    };
  }

  // Analiza wydajności pracowników
  Future<Map<String, dynamic>> _getEmployeePerformance() async {
    final summary = await _investmentService.getInvestmentSummary();
    final investments = summary['investments'] as List<dynamic>? ?? [];

    Map<String, double> employeeVolume = {};
    Map<String, int> employeeCount = {};
    Map<String, double> employeeProfit = {};
    Map<String, String> employeeNames = {};

    for (var investment in investments) {
      final employeeId = investment['employeeId'] ?? '';
      final employeeName =
          '${investment['employeeFirstName'] ?? ''} ${investment['employeeLastName'] ?? ''}'
              .trim();
      final amount = investment['investmentAmount'] ?? 0.0;
      final profit = investment['profitLoss'] ?? 0.0;

      if (employeeId.isNotEmpty) {
        employeeVolume[employeeId] = (employeeVolume[employeeId] ?? 0) + amount;
        employeeCount[employeeId] = (employeeCount[employeeId] ?? 0) + 1;
        employeeProfit[employeeId] = (employeeProfit[employeeId] ?? 0) + profit;
        employeeNames[employeeId] = employeeName;
      }
    }

    // Oblicz średnie dla każdego pracownika
    Map<String, double> employeeAverageInvestment = {};
    for (var employeeId in employeeVolume.keys) {
      employeeAverageInvestment[employeeId] =
          employeeVolume[employeeId]! / (employeeCount[employeeId] ?? 1);
    }

    return {
      'employeeVolume': employeeVolume,
      'employeeCount': employeeCount,
      'employeeProfit': employeeProfit,
      'employeeNames': employeeNames,
      'employeeAverageInvestment': employeeAverageInvestment,
      'topEmployeeByVolume': _getTopEmployee(employeeVolume, employeeNames),
      'topEmployeeByCount': _getTopEmployee(
        employeeCount.map((k, v) => MapEntry(k, v.toDouble())),
        employeeNames,
      ),
    };
  }

  // Analiza ryzyka
  Future<Map<String, dynamic>> _getRiskAnalytics() async {
    final summary = await _investmentService.getInvestmentSummary();
    final investments = summary['investments'] as List<dynamic>? ?? [];

    Map<String, int> statusDistribution = {};
    Map<String, double> riskByProduct = {};
    List<double> investmentAmounts = [];
    double volatility = 0;
    int earlyRedemptions = 0;

    for (var investment in investments) {
      final status = investment['status'] ?? '';
      final productType = investment['productType'] ?? '';
      final amount = investment['investmentAmount'] ?? 0.0;
      final profitLossPercentage = investment['profitLossPercentage'] ?? 0.0;

      statusDistribution[status] = (statusDistribution[status] ?? 0) + 1;
      investmentAmounts.add(amount);

      if (status.contains('earlyRedemption')) {
        earlyRedemptions++;
      }

      // Oblicz ryzyko produktu na podstawie odchylenia zwrotów
      if (!riskByProduct.containsKey(productType)) {
        riskByProduct[productType] = 0;
      }
      riskByProduct[productType] =
          riskByProduct[productType]! + profitLossPercentage.abs();
    }

    // Oblicz zmienność portfela
    if (investmentAmounts.isNotEmpty) {
      final mean =
          investmentAmounts.reduce((a, b) => a + b) / investmentAmounts.length;
      final variance =
          investmentAmounts
              .map((x) => (x - mean) * (x - mean))
              .reduce((a, b) => a + b) /
          investmentAmounts.length;
      volatility = variance > 0 ? math.sqrt(variance) : 0;
    }

    return {
      'statusDistribution': statusDistribution,
      'portfolioVolatility': volatility,
      'earlyRedemptionRate': investments.isNotEmpty
          ? (earlyRedemptions / investments.length * 100)
          : 0,
      'riskByProduct': riskByProduct,
      'concentrationRisk': _calculateConcentrationRisk(investments),
    };
  }

  // Analiza zyskowności
  Future<Map<String, dynamic>> _getProfitabilityAnalytics() async {
    final summary = await _investmentService.getInvestmentSummary();
    final investments = summary['investments'] as List<dynamic>? ?? [];

    double totalInvested = 0;
    double totalRealized = 0;
    double totalInterest = 0;
    double totalTax = 0;
    Map<String, double> profitByProduct = {};
    Map<String, double> marginByProduct = {};

    for (var investment in investments) {
      final invested = investment['investmentAmount'] ?? 0.0;
      final realized = investment['realizedCapital'] ?? 0.0;
      final interest = investment['realizedInterest'] ?? 0.0;
      final tax = investment['realizedTax'] ?? 0.0;
      final productType = investment['productType'] ?? '';

      totalInvested += invested;
      totalRealized += realized;
      totalInterest += interest;
      totalTax += tax;

      final profit = realized + interest - invested - tax;
      profitByProduct[productType] =
          (profitByProduct[productType] ?? 0) + profit;

      // Oblicz marżę (profit margin)
      if (invested > 0) {
        final margin = (profit / invested) * 100;
        marginByProduct[productType] =
            (marginByProduct[productType] ?? 0) + margin;
      }
    }

    return {
      'totalInvested': totalInvested,
      'totalRealized': totalRealized,
      'totalInterest': totalInterest,
      'totalTax': totalTax,
      'netProfit': totalRealized + totalInterest - totalInvested - totalTax,
      'grossReturn': totalInvested > 0
          ? ((totalRealized + totalInterest) / totalInvested * 100)
          : 0,
      'netReturn': totalInvested > 0
          ? ((totalRealized + totalInterest - totalTax) / totalInvested * 100)
          : 0,
      'profitByProduct': profitByProduct,
      'marginByProduct': marginByProduct,
    };
  }

  // Pomocnicze metody analityczne
  double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0;
    double trend = 0;
    for (int i = 1; i < values.length; i++) {
      trend += values[i] - values[i - 1];
    }
    return trend / (values.length - 1);
  }

  String _getTopBranch(Map<String, double> branchData) {
    if (branchData.isEmpty) return 'Brak danych';
    var maxEntry = branchData.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    return maxEntry.key;
  }

  Map<String, String> _getTopEmployee(
    Map<String, double> employeeData,
    Map<String, String> employeeNames,
  ) {
    if (employeeData.isEmpty)
      return {'id': '', 'name': 'Brak danych', 'value': '0'};
    var maxEntry = employeeData.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    return {
      'id': maxEntry.key,
      'name': employeeNames[maxEntry.key] ?? 'Nieznany',
      'value': maxEntry.value.toStringAsFixed(2),
    };
  }

  double _calculateConcentrationRisk(List<dynamic> investments) {
    Map<String, double> productConcentration = {};
    double totalValue = 0;

    for (var investment in investments) {
      final productType = investment['productType'] ?? '';
      final amount = investment['investmentAmount'] ?? 0.0;
      productConcentration[productType] =
          (productConcentration[productType] ?? 0) + amount;
      totalValue += amount;
    }

    if (totalValue == 0) return 0;

    // Oblicz indeks koncentracji Herfindahla-Hirschmana
    double hhi = 0;
    for (var concentration in productConcentration.values) {
      double share = concentration / totalValue;
      hhi += share * share;
    }

    return hhi * 10000; // Skalowanie do standardowej skali HHI
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eksport raportu - funkcja w przygotowaniu'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header z zakładkami
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.gradientDecoration,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zaawansowana Analityka',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(color: AppTheme.textOnPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kompleksowa analiza portfela inwestycyjnego',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppTheme.textOnPrimary.withOpacity(
                                    0.8,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _buildTimeRangeSelector(),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _exportReport,
                          icon: const Icon(Icons.download),
                          label: const Text('Eksport'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.surfaceCard,
                            foregroundColor: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTabBar(),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<int>(
        value: _selectedTimeRange,
        underline: const SizedBox(),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppTheme.primaryColor),
        dropdownColor: AppTheme.surfaceCard,
        items: const [
          DropdownMenuItem(value: 3, child: Text('3 miesiące')),
          DropdownMenuItem(value: 6, child: Text('6 miesięcy')),
          DropdownMenuItem(value: 12, child: Text('12 miesięcy')),
          DropdownMenuItem(value: 24, child: Text('24 miesiące')),
          DropdownMenuItem(value: -1, child: Text('Cały okres')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedTimeRange = value!;
          });
          _loadAnalyticsData();
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabButton('overview', 'Przegląd', Icons.dashboard),
          _buildTabButton('performance', 'Wydajność', Icons.trending_up),
          _buildTabButton('risk', 'Ryzyko', Icons.security),
          _buildTabButton('employees', 'Pracownicy', Icons.people),
          _buildTabButton('geographic', 'Geografia', Icons.map),
          _buildTabButton('trends', 'Trendy', Icons.timeline),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabId, String label, IconData icon) {
    final isSelected = _selectedAnalyticsTab == tabId;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedAnalyticsTab = tabId;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedAnalyticsTab) {
      case 'overview':
        return _buildOverviewTab();
      case 'performance':
        return _buildPerformanceTab();
      case 'risk':
        return _buildRiskTab();
      case 'employees':
        return _buildEmployeesTab();
      case 'geographic':
        return _buildGeographicTab();
      case 'trends':
        return _buildTrendsTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            change,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.successColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChart() {
    if (_investmentSummary == null) return const SizedBox();

    final byStatus = _investmentSummary!['byStatus'] as Map? ?? {};

    if (byStatus.isEmpty) {
      return const Center(child: Text('Brak danych do wyświetlenia'));
    }

    return PieChart(
      PieChartData(
        sections: byStatus.entries.map((entry) {
          final color = _getStatusColor(entry.key.toString());
          return PieChartSectionData(
            color: color,
            value: entry.value.toDouble(),
            title: '${entry.value}',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          );
        }).toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'InvestmentStatus.active':
        return AppTheme.successColor;
      case 'InvestmentStatus.inactive':
        return AppTheme.errorColor;
      case 'InvestmentStatus.earlyRedemption':
        return AppTheme.warningColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  Widget _buildTopProductItem(String name, String amount, double percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                amount,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0 PLN';
    final amount = value is double
        ? value
        : double.tryParse(value.toString()) ?? 0;
    return CurrencyFormatter.formatCurrencyShort(amount);
  }

  // ============ ZAKŁADKI ANALITYKI ============

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Główne metryki
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Całkowita wartość portfela',
                  _formatCurrency(_investmentSummary?['totalAmount'] ?? 0),
                  Icons.account_balance_wallet,
                  AppTheme.primaryColor,
                  '+${((_profitabilityAnalytics?['netReturn'] ?? 0)).toStringAsFixed(1)}%',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Zysk netto',
                  _formatCurrency(_profitabilityAnalytics?['netProfit'] ?? 0),
                  Icons.trending_up,
                  AppTheme.successColor,
                  '${(_performanceAnalytics?['successRate'] ?? 0).toStringAsFixed(1)}% sukces',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Średni ROI',
                  '${(_performanceAnalytics?['averageROI'] ?? 0).toStringAsFixed(2)}%',
                  Icons.bar_chart,
                  AppTheme.infoColor,
                  'Portfolio',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rozkład inwestycji według statusu',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(height: 300, child: _buildStatusChart()),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top produkty inwestycyjne',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ..._topProducts.map(
                        (product) => _buildTopProductItem(
                          product['name'],
                          _formatCurrency(product['amount']),
                          product['amount'] /
                              (_topProducts.isNotEmpty
                                  ? _topProducts.first['amount']
                                  : 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statystyki klientów',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      _buildStatItem(
                        'Całkowita liczba klientów',
                        '${_clientStats?['totalCount'] ?? 0}',
                        Icons.people,
                      ),
                      _buildStatItem(
                        'Klienci z emailem',
                        '${_clientStats?['withEmail'] ?? 0}',
                        Icons.email,
                      ),
                      _buildStatItem(
                        'Klienci z telefonem',
                        '${_clientStats?['withPhone'] ?? 0}',
                        Icons.phone,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Podsumowanie finansowe',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      _buildStatItem(
                        'Zainwestowany kapitał',
                        _formatCurrency(
                          _profitabilityAnalytics?['totalInvested'] ?? 0,
                        ),
                        Icons.input,
                      ),
                      _buildStatItem(
                        'Zrealizowane zyski',
                        _formatCurrency(
                          _profitabilityAnalytics?['totalRealized'] ?? 0,
                        ),
                        Icons.output,
                      ),
                      _buildStatItem(
                        'Podatek zapłacony',
                        _formatCurrency(
                          _profitabilityAnalytics?['totalTax'] ?? 0,
                        ),
                        Icons.receipt,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Średni ROI',
                  '${(_performanceAnalytics?['averageROI'] ?? 0).toStringAsFixed(2)}%',
                  Icons.trending_up,
                  AppTheme.successColor,
                  'Portfel',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Zyskowne inwestycje',
                  '${_performanceAnalytics?['profitableInvestments'] ?? 0}',
                  Icons.check_circle,
                  AppTheme.successColor,
                  '${(_performanceAnalytics?['successRate'] ?? 0).toStringAsFixed(1)}%',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Stratne inwestycje',
                  '${_performanceAnalytics?['lossInvestments'] ?? 0}',
                  Icons.error,
                  AppTheme.errorColor,
                  'Straty',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wydajność według produktów',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ..._buildPerformanceByProductList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wydajność według rynku',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ..._buildPerformanceByMarketList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analiza zysków i strat',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Zrealizowane zyski',
                        _formatCurrency(
                          _performanceAnalytics?['totalRealizedProfit'] ?? 0,
                        ),
                        Icons.monetization_on,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Niezrealizowane zyski',
                        _formatCurrency(
                          _performanceAnalytics?['totalUnrealizedGains'] ?? 0,
                        ),
                        Icons.schedule,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Volatilność portfela',
                  '${(_riskAnalytics?['portfolioVolatility'] ?? 0).toStringAsFixed(2)}',
                  Icons.show_chart,
                  AppTheme.warningColor,
                  'Odchylenie',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Ryzyko koncentracji (HHI)',
                  '${(_riskAnalytics?['concentrationRisk'] ?? 0).toStringAsFixed(0)}',
                  Icons.pie_chart,
                  AppTheme.infoColor,
                  'Indeks',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Przedterminowe wykupy',
                  '${(_riskAnalytics?['earlyRedemptionRate'] ?? 0).toStringAsFixed(1)}%',
                  Icons.exit_to_app,
                  AppTheme.errorColor,
                  'Wskaźnik',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rozkład według statusu',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ..._buildStatusDistributionList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ryzyko według produktów',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ..._buildRiskByProductList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Najlepszy sprzedawca (wolumen)',
                  _employeePerformance?['topEmployeeByVolume']?['name'] ??
                      'Brak danych',
                  Icons.person_pin,
                  AppTheme.successColor,
                  _formatCurrency(
                    _employeePerformance?['topEmployeeByVolume']?['value'] ?? 0,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Najlepszy sprzedawca (liczba)',
                  _employeePerformance?['topEmployeeByCount']?['name'] ??
                      'Brak danych',
                  Icons.star,
                  AppTheme.primaryColor,
                  '${_employeePerformance?['topEmployeeByCount']?['value'] ?? 0} transakcji',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ranking pracowników według wolumenu',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                ..._buildEmployeeRankingList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeographicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Najlepszy oddział (wyniki)',
                  _geographicAnalytics?['topPerformingBranch'] ?? 'Brak danych',
                  Icons.place,
                  AppTheme.successColor,
                  'Wydajność',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Najlepszy oddział (wolumen)',
                  _geographicAnalytics?['highestVolumeBranch'] ?? 'Brak danych',
                  Icons.business,
                  AppTheme.primaryColor,
                  'Wolumen',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wydajność według oddziałów',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ..._buildBranchPerformanceList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wolumen według oddziałów',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ..._buildBranchVolumeList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Trend inwestycji',
                  '${(_timeSeriesData?['trend'] ?? 0) > 0 ? '↗' : '↘'} ${(_timeSeriesData?['trend'] ?? 0).toStringAsFixed(2)}',
                  Icons.timeline,
                  (_timeSeriesData?['trend'] ?? 0) > 0
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                  'Miesięczny',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trendy miesięczne - inwestycje',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                ..._buildMonthlyTrendsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ POMOCNICZE METODY BUDOWANIA LIST ============

  List<Widget> _buildPerformanceByProductList() {
    final performanceByProduct =
        _performanceAnalytics?['performanceByProduct']
            as Map<String, dynamic>? ??
        {};
    return performanceByProduct.entries.map((entry) {
      return _buildStatItem(
        _getProductTypeName(
          ProductType.values.firstWhere(
            (e) => e.name == entry.key,
            orElse: () => ProductType.bonds,
          ),
        ),
        '${entry.value.toStringAsFixed(2)}%',
        Icons.assessment,
      );
    }).toList();
  }

  List<Widget> _buildPerformanceByMarketList() {
    final performanceByMarket =
        _performanceAnalytics?['performanceByMarket']
            as Map<String, dynamic>? ??
        {};
    return performanceByMarket.entries.map((entry) {
      return _buildStatItem(
        entry.key,
        '${entry.value.toStringAsFixed(2)}%',
        Icons.store,
      );
    }).toList();
  }

  List<Widget> _buildStatusDistributionList() {
    final statusDistribution =
        _riskAnalytics?['statusDistribution'] as Map<String, dynamic>? ?? {};
    return statusDistribution.entries.map((entry) {
      return _buildStatItem(
        entry.key.replaceAll('InvestmentStatus.', ''),
        '${entry.value}',
        Icons.circle,
      );
    }).toList();
  }

  List<Widget> _buildRiskByProductList() {
    final riskByProduct =
        _riskAnalytics?['riskByProduct'] as Map<String, dynamic>? ?? {};
    return riskByProduct.entries.map((entry) {
      return _buildStatItem(
        _getProductTypeName(
          ProductType.values.firstWhere(
            (e) => e.name == entry.key,
            orElse: () => ProductType.bonds,
          ),
        ),
        '${entry.value.toStringAsFixed(2)}',
        Icons.warning,
      );
    }).toList();
  }

  List<Widget> _buildEmployeeRankingList() {
    final employeeVolume =
        _employeePerformance?['employeeVolume'] as Map<String, dynamic>? ?? {};
    final employeeNames =
        _employeePerformance?['employeeNames'] as Map<String, dynamic>? ?? {};

    final sortedEmployees = employeeVolume.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEmployees.take(10).map((entry) {
      return _buildStatItem(
        employeeNames[entry.key] ?? 'Nieznany',
        _formatCurrency(entry.value),
        Icons.person,
      );
    }).toList();
  }

  List<Widget> _buildBranchPerformanceList() {
    final branchPerformance =
        _geographicAnalytics?['branchPerformance'] as Map<String, dynamic>? ??
        {};
    return branchPerformance.entries.map((entry) {
      return _buildStatItem(
        entry.key,
        _formatCurrency(entry.value),
        Icons.trending_up,
      );
    }).toList();
  }

  List<Widget> _buildBranchVolumeList() {
    final branchVolume =
        _geographicAnalytics?['branchVolume'] as Map<String, dynamic>? ?? {};
    return branchVolume.entries.map((entry) {
      return _buildStatItem(
        entry.key,
        _formatCurrency(entry.value),
        Icons.account_balance,
      );
    }).toList();
  }

  List<Widget> _buildMonthlyTrendsList() {
    final monthlyInvestments =
        _timeSeriesData?['monthlyInvestments'] as Map<String, dynamic>? ?? {};
    final sortedMonths = monthlyInvestments.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sortedMonths.map((entry) {
      return _buildStatItem(
        entry.key,
        _formatCurrency(entry.value),
        Icons.calendar_month,
      );
    }).toList();
  }
}
