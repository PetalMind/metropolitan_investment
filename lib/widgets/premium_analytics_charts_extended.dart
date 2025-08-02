import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '.    double totalReturn = 0.0;
    int validInvestments = 0;

    for (final investment in investor.investments) {
      if (investment.investmentAmount > 0) {
        // ⭐ Zwrot obliczony tylko na podstawie kapitału pozostałego
        final returnValue = (investment.remainingCapital - investment.investmentAmount) / 
                           investment.investmentAmount * 100;
        totalReturn += returnValue;
        validInvestments++;
      }
    }

    return validInvestments > 0 ? totalReturn / validInvestments : 0.0;.dart';
import '../models/investor_summary.dart';
import '../utils/currency_formatter.dart';

/// 🔥 DODATKOWE PREMIUM WYKRESY ANALITYCZNE
///
/// Rozszerza możliwości analityczne o:
/// • Heatmapa korelacji
/// • Radar chart diversyfikacji
/// • Bubble chart ryzyka vs zwrotu
/// • Matrix chart alokacji

/// 🌡️ HEATMAPA ANALIZY RYZYKA I RENTOWNOŚCI
class PremiumRiskHeatMap extends StatefulWidget {
  final List<InvestorSummary> investors;
  final String title;
  final int gridSize;

  const PremiumRiskHeatMap({
    super.key,
    required this.investors,
    required this.title,
    this.gridSize = 10,
  });

  @override
  State<PremiumRiskHeatMap> createState() => _PremiumRiskHeatMapState();
}

