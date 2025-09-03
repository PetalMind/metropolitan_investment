import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart' as html_package;
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';

/// 🎨 CUSTOM ATTRIBUTES FOR ADVANCED FONT HANDLING
class CustomAttributes {
  // Custom font attribute for font family selection
  static final font = Attribute<String>('font', AttributeScope.inline, 'Arial');

  // Additional custom attributes for future extensions
  static final letterSpacing = Attribute<double>(
    'letterSpacing',
    AttributeScope.inline,
    0.0,
  );
  static final lineHeight = Attribute<double>(
    'lineHeight',
    AttributeScope.inline,
    1.0,
  );
}

/// 🎨 FONT FAMILY CONFIGURATION
class FontFamilyConfig {
  static const Map<String, String> availableFonts = {
    'Arial': 'Arial',
    'Helvetica': 'Helvetica',
    'Times New Roman': 'Times New Roman',
    'Courier New': 'Courier New',
    'Verdana': 'Verdana',
    'Georgia': 'Georgia',
    'Trebuchet MS': 'Trebuchet MS',
    'Tahoma': 'Tahoma',
    'Calibri': 'Calibri',
    'Segoe UI': 'Segoe UI',
    'Open Sans': 'Open Sans',
    'Roboto': 'Roboto',
    'Lato': 'Lato',
    'Montserrat': 'Montserrat',
  };

  static const String defaultFont = 'Arial';

  /// Get CSS font family with fallbacks
  static String getCssFontFamily(String fontName) {
    const fontFallbacks = {
      'Arial': 'Arial, "Helvetica Neue", Helvetica, sans-serif',
      'Helvetica': 'Helvetica, "Helvetica Neue", Arial, sans-serif',
      'Times New Roman': '"Times New Roman", Times, serif',
      'Courier New': '"Courier New", Courier, monospace',
      'Verdana': 'Verdana, Geneva, sans-serif',
      'Georgia': 'Georgia, "Times New Roman", Times, serif',
      'Trebuchet MS':
          '"Trebuchet MS", "Lucida Grande", "Lucida Sans Unicode", "Lucida Sans", Tahoma, sans-serif',
      'Tahoma': 'Tahoma, Geneva, sans-serif',
      'Calibri': 'Calibri, "Segoe UI", "Helvetica Neue", Arial, sans-serif',
      'Segoe UI': '"Segoe UI", Tahoma, Geneva, Verdana, sans-serif',
      'Open Sans':
          '"Open Sans", "Segoe UI", "Helvetica Neue", Arial, sans-serif',
      'Roboto': 'Roboto, "Segoe UI", "Helvetica Neue", Arial, sans-serif',
      'Lato': 'Lato, "Segoe UI", "Helvetica Neue", Arial, sans-serif',
      'Montserrat':
          'Montserrat, "Segoe UI", "Helvetica Neue", Arial, sans-serif',
    };

    return fontFallbacks[fontName] ?? '$fontName, Arial, sans-serif';
  }
}

/// **🚀 WOW EMAIL EDITOR SCREEN - NAJPIĘKNIEJSZY SCREEN W FLUTTER! 🚀**
///
/// Ten screen pokazuje pełnię możliwości UI/UX designu:
/// - Glassmorphism effects
/// - Płynne animacje z elastycznością
/// - Priorytet responsywności dla edytora
/// - Zwijane sekcje z WOW efektami
/// - Profesjonalne gradienty i cienie
/// - Możliwość cofnięcia się z przyciskiem back
class WowEmailEditorScreen extends StatefulWidget {
  final List<InvestorSummary> selectedInvestors;
  final String? initialSubject;
  final String? initialMessage;

  const WowEmailEditorScreen({
    super.key,
    required this.selectedInvestors,
    this.initialSubject,
    this.initialMessage,
  });

  @override
  State<WowEmailEditorScreen> createState() => _WowEmailEditorScreenState();
}

