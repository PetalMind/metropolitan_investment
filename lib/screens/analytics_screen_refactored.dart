import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/advanced_analytics_service.dart';
import '../models/product.dart';
import '../utils/currency_formatter.dart';

/// 🚀 REFACTORED ADVANCED ANALYTICS SCREEN
/// Completely redesigned with modular components and real Firebase data
class AnalyticsScreenRefactored extends StatefulWidget {
  const AnalyticsScreenRefactored({super.key});

  @override
  State<AnalyticsScreenRefactored> createState() => _AnalyticsScreenRefactoredState();
}

class _AnalyticsScreenRefactoredState extends State<AnalyticsScreenRefactored>
    with TickerProviderStateMixin {
  
  final AdvancedAnalyticsService _analyticsService = AdvancedAnalyticsService();
  
  // Data
  AdvancedDashboardMetrics? _metricsData;
  bool _isLoading = true;
  String? _error;
  
  // UI State
  int _selectedTimeRange = 12;
  String _selectedAnalyticsTab = 'overview';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Responsive breakpoints
  bool get _isTablet => MediaQuery.of(context).size.width > 768;
  bool get _isDesktop => MediaQuery.of(context).size.width > 1200;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAnalyticsData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadAnalyticsData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final metrics = await _analyticsService.getAdvancedDashboardMetrics();
      
      if (!mounted) return;
      
      setState(() {
        _metricsData = metrics;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
      floatingActionButton: _buildRefreshFab(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
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
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppTheme.textOnPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Analiza w czasie rzeczywistym z danymi Firebase',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textOnPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isTablet) _buildDesktopControls(),
            ],
          ),
          const SizedBox(height: 24),
          _buildTabBar(),
        ],
      ),
    );
  }

  Widget _buildDesktopControls() {
    return Row(
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
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<int>(
        value: _selectedTimeRange,
        underline: const SizedBox(),
        style: const TextStyle(color: AppTheme.primaryColor),
        dropdownColor: AppTheme.surfaceCard,
        items: const [
          DropdownMenuItem(value: 3, child: Text('3 miesiące')),
          DropdownMenuItem(value: 6, child: Text('6 miesięcy')),
          DropdownMenuItem(value: 12, child: Text('12 miesięcy')),
          DropdownMenuItem(value: 24, child: Text('24 miesiące')),
          DropdownMenuItem(value: -1, child: Text('Cały okres')),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedTimeRange = value);
            _loadAnalyticsData();
          }
        },
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      _TabInfo('overview', 'Przegląd', Icons.dashboard),
      _TabInfo('performance', 'Wydajność', Icons.trending_up),
      _TabInfo('risk', 'Ryzyko', Icons.security),
      _TabInfo('employees', 'Zespół', Icons.people),
      _TabInfo('geographic', 'Geografia', Icons.map),
      _TabInfo('trends', 'Trendy', Icons.timeline),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _isTablet
          ? Row(
              children: tabs.map((tab) => Expanded(
                child: _buildTabButton(tab),
              )).toList(),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tabs.map((tab) => _buildTabButton(tab, isExpanded: false)).toList(),
              ),
            ),
    );
  }

  Widget _buildTabButton(_TabInfo tab, {bool isExpanded = true}) {
    final isSelected = _selectedAnalyticsTab == tab.id;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isExpanded ? null : 120,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedAnalyticsTab = tab.id),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 12, 
              horizontal: isExpanded ? 8 : 16,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tab.icon,
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  tab.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            SizedBox(height: 16),
            Text('Ładowanie danych analitycznych...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text('Błąd: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnalyticsData,
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadAnalyticsData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildTabContent(),
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

  Widget _buildOverviewTab() {
    return Column(
      children: [
        _buildKeyMetricsGrid(),
        const SizedBox(height: 24),
        _buildChartsRow(),
        const SizedBox(height: 24),
        _buildSummaryRow(),
      ],
    );
  }

  Widget _buildKeyMetricsGrid() {
    final metrics = _metricsData?.portfolioMetrics;
    if (metrics == null) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _isDesktop ? 4 : (_isTablet ? 3 : 2);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: _isTablet ? 1.2 : 1.0,
          children: [
            _buildMetricCard(
              'Całkowita wartość',
              CurrencyFormatter.formatCurrencyShort(metrics.totalValue),
              Icons.account_balance_wallet,
              AppTheme.primaryColor,
              change: '+${metrics.roi.toStringAsFixed(1)}%',
            ),
            _buildMetricCard(
              'Zrealizowany zysk',
              CurrencyFormatter.formatCurrencyShort(metrics.totalProfit),
              Icons.trending_up,
              AppTheme.successColor,
            ),
            _buildMetricCard(
              'ROI Portfela',
              '${metrics.roi.toStringAsFixed(2)}%',
              Icons.bar_chart,
              AppTheme.infoColor,
            ),
            _buildMetricCard(
              'Aktywne inwestycje',
              '${metrics.activeInvestmentsCount}',
              Icons.pie_chart,
              AppTheme.secondaryGold,
              subtitle: '${metrics.totalInvestmentsCount} łącznie',
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? change,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration.copyWith(
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
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
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          if (change != null || subtitle != null) ...[
            const SizedBox(height: 8),
            if (change != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: const TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 12,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_isTablet) {
          return Row(
            children: [
              Expanded(child: _buildPortfolioChart()),
              const SizedBox(width: 16),
              Expanded(child: _buildPerformanceChart()),
            ],
          );
        } else {
          return Column(
            children: [
              _buildPortfolioChart(),
              const SizedBox(height: 16),
              _buildPerformanceChart(),
            ],
          );
        }
      },
    );
  }

  Widget _buildPortfolioChart() {
    final productAnalytics = _metricsData?.productAnalytics;
    if (productAnalytics == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rozkład portfela',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sections: _buildPieChartSections(productAnalytics.productPerformance),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    final timeSeriesData = _metricsData?.timeSeriesAnalytics.monthlyData;
    if (timeSeriesData == null || timeSeriesData.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend miesięczny',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: _buildLineChartSpots(timeSeriesData),
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    Map<ProductType, ProductPerformance> productPerformance,
  ) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryGold,
      AppTheme.successColor,
      AppTheme.infoColor,
    ];

    return productPerformance.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final product = entry.value;
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: product.value.totalValue,
        title: product.value.count.toString(),
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<FlSpot> _buildLineChartSpots(List<MonthlyData> monthlyData) {
    return monthlyData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.totalVolume / 1000000);
    }).toList();
  }

  Widget _buildSummaryRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_isTablet) {
          return Row(
            children: [
              Expanded(child: _buildClientSummaryCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildRiskSummaryCard()),
            ],
          );
        } else {
          return Column(
            children: [
              _buildClientSummaryCard(),
              const SizedBox(height: 16),
              _buildRiskSummaryCard(),
            ],
          );
        }
      },
    );
  }

  Widget _buildClientSummaryCard() {
    final clientAnalytics = _metricsData?.clientAnalytics;
    if (clientAnalytics == null) return const SizedBox();

    return Container(
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
            'Łączna liczba klientów',
            '${clientAnalytics.totalClients}',
            Icons.people,
          ),
          _buildStatItem(
            'Nowi klienci (miesiąc)',
            '${clientAnalytics.newClientsThisMonth}',
            Icons.person_add,
          ),
          _buildStatItem(
            'Retencja klientów',
            '${clientAnalytics.clientRetention.toStringAsFixed(1)}%',
            Icons.favorite,
          ),
        ],
      ),
    );
  }

  Widget _buildRiskSummaryCard() {
    final riskMetrics = _metricsData?.riskMetrics;
    if (riskMetrics == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analiza ryzyka',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            'Volatilność portfela',
            '${riskMetrics.volatility.toStringAsFixed(2)}%',
            Icons.show_chart,
          ),
          _buildStatItem(
            'Sharpe Ratio',
            riskMetrics.sharpeRatio.toStringAsFixed(2),
            Icons.trending_up,
          ),
          _buildStatItem(
            'Maksymalny spadek',
            '${riskMetrics.maxDrawdown.toStringAsFixed(1)}%',
            Icons.trending_down,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 14)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder methods for other tabs
  Widget _buildPerformanceTab() {
    return const Center(child: Text('Zakładka wydajności - w przygotowaniu'));
  }

  Widget _buildRiskTab() {
    return const Center(child: Text('Zakładka ryzyka - w przygotowaniu'));
  }

  Widget _buildEmployeesTab() {
    return const Center(child: Text('Zakładka zespołu - w przygotowaniu'));
  }

  Widget _buildGeographicTab() {
    return const Center(child: Text('Zakładka geograficzna - w przygotowaniu'));
  }

  Widget _buildTrendsTab() {
    return const Center(child: Text('Zakładka trendów - w przygotowaniu'));
  }

  Widget _buildRefreshFab() {
    return FloatingActionButton(
      onPressed: _loadAnalyticsData,
      backgroundColor: AppTheme.primaryColor,
      child: const Icon(Icons.refresh),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eksport raportu - funkcja w przygotowaniu'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}

class _TabInfo {
  final String id;
  final String label;
  final IconData icon;

  const _TabInfo(this.id, this.label, this.icon);
}