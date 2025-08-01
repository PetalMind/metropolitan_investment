import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/client.dart';
import '../models/investor_summary.dart';
import '../utils/currency_formatter.dart';

/// 🔥 PREMIUM DYNAMICZNE WYKRESY ANALITYCZNE
/// 
/// Nowoczesne, interaktywne wykresy inspirowane platformami:
/// • Bloomberg Terminal
/// • Refinitiv Eikon  
/// • FactSet
/// • Trading View
/// 
/// ✨ FEATURES:
/// • Real-time animacje
/// • Interaktywne tooltips
/// • Zoom i pan
/// • Responsive design
/// • Beautiful gradients
/// • Smooth transitions

/// 📊 WYKRES KOŁOWY STATUSÓW GŁOSOWANIA Z ANIMACJAMI
class PremiumVotingPieChart extends StatefulWidget {
  final Map<VotingStatus, double> votingDistribution;
  final Map<VotingStatus, int> votingCounts;
  final double totalCapital;
  final bool showAnimations;
  final VoidCallback? onSegmentTap;

  const PremiumVotingPieChart({
    super.key,
    required this.votingDistribution,
    required this.votingCounts,
    required this.totalCapital,
    this.showAnimations = true,
    this.onSegmentTap,
  });

  @override
  State<PremiumVotingPieChart> createState() => _PremiumVotingPieChartState();
}

