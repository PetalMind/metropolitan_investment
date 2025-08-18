import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/unified_product.dart';
import '../screens/products_management_screen.dart';
import 'common/investor_count_widget.dart';
import 'common/synchronized_product_values_widget.dart'; // 🚀 NOWY IMPORT

/// Widget do wyświetlania karty produktu zgodny z motywem aplikacji
class ProductCardWidget extends StatefulWidget {
  final UnifiedProduct product;
  final ViewMode viewMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  const ProductCardWidget({
    super.key,
    required this.product,
    required this.viewMode,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  @override
  State<ProductCardWidget> createState() => _ProductCardWidgetState();
}

class _ProductCardWidgetState extends State<ProductCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _pressController;
  late Animation<double> _hoverAnimation;
  late Animation<double> _pressAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );

    _pressAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _pressController.reverse();
    if (widget.onTap != null) {
      HapticFeedback.lightImpact();
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  void _onHoverEnter() {
    setState(() {
      _isHovered = true;
    });
    _hoverController.forward();
  }

  void _onHoverExit() {
    setState(() {
      _isHovered = false;
    });
    _hoverController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.viewMode == ViewMode.list) {
      return _buildListCard();
    } else {
      return _buildGridCard();
    }
  }

  Widget _buildGridCard() {
    return AnimatedBuilder(
      animation: Listenable.merge([_hoverAnimation, _pressAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _hoverAnimation.value * _pressAnimation.value,
          child: MouseRegion(
            onEnter: (_) => _onHoverEnter(),
            onExit: (_) => _onHoverExit(),
            child: GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              onLongPress: widget.onLongPress,
              child: Container(
                decoration: _getCardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header z ikoną i statusem
                    _buildCardHeader(),

                    // Główna zawartość
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nazwa produktu
                            _buildProductName(),

                            const SizedBox(height: 6),

                            // Typ produktu
                            _buildProductType(),

                            const SizedBox(height: 8),

                            // Wartości finansowe
                            _buildFinancialInfo(),

                            const Spacer(),

                            // Dodatkowe informacje
                            _buildAdditionalInfo(),
                          ],
                        ),
                      ),
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

  Widget _buildListCard() {
    return AnimatedBuilder(
      animation: Listenable.merge([_hoverAnimation, _pressAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _hoverAnimation.value * _pressAnimation.value,
          child: MouseRegion(
            onEnter: (_) => _onHoverEnter(),
            onExit: (_) => _onHoverExit(),
            child: GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              onLongPress: widget.onLongPress,
              child: Container(
                decoration: _getCardDecoration(),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Ikona produktu
                    _buildProductIcon(),

                    const SizedBox(width: 12),

                    // Główne informacje
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildProductName()),
                              _buildStatusBadge(),
                            ],
                          ),
                          const SizedBox(height: 3),
                          _buildProductType(),
                          const SizedBox(height: 6),
                          _buildFinancialInfoHorizontal(),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Strzałka
                    Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _getCardDecoration() {
    return BoxDecoration(
      gradient: _isHovered
          ? LinearGradient(
              colors: [
                AppTheme.surfaceCard.withOpacity(0.9),
                AppTheme.surfaceElevated.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : AppTheme.cardGradient,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: widget.isSelected
            ? AppTheme.secondaryGold
            : _isHovered
            ? AppTheme.borderFocus
            : AppTheme.borderPrimary,
        width: widget.isSelected ? 2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: AppTheme.shadowColor,
          blurRadius: _isHovered ? 16 : 8,
          spreadRadius: _isHovered ? 2 : 0,
          offset: Offset(0, _isHovered ? 8 : 4),
        ),
        if (widget.isSelected)
          BoxShadow(
            color: AppTheme.secondaryGold.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
      ],
    );
  }

  Widget _buildCardHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getProductTypeBackground(
          widget.product.productType.collectionName,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [_buildProductIcon(), const Spacer(), _buildStatusBadge()],
      ),
    );
  }

  Widget _buildProductIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.getProductTypeColor(
          widget.product.productType.collectionName,
        ).withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.getProductTypeColor(
            widget.product.productType.collectionName,
          ).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(
        _getProductIcon(),
        color: AppTheme.getProductTypeColor(
          widget.product.productType.collectionName,
        ),
        size: 20,
      ),
    );
  }

  Widget _buildStatusBadge() {
    final color = AppTheme.getStatusColor(widget.product.status.displayName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        widget.product.status.displayName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProductName() {
    return Text(
      widget.product.name,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      maxLines: widget.viewMode == ViewMode.grid ? 2 : 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProductType() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.getProductTypeColor(
          widget.product.productType.collectionName,
        ).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        widget.product.productType.displayName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.getProductTypeColor(
            widget.product.productType.collectionName,
          ),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFinancialInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInvestorCountRow(),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Inwestycja',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
            ),
            SynchronizedProductValuesWidget(
              product: widget.product,
              valueType: 'totalInvestmentAmount',
              textStyle: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              valueColor: AppTheme.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Wartość',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
            ),
            SynchronizedProductValuesWidget(
              product: widget.product,
              valueType: 'totalRemainingCapital',
              textStyle: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              valueColor: AppTheme.secondaryGold,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialInfoHorizontal() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFinancialColumn(
                'Inwestorzy',
                '',
                AppTheme.primaryAccent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inwestycja',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  SynchronizedProductValuesWidget(
                    product: widget.product,
                    valueType: 'totalInvestmentAmount',
                    textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    valueColor: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: InvestorCountWidget(
                product: widget.product,
                textStyle: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                color: AppTheme.primaryAccent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wartość',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  SynchronizedProductValuesWidget(
                    product: widget.product,
                    valueType: 'totalRemainingCapital',
                    textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    valueColor: AppTheme.secondaryGold,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInvestorCountRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Inwestorzy',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
        ),
        InvestorCountWidget(
          product: widget.product,
          textStyle: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          color: AppTheme.primaryAccent,
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    final additionalInfo = <String>[];

    if (widget.product.companyName != null) {
      additionalInfo.add(widget.product.companyName!);
    }

    if (widget.product.interestRate != null) {
      additionalInfo.add('${widget.product.interestRate!.toStringAsFixed(1)}%');
    }

    if (widget.product.sharesCount != null && widget.product.sharesCount! > 0) {
      additionalInfo.add('${widget.product.sharesCount} udziałów');
    }

    if (additionalInfo.isEmpty) {
      return Text(
        'Utworzono: ${_formatDate(widget.product.createdAt)}',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          additionalInfo.first,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (additionalInfo.length > 1)
          Text(
            additionalInfo.skip(1).join(' • '),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  IconData _getProductIcon() {
    switch (widget.product.productType) {
      case UnifiedProductType.bonds:
        return Icons.account_balance;
      case UnifiedProductType.shares:
        return Icons.trending_up;
      case UnifiedProductType.loans:
        return Icons.attach_money;
      case UnifiedProductType.apartments:
        return Icons.apartment;
      case UnifiedProductType.other:
        return Icons.inventory;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
