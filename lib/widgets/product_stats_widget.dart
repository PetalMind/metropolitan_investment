import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/unified_product.dart';
import '../services/unified_product_service.dart';

/// Widget do wyświetlania statystyk produktów zgodny z motywem aplikacji
class ProductStatsWidget extends StatefulWidget {
  final ProductStatistics statistics;
  final AnimationController? animationController;

  const ProductStatsWidget({
    super.key,
    required this.statistics,
    this.animationController,
  });

  @override
  State<ProductStatsWidget> createState() => _ProductStatsWidgetState();
}

class _ProductStatsWidgetState extends State<ProductStatsWidget>
    with TickerProviderStateMixin {
  late AnimationController _localController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _localController =
        widget.animationController ??
        AnimationController(
          duration: const Duration(milliseconds: 1200),
          vsync: this,
        );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _localController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _localController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    if (widget.animationController == null) {
      _localController.forward();
    }
  }

  @override
  void dispose() {
    if (widget.animationController == null) {
      _localController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnimation, _fadeAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: AppTheme.premiumCardDecoration,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nagłówek sekcji
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.analytics,
                          color: AppTheme.secondaryGold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Statystyki Produktów',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      _buildTrendIndicator(),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Główne metryki
                  _buildMainMetrics(),

                  const SizedBox(height: 20),

                  // Dystrybucja typów produktów
                  _buildTypeDistribution(),

                  const SizedBox(height: 16),

                  // Rozkład statusów
                  _buildStatusDistribution(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendIndicator() {
    final profitLoss = widget.statistics.profitLoss;
    final isProfit = profitLoss >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isProfit ? AppTheme.gainBackground : AppTheme.lossBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isProfit
              ? AppTheme.gainPrimary.withOpacity(0.3)
              : AppTheme.lossPrimary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isProfit ? Icons.trending_up : Icons.trending_down,
            color: isProfit ? AppTheme.gainPrimary : AppTheme.lossPrimary,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.statistics.profitLossPercentage.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isProfit ? AppTheme.gainPrimary : AppTheme.lossPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Łącznie',
            value: widget.statistics.totalProducts.toString(),
            subtitle: 'produktów',
            icon: Icons.inventory_2,
            color: AppTheme.infoPrimary,
            delay: 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Aktywne',
            value: widget.statistics.activeProducts.toString(),
            subtitle:
                '${widget.statistics.activePercentage.toStringAsFixed(0)}%',
            icon: Icons.check_circle,
            color: AppTheme.successPrimary,
            delay: 0.1,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Wartość',
            value: _formatCurrency(widget.statistics.totalValue),
            subtitle: 'PLN',
            icon: Icons.account_balance_wallet,
            color: AppTheme.secondaryGold,
            delay: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double delay,
  }) {
    return AnimatedBuilder(
      animation: _localController,
      builder: (context, child) {
        final animationValue = Curves.easeOutBack.transform(
          ((_localController.value - delay).clamp(0.0, 1.0) / (1.0 - delay))
              .clamp(0.0, 1.0),
        );

        return Transform.scale(
          scale: animationValue,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeDistribution() {
    if (widget.statistics.typeDistribution.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dystrybucja typów produktów',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.statistics.typeDistribution.entries.map((entry) {
          final percentage =
              (entry.value / widget.statistics.totalProducts) * 100;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildProgressBar(
              label: entry.key.displayName,
              value: entry.value,
              percentage: percentage,
              color: AppTheme.getProductTypeColor(entry.key.collectionName),
              delay:
                  widget.statistics.typeDistribution.keys.toList().indexOf(
                    entry.key,
                  ) *
                  0.1,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatusDistribution() {
    if (widget.statistics.statusDistribution.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rozkład statusów',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: widget.statistics.statusDistribution.entries.map((entry) {
            final color = _getStatusColor(entry.key);

            return Expanded(
              flex: entry.value,
              child: Container(
                height: 8,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: widget.statistics.statusDistribution.entries.map((entry) {
            final percentage =
                (entry.value / widget.statistics.totalProducts) * 100;
            final color = _getStatusColor(entry.key);

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${entry.key.displayName} (${percentage.toStringAsFixed(0)}%)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProgressBar({
    required String label,
    required int value,
    required double percentage,
    required Color color,
    required double delay,
  }) {
    return AnimatedBuilder(
      animation: _localController,
      builder: (context, child) {
        final animationValue = Curves.easeOutCubic.transform(
          ((_localController.value - delay).clamp(0.0, 1.0) / (1.0 - delay))
              .clamp(0.0, 1.0),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '$value (${percentage.toStringAsFixed(0)}%)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.surfaceInteractive.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (percentage / 100) * animationValue,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.active:
        return AppTheme.successPrimary;
      case ProductStatus.inactive:
        return AppTheme.textTertiary;
      case ProductStatus.pending:
        return AppTheme.warningPrimary;
      case ProductStatus.suspended:
        return AppTheme.errorPrimary;
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}
