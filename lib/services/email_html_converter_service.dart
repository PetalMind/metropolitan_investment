import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import '../models_and_services.dart';

/// 🎨 Service responsible for converting Quill content to HTML
/// Extracted from WowEmailEditorScreen for better separation of concerns
class EmailHtmlConverterService {
  static String get defaultFont => 'Arial';

  /// Enhanced font sizes with complete range
  static const Map<String, String> fontSizes = {
    'Bardzo mały (10px)': '10',
    'Mały (12px)': '12',
    'Normalny (14px)': '14',
    'Średni (16px)': '16',
    'Duży (18px)': '18',
    'Większy (20px)': '20',
    'Duży nagłówek (24px)': '24',
    'Bardzo duży (28px)': '28',
    'Ogromny (32px)': '32',
    'Gigantyczny (36px)': '36',
    'Maksymalny (48px)': '48',
  };

  /// Get CSS font family with fallbacks
  static String getCssFontFamily(String fontName) {
    return FontFamilyService.getCssFontFamily(fontName);
  }

  /// Convert Quill controller content to HTML for preview (without full document structure)
  static String convertQuillToHtmlForPreview(QuillController controller) {
    try {
      debugPrint('🔄 Starting HTML conversion for preview...');
      debugPrint('📊 Document length: ${controller.document.length}');

      final plainText = controller.document.toPlainText();
      debugPrint('📄 Plain text: "$plainText"');
      debugPrint('📄 Plain text length: ${plainText.length}');

      // If document is essentially empty, return formatted empty content
      if (controller.document.length <= 1 || plainText.trim().isEmpty) {
        debugPrint('📭 Document is empty, returning placeholder');
        return '<div style="font-family: Arial, sans-serif; font-size: 16px; line-height: 1.6; color: #666; font-style: italic;"><p>Wpisz treść wiadomości...</p></div>';
      }

      debugPrint('🔄 Converting delta to HTML for preview...');
      final deltaJson = controller.document.toDelta().toJson();
      debugPrint('📋 Delta JSON: $deltaJson');

      final converter = QuillDeltaToHtmlConverter(
        deltaJson,
        ConverterOptions(
          converterOptions: OpConverterOptions(
            inlineStylesFlag: true,
            allowBackgroundClasses: false,
            paragraphTag: 'p',
            inlineStyles: _buildInlineStyles(),
          ),
        ),
      );

      final htmlOutput = converter.convert();
      debugPrint(
        '✅ HTML conversion for preview successful: ${htmlOutput.length} characters',
      );
      debugPrint(
        '🎨 Preview HTML: ${htmlOutput.substring(0, htmlOutput.length > 200 ? 200 : htmlOutput.length)}...',
      );

      // For preview, return just the content without full document structure
      return htmlOutput;
    } catch (e) {
      debugPrint('⚠️ HTML conversion for preview error: $e');
      final plainText = controller.document.toPlainText();
      const defaultFontFamily = 'Arial, sans-serif';
      final fallbackHtml =
          '<div style="font-family: $defaultFontFamily !important; font-size: 16px; line-height: 1.6;"><p>${plainText.isNotEmpty ? plainText.replaceAll('\n', '<br>') : 'Błąd konwersji HTML'}</p></div>';
      debugPrint('🔄 Returning fallback HTML for preview: $fallbackHtml');
      return fallbackHtml;
    }
  }

  /// Convert Quill controller content to HTML with enhanced formatting support
  static String convertQuillToHtml(QuillController controller) {
    try {
      debugPrint('🔄 Starting HTML conversion...');
      debugPrint('📊 Document length: ${controller.document.length}');
      
      final plainText = controller.document.toPlainText();
      debugPrint('📄 Plain text: "$plainText"');
      debugPrint('📄 Plain text length: ${plainText.length}');

      // If document is essentially empty, return formatted empty content
      if (controller.document.length <= 1 || plainText.trim().isEmpty) {
        debugPrint('📭 Document is empty, returning placeholder');
        return '<div style="font-family: Arial, sans-serif; font-size: 16px; line-height: 1.6; color: #666; font-style: italic;"><p>Wpisz treść wiadomości...</p></div>';
      }

      debugPrint('🔄 Converting delta to HTML...');
      final deltaJson = controller.document.toDelta().toJson();
      debugPrint('📋 Delta JSON: $deltaJson');
      
      final converter = QuillDeltaToHtmlConverter(
        deltaJson,
        ConverterOptions(
          converterOptions: OpConverterOptions(
            inlineStylesFlag: true,
            allowBackgroundClasses: false,
            paragraphTag: 'p',
            inlineStyles: _buildInlineStyles(),
          ),
        ),
      );

      final htmlOutput = converter.convert();
      debugPrint(
        '✅ HTML conversion successful: ${htmlOutput.length} characters',
      );
      debugPrint(
        '🎨 Raw HTML: ${htmlOutput.substring(0, htmlOutput.length > 200 ? 200 : htmlOutput.length)}...',
      );

      final finalHtml = _enhanceHtmlWithEmailCompatibility(htmlOutput);
      debugPrint('🚀 Final HTML: ${finalHtml.length} characters');

      return finalHtml;
    } catch (e) {
      debugPrint('⚠️ HTML conversion error: $e');
      final plainText = controller.document.toPlainText();
      const defaultFontFamily = 'Arial, sans-serif';
      final fallbackHtml =
          '<div style="font-family: $defaultFontFamily !important; font-size: 16px; line-height: 1.6;"><p>${plainText.isNotEmpty ? plainText.replaceAll('\n', '<br>') : 'Błąd konwersji HTML'}</p></div>';
      debugPrint('🔄 Returning fallback HTML: $fallbackHtml');
      return fallbackHtml;
    }
  }

