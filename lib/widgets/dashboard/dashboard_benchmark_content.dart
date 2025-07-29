import 'package:flutter/material.dart';
import '../../services/advanced_analytics_service.dart';
import '../../theme/app_theme.dart';

class DashboardBenchmarkContent extends StatelessWidget {
  final AdvancedDashboardMetrics? metrics;
  final bool isMobile;
  final double horizontalPadding;
  final BuildContext context;

  const DashboardBenchmarkContent({
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
            'Porównanie z Benchmarkami',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildBenchmarkComparison(),
          const SizedBox(height: 16),
          _buildRelativePerformance(),
          const SizedBox(height: 16),
          _buildMarketIndices(),
        ],
      ),
    );
  }

  Widget _buildBenchmarkComparison() {
    // final benchmarks = metrics?.benchmarkMetrics; // Usunięte bo nie jest używane

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
            'Porównanie Głównych Wskaźników',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildBenchmarkCard('WIG20', '+12.5%', '+8.5%', true),
          const SizedBox(height: 12),
          _buildBenchmarkCard('S&P 500', '+15.2%', '+8.5%', false),
          const SizedBox(height: 12),
          _buildBenchmarkCard('EURO STOXX 50', '+9.8%', '+8.5%', false),
          const SizedBox(height: 12),
          _buildBenchmarkCard('Obligacje 10Y', '+4.2%', '+8.5%', true),
        ],
      ),
    );
  }

  Widget _buildBenchmarkCard(
    String name,
    String benchmarkReturn,
    String portfolioReturn,
    bool outperforming,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: outperforming
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Benchmark',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  benchmarkReturn,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Portfel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  portfolioReturn,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: outperforming ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            outperforming ? Icons.arrow_upward : Icons.arrow_downward,
            color: outperforming ? Colors.green : Colors.red,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildRelativePerformance() {
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
            'Względna Wydajność',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.compare_arrows,
                    size: 48,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Wykres względnej wydajności będzie wyświetlony po implementacji danych',
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

  Widget _buildMarketIndices() {
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
            'Indeksy Rynkowe',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (isMobile) ...[
            _buildIndexCard('WIG20', '2,245.67', '+1.2%', true),
            const SizedBox(height: 12),
            _buildIndexCard('S&P 500', '4,567.89', '+0.8%', true),
            const SizedBox(height: 12),
            _buildIndexCard('NASDAQ', '14,234.56', '-0.3%', false),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildIndexCard('WIG20', '2,245.67', '+1.2%', true),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildIndexCard('S&P 500', '4,567.89', '+0.8%', true),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildIndexCard('NASDAQ', '14,234.56', '-0.3%', false),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIndexCard(
    String name,
    String value,
    String change,
    bool isPositive,
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
          Text(
            name,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: isPositive ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
