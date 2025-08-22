import 'package:flutter/material.dart';

/// Professional Financial Theme - Maximum readability and minimalist design
/// Inspired by Bloomberg Terminal, Charles Schwab, Fidelity, and top-tier financial platforms
/// Focus: Extreme readability, professional appearance, functional minimalism
class AppThemePro {
  // === CORE PROFESSIONAL COLORS ===
  // Ultra-high contrast for maximum readability
  static const Color primaryDark = Color(0xFF0B1426); // Deep financial navy
  static const Color primaryMedium = Color(0xFF1E2A47); // Medium navy surface
  static const Color primaryLight = Color(0xFF2D3E63); // Light navy accent

  // === PREMIUM ACCENT COLORS ===
  // Sophisticated gold system for hierarchy and emphasis
  static const Color accentGold = Color(
    0xFFFFD700,
  ); // Pure gold for primary actions
  static const Color accentGoldMuted = Color(
    0xFFE6C200,
  ); // Muted gold for secondary
  static const Color accentGoldDark = Color(0xFFB8860B); // Dark gold for depth

  // === ULTRA-HIGH CONTRAST TEXT ===
  // Maximum readability in dark environment
  static const Color textPrimary = Color(
    0xFFFFFFFF,
  ); // Pure white for critical text
  static const Color textSecondary = Color(0xFFE5E7EB); // High contrast gray
  static const Color textTertiary = Color(0xFFD1D5DB); // Medium contrast gray
  static const Color textMuted = Color(0xFF9CA3AF); // Subtle text
  static const Color textDisabled = Color(0xFF6B7280); // Disabled state

  // === PROFESSIONAL BACKGROUND SYSTEM ===
  // Ultra-professional dark backgrounds with subtle depth
  static const Color backgroundPrimary = Color(
    0xFF0F172A,
  ); // Primary background
  static const Color backgroundSecondary = Color(
    0xFF1E293B,
  ); // Cards and surfaces
  static const Color backgroundTertiary = Color(
    0xFF334155,
  ); // Elevated elements
  static const Color backgroundModal = Color(0xFF0F172A); // Modal backgrounds

  // === FINANCIAL DATA COLORS ===
  // Professional colors for financial performance
  static const Color profitGreen = Color(0xFF10B981); // Gain/profit indicator
  static const Color profitGreenBg = Color(0xFF064E3B); // Profit background
  static const Color lossRed = Color(0xFFEF4444); // Loss/decline indicator
  static const Color lossRedBg = Color(0xFF7F1D1D); // Loss background
  static const Color neutralGray = Color(0xFF6B7280); // Neutral/no change
  static const Color neutralGrayBg = Color(0xFF374151); // Neutral background

  // === INVESTMENT CATEGORY COLORS ===
  // Clear categorization for different investment types
  static const Color bondsBlue = Color(0xFF3B82F6); // Bonds - conservative blue
  static const Color sharesGreen = Color(0xFF059669); // Shares - growth green
  static const Color loansOrange = Color(
    0xFFF59E0B,
  ); // Loans - attention orange
  static const Color realEstateViolet = Color(
    0xFF8B5CF6,
  ); // Real estate - stable violet
  static const Color cryptoAmber = Color(0xFFD97706); // Crypto - dynamic amber

  // === STATUS COLORS ===
  // Clear status indication system
  static const Color statusSuccess = Color(0xFF10B981); // Success state
  static const Color statusWarning = Color(0xFFF59E0B); // Warning state
  static const Color statusError = Color(0xFFEF4444); // Error state
  static const Color statusInfo = Color(0xFF3B82F6); // Information state

  // === BORDER AND DIVIDER SYSTEM ===
  // Subtle but clear boundaries
  static const Color borderPrimary = Color(0xFF374151); // Primary borders
  static const Color borderSecondary = Color(0xFF4B5563); // Secondary borders
  static const Color borderAccent = Color(0xFF6B7280); // Accent borders
  static const Color dividerColor = Color(0xFF374151); // Dividers

  // === SURFACE COLORS ===
  // Professional surface hierarchy
  static const Color surfaceCard = Color(0xFF1E293B); // Card surfaces
  static const Color surfaceElevated = Color(0xFF334155); // Elevated surfaces
  static const Color surfaceInteractive = Color(
    0xFF475569,
  ); // Interactive elements
  static const Color surfaceHover = Color(0xFF64748B); // Hover states

