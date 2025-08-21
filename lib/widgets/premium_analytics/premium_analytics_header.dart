import 'package:flutter/material.dart';
import '../../theme/app_theme_professional.dart';
import '../../models_and_services.dart';

/// 🚀 Nowoczesny, responsywny i animowany header dla Premium Analytics
///
/// Funkcje:
/// - Responsywny design (tablet/mobile)
/// - Płynne animacje i przejścia
/// - Tryb selekcji z licznikiem
/// - Przyciski: Refresh, Export, Email, Filter, ViewMode
/// - Gradient background z efektami świetlnymi
/// - RBAC support z tooltipami
/// - Accessibility support
/// - Mikrointerakcje i hover effects
///
/// Przykład użycia:
/// ```dart
/// PremiumAnalyticsHeader(
///   isTablet: MediaQuery.of(context).size.width > 768,
///   canEdit: Provider.of<AuthProvider>(context).isAdmin,
///   totalCount: investors.length,
///   isLoading: isLoadingData,
///   isRefreshing: isRefreshingData,
///   isSelectionMode: currentSelectionMode,
///   // ... pozostałe wymagane parametry
///   onRefresh: () => refreshData(),
///   onToggleExport: () => toggleExportMode(),
///   // ... pozostałe callbacki
/// )
/// ```
class PremiumAnalyticsHeader extends StatefulWidget {
  // === REQUIRED PROPS ===
  final bool isTablet;
  final bool canEdit;
  final int totalCount;
  final bool isLoading;
  final bool isRefreshing;

  // === STATE PROPS ===
  final bool isSelectionMode;
  final bool isExportMode;
  final bool isEmailMode;
  final bool isFilterVisible;
  final Set<String> selectedInvestorIds;
  final List<InvestorSummary> displayedInvestors;

  // === VIEW MODE ===
  final ViewMode currentViewMode;
  final bool isMajorityTab;

  // === CALLBACKS ===
  final VoidCallback onRefresh;
  final VoidCallback onToggleExport;
  final VoidCallback onToggleEmail;
  final VoidCallback onToggleFilter;
  final ValueChanged<ViewMode> onViewModeChanged;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;

  const PremiumAnalyticsHeader({
    super.key,
    required this.isTablet,
    required this.canEdit,
    required this.totalCount,
    required this.isLoading,
    required this.isRefreshing,
    required this.isSelectionMode,
    required this.isExportMode,
    required this.isEmailMode,
    required this.isFilterVisible,
    required this.selectedInvestorIds,
    required this.displayedInvestors,
    required this.currentViewMode,
    required this.isMajorityTab,
    required this.onRefresh,
    required this.onToggleExport,
    required this.onToggleEmail,
    required this.onToggleFilter,
    required this.onViewModeChanged,
    required this.onSelectAll,
    required this.onClearSelection,
  });

  @override
  State<PremiumAnalyticsHeader> createState() => _PremiumAnalyticsHeaderState();
}