class _WowEmailEditorScreenState extends State<WowEmailEditorScreen>
    with TickerProviderStateMixin {
  // 🎮 KONTROLERY PODSTAWOWE
  late QuillController _quillController;
  late FocusNode _editorFocusNode;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _senderEmailController = TextEditingController();
  final _senderNameController = TextEditingController(
    text: 'Metropolitan Investment',
  );
  final _subjectController = TextEditingController();
  final _additionalEmailController = TextEditingController();

  // 📏 ENHANCED FONT SIZES WITH COMPLETE RANGE
  static const Map<String, String> _fontSizes = {
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

  // 🎭 STAN SCREEN Z WOW EFEKTAMI
  bool _isLoading = false;
  bool _includeInvestmentDetails = true;
  bool _isGroupEmail = false;
  bool _isEditorExpanded = false;
  bool _isSettingsCollapsed = false;
  bool _isRecipientsCollapsed = false;
  bool _isPreviewVisible = false;
  bool _isPreviewDarkTheme = false;
  String? _error;
  List<EmailSendResult>? _results;
  String _currentPreviewHtml = '';
  double _previewZoomLevel = 1.0;
  
  // 📊 ENHANCED LOADING STATE
  String _loadingMessage = 'Przygotowywanie wiadomości...';
  int _emailsSent = 0;
  int _totalEmailsToSend = 0;
  double _loadingProgress = 0.0;

  // 🎪 KONTROLERY ANIMACJI DLA MAKSYMALNEGO WOW
  late AnimationController _settingsAnimationController;
  late AnimationController _editorAnimationController;
  late AnimationController _mainScreenController;
  late AnimationController _recipientsAnimationController;

  // late Animation<double> _settingsSlideAnimation;
  late Animation<double> _editorBounceAnimation;
  late Animation<double> _screenEntranceAnimation;
  late Animation<Offset> _screenSlideAnimation;

  // 📧 ZARZĄDZANIE ODBIORCAMI
  final Map<String, bool> _recipientEnabled = {};
  final Map<String, String> _recipientEmails = {};
  final List<String> _additionalEmails = [];



  @override
  void initState() {
    super.initState();
    _initializeWowScreen();
  }

  void _initializeWowScreen() {
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      final doc = Document()..insert(0, widget.initialMessage!);
      _quillController = QuillController(document: doc, selection: const TextSelection.collapsed(offset: 0));
    } else {
      _quillController = QuillController.basic();
    }
    _editorFocusNode = FocusNode();

    // 🎪 INICJALIZACJA WOW ANIMACJI
    _settingsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _editorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _mainScreenController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _recipientsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // 🌊 ANIMACJE SEKCJI USTAWIEŃ (GLASSMORPHISM)
    // _settingsSlideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
    //   CurvedAnimation(
    //     parent: _settingsAnimationController,
    //     curve: Curves.elasticInOut,
    //   ),
    // );

    // 🎯 ANIMACJA BOUNCY EDYTORA
    _editorBounceAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _editorAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // 🚀 ANIMACJA WEJŚCIA CAŁEGO SCREEN
    _screenEntranceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainScreenController, curve: Curves.elasticOut),
    );

    _screenSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _mainScreenController,
            curve: Curves.easeOutBack,
          ),
        );

    // 🎬 URUCHOM ANIMACJE WEJŚCIOWE
    _mainScreenController.forward();

    // Ustaw domyślne wartości
    _subjectController.text =
        widget.initialSubject ??
        'Aktualizacja portfela inwestycyjnego - Metropolitan Investment';

    _initializeRecipients();
    _loadSmtpEmail();

    // 🎪 REAL-TIME PREVIEW LISTENER
    _quillController.addListener(_updatePreviewContent);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeContent();
      _updatePreviewContent(); // Initial preview
    });
  }

  void _initializeRecipients() {
    for (final investor in widget.selectedInvestors) {
      final clientId = investor.client.id;
      final email = investor.client.email;

      _recipientEnabled[clientId] =
          email.isNotEmpty &&
          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
      _recipientEmails[clientId] = email;
    }
  }

  Future<void> _loadSmtpEmail() async {
    try {
      final smtpService = SmtpService();
      final smtpSettings = await smtpService.getSmtpSettings();
      if (smtpSettings != null && smtpSettings.username.isNotEmpty) {
        _senderEmailController.text = smtpSettings.username;
      }
    } catch (e) {
      // Ignore error
    }
  }

  void _initializeContent() {
    final content =
        widget.initialMessage ??
        '''Szanowni Państwo,

Przesyłamy aktualne informacje dotyczące Państwa inwestycji w Metropolitan Investment.

Poniżej znajdą Państwo szczegółowe podsumowanie swojego portfela inwestycyjnego.

W razie pytań prosimy o kontakt z naszym działem obsługi klienta.

Z poważaniem,
Zespół Metropolitan Investment''';

    try {
      _quillController.clear();
      _quillController.document.insert(0, content);
      
      _quillController.updateSelection(
        TextSelection.collapsed(offset: content.length),
        ChangeSource.local,
      );
      
      debugPrint('🎨 Initial content loaded');
    } catch (e) {
      debugPrint('Error initializing content: $e');
    }
  }

  @override
  void dispose() {
    _previewUpdateTimer?.cancel(); // Clean up timer
    _quillController.removeListener(_updatePreviewContent);
    _quillController.dispose();
    _editorFocusNode.dispose();
    _senderEmailController.dispose();
    _senderNameController.dispose();
    _subjectController.dispose();
    _additionalEmailController.dispose();
    _settingsAnimationController.dispose();
    _editorAnimationController.dispose();
    _mainScreenController.dispose();
    _recipientsAnimationController.dispose();
    super.dispose();
  }

  // 🎪 ENHANCED REAL-TIME PREVIEW UPDATER WITH DEBOUNCING
  Timer? _previewUpdateTimer;
  
  void _updatePreviewContent() {
    // Cancel previous timer to debounce rapid changes
    _previewUpdateTimer?.cancel();

    _previewUpdateTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          try {
            _currentPreviewHtml = _convertQuillToHtml();
            if (_includeInvestmentDetails) {
              _currentPreviewHtml = _addInvestmentDetailsToHtml(
                _currentPreviewHtml,
              );
            }
            debugPrint('🔄 Preview updated successfully');
          } catch (e) {
            debugPrint('⚠️ Preview update error: $e');
            // Fallback to plain text if conversion fails
            final plainText = _quillController.document.toPlainText();
            _currentPreviewHtml =
                '<p>${plainText.isNotEmpty ? plainText : 'Wpisz treść wiadomości...'}</p>';
          }
        });
      }
    });
  }

  // 🎪 FORCE IMMEDIATE PREVIEW UPDATE (FOR CRITICAL CHANGES)
  void _forcePreviewUpdate() {
    _previewUpdateTimer?.cancel();
    if (mounted) {
      setState(() {
        try {
          _currentPreviewHtml = _convertQuillToHtml();
          if (_includeInvestmentDetails) {
            _currentPreviewHtml = _addInvestmentDetailsToHtml(
              _currentPreviewHtml,
            );
          }
          debugPrint('🔄 Preview force updated');
        } catch (e) {
          debugPrint('⚠️ Force preview update error: $e');
          final plainText = _quillController.document.toPlainText();
          _currentPreviewHtml =
              '<p>${plainText.isNotEmpty ? plainText : 'Wpisz treść wiadomości...'}</p>';
        }
      });
    }
  }

  // 📝 DODAWANIE SZCZEGÓŁÓW INWESTYCJI DO HTML Z KOLOROWYMI IKONKAMI (BEZ ANIMACJI)
  String _addInvestmentDetailsToHtml(String baseHtml) {
    final investmentDetails = _generateInvestmentDetailsText();
    final investmentHtml = investmentDetails
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
          if (line.contains('📊') ||
              line.contains('👤') ||
              line.contains('👥')) {
            return '<div style="background: linear-gradient(135deg, #2b6cb0, #4299e1); color: white; padding: 15px; margin: 15px 0 8px 0; border-radius: 12px; font-weight: 600; font-size: 16px; text-align: center;"><span style="font-size: 24px; margin-right: 10px;">$line</span></div>';
          }
          if (line.startsWith('---')) {
            return '<div style="height: 2px; background: linear-gradient(90deg, transparent, #e2e8f0, transparent); margin: 20px 0;"></div>';
          }
          return '<div style="margin: 5px 0;">$line</div>';
        })
        .join('\n');

    // Dodajemy podstawowe style
    final styles =
        '''
<style>
body { 
  margin: 0; 
  padding: 20px; 
  font-family: Arial, sans-serif; 
  line-height: 1.6; 
}
* { 
  font-family: inherit !important; 
}
</style>
''';

    // Ensure we have proper HTML structure
    String finalHtml = baseHtml;
    
    if (!baseHtml.contains('<html>') && !baseHtml.contains('<body>')) {
      finalHtml =
          '''
<html>
<head>
  <meta charset="UTF-8">
  $styles
</head>
<body>
  <div>
    $baseHtml$investmentHtml
  </div>
</body>
</html>''';
    } else if (baseHtml.contains('</head>')) {
      finalHtml = baseHtml
          .replaceAll('</head>', '$styles</head>')
          .replaceAll('</body>', '<div>$investmentHtml</div></body>');
    } else if (baseHtml.contains('</body>')) {
      finalHtml = baseHtml.replaceAll(
        '</body>',
        '$styles<div>$investmentHtml</div></body>',
      );
    } else {
      finalHtml = '<div>$baseHtml$styles$investmentHtml</div>';
    }

    return finalHtml;
  }

  // 🎪 TOGGLE PREVIEW VISIBILITY
  void _togglePreviewVisibility() {
    setState(() {
      _isPreviewVisible = !_isPreviewVisible;
      if (_isPreviewVisible) {
        _updatePreviewContent();
      }
    });
  }

  // 🌓 TOGGLE PREVIEW THEME
  void _togglePreviewTheme() {
    setState(() {
      _isPreviewDarkTheme = !_isPreviewDarkTheme;
    });
  }

  // 🔍 ZOOM CONTROLS FOR PREVIEW
  void _zoomInPreview() {
    setState(() {
      _previewZoomLevel = (_previewZoomLevel + 0.1).clamp(0.5, 2.0);
    });
  }

  void _zoomOutPreview() {
    setState(() {
      _previewZoomLevel = (_previewZoomLevel - 0.1).clamp(0.5, 2.0);
    });
  }

  void _resetPreviewZoom() {
    setState(() {
      _previewZoomLevel = 1.0;
    });
  }

  // 🎨 ENHANCED KONWERSJA DO HTML Z PEŁNYM WSPARCIEM FORMATOWANIA
  String _convertQuillToHtml() {
    try {
      if (_quillController.document.length <= 1) return '<p></p>';

      final plainText = _quillController.document.toPlainText();
      if (plainText.trim().isEmpty) return '<p></p>';

      final converter = QuillDeltaToHtmlConverter(
        _quillController.document.toDelta().toJson(),
        ConverterOptions(
          converterOptions: OpConverterOptions(
            inlineStylesFlag: true,
            allowBackgroundClasses: false,
            paragraphTag: 'p',
            inlineStyles: InlineStyles({
              'bold': InlineStyleType(fn: (value, _) => 'font-weight: bold'),
              'italic': InlineStyleType(fn: (value, _) => 'font-style: italic'),
              'underline': InlineStyleType(
                fn: (value, _) => 'text-decoration: underline',
              ),
              'strike': InlineStyleType(
                fn: (value, _) => 'text-decoration: line-through',
              ),
              // 🎨 LEPSZA OBSŁUGA KOLORÓW (HEX/RGB)
              'color': InlineStyleType(
                fn: (value, _) {
                  if (value.toString().isEmpty) return null;
                  String colorValue = value.toString();
                  debugPrint('🎨 Converting color: $colorValue');
                  if (colorValue.startsWith('#')) {
                    return 'color: $colorValue !important';
                  }
                  if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(colorValue)) {
                    return 'color: #$colorValue !important';
                  }
                  // rgb() format
                  if (RegExp(r'^rgb\((\d{1,3}), ?(\d{1,3}), ?(\d{1,3})\)$').hasMatch(colorValue)) {
                    return 'color: $colorValue !important';
                  }
                  // fallback: try to use as is
                  return 'color: $colorValue !important';
                },
              ),
              'background': InlineStyleType(
                fn: (value, _) {
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
                },
              ),
              // Ostrzeżenie/fallback dla niestandardowych fontów
              'font': InlineStyleType(
                fn: (value, _) {
                  if (value.isEmpty) return null;
                  final cssFontFamily = FontFamilyConfig.getCssFontFamily(value);
                  final knownFonts = FontFamilyConfig.availableFonts.keys;
                  if (!knownFonts.contains(value)) {
                    debugPrint('⚠️ Uwaga: font "$value" może nie być wspierany przez klienty poczty.');
                  }
                  return 'font-family: $cssFontFamily !important';
                },
              ),
              'font-family': InlineStyleType(
                fn: (value, _) {
                  if (value.isEmpty) return null;
                  final cssFontFamily = FontFamilyConfig.getCssFontFamily(value);
                  final knownFonts = FontFamilyConfig.availableFonts.keys;
                  if (!knownFonts.contains(value)) {
                    debugPrint('⚠️ Uwaga: font "$value" może nie być wspierany przez klienty poczty.');
                  }
                  return 'font-family: $cssFontFamily !important';
                },
              ),

              // 🔤 ENHANCED FONT FAMILY HANDLING WITH CUSTOM ATTRIBUTES
              'font': InlineStyleType(
                fn: (value, _) {
                  if (value.isEmpty) return null;
                  
                  // Use our FontFamilyConfig for proper CSS font families
                  final cssFontFamily = FontFamilyConfig.getCssFontFamily(
                    value,
                  );
                  debugPrint(
                    '🎨 Converting custom font to HTML: $value → $cssFontFamily',
                  );
                  return 'font-family: $cssFontFamily !important';
                },
              ),
              'font-family': InlineStyleType(
                fn: (value, _) {
                  if (value.isEmpty) return null;
                  
                  // Use our FontFamilyConfig for proper CSS font families
                  final cssFontFamily = FontFamilyConfig.getCssFontFamily(
                    value,
                  );
                  debugPrint(
                    '🎨 Converting font-family to HTML: $value → $cssFontFamily',
                  );
                  return 'font-family: $cssFontFamily !important';
                },
              ),

              // 📏 ENHANCED FONT SIZE HANDLING
              'size': InlineStyleType(
                fn: (value, _) {
                  if (value.isEmpty) return null;

                  debugPrint('🎨 Converting size: $value');

                  // Handle predefined sizes from _fontSizes map
                  if (_fontSizes.containsKey(value)) {
                    final sizeValue = _fontSizes[value]!;
                    debugPrint(
                      '🎨 Found predefined size: $value → ${sizeValue}px',
                    );
                    return 'font-size: ${sizeValue}px !important';
                  }

                  // Extract number from formatted value like "Normalny (14px)"
                  final sizeMatch = RegExp(r'\((\d+)px\)').firstMatch(value);
                  if (sizeMatch != null) {
                    final size = sizeMatch.group(1)!;
                    debugPrint(
                      '🎨 Extracted size from format: $value → ${size}px',
                    );
                    return 'font-size: ${size}px !important';
                  }

                  // Handle plain numbers
                  if (RegExp(r'^\d+$').hasMatch(value)) {
                    debugPrint('🎨 Plain number size: $value → ${value}px');
                    return 'font-size: ${value}px !important';
                  }

                  // Handle sizes with units
                  if (RegExp(
                    r'^\d+(\.\d+)?(px|pt|em|rem|%)$',
                  ).hasMatch(value)) {
                    debugPrint('🎨 Size with unit: $value');
                    return 'font-size: $value !important';
                  }

                  // Fallback for any other size format
                  debugPrint('🎨 Fallback size: $value');
                  return 'font-size: $value !important';
                },
              ),

              // 📐 TEXT ALIGNMENT
              'align': InlineStyleType(
                fn: (value, _) {
                  if (value.isEmpty) return null;
                  debugPrint('🎨 Converting alignment: $value');
                  // Ensure proper alignment values
                  const validAlignments = [
                    'left',
                    'center',
                    'right',
                    'justify',
                  ];
                  final alignment = validAlignments.contains(value)
                      ? value
                      : 'left';
                  return 'text-align: $alignment !important';
                },
              ),

              // 📝 LIST FORMATTING (enhanced)
              'list': InlineStyleType(
                fn: (value, _) {
                  if (value.isEmpty) return null;
                  debugPrint('🎨 Converting list: $value');
                  // Add proper list styling
                  return 'margin-left: 20px; padding-left: 10px;';
                },
              ),

              // 🎭 TEXT INDENTATION
              'indent': InlineStyleType(
                fn: (value, _) {
                  if (value.isEmpty) return null;
                  final indentValue = int.tryParse(value.toString()) ?? 1;
                  final indentPx = indentValue * 30; // 30px per indent level
                  debugPrint('🎨 Converting indent: $value → ${indentPx}px');
                  return 'margin-left: ${indentPx}px !important';
                },
              ),

              // 🔗 LINK FORMATTING (enhanced)
              'link': InlineStyleType(
                fn: (value, _) {
                  if (value.isEmpty) return null;
                  debugPrint('🎨 Converting link: $value');
                  return 'color: #0066cc !important; text-decoration: underline !important;';
                },
              ),

              // 📏 LINE HEIGHT
              'line-height': InlineStyleType(
                fn: (value, _) {
                  if (value.isEmpty) return null;
                  debugPrint('🎨 Converting line-height: $value');
                  return 'line-height: $value !important';
                },
              ),

              // 🎨 LETTER SPACING
              'letter-spacing': InlineStyleType(
                fn: (value, _) {
                  if (value.isEmpty) return null;
                  debugPrint('🎨 Converting letter-spacing: $value');
                  return 'letter-spacing: $value !important';
                },
              ),
            }),
          ),
        ),
      );

      final htmlOutput = converter.convert();

      // 🔍 VALIDATE AND ENHANCE HTML OUTPUT
      String finalHtml = htmlOutput;

      // Kompatybilność email: tabela jako główny layout
      if (!finalHtml.contains('<html>')) {
        finalHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Email Content</title>
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
  </style>
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

      debugPrint('🎨 HTML conversion completed with enhanced structure');
      return finalHtml;
    } catch (e) {
      debugPrint('⚠️ HTML conversion error: $e');
      final plainText = _quillController.document.toPlainText();
      final defaultFontFamily = 'Arial, sans-serif';
      return '<div style="font-family: $defaultFontFamily !important; font-size: 16px; line-height: 1.6;"><p>$plainText</p></div>';
    }
  }

  // 🎪 WOW AKCJE Z ANIMACJAMI
  void _toggleSettingsCollapse() {
    setState(() {
      _isSettingsCollapsed = !_isSettingsCollapsed;
    });

    if (_isSettingsCollapsed) {
      _settingsAnimationController.forward();
    } else {
      _settingsAnimationController.reverse();
    }
  }

  void _toggleRecipientsCollapse() {
    setState(() {
      _isRecipientsCollapsed = !_isRecipientsCollapsed;
    });

    if (_isRecipientsCollapsed) {
      _recipientsAnimationController.forward();
    } else {
      _recipientsAnimationController.reverse();
    }
  }

  void _toggleEditorExpansion() {
    setState(() {
      _isEditorExpanded = !_isEditorExpanded;
    });

    _editorAnimationController.reset();
    _editorAnimationController.forward();
  }

  void _addAdditionalEmail() {
    final email = _additionalEmailController.text.trim();
    if (email.isEmpty) return;

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() {
        _error = 'Nieprawidłowy format adresu email: $email';
      });
      return;
    }

    if (_additionalEmails.contains(email)) {
      setState(() {
        _error = 'Email $email już został dodany';
      });
      return;
    }

    setState(() {
      _additionalEmails.add(email);
      _additionalEmailController.clear();
      _error = null;
    });
  }

  void _removeAdditionalEmail(String email) {
    setState(() {
      _additionalEmails.remove(email);
    });
  }

  void _insertInvestmentDetails() {
    final cursor = _quillController.selection.baseOffset;
    final investmentText = _generateInvestmentDetailsText();

    _quillController.document.insert(cursor, investmentText);
    _quillController.updateSelection(
      TextSelection.collapsed(offset: cursor + investmentText.length),
      ChangeSource.local,
    );
  }

  String _generateInvestmentDetailsText() {
    if (widget.selectedInvestors.isEmpty) {
      return '\n\n=== BRAK DANYCH INWESTYCYJNYCH ===\n\nNie wybrano żadnych inwestorów.\n\n';
    }

    final buffer = StringBuffer();
    buffer.writeln('\n\n=== SZCZEGÓŁY INWESTYCJI ===\n');

    double totalInvestmentAmount = 0;
    double totalRemainingCapital = 0;
    double totalSharesValue = 0;
    int totalInvestments = 0;

    for (final investor in widget.selectedInvestors) {
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
    buffer.writeln('• Liczba inwestorów: ${widget.selectedInvestors.length}');
    buffer.writeln();

    final limitedInvestors = widget.selectedInvestors.take(5).toList();
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

    if (widget.selectedInvestors.length > 5) {
      buffer.writeln();
      buffer.writeln(
        '...oraz ${widget.selectedInvestors.length - 5} innych inwestorów.',
      );
    }

    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('Dane aktualne na dzień: ${_formatDate(DateTime.now())}');
    buffer.writeln('Metropolitan Investment');
    buffer.writeln();

    return buffer.toString();
  }

  // 🧪 TESTING HELPER - ADD SAMPLE FORMATTED CONTENT
  void _addSampleContent() {
    final sampleContent = '''Witam Szanownych Państwa!

To jest przykład wiadomości z różnymi formatowaniami:

BOLD TEXT - pogrubione
Italic text - kursywa  
Underlined text - podkreślone
Strikethrough text - przekreślone

Lista punktowana:
• Pierwszy punkt
• Drugi punkt z ważną informacją
• Trzeci punkt

Lista numerowana:
1. Krok pierwszy
2. Krok drugi  
3. Krok trzeci

Link do strony: https://metropolitan-investment.pl

"To jest cytat z ważnym komunikatem"

Kod przykładowy: console.log("Hello World!");

Z poważaniem,
Zespół Metropolitan Investment''';

    try {
      _quillController.clear();
      _quillController.document.insert(0, sampleContent);

      _quillController.updateSelection(
        TextSelection.collapsed(offset: sampleContent.length),
        ChangeSource.local,
      );

      // Force immediate preview update
      _forcePreviewUpdate();

      debugPrint('🧪 Sample content loaded for testing');
    } catch (e) {
      debugPrint('Error loading sample content: $e');
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (Match m) => '${m[1]} ')} PLN';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _clearEditor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wyczyść edytor'),
        content: const Text('Czy na pewno chcesz wyczyścić całą treść?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              _quillController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Wyczyść'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendEmails() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _error = 'Proszę wypełnić wszystkie wymagane pola.';
      });
      return;
    }

    // Initialize progress tracking
    final enabledInvestors = widget.selectedInvestors
        .where((investor) => _recipientEnabled[investor.client.id] ?? false)
        .toList();
    
    final allEmails = <String>[
      ...enabledInvestors.map((inv) => inv.client.email),
      ..._additionalEmails,
    ].where((email) => email.isNotEmpty).toList();

    setState(() {
      _isLoading = true;
      _error = null;
      _totalEmailsToSend = allEmails.length;
      _emailsSent = 0;
      _loadingProgress = 0.0;
      _loadingMessage = 'Przygotowywanie wiadomości...';
    });

    if (allEmails.isEmpty) {
      setState(() {
        _error = 'Brak aktywnych odbiorców email.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Step 1: Preparing HTML
      setState(() {
        _loadingMessage = 'Konwertowanie treści do HTML...';
        _loadingProgress = 0.1;
      });
      
      final emailHtml = _convertQuillToHtml();
      final finalHtml = _includeInvestmentDetails 
          ? _addInvestmentDetailsToHtml(emailHtml)
          : emailHtml;

      // Step 2: Connecting to email service
      setState(() {
        _loadingMessage = 'Łączenie z serwerem email...';
        _loadingProgress = 0.2;
      });

      // Step 3: Sending emails
      setState(() {
        _loadingMessage = 'Wysyłanie $_totalEmailsToSend wiadomości...';
        _loadingProgress = 0.3;
      });

      final emailService = EmailAndExportService();
      
      final results = await emailService.sendCustomEmailsToMixedRecipients(
        investors: enabledInvestors,
        additionalEmails: _additionalEmails,
        subject: _subjectController.text,
        htmlContent: finalHtml,
        includeInvestmentDetails: _includeInvestmentDetails,
        senderEmail: _senderEmailController.text,
        senderName: _senderNameController.text,
      );

      // 📊 Save email history after successful sending
      setState(() {
        _loadingMessage = 'Zapisywanie historii emaili...';
        _loadingProgress = 0.9;
      });

      await _saveEmailHistory(results, finalHtml);

      // Update final progress
      final successfulEmails = results.where((r) => r.success).length;
      setState(() {
        _emailsSent = results.length;
        _loadingProgress = 1.0;
        _loadingMessage = 'Wysłano $successfulEmails z ${results.length} wiadomości';
        _results = results;
        _isLoading = false;
      });

      // 🔊 Play success sound if emails were sent successfully
      if (successfulEmails > 0) {
        _playSuccessSound();
      }

      // Powrót do poprzedniego ekranu z wynikiem
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _error = 'Błąd podczas wysyłania: $e';
        _isLoading = false;
        _loadingMessage = 'Błąd wysyłania';
        _loadingProgress = 0.0;
      });
    }
  }

  // 📊 SAVE EMAIL HISTORY
  Future<void> _saveEmailHistory(
    List<EmailSendResult> results,
    String htmlContent,
  ) async {
    try {
      final emailHistoryService = EmailHistoryService();

      // Prepare recipients list from enabled investors and additional emails
      final recipients = <EmailRecipient>[];

      // Add enabled investors as recipients
      for (final investor in widget.selectedInvestors) {
        if (_recipientEnabled[investor.client.id] ?? false) {
          final result = results.firstWhere(
            (r) => r.clientEmail == investor.client.email,
            orElse: () => EmailSendResult(
              success: false,
              messageId: '',
              clientEmail: investor.client.email.isNotEmpty
                  ? investor.client.email
                  : '',
              clientName: investor.client.name,
              investmentCount: 0,
              totalAmount: 0,
              executionTimeMs: 0,
              template: 'mixed_html',
            ),
          );

          recipients.add(
            EmailRecipient(
              clientId: investor.client.id,
              clientName: investor.client.name,
              emailAddress: investor.client.email.isNotEmpty
                  ? investor.client.email
                  : '',
              isCustomEmail: false,
              deliveryStatus: result.success
                  ? DeliveryStatus.delivered
                  : DeliveryStatus.failed,
              deliveryError: result.error,
              deliveredAt: result.success ? DateTime.now() : null,
              messageId: result.messageId.isNotEmpty ? result.messageId : null,
            ),
          );
        }
      }

      // Add additional emails as recipients
      for (final email in _additionalEmails) {
        final result = results.firstWhere(
          (r) => r.clientEmail == email,
          orElse: () => EmailSendResult(
            success: false,
            messageId: '',
            clientEmail: email,
            clientName: email,
            investmentCount: 0,
            totalAmount: 0,
            executionTimeMs: 0,
            template: 'mixed_html',
          ),
        );

        recipients.add(
          EmailRecipient(
            clientId:
                'additional_${email.hashCode}', // Generate unique ID for additional emails
            clientName: email,
            emailAddress: email,
            isCustomEmail: true,
            deliveryStatus: result.success
                ? DeliveryStatus.delivered
                : DeliveryStatus.failed,
            deliveryError: result.error,
            deliveredAt: result.success ? DateTime.now() : null,
            messageId: result.messageId.isNotEmpty ? result.messageId : null,
          ),
        );
      }

      // Determine overall email status
      final totalRecipients = recipients.length;
      final successfulDeliveries = recipients
          .where((r) => r.deliveryStatus == DeliveryStatus.delivered)
          .length;

      EmailStatus emailStatus;
      if (successfulDeliveries == 0) {
        emailStatus = EmailStatus.failed;
      } else if (successfulDeliveries == totalRecipients) {
        emailStatus = EmailStatus.sent;
      } else {
        emailStatus = EmailStatus.partiallyFailed;
      }

      // Calculate total execution time
      final totalExecutionTime = results.fold<int>(
        0,
        (sum, result) => sum + result.executionTimeMs,
      );

      // Convert Quill content to plain text for backup
      final plainTextContent = _quillController.document.toPlainText();

      // Create email history entry
      final emailHistory = EmailHistory(
        id: '', // Will be set by Firestore
        senderEmail: _senderEmailController.text,
        senderName: _senderNameController.text,
        recipients: recipients,
        subject: _subjectController.text,
        plainTextContent: plainTextContent,
        includeInvestmentDetails: _includeInvestmentDetails,
        sentAt: DateTime.now(),
        status: emailStatus,
        messageId: results.isNotEmpty && results.first.messageId.isNotEmpty
            ? results.first.messageId
            : null,
        errorMessage: emailStatus == EmailStatus.failed
            ? results.where((r) => !r.success).map((r) => r.error).join(', ')
            : null,
        executionTimeMs: totalExecutionTime,
        metadata: {
          'editorVersion': 'wow_email_editor_v1',
          'totalRecipients': totalRecipients,
          'successfulDeliveries': successfulDeliveries,
          'enabledInvestorsCount': widget.selectedInvestors
              .where((inv) => _recipientEnabled[inv.client.id] ?? false)
              .length,
          'additionalEmailsCount': _additionalEmails.length,
        },
      );

      // Save to email history
      final savedHistoryId = await emailHistoryService.saveEmailHistory(
        emailHistory,
      );

      if (savedHistoryId != null) {
        debugPrint(
          '📊 Email history saved successfully with ID: $savedHistoryId',
        );
      } else {
        debugPrint('⚠️ Failed to save email history');
      }
    } catch (e) {
      debugPrint('⚠️ Error saving email history: $e');
      // Don't throw error - this is not critical for email sending
    }
  }

  // 🔊 PLAY SUCCESS SOUND FOR EMAIL SENDING
  void _playSuccessSound() {
    try {
      // Use Flutter's built-in SystemSound for success
      SystemSound.play(SystemSoundType.alert);
      debugPrint('🔊 Success sound played');
    } catch (e) {
      debugPrint('⚠️ Could not play success sound: $e');
    }
  }

  int _getEnabledRecipientsCount() {
    return _recipientEnabled.values.where((enabled) => enabled).length;
  }

  int _getTotalRecipientsCount() {
    return _getEnabledRecipientsCount() + _additionalEmails.length;
  }

  // 🎨 CUSTOM FONT TOOLBAR BUILDER
  Widget _buildCustomFontToolbar(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.accentGold.withValues(alpha: 0.1),
            AppThemePro.bondsBlue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemePro.accentGold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Font Family Dropdown
          Icon(
            Icons.font_download_outlined,
            color: AppThemePro.accentGold,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            'Czcionka:',
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 8),
          Expanded(child: _buildFontFamilyDropdown()),
          
          SizedBox(width: 16),
          
          // Simple Color Pickers
          _buildSimpleColorPicker(),
        ],
      ),
    );
  }

  // 🎨 SIMPLE COLOR PICKER
  Widget _buildSimpleColorPicker() {
    const colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Text Color
        PopupMenuButton<Color>(
          icon: Icon(
            Icons.format_color_text,
            color: AppThemePro.accentGold,
            size: 20,
          ),
          tooltip: 'Kolor tekstu',
          onSelected: _applyTextColor,
          itemBuilder: (context) => colors.map((color) {
            return PopupMenuItem<Color>(
              value: color,
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    _getColorName(color),
                    style: TextStyle(color: AppThemePro.textPrimary),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        
        SizedBox(width: 8),
        
        // Background Color
        PopupMenuButton<Color>(
          icon: Icon(
            Icons.format_color_fill,
            color: AppThemePro.accentGold,
            size: 20,
          ),
          tooltip: 'Kolor tła',
          onSelected: _applyBackgroundColor,
          itemBuilder: (context) => colors.map((color) {
            return PopupMenuItem<Color>(
              value: color,
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    _getColorName(color),
                    style: TextStyle(color: AppThemePro.textPrimary),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 🎨 GET COLOR NAME FOR DISPLAY
  String _getColorName(Color color) {
    if (color == Colors.black) return 'Czarny';
    if (color == Colors.red) return 'Czerwony';
    if (color == Colors.blue) return 'Niebieski';
    if (color == Colors.green) return 'Zielony';
    if (color == Colors.orange) return 'Pomarańczowy';
    if (color == Colors.purple) return 'Fioletowy';
    if (color == Colors.teal) return 'Turkusowy';
    if (color == Colors.brown) return 'Brązowy';
    return 'Inny';
  }

  // 🎨 FONT FAMILY DROPDOWN WIDGET
  Widget _buildFontFamilyDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppThemePro.borderSecondary.withValues(alpha: 0.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _getCurrentFontFamily(),
          isExpanded: true,
          style: TextStyle(color: AppThemePro.textPrimary, fontSize: 14),
          dropdownColor: AppThemePro.backgroundSecondary,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: AppThemePro.textSecondary,
            size: 18,
          ),
          items: FontFamilyConfig.availableFonts.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                style: TextStyle(
                  fontFamily: entry.key,
                  fontSize: 14,
                  color: AppThemePro.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newFont) {
            if (newFont != null) {
              _applyFontFamily(newFont);
            }
          },
        ),
      ),
    );
  }

  // 🎨 GET CURRENT FONT FAMILY FROM SELECTION
  String _getCurrentFontFamily() {
    try {
      final style = _quillController.getSelectionStyle();
      final fontAttribute = style.attributes['font'];

      if (fontAttribute != null && fontAttribute.value != null) {
        final fontValue = fontAttribute.value.toString();
        debugPrint('🎨 Current font from selection: $fontValue');

        // Check if it's one of our predefined fonts
        if (FontFamilyConfig.availableFonts.containsKey(fontValue)) {
          return fontValue;
        }
      }

      debugPrint('🎨 No font attribute found, using default');
      return FontFamilyConfig.defaultFont;
    } catch (e) {
      debugPrint('🎨 Error getting current font: $e');
      return FontFamilyConfig.defaultFont;
    }
  }

  // 🎨 APPLY FONT FAMILY TO SELECTION
  void _applyFontFamily(String fontFamily) {
    try {
      debugPrint('🎨 Applying font family: $fontFamily');

      // Use correct attribute creation for Flutter Quill
      final fontAttribute = Attribute.fromKeyValue('font', fontFamily);
      _quillController.formatSelection(fontAttribute);

      // Update preview immediately
      _forcePreviewUpdate();

      debugPrint('🎨 Font family applied successfully');
    } catch (e) {
      debugPrint('🎨 Error applying font family: $e');
    }
  }

  // 🎨 APPLY COLOR TO SELECTION
  void _applyTextColor(Color color) {
    try {
      debugPrint('🎨 Applying text color: $color');
      
      // Convert color to hex string using newer API
      final hexColor = '#${color.r.toInt().toRadixString(16).padLeft(2, '0')}${color.g.toInt().toRadixString(16).padLeft(2, '0')}${color.b.toInt().toRadixString(16).padLeft(2, '0')}';
      
      final colorAttribute = Attribute.fromKeyValue('color', hexColor);
      _quillController.formatSelection(colorAttribute);
      _forcePreviewUpdate();
      
      debugPrint('🎨 Text color applied successfully');
    } catch (e) {
      debugPrint('🎨 Error applying text color: $e');
    }
  }

  // 🎨 APPLY BACKGROUND COLOR TO SELECTION
  void _applyBackgroundColor(Color color) {
    try {
      debugPrint('🎨 Applying background color: $color');
      
      // Convert color to hex string using newer API
      final hexColor = '#${color.r.toInt().toRadixString(16).padLeft(2, '0')}${color.g.toInt().toRadixString(16).padLeft(2, '0')}${color.b.toInt().toRadixString(16).padLeft(2, '0')}';
      
      final backgroundAttribute = Attribute.fromKeyValue('background', hexColor);
      _quillController.formatSelection(backgroundAttribute);
      _forcePreviewUpdate();
      
      debugPrint('🎨 Background color applied successfully');
    } catch (e) {
      debugPrint('🎨 Error applying background color: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemePro.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppThemePro.backgroundSecondary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppThemePro.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edytor Email',
          style: TextStyle(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isPreviewVisible)
            IconButton(
              icon: Icon(
                _isPreviewDarkTheme ? Icons.light_mode : Icons.dark_mode,
                color: AppThemePro.accentGold,
              ),
              onPressed: _togglePreviewTheme,
              tooltip: 'Zmień motyw podglądu',
            ),
          IconButton(
            icon: Icon(
              _isPreviewVisible ? Icons.visibility_off : Icons.visibility,
              color: AppThemePro.accentGold,
            ),
            onPressed: _togglePreviewVisibility,
            tooltip: _isPreviewVisible ? 'Ukryj podgląd' : 'Pokaż podgląd',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final canEdit = Provider.of<AuthProvider>(context).isAdmin;
          final isMobile = constraints.maxWidth < 600;
          final isTablet = constraints.maxWidth < 900;

          return AnimatedBuilder(
            animation: Listenable.merge([
              _settingsAnimationController,
              _editorAnimationController,
              _mainScreenController,
            ]),
            builder: (context, _) {
              return FadeTransition(
                opacity: _screenEntranceAnimation,
                child: SlideTransition(
                  position: _screenSlideAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppThemePro.backgroundPrimary,
                          AppThemePro.backgroundSecondary.withValues(
                            alpha: 0.8,
                          ),
                        ],
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Error Banner
                            if (_error != null) _buildWowErrorBanner(),

                            // Results Banner
                            if (_results != null) _buildWowResultsBanner(),

                            // Loading Banner
                            if (_isLoading) _buildWowLoadingBanner(),

                            // Email Settings
                            _buildWowEmailSettings(isMobile, isTablet),

                            SizedBox(height: isMobile ? 16 : 24),

                            // Recipients List
                            _buildRecipientsList(isMobile),

                            SizedBox(height: isMobile ? 16 : 24),

                            // Editor
                            _buildWowEditor(isMobile, isTablet),

                            SizedBox(height: isMobile ? 16 : 24),

                            // Live Preview Panel
                            if (_isPreviewVisible) ...[
                              _buildLivePreviewPanel(isMobile, isTablet),
                              SizedBox(height: isMobile ? 16 : 24),
                            ],

                            // Quick Actions
                            _buildWowQuickActions(isMobile, isTablet),

                            SizedBox(height: isMobile ? 24 : 32),

                            // Actions
                            _buildWowActions(canEdit, isMobile, isTablet),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🎭 WOW HEADER Z GRADIENTAMI I EFEKTAMI
  Widget _buildWowHeader(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.accentGold.withValues(alpha: 0.1),
            AppThemePro.bondsBlue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border(
          top: BorderSide(
            color: AppThemePro.accentGold.withValues(alpha: 0.3),
            width: 2,
          ),
          left: BorderSide(
            color: AppThemePro.accentGold.withValues(alpha: 0.3),
            width: 2,
          ),
          right: BorderSide(
            color: AppThemePro.accentGold.withValues(alpha: 0.3),
            width: 2,
          ),
          bottom: BorderSide(
            color: AppThemePro.accentGold.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.accentGold.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppThemePro.accentGold, AppThemePro.bondsBlue],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.email_outlined,
              color: AppThemePro.primaryDark,
              size: 24,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profesjonalny Edytor Email',
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Wyślij spersonalizowane wiadomości do inwestorów',
                  style: TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isSettingsCollapsed ? Icons.expand_more : Icons.expand_less,
              color: AppThemePro.accentGold,
            ),
            onPressed: _toggleSettingsCollapse,
            tooltip: _isSettingsCollapsed
                ? 'Rozwiń ustawienia'
                : 'Zwiń ustawienia',
          ),
        ],
      ),
    );
  }

  Widget _buildWowMainContent(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email Fields
          _buildEmailFields(isMobile),

          SizedBox(height: isMobile ? 16 : 24),

          // Email Options
          _buildEmailOptions(isMobile),
        ],
      ),
    );
  }

  // 📧 ZWIJANE USTAWIENIA Z GLASSMORPHISM
  Widget _buildWowEmailSettings(bool isMobile, bool isTablet) {
    return AnimatedBuilder(
      animation: _settingsAnimationController,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppThemePro.backgroundSecondary.withValues(alpha: 0.9),
                AppThemePro.backgroundPrimary.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppThemePro.borderSecondary.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                children: [
                  // Header - zawsze widoczny
                  _buildWowHeader(isMobile, isTablet),

                  // Main Content - zwijany/rozwijany
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _isSettingsCollapsed
                        ? const SizedBox.shrink()
                        : Column(
                            children: [
                              SizedBox(height: isMobile ? 16 : 24),
                              _buildWowMainContent(isMobile, isTablet),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 📧 POLA EMAIL Z WOW STYLEM
  Widget _buildEmailFields(bool isMobile) {
    return Column(
      children: [
        if (!isMobile) ...[
          Row(
            children: [
              Expanded(
                child: _buildWowTextField(
                  controller: _senderNameController,
                  label: 'Nazwa nadawcy',
                  hint: 'np. Metropolitan Investment',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nazwa nadawcy jest wymagana';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildWowTextField(
                  controller: _senderEmailController,
                  label: 'Email nadawcy',
                  hint: 'np. kontakt@metropolitan.pl',
                  icon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email nadawcy jest wymagany';
                    }
                    if (!RegExp(
                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                    ).hasMatch(value)) {
                      return 'Nieprawidłowy format email';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ] else ...[
          _buildWowTextField(
            controller: _senderNameController,
            label: 'Nazwa nadawcy',
            hint: 'np. Metropolitan Investment',
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nazwa nadawcy jest wymagana';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          _buildWowTextField(
            controller: _senderEmailController,
            label: 'Email nadawcy',
            hint: 'np. kontakt@metropolitan.pl',
            icon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email nadawcy jest wymagany';
              }
              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                return 'Nieprawidłowy format email';
              }
              return null;
            },
          ),
        ],
        SizedBox(height: 16),
        _buildWowTextField(
          controller: _subjectController,
          label: 'Temat wiadomości',
          hint: 'Wpisz temat email',
          icon: Icons.subject,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Temat jest wymagany';
            }
            return null;
          },
        ),
      ],
    );
  }

  // 🎨 WOW TEXT FIELD
  Widget _buildWowTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, color: AppThemePro.accentGold)
            : null,
        filled: true,
        fillColor: AppThemePro.backgroundSecondary.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppThemePro.borderSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppThemePro.borderSecondary.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppThemePro.accentGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppThemePro.statusError, width: 2),
        ),
        labelStyle: TextStyle(color: AppThemePro.textSecondary),
        hintStyle: TextStyle(
          color: AppThemePro.textSecondary.withValues(alpha: 0.7),
        ),
      ),
      style: TextStyle(color: AppThemePro.textPrimary),
    );
  }

  // ⚙️ OPCJE EMAIL Z WOW SWITCHAMI
  Widget _buildEmailOptions(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: _buildWowSwitch(
            title: 'Szczegóły inwestycji',
            subtitle: 'Dołącz informacje o inwestycjach',
            value: _includeInvestmentDetails,
            onChanged: (value) {
              setState(() => _includeInvestmentDetails = value);
              _forcePreviewUpdate(); // Immediately update preview when toggling investment details
            },
            icon: Icons.attach_money_outlined,
          ),
        ),
        if (!isMobile) SizedBox(width: 16),
        if (!isMobile)
          Expanded(
            child: _buildWowSwitch(
              title: 'Email grupowy',
              subtitle: 'Wyślij do wszystkich odbiorców',
              value: _isGroupEmail,
              onChanged: (value) => setState(() => _isGroupEmail = value),
              icon: Icons.group_outlined,
            ),
          ),
      ],
    );
  }

  // 🎨 WOW SWITCH
  Widget _buildWowSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.backgroundSecondary.withValues(alpha: 0.5),
            AppThemePro.backgroundPrimary.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (value ? AppThemePro.accentGold : AppThemePro.borderSecondary)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? AppThemePro.accentGold.withValues(alpha: 0.1)
                  : AppThemePro.borderSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? AppThemePro.accentGold : AppThemePro.textSecondary,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppThemePro.accentGold,
            activeTrackColor: AppThemePro.accentGold.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  // 👥 LISTA ODBIORCÓW Z WOW STATUSEM
  Widget _buildRecipientsList(bool isMobile) {
    final allInvestors = widget.selectedInvestors;

    if (allInvestors.isEmpty && _additionalEmails.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppThemePro.statusError.withValues(alpha: 0.1),
              AppThemePro.statusError.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppThemePro.statusError.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_outlined,
                  color: AppThemePro.statusError,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Brak odbiorców email. Dodaj inwestorów lub dodatkowe adresy email.',
                    style: TextStyle(
                      color: AppThemePro.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Przycisk do dodawania odbiorcy
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppThemePro.accentGold, AppThemePro.bondsBlue],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isRecipientsCollapsed = false;
                  });
                  // Scroll do sekcji odbiorców jeśli to możliwe
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // Możemy dodać scroll do sekcji odbiorców jeśli będzie potrzebne
                  });
                },
                icon: Icon(
                  Icons.person_add_outlined,
                  color: AppThemePro.primaryDark,
                ),
                label: Text(
                  'Dodaj odbiorców',
                  style: TextStyle(
                    color: AppThemePro.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _recipientsAnimationController,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppThemePro.statusSuccess.withValues(alpha: 0.1),
                AppThemePro.statusSuccess.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppThemePro.statusSuccess.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              // Header - zawsze widoczny
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_outlined,
                      color: AppThemePro.statusSuccess,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Odbiorcy (${_getTotalRecipientsCount()})',
                        style: TextStyle(
                          color: AppThemePro.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isRecipientsCollapsed
                            ? Icons.expand_more
                            : Icons.expand_less,
                        color: AppThemePro.accentGold,
                      ),
                      onPressed: _toggleRecipientsCollapse,
                      tooltip: _isRecipientsCollapsed
                          ? 'Rozwiń odbiorców'
                          : 'Zwiń odbiorców',
                    ),
                  ],
                ),
              ),

              // Main Content - zwijany/rozwijany
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isRecipientsCollapsed
                    ? const SizedBox.shrink()
                    : Container(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dodatkowi odbiorcy - przeniesione z _buildAdditionalEmails
                            Row(
                              children: [
                                Icon(
                                  Icons.person_add_outlined,
                                  color: AppThemePro.accentGold,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Dodatkowi odbiorcy',
                                  style: TextStyle(
                                    color: AppThemePro.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Spacer(),
                                TextButton.icon(
                                  onPressed: _addAdditionalEmail,
                                  icon: Icon(Icons.add, size: 16),
                                  label: Text('Dodaj'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppThemePro.accentGold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _additionalEmailController,
                                    decoration: InputDecoration(
                                      hintText: 'Wpisz adres email...',
                                      filled: true,
                                      fillColor: AppThemePro.backgroundSecondary
                                          .withValues(alpha: 0.3),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: AppThemePro.borderSecondary
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: AppThemePro.borderSecondary
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: AppThemePro.accentGold,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    style: TextStyle(
                                      color: AppThemePro.textPrimary,
                                    ),
                                    onSubmitted: (_) => _addAdditionalEmail(),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppThemePro.accentGold,
                                        AppThemePro.bondsBlue,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    onPressed: _addAdditionalEmail,
                                    icon: Icon(
                                      Icons.add,
                                      color: AppThemePro.primaryDark,
                                    ),
                                    tooltip: 'Dodaj email',
                                  ),
                                ),
                              ],
                            ),

                            if (_additionalEmails.isNotEmpty) ...[
                              SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppThemePro.backgroundSecondary
                                          .withValues(alpha: 0.5),
                                      AppThemePro.backgroundPrimary.withValues(
                                        alpha: 0.3,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppThemePro.borderSecondary
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dodani odbiorcy:',
                                      style: TextStyle(
                                        color: AppThemePro.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _additionalEmails.map((email) {
                                        return Chip(
                                          label: Text(
                                            email,
                                            style: TextStyle(
                                              color: AppThemePro.textPrimary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          backgroundColor: AppThemePro
                                              .accentGold
                                              .withValues(alpha: 0.1),
                                          deleteIcon: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: AppThemePro.statusError,
                                          ),
                                          onDeleted: () =>
                                              _removeAdditionalEmail(email),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            side: BorderSide(
                                              color: AppThemePro.accentGold
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            if (allInvestors.isNotEmpty) ...[
                              if (_additionalEmails.isNotEmpty)
                                SizedBox(height: 20),
                              Text(
                                'Inwestorzy:',
                                style: TextStyle(
                                  color: AppThemePro.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: allInvestors.length,
                                itemBuilder: (context, index) {
                                  final investor = allInvestors[index];
                                  final client = investor.client;
                                  final isEnabled =
                                      _recipientEnabled[client.id] ?? true;

                                  return Container(
                                    margin: EdgeInsets.only(bottom: 8),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppThemePro.backgroundSecondary
                                              .withValues(alpha: 0.3),
                                          AppThemePro.backgroundPrimary
                                              .withValues(alpha: 0.2),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isEnabled
                                            ? AppThemePro.statusSuccess
                                                  .withValues(alpha: 0.3)
                                            : AppThemePro.statusError
                                                  .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: isEnabled
                                                ? AppThemePro.statusSuccess
                                                : AppThemePro.statusError,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                client.name,
                                                style: TextStyle(
                                                  color: isEnabled
                                                      ? AppThemePro.textPrimary
                                                      : AppThemePro
                                                            .textSecondary
                                                            .withValues(
                                                              alpha: 0.6,
                                                            ),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                client.email,
                                                style: TextStyle(
                                                  color: isEnabled
                                                      ? AppThemePro
                                                            .textSecondary
                                                      : AppThemePro
                                                            .textSecondary
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Checkbox(
                                          value: isEnabled,
                                          onChanged: (value) {
                                            setState(() {
                                              _recipientEnabled[client.id] =
                                                  value ?? true;
                                            });
                                          },
                                          activeColor: AppThemePro.accentGold,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✍️ WOW EDYTOR Z MAKSYMALNYM PRIORYTETEM
  Widget _buildWowEditor(bool isMobile, bool isTablet) {
    return AnimatedBuilder(
      animation: _editorAnimationController,
      builder: (context, _) {
        return Transform.scale(
          scale: _editorBounceAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppThemePro.backgroundSecondary.withValues(alpha: 0.8),
                  AppThemePro.backgroundPrimary.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppThemePro.accentGold.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppThemePro.accentGold.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Column(
                  children: [
                    // Editor Header
                    Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppThemePro.accentGold.withValues(alpha: 0.1),
                            AppThemePro.bondsBlue.withValues(alpha: 0.1),
                          ],
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: AppThemePro.borderSecondary.withValues(
                              alpha: 0.3,
                            ),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: AppThemePro.accentGold,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Edytor treści',
                              style: TextStyle(
                                color: AppThemePro.textPrimary,
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isEditorExpanded
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
                              color: AppThemePro.accentGold,
                            ),
                            onPressed: _toggleEditorExpansion,
                            tooltip: _isEditorExpanded
                                ? 'Zmniejsz edytor'
                                : 'Powiększ edytor',
                          ),
                        ],
                      ),
                    ),

                    // Editor Content
                    Container(
                      height: _isEditorExpanded
                          ? (isMobile ? 400 : 500)
                          : (isMobile ? 250 : 300),
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      child: QuillEditor(
                        controller: _quillController,
                        focusNode: _editorFocusNode,
                        scrollController: ScrollController(),
                        config: QuillEditorConfig(
                          customStyles: DefaultStyles(
                            paragraph: DefaultTextBlockStyle(
                              TextStyle(
                                fontSize: 16,
                                color: AppThemePro.textPrimary,
                                fontFamily: FontFamilyConfig.defaultFont,
                              ),
                              HorizontalSpacing.zero,
                              VerticalSpacing.zero,
                              VerticalSpacing.zero,
                              null,
                            ),
                            h1: DefaultTextBlockStyle(
                              TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppThemePro.textPrimary,
                                fontFamily: FontFamilyConfig.defaultFont,
                              ),
                              HorizontalSpacing.zero,
                              VerticalSpacing.zero,
                              VerticalSpacing.zero,
                              null,
                            ),
                            h2: DefaultTextBlockStyle(
                              TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppThemePro.textPrimary,
                                fontFamily: FontFamilyConfig.defaultFont,
                              ),
                              HorizontalSpacing.zero,
                              VerticalSpacing.zero,
                              VerticalSpacing.zero,
                              null,
                            ),
                            h3: DefaultTextBlockStyle(
                              TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppThemePro.textPrimary,
                                fontFamily: FontFamilyConfig.defaultFont,
                              ),
                              HorizontalSpacing.zero,
                              VerticalSpacing.zero,
                              VerticalSpacing.zero,
                              null,
                            ),
                            placeHolder: DefaultTextBlockStyle(
                              TextStyle(
                                fontSize: 16,
                                color: AppThemePro.textSecondary,
                                fontFamily: FontFamilyConfig.defaultFont,
                              ),
                              HorizontalSpacing.zero,
                              VerticalSpacing.zero,
                              VerticalSpacing.zero,
                              null,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Toolbar
                    Container(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppThemePro.backgroundSecondary.withValues(
                              alpha: 0.9,
                            ),
                            AppThemePro.backgroundPrimary.withValues(
                              alpha: 0.7,
                            ),
                          ],
                        ),
                        border: Border(
                          top: BorderSide(
                            color: AppThemePro.borderSecondary.withValues(
                              alpha: 0.3,
                            ),
                            width: 1,
                          ),
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: IntrinsicWidth(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // � CUSTOM FONT FAMILY DROPDOWN
                              _buildCustomFontToolbar(isMobile),
                              
                              SizedBox(height: 8),
                              
                              // �🎯 ENHANCED QUILL TOOLBAR WITH ALL FORMATTING OPTIONS
                              QuillSimpleToolbar(
                                controller: _quillController,
                                config: QuillSimpleToolbarConfig(
                                  // 🎨 LAYOUT & DISPLAY
                                  multiRowsDisplay: !isMobile,
                                  showDividers: true,

                                  // ✏️ BASIC TEXT FORMATTING (Enhanced)
                                  showBoldButton: true,
                                  showItalicButton: true,
                                  showUnderLineButton: true,
                                  showStrikeThrough: true,
                                  showInlineCode: true,
                                  showClearFormat: true,
                                  showSmallButton: true,
                                  showSubscript: !isMobile,
                                  showSuperscript: !isMobile,

                                  // 🔤 FONT & SIZE CONTROLS
                                  showFontFamily: false, // We have custom font dropdown
                                  showFontSize: true,
                                  
                                  // 🎨 COLOR CONTROLS - Disabled (using custom)
                                  showColorButton: false,
                                  showBackgroundColorButton: false,
                                  
                                  // 📝 STRUCTURAL FORMATTING
                                  showHeaderStyle: true,
                                  showQuote: true,
                                  showCodeBlock:
                                      !isMobile, // Hide on mobile for space
                                  // 📋 LIST CONTROLS
                                  showListBullets: true,
                                  showListNumbers: true,
                                  showListCheck: true,
                                  
                                  // 📐 ALIGNMENT & INDENTATION
                                  showAlignmentButtons: true,
                                  showDirection:
                                      false, // Usually not needed for emails
                                  showIndent: true,
                                  
                                  // 🔗 LINKS & MEDIA
                                  showLink: true,
                                  showSearchButton:
                                      false, // Not needed for email editor
                                  // ↩️ UNDO/REDO
                                  showUndo: true,
                                  showRedo: true,
                                  
                                  // 🎛️ BASIC BUTTON OPTIONS (WORKING CONFIGURATION)
                                  buttonOptions:
                                      QuillSimpleToolbarButtonOptions(
                                        // 📏 FONT SIZE OPTIONS (Enhanced)
                                        fontSize:
                                            QuillToolbarFontSizeButtonOptions(
                                              items: _fontSizes.map(
                                                (key, value) =>
                                                    MapEntry(key, value),
                                              ),
                                              tooltip: 'Rozmiar tekstu',
                                              initialValue: '14',
                                            ),
                                    
                                        // 🎨 ENHANCED COLOR OPTIONS
                                        color: QuillToolbarColorButtonOptions(
                                          tooltip: 'Kolor tekstu',
                                        ),
                                        backgroundColor:
                                            QuillToolbarColorButtonOptions(
                                              tooltip: 'Kolor tła tekstu',
                                            ),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 👁️ LIVE PREVIEW PANEL Z DARK/LIGHT TOGGLE
  Widget _buildLivePreviewPanel(bool isMobile, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.backgroundSecondary.withValues(alpha: 0.9),
            AppThemePro.backgroundPrimary.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppThemePro.accentGold.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.accentGold.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              // Preview Header
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppThemePro.accentGold.withValues(alpha: 0.1),
                      AppThemePro.bondsBlue.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: AppThemePro.borderSecondary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      color: AppThemePro.accentGold,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Podgląd wiadomości',
                            style: TextStyle(
                              color: AppThemePro.textPrimary,
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppThemePro.statusSuccess.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppThemePro.statusSuccess.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.font_download,
                                  size: 14,
                                  color: AppThemePro.statusSuccess,
                                ),
                                
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Zoom Controls
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.zoom_out, size: 20),
                          onPressed: _zoomOutPreview,
                          tooltip: 'Pomniejsz',
                          color: AppThemePro.textSecondary,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppThemePro.backgroundSecondary.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(_previewZoomLevel * 100).round()}%',
                            style: TextStyle(
                              color: AppThemePro.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.zoom_in, size: 20),
                          onPressed: _zoomInPreview,
                          tooltip: 'Powiększ',
                          color: AppThemePro.textSecondary,
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh, size: 20),
                          onPressed: _resetPreviewZoom,
                          tooltip: 'Resetuj zoom',
                          color: AppThemePro.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Preview Content
              Container(
                height: isMobile ? 300 : 400,
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                child: SingleChildScrollView(
                  child: Transform.scale(
                    scale: _previewZoomLevel,
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _isPreviewDarkTheme
                            ? Colors.grey[900]
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isPreviewDarkTheme
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      padding: EdgeInsets.all(16),
                      child: html_package.Html(
                        data: _currentPreviewHtml,
                        style: {
                          // 📝 BASIC ELEMENTS
                          'body': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            lineHeight: html_package.LineHeight.number(1.6),
                            fontSize: html_package.FontSize(16),
                          ),
                          // 🏷️ HEADERS
                          'h1': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: html_package.FontSize(32),
                            margin: html_package.Margins.only(
                              top: 16,
                              bottom: 8,
                            ),
                          ),
                          'h2': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: html_package.FontSize(24),
                            margin: html_package.Margins.only(
                              top: 16,
                              bottom: 8,
                            ),
                          ),
                          'h3': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: html_package.FontSize(20),
                            margin: html_package.Margins.only(
                              top: 16,
                              bottom: 8,
                            ),
                          ),
                          'h4': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: html_package.FontSize(18),
                            margin: html_package.Margins.only(
                              top: 16,
                              bottom: 8,
                            ),
                          ),
                          'h5': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: html_package.FontSize(16),
                            margin: html_package.Margins.only(
                              top: 16,
                              bottom: 8,
                            ),
                          ),
                          'h6': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: html_package.FontSize(14),
                            margin: html_package.Margins.only(
                              top: 16,
                              bottom: 8,
                            ),
                          ),
                          
                          // 📝 PARAGRAPHS AND TEXT
                          'p': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            margin: html_package.Margins.only(bottom: 16),
                            lineHeight: html_package.LineHeight.number(1.6),
                          ),
                          'div': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            lineHeight: html_package.LineHeight.number(1.6),
                          ),
                          'span': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                          ),

                          // ✏️ TEXT FORMATTING
                          'strong': html_package.Style(
                            fontWeight: FontWeight.bold,
                          ),
                          'b': html_package.Style(
                            fontWeight: FontWeight.bold,
                          ),
                          'em': html_package.Style(
                            fontStyle: FontStyle.italic),
                          'i': html_package.Style(fontStyle: FontStyle.italic),
                          'u': html_package.Style(
                            textDecoration: TextDecoration.underline,
                          ),
                          's': html_package.Style(
                            textDecoration: TextDecoration.lineThrough,
                          ),
                          'del': html_package.Style(
                            textDecoration: TextDecoration.lineThrough,
                          ),

                          // 📋 LISTS
                          'ul': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            margin: html_package.Margins.only(
                              left: 20,
                              bottom: 16,
                            ),
                            padding: html_package.HtmlPaddings.only(left: 20),
                          ),
                          'ol': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            margin: html_package.Margins.only(
                              left: 20,
                              bottom: 16,
                            ),
                            padding: html_package.HtmlPaddings.only(left: 20),
                          ),
                          'li': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            margin: html_package.Margins.only(bottom: 8),
                            lineHeight: html_package.LineHeight.number(1.5),
                          ),

                          // 💬 QUOTES AND CODE
                          'blockquote': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white70
                                : Colors.black87,
                            margin: html_package.Margins.only(
                              left: 20,
                              right: 20,
                              bottom: 16,
                            ),
                            padding: html_package.HtmlPaddings.all(16),
                            backgroundColor: _isPreviewDarkTheme
                                ? Colors.grey[800]
                                : Colors.grey[100],
                            fontStyle: FontStyle.italic,
                          ),
                          'code': html_package.Style(
                            backgroundColor: _isPreviewDarkTheme
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            fontFamily: 'Courier New, monospace',
                            padding: html_package.HtmlPaddings.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            fontSize: html_package.FontSize(14),
                          ),
                          'pre': html_package.Style(
                            backgroundColor: _isPreviewDarkTheme
                                ? Colors.grey[900]
                                : Colors.grey[100],
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            fontFamily: 'Courier New, monospace',
                            padding: html_package.HtmlPaddings.all(12),
                            margin: html_package.Margins.only(bottom: 16),
                          ),

                          // 🔗 LINKS
                          'a': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.lightBlue[300]
                                : Colors.blue[700],
                            textDecoration: TextDecoration.underline,
                          ),

                          // 📊 TABLES (basic styling)
                          'table': html_package.Style(
                            width: html_package.Width(
                              100,
                              html_package.Unit.percent,
                            ),
                            margin: html_package.Margins.only(bottom: 16),
                          ),
                          'th': html_package.Style(
                            backgroundColor: _isPreviewDarkTheme
                                ? Colors.grey[700]
                                : Colors.grey[200],
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                            padding: html_package.HtmlPaddings.all(8),
                          ),
                          'td': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            padding: html_package.HtmlPaddings.all(8),
                          ),
                        },
                        onLinkTap: (url, attributes, element) {
                          debugPrint('🔗 Link tapped: $url');
                          // Handle link taps if needed
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🚀 WOW SZYBKIE AKCJE
  Widget _buildWowQuickActions(bool isMobile, bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.backgroundSecondary.withValues(alpha: 0.8),
            AppThemePro.backgroundPrimary.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppThemePro.accentGold.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.electric_bolt,
                color: AppThemePro.accentGold,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Szybkie akcje',
                style: TextStyle(
                  color: AppThemePro.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildWowActionButton(
                icon: Icons.attach_money_outlined,
                label: 'Wstaw szczegóły inwestycji',
                color: AppThemePro.bondsBlue,
                onPressed: _insertInvestmentDetails,
              ),
              _buildWowActionButton(
                icon: Icons.visibility_outlined,
                label: 'Podgląd',
                color: AppThemePro.accentGold,
                onPressed: _togglePreviewVisibility,
              ),
              _buildWowActionButton(
                icon: Icons.science_outlined,
                label: 'Przykładowa treść',
                color: AppThemePro.statusSuccess,
                onPressed: _addSampleContent,
              ),
              _buildWowActionButton(
                icon: Icons.clear,
                label: 'Wyczyść edytor',
                color: AppThemePro.statusError,
                onPressed: _clearEditor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🎯 WOW PRZYCISK AKCJI Z ANIMACJAMI
  Widget _buildWowActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          onTapDown: (_) {
            // Efekt naciskania - przycisk się zmniejsza
          },
          onTapUp: (_) {
            // Efekt odpuszczania - przycisk wraca do normalnego rozmiaru
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    icon,
                    key: ValueKey(icon),
                    color: color,
                    size: 18,
                  ),
                ),
                SizedBox(width: 8),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ❌ WOW ERROR BANNER
  Widget _buildWowErrorBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.statusError.withValues(alpha: 0.1),
            AppThemePro.statusError.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemePro.statusError),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.statusError.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppThemePro.statusError, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: AppThemePro.textPrimary, fontSize: 14),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20),
            onPressed: () => setState(() => _error = null),
            color: AppThemePro.textSecondary,
          ),
        ],
      ),
    );
  }

  // ✅ WOW RESULTS BANNER
  Widget _buildWowResultsBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.statusSuccess.withValues(alpha: 0.1),
            AppThemePro.statusSuccess.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemePro.statusSuccess),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.statusSuccess.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppThemePro.statusSuccess,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wiadomości wysłane pomyślnie!',
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Liczba wysłanych wiadomości: ${_results!.length}',
                  style: TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ⏳ WOW LOADING BANNER
  Widget _buildWowLoadingBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.statusInfo.withValues(alpha: 0.15),
            AppThemePro.accentGold.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemePro.statusInfo, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.statusInfo.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row with spinning indicator
          Row(
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  value: _loadingProgress > 0 ? _loadingProgress : null,
                  valueColor: AlwaysStoppedAnimation<Color>(AppThemePro.accentGold),
                  backgroundColor: AppThemePro.statusInfo.withValues(alpha: 0.2),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wysyłanie Wiadomości Email',
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _loadingMessage,
                      style: TextStyle(
                        color: AppThemePro.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Progress bar and counter (if progress is available)
          if (_loadingProgress > 0) ...[
            const SizedBox(height: 16),
            Column(
              children: [
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _loadingProgress,
                    backgroundColor: AppThemePro.backgroundSecondary,
                    valueColor: AlwaysStoppedAnimation<Color>(AppThemePro.accentGold),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                // Progress text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(_loadingProgress * 100).toInt()}% ukończone',
                      style: TextStyle(
                        color: AppThemePro.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_totalEmailsToSend > 0)
                      Text(
                        '$_emailsSent / $_totalEmailsToSend emaili',
                        style: TextStyle(
                          color: AppThemePro.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 🎬 WOW AKCJE DOLNE
  Widget _buildWowActions(bool canEdit, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.backgroundSecondary.withValues(alpha: 0.9),
            AppThemePro.backgroundPrimary.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppThemePro.accentGold.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.accentGold.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close),
              label: Text('Anuluj'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppThemePro.textSecondary,
                side: BorderSide(color: AppThemePro.borderSecondary),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canEdit ? _sendEmails : null,
              icon: Icon(Icons.send),
              label: Text('Wyślij wiadomości'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemePro.accentGold,
                foregroundColor: AppThemePro.primaryDark,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


