/// 🎨 Service for managing Google Fonts for professional email editor
class FontFamilyService {
  /// Premium Google Fonts for professional communication
  static const List<String> googleFonts = [
    // 📰 Professional & Business
    'Open Sans',
    'Roboto',
    'Lato',
    'Montserrat',
    'Source Sans Pro',
    'Nunito Sans',
    'Inter',
    'Work Sans',
    
    // 📝 Elegant & Readable
    'Merriweather',
    'Playfair Display',
    'Libre Baskerville',
    'Crimson Text',
    
    // 🎨 Modern & Stylish
    'Poppins',
    'Raleway',
    'Ubuntu',
    'Nunito',
    
    // 💼 Corporate & Clean
    'Roboto Condensed',
    'Oswald',
    'Fira Sans',
    'PT Sans',
  ];

  /// All available fonts (Google Fonts only)
  static List<String> get allFonts => googleFonts;

  /// Check if a font is a Google Font
  static bool isGoogleFont(String fontFamily) {
    return googleFonts.contains(fontFamily);
  }

  /// Get CSS font family string with professional fallbacks
  static String getCSSFontFamily(String fontFamily) {
    // Determine appropriate fallback based on font category
    String fallback;
    
    // Serif fonts get serif fallbacks
    if (['Merriweather', 'Playfair Display', 'Libre Baskerville', 'Crimson Text'].contains(fontFamily)) {
      fallback = 'Georgia, "Times New Roman", serif';
    } 
    // All other Google Fonts get sans-serif fallbacks
    else {
      fallback = 'system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif';
    }
    
    // Return font with appropriate quotes and fallbacks
    if (fontFamily.contains(' ')) {
      return '"$fontFamily", $fallback';
    } else {
      return '$fontFamily, $fallback';
    }
  }

  /// Get Google Fonts CSS URL for a font
  static String? getGoogleFontsUrl(String fontFamily) {
    if (!isGoogleFont(fontFamily)) return null;
    
    // Convert font name to URL format
    final urlName = fontFamily.replaceAll(' ', '+');
    return 'https://fonts.googleapis.com/css2?family=$urlName:wght@300;400;500;600;700&display=swap';
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
        if (allFonts.contains(firstFont)) {
          fonts.add(firstFont);
        }
      }
    }
    
    return fonts.toList();
  }

  /// Generate Google Fonts link tags for HTML
  static String generateGoogleFontsHtml(List<String> fonts) {
    final googleFontsList = fonts.where((font) => isGoogleFont(font)).toList();
    if (googleFontsList.isEmpty) return '';

    final urls = googleFontsList.map((font) => getGoogleFontsUrl(font)).where((url) => url != null).toSet();
    return urls.map((url) => '<link href="$url" rel="stylesheet">').join('\n');
  }

  /// Generate Google Fonts CSS imports
  static String generateGoogleFontsCss(List<String> fonts) {
    final googleFontsList = fonts.where((font) => isGoogleFont(font)).toList();
    if (googleFontsList.isEmpty) return '';

    final urls = googleFontsList.map((font) => getGoogleFontsUrl(font)).where((url) => url != null).toSet();
    return urls.map((url) => '@import url("$url");').join('\n');
  }
}