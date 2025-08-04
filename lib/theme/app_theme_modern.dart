import 'package:flutter/material.dart';

/// Modern Premium Financial Theme - Sophisticated Dark & Gold Design
/// Inspired by cutting-edge fintech platforms like Stripe, Robinhood, and modern trading apps
/// Features: Enhanced visual hierarchy, modern gradients, premium shadows, glassmorphism effects
class ModernAppTheme {
  // === PREMIUM BRAND COLORS ===
  // Deep, sophisticated dark blues with enhanced depth
  static const Color primaryNavy = Color(0xFF0A1628); // Ultra-deep navy primary
  static const Color primaryNavyLight = Color(0xFF1A2332); // Elevated navy surfaces
  static const Color primaryAccent = Color(0xFF2D3E50); // Medium navy accents
  static const Color primaryMuted = Color(0xFF34495E); // Muted navy for backgrounds

  // === PREMIUM GOLD SYSTEM ===
  // Sophisticated gold palette with multiple tones for visual hierarchy
  static const Color goldPrimary = Color(0xFFFFD700); // Pure premium gold
  static const Color goldWarm = Color(0xFFF4D03F); // Warm gold variant
  static const Color goldRose = Color(0xFFE6B800); // Rose gold undertone
  static const Color goldDark = Color(0xFFB8860B); // Dark gold for depth
  static const Color goldMuted = Color(0xFFDAA520); // Muted gold for subtle accents

  // === MODERN BACKGROUND SYSTEM ===
  // Ultra-deep backgrounds with subtle gradient undertones
  static const Color backgroundDeep = Color(0xFF0B1426); // Primary deep background
  static const Color backgroundCard = Color(0xFF1A2332); // Card surfaces
  static const Color backgroundElevated = Color(0xFF243447); // Elevated surfaces
  static const Color backgroundModal = Color(0xFF2C3E50); // Modal backgrounds
  static const Color backgroundGlass = Color(0x1AFFFFFF); // Glass morphism overlay

  // === ENHANCED TEXT HIERARCHY ===
  // Premium text system with enhanced contrast and readability
  static const Color textPrimary = Color(0xFFF8FAFC); // Ultra-high contrast white
  static const Color textSecondary = Color(0xFFE2E8F0); // High contrast secondary
  static const Color textTertiary = Color(0xFFCBD5E1); // Medium contrast tertiary
  static const Color textMuted = Color(0xFF94A3B8); // Subtle muted text
  static const Color textDisabled = Color(0xFF64748B); // Disabled state
  static const Color textOnGold = Color(0xFF1A1A1A); // Text on gold backgrounds
  static const Color textOnDark = Color(0xFFFFFFFF); // Text on dark backgrounds

  // === SOPHISTICATED PERFORMANCE COLORS ===
  // Modern financial indicators with enhanced visual appeal
  static const Color gainPrimary = Color(0xFF00D7AA); // Modern gain green
  static const Color gainSecondary = Color(0xFF4FFFCB); // Light gain accent
  static const Color gainBackground = Color(0xFF0D2818); // Subtle gain background
  static const Color gainGlow = Color(0x2000D7AA); // Gain glow effect

  static const Color lossPrimary = Color(0xFFFF4757); // Modern loss red
  static const Color lossSecondary = Color(0xFFFF7979); // Light loss accent
  static const Color lossBackground = Color(0xFF2D1B1E); // Subtle loss background
  static const Color lossGlow = Color(0x20FF4757); // Loss glow effect

  static const Color neutralPrimary = Color(0xFF8B9DC3); // Neutral indicator
  static const Color neutralSecondary = Color(0xFFA8B8D8); // Light neutral
  static const Color neutralBackground = Color(0xFF1E2630); // Neutral background

  // === MODERN INVESTMENT COLORS ===
  // Enhanced investment category colors with modern appeal
  static const Color bondsModern = Color(0xFF5DADE2); // Modern bonds blue
  static const Color bondsGlow = Color(0x205DADE2); // Bonds glow effect
  static const Color bondsBackground = Color(0xFF0F1C2A); // Bonds background

  static const Color sharesModern = Color(0xFF58D68D); // Modern shares green
  static const Color sharesGlow = Color(0x2058D68D); // Shares glow effect
  static const Color sharesBackground = Color(0xFF0F2A15); // Shares background

