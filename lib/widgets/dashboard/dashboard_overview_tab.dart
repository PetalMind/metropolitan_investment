import 'package:flutter/material.dart';
import '../../models/investment.dart';
import '../../services/web_analytics_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../advanced_analytics_widgets.dart';

class DashboardOverviewTab extends StatelessWidget {
  final bool isMobile;
  final DashboardMetrics? dashboardMetrics;
  final List<Investment> recentInvestments;
  final List<Investment> investmentsRequiringAttention;
  final List<ClientSummary> topClients;

  const DashboardOverviewTab({
    super.key,
    required this.isMobile,
    required this.dashboardMetrics,
    required this.recentInvestments,
    required this.investmentsRequiringAttention,
    this.topClients = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        children: [
          if (isMobile) _buildMobileLayout() else _buildDesktopLayout(),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildSummaryCards(),
        const SizedBox(height: 24),
        _buildRecentInvestments(),
        const SizedBox(height: 24),
        _buildAttentionRequired(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildSummaryCards(),
              const SizedBox(height: 24),
              _buildRecentInvestments(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildQuickMetrics(),
              const SizedBox(height: 24),
              _buildPortfolioComposition(),
              const SizedBox(height: 24),
              _buildAttentionRequired(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    if (dashboardMetrics == null) return const SizedBox();

    final metrics = dashboardMetrics!;

    if (isMobile) {
      return Column(
        children: [
          _buildSummaryCard(
            title: 'Łączna wartość',
            value: CurrencyFormatter.formatCurrency(metrics.totalValue),
            subtitle: 'Aktualna wartość portfela',
            icon: Icons.account_balance_wallet,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            title: 'Zrealizowany zysk',
            value: CurrencyFormatter.formatCurrency(
              metrics.totalRealizedCapital + metrics.totalRealizedInterest,
            ),
            subtitle: _getRealizedTrend(),
            icon: Icons.trending_up,
            color: AppTheme.successColor,
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            title: 'Liczba inwestycji',
            value: metrics.totalInvestments.toString(),
            subtitle: '${metrics.activeInvestments} aktywnych',
            icon: Icons.insert_chart,
            color: AppTheme.infoColor,
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            title: 'Średni ROI',
            value: '${metrics.roi.toStringAsFixed(1)}%',
            subtitle: 'Zwrot z inwestycji',
            icon: Icons.percent,
            color: AppTheme.secondaryGold,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Łączna wartość',
            value: CurrencyFormatter.formatCurrency(metrics.totalValue),
            subtitle: 'Aktualna wartość portfela',
            icon: Icons.account_balance_wallet,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Zrealizowany zysk',
            value: CurrencyFormatter.formatCurrency(
              metrics.totalRealizedCapital + metrics.totalRealizedInterest,
            ),
            subtitle: _getRealizedTrend(),
            icon: Icons.trending_up,
            color: AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Liczba inwestycji',
            value: metrics.totalInvestments.toString(),
            subtitle: '${metrics.activeInvestments} aktywnych',
            icon: Icons.insert_chart,
            color: AppTheme.infoColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Średni ROI',
            value: '${metrics.roi.toStringAsFixed(1)}%',
            subtitle: 'Zwrot z inwestycji',
            icon: Icons.percent,
            color: AppTheme.secondaryGold,
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
    String? trend,
    double? trendValue,
    List<String>? additionalInfo,
    String? tooltip,
  }) {
    return AdvancedMetricCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      color: color,
      trend: trend,
      trendValue: trendValue,
      additionalInfo: additionalInfo,
      tooltip: tooltip,
    );
  }

  Widget _buildQuickMetrics() {
    if (dashboardMetrics == null) return const SizedBox();

    final metrics = dashboardMetrics!;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Szybkie metryki',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _buildQuickMetricItem(
                'Najlepszy klient',
                topClients.isNotEmpty
                    ? topClients.first.clientName
                    : 'Brak danych',
                Icons.star,
                AppTheme.secondaryGold,
              ),
              _buildQuickMetricItem(
                'Średnia wartość',
                CurrencyFormatter.formatCurrency(
                  metrics.averageInvestmentAmount,
                ),
                Icons.account_balance,
                AppTheme.infoColor,
              ),
              _buildQuickMetricItem(
                'Aktywne inwestycje',
                metrics.activeInvestments.toString(),
                Icons.category,
                AppTheme.primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickMetricItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioComposition() {
    if (dashboardMetrics == null) return const SizedBox();

    // Podstawowy wykres z prostymi danymi
    final productData = <String, double>{
      'Obligacje': dashboardMetrics!.totalValue * 0.4,
      'Udziały': dashboardMetrics!.totalValue * 0.3,
      'Pożyczki': dashboardMetrics!.totalValue * 0.2,
      'Apartamenty': dashboardMetrics!.totalValue * 0.1,
    };

    final productColors = <String, Color>{
      'Obligacje': AppTheme.primaryColor,
      'Udziały': AppTheme.secondaryGold,
      'Pożyczki': AppTheme.successColor,
      'Apartamenty': AppTheme.infoColor,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: AdvancedPieChart(
        title: 'Struktura portfela',
        data: productData,
        colors: productColors,
        showPercentages: true,
      ),
    );
  }

  Widget _buildRecentInvestments() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ostatnie inwestycje',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (recentInvestments.isEmpty)
            const Center(
              child: Text(
                'Brak ostatnich inwestycji',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else
            ...recentInvestments.map(_buildInvestmentListItem),
        ],
      ),
    );
  }

  Widget _buildAttentionRequired() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: AppTheme.warningColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Wymagają uwagi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (investmentsRequiringAttention.isEmpty)
            const Center(
              child: Text(
                'Brak inwestycji wymagających uwagi',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else
            ...investmentsRequiringAttention.map(_buildAttentionItem),
        ],
      ),
    );
  }

  Widget _buildInvestmentListItem(Investment investment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderSecondary),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getProductTypeColor(
                investment.productType.name,
              ).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getProductIcon(investment.productType.name),
              color: _getProductTypeColor(investment.productType.name),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  investment.clientName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  investment.productName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatCurrency(investment.investmentAmount),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                _formatDate(investment.signedDate),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionItem(Investment investment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: AppTheme.warningColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  investment.clientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  investment.productName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.formatCurrency(investment.remainingCapital),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getRealizedTrend() {
    if (dashboardMetrics == null) return '';
    final realized =
        dashboardMetrics!.totalRealizedCapital +
        dashboardMetrics!.totalRealizedInterest;
    final invested = dashboardMetrics!.totalInvestmentAmount;
    if (invested > 0) {
      final percentage = (realized / invested) * 100;
      return '${percentage.toStringAsFixed(1)}% z wpłat';
    }
    return '';
  }

  Color _getProductTypeColor(String productType) {
    switch (productType.toLowerCase()) {
      case 'bonds':
      case 'obligacje':
        return AppTheme.primaryColor;
      case 'shares':
      case 'udziały':
      case 'akcje':
        return AppTheme.secondaryGold;
      case 'loans':
      case 'pożyczki':
        return AppTheme.successColor;
      case 'apartments':
      case 'apartamenty':
      case 'nieruchomości':
        return AppTheme.infoColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getProductIcon(String productType) {
    switch (productType.toLowerCase()) {
      case 'bonds':
      case 'obligacje':
        return Icons.account_balance;
      case 'shares':
      case 'udziały':
      case 'akcje':
        return Icons.trending_up;
      case 'loans':
      case 'pożyczki':
        return Icons.account_balance_wallet;
      case 'apartments':
      case 'apartamenty':
      case 'nieruchomości':
        return Icons.home;
      default:
        return Icons.insert_chart;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