class _PremiumAnalyticsHeaderState extends State<PremiumAnalyticsHeader>
    with TickerProviderStateMixin {
  late AnimationController _titleAnimationController;
  late AnimationController _buttonsAnimationController;
  late AnimationController _glowAnimationController;

  late Animation<double> _titleSlideAnimation;
  late Animation<double> _buttonsScaleAnimation;
  late Animation<double> _glowPulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _titleAnimationController.dispose();
    _buttonsAnimationController.dispose();
    _glowAnimationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _titleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _buttonsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _glowAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _titleSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _buttonsScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonsAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _glowPulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    _titleAnimationController.forward();
    _buttonsAnimationController.forward();
    _glowAnimationController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PremiumAnalyticsHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Restart button animation when selection mode changes
    if (oldWidget.isSelectionMode != widget.isSelectionMode ||
        oldWidget.isExportMode != widget.isExportMode ||
        oldWidget.isEmailMode != widget.isEmailMode) {
      _buttonsAnimationController.reset();
      _buttonsAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _titleAnimationController,
        _buttonsAnimationController,
        _glowAnimationController,
      ]),
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isTablet ? 24 : 16,
            vertical: 16,
          ),
          decoration: _buildHeaderDecoration(),
          child: Row(
            children: [
              _buildAnimatedIcon(),
              const SizedBox(width: 12),
              Expanded(child: _buildTitleSection()),
              if (widget.isSelectionMode) ...[
                _buildSelectionControls(),
              ] else ...[
                _buildActionButtons(),
                if (!widget.isTablet) ...[
                  const SizedBox(width: 4),
                  _buildViewModeToggle(),
                ],
              ],
              const SizedBox(width: 8),
              _buildFilterButton(),
            ],
          ),
        );
      },
    );
  }

  BoxDecoration _buildHeaderDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppThemePro.primaryDark,
          AppThemePro.primaryMedium.withValues(alpha: 0.9),
          AppThemePro.backgroundPrimary,
        ],
      ),
      border: Border(
        bottom: BorderSide(
          color: AppThemePro.accentGold.withValues(
            alpha: 0.3 * _glowPulseAnimation.value,
          ),
          width: 1,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: AppThemePro.accentGold.withValues(
            alpha: 0.1 * _glowPulseAnimation.value,
          ),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildAnimatedIcon() {
    return Transform.scale(
      scale: _buttonsScaleAnimation.value,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: RadialGradient(
            colors: [
              AppThemePro.accentGold.withValues(
                alpha: 0.3 * _glowPulseAnimation.value,
              ),
              AppThemePro.accentGold.withValues(
                alpha: 0.1 * _glowPulseAnimation.value,
              ),
              Colors.transparent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppThemePro.accentGold.withValues(
                alpha: 0.4 * _glowPulseAnimation.value,
              ),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          Icons.analytics_rounded,
          color: AppThemePro.accentGold,
          size: widget.isTablet ? 32 : 28,
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-0.3, 0),
        end: Offset.zero,
      ).animate(_titleSlideAnimation),
      child: FadeTransition(
        opacity: _titleSlideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedTitle(),
            if (widget.totalCount > 0) ...[
              const SizedBox(height: 4),
              _buildSubtitle(),
              const SizedBox(height: 4),
              _buildStatusBadge(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle() {
    final title = widget.isSelectionMode
        ? 'Wybór Inwestorów'
        : 'Analityka Inwestorów';

    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          AppThemePro.accentGold,
          AppThemePro.accentGoldMuted,
          AppThemePro.textPrimary,
        ],
      ).createShader(bounds),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: Text(
          title,
          key: ValueKey(title),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: AppThemePro.accentGold.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    final subtitle =
        widget.isSelectionMode && widget.selectedInvestorIds.isNotEmpty
        ? 'Wybrano ${widget.selectedInvestorIds.length} z ${widget.displayedInvestors.length} inwestorów'
        : '${widget.totalCount} inwestorów';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        subtitle,
        key: ValueKey(subtitle),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppThemePro.textSecondary),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: widget.isLoading
            ? AppThemePro.statusWarning.withOpacity(0.1)
            : AppThemePro.statusSuccess.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isLoading
              ? AppThemePro.statusWarning.withOpacity(0.3)
              : AppThemePro.statusSuccess.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isLoading) ...[
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppThemePro.statusWarning),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Ładowanie...',
              style: TextStyle(
                color: AppThemePro.statusWarning,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            Icon(
              Icons.check_circle_rounded,
              size: 12,
              color: AppThemePro.statusSuccess,
            ),
            const SizedBox(width: 4),
            Text(
              'Aktualny',
              style: TextStyle(
                color: AppThemePro.statusSuccess,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectionControls() {
    return ScaleTransition(
      scale: _buttonsScaleAnimation,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.displayedInvestors.isNotEmpty) ...[
            _buildSelectionButton(),
            const SizedBox(width: 8),
          ],
          _buildViewModeToggle(),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSelectionButton() {
    final isAllSelected =
        widget.selectedInvestorIds.length == widget.displayedInvestors.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: TextButton.icon(
        onPressed: isAllSelected ? widget.onClearSelection : widget.onSelectAll,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isAllSelected ? Icons.deselect : Icons.select_all,
            key: ValueKey(isAllSelected),
            size: 20,
            color: AppThemePro.accentGold,
          ),
        ),
        label: Text(
          isAllSelected ? 'Usuń zaznaczenie' : 'Zaznacz wszystko',
          style: TextStyle(
            fontSize: widget.isTablet ? 12 : 10,
            color: AppThemePro.accentGold,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppThemePro.accentGold,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isTablet ? 12 : 8,
            vertical: 4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppThemePro.accentGold.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return ScaleTransition(
      scale: _buttonsScaleAnimation,
      child: widget.isTablet
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRefreshButton(),
                const SizedBox(width: 8),
                _buildExportButton(),
                const SizedBox(width: 8),
                _buildEmailButton(),
                const SizedBox(width: 8),
                _buildViewModeToggle(),
                const SizedBox(width: 8),
              ],
            )
          : PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: AppThemePro.textSecondary,
              ),
              tooltip: 'Więcej opcji',
              onSelected: (value) {
                switch (value) {
                  case 'refresh':
                    if (widget.canEdit && !widget.isLoading) widget.onRefresh();
                    break;
                  case 'export':
                    if (widget.canEdit) widget.onToggleExport();
                    break;
                  case 'email':
                    if (widget.canEdit) widget.onToggleEmail();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'refresh',
                  enabled: widget.canEdit && !widget.isLoading,
                  child: Row(
                    children: [
                      widget.isRefreshing
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  AppThemePro.accentGold,
                                ),
                              ),
                            )
                          : Icon(Icons.refresh_rounded, size: 16),
                      const SizedBox(width: 8),
                      Text('Odśwież'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'export',
                  enabled: widget.canEdit,
                  child: Row(
                    children: [
                      Icon(
                        widget.isExportMode
                            ? Icons.close_rounded
                            : Icons.download_rounded,
                        size: 16,
                        color: widget.isExportMode
                            ? AppThemePro.statusError
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isExportMode ? 'Zakończ eksport' : 'Eksportuj',
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'email',
                  enabled: widget.canEdit,
                  child: Row(
                    children: [
                      Icon(
                        widget.isEmailMode
                            ? Icons.close_rounded
                            : Icons.email_rounded,
                        size: 16,
                        color: widget.isEmailMode
                            ? AppThemePro.statusError
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isEmailMode ? 'Zakończ email' : 'Wyślij email',
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRefreshButton() {
    const kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

    return Tooltip(
      message: widget.canEdit ? 'Odśwież dane' : kRbacNoPermissionTooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: widget.isRefreshing
              ? AppThemePro.statusWarning.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: IconButton(
          onPressed: (!widget.canEdit || widget.isLoading)
              ? null
              : widget.onRefresh,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: widget.isRefreshing
                ? SizedBox(
                    key: const ValueKey('loading'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        AppThemePro.accentGold,
                      ),
                    ),
                  )
                : Icon(
                    key: const ValueKey('refresh'),
                    Icons.refresh_rounded,
                    color: widget.canEdit
                        ? AppThemePro.textSecondary
                        : Colors.grey,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    const kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

    return Tooltip(
      message: widget.canEdit
          ? (widget.isExportMode ? 'Zakończ eksport' : 'Eksportuj dane')
          : kRbacNoPermissionTooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: widget.isExportMode
              ? AppThemePro.statusError.withOpacity(0.1)
              : Colors.transparent,
          border: widget.isExportMode
              ? Border.all(color: AppThemePro.statusError.withOpacity(0.3))
              : null,
        ),
        child: IconButton(
          onPressed: !widget.canEdit ? null : widget.onToggleExport,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              widget.isExportMode
                  ? Icons.close_rounded
                  : Icons.download_rounded,
              key: ValueKey(widget.isExportMode),
              color: widget.isExportMode
                  ? AppThemePro.statusError
                  : (widget.canEdit ? AppThemePro.accentGold : Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailButton() {
    const kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

    return Tooltip(
      message: widget.canEdit
          ? (widget.isEmailMode ? 'Zakończ wysyłanie' : 'Wyślij emaile')
          : kRbacNoPermissionTooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: widget.isEmailMode
              ? AppThemePro.statusError.withOpacity(0.1)
              : Colors.transparent,
          border: widget.isEmailMode
              ? Border.all(color: AppThemePro.statusError.withOpacity(0.3))
              : null,
        ),
        child: IconButton(
          onPressed: !widget.canEdit ? null : widget.onToggleEmail,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              widget.isEmailMode ? Icons.close_rounded : Icons.email_rounded,
              key: ValueKey(widget.isEmailMode),
              color: widget.isEmailMode
                  ? AppThemePro.statusError
                  : (widget.canEdit ? AppThemePro.accentGold : Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return ViewModeSelector(
      currentMode: widget.currentViewMode,
      onModeChanged: widget.onViewModeChanged,
      isTablet: widget.isTablet,
    );
  }

  Widget _buildFilterButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: widget.isFilterVisible
            ? AppThemePro.accentGold.withOpacity(0.1)
            : Colors.transparent,
        border: widget.isFilterVisible
            ? Border.all(color: AppThemePro.accentGold.withOpacity(0.3))
            : null,
      ),
      child: IconButton(
        onPressed: widget.onToggleFilter,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            widget.isFilterVisible
                ? Icons.filter_list_off_rounded
                : Icons.filter_list_rounded,
            key: ValueKey(widget.isFilterVisible),
            color: widget.isFilterVisible
                ? AppThemePro.accentGold
                : AppThemePro.textSecondary,
          ),
        ),
        tooltip: 'Filtry',
      ),
    );
  }
}