  /// Build comprehensive inline styles for email compatibility
  static InlineStyles _buildInlineStyles() {
    return InlineStyles({
      'bold': InlineStyleType(fn: (value, _) => 'font-weight: bold !important'),
      'italic': InlineStyleType(fn: (value, _) => 'font-style: italic !important'),
      'underline': InlineStyleType(
        fn: (value, _) => 'text-decoration: underline !important',
      ),
      'strike': InlineStyleType(
        fn: (value, _) => 'text-decoration: line-through !important',
      ),
      'color': InlineStyleType(
        fn: (value, _) => _convertColorAttribute(value),
      ),
      'background': InlineStyleType(
        fn: (value, _) => _convertBackgroundAttribute(value),
      ),
      'font': InlineStyleType(
        fn: (value, _) => _convertFontAttribute(value),
      ),
      'font-family': InlineStyleType(
        fn: (value, _) => _convertFontAttribute(value),
      ),
      'size': InlineStyleType(
        fn: (value, _) => _convertSizeAttribute(value),
      ),
      'align': InlineStyleType(
        fn: (value, _) => _convertAlignAttribute(value),
      ),
      'list': InlineStyleType(
        fn: (value, _) => 'margin-left: 20px; padding-left: 10px;',
      ),
      'indent': InlineStyleType(
        fn: (value, _) => _convertIndentAttribute(value),
      ),
      'link': InlineStyleType(
        fn: (value, _) => 'color: #0066cc !important; text-decoration: underline !important;',
      ),
      'line-height': InlineStyleType(
        fn: (value, _) => 'line-height: $value !important',
      ),
      'letter-spacing': InlineStyleType(
        fn: (value, _) => 'letter-spacing: $value !important',
      ),
      // 🎨 Extended formatting support
      'header': InlineStyleType(
        fn: (value, _) => _convertHeaderAttribute(value),
      ),
      'blockquote': InlineStyleType(
        fn: (value, _) => _convertBlockquoteAttribute(value),
      ),
      'code-block': InlineStyleType(
        fn: (value, _) => _convertCodeBlockAttribute(value),
      ),
      'script': InlineStyleType(
        fn: (value, _) => _convertScriptAttribute(value),
      ),
      'direction': InlineStyleType(
        fn: (value, _) => 'direction: $value !important',
      ),
      'font-weight': InlineStyleType(
        fn: (value, _) => _convertFontWeightAttribute(value),
      ),
      'font-size': InlineStyleType(
        fn: (value, _) => _convertSizeAttribute(value),
      ),
      'text-align': InlineStyleType(
        fn: (value, _) => _convertAlignAttribute(value),
      ),
    });
  }

  /// Convert color attribute with proper validation and email client compatibility
  static String? _convertColorAttribute(dynamic value) {
    if (value.toString().isEmpty) return null;
    String colorValue = value.toString().trim();
    debugPrint('🎨 Converting color: $colorValue');
    
    // Handle hex colors with #
    if (colorValue.startsWith('#')) {
      if (RegExp(r'^#[0-9a-fA-F]{3}$').hasMatch(colorValue)) {
        // Convert 3-digit hex to 6-digit for better email client support
        final r = colorValue[1];
        final g = colorValue[2];
        final b = colorValue[3];
        colorValue = '#$r$r$g$g$b$b';
      } else if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(colorValue)) {
        // Invalid hex, fallback to black
        colorValue = '#000000';
      }
      return 'color: $colorValue !important';
    }
    
