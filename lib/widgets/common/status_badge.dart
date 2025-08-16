import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Widget do wyświetlania statusu z kolorową kropką i tekstem
class StatusBadge extends StatelessWidget {
  final String status;
  final bool isActive;
  final Color? customColor;
  final double? fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    required this.isActive,
    this.customColor,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor =
        customColor ?? (isActive ? AppTheme.successColor : AppTheme.errorColor);

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
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
