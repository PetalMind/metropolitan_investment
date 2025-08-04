import 'package:flutter/material.dart';

/// Modern Premium Financial Theme for Metropolitan Investment
/// Enhanced with sophisticated gradients, glassmorphism effects, and refined color palette
/// Inspired by cutting-edge fintech platforms with professional gold-dark aesthetic
class AppTheme {
  // === REFINED BRAND COLORS ===
  // Deep, sophisticated navy with enhanced visual depth
  static const Color primaryColor = Color(
    0xFF0A1628,
  ); // Ultra-deep navy - primary brand
  static const Color primaryLight = Color(
    0xFF1A2332,
  ); // Elevated navy surfaces with warmth
  static const Color primaryAccent = Color(
    0xFF2D3E50,
  ); // Medium navy with refined sophistication

  // === PREMIUM GOLD SYSTEM ===
  // Enhanced gold palette with multiple tones for visual hierarchy
  static const Color secondaryGold = Color(0xFFFFD700); // Pure premium gold
  static const Color secondaryCopper = Color(0xFFF4D03F); // Warm copper-gold
  static const Color secondaryAmber = Color(
    0xFFE6B800,
  ); // Rich amber with rose undertones

  // === SOPHISTICATED BACKGROUND PALETTE ===
  // Ultra-deep backgrounds with subtle gradient undertones
  static const Color backgroundPrimary = Color(
    0xFF0B1426,
  ); // Primary deep background with blue tint
  static const Color backgroundSecondary = Color(
    0xFF1A2332,
  ); // Card surfaces with warmth
  static const Color backgroundTertiary = Color(
    0xFF243447,
  ); // Elevated surfaces with depth
  static const Color backgroundModal = Color(
    0xFF2C3E50,
  ); // Modal backgrounds with sophistication

  // === ENHANCED SURFACE COLORS ===
  // Sophisticated surface hierarchy with depth and warmth
  static const Color surfaceContainer = Color(
    0xFF1E2A38,
  ); // Main container surface with sophistication
  static const Color surfaceCard = Color(
    0xFF243447,
  ); // Card surfaces with depth
  static const Color surfaceElevated = Color(
    0xFF2A3A4F,
  ); // Elevated components with presence
  static const Color surfaceInteractive = Color(
    0xFF334155,
  ); // Interactive elements with modern appeal

  // === REFINED TEXT HIERARCHY ===
  // Premium text system with enhanced contrast and readability
  static const Color textPrimary = Color(
    0xFFF8FAFC,
  ); // Ultra-high contrast white
  static const Color textSecondary = Color(
    0xFFE2E8F0,
  ); // High contrast secondary
  static const Color textTertiary = Color(
    0xFFCBD5E1,
  ); // Medium contrast tertiary
  static const Color textDisabled = Color(
    0xFF64748B,
  ); // Disabled state with clarity
  static const Color textOnPrimary = Color(
    0xFFFFFFFF,
  ); // Text on primary surfaces
  static const Color textOnSecondary = Color(
    0xFF1A1A1A,
  ); // Text on secondary/gold surfaces

  // === MODERN INVESTMENT PERFORMANCE COLORS ===
  // Enhanced color system for financial data with visual sophistication
  static const Color gainPrimary = Color(
    0xFF00D7AA,
  ); // Modern gain green with energy
  static const Color gainSecondary = Color(
    0xFF4FFFCB,
  ); // Light gain accent with vitality
  static const Color gainBackground = Color(
    0xFF0D2818,
  ); // Sophisticated gain background

  static const Color lossPrimary = Color(
    0xFFFF4757,
  ); // Modern loss red with clarity
  static const Color lossSecondary = Color(
    0xFFFF7979,
  ); // Light loss accent with warmth
  static const Color lossBackground = Color(
    0xFF2D1B1E,
  ); // Refined loss background

  static const Color neutralPrimary = Color(
    0xFF8B9DC3,
  ); // Neutral with sophistication
  static const Color neutralSecondary = Color(
    0xFFA8B8D8,
  ); // Light neutral with elegance
  static const Color neutralBackground = Color(
    0xFF1E2630,
  ); // Neutral background with depth

  // === ENHANCED INVESTMENT PRODUCT COLORS ===
  // Modern colors for different investment types with visual appeal
  static const Color bondsColor = Color(
    0xFF5DADE2,
  ); // Modern bonds blue with confidence
  static const Color bondsBackground = Color(
    0xFF0F1C2A,
  ); // Sophisticated bonds background

