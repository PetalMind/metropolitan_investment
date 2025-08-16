import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Widget nagłówka produktu z ikoną, nazwą, typem i przyciskiem zamknięcia
class ProductHeader extends StatelessWidget {
  final String productName;
  final String productType;
  final String? companyName;
  final bool isActive;
  final String status;
  final IconData productIcon;
  final Color productColor;
  final VoidCallback onClose;

  const ProductHeader({
    super.key,
    required this.productName,
    required this.productType,
    this.companyName,
    required this.isActive,
    required this.status,
    required this.productIcon,
    required this.productColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            productColor.withValues(alpha: 0.1),
            productColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Ikona produktu
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: productColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: productColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(productIcon, color: productColor, size: 28),
          ),

          const SizedBox(width: 16),

          // Informacje główne
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: productColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: productColor.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        productType,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: productColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(context),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  productName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (companyName != null && companyName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    companyName!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Przycisk zamknięcia
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            color: AppTheme.textSecondary,
            tooltip: 'Zamknij',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final statusColor = isActive ? AppTheme.successColor : AppTheme.errorColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
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
            status,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
