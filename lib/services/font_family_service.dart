/// 🎨 Service for managing font families with web-safe vs Google Fonts distinction
class FontFamilyService {
  /// Web-safe fonts that don't require external loading
  static const List<String> webSafeFonts = [
    'Arial',
    'Times New Roman',
    'Courier New',
    'Verdana',
    'Georgia',
    'Trebuchet MS',
    'Tahoma',
    'Calibri',
    'Segoe UI',
    'Helvetica',
  ];

  /// Google Fonts that require external loading
  static const List<String> googleFonts = [
    'Open Sans',
    'Roboto',
    'Lato',
    'Montserrat',
  ];

  /// All available fonts
  static List<String> get allFonts => [...webSafeFonts, ...googleFonts];

  /// Check if a font is web-safe
  static bool isWebSafeFont(String fontFamily) {
    return webSafeFonts.contains(fontFamily);
  }

  /// Check if a font is a Google Font
  static bool isGoogleFont(String fontFamily) {
    return googleFonts.contains(fontFamily);
  }

  /// Get CSS font family string with fallbacks
  static String getCSSFontFamily(String fontFamily) {
    switch (fontFamily) {
      case 'Arial':
        return 'Arial, "Helvetica Neue", Helvetica, sans-serif';
      case 'Times New Roman':
        return '"Times New Roman", Times, serif';
      case 'Courier New':
        return '"Courier New", Courier, monospace';
      case 'Verdana':
        return 'Verdana, Geneva, sans-serif';
      case 'Georgia':
        return 'Georgia, "Times New Roman", Times, serif';
      case 'Trebuchet MS':
        return '"Trebuchet MS", "Lucida Grande", "Lucida Sans Unicode", "Lucida Sans", Tahoma, sans-serif';
      case 'Tahoma':
        return 'Tahoma, Geneva, sans-serif';
      case 'Calibri':
        return 'Calibri, "Helvetica Neue", Arial, sans-serif';
      case 'Segoe UI':
        return '"Segoe UI", "Roboto", "Oxygen", "Ubuntu", "Cantarell", "Fira Sans", "Droid Sans", "Helvetica Neue", sans-serif';
      case 'Helvetica':
        return 'Helvetica, "Helvetica Neue", Arial, sans-serif';
      case 'Open Sans':
        return '"Open Sans", "Helvetica Neue", Arial, sans-serif';
      case 'Roboto':
        return 'Roboto, "Helvetica Neue", Arial, sans-serif';
      case 'Lato':
        return 'Lato, "Helvetica Neue", Arial, sans-serif';
      case 'Montserrat':
        return 'Montserrat, "Helvetica Neue", Arial, sans-serif';
      default:
        return '$fontFamily, Arial, sans-serif';
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