class _PremiumVotingPieChartState extends State<PremiumVotingPieChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    
    if (widget.showAnimations) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.votingDistribution.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundPrimary,
            AppTheme.backgroundSecondary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Wykres kołowy
            Expanded(
              flex: 3,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: widget.showAnimations ? _animation.value : 1.0,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 80,
                        sections: _buildPieSections(),
                        pieTouchData: PieTouchData(
                          touchCallback: _onPieTouch,
                          mouseCursorResolver: (event, response) {
                            return response == null 
                                ? MouseCursor.defer 
                                : SystemMouseCursors.click;
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(width: 32),
            
            // Legenda z animacjami
            Expanded(
              flex: 2,
              child: _buildAnimatedLegend(),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final List<PieChartSectionData> sections = [];
    int index = 0;
    
    for (final entry in widget.votingDistribution.entries) {
      final percentage = widget.totalCapital > 0 
          ? (entry.value / widget.totalCapital) * 100 
          : 0.0;
      
      final isTouch = index == _touchedIndex;
      final radius = isTouch ? 110.0 : 100.0;
      final fontSize = isTouch ? 14.0 : 12.0;
      
      sections.add(
        PieChartSectionData(
          color: _getVotingStatusGradientColor(entry.key),
          value: entry.value,
          title: percentage > 3 ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.8),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
          badgeWidget: isTouch ? _buildHoverBadge(entry.key, entry.value, percentage) : null,
          badgePositionPercentageOffset: 1.3,
        ),
      );
      index++;
    }
    
    return sections;
  }

  Widget _buildHoverBadge(VotingStatus status, double value, double percentage) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getVotingStatusColor(status), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getVotingStatusLabel(status),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            CurrencyFormatter.formatCurrencyShort(value),
            style: TextStyle(
              color: _getVotingStatusColor(status),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLegend() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.votingDistribution.entries.map((entry) {
        final percentage = widget.totalCapital > 0 
            ? (entry.value / widget.totalCapital) * 100 
            : 0.0;
        final count = widget.votingCounts[entry.key] ?? 0;
        
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 800 + (entry.key.index * 200)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset((1 - value) * 50, 0),
              child: Opacity(
                opacity: value,
                child: _buildLegendItem(entry.key, entry.value, percentage, count),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildLegendItem(VotingStatus status, double value, double percentage, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getVotingStatusColor(status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getVotingStatusColor(status),
                  _getVotingStatusColor(status).withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: _getVotingStatusColor(status).withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Status info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getVotingStatusLabel(status),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${CurrencyFormatter.formatCurrencyShort(value)} • $count osób',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Percentage
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getVotingStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: _getVotingStatusColor(status),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderPrimary),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Brak danych do analizy',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Załaduj dane inwestorów aby zobaczyć rozkład głosowania',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _onPieTouch(FlTouchEvent event, PieTouchResponse? response) {
    setState(() {
      if (!event.isInterestedForInteractions ||
          response == null ||
          response.touchedSection == null) {
        _touchedIndex = -1;
        return;
      }
      _touchedIndex = response.touchedSection!.touchedSectionIndex;
    });
    
    if (widget.onSegmentTap != null) {
      widget.onSegmentTap!();
    }
  }

  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return const Color(0xFF00C851); // Bright green
      case VotingStatus.no:
        return const Color(0xFFFF4444); // Bright red
      case VotingStatus.abstain:
        return const Color(0xFFFF8800); // Orange
      case VotingStatus.undecided:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  Color _getVotingStatusGradientColor(VotingStatus status) {
    final baseColor = _getVotingStatusColor(status);
    return baseColor;
  }

  String _getVotingStatusLabel(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return 'ZA';
      case VotingStatus.no:
        return 'PRZECIW';
      case VotingStatus.abstain:
        return 'WSTRZYMUJE';
      case VotingStatus.undecided:
        return 'NIEZDECYDOWANY';
    }
  }
}

/// 📈 WYKRES LINIOWY KAPITAŁU W CZASIE Z ZOOM I INTERAKCJĄ
class PremiumCapitalTrendChart extends StatefulWidget {
  final List<InvestorSummary> investors;
  final String title;
  final Color primaryColor;
  final bool showProjection;

  const PremiumCapitalTrendChart({
    super.key,
    required this.investors,
    required this.title,
    this.primaryColor = AppTheme.primaryColor,
    this.showProjection = true,
  });

  @override
  State<PremiumCapitalTrendChart> createState() => _PremiumCapitalTrendChartState();
}

class _PremiumCapitalTrendChartState extends State<PremiumCapitalTrendChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<FlSpot> _dataPoints = [];
  List<FlSpot> _projectionPoints = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    
    _prepareData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _prepareData() {
    // Sortuj inwestorów według kapitału
    final sortedInvestors = List<InvestorSummary>.from(widget.investors)
      ..sort((a, b) => a.viableRemainingCapital.compareTo(b.viableRemainingCapital));

    // Utwórz punkty danych dla wykresu
    double cumulativeCapital = 0;
    _dataPoints = [];
    
    for (int i = 0; i < sortedInvestors.length; i++) {
      cumulativeCapital += sortedInvestors[i].viableRemainingCapital;
      _dataPoints.add(FlSpot(i.toDouble(), cumulativeCapital));
    }

    // Dodaj projekcję wzrostu
    if (widget.showProjection && _dataPoints.isNotEmpty) {
      _projectionPoints = _calculateProjection();
    }
  }

  List<FlSpot> _calculateProjection() {
    if (_dataPoints.length < 3) return [];
    
    // Oblicz trend na podstawie ostatnich punktów
    final lastPointsCount = math.min(5, _dataPoints.length);
    final lastPoints = _dataPoints.sublist(_dataPoints.length - lastPointsCount);
    double avgGrowth = 0;
    
    for (int i = 1; i < lastPoints.length; i++) {
      avgGrowth += (lastPoints[i].y - lastPoints[i-1].y);
    }
    avgGrowth /= (lastPoints.length - 1);
    
    // Utwórz punkty projekcji
    final projectionLength = (_dataPoints.length * 0.3).round();
    final projectionPoints = <FlSpot>[];
    
    for (int i = 1; i <= projectionLength; i++) {
      final x = _dataPoints.length + i - 1;
      final y = _dataPoints.last.y + (avgGrowth * i * 0.8); // Zmniejsz wzrost w projekcji
      projectionPoints.add(FlSpot(x.toDouble(), y));
    }
    
    return projectionPoints;
  }

  @override
  Widget build(BuildContext context) {
    if (_dataPoints.isEmpty) {
      return _buildEmptyState();
    }

    final maxY = [..._dataPoints, ..._projectionPoints]
        .map((spot) => spot.y)
        .reduce(math.max) * 1.1;

    return Container(
      height: 400,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundPrimary,
            AppTheme.backgroundSecondary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChartHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return LineChart(
                    _buildLineChartData(maxY),
                    duration: const Duration(milliseconds: 250),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Skumulowany kapitał według inwestorów',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: widget.primaryColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Live',
                style: TextStyle(
                  color: widget.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  LineChartData _buildLineChartData(double maxY) {
    return LineChartData(
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        // Linia główna
        LineChartBarData(
          spots: _dataPoints.take((_dataPoints.length * _animation.value).round()).toList(),
          isCurved: true,
          curveSmoothness: 0.3,
          gradient: LinearGradient(
            colors: [
              widget.primaryColor.withOpacity(0.8),
              widget.primaryColor,
            ],
          ),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 6,
                color: widget.primaryColor,
                strokeWidth: 3,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.primaryColor.withOpacity(0.3),
                widget.primaryColor.withOpacity(0.05),
              ],
            ),
          ),
        ),
        
        // Linia projekcji
        if (_projectionPoints.isNotEmpty && _animation.value > 0.8)
          LineChartBarData(
            spots: _projectionPoints,
            isCurved: true,
            curveSmoothness: 0.3,
            color: widget.primaryColor.withOpacity(0.5),
            barWidth: 3,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.primaryColor.withOpacity(0.15),
                  widget.primaryColor.withOpacity(0.02),
                ],
              ),
            ),
          ),
      ],
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              return Text(
                CurrencyFormatter.formatAxisValue(value),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: (_dataPoints.length / 5).ceilToDouble(),
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Inv ${value.toInt() + 1}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppTheme.borderPrimary.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
      ),
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => Colors.black87,
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final isProjection = spot.x >= _dataPoints.length;
              return LineTooltipItem(
                '${isProjection ? 'Projekcja' : 'Inwestor'} ${spot.x.toInt() + 1}\n'
                '${CurrencyFormatter.formatCurrencyShort(spot.y)}',
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
        getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: widget.primaryColor.withOpacity(0.8),
                strokeWidth: 2,
              ),
              FlDotData(
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 8,
                    color: widget.primaryColor,
                    strokeWidth: 3,
                    strokeColor: Colors.white,
                  );
                },
              ),
            );
          }).toList();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderPrimary),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Brak danych do analizy trendów',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📊 WYKRES SŁUPKOWY ROZKŁADU KAPITAŁU WEDŁUG PROGÓW
