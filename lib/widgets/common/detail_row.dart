import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Wiersz z etykietą, wartością i ikoną - dla listy szczegółów
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: padding!,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color ?? AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color ?? AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: color != null
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: row,
      );
    }

    return row;
  }
}
