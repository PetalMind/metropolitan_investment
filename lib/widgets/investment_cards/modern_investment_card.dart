import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../models_and_services.dart';

/// 🏦 MODERN INVESTMENT CARD
/// 
/// Nowoczesna, elegancka karta inwestycji zaprojektowana dla aplikacji finansowych:
/// - Profesjonalny gradient design z subtelną animacją
/// - Czytelne hierarchie informacji z financial metrics
/// - Eleganckie badges dla typów produktów z emoji
/// - Smart hover states i interactive elements
/// - Responsywny design dla różnych rozmiarów ekranu
class ModernInvestmentCard extends StatefulWidget {
  final DeduplicatedProduct product;
  final int index;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onTap;
  final Function(bool)? onSelectionChanged;
  final bool showDuplicateInfo;
  final bool isCompact;

  const ModernInvestmentCard({
    super.key,
    required this.product,
    required this.index,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onTap,
    this.onSelectionChanged,
    this.showDuplicateInfo = true,
    this.isCompact = false,
  });

  @override
  State<ModernInvestmentCard> createState() => _ModernInvestmentCardState();
}

class _ModernInvestmentCardState extends State<ModernInvestmentCard>
    with TickerProviderStateMixin {
  
  late AnimationController _hoverController;
  late AnimationController _selectionController;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _borderColorAnimation;
  
  bool _isHovered = false;

  static const Map<UnifiedProductType, String> _productEmojis = {
    UnifiedProductType.bonds: '📜',
    UnifiedProductType.shares: '📈',
    UnifiedProductType.loans: '💰',
    UnifiedProductType.apartments: '🏠',
    UnifiedProductType.other: '📦',
  };

  static const Map<UnifiedProductType, List<Color>> _productGradients = {
    UnifiedProductType.bonds: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
    UnifiedProductType.shares: [Color(0xFF1565C0), Color(0xFF2196F3)],
    UnifiedProductType.loans: [Color(0xFFE65100), Color(0xFFFF9800)],
    UnifiedProductType.apartments: [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
    UnifiedProductType.other: [Color(0xFF424242), Color(0xFF616161)],
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: 2,
      end: 8,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));

    _borderColorAnimation = ColorTween(
      begin: AppTheme.textSecondary.withValues(alpha: 0.2),
      end: AppTheme.secondaryGold,
    ).animate(CurvedAnimation(
      parent: _selectionController,
      curve: Curves.easeInOut,
    ));

    if (widget.isSelected) {
      _selectionController.forward();
    }
  }

  @override
  void didUpdateWidget(ModernInvestmentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _selectionController.forward();
      } else {
        _selectionController.reverse();
      }
    }
  }

  void _handleHover(bool isHovered) {
    if (_isHovered == isHovered) return;
    
    setState(() {
      _isHovered = isHovered;
    });
    
    if (isHovered) {
      _hoverController.forward();
      HapticFeedback.lightImpact();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _productGradients[widget.product.productType] ?? 
        _productGradients[UnifiedProductType.other]!;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_hoverController, _selectionController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: (_) => _handleHover(true),
            onExit: (_) => _handleHover(false),
            child: Container(
              margin: EdgeInsets.only(
                bottom: widget.isCompact ? 8 : 12,
                left: 4,
                right: 4,
                top: 4,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.backgroundSecondary,
                    AppTheme.backgroundSecondary.withValues(alpha: 0.95),
                    gradientColors[0].withValues(alpha: 0.03),
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _borderColorAnimation.value ?? AppTheme.textSecondary.withValues(alpha: 0.2),
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor.withValues(alpha: 0.15),
                    blurRadius: _elevationAnimation.value * 2,
                    offset: Offset(0, _elevationAnimation.value),
                  ),
                  if (_isHovered || widget.isSelected)
                    BoxShadow(
                      color: gradientColors[0].withValues(alpha: 0.2),
                      blurRadius: _elevationAnimation.value * 3,
                      offset: Offset(0, _elevationAnimation.value * 1.5),
                    ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (widget.isSelectionMode) {
                      widget.onSelectionChanged?.call(!widget.isSelected);
                    } else {
                      widget.onTap?.call();
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.all(widget.isCompact ? 16 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        SizedBox(height: widget.isCompact ? 12 : 16),
                        _buildTitle(),
                        SizedBox(height: widget.isCompact ? 8 : 12),
                        _buildMetrics(),
                        if (widget.showDuplicateInfo && widget.product.hasDuplicates) ...[
                          SizedBox(height: widget.isCompact ? 12 : 16),
                          _buildDuplicateInfo(),
                        ],
                      ],
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

  Widget _buildHeader() {
    final emoji = _productEmojis[widget.product.productType] ?? '📦';
    final gradientColors = _productGradients[widget.product.productType] ?? 
        _productGradients[UnifiedProductType.other]!;

    return Row(
      children: [
        if (widget.isSelectionMode) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Checkbox(
              value: widget.isSelected,
              onChanged: (value) => widget.onSelectionChanged?.call(value ?? false),
              activeColor: AppTheme.secondaryGold,
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        
        // Product type badge with emoji and gradient
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradientColors[0].withValues(alpha: 0.15),
                gradientColors[1].withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: gradientColors[0].withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                widget.product.productType.displayName,
                style: TextStyle(
                  color: gradientColors[0],
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        
        const Spacer(),
        
        // Investment count badge
        if (widget.product.hasDuplicates)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.warningColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.layers,
                  size: 14,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.product.totalInvestments}',
                  style: TextStyle(
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.name,
          style: TextStyle(
            fontSize: widget.isCompact ? 16 : 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.business,
              size: 14,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.product.companyName,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetrics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricItem(
              'Wartość',
              _formatCurrency(widget.product.totalValue),
              Icons.account_balance_wallet_outlined,
              AppTheme.secondaryGold,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.textSecondary.withValues(alpha: 0.1),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: _buildMetricItem(
              'Inwestorzy',
              '${widget.product.actualInvestorCount ?? widget.product.uniqueInvestors}',
              Icons.people_outline,
              AppTheme.infoColor,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.textSecondary.withValues(alpha: 0.1),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: _buildMetricItem(
              'Pozostały',
              _formatCurrency(widget.product.totalRemainingCapital),
              Icons.trending_up_outlined,
              AppTheme.successColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 18,
          color: color,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: widget.isCompact ? 14 : 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDuplicateInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warningColor.withValues(alpha: 0.05),
            AppTheme.warningColor.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.warningColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: AppTheme.warningColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informacje o duplikatach',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warningColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rzeczywista liczba: ${widget.product.actualInvestorCount} • '
                  'Lokalna: ${widget.product.uniqueInvestors} • '
                  'Duplikacja: ${(widget.product.duplicationRatio * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.warningColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M PLN';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k PLN';
    }
    return '${amount.toStringAsFixed(0)} PLN';
  }
}