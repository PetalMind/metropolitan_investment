import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';
import '../../../services/analytics/overview_analytics_service.dart';
import '../../../models/analytics/overview_analytics_models.dart';
import '../../../utils/currency_formatter.dart';
import '../widgets/metric_card.dart';
import '../widgets/portfolio_chart.dart';
import '../widgets/performance_chart.dart';
import '../widgets/client_summary_card.dart';
import '../widgets/risk_summary_card.dart';

/// Tab przeglądu z pełną implementacją analityki
class OverviewTab extends StatefulWidget {
  final int selectedTimeRange;

  const OverviewTab({super.key, required this.selectedTimeRange});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  final OverviewAnalyticsService _service = OverviewAnalyticsService();
  OverviewAnalytics? _analytics;
  bool _isLoading = true;
  String? _error;

  // Responsive breakpoints
  bool get _isTablet => MediaQuery.of(context).size.width > 768;
  bool get _isDesktop => MediaQuery.of(context).size.width > 1200;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(OverviewTab oldWidget) {
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

      final analytics = await _service.getOverviewAnalytics(
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
            _buildKeyMetricsGrid(analytics.portfolioMetrics),
            const SizedBox(height: 24),
            _buildChartsRow(analytics),
            const SizedBox(height: 24),
            _buildSummaryRow(analytics),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsGrid(PortfolioMetricsData metrics) {
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
              title: 'Całkowita wartość',
              value: CurrencyFormatter.formatCurrencyShort(metrics.totalValue),
              icon: Icons.account_balance_wallet,
              color: AppTheme.primaryColor,
              change: '+${metrics.growthPercentage.toStringAsFixed(1)}%',
            ),
            MetricCard(
              title: 'Zrealizowany zysk',
              value: CurrencyFormatter.formatCurrencyShort(metrics.totalProfit),
              icon: Icons.trending_up,
              color: AppTheme.successColor,
            ),
            MetricCard(
              title: 'ROI Portfela',
              value: '${metrics.totalROI.toStringAsFixed(2)}%',
              icon: Icons.bar_chart,
              color: AppTheme.infoColor,
            ),
            MetricCard(
              title: 'Aktywne inwestycje',
              value: '${metrics.activeInvestmentsCount}',
              icon: Icons.pie_chart,
              color: AppTheme.secondaryGold,
              subtitle: '${metrics.totalInvestmentsCount} łącznie',
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartsRow(OverviewAnalytics analytics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_isTablet) {
          return Row(
            children: [
              Expanded(
                child: PortfolioChart(
                  productBreakdown: analytics.productBreakdown,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PerformanceChart(
                  monthlyData: analytics.monthlyPerformance,
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              PortfolioChart(productBreakdown: analytics.productBreakdown),
              const SizedBox(height: 16),
              PerformanceChart(monthlyData: analytics.monthlyPerformance),
            ],
          );
        }
      },
    );
  }

  Widget _buildSummaryRow(OverviewAnalytics analytics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_isTablet) {
          return Row(
            children: [
              Expanded(
                child: ClientSummaryCard(
                  clientMetrics: analytics.clientMetrics,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: RiskSummaryCard(riskMetrics: analytics.riskMetrics),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              ClientSummaryCard(clientMetrics: analytics.clientMetrics),
              const SizedBox(height: 16),
              RiskSummaryCard(riskMetrics: analytics.riskMetrics),
            ],
          );
        }
      },
    );
  }
}
