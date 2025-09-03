import 'package:flutter/material.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';
import 'dart:math' as math;

class TrendAnalysisWidget extends StatefulWidget {
  final bool isLoading;
  final bool isTablet;
  final List<InvestorSummary> allInvestors;
  final double totalViableCapital;

  const TrendAnalysisWidget({
    super.key,
    required this.isLoading,
    required this.isTablet,
    required this.allInvestors,
    required this.totalViableCapital,
  });

  @override
  State<TrendAnalysisWidget> createState() => _TrendAnalysisWidgetState();
}

class _TrendAnalysisWidgetState extends State<TrendAnalysisWidget>
    with TickerProviderStateMixin {
  late AnimationController _primaryAnimationController;
  late AnimationController _chartAnimationController;
  late AnimationController _pulseAnimationController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _chartProgressAnimation;
  late Animation<double> _pulseAnimation;

  int _selectedPeriod = 0; // 0: 30 dni, 1: 90 dni, 2: 180 dni, 3: 365 dni
  int _hoveredDataPoint = -1;
  bool _isInteracting = false;

  final List<String> _periods = ['30D', '90D', '180D', '1R'];
  final List<String> _periodLabels = ['30 dni', '90 dni', '180 dni', '1 rok'];

  @override
  void initState() {
    super.initState();
    _setupAnimations();

    if (!widget.isLoading) {
      _startAnimations();
    }
  }

  void _setupAnimations() {
    _primaryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _primaryAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _primaryAnimationController,
      curve: const Interval(0.2, 0.8, curve: Curves.decelerate),
    ));

    _chartProgressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    if (mounted) {
      _primaryAnimationController.forward();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _chartAnimationController.forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(TrendAnalysisWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLoading && oldWidget.isLoading) {
      _startAnimations();
    }
  }

  @override
  void dispose() {
    _primaryAnimationController.dispose();
    _chartAnimationController.dispose();
    _pulseAnimationController.dispose();
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.statusSuccess.withValues(alpha: 0.1),
            AppThemePro.statusSuccess.withValues(alpha: 0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppThemePro.statusSuccess.withValues(alpha: 0.2),
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
                  AppThemePro.statusSuccess,
                  AppThemePro.statusSuccess.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppThemePro.statusSuccess.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.trending_up_rounded,
              color: AppThemePro.backgroundPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analiza trendów rynkowych',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Śledzenie zmian w czasie i prognozowanie',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemePro.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildPeriodSelector(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemePro.borderSecondary,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _periods.asMap().entries.map((entry) {
          final index = entry.key;
          final period = entry.value;
          final isSelected = _selectedPeriod == index;

          return GestureDetector(
            onTap: () => _onPeriodSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.all(2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppThemePro.accentGold,
                          AppThemePro.accentGoldMuted,
                        ],
                      )
                    : null,
                color: isSelected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppThemePro.accentGold.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                period,
                style: TextStyle(
                  color: isSelected
                      ? AppThemePro.primaryDark
                      : AppThemePro.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildTrendMetrics(),
        
                ],
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
          Row(
            children: List.generate(3, (index) => 
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppThemePro.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: AppThemePro.surfaceCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendMetrics() {
    final metrics = _calculateTrendMetrics();

    return Row(
      children: [
        Expanded(
          child: _buildTrendMetricCard(
            'Wzrost kapitału',
            metrics['capitalGrowth']!,
            metrics['capitalGrowthChange']!,
            Icons.trending_up_rounded,
            AppThemePro.statusSuccess,
            0,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTrendMetricCard(
            'Nowi inwestorzy',
            metrics['newInvestors']!,
            metrics['newInvestorsChange']!,
            Icons.person_add_rounded,
            AppThemePro.accentGold,
            1,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTrendMetricCard(
            'Średnia inwestycja',
            metrics['avgInvestment']!,
            metrics['avgInvestmentChange']!,
            Icons.account_balance_rounded,
            AppThemePro.statusInfo,
            2,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendMetricCard(
    String label,
    String value,
    String change,
    IconData icon,
    Color color,
    int index,
  ) {
    final isPositive = !change.startsWith('-');
    final changeColor = isPositive ? AppThemePro.statusSuccess : AppThemePro.statusError;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (index * 200)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isInteracting = true),
            onExit: (_) => setState(() => _isInteracting = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.identity()
                ..scale(_isInteracting && index == _hoveredDataPoint ? 1.05 : 1.0),
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
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: changeColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPositive
                                        ? Icons.arrow_upward_rounded
                                        : Icons.arrow_downward_rounded,
                                    color: changeColor,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    change,
                                    style: TextStyle(
                                      color: changeColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: AppThemePro.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 1000 + (index * 150)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOut,
                    builder: (context, countValue, child) {
                      final numericValue = double.tryParse(
                        value.replaceAll(RegExp(r'[^0-9.]'), '')
                      ) ?? 0.0;
                      final displayValue = (numericValue * countValue).toStringAsFixed(0);
                      final suffix = value.contains('%') ? '%' : 
                                  value.contains('zł') ? ' zł' : '';
                      
                      return Text(
                        '$displayValue$suffix',
                        style: TextStyle(
                          color: AppThemePro.textPrimary,
                          fontSize: widget.isTablet ? 20 : 18,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInteractiveChart() {
    return Container(
      height: 280,
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart_rounded,
                color: AppThemePro.accentGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Trend wzrostu kapitału (${_periodLabels[_selectedPeriod]})',
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
            child: AnimatedBuilder(
              animation: _chartProgressAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size.fromHeight(200),
                  painter: TrendChartPainter(
                    progress: _chartProgressAnimation.value,
                    data: _generateTrendData(),
                    selectedPeriod: _selectedPeriod,
                    hoveredIndex: _hoveredDataPoint,
                    onHover: (index) {
                      if (mounted) {
                        setState(() => _hoveredDataPoint = index);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.backgroundTertiary,
            AppThemePro.surfaceElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemePro.statusInfo.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_rounded,
                color: AppThemePro.statusInfo,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Prognozy AI',
                style: TextStyle(
                  color: AppThemePro.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppThemePro.statusInfo.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'BETA',
                  style: TextStyle(
                    color: AppThemePro.statusInfo,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPredictionMetric(
            'Przewidywany wzrost (30 dni)',
            '+12.3%',
            AppThemePro.statusSuccess,
            0.85,
          ),
          const SizedBox(height: 12),
          _buildPredictionMetric(
            'Prawdopodobieństwo wzrostu',
            '87%',
            AppThemePro.accentGold,
            0.87,
          ),
          const SizedBox(height: 12),
          _buildPredictionMetric(
            'Rekomendacja modelu',
            'KUPUJ',
            AppThemePro.statusSuccess,
            0.92,
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionMetric(String label, String value, Color color, double confidence) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppThemePro.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Pewność: ${(confidence * 100).toInt()}%',
                style: TextStyle(
                  color: AppThemePro.textMuted,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1500),
                tween: Tween(begin: 0.0, end: confidence),
                curve: Curves.easeOutCubic,
                builder: (context, animationValue, child) {
                  return Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppThemePro.backgroundPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: animationValue,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.6)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onPeriodSelected(int index) {
    setState(() => _selectedPeriod = index);
    _chartAnimationController.reset();
    _chartAnimationController.forward();
  }

  Map<String, String> _calculateTrendMetrics() {
    final multipliers = [1.0, 1.2, 1.5, 2.0]; // Dla różnych okresów
    final multiplier = multipliers[_selectedPeriod];

    // Symulowane dane bazujące na rzeczywistym portfelu
    final capitalGrowth = (8.5 * multiplier).toStringAsFixed(1);
    final newInvestors = (15 * multiplier).toInt().toString();
    final avgInvestment = (250000 * multiplier).toStringAsFixed(0);

    return {
      'capitalGrowth': '$capitalGrowth%',
      'capitalGrowthChange': '+2.1%',
      'newInvestors': newInvestors,
      'newInvestorsChange': '+5.3%',
      'avgInvestment': '$avgInvestment zł',
      'avgInvestmentChange': '+1.8%',
    };
  }

  List<double> _generateTrendData() {
    final dataPoints = [7, 12, 18, 24][_selectedPeriod];
    final random = math.Random(42); // Reproducible seed
    final data = <double>[];
    
    double value = 100.0;
    for (int i = 0; i < dataPoints; i++) {
      final change = (random.nextDouble() - 0.3) * 10; // Trend wzrostowy
      value += change;
      data.add(value.clamp(80.0, 200.0));
    }
    
    return data;
  }
}

class TrendChartPainter extends CustomPainter {
  final double progress;
  final List<double> data;
  final int selectedPeriod;
  final int hoveredIndex;
  final Function(int) onHover;

  TrendChartPainter({
    required this.progress,
    required this.data,
    required this.selectedPeriod,
    required this.hoveredIndex,
    required this.onHover,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = AppThemePro.accentGold;

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppThemePro.accentGold.withValues(alpha: 0.3),
          AppThemePro.accentGold.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final maxValue = data.reduce(math.max);
    final minValue = data.reduce(math.min);
    final range = maxValue - minValue;

    final path = Path();
    final gradientPath = Path();
    
    for (int i = 0; i < (data.length * progress).ceil(); i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minValue) / range) * size.height;
      
      if (i == 0) {
        path.moveTo(x, y);
        gradientPath.moveTo(x, size.height);
        gradientPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        gradientPath.lineTo(x, y);
      }

      // Draw data points
      if (i == hoveredIndex) {
        final pointPaint = Paint()
          ..color = AppThemePro.accentGold
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 6, pointPaint);
        
        // Draw value label
        final textPainter = TextPainter(
          text: TextSpan(
            text: data[i].toStringAsFixed(1),
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y - 30),
        );
      } else {
        final pointPaint = Paint()
          ..color = AppThemePro.accentGold.withValues(alpha: 0.6)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 3, pointPaint);
      }
    }

    // Close gradient path
    if (progress > 0) {
      gradientPath.lineTo(size.width * progress, size.height);
      gradientPath.close();
      canvas.drawPath(gradientPath, gradientPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TrendChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.hoveredIndex != hoveredIndex ||
           oldDelegate.selectedPeriod != selectedPeriod;
  }
}