class _PremiumRiskHeatMapState extends State<PremiumRiskHeatMap>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<List<double>> _heatMapData = [];
  double _maxValue = 0;
  double _minValue = 0;

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

    _prepareHeatMapData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _prepareHeatMapData() {
    if (widget.investors.isEmpty) return;

    // Przygotuj dane dla heatmapy - ryzyko vs rentowność
    _heatMapData = List.generate(
      widget.gridSize,
      (_) => List.generate(widget.gridSize, (_) => 0.0),
    );

    final maxReturn = widget.investors
        .map((i) => _calculateReturn(i))
        .reduce(math.max);
    final minReturn = widget.investors
        .map((i) => _calculateReturn(i))
        .reduce(math.min);
    final maxRisk = widget.investors
        .map((i) => _calculateRisk(i))
        .reduce(math.max);
    final minRisk = widget.investors
        .map((i) => _calculateRisk(i))
        .reduce(math.min);

    // Mapuj inwestorów na siatkę
    for (final investor in widget.investors) {
      final risk = _calculateRisk(investor);
      final returnVal = _calculateReturn(investor);

      final riskIndex =
          ((risk - minRisk) / (maxRisk - minRisk) * (widget.gridSize - 1))
              .clamp(0, widget.gridSize - 1)
              .round();
      final returnIndex =
          ((returnVal - minReturn) /
                  (maxReturn - minReturn) *
                  (widget.gridSize - 1))
              .clamp(0, widget.gridSize - 1)
              .round();

      _heatMapData[riskIndex][returnIndex] += investor.viableRemainingCapital;
    }

    // Znajdź min/max wartości
    _maxValue = 0;
    _minValue = double.infinity;
    for (final row in _heatMapData) {
      for (final value in row) {
        if (value > _maxValue) _maxValue = value;
        if (value < _minValue && value > 0) _minValue = value;
      }
    }
  }

  double _calculateReturn(InvestorSummary investor) {
    // Oblicz średni zwrot na podstawie inwestycji
    if (investor.investments.isEmpty) return 0.0;

    double totalReturn = 0;
    int validInvestments = 0;

    for (final investment in investor.investments) {
      if (investment.investmentAmount > 0) {
        final returnValue =
            (investment.realizedCapital +
                investment.remainingCapital -
                investment.investmentAmount) /
            investment.investmentAmount *
            100;
        totalReturn += returnValue;
        validInvestments++;
      }
    }

    return validInvestments > 0 ? totalReturn / validInvestments : 0.0;
  }

  double _calculateRisk(InvestorSummary investor) {
    // Uproszczone obliczenie ryzyka na podstawie diversyfikacji portfela
    final productTypes = investor.investments
        .map((inv) => inv.productType)
        .toSet()
        .length;
    final totalInvestments = investor.investments.length;

    // Mniej produktów = większe ryzyko
    return totalInvestments > 0
        ? (1 - (productTypes / totalInvestments)) * 100
        : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_heatMapData.isEmpty || widget.investors.isEmpty) {
      return _buildEmptyState();
    }

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
            color: AppTheme.primaryColor.withOpacity(0.1),
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
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                children: [
                  // Oś Y (Ryzyko)
                  SizedBox(
                    width: 50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('Wysokie', style: _getAxisLabelStyle()),
                        Container(height: 1, color: AppTheme.borderPrimary),
                        Text('Ryzyko', style: _getAxisLabelStyle()),
                        Container(height: 1, color: AppTheme.borderPrimary),
                        Text('Niskie', style: _getAxisLabelStyle()),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Heatmapa
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Column(
                          children: [
                            Expanded(child: _buildHeatMapGrid()),
                            const SizedBox(height: 10),
                            // Oś X (Rentowność)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text('Niska', style: _getAxisLabelStyle()),
                                Text('Rentowność', style: _getAxisLabelStyle()),
                                Text('Wysoka', style: _getAxisLabelStyle()),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildColorLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
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
          'Mapa cieplna: Ryzyko vs Rentowność',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildHeatMapGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.gridSize,
        childAspectRatio: 1,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: widget.gridSize * widget.gridSize,
      itemBuilder: (context, index) {
        final row = index ~/ widget.gridSize;
        final col = index % widget.gridSize;
        final value = _heatMapData[row][col];

        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 20)),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: _getHeatMapColor(value),
            borderRadius: BorderRadius.circular(2),
          ),
          child: value > 0
              ? Tooltip(
                  message:
                      'Kapitał: ${CurrencyFormatter.formatCurrencyShort(value)}',
                  child: Container(),
                )
              : Container(),
        );
      },
    );
  }

  Color _getHeatMapColor(double value) {
    if (value == 0 || _maxValue == 0) {
      return AppTheme.backgroundSecondary.withOpacity(0.1);
    }

    final intensity = (value / _maxValue).clamp(0.0, 1.0);

    // Gradient od niebieskiego przez zielony do czerwonego
    if (intensity < 0.5) {
      return Color.lerp(
        Colors.blue.withOpacity(0.2),
        Colors.green.withOpacity(0.6),
        intensity * 2,
      )!;
    } else {
      return Color.lerp(
        Colors.green.withOpacity(0.6),
        Colors.red.withOpacity(0.8),
        (intensity - 0.5) * 2,
      )!;
    }
  }

  Widget _buildColorLegend() {
    return Row(
      children: [
        Text(
          'Kapitał:',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.green, Colors.orange, Colors.red],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.formatCurrencyShort(_maxValue),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            ),
            Text(
              CurrencyFormatter.formatCurrencyShort(_minValue),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  TextStyle _getAxisLabelStyle() {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.textTertiary,
          fontSize: 10,
        ) ??
        const TextStyle();
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
            Icon(Icons.grid_on_rounded, size: 64, color: AppTheme.textTertiary),
            const SizedBox(height: 16),
            Text(
              'Brak danych dla heatmapy',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🎯 RADAR CHART ANALIZA PORTFELA
class PremiumPortfolioRadarChart extends StatefulWidget {
  final Map<String, double> metrics;
  final String title;
  final Color primaryColor;
  final List<String> labels;

  const PremiumPortfolioRadarChart({
    super.key,
    required this.metrics,
    required this.title,
    this.primaryColor = AppTheme.primaryColor,
    required this.labels,
  });

  @override
  State<PremiumPortfolioRadarChart> createState() =>
      _PremiumPortfolioRadarChartState();
}

class _PremiumPortfolioRadarChartState extends State<PremiumPortfolioRadarChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.metrics.isEmpty) {
      return _buildEmptyState();
    }

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
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return RadarChart(
                    RadarChartData(
                      radarShape: RadarShape.polygon,
                      tickCount: 4,
                      ticksTextStyle: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 10,
                      ),
                      radarBackgroundColor: Colors.transparent,
                      borderData: FlBorderData(show: false),
                      gridBorderData: BorderSide(
                        color: AppTheme.borderPrimary.withOpacity(0.3),
                        width: 1,
                      ),
                      getTitle: (index, angle) {
                        if (index < widget.labels.length) {
                          return RadarChartTitle(
                            text: widget.labels[index],
                            angle: angle,
                            textStyle: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        return const RadarChartTitle(text: '');
                      },
                      dataSets: [
                        RadarDataSet(
                          fillColor: widget.primaryColor.withOpacity(0.2),
                          borderColor: widget.primaryColor,
                          borderWidth: 3,
                          entryRadius: 5,
                          dataEntries: _buildRadarDataEntries(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
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
          'Analiza wielowymiarowa portfela',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  List<RadarEntry> _buildRadarDataEntries() {
    return widget.metrics.values.map((value) {
      // Normalizuj wartości do zakresu 0-100
      final normalizedValue = (value / 100).clamp(0.0, 1.0) * _animation.value;
      return RadarEntry(value: normalizedValue * 100);
    }).toList();
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
            Icon(Icons.radar_rounded, size: 64, color: AppTheme.textTertiary),
            const SizedBox(height: 16),
            Text(
              'Brak danych dla analizy radar',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// 💹 BUBBLE CHART RYZYKO VS ZWROT
class PremiumRiskReturnBubbleChart extends StatefulWidget {
  final List<InvestorSummary> investors;
  final String title;
  final Color primaryColor;

  const PremiumRiskReturnBubbleChart({
    super.key,
    required this.investors,
    required this.title,
    this.primaryColor = AppTheme.primaryColor,
  });

  @override
  State<PremiumRiskReturnBubbleChart> createState() =>
      _PremiumRiskReturnBubbleChartState();
}

class _PremiumRiskReturnBubbleChartState
    extends State<PremiumRiskReturnBubbleChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<ScatterSpot> _bubbleData = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _prepareBubbleData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _prepareBubbleData() {
    _bubbleData = widget.investors.asMap().entries.map((entry) {
      final investor = entry.value;
      final risk = _calculateRisk(investor);
      final returnVal = _calculateReturn(investor);

      return ScatterSpot(
        risk,
        returnVal,
        dotPainter: FlDotCirclePainter(
          radius: (investor.viableRemainingCapital / 1000000).clamp(3.0, 12.0),
          color: widget.primaryColor.withOpacity(0.7),
          strokeColor: widget.primaryColor,
          strokeWidth: 2,
        ),
      );
    }).toList();
  }

  double _calculateReturn(InvestorSummary investor) {
    // Oblicz średni zwrot na podstawie inwestycji
    if (investor.investments.isEmpty) return 0.0;

    double totalReturn = 0;
    int validInvestments = 0;

    for (final investment in investor.investments) {
      if (investment.investmentAmount > 0) {
        // ⭐ Zwrot obliczony tylko na podstawie kapitału pozostałego
        final returnValue = (investment.remainingCapital - investment.investmentAmount) / 
                           investment.investmentAmount * 100;
        totalReturn += returnValue;
        validInvestments++;
      }
    }

    return validInvestments > 0 ? totalReturn / validInvestments : 0.0;
  }

  double _calculateRisk(InvestorSummary investor) {
    // Uproszczone obliczenie ryzyka
    final productTypes = investor.investments
        .map((inv) => inv.productType)
        .toSet()
        .length;
    final totalInvestments = investor.investments.length;

    return totalInvestments > 0
        ? ((1 - (productTypes / totalInvestments)) * 100).clamp(0.0, 100.0)
        : 50.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_bubbleData.isEmpty) {
      return _buildEmptyState();
    }

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
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return ScatterChart(
                    ScatterChartData(
                      scatterSpots: _bubbleData,
                      minX: 0,
                      maxX: 100,
                      minY: -20,
                      maxY: 50,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: true,
                        horizontalInterval: 10,
                        verticalInterval: 20,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppTheme.borderPrimary.withOpacity(0.3),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: AppTheme.borderPrimary.withOpacity(0.3),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}%',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.textTertiary),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${value.toInt()}%',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppTheme.textTertiary),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      scatterTouchData: ScatterTouchData(
                        touchTooltipData: ScatterTouchTooltipData(
                          getTooltipColor: (_) => Colors.black87,
                          getTooltipItems: (ScatterSpot touchedSpot) {
                            final index = _bubbleData.indexOf(touchedSpot);
                            if (index >= 0 && index < widget.investors.length) {
                              final investor = widget.investors[index];
                              return ScatterTooltipItem(
                                '${investor.client.name}\n'
                                'Ryzyko: ${touchedSpot.x.toStringAsFixed(1)}%\n'
                                'Zwrot: ${touchedSpot.y.toStringAsFixed(1)}%\n'
                                'Kapitał: ${CurrencyFormatter.formatCurrencyShort(investor.viableRemainingCapital)}',
                              );
                            }
                            return ScatterTooltipItem('');
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
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
          'Analiza bąbelkowa: Ryzyko vs Zwrot (wielkość = kapitał)',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        ),
      ],
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
              Icons.bubble_chart_rounded,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Brak danych dla analizy bąbelkowej',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
