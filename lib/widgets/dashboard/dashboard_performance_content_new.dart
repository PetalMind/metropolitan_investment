import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/advanced_analytics_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';

class DashboardPerformanceContent extends StatelessWidget {
  final AdvancedDashboardMetrics? metrics;
  final bool isMobile;
  final double horizontalPadding;

  const DashboardPerformanceContent({
    super.key,
    required this.metrics,
    required this.isMobile,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analiza Wydajności',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPerformanceMetrics(context),
          const SizedBox(height: 16),
          _buildReturnChart(context),
          const SizedBox(height: 16),
          _buildPerformanceByProduct(context),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(BuildContext context) {
    final performance = metrics?.performanceMetrics;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppTheme.successColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Metryki wydajności',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isMobile) ...[
            _buildPerformanceCard(
              context,
              'Średni zwrot',
              '${(performance?.averageReturn ?? 0.0).toStringAsFixed(2)}%',
            ),
            const SizedBox(height: 12),
            _buildPerformanceCard(
              context,
              'Wskaźnik sukcesu',
              '${(performance?.successRate ?? 0.0).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            _buildPerformanceCard(
              context,
              'Alpha',
              (performance?.alpha ?? 0.0).toStringAsFixed(3),
            ),
            const SizedBox(height: 12),
            _buildPerformanceCard(
              context,
              'Beta',
              (performance?.beta ?? 0.0).toStringAsFixed(3),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceCard(
                    context,
                    'Średni zwrot',
                    '${(performance?.averageReturn ?? 0.0).toStringAsFixed(2)}%',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPerformanceCard(
                    context,
                    'Wskaźnik sukcesu',
                    '${(performance?.successRate ?? 0.0).toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceCard(
                    context,
                    'Alpha',
                    (performance?.alpha ?? 0.0).toStringAsFixed(3),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPerformanceCard(
                    context,
                    'Beta',
                    (performance?.beta ?? 0.0).toStringAsFixed(3),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(
    BuildContext context,
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnChart(BuildContext context) {
    if (metrics?.timeSeriesAnalytics.monthlyData == null ||
        metrics!.timeSeriesAnalytics.monthlyData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration,
        child: Text('Brak danych do wykresu'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: AppTheme.infoColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Wykres zwrotów w czasie',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(show: true),
                borderData: FlBorderData(show: true),
                maxX:
                    metrics!.timeSeriesAnalytics.monthlyData.length.toDouble() -
                    1,
                minY:
                    metrics!.timeSeriesAnalytics.monthlyData
                        .map((e) => e.averageReturn)
                        .reduce((a, b) => a < b ? a : b) -
                    1,
                maxY:
                    metrics!.timeSeriesAnalytics.monthlyData
                        .map((e) => e.averageReturn)
                        .reduce((a, b) => a > b ? a : b) +
                    1,
                lineBarsData: [
                  LineChartBarData(
                    spots: metrics!.timeSeriesAnalytics.monthlyData
                        .asMap()
                        .entries
                        .map((entry) {
                          return FlSpot(
                            entry.key.toDouble(),
                            entry.value.averageReturn,
                          );
                        })
                        .toList(),
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceByProduct(BuildContext context) {
    final productPerformance = metrics?.productAnalytics.productPerformance;

    if (productPerformance == null || productPerformance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration,
        child: Text('Brak danych o wydajności produktów'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppTheme.warningColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Wydajność według produktów',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...productPerformance.entries.map((entry) {
            final productType = entry.key;
            final performance = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderPrimary),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getProductTypeName(productType.toString()),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Wartość: ${CurrencyFormatter.formatCurrency(performance.totalValue)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${performance.averageReturn.toStringAsFixed(2)}%',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: performance.averageReturn >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                        ),
                        Text(
                          '${performance.count} inwest.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  String _getProductTypeName(String productType) {
    switch (productType.toLowerCase()) {
      case 'bonds':
        return 'Obligacje';
      case 'shares':
        return 'Udziały';
      case 'loans':
        return 'Pożyczki';
      default:
        return productType;
    }
  }
}
