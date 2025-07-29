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

  const DashboardOverviewContent({
    super.key,
    required this.recentInvestments,
    required this.metrics,
    required this.isMobile,
    required this.selectedTimeFrame,
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
          _buildTotalValueCard(context),
          const SizedBox(height: 16),
          if (isMobile) ...[
            _buildPortfolioSummary(context),
            const SizedBox(height: 16),
            _buildRiskMetrics(context),
            const SizedBox(height: 16),
            _buildRecentInvestments(context),
            const SizedBox(height: 16),
            _buildProductDistribution(context),
            const SizedBox(height: 16),
            _buildPerformanceChart(context),
          ] else ...[
            Row(
              children: [
                Expanded(child: _buildPortfolioSummary(context)),
                const SizedBox(width: 16),
                Expanded(child: _buildRiskMetrics(context)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildRecentInvestments(context)),
                const SizedBox(width: 16),
                Expanded(child: _buildProductDistribution(context)),
              ],
            ),
            const SizedBox(height: 16),
            _buildPerformanceChart(context),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalValueCard(BuildContext context) {
    final totalValue = metrics?.portfolioMetrics.totalValue ?? 0.0;
    final totalGain = metrics?.portfolioMetrics.totalProfit ?? 0.0;
    final totalGainPercent = metrics?.portfolioMetrics.roi ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text(
                'Całkowita wartość portfela',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            CurrencyFormatter.formatCurrency(totalValue),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Zysk: ${CurrencyFormatter.formatCurrency(totalGain)} (${totalGainPercent.toStringAsFixed(2)}%)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSummary(BuildContext context) {
    final activeInvestments =
        metrics?.portfolioMetrics.activeInvestmentsCount ?? 0;
    final totalInvestments =
        metrics?.portfolioMetrics.totalInvestmentsCount ?? 0;
    final averageSize = metrics?.portfolioMetrics.averageInvestmentSize ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Podsumowanie portfela',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryItem(
            context,
            'Aktywne inwestycje',
            '$activeInvestments',
          ),
          const SizedBox(height: 8),
          _buildSummaryItem(
            context,
            'Wszystkie inwestycje',
            '$totalInvestments',
          ),
          const SizedBox(height: 8),
          _buildSummaryItem(
            context,
            'Średni rozmiar',
            CurrencyFormatter.formatCurrency(averageSize),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildRiskMetrics(BuildContext context) {
    final volatility = metrics?.riskMetrics.volatility ?? 0.0;
    final sharpeRatio = metrics?.riskMetrics.sharpeRatio ?? 0.0;
    final maxDrawdown = metrics?.riskMetrics.maxDrawdown ?? 0.0;

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
          _buildSummaryItem(
            context,
            'Zmienność',
            '${volatility.toStringAsFixed(2)}%',
          ),
          const SizedBox(height: 8),
          _buildSummaryItem(
            context,
            'Współczynnik Sharpe',
            sharpeRatio.toStringAsFixed(3),
          ),
          const SizedBox(height: 8),
          _buildSummaryItem(
            context,
            'Maks. spadek',
            '${maxDrawdown.toStringAsFixed(2)}%',
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInvestments(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: AppTheme.successColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Ostatnie inwestycje',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentInvestments.isEmpty)
            Text('Brak danych', style: Theme.of(context).textTheme.bodyMedium)
          else
            ...recentInvestments.take(5).map((investment) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            investment.clientName,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            investment.productName,
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
                          CurrencyFormatter.formatCurrency(
                            investment.totalValue,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${investment.profitLossPercentage >= 0 ? '+' : ''}${investment.profitLossPercentage.toStringAsFixed(2)}%',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: investment.profitLossPercentage >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildProductDistribution(BuildContext context) {
    if (metrics?.productAnalytics.productPerformance == null ||
        metrics!.productAnalytics.productPerformance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration,
        child: Text('Brak danych o produktach'),
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
              Icon(Icons.donut_small, color: AppTheme.infoColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Rozkład produktów',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: metrics!.productAnalytics.productPerformance.entries.map((
                  entry,
                ) {
                  return PieChartSectionData(
                    value: entry.value.totalValue,
                    title:
                        '${(entry.value.totalValue * 100 / metrics!.portfolioMetrics.totalValue).toStringAsFixed(1)}%',
                    color: _getProductTypeColor(entry.key),
                    radius: 50,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...metrics!.productAnalytics.productPerformance.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getProductTypeColor(entry.key),
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
                    '${(entry.value.totalValue * 100 / metrics!.portfolioMetrics.totalValue).toStringAsFixed(1)}%',
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

  Widget _buildPerformanceChart(BuildContext context) {
    if (metrics?.timeSeriesAnalytics.monthlyData == null ||
        metrics!.timeSeriesAnalytics.monthlyData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration,
        child: Text('Brak danych wydajności'),
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
              Icon(Icons.trending_up, color: AppTheme.successColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Wydajność w czasie',
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

  Color _getProductTypeColor(ProductType productType) {
    switch (productType) {
      case ProductType.bonds:
        return AppTheme.bondsColor;
      case ProductType.shares:
        return AppTheme.sharesColor;
      case ProductType.loans:
        return AppTheme.loansColor;
      default:
        return AppTheme.primaryColor;
    }
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
