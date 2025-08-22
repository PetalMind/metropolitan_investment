import 'package:flutter/material.dart';
import '../../models_and_services.dart';
import 'total_capital_edit_dialog.dart';

/// 🚀 NOWOCZESNY REDESIGN - ProductDetailsHeader
/// 
/// Cechy nowego designu:
/// • Fluid glassmorphism z dynamicznymi gradientami
/// • Adaptacyjny layout z inteligentnym skalowaniem
/// • Micro-interactions z płynymi animacjami
/// • Modern card-based metrics z depth shadows
/// • Advanced responsive breakpoints
/// • Enhanced accessibility i visual hierarchy
/// • Premium dark theme z gold accents
class ProductDetailsHeader extends StatefulWidget {
  final UnifiedProduct product;
  final List<InvestorSummary> investors;
  final bool isLoadingInvestors;
  final VoidCallback onClose;
  final VoidCallback? onShowInvestors;
  final Function(bool)? onEditModeChanged;
  final Function(int)? onTabChanged;
  final Future<void> Function()? onDataChanged;
  final bool isCollapsed;
  final double collapseFactor;

  const ProductDetailsHeader({
    super.key,
    required this.product,
    required this.investors,
    required this.isLoadingInvestors,
    required this.onClose,
    this.onShowInvestors,
    this.onEditModeChanged,
    this.onTabChanged,
    this.onDataChanged,
    this.isCollapsed = false,
    this.collapseFactor = 1.0,
  });

  @override
  State<ProductDetailsHeader> createState() => _ProductDetailsHeaderState();
}

