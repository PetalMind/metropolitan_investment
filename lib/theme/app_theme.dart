import 'package:flutter/material.dart';

/// Premium Dark Theme for Cosmopolitan Investment
/// Inspired by professional financial platforms like Bloomberg Terminal,
/// Charles Schwab, and modern fintech applications
class AppTheme {
  // === CORE BRAND COLORS ===
  // Rich, deep blue-grays that convey trust and professionalism
  static const Color primaryColor = Color(
    0xFF0D1B2A,
  ); // Deep navy - primary brand
  static const Color primaryLight = Color(
    0xFF1B263B,
  ); // Lighter navy for surfaces
  static const Color primaryAccent = Color(
    0xFF415A77,
  ); // Medium blue-gray for accents

  // === SECONDARY FINANCIAL COLORS ===
  // Sophisticated gold and copper tones that suggest wealth and prosperity
  static const Color secondaryGold = Color(0xFFD4AF37); // Premium gold
  static const Color secondaryCopper = Color(0xFFB87333); // Rich copper
  static const Color secondaryAmber = Color(
    0xFFFFB300,
  ); // Warm amber for highlights

  // === DARK BACKGROUND PALETTE ===
  // Professional dark grays with subtle blue undertones
  static const Color backgroundPrimary = Color(
    0xFF0A0E13,
  ); // Almost black, slight blue tint
  static const Color backgroundSecondary = Color(
    0xFF0F1419,
  ); // Slightly lighter for cards
  static const Color backgroundTertiary = Color(
    0xFF161B22,
  ); // For elevated surfaces
  static const Color backgroundModal = Color(
    0xFF1C2128,
  ); // For modals and overlays

  // === SURFACE COLORS ===
  // Sophisticated surface hierarchy
  static const Color surfaceContainer = Color(
    0xFF1E252D,
  ); // Main container surface
  static const Color surfaceCard = Color(0xFF232A33); // Card surfaces
  static const Color surfaceElevated = Color(0xFF2A3139); // Elevated components
  static const Color surfaceInteractive = Color(
    0xFF2F3640,
  ); // Interactive elements

  // === TEXT HIERARCHY ===
  // Carefully crafted text colors for optimal readability
  static const Color textPrimary = Color(0xFFE8EAED); // High contrast white
  static const Color textSecondary = Color(0xFFBDC1C6); // Medium contrast gray
  static const Color textTertiary = Color(
    0xFF9AA0A6,
  ); // Lower contrast for labels
  static const Color textDisabled = Color(0xFF5F6368); // Disabled state
  static const Color textOnPrimary = Color(
    0xFFFFFFFF,
  ); // Text on primary surfaces
  static const Color textOnSecondary = Color(
    0xFF0D1B2A,
  ); // Text on secondary surfaces

  // === INVESTMENT PERFORMANCE COLORS ===
  // Professional color system for financial data
  static const Color gainPrimary = Color(0xFF00C896); // Primary gain green
  static const Color gainSecondary = Color(
    0xFF10E78B,
  ); // Secondary gain (lighter)
  static const Color gainBackground = Color(0xFF0A2D20); // Gain background

  static const Color lossPrimary = Color(0xFFFF6B6B); // Primary loss red
  static const Color lossSecondary = Color(
    0xFFFF8E8E,
  ); // Secondary loss (lighter)
  static const Color lossBackground = Color(0xFF2D0A0A); // Loss background

  static const Color neutralPrimary = Color(0xFF8B9DC3); // Neutral/unchanged
  static const Color neutralSecondary = Color(0xFFA5B3D1); // Lighter neutral
  static const Color neutralBackground = Color(
    0xFF1A1F2E,
  ); // Neutral background

  // === INVESTMENT PRODUCT COLORS ===
  // Distinct colors for different investment types
  static const Color bondsColor = Color(0xFF4FC3F7); // Light blue for bonds
  static const Color bondsBackground = Color(0xFF0D1F2A); // Bonds background

  static const Color sharesColor = Color(0xFF66BB6A); // Green for shares
  static const Color sharesBackground = Color(0xFF0F2A14); // Shares background

  static const Color loansColor = Color(0xFFFFB74D); // Orange for loans
  static const Color loansBackground = Color(0xFF2A1A0A); // Loans background

  static const Color apartmentsColor = Color(
    0xFFBA68C8,
  ); // Purple for real estate
  static const Color apartmentsBackground = Color(
    0xFF1F0D2A,
  ); // Apartments background