  static const Color sharesColor = Color(
    0xFF58D68D,
  ); // Modern shares green with growth energy
  static const Color sharesBackground = Color(
    0xFF0F2A15,
  ); // Refined shares background

  static const Color loansColor = Color(
    0xFFF39C12,
  ); // Modern loans orange with warmth
  static const Color loansBackground = Color(
    0xFF2A1B0A,
  ); // Elegant loans background

  static const Color apartmentsColor = Color(
    0xFFAB47BC,
  ); // Modern real estate purple with luxury
  static const Color apartmentsBackground = Color(
    0xFF1F0D2A,
  ); // Sophisticated apartments background

  static const Color etfColor = Color(0xFF42A5F5); // Modern ETF blue with trust
  static const Color cryptoColor = Color(
    0xFFFF9500,
  ); // Modern crypto orange with innovation
  static const Color commoditiesColor = Color(
    0xFF8D6E63,
  ); // Refined commodities brown with stability

  // === MODERN STATUS COLORS ===
  // Enhanced status indication system with sophisticated appeal
  static const Color successPrimary = Color(
    0xFF00E676,
  ); // Modern success with vitality
  static const Color successBackground = Color(
    0xFF0D2E1C,
  ); // Sophisticated success background

  static const Color warningPrimary = Color(
    0xFFFFC107,
  ); // Modern warning with clarity
  static const Color warningBackground = Color(
    0xFF2A2000,
  ); // Refined warning background

  static const Color errorPrimary = Color(
    0xFFFF1744,
  ); // Modern error with urgency
  static const Color errorBackground = Color(
    0xFF2D0A0F,
  ); // Sophisticated error background

  static const Color infoPrimary = Color(0xFF2196F3); // Modern info with trust
  static const Color infoBackground = Color(
    0xFF0A1A2D,
  ); // Elegant info background

  // === REFINED BORDER AND DIVIDER COLORS ===
  static const Color borderPrimary = Color(
    0xFF3A4A5C,
  ); // Modern primary borders
  static const Color borderSecondary = Color(
    0xFF2A3441,
  ); // Sophisticated secondary borders
  static const Color borderFocus = Color(
    0xFF4A5A6C,
  ); // Enhanced focused borders
  static const Color dividerColor = Color(
    0xFF2E3A47,
  ); // Modern dividers with depth

  // === ENHANCED OVERLAY COLORS ===
  static const Color overlayLight = Color(0x15FFFFFF); // Refined light overlay
  static const Color overlayMedium = Color(
    0x30FFFFFF,
  ); // Enhanced medium overlay
  static const Color overlayDark = Color(
    0x70000000,
  ); // Sophisticated dark overlay
  static const Color scrimColor = Color(0xE0000000); // Modern modal scrim
  static const Color shadowColor = Color(0x30000000); // Enhanced shadow color

  // === ENHANCED GRADIENT DEFINITIONS ===
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryLight, primaryAccent],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryGold, secondaryCopper, secondaryAmber],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundSecondary, backgroundTertiary],
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
    radius: 2.0,
    colors: [primaryLight, primaryColor, backgroundPrimary],
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [overlayLight, Color(0x10FFFFFF), Color(0x05FFFFFF)],
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

      // App Bar Theme with enhanced styling
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundSecondary,
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
        iconTheme: IconThemeData(color: secondaryGold, size: 24),
        actionsIconTheme: IconThemeData(color: secondaryGold, size: 24),
      ),

      // Enhanced Card Theme
      cardTheme: CardThemeData(
        color: surfaceCard,
        shadowColor: Colors.black38,
        elevation: 8,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderPrimary, width: 1),
        ),
      ),

      // Enhanced Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryGold,
          foregroundColor: textOnSecondary,
          disabledBackgroundColor: surfaceInteractive,
          disabledForegroundColor: textDisabled,
          elevation: 8,
          shadowColor: secondaryGold.withOpacity(0.4),
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
          foregroundColor: secondaryGold,
          disabledForegroundColor: textDisabled,
          side: const BorderSide(color: secondaryGold, width: 2),
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
          foregroundColor: secondaryGold,
          disabledForegroundColor: textDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Enhanced Input Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceInteractive,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),

        // Modern Border Styles
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
          borderSide: const BorderSide(color: secondaryGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorPrimary, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorPrimary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderSecondary, width: 0.5),
        ),

        // Enhanced Text Styles
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: secondaryGold,
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

        // Enhanced Icons
        prefixIconColor: secondaryGold,
        suffixIconColor: secondaryGold,
      ),

      // Enhanced Typography
      textTheme: const TextTheme(
        // Display styles - enhanced for major headings
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

        // Headline styles - enhanced for section headers
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

        // Title styles - enhanced for card titles and important labels
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

        // Body styles - enhanced for main content
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

        // Label styles - enhanced for small labels and captions
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
          color: textTertiary,
          letterSpacing: 0.5,
          height: 1.4,
        ),
      ),

      // Enhanced Icon Theme
      iconTheme: const IconThemeData(color: secondaryGold, size: 24),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // Enhanced List Tile Theme
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: surfaceElevated,
        iconColor: secondaryGold,
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

      // Enhanced Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        selectedColor: secondaryCopper,
        secondarySelectedColor: secondaryAmber,
        deleteIconColor: textSecondary,
        disabledColor: surfaceCard,
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
          color: textOnSecondary,
        ),
      ),

      // Enhanced Bottom Navigation Theme
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

      // Enhanced Tab Bar Theme
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

      // Enhanced Dialog Theme
      dialogTheme: const DialogThemeData(
        backgroundColor: backgroundModal,
        elevation: 8,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: borderPrimary, width: 1),
        ),
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.5,
        ),
      ),

      // Enhanced Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        actionTextColor: secondaryGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
      ),

      // Enhanced Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: secondaryGold,
        linearTrackColor: surfaceInteractive,
        circularTrackColor: surfaceInteractive,
      ),

      // Enhanced Switch Theme
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

      // Enhanced Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return secondaryGold;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(textOnSecondary),
        side: const BorderSide(color: borderPrimary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),

      // Enhanced Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return secondaryGold;
          }
          return borderPrimary;
        }),
      ),

      // Enhanced Slider Theme
      sliderTheme: const SliderThemeData(
        activeTrackColor: secondaryGold,
        inactiveTrackColor: surfaceInteractive,
        thumbColor: secondaryGold,
        overlayColor: Color(0x1FFFD700),
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

  // === PREMIUM DECORATIONS ===

  /// Ultra-premium card decoration with enhanced shadows and glassmorphism
  static BoxDecoration get premiumCardDecoration => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: borderPrimary, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 20,
        offset: const Offset(0, 8),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: secondaryGold.withOpacity(0.05),
        blurRadius: 15,
        offset: const Offset(0, 4),
        spreadRadius: 0,
      ),
    ],
  );

  /// Modern elevated surface decoration with sophisticated styling
  static BoxDecoration get elevatedSurfaceDecoration => BoxDecoration(
    color: surfaceElevated,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderSecondary, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.25),
        blurRadius: 12,
        offset: const Offset(0, 6),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: secondaryGold.withOpacity(0.03),
        blurRadius: 8,
        offset: const Offset(0, 2),
        spreadRadius: 0,
      ),
    ],
  );

  /// Enhanced investment performance card decoration with glow effects
  static BoxDecoration getPerformanceCardDecoration(double value) =>
      BoxDecoration(
        color: getPerformanceBackground(value),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: getPerformanceColor(value).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: getPerformanceColor(value).withOpacity(0.2),
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

  /// Enhanced product type chip decoration with modern styling
  static BoxDecoration getProductChipDecoration(String productType) =>
      BoxDecoration(
        color: getProductTypeBackground(productType),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: getProductTypeColor(productType).withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: getProductTypeColor(productType).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
      );

  /// Modern glassmorphism effect decoration
  static BoxDecoration get glassMorphismDecoration => BoxDecoration(
    gradient: glassGradient,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: borderPrimary.withOpacity(0.3), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, 10),
        spreadRadius: 0,
      ),
    ],
  );

  // === ENHANCED COLORS AND DECORATIONS FOR COMPATIBILITY ===

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

  /// Enhanced gradient decoration for backgrounds
  static BoxDecoration get gradientDecoration => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.circular(20),
  );

  /// Card decoration alias for backward compatibility
  static BoxDecoration get cardDecoration => premiumCardDecoration;

  /// Modern gold accent decoration with sophisticated appeal
  static BoxDecoration get goldAccentDecoration => BoxDecoration(
    gradient: goldGradient,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: secondaryGold.withOpacity(0.3),
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

  /// Interactive surface decoration with hover effects
  static BoxDecoration get interactiveDecoration => BoxDecoration(
    color: surfaceInteractive,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: borderFocus, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.15),
        blurRadius: 8,
        offset: const Offset(0, 2),
        spreadRadius: 0,
      ),
    ],
  );
}