class _ProductDetailsHeaderState extends State<ProductDetailsHeader>
    with TickerProviderStateMixin {
  
  // 🎬 ANIMACJE - Multiple controllers for sophisticated micro-interactions
  late final AnimationController _mainController;
  late final AnimationController _metricsController;
  late final AnimationController _pulseController;
  late final AnimationController _editModeController;
  
  late final Animation<double> _slideUpAnimation;
  late final Animation<double> _fadeInAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _metricsSlideAnimation;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _editModeAnimation;

  // 📊 DANE I SERWISY
  final UnifiedProductModalService _modalService = UnifiedProductModalService();
  ProductModalData? _modalData;
  bool _isLoadingStatistics = false;
  bool _isEditModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startEntryAnimation();
    _loadServerStatistics();
  }

  void _initializeAnimations() {
    // Main entry animation
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Metrics delayed animation
    _metricsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Continuous pulse for interactive elements
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Edit mode transition
    _editModeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Define animations with sophisticated curves
    _slideUpAnimation = Tween<double>(
      begin: 80.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Cubic(0.25, 0.46, 0.45, 0.94), // easeOutQuart
    ));

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Cubic(0.175, 0.885, 0.32, 1.275), // easeOutBack
    ));

    _metricsSlideAnimation = Tween<double>(
      begin: 60.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _metricsController,
      curve: const Cubic(0.25, 0.46, 0.45, 0.94),
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _editModeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _editModeController,
      curve: Curves.elasticOut,
    ));
  }

  void _startEntryAnimation() async {
    _mainController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      _metricsController.forward();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ProductDetailsHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.investors != widget.investors ||
        oldWidget.isLoadingInvestors != widget.isLoadingInvestors) {
      _modalService.clearProductCache(widget.product.id);
      _loadServerStatistics();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _metricsController.dispose();
    _pulseController.dispose();
    _editModeController.dispose();
    super.dispose();
  }

  // 📊 DATA LOADING
  Future<void> _loadServerStatistics() async {
    await _loadServerStatisticsInternal(forceRefresh: false);
  }

  Future<void> _loadServerStatisticsInternal({required bool forceRefresh}) async {
    if (widget.isLoadingInvestors || widget.investors.isEmpty) return;
    if (widget.product.name.trim().isEmpty) return;

    setState(() => _isLoadingStatistics = true);

    try {
      final modalData = await _modalService.getProductModalData(
        product: widget.product,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      setState(() {
        _modalData = modalData;
        _isLoadingStatistics = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingStatistics = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ResponsiveContainer(
      collapseFactor: widget.collapseFactor,
      child: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideUpAnimation.value),
            child: Opacity(
              opacity: _fadeInAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: _ModernHeaderContainer(
                  isCollapsed: widget.isCollapsed,
                  collapseFactor: widget.collapseFactor,
                  product: widget.product,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildActionBar(),
                      _buildProductInfo(),
                      if (!widget.isCollapsed && !_isLoadingStatistics) 
                        _buildMetricsSection(),
                      if (!widget.isCollapsed && _isLoadingStatistics)
                        _buildLoadingMetrics(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔥 NOWY ACTION BAR - Floating glass buttons
  Widget _buildActionBar() {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.isCollapsed ? 8 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Edit Mode Toggle
          AnimatedBuilder(
            animation: _editModeAnimation,
            builder: (context, child) {
              return _GlassActionButton(
                onPressed: _toggleEditMode,
                icon: _isEditModeEnabled ? Icons.visibility : Icons.edit,
                color: _isEditModeEnabled ? AppTheme.successPrimary : AppTheme.secondaryGold,
                tooltip: _isEditModeEnabled ? 'Wyłącz edycję' : 'Włącz edycję',
                isActive: _isEditModeEnabled,
                pulseAnimation: _pulseAnimation,
                editModeAnimation: _editModeAnimation,
              );
            },
          ),
          const SizedBox(width: 12),
          // Close Button
          _GlassActionButton(
            onPressed: widget.onClose,
            icon: Icons.close,
            color: AppTheme.textPrimary,
            tooltip: 'Zamknij',
          ),
        ],
      ),
    );
  }

  // 🎯 NOWY PRODUCT INFO - Enhanced layout with status indicator
  Widget _buildProductInfo() {
    return _ResponsiveLayout(
      mobile: _buildMobileProductInfo(),
      desktop: _buildDesktopProductInfo(),
    );
  }

  Widget _buildMobileProductInfo() {
    if (widget.isCollapsed) {
      return _CollapsedProductInfo(
        product: widget.product,
        collapseFactor: widget.collapseFactor,
      );
    }
    
    return _ExpandedMobileProductInfo(
      product: widget.product,
      collapseFactor: widget.collapseFactor,
    );
  }

  Widget _buildDesktopProductInfo() {
    return _DesktopProductInfo(
      product: widget.product,
      collapseFactor: widget.collapseFactor,
      isCollapsed: widget.isCollapsed,
    );
  }

  // 📊 NOWY METRICS SECTION - Card-based layout
  Widget _buildMetricsSection() {
    return AnimatedBuilder(
      animation: _metricsController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _metricsSlideAnimation.value),
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: _MetricsGrid(
              modalData: _modalData,
              investors: widget.investors,
              product: widget.product,
              isEditModeEnabled: _isEditModeEnabled,
              onCapitalEdit: _openTotalCapitalEditDialog,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingMetrics() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: _LoadingMetricsGrid(),
    );
  }

  // 🎛️ ACTIONS
  void _toggleEditMode() {
    setState(() {
      _isEditModeEnabled = !_isEditModeEnabled;
    });

    if (_isEditModeEnabled) {
      _editModeController.forward();
      widget.onTabChanged?.call(1);
    } else {
      _editModeController.reverse();
    }

    widget.onEditModeChanged?.call(_isEditModeEnabled);
    _showModernSnackBar(
      _isEditModeEnabled 
        ? 'Tryb edycji włączony'
        : 'Tryb edycji wyłączony',
      isSuccess: true,
    );
  }

  void _openTotalCapitalEditDialog() async {
    if (!_isEditModeEnabled) return;

    try {
      final allInvestorSummaries = _modalData?.investors ?? <InvestorSummary>[];
      final allInvestments = <Investment>[];

      for (final investor in allInvestorSummaries) {
        for (final investment in investor.investments) {
          bool belongsToProduct = false;

          if (investment.productId != null &&
              investment.productId!.isNotEmpty &&
              investment.productId != "null") {
            if (investment.productId == widget.product.id) {
              belongsToProduct = true;
            }
          }

          if (!belongsToProduct) {
            if (investment.productName.trim().toLowerCase() ==
                widget.product.name.trim().toLowerCase()) {
              belongsToProduct = true;
            }
          }

          if (belongsToProduct) {
            allInvestments.add(investment);
          }
        }
      }

      final uniqueInvestments = <String, Investment>{};
      for (final investment in allInvestments) {
        final key = investment.id.isNotEmpty
            ? investment.id
            : '${investment.productName}_${investment.investmentAmount}_${investment.clientId}';
        uniqueInvestments[key] = investment;
      }

      final investments = uniqueInvestments.values.toList();

      if (!mounted) return;

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => TotalCapitalEditDialog(
          product: widget.product,
          currentTotalCapital: _modalData?.statistics.totalRemainingCapital ?? 
              _computeTotalRemainingCapital(),
          investments: investments,
          onChanged: () async {
            await _modalService.clearProductCache(widget.product.id);
            _loadServerStatisticsInternal(forceRefresh: true);
            if (widget.onDataChanged != null) {
              await widget.onDataChanged!();
            }
          },
        ),
      );

      if (result == true) {
        _showModernSnackBar('Kapitał zaktualizowany pomyślnie', isSuccess: true);
      }
    } catch (e) {
      _showModernSnackBar('Błąd podczas edycji kapitału', isSuccess: false);
    }
  }

  void _showModernSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? AppTheme.successPrimary : AppTheme.errorPrimary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // 🧮 HELPER COMPUTATIONS
  double _computeTotalRemainingCapital() {
    double sum = 0.0;
    final processedIds = <String>{};

    for (final investor in widget.investors) {
      for (final investment in investor.investments) {
        if (investment.productName != widget.product.name) continue;
        if (processedIds.contains(investment.id)) continue;
        processedIds.add(investment.id);
        sum += investment.remainingCapital;
      }
    }
    return sum;
  }
}

// 🎨 RESPONSIVE CONTAINER - Main container with adaptive sizing
class _ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double collapseFactor;

  const _ResponsiveContainer({
    required this.child,
    required this.collapseFactor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;
    
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 120 * collapseFactor,
        maxHeight: isDesktop ? 400 : 350,
      ),
      child: child,
    );
  }
}

// 🌟 MODERN HEADER CONTAINER - Glassmorphism with dynamic gradients
class _ModernHeaderContainer extends StatelessWidget {
  final Widget child;
  final bool isCollapsed;
  final double collapseFactor;
  final UnifiedProduct product;

  const _ModernHeaderContainer({
    required this.child,
    required this.isCollapsed,
    required this.collapseFactor,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final productColor = AppTheme.getProductTypeColor(product.productType.collectionName);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24 * collapseFactor),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundSecondary.withOpacity(0.95),
            productColor.withOpacity(0.1),
            AppTheme.backgroundTertiary.withOpacity(0.9),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(
          color: AppTheme.borderPrimary.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: productColor.withOpacity(0.15),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// 📱 RESPONSIVE LAYOUT - Adaptive mobile/desktop
class _ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;

  const _ResponsiveLayout({
    required this.mobile,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 768 ? mobile : desktop;
  }
}

// 🔘 GLASS ACTION BUTTON - Modern floating buttons
class _GlassActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;
  final String tooltip;
  final bool isActive;
  final Animation<double>? pulseAnimation;
  final Animation<double>? editModeAnimation;

  const _GlassActionButton({
    required this.onPressed,
    required this.icon,
    required this.color,
    required this.tooltip,
    this.isActive = false,
    this.pulseAnimation,
    this.editModeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive 
            ? [
                color.withOpacity(0.2),
                color.withOpacity(0.1),
              ]
            : [
                AppTheme.surfaceContainer.withOpacity(0.8),
                AppTheme.surfaceCard.withOpacity(0.6),
              ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color.withOpacity(0.5) : AppTheme.borderPrimary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isActive ? color : AppTheme.shadowColor).withOpacity(0.2),
            blurRadius: isActive ? 12 : 8,
            spreadRadius: isActive ? 1 : 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isActive ? color : AppTheme.textPrimary,
          size: 20,
        ),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
      ),
    );

    if (pulseAnimation != null && isActive) {
      button = AnimatedBuilder(
        animation: pulseAnimation!,
        builder: (context, child) {
          return Transform.scale(
            scale: pulseAnimation!.value,
            child: button,
          );
        },
      );
    }

    if (editModeAnimation != null && isActive) {
      button = AnimatedBuilder(
        animation: editModeAnimation!,
        builder: (context, child) {
          return Transform.rotate(
            angle: editModeAnimation!.value * 0.1,
            child: button,
          );
        },
      );
    }

    return button;
  }
}

// 📊 COLLAPSED PRODUCT INFO - Compact horizontal layout
class _CollapsedProductInfo extends StatelessWidget {
  final UnifiedProduct product;
  final double collapseFactor;

  const _CollapsedProductInfo({
    required this.product,
    required this.collapseFactor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ProductIcon(
          product: product,
          size: 40 * collapseFactor,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16 * collapseFactor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              _ProductTypeBadge(
                productType: product.productType,
                isCompact: true,
              ),
            ],
          ),
        ),
        _StatusIndicator(
          status: product.status,
          isCompact: true,
        ),
      ],
    );
  }
}

