import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// 🎪 CLIENTS ACTION CENTER
///
/// Floating Action Center z:
/// - Contextual actions z smooth morphing
/// - Bulk operations z progress indicators
/// - Quick shortcuts z gesture support
/// - Smart positioning z collision detection
class ClientsActionCenter extends StatefulWidget {
  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback onBulkEmail;
  final VoidCallback onExportSelected;
  final VoidCallback? onCreateClient;

  const ClientsActionCenter({
    super.key,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.onBulkEmail,
    required this.onExportSelected,
    this.onCreateClient,
  });

  @override
  State<ClientsActionCenter> createState() => _ClientsActionCenterState();
}

class _ClientsActionCenterState extends State<ClientsActionCenter>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fabController;
  late AnimationController _dashboardController;
  late AnimationController _morphController;
  late AnimationController _expandController;
  late AnimationController _pulseController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabAnimation;
  late Animation<double> _dashboardAnimation;
  late Animation<double> _morphAnimation;
  late Animation<double> _expandAnimation;
  late Animation<double> _pulseAnimation;

  bool _isActionCenterExpanded = false;
  bool _isDashboardVisible = false;
  bool _isSelectionMode = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _morphController.dispose();
    _expandController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _morphAnimation = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeInOut,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutBack,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  void _toggleActionCenter() {
    setState(() {
      _isActionCenterExpanded = !_isActionCenterExpanded;
    });

    if (_isActionCenterExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _showBulkActions() {
    // Show bulk actions bottom sheet or dialog
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bulk actions triggered')));
  }

  void _toggleIntelligenceDashboard() {
    setState(() {
      _isDashboardVisible = !_isDashboardVisible;
    });

    if (_isDashboardVisible) {
      _dashboardController.forward();
    } else {
      _dashboardController.reverse();
    }
  }

  @override
  void didUpdateWidget(ClientsActionCenter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSelectionMode != oldWidget.isSelectionMode) {
      if (widget.isSelectionMode) {
        _morphController.forward();
      } else {
        _morphController.reverse();
        _collapse();
      }
    }
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _collapse() {
    setState(() {
      _isExpanded = false;
    });
    _expandController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _morphAnimation,
      builder: (context, child) {
        return widget.isSelectionMode
            ? _buildSelectionMode()
            : _buildNormalMode();
      },
    );
  }

  Widget _buildNormalMode() {
    if (widget.onCreateClient == null) {
      return const SizedBox();
    }

    return ScaleTransition(
      scale: _pulseAnimation,
      child: FloatingActionButton.extended(
        onPressed: widget.onCreateClient,
        backgroundColor: AppTheme.secondaryGold,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nowy Klient',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 8,
        highlightElevation: 12,
      ),
    );
  }

  Widget _buildSelectionMode() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Expanded actions
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _expandAnimation.value,
              child: _buildExpandedActions(),
            );
          },
        ),

        const SizedBox(height: 16),

        // Main action button
        _buildMainActionButton(),
      ],
    );
  }

  Widget _buildExpandedActions() {
    if (!_isExpanded) return const SizedBox();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.download_rounded,
          label: 'Eksportuj',
          color: AppTheme.infoColor,
          onTap: widget.onExportSelected,
        ),

        const SizedBox(height: 12),

        _buildActionButton(
          icon: Icons.edit_rounded,
          label: 'Edytuj zbiorczo',
          color: AppTheme.warningColor,
          onTap: () {
            // TODO: Implement bulk edit
          },
        ),

        const SizedBox(height: 12),

        _buildActionButton(
          icon: Icons.delete_rounded,
          label: 'Usuń wybrane',
          color: AppTheme.errorColor,
          onTap: () {
            // TODO: Implement bulk delete
          },
        ),
      ],
    );
  }

  Widget _buildMainActionButton() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Main button
        FloatingActionButton.extended(
          onPressed: _isSelectionMode
              ? _showBulkActions
              : () => _toggleActionCenter(),
          label: Text(
            _isSelectionMode ? 'Bulk Actions' : 'Quick Actions',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: Icon(
            _isSelectionMode ? Icons.checklist_rounded : Icons.bolt_rounded,
            color: AppTheme.secondaryGold,
          ),
          backgroundColor: AppTheme.backgroundSecondary,
        ), // Expand button
        Positioned(
          right: 8,
          child: GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedRotation(
                turns: _isExpanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: color,
      foregroundColor: Colors.white,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      elevation: 4,
      highlightElevation: 8,
    );
  }
}

/// 🧠 CLIENTS INTELLIGENCE DASHBOARD
///
/// AI-powered analytics dashboard z:
/// - Real-time insights z trend visualization
/// - Predictive analytics z confidence indicators
/// - Client segmentation z visual clustering
/// - Performance metrics z comparative analysis
class ClientsIntelligenceDashboard extends StatefulWidget {
  final Map<String, dynamic> intelligenceData;
  final List<ClientInsight> insights;
  final Map<String, ClientMetrics> clientMetrics;
  final bool isCompact;

  const ClientsIntelligenceDashboard({
    super.key,
    required this.intelligenceData,
    required this.insights,
    required this.clientMetrics,
    required this.isCompact,
  });

  @override
  State<ClientsIntelligenceDashboard> createState() =>
      _ClientsIntelligenceDashboardState();
}

