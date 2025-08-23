import 'package:flutter/material.dart';
import 'premium_tab_navigation.dart';
import '../../theme/app_theme_professional.dart';

/// Helper dla łatwego konfigurowania nawigacji w Premium Analytics
class PremiumTabHelper {
  /// Zwraca listę standardowych zakładek dla Analytics
  static List<PremiumTabItem> getAnalyticsTabItems() {
    return [
      PremiumTabExtensions.overview,
      PremiumTabExtensions.investors,
      PremiumTabExtensions.analytics,
      PremiumTabExtensions.majority,
    ];
  }

  /// Buduje tryb eksportu z informacją o wybranych elementach
  static Widget buildExportModeBar({
    required int selectedCount,
    required VoidCallback onComplete,
    required VoidCallback onClose,
    String? customMessage,
  }) {
    return PremiumModeBar(
      title: 'Tryb eksportu aktywny',
      subtitle: customMessage ?? 'Wybrano $selectedCount inwestorów',
      icon: Icons.download_rounded,
      color: AppThemePro.accentGold,
      onClose: onClose,
      actions: [
        ElevatedButton.icon(
          onPressed: selectedCount > 0 ? onComplete : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedCount > 0
                ? AppThemePro.accentGold
                : AppThemePro.surfaceInteractive,
            foregroundColor: selectedCount > 0
                ? AppThemePro.primaryDark
                : AppThemePro.textMuted,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: selectedCount > 0 ? 2 : 0,
          ),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text(
            'Dokończ eksport',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  /// Buduje tryb email z informacją o wybranych odbiorcach
  static Widget buildEmailModeBar({
    required int selectedCount,
    required VoidCallback onSendEmails,
    required VoidCallback onClose,
    String? customMessage,
  }) {
    return PremiumModeBar(
      title: 'Tryb wysyłania e-maili',
      subtitle: customMessage ?? 'Wysyłanie do $selectedCount inwestorów',
      icon: Icons.email_rounded,
      color: AppThemePro.statusInfo,
      onClose: onClose,
      actions: [
        ElevatedButton.icon(
          onPressed: selectedCount > 0 ? onSendEmails : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedCount > 0
                ? AppThemePro.statusInfo
                : AppThemePro.surfaceInteractive,
            foregroundColor: selectedCount > 0
                ? Colors.white
                : AppThemePro.textMuted,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: selectedCount > 0 ? 2 : 0,
          ),
          icon: const Icon(Icons.send_rounded, size: 18),
          label: const Text(
            'Wyślij e-maile',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  /// Buduje customowy mode bar dla innych tryb
  static Widget buildCustomModeBar({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Widget> actions,
    VoidCallback? onClose,
    EdgeInsets? padding,
  }) {
    return PremiumModeBar(
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      actions: actions,
      onClose: onClose,
    );
  }

  /// Zwraca standardowe akcje dla mode barów
  static List<Widget> getStandardActions({
    required String primaryLabel,
    required VoidCallback? onPrimary,
    required Color primaryColor,
    String? secondaryLabel,
    VoidCallback? onSecondary,
    Color? secondaryColor,
    bool showCount = false,
    int count = 0,
  }) {
    final actions = <Widget>[];

    // Opcjonalny przycisk secondary
    if (secondaryLabel != null && onSecondary != null) {
      actions.add(
        OutlinedButton.icon(
          onPressed: onSecondary,
          style: OutlinedButton.styleFrom(
            foregroundColor: secondaryColor ?? AppThemePro.textSecondary,
            side: BorderSide(
              color: secondaryColor ?? AppThemePro.borderPrimary,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.edit_rounded, size: 16),
          label: Text(
            secondaryLabel,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    // Główny przycisk akcji
    actions.add(
      ElevatedButton.icon(
        onPressed: onPrimary,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPrimary != null
              ? primaryColor
              : AppThemePro.surfaceInteractive,
          foregroundColor: onPrimary != null
              ? (primaryColor == AppThemePro.accentGold
                    ? AppThemePro.primaryDark
                    : Colors.white)
              : AppThemePro.textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: onPrimary != null ? 2 : 0,
        ),
        icon: Icon(_getIconForAction(primaryLabel), size: 18),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              primaryLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (showCount && count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: onPrimary != null
                      ? (primaryColor == AppThemePro.accentGold
                            ? AppThemePro.primaryDark.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.3))
                      : AppThemePro.borderPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: onPrimary != null
                        ? (primaryColor == AppThemePro.accentGold
                              ? AppThemePro.primaryDark
                              : Colors.white)
                        : AppThemePro.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return actions;
  }

  /// Zwraca odpowiednią ikonę dla akcji
  static IconData _getIconForAction(String label) {
    final lowerLabel = label.toLowerCase();

    if (lowerLabel.contains('eksport') || lowerLabel.contains('pobierz')) {
      return Icons.download_rounded;
    } else if (lowerLabel.contains('wyślij') || lowerLabel.contains('email')) {
      return Icons.send_rounded;
    } else if (lowerLabel.contains('dokończ') ||
        lowerLabel.contains('zatwierdź')) {
      return Icons.check_rounded;
    } else if (lowerLabel.contains('anuluj') ||
        lowerLabel.contains('zamknij')) {
      return Icons.close_rounded;
    } else if (lowerLabel.contains('edytuj') || lowerLabel.contains('zmień')) {
      return Icons.edit_rounded;
    } else if (lowerLabel.contains('usuń') || lowerLabel.contains('skasuj')) {
      return Icons.delete_rounded;
    } else if (lowerLabel.contains('zapisz')) {
      return Icons.save_rounded;
    } else if (lowerLabel.contains('odśwież')) {
      return Icons.refresh_rounded;
    } else {
      return Icons.arrow_forward_rounded;
    }
  }

  /// Konfiguracja kolorów dla różnych trybów
  static Color getModeColor(String mode) {
    switch (mode.toLowerCase()) {
      case 'export':
      case 'eksport':
        return AppThemePro.accentGold;
      case 'email':
        return AppThemePro.statusInfo;
      case 'delete':
      case 'usuń':
        return AppThemePro.statusError;
      case 'edit':
      case 'edytuj':
        return AppThemePro.statusWarning;
      case 'view':
      case 'podgląd':
        return AppThemePro.statusSuccess;
      default:
        return AppThemePro.accentGold;
    }
  }

  /// Zwraca animację dla przejścia między trybami
  static AnimationController createModeTransitionController({
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return AnimationController(duration: duration, vsync: vsync);
  }

  /// Buduje animowaną ikonę dla trybu
  static Widget buildAnimatedModeIcon({
    required IconData icon,
    required Color color,
    required AnimationController controller,
    double size = 24,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * controller.value),
          child: Icon(icon, color: color, size: size),
        );
      },
    );
  }
}
