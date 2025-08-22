import 'package:flutter/material.dart';
import '../../models_and_services.dart';

/// Zaawansowana karta produktu z obsługą selekcji i szczegółowych informacji
class ProductCardAdvanced extends StatelessWidget {
  final DeduplicatedProduct product;
  final int index;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final Function(bool?) onSelectionChanged;

  const ProductCardAdvanced({
    super.key,
    required this.product,
    required this.index,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: isSelected
          ? AppTheme.premiumCardDecoration.copyWith(
              border: Border.all(color: AppTheme.secondaryGold, width: 2),
            )
          : AppTheme.premiumCardDecoration,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildProductInfo(context),
              const SizedBox(height: 12),
              _buildStatistics(context),
              const SizedBox(height: 8),
              _buildMetadata(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Checkbox w trybie selekcji
        if (isSelectionMode) ...[
          Checkbox(
            value: isSelected,
            onChanged: onSelectionChanged,
            activeColor: AppTheme.secondaryGold,
          ),
          const SizedBox(width: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: product.productType.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: product.productType.color.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            product.productType.displayName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: product.productType.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: product.status == ProductStatus.active
                ? AppTheme.successColor.withValues(alpha: 0.1)
                : AppTheme.errorColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: product.status == ProductStatus.active
                  ? AppTheme.successColor
                  : AppTheme.errorColor,
              width: 1,
            ),
          ),
          child: Text(
            product.status.displayName,
            style: TextStyle(
              color: product.status == ProductStatus.active
                  ? AppTheme.successColor
                  : AppTheme.errorColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          product.companyName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (product.interestRate != null && product.interestRate! > 0) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.trending_up, size: 16, color: AppTheme.primaryAccent),
              const SizedBox(width: 4),
              Text(
                '${product.interestRate!.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatistics(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatColumn(
            'Wartość całkowita',
            AppTheme.formatCurrency(product.totalValue),
            Icons.account_balance_wallet,
            context,
          ),
        ),
        Expanded(
          child: _buildStatColumn(
            'Kapitał pozostały',
            AppTheme.formatCurrency(product.totalRemainingCapital),
            Icons.savings,
            context,
          ),
        ),
        Expanded(
          child: _buildStatColumn(
            'Inwestorów',
            '${product.uniqueInvestors}',
            Icons.people,
            context,
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(
    String label,
    String value,
    IconData icon,
    BuildContext context,
  ) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMetadata(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.business_center,
          size: 12,
          color: AppTheme.textSecondary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Text(
          '${product.totalInvestments} inwestycji',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.textSecondary.withValues(alpha: 0.7),
          ),
        ),
        const Spacer(),
        if (product.averageInvestment > 0) ...[
          Icon(
            Icons.bar_chart,
            size: 12,
            color: AppTheme.textSecondary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            'Śr. ${AppTheme.formatShortCurrency(product.averageInvestment)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}
