import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../models_and_services.dart';
import 'product_type_distribution_widget.dart';
import 'dart:math' as math;

/// 🎨 ANIMATED PRODUCT STATS
/// 
/// Nowoczesny widget statystyk produktów który:
/// - Zawija się podczas przewijania z płynną animacją
/// - Wyświetla interaktywne wykresy
/// - Animowane liczniki z easing
/// - Responsywny design (compact/full)
/// - Smart data visualization z gradientami
class AnimatedProductStats extends StatefulWidget {
  final dynamic productStatistics; // fb.ProductStatistics or similar
  final bool isLoading;
  final bool isCollapsed;
  final bool showCharts;
  final VoidCallback? onToggleCharts;
  final ScrollController? scrollController;

  const AnimatedProductStats({
    super.key,
    this.productStatistics,
    this.isLoading = false,
    this.isCollapsed = false,
    this.showCharts = true,
    this.onToggleCharts,
    this.scrollController,
  });

  @override
  State<AnimatedProductStats> createState() => _AnimatedProductStatsState();
}

class _AnimatedProductStatsState extends State<AnimatedProductStats>
    with TickerProviderStateMixin {
  
  late AnimationController _collapseController;
  late AnimationController _counterController;
  late AnimationController _chartController;
  late AnimationController _pulseController;
  
  late Animation<double> _collapseAnimation;
  late Animation<double> _counterAnimation;
  late Animation<double> _chartAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _wasScrollingDown = false;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_handleScroll);
    _collapseController.dispose();
    _counterController.dispose();
    _chartController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _collapseController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _counterController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _collapseAnimation = CurvedAnimation(
      parent: _collapseController,
      curve: Curves.easeInOutCubic,
    );
    
    _counterAnimation = CurvedAnimation(
      parent: _counterController,
      curve: Curves.easeOutQuart,
    );
    
    _chartAnimation = CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeInOutBack,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _counterController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start subtle pulse animation
    _pulseController.repeat(reverse: true);
    
    // Start animations when data is available
    if (widget.productStatistics != null) {
      _startAnimations();
    }
  }

  void _setupScrollListener() {
    widget.scrollController?.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (widget.scrollController == null) return;
    
    final currentOffset = widget.scrollController!.offset;
    final isScrollingDown = currentOffset > _lastScrollOffset;
    
    if (isScrollingDown != _wasScrollingDown) {
      if (isScrollingDown && currentOffset > 50) {
        _collapseController.forward();
      } else if (!isScrollingDown) {
        _collapseController.reverse();
      }
      _wasScrollingDown = isScrollingDown;
    }
    
    _lastScrollOffset = currentOffset;
  }

  void _startAnimations() {
    _counterController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && widget.showCharts) {
        _chartController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedProductStats oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.productStatistics != null && oldWidget.productStatistics == null) {
      _startAnimations();
    }
    
    if (widget.isCollapsed != oldWidget.isCollapsed) {
      if (widget.isCollapsed) {
        _collapseController.forward();
      } else {
        _collapseController.reverse();
      }
    }
    
    if (widget.showCharts != oldWidget.showCharts) {
      if (widget.showCharts) {
        _chartController.forward();
      } else {
        _chartController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.productStatistics == null) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _collapseAnimation,
        _counterAnimation,
        _chartAnimation,
        _pulseAnimation,
      ]),
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: _calculateHeight(),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.95),
                  AppTheme.primaryColor.withValues(alpha: 0.85),
                  AppTheme.secondaryGold.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 15 * (1 - _collapseAnimation.value),
                  offset: Offset(0, 8 * (1 - _collapseAnimation.value)),
                ),
              ],
            ),
            child: Stack(
              children: [
                _buildParticleBackground(),
                _buildContent(),
              ],
            ),
          ),
        );
      },
    );
  }

  double _calculateHeight() {
    final baseHeight = widget.isCollapsed ? 80.0 : 160.0;
    final chartsHeight = widget.showCharts && !widget.isCollapsed ? 200.0 : 0.0;
    return baseHeight + chartsHeight;
  }

  Widget _buildParticleBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: ProductStatsParticlePainter(
          animationValue: _pulseAnimation.value,
          isCollapsed: widget.isCollapsed,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          
          if (!widget.isCollapsed) ...[
            const SizedBox(height: 16),
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _counterAnimation,
                child: _buildStatsGrid(),
              ),
            ),
            
            if (widget.showCharts) ...[
              const SizedBox(height: 16),
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _chartAnimation,
                  child: _buildChartsSection(),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryGold),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Ładowanie statystyk produktów...',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.3),
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics_outlined,
              color: AppTheme.textSecondary,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              'Brak danych statystycznych',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.isCollapsed ? 'Statystyki' : 'Analiza Produktów',
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.isCollapsed ? 16 : 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final stats = widget.productStatistics;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Produkty',
            value: _animatedNumber(stats?.totalProducts?.toDouble() ?? 0, 0),
            icon: Icons.inventory_2,
            color: AppTheme.infoColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'Wartość',
            value: _formatCurrency(_animatedNumber(stats?.totalValue?.toDouble() ?? 0, 0)),
            icon: Icons.account_balance_wallet,
            color: AppTheme.secondaryGold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'Średnia',
            value: _formatCurrency(_animatedNumber(stats?.averageValue?.toDouble() ?? 0, 0)),
            icon: Icons.trending_up,
            color: AppTheme.successColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: ProductTypeDistributionWidget(
                productStatistics: widget.productStatistics,
                isLoading: widget.isLoading,
                height: 140,
                showAnimation: true,
                showLegend: false,
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: _buildValueTrendChart(),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildValueTrendChart() {
    return Column(
      children: [
        const Text(
          'Trend wartości',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return const FlLine(
                    color: Colors.white12,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: _generateTrendData(),
                  isCurved: true,
                  color: AppTheme.secondaryGold,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.secondaryGold.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _generateTrendData() {
    // Generate sample trend data based on animation progress
    final List<FlSpot> spots = [];
    for (int i = 0; i < 10; i++) {
      final x = i.toDouble();
      final y = (math.sin(i * 0.5) + 1) * 50 * _chartAnimation.value;
      spots.add(FlSpot(x, y));
    }
    return spots;
  }

  String _animatedNumber(double targetValue, int decimals) {
    final currentValue = targetValue * _counterAnimation.value;
    return decimals == 0 
        ? currentValue.round().toString()
        : currentValue.toStringAsFixed(decimals);
  }

  String _formatCurrency(String value) {
    final number = double.tryParse(value) ?? 0;
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}k';
    }
    return value;
  }
}

/// Custom painter for animated particle background
class ProductStatsParticlePainter extends CustomPainter {
  final double animationValue;
  final bool isCollapsed;

  ProductStatsParticlePainter({
    required this.animationValue,
    required this.isCollapsed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final particleCount = isCollapsed ? 5 : 12;
    
    for (int i = 0; i < particleCount; i++) {
      final progress = (animationValue + i * 0.1) % 1.0;
      final x = (size.width * 0.1) + (size.width * 0.8 * (i / particleCount));
      final y = size.height * 0.3 + 
          (size.height * 0.4 * math.sin(progress * 2 * math.pi + i));
      
      final radius = (2 + (i % 3)) * (isCollapsed ? 0.5 : 1.0);
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ProductStatsParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.isCollapsed != isCollapsed;
  }
}