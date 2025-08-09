import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../services/advanced_analytics_service.dart';
import '../../models/investment.dart';
import '../../utils/currency_formatter.dart';

// Alias dla AppColors i AppTextStyles z AppTheme
class AppColors {
  static const Color text = AppTheme.textPrimary;
  static const Color textSecondary = AppTheme.textSecondary;
  static const Color primary = AppTheme.primaryColor;
  static const Color primaryLight = AppTheme.primaryLight;
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
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppTheme.textSecondary,
  );
}

class PerformanceTab extends StatelessWidget {
  final Map<String, dynamic>? advancedMetrics;

  const PerformanceTab({super.key, this.advancedMetrics});

  @override
  Widget build(BuildContext context) {
    if (advancedMetrics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Pobierz metryki wydajności z Firebase Functions data structure
    final performanceData =
        advancedMetrics?['portfolioMetrics'] as Map<String, dynamic>?;
    final timeSeriesData =
        advancedMetrics?['timeSeriesPerformance'] as List<dynamic>?;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: _getHorizontalPadding(context),
        vertical: _getVerticalSpacing(context),
      ),
      child: Column(
        children: [
          _buildPerformanceHeader(context),
          SizedBox(height: _getVerticalSpacing(context)),
          _buildPerformanceOverviewFromFirebase(context, performanceData),
          SizedBox(height: _getVerticalSpacing(context)),
          _buildPerformanceChartFromFirebase(context, timeSeriesData),
          SizedBox(height: _getVerticalSpacing(context)),
          _buildProductPerformanceFromFirebase(context, performanceData),
        ],
      ),
    );
  }

  Widget _buildPerformanceHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wydajność Portfela',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Analiza zwrotów i wydajności inwestycji',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        _buildPerformanceTooltip(),
      ],
    );
  }

  Widget _buildPerformanceTooltip() {
    return Tooltip(
      message:
          'Metryki wydajności uwzględniają wszystkie typy produktów '
          'z uwzględnieniem ryzyka i benchmarków rynkowych. '
          'ROI = (Wartość obecna - Inwestycja) / Inwestycja * 100',
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.help_outline, color: AppColors.primary, size: 18),
      ),
    );
  }

  Widget _buildPerformanceOverview(
    BuildContext context,
    PerformanceMetrics performance,
  ) {
    final cards = [
      _buildPerformanceCard(
        context: context,
        title: 'Całkowity ROI',
        value: '${performance.totalROI.toStringAsFixed(1)}%',
        subtitle: 'Zwrot z inwestycji',
        icon: Icons.trending_up,
        color: performance.totalROI >= 0 ? AppColors.success : AppColors.error,
        trend: performance.totalROI >= 0 ? '↗' : '↘',
      ),
      _buildPerformanceCard(
        context: context,
        title: 'Roczny Zwrot',
        value: '${performance.annualizedReturn.toStringAsFixed(1)}%',
        subtitle: 'CAGR',
        icon: Icons.calendar_today,
        color: performance.annualizedReturn >= 5
            ? AppColors.success
            : AppColors.warning,
      ),
      _buildPerformanceCard(
        context: context,
        title: 'Współczynnik Sharpe',
        value: performance.sharpeRatio.toStringAsFixed(2),
        subtitle: 'Ryzyko/Zwrot',
        icon: Icons.balance,
        color: _getSharpeColor(performance.sharpeRatio),
      ),
      _buildPerformanceCard(
        context: context,
        title: 'Sukces Rate',
        value: '${performance.successRate.toStringAsFixed(0)}%',
        subtitle: 'Zyskownych inwestycji',
        icon: Icons.check_circle,
        color: AppColors.info,
      ),
    ];

    // Responsywny układ - Column na mobile, Row na desktop
    if (_isMobile(context)) {
      return Column(
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: card,
              ),
            )
            .toList(),
      );
    } else {
      return Row(
        children: cards
            .map(
              (card) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: card,
                ),
              ),
            )
            .toList(),
      );
    }
  }

  Widget _buildPerformanceCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? trend,
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
              if (trend != null)
                Text(
                  trend,
                  style: TextStyle(
                    fontSize: 18,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
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

  Widget _buildPerformanceChart(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Wydajność w Czasie',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  _buildLegendItem('Portfolio', AppColors.primary),
                  const SizedBox(width: 16),
                  _buildLegendItem('Benchmark', AppColors.secondary),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: AppColors.borderColor, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            _getMonthLabel(value.toInt()),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 11,
                minY: -5,
                maxY: 20,
                lineBarsData: [
                  LineChartBarData(
                    spots: _generatePerformanceSpots(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: AppColors.cardBackground,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: _generateBenchmarkSpots(),
                    isCurved: true,
                    color: AppColors.secondary,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductPerformanceAnalysis(
    BuildContext context,
    PerformanceMetrics performance,
  ) {
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
            'Wydajność według Typu Produktu',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...performance.productPerformance.entries.map(
            (entry) => _buildProductPerformanceItem(entry.key, entry.value),
          ),
        ],
      ),
    );
  }

  Widget _buildProductPerformanceItem(String productType, double performance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getProductTypeColor(productType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getProductIcon(productType),
              color: _getProductTypeColor(productType),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getProductDisplayName(productType),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Średni zwrot',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: performance >= 0
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${performance.toStringAsFixed(1)}%',
              style: AppTextStyles.bodyMedium.copyWith(
                color: performance >= 0 ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformersSection(
    BuildContext context,
    PerformanceMetrics performance,
  ) {
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
            'Najlepsze Inwestycje',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...performance.topPerformers
              .take(5)
              .map((investment) => _buildTopPerformerItem(investment)),
        ],
      ),
    );
  }

  Widget _buildTopPerformerItem(Investment investment) {
    final performance = _calculateInvestmentPerformance(investment);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      investment.clientName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      investment.productName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: performance >= 0
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${performance.toStringAsFixed(1)}%',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: performance >= 0
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.formatCurrency(investment.totalValue),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods
  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;
  double _getHorizontalPadding(BuildContext context) =>
      _isMobile(context) ? 16.0 : 24.0;
  double _getVerticalSpacing(BuildContext context) =>
      _isMobile(context) ? 16.0 : 24.0;

  Color _getSharpeColor(double sharpe) {
    if (sharpe > 1) return AppColors.success;
    if (sharpe > 0.5) return AppColors.warning;
    return AppColors.error;
  }

  String _getMonthLabel(int index) {
    const months = [
      'Sty',
      'Lut',
      'Mar',
      'Kwi',
      'Maj',
      'Cze',
      'Lip',
      'Sie',
      'Wrz',
      'Paź',
      'Lis',
      'Gru',
    ];
    return months[index % 12];
  }

  List<FlSpot> _generatePerformanceSpots() {
    // Generuj przykładowe dane wydajności
    return List.generate(12, (index) {
      final baseReturn = 5.0;
      final volatility = 3.0;
      final trend = index * 0.5;
      final noise = (index % 3 - 1) * volatility;
      return FlSpot(index.toDouble(), baseReturn + trend + noise);
    });
  }

  List<FlSpot> _generateBenchmarkSpots() {
    // Generuj benchmark (stała linia 5%)
    return List.generate(12, (index) => FlSpot(index.toDouble(), 5.0));
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
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  IconData _getProductIcon(String productType) {
    switch (productType.toLowerCase()) {
      case 'bonds':
      case 'obligacje':
        return Icons.account_balance;
      case 'shares':
      case 'udziały':
        return Icons.trending_up;
      case 'loans':
      case 'pożyczki':
        return Icons.monetization_on;
      case 'apartments':
      case 'apartamenty':
        return Icons.apartment;
      default:
        return Icons.business_center;
    }
  }

  Color _getProductTypeColor(String productType) {
    switch (productType.toLowerCase()) {
      case 'bonds':
      case 'obligacje':
        return AppColors.primary;
      case 'shares':
      case 'udziały':
        return AppColors.success;
      case 'loans':
      case 'pożyczki':
        return AppColors.warning;
      case 'apartments':
      case 'apartamenty':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getProductDisplayName(String productType) {
    switch (productType.toLowerCase()) {
      case 'bonds':
        return 'Obligacje';
      case 'shares':
        return 'Udziały';
      case 'loans':
        return 'Pożyczki';
      case 'apartments':
        return 'Apartamenty';
      default:
        return productType;
    }
  }

  double _calculateInvestmentPerformance(Investment investment) {
    if (investment.investmentAmount == 0) return 0;
    return ((investment.totalValue - investment.investmentAmount) /
            investment.investmentAmount) *
        100;
  }

  // 📊 METODY UŻYWAJĄCE DANYCH Z FIREBASE FUNCTIONS

  Widget _buildPerformanceOverviewFromFirebase(
    BuildContext context,
    Map<String, dynamic>? performanceData,
  ) {
    if (performanceData == null) {
      return const Center(child: Text('Brak danych wydajności'));
    }

    final totalValue =
        (performanceData['totalValue'] as num?)?.toDouble() ?? 0.0;
    final roi = (performanceData['roi'] as num?)?.toDouble() ?? 0.0;
    final totalInvestments =
        performanceData['totalInvestmentsCount'] as int? ?? 0;
    final viableCapital =
        (performanceData['viableRemainingCapital'] as num?)?.toDouble() ?? 0.0;

    final cards = [
      _buildPerformanceCard(
        context: context,
        title: 'Wartość Portfela',
        value: _formatCurrencyLocal(totalValue),
        subtitle: 'Łączna wartość',
        icon: Icons.account_balance_wallet,
        color: AppColors.primary,
      ),
      _buildPerformanceCard(
        context: context,
        title: 'ROI',
        value: '${roi.toStringAsFixed(1)}%',
        subtitle: 'Zwrot z inwestycji',
        icon: Icons.trending_up,
        color: roi >= 0 ? AppColors.success : AppColors.error,
        trend: roi >= 0 ? '↗' : '↘',
      ),
      _buildPerformanceCard(
        context: context,
        title: 'Inwestycje',
        value: totalInvestments.toString(),
        subtitle: 'Aktywnych pozycji',
        icon: Icons.pie_chart,
        color: AppColors.info,
      ),
      _buildPerformanceCard(
        context: context,
        title: 'Kapitał Pozostały',
        value: _formatCurrencyLocal(viableCapital),
        subtitle: 'Do spłaty',
        icon: Icons.account_balance,
        color: AppColors.warning,
      ),
    ];

    // Responsywny układ
    if (_isMobile(context)) {
      return Column(
        children: cards
            .map(
              (card) => Padding(
                padding: EdgeInsets.only(bottom: _getVerticalSpacing(context)),
                child: card,
              ),
            )
            .toList(),
      );
    }

    return Row(
      children: cards
          .map(
            (card) => Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: _getHorizontalPadding(context) / 4,
                ),
                child: card,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPerformanceChartFromFirebase(
    BuildContext context,
    List<dynamic>? timeSeriesData,
  ) {
    if (timeSeriesData == null || timeSeriesData.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('Brak danych do wykresu czasowego')),
      );
    }

    return Container(
      height: 350,
      padding: EdgeInsets.all(_getHorizontalPadding(context)),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wykres Wydajności', style: AppTextStyles.titleMedium),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Text(
                'Wykres czasowy (${timeSeriesData.length} punktów danych)',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductPerformanceFromFirebase(
    BuildContext context,
    Map<String, dynamic>? performanceData,
  ) {
    if (performanceData == null) {
      return const SizedBox.shrink();
    }

    // Ekstraktuj metryki produktów z danych
    final productBreakdown =
        performanceData['productBreakdown'] as Map<String, dynamic>? ?? {};

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
          Text('Analiza Produktów', style: AppTextStyles.titleMedium),
          const SizedBox(height: 16),
          ...productBreakdown.entries.map(
            (entry) => _buildProductPerformanceItemFromFirebase(
              entry.key,
              entry.value as Map<String, dynamic>? ?? {},
            ),
          ),
          if (productBreakdown.isEmpty)
            const Center(child: Text('Brak danych o produktach')),
        ],
      ),
    );
  }

  Widget _buildProductPerformanceItemFromFirebase(
    String productType,
    Map<String, dynamic> data,
  ) {
    final count = data['count'] as int? ?? 0;
    final value = (data['totalValue'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(productType.toUpperCase(), style: AppTextStyles.bodyMedium),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrencyLocal(value),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('$count pozycji', style: AppTextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrencyLocal(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M PLN';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K PLN';
    } else {
      return '${value.toStringAsFixed(0)} PLN';
    }
  }
}
