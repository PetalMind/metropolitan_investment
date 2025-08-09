import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/product.dart';
import '../advanced_analytics_widgets.dart';

// Alias dla AppColors i AppTextStyles z AppTheme
class AppColors {
  static const Color text = AppTheme.textPrimary;
  static const Color textSecondary = AppTheme.textSecondary;
  static const Color primary = AppTheme.primaryColor;
  static const Color primaryLight = AppTheme.primaryLight;
  static const Color success = AppTheme.successPrimary;
  static const Color error = AppTheme.errorPrimary;
  static const Color warning = AppTheme.warningPrimary;
  static const Color info = AppTheme.infoPrimary;
  static const Color cardBackground = AppTheme.surfaceCard;
  static const Color borderColor = AppTheme.borderPrimary;
}

class AppTextStyles {
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
  );
  static const TextStyle headingMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppTheme.textPrimary,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppTheme.textSecondary,
  );
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppTheme.textSecondary,
  );
}

class OverviewTab extends StatelessWidget {
  final Map<String, dynamic>? dashboardMetrics;

  const OverviewTab({super.key, this.dashboardMetrics});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: _getHorizontalPadding(context),
        vertical: _getVerticalSpacing(context),
      ),
      child: _isMobile(context)
          ? _buildMobileLayout(context)
          : _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildAdvancedSummaryCards(context),
        SizedBox(height: _getVerticalSpacing(context)),
        _buildQuickMetrics(context),
        SizedBox(height: _getVerticalSpacing(context)),
        _buildPortfolioComposition(context),
        SizedBox(height: _getVerticalSpacing(context)),
        _buildRiskAlerts(context),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Główne karty po lewej - 60% szerokości
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildAdvancedSummaryCards(context),
              SizedBox(height: _getVerticalSpacing(context)),
              _buildPortfolioComposition(context),
            ],
          ),
        ),
        SizedBox(width: _getVerticalSpacing(context)),
        // Panel boczny po prawej - 40% szerokości
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildQuickMetrics(context),
              SizedBox(height: _getVerticalSpacing(context)),
              _buildRiskAlerts(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSummaryCards(BuildContext context) {
    if (dashboardMetrics == null) return const SizedBox();

    final metrics =
        dashboardMetrics!['portfolioMetrics'] as Map<String, dynamic>?;
    if (metrics == null) return const SizedBox();

    if (_isMobile(context)) {
      return Column(
        children: [
          _buildSummaryCard(
            context: context,
            title: 'Wartość Portfela',
            value: _formatCurrency(
              (metrics['totalValue'] as num?)?.toDouble() ?? 0.0,
            ),
            subtitle: 'Całkowita wartość',
            icon: Icons.account_balance_wallet,
            color: AppColors.success,
            trend: _getRealizedTrend(),
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            context: context,
            title: 'Zainwestowano',
            value: _formatCurrency(
              (metrics['totalInvested'] as num?)?.toDouble() ?? 0.0,
            ),
            subtitle: 'Kapitał początkowy',
            icon: Icons.trending_up,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            context: context,
            title: 'ROI',
            value:
                '${((metrics['roi'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)}%',
            subtitle: 'Zwrot z inwestycji',
            icon: Icons.percent,
            color: ((metrics['roi'] as num?)?.toDouble() ?? 0.0) >= 0
                ? AppColors.success
                : AppColors.error,
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            context: context,
            title: 'Aktywne',
            value:
                '${(metrics['activeInvestmentsCount'] as num?)?.toInt() ?? 0}',
            subtitle:
                'z ${(metrics['totalInvestmentsCount'] as num?)?.toInt() ?? 0} inwestycji',
            icon: Icons.business_center,
            color: AppColors.info,
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context: context,
                title: 'Wartość Portfela',
                value: _formatCurrency(
                  (metrics['totalValue'] as num?)?.toDouble() ?? 0.0,
                ),
                subtitle: 'Całkowita wartość',
                icon: Icons.account_balance_wallet,
                color: AppColors.success,
                trend: _getRealizedTrend(),
                trendValue:
                    (metrics['portfolioGrowthRate'] as num?)?.toDouble() ?? 0.0,
                additionalInfo: [
                  'Zrealizowano: ${_formatCurrency((metrics['totalRealized'] as num?)?.toDouble() ?? 0.0)}',
                  'Pozostało: ${_formatCurrency((metrics['totalRemaining'] as num?)?.toDouble() ?? 0.0)}',
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                context: context,
                title: 'Zainwestowano',
                value: _formatCurrency(
                  (metrics['totalInvested'] as num?)?.toDouble() ?? 0.0,
                ),
                subtitle: 'Kapitał początkowy',
                icon: Icons.trending_up,
                color: AppColors.primary,
                additionalInfo: [
                  'Średnia: ${_formatCurrency((metrics['averageInvestmentSize'] as num?)?.toDouble() ?? 0.0)}',
                  'Mediana: ${_formatCurrency((metrics['medianInvestmentSize'] as num?)?.toDouble() ?? 0.0)}',
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context: context,
                title: 'ROI',
                value:
                    '${((metrics['roi'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)}%',
                subtitle: 'Zwrot z investycji',
                icon: Icons.percent,
                color: ((metrics['roi'] as num?)?.toDouble() ?? 0.0) >= 0
                    ? AppColors.success
                    : AppColors.error,
                additionalInfo: [
                  'Zysk: ${_formatCurrency((metrics['totalProfit'] as num?)?.toDouble() ?? 0.0)}',
                  'Odsetki: ${_formatCurrency((metrics['totalInterest'] as num?)?.toDouble() ?? 0.0)}',
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                context: context,
                title: 'Aktywne',
                value:
                    '${(metrics['activeInvestmentsCount'] as num?)?.toInt() ?? 0}',
                subtitle:
                    'z ${(metrics['totalInvestmentsCount'] as num?)?.toInt() ?? 0} inwestycji',
                icon: Icons.business_center,
                color: AppColors.info,
                additionalInfo: [
                  'Wzrost: ${((metrics['portfolioGrowthRate'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)}%',
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
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

  Widget _buildQuickMetrics(BuildContext context) {
    if (dashboardMetrics == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Szybkie Metryki',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
            children: [
              _buildQuickMetricItem(
                'Najlepsza inwestycja',
                '${(dashboardMetrics!['performanceMetrics']?['bestPerformingInvestment']?['profitLossPercentage'] ?? 0.0).toStringAsFixed(1)}%',
                Icons.trending_up,
                AppColors.success,
              ),
              const Divider(height: 24),
              _buildQuickMetricItem(
                'Współczynnik Sharpe',
                '${(dashboardMetrics!['riskMetrics']?['sharpeRatio'] ?? 0.0).toStringAsFixed(2)}',
                Icons.analytics,
                _getSharpeColor(
                  dashboardMetrics!['riskMetrics']?['sharpeRatio'] ?? 0.0,
                ),
              ),
              const Divider(height: 24),
              _buildQuickMetricItem(
                'Volatility',
                '${(dashboardMetrics!['riskMetrics']?['volatility'] ?? 0.0).toStringAsFixed(1)}%',
                Icons.show_chart,
                AppColors.warning,
              ),
              const Divider(height: 24),
              _buildQuickMetricItem(
                'Koncentracja ryzyka',
                '${(dashboardMetrics!['riskMetrics']?['concentrationRisk'] ?? 0.0).toStringAsFixed(0)}',
                Icons.pie_chart,
                _getConcentrationColor(
                  dashboardMetrics!['riskMetrics']?['concentrationRisk'] ?? 0.0,
                ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: AppTextStyles.titleSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioComposition(BuildContext context) {
    if (dashboardMetrics == null) return const SizedBox();

    final productData = <String, double>{};
    final productColors = <String, Color>{};

    final productAnalytics =
        dashboardMetrics!['productAnalytics'] as Map<String, dynamic>? ?? {};
    final productPerformance =
        productAnalytics['productPerformance'] as Map<String, dynamic>? ?? {};

    productPerformance.forEach((productTypeStr, performance) {
      final perfData = performance as Map<String, dynamic>? ?? {};
      productData[productTypeStr] =
          (perfData['totalValue'] as num?)?.toDouble() ?? 0.0;
      productColors[productTypeStr] = _getProductColor(
        _parseProductType(productTypeStr),
      );
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Struktura Portfela',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // Dodaj tutaj wykres kołowy z strukturą portfela
          SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Wykres struktury portfela',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAlerts(BuildContext context) {
    if (dashboardMetrics == null) return const SizedBox();

    final riskMetrics =
        dashboardMetrics!['riskMetrics'] as Map<String, dynamic>? ?? {};
    final alerts = <Widget>[];

    // Sprawdź różne poziomy ryzyka
    final concentrationRisk =
        (riskMetrics['concentrationRisk'] as num?)?.toDouble() ?? 0.0;
    if (concentrationRisk > 2500) {
      alerts.add(
        _buildRiskAlert(
          'Wysokie ryzyko koncentracji',
          'Portfel może być zbyt skoncentrowany w jednym typie produktu',
          Icons.warning,
          AppColors.warning,
        ),
      );
    }

    final volatility = (riskMetrics['volatility'] as num?)?.toDouble() ?? 0.0;
    if (volatility > 15) {
      alerts.add(
        _buildRiskAlert(
          'Wysoka volatilność',
          'Portfel wykazuje wysoką zmienność',
          Icons.trending_up,
          AppColors.error,
        ),
      );
    }

    final liquidityRisk =
        (riskMetrics['liquidityRisk'] as num?)?.toDouble() ?? 0.0;
    if (liquidityRisk > 70) {
      alerts.add(
        _buildRiskAlert(
          'Ryzyko płynności',
          'Duży odsetek długoterminowych inwestycji',
          Icons.access_time,
          AppColors.info,
        ),
      );
    }

    if (alerts.isEmpty) {
      alerts.add(
        _buildRiskAlert(
          'Portfolio w dobrej kondycji',
          'Brak istotnych alertów ryzyka',
          Icons.check_circle,
          AppColors.success,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alerty Ryzyka',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...alerts.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: alert,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAlert(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods
  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;
  double _getHorizontalPadding(BuildContext context) =>
      _isMobile(context) ? 16.0 : 24.0;
  double _getVerticalSpacing(BuildContext context) =>
      _isMobile(context) ? 16.0 : 24.0;

  String _getRealizedTrend() => '↗';
  String _formatCurrency(double amount) => '${amount.toStringAsFixed(2)} PLN';

  Color _getSharpeColor(double sharpe) {
    if (sharpe > 1) return AppColors.success;
    if (sharpe > 0.5) return AppColors.warning;
    return AppColors.error;
  }

  Color _getConcentrationColor(double concentration) {
    if (concentration > 2500) return AppColors.error;
    if (concentration > 1800) return AppColors.warning;
    return AppColors.success;
  }

  ProductType _parseProductType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'bonds':
      case 'obligacje':
        return ProductType.bonds;
      case 'shares':
      case 'udziały':
        return ProductType.shares;
      case 'apartments':
      case 'apartamenty':
        return ProductType.apartments;
      case 'loans':
      case 'pożyczki':
        return ProductType.loans;
      default:
        return ProductType.bonds;
    }
  }

  Color _getProductColor(ProductType type) {
    switch (type) {
      case ProductType.bonds:
        return AppColors.primary;
      case ProductType.shares:
        return AppColors.success;
      case ProductType.apartments:
        return AppColors.info;
      case ProductType.loans:
        return AppColors.warning;
    }
  }
}
