import 'package:flutter/material.dart';
import '../../theme/app_theme_professional.dart';
import '../../models_and_services.dart';
import 'majority_stats_card.dart';
import 'majority_holders_list.dart';

/// Główny komponent widoku analizy większości z zaawansowanymi animacjami
class MajorityAnalysisView extends StatefulWidget {
  final List<InvestorSummary> majorityHolders;
  final double majorityThreshold;
  final double totalCapital;
  final bool isLoading;
  final bool isTablet;
  final ViewMode viewMode;
  final VoidCallback? onViewModeChanged;
  final Function(InvestorSummary)? onInvestorTap;

  const MajorityAnalysisView({
    super.key,
    required this.majorityHolders,
    required this.majorityThreshold,
    required this.totalCapital,
    this.isLoading = false,
    this.isTablet = false,
    required this.viewMode,
    this.onViewModeChanged,
    this.onInvestorTap,
  });

  @override
  State<MajorityAnalysisView> createState() => _MajorityAnalysisViewState();
}

class _MajorityAnalysisViewState extends State<MajorityAnalysisView>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _statsController;
  late AnimationController _listController;
  late AnimationController _pulseController;

  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _statsSlideAnimation;
  late Animation<double> _statsFadeAnimation;
  late Animation<double> _listFadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Kontroler dla animacji nagłówka
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Kontroler dla animacji statystyk
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Kontroler dla animacji listy
    _listController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Kontroler dla animacji pulsowania
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Definicje animacji nagłówka
    _headerSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    // Definicje animacji statystyk
    _statsSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(parent: _statsController, curve: Curves.easeOutCubic),
        );

    _statsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _statsController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    // Definicje animacji listy
    _listFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _listController, curve: Curves.easeOut));

    // Animacja pulsowania
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    // Sekwencyjne uruchamianie animacji
    _headerController.forward().then((_) {
      if (mounted) {
        _statsController.forward().then((_) {
          if (mounted) {
            _listController.forward();
            _pulseController.repeat(reverse: true);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _statsController.dispose();
    _listController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAnimatedHeader(),
          const SizedBox(height: 24),
          _buildAnimatedStats(),
          const SizedBox(height: 24),
          _buildAnimatedContent(),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _headerSlideAnimation,
        _headerFadeAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _headerSlideAnimation.value,
          child: FadeTransition(
            opacity: _headerFadeAnimation,
            child: _buildHeader(),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.accentGold.withValues(alpha: 0.1),
            AppThemePro.accentGoldMuted.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemePro.accentGold.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.accentGold.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppThemePro.accentGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.groups_rounded,
              color: AppThemePro.accentGold,
              size: widget.isTablet ? 32 : 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analiza Większości',
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontSize: widget.isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Minimalna koalicja kontrolująca ≥${widget.majorityThreshold.toStringAsFixed(0)}% kapitału',
                  style: TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: widget.isTablet ? 14 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppThemePro.statusSuccess,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppThemePro.statusSuccess.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    '${widget.majorityHolders.length} inwestorów',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStats() {
    return SlideTransition(
      position: _statsSlideAnimation,
      child: FadeTransition(
        opacity: _statsFadeAnimation,
        child: MajorityStatsCard(
          majorityHolders: widget.majorityHolders,
          majorityThreshold: widget.majorityThreshold,
          totalCapital: widget.totalCapital,
          isTablet: widget.isTablet,
        ),
      ),
    );
  }

  Widget _buildAnimatedContent() {
    return FadeTransition(
      opacity: _listFadeAnimation,
      child: MajorityHoldersList(
        majorityHolders: widget.majorityHolders,
        isTablet: widget.isTablet,
        onInvestorTap: () {
          // Lista ma wewnętrzną logikę wyboru inwestora
        },
      ),
    );
  }
}

/// Enum dla różnych trybów wyświetlania
enum ViewMode { list, cards, table }
