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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
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
      child: isMobile
          ? _buildMobileLayout(context)
          : _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Górny wiersz: ikona + przycisk zamknięcia
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: productColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: productColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(productIcon, color: productColor, size: 24),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close),
              color: AppTheme.textSecondary,
              tooltip: 'Zamknij',
              iconSize: 20,
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Typ produktu i status w grid
        Row(
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: productColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
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
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(context),
          ],
        ),

        const SizedBox(height: 10),

        // Nazwa produktu
        Text(
          productName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        // Nazwa firmy (jeśli istnieje)
        if (companyName != null && companyName!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            companyName!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
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
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final statusColor = isActive ? AppTheme.successColor : AppTheme.errorColor;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 8,
        vertical: isMobile ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isMobile ? 5 : 6,
            height: isMobile ? 5 : 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isMobile ? 3 : 4),
          Text(
            status,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 9 : 10,
            ),
          ),
        ],
      ),
    );
  }
}