// 📱 EXPANDED MOBILE PRODUCT INFO
class _ExpandedMobileProductInfo extends StatelessWidget {
  final UnifiedProduct product;
  final double collapseFactor;

  const _ExpandedMobileProductInfo({
    required this.product,
    required this.collapseFactor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _ProductIcon(
              product: product,
              size: 56 * collapseFactor,
            ),
            const Spacer(),
            _StatusIndicator(status: product.status),
          ],
        ),
        SizedBox(height: 16 * collapseFactor),
        Text(
          product.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24 * collapseFactor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 8 * collapseFactor),
        _ProductTypeBadge(productType: product.productType),
      ],
    );
  }
}

// 🖥️ DESKTOP PRODUCT INFO
class _DesktopProductInfo extends StatelessWidget {
  final UnifiedProduct product;
  final double collapseFactor;
  final bool isCollapsed;

  const _DesktopProductInfo({
    required this.product,
    required this.collapseFactor,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ProductIcon(
          product: product,
          size: isCollapsed ? 48 * collapseFactor : 64 * collapseFactor,
        ),
        SizedBox(width: 20 * collapseFactor),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: isCollapsed ? 20 * collapseFactor : 28 * collapseFactor,
                ),
                maxLines: isCollapsed ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isCollapsed) ...[
                SizedBox(height: 8 * collapseFactor),
                _ProductTypeBadge(productType: product.productType),
              ],
            ],
          ),
        ),
        _StatusIndicator(status: product.status),
      ],
    );
  }
}

