import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../models/unified_product.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';

/// Widok listy produktów
class ProductsListView extends StatelessWidget {
  final List<UnifiedProduct> products;
  final Function(UnifiedProduct) onProductTap;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final bool hasMoreItems;

  const ProductsListView({
    super.key,
    required this.products,
    required this.onProductTap,
    required this.scrollController,
    this.isLoadingMore = false,
    this.hasMoreItems = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    
    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.all(isMobile ? 8 : 16),
      itemCount: products.length + (isLoadingMore || hasMoreItems ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= products.length) {
          return _buildLoadingIndicator();
        }
        
        final product = products[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ProductListTile(
            product: product,
            onTap: () => onProductTap(product),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.secondaryGold,
          ),
        ),
      );
    } else if (hasMoreItems) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Przewiń w dół aby załadować więcej',
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 12,
            ),
          ),
        ),
      );
    } else {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppTheme.successColor,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Wszystkie produkty zostały załadowane',
                style: TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

/// Pojedynczy element listy produktów
class ProductListTile extends StatelessWidget {
  final UnifiedProduct product;
  final VoidCallback onTap;

  const ProductListTile({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final productColor = AppTheme.getProductTypeColor(product.productType.name);
    
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: productColor.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: isMobile 
              ? _buildMobileLayout(context, productColor)
              : _buildDesktopLayout(context, productColor),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, Color productColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pierwsza linia - typ produktu i status
        Row(
          children: [
            _buildProductTypeChip(context, productColor),
            const Spacer(),
            _buildStatusIndicator(),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Nazwa produktu
        Text(
          product.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        if (product.companyName != null && product.companyName!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            product.companyName!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        
        const SizedBox(height: 12),
        
        // Kwoty
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (product.investmentAmount > 0) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inwestycja',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatCurrency(product.investmentAmount),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Wartość całkowita',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatCurrency(product.totalValue),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.secondaryGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Footer z datą
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 14,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              'Utworzono ${_formatDate(product.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiary,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: AppTheme.textTertiary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Color productColor) {
    return Row(
      children: [
        // Ikona produktu
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: productColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: productColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(
            _getProductIcon(),
            color: productColor,
            size: 24,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Informacje główne
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildProductTypeChip(context, productColor),
                  const SizedBox(width: 8),
                  _buildStatusIndicator(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (product.companyName != null && product.companyName!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  product.companyName!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        
        // Dodatkowe informacje
        Expanded(
          flex: 2,
          child: _buildAdditionalInfo(context),
        ),
        
        // Kwoty
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (product.investmentAmount > 0) ...[
                Text(
                  'Inwestycja',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatCurrency(product.investmentAmount),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                'Wartość całkowita',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
              Text(
                CurrencyFormatter.formatCurrency(product.totalValue),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.secondaryGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Strzałka
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppTheme.textTertiary,
        ),
      ],
    );
  }

  Widget _buildProductTypeChip(BuildContext context, Color productColor) {
    return Container(
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
    );
  }

  Widget _buildStatusIndicator() {
    final statusColor = product.isActive 
        ? AppTheme.successColor 
        : AppTheme.errorColor;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          product.status.displayName,
          style: const TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo(BuildContext context) {
    final info = <String>[];
    
    switch (product.productType) {
      case UnifiedProductType.bonds:
        if (product.interestRate != null) {
          info.add('${product.interestRate!.toStringAsFixed(2)}% oprocentowanie');
        }
        if (product.remainingCapital != null && product.remainingCapital! > 0) {
          info.add('Pozostały kapitał: ${CurrencyFormatter.formatCurrency(product.remainingCapital!)}');
        }
        break;
        
      case UnifiedProductType.shares:
        if (product.sharesCount != null && product.sharesCount! > 0) {
          info.add('${product.sharesCount} udziałów');
        }
        if (product.pricePerShare != null && product.pricePerShare! > 0) {
          info.add('${CurrencyFormatter.formatCurrency(product.pricePerShare!)} za udział');
        }
        break;
        
      default:
        break;
    }
    
    info.add('Utworzono ${_formatDate(product.createdAt)}');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: info.take(3).map((text) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textTertiary,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

/// Wariant z rozszerzonymi informacjami
class ExtendedProductListTile extends StatelessWidget {
  final UnifiedProduct product;
  final VoidCallback onTap;

  const ExtendedProductListTile({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final productColor = AppTheme.getProductTypeColor(product.productType.name);
    
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      child: ExpansionTile(
        leading: Container(
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
        title: Text(
          product.name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${product.productType.displayName} • ${CurrencyFormatter.formatCurrency(product.totalValue)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.open_in_new),
          color: AppTheme.secondaryGold,
          tooltip: 'Pokaż szczegóły',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...product.detailsList.map((detail) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          detail.key,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          detail.value,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
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