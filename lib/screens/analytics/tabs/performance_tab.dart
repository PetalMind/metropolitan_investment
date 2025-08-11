import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';
import '../../../services/analytics/performance_analytics_service.dart';
import '../../../models/analytics/performance_analytics_models.dart';
import '../../../utils/currency_formatter.dart';
import '../widgets/metric_card.dart';

/// Tab wydajności z kompletną implementacją
class PerformanceTab extends StatefulWidget {
  final int selectedTimeRange;

  const PerformanceTab({super.key, required this.selectedTimeRange});

  @override
  State<PerformanceTab> createState() => _PerformanceTabState();
}

class _PerformanceTabState extends State<PerformanceTab> {
  final PerformanceAnalyticsService _service = PerformanceAnalyticsService();
  PerformanceAnalytics? _analytics;
  bool _isLoading = true;
  String? _error;

  // UI state
  String _selectedView = 'overview';

  bool get _isTablet => MediaQuery.of(context).size.width > 768;
  bool get _isDesktop => MediaQuery.of(context).size.width > 1200;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(PerformanceTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTimeRange != widget.selectedTimeRange) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final analytics = await _service.getPerformanceAnalytics(
        timeRangeMonths: widget.selectedTimeRange,
      );

      if (!mounted) return;

      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
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
              onPressed: _loadData,
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    final analytics = _analytics!;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildViewSelector(),
            const SizedBox(height: 24),
            _buildSelectedView(analytics),
          ],
        ),
      ),
    );
  }

  Widget _buildViewSelector() {
    final views = [
      {'id': 'overview', 'name': 'Przegląd', 'icon': Icons.dashboard},
      {'id': 'benchmark', 'name': 'Benchmark', 'icon': Icons.compare_arrows},
      {'id': 'products', 'name': 'Produkty', 'icon': Icons.pie_chart},
      {'id': 'risk', 'name': 'Ryzyko', 'icon': Icons.security},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _isTablet
          ? Row(
              children: views
                  .map((view) => Expanded(child: _buildViewButton(view)))
                  .toList(),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: views
                    .map((view) => _buildViewButton(view, isExpanded: false))
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildViewButton(Map<String, dynamic> view, {bool isExpanded = true}) {
    final isSelected = _selectedView == view['id'];
    return Container(
      width: isExpanded ? null : 120,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedView = view['id']),
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
                  view['icon'],
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  view['name'],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
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

  Widget _buildSelectedView(PerformanceAnalytics analytics) {
    switch (_selectedView) {
      case 'overview':
        return _buildOverviewView(analytics);
      case 'benchmark':
        return _buildBenchmarkView(analytics);
      case 'products':
        return _buildProductsView(analytics);
      case 'risk':
        return _buildRiskView(analytics);
      default:
        return _buildOverviewView(analytics);
    }
  }

  Widget _buildOverviewView(PerformanceAnalytics analytics) {
    return Column(
      children: [
        _buildOverviewMetrics(analytics.overview),
        const SizedBox(height: 24),
        _buildPerformanceChart(analytics.performanceHistory),
        const SizedBox(height: 24),
        _buildTopPerformers(analytics.topPerformers),
      ],
    );
  }

  Widget _buildOverviewMetrics(PerformanceOverviewData overview) {
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
            MetricCard(
              title: 'Całkowity zwrot',
              value: '${overview.totalReturn.toStringAsFixed(2)}%',
              icon: Icons.trending_up,
              color: overview.totalReturn >= 0
                  ? AppTheme.successColor
                  : AppTheme.errorColor,
              change: overview.excessReturn >= 0
                  ? '+${overview.excessReturn.toStringAsFixed(1)}% vs benchmark'
                  : '${overview.excessReturn.toStringAsFixed(1)}% vs benchmark',
            ),
            MetricCard(
              title: 'Zwrot roczny (CAGR)',
              value: '${overview.annualizedReturn.toStringAsFixed(2)}%',
              icon: Icons.show_chart,
              color: AppTheme.primaryColor,
            ),
            MetricCard(
              title: 'Współczynnik sukcesu',
              value: '${overview.successRate.toStringAsFixed(1)}%',
              icon: Icons.emoji_events,
              color: AppTheme.secondaryGold,
            ),
            MetricCard(
              title: 'Stosunek zysków/strat',
              value: overview.winLossRatio == double.infinity
                  ? '∞'
                  : overview.winLossRatio.toStringAsFixed(2),
              icon: Icons.balance,
              color: AppTheme.infoColor,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPerformanceChart(List<PerformanceHistoryItem> history) {
    if (history.isEmpty) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 64, color: AppTheme.textTertiary),
              SizedBox(height: 16),
              Text('Brak danych historycznych'),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historia wydajności',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: history.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.cumulativeReturn,
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.3),
                          AppTheme.primaryColor.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (history.length / 6).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= history.length) {
                          return const SizedBox();
                        }
                        final date = history[index].date;
                        return Text(
                          '${date.month}/${date.year.toString().substring(2)}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.textTertiary.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformers(List<TopPerformingInvestmentItem> topPerformers) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 10 wykonujących inwestycji',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ...topPerformers
              .take(10)
              .map((investment) => _buildTopPerformerItem(investment))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildTopPerformerItem(TopPerformingInvestmentItem investment) {
    final returnColor = investment.return_ >= 0
        ? AppTheme.successColor
        : AppTheme.errorColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: returnColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: returnColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              investment.return_ >= 0 ? Icons.trending_up : Icons.trending_down,
              color: returnColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  investment.clientName.length > 30
                      ? '${investment.clientName.substring(0, 30)}...'
                      : investment.clientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  investment.productName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${investment.return_.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: returnColor,
                  fontSize: 16,
                ),
              ),
              Text(
                CurrencyFormatter.formatCurrencyShort(
                  investment.investmentAmount,
                ),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkView(PerformanceAnalytics analytics) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Porównanie z benchmarkiem',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          ...analytics.benchmarkComparison
              .map((comparison) => _buildBenchmarkItem(comparison))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildBenchmarkItem(BenchmarkComparisonItem comparison) {
    final outperformanceColor = comparison.outperformance >= 0
        ? AppTheme.successColor
        : AppTheme.errorColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            child: Text(
              comparison.period,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${comparison.portfolioReturn.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Text(
                      'Portfel',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${comparison.benchmarkReturn.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const Text(
                      'Benchmark',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${comparison.outperformance >= 0 ? '+' : ''}${comparison.outperformance.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: outperformanceColor,
                      ),
                    ),
                    const Text(
                      'Różnica',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
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

  Widget _buildProductsView(PerformanceAnalytics analytics) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wydajność według produktów',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          ...analytics.productPerformance
              .map((product) => _buildProductItem(product))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildProductItem(ProductPerformanceData product) {
    final returnColor = product.averageReturn >= 0
        ? AppTheme.successColor
        : AppTheme.errorColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: returnColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                product.productName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${product.averageReturn.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: returnColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProductStat('Inwestycje', '${product.investmentCount}'),
              _buildProductStat(
                'Wartość',
                CurrencyFormatter.formatCurrencyShort(product.totalValue),
              ),
              _buildProductStat(
                'Volatilność',
                '${product.volatility.toStringAsFixed(2)}%',
              ),
              _buildProductStat(
                'Sharpe',
                product.sharpeRatio.toStringAsFixed(2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildRiskView(PerformanceAnalytics analytics) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metryki dostosowane do ryzyka',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          _buildRiskMetricsGrid(analytics.riskAdjustedMetrics),
        ],
      ),
    );
  }

  Widget _buildRiskMetricsGrid(RiskAdjustedMetrics metrics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _isDesktop ? 3 : (_isTablet ? 2 : 1);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: _isTablet ? 1.5 : 2.0,
          children: [
            MetricCard(
              title: 'Alpha',
              value: metrics.alpha.toStringAsFixed(3),
              icon: Icons.functions,
              color: metrics.alpha >= 0
                  ? AppTheme.successColor
                  : AppTheme.errorColor,
            ),
            MetricCard(
              title: 'Beta',
              value: metrics.beta.toStringAsFixed(3),
              icon: Icons.trending_up,
              color: AppTheme.primaryColor,
            ),
            MetricCard(
              title: 'Information Ratio',
              value: metrics.informationRatio.toStringAsFixed(3),
              icon: Icons.info,
              color: AppTheme.infoColor,
            ),
            MetricCard(
              title: 'Treynor Ratio',
              value: metrics.treynorRatio.toStringAsFixed(3),
              icon: Icons.balance,
              color: AppTheme.secondaryGold,
            ),
            MetricCard(
              title: 'Calmar Ratio',
              value: metrics.calmarRatio.toStringAsFixed(3),
              icon: Icons.security,
              color: AppTheme.warningColor,
            ),
            MetricCard(
              title: 'VaR (95%)',
              value: '${metrics.valueAtRisk95.toStringAsFixed(2)}%',
              icon: Icons.warning,
              color: AppTheme.errorColor,
            ),
          ],
        );
      },
    );
  }
}