    // Handle hex without # prefix
    if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(colorValue)) {
      return 'color: #$colorValue !important';
    }
    if (RegExp(r'^[0-9a-fA-F]{3}$').hasMatch(colorValue)) {
      final r = colorValue[0];
      final g = colorValue[1];
      final b = colorValue[2];
      return 'color: #$r$r$g$g$b$b !important';
    }
    
    // Handle RGB format
    if (RegExp(r'^rgb\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)$').hasMatch(colorValue)) {
      return 'color: $colorValue !important';
    }
    
    // Handle RGBA format - convert to RGB for email compatibility
    final rgbaMatch = RegExp(r'^rgba\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*[\d.]+\s*\)$').firstMatch(colorValue);
    if (rgbaMatch != null) {
      final r = rgbaMatch.group(1);
      final g = rgbaMatch.group(2);
      final b = rgbaMatch.group(3);
      return 'color: rgb($r, $g, $b) !important';
    }
    
    // Handle HSL format - convert to standard named color or fallback
    if (colorValue.startsWith('hsl(')) {
      // For email compatibility, we'll use a fallback
      debugPrint('⚠️ HSL color converted to fallback black for email compatibility');
      return 'color: #000000 !important';
    }
    
    // Handle named colors (CSS color names)
    final namedColors = {
      'black': '#000000', 'white': '#ffffff', 'red': '#ff0000', 'green': '#008000', 'blue': '#0000ff',
      'yellow': '#ffff00', 'orange': '#ffa500', 'purple': '#800080', 'pink': '#ffc0cb', 'brown': '#a52a2a',
      'gray': '#808080', 'grey': '#808080', 'silver': '#c0c0c0', 'gold': '#ffd700', 'navy': '#000080',
      'teal': '#008080', 'lime': '#00ff00', 'aqua': '#00ffff', 'maroon': '#800000', 'olive': '#808000'
    };
    
    final lowerColor = colorValue.toLowerCase();
    if (namedColors.containsKey(lowerColor)) {
      return 'color: ${namedColors[lowerColor]} !important';
    }
    
    // Fallback for any unrecognized format
    debugPrint('⚠️ Unrecognized color format: $colorValue, using fallback black');
    return 'color: #000000 !important';
  }

  /// Convert background color attribute with enhanced email client compatibility
  static String? _convertBackgroundAttribute(dynamic value) {
    if (value.toString().isEmpty) return null;
    String colorValue = value.toString().trim();
    debugPrint('🎨 Converting background: $colorValue');
    
    // Handle hex colors with #
    if (colorValue.startsWith('#')) {
      if (RegExp(r'^#[0-9a-fA-F]{3}$').hasMatch(colorValue)) {
        // Convert 3-digit hex to 6-digit for better email client support
        final r = colorValue[1];
        final g = colorValue[2];
        final b = colorValue[3];
        colorValue = '#$r$r$g$g$b$b';
      } else if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(colorValue)) {
        // Invalid hex, fallback to transparent
        colorValue = 'transparent';
      }
      return 'background-color: $colorValue !important';
    }
    
    // Handle hex without # prefix
    if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(colorValue)) {
      return 'background-color: #$colorValue !important';
    }
    if (RegExp(r'^[0-9a-fA-F]{3}$').hasMatch(colorValue)) {
      final r = colorValue[0];
      final g = colorValue[1];
      final b = colorValue[2];
      return 'background-color: #$r$r$g$g$b$b !important';
    }
    
    // Handle RGB format
    if (RegExp(r'^rgb\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)$').hasMatch(colorValue)) {
      return 'background-color: $colorValue !important';
    }
    
    // Handle RGBA format - convert to RGB for email compatibility
    final rgbaMatch = RegExp(r'^rgba\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*[\d.]+\s*\)$').firstMatch(colorValue);
    if (rgbaMatch != null) {
      final r = rgbaMatch.group(1);
      final g = rgbaMatch.group(2);
      final b = rgbaMatch.group(3);
      debugPrint('🎨 Converting RGBA to RGB for background color compatibility');
      return 'background-color: rgb($r, $g, $b) !important';
    }
    
    // Handle HSL format - convert to fallback transparent
    if (colorValue.startsWith('hsl(')) {
      debugPrint('⚠️ HSL background color converted to transparent for email compatibility');
      return 'background-color: transparent !important';
    }
    
    // Handle named colors (CSS color names)
    final namedColors = {
      'black': '#000000', 'white': '#ffffff', 'red': '#ff0000', 'green': '#008000', 'blue': '#0000ff',
      'yellow': '#ffff00', 'orange': '#ffa500', 'purple': '#800080', 'pink': '#ffc0cb', 'brown': '#a52a2a',
      'gray': '#808080', 'grey': '#808080', 'silver': '#c0c0c0', 'gold': '#ffd700', 'navy': '#000080',
      'teal': '#008080', 'lime': '#00ff00', 'aqua': '#00ffff', 'maroon': '#800000', 'olive': '#808000',
      'transparent': 'transparent'
    };
    
    final lowerColor = colorValue.toLowerCase();
    if (namedColors.containsKey(lowerColor)) {
      return 'background-color: ${namedColors[lowerColor]} !important';
    }
    
    // Fallback for any unrecognized format
    debugPrint('⚠️ Unrecognized background color format: $colorValue, using fallback transparent');
    return 'background-color: transparent !important';
  }

  /// Convert font attribute with fallbacks
  static String? _convertFontAttribute(dynamic value) {
    if (value.toString().isEmpty) return null;
    
    final fontName = value.toString();
    final cssFontFamily = getCssFontFamily(fontName);
    
    debugPrint('🎨 Using font: $fontName with fallbacks');
    
    debugPrint('🎨 Converting font to HTML: $fontName → $cssFontFamily');
    return 'font-family: $cssFontFamily !important';
  }

  /// Convert size attribute with comprehensive handling
  static String? _convertSizeAttribute(dynamic value) {
    if (value.toString().isEmpty) return null;
    
    final sizeValue = value.toString();
    debugPrint('🎨 Converting size: $sizeValue');

    // Handle predefined sizes from fontSizes map
    if (fontSizes.containsKey(sizeValue)) {
      final size = fontSizes[sizeValue]!;
      debugPrint('🎨 Found predefined size: $sizeValue → ${size}px');
      return 'font-size: ${size}px !important';
    }

    // Extract number from formatted value like "Normalny (14px)"
    final sizeMatch = RegExp(r'\((\d+)px\)').firstMatch(sizeValue);
    if (sizeMatch != null) {
      final size = sizeMatch.group(1)!;
      debugPrint('🎨 Extracted size from format: $sizeValue → ${size}px');
      return 'font-size: ${size}px !important';
    }

    // Handle plain numbers
    if (RegExp(r'^\d+$').hasMatch(sizeValue)) {
      debugPrint('🎨 Plain number size: $sizeValue → ${sizeValue}px');
      return 'font-size: ${sizeValue}px !important';
    }

    // Handle sizes with units
    if (RegExp(r'^\d+(\.\d+)?(px|pt|em|rem|%)$').hasMatch(sizeValue)) {
      debugPrint('🎨 Size with unit: $sizeValue');
      return 'font-size: $sizeValue !important';
    }

    // Fallback
    debugPrint('🎨 Fallback size: $sizeValue');
    return 'font-size: $sizeValue !important';
  }

  /// Convert alignment attribute
  static String? _convertAlignAttribute(dynamic value) {
    if (value.toString().isEmpty) return null;
    debugPrint('🎨 Converting alignment: $value');
    
    const validAlignments = ['left', 'center', 'right', 'justify'];
    final alignment = validAlignments.contains(value.toString()) 
        ? value.toString() 
        : 'left';
    return 'text-align: $alignment !important';
  }

  /// Convert indent attribute
  static String? _convertIndentAttribute(dynamic value) {
    if (value.toString().isEmpty) return null;
    final indentValue = int.tryParse(value.toString()) ?? 1;
    final indentPx = indentValue * 30; // 30px per indent level
    debugPrint('🎨 Converting indent: $value → ${indentPx}px');
    return 'margin-left: ${indentPx}px !important';
  }

  /// Convert header attribute (h1, h2, h3, etc.)
  static String? _convertHeaderAttribute(dynamic value) {
    if (value.toString().isEmpty) return null;
    final headerLevel = int.tryParse(value.toString()) ?? 1;
    final fontSize = [32, 28, 24, 20, 18, 16][headerLevel.clamp(1, 6) - 1];
    debugPrint('🎨 Converting header: level $headerLevel → ${fontSize}px');
    return 'font-size: ${fontSize}px !important; font-weight: 600 !important; margin: 16px 0 8px 0 !important; line-height: 1.2 !important';
  }

  /// Convert blockquote attribute
  static String? _convertBlockquoteAttribute(dynamic value) {
    debugPrint('🎨 Converting blockquote');
    return 'margin: 16px 20px !important; padding: 16px !important; background-color: #f9f9f9 !important; border-left: 4px solid #ccc !important; font-style: italic !important';
  }

  /// Convert code block attribute
  static String? _convertCodeBlockAttribute(dynamic value) {
    debugPrint('🎨 Converting code block');
    return 'background-color: #f4f4f4 !important; padding: 12px !important; font-family: "Courier New", monospace !important; white-space: pre-wrap !important; margin: 0 0 16px 0 !important; border-radius: 4px !important';
  }

  /// Convert script attribute (superscript/subscript)
  static String? _convertScriptAttribute(dynamic value) {
    if (value.toString().isEmpty) return null;
    final scriptType = value.toString();
    debugPrint('🎨 Converting script: $scriptType');
    
    if (scriptType == 'super') {
      return 'vertical-align: super !important; font-size: 0.8em !important';
    } else if (scriptType == 'sub') {
      return 'vertical-align: sub !important; font-size: 0.8em !important';
    }
    return null;
  }

  /// Convert font weight attribute
  static String? _convertFontWeightAttribute(dynamic value) {
    if (value.toString().isEmpty) return null;
    final weight = value.toString();
    debugPrint('🎨 Converting font weight: $weight');
    
    // Convert numeric and text weights
    final validWeights = ['100', '200', '300', '400', '500', '600', '700', '800', '900', 'normal', 'bold', 'bolder', 'lighter'];
    if (validWeights.contains(weight)) {
      return 'font-weight: $weight !important';
    }
    return 'font-weight: normal !important';
  }

  /// Enhance HTML with email client compatibility
  static String _enhanceHtmlWithEmailCompatibility(String htmlOutput) {
    String finalHtml = htmlOutput;

    debugPrint('🎨 Using standard web fonts for email compatibility');

    // Add email-compatible structure if not present
    if (!finalHtml.contains('<html>') && !finalHtml.contains('<body>')) {
      finalHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Email Content</title>
  ${_getEmailCompatibleStyles()}
</head>
<body>
  <table class="email-main" role="presentation" cellpadding="0" cellspacing="0" border="0">
    <tr>
      <td class="email-content">
        $finalHtml
      </td>
    </tr>
  </table>
</body>
</html>''';
    }
    debugPrint('🎨 HTML conversion completed with web-compatible structure');
    return finalHtml;
  }

  /// Get email-compatible CSS styles with enhanced formatting support
  static String _getEmailCompatibleStyles() {
    return '''
  <style>
    /* Base styles for email compatibility */
    body { 
      font-family: Arial, "Helvetica Neue", Helvetica, sans-serif !important; 
      line-height: 1.6 !important; 
      color: #333333 !important; 
      margin: 0; 
      padding: 0; 
      background: #ffffff !important;
      -webkit-text-size-adjust: 100% !important;
      -ms-text-size-adjust: 100% !important;
    }
    
    /* Email container structure */
    table.email-main { width: 100% !important; max-width: 700px !important; margin: 0 auto !important; background: #ffffff !important; border-collapse: collapse !important; }
    td.email-content { padding: 20px !important; }
    
    /* Typography improvements */
    p { margin: 0 0 16px 0 !important; line-height: 1.6 !important; }
    h1 { font-size: 32px !important; font-weight: 600 !important; margin: 24px 0 16px 0 !important; line-height: 1.2 !important; color: #1a1a1a !important; }
    h2 { font-size: 28px !important; font-weight: 600 !important; margin: 20px 0 12px 0 !important; line-height: 1.3 !important; color: #1a1a1a !important; }
    h3 { font-size: 24px !important; font-weight: 600 !important; margin: 18px 0 10px 0 !important; line-height: 1.3 !important; color: #1a1a1a !important; }
    h4 { font-size: 20px !important; font-weight: 600 !important; margin: 16px 0 8px 0 !important; line-height: 1.4 !important; color: #1a1a1a !important; }
    h5 { font-size: 18px !important; font-weight: 600 !important; margin: 14px 0 8px 0 !important; line-height: 1.4 !important; color: #1a1a1a !important; }
    h6 { font-size: 16px !important; font-weight: 600 !important; margin: 12px 0 6px 0 !important; line-height: 1.4 !important; color: #1a1a1a !important; }
    
    /* Lists and indentation */
    ul, ol { margin: 0 0 16px 20px !important; padding-left: 20px !important; }
    li { margin: 0 0 8px 0 !important; line-height: 1.6 !important; }
    
    /* Blockquotes and special formatting */
    blockquote { 
      margin: 16px 20px !important; 
      padding: 16px !important; 
      background-color: #f9f9f9 !important; 
      border-left: 4px solid #cccccc !important; 
      font-style: italic !important;
      border-radius: 4px !important;
    }
    
    /* Links and interactive elements */
    a { color: #0066cc !important; text-decoration: underline !important; }
    a:hover { color: #0052a3 !important; }
    
    /* Text formatting */
    strong, b { font-weight: bold !important; }
    em, i { font-style: italic !important; }
    u { text-decoration: underline !important; }
    strike, s { text-decoration: line-through !important; }
    sup { vertical-align: super !important; font-size: 0.8em !important; }
    sub { vertical-align: sub !important; font-size: 0.8em !important; }
    
    /* Code formatting */
    code { 
      background-color: #f4f4f4 !important; 
      padding: 2px 6px !important; 
      font-family: "Courier New", Consolas, Monaco, monospace !important; 
      font-size: 14px !important;
      border-radius: 3px !important;
      color: #d63384 !important;
    }
    pre { 
      background-color: #f4f4f4 !important; 
      padding: 16px !important; 
      font-family: "Courier New", Consolas, Monaco, monospace !important; 
      white-space: pre-wrap !important; 
      margin: 0 0 16px 0 !important;
      border-radius: 4px !important;
      border: 1px solid #e9ecef !important;
      overflow-x: auto !important;
    }
    
    /* Table formatting for better email client support */
    table { border-collapse: collapse !important; width: 100% !important; }
    th, td { padding: 8px 12px !important; text-align: left !important; border: 1px solid #ddd !important; }
    th { background-color: #f8f9fa !important; font-weight: 600 !important; }
    
    /* Responsive design for mobile email clients */
    @media only screen and (max-width: 600px) {
      table.email-main { width: 100% !important; margin: 0 !important; }
      td.email-content { padding: 15px !important; }
      h1 { font-size: 28px !important; }
      h2 { font-size: 24px !important; }
      h3 { font-size: 20px !important; }
    }
    
    /* Dark mode support for email clients that support it */
    @media (prefers-color-scheme: dark) {
      body { background-color: #1a1a1a !important; color: #ffffff !important; }
      table.email-main { background-color: #1a1a1a !important; }
      h1, h2, h3, h4, h5, h6 { color: #ffffff !important; }
      blockquote { background-color: #2d2d2d !important; border-left-color: #555555 !important; }
      code { background-color: #2d2d2d !important; color: #ff6b9d !important; }
      pre { background-color: #2d2d2d !important; border-color: #555555 !important; }
      th { background-color: #2d2d2d !important; }
      th, td { border-color: #555555 !important; }
    }
  </style>''';
  }

  /// Add investment details to HTML with colorful sections
  static String addInvestmentDetailsToHtml(
    String baseHtml, 
    List<InvestorSummary> selectedInvestors,
  ) {
    final investmentDetails = _generateInvestmentDetailsText(selectedInvestors);
    final investmentHtml = _convertInvestmentDetailsToHtml(investmentDetails);

    // Add to existing HTML structure
    String finalHtml = baseHtml;
    
    if (!baseHtml.contains('<html>') && !baseHtml.contains('<body>')) {
      finalHtml = '''
<html>
<head>
  <meta charset="UTF-8">
  ${_getEmailCompatibleStyles()}
</head>
<body>
  <div>
    $baseHtml$investmentHtml
  </div>
</body>
</html>''';
    } else if (baseHtml.contains('</head>')) {
      finalHtml = baseHtml
          .replaceAll('</head>', '${_getEmailCompatibleStyles()}</head>')
          .replaceAll('</body>', '<div>$investmentHtml</div></body>');
    } else if (baseHtml.contains('</body>')) {
      finalHtml = baseHtml.replaceAll(
        '</body>',
        '${_getEmailCompatibleStyles()}<div>$investmentHtml</div></body>',
      );
    } else {
      finalHtml = '<div>$baseHtml${_getEmailCompatibleStyles()}$investmentHtml</div>';
    }

    return finalHtml;
  }

  /// Generate investment details text
  static String _generateInvestmentDetailsText(List<InvestorSummary> selectedInvestors) {
    if (selectedInvestors.isEmpty) {
      return '\n\n=== BRAK DANYCH INWESTYCYJNYCH ===\n\nNie wybrano żadnych inwestorów.\n\n';
    }

    final buffer = StringBuffer();
    buffer.writeln('\n\n=== SZCZEGÓŁY INWESTYCJI ===\n');

    double totalInvestmentAmount = 0;
    double totalRemainingCapital = 0;
    double totalSharesValue = 0;
    int totalInvestments = 0;

    for (final investor in selectedInvestors) {
      totalInvestmentAmount += investor.totalInvestmentAmount;
      totalRemainingCapital += investor.totalRemainingCapital;
      totalSharesValue += investor.totalSharesValue;
      totalInvestments += investor.investmentCount;
    }

    buffer.writeln('📊 PODSUMOWANIE PORTFELA:');
    buffer.writeln(
      '• Całkowita wartość inwestycji: ${_formatCurrency(totalInvestmentAmount)}',
    );
    buffer.writeln(
      '• Kapitał pozostały: ${_formatCurrency(totalRemainingCapital)}',
    );
    buffer.writeln('• Wartość udziałów: ${_formatCurrency(totalSharesValue)}');
    buffer.writeln('• Liczba inwestycji: $totalInvestments');
    buffer.writeln('• Liczba inwestorów: ${selectedInvestors.length}');
    buffer.writeln();

    final limitedInvestors = selectedInvestors.take(5).toList();
    buffer.writeln(
      limitedInvestors.length == 1
          ? '👤 SZCZEGÓŁY INWESTORA:'
          : '👥 SZCZEGÓŁY INWESTORÓW:',
    );

    for (int i = 0; i < limitedInvestors.length; i++) {
      final investor = limitedInvestors[i];
      final client = investor.client;

      buffer.writeln();
      buffer.writeln('${i + 1}. ${client.name}');
      buffer.writeln('   📧 Email: ${client.email}');
      buffer.writeln(
        '   💰 Kapitał pozostały: ${_formatCurrency(investor.totalRemainingCapital)}',
      );
      buffer.writeln(
        '   📈 Wartość udziałów: ${_formatCurrency(investor.totalSharesValue)}',
      );
      buffer.writeln('   🔢 Liczba inwestycji: ${investor.investmentCount}');

      if (investor.capitalSecuredByRealEstate > 0) {
        buffer.writeln(
          '   🏠 Zabezpieczone nieruchomościami: ${_formatCurrency(investor.capitalSecuredByRealEstate)}',
        );
      }
    }

    if (selectedInvestors.length > 5) {
      buffer.writeln();
      buffer.writeln(
        '...oraz ${selectedInvestors.length - 5} innych inwestorów.',
      );
    }

    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('Dane aktualne na dzień: ${_formatDate(DateTime.now())}');
    buffer.writeln('Metropolitan Investment');
    buffer.writeln();

    return buffer.toString();
  }

  /// Convert investment details to styled HTML with professional design
  static String _convertInvestmentDetailsToHtml(String investmentDetails) {
    return investmentDetails
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) {
          // Main header with elegant design
          if (line.startsWith('===')) {
            final headerText = line.replaceAll('=', '').trim();
            return '''
<div style="background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 50%, #60a5fa 100%); 
           color: white; 
           padding: 24px 32px; 
           margin: 32px 0 24px 0; 
           border-radius: 16px; 
           font-weight: 700; 
           font-size: 20px; 
           text-align: center; 
           box-shadow: 0 12px 32px rgba(30, 58, 138, 0.25), 0 4px 16px rgba(30, 58, 138, 0.15);
           border: 1px solid rgba(255, 255, 255, 0.1);
           position: relative;
           overflow: hidden;">
  <div style="position: absolute; top: 0; left: 0; right: 0; height: 1px; background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);"></div>
  <span style="display: inline-block; margin-right: 12px; font-size: 24px; filter: drop-shadow(0 2px 4px rgba(0,0,0,0.2));">📊</span>
  <span style="letter-spacing: 0.5px;">$headerText</span>
  <div style="position: absolute; bottom: 0; left: 0; right: 0; height: 1px; background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent);"></div>
</div>''';
          }

          // Summary cards with modern card design
          if (line.startsWith('•')) {
            final cleanLine = line.substring(1).trim();
            
            if (cleanLine.contains('Całkowita wartość inwestycji')) {
              return _createSummaryCard(
                cleanLine,
                '💎',
                '#059669',
                '#10b981',
                '5, 150, 105',
              );
            }
            if (cleanLine.contains('Kapitał pozostały')) {
              return _createSummaryCard(
                cleanLine,
                '💰',
                '#0369a1',
                '#0ea5e9',
                '3, 105, 161',
              );
            }
            if (cleanLine.contains('Wartość udziałów')) {
              return _createSummaryCard(
                cleanLine,
                '📈',
                '#d97706',
                '#f59e0b',
                '217, 119, 6',
              );
            }
            if (cleanLine.contains('Liczba inwestycji')) {
              return _createSummaryCard(
                cleanLine,
                '🎯',
                '#7c3aed',
                '#8b5cf6',
                '124, 58, 237',
              );
            }
            if (cleanLine.contains('Liczba inwestorów')) {
              return _createSummaryCard(
                cleanLine,
                '👥',
                '#dc2626',
                '#ef4444',
                '220, 38, 38',
              );
            }
            return _createSummaryCard(
              cleanLine,
              '•',
              '#4b5563',
              '#6b7280',
              '75, 85, 99',
            );
          }

          // Investor cards with sophisticated design
          if (RegExp(r'^\d+\.').hasMatch(line)) {
            return '''
<div style="background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%); 
           color: #1e293b; 
           padding: 20px 24px; 
           margin: 16px 0; 
           border-radius: 16px; 
           font-weight: 600; 
           font-size: 16px;
           box-shadow: 0 8px 24px rgba(15, 23, 42, 0.08), 0 2px 8px rgba(15, 23, 42, 0.04);
           border: 1px solid #e2e8f0;
           border-left: 6px solid #3b82f6;
           position: relative;
           transition: all 0.3s ease;">
  <div style="display: flex; align-items: center;">
    <span style="background: linear-gradient(135deg, #3b82f6, #1d4ed8); 
                 color: white; 
                 width: 32px; 
                 height: 32px; 
                 border-radius: 50%; 
                 display: inline-flex; 
                 align-items: center; 
                 justify-content: center; 
                 margin-right: 16px; 
                 font-size: 16px;
                 box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);">👤</span>
    <span style="flex: 1; font-size: 17px; font-weight: 600; color: #1e293b;">$line</span>
  </div>
</div>''';
          }

          // Detail cards with refined styling
          if (line.startsWith('   ')) {
            final cleanLine = line.trim();
            
            if (cleanLine.contains('Email:')) {
              return _createDetailCard(
                cleanLine,
                '📧',
                '#0ea5e9',
                '#0284c7',
                '14, 165, 233',
              );
            }
            if (cleanLine.contains('Kapitał pozostały:')) {
              return _createDetailCard(
                cleanLine,
                '💰',
                '#10b981',
                '#059669',
                '16, 185, 129',
              );
            }
            if (cleanLine.contains('Wartość udziałów:')) {
              return _createDetailCard(
                cleanLine,
                '📊',
                '#f59e0b',
                '#d97706',
                '245, 158, 11',
              );
            }
            if (cleanLine.contains('Liczba inwestycji:')) {
              return _createDetailCard(
                cleanLine,
                '🎯',
                '#8b5cf6',
                '#7c3aed',
                '139, 92, 246',
              );
            }
            if (cleanLine.contains('Zabezpieczone nieruchomościami:')) {
              return _createDetailCard(
                cleanLine,
                '🏠',
                '#f97316',
                '#ea580c',
                '249, 115, 22',
              );
            }
            
            return '''
<div style="color: #64748b; 
           margin: 6px 0 6px 48px; 
           font-size: 14px; 
           padding: 8px 12px; 
           background: #f8fafc; 
           border-radius: 8px; 
           border-left: 3px solid #cbd5e1;">$cleanLine</div>''';
          }

          // Section headers
          if (line.contains('📊') || line.contains('👤') || line.contains('👥')) {
            return '''
<div style="background: linear-gradient(135deg, #1e40af 0%, #3b82f6 100%); 
           color: white; 
           padding: 18px 24px; 
           margin: 24px 0 16px 0; 
           border-radius: 14px; 
           font-weight: 600; 
           font-size: 18px; 
           text-align: center;
           box-shadow: 0 8px 20px rgba(30, 64, 175, 0.2);
           border: 1px solid rgba(255, 255, 255, 0.1);">
  <span style="font-size: 22px; margin-right: 12px; filter: drop-shadow(0 1px 2px rgba(0,0,0,0.1));">
    ${line.contains('�')
                ? '📊'
                : line.contains('�👤')
                ? '👤'
                : '👥'}
  </span>
  <span style="letter-spacing: 0.3px;">$line</span>
</div>''';
          }

          // Elegant divider
          if (line.startsWith('---')) {
            return '''
<div style="margin: 32px 0; text-align: center;">
  <div style="height: 1px; 
             background: linear-gradient(90deg, transparent 0%, #cbd5e1 20%, #94a3b8 50%, #cbd5e1 80%, transparent 100%); 
             margin: 16px 0;"></div>
  <div style="display: inline-block; 
             background: #f1f5f9; 
             padding: 8px 16px; 
             border-radius: 20px; 
             color: #64748b; 
             font-size: 12px; 
             font-weight: 500; 
             letter-spacing: 0.5px;
             border: 1px solid #e2e8f0;">• • •</div>
</div>''';
          }

          // Default styling for other content
          return '''
<div style="margin: 8px 0; 
           color: #475569; 
           font-size: 15px; 
           line-height: 1.6; 
           padding: 6px 0;">$line</div>''';
        })
        .join('\n');
  }

  /// Create a modern summary card
  static String _createSummaryCard(
    String content,
    String icon,
    String primaryColor,
    String secondaryColor,
    String shadowRgb,
  ) {
    return '''
<div style="background: linear-gradient(135deg, $primaryColor 0%, $secondaryColor 100%); 
           color: white; 
           padding: 20px 24px; 
           margin: 12px 0; 
           border-radius: 14px; 
           font-weight: 600; 
           font-size: 16px;
           box-shadow: 0 8px 24px rgba($shadowRgb, 0.2), 0 2px 8px rgba($shadowRgb, 0.1);
           border: 1px solid rgba(255, 255, 255, 0.1);
           position: relative;
           overflow: hidden;">
  <div style="position: absolute; top: 0; right: 0; width: 60px; height: 60px; background: rgba(255,255,255,0.05); border-radius: 50%; transform: translate(20px, -20px);"></div>
  <div style="display: flex; align-items: center;">
    <span style="background: rgba(255, 255, 255, 0.15); 
                 width: 40px; 
                 height: 40px; 
                 border-radius: 12px; 
                 display: inline-flex; 
                 align-items: center; 
                 justify-content: center; 
                 margin-right: 16px; 
                 font-size: 18px;
                 backdrop-filter: blur(10px);
                 border: 1px solid rgba(255, 255, 255, 0.1);">$icon</span>
    <span style="flex: 1; font-size: 16px; letter-spacing: 0.2px;">$content</span>
  </div>
</div>''';
  }

  /// Create a refined detail card
  static String _createDetailCard(
    String content,
    String icon,
    String primaryColor,
    String secondaryColor,
    String shadowRgb,
  ) {
    return '''
<div style="background: linear-gradient(135deg, $primaryColor 0%, $secondaryColor 100%); 
           color: white; 
           padding: 12px 16px; 
           margin: 6px 0 6px 48px; 
           border-radius: 10px; 
           font-size: 14px;
           font-weight: 500;
           box-shadow: 0 4px 12px rgba($shadowRgb, 0.15), 0 1px 4px rgba($shadowRgb, 0.1);
           border: 1px solid rgba(255, 255, 255, 0.1);
           position: relative;">
  <div style="display: flex; align-items: center;">
    <span style="background: rgba(255, 255, 255, 0.15); 
                 width: 28px; 
                 height: 28px; 
                 border-radius: 8px; 
                 display: inline-flex; 
                 align-items: center; 
                 justify-content: center; 
                 margin-right: 12px; 
                 font-size: 14px;
                 backdrop-filter: blur(5px);">$icon</span>
    <span style="flex: 1; letter-spacing: 0.1px;">$content</span>
  </div>
</div>''';
  }

  /// Format currency
  static String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} PLN';
  }

  /// Format date
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}