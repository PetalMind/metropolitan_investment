import 'package:flutter/material.dart';
import '../../models/unified_product.dart';
import '../../theme/app_theme.dart';

/// Prosti wykres słupkowy dystrybucji produktów
class ProductDistributionChart extends StatelessWidget {
  final Map<UnifiedProductType, int> distribution;
  final bool isCompact;

  const ProductDistributionChart({
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