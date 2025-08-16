import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Widget do wyświetlania informacji o kwocie w kolumnie
class AmountInfo extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final String Function(double) formatter;
  final VoidCallback? onTap;

  const AmountInfo({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.formatter,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          formatter(amount),
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      );
    }

    return content;
  }
}
