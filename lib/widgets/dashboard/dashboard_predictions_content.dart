import 'package:flutter/material.dart';
import '../../services/advanced_analytics_service.dart';
import '../../theme/app_theme.dart';

class DashboardPredictionsContent extends StatelessWidget {
  final AdvancedDashboardMetrics? metrics;
  final bool isMobile;
  final double horizontalPadding;
  final BuildContext context;

  const DashboardPredictionsContent({
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
            'Prognozy i Symulacje',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPredictionModels(),
          const SizedBox(height: 16),
          _buildForecastChart(),
          const SizedBox(height: 16),
          _buildScenarioAnalysis(),
        ],
      ),
    );
  }

  Widget _buildPredictionModels() {
    final predictions = metrics?.predictionMetrics;

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
            'Modele Predykcyjne',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (isMobile) ...[
            _buildPredictionCard(
              'Prognoza 1M',
              '${predictions?.predictions['1M']?.toStringAsFixed(2) ?? '0.00'}%',
              Icons.calendar_today,
            ),
            const SizedBox(height: 12),
            _buildPredictionCard(
              'Prognoza 3M',
              '${predictions?.predictions['3M']?.toStringAsFixed(2) ?? '0.00'}%',
              Icons.calendar_month,
            ),
            const SizedBox(height: 12),
            _buildPredictionCard(
              'Prognoza 12M',
              '${predictions?.predictions['12M']?.toStringAsFixed(2) ?? '0.00'}%',
              Icons.calendar_view_year,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildPredictionCard(
                    'Prognoza 1M',
                    '${predictions?.predictions['1M']?.toStringAsFixed(2) ?? '0.00'}%',
                    Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPredictionCard(
                    'Prognoza 3M',
                    '${predictions?.predictions['3M']?.toStringAsFixed(2) ?? '0.00'}%',
                    Icons.calendar_month,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPredictionCard(
                    'Prognoza 12M',
                    '${predictions?.predictions['12M']?.toStringAsFixed(2) ?? '0.00'}%',
                    Icons.calendar_view_year,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPredictionCard(String title, String value, IconData icon) {
    final numValue = double.tryParse(value.replaceAll('%', '')) ?? 0.0;
    final color = numValue >= 0 ? Colors.green : Colors.red;

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
              Icon(icon, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
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

  Widget _buildForecastChart() {
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
            'Wykres Prognoz',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insights,
                    size: 48,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Wykres prognoz będzie wyświetlony po implementacji modeli AI',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioAnalysis() {
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
            'Analiza Scenariuszy',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildScenarioCard(
            'Scenariusz Optymistyczny',
            '+15.2%',
            Colors.green,
            Icons.trending_up,
          ),
          const SizedBox(height: 12),
          _buildScenarioCard(
            'Scenariusz Bazowy',
            '+8.5%',
            Colors.blue,
            Icons.trending_flat,
          ),
          const SizedBox(height: 12),
          _buildScenarioCard(
            'Scenariusz Pesymistyczny',
            '-3.2%',
            Colors.red,
            Icons.trending_down,
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
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
    );
  }
}
