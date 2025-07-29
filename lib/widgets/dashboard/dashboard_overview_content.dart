import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/investment.dart';
import '../../models/product.dart';
import '../../services/advanced_analytics_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';

class DashboardOverviewContent extends StatelessWidget {
  final List<Investment> recentInvestments;
  final AdvancedDashboardMetrics? metrics;
  final bool isMobile;
  final String selectedTimeFrame;
  final double horizontalPadding;
  final BuildContext context;

  const DashboardOverviewContent({
    super.key,
    required this.recentInvestments,
    required this.metrics,
    required this.isMobile,
    required this.selectedTimeFrame,
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
          _buildTotalValueCard(),
          const SizedBox(height: 16),
          if (isMobile) ...[
            _buildReturnCard(),
            const SizedBox(height: 16),
            _buildRiskCard(),
            const SizedBox(height: 16),
            _buildRecentInvestments(),
            const SizedBox(height: 16),
            _buildPortfolioComposition(),
            const SizedBox(height: 16),
            _buildPerformanceChart(),
          ] else ...[
            Row(
              children: [
                Expanded(child: _buildReturnCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildRiskCard()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildRecentInvestments(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: _buildPortfolioComposition(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPerformanceChart(),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalValueCard() {
    final totalValue = metrics?.portfolioMetrics.totalValue ?? 0.0;
    final totalGain = metrics?.portfolioMetrics.totalGain ?? 0.0;
    final totalGainPercent = metrics?.portfolioMetrics.totalReturn ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Całkowita wartość portfela',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatCurrency(totalValue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                totalGain >= 0 ? Icons.trending_up : Icons.trending_down,
                color: totalGain >= 0 ? Colors.greenAccent : Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${totalGain >= 0 ? '+' : ''}${CurrencyFormatter.formatCurrency(totalGain)} (${totalGainPercent.toStringAsFixed(2)}%)',
                style: TextStyle(
                  color: totalGain >= 0 ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReturnCard() {
    final annualizedReturn = metrics?.performanceMetrics.annualizedReturn ?? 0.0;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Zwrot roczny',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${annualizedReturn.toStringAsFixed(2)}%',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: annualizedReturn >= 0 ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Okres: $selectedTimeFrame',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskCard() {
    final sharpeRatio = metrics?.riskMetrics.sharpeRatio ?? 0.0;
    final volatility = metrics?.riskMetrics.volatility ?? 0.0;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.security,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Wskaźnik Sharpe\'a',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            sharpeRatio.toStringAsFixed(2),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _getSharpeColor(sharpeRatio),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Zmienność: ${volatility.toStringAsFixed(2)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInvestments() {
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
            'Ostatnie inwestycje',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (recentInvestments.isEmpty)
            const Text('Brak ostatnich inwestycji')
          else
            ...recentInvestments.take(5).map((investment) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getProductColor(investment.productType.toString()),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            investment.productName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatCurrency(investment.investmentValue),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${investment.currentGainPercent >= 0 ? '+' : ''}${investment.currentGainPercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: investment.currentGainPercent >= 0 ? Colors.green : Colors.red,
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

  Widget _buildPortfolioComposition() {
    if (metrics?.productAnalytics.typeDistribution == null || 
        metrics!.productAnalytics.typeDistribution.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSecondary),
        ),
        child: const Center(
          child: Text('Brak danych o składzie portfela'),
        ),
      );
    }

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
            'Skład portfela',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: metrics!.productAnalytics.typeDistribution.entries.map((entry) {
                  return PieChartSectionData(
                    value: entry.value,
                    title: '${entry.value.toStringAsFixed(1)}%',
                    color: _getProductColor(entry.key.toString()),
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...metrics!.productAnalytics.typeDistribution.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getProductColor(entry.key.toString()),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getProductTypeName(entry.key.toString()),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${entry.value.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildPerformanceChart() {
    if (metrics?.timeSeriesAnalytics.monthlyPerformance == null || 
        metrics!.timeSeriesAnalytics.monthlyPerformance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSecondary),
        ),
        child: const Center(
          child: Text('Brak danych historycznych'),
        ),
      );
    }

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
            'Wykres wydajności',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.borderSecondary,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: AppTheme.borderSecondary,
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
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text('${value.toInt()}', style: style),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        return Text('${value.toInt()}%', style: style);
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppTheme.borderSecondary),
                ),
                minX: 0,
                maxX: metrics!.timeSeriesAnalytics.monthlyPerformance.length.toDouble() - 1,
                minY: metrics!.timeSeriesAnalytics.monthlyPerformance.values.reduce((a, b) => a < b ? a : b) - 1,
                maxY: metrics!.timeSeriesAnalytics.monthlyPerformance.values.reduce((a, b) => a > b ? a : b) + 1,
                lineBarsData: [
                  LineChartBarData(
                    spots: metrics!.timeSeriesAnalytics.monthlyPerformance.entries.toList().asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.value);
                    }).toList(),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.primaryAccent],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.3),
                          AppTheme.primaryAccent.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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

  Color _getSharpeColor(double sharpe) {
    if (sharpe > 1.0) return Colors.green;
    if (sharpe > 0.5) return Colors.orange;
    return Colors.red;
  }

  Color _getProductColor(String productType) {
    switch (productType.toLowerCase()) {
      case 'akcje':
      case 'shares':
        return Colors.blue;
      case 'obligacje':
      case 'bonds':
        return Colors.green;
      case 'nieruchomości':
      case 'apartments':
        return Colors.orange;
      case 'pożyczki':
      case 'loans':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getProductTypeName(String productType) {
    switch (productType.toLowerCase()) {
      case 'shares':
        return 'Akcje';
      case 'bonds':
        return 'Obligacje';
      case 'apartments':
        return 'Nieruchomości';
      case 'loans':
        return 'Pożyczki';
      default:
        return productType;
    }
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
          _buildTotalValueCard(),
          const SizedBox(height: 16),
          if (isMobile) ...[
            _buildReturnCard(),
            const SizedBox(height: 16),
            _buildRiskCard(),
            const SizedBox(height: 16),
            _buildRecentInvestments(),
            const SizedBox(height: 16),
            _buildPortfolioComposition(),
            const SizedBox(height: 16),
            _buildPerformanceChart(),
          ] else ...[
            Row(
              children: [
                Expanded(child: _buildReturnCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildRiskCard()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildRecentInvestments(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: _buildPortfolioComposition(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPerformanceChart(),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalValueCard() {
    final totalValue = metrics?.totalValue ?? 0.0;
    final totalGain = metrics?.totalGain ?? 0.0;
    final totalGainPercent = metrics?.totalGainPercent ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Całkowita wartość portfela',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatCurrency(totalValue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                totalGain >= 0 ? Icons.trending_up : Icons.trending_down,
                color: totalGain >= 0 ? Colors.greenAccent : Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${totalGain >= 0 ? '+' : ''}${CurrencyFormatter.formatCurrency(totalGain)} (${totalGainPercent.toStringAsFixed(2)}%)',
                style: TextStyle(
                  color: totalGain >= 0 ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReturnCard() {
    final annualizedReturn = metrics?.annualizedReturn ?? 0.0;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Zwrot roczny',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${annualizedReturn.toStringAsFixed(2)}%',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: annualizedReturn >= 0 ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Okres: $selectedTimeFrame',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskCard() {
    final sharpeRatio = metrics?.sharpeRatio ?? 0.0;
    final volatility = metrics?.volatility ?? 0.0;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.security,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Wskaźnik Sharpe\'a',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            sharpeRatio.toStringAsFixed(2),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _getSharpeColor(sharpeRatio),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Zmienność: ${volatility.toStringAsFixed(2)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInvestments() {
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
            'Ostatnie inwestycje',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (recentInvestments.isEmpty)
            const Text('Brak ostatnich inwestycji')
          else
            ...recentInvestments.take(5).map((investment) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getProductColor(investment.productType),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            investment.productName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatCurrency(investment.amount),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${investment.currentReturn >= 0 ? '+' : ''}${investment.currentReturn.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: investment.currentReturn >= 0 ? Colors.green : Colors.red,
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

  Widget _buildPortfolioComposition() {
    if (metrics?.portfolioComposition == null || metrics!.portfolioComposition.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSecondary),
        ),
        child: const Center(
          child: Text('Brak danych o składzie portfela'),
        ),
      );
    }

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
            'Skład portfela',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: metrics!.portfolioComposition.entries.map((entry) {
                  return PieChartSectionData(
                    value: entry.value,
                    title: '${entry.value.toStringAsFixed(1)}%',
                    color: _getProductColor(entry.key),
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...metrics!.portfolioComposition.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getProductColor(entry.key),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getProductTypeName(entry.key),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${entry.value.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildPerformanceChart() {
    if (metrics?.performanceHistory == null || metrics!.performanceHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSecondary),
        ),
        child: const Center(
          child: Text('Brak danych historycznych'),
        ),
      );
    }

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
            'Wykres wydajności',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.borderSecondary,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: AppTheme.borderSecondary,
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
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text('${value.toInt()}', style: style),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        return Text('${value.toInt()}%', style: style);
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppTheme.borderSecondary),
                ),
                minX: 0,
                maxX: metrics!.performanceHistory.length.toDouble() - 1,
                minY: metrics!.performanceHistory.map((e) => e.value).reduce((a, b) => a < b ? a : b) - 1,
                maxY: metrics!.performanceHistory.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 1,
                lineBarsData: [
                  LineChartBarData(
                    spots: metrics!.performanceHistory.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.value);
                    }).toList(),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.accentColor],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.3),
                          AppTheme.accentColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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

  Color _getSharpeColor(double sharpe) {
    if (sharpe > 1.0) return Colors.green;
    if (sharpe > 0.5) return Colors.orange;
    return Colors.red;
  }

  Color _getProductColor(String productType) {
    switch (productType.toLowerCase()) {
      case 'akcje':
      case 'shares':
        return Colors.blue;
      case 'obligacje':
      case 'bonds':
        return Colors.green;
      case 'nieruchomości':
      case 'apartments':
        return Colors.orange;
      case 'pożyczki':
      case 'loans':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getProductTypeName(String productType) {
    switch (productType.toLowerCase()) {
      case 'shares':
        return 'Akcje';
      case 'bonds':
        return 'Obligacje';
      case 'apartments':
        return 'Nieruchomości';
      case 'loans':
        return 'Pożyczki';
      default:
        return productType;
    }
  }
}
