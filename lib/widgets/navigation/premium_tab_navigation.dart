import 'package:flutter/material.dart';
import '../../theme/app_theme_professional.dart';

/// Zaawansowany widget przełączania widoków z ulepszonymi animacjami
/// i dostosowaniem do AppThemePro
class PremiumTabNavigation extends StatefulWidget {
  final TabController tabController;
  final List<PremiumTabItem> tabs;
  final bool isTablet;
  final bool isExportMode;
  final bool isEmailMode;
  final VoidCallback? onExportToggle;
  final VoidCallback? onEmailToggle;
  final Widget? customExportBar;
  final Widget? customEmailBar;
  final EdgeInsets? padding;
  final double? height;
  final bool showBadges;
  final Map<int, int>? badgeCounts;

  const PremiumTabNavigation({
    super.key,
    required this.tabController,
    required this.tabs,
    this.isTablet = false,
    this.isExportMode = false,
    this.isEmailMode = false,
    this.onExportToggle,
    this.onEmailToggle,
    this.customExportBar,
    this.customEmailBar,
    this.padding,
    this.height,
    this.showBadges = false,
    this.badgeCounts,
  });

  @override
  State<PremiumTabNavigation> createState() => _PremiumTabNavigationState();
}

class _PremiumTabNavigationState extends State<PremiumTabNavigation>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Kontroler dla animacji przesuwania
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Kontroler dla animacji zanikania
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Kontroler dla animacji skalowania
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    // Definicje animacji
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Uruchom animacje przy inicjalizacji
    _slideController.forward();
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void didUpdateWidget(PremiumTabNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animacja przy zmianie trybu
    if (oldWidget.isExportMode != widget.isExportMode ||
        oldWidget.isEmailMode != widget.isEmailMode) {
      _fadeController.reset();
      _scaleController.reset();
      _fadeController.forward();
      _scaleController.forward();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: widget.height ?? _calculateHeight(),
        padding: widget.padding ?? EdgeInsets.zero,
        decoration: _buildContainerDecoration(),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppThemePro.backgroundSecondary,
          AppThemePro.backgroundPrimary,
        ],
        stops: const [0.0, 1.0],
      ),
      border: Border(
        bottom: BorderSide(
          color: AppThemePro.accentGold.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: AppThemePro.primaryDark.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: AppThemePro.accentGold.withValues(alpha: 0.1),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (widget.isExportMode && widget.customExportBar != null) {
      return widget.customExportBar!;
    }

    if (widget.isEmailMode && widget.customEmailBar != null) {
      return widget.customEmailBar!;
    }

    return _buildTabBar();
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: widget.tabController,
      isScrollable: !widget.isTablet && widget.tabs.length > 3,
      labelColor: AppThemePro.accentGold,
      unselectedLabelColor: AppThemePro.textSecondary,
      indicatorColor: AppThemePro.accentGold,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      labelStyle: TextStyle(
        fontSize: widget.isTablet ? 15 : 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: widget.isTablet ? 15 : 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
      ),
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            AppThemePro.accentGold.withValues(alpha: 0.25),
            AppThemePro.accentGold.withValues(alpha: 0.1),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.accentGold.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      tabs: widget.tabs.map((tab) => _buildAnimatedTab(tab)).toList(),
    );
  }

  Widget _buildAnimatedTab(PremiumTabItem tab) {
    final index = widget.tabs.indexOf(tab);
    final isSelected = widget.tabController.index == index;
    final badgeCount = widget.showBadges && widget.badgeCounts != null
        ? widget.badgeCounts![index]
        : null;

    return AnimatedBuilder(
      animation: widget.tabController.animation!,
      builder: (context, child) {
        final animationValue = _getTabAnimationValue(index);

        return Transform.scale(
          scale: 0.95 + (0.05 * animationValue),
          child: Tab(
            height: widget.isTablet ? 70 : 65,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isTablet ? 16 : 12,
                vertical: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTabIcon(tab, isSelected, animationValue, badgeCount),
                  const SizedBox(height: 6),
                  _buildTabLabel(tab, isSelected, animationValue),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabIcon(
    PremiumTabItem tab,
    bool isSelected,
    double animationValue,
    int? badgeCount,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isSelected
                ? AppThemePro.accentGold.withValues(alpha: 0.15)
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? AppThemePro.accentGold.withValues(alpha: 0.4)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              tab.icon,
              key: ValueKey(isSelected),
              size: widget.isTablet ? 22 : 20,
              color: Color.lerp(
                AppThemePro.textSecondary,
                AppThemePro.accentGold,
                animationValue,
              ),
            ),
          ),
        ),

        // Badge z liczbą
        if (badgeCount != null && badgeCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppThemePro.statusError,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppThemePro.statusError.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabLabel(
    PremiumTabItem tab,
    bool isSelected,
    double animationValue,
  ) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: TextStyle(
        fontSize: widget.isTablet ? 13 : 11,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: Color.lerp(
          AppThemePro.textSecondary,
          AppThemePro.accentGold,
          animationValue,
        ),
        letterSpacing: isSelected ? 0.5 : 0.2,
      ),
      child: Text(
        tab.label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  double _getTabAnimationValue(int index) {
    if (widget.tabController.animation == null) return 0.0;

    final animation = widget.tabController.animation!;
    final currentIndex = animation.value;

    if (index == currentIndex.round()) {
      return 1.0;
    } else if ((index - currentIndex).abs() <= 1.0) {
      return 1.0 - (index - currentIndex).abs();
    }

    return 0.0;
  }

  double _calculateHeight() {
    if (widget.isExportMode || widget.isEmailMode) {
      return 80;
    }
    return widget.isTablet ? 85 : 80;
  }
}

/// Model dla elementu zakładki
class PremiumTabItem {
  final String label;
  final IconData icon;
  final String? tooltip;
  final bool enabled;
  final Color? customColor;

  const PremiumTabItem({
    required this.label,
    required this.icon,
    this.tooltip,
    this.enabled = true,
    this.customColor,
  });
}

/// Rozszerzenie dla łatwego tworzenia standardowych zakładek
extension PremiumTabExtensions on PremiumTabItem {
  static const overview = PremiumTabItem(
    label: 'Przegląd',
    icon: Icons.dashboard_rounded,
    tooltip: 'Ogólny przegląd danych',
  );

  static const investors = PremiumTabItem(
    label: 'Inwestorzy',
    icon: Icons.people_rounded,
    tooltip: 'Lista i szczegóły inwestorów',
  );

  static const analytics = PremiumTabItem(
    label: 'Analityka',
    icon: Icons.analytics_rounded,
    tooltip: 'Zaawansowane analizy i wykresy',
  );

  static const majority = PremiumTabItem(
    label: 'Większość',
    icon: Icons.groups_rounded,
    tooltip: 'Analiza grup większościowych',
  );

  static const exports = PremiumTabItem(
    label: 'Eksport',
    icon: Icons.download_rounded,
    tooltip: 'Eksport danych',
  );

  static const settings = PremiumTabItem(
    label: 'Ustawienia',
    icon: Icons.settings_rounded,
    tooltip: 'Konfiguracja aplikacji',
  );
}

/// Widget pomocniczy dla mode bar (eksport/email)
class PremiumModeBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Widget> actions;
  final VoidCallback? onClose;

  const PremiumModeBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.actions,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: AppThemePro.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          subtitle,
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
            ),
          ),
          const SizedBox(width: 16),
          ...actions.map(
            (action) =>
                Padding(padding: const EdgeInsets.only(left: 8), child: action),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onClose,
              style: IconButton.styleFrom(
                backgroundColor: AppThemePro.statusError.withValues(alpha: 0.1),
                foregroundColor: AppThemePro.statusError,
                padding: const EdgeInsets.all(12),
              ),
              icon: const Icon(Icons.close_rounded, size: 20),
              tooltip: 'Zamknij tryb',
            ),
          ],
        ],
      ),
    );
  }
}
