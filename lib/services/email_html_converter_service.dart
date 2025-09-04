import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import '../models_and_services.dart';

/// 🎨 Service responsible for converting Quill content to HTML
/// Extracted from WowEmailEditorScreen for better separation of concerns
/// Now uses FontFamilyService for better font management
class EmailHtmlConverterService {
  /// Font family configuration with fallbacks
  static Map<String, String> get availableFonts => {
    for (String font in FontFamilyService.allFonts) font: font
  };

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
    return FontFamilyService.getCSSFontFamily(fontName);
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
      'bold': InlineStyleType(fn: (value, _) => 'font-weight: bold'),
      'italic': InlineStyleType(fn: (value, _) => 'font-style: italic'),
      'underline': InlineStyleType(
        fn: (value, _) => 'text-decoration: underline',
      ),
      'strike': InlineStyleType(
        fn: (value, _) => 'text-decoration: line-through',
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
    });
  }

  /// Convert color attribute with proper validation
  static String? _convertColorAttribute(dynamic value) {
    if (value.toString().isEmpty) return null;
    String colorValue = value.toString();
    debugPrint('🎨 Converting color: $colorValue');
    
    if (colorValue.startsWith('#')) {
      return 'color: $colorValue !important';
    }
    if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(colorValue)) {
      return 'color: #$colorValue !important';
    }
    if (RegExp(r'^rgb\((\d{1,3}), ?(\d{1,3}), ?(\d{1,3})\)$').hasMatch(colorValue)) {
      return 'color: $colorValue !important';
    }
    return 'color: $colorValue !important';
  }

  /// Convert background color attribute
  static String? _convertBackgroundAttribute(dynamic value) {
    if (value.toString().isEmpty) return null;
    String colorValue = value.toString();
    debugPrint('🎨 Converting background: $colorValue');
    
    if (colorValue.startsWith('#')) {
      return 'background-color: $colorValue !important';
    }
    if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(colorValue)) {
      return 'background-color: #$colorValue !important';
    }
    if (RegExp(r'^rgb\((\d{1,3}), ?(\d{1,3}), ?(\d{1,3})\)$').hasMatch(colorValue)) {
      return 'background-color: $colorValue !important';
    }
    return 'background-color: $colorValue !important';
  }

  /// Convert font attribute with fallbacks
  static String? _convertFontAttribute(dynamic value) {
    if (value.toString().isEmpty) return null;
    
    final fontName = value.toString();
    final cssFontFamily = getCssFontFamily(fontName);
    
    // Check if font requires Google Fonts
    if (FontFamilyService.isGoogleFont(fontName)) {
      debugPrint('📤 Font "$fontName" requires Google Fonts. Email may need additional setup.');
    } else if (!FontFamilyService.isWebSafeFont(fontName)) {
      debugPrint('⚠️ Warning: font "$fontName" may not be supported by email clients.');
    }
    
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

  /// Enhance HTML with email client compatibility
  static String _enhanceHtmlWithEmailCompatibility(String htmlOutput) {
    String finalHtml = htmlOutput;

    // Detect Google Fonts usage
    final requiredGoogleFonts = FontFamilyService.extractFontsFromHtml(htmlOutput);
    final googleFontsLinks = FontFamilyService.generateGoogleFontsHtml(requiredGoogleFonts);

    // Add email-compatible structure if not present
    if (!finalHtml.contains('<html>') && !finalHtml.contains('<body>')) {
      finalHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Email Content</title>
  ${googleFontsLinks.isNotEmpty ? '  $googleFontsLinks' : ''}
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
    } else if (googleFontsLinks.isNotEmpty && finalHtml.contains('<head>')) {
      // Inject Google Fonts into existing head
      finalHtml = finalHtml.replaceFirst(
        '<head>',
        '<head>\n  $googleFontsLinks',
      );
    }

    if (requiredGoogleFonts.isNotEmpty) {
      debugPrint('📤 HTML enhanced with Google Fonts: ${requiredGoogleFonts.join(', ')}');
    }
    debugPrint('🎨 HTML conversion completed with enhanced structure');
    return finalHtml;
  }

  /// Get email-compatible CSS styles
  static String _getEmailCompatibleStyles() {
    return '''
  <style>
    body { 
      font-family: Arial, "Helvetica Neue", Helvetica, sans-serif !important; 
      line-height: 1.6 !important; 
      color: #333333 !important; 
      margin: 0; 
      padding: 0; 
      background: #fff !important;
    }
    table.email-main { width: 100%; max-width: 700px; margin: 0 auto; background: #fff; border-collapse: collapse; }
    td.email-content { padding: 20px; }
    p { margin: 0 0 16px 0 !important; }
    h1 { font-size: 32px !important; margin: 16px 0 8px 0 !important; }
    h2 { font-size: 24px !important; margin: 16px 0 8px 0 !important; }
    h3 { font-size: 20px !important; margin: 16px 0 8px 0 !important; }
    ul, ol { margin: 0 0 16px 20px !important; padding-left: 20px !important; }
    li { margin: 0 0 8px 0 !important; }
    blockquote { 
      margin: 16px 20px !important; 
      padding: 16px !important; 
      background-color: #f9f9f9 !important; 
      border-left: 4px solid #ccc !important; 
      font-style: italic !important; 
    }
    a { color: #0066cc !important; text-decoration: underline !important; }
    strong, b { font-weight: bold !important; }
    em, i { font-style: italic !important; }
    u { text-decoration: underline !important; }
    strike, s { text-decoration: line-through !important; }
    code { 
      background-color: #f4f4f4 !important; 
      padding: 2px 4px !important; 
      font-family: "Courier New", monospace !important; 
      font-size: 14px !important; 
    }
    pre { 
      background-color: #f4f4f4 !important; 
      padding: 12px !important; 
      font-family: "Courier New", monospace !important; 
      white-space: pre-wrap !important; 
      margin: 0 0 16px 0 !important; 
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

  /// Convert investment details to styled HTML
  static String _convertInvestmentDetailsToHtml(String investmentDetails) {
    return investmentDetails
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) {
          if (line.startsWith('===')) {
            return '''
<div style="background: linear-gradient(135deg, #1a365d, #2b6cb0); color: white; padding: 20px; margin: 20px 0 10px 0; border-radius: 15px; font-weight: bold; font-size: 18px; text-align: center; box-shadow: 0 8px 25px rgba(26, 54, 93, 0.3);">
  <span style="display: inline-block;">📊</span> $line
</div>''';
          }
          if (line.startsWith('•')) {
            final cleanLine = line.substring(1).trim();
            if (cleanLine.contains('Całkowita wartość inwestycji')) {
              return '<div style="background: linear-gradient(135deg, #38a169, #48bb78); color: white; padding: 15px; margin: 10px 0; border-radius: 12px; font-weight: 600; box-shadow: 0 4px 15px rgba(56, 161, 105, 0.3);"><span style="font-size: 20px; margin-right: 10px;">💰</span>$cleanLine</div>';
            }
            if (cleanLine.contains('Kapitał pozostały')) {
              return '<div style="background: linear-gradient(135deg, #3182ce, #4299e1); color: white; padding: 15px; margin: 10px 0; border-radius: 12px; font-weight: 600; box-shadow: 0 4px 15px rgba(49, 130, 206, 0.3);"><span style="font-size: 20px; margin-right: 10px;">💵</span>$cleanLine</div>';
            }
            if (cleanLine.contains('Wartość udziałów')) {
              return '<div style="background: linear-gradient(135deg, #d69e2e, #f6e05e); color: #2d3748; padding: 15px; margin: 10px 0; border-radius: 12px; font-weight: 600; box-shadow: 0 4px 15px rgba(214, 158, 46, 0.3);"><span style="font-size: 20px; margin-right: 10px;">📈</span>$cleanLine</div>';
            }
            if (cleanLine.contains('Liczba inwestycji')) {
              return '<div style="background: linear-gradient(135deg, #805ad5, #9f7aea); color: white; padding: 15px; margin: 10px 0; border-radius: 12px; font-weight: 600; box-shadow: 0 4px 15px rgba(128, 90, 213, 0.3);"><span style="font-size: 20px; margin-right: 10px;">🔢</span>$cleanLine</div>';
            }
            if (cleanLine.contains('Liczba inwestorów')) {
              return '<div style="background: linear-gradient(135deg, #e53e3e, #fc8181); color: white; padding: 15px; margin: 10px 0; border-radius: 12px; font-weight: 600; box-shadow: 0 4px 15px rgba(229, 62, 62, 0.3);"><span style="font-size: 20px; margin-right: 10px;">👥</span>$cleanLine</div>';
            }
            return '<div style="background: linear-gradient(135deg, #4a5568, #718096); color: white; padding: 12px; margin: 8px 0; border-radius: 10px;"><span style="margin-right: 8px;">•</span>$cleanLine</div>';
          }
          if (RegExp(r'^\d+\.').hasMatch(line)) {
            return '<div style="background: linear-gradient(135deg, #2d3748, #4a5568); color: white; padding: 12px 15px; margin: 8px 0; border-radius: 10px; font-weight: 500; border-left: 4px solid #ffd700;"><span style="color: #ffd700; margin-right: 10px;">👤</span>$line</div>';
          }
          if (line.startsWith('   ')) {
            final cleanLine = line.trim();
            if (cleanLine.contains('Email:')) {
              return '<div style="background: linear-gradient(135deg, #4299e1, #63b3ed); color: white; padding: 8px 12px; margin: 4px 0 4px 30px; border-radius: 8px; font-size: 14px;"><span style="margin-right: 8px;">📧</span>$cleanLine</div>';
            }
            if (cleanLine.contains('Kapitał pozostały:')) {
              return '<div style="background: linear-gradient(135deg, #48bb78, #68d391); color: white; padding: 8px 12px; margin: 4px 0 4px 30px; border-radius: 8px; font-size: 14px;"><span style="margin-right: 8px;">💰</span>$cleanLine</div>';
            }
            if (cleanLine.contains('Wartość udziałów:')) {
              return '<div style="background: linear-gradient(135deg, #f6e05e, #faf089); color: #2d3748; padding: 8px 12px; margin: 4px 0 4px 30px; border-radius: 8px; font-size: 14px;"><span style="margin-right: 8px;">📈</span>$cleanLine</div>';
            }
            if (cleanLine.contains('Liczba inwestycji:')) {
              return '<div style="background: linear-gradient(135deg, #9f7aea, #b794f6); color: white; padding: 8px 12px; margin: 4px 0 4px 30px; border-radius: 8px; font-size: 14px;"><span style="margin-right: 8px;">🔢</span>$cleanLine</div>';
            }
            if (cleanLine.contains('Zabezpieczone nieruchomościami:')) {
              return '<div style="background: linear-gradient(135deg, #ed8936, #f6ad55); color: white; padding: 8px 12px; margin: 4px 0 4px 30px; border-radius: 8px; font-size: 14px;"><span style="margin-right: 8px;">🏠</span>$cleanLine</div>';
            }
            return '<div style="color: #4a5568; margin: 3px 0 3px 30px; font-size: 14px;">$cleanLine</div>';
          }
          if (line.contains('📊') || line.contains('👤') || line.contains('👥')) {
            return '<div style="background: linear-gradient(135deg, #2b6cb0, #4299e1); color: white; padding: 15px; margin: 15px 0 8px 0; border-radius: 12px; font-weight: 600; font-size: 16px; text-align: center;"><span style="font-size: 24px; margin-right: 10px;">$line</span></div>';
          }
          if (line.startsWith('---')) {
            return '<div style="height: 2px; background: linear-gradient(90deg, transparent, #e2e8f0, transparent); margin: 20px 0;"></div>';
          }
          return '<div style="margin: 5px 0;">$line</div>';
        })
        .join('\n');
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