  // === OVERLAY SYSTEM ===
  static const Color overlayLight = Color(0x1AFFFFFF); // Light overlay
  static const Color overlayMedium = Color(0x33FFFFFF); // Medium overlay
  static const Color overlayDark = Color(0x80000000); // Dark overlay
  static const Color scrimColor = Color(0xE6000000); // Modal scrim

  // === UTILITY METHODS ===

  /// Returns color for investment performance
  static Color getPerformanceColor(double value) {
    if (value > 0) return profitGreen;
    if (value < 0) return lossRed;
    return neutralGray;
  }

  /// Returns background color for investment performance
  static Color getPerformanceBackground(double value) {
    if (value > 0) return profitGreenBg;
    if (value < 0) return lossRedBg;
    return neutralGrayBg;
  }

  /// Returns color for investment type
  static Color getInvestmentTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'bonds':
      case 'obligacje':
        return bondsBlue;
      case 'shares':
      case 'udziały':
      case 'akcje':
        return sharesGreen;
      case 'loans':
      case 'pożyczki':
        return loansOrange;
      case 'real_estate':
      case 'apartamenty':
      case 'nieruchomości':
        return realEstateViolet;
      case 'crypto':
      case 'krypto':
        return cryptoAmber;
      default:
        return textMuted;
    }
  }

  /// Returns status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'aktywny':
      case 'completed':
      case 'zakończony':
        return statusSuccess;
      case 'pending':
      case 'oczekujący':
      case 'warning':
        return statusWarning;
      case 'error':
      case 'błąd':
      case 'cancelled':
      case 'anulowany':
        return statusError;
      case 'info':
      case 'informacja':
        return statusInfo;
      default:
        return neutralGray;
    }
  }

  // === PREMIUM DECORATIONS ===

  /// Ultra-professional card decoration
  static BoxDecoration get premiumCardDecoration => BoxDecoration(
    color: surfaceCard,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: borderPrimary, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  /// Elevated surface decoration
  static BoxDecoration get elevatedSurfaceDecoration => BoxDecoration(
    color: surfaceElevated,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: borderSecondary, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.15),
        blurRadius: 6,
        offset: const Offset(0, 1),
      ),
    ],
  );

  /// Interactive element decoration
  static BoxDecoration get interactiveDecoration => BoxDecoration(
    color: surfaceInteractive,
    borderRadius: BorderRadius.circular(6),
    border: Border.all(color: borderAccent, width: 1),
  );

  /// Financial data container decoration
  static BoxDecoration getFinancialDataDecoration(double value) =>
      BoxDecoration(
        color: getPerformanceBackground(value),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: getPerformanceColor(value).withOpacity(0.5),
          width: 1,
        ),
      );

  // === MAIN THEME CONFIGURATION ===

  static ThemeData get professionalTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Core color scheme
      colorScheme: const ColorScheme.dark(
        primary: accentGold,
        onPrimary: primaryDark,
        primaryContainer: primaryMedium,
        onPrimaryContainer: textPrimary,

        secondary: accentGoldMuted,
        onSecondary: primaryDark,
        secondaryContainer: primaryLight,
        onSecondaryContainer: textPrimary,

        tertiary: accentGoldDark,
        onTertiary: textPrimary,

        surface: backgroundSecondary,
        onSurface: textPrimary,
        surfaceContainerHighest: backgroundTertiary,
        onSurfaceVariant: textSecondary,

        error: statusError,
        onError: textPrimary,
        errorContainer: lossRedBg,
        onErrorContainer: lossRed,

        outline: borderPrimary,
        outlineVariant: borderSecondary,
        shadow: Colors.black,
        scrim: scrimColor,
      ),

      // Background
      scaffoldBackgroundColor: backgroundPrimary,

      // App bar
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundPrimary,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textSecondary, size: 24),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderPrimary, width: 1),
        ),
      ),

      // Text theme - ultra-high readability
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.25,
          height: 1.25,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.3,
        ),

        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.35,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.4,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.45,
        ),

        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.15,
          height: 1.5,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.1,
          height: 1.5,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 0.2,
          height: 1.5,
        ),

        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          letterSpacing: 0.15,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          letterSpacing: 0.1,
          height: 1.6,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          letterSpacing: 0.2,
          height: 1.6,
        ),

        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          letterSpacing: 0.3,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          letterSpacing: 0.4,
          height: 1.4,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textMuted,
          letterSpacing: 0.5,
          height: 1.4,
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceInteractive,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderPrimary, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderPrimary, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: statusError, width: 1),
        ),

        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          foregroundColor: primaryDark,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentGold,
          side: const BorderSide(color: accentGold, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentGold,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