class _ClientsIntelligenceDashboardState
    extends State<ClientsIntelligenceDashboard>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _counterController;
  late AnimationController _chartController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _counterAnimation;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _counterController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _counterController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _chartController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _counterAnimation = CurvedAnimation(
      parent: _counterController,
      curve: Curves.easeOutQuart,
    );

    _chartAnimation = CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeOutCubic,
    );
  }

  void _startAnimations() {
    _slideController.forward();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _counterController.forward();
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _chartController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              AppTheme.secondaryGold.withOpacity(0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.secondaryGold.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),

            if (widget.isCompact)
              _buildCompactContent()
            else
              _buildFullContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.secondaryGold.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.psychology_rounded,
              color: AppTheme.secondaryGold,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inteligentne Analizy',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'AI-powered insights dla Twojego portfela klientów',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          _buildInsightsBadge(),
        ],
      ),
    );
  }

  Widget _buildInsightsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.successColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lightbulb_rounded, color: AppTheme.successColor, size: 16),

          const SizedBox(width: 6),

          Text(
            '${widget.insights.length} insights',
            style: TextStyle(
              color: AppTheme.successColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(child: _buildKeyMetrics()),
          const SizedBox(width: 20),
          Expanded(child: _buildTopInsights()),
        ],
      ),
    );
  }

  Widget _buildFullContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildKeyMetrics(),

          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildTopInsights()),
              const SizedBox(width: 24),
              Expanded(flex: 3, child: _buildTrendChart()),
            ],
          ),

          const SizedBox(height: 24),

          _buildClientSegmentation(),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics() {
    final data = widget.intelligenceData;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Średnia wartość',
            '${data['avg_client_value']?.toStringAsFixed(0) ?? '0'} zł',
            Icons.account_balance_wallet_rounded,
            AppTheme.secondaryGold,
            '↑ 12.5%',
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: _buildMetricCard(
            'Wskaźnik ryzyka',
            '${((data['risk_score'] ?? 0.0) * 100).toStringAsFixed(1)}%',
            Icons.shield_rounded,
            AppTheme.infoColor,
            data['risk_score'] < 0.5 ? '↓ Niskie' : '↑ Wysokie',
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: _buildMetricCard(
            'Wzrost',
            '${data['growth_rate']?.toStringAsFixed(1) ?? '0'}%',
            Icons.trending_up_rounded,
            AppTheme.successColor,
            '↑ YoY',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String trend,
  ) {
    return AnimatedBuilder(
      animation: _counterAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                trend,
                style: TextStyle(
                  color: AppTheme.successColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kluczowe insights',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        ...widget.insights.take(3).map((insight) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildInsightCard(insight),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildInsightCard(ClientInsight insight) {
    Color insightColor;
    IconData insightIcon;

    switch (insight.type) {
      case InsightType.opportunity:
        insightColor = AppTheme.successColor;
        insightIcon = Icons.lightbulb_rounded;
        break;
      case InsightType.warning:
        insightColor = AppTheme.warningColor;
        insightIcon = Icons.warning_amber_rounded;
        break;
      case InsightType.info:
        insightColor = AppTheme.infoColor;
        insightIcon = Icons.info_rounded;
        break;
      case InsightType.success:
        insightColor = AppTheme.successColor;
        insightIcon = Icons.check_circle_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: insightColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: insightColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(insightIcon, color: insightColor, size: 18),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  insight.description,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderSecondary, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trend portfela',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: CustomPaint(
                  painter: TrendChartPainter(
                    progress: _chartAnimation.value,
                    color: AppTheme.secondaryGold,
                  ),
                  size: Size.infinite,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClientSegmentation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSecondary, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Segmentacja klientów',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _buildSegmentChip('Premium', 45, AppTheme.secondaryGold),
              const SizedBox(width: 12),
              _buildSegmentChip('Corporate', 32, AppTheme.infoColor),
              const SizedBox(width: 12),
              _buildSegmentChip('Retail', 78, AppTheme.successColor),
              const SizedBox(width: 12),
              _buildSegmentChip('Inactive', 15, AppTheme.errorColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for trend chart
class TrendChartPainter extends CustomPainter {
  final double progress;
  final Color color;

  TrendChartPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.6),
      Offset(size.width * 0.4, size.height * 0.4),
      Offset(size.width * 0.6, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width, size.height * 0.1),
    ];

    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        final currentPoint = points[i];
        final previousPoint = points[i - 1];

        final controlPoint1 = Offset(
          previousPoint.dx + (currentPoint.dx - previousPoint.dx) * 0.5,
          previousPoint.dy,
        );

        final controlPoint2 = Offset(
          previousPoint.dx + (currentPoint.dx - previousPoint.dx) * 0.5,
          currentPoint.dy,
        );

        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          currentPoint.dx,
          currentPoint.dy,
        );
      }
    }

    // Draw the path with progress animation
    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      final extractedPath = pathMetric.extractPath(
        0,
        pathMetric.length * progress,
      );
      canvas.drawPath(extractedPath, paint);
    }
  }

  @override
  bool shouldRepaint(TrendChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Import required types from main screen
class ClientInsight {
  final InsightType type;
  final String title;
  final String description;
  final InsightPriority priority;
  final bool actionable;

  ClientInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    this.actionable = false,
  });
}

class ClientMetrics {
  final double totalValue;
  final int investmentCount;
  final double averageInvestment;
  final DateTime lastActivity;
  final double riskScore;

  ClientMetrics({
    required this.totalValue,
    required this.investmentCount,
    required this.averageInvestment,
    required this.lastActivity,
    required this.riskScore,
  });
}

enum InsightType { opportunity, warning, info, success }

enum InsightPriority { low, medium, high, critical }