// 🎯 PRODUCT ICON - Enhanced with animations
class _ProductIcon extends StatelessWidget {
  final UnifiedProduct product;
  final double size;

  const _ProductIcon({
    required this.product,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final productColor = AppTheme.getProductTypeColor(product.productType.collectionName);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            productColor.withOpacity(0.8),
            productColor,
            productColor.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(
          color: AppTheme.borderPrimary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: productColor.withOpacity(0.3),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 8,
            spreadRadius: -2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        _getProductIcon(product.productType),
        color: AppTheme.textOnPrimary,
        size: size * 0.5,
      ),
    );
  }

  IconData _getProductIcon(UnifiedProductType productType) {
    switch (productType) {
      case UnifiedProductType.bonds:
        return Icons.account_balance;
      case UnifiedProductType.shares:
        return Icons.trending_up;
      case UnifiedProductType.loans:
        return Icons.monetization_on;
      case UnifiedProductType.apartments:
        return Icons.home;
      case UnifiedProductType.other:
        return Icons.inventory;
    }
  }
}

// 🏷️ PRODUCT TYPE BADGE - Modern badge design
class _ProductTypeBadge extends StatelessWidget {
  final UnifiedProductType productType;
  final bool isCompact;

  const _ProductTypeBadge({
    required this.productType,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceContainer.withOpacity(0.8),
            AppTheme.surfaceCard.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
        border: Border.all(
          color: AppTheme.borderPrimary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        productType.displayName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: isCompact ? 10 : 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// 🚥 STATUS INDICATOR - Modern status with glow
class _StatusIndicator extends StatelessWidget {
  final dynamic status;
  final bool isCompact;

  const _StatusIndicator({
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(status.displayName);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.2),
            statusColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
        border: Border.all(
          color: statusColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 6 : 8,
            height: isCompact ? 6 : 8,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          SizedBox(width: isCompact ? 6 : 8),
          Text(
            status.displayName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: isCompact ? 10 : 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// 📊 METRICS GRID - Card-based metrics layout
class _MetricsGrid extends StatelessWidget {
  final ProductModalData? modalData;
  final List<InvestorSummary> investors;
  final UnifiedProduct product;
  final bool isEditModeEnabled;
  final VoidCallback onCapitalEdit;

  const _MetricsGrid({
    required this.modalData,
    required this.investors,
    required this.product,
    required this.isEditModeEnabled,
    required this.onCapitalEdit,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    final metrics = _getMetrics();

    if (isDesktop) {
      return _DesktopMetricsRow(
        metrics: metrics,
        isEditModeEnabled: isEditModeEnabled,
        onCapitalEdit: onCapitalEdit,
      );
    } else if (isTablet) {
      return _TabletMetricsGrid(
        metrics: metrics,
        isEditModeEnabled: isEditModeEnabled,
        onCapitalEdit: onCapitalEdit,
      );
    } else {
      return _MobileMetricsGrid(
        metrics: metrics,
        isEditModeEnabled: isEditModeEnabled,
        onCapitalEdit: onCapitalEdit,
      );
    }
  }

  List<_MetricData> _getMetrics() {
    final double totalInvestmentAmount;
    final double totalRemainingCapital;
    final double totalCapitalSecured;
    final double totalCapitalForRestructuring;

    if (modalData != null) {
      totalInvestmentAmount = modalData!.statistics.totalInvestmentAmount;
      totalRemainingCapital = modalData!.statistics.totalRemainingCapital;
      totalCapitalSecured = modalData!.statistics.totalCapitalSecuredByRealEstate;
      totalCapitalForRestructuring = _computeTotalCapitalForRestructuring();
    } else {
      totalInvestmentAmount = _computeTotalInvestmentAmount();
      totalRemainingCapital = _computeTotalRemainingCapital();
      totalCapitalSecured = _computeTotalCapitalSecured();
      totalCapitalForRestructuring = _computeTotalCapitalForRestructuring();
    }

    return [
      _MetricData(
        title: 'Suma inwestycji',
        value: CurrencyFormatter.formatCurrency(totalInvestmentAmount),
        icon: Icons.trending_up,
        color: AppTheme.infoPrimary,
        isEditable: false,
      ),
      _MetricData(
        title: 'Kapitał pozostały',
        value: CurrencyFormatter.formatCurrency(totalRemainingCapital),
        icon: Icons.account_balance_wallet,
        color: AppTheme.successPrimary,
        isEditable: true,
      ),
      _MetricData(
        title: 'Kapitał zabezpieczony',
        value: CurrencyFormatter.formatCurrency(totalCapitalSecured),
        icon: Icons.security,
        color: AppTheme.warningPrimary,
        isEditable: false,
      ),
      _MetricData(
        title: 'Do restrukturyzacji',
        value: CurrencyFormatter.formatCurrency(totalCapitalForRestructuring),
        icon: Icons.build,
        color: AppTheme.errorPrimary,
        isEditable: false,
      ),
    ];
  }

  double _computeTotalInvestmentAmount() {
    double sum = 0.0;
    final processedIds = <String>{};

    for (final investor in investors) {
      for (final investment in investor.investments) {
        if (investment.productName != product.name) continue;
        if (processedIds.contains(investment.id)) continue;
        processedIds.add(investment.id);
        sum += investment.investmentAmount;
      }
    }
    return sum;
  }

  double _computeTotalRemainingCapital() {
    double sum = 0.0;
    final processedIds = <String>{};

    for (final investor in investors) {
      for (final investment in investor.investments) {
        if (investment.productName != product.name) continue;
        if (processedIds.contains(investment.id)) continue;
        processedIds.add(investment.id);
        sum += investment.remainingCapital;
      }
    }
    return sum;
  }

  double _computeTotalCapitalSecured() {
    final totalRemaining = _computeTotalRemainingCapital();
    final totalForRestructuring = _computeTotalCapitalForRestructuring();
    return (totalRemaining - totalForRestructuring).clamp(0.0, double.infinity);
  }

  double _computeTotalCapitalForRestructuring() {
    double sum = 0.0;
    final processedIds = <String>{};

    for (final investor in investors) {
      for (final investment in investor.investments) {
        if (investment.productName != product.name) continue;
        if (processedIds.contains(investment.id)) continue;
        processedIds.add(investment.id);
        sum += investment.capitalForRestructuring;
      }
    }
    return sum;
  }
}

// 📊 METRIC DATA MODEL
class _MetricData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isEditable;

  const _MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isEditable,
  });
}

// 🖥️ DESKTOP METRICS ROW
class _DesktopMetricsRow extends StatelessWidget {
  final List<_MetricData> metrics;
  final bool isEditModeEnabled;
  final VoidCallback onCapitalEdit;

  const _DesktopMetricsRow({
    required this.metrics,
    required this.isEditModeEnabled,
    required this.onCapitalEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: metrics.asMap().entries.map((entry) {
        final index = entry.key;
        final metric = entry.value;
        
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index > 0 ? 8 : 0,
              right: index < metrics.length - 1 ? 8 : 0,
            ),
            child: _MetricCard(
              metric: metric,
              isEditModeEnabled: isEditModeEnabled,
              onTap: metric.isEditable ? onCapitalEdit : null,
              animationDelay: index * 100,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// 📱 TABLET METRICS GRID
class _TabletMetricsGrid extends StatelessWidget {
  final List<_MetricData> metrics;
  final bool isEditModeEnabled;
  final VoidCallback onCapitalEdit;

  const _TabletMetricsGrid({
    required this.metrics,
    required this.isEditModeEnabled,
    required this.onCapitalEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                metric: metrics[0],
                isEditModeEnabled: isEditModeEnabled,
                onTap: metrics[0].isEditable ? onCapitalEdit : null,
                animationDelay: 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                metric: metrics[1],
                isEditModeEnabled: isEditModeEnabled,
                onTap: metrics[1].isEditable ? onCapitalEdit : null,
                animationDelay: 100,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                metric: metrics[2],
                isEditModeEnabled: isEditModeEnabled,
                onTap: metrics[2].isEditable ? onCapitalEdit : null,
                animationDelay: 200,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                metric: metrics[3],
                isEditModeEnabled: isEditModeEnabled,
                onTap: metrics[3].isEditable ? onCapitalEdit : null,
                animationDelay: 300,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// 📱 MOBILE METRICS GRID
class _MobileMetricsGrid extends StatelessWidget {
  final List<_MetricData> metrics;
  final bool isEditModeEnabled;
  final VoidCallback onCapitalEdit;

  const _MobileMetricsGrid({
    required this.metrics,
    required this.isEditModeEnabled,
    required this.onCapitalEdit,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 400;

    if (isVerySmall) {
      return Column(
        children: metrics.asMap().entries.map((entry) {
          final index = entry.key;
          final metric = entry.value;
          
          return Padding(
            padding: EdgeInsets.only(bottom: index < metrics.length - 1 ? 8 : 0),
            child: _MetricCard(
              metric: metric,
              isEditModeEnabled: isEditModeEnabled,
              onTap: metric.isEditable ? onCapitalEdit : null,
              animationDelay: index * 100,
              isCompact: true,
            ),
          );
        }).toList(),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                metric: metrics[0],
                isEditModeEnabled: isEditModeEnabled,
                onTap: metrics[0].isEditable ? onCapitalEdit : null,
                animationDelay: 0,
                isCompact: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                metric: metrics[1],
                isEditModeEnabled: isEditModeEnabled,
                onTap: metrics[1].isEditable ? onCapitalEdit : null,
                animationDelay: 100,
                isCompact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                metric: metrics[2],
                isEditModeEnabled: isEditModeEnabled,
                onTap: metrics[2].isEditable ? onCapitalEdit : null,
                animationDelay: 200,
                isCompact: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                metric: metrics[3],
                isEditModeEnabled: isEditModeEnabled,
                onTap: metrics[3].isEditable ? onCapitalEdit : null,
                animationDelay: 300,
                isCompact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// 💳 METRIC CARD - Modern card with glassmorphism
class _MetricCard extends StatefulWidget {
  final _MetricData metric;
  final bool isEditModeEnabled;
  final VoidCallback? onTap;
  final int animationDelay;
  final bool isCompact;

  const _MetricCard({
    required this.metric,
    required this.isEditModeEnabled,
    this.onTap,
    required this.animationDelay,
    this.isCompact = false,
  });

  @override
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.onTap != null && 
                         widget.metric.isEditable && 
                         widget.isEditModeEnabled;
    
    return MouseRegion(
      onEnter: (_) => _onHoverChange(true),
      onExit: (_) => _onHoverChange(false),
      child: AnimatedBuilder(
        animation: _hoverAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _hoverAnimation.value,
            child: GestureDetector(
              onTap: isInteractive ? widget.onTap : null,
              child: TweenAnimationBuilder(
                duration: Duration(milliseconds: 600 + widget.animationDelay),
                tween: Tween<double>(begin: 0, end: 1),
                curve: Curves.easeOutCubic,
                builder: (context, animValue, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - animValue)),
                    child: Opacity(
                      opacity: animValue,
                      child: Container(
                        height: widget.isCompact ? 80 : 100,
                        padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.surfaceContainer.withOpacity(0.8),
                              AppTheme.surfaceCard.withOpacity(0.6),
                              if (isInteractive) 
                                widget.metric.color.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isInteractive && widget.isEditModeEnabled
                                ? widget.metric.color.withOpacity(0.5)
                                : AppTheme.borderPrimary.withOpacity(0.3),
                            width: isInteractive && widget.isEditModeEnabled ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isHovered && isInteractive
                                  ? widget.metric.color
                                  : AppTheme.shadowColor).withOpacity(0.15),
                              blurRadius: _isHovered && isInteractive ? 16 : 8,
                              spreadRadius: _isHovered && isInteractive ? 1 : 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.metric.icon,
                                  color: widget.metric.color,
                                  size: widget.isCompact ? 16 : 18,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    widget.metric.title,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: widget.isCompact ? 10 : 11,
                                      letterSpacing: 0.3,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: widget.isCompact ? 2 : 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: widget.isCompact ? 6 : 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.metric.value,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: widget.isCompact ? 14 : 16,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            if (isInteractive && widget.isEditModeEnabled) ...[
                              const SizedBox(height: 2),
                              Icon(
                                Icons.edit,
                                color: widget.metric.color.withOpacity(0.7),
                                size: 12,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _onHoverChange(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }
}

// ⏳ LOADING METRICS GRID
class _LoadingMetricsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    if (isDesktop) {
      return Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index > 0 ? 8 : 0,
                right: index < 3 ? 8 : 0,
              ),
              child: _LoadingMetricCard(delay: index * 100),
            ),
          );
        }),
      );
    } else if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _LoadingMetricCard(delay: 0)),
              const SizedBox(width: 12),
              Expanded(child: _LoadingMetricCard(delay: 100)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _LoadingMetricCard(delay: 200)),
              const SizedBox(width: 12),
              Expanded(child: _LoadingMetricCard(delay: 300)),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _LoadingMetricCard(delay: 0, isCompact: true)),
              const SizedBox(width: 8),
              Expanded(child: _LoadingMetricCard(delay: 100, isCompact: true)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _LoadingMetricCard(delay: 200, isCompact: true)),
              const SizedBox(width: 8),
              Expanded(child: _LoadingMetricCard(delay: 300, isCompact: true)),
            ],
          ),
        ],
      );
    }
  }
}

// ⏳ LOADING METRIC CARD
class _LoadingMetricCard extends StatefulWidget {
  final int delay;
  final bool isCompact;

  const _LoadingMetricCard({
    required this.delay,
    this.isCompact = false,
  });

  @override
  State<_LoadingMetricCard> createState() => _LoadingMetricCardState();
}

class _LoadingMetricCardState extends State<_LoadingMetricCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _shimmerController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.isCompact ? 80 : 100,
      padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceContainer.withOpacity(0.5),
            AppTheme.surfaceCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ShimmerBox(
                    width: widget.isCompact ? 16 : 18,
                    height: widget.isCompact ? 16 : 18,
                    borderRadius: 9,
                    shimmerAnimation: _shimmerAnimation,
                  ),
                  const SizedBox(width: 6),
                  _ShimmerBox(
                    width: widget.isCompact ? 60 : 80,
                    height: widget.isCompact ? 10 : 12,
                    borderRadius: 6,
                    shimmerAnimation: _shimmerAnimation,
                  ),
                ],
              ),
              SizedBox(height: widget.isCompact ? 8 : 12),
              _ShimmerBox(
                width: widget.isCompact ? 80 : 100,
                height: widget.isCompact ? 16 : 20,
                borderRadius: 8,
                shimmerAnimation: _shimmerAnimation,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ✨ SHIMMER BOX
class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Animation<double> shimmerAnimation;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.shimmerAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + shimmerAnimation.value, 0.0),
          end: Alignment(1.0 + shimmerAnimation.value, 0.0),
          colors: [
            AppTheme.surfaceContainer.withOpacity(0.3),
            AppTheme.textSecondary.withOpacity(0.2),
            AppTheme.surfaceContainer.withOpacity(0.3),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}