import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../services/firebase_functions_advanced_analytics_service.dart';

/// 📊 BENCHMARK TAB - Market benchmark comparisons tab
///
/// Displays:
/// - Market index comparisons
/// - Relative performance analysis
/// - Tracking error and correlation
/// - Beta and Alpha calculations
class BenchmarkTab extends StatefulWidget {
  const BenchmarkTab({super.key});

  @override
  State<BenchmarkTab> createState() => _BenchmarkTabState();
}

class _BenchmarkTabState extends State<BenchmarkTab> {
  Map<String, dynamic>? _benchmarkData;
  bool _isLoading = true;
  String _selectedBenchmark = 'market';

  final List<Map<String, String>> _benchmarkTypes = [
    {'id': 'market', 'name': 'General Market', 'description': 'WIG20, S&P500'},
    {
      'id': 'industry',
      'name': 'Sector-based',
      'description': 'Financial sector',
    },
    {'id': 'bond', 'name': 'Bonds', 'description': 'Bond indices'},
    {'id': 'real_estate', 'name': 'Real Estate', 'description': 'REIT indices'},
  ];

  @override
  void initState() {
    super.initState();
    _loadBenchmarks();
  }

  Future<void> _loadBenchmarks() async {
    setState(() => _isLoading = true);

    try {
      final data =
          await FirebaseFunctionsAdvancedAnalyticsService.getDashboardBenchmarks(
            benchmarkType: _selectedBenchmark,
            forceRefresh: false,
          );

      setState(() {
        _benchmarkData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd ładowania benchmarków: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _benchmarkData == null
          ? _buildErrorState()
          : _buildBenchmarkContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Nie można załadować benchmarków',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadBenchmarks,
            child: const Text('Spróbuj ponownie'),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkContent() {
    return RefreshIndicator(
      onRefresh: _loadBenchmarks,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildBenchmarkSelector(),
            const SizedBox(height: 24),
            _buildComparisonSummaryCards(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildPerformanceComparisonChart(),
                      const SizedBox(height: 24),
                      _buildCorrelationMatrix(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildRiskMetricsComparison(),
                      const SizedBox(height: 24),
                      _buildBenchmarkStatistics(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildRelativePerformanceChart(),
            const SizedBox(height: 24),
            _buildAttributionAnalysis(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analiza Benchmarków',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Porównania z indeksami rynkowymi',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                Icons.compare_arrows,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Benchmark: ${_benchmarkTypes.firstWhere((b) => b['id'] == _selectedBenchmark)['name']}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenchmarkSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textSecondary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Typ benchmarku',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: _benchmarkTypes.map((benchmark) {
              final isSelected = benchmark['id'] == _selectedBenchmark;
              return ChoiceChip(
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(benchmark['name'] ?? ''),
                    Text(
                      benchmark['description'] ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedBenchmark = benchmark['id']!;
                    });
                    _loadBenchmarks();
                  }
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                backgroundColor: AppTheme.textSecondary.withOpacity(0.1),
                labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSummaryCards() {
    // Przykładowe dane - w prawdziwej implementacji z _benchmarkData
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Relative Performance',
            value: '+2.4%',
            subtitle: 'vs benchmark YTD',
            icon: Icons.trending_up,
            color: AppTheme.gainPrimary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Alpha',
            value: '1.8%',
            subtitle: 'Excess return',
            icon: Icons.stars,
            color: AppTheme.secondaryGold,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Beta',
            value: '0.85',
            subtitle: 'Market sensitivity',
            icon: Icons.analytics,
            color: AppTheme.bondsColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Correlation',
            value: '0.72',
            subtitle: 'vs benchmark',
            icon: Icons.link,
            color: AppTheme.sharesColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceComparisonChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textSecondary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Porównanie Wydajności',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Portfolio vs benchmark w czasie',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.textSecondary.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final months = [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'May',
                          'Jun',
                          'Jul',
                          'Aug',
                          'Sep',
                          'Oct',
                          'Nov',
                          'Dec',
                        ];
                        if (value.toInt() < months.length) {
                          return Text(
                            months[value.toInt()],
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Portfolio performance
                  LineChartBarData(
                    spots: _generatePerformanceSpots(portfolio: true),
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                  ),
                  // Benchmark performance
                  LineChartBarData(
                    spots: _generatePerformanceSpots(portfolio: false),
                    isCurved: true,
                    color: AppTheme.secondaryGold,
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildChartLegend(),
        ],
      ),
    );
  }

  List<FlSpot> _generatePerformanceSpots({required bool portfolio}) {
    final spots = <FlSpot>[];
    final basePerformance = portfolio ? 6.2 : 5.1;

    for (int i = 0; i < 12; i++) {
      final x = i.toDouble();
      final trend = basePerformance * (i + 1) / 12.0;
      final noise = portfolio
          ? (i % 3 == 0 ? 0.5 : -0.3)
          : (i % 4 == 0 ? 0.2 : -0.1);
      spots.add(FlSpot(x, trend + noise));
    }

    return spots;
  }

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Portfolio', AppTheme.primaryColor),
        const SizedBox(width: 24),
        _buildLegendItem('Benchmark', AppTheme.secondaryGold),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCorrelationMatrix() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textSecondary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macierz Korelacji',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          // Placeholder dla macierzy korelacji
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Macierz korelacji będzie tutaj',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskMetricsComparison() {
    final riskMetrics = [
      {'label': 'Volatility', 'portfolio': '12.5%', 'benchmark': '15.2%'},
      {'label': 'Max Drawdown', 'portfolio': '8.3%', 'benchmark': '11.7%'},
      {'label': 'Sharpe Ratio', 'portfolio': '1.24', 'benchmark': '0.98'},
      {'label': 'Sortino Ratio', 'portfolio': '1.68', 'benchmark': '1.34'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textSecondary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metryki Ryzyka',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...riskMetrics.map(
            (metric) => _buildRiskMetricRow(
              metric['label']!,
              metric['portfolio']!,
              metric['benchmark']!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskMetricRow(
    String label,
    String portfolioValue,
    String benchmarkValue,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Portfolio: $portfolioValue',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.primaryColor),
              ),
              Text(
                'Benchmark: $benchmarkValue',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.secondaryGold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildBenchmarkStatistics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textSecondary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kapitał',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
      
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelativePerformanceChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textSecondary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Względna Wydajność',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Różnica zwrotów vs benchmark',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          // Placeholder dla wykresu względnej wydajności
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Wykres względnej wydajności będzie tutaj',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributionAnalysis() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textSecondary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analiza Atrybucji',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Wpływ alokacji vs selekcji na wyniki',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildAttributionBar(
                  'Alokacja',
                  1.2,
                  AppTheme.bondsColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAttributionBar(
                  'Selekcja',
                  0.8,
                  AppTheme.sharesColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAttributionBar(
                  'Interakcja',
                  0.4,
                  AppTheme.loansColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttributionBar(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          '${value.toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 60,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: (value / 2.0) * 60, // Scaled height
              width: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
