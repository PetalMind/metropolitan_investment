import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../models_and_services.dart';
import '../../theme/app_theme.dart';

/// 🦸‍♂️ CLIENTS HERO SECTION
///
/// Spektakularny nagłówek z:
/// - Animated gradient background z particles
/// - Smart badges z real-time metrics
/// - Contextual actions z fluid transitions
/// - AI-powered insights z visual indicators
/// - Progressive disclosure z micro-interactions
class ClientsHeroSection extends StatefulWidget {
  final ClientStats? clientStats;
  final Map<String, dynamic> intelligenceData;
  final List<ClientInsight> insights;
  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback onExitSelection;
  final VoidCallback onBulkEmail;
  final VoidCallback onToggleIntelligence;
  final bool canEdit;

  const ClientsHeroSection({
    super.key,
    this.clientStats,
    required this.intelligenceData,
    required this.insights,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.onExitSelection,
    required this.onBulkEmail,
    required this.onToggleIntelligence,
    required this.canEdit,
  });

  @override
  State<ClientsHeroSection> createState() => _ClientsHeroSectionState();
}

class _ClientsHeroSectionState extends State<ClientsHeroSection>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _metricsController;
  late AnimationController _actionsController;
  late AnimationController _insightsController;
  late AnimationController _particleController;

  late Animation<double> _backgroundAnimation;
  late Animation<double> _metricsSlideAnimation;
  late Animation<double> _actionsScaleAnimation;
  late Animation<double> _insightsPulseAnimation;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pl_PL',
    symbol: 'zł',
    decimalDigits: 0,
  );

  List<Particle> _particles = [];
  final bool _showInsights = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
    _startAnimations();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _metricsController.dispose();
    _actionsController.dispose();
    _insightsController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _metricsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _actionsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _insightsController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    _metricsSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _metricsController, curve: Curves.easeOutQuart),
    );

    _actionsScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _actionsController, curve: Curves.elasticOut),
    );

    _insightsPulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _insightsController, curve: Curves.elasticInOut),
    );
  }

  void _generateParticles() {
    final random = math.Random();
    _particles = List.generate(15, (index) {
      return Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 4 + 2,
        speed: random.nextDouble() * 0.5 + 0.1,
        opacity: random.nextDouble() * 0.6 + 0.2,
      );
    });
  }

  void _startAnimations() {
    _metricsController.forward();
    _backgroundController.repeat();
    _particleController.repeat();
    _insightsController.repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _actionsController.forward();
    });
  }

  @override
  void didUpdateWidget(ClientsHeroSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSelectionMode != oldWidget.isSelectionMode) {
      if (widget.isSelectionMode) {
        _actionsController.forward();
      } else {
        _actionsController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.isSelectionMode ? 280 : 320,
      decoration: _buildGradientBackground(),
      child: Stack(
        children: [
          // 🌟 Animated particles
          _buildParticleLayer(),

          // 📊 Main content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Title and intelligence toggle
                _buildHeaderRow(),

                const SizedBox(height: 24),

                // Selection mode vs Normal mode
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: widget.isSelectionMode
                      ? _buildSelectionModeContent()
                      : _buildNormalModeContent(),
                ),
              ],
            ),
          ),

          // 🎭 Selection mode overlay
          if (widget.isSelectionMode) _buildSelectionOverlay(),
        ],
      ),
    );
  }

  BoxDecoration _buildGradientBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.primaryColor.withOpacity(0.9),
          AppTheme.secondaryGold.withOpacity(0.8),
          AppTheme.primaryColor.withOpacity(0.95),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(_backgroundAnimation.value * math.pi / 4),
      ),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primaryColor.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget _buildParticleLayer() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            animation: _particleController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🎯 Title with icon
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isSelectionMode
                              ? '✉️ Wybierz Klientów'
                              : '👥 Baza Klientów',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isSelectionMode
                              ? 'Zaznacz klientów do wysłania email'
                              : 'Zarządzanie i analiza portfela klientów',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 🔧 Action buttons
        _buildHeaderActions(),
      ],
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Intelligence toggle
        ScaleTransition(
          scale: _actionsScaleAnimation,
          child: _buildActionButton(
            icon: Icons.psychology_rounded,
            label: 'Insights',
            onTap: widget.onToggleIntelligence,
            isActive: _showInsights,
          ),
        ),

        const SizedBox(width: 12),

        // Selection mode actions
        if (widget.isSelectionMode) ...[
          ScaleTransition(
            scale: _actionsScaleAnimation,
            child: _buildActionButton(
              icon: Icons.close_rounded,
              label: 'Anuluj',
              onTap: widget.onExitSelection,
              isDestructive: true,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withOpacity(0.25)
                : isDestructive
                ? Colors.red.withOpacity(0.2)
                : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? Colors.white.withOpacity(0.4)
                  : isDestructive
                  ? Colors.red.withOpacity(0.3)
                  : Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionModeContent() {
    return Column(
      key: const ValueKey('selection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selection stats
        Row(
          children: [
            _buildSelectionBadge(
              '${widget.selectedCount}',
              'Wybrano',
              Icons.check_circle_rounded,
              AppTheme.successColor,
            ),
            const SizedBox(width: 16),
            if (widget.selectedCount > 0)
              _buildActionBadge(
                'Wyślij Email',
                Icons.email_rounded,
                widget.onBulkEmail,
              ),
          ],
        ),

        const SizedBox(height: 24),

        // Quick actions row
        _buildSelectionActions(),
      ],
    );
  }

  Widget _buildNormalModeContent() {
    return Column(
      key: const ValueKey('normal'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main metrics row
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(_metricsSlideAnimation),
          child: _buildMetricsRow(),
        ),

        const SizedBox(height: 24),

        // Insights row
        if (widget.insights.isNotEmpty && _showInsights)
          ScaleTransition(
            scale: _insightsPulseAnimation,
            child: _buildInsightsRow(),
          ),
      ],
    );
  }

  Widget _buildMetricsRow() {
    if (widget.clientStats == null) {
      return _buildLoadingMetrics();
    }

    final stats = widget.clientStats!;
    final avgInvestment = stats.totalInvestments > 0
        ? stats.totalRemainingCapital / stats.totalInvestments
        : 0.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildMetricBadge(
            '${stats.totalClients}',
            'Klientów',
            Icons.people_rounded,
            AppTheme.primaryColor,
          ),

          const SizedBox(width: 16),

          _buildMetricBadge(
            '${stats.totalInvestments}',
            'Inwestycji',
            Icons.trending_up_rounded,
            AppTheme.secondaryGold,
          ),

          const SizedBox(width: 16),

          _buildMetricBadge(
            _currencyFormat.format(stats.totalRemainingCapital),
            'Kapitał',
            Icons.account_balance_wallet_rounded,
            AppTheme.infoColor,
          ),

          const SizedBox(width: 16),

          _buildMetricBadge(
            _currencyFormat.format(avgInvestment),
            'Średnia',
            Icons.analytics_rounded,
            AppTheme.warningColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: widget.insights.map((insight) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildInsightBadge(insight),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsightBadge(ClientInsight insight) {
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: insightColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: insightColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(insightIcon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                insight.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Text(
                insight.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBadge(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBadge(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.secondaryGold.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.secondaryGold.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionActions() {
    return Row(
      children: [
        if (widget.canEdit)
          _buildActionBadge('Nowy Klient', Icons.add_rounded, () {
            // TODO: Implement new client
          }),

        const SizedBox(width: 16),

        _buildActionBadge('Eksport', Icons.download_rounded, () {
          // TODO: Implement export
        }),
      ],
    );
  }

  Widget _buildSelectionOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.secondaryGold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const SizedBox(),
      ),
    );
  }

  Widget _buildLoadingMetrics() {
    return Row(
      children: List.generate(4, (index) {
        return Padding(
          padding: EdgeInsets.only(right: index < 3 ? 16 : 0),
          child: Container(
            width: 140,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// 🌟 Particle system for background animation
class Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animation;

  ParticlePainter({required this.particles, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      // Update particle position
      particle.y += particle.speed * 0.01;
      if (particle.y > 1) {
        particle.y = -0.1;
        particle.x = math.Random().nextDouble();
      }

      final x = particle.x * size.width;
      final y = particle.y * size.height;

      paint.color = Colors.white.withOpacity(particle.opacity * 0.6);
      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

// Import the insight types from the main screen
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

enum InsightType { opportunity, warning, info, success }

enum InsightPriority { low, medium, high, critical }
