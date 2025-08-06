import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../models/unified_product.dart';
import '../../services/unified_product_service.dart';
import '../../theme/app_theme.dart';
import 'products_statistics_card.dart';
import '../charts/product_distribution_chart.dart';

/// Dashboard z podsumowaniem produktów
class ProductsDashboard extends StatefulWidget {
  final List<UnifiedProduct> products;
  final ProductStatistics? statistics;
  final Function(UnifiedProductType)? onTypeFilterTap;

  const ProductsDashboard({
    super.key,
    required this.products,
    this.statistics,
    this.onTypeFilterTap,
  });

  @override
  State<ProductsDashboard> createState() => _ProductsDashboardState();
}

class _ProductsDashboardState extends State<ProductsDashboard> {
  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nagłówek dashboard
          _buildDashboardHeader(context),
          
          const SizedBox(height: 24),
          
          // Statystyki główne
          if (widget.statistics != null)
            ProductsStatisticsCard(statistics: widget.statistics!),
          
          const SizedBox(height: 24),
          
          // Layout responsywny
          if (isMobile)
            _buildMobileLayout(context)
          else
            _buildDesktopLayout(context),
          
          const SizedBox(height: 24),
          
          // Ostatnie produkty
          _buildRecentProductsSection(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.secondaryGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.secondaryGold.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.dashboard_outlined,
            color: AppTheme.secondaryGold,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard Produktów',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Przegląd wszystkich produktów inwestycyjnych',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildQuickStatsCards(context, true),
        const SizedBox(height: 16),
        _buildProductTypesOverview(context, true),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildQuickStatsCards(context, false),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: _buildProductTypesOverview(context, false),
        ),
      ],
    );
  }

  Widget _buildQuickStatsCards(BuildContext context, bool isMobile) {
    final stats = widget.statistics;
    if (stats == null) return const SizedBox.shrink();

    final cards = [
      _QuickStatCard(
        title: 'Najwyższe ROI',
        value: '${stats.profitLossPercentage.toStringAsFixed(1)}%',
        subtitle: 'Zwrot z inwestycji',
        icon: Icons.trending_up,
        color: stats.profitLoss >= 0 ? AppTheme.successColor : AppTheme.errorColor,
      ),
      _QuickStatCard(
        title: 'Średnia wartość',
        value: '${(stats.averageValue / 1000).toStringAsFixed(0)}k',
        subtitle: 'PLN na produkt',
        icon: Icons.account_balance_wallet,
        color: AppTheme.primaryAccent,
      ),
      _QuickStatCard(
        title: 'Aktywność',
        value: '${stats.activePercentage.toStringAsFixed(0)}%',
        subtitle: 'Produktów aktywnych',
        icon: Icons.check_circle,
        color: AppTheme.successColor,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map((card) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: card,
                ))
            .toList(),
      );
    } else {
      return Column(
        children: cards
            .map((card) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: card,
                ))
            .toList(),
      );
    }
  }

  Widget _buildProductTypesOverview(BuildContext context, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart_outline,
                color: AppTheme.secondaryGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Rozkład typów produktów',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          if (widget.statistics != null)
            ProductTypeDistributionChart(
              distribution: widget.statistics!.typeDistribution,
              isCompact: isMobile,
            ),
          
          const SizedBox(height: 16),
          
          _buildTypeButtons(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildTypeButtons(BuildContext context, bool isMobile) {
    final stats = widget.statistics;
    if (stats == null) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: UnifiedProductType.values.map((type) {
        final count = stats.typeDistribution[type] ?? 0;
        final color = AppTheme.getProductTypeColor(type.name);
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onTypeFilterTap?.call(type),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${type.displayName} ($count)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentProductsSection(BuildContext context, bool isMobile) {
    final recentProducts = widget.products
        .take(isMobile ? 3 : 5)
        .toList();

    if (recentProducts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: AppTheme.secondaryGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Ostatnio dodane produkty',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          ...recentProducts.map((product) => _buildRecentProductTile(context, product)),
        ],
      ),
    );
  }

  Widget _buildRecentProductTile(BuildContext context, UnifiedProduct product) {
    final color = AppTheme.getProductTypeColor(product.productType.name);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getProductIcon(product.productType),
              color: color,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
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
                Text(
                  product.productType.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(product.totalValue),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatDate(product.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getProductIcon(UnifiedProductType type) {
    switch (type) {
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

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M PLN';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k PLN';
    } else {
      return '${value.toStringAsFixed(0)} PLN';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

/// Widget z kartą szybkich statystyk
class _QuickStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _QuickStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.elevatedSurfaceDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}