  static const Color loansModern = Color(0xFFF39C12); // Modern loans orange
  static const Color loansGlow = Color(0x20F39C12); // Loans glow effect
  static const Color loansBackground = Color(0xFF2A1B0A); // Loans background

  static const Color realEstateModern = Color(0xFFAB47BC); // Modern real estate purple
  static const Color realEstateGlow = Color(0x20AB47BC); // Real estate glow
  static const Color realEstateBackground = Color(0xFF1F0D2A); // Real estate background

  static const Color cryptoModern = Color(0xFFFF9500); // Modern crypto orange
  static const Color cryptoGlow = Color(0x20FF9500); // Crypto glow effect
  static const Color cryptoBackground = Color(0xFF2A1700); // Crypto background

  static const Color etfModern = Color(0xFF42A5F5); // Modern ETF blue
  static const Color etfGlow = Color(0x2042A5F5); // ETF glow effect
  static const Color etfBackground = Color(0xFF0A1A2A); // ETF background

  // === MODERN STATUS SYSTEM ===
  // Enhanced status colors with glow effects
  static const Color successModern = Color(0xFF00E676); // Modern success
  static const Color successGlow = Color(0x2000E676); // Success glow
  static const Color successBackground = Color(0xFF0D2E1C); // Success background

  static const Color warningModern = Color(0xFFFFC107); // Modern warning
  static const Color warningGlow = Color(0x20FFC107); // Warning glow
  static const Color warningBackground = Color(0xFF2A2000); // Warning background

  static const Color errorModern = Color(0xFFFF1744); // Modern error
  static const Color errorGlow = Color(0x20FF1744); // Error glow
  static const Color errorBackground = Color(0xFF2D0A0F); // Error background

  static const Color infoModern = Color(0xFF2196F3); // Modern info
  static const Color infoGlow = Color(0x202196F3); // Info glow
  static const Color infoBackground = Color(0xFF0A1A2D); // Info background

  // === ENHANCED BORDER SYSTEM ===
  // Modern border colors with subtle gradients
  static const Color borderPrimary = Color(0xFF3A4A5C); // Primary borders
  static const Color borderSecondary = Color(0xFF2A3441); // Secondary borders
  static const Color borderAccent = Color(0xFF4A5A6C); // Accent borders
  static const Color borderGlow = Color(0x40FFD700); // Gold glow border
  static const Color dividerModern = Color(0xFF2E3A47); // Modern dividers

  // === SURFACE ENHANCEMENT ===
  // Modern surface colors with depth
  static const Color surfacePrimary = Color(0xFF1E2A38); // Primary surfaces
  static const Color surfaceSecondary = Color(0xFF243447); // Secondary surfaces
  static const Color surfaceInteractive = Color(0xFF2A3A4F); // Interactive surfaces
  static const Color surfaceHover = Color(0xFF334155); // Hover states
  static const Color surfacePressed = Color(0xFF3A4A5F); // Pressed states

  // === MODERN OVERLAY SYSTEM ===
  static const Color overlayLight = Color(0x15FFFFFF); // Light overlay
  static const Color overlayMedium = Color(0x30FFFFFF); // Medium overlay
  static const Color overlayDark = Color(0x70000000); // Dark overlay
  static const Color overlayGlass = Color(0x20FFFFFF); // Glass effect
  static const Color scrimModern = Color(0xE0000000); // Modern scrim

