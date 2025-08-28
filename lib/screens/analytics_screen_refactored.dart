import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme_professional.dart';
import '../providers/auth_provider.dart';
import '../widgets/metropolitan_loading_system.dart';
import '../models_and_services.dart';
import '../services/analytics_screen_service.dart';
import '../models/analytics/overview_analytics_models.dart';
import 'dart:math' as math;

// Import wszystkich tabów
import 'analytics/tabs/overview_tab.dart';
import 'analytics/tabs/performance_tab.dart';
import 'analytics/tabs/risk_tab.dart';
import 'analytics/tabs/employees_tab.dart';
import 'analytics/tabs/geographic_tab.dart';
import 'analytics/tabs/trends_tab.dart';

// RBAC: wspólny tooltip dla braku uprawnień
const String kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

/// 🚀 PROFESSIONAL ANALYTICS SCREEN
/// Completely redesigned with professional theme and modular components
/// Uses AppThemePro for maximum readability and professional appearance
class AnalyticsScreenRefactored extends StatefulWidget {
  const AnalyticsScreenRefactored({super.key});

  @override
  State<AnalyticsScreenRefactored> createState() =>
      _AnalyticsScreenRefactoredState();
}

class _AnalyticsScreenRefactoredState extends State<AnalyticsScreenRefactored>
    with TickerProviderStateMixin {
  // UI State
  int _selectedTimeRange = 12;
  String _selectedAnalyticsTab = 'overview';
  bool _isLoading = true;
  
  // Advanced Animation Controllers
  late AnimationController _animationController;
  late AnimationController _staggerController;
  late AnimationController _hoverController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  
  // Sophisticated Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  
  // Hover and interaction states
  String? _hoveredTab;
  bool _isHovering = false;
  
  // Data state
  String? _error;
  double _loadingProgress = 0.0;
  
  // Analytics data and service
  final AnalyticsScreenService _analyticsService = AnalyticsScreenService();
  AnalyticsScreenData? _analyticsData;

  // RBAC getter
  bool get canEdit => Provider.of<AuthProvider>(context, listen: false).isAdmin;

  // Responsive breakpoints
  bool get _isTablet => MediaQuery.of(context).size.width > 768;

  // Tab definitions
  final List<_TabInfo> _tabs = [
    _TabInfo('overview', 'Przegląd', Icons.dashboard),
    _TabInfo('performance', 'Wydajność', Icons.trending_up),
    _TabInfo('risk', 'Ryzyko', Icons.warning_amber),
    _TabInfo('employees', 'Pracownicy', Icons.people),
    _TabInfo('geography', 'Geografia', Icons.map),
    _TabInfo('trends', 'Trendy', Icons.analytics),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _loadingProgress = 0.0;
      });

      // Progressive loading steps with real data fetching
      final loadingSteps = [
        'Łączenie z Firebase Functions...',
        'Pobieranie danych finansowych...',
        'Obliczanie metryki portfolio...',
        'Przetwarzanie analityki ryzyka...',
        'Generowanie trendów rynkowych...',
        'Przygotowywanie wizualizacji...',
        'Finalizacja obliczeń...',
      ];
      
      // Start the actual data fetching in parallel with UI updates
      final dataFuture = _analyticsService.getAnalyticsScreenData(
        timeRangeMonths: _selectedTimeRange,
        forceRefresh: true,
      );
      
      // Simulate progress updates while data is being fetched
      for (int i = 0; i < loadingSteps.length - 1; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          setState(() {
            _loadingProgress = (i + 1) / loadingSteps.length;
          });
        }
      }
      
      // Wait for actual data and complete loading
      final analyticsData = await dataFuture;
      
      if (mounted) {
        setState(() {
          _loadingProgress = 1.0;
          _analyticsData = analyticsData;
          _isLoading = false;
        });
        
        // Show success message with data details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppThemePro.statusSuccess,
                        AppThemePro.statusSuccess.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.analytics,
                    color: AppThemePro.textPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Analityka załadowana pomyślnie!',
                        style: TextStyle(
                          color: AppThemePro.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${analyticsData.totalClients} klientów, ${analyticsData.totalInvestments} inwestycji',
                        style: TextStyle(
                          color: AppThemePro.textPrimary.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppThemePro.accentGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${analyticsData.executionTimeMs}ms',
                    style: TextStyle(
                      color: AppThemePro.accentGold,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppThemePro.surfaceCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Błąd podczas ładowania analityki: ${e.toString()}';
          _isLoading = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppThemePro.textPrimary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Błąd ładowania analityki',
                        style: TextStyle(
                          color: AppThemePro.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        e.toString(),
                        style: TextStyle(
                          color: AppThemePro.textPrimary.withOpacity(0.8),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppThemePro.statusError,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 5),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _initializeAnimations() {
    // Main animation controller for entrance
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Stagger animation for UI elements
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Hover effects controller
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Pulse animation for interactive elements
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Shimmer effect for loading states
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Create sophisticated animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: Curves.easeOutCubic,
      ),
    );
    
    _slideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: Curves.easeOutQuart,
      ),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start animations with stagger effect
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Shimmer for loading effect
    _shimmerController.repeat(reverse: true);
    
    // Pulse for interactive elements
    _pulseController.repeat(reverse: true);
    
    // Start main entrance animation
    await Future.delayed(const Duration(milliseconds: 300));
    _animationController.forward();
    
    // Start stagger animation after main animation
    await Future.delayed(const Duration(milliseconds: 600));
    _staggerController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _staggerController.dispose();
    _hoverController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppThemePro.professionalTheme,
      child: Scaffold(
        backgroundColor: AppThemePro.backgroundPrimary,
        body: _isLoading
            ? _buildSophisticatedLoading()
            : _error != null
            ? _buildErrorState()
            : _buildMainContent(),
        floatingActionButton: _buildEnhancedFab(),
      ),
    );
  }
  
  Widget _buildSophisticatedLoading() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            AppThemePro.backgroundPrimary,
            AppThemePro.backgroundSecondary,
            AppThemePro.backgroundPrimary,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated background particles
          ...List.generate(20, (index) => _buildFloatingParticle(index)),
          
          // Main loading content
          Center(
            child: AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        AppThemePro.surfaceCard.withOpacity(0.8),
                        AppThemePro.surfaceElevated.withOpacity(0.6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppThemePro.accentGold.withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Premium loading animation
                      MetropolitanLoadingWidget.analytics(
                        showProgress: true,
                        progress: _loadingProgress,
                      ),
                      const SizedBox(height: 24),
                      
                      // Progress indicator with shimmer
                      Container(
                        width: 300,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: AppThemePro.surfaceInteractive,
                        ),
                        child: Stack(
                          children: [
                            // Progress bar
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _loadingProgress,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  gradient: LinearGradient(
                                    colors: [
                                      AppThemePro.accentGold,
                                      AppThemePro.accentGoldMuted,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            // Shimmer overlay
                            Positioned(
                              left: 300 * _shimmerAnimation.value * 0.3,
                              child: Container(
                                width: 60,
                                height: 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppThemePro.accentGold.withOpacity(0.4),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      Text(
                        '${(_loadingProgress * 100).toInt()}%',
                        style: TextStyle(
                          color: AppThemePro.accentGold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(40),
                margin: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppThemePro.statusError.withOpacity(0.1),
                      AppThemePro.surfaceCard,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppThemePro.statusError.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppThemePro.statusError.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Icon(
                            Icons.analytics_outlined,
                            size: 64,
                            color: AppThemePro.statusError,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Błąd ładowania analityki',
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: AppThemePro.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    _buildAnimatedButton(
                      onPressed: _loadAnalyticsData,
                      icon: Icons.refresh,
                      label: 'Ponów próbę',
                      color: AppThemePro.accentGold,
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
  
  Widget _buildMainContent() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            children: [
              _buildSpectacularHeader(),
              Expanded(
                child: SlideTransition(
                  position: _offsetAnimation,
                  child: _buildTabContent(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpectacularHeader() {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _slideAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppThemePro.primaryDark,
                  AppThemePro.primaryMedium,
                  AppThemePro.primaryLight.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppThemePro.accentGold.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Spectacular title with animation
                          AnimatedBuilder(
                            animation: _rotationAnimation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotationAnimation.value,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: RadialGradient(
                                          colors: [
                                            AppThemePro.accentGold,
                                            AppThemePro.accentGoldMuted,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppThemePro.accentGold.withOpacity(0.4),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.analytics,
                                        color: AppThemePro.primaryDark,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ShaderMask(
                                            shaderCallback: (bounds) => LinearGradient(
                                              colors: [
                                                AppThemePro.textPrimary,
                                                AppThemePro.accentGold,
                                                AppThemePro.textPrimary,
                                              ],
                                            ).createShader(bounds),
                                            child: Text(
                                              'Metropolitan Analytics',
                                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppThemePro.accentGold.withOpacity(0.2),
                                                  AppThemePro.accentGoldMuted.withOpacity(0.1),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: AppThemePro.accentGold.withOpacity(0.3),
                                              ),
                                            ),
                                            child: Text(
                                              'Profesjonalna analiza inwestycji w czasie rzeczywistym',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: AppThemePro.accentGold,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_isTablet) _buildEnhancedDesktopControls(),
                  ],
                ),
                const SizedBox(height: 32),
                _buildSpectacularTabBar(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedFab() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _rotationAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseAnimation.value - 1.0) * 0.1,
          child: MouseRegion(
            onEnter: (_) => _hoverController.forward(),
            onExit: (_) => _hoverController.reverse(),
            child: Tooltip(
              message: canEdit ? 'Odśwież dane analityczne' : kRbacNoPermissionTooltip,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: canEdit
                      ? LinearGradient(
                          colors: [
                            AppThemePro.accentGold,
                            AppThemePro.accentGoldMuted,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            Colors.grey.withOpacity(0.5),
                            Colors.grey.withOpacity(0.3),
                          ],
                        ),
                  boxShadow: canEdit ? [
                    BoxShadow(
                      color: AppThemePro.accentGold.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: AppThemePro.accentGold.withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ] : [],
                ),
                child: FloatingActionButton.extended(
                  onPressed: canEdit ? _refreshCurrentTab : null,
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppThemePro.primaryDark,
                  elevation: 0,
                  icon: AnimatedBuilder(
                    animation: _hoverController,
                    builder: (context, child) {
                      return AnimatedRotation(
                        turns: _isLoading ? _rotationAnimation.value : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Transform.scale(
                          scale: 1.0 + (_hoverController.value * 0.1),
                          child: Icon(
                            _isLoading ? Icons.hourglass_top : Icons.analytics,
                            color: canEdit ? AppThemePro.primaryDark : Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                  label: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _isLoading ? 'Ładowanie...' : 'Odśwież',
                      key: ValueKey(_isLoading),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: canEdit ? AppThemePro.primaryDark : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildFloatingParticle(int index) {
    final random = math.Random(index);
    final size = 2.0 + random.nextDouble() * 4.0;
    final left = random.nextDouble() * MediaQuery.of(context).size.width;
    final animationDelay = random.nextDouble() * 2000;
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final opacity = (math.sin((_pulseController.value * 2 * math.pi) + animationDelay) + 1) / 4;
        return Positioned(
          left: left,
          top: 100 + (math.sin(_pulseController.value * math.pi + animationDelay) * 50),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppThemePro.accentGold.withOpacity(opacity),
              boxShadow: [
                BoxShadow(
                  color: AppThemePro.accentGold.withOpacity(opacity * 0.5),
                  blurRadius: size * 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    String? tooltip,
  }) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: _isHovering ? 1.05 : 1.0,
            child: Tooltip(
              message: tooltip ?? label,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: onPressed != null ? [
                      color,
                      color.withOpacity(0.8),
                    ] : [
                      Colors.grey.withOpacity(0.3),
                      Colors.grey.withOpacity(0.2),
                    ],
                  ),
                  boxShadow: onPressed != null && _isHovering ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ] : [],
                ),
                child: ElevatedButton.icon(
                  onPressed: onPressed,
                  icon: AnimatedRotation(
                    turns: _isHovering ? 0.1 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(icon, size: 20),
                  ),
                  label: Text(label),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: onPressed != null
                        ? AppThemePro.primaryDark
                        : Colors.grey,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedDesktopControls() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Row(
          children: [
            _buildEnhancedTimeRangeSelector(),
            const SizedBox(width: 20),
            _buildAnimatedButton(
              onPressed: canEdit ? _exportReport : null,
              icon: Icons.file_download_outlined,
              label: 'Eksport',
              color: AppThemePro.accentGold,
              tooltip: canEdit ? 'Eksportuj raport analityczny' : kRbacNoPermissionTooltip,
            ),
          ],
        );
      },
    );
  }

  Widget _buildEnhancedTimeRangeSelector() {
    return MouseRegion(
      onEnter: (_) => _hoverController.forward(),
      onExit: (_) => _hoverController.reverse(),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_hoverController.value * 0.02),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppThemePro.surfaceElevated,
                    AppThemePro.surfaceInteractive,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppThemePro.accentGold.withOpacity(0.2 + (_hoverController.value * 0.3)),
                  width: 1 + _hoverController.value,
                ),
                boxShadow: [
                  if (_hoverController.value > 0.5)
                    BoxShadow(
                      color: AppThemePro.accentGold.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    color: AppThemePro.accentGold,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _selectedTimeRange,
                    underline: const SizedBox(),
                    style: TextStyle(
                      color: AppThemePro.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    dropdownColor: AppThemePro.surfaceCard,
                    icon: AnimatedRotation(
                      turns: _hoverController.value * 0.25,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppThemePro.accentGold,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 miesiąc')),
                      DropdownMenuItem(value: 3, child: Text('3 miesiące')),
                      DropdownMenuItem(value: 6, child: Text('6 miesięcy')),
                      DropdownMenuItem(value: 12, child: Text('12 miesięcy')),
                      DropdownMenuItem(value: 24, child: Text('24 miesiące')),
                      DropdownMenuItem(value: -1, child: Text('Cały okres')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedTimeRange = value);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpectacularTabBar() {
    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppThemePro.surfaceElevated.withOpacity(0.8),
              AppThemePro.surfaceCard.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppThemePro.accentGold.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _isTablet
            ? Row(
                children: _tabs
                    .asMap()
                    .entries
                    .map((entry) => Expanded(
                          child: _buildSpectacularTabButton(
                            entry.value,
                            index: entry.key,
                          ),
                        ))
                    .toList(),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _tabs
                      .asMap()
                      .entries
                      .map((entry) => _buildSpectacularTabButton(
                            entry.value,
                            isExpanded: false,
                            index: entry.key,
                          ))
                      .toList(),
                ),
              ),
      ),
    );
  }

  Widget _buildSpectacularTabButton(
    _TabInfo tab, {
    bool isExpanded = true,
    required int index,
  }) {
    final isSelected = _selectedAnalyticsTab == tab.id;
    final isHovered = _hoveredTab == tab.id;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredTab = tab.id),
      onExit: (_) => setState(() => _hoveredTab = null),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _staggerController]),
        builder: (context, child) {
          final delay = index * 100;
          final staggerValue = (_staggerController.value * 1000 - delay).clamp(0.0, 1.0);
          
          return Transform.translate(
            offset: Offset(0, 20 * (1 - staggerValue)),
            child: Opacity(
              opacity: staggerValue,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                width: isExpanded ? null : 130,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedAnalyticsTab = tab.id);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: isExpanded ? 12 : 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  AppThemePro.accentGold,
                                  AppThemePro.accentGoldMuted,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : isHovered
                                ? LinearGradient(
                                    colors: [
                                      AppThemePro.surfaceInteractive,
                                      AppThemePro.surfaceHover.withOpacity(0.5),
                                    ],
                                  )
                                : null,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppThemePro.accentGoldDark
                              : isHovered
                                  ? AppThemePro.accentGold.withOpacity(0.5)
                                  : AppThemePro.borderPrimary.withOpacity(0.3),
                          width: isSelected || isHovered ? 2 : 1,
                        ),
                        boxShadow: [
                          if (isSelected || isHovered)
                            BoxShadow(
                              color: (isSelected
                                      ? AppThemePro.accentGold
                                      : AppThemePro.surfaceInteractive)
                                  .withOpacity(0.3),
                              blurRadius: isSelected ? 15 : 8,
                              spreadRadius: isSelected ? 2 : 1,
                            ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isSelected || isHovered
                                  ? RadialGradient(
                                      colors: [
                                        (isSelected
                                                ? AppThemePro.primaryDark
                                                : AppThemePro.accentGold)
                                            .withOpacity(0.2),
                                        Colors.transparent,
                                      ],
                                    )
                                  : null,
                            ),
                            child: AnimatedScale(
                              scale: isHovered ? 1.1 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                tab.icon,
                                color: isSelected
                                    ? AppThemePro.primaryDark
                                    : isHovered
                                        ? AppThemePro.accentGold
                                        : AppThemePro.textSecondary,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              color: isSelected
                                  ? AppThemePro.primaryDark
                                  : isHovered
                                      ? AppThemePro.accentGold
                                      : AppThemePro.textPrimary,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                              letterSpacing: 0.2,
                            ),
                            child: Text(
                              tab.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppThemePro.primaryDark, AppThemePro.primaryMedium],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zaawansowana Analityka',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            color: AppThemePro.textPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kompleksowa analiza w czasie rzeczywistym z Firebase',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppThemePro.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isTablet) _buildDesktopControls(),
            ],
          ),
          const SizedBox(height: 24),
          _buildTabBar(),
        ],
      ),
    );
  }

  Widget _buildDesktopControls() {
    return Row(
      children: [
        _buildTimeRangeSelector(),
        const SizedBox(width: 16),
        Tooltip(
          message: canEdit ? 'Eksportuj raport' : kRbacNoPermissionTooltip,
          child: ElevatedButton.icon(
            onPressed: canEdit ? _exportReport : null,
            icon: Icon(
              Icons.download,
              color: canEdit ? AppThemePro.primaryDark : Colors.grey,
            ),
            label: Text(
              'Eksport',
              style: TextStyle(
                color: canEdit ? AppThemePro.primaryDark : Colors.grey,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemePro.accentGold,
              foregroundColor: AppThemePro.primaryDark,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: AppThemePro.elevatedSurfaceDecoration,
      child: DropdownButton<int>(
        value: _selectedTimeRange,
        underline: const SizedBox(),
        style: TextStyle(color: AppThemePro.textPrimary, fontSize: 14),
        dropdownColor: AppThemePro.surfaceCard,
        items: const [
          DropdownMenuItem(value: 1, child: Text('1 miesiąc')),
          DropdownMenuItem(value: 3, child: Text('3 miesiące')),
          DropdownMenuItem(value: 6, child: Text('6 miesięcy')),
          DropdownMenuItem(value: 12, child: Text('12 miesięcy')),
          DropdownMenuItem(value: 24, child: Text('24 miesiące')),
          DropdownMenuItem(value: -1, child: Text('Cały okres')),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedTimeRange = value);
          }
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: AppThemePro.elevatedSurfaceDecoration,
      child: _isTablet
          ? Row(
              children: _tabs
                  .map((tab) => Expanded(child: _buildTabButton(tab)))
                  .toList(),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tabs
                    .map((tab) => _buildTabButton(tab, isExpanded: false))
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildTabButton(_TabInfo tab, {bool isExpanded = true}) {
    final isSelected = _selectedAnalyticsTab == tab.id;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isExpanded ? null : 120,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedAnalyticsTab = tab.id),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 16,
              horizontal: isExpanded ? 12 : 16,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppThemePro.accentGold : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? null
                  : Border.all(color: AppThemePro.borderPrimary, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tab.icon,
                  color: isSelected
                      ? AppThemePro.primaryDark
                      : AppThemePro.accentGold,
                  size: 24,
                ),
                const SizedBox(height: 6),
                Text(
                  tab.label,
                  style: TextStyle(
                    color: isSelected
                        ? AppThemePro.primaryDark
                        : AppThemePro.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    // If no data is available yet, show loading or placeholder
    if (_analyticsData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppThemePro.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Dane analityczne będą dostępne po załadowaniu',
              style: TextStyle(
                color: AppThemePro.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    switch (_selectedAnalyticsTab) {
      case 'overview':
        return _buildOverviewTabWithData();
      case 'performance':
        return _buildPerformanceTabWithData();
      case 'risk':
        return _buildRiskTabWithData();
      case 'employees':
        return _buildEmployeesTabWithData();
      case 'geographic':
        return _buildGeographicTabWithData();
      case 'trends':
        return _buildTrendsTabWithData();
      default:
        return _buildOverviewTabWithData();
    }
  }
  
  Widget _buildOverviewTabWithData() {
    final data = _analyticsData!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildPortfolioMetricsCards(data.portfolioMetrics),
          const SizedBox(height: 24),
          _buildProductBreakdownChart(data.productBreakdown),
          const SizedBox(height: 24),
          _buildMonthlyPerformanceChart(data.monthlyPerformance),
          const SizedBox(height: 24),
          _buildClientAndRiskSummary(data.clientMetrics, data.riskMetrics),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceTabWithData() {
    return PerformanceTab(
      selectedTimeRange: _selectedTimeRange,
    );
  }
  
  Widget _buildRiskTabWithData() {
    return RiskTab(
      selectedTimeRange: _selectedTimeRange,
    );
  }
  
  Widget _buildEmployeesTabWithData() {
    return EmployeesTab(
      selectedTimeRange: _selectedTimeRange,
    );
  }
  
  Widget _buildGeographicTabWithData() {
    return GeographicTab(
      selectedTimeRange: _selectedTimeRange,
    );
  }
  
  Widget _buildTrendsTabWithData() {
    return TrendsTab(
      selectedTimeRange: _selectedTimeRange,
    );
  }
  
  /// Build portfolio metrics cards with real data
  Widget _buildPortfolioMetricsCards(PortfolioMetricsData metrics) {
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, child) {
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: _isTablet ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildMetricCard(
              title: 'Całkowita Wartość',
              value: CurrencyFormatter.formatCurrency(metrics.totalValue),
              icon: Icons.account_balance_wallet,
              color: AppThemePro.accentGold,
              subtitle: '+${metrics.growthPercentage.toStringAsFixed(1)}%',
            ),
            _buildMetricCard(
              title: 'Pozostały Kapitał',
              value: CurrencyFormatter.formatCurrency(metrics.totalInvested),
              icon: Icons.savings,
              color: AppThemePro.statusSuccess,
              subtitle: 'Dostępny',
            ),
            _buildMetricCard(
              title: 'Zrealizowany Zysk',
              value: CurrencyFormatter.formatCurrency(metrics.totalProfit),
              icon: Icons.trending_up,
              color: AppThemePro.bondsBlue,
              subtitle: 'ROI ${metrics.totalROI.toStringAsFixed(1)}%',
            ),
            _buildMetricCard(
              title: 'Aktywne Inwestycje',
              value: '${metrics.activeInvestmentsCount}',
              icon: Icons.pie_chart,
              color: AppThemePro.realEstateViolet,
              subtitle: '${metrics.totalInvestmentsCount} łącznie',
            ),
          ],
        );
      },
    );
  }
  
  /// Build individual metric card
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseAnimation.value - 1.0) * 0.02,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppThemePro.surfaceCard,
                  AppThemePro.surfaceElevated.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// Build product breakdown chart
  Widget _buildProductBreakdownChart(List<ProductBreakdownItem> breakdown) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Struktura Produktów',
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildProductBreakdownPieChart(breakdown),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildProductBreakdownLegend(breakdown),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build product breakdown pie chart (placeholder)
  Widget _buildProductBreakdownPieChart(List<ProductBreakdownItem> breakdown) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppThemePro.accentGold.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pie_chart,
              size: 64,
              color: AppThemePro.accentGold,
            ),
            const SizedBox(height: 8),
            Text(
              'Wykres Struktury',
              style: TextStyle(
                color: AppThemePro.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build product breakdown legend
  Widget _buildProductBreakdownLegend(List<ProductBreakdownItem> breakdown) {
    // Group breakdown items by product type and create display data
    final productTypeColors = {
      'bonds': AppThemePro.bondsBlue,
      'loans': AppThemePro.loansOrange,
      'shares': AppThemePro.sharesGreen,
      'apartments': AppThemePro.realEstateViolet,
      'other': AppThemePro.neutralGray,
    };
    
    final products = breakdown.take(5).map((item) {
      final color = productTypeColors[item.productType.toLowerCase()] ?? AppThemePro.neutralGray;
      return (item.productName.isNotEmpty ? item.productName : item.productType, item, color);
    }).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: products.map((product) {
        final name = product.$1;
        final data = product.$2;
        final color = product.$3;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${data.count} • ${data.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: AppThemePro.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.formatCurrency(data.value),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  /// Build monthly performance chart
  Widget _buildMonthlyPerformanceChart(List<MonthlyPerformanceItem> monthlyData) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wydajność Miesięczna',
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 48,
                    color: AppThemePro.accentGold,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Wykres wydajności dla ${monthlyData.length} miesięcy',
                    style: TextStyle(
                      color: AppThemePro.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  if (monthlyData.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Ostatnia wartość: ${CurrencyFormatter.formatCurrency(monthlyData.last.totalValue)}',
                      style: TextStyle(
                        color: AppThemePro.accentGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build client and risk summary
  Widget _buildClientAndRiskSummary(ClientMetricsData clientMetrics, RiskMetricsData riskMetrics) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: AppThemePro.premiumCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: AppThemePro.accentGold, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Metryki Klientów',
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSummaryRow('Łączna liczba', '${clientMetrics.totalClients}'),
                _buildSummaryRow('Aktywni', '${clientMetrics.activeClients}'),
                _buildSummaryRow('Nowi w tym miesiącu', '${clientMetrics.newClientsThisMonth}'),
                _buildSummaryRow(
                  'Średnia inwestycja',
                  CurrencyFormatter.formatCurrency(clientMetrics.averageClientValue),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: AppThemePro.premiumCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppThemePro.statusWarning, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Analiza Ryzyka',
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRiskRow('Wolatolność', '${riskMetrics.volatility.toStringAsFixed(2)}%', AppThemePro.statusError),
                _buildRiskRow('Współczynnik Sharpe', riskMetrics.sharpeRatio.toStringAsFixed(2), AppThemePro.statusWarning),
                _buildRiskRow('Max Drawdown', '${riskMetrics.maxDrawdown.toStringAsFixed(2)}%', AppThemePro.statusSuccess),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppThemePro.surfaceInteractive,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Poziom ryzyka: ${riskMetrics.riskLevel}',
                    style: TextStyle(
                      color: AppThemePro.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppThemePro.textSecondary,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRiskRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppThemePro.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshFab() {
    return Tooltip(
      message: canEdit ? 'Odśwież dane' : kRbacNoPermissionTooltip,
      child: FloatingActionButton.extended(
        onPressed: canEdit ? _refreshCurrentTab : null,
        backgroundColor: canEdit ? AppThemePro.accentGold : Colors.grey,
        foregroundColor: AppThemePro.primaryDark,
        elevation: 4,
        icon: const Icon(Icons.refresh),
        label: const Text('Odśwież'),
      ),
    );
  }

  void _refreshCurrentTab() {
    // Trigger refresh for current tab
    setState(() {
      // Force rebuild with new timestamp to trigger refresh
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Odświeżanie danych dla taba: ${_getTabName(_selectedAnalyticsTab)}',
          style: const TextStyle(color: AppThemePro.textPrimary),
        ),
        backgroundColor: AppThemePro.accentGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getTabName(String tabId) {
    final tab = _tabs.firstWhere(
      (tab) => tab.id == tabId,
      orElse: () => _TabInfo(tabId, 'Nieznany', Icons.help),
    );
    return tab.label;
  }

  void _exportReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppThemePro.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Eksport raportu',
          style: TextStyle(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Wybierz format eksportu:',
              style: TextStyle(color: AppThemePro.textSecondary),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              children: [
                _buildExportButton(
                  'PDF',
                  Icons.picture_as_pdf,
                  AppThemePro.statusError,
                  _exportToPDF,
                ),
                _buildExportButton(
                  'Excel',
                  Icons.table_chart,
                  AppThemePro.statusSuccess,
                  _exportToExcel,
                ),
                _buildExportButton(
                  'CSV',
                  Icons.text_snippet,
                  AppThemePro.statusWarning,
                  _exportToCSV,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Anuluj',
              style: TextStyle(color: AppThemePro.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _exportToPDF() {
    Navigator.of(context).pop();
    _showExportMessage('Eksport do PDF - funkcja w przygotowaniu');
  }

  void _exportToExcel() {
    Navigator.of(context).pop();
    _showExportMessage('Eksport do Excel - funkcja w przygotowaniu');
  }

  void _exportToCSV() {
    Navigator.of(context).pop();
    _showExportMessage('Eksport do CSV - funkcja w przygotowaniu');
  }

  void _showExportMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppThemePro.textPrimary),
        ),
        backgroundColor: AppThemePro.statusInfo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// Enhanced Tab Info class with additional properties
class _TabInfo {
  final String id;
  final String label;
  final IconData icon;
  final String? description;
  final Color? accentColor;

  const _TabInfo(
    this.id,
    this.label,
    this.icon, {
    this.description,
    this.accentColor,
  });
}