class PremiumCapitalDistributionChart extends StatefulWidget {
  final List<InvestorSummary> investors;
  final String title;
  final List<double> thresholds;
  final Color primaryColor;

  const PremiumCapitalDistributionChart({
    super.key,
    required this.investors,
    required this.title,
    this.thresholds = const [100000, 500000, 1000000, 5000000, 10000000],
    this.primaryColor = AppTheme.primaryColor,
  });

  @override
  State<PremiumCapitalDistributionChart> createState() => _PremiumCapitalDistributionChartState();
}

class _PremiumCapitalDistributionChartState extends State<PremiumCapitalDistributionChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  Map<String, int> _distributionData = {};
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    
    _prepareDistributionData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _prepareDistributionData() {
    _distributionData = {};
    
    // Inicjalizuj kategorie
    _distributionData['0-100K'] = 0;
    _distributionData['100K-500K'] = 0;
    _distributionData['500K-1M'] = 0;
    _distributionData['1M-5M'] = 0;
    _distributionData['5M-10M'] = 0;
    _distributionData['10M+'] = 0;
    
    // Policz inwestorów w każdej kategorii
    for (final investor in widget.investors) {
      final capital = investor.viableRemainingCapital;
      
      if (capital < 100000) {
        _distributionData['0-100K'] = _distributionData['0-100K']! + 1;
      } else if (capital < 500000) {
        _distributionData['100K-500K'] = _distributionData['100K-500K']! + 1;
      } else if (capital < 1000000) {
        _distributionData['500K-1M'] = _distributionData['500K-1M']! + 1;
      } else if (capital < 5000000) {
        _distributionData['1M-5M'] = _distributionData['1M-5M']! + 1;
      } else if (capital < 10000000) {
        _distributionData['5M-10M'] = _distributionData['5M-10M']! + 1;
      } else {
        _distributionData['10M+'] = _distributionData['10M+']! + 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_distributionData.isEmpty) {
      return _buildEmptyState();
    }

    final maxValue = _distributionData.values.isNotEmpty 
        ? _distributionData.values.reduce(math.max).toDouble() 
        : 1.0;

    return Container(
      height: 350,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundPrimary,
            AppTheme.backgroundSecondary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChartHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return BarChart(
                    _buildBarChartData(maxValue),
                    swapAnimationDuration: const Duration(milliseconds: 250),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartHeader() {
    final totalInvestors = widget.investors.length;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Rozkład $totalInvestors inwestorów według kapitału',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.warningColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insights_rounded,
                color: AppTheme.warningColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Analiza',
                style: TextStyle(
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BarChartData _buildBarChartData(double maxValue) {
    return BarChartData(
      maxY: maxValue * 1.2,
      barGroups: _distributionData.entries.toList().asMap().entries.map((entry) {
        final index = entry.key;
        final count = entry.value.value.toDouble();
        
        final isTouched = index == _touchedIndex;
        final barWidth = isTouched ? 28.0 : 24.0;
        final animatedHeight = count * _animation.value;
        
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: animatedHeight,
              color: _getBarColor(index),
              width: barWidth,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  _getBarColor(index).withOpacity(0.7),
                  _getBarColor(index),
                ],
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxValue * 1.2,
                color: AppTheme.textTertiary.withOpacity(0.1),
              ),
            ),
          ],
        );
      }).toList(),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < _distributionData.length) {
                final category = _distributionData.keys.toList()[index];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: false,
        horizontalInterval: maxValue / 4,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppTheme.borderPrimary.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
      ),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.black87,
          tooltipRoundedRadius: 8,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final category = _distributionData.keys.toList()[group.x];
            final count = rod.toY.toInt();
            final percentage = widget.investors.isNotEmpty 
                ? (count / widget.investors.length * 100).toStringAsFixed(1)
                : '0.0';
            
            return BarTooltipItem(
              '$category\n$count inwestorów ($percentage%)',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            );
          },
        ),
        touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                response == null ||
                response.spot == null) {
              _touchedIndex = -1;
              return;
            }
            _touchedIndex = response.spot!.touchedBarGroupIndex;
          });
        },
      ),
    );
  }

  Color _getBarColor(int index) {
    final colors = [
      const Color(0xFF4CAF50), // Green
      const Color(0xFF2196F3), // Blue
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFFE91E63), // Pink
    ];
    return colors[index % colors.length];
  }

  Widget _buildEmptyState() {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderPrimary),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Brak danych do analizy rozkładu',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension helper dla tej klasy
extension _ListExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (count >= length) return this;
    return sublist(length - count);
  }
}
