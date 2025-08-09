import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../services/advanced_analytics_service.dart';

// Alias dla AppColors i AppTextStyles
class AppColors {
  static const Color text = AppTheme.textPrimary;
  static const Color textSecondary = AppTheme.textSecondary;
  static const Color primary = AppTheme.primaryColor;
  static const Color secondary = AppTheme.secondaryGold;
  static const Color success = AppTheme.successPrimary;
  static const Color error = AppTheme.errorPrimary;
  static const Color warning = AppTheme.warningPrimary;
  static const Color info = AppTheme.infoPrimary;
  static const Color cardBackground = AppTheme.surfaceCard;
  static const Color surface = AppTheme.surfaceContainer;
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
}

class RiskTab extends StatelessWidget {
  final Map<String, dynamic>? advancedMetrics;

  const RiskTab({super.key, this.advancedMetrics});

  @override
  Widget build(BuildContext context) {
    if (advancedMetrics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Pobierz metryki ryzyka z Firebase Functions data structure
    final portfolioMetrics =
        advancedMetrics?['portfolioMetrics'] as Map<String, dynamic>?;
    final riskMetrics =
        advancedMetrics?['riskMetrics'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: _getHorizontalPadding(context),
        vertical: _getVerticalSpacing(context),
      ),
      child: Column(
        children: [
          _buildRiskHeader(context),
          SizedBox(height: _getVerticalSpacing(context)),
          _buildRiskOverviewFromFirebase(
            context,
            portfolioMetrics,
            riskMetrics,
          ),
          SizedBox(height: _getVerticalSpacing(context)),
          _buildRiskDistributionFromFirebase(context, riskMetrics),
        ],
      ),
    );
  }

