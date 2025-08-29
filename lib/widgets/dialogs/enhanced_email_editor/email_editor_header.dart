import 'package:flutter/material.dart';
import '../../../theme/app_theme_professional.dart';

class EmailEditorHeader extends StatelessWidget {
  final bool isMobile;
  final bool isSmallScreen;
  final int selectedInvestorsCount;
  final VoidCallback onClose;

  const EmailEditorHeader({
    super.key,
    required this.isMobile,
    required this.isSmallScreen,
    required this.selectedInvestorsCount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(color: AppThemePro.borderPrimary),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.email,
            color: AppThemePro.accentGold,
            size: isMobile ? 20 : 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edytor wiadomości email',
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Wybrani odbiorcy: $selectedInvestorsCount',
                    style: TextStyle(
                      color: AppThemePro.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close,
              color: AppThemePro.textSecondary,
            ),
            tooltip: 'Zamknij',
          ),
        ],
      ),
    );
  }
}