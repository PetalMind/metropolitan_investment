import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../models/unified_product.dart';
import '../../services/unified_product_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';

/// Karta ze statystykami produktów
class ProductsStatisticsCard extends StatelessWidget {
  final ProductStatistics statistics;

  const ProductsStatisticsCard({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);

    if (isMobile) {
      return _buildMobileLayout(context);
    } else {
      return _buildDesktopLayout(context, isTablet);
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          _buildStatCard(
            context,
            'Produkty',
            '${statistics.totalProducts}',
            'Łącznie produktów',
            Icons.inventory_2,
            AppTheme.primaryAccent,
            isCompact: true,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Aktywne',
                  '${statistics.activeProducts}',
                  '${statistics.activePercentage.toStringAsFixed(1)}%',
                  Icons.check_circle,
                  AppTheme.successColor,
                  isCompact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Wartość',
                  CurrencyFormatter.formatCurrency(statistics.totalValue),
                  'Łączna wartość',
                  Icons.account_balance_wallet,
                  AppTheme.secondaryGold,
                  isCompact: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildStatCard(
              context,
              'Łącznie Produktów',
              '${statistics.totalProducts}',
              'W systemie',
              Icons.inventory_2,
              AppTheme.primaryAccent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildStatCard(
              context,
              'Aktywne Produkty',
              '${statistics.activeProducts}',
              '${statistics.activePercentage.toStringAsFixed(1)}% wszystkich',
              Icons.check_circle,
              AppTheme.successColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: _buildStatCard(
              context,
              'Łączna Wartość',
              CurrencyFormatter.formatCurrency(statistics.totalValue),
              statistics.profitLoss >= 0 
                  ? '+${CurrencyFormatter.formatCurrency(statistics.profitLoss)}'
                  : CurrencyFormatter.formatCurrency(statistics.profitLoss),
              Icons.account_balance_wallet,
              AppTheme.secondaryGold,
              subtitleColor: statistics.profitLoss >= 0 
                  ? AppTheme.successColor 
                  : AppTheme.errorColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildStatCard(
              context,
              'Najpopularniejszy',
              statistics.mostValuableType.displayName,
              'Typ produktu',
              Icons.trending_up,
              AppTheme.getProductTypeColor(statistics.mostValuableType.name),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color, {
    bool isCompact = false,
    Color? subtitleColor,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 20),
      decoration: AppTheme.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 6 : 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isCompact ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: isCompact ? 20 : 24,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: subtitleColor ?? AppTheme.textTertiary,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Widget z wykresem rozkładu typów produktów
class ProductTypeDistributionChart extends StatelessWidget {
  final Map<UnifiedProductType, int> distribution;
  final bool isCompact;

  const ProductTypeDistributionChart({
    super.key,
    required this.distribution,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return Container(
        height: isCompact ? 120 : 180,
        decoration: AppTheme.premiumCardDecoration,
        child: const Center(
          child: Text(
            'Brak danych do wyświetlenia',
            style: TextStyle(color: AppTheme.textTertiary),
          ),
        ),
      );
    }

    return Container(
      height: isCompact ? 120 : 180,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rozkład typów produktów',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildDistributionBars(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionBars(BuildContext context) {
    final total = distribution.values.fold(0, (sum, value) => sum + value);
    if (total == 0) return const SizedBox.shrink();

    final sortedEntries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedEntries.take(4).map((entry) {
        final percentage = (entry.value / total) * 100;
        final color = AppTheme.getProductTypeColor(entry.key.name);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  entry.key.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: isCompact ? 6 : 8,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceInteractive,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text(
                  '${entry.value}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Rozszerzona karta statystyk z wykresami
class ExtendedProductsStatisticsCard extends StatelessWidget {
  final ProductStatistics statistics;

  const ExtendedProductsStatisticsCard({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);

    return Column(
      children: [
        ProductsStatisticsCard(statistics: statistics),
        if (isTablet) ...[
          const SizedBox(height: 16),
          ProductTypeDistributionChart(
            distribution: statistics.typeDistribution,
          ),
        ],
      ],
    );
  }
}