  Widget _buildRiskHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analiza Ryzyka',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ocena ryzyka portfela i analiza VaR',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        _buildRiskTooltip(),
      ],
    );
  }

  Widget _buildRiskTooltip() {
    return Tooltip(
      message:
          'Metryki ryzyka obejmują:\n'
          '• VaR - Value at Risk (maksymalna strata)\n'
          '• Volatilność - zmienność zwrotów\n'
          '• Beta - wrażliwość na rynek\n'
          '• Sharpe Ratio - współczynnik ryzyka/zwrotu',
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.help_outline, color: AppColors.primary, size: 18),
      ),
    );
  }

  Widget _buildRiskOverview(BuildContext context, RiskMetrics risk) {
    return Row(
      children: [
        Expanded(
          child: _buildRiskCard(
            title: 'Value at Risk',
            value: '${risk.valueAtRisk.toStringAsFixed(2)}%',
            subtitle: '95% poziom ufności',
            icon: Icons.trending_down,
            color: _getVaRColor(risk.valueAtRisk),
            level: _getRiskLevel(risk.valueAtRisk),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildRiskCard(
            title: 'Beta',
            value: risk.beta.toStringAsFixed(2),
            subtitle: 'Wrażliwość na rynek',
            icon: Icons.show_chart,
            color: _getBetaColor(risk.beta),
            level: _getBetaLevel(risk.beta),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildRiskCard(
            title: 'Volatilność',
            value: '${risk.volatility.toStringAsFixed(1)}%',
            subtitle: 'Odchylenie standardowe',
            icon: Icons.waves,
            color: _getVolatilityColor(risk.volatility),
            level: _getVolatilityLevel(risk.volatility),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String level,
  }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  level,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppTextStyles.headingMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskMatrix(BuildContext context) {
    return Container(
      height: 300,
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
            'Macierz Ryzyko/Zwrot',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ScatterChart(
              ScatterChartData(
                scatterSpots: _generateRiskReturnSpots(),
                minX: 0,
                maxX: 25,
                minY: -10,
                maxY: 20,
                backgroundColor: Colors.transparent,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: AppColors.borderColor, strokeWidth: 1),
                  getDrawingVerticalLine: (value) =>
                      FlLine(color: AppColors.borderColor, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                scatterTouchData: ScatterTouchData(
                  touchTooltipData: ScatterTouchTooltipData(
                    getTooltipColor: (touchedSpot) => AppColors.surface,
                    getTooltipItems: (touchedSpot) => ScatterTooltipItem(
                      'Ryzyko: ${touchedSpot.x.toStringAsFixed(1)}%\nZwrot: ${touchedSpot.y.toStringAsFixed(1)}%',
                      textStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskConcentration(BuildContext context, RiskMetrics risk) {
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
            'Koncentracja Ryzyka',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: _generateRiskConcentrationSections(),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                      startDegreeOffset: -90,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRiskLegendItem('Obligacje', AppColors.primary, '45%'),
                    const SizedBox(height: 8),
                    _buildRiskLegendItem('Udziały', AppColors.success, '30%'),
                    const SizedBox(height: 8),
                    _buildRiskLegendItem('Pożyczki', AppColors.warning, '15%'),
                    const SizedBox(height: 8),
                    _buildRiskLegendItem('Apartamenty', AppColors.info, '10%'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getConcentrationColor(
                          risk.concentrationRisk,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HHI Index',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            risk.concentrationRisk.toStringAsFixed(0),
                            style: AppTextStyles.titleMedium.copyWith(
                              color: _getConcentrationColor(
                                risk.concentrationRisk,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVaRAnalysis(BuildContext context, RiskMetrics risk) {
    // Oblicz VaR dla różnych poziomów
    final var95_1day = risk.valueAtRisk;
    final var99_1day = var95_1day * 1.28; // Standardowy mnożnik

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
            'Value at Risk (VaR) Analysis',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildVaRItem(
                  'VaR 95% (1 dzień)',
                  '${var95_1day.toStringAsFixed(2)}%',
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildVaRItem(
                  'VaR 99% (1 dzień)',
                  '${var99_1day.toStringAsFixed(2)}%',
                  AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interpretacja VaR',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Z 95% prawdopodobieństwem dzienna strata nie przekroczy ${var95_1day.toStringAsFixed(2)}% wartości portfela.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaRItem(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskLegendItem(String label, Color color, String percentage) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.text),
          ),
        ),
        Text(
          percentage,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
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

  String _getRiskLevel(double var95) {
    if (var95 < 5) return 'Niskie';
    if (var95 < 10) return 'Średnie';
    if (var95 < 15) return 'Wysokie';
    return 'Bardzo Wysokie';
  }

  Color _getVaRColor(double var95) {
    if (var95 < 5) return AppColors.success;
    if (var95 < 10) return AppColors.warning;
    return AppColors.error;
  }

  Color _getBetaColor(double beta) {
    if (beta < 0.8) return AppColors.success;
    if (beta < 1.2) return AppColors.warning;
    return AppColors.error;
  }

  String _getBetaLevel(double beta) {
    if (beta < 0.8) return 'Defensywny';
    if (beta < 1.2) return 'Neutralny';
    return 'Agresywny';
  }

  Color _getVolatilityColor(double volatility) {
    if (volatility < 10) return AppColors.success;
    if (volatility < 20) return AppColors.warning;
    return AppColors.error;
  }

  String _getVolatilityLevel(double volatility) {
    if (volatility < 10) return 'Stabilny';
    if (volatility < 20) return 'Umiarkowany';
    return 'Niestabilny';
  }

  Color _getConcentrationColor(double concentration) {
    if (concentration < 1800) return AppColors.success;
    if (concentration < 2500) return AppColors.warning;
    return AppColors.error;
  }

  List<ScatterSpot> _generateRiskReturnSpots() {
    // Generuj przykładowe dane risk/return
    return [
      ScatterSpot(5, 8),
      ScatterSpot(12, 15),
      ScatterSpot(18, 12),
      ScatterSpot(8, 10),
      ScatterSpot(15, 18),
    ];
  }

  List<PieChartSectionData> _generateRiskConcentrationSections() {
    return [
      PieChartSectionData(
        color: AppColors.primary,
        value: 45,
        title: '45%',
        radius: 60,
        titleStyle: AppTextStyles.bodySmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      PieChartSectionData(
        color: AppColors.success,
        value: 30,
        title: '30%',
        radius: 60,
        titleStyle: AppTextStyles.bodySmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      PieChartSectionData(
        color: AppColors.warning,
        value: 15,
        title: '15%',
        radius: 60,
        titleStyle: AppTextStyles.bodySmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      PieChartSectionData(
        color: AppColors.info,
        value: 10,
        title: '10%',
        radius: 60,
        titleStyle: AppTextStyles.bodySmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ];
  }

  // 📊 METODY UŻYWAJĄCE DANYCH Z FIREBASE FUNCTIONS

  Widget _buildRiskOverviewFromFirebase(
    BuildContext context,
    Map<String, dynamic>? portfolioMetrics,
    Map<String, dynamic>? riskMetrics,
  ) {
    if (portfolioMetrics == null && riskMetrics == null) {
      return const Center(child: Text('Brak danych o ryzyku'));
    }

    final totalValue =
        (portfolioMetrics?['totalValue'] as num?)?.toDouble() ?? 0.0;
    final totalInvestments =
        portfolioMetrics?['totalInvestmentsCount'] as int? ?? 0;
    final avgRisk = (riskMetrics?['averageRisk'] as num?)?.toDouble() ?? 0.0;
    final volatility = (riskMetrics?['volatility'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: EdgeInsets.all(_getHorizontalPadding(context)),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Przegląd Ryzyka', style: AppTextStyles.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRiskMetricCard(
                  'Wartość Portfela',
                  _formatCurrency(totalValue),
                  Icons.account_balance_wallet,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRiskMetricCard(
                  'Inwestycje',
                  totalInvestments.toString(),
                  Icons.pie_chart,
                  AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRiskMetricCard(
                  'Średnie Ryzyko',
                  '${avgRisk.toStringAsFixed(1)}/10',
                  Icons.warning,
                  _getRiskColor(avgRisk),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRiskMetricCard(
                  'Zmienność',
                  '${(volatility * 100).toStringAsFixed(1)}%',
                  Icons.trending_up,
                  AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskDistributionFromFirebase(
    BuildContext context,
    Map<String, dynamic>? riskMetrics,
  ) {
    if (riskMetrics == null) {
      return const SizedBox.shrink();
    }

    final distribution =
        riskMetrics['riskDistribution'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: EdgeInsets.all(_getHorizontalPadding(context)),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rozkład Ryzyka', style: AppTextStyles.titleMedium),
          const SizedBox(height: 16),
          ...distribution.entries.map(
            (entry) => _buildRiskDistributionItem(
              entry.key,
              (entry.value as num?)?.toDouble() ?? 0.0,
            ),
          ),
          if (distribution.isEmpty)
            const Center(child: Text('Brak danych o rozkładzie ryzyka')),
        ],
      ),
    );
  }

  Widget _buildRiskMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRiskDistributionItem(String riskLevel, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(riskLevel.toUpperCase(), style: AppTextStyles.bodyMedium),
          Row(
            children: [
              Container(
                width: 100,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.borderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getRiskLevelColor(riskLevel),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(double risk) {
    if (risk <= 3) return AppColors.success;
    if (risk <= 6) return AppColors.warning;
    return AppColors.error;
  }

  Color _getRiskLevelColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
      case 'niskie':
        return AppColors.success;
      case 'medium':
      case 'średnie':
        return AppColors.warning;
      case 'high':
      case 'wysokie':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M PLN';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K PLN';
    } else {
      return '${value.toStringAsFixed(0)} PLN';
    }
  }
}
