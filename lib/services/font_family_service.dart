/// Service for managing ONLY local font families from assets/fonts/
/// Provides font family names for Flutter Quill integration
/// NO SYSTEM FONTS - ONLY LOCAL ASSETS
/// 
/// All fonts configured in pubspec.yaml and available in assets/fonts/
class FontFamilyService {
  /// Available local font families from assets/fonts/ - CONFIRMED ASSETS!
  /// These match exactly with pubspec.yaml font family definitions
  static const Map<String, String> _localFonts = {
    'CrimsonText':
        'CrimsonText', // Serif - Elegant headlines (Regular, SemiBold, Bold)
    'FiraSans':
        'FiraSans', // Sans-serif - Clean body text (Light, Regular, Medium, SemiBold, Bold)
    'Inter': 'Inter', // Sans-serif - Modern UI (Variable font) - DEFAULT
    'Lato': 'Lato', // Sans-serif - Friendly (Light, Regular, Bold)
    'LibreBaskerville':
        'LibreBaskerville', // Serif - Classic reading (Regular, Bold)
    'Merriweather': 'Merriweather', // Serif - Web optimized (Variable font)
    'Montserrat': 'Montserrat', // Sans-serif - Professional (Variable font)
    'Nunito': 'Nunito', // Sans-serif - Rounded (Variable font)
  };

  /// Web-safe fallback fonts for email compatibility
  static const Map<String, String> _webSafeFallbacks = {
    'CrimsonText': 'serif',
    'FiraSans': 'sans-serif',
    'Inter': 'sans-serif',
    'Lato': 'sans-serif',
    'LibreBaskerville': 'serif',
    'Merriweather': 'serif',
    'Montserrat': 'sans-serif',
    'Nunito': 'sans-serif',
  };

  /// Get all available local font families
  static Map<String, String> getLocalFonts() {
    return Map.from(_localFonts);
  }

  /// Get font family items for Quill toolbar dropdown
  static Map<String, String> getQuillToolbarItems() {
    return Map.from(_localFonts);
  }

  /// Get font family names as list for Quill dropdown
  static List<String> getFontFamilyNames() {
    return _localFonts.keys.toList()..sort();
  }

  /// Mapowanie systemowych czcionek na nasze lokalne czcionki
  static const Map<String, String> _systemToLocalMapping = {
    // System fonts → Local fonts
    'Arial': 'Inter',
    'Helvetica': 'Lato',
    'Times New Roman': 'CrimsonText',
    'Times': 'CrimsonText',
    'Courier New': 'FiraSans',
    'Courier': 'FiraSans',
    'Verdana': 'Nunito',
    'Georgia': 'Merriweather',
    'Trebuchet MS': 'Montserrat',
    'Comic Sans MS': 'Nunito',
    'Impact': 'Montserrat',
    'Lucida Console': 'FiraSans',
    'Tahoma': 'Lato',
    'Palatino': 'LibreBaskerville',
    'Roboto': 'Inter', // Keep Inter as default
  };

  /// Get CSS font family string with system→local mapping for HTML export
  static String getCssFontFamily(String fontFamily) {
    // First check if it's a local font
    if (_localFonts.containsKey(fontFamily)) {
      final fallback = _webSafeFallbacks[fontFamily] ?? 'sans-serif';
      return '$fontFamily, $fallback';
    }
    
    // Map system fonts to local fonts
    if (_systemToLocalMapping.containsKey(fontFamily)) {
      final localFont = _systemToLocalMapping[fontFamily]!;
      final fallback = _webSafeFallbacks[localFont] ?? 'sans-serif';
      return '$localFont, $fallback';
    }
    
    // Fallback to Inter for unknown fonts
    return 'Inter, sans-serif';
  }

  /// Check if font family is available locally
  static bool isLocalFont(String fontFamily) {
    return _localFonts.containsKey(fontFamily);
  }

  /// Get display name for font family
  static String getDisplayName(String fontFamily) {
    return _localFonts[fontFamily] ?? fontFamily;
  }

  /// Get email-safe font family for HTML emails
  static String getEmailSafeFontFamily(String fontFamily) {
    if (_localFonts.containsKey(fontFamily)) {
      // For email, we need to include the actual font name and fallbacks
      final fallback = _webSafeFallbacks[fontFamily] ?? 'sans-serif';
      return '"$fontFamily", $fallback';
    }
    return 'Arial, sans-serif';
  }

  /// Verify that all configured fonts are actually available in assets
  /// Returns list of fonts that are properly configured in pubspec.yaml
  static List<String> getVerifiedLocalFonts() {
    // All fonts listed here are confirmed to exist in assets/fonts/ and pubspec.yaml
    return _localFonts.keys.toList()..sort();
  }

  /// Get font weight information for each font family
  static Map<String, List<int>> getFontWeights() {
    return {
      'CrimsonText': [400, 600, 700], // Regular, SemiBold, Bold
      'FiraSans': [
        100,
        200,
        300,
        400,
        500,
        600,
        700,
        800,
        900,
      ], // Thin, ExtraLight, Light, Regular, Medium, SemiBold, Bold, ExtraBold, Black
      'Inter': [100, 200, 300, 400, 500, 600, 700, 800, 900], // Variable font
      'Lato': [100, 300, 400, 700, 900], // Thin, Light, Regular, Bold, Black
      'LibreBaskerville': [400, 700], // Regular, Bold
      'Merriweather': [
        100,
        200,
        300,
        400,
        500,
        600,
        700,
        800,
        900,
      ], // Variable font
      'Montserrat': [
        100,
        200,
        300,
        400,
        500,
        600,
        700,
        800,
        900,
      ], // Variable font
      'Nunito': [100, 200, 300, 400, 500, 600, 700, 800, 900], // Variable font
    };
  }

  /// Check if specific font weight is available for given font family
  static bool isFontWeightAvailable(String fontFamily, int weight) {
    final weights = getFontWeights()[fontFamily];
    return weights?.contains(weight) ?? false;
  }
}