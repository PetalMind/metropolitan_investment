import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/currency_formatter.dart';

/// 📊 ANALYTICS CARD COMPONENT
/// Reusable card for displaying analytics metrics
class AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? change;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isLoading;

  const AnalyticsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.change,
    this.subtitle,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.cardDecoration.copyWith(
            border: Border.all(
              color: color.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return _buildLoadingContent();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        _buildValue(context),
        if (change != null || subtitle != null) ...[
          const SizedBox(height: 8),
          _buildFooter(context),
        ],
      ],
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color.withValues(alpha: 0.3), size: 24),
            const SizedBox(width: 8),
            Container(
              height: 16,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 32,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildValue(BuildContext context) {
    return Text(
      value,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        if (change != null) ...[
          _buildChangeIndicator(),
          const SizedBox(width: 8),
        ],
        if (subtitle != null)
          Expanded(
            child: Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildChangeIndicator() {
    if (change == null) return const SizedBox();

    final isPositive = change!.startsWith('+') || 
                      (!change!.startsWith('-') && !change!.startsWith('0'));
    final changeColor = isPositive ? AppTheme.successColor : AppTheme.errorColor;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: changeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: changeColor,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            change!,
            style: TextStyle(
              color: changeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 💰 CURRENCY ANALYTICS CARD
/// Specialized card for currency values
class CurrencyAnalyticsCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final double? changeValue;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isLoading;

  const CurrencyAnalyticsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.changeValue,
    this.subtitle,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnalyticsCard(
      title: title,
      value: CurrencyFormatter.formatCurrencyShort(value),
      icon: icon,
      color: color,
      change: changeValue != null ? _formatChange(changeValue!) : null,
      subtitle: subtitle,
      onTap: onTap,
      isLoading: isLoading,
    );
  }

  String _formatChange(double change) {
    if (change == 0) return '0%';
    final prefix = change > 0 ? '+' : '';
    return '$prefix${change.toStringAsFixed(1)}%';
  }
}

/// 📈 PERCENTAGE ANALYTICS CARD
/// Specialized card for percentage values
class PercentageAnalyticsCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isLoading;

  const PercentageAnalyticsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnalyticsCard(
      title: title,
      value: '${value.toStringAsFixed(1)}%',
      icon: icon,
      color: color,
      subtitle: subtitle,
      onTap: onTap,
      isLoading: isLoading,
    );
  }
}

/// 🔢 COUNT ANALYTICS CARD
/// Specialized card for count/number values
class CountAnalyticsCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isLoading;

  const CountAnalyticsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnalyticsCard(
      title: title,
      value: value.toString(),
      icon: icon,
      color: color,
      subtitle: subtitle,
      onTap: onTap,
      isLoading: isLoading,
    );
  }
}