  static const Color etfColor = Color(0xFF42A5F5); // Blue for ETFs
  static const Color cryptoColor = Color(0xFFFFA726); // Gold for crypto
  static const Color commoditiesColor = Color(
    0xFF8D6E63,
  ); // Brown for commodities

  // === STATUS COLORS ===
  // Professional status indication system
  static const Color successPrimary = Color(0xFF00C896); // Success state
  static const Color successBackground = Color(
    0xFF0A2D20,
  ); // Success background

  static const Color warningPrimary = Color(0xFFFFB300); // Warning state
  static const Color warningBackground = Color(
    0xFF2A2000,
  ); // Warning background

  static const Color errorPrimary = Color(0xFFFF5252); // Error state
  static const Color errorBackground = Color(0xFF2D0A0A); // Error background

  static const Color infoPrimary = Color(0xFF42A5F5); // Info state
  static const Color infoBackground = Color(0xFF0A1A2A); // Info background

  // === BORDER AND DIVIDER COLORS ===
  static const Color borderPrimary = Color(0xFF373E47); // Primary borders
  static const Color borderSecondary = Color(0xFF2F3640); // Secondary borders
  static const Color borderFocus = Color(0xFF415A77); // Focused borders
  static const Color dividerColor = Color(0xFF2A2F36); // Dividers

  // === OVERLAY COLORS ===
  static const Color overlayLight = Color(0x1AFFFFFF); // Light overlay
  static const Color overlayMedium = Color(0x33FFFFFF); // Medium overlay
  static const Color overlayDark = Color(0x80000000); // Dark overlay
  static const Color scrimColor = Color(0xCC000000); // Modal scrim
  static const Color shadowColor = Color(0x26000000); // Shadow color

