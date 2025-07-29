import 'package:flutter/material.dart';
import '../../services/advanced_analytics_service.dart';
import '../../theme/app_theme.dart';

class DashboardPerformanceContent extends StatelessWidget {
  final AdvancedDashboardMetrics? metrics;
  final bool isMobile;
  final double horizontalPadding;
  final BuildContext context;

  const DashboardPerformanceContent({
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
            'Analiza Wydajności',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPerformanceMetrics(),
          const SizedBox(height: 16),
          _buildReturnChart(),
          const SizedBox(height: 16),
          _buildPerformanceByProduct(),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    final performance = metrics?.performanceMetrics;
    
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
            'Kluczowe Wskaźniki Wydajności',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (isMobile) ...[
            _buildMetricCard('Zwrot roczny', '${performance?.annualizedReturn.toStringAsFixed(2) ?? '0.00'}%', Icons.trending_up),
            const SizedBox(height: 12),
            _buildMetricCard('Średni zwrot', '${performance?.averageReturn.toStringAsFixed(2) ?? '0.00'}%', Icons.analytics),
            const SizedBox(height: 12),
            _buildMetricCard('Współczynnik sukcesu', '${performance?.successRate.toStringAsFixed(2) ?? '0.00'}%', Icons.calendar_today),
          ] else ...[
            Row(
              children: [
                Expanded(child: _buildMetricCard('Zwrot roczny', '${performance?.annualizedReturn.toStringAsFixed(2) ?? '0.00'}%', Icons.trending_up)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard('Średni zwrot', '${performance?.averageReturn.toStringAsFixed(2) ?? '0.00'}%', Icons.analytics)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard('Współczynnik sukcesu', '${performance?.successRate.toStringAsFixed(2) ?? '0.00'}%', Icons.calendar_today)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnChart() {
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
            'Wykres Zwrotów w Czasie',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: Center(
              child: Text(
                'Wykres zwrotów będzie wyświetlony po implementacji danych',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceByProduct() {
    final productPerformance = metrics?.performanceMetrics.productPerformance;
    
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
            'Wydajność według Produktu',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (productPerformance == null || productPerformance.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Brak danych o wydajności produktów',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...productPerformance.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${entry.value >= 0 ? '+' : ''}${entry.value.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: entry.value >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
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
}

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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPerformanceMetrics(),
          const SizedBox(height: 16),
          _buildReturnChart(),
          const SizedBox(height: 16),
          _buildPerformanceByProduct(),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    final performance = metrics?.performanceMetrics;
    
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
            'Kluczowe Wskaźniki Wydajności',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (isMobile) ...[
            _buildMetricCard('Zwrot roczny', '${performance?.annualizedReturn.toStringAsFixed(2) ?? '0.00'}%', Icons.trending_up),
            const SizedBox(height: 12),
            _buildMetricCard('Zwrot całkowity', '${performance?.totalReturn.toStringAsFixed(2) ?? '0.00'}%', Icons.analytics),
            const SizedBox(height: 12),
            _buildMetricCard('Zwrot miesięczny', '${performance?.monthlyReturn.toStringAsFixed(2) ?? '0.00'}%', Icons.calendar_today),
          ] else ...[
            Row(
              children: [
                Expanded(child: _buildMetricCard('Zwrot roczny', '${performance?.annualizedReturn.toStringAsFixed(2) ?? '0.00'}%', Icons.trending_up)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard('Zwrot całkowity', '${performance?.totalReturn.toStringAsFixed(2) ?? '0.00'}%', Icons.analytics)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard('Zwrot miesięczny', '${performance?.monthlyReturn.toStringAsFixed(2) ?? '0.00'}%', Icons.calendar_today)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnChart() {
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
            'Wykres Zwrotów w Czasie',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: Center(
              child: Text(
                'Wykres zwrotów będzie wyświetlony po implementacji danych',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceByProduct() {
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
            'Wydajność według Produktu',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Analiza wydajności według produktów będzie wyświetlona po implementacji danych',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
