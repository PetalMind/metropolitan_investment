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
  late AnimationController _chartAnimationController;
  late AnimationController _metricsAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _chartAnimation;
  late Animation<double> _metricsAnimation;
  
  int _selectedTabIndex = 0;
  int _hoveredMetricIndex = -1;
  bool _showAdvancedMetrics = false;

  @override
  void initState() {
    super.initState();
    _primaryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _metricsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _primaryAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _primaryAnimationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _primaryAnimationController,
      curve: const Interval(0.3, 1.0, curve: Curves.decelerate),
    ));
    
    _chartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeInOutQuart,
    ));
    
    _metricsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _metricsAnimationController,
      curve: Curves.easeOutExpo,
    ));

    if (!widget.isLoading) {
      _startAnimations();
    }
  }
  
  void _startAnimations() {
    _primaryAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _chartAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _metricsAnimationController.forward();
    });
  }

  @override
  void didUpdateWidget(PerformanceMetricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLoading && oldWidget.isLoading) {
      _startAnimations();
    }
  }

  @override
  void dispose() {
    _primaryAnimationController.dispose();
    _chartAnimationController.dispose();
    _metricsAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(widget.isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.surfaceCard,
            AppThemePro.backgroundSecondary,
            AppThemePro.surfaceCard.withValues(alpha: 0.95),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppThemePro.accentGold.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppThemePro.accentGold.withValues(alpha: 0.15),
            blurRadius: 60,
            offset: const Offset(0, 25),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdvancedHeader(context),
            _buildTabNavigation(),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.accentGold.withValues(alpha: 0.12),
            AppThemePro.accentGoldMuted.withValues(alpha: 0.08),
            AppThemePro.accentGold.withValues(alpha: 0.06),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppThemePro.accentGold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppThemePro.accentGold,
                  AppThemePro.accentGoldMuted,
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppThemePro.accentGold.withValues(alpha: 0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.analytics_rounded,
              color: AppThemePro.primaryDark,
              size: 32,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analiza Inwestorów i Portfela',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: widget.isTablet ? 26 : 22,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'KPI inwestorów, struktura portfela i aktywność w czasie',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppThemePro.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (widget.isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppThemePro.accentGold),
                ),
              ),
            ),
          if (!widget.isLoading)
            IconButton(
              onPressed: () => setState(() => _showAdvancedMetrics = !_showAdvancedMetrics),
              icon: Icon(
                _showAdvancedMetrics ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: AppThemePro.accentGold,
                size: 24,
              ),
              tooltip: _showAdvancedMetrics ? 'Ukryj szczegóły' : 'Pokaż szczegóły',
            ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation() {
    if (widget.isLoading) return const SizedBox.shrink();
    
    final tabs = [
      {'label': 'KPI Ogólne', 'icon': Icons.dashboard_rounded},
      {'label': 'Struktura', 'icon': Icons.pie_chart_rounded},
      {'label': 'Ranking', 'icon': Icons.leaderboard_rounded},
    ];

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == _selectedTabIndex;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: isSelected ? LinearGradient(
                    colors: [
                      AppThemePro.accentGold.withValues(alpha: 0.2),
                      AppThemePro.accentGoldMuted.withValues(alpha: 0.15),
                    ],
                  ) : null,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected ? Border.all(
                    color: AppThemePro.accentGold.withValues(alpha: 0.4),
                  ) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      color: isSelected ? AppThemePro.accentGold : AppThemePro.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        color: isSelected ? AppThemePro.accentGold : AppThemePro.textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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
                padding: const EdgeInsets.all(28),
                child: _buildTabContent(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildKPIGeneralTab();
      case 1:
        return _buildStructureTab();
      case 2:
        return _buildRankingTab();
      default:
        return _buildKPIGeneralTab();
    }
  }

  Widget _buildKPIGeneralTab() {
    return Column(
      children: [
        _buildGeneralKPIGrid(),
        const SizedBox(height: 32),
        _buildCapitalOverviewChart(),
        if (_showAdvancedMetrics) ...[
          const SizedBox(height: 32),
          _buildRiskDistributionChart(),
        ],
      ],
    );
  }

  Widget _buildStructureTab() {
    return Column(
      children: [
        _buildStructureOverview(),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: _buildInvestmentValueDistribution()),
            const SizedBox(width: 24),
            Expanded(child: _buildDiversificationChart()),
          ],
        ),
        if (_showAdvancedMetrics) ...[
          const SizedBox(height: 32),
          _buildSegmentationHeatmap(),
        ],
      ],
    );
  }


  Widget _buildRankingTab() {
    return Column(
      children: [
        _buildTopInvestorsTable(),
        const SizedBox(height: 32),
        _buildInvestorSegmentation(),
      ],
    );
  }

  Widget _buildGeneralKPIGrid() {
    final kpis = _calculateGeneralKPIs();
    
    return AnimatedBuilder(
      animation: _metricsAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_metricsAnimation.value * 0.2),
          child: Opacity(
            opacity: _metricsAnimation.value,
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: widget.isTablet ? 4 : 2,
              childAspectRatio: widget.isTablet ? 1.3 : 1.1,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              children: [
                _buildKPICard(
                  'Liczba Inwestorów',
                  kpis['totalInvestors']!,
                  Icons.people_rounded,
                  AppThemePro.statusInfo,
                  'Wszyscy zarejestrowani inwestorzy',
                  0,
                ),
                _buildKPICard(
                  'Łączny Kapitał',
                  kpis['totalCapital']!,
                  Icons.account_balance_wallet_rounded,
                  AppThemePro.statusSuccess,
                  'Całkowita wartość portfela',
                  1,
                ),
                _buildKPICard(
                  'Średnia Inwestycja',
                  kpis['avgInvestment']!,
                  Icons.trending_up_rounded,
                  AppThemePro.accentGold,
                  'Średnia wartość na inwestora',
                  2,
                ),
                _buildKPICard(
                  'Wskaźnik Ryzyka',
                  kpis['riskPercentage']!,
                  Icons.shield_rounded,
                  AppThemePro.statusWarning,
                  'Procent kapitału w restrukturyzacji',
                  3,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKPICard(
    String title,
    String value,
    IconData icon,
    Color color,
    String description,
    int index,
  ) {
    final isHovered = _hoveredMetricIndex == index;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredMetricIndex = index),
      onExit: (_) => setState(() => _hoveredMetricIndex = -1),
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 1000 + (index * 150)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.elasticOut,
        builder: (context, animationValue, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()..scale(isHovered ? 1.05 : 1.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: isHovered ? 0.15 : 0.08),
                    AppThemePro.surfaceElevated,
                    color.withValues(alpha: isHovered ? 0.12 : 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withValues(alpha: isHovered ? 0.4 : 0.2),
                  width: isHovered ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isHovered ? 0.3 : 0.15),
                    blurRadius: isHovered ? 20 : 12,
                    offset: const Offset(0, 8),
                    spreadRadius: isHovered ? 2 : 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              color.withValues(alpha: 0.3),
                              color.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 28,
                        ),
                      ),
                      const Spacer(),
                      AnimatedRotation(
                        turns: isHovered ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: AppThemePro.textMuted.withValues(alpha: isHovered ? 1.0 : 0.6),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: TextStyle(
                      color: AppThemePro.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 1500 + (index * 150)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutExpo,
                    builder: (context, countValue, child) {
                      final displayValue = _animateValue(value, countValue);
                      
                      return Text(
                        displayValue,
                        style: TextStyle(
                          color: AppThemePro.textPrimary,
                          fontSize: widget.isTablet ? 24 : 20,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: isHovered ? null : 0,
                    child: isHovered ? Text(
                      description,
                      style: TextStyle(
                        color: AppThemePro.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ) : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCapitalOverviewChart() {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Container(
          height: 400,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppThemePro.backgroundTertiary,
                AppThemePro.surfaceElevated.withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppThemePro.accentGold.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
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
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Kapitał Inwestorów - Podział',
                    style: TextStyle(
                      color: AppThemePro.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: PieChart(
                        PieChartData(
                          sections: _buildCapitalPieSections(),
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                          pieTouchData: PieTouchData(
                            enabled: true,
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              // Optional: Handle touch interactions
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: _buildCapitalLegend(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStructureOverview() {
    final structure = _calculateStructureMetrics();
    
    return Row(
      children: structure.entries.map((entry) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStructureColor(entry.key).withValues(alpha: 0.1),
                  AppThemePro.surfaceElevated,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getStructureColor(entry.key).withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(_getStructureIcon(entry.key), color: _getStructureColor(entry.key), size: 28),
                const SizedBox(height: 12),
                Text(
                  entry.key,
                  style: TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  entry.value,
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInvestmentValueDistribution() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.backgroundTertiary,
            AppThemePro.surfaceElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemePro.accentGold.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rozkład wg Wartości Inwestycji',
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 50,
                sections: _buildValueDistributionSections(),
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    // Handle touch interactions
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiversificationChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.backgroundTertiary,
            AppThemePro.surfaceElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemePro.statusInfo.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dywersyfikacja Portfela',
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barGroups: _buildDiversificationBarGroups(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final labels = ['1 Produkt', '2-3 Produkty', '4+ Produkty'];
                        return Text(
                          labels[value.toInt()],
                          style: TextStyle(
                            color: AppThemePro.textSecondary,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: TextStyle(
                          color: AppThemePro.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewInvestorsChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.backgroundTertiary,
            AppThemePro.surfaceElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemePro.statusSuccess.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nowi Inwestorzy w Czasie',
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: TextStyle(color: AppThemePro.textSecondary, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final months = ['Sty', 'Lut', 'Mar', 'Kwi', 'Maj', 'Cze'];
                        final index = value.toInt();
                        return Text(
                          index < months.length ? months[index] : '',
                          style: TextStyle(color: AppThemePro.textSecondary, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [], // Removed _generateNewInvestorsData()
                    isCurved: true,
                    color: AppThemePro.statusSuccess,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 6,
                        color: AppThemePro.statusSuccess,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppThemePro.statusSuccess.withValues(alpha: 0.3),
                          AppThemePro.statusSuccess.withValues(alpha: 0.1),
                        ],
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

  Widget _buildTopInvestorsTable() {
    final topInvestors = _getTopInvestors();
    
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.backgroundTertiary,
            AppThemePro.surfaceElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemePro.accentGold.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: AppThemePro.accentGold,
                size: 28,
              ),
              const SizedBox(width: 16),
              Text(
                'TOP 10 Największych Inwestorów',
                style: TextStyle(
                  color: AppThemePro.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...topInvestors.asMap().entries.map((entry) {
            final index = entry.key;
            final investor = entry.value;
            return _buildInvestorRankItem(index + 1, investor);
          }),
        ],
      ),
    );
  }

  Widget _buildInvestorRankItem(int rank, InvestorSummary investor) {
    Color rankColor = AppThemePro.textSecondary;
    if (rank == 1) {
      rankColor = AppThemePro.accentGold;
    } else if (rank == 2) {
      rankColor = AppThemePro.textSecondary;
    } else if (rank == 3) {
      rankColor = AppThemePro.loansOrange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            rankColor.withValues(alpha: 0.1),
            AppThemePro.surfaceCard,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rankColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [rankColor, rankColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  investor.client.name,
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${investor.investmentCount} inwestycji',
                  style: TextStyle(
                    color: AppThemePro.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(investor.totalValue),
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestorSegmentation() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.backgroundTertiary,
            AppThemePro.surfaceElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemePro.realEstateViolet.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Segmentacja Inwestorów',
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _buildSegmentationGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentationGrid() {
    final segments = _calculateInvestorSegmentation();
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: segments.entries.map((entry) {
        final color = _getSegmentColor(entry.value);
        return Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.value}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRiskDistributionChart() {
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemePro.statusWarning.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rozkład Ryzyka Portfela',
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barGroups: _buildRiskBarGroups(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final labels = ['Niskie', 'Średnie', 'Wysokie'];
                        return Text(
                          labels[value.toInt()],
                          style: TextStyle(
                            color: AppThemePro.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: TextStyle(
                          color: AppThemePro.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentationHeatmap() {
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemePro.realEstateViolet.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mapa Segmentacji Inwestorów',
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 5,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              children: _buildHeatmapCells(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowDynamicsChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.backgroundTertiary,
            AppThemePro.surfaceElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemePro.accentGold.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dynamika Przepływów Pieniężnych',
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100000, // Removed _getMaxCashFlowValue() * 1.2
                barGroups: [], // Removed _buildCashFlowBarGroups()
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final months = ['Sty', 'Lut', 'Mar', 'Kwi', 'Maj', 'Cze'];
                        return Text(
                          months[value.toInt()],
                          style: TextStyle(
                            color: AppThemePro.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) => Text(
                        _formatCurrencyShort(value),
                        style: TextStyle(
                          color: AppThemePro.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: widget.isTablet ? 4 : 2,
            childAspectRatio: widget.isTablet ? 1.3 : 1.1,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            children: List.generate(4, (index) => _buildShimmerCard()),
          ),
          const SizedBox(height: 32),
          _buildShimmerChart(),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemePro.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppThemePro.backgroundTertiary,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const Spacer(),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppThemePro.backgroundTertiary,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: AppThemePro.backgroundTertiary,
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 80,
            height: 24,
            decoration: BoxDecoration(
              color: AppThemePro.backgroundTertiary,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerChart() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemePro.borderSecondary),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  // Data calculation methods
  Map<String, String> _calculateGeneralKPIs() {
    if (widget.allInvestors.isEmpty) {
      return {
        'totalInvestors': '0',
        'totalCapital': '0 PLN',
        'avgInvestment': '0 PLN',
        'riskPercentage': '0.0%',
      };
    }

    final totalInvestors = widget.allInvestors.length;
    final totalCapital = widget.totalViableCapital;
    final avgInvestment = totalCapital / totalInvestors;
    
    // Oblicz procent kapitału w restrukturyzacji
    final totalRestructuring = widget.allInvestors.fold<double>(
      0.0, (sum, investor) => sum + investor.capitalForRestructuring
    );
    final riskPercentage = totalCapital > 0 ? (totalRestructuring / totalCapital * 100) : 0.0;

    return {
      'totalInvestors': totalInvestors.toString(),
      'totalCapital': _formatCurrency(totalCapital),
      'avgInvestment': _formatCurrency(avgInvestment),
      'riskPercentage': '${riskPercentage.toStringAsFixed(1)}%',
    };
  }

  Map<String, String> _calculateStructureMetrics() {
    if (widget.allInvestors.isEmpty) {
      return {
        'Małe\n(<100K)': '0',
        'Średnie\n(100K-500K)': '0',
        'Duże\n(500K-1M)': '0',
        'VIP\n(>1M)': '0',
      };
    }

    int small = 0, medium = 0, large = 0, vip = 0;
    
    for (final investor in widget.allInvestors) {
      final value = investor.totalValue;
      if (value < 100000) {
        small++;
      } else if (value < 500000) {
        medium++;
      } else if (value < 1000000) {
        large++;
      } else {
        vip++;
      }
    }

    return {
      'Małe\n(<100K)': small.toString(),
      'Średnie\n(100K-500K)': medium.toString(),
      'Duże\n(500K-1M)': large.toString(),
      'VIP\n(>1M)': vip.toString(),
    };
  }

  List<InvestorSummary> _getTopInvestors() {
    final sorted = List<InvestorSummary>.from(widget.allInvestors);
    sorted.sort((a, b) => b.totalValue.compareTo(a.totalValue));
    return sorted.take(10).toList();
  }

  Map<String, int> _calculateInvestorSegmentation() {
    if (widget.allInvestors.isEmpty) {
      return {
        'Nowi': 5,
        'Stali': 45,
        'VIP': 12,
        'Małe': 25,
        'Średnie': 38,
        'Duże': 18,
        '1 Produkt': 42,
        '2-3 Produkty': 35,
        '4+ Produkty': 15,
      };
    }

    // Segmentacja na podstawie rzeczywistych danych
    int newInvestors = 0;
    int regular = 0;
    int vip = 0;
    int small = 0;
    int medium = 0;
    int large = 0;
    int singleProduct = 0;
    int multiProduct = 0;
    int diversified = 0;

    for (final investor in widget.allInvestors) {
      final value = investor.totalValue;
      final productCount = investor.investmentCount;
      
      // Segmentacja wartościowa
      if (value < 100000) {
        small++;
      } else if (value < 500000) {
        medium++;
      } else {
        large++;
      }
      
      // Segmentacja VIP
      if (value > 1000000) {
        vip++;
      } else {
        regular++;
      }
      
      // Segmentacja dywersyfikacji
      if (productCount == 1) {
        singleProduct++;
      } else if (productCount <= 3) {
        multiProduct++;
      } else {
        diversified++;
      }
    }

    return {
      'Nowi': newInvestors,
      'Stali': regular,
      'VIP': vip,
      'Małe': small,
      'Średnie': medium,
      'Duże': large,
      '1 Produkt': singleProduct,
      '2-3 Produkty': multiProduct,
      '4+ Produkty': diversified,
    };
  }

  List<PieChartSectionData> _buildCapitalPieSections() {
    if (widget.allInvestors.isEmpty) {
      return [
        PieChartSectionData(
          color: AppThemePro.statusSuccess,
          value: 25,
          title: 'Brak danych',
          radius: 80,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ];
    }

    final totalRealized = widget.allInvestors.fold<double>(
      0.0, (sum, investor) => sum + investor.totalRealizedCapital
    );
    final totalRemaining = widget.totalViableCapital;
    final totalSecured = widget.allInvestors.fold<double>(
      0.0, (sum, investor) => sum + investor.capitalSecuredByRealEstate
    );
    final totalRestructuring = widget.allInvestors.fold<double>(
      0.0, (sum, investor) => sum + investor.capitalForRestructuring
    );

    final totalCapital = totalRealized + totalRemaining + totalSecured + totalRestructuring;
    if (totalCapital == 0) {
      return [
        PieChartSectionData(
          color: AppThemePro.textMuted,
          value: 100,
          title: 'Brak danych',
          radius: 80,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ];
    }

    final List<PieChartSectionData> sections = [];
    
    if (totalRealized > 0) {
      final percentage = (totalRealized / totalCapital) * 100;
      sections.add(
        PieChartSectionData(
          color: AppThemePro.statusSuccess,
          value: totalRealized,
          title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: 80,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      );
    }
    
    if (totalRemaining > 0) {
      final percentage = (totalRemaining / totalCapital) * 100;
      sections.add(
        PieChartSectionData(
          color: AppThemePro.accentGold,
          value: totalRemaining,
          title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: 80,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      );
    }
    
    if (totalSecured > 0) {
      final percentage = (totalSecured / totalCapital) * 100;
      sections.add(
        PieChartSectionData(
          color: AppThemePro.statusInfo,
          value: totalSecured,
          title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: 80,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      );
    }
    
    if (totalRestructuring > 0) {
      final percentage = (totalRestructuring / totalCapital) * 100;
      sections.add(
        PieChartSectionData(
          color: AppThemePro.statusError,
          value: totalRestructuring,
          title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: 80,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      );
    }

    return sections;
  }

  Widget _buildCapitalLegend() {
    if (widget.allInvestors.isEmpty) {
      return Center(
        child: Text(
          'Brak danych do wyświetlenia',
          style: TextStyle(
            color: AppThemePro.textSecondary,
            fontSize: 14,
          ),
        ),
      );
    }

    final totalRealized = widget.allInvestors.fold<double>(
      0.0, (sum, investor) => sum + investor.totalRealizedCapital
    );
    final totalRemaining = widget.totalViableCapital;
    final totalSecured = widget.allInvestors.fold<double>(
      0.0, (sum, investor) => sum + investor.capitalSecuredByRealEstate
    );
    final totalRestructuring = widget.allInvestors.fold<double>(
      0.0, (sum, investor) => sum + investor.capitalForRestructuring
    );

    final legendItems = [
      {'label': 'Zrealizowany', 'value': totalRealized, 'color': AppThemePro.statusSuccess},
      {'label': 'Pozostały', 'value': totalRemaining, 'color': AppThemePro.accentGold},
      {'label': 'Zabezpieczony', 'value': totalSecured, 'color': AppThemePro.statusInfo},
      {'label': 'Restrukturyzacja', 'value': totalRestructuring, 'color': AppThemePro.statusError},
    ].where((item) => (item['value'] as double) > 0).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: legendItems.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: item['color'] as Color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatCurrency(item['value'] as double),
                      style: TextStyle(
                        color: AppThemePro.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<PieChartSectionData> _buildValueDistributionSections() {
    final structure = _calculateStructureMetrics();
    final colors = [AppThemePro.statusSuccess, AppThemePro.accentGold, AppThemePro.statusWarning, AppThemePro.realEstateViolet];
    
    return structure.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final value = double.tryParse(data.value) ?? 1;
      final total = structure.values.map((v) => double.tryParse(v) ?? 0).reduce((a, b) => a + b);
      final percentage = total > 0 ? (value / total) * 100 : 25;
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: percentage.toDouble(),
        title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<BarChartGroupData> _buildDiversificationBarGroups() {
    if (widget.allInvestors.isEmpty) {
      return [
        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 0, color: AppThemePro.statusWarning, width: 30, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]),
        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 0, color: AppThemePro.accentGold, width: 30, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]),
        BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 0, color: AppThemePro.statusSuccess, width: 30, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]),
      ];
    }

    // Oblicz rzeczywiste dane dywersyfikacji
    int singleProductCount = 0;
    int multiProductCount = 0;
    int diversifiedCount = 0;

    for (final investor in widget.allInvestors) {
      final investmentCount = investor.investmentCount;
      if (investmentCount == 1) {
        singleProductCount++;
      } else if (investmentCount <= 3) {
        multiProductCount++;
      } else {
        diversifiedCount++;
      }
    }

    return [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: singleProductCount.toDouble(), color: AppThemePro.statusWarning, width: 30, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]),
      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: multiProductCount.toDouble(), color: AppThemePro.accentGold, width: 30, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]),
      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: diversifiedCount.toDouble(), color: AppThemePro.statusSuccess, width: 30, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]),
    ];
  }

  List<BarChartGroupData> _buildRiskBarGroups() {
    // Analiza ryzyka na podstawie typów produktów
    double lowRisk = 0, mediumRisk = 0, highRisk = 0;
    double totalCapital = 0;
    
    for (final investor in widget.allInvestors) {
      for (final investment in investor.investments) {
        final capital = investment.remainingCapital;
        totalCapital += capital;
        
        switch (investment.productType) {
          case ProductType.bonds:
            lowRisk += capital;
            break;
          case ProductType.apartments:
            lowRisk += capital * 0.7;
            mediumRisk += capital * 0.3;
            break;
          case ProductType.loans:
            mediumRisk += capital;
            break;
          case ProductType.shares:
            highRisk += capital;
            break;
        }
      }
    }
    
    if (totalCapital <= 0) {
      return [
        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 33, color: AppThemePro.statusSuccess, width: 40, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))]),
        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 33, color: AppThemePro.statusWarning, width: 40, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))]),
        BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 34, color: AppThemePro.statusError, width: 40, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))]),
      ];
    }
    
    final lowPercent = (lowRisk / totalCapital) * 100;
    final mediumPercent = (mediumRisk / totalCapital) * 100;
    final highPercent = (highRisk / totalCapital) * 100;
    
    return [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: lowPercent, color: AppThemePro.statusSuccess, width: 40, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))]),
      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: mediumPercent, color: AppThemePro.statusWarning, width: 40, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))]),
      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: highPercent, color: AppThemePro.statusError, width: 40, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))]),
    ];
  }

  // Helper methods
  
  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M PLN';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K PLN';
    }
    return '${value.toStringAsFixed(0)} PLN';
  }

  String _formatCurrencyShort(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  String _animateValue(String value, double progress) {
    if (value.contains('%')) {
      final numericValue = double.tryParse(value.replaceAll('%', '')) ?? 0;
      return '${(numericValue * progress).toStringAsFixed(1)}%';
    } else if (value.contains('PLN')) {
      final cleanValue = value.replaceAll(' PLN', '').replaceAll('M', '').replaceAll('K', '');
      final numericValue = double.tryParse(cleanValue) ?? 0;
      if (value.contains('M')) {
        return '${(numericValue * progress).toStringAsFixed(1)}M PLN';
      } else if (value.contains('K')) {
        return '${(numericValue * progress).toStringAsFixed(0)}K PLN';
      }
      return '${(numericValue * progress).toStringAsFixed(0)} PLN';
    } else {
      final numericValue = double.tryParse(value) ?? 0;
      return (numericValue * progress).toStringAsFixed(0);
    }
  }

  Color _getStructureColor(String key) {
    if (key.contains('Małe')) return AppThemePro.statusSuccess;
    if (key.contains('Średnie')) return AppThemePro.accentGold;
    if (key.contains('Duże')) return AppThemePro.statusWarning;
    if (key.contains('VIP')) return AppThemePro.realEstateViolet;
    return AppThemePro.textMuted;
  }

  IconData _getStructureIcon(String key) {
    if (key.contains('Małe')) return Icons.people_outline_rounded;
    if (key.contains('Średnie')) return Icons.people_rounded;
    if (key.contains('Duże')) return Icons.business_rounded;
    if (key.contains('VIP')) return Icons.diamond_rounded;
    return Icons.help_rounded;
  }

  Color _getSegmentColor(int value) {
    if (value < 10) return AppThemePro.statusSuccess;
    if (value < 30) return AppThemePro.accentGold;
    if (value < 50) return AppThemePro.statusWarning;
    return AppThemePro.statusError;
  }

  List<Widget> _buildHeatmapCells() {
    if (widget.allInvestors.isEmpty) {
      return List.generate(20, (index) => Container(
        decoration: BoxDecoration(
          color: AppThemePro.textMuted,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            '0',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ));
    }

    // Grupuj inwestorów po kapitale i liczbie produktów
    final List<Map<String, dynamic>> heatmapData = [];
    
    for (final investor in widget.allInvestors) {
      final capital = investor.totalRemainingCapital;
      final productCount = investor.investmentCount;
      
      // Normalizuj wartości dla heatmapy (0-100)
      final capitalIntensity = capital > 0 
          ? (capital / 1000000 * 50).clamp(0, 100).toDouble() // Scale by millions
          : 0.0;
      final productIntensity = (productCount * 20).clamp(0, 100).toDouble(); // Scale by product count
      
      final combinedIntensity = ((capitalIntensity + productIntensity) / 2).clamp(0, 100);
      
      heatmapData.add({
        'intensity': combinedIntensity,
        'capital': capital,
        'products': productCount,
      });
    }
    
    // Stwórz 20 komórek na podstawie rzeczywistych danych
    return List.generate(20, (index) {
      final dataIndex = index < heatmapData.length ? index : heatmapData.length - 1;
      final intensity = heatmapData.isNotEmpty ? heatmapData[dataIndex % heatmapData.length]['intensity'] : 0.0;
      final color = _getHeatmapColor(intensity);
      
      return Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            intensity.toInt().toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    });
  }

  Color _getHeatmapColor(double intensity) {
    if (intensity < 25) return AppThemePro.statusSuccess;
    if (intensity < 50) return AppThemePro.accentGold;
    if (intensity < 75) return AppThemePro.statusWarning;
    return AppThemePro.statusError;
  }
}