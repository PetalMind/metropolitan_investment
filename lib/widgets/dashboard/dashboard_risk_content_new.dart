import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/advanced_analytics_service.dart';
import '../../theme/app_theme.dart';

class DashboardRiskContent extends StatelessWidget {
  final AdvancedDashboardMetrics? metrics;
  final bool isMobile;
  final double horizontalPadding;

  const DashboardRiskContent({
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
            'Analiza Ryzyka',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildRiskMetrics(context),
          const SizedBox(height: 16),
          _buildRiskDistribution(context),
          const SizedBox(height: 16),
          _buildRiskAnalysis(context),
        ],
      ),
    );
  }

  Widget _buildRiskMetrics(BuildContext context) {
    final riskMetrics = metrics?.riskMetrics;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: AppTheme.warningColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Metryki ryzyka',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isMobile) ...[
            _buildRiskCard(
              context,
              'Zmienność',
              '${(riskMetrics?.volatility ?? 0.0).toStringAsFixed(2)}%',
            ),
            const SizedBox(height: 12),
            _buildRiskCard(
              context,
              'Współczynnik Sharpe',
              (riskMetrics?.sharpeRatio ?? 0.0).toStringAsFixed(3),
            ),
            const SizedBox(height: 12),
            _buildRiskCard(
              context,
              'Maksymalny spadek',
              '${(riskMetrics?.maxDrawdown ?? 0.0).toStringAsFixed(2)}%',
            ),
            const SizedBox(height: 12),
            _buildRiskCard(
              context,
              'Value at Risk',
              '${(riskMetrics?.valueAtRisk ?? 0.0).toStringAsFixed(2)}%',
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildRiskCard(
                    context,
                    'Zmienność',
                    '${(riskMetrics?.volatility ?? 0.0).toStringAsFixed(2)}%',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRiskCard(
                    context,
                    'Współczynnik Sharpe',
                    (riskMetrics?.sharpeRatio ?? 0.0).toStringAsFixed(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRiskCard(
                    context,
                    'Maksymalny spadek',
                    '${(riskMetrics?.maxDrawdown ?? 0.0).toStringAsFixed(2)}%',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRiskCard(
                    context,
                    'Value at Risk',
                    '${(riskMetrics?.valueAtRisk ?? 0.0).toStringAsFixed(2)}%',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskCard(BuildContext context, String title, String value) {
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
              color: AppTheme.warningColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskDistribution(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: AppTheme.infoColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Rozkład ryzyka',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 250,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sections: _getRiskSections(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRiskLegendItem(
                        context,
                        'Niskie ryzyko',
                        AppTheme.successColor,
                        '30%',
                      ),
                      const SizedBox(height: 8),
                      _buildRiskLegendItem(
                        context,
                        'Średnie ryzyko',
                        AppTheme.warningColor,
                        '50%',
                      ),
                      const SizedBox(height: 8),
                      _buildRiskLegendItem(
                        context,
                        'Wysokie ryzyko',
                        AppTheme.errorColor,
                        '20%',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskLegendItem(
    BuildContext context,
    String label,
    Color color,
    String percentage,
  ) {
    return Row(
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
          percentage,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  List<PieChartSectionData> _getRiskSections() {
    return [
      PieChartSectionData(
        value: 30,
        title: '30%',
        color: AppTheme.successColor,
        radius: 50,
      ),
      PieChartSectionData(
        value: 50,
        title: '50%',
        color: AppTheme.warningColor,
        radius: 50,
      ),
      PieChartSectionData(
        value: 20,
        title: '20%',
        color: AppTheme.errorColor,
        radius: 50,
      ),
    ];
  }

  Widget _buildRiskAnalysis(BuildContext context) {
    final riskMetrics = metrics?.riskMetrics;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Dodatkowe metryki ryzyka',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAnalysisItem(
            context,
            'Ryzyko koncentracji',
            '${(riskMetrics?.concentrationRisk ?? 0.0).toStringAsFixed(2)}%',
          ),
          const SizedBox(height: 8),
          _buildAnalysisItem(
            context,
            'Współczynnik dywersyfikacji',
            (riskMetrics?.diversificationRatio ?? 0.0).toStringAsFixed(3),
          ),
          const SizedBox(height: 8),
          _buildAnalysisItem(
            context,
            'Ryzyko płynności',
            '${(riskMetrics?.liquidityRisk ?? 0.0).toStringAsFixed(2)}%',
          ),
          const SizedBox(height: 8),
          _buildAnalysisItem(
            context,
            'Ryzyko kredytowe',
            '${(riskMetrics?.creditRisk ?? 0.0).toStringAsFixed(2)}%',
          ),
          const SizedBox(height: 8),
          _buildAnalysisItem(
            context,
            'Beta',
            (riskMetrics?.beta ?? 0.0).toStringAsFixed(3),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderSecondary),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