  // === GRADIENT DEFINITIONS ===
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryLight],
    stops: [0.0, 1.0],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryGold, secondaryCopper],
    stops: [0.0, 1.0],
  );

  static const LinearGradient performanceGainGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [gainBackground, gainPrimary],
    stops: [0.0, 1.0],
  );

  static const LinearGradient performanceLossGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [lossBackground, lossPrimary],
    stops: [0.0, 1.0],
  );

  static const RadialGradient heroGradient = RadialGradient(
    center: Alignment.topLeft,
    radius: 1.5,
    colors: [Color(0xFF1B263B), Color(0xFF0D1B2A), Color(0xFF0A0E13)],
    stops: [0.0, 0.5, 1.0],
  );

  // === MAIN THEME CONFIGURATION ===
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme for light theme
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: textOnPrimary,
        primaryContainer: primaryLight,
        onPrimaryContainer: textPrimary,

        secondary: secondaryGold,
        onSecondary: textOnSecondary,
        secondaryContainer: secondaryCopper,
        onSecondaryContainer: textPrimary,

        tertiary: secondaryAmber,
        onTertiary: textOnSecondary,

        surface: Color(0xFFFFFBFE),
        onSurface: Color(0xFF1C1B1F),
        surfaceVariant: Color(0xFFE7E0EC),
        onSurfaceVariant: Color(0xFF49454F),

        background: Color(0xFFFFFBFE),
        onBackground: Color(0xFF1C1B1F),

        error: Color(0xFFBA1A1A),
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),

        outline: Color(0xFF79747E),
        outlineVariant: Color(0xFFCAC4D0),
        shadow: Colors.black,
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFF313033),
        onInverseSurface: Color(0xFFF4EFF4),
        inversePrimary: Color(0xFFD0BCFF),
      ),

      // Scaffold Background
      scaffoldBackgroundColor: const Color(0xFFFFFBFE),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFBFE),
        foregroundColor: Color(0xFF1C1B1F),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black26,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1C1B1F),
          letterSpacing: -0.5,
        ),
        toolbarTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF49454F),
        ),
        iconTheme: IconThemeData(color: Color(0xFF49454F), size: 24),
        actionsIconTheme: IconThemeData(color: Color(0xFF49454F), size: 24),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: Color(0xFFFFFBFE),
        shadowColor: Colors.black26,
        elevation: 2,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Color(0xFFCAC4D0), width: 0.5),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        onPrimary: textOnPrimary,
        primaryContainer: primaryLight,
        onPrimaryContainer: textPrimary,

        secondary: secondaryGold,
        onSecondary: textOnSecondary,
        secondaryContainer: secondaryCopper,
        onSecondaryContainer: textPrimary,

        tertiary: secondaryAmber,
        onTertiary: textOnSecondary,

        surface: surfaceContainer,
        onSurface: textPrimary,
        surfaceVariant: surfaceCard,
        onSurfaceVariant: textSecondary,

        background: backgroundPrimary,
        onBackground: textPrimary,

        error: errorPrimary,
        onError: textOnPrimary,
        errorContainer: errorBackground,
        onErrorContainer: errorPrimary,

        outline: borderPrimary,
        outlineVariant: borderSecondary,
        shadow: Colors.black,
        scrim: scrimColor,
        inverseSurface: textPrimary,
        onInverseSurface: backgroundPrimary,
        inversePrimary: primaryLight,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: backgroundPrimary,

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundSecondary,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black26,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        toolbarTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        iconTheme: IconThemeData(color: textSecondary, size: 24),
        actionsIconTheme: IconThemeData(color: textSecondary, size: 24),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceCard,
        shadowColor: Colors.black26,
        elevation: 2,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderSecondary, width: 0.5),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textOnPrimary,
          disabledBackgroundColor: surfaceInteractive,
          disabledForegroundColor: textDisabled,
          elevation: 3,
          shadowColor: Colors.black38,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryAccent,
          disabledForegroundColor: textDisabled,
          side: const BorderSide(color: borderPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryGold,
          disabledForegroundColor: textDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.25,
          ),
        ),
      ),

      // Input Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceInteractive,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        // Border Styles
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSecondary, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSecondary, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderFocus, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorPrimary, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorPrimary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSecondary, width: 0.5),
        ),

        // Text Styles
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: borderFocus,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(
          color: textTertiary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        errorStyle: const TextStyle(
          color: errorPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        helperStyle: const TextStyle(
          color: textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),

        // Icons
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),

      // Typography
      textTheme: const TextTheme(
        // Display styles - for major headings
        displayLarge: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -1.0,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.8,
          height: 1.25,
        ),
        displaySmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.6,
          height: 1.3,
        ),

        // Headline styles - for section headers
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.4,
          height: 1.35,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.2,
          height: 1.4,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0,
          height: 1.45,
        ),

        // Title styles - for card titles and important labels
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

        // Body styles - for main content
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

        // Label styles - for small labels and captions
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
          color: textTertiary,
          letterSpacing: 0.5,
          height: 1.4,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: textSecondary, size: 24),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: surfaceElevated,
        iconColor: textSecondary,
        textColor: textPrimary,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),

      // Data Table Theme
      dataTableTheme: DataTableThemeData(
        headingRowColor: MaterialStateProperty.all(surfaceElevated),
        headingRowHeight: 56,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 64,
        columnSpacing: 24,
        horizontalMargin: 16,
        headingTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.2,
        ),
        dataTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          letterSpacing: 0.1,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: borderSecondary, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        selectedColor: primaryLight,
        secondarySelectedColor: secondaryCopper,
        deleteIconColor: textSecondary,
        disabledColor: surfaceCard,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        side: const BorderSide(color: borderSecondary, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textOnPrimary,
        ),
      ),

      // Bottom Navigation Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundSecondary,
        selectedItemColor: secondaryGold,
        unselectedItemColor: textTertiary,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Tab Bar Theme
      tabBarTheme: const TabBarThemeData(
        labelColor: secondaryGold,
        unselectedLabelColor: textTertiary,
        indicatorColor: secondaryGold,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
      ),

      // Dialog Theme
      dialogTheme: const DialogThemeData(
        backgroundColor: backgroundModal,
        elevation: 8,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: borderPrimary, width: 0.5),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.5,
        ),
      ),

      // Snack Bar Theme
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        actionTextColor: secondaryGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        elevation: 6,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: secondaryGold,
        linearTrackColor: surfaceInteractive,
        circularTrackColor: surfaceInteractive,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return secondaryGold;
          }
          return textTertiary;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return secondaryGold.withOpacity(0.3);
          }
          return surfaceInteractive;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return secondaryGold;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(textOnSecondary),
        side: const BorderSide(color: borderPrimary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return secondaryGold;
          }
          return borderPrimary;
        }),
      ),

      // Slider Theme
      sliderTheme: const SliderThemeData(
        activeTrackColor: secondaryGold,
        inactiveTrackColor: surfaceInteractive,
        thumbColor: secondaryGold,
        overlayColor: Color(0x1FD4AF37),
        valueIndicatorColor: primaryColor,
        valueIndicatorTextStyle: TextStyle(
          color: textOnPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // === UTILITY METHODS ===

  /// Returns appropriate color for investment product type
  static Color getProductTypeColor(String productType) {
    switch (productType.toLowerCase()) {
      case 'bonds':
      case 'obligacje':
        return bondsColor;
      case 'shares':
      case 'udziały':
      case 'akcje':
        return sharesColor;
      case 'loans':
      case 'pożyczki':
        return loansColor;
      case 'apartments':
      case 'apartamenty':
      case 'nieruchomości':
        return apartmentsColor;
      case 'etf':
      case 'funds':
      case 'fundusze':
        return etfColor;
      case 'crypto':
      case 'krypto':
        return cryptoColor;
      case 'commodities':
      case 'surowce':
        return commoditiesColor;
      default:
        return primaryAccent;
    }
  }

  /// Returns background color for investment product type
  static Color getProductTypeBackground(String productType) {
    switch (productType.toLowerCase()) {
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
      case 'apartments':
      case 'apartamenty':
      case 'nieruchomości':
        return apartmentsBackground;
      default:
        return surfaceCard;
    }
  }

  /// Returns appropriate color for performance value
  static Color getPerformanceColor(double value) {
    if (value > 0) return gainPrimary;
    if (value < 0) return lossPrimary;
    return neutralPrimary;
  }

  /// Returns background color for performance value
  static Color getPerformanceBackground(double value) {
    if (value > 0) return gainBackground;
    if (value < 0) return lossBackground;
    return neutralBackground;
  }

  /// Returns appropriate color for status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'aktywny':
      case 'completed':
      case 'zakończony':
        return successPrimary;
      case 'pending':
      case 'oczekujący':
      case 'warning':
        return warningPrimary;
      case 'inactive':
      case 'nieaktywny':
      case 'cancelled':
      case 'anulowany':
      case 'error':
        return errorPrimary;
      case 'info':
      case 'informacja':
        return infoPrimary;
      default:
        return neutralPrimary;
    }
  }

  /// Returns appropriate color for risk level
  static Color getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
      case 'niskie':
      case 'bezpieczne':
        return successPrimary;
      case 'medium':
      case 'średnie':
      case 'umiarkowane':
        return warningPrimary;
      case 'high':
      case 'wysokie':
      case 'ryzykowne':
        return errorPrimary;
      case 'very_high':
      case 'bardzo_wysokie':
      case 'spekulacyjne':
        return lossPrimary;
      default:
        return neutralPrimary;
    }
  }

  // === CUSTOM DECORATIONS ===

  /// Premium card decoration with subtle border and shadow
  static BoxDecoration get premiumCardDecoration => BoxDecoration(
    color: surfaceCard,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderSecondary, width: 0.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.15),
        blurRadius: 12,
        offset: const Offset(0, 4),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 6,
        offset: const Offset(0, 2),
        spreadRadius: 0,
      ),
    ],
  );

  /// Elevated surface decoration for important components
  static BoxDecoration get elevatedSurfaceDecoration => BoxDecoration(
    color: surfaceElevated,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: borderPrimary, width: 0.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 2),
        spreadRadius: 0,
      ),
    ],
  );

  /// Investment performance card decoration
  static BoxDecoration getPerformanceCardDecoration(double value) =>
      BoxDecoration(
        color: getPerformanceBackground(value),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: getPerformanceColor(value).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: getPerformanceColor(value).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      );

  /// Product type chip decoration
  static BoxDecoration getProductChipDecoration(String productType) =>
      BoxDecoration(
        color: getProductTypeBackground(productType),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: getProductTypeColor(productType).withOpacity(0.5),
          width: 1,
        ),
      );

  /// Glass morphism effect decoration
  static BoxDecoration get glassMorphismDecoration => BoxDecoration(
    color: surfaceCard.withOpacity(0.8),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderPrimary.withOpacity(0.5), width: 0.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 16,
        offset: const Offset(0, 8),
        spreadRadius: 0,
      ),
    ],
  );

  // === ADDITIONAL COLORS AND DECORATIONS FOR COMPATIBILITY ===

  /// Error color alias for backward compatibility
  static const Color errorColor = errorPrimary;

  /// Success color alias for backward compatibility
  static const Color successColor = successPrimary;

  /// Warning color alias for backward compatibility
  static const Color warningColor = warningPrimary;

  /// Info color alias for backward compatibility
  static const Color infoColor = infoPrimary;

  /// Text hint color alias for backward compatibility
  static const Color textHint = textTertiary;

  /// Gradient decoration for backgrounds
  static BoxDecoration get gradientDecoration => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.circular(16),
  );

  /// Card decoration alias for backward compatibility
  static BoxDecoration get cardDecoration => premiumCardDecoration;
}
