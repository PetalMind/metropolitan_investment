/// 🎨 Service for managing Local Fonts for professional email editor
class FontFamilyService {
  /// Premium Local Fonts for professional communication
  static const List<String> localFonts = [
    // 📰 Professional & Business
    'OpenSans',
    'Roboto',
    'Lato',
    'Montserrat',
    'SourceSans3',
    'NunitoSans',
    'Inter',
    'WorkSans',
    
    // 📝 Elegant & Readable
    'Merriweather',
    'PlayfairDisplay',
    'LibreBaskerville',
    'CrimsonText',
    
    // 🎨 Modern & Stylish
    'Poppins',
    'Raleway',
    'Ubuntu',
    'Nunito',
    
    // 💼 Corporate & Clean
    'RobotoCondensed',
    'Oswald',
    'FiraSans',
    'PTSans',
  ];

  /// Font display names mapping for better user experience
  static const Map<String, String> fontDisplayNames = {
    'OpenSans': 'Open Sans',
    'Roboto': 'Roboto',
    'Lato': 'Lato',
    'Montserrat': 'Montserrat',
    'SourceSans3': 'Source Sans Pro',
    'NunitoSans': 'Nunito Sans',
    'Inter': 'Inter',
    'WorkSans': 'Work Sans',
    'Merriweather': 'Merriweather',
    'PlayfairDisplay': 'Playfair Display',
    'LibreBaskerville': 'Libre Baskerville',
    'CrimsonText': 'Crimson Text',
    'Poppins': 'Poppins',
    'Raleway': 'Raleway',
    'Ubuntu': 'Ubuntu',
    'Nunito': 'Nunito',
    'RobotoCondensed': 'Roboto Condensed',
    'Oswald': 'Oswald',
    'FiraSans': 'Fira Sans',
    'PTSans': 'PT Sans',
  };

  /// All available fonts (Local Fonts only)
  static List<String> get allFonts => localFonts;

  /// Get display name for a font
  static String getDisplayName(String fontFamily) {
    return fontDisplayNames[fontFamily] ?? fontFamily;
  }

  /// Check if a font is a local font
  static bool isLocalFont(String fontFamily) {
    return localFonts.contains(fontFamily) ||
        fontDisplayNames.containsValue(fontFamily);
  }

  /// Convert display name to Flutter font family name
  static String getFlutterFontFamily(String displayName) {
    for (final entry in fontDisplayNames.entries) {
      if (entry.value == displayName) {
        return entry.key;
      }
    }
    return displayName.replaceAll(' ', '');
  }

  /// Get CSS font family string with professional fallbacks
  static String getCSSFontFamily(String fontFamily) {
    // Convert display name to Flutter font family if needed
    final flutterFontFamily = getFlutterFontFamily(fontFamily);
    
    // Determine appropriate fallback based on font category
    String fallback;
    
    // Serif fonts get serif fallbacks
    if ([
      'Merriweather',
      'PlayfairDisplay',
      'LibreBaskerville',
      'CrimsonText',
    ].contains(flutterFontFamily)) {
      fallback = 'Georgia, "Times New Roman", serif';
    } 
    // All other local fonts get sans-serif fallbacks
    else {
      fallback = 'system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif';
    }
    
    // Return font with appropriate quotes and fallbacks
    final displayName = getDisplayName(flutterFontFamily);
    if (displayName.contains(' ')) {
      return '"$displayName", $fallback';
    } else {
      return '$displayName, $fallback';
    }
  }

  /// Extract fonts from HTML content
  static List<String> extractFontsFromHtml(String html) {
    final fonts = <String>{};
    // Use a simpler regex to extract font-family values
    final regex = RegExp(r'font-family:\s*([^;]+)', caseSensitive: false);
    final matches = regex.allMatches(html);
    
    for (final match in matches) {
      final fontFamily = match.group(1);
      if (fontFamily != null) {
        // Extract the first font from the font stack and clean quotes
        var firstFont = fontFamily.split(',').first.trim();
        // Remove quotes
        firstFont = firstFont.replaceAll('"', '').replaceAll("'", '');
        
        // Check if it's a display name and convert to Flutter font family
        final flutterFontFamily = getFlutterFontFamily(firstFont);
        if (allFonts.contains(flutterFontFamily)) {
          fonts.add(flutterFontFamily);
        }
      }
    }
    
    return fonts.toList();
  }

  /// Generate CSS @font-face declarations for local fonts
  static String generateLocalFontsCss(List<String> fonts) {
    final localFontsList = fonts.where((font) => isLocalFont(font)).toList();
    if (localFontsList.isEmpty) return '';

    final cssDeclarations = <String>[];

    for (final font in localFontsList) {
      final displayName = getDisplayName(font);
      // Add CSS for common weights available for most fonts
      final weights = [300, 400, 500, 600, 700];
      
      for (final weight in weights) {
        cssDeclarations.add('''
@font-face {
  font-family: "$displayName";
  font-weight: $weight;
  font-style: normal;
  font-display: swap;
  /* Local font - loaded from app assets */
}''');
      }
    }
    
    return cssDeclarations.join('\n');
  }

  /// Generate font CSS for HTML emails (no actual @font-face needed for local fonts in Flutter)
  static String generateFontsCssForEmail(List<String> fonts) {
    // For email, we'll use web-safe fallbacks since local fonts won't work in email clients
    return '';
  }
}