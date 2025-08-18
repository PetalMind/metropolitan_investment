import 'package:flutter/material.dart';
import '../../models/unified_product.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../common/investor_count_widget.dart';

/// Karta produktu w widoku siatki
class ProductCard extends StatelessWidget {
  final UnifiedProduct product;
  final VoidCallback onTap;
  final double? aspectRatio;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final productColor = AppTheme.getProductTypeColor(product.productType.name);
    
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: productColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, productColor),
              Expanded(
                child: _buildContent(context),
              ),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color productColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: productColor.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: productColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: productColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              product.productType.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: productColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          const Spacer(),
          _buildStatusDot(),
        ],
      ),
    );
  }

  Widget _buildStatusDot() {
    final statusColor = product.isActive 
        ? AppTheme.successColor 
        : AppTheme.errorColor;
    
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: statusColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nazwa produktu
          Text(
            product.name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // Opis lub dodatkowe informacje
          if (product.companyName != null && product.companyName!.isNotEmpty)
            Text(
              product.companyName!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          
          const Spacer(),
          
          // Kwoty i wartości
          _buildAmountInfo(context),
        ],
      ),
    );
  }

  Widget _buildAmountInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Liczba inwestorów
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Inwestorzy:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiary,
                fontSize: 11,
              ),
            ),
            InvestorCountWidget(
              product: product,
              textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryAccent,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              color: AppTheme.primaryAccent,
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        if (product.investmentAmount > 0) ...[
          _buildAmountRow(
            context,
            'Inwestycja:',
            CurrencyFormatter.formatCurrency(product.investmentAmount),
            AppTheme.textSecondary,
          ),
          const SizedBox(height: 4),
        ],
        
        _buildAmountRow(
          context,
          'Wartość:',
          CurrencyFormatter.formatCurrency(product.totalValue),
          AppTheme.secondaryGold,
          isHighlight: true,
        ),
        
        // Dodatkowe informacje specyficzne dla typu produktu
        const SizedBox(height: 4),
        _buildProductSpecificInfo(context),
      ],
    );
  }

  Widget _buildAmountRow(
    BuildContext context,
    String label,
    String value,
    Color valueColor, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textTertiary,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: valueColor,
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
            fontSize: isHighlight ? 12 : 11,
          ),
        ),
      ],
    );
  }

  Widget _buildProductSpecificInfo(BuildContext context) {
    switch (product.productType) {
      case UnifiedProductType.bonds:
        if (product.interestRate != null) {
          return _buildAmountRow(
            context,
            'Oprocentowanie:',
            '${product.interestRate!.toStringAsFixed(2)}%',
            AppTheme.textSecondary,
          );
        }
        break;
        
      case UnifiedProductType.shares:
        if (product.sharesCount != null && product.sharesCount! > 0) {
          return _buildAmountRow(
            context,
            'Liczba udziałów:',
            '${product.sharesCount}',
            AppTheme.textSecondary,
          );
        }
        break;
        
      default:
        break;
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: 12,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _formatDate(product.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiary,
                fontSize: 10,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 10,
            color: AppTheme.textTertiary,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

/// Kompaktowa wersja karty produktu
class CompactProductCard extends StatelessWidget {
  final UnifiedProduct product;
  final VoidCallback onTap;

  const CompactProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final productColor = AppTheme.getProductTypeColor(product.productType.name);
    
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: productColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Ikona typu produktu
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: productColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getProductIcon(),
                  color: productColor,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Informacje o produkcie
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.productType.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Wartość
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatCurrency(product.totalValue),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.secondaryGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: product.isActive 
                          ? AppTheme.successColor 
                          : AppTheme.errorColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 8),
              
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: AppTheme.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getProductIcon() {
    switch (product.productType) {
      case UnifiedProductType.bonds:
        return Icons.account_balance;
      case UnifiedProductType.shares:
        return Icons.trending_up;
      case UnifiedProductType.loans:
        return Icons.handshake;
      case UnifiedProductType.apartments:
        return Icons.home;
      case UnifiedProductType.other:
        return Icons.category;
    }
  }
}