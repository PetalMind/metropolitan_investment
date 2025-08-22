import 'package:flutter/material.dart';
import '../../models_and_services.dart';

// Enum for view modes in products management
enum ProductViewMode {
  grid,
  list;

  IconData get icon {
    switch (this) {
      case ProductViewMode.grid:
        return Icons.grid_view;
      case ProductViewMode.list:
        return Icons.view_list;
    }
  }

  String get displayName {
    switch (this) {
      case ProductViewMode.grid:
        return 'Siatka';
      case ProductViewMode.list:
        return 'Lista';
    }
  }
}

/// 🚀 Nowoczesny, responsywny i animowany header dla Products Management Screen
///
/// Bazuje na PremiumAnalyticsHeader z premium_investor_analytics_screen
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
class ProductsManagementHeader extends StatefulWidget {
  // === REQUIRED PROPS ===
  final bool isTablet;
  final bool canEdit;
  final int totalCount;
  final bool isLoading;
  final bool isRefreshing;

  // === STATE PROPS ===
  final bool isSelectionMode;
  final bool isEmailMode;
  final bool isFilterVisible;
  final Set<String> selectedProductIds;
  final List<DeduplicatedProduct> displayedProducts;

  // === VIEW MODE ===
  final ProductViewMode currentViewMode;

  // === CALLBACKS ===
  final VoidCallback onRefresh;
  final VoidCallback onToggleEmail;
  final VoidCallback onToggleFilter;
  final ValueChanged<ProductViewMode> onViewModeChanged;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;

  const ProductsManagementHeader({
    super.key,
    required this.isTablet,
    required this.canEdit,
    required this.totalCount,
    required this.isLoading,
    required this.isRefreshing,
    required this.isSelectionMode,
    required this.isEmailMode,
    required this.isFilterVisible,
    required this.selectedProductIds,
    required this.displayedProducts,
    required this.currentViewMode,
    required this.onRefresh,
    required this.onToggleEmail,
    required this.onToggleFilter,
    required this.onViewModeChanged,
    required this.onSelectAll,
    required this.onClearSelection,
  });

  @override
  State<ProductsManagementHeader> createState() =>
      _ProductsManagementHeaderState();
}

