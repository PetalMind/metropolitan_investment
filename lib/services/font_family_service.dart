/// Service for managing ONLY local font families from assets/fonts/
/// Provides font family names for Flutter Quill integration
/// NO SYSTEM FONTS - ONLY LOCAL ASSETS
class FontFamilyService {
  /// Available local font families from assets/fonts/ - ONLY THESE!
  static const Map<String, String> _localFonts = {
    'CrimsonText': 'CrimsonText',           // Serif - Elegant headlines
    'FiraSans': 'FiraSans',                 // Sans-serif - Clean body text  
    'Inter': 'Inter',                       // Sans-serif - Modern UI
    'Lato': 'Lato',                         // Sans-serif - Friendly
    'LibreBaskerville': 'LibreBaskerville', // Serif - Classic reading
    'Merriweather': 'Merriweather',         // Serif - Web optimized
    'Montserrat': 'Montserrat',             // Sans-serif - Professional
    'Nunito': 'Nunito',                     // Sans-serif - Rounded
    'NunitoSans': 'NunitoSans',             // Sans-serif - Extended family
    'Oswald': 'Oswald',                     // Sans-serif - Condensed
    'Raleway': 'Raleway',                   // Sans-serif - Elegant thin
    'Roboto': 'Roboto',                     // Sans-serif - Material Design
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
    'NunitoSans': 'sans-serif',
    'Oswald': 'sans-serif',
    'Raleway': 'sans-serif',
    'Roboto': 'sans-serif',
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
    'Impact': 'Oswald',
    'Lucida Console': 'Roboto',
    'Tahoma': 'NunitoSans',
    'Palatino': 'LibreBaskerville',
    'Roboto': 'Roboto', // Keep Roboto as is
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
}