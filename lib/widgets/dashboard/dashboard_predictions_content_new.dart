import 'package:flutter/material.dart';
import '../../services/advanced_analytics_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';

class DashboardPredictionsContent extends StatelessWidget {
  final AdvancedDashboardMetrics? metrics;
  final bool isMobile;
  final double horizontalPadding;

  const DashboardPredictionsContent({
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
            'Prognozy i Symulacje',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPredictionModels(context),
          const SizedBox(height: 16),
          _buildForecastChart(context),
          const SizedBox(height: 16),
          _buildScenarioAnalysis(context),
        ],
      ),
    );
  }

  Widget _buildPredictionModels(BuildContext context) {
    final predictions = metrics?.predictionMetrics;

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
                'Modele predykcyjne',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isMobile) ...[
            _buildPredictionCard(
              context,
              'Prognozowane zwroty',
              '${(predictions?.projectedReturns ?? 0.0).toStringAsFixed(2)}%',
              Icons.show_chart,
            ),
            const SizedBox(height: 12),
            _buildPredictionCard(
              context,
              'Oczekiwana wartość przy zapadaniu',
              CurrencyFormatter.formatCurrency(
                predictions?.expectedMaturityValue ?? 0.0,
              ),
              Icons.savings,
            ),
            const SizedBox(height: 12),
            _buildPredictionCard(
              context,
              'Zwroty skorygowane o ryzyko',
              '${(predictions?.riskAdjustedReturns ?? 0.0).toStringAsFixed(2)}%',
              Icons.security,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildPredictionCard(
                    context,
                    'Prognozowane zwroty',
                    '${(predictions?.projectedReturns ?? 0.0).toStringAsFixed(2)}%',
                    Icons.show_chart,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPredictionCard(
                    context,
                    'Oczekiwana wartość przy zapadaniu',
                    CurrencyFormatter.formatCurrency(
                      predictions?.expectedMaturityValue ?? 0.0,
                    ),
                    Icons.savings,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPredictionCard(
              context,
              'Zwroty skorygowane o ryzyko',
              '${(predictions?.riskAdjustedReturns ?? 0.0).toStringAsFixed(2)}%',
              Icons.security,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPredictionCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderPrimary),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: AppTheme.infoColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Wykres prognoz',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderPrimary),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insert_chart,
                    size: 48,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Wykres prognoz zostanie wyświetlony tutaj',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
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

  Widget _buildScenarioAnalysis(BuildContext context) {
    final predictions = metrics?.predictionMetrics;

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
                'Analiza scenariuszy',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildScenarioItem(
            context,
            'Scenariusz optymistyczny',
            '${((predictions?.projectedReturns ?? 0.0) * 1.2).toStringAsFixed(2)}%',
            AppTheme.successColor,
          ),
          const SizedBox(height: 12),
          _buildScenarioItem(
            context,
            'Scenariusz bazowy',
            '${(predictions?.projectedReturns ?? 0.0).toStringAsFixed(2)}%',
            AppTheme.infoColor,
          ),
          const SizedBox(height: 12),
          _buildScenarioItem(
            context,
            'Scenariusz pesymistyczny',
            '${((predictions?.projectedReturns ?? 0.0) * 0.7).toStringAsFixed(2)}%',
            AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          Container(
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
                  'Optymalizacja portfela',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  predictions?.portfolioOptimization ?? 'Brak rekomendacji',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderPrimary),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