class _ProductsManagementHeaderState extends State<ProductsManagementHeader>
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
  void didUpdateWidget(ProductsManagementHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Restart button animation when selection mode changes
    if (oldWidget.isSelectionMode != widget.isSelectionMode ||
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
          decoration: _buildHeaderDecoration(),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isTablet ? 24 : 16,
                vertical: 16,
              ),
              child: Row(
                children: [
                  _buildAnimatedIcon(),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTitleSection()),
                  const SizedBox(width: 16),
                  if (widget.isSelectionMode) ...[
                    _buildSelectionControls(),
                  ] else ...[
                    _buildActionButtons(),
                  ],
                  if (!widget.isTablet) ...[
                    const SizedBox(width: 8),
                    _buildFilterButton(),
                  ],
                ],
              ),
            ),
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
          AppTheme.backgroundSecondary.withOpacity(0.95),
          AppTheme.backgroundPrimary.withOpacity(0.98),
          AppTheme.backgroundPrimary,
        ],
      ),
      border: Border(
        bottom: BorderSide(
          color: AppTheme.secondaryGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: AppTheme.secondaryGold.withOpacity(
            0.1 * _glowPulseAnimation.value,
          ),
          blurRadius: 20,
          spreadRadius: 2,
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
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppTheme.secondaryGold.withOpacity(0.3),
              AppTheme.secondaryGold.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondaryGold.withOpacity(
                0.3 * _glowPulseAnimation.value,
              ),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          widget.isSelectionMode
              ? Icons.inventory_2_outlined
              : Icons.inventory_2,
          color: AppTheme.secondaryGold,
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
            const SizedBox(height: 4),
            _buildSubtitle(),
            _buildStatusBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle() {
    final title = widget.isSelectionMode
        ? 'Wybór Produktów'
        : 'Zarządzanie Produktami';

    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          AppTheme.secondaryGold,
          AppTheme.secondaryGold.withOpacity(0.8),
          AppTheme.textPrimary,
        ],
      ).createShader(bounds),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: Text(
          title,
          key: ValueKey(title),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: widget.isTablet ? 24 : 20,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    final subtitle =
        widget.isSelectionMode && widget.selectedProductIds.isNotEmpty
        ? 'Wybrano ${widget.selectedProductIds.length} z ${widget.displayedProducts.length} produktów'
        : '${widget.totalCount} produktów';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        subtitle,
        key: ValueKey(subtitle),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: widget.isLoading
            ? AppTheme.warningColor.withOpacity(0.1)
            : AppTheme.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isLoading
              ? AppTheme.warningColor.withOpacity(0.3)
              : AppTheme.successColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isLoading)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppTheme.warningColor),
              ),
            )
          else
            Icon(
              Icons.check_circle_rounded,
              size: 12,
              color: AppTheme.successColor,
            ),
          const SizedBox(width: 4),
          Text(
            widget.isLoading ? 'Ładowanie...' : 'Gotowe',
            style: TextStyle(
              fontSize: 10,
              color: widget.isLoading
                  ? AppTheme.warningColor
                  : AppTheme.successColor,
              fontWeight: FontWeight.w500,
            ),
          ),
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
          _buildSelectionButton(),
          if (widget.selectedProductIds.isNotEmpty) ...[
            const SizedBox(width: 8),
            _buildEmailButton(),
          ],
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSelectionButton() {
    final isAllSelected =
        widget.selectedProductIds.length == widget.displayedProducts.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: TextButton.icon(
        onPressed: isAllSelected ? widget.onClearSelection : widget.onSelectAll,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isAllSelected ? Icons.clear_all_rounded : Icons.select_all_rounded,
            key: ValueKey(isAllSelected),
            size: 16,
          ),
        ),
        label: Text(
          isAllSelected ? 'Odznacz' : 'Zaznacz wszystkie',
          style: TextStyle(fontSize: widget.isTablet ? 14 : 12),
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.secondaryGold,
          backgroundColor: AppTheme.secondaryGold.withOpacity(0.1),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isTablet ? 16 : 12,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppTheme.secondaryGold.withOpacity(0.3)),
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
                if (widget.canEdit) ...[
                  _buildEmailToggleButton(),
                  const SizedBox(width: 8),
                ],
                _buildViewModeToggle(),
                const SizedBox(width: 8),
                _buildFilterButton(),
              ],
            )
          : PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: AppTheme.textSecondary,
              ),
              tooltip: 'Więcej opcji',
              onSelected: (value) {
                switch (value) {
                  case 'refresh':
                    if (!widget.isLoading) widget.onRefresh();
                    break;
                  case 'email':
                    if (widget.canEdit) widget.onToggleEmail();
                    break;
                  case 'filter':
                    widget.onToggleFilter();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'refresh',
                  enabled: !widget.isLoading,
                  child: Row(
                    children: [
                      widget.isRefreshing
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  AppTheme.secondaryGold,
                                ),
                              ),
                            )
                          : Icon(Icons.refresh_rounded, size: 16),
                      const SizedBox(width: 8),
                      Text('Odśwież'),
                    ],
                  ),
                ),
                if (widget.canEdit)
                  PopupMenuItem(
                    value: 'email',
                    child: Row(
                      children: [
                        Icon(
                          widget.isEmailMode
                              ? Icons.close_rounded
                              : Icons.email_rounded,
                          size: 16,
                          color: widget.isEmailMode
                              ? AppTheme.errorColor
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.isEmailMode ? 'Zakończ email' : 'Wyślij email',
                        ),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'filter',
                  child: Row(
                    children: [
                      Icon(
                        widget.isFilterVisible
                            ? Icons.filter_list_off_rounded
                            : Icons.filter_list_rounded,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isFilterVisible
                            ? 'Ukryj filtry'
                            : 'Pokaż filtry',
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRefreshButton() {
    return Tooltip(
      message: 'Odśwież dane',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: widget.isRefreshing
              ? AppTheme.secondaryGold.withOpacity(0.2)
              : Colors.transparent,
        ),
        child: IconButton(
          onPressed: widget.isLoading ? null : widget.onRefresh,
          icon: widget.isRefreshing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppTheme.secondaryGold),
                  ),
                )
              : Icon(
                  Icons.refresh_rounded,
                  color: widget.isLoading
                      ? AppTheme.textTertiary
                      : AppTheme.textSecondary,
                ),
          tooltip: 'Odśwież dane',
          style: IconButton.styleFrom(
            backgroundColor: widget.isRefreshing
                ? AppTheme.secondaryGold.withOpacity(0.1)
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailToggleButton() {
    const kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

    return Tooltip(
      message: widget.canEdit
          ? (widget.isEmailMode ? 'Zakończ wysyłanie' : 'Tryb wysyłania emaili')
          : kRbacNoPermissionTooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: IconButton(
          onPressed: widget.canEdit ? widget.onToggleEmail : null,
          icon: Icon(
            widget.isEmailMode ? Icons.close_rounded : Icons.email_rounded,
            color: widget.canEdit
                ? (widget.isEmailMode
                      ? AppTheme.errorColor
                      : AppTheme.secondaryGold)
                : AppTheme.textTertiary,
          ),
          style: IconButton.styleFrom(
            backgroundColor: widget.isEmailMode
                ? AppTheme.errorColor.withOpacity(0.1)
                : AppTheme.secondaryGold.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: widget.isEmailMode
                    ? AppTheme.errorColor.withOpacity(0.3)
                    : AppTheme.secondaryGold.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailButton() {
    return Tooltip(
      message: 'Wyślij email do wybranych produktów',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: IconButton(
          onPressed: widget.canEdit ? widget.onToggleEmail : null,
          icon: Icon(
            Icons.email_rounded,
            color: widget.canEdit
                ? AppTheme.secondaryGold
                : AppTheme.textTertiary,
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.secondaryGold.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppTheme.secondaryGold.withOpacity(0.3)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return PopupMenuButton<ProductViewMode>(
      icon: Icon(widget.currentViewMode.icon, color: AppTheme.textSecondary),
      tooltip: 'Zmień widok (${widget.currentViewMode.displayName})',
      itemBuilder: (context) => ProductViewMode.values.map((mode) {
        return PopupMenuItem<ProductViewMode>(
          value: mode,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  mode.icon,
                  color: mode == widget.currentViewMode
                      ? AppTheme.secondaryGold
                      : AppTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.displayName,
                        style: TextStyle(
                          color: mode == widget.currentViewMode
                              ? AppTheme.secondaryGold
                              : AppTheme.textPrimary,
                          fontWeight: mode == widget.currentViewMode
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      Text(
                        _getViewModeDescription(mode),
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (mode == widget.currentViewMode) ...[
                  Icon(
                    Icons.check_rounded,
                    color: AppTheme.secondaryGold,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
      onSelected: widget.onViewModeChanged,
    );
  }

  String _getViewModeDescription(ProductViewMode mode) {
    switch (mode) {
      case ProductViewMode.list:
        return 'Lista produktów';
      case ProductViewMode.grid:
        return 'Siatka produktów';
    }
  }

  Widget _buildFilterButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: widget.isFilterVisible
            ? AppTheme.secondaryGold.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: IconButton(
        onPressed: widget.onToggleFilter,
        icon: Icon(
          widget.isFilterVisible
              ? Icons.filter_list_off_rounded
              : Icons.filter_list_rounded,
          color: widget.isFilterVisible
              ? AppTheme.secondaryGold
              : AppTheme.textSecondary,
        ),
        tooltip: widget.isFilterVisible ? 'Ukryj filtry' : 'Pokaż filtry',
        style: IconButton.styleFrom(
          backgroundColor: widget.isFilterVisible
              ? AppTheme.secondaryGold.withOpacity(0.1)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