  // === PREMIUM GRADIENTS ===
  // Modern gradient definitions for enhanced visual appeal
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryNavy, primaryNavyLight, primaryAccent],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldPrimary, goldWarm, goldRose],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundCard, backgroundElevated],
    stops: [0.0, 1.0],
  );

  static const LinearGradient gainGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [gainBackground, gainPrimary],
    stops: [0.0, 1.0],
  );

  static const LinearGradient lossGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [lossBackground, lossPrimary],
    stops: [0.0, 1.0],
  );

  static const RadialGradient heroGradient = RadialGradient(
    center: Alignment.topLeft,
    radius: 2.0,
    colors: [primaryNavyLight, primaryNavy, backgroundDeep],
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [overlayGlass, Color(0x10FFFFFF), Color(0x05FFFFFF)],
    stops: [0.0, 0.5, 1.0],
  );

  // === UTILITY METHODS ===

  /// Returns modern color for investment performance with glow effect
  static Color getPerformanceColor(double value, {bool withGlow = false}) {
    Color baseColor;
    if (value > 0) {
      baseColor = gainPrimary;
    } else if (value < 0) {
      baseColor = lossPrimary;
    } else {
      baseColor = neutralPrimary;
    }

    return withGlow ? baseColor : baseColor;
  }

  /// Returns modern background color for performance with subtle effects
  static Color getPerformanceBackground(double value) {
    if (value > 0) return gainBackground;
    if (value < 0) return lossBackground;
    return neutralBackground;
  }

  /// Returns glow color for performance indicators
  static Color getPerformanceGlow(double value) {
    if (value > 0) return gainGlow;
    if (value < 0) return lossGlow;
    return Color(0x20FFFFFF);
  }

  /// Returns modern color for investment types
  static Color getInvestmentTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'bonds':
      case 'obligacje':
        return bondsModern;
      case 'shares':
      case 'udziały':
      case 'akcje':
        return sharesModern;
      case 'loans':
      case 'pożyczki':
        return loansModern;
      case 'real_estate':
      case 'apartamenty':
      case 'nieruchomości':
        return realEstateModern;
      case 'crypto':
      case 'krypto':
        return cryptoModern;
      case 'etf':
      case 'fundusze':
        return etfModern;
      default:
        return neutralPrimary;
    }
  }

  /// Returns background color for investment types
  static Color getInvestmentTypeBackground(String type) {
    switch (type.toLowerCase()) {
      case 'bonds':
      case 'obligacje':
        return bondsBackground;
      case 'shares':
      case 'udziały':
      case 'akcje':
        return sharesBackground;
      case 'loans':
      case 'pożyczki':
        return loansBackground;
      case 'real_estate':
      case 'apartamenty':
      case 'nieruchomości':
        return realEstateBackground;
      case 'crypto':
      case 'krypto':
        return cryptoBackground;
      case 'etf':
      case 'fundusze':
        return etfBackground;
      default:
        return backgroundCard;
    }
  }

  /// Returns glow color for investment types
  static Color getInvestmentTypeGlow(String type) {
    switch (type.toLowerCase()) {
      case 'bonds':
      case 'obligacje':
        return bondsGlow;
      case 'shares':
      case 'udziały':
      case 'akcje':
        return sharesGlow;
      case 'loans':
      case 'pożyczki':
        return loansGlow;
      case 'real_estate':
      case 'apartamenty':
      case 'nieruchomości':
        return realEstateGlow;
      case 'crypto':
      case 'krypto':
        return cryptoGlow;
      case 'etf':
      case 'fundusze':
        return etfGlow;
      default:
        return overlayLight;
    }
  }

  /// Returns modern status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'aktywny':
      case 'completed':
      case 'zakończony':
        return successModern;
      case 'pending':
      case 'oczekujący':
      case 'warning':
        return warningModern;
      case 'error':
      case 'błąd':
      case 'cancelled':
      case 'anulowany':
        return errorModern;
      case 'info':
      case 'informacja':
        return infoModern;
      default:
        return neutralPrimary;
    }
  }

  // === PREMIUM DECORATIONS ===

  /// Ultra-premium card decoration with glassmorphism
  static BoxDecoration get premiumCardDecoration => BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderPrimary,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: goldPrimary.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      );

  /// Glassmorphism card decoration
  static BoxDecoration get glassMorphismDecoration => BoxDecoration(
        gradient: glassGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderPrimary.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      );

  /// Elevated surface with modern styling
  static BoxDecoration get modernElevatedDecoration => BoxDecoration(
        color: surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderAccent,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: goldPrimary.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      );

  /// Performance card with glow effect
  static BoxDecoration getPerformanceCardDecoration(double value) => BoxDecoration(
        color: getPerformanceBackground(value),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: getPerformanceColor(value).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: getPerformanceGlow(value),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      );

  /// Investment type chip with glow
  static BoxDecoration getInvestmentChipDecoration(String type) => BoxDecoration(
        color: getInvestmentTypeBackground(type),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: getInvestmentTypeColor(type).withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: getInvestmentTypeGlow(type),
            blurRadius: 12,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
      );

  /// Gold accent decoration
  static BoxDecoration get goldAccentDecoration => BoxDecoration(
        gradient: goldGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: goldPrimary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      );

  /// Interactive surface decoration
  static BoxDecoration get interactiveDecoration => BoxDecoration(
        color: surfaceInteractive,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderAccent,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      );

  // === MAIN THEME CONFIGURATION ===

  static ThemeData get modernTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Enhanced color scheme
      colorScheme: const ColorScheme.dark(
        primary: goldPrimary,
        onPrimary: textOnGold,
        primaryContainer: primaryNavyLight,
        onPrimaryContainer: textPrimary,

        secondary: goldWarm,
        onSecondary: textOnGold,
        secondaryContainer: goldDark,
        onSecondaryContainer: textPrimary,

        tertiary: goldRose,
        onTertiary: textOnGold,

        surface: surfacePrimary,
        onSurface: textPrimary,
        surfaceVariant: surfaceSecondary,
        onSurfaceVariant: textSecondary,

        background: backgroundDeep,
        onBackground: textPrimary,

        error: errorModern,
        onError: textOnDark,
        errorContainer: errorBackground,
        onErrorContainer: errorModern,

        outline: borderPrimary,
        outlineVariant: borderSecondary,
        shadow: Colors.black,
        scrim: scrimModern,
        inverseSurface: textPrimary,
        onInverseSurface: backgroundDeep,
        inversePrimary: primaryNavyLight,
      ),

      // Background
      scaffoldBackgroundColor: backgroundDeep,

      // Modern app bar
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundCard,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black26,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        toolbarTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        iconTheme: IconThemeData(color: goldPrimary, size: 24),
        actionsIconTheme: IconThemeData(color: goldPrimary, size: 24),
      ),

      // Premium cards
      cardTheme: CardThemeData(
        color: surfacePrimary,
        shadowColor: Colors.black38,
        elevation: 8,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderPrimary, width: 1),
        ),
      ),

      // Enhanced buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: goldPrimary,
          foregroundColor: textOnGold,
          disabledBackgroundColor: surfaceInteractive,
          disabledForegroundColor: textDisabled,
          elevation: 8,
          shadowColor: goldPrimary.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: goldPrimary,
          disabledForegroundColor: textDisabled,
          side: const BorderSide(color: goldPrimary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: goldPrimary,
          disabledForegroundColor: textDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Modern input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceInteractive,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderSecondary, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderPrimary, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: goldPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorModern, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorModern, width: 2),
        ),

        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: goldPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(
          color: textMuted,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: goldPrimary,
        suffixIconColor: goldPrimary,
      ),

      // Enhanced typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -1.2,
          height: 1.1,
        ),
        displayMedium: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -1.0,
          height: 1.2,
        ),
        displaySmall: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.8,
          height: 1.25,
        ),

        headlineLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.6,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.4,
          height: 1.35,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.2,
          height: 1.4,
        ),

        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0,
          height: 1.45,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.1,
          height: 1.5,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 0.2,
          height: 1.5,
        ),

        bodyLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          letterSpacing: 0.1,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          letterSpacing: 0.1,
          height: 1.6,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          letterSpacing: 0.2,
          height: 1.6,
        ),

        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          letterSpacing: 0.3,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          letterSpacing: 0.4,
          height: 1.4,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textMuted,
          letterSpacing: 0.5,
          height: 1.4,
        ),
      ),

      // Enhanced components
      iconTheme: const IconThemeData(color: goldPrimary, size: 24),

      dividerTheme: const DividerThemeData(
        color: dividerModern,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: surfaceSecondary,
        iconColor: goldPrimary,
        textColor: textPrimary,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceSecondary,
        selectedColor: goldDark,
        secondarySelectedColor: goldWarm,
        deleteIconColor: textSecondary,
        disabledColor: surfaceInteractive,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        side: const BorderSide(color: borderPrimary, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textOnGold,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: goldPrimary,
        linearTrackColor: surfaceInteractive,
        circularTrackColor: surfaceInteractive,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceSecondary,
        contentTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        actionTextColor: goldPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
      ),
    );
  }

  // === COMPATIBILITY ALIASES ===
  static const Color errorColor = errorModern;
  static const Color successColor = successModern;
  static const Color warningColor = warningModern;
  static const Color infoColor = infoModern;
  static const Color textHint = textMuted;

  static BoxDecoration get cardDecoration => premiumCardDecoration;
  static BoxDecoration get gradientDecoration => BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(20),
      );
}
