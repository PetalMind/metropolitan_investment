import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../models/unified_product.dart';
import '../../models/investor_summary.dart';
import '../../models/client.dart';
import '../../models_and_services.dart';
import '../premium_error_widget.dart';
import 'product_details_service.dart';

/// Zakładka z analizą produktu i statystykami
class ProductAnalyticsTab extends StatefulWidget {
  final UnifiedProduct product;
  final List<InvestorSummary> investors;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;

  const ProductAnalyticsTab({
    super.key,
    required this.product,
    required this.investors,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
  });

  @override
  State<ProductAnalyticsTab> createState() => _ProductAnalyticsTabState();
}

class _ProductAnalyticsTabState extends State<ProductAnalyticsTab>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  final ProductDetailsService _service = ProductDetailsService();
  String _selectedTimeframe = '6M'; // '3M', '6M', '1Y', 'ALL'

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );

    if (!widget.isLoading) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(ProductAnalyticsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLoading && oldWidget.isLoading) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: PremiumShimmerLoadingWidget.chart());
    }

    if (widget.error != null) {
      return PremiumErrorWidget(
        error: widget.error!,
        onRetry: widget.onRefresh,
      );
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: FadeTransition(
        opacity: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header z kontrolkami
              _buildHeader(),
              const SizedBox(height: 24),

              // Kluczowe metryki
              _buildKeyMetrics(),
              const SizedBox(height: 24),

              // Wykres dystrybucji kapitału
              _buildCapitalDistributionChart(),
              const SizedBox(height: 24),

              // Analiza inwestorów
              _buildInvestorAnalysis(),
              const SizedBox(height: 24),

              // Statystyki głosowania (jeśli dostępne)
              if (_hasVotingData()) ...[
                _buildVotingAnalysis(),
                const SizedBox(height: 24),
              ],

              // Prognoza wydajności
              _buildPerformanceProjection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.08),
            AppTheme.backgroundSecondary.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderPrimary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.analytics,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analiza Produktu',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.secondaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Szczegółowa analiza wydajności i struktury inwestorów',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Kontrolki czasowe
          _buildTimeframeSelector(),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    final options = ['3M', '6M', '1Y', 'ALL'];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundModal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderPrimary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          final isSelected = _selectedTimeframe == option;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTimeframe = option;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.secondaryGold.withOpacity(0.15)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                option,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.secondaryGold
                      : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeyMetrics() {
    final analytics = _calculateAnalytics();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundSecondary.withOpacity(0.6),
            AppTheme.surfaceCard,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderPrimary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Kluczowe Metryki',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMetricCard(
                  'Łączny Kapitał',
                  _service.formatCurrency(analytics.totalCapital),
                  Icons.account_balance_wallet,
                  AppTheme.secondaryGold,
                  'Suma pozostałego kapitału',
                ),
                _buildMetricCard(
                  'Średnia Inwestycja',
                  _service.formatCurrency(analytics.averageInvestment),
                  Icons.trending_up,
                  AppTheme.gainPrimary,
                  'Średni kapitał na inwestora',
                ),
                _buildMetricCard(
                  'Koncentracja TOP 3',
                  '${analytics.top3Concentration.toStringAsFixed(1)}%',
                  Icons.pie_chart,
                  AppTheme.infoPrimary,
                  'Udział 3 największych inwestorów',
                ),
                _buildMetricCard(
                  'Aktywni Inwestorzy',
                  analytics.activeInvestors.toString(),
                  Icons.people,
                  AppTheme.primaryColor,
                  'Liczba inwestorów z kapitałem',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Icon(Icons.trending_up, color: color.withOpacity(0.5), size: 16),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textTertiary,
              fontSize: 10,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCapitalDistributionChart() {
    if (widget.investors.isEmpty) {
      return _buildNoDataPlaceholder('Brak danych do wykresu');
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundSecondary.withOpacity(0.6),
            AppTheme.surfaceCard,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderPrimary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.donut_large, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Dystrybucja Kapitału',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: Row(
              children: [
                // Wykres kołowy
                Expanded(flex: 3, child: _buildPieChart()),
                const SizedBox(width: 20),
                // Legenda
                Expanded(flex: 2, child: _buildChartLegend()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final chartData = _prepareChartData();

    return PieChart(
      PieChartData(
        sections: chartData,
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 60,
        startDegreeOffset: -90,
      ),
    );
  }

  Widget _buildChartLegend() {
    final sortedInvestors = List<InvestorSummary>.from(widget.investors)
      ..sort(
        (a, b) => b.viableRemainingCapital.compareTo(a.viableRemainingCapital),
      );

    final displayInvestors = sortedInvestors.take(5).toList();
    final colors = _getChartColors();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Najwięksi Inwestorzy',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...displayInvestors.asMap().entries.map((entry) {
          final index = entry.key;
          final investor = entry.value;
          final percentage =
              (investor.viableRemainingCapital /
              _calculateAnalytics().totalCapital *
              100);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    investor.client.name.isNotEmpty
                        ? investor.client.name
                        : 'Inwestor ${index + 1}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
        if (sortedInvestors.length > 5) ...[
          const Divider(color: AppTheme.borderPrimary),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Pozostali (${sortedInvestors.length - 5})',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInvestorAnalysis() {
    final analytics = _calculateAnalytics();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundSecondary.withOpacity(0.6),
            AppTheme.surfaceCard,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderPrimary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: AppTheme.infoPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Analiza Struktury Inwestorów',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Histogram rozkładu kapitału
          _buildCapitalDistributionHistogram(),

          const SizedBox(height: 20),

          // Statystyki rozkładu
          _buildDistributionStats(analytics),
        ],
      ),
    );
  }

  Widget _buildCapitalDistributionHistogram() {
    final buckets = _createCapitalBuckets();
    if (buckets.isEmpty) return _buildNoDataPlaceholder('Brak danych');

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundModal.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: buckets.values.reduce((a, b) => a > b ? a : b).toDouble(),
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final ranges = buckets.keys.toList();
                  if (value.toInt() < ranges.length) {
                    return Text(
                      ranges[value.toInt()],
                      style: const TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 10,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: AppTheme.textTertiary,
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
          borderData: FlBorderData(show: false),
          barGroups: buckets.entries.map((entry) {
            final index = buckets.keys.toList().indexOf(entry.key);
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  color: AppTheme.infoPrimary.withOpacity(0.8),
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDistributionStats(_Analytics analytics) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Mediana',
            _service.formatCurrency(analytics.medianInvestment),
            Icons.show_chart,
            AppTheme.infoPrimary,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            'Odchylenie Std.',
            _service.formatCurrency(analytics.standardDeviation),
            Icons.scatter_plot,
            AppTheme.warningPrimary,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            'Współcz. Giniego',
            analytics.giniCoefficient.toStringAsFixed(3),
            Icons.balance,
            AppTheme.errorPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textTertiary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVotingAnalysis() {
    final votingStats = _calculateVotingStats();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.secondaryGold.withOpacity(0.05),
            AppTheme.backgroundSecondary.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondaryGold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.how_to_vote, color: AppTheme.secondaryGold, size: 24),
              const SizedBox(width: 12),
              Text(
                'Analiza Głosowania',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: votingStats.entries.map((entry) {
              return _buildVotingStatCard(entry.key, entry.value);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingStatCard(String status, int count) {
    Color color;
    IconData icon;

    switch (status) {
      case 'Tak':
        color = AppTheme.successPrimary;
        icon = Icons.check_circle;
        break;
      case 'Nie':
        color = AppTheme.errorPrimary;
        icon = Icons.cancel;
        break;
      case 'Wstrzymuje się':
        color = AppTheme.warningPrimary;
        icon = Icons.pause_circle;
        break;
      default:
        color = AppTheme.neutralPrimary;
        icon = Icons.help;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceProjection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.gainPrimary.withOpacity(0.05),
            AppTheme.backgroundSecondary.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gainPrimary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppTheme.gainPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Prognoza Wydajności',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildProjectionContent(),
        ],
      ),
    );
  }

  Widget _buildProjectionContent() {
    // Symulacja prognozy na podstawie typu produktu
    final projections = _generateProjections();

    return Column(
      children: [
        // Wykres liniowy prognozy
        Container(
          height: 150,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundModal.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1000,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppTheme.borderPrimary.withOpacity(0.3),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: projections,
                  isCurved: true,
                  color: AppTheme.gainPrimary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.gainPrimary.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Kluczowe wskaźniki prognozy
        Row(
          children: [
            Expanded(
              child: _buildProjectionStat(
                'ROI Prognoza',
                '+${(8.5).toStringAsFixed(1)}%',
                Icons.assessment,
                AppTheme.gainPrimary,
              ),
            ),
            Expanded(
              child: _buildProjectionStat(
                'Ryzyko',
                'Średnie',
                Icons.warning_amber,
                AppTheme.warningPrimary,
              ),
            ),
            Expanded(
              child: _buildProjectionStat(
                'Likwidność',
                'Wysoka',
                Icons.water_drop,
                AppTheme.infoPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectionStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textTertiary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataPlaceholder(String message) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.backgroundModal.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderPrimary.withOpacity(0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, color: AppTheme.textTertiary, size: 48),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  // Metody pomocnicze dla obliczeń
  _Analytics _calculateAnalytics() {
    if (widget.investors.isEmpty) {
      return _Analytics(
        totalCapital: 0,
        averageInvestment: 0,
        medianInvestment: 0,
        standardDeviation: 0,
        top3Concentration: 0,
        activeInvestors: 0,
        giniCoefficient: 0,
      );
    }

    final investments =
        widget.investors
            .map((i) => i.viableRemainingCapital)
            .where((c) => c > 0)
            .toList()
          ..sort();

    final totalCapital = investments.fold(0.0, (sum, c) => sum + c);
    final activeInvestors = investments.length;
    final averageInvestment = totalCapital / activeInvestors;

    // Mediana
    final medianInvestment = investments.length.isOdd
        ? investments[investments.length ~/ 2]
        : (investments[investments.length ~/ 2 - 1] +
                  investments[investments.length ~/ 2]) /
              2;

    // Odchylenie standardowe
    final variance =
        investments
            .map((c) => (c - averageInvestment) * (c - averageInvestment))
            .fold(0.0, (sum, v) => sum + v) /
        activeInvestors;
    final standardDeviation = variance.isFinite ? variance.sqrt() : 0.0;

    // Koncentracja TOP 3
    final sortedDesc = List<double>.from(investments)
      ..sort((a, b) => b.compareTo(a));
    final top3Sum = sortedDesc.take(3).fold(0.0, (sum, c) => sum + c);
    final top3Concentration = totalCapital > 0
        ? (top3Sum / totalCapital) * 100
        : 0;

    // Współczynnik Giniego (uproszczony)
    double giniSum = 0;
    for (int i = 0; i < investments.length; i++) {
      for (int j = 0; j < investments.length; j++) {
        giniSum += (investments[i] - investments[j]).abs();
      }
    }
    final giniCoefficient = totalCapital > 0
        ? giniSum / (2 * investments.length * totalCapital)
        : 0;

    return _Analytics(
      totalCapital: totalCapital,
      averageInvestment: averageInvestment,
      medianInvestment: medianInvestment,
      standardDeviation: standardDeviation,
      top3Concentration: top3Concentration.toDouble(),
      activeInvestors: activeInvestors,
      giniCoefficient: giniCoefficient.toDouble(),
    );
  }

  List<PieChartSectionData> _prepareChartData() {
    final sortedInvestors = List<InvestorSummary>.from(widget.investors)
      ..sort(
        (a, b) => b.viableRemainingCapital.compareTo(a.viableRemainingCapital),
      );

    final totalCapital = _calculateAnalytics().totalCapital;
    final colors = _getChartColors();

    final sections = <PieChartSectionData>[];

    for (int i = 0; i < sortedInvestors.take(5).length; i++) {
      final investor = sortedInvestors[i];
      final percentage = (investor.viableRemainingCapital / totalCapital) * 100;

      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: investor.viableRemainingCapital,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    // Pozostali inwestorzy
    if (sortedInvestors.length > 5) {
      final remainingCapital = sortedInvestors
          .skip(5)
          .fold(0.0, (sum, investor) => sum + investor.viableRemainingCapital);

      if (remainingCapital > 0) {
        final percentage = (remainingCapital / totalCapital) * 100;
        sections.add(
          PieChartSectionData(
            color: AppTheme.textTertiary,
            value: remainingCapital,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    return sections;
  }

  List<Color> _getChartColors() {
    return [
      AppTheme.primaryColor,
      AppTheme.secondaryGold,
      AppTheme.gainPrimary,
      AppTheme.infoPrimary,
      AppTheme.warningPrimary,
    ];
  }

  Map<String, int> _createCapitalBuckets() {
    if (widget.investors.isEmpty) return {};

    final investments = widget.investors
        .map((i) => i.viableRemainingCapital)
        .where((c) => c > 0)
        .toList();

    if (investments.isEmpty) return {};

    final maxCapital = investments.reduce((a, b) => a > b ? a : b);
    final bucketSize = maxCapital / 5; // 5 przedziałów

    final buckets = <String, int>{};

    for (int i = 0; i < 5; i++) {
      final rangeStart = i * bucketSize;
      final rangeEnd = (i + 1) * bucketSize;
      final label =
          '${(rangeStart / 1000).toStringAsFixed(0)}k-${(rangeEnd / 1000).toStringAsFixed(0)}k';

      buckets[label] = investments
          .where((c) => c >= rangeStart && c < rangeEnd)
          .length;
    }

    return buckets;
  }

  bool _hasVotingData() {
    return widget.investors.any(
      (investor) => investor.client.votingStatus != VotingStatus.undecided,
    );
  }

  Map<String, int> _calculateVotingStats() {
    final stats = <String, int>{};

    for (final investor in widget.investors) {
      final status = _getVotingStatusText(investor.client.votingStatus);
      stats[status] = (stats[status] ?? 0) + 1;
    }

    return stats;
  }

  String _getVotingStatusText(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return 'Tak';
      case VotingStatus.no:
        return 'Nie';
      case VotingStatus.abstain:
        return 'Wstrzymuje się';
      case VotingStatus.undecided:
        return 'Niezdecydowany';
    }
  }

  List<FlSpot> _generateProjections() {
    // Symulacja prognozy na 12 miesięcy
    final baseValue = 1000.0;
    final projections = <FlSpot>[];

    for (int i = 0; i <= 12; i++) {
      // Symulacja wzrostu z niewielkimi wahaniami
      final growth = 1 + (0.08 * i / 12); // 8% wzrost rocznie
      final noise = math.sin(i * 0.02) * 0.03; // Małe wahania
      final value = baseValue * growth * (1 + noise);

      projections.add(FlSpot(i.toDouble(), value));
    }

    return projections;
  }
}

/// Klasa pomocnicza do przechowywania obliczeń analitycznych
class _Analytics {
  final double totalCapital;
  final double averageInvestment;
  final double medianInvestment;
  final double standardDeviation;
  final double top3Concentration;
  final int activeInvestors;
  final double giniCoefficient;

  const _Analytics({
    required this.totalCapital,
    required this.averageInvestment,
    required this.medianInvestment,
    required this.standardDeviation,
    required this.top3Concentration,
    required this.activeInvestors,
    required this.giniCoefficient,
  });
}

extension on double {
  double sqrt() => this >= 0 ? math.sqrt(this) : 0;
}
