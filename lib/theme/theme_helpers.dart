import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 🎨 APP COLORS - Helper class for theme colors
/// Mapuje konstante z AppTheme na łatwiejsze API
class AppColors {
  static Color get primaryColor => AppTheme.primaryColor;
  static Color get accentColor =>
      AppTheme.secondaryGold; // Mapujemy gold jako accent
  static Color get warningColor =>
      AppTheme.loansColor; // Orange/amber dla warnings
  static Color get errorColor => AppTheme.lossPrimary; // Czerwony dla błędów
  static Color get infoColor => AppTheme.bondsColor; // Niebieski dla info
  static Color get successColor => AppTheme.gainPrimary; // Zielony dla sukcesu

  // Aliasy dla kompatybilności
  static Color get primary => primaryColor;
  static Color get success => successColor;
  static Color get warning => warningColor;
  static Color get error => errorColor;
  static Color get info => infoColor;

  // Dodatkowe kolory tła i powierzchni
  static Color get backgroundColor => AppTheme.backgroundPrimary;
  static Color get surfaceColor => AppTheme.surfaceCard;
  static Color get surface => surfaceColor;
  static Color get cardBackground => AppTheme.surfaceCard;
  static Color get borderColor => AppTheme.borderPrimary;
  static Color get cardColor => AppTheme.textSecondary;

  // Kolory tekstu
  static Color get text => AppTheme.textPrimary;
  static Color get textSecondary => AppTheme.textSecondary;
  static Color get textTertiary => AppTheme.textTertiary;
}

/// ✍️ APP TEXT STYLES - Helper class for text styles
/// Mapuje TextTheme na łatwiejsze API
class AppTextStyles {
  static TextTheme get _textTheme => AppTheme.lightTheme.textTheme;

  static TextStyle? get displayLarge => _textTheme.displayLarge;
  static TextStyle? get displayMedium => _textTheme.displayMedium;
  static TextStyle? get displaySmall => _textTheme.displaySmall;

  static TextStyle? get headlineLarge => _textTheme.headlineLarge;
  static TextStyle? get headlineMedium => _textTheme.headlineMedium;
  static TextStyle? get headlineSmall => _textTheme.headlineSmall;

  static TextStyle? get titleLarge => _textTheme.titleLarge;
  static TextStyle? get titleMedium => _textTheme.titleMedium;
  static TextStyle? get titleSmall => _textTheme.titleSmall;

  static TextStyle? get bodyLarge => _textTheme.bodyLarge;
  static TextStyle? get bodyMedium => _textTheme.bodyMedium;
  static TextStyle? get bodySmall => _textTheme.bodySmall;

  static TextStyle? get labelLarge => _textTheme.labelLarge;
  static TextStyle? get labelMedium => _textTheme.labelMedium;
  static TextStyle? get labelSmall => _textTheme.labelSmall;
}

/// 📐 APP DIMENSIONS - Helper class for consistent spacing
class AppDimensions {
  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Margins
  static const double marginSmall = 8.0;
  static const double marginMedium = 16.0;
  static const double marginLarge = 24.0;

  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  // Icon sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
}

/// 🎯 APP CONSTANTS - Stałe używane w całej aplikacji
class AppConstants {
  // Animation durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Chart colors
  static const List<Color> chartColors = [
    Color(0xFF6366F1), // Primary
    Color(0xFF10B981), // Accent
    Color(0xFFF59E0B), // Warning
    Color(0xFF3B82F6), // Info
    Color(0xFFEF4444), // Error
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
  ];

  // Breakpoints for responsive design
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;
}

/// 🔧 THEME EXTENSIONS - Rozszerzenia dla łatwiejszego dostępu
extension ThemeExtensions on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  bool get isMobile =>
      MediaQuery.of(this).size.width < AppConstants.mobileBreakpoint;
  bool get isTablet =>
      MediaQuery.of(this).size.width >= AppConstants.mobileBreakpoint &&
      MediaQuery.of(this).size.width < AppConstants.desktopBreakpoint;
  bool get isDesktop =>
      MediaQuery.of(this).size.width >= AppConstants.desktopBreakpoint;
}
