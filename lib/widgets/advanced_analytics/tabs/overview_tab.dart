import 'package:flutter/material.dart';
import '../cards/analytics_card.dart';
import '../charts/portfolio_pie_chart.dart';
import '../../../theme/app_theme.dart';

/// 📊 OVERVIEW TAB COMPONENT
/// Main overview analytics tab with key metrics
class OverviewTab extends StatelessWidget {
  final Map<String, dynamic>? data;
  final bool isLoading;

  const OverviewTab({
    super.key,
    required this.data,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildKeyMetricsSection(),
          const SizedBox(height: 24),
          _buildChartsSection(),
          const SizedBox(height: 24),
          _buildSummarySection(),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 768;
        final crossAxisCount = isTablet ? 4 : 2;
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isTablet ? 1.2 : 1.0,
          children: [
            CurrencyAnalyticsCard(
              title: 'Całkowita wartość portfela',
              value: (data?['portfolioSummary']?['totalAmount'] ?? 0.0).toDouble(),
              icon: Icons.account_balance_wallet,
              color: AppTheme.primaryColor,
              changeValue: data?.profitabilityAnalytics['netReturn'],
              isLoading: isLoading,
            ),
            CurrencyAnalyticsCard(
              title: 'Zysk netto',
              value: data?.profitabilityAnalytics['netProfit'] ?? 0.0,
              icon: Icons.trending_up,
              color: AppTheme.successColor,
              subtitle: '${(data?.performanceAnalytics['successRate'] ?? 0).toStringAsFixed(1)}% sukces',
              isLoading: isLoading,
            ),
            PercentageAnalyticsCard(
              title: 'Średni ROI',
              value: data?.performanceAnalytics['averageROI'] ?? 0.0,
              icon: Icons.bar_chart,
              color: AppTheme.infoColor,
              subtitle: 'Portfolio',
              isLoading: isLoading,
            ),
            CountAnalyticsCard(
              title: 'Łączna liczba inwestycji',
              value: data?.portfolioSummary['totalCount'] ?? 0,
              icon: Icons.pie_chart,
              color: AppTheme.secondaryGold,
              subtitle: 'Wszystkie produkty',
              isLoading: isLoading,
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 768;
        
        if (isTablet) {
          return Row(
            children: [
              Expanded(
                child: PortfolioPieChart(
                  title: 'Rozkład według statusu',
                  data: data?.portfolioSummary['statusDistribution'] ?? {},
                  subtitle: 'Status inwestycji',
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PortfolioPieChart(
                  title: 'Rozkład według produktów',
                  data: data?.portfolioSummary['amountByProduct'] ?? {},
                  subtitle: 'Wartość według typu',
                  isLoading: isLoading,
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              PortfolioPieChart(
                title: 'Rozkład według statusu',
                data: data?.portfolioSummary['statusDistribution'] ?? {},
                subtitle: 'Status inwestycji',
                isLoading: isLoading,
              ),
              const SizedBox(height: 16),
              PortfolioPieChart(
                title: 'Rozkład według produktów',
                data: data?.portfolioSummary['amountByProduct'] ?? {},
                subtitle: 'Wartość według typu',
                isLoading: isLoading,
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildSummarySection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 768;
        
        if (isTablet) {
          return Row(
            children: [
              Expanded(child: _buildClientStatsCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildFinancialSummaryCard()),
            ],
          );
        } else {
          return Column(
            children: [
              _buildClientStatsCard(),
              const SizedBox(height: 16),
              _buildFinancialSummaryCard(),
            ],
          );
        }
      },
    );
  }

  Widget _buildClientStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statystyki klientów',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading) ...[
            _buildLoadingRows(3),
          ] else ...[
            _buildStatItem(
              'Całkowita liczba klientów',
              '${data?.clientAnalytics['totalClients'] ?? 0}',
              Icons.people,
            ),
            _buildStatItem(
              'Pokrycie email',
              '${(data?.clientAnalytics['emailCoverage'] ?? 0).toStringAsFixed(1)}%',
              Icons.email,
            ),
            _buildStatItem(
              'Pokrycie telefon',
              '${(data?.clientAnalytics['phoneCoverage'] ?? 0).toStringAsFixed(1)}%',
              Icons.phone,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Podsumowanie finansowe',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading) ...[
            _buildLoadingRows(3),
          ] else ...[
            _buildStatItem(
              'Zainwestowany kapitał',
              _formatCurrency(data?.profitabilityAnalytics['totalInvested'] ?? 0),
              Icons.input,
            ),
            _buildStatItem(
              'Zrealizowane zyski',
              _formatCurrency(data?.profitabilityAnalytics['totalRealized'] ?? 0),
              Icons.output,
            ),
            _buildStatItem(
              'Podatek zapłacony',
              _formatCurrency(data?.profitabilityAnalytics['totalTax'] ?? 0),
              Icons.receipt,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingRows(int count) {
    return Column(
      children: List.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0 PLN';
    final amount = value is double ? value : double.tryParse(value.toString()) ?? 0;
    return '${(amount / 1000000).toStringAsFixed(1)}M PLN';
  }
}