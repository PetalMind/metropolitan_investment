import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/investment.dart';
import '../models/product.dart';
import '../services/investment_service.dart';
import '../services/advanced_analytics_service.dart';
import '../widgets/advanced_analytics_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> 
    with TickerProviderStateMixin {
  final InvestmentService _investmentService = InvestmentService();
  final AdvancedAnalyticsService _analyticsService = AdvancedAnalyticsService();
  
  // Dane podstawowe
  Map<String, dynamic>? _summary;
  List<Investment> _recentInvestments = [];
  List<Investment> _investmentsRequiringAttention = [];
  
  // Zaawansowane metryki
  AdvancedDashboardMetrics? _advancedMetrics;
  
  bool _isLoading = true;
  String _selectedTimeFrame = '12M';
  int _selectedDashboardTab = 0;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDashboardData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Ładuj dane równolegle dla lepszej wydajności
      final results = await Future.wait([
        _investmentService.getInvestmentSummary(),
        _investmentService.getInvestmentsPaginated(limit: 5),
        _investmentService.getInvestmentsRequiringAttention(),
        _analyticsService.getAdvancedDashboardMetrics(),
      ]);

      setState(() {
        _summary = results[0] as Map<String, dynamic>;
        _recentInvestments = results[1] as List<Investment>;
        _investmentsRequiringAttention = results[2] as List<Investment>;
        _advancedMetrics = results[3] as AdvancedDashboardMetrics;
        _isLoading = false;
      });

      // Start animation after data is loaded
      _fadeController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Błąd podczas ładowania danych: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        action: SnackBarAction(
          label: 'Spróbuj ponownie',
          textColor: Colors.white,
          onPressed: _loadDashboardData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text(
                'Ładowanie zaawansowanych analiz...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildDashboardHeader(),
            _buildTabBar(),
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.gradientDecoration,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Inwestycji',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.textOnPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kompleksowa analiza portfela z predykcjami i alertami',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textOnPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          _buildTimeFrameSelector(),
          const SizedBox(width: 16),
          _buildRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildTimeFrameSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedTimeFrame,
        dropdownColor: AppTheme.surfaceCard,
        underline: const SizedBox(),
        style: const TextStyle(color: AppTheme.textOnPrimary),
        items: const [
          DropdownMenuItem(value: '1M', child: Text('1 miesiąc')),
          DropdownMenuItem(value: '3M', child: Text('3 miesiące')),
          DropdownMenuItem(value: '6M', child: Text('6 miesięcy')),
          DropdownMenuItem(value: '12M', child: Text('12 miesięcy')),
          DropdownMenuItem(value: 'ALL', child: Text('Wszystko')),
        ],
        onChanged: (value) {
          setState(() => _selectedTimeFrame = value!);
          _loadDashboardData();
        },
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: _loadDashboardData,
        icon: const Icon(Icons.refresh, color: AppTheme.textOnPrimary),
        tooltip: 'Odśwież dane',
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildTabButton(0, 'Przegląd', Icons.dashboard),
          _buildTabButton(1, 'Wydajność', Icons.trending_up),
          _buildTabButton(2, 'Ryzyko', Icons.security),
          _buildTabButton(3, 'Prognozy', Icons.insights),
          _buildTabButton(4, 'Benchmarki', Icons.compare_arrows),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedDashboardTab == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDashboardTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedDashboardTab) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildPerformanceTab();
      case 2:
        return _buildRiskTab();
      case 3:
        return _buildPredictionsTab();
      case 4:
        return _buildBenchmarkTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdvancedSummaryCards(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildPortfolioComposition(),
                    const SizedBox(height: 24),
                    _buildRecentInvestments(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildQuickMetrics(),
                    const SizedBox(height: 24),
                    _buildAttentionRequired(),
                    const SizedBox(height: 24),
                    _buildRiskAlerts(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    if (_advancedMetrics == null) return const SizedBox();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildPerformanceMetrics(),
          const SizedBox(height: 24),
          _buildEmployeePerformance(),
          const SizedBox(height: 24),
          _buildProductPerformance(),
        ],
      ),
    );
  }

  Widget _buildRiskTab() {
    if (_advancedMetrics == null) return const SizedBox();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildRiskMetrics(),
          const SizedBox(height: 24),
          _buildRiskAnalysis(),
          const SizedBox(height: 24),
          _buildConcentrationAnalysis(),
        ],
      ),
    );
  }

  Widget _buildPredictionsTab() {
    if (_advancedMetrics == null) return const SizedBox();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildPredictiveAnalytics(),
          const SizedBox(height: 24),
          _buildPortfolioOptimization(),
          const SizedBox(height: 24),
          _buildMarketTrends(),
        ],
      ),
    );
  }

  Widget _buildBenchmarkTab() {
    if (_advancedMetrics == null) return const SizedBox();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildBenchmarkComparison(),
          const SizedBox(height: 24),
          _buildMarketComparison(),
          const SizedBox(height: 24),
          _buildCompetitorAnalysis(),
        ],
      ),
    );
  }

  // ============ ZAAWANSOWANE METRYKI DASHBOARD ============

  Widget _buildAdvancedSummaryCards() {
    if (_advancedMetrics == null) return const SizedBox();
    
    final metrics = _advancedMetrics!.portfolioMetrics;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AdvancedMetricCard(
                title: 'Łączna Wartość Portfela',
                value: _formatCurrency(metrics.totalValue),
                subtitle: 'Wszystkie inwestycje',
                icon: Icons.account_balance_wallet,
                color: AppTheme.primaryColor,
                trend: '${metrics.portfolioGrowthRate >= 0 ? '+' : ''}${metrics.portfolioGrowthRate.toStringAsFixed(1)}%',
                trendValue: metrics.portfolioGrowthRate,
                additionalInfo: [
                  'ROI portfela: ${metrics.roi.toStringAsFixed(2)}%',
                  'Średnia inwestycja: ${_formatCurrency(metrics.averageInvestmentSize)}',
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AdvancedMetricCard(
                title: 'Zainwestowany Kapitał',
                value: _formatCurrency(metrics.totalInvested),
                subtitle: 'Całkowite wpłaty',
                icon: Icons.trending_up,
                color: AppTheme.infoColor,
                additionalInfo: [
                  'Mediana: ${_formatCurrency(metrics.medianInvestmentSize)}',
                  'Aktywne: ${metrics.activeInvestmentsCount}/${metrics.totalInvestmentsCount}',
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AdvancedMetricCard(
                title: 'Zrealizowane Zyski',
                value: _formatCurrency(metrics.totalRealized),
                subtitle: 'Wypłacone środki',
                icon: Icons.monetization_on,
                color: AppTheme.successColor,
                trend: _getRealizedTrend(),
                additionalInfo: [
                  'Odsetki: ${_formatCurrency(metrics.totalInterest)}',
                  'Zysk całkowity: ${_formatCurrency(metrics.totalProfit)}',
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AdvancedMetricCard(
                title: 'Wskaźnik Sharpe\'a',
                value: _advancedMetrics!.riskMetrics.sharpeRatio.toStringAsFixed(3),
                subtitle: 'Ryzyko vs zwrot',
                icon: Icons.analytics,
                color: _getSharpeColor(_advancedMetrics!.riskMetrics.sharpeRatio),
                additionalInfo: [
                  'Volatilność: ${_advancedMetrics!.riskMetrics.volatility.toStringAsFixed(2)}%',
                  'Max strata: ${_advancedMetrics!.riskMetrics.maxDrawdown.toStringAsFixed(2)}%',
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPortfolioComposition() {
    if (_advancedMetrics == null) return const SizedBox();
    
    final productData = <String, double>{};
    final productColors = <String, Color>{};
    
    _advancedMetrics!.productAnalytics.productPerformance.forEach((type, performance) {
      productData[_getProductTypeName(type)] = performance.totalValue;
      productColors[_getProductTypeName(type)] = AppTheme.getProductTypeColor(type.name);
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: AdvancedPieChart(
        data: productData,
        colors: productColors,
        title: 'Skład Portfela według Produktów',
        showLegend: true,
        showPercentages: true,
      ),
    );
  }

  Widget _buildQuickMetrics() {
    if (_advancedMetrics == null) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Szybkie Metryki',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildQuickMetricItem(
            'Nowi klienci (miesiąc)',
            '${_advancedMetrics!.clientAnalytics.newClientsThisMonth}',
            Icons.person_add,
            AppTheme.successColor,
          ),
          _buildQuickMetricItem(
            'Retencja klientów',
            '${_advancedMetrics!.clientAnalytics.clientRetention.toStringAsFixed(1)}%',
            Icons.loyalty,
            AppTheme.primaryColor,
          ),
          _buildQuickMetricItem(
            'Dywersyfikacja geo.',
            '${_advancedMetrics!.geographicAnalytics.geographicDiversification.toStringAsFixed(0)} oddziałów',
            Icons.public,
            AppTheme.infoColor,
          ),
          _buildQuickMetricItem(
            'Momentum portfela',
            '${_advancedMetrics!.timeSeriesAnalytics.momentum.toStringAsFixed(1)}%',
            Icons.speed,
            _getMomentumColor(_advancedMetrics!.timeSeriesAnalytics.momentum),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetricItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAlerts() {
    if (_advancedMetrics == null) return const SizedBox();
    
    final riskMetrics = _advancedMetrics!.riskMetrics;
    final alerts = <Widget>[];

    // Sprawdź różne poziomy ryzyka
    if (riskMetrics.concentrationRisk > 2500) {
      alerts.add(RiskAlertWidget(
        title: 'Wysokie ryzyko koncentracji',
        message: 'HHI: ${riskMetrics.concentrationRisk.toStringAsFixed(0)}',
        riskLevel: riskMetrics.concentrationRisk > 5000 ? RiskLevel.high : RiskLevel.medium,
      ));
    }

    if (riskMetrics.volatility > 15) {
      alerts.add(RiskAlertWidget(
        title: 'Wysoka volatilność',
        message: 'Odchylenie: ${riskMetrics.volatility.toStringAsFixed(2)}%',
        riskLevel: riskMetrics.volatility > 25 ? RiskLevel.high : RiskLevel.medium,
      ));
    }

    if (riskMetrics.liquidityRisk > 70) {
      alerts.add(RiskAlertWidget(
        title: 'Ryzyko płynności',
        message: '${riskMetrics.liquidityRisk.toStringAsFixed(1)}% długoterminowe',
        riskLevel: RiskLevel.medium,
      ));
    }

    if (alerts.isEmpty) {
      alerts.add(RiskAlertWidget(
        title: 'Poziom ryzyka kontrolowany',
        message: 'Wszystkie wskaźniki w normie',
        riskLevel: RiskLevel.low,
      ));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alerty Ryzyka',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ...alerts,
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    if (_advancedMetrics == null) return const SizedBox();
    
    final perfMetrics = _advancedMetrics!.performanceMetrics;
    
    return Row(
      children: [
        Expanded(
          child: AdvancedMetricCard(
            title: 'Średni Zwrot',
            value: '${perfMetrics.averageReturn.toStringAsFixed(2)}%',
            subtitle: 'Portfel',
            icon: Icons.trending_up,
            color: AppTheme.successColor,
            additionalInfo: [
              'Sukces: ${perfMetrics.successRate.toStringAsFixed(1)}%',
              'Alpha: ${perfMetrics.alpha.toStringAsFixed(3)}',
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdvancedMetricCard(
            title: 'Beta Portfela',
            value: perfMetrics.beta.toStringAsFixed(3),
            subtitle: 'Wrażliwość na rynek',
            icon: Icons.show_chart,
            color: AppTheme.infoColor,
            additionalInfo: [
              'Info Ratio: ${perfMetrics.informationRatio.toStringAsFixed(3)}',
              'Tracking Error: ${perfMetrics.trackingError.toStringAsFixed(2)}%',
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdvancedMetricCard(
            title: 'Najlepsza Inwestycja',
            value: perfMetrics.bestPerformingInvestment != null 
              ? '${perfMetrics.bestPerformingInvestment!.profitLossPercentage.toStringAsFixed(2)}%'
              : 'Brak danych',
            subtitle: perfMetrics.bestPerformingInvestment?.clientName ?? '',
            icon: Icons.star,
            color: AppTheme.successColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeePerformance() {
    if (_advancedMetrics == null) return const SizedBox();
    
    final employeeData = <String, double>{};
    _advancedMetrics!.employeeAnalytics.topPerformers.take(5).forEach((emp) {
      employeeData[emp.name] = emp.performance.totalVolume;
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: AdvancedBarChart(
        data: employeeData,
        title: 'Top 5 Sprzedawców (Wolumen)',
        color: AppTheme.primaryColor,
        yAxisLabel: 'Wolumen (PLN)',
      ),
    );
  }

  Widget _buildProductPerformance() {
    if (_advancedMetrics == null) return const SizedBox();
    
    final productData = <String, double>{};
    _advancedMetrics!.productAnalytics.productPerformance.forEach((type, performance) {
      productData[_getProductTypeName(type)] = performance.averageReturn;
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: AdvancedBarChart(
        data: productData,
        title: 'Średni Zwrot według Produktów',
        color: AppTheme.successColor,
        yAxisLabel: 'Zwrot (%)',
      ),
    );
  }

  Widget _buildRiskMetrics() {
    if (_advancedMetrics == null) return const SizedBox();
    
    final riskMetrics = _advancedMetrics!.riskMetrics;
    
    return Row(
      children: [
        Expanded(
          child: AdvancedMetricCard(
            title: 'Value at Risk (5%)',
            value: '${riskMetrics.valueAtRisk.toStringAsFixed(2)}%',
            subtitle: '5% prawdopodobieństwo',
            icon: Icons.warning,
            color: AppTheme.errorColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdvancedMetricCard(
            title: 'Ryzyko Koncentracji (HHI)',
            value: riskMetrics.concentrationRisk.toStringAsFixed(0),
            subtitle: 'Indeks Herfindahla',
            icon: Icons.pie_chart,
            color: _getConcentrationColor(riskMetrics.concentrationRisk),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdvancedMetricCard(
            title: 'Dywersyfikacja',
            value: '${riskMetrics.diversificationRatio.toStringAsFixed(1)}%',
            subtitle: 'Wskaźnik rozproszenia',
            icon: Icons.scatter_plot,
            color: AppTheme.infoColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdvancedMetricCard(
            title: 'Ryzyko Kredytowe',
            value: riskMetrics.creditRisk.toStringAsFixed(2),
            subtitle: 'Ocena portfela',
            icon: Icons.credit_score,
            color: _getCreditRiskColor(riskMetrics.creditRisk),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskAnalysis() {
    // Placeholder for detailed risk analysis
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analiza Ryzyka - Macierz Korelacji',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Zaawansowana analiza korelacji między produktami\n(funkcjonalność w trakcie implementacji)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConcentrationAnalysis() {
    if (_advancedMetrics == null) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analiza Koncentracji - Top Klienci',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ..._advancedMetrics!.clientAnalytics.topClients.take(5).map((client) {
            final percentage = _advancedMetrics!.portfolioMetrics.totalValue > 0 
              ? (client.value / _advancedMetrics!.portfolioMetrics.totalValue) * 100
              : 0;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      client.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(client.value),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(2)}% portfela',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPredictiveAnalytics() {
    if (_advancedMetrics == null) return const SizedBox();
    
    final prediction = _advancedMetrics!.predictionMetrics;
    
    return Row(
      children: [
        Expanded(
          child: AdvancedMetricCard(
            title: 'Prognozowane Zwroty',
            value: '${prediction.projectedReturns.toStringAsFixed(2)}%',
            subtitle: '12 miesięcy',
            icon: Icons.timeline,
            color: AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdvancedMetricCard(
            title: 'Oczekiwana Wartość Wykupu',
            value: _formatCurrency(prediction.expectedMaturityValue),
            subtitle: 'Przy zapadalności',
            icon: Icons.paid,
            color: AppTheme.infoColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdvancedMetricCard(
            title: 'Zwrot z Korektą Ryzyka',
            value: prediction.riskAdjustedReturns.toStringAsFixed(3),
            subtitle: 'Skorygowany o volatilność',
            icon: Icons.balance,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioOptimization() {
    if (_advancedMetrics == null) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rekomendacje Optymalizacji',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border(left: BorderSide(color: AppTheme.primaryColor, width: 4)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _advancedMetrics!.predictionMetrics.portfolioOptimization,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketTrends() {
    if (_advancedMetrics == null) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: AdvancedLineChart(
        data: _advancedMetrics!.timeSeriesAnalytics.monthlyData,
        title: 'Trendy Inwestycji - Szereg Czasowy',
        color: AppTheme.primaryColor,
        yAxisLabel: 'Wolumen (PLN)',
      ),
    );
  }

  Widget _buildBenchmarkComparison() {
    if (_advancedMetrics == null) return const SizedBox();
    
    final benchmark = _advancedMetrics!.benchmarkMetrics;
    
    return Row(
      children: [
        Expanded(
          child: AdvancedMetricCard(
            title: 'vs. Rynek',
            value: '${benchmark.vsMarketReturn >= 0 ? '+' : ''}${benchmark.vsMarketReturn.toStringAsFixed(2)}%',
            subtitle: 'Nadwyżka nad benchmarkiem',
            icon: Icons.compare_arrows,
            color: benchmark.vsMarketReturn >= 0 ? AppTheme.successColor : AppTheme.errorColor,
            trend: benchmark.vsMarketReturn >= 0 ? 'Outperformance' : 'Underperformance',
            trendValue: benchmark.vsMarketReturn,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdvancedMetricCard(
            title: 'Względna Wydajność',
            value: '${benchmark.relativePerfomance.toStringAsFixed(1)}%',
            subtitle: 'vs. benchmark bazowy',
            icon: Icons.percent,
            color: AppTheme.infoColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdvancedMetricCard(
            title: 'Ponad Benchmark',
            value: '${benchmark.outperformingInvestments}',
            subtitle: 'Liczba inwestycji',
            icon: Icons.emoji_events,
            color: AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdvancedMetricCard(
            title: 'Korelacja z Rynkiem',
            value: benchmark.benchmarkCorrelation.toStringAsFixed(3),
            subtitle: 'Współczynnik Beta',
            icon: Icons.device_hub,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMarketComparison() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Porównanie z Rynkiem',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Szczegółowe porównanie z indeksami rynkowymi\n(funkcjonalność w trakcie implementacji)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitorAnalysis() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analiza Konkurencji',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Pozycjonowanie względem konkurencji\n(funkcjonalność w trakcie implementacji)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ METODY POMOCNICZE ============

  String _getRealizedTrend() {
    if (_advancedMetrics == null) return '';
    final realized = _advancedMetrics!.portfolioMetrics.totalRealized;
    final invested = _advancedMetrics!.portfolioMetrics.totalInvested;
    if (invested > 0) {
      final percentage = (realized / invested) * 100;
      return '${percentage.toStringAsFixed(1)}% z wpłat';
    }
    return '';
  }

  Color _getSharpeColor(double sharpe) {
    if (sharpe > 1.0) return AppTheme.successColor;
    if (sharpe > 0.5) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  Color _getMomentumColor(double momentum) {
    if (momentum > 5) return AppTheme.successColor;
    if (momentum > 0) return AppTheme.infoColor;
    if (momentum > -5) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  Color _getConcentrationColor(double hhi) {
    if (hhi < 1500) return AppTheme.successColor;
    if (hhi < 2500) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  Color _getCreditRiskColor(double risk) {
    if (risk < 2) return AppTheme.successColor;
    if (risk < 3) return AppTheme.warningColor;
    return AppTheme.errorColor;
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.gradientDecoration,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Inwestycji',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.textOnPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Przegląd aktywności inwestycyjnej',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textOnPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.dashboard,
            size: 48,
            color: AppTheme.textOnPrimary.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final summary = _summary;
    if (summary == null) return const SizedBox();

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Łączne Inwestycje',
            '${_formatCurrency(summary['totalInvestment'] ?? 0)}',
            Icons.account_balance_wallet,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Zrealizowane',
            '${_formatCurrency(summary['totalRealized'] ?? 0)}',
            Icons.trending_up,
            AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Pozostałe',
            '${_formatCurrency(summary['totalRemaining'] ?? 0)}',
            Icons.hourglass_empty,
            AppTheme.warningColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Zysk/Strata',
            '${_formatCurrency(summary['totalProfit'] ?? 0)}',
            Icons.show_chart,
            (summary['totalProfit'] ?? 0) >= 0
                ? AppTheme.successColor
                : AppTheme.errorColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 32),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.arrow_upward, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentsByTypeChart() {
    final summary = _summary;
    if (summary == null) return const SizedBox();

    final byType = summary['byType'] as Map<ProductType, double>? ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inwestycje według typu',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: byType.entries.map((entry) {
                  final percentage =
                      (entry.value / (summary['totalInvestment'] ?? 1)) * 100;
                  return PieChartSectionData(
                    value: entry.value,
                    title: '${percentage.toStringAsFixed(1)}%',
                    color: AppTheme.getProductTypeColor(entry.key.name),
                    radius: 100,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  );
                }).toList(),
                centerSpaceRadius: 50,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...byType.entries.map(
            (entry) => _buildLegendItem(
              entry.key.displayName,
              AppTheme.getProductTypeColor(entry.key.name),
              _formatCurrency(entry.value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentsByStatusChart() {
    final summary = _summary;
    if (summary == null) return const SizedBox();

    final byStatus = summary['byStatus'] as Map<InvestmentStatus, int>? ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status inwestycji',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: byStatus.values.isNotEmpty
                    ? byStatus.values.reduce((a, b) => a > b ? a : b).toDouble()
                    : 10,
                barGroups: byStatus.entries.map((entry) {
                  final index = byStatus.keys.toList().indexOf(entry.key);
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(),
                        color: AppTheme.getStatusColor(entry.key.name),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final statuses = byStatus.keys.toList();
                        if (value.toInt() < statuses.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              statuses[value.toInt()].displayName,
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInvestments() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Najnowsze inwestycje',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              TextButton(
                onPressed: () {
                  // Navigate to investments screen
                },
                child: const Text('Zobacz wszystkie'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._recentInvestments.map(
            (investment) => _buildInvestmentListItem(investment),
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionRequired() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wymagają uwagi',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          if (_investmentsRequiringAttention.isEmpty)
            const Text('Brak inwestycji wymagających uwagi')
          else
            ..._investmentsRequiringAttention.map(
              (investment) => _buildAttentionItem(investment),
            ),
        ],
      ),
    );
  }

  Widget _buildInvestmentListItem(Investment investment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.getProductTypeColor(investment.productType.name),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  investment.clientName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  investment.productName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(investment.investmentAmount),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                _formatDate(investment.signedDate),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionItem(Investment investment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: AppTheme.warningColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  investment.clientName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  'Wykup: ${_formatDate(investment.redemptionDate!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match match) => '${match[1]} ')} PLN';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
