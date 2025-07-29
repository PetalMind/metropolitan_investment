import 'package:flutter/material.dart';
import '../../services/advanced_analytics_service.dart';
import '../../theme/app_theme.dart';

class DashboardRiskContent extends StatelessWidget {
  final AdvancedDashboardMetrics? metrics;
  final bool isMobile;
  final double horizontalPadding;
  final BuildContext context;

  const DashboardRiskContent({
    super.key,
    required this.metrics,
    required this.isMobile,
    required this.horizontalPadding,
    required this.context,
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
          _buildRiskMetrics(),
          const SizedBox(height: 16),
          _buildRiskDistribution(),
          const SizedBox(height: 16),
          _buildCorrelationMatrix(),
        ],
      ),
    );
  }

  Widget _buildRiskMetrics() {
    final risk = metrics?.riskMetrics;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wskaźniki Ryzyka',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (isMobile) ...[
            _buildRiskCard(
              'Wskaźnik Sharpe\'a',
              '${risk?.sharpeRatio.toStringAsFixed(2) ?? '0.00'}',
              Icons.trending_up,
              _getSharpeColor(risk?.sharpeRatio ?? 0.0),
            ),
            const SizedBox(height: 12),
            _buildRiskCard(
              'Zmienność',
              '${risk?.volatility.toStringAsFixed(2) ?? '0.00'}%',
              Icons.analytics,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildRiskCard(
              'VaR (95%)',
              '${risk?.valueAtRisk.toStringAsFixed(2) ?? '0.00'}%',
              Icons.warning,
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildRiskCard(
              'Maksymalny spadek',
              '${risk?.maxDrawdown.toStringAsFixed(2) ?? '0.00'}%',
              Icons.trending_down,
              Colors.red,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildRiskCard(
                    'Wskaźnik Sharpe\'a',
                    '${risk?.sharpeRatio.toStringAsFixed(2) ?? '0.00'}',
                    Icons.trending_up,
                    _getSharpeColor(risk?.sharpeRatio ?? 0.0),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRiskCard(
                    'Zmienność',
                    '${risk?.volatility.toStringAsFixed(2) ?? '0.00'}%',
                    Icons.analytics,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRiskCard(
                    'VaR (95%)',
                    '${risk?.valueAtRisk.toStringAsFixed(2) ?? '0.00'}%',
                    Icons.warning,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRiskCard(
                    'Maksymalny spadek',
                    '${risk?.maxDrawdown.toStringAsFixed(2) ?? '0.00'}%',
                    Icons.trending_down,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskDistribution() {
    final riskDistribution = metrics?.riskMetrics.riskDistribution;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rozkład Ryzyka według Produktów',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (riskDistribution == null || riskDistribution.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Brak danych o rozkładzie ryzyka',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...riskDistribution.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${entry.value.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: entry.value / 100,
                      backgroundColor: AppTheme.borderSecondary,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getRiskColor(entry.value),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildCorrelationMatrix() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macierz Korelacji',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Macierz korelacji między produktami będzie wyświetlona po implementacji danych',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSharpeColor(double sharpe) {
    if (sharpe > 1.0) return Colors.green;
    if (sharpe > 0.5) return Colors.orange;
    return Colors.red;
  }

  Color _getRiskColor(double risk) {
    if (risk > 75) return Colors.red;
    if (risk > 50) return Colors.orange;
    if (risk > 25) return Colors.yellow;
    return Colors.green;
  }
}
