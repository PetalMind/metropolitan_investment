import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../models/unified_product.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import 'product_card.dart';

/// Widok siatki produktów
class ProductsGridView extends StatelessWidget {
  final List<UnifiedProduct> products;
  final Function(UnifiedProduct) onProductTap;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final bool hasMoreItems;

  const ProductsGridView({
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
    final isTablet = ResponsiveBreakpoints.of(context).between(TABLET, DESKTOP);
    
    int crossAxisCount;
    double childAspectRatio;
    
    if (isMobile) {
      crossAxisCount = 1;
      childAspectRatio = 2.2;
    } else if (isTablet) {
      crossAxisCount = 2;
      childAspectRatio = 1.8;
    } else {
      crossAxisCount = 3;
      childAspectRatio = 1.6;
    }

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(isMobile ? 8 : 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: isMobile ? 8 : 16,
              mainAxisSpacing: isMobile ? 8 : 16,
              childAspectRatio: childAspectRatio,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  onTap: () => onProductTap(product),
                );
              },
              childCount: products.length,
            ),
          ),
        ),
        if (isLoadingMore || hasMoreItems)
          SliverToBoxAdapter(
            child: _buildLoadingIndicator(),
          ),
      ],
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

/// Staggered grid view dla lepszego wyglądu na dużych ekranach
class ProductsStaggeredGridView extends StatelessWidget {
  final List<UnifiedProduct> products;
  final Function(UnifiedProduct) onProductTap;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final bool hasMoreItems;

  const ProductsStaggeredGridView({
    super.key,
    required this.products,
    required this.onProductTap,
    required this.scrollController,
    this.isLoadingMore = false,
    this.hasMoreItems = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 64) / 3; // 3 kolumny z paddingiem

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Grupuj produkty po 3
                final startIndex = index * 3;
                final endIndex = (startIndex + 3).clamp(0, products.length);
                final rowProducts = products.sublist(startIndex, endIndex);

                if (rowProducts.isEmpty) return null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rowProducts.asMap().entries.map((entry) {
                      final product = entry.value;
                      final isLast = entry.key == rowProducts.length - 1;
                      
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: isLast ? 0 : 16),
                          child: ProductCard(
                            product: product,
                            onTap: () => onProductTap(product),
                            aspectRatio: _getCardAspectRatio(product),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
              childCount: (products.length / 3).ceil(),
            ),
          ),
        ),
        if (isLoadingMore || hasMoreItems)
          SliverToBoxAdapter(
            child: ProductsGridView(
              products: [],
              onProductTap: onProductTap,
              scrollController: scrollController,
              isLoadingMore: isLoadingMore,
              hasMoreItems: hasMoreItems,
            )._buildLoadingIndicator(),
          ),
      ],
    );
  }

  double _getCardAspectRatio(UnifiedProduct product) {
    // Zróżnicuj wysokość kart na podstawie typu produktu
    switch (product.productType) {
      case UnifiedProductType.bonds:
        return 1.4; // Wyższe karty dla obligacji (więcej danych)
      case UnifiedProductType.shares:
        return 1.6; // Średnie karty dla udziałów
      case UnifiedProductType.loans:
        return 1.8; // Niższe karty dla pożyczek (mniej danych)
      default:
        return 1.6;
    }
  }
}

/// Alternatywny widok siatki z większymi kartami
class ProductsLargeGridView extends StatelessWidget {
  final List<UnifiedProduct> products;
  final Function(UnifiedProduct) onProductTap;
  final ScrollController scrollController;

  const ProductsLargeGridView({
    super.key,
    required this.products,
    required this.onProductTap,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(isMobile ? 8 : 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isMobile ? 1.8 : 1.4,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                return ProductLargeCard(
                  product: product,
                  onTap: () => onProductTap(product),
                );
              },
              childCount: products.length,
            ),
          ),
        ),
      ],
    );
  }
}

/// Duża karta produktu z więcej szczegółami
class ProductLargeCard extends StatelessWidget {
  final UnifiedProduct product;
  final VoidCallback onTap;

  const ProductLargeCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final productColor = AppTheme.getProductTypeColor(product.productType.name);
    
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: productColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header z typem produktu i statusem
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: productColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: productColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      product.productType.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: productColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildStatusIndicator(context),
                ],
              ),
              const SizedBox(height: 16),
              
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
              
              if (product.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  product.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const Spacer(),
              
              // Kwoty
              _buildAmountSection(context),
              
              const SizedBox(height: 12),
              
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
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final statusColor = product.isActive ? AppTheme.successColor : AppTheme.errorColor;
    
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: statusColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildAmountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.investmentAmount > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kwota inwestycji:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                CurrencyFormatter.formatCurrency(product.investmentAmount),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Wartość całkowita:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
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
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}