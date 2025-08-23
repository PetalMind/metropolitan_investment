import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';
import 'dart:math' as math;

class PerformanceMetricsWidget extends StatefulWidget {
  final bool isLoading;
  final bool isTablet;
  final List<InvestorSummary> allInvestors;
  final double totalViableCapital;

  const PerformanceMetricsWidget({
    super.key,
    required this.isLoading,
    required this.isTablet,
    required this.allInvestors,
    required this.totalViableCapital,
  });

  @override
  State<PerformanceMetricsWidget> createState() => _PerformanceMetricsWidgetState();
}

class _PerformanceMetricsWidgetState extends State<PerformanceMetricsWidget>
    with TickerProviderStateMixin {
  late AnimationController _primaryAnimationController;
  late AnimationController _secondaryAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _primaryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _secondaryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _primaryAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _primaryAnimationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _primaryAnimationController,
      curve: const Interval(0.3, 1.0, curve: Curves.decelerate),
    ));

    if (!widget.isLoading) {
      _primaryAnimationController.forward();
    }
  }

  @override
  void didUpdateWidget(PerformanceMetricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLoading && oldWidget.isLoading) {
      _primaryAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _primaryAnimationController.dispose();
    _secondaryAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(widget.isTablet ? 16 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.surfaceCard,
            AppThemePro.backgroundSecondary,
            AppThemePro.surfaceCard.withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppThemePro.accentGold.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppThemePro.accentGold.withValues(alpha: 0.1),
            blurRadius: 50,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.accentGold.withValues(alpha: 0.1),
            AppThemePro.accentGoldMuted.withValues(alpha: 0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppThemePro.accentGold.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppThemePro.accentGold,
                  AppThemePro.accentGoldMuted,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppThemePro.accentGold.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.analytics_rounded,
              color: AppThemePro.primaryDark,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Metryki wydajności portfela',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Analiza kluczowych wskaźników finansowych',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemePro.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (widget.isLoading)
            Container(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppThemePro.accentGold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    return AnimatedBuilder(
      animation: _primaryAnimationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildMetricsGrid(),
                    const SizedBox(height: 24),
                    _buildPerformanceChart(),
                    const SizedBox(height: 24),
                    _buildRiskMetrics(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: widget.isTablet ? 4 : 2,
            childAspectRatio: widget.isTablet ? 1.4 : 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: List.generate(4, (index) => _buildShimmerCard()),
          ),
          const SizedBox(height: 24),
          _buildShimmerChart(),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final metrics = _calculatePerformanceMetrics();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: widget.isTablet ? 4 : 2,
      childAspectRatio: widget.isTablet ? 1.4 : 1.2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildEnhancedMetricCard(
          'ROI Średni',
          metrics['avgROI']!,
          Icons.trending_up_rounded,
          AppThemePro.statusSuccess,
          'Średni zwrot z inwestycji',
          0,
        ),
        _buildEnhancedMetricCard(
          'Najwyższy ROI',
          metrics['maxROI']!,
          Icons.star_rounded,
          AppThemePro.accentGold,
          'Maksymalny uzyskany zwrot',
          1,
        ),
        _buildEnhancedMetricCard(
          'Efektywność',
          metrics['efficiency']!,
          Icons.speed_rounded,
          AppThemePro.statusWarning,
          'Współczynnik efektywności',
          2,
        ),
        _buildEnhancedMetricCard(
          'Wskaźnik Sharpe',
          metrics['sharpeRatio']!,
          Icons.analytics_rounded,
          AppThemePro.statusInfo,
          'Stosunek zwrotu do ryzyka',
          3,
        ),
      ],
    );
  }

  Widget _buildEnhancedMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String description,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (index * 200)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showMetricDetails(title, value, description),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppThemePro.backgroundTertiary,
                      AppThemePro.surfaceElevated,
                      color.withValues(alpha: 0.05),
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: 24,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppThemePro.textMuted,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: TextStyle(
                        color: AppThemePro.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 1000 + (index * 150)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOut,
                      builder: (context, countValue, child) {
                        final displayValue = value.contains('%')
                            ? '${(double.parse(value.replaceAll('%', '')) * countValue).toStringAsFixed(1)}%'
                            : (double.parse(value) * countValue).toStringAsFixed(2);
                        
                        return Text(
                          displayValue,
                          style: TextStyle(
                            color: AppThemePro.textPrimary,
                            fontSize: widget.isTablet ? 22 : 18,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppThemePro.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPerformanceChart() {
    final portfolioData = _calculatePortfolioBreakdown();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.backgroundTertiary,
            AppThemePro.surfaceElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemePro.accentGold.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              Icon(
                Icons.pie_chart_rounded,
                color: AppThemePro.accentGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Rozkład wydajności portfela',
                style: TextStyle(
                  color: AppThemePro.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                // Wykres kołowy fl_chart
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _buildPieSections(portfolioData),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Legenda
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('Obligacje', AppThemePro.bondsBlue, portfolioData['bonds']!),
                      const SizedBox(height: 12),
                      _buildLegendItem('Udziały', AppThemePro.sharesGreen, portfolioData['shares']!),
                      const SizedBox(height: 12),
                      _buildLegendItem('Pożyczki', AppThemePro.loansOrange, portfolioData['loans']!),
                      const SizedBox(height: 12),
                      _buildLegendItem('Apartamenty', AppThemePro.realEstateViolet, portfolioData['apartments']!),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, double value) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppThemePro.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${value.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: AppThemePro.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildRiskMetrics() {
    final riskData = _calculateRiskBreakdown();
    
    return Container(
      height: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.backgroundTertiary,
            AppThemePro.surfaceElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemePro.statusWarning.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_rounded,
                color: AppThemePro.statusWarning,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Analiza ryzyka portfela',
                style: TextStyle(
                  color: AppThemePro.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: math.max(
                  math.max(riskData['low']!, riskData['medium']!), 
                  riskData['high']!
                ) * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => AppThemePro.surfaceCard,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String riskLevel;
                      switch (groupIndex) {
                        case 0: riskLevel = 'Niskie ryzyko'; break;
                        case 1: riskLevel = 'Średnie ryzyko'; break;
                        case 2: riskLevel = 'Wysokie ryzyko'; break;
                        default: riskLevel = 'Nieznane';
                      }
                      return BarTooltipItem(
                        '$riskLevel\n${rod.toY.toStringAsFixed(1)}%',
                        TextStyle(
                          color: AppThemePro.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        String text;
                        switch (value.toInt()) {
                          case 0: text = 'Niskie'; break;
                          case 1: text = 'Średnie'; break;
                          case 2: text = 'Wysokie'; break;
                          default: text = '';
                        }
                        return Text(
                          text,
                          style: TextStyle(
                            color: AppThemePro.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: TextStyle(
                            color: AppThemePro.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppThemePro.borderSecondary.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: AppThemePro.borderSecondary.withValues(alpha: 0.3)),
                    bottom: BorderSide(color: AppThemePro.borderSecondary.withValues(alpha: 0.3)),
                  ),
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: riskData['low']!,
                        color: AppThemePro.statusSuccess,
                        width: 30,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: riskData['medium']!,
                        color: AppThemePro.statusWarning,
                        width: 30,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: riskData['high']!,
                        color: AppThemePro.statusError,
                        width: 30,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildShimmerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemePro.borderSecondary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppThemePro.backgroundTertiary,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const Spacer(),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppThemePro.backgroundTertiary,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: AppThemePro.backgroundTertiary,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 60,
            height: 20,
            decoration: BoxDecoration(
              color: AppThemePro.backgroundTertiary,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const Spacer(),
          Container(
            width: 100,
            height: 10,
            decoration: BoxDecoration(
              color: AppThemePro.backgroundTertiary,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerChart() {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemePro.borderSecondary,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _showMetricDetails(String title, String value, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppThemePro.surfaceCard,
        title: Text(
          title,
          style: TextStyle(color: AppThemePro.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wartość: $value',
              style: TextStyle(
                color: AppThemePro.accentGold,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(color: AppThemePro.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Zamknij',
              style: TextStyle(color: AppThemePro.accentGold),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _calculatePerformanceMetrics() {
    if (widget.allInvestors.isEmpty) {
      return {
        'avgROI': '0.0',
        'maxROI': '0.0',
        'efficiency': '0.0',
        'sharpeRatio': '0.00',
      };
    }

    // Prawdziwe metryki bazowane na rzeczywistych danych portfela
    final totalCapital = widget.totalViableCapital;
    final totalInvestment = widget.allInvestors.fold<double>(
      0.0, (sum, investor) => sum + investor.totalInvestmentAmount
    );
    final totalRealized = widget.allInvestors.fold<double>(
      0.0, (sum, investor) => sum + investor.totalRealizedCapital
    );

    // Rzeczywisty ROI bazowany na danych
    final avgROI = totalInvestment > 0 
        ? ((totalCapital + totalRealized - totalInvestment) / totalInvestment * 100)
        : 0.0;
    
    // Znajdź najlepszego inwestora
    double maxROI = 0.0;
    for (final investor in widget.allInvestors) {
      if (investor.totalInvestmentAmount > 0) {
        final investorROI = ((investor.totalRemainingCapital + investor.totalRealizedCapital - investor.totalInvestmentAmount) / investor.totalInvestmentAmount * 100);
        if (investorROI > maxROI) {
          maxROI = investorROI;
        }
      }
    }
    
    // Efektywność portfela - stosunek kapitału pozostałego do zainwestowanego
    final efficiency = totalInvestment > 0 
        ? (totalCapital / totalInvestment * 100)
        : 0.0;
    
    // Wskaźnik Sharpe - uproszczony (ROI / odchylenie standardowe ROI)
    final rois = <double>[];
    for (final investor in widget.allInvestors) {
      if (investor.totalInvestmentAmount > 0) {
        final roi = ((investor.totalRemainingCapital + investor.totalRealizedCapital - investor.totalInvestmentAmount) / investor.totalInvestmentAmount * 100);
        rois.add(roi);
      }
    }
    
    double sharpeRatio = 0.0;
    if (rois.isNotEmpty) {
      final mean = rois.reduce((a, b) => a + b) / rois.length;
      final variance = rois.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / rois.length;
      final stdDev = math.sqrt(variance);
      sharpeRatio = stdDev > 0 ? mean / stdDev : 0.0;
    }

    return {
      'avgROI': avgROI.toStringAsFixed(1),
      'maxROI': maxROI.toStringAsFixed(1),
      'efficiency': efficiency.toStringAsFixed(1),
      'sharpeRatio': sharpeRatio.toStringAsFixed(2),
    };
  }

  Map<String, double> _calculatePortfolioBreakdown() {
    if (widget.allInvestors.isEmpty) {
      return {
        'bonds': 0.0,
        'shares': 0.0,
        'loans': 0.0,
        'apartments': 0.0,
      };
    }

    double bondsCapital = 0.0;
    double sharesCapital = 0.0;
    double loansCapital = 0.0;
    double apartmentsCapital = 0.0;
    double totalCapital = 0.0;

    // Oblicz kapitał dla każdego typu produktu
    for (final investor in widget.allInvestors) {
      for (final investment in investor.investments) {
        final capital = investment.remainingCapital;
        totalCapital += capital;
        
        switch (investment.productType) {
          case ProductType.bonds:
            bondsCapital += capital;
            break;
          case ProductType.shares:
            sharesCapital += capital;
            break;
          case ProductType.loans:
            loansCapital += capital;
            break;
          case ProductType.apartments:
            apartmentsCapital += capital;
            break;
        }
      }
    }

    // Zwróć wartości procentowe
    if (totalCapital <= 0) {
      return {
        'bonds': 0.0,
        'shares': 0.0,
        'loans': 0.0,
        'apartments': 0.0,
      };
    }

    final result = {
      'bonds': (bondsCapital / totalCapital) * 100,
      'shares': (sharesCapital / totalCapital) * 100,
      'loans': (loansCapital / totalCapital) * 100,
      'apartments': (apartmentsCapital / totalCapital) * 100,
    };


    return result;
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> portfolioData) {
    final sections = <PieChartSectionData>[];
    
    // Dane sekcji z kolorami i nazwami
    final sectionData = [
      {
        'key': 'bonds',
        'color': AppThemePro.bondsBlue,
        'name': 'Obligacje'
      },
      {
        'key': 'shares',
        'color': AppThemePro.sharesGreen,
        'name': 'Udziały'
      },
      {
        'key': 'loans',
        'color': AppThemePro.loansOrange,
        'name': 'Pożyczki'
      },
      {
        'key': 'apartments',
        'color': AppThemePro.realEstateViolet,
        'name': 'Apartamenty'
      },
    ];

    for (final section in sectionData) {
      final value = portfolioData[section['key'] as String] ?? 0.0;
      
      // Dodaj sekcję tylko gdy wartość > 0
      if (value > 0.1) { // Minimum 0.1% żeby było widoczne
        sections.add(
          PieChartSectionData(
            color: section['color'] as Color,
            value: value,
            title: value > 5.0 ? '${value.toStringAsFixed(1)}%' : '',
            radius: 60,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        );
      }
    }
    
    // Jeśli nie ma żadnych sekcji, dodaj placeholder
    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          color: AppThemePro.textMuted,
          value: 100,
          title: 'Brak danych',
          radius: 60,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
    }
    
    return sections;
  }

  Map<String, double> _calculateRiskBreakdown() {
    if (widget.allInvestors.isEmpty) {
      return {
        'low': 0.0,
        'medium': 0.0,
        'high': 0.0,
      };
    }

    double lowRiskCapital = 0.0;
    double mediumRiskCapital = 0.0;
    double highRiskCapital = 0.0;
    double totalCapital = 0.0;

    // Analiza ryzyka na podstawie typu produktów i kapitału
    for (final investor in widget.allInvestors) {
      for (final investment in investor.investments) {
        final capital = investment.remainingCapital;
        totalCapital += capital;
        
        // Przypisanie ryzyka na podstawie typu produktu
        switch (investment.productType) {
          case ProductType.bonds:
            // Obligacje - niskie ryzyko
            lowRiskCapital += capital;
            break;
          case ProductType.shares:
            // Udziały - wysokie ryzyko
            highRiskCapital += capital;
            break;
          case ProductType.loans:
            // Pożyczki - średnie ryzyko
            mediumRiskCapital += capital;
            break;
          case ProductType.apartments:
            // Apartamenty - niskie do średniego ryzyka
            // Dzielimy 70% niskie, 30% średnie
            lowRiskCapital += capital * 0.7;
            mediumRiskCapital += capital * 0.3;
            break;
        }
      }
    }

    // Zwróć wartości procentowe
    if (totalCapital <= 0) {
      return {
        'low': 0.0,
        'medium': 0.0,
        'high': 0.0,
      };
    }

    return {
      'low': (lowRiskCapital / totalCapital) * 100,
      'medium': (mediumRiskCapital / totalCapital) * 100,
      'high': (highRiskCapital / totalCapital) * 100,
    };
  }
}