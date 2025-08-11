import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/analytics/overview_analytics_models.dart';

/// Widget karty podsumowania ryzyka
class RiskSummaryCard extends StatelessWidget {
  final RiskMetricsData riskMetrics;

  const RiskSummaryCard({super.key, required this.riskMetrics});

  @override
  Widget build(BuildContext context) {
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
                'Analiza ryzyka',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              _buildRiskLevelIndicator(),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            'Volatilność portfela',
            '${riskMetrics.volatility.toStringAsFixed(2)}%',
            Icons.show_chart,
            _getVolatilityColor(riskMetrics.volatility),
          ),
          _buildStatItem(
            'Sharpe Ratio',
            riskMetrics.sharpeRatio.toStringAsFixed(2),
            Icons.trending_up,
            _getSharpeRatioColor(riskMetrics.sharpeRatio),
          ),
          _buildStatItem(
            'Maksymalny spadek',
            '${riskMetrics.maxDrawdown.toStringAsFixed(1)}%',
            Icons.trending_down,
            _getDrawdownColor(riskMetrics.maxDrawdown),
          ),
          _buildStatItem(
            'Value at Risk (5%)',
            '${riskMetrics.valueAtRisk.toStringAsFixed(1)}%',
            Icons.warning,
            AppTheme.warningColor,
          ),
          _buildStatItem(
            'Indeks dywersyfikacji',
            '${riskMetrics.diversificationIndex.toStringAsFixed(1)}%',
            Icons.pie_chart,
            _getDiversificationColor(riskMetrics.diversificationIndex),
          ),
          const SizedBox(height: 16),
          _buildRiskGauge(),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskLevelIndicator() {
    Color riskColor;
    IconData riskIcon;

    switch (riskMetrics.riskLevel.toLowerCase()) {
      case 'low':
        riskColor = AppTheme.successColor;
        riskIcon = Icons.shield;
        break;
      case 'high':
        riskColor = AppTheme.errorColor;
        riskIcon = Icons.warning;
        break;
      default:
        riskColor = AppTheme.warningColor;
        riskIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(riskIcon, size: 16, color: riskColor),
          const SizedBox(width: 4),
          Text(
            _getRiskLevelText(riskMetrics.riskLevel),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: riskColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskGauge() {
    final concentrationRisk = riskMetrics.concentrationRisk;
    final normalizedRisk = (concentrationRisk / 10000).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ryzyko koncentracji',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(normalizedRisk * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getConcentrationRiskColor(normalizedRisk),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: AppTheme.textTertiary.withValues(alpha: 0.2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: normalizedRisk,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.successColor,
                    AppTheme.warningColor,
                    AppTheme.errorColor,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Niskie',
              style: TextStyle(fontSize: 10, color: AppTheme.textTertiary),
            ),
            Text(
              'Wysokie',
              style: TextStyle(fontSize: 10, color: AppTheme.textTertiary),
            ),
          ],
        ),
      ],
    );
  }

  String _getRiskLevelText(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return 'Niskie';
      case 'high':
        return 'Wysokie';
      default:
        return 'Średnie';
    }
  }

  Color _getVolatilityColor(double volatility) {
    if (volatility < 5) return AppTheme.successColor;
    if (volatility < 15) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  Color _getSharpeRatioColor(double sharpeRatio) {
    if (sharpeRatio > 1) return AppTheme.successColor;
    if (sharpeRatio > 0.5) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  Color _getDrawdownColor(double drawdown) {
    if (drawdown < 5) return AppTheme.successColor;
    if (drawdown < 15) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  Color _getDiversificationColor(double diversification) {
    if (diversification > 50) return AppTheme.successColor;
    if (diversification > 25) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  Color _getConcentrationRiskColor(double normalizedRisk) {
    if (normalizedRisk < 0.3) return AppTheme.successColor;
    if (normalizedRisk < 0.7) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}
