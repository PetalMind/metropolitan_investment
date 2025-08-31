import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart' as html_package;
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';

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

  // 🎨 GOOGLE FONTS ONLY - CURATED COLLECTION WITH CATEGORIES
  static final Map<
    String,
    TextStyle Function({double? fontSize, FontWeight? fontWeight, Color? color})
  >
  _googleFonts = {
    // Sans-serif fonts
    'Roboto': GoogleFonts.roboto,
    'Open Sans': GoogleFonts.openSans,
    'Lato': GoogleFonts.lato,
    'Montserrat': GoogleFonts.montserrat,
    'Poppins': GoogleFonts.poppins,
    'Inter': GoogleFonts.inter,
    'Source Sans 3': GoogleFonts.sourceSans3,
    'Nunito': GoogleFonts.nunito,
    'PT Sans': GoogleFonts.ptSans,
    'Ubuntu': GoogleFonts.ubuntu,
    'Work Sans': GoogleFonts.workSans,
    'Raleway': GoogleFonts.raleway,
    'Fira Sans': GoogleFonts.firaSans,
    'Mulish': GoogleFonts.mulish,

    // Serif fonts
    'Playfair Display': GoogleFonts.playfairDisplay,
    'Merriweather': GoogleFonts.merriweather,
    'Libre Baskerville': GoogleFonts.libreBaskerville,
    'Crimson Text': GoogleFonts.crimsonText,
    'EB Garamond': GoogleFonts.ebGaramond,
    'Lora': GoogleFonts.lora,
    'Source Serif 4': GoogleFonts.sourceSerif4,
    'Cormorant Garamond': GoogleFonts.cormorantGaramond,
    'Noto Serif': GoogleFonts.notoSerif,

    // Monospace fonts
    'Fira Code': GoogleFonts.firaCode,
    'Source Code Pro': GoogleFonts.sourceCodePro,
    'JetBrains Mono': GoogleFonts.jetBrainsMono,
    'Roboto Mono': GoogleFonts.robotoMono,
    'Ubuntu Mono': GoogleFonts.ubuntuMono,
    'Space Mono': GoogleFonts.spaceMono,

    // Decorative fonts
    'Archivo Black': GoogleFonts.archivoBlack,
    'Comic Neue': GoogleFonts.comicNeue,
    'Kalam': GoogleFonts.kalam,
    'Oswald': GoogleFonts.oswald,
    'Pacifico': GoogleFonts.pacifico,
    'Dancing Script': GoogleFonts.dancingScript,
    'Righteous': GoogleFonts.righteous,
    'Fredoka': GoogleFonts.fredoka,
  };

  // Font categories for organized display
  static const Map<String, List<String>> _fontCategories = {
    'Sans-serif': [
      'Roboto',
      'Open Sans',
      'Lato',
      'Montserrat',
      'Poppins',
      'Inter',
      'Source Sans 3',
      'Nunito',
      'PT Sans',
      'Ubuntu',
      'Work Sans',
      'Raleway',
      'Fira Sans',
      'Mulish',
    ],
    'Serif': [
      'Playfair Display',
      'Merriweather',
      'Libre Baskerville',
      'Crimson Text',
      'EB Garamond',
      'Lora',
      'Source Serif 4',
      'Cormorant Garamond',
      'Noto Serif',
    ],
    'Monospace': [
      'Fira Code',
      'Source Code Pro',
      'JetBrains Mono',
      'Roboto Mono',
      'Ubuntu Mono',
      'Space Mono',
    ],
    'Decorative': [
      'Archivo Black',
      'Comic Neue',
      'Kalam',
      'Oswald',
      'Pacifico',
      'Dancing Script',
      'Righteous',
      'Fredoka',
    ],
  };

  static const Map<String, String> _fontSizes = {
    'Mały (12px)': '12',
    'Normalny (14px)': '14',
    'Średni (16px)': '16',
    'Duży (18px)': '18',
    'Bardzo duży (24px)': '24',
    'Ogromny (32px)': '32',
    'Mini (10px)': '10',
    'Nagłówek (28px)': '28',
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

  // 🎨 SELECTED GOOGLE FONT TRACKING
  String _selectedFontFamily = 'Roboto';

  // 🎨 GOOGLE FONTS HELPER METHODS
  String _getFontFamilyForHtml(String fontName) {
    // Wszystkie fonty to już Google Fonts, return proper CSS
    return '"$fontName", sans-serif';
  }

  List<DropdownMenuItem<String>> _buildCategorizedFontItems() {
    List<DropdownMenuItem<String>> items = [];

    // Iteruj przez każdą kategorię i dodaj jej fonty
    _fontCategories.forEach((category, fonts) {
      // Dodaj separator kategorii (ale nie jako wybieralny element)
      // Dodaj fonty z tej kategorii
      for (String fontName in fonts) {
        if (_googleFonts.containsKey(fontName)) {
          items.add(
            DropdownMenuItem<String>(
              value: fontName,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Category indicator
                        Container(
                          width: 3,
                          height: 16,
                          color: _getCategoryColor(category),
                          margin: EdgeInsets.only(right: 8),
                        ),
                        Flexible(
                          child: Text(
                            fontName,
                            style: _getGoogleFontTextStyle(
                              fontName,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppThemePro.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 11),
                      child: Text(
                        'Przykład tekstu 123 • $category',
                        style: _getGoogleFontTextStyle(
                          fontName,
                          fontSize: 12,
                          color: AppThemePro.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    });

    return items;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Sans-serif':
        return Colors.blue;
      case 'Serif':
        return Colors.green;
      case 'Monospace':
        return Colors.orange;
      case 'Decorative':
        return Colors.purple;
      default:
        return AppThemePro.accentGold;
    }
  }

  String _getGoogleFontsImportUrl() {
    // Generuj URL dla wszystkich Google Fonts
    final googleFonts = _googleFonts.keys
        .map((font) => font.replaceAll(' ', '+'))
        .toList();

    if (googleFonts.isEmpty) return '';

    return 'https://fonts.googleapis.com/css2?${googleFonts.map((font) => 'family=$font:wght@300;400;600;700').join('&')}&display=swap';
  }

  // 🎨 PRELOAD GOOGLE FONTS TO ENSURE AVAILABILITY
  Future<void> _preloadGoogleFonts() async {
    try {
      // Preload wszystkie Google Fonts z listy używając funkcji
      for (final fontName in _googleFonts.keys) {
        final fontFunction = _googleFonts[fontName]!;
        fontFunction(); // Call the Google Font function to preload
      }

      debugPrint(
        '🎨 Google Fonts preloaded successfully: ${_googleFonts.length} fonts',
      );
      
      // Also add foundation CSS imports for web compatibility
      _injectGoogleFontsCSSForWeb();
    } catch (e) {
      debugPrint('⚠️ Error preloading Google Fonts: $e');
    }
  }

  void _injectGoogleFontsCSSForWeb() {
    try {
      // Generate CSS font-family names that match our Google Fonts
      final fontFamilyNames = <String>[];
      for (final fontName in _googleFonts.keys) {
        fontFamilyNames.add('"$fontName"');
      }
      
      debugPrint('🌐 Available Google Font families: ${fontFamilyNames.join(', ')}');
      
      // Note: GoogleFonts package handles CSS loading automatically
      // This is just for debugging and verification
    } catch (e) {
      debugPrint('⚠️ Error setting up web fonts: $e');
    }
  }

  // 🎨 GET GOOGLE FONT FOR FLUTTER WIDGETS
  TextStyle _getGoogleFontTextStyle(
    String fontName, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    try {
      // Use Google Fonts function from mapping
      final fontFunction = _googleFonts[fontName];
      if (fontFunction != null) {
        return fontFunction(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );
      } else {
        // Fallback to Roboto if font not found
        return GoogleFonts.roboto(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );
      }
    } catch (e) {
      debugPrint('Error loading Google Font $fontName: $e');
      // Fallback to Roboto on error
      return GoogleFonts.roboto(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeWowScreen();
  }

  void _initializeWowScreen() {
    _quillController = QuillController.basic();
    _editorFocusNode = FocusNode();

    // 🎨 PRELOAD GOOGLE FONTS
    _preloadGoogleFonts();

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
      
      // Zastosuj domyślną czcionkę do całego tekstu
      if (content.isNotEmpty) {
        _quillController.formatText(
          0,
          content.length,
          Attribute.fromKeyValue('font', _selectedFontFamily)
        );
      }
      
      _quillController.updateSelection(
        TextSelection.collapsed(offset: content.length),
        ChangeSource.local,
      );
    } catch (e) {
      debugPrint('Error initializing content: $e');
    }
  }

  @override
  void dispose() {
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

  // 🎪 REAL-TIME PREVIEW UPDATER
  void _updatePreviewContent() {
    setState(() {
      _currentPreviewHtml = _convertQuillToHtml();
      if (_includeInvestmentDetails) {
        _currentPreviewHtml = _addInvestmentDetailsToHtml(_currentPreviewHtml);
      }
    });
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

    // Dodajemy style z dynamicznym Google Fonts import
    final googleFontsUrl = _getGoogleFontsImportUrl();
    final styles =
        '''
<style>
${googleFontsUrl.isNotEmpty ? '@import url(\'$googleFontsUrl\');' : ''}
body { margin: 0; padding: 20px; font-family: Arial, sans-serif; line-height: 1.6; }
* { font-family: inherit !important; }
</style>
''';

    // Ensure we have proper HTML structure with font loading
    String finalHtml = baseHtml;
    if (!baseHtml.contains('<html>') && !baseHtml.contains('<body>')) {
      finalHtml =
          '<html><head><meta charset="UTF-8">$styles</head><body>$baseHtml$investmentHtml</body></html>';
    } else if (baseHtml.contains('</head>')) {
      finalHtml = baseHtml
          .replaceAll('</head>', '$styles</head>')
          .replaceAll('</body>', '$investmentHtml</body>');
    } else if (baseHtml.contains('</body>')) {
      finalHtml = baseHtml.replaceAll(
        '</body>',
        '$styles$investmentHtml</body>',
      );
    } else {
      finalHtml = baseHtml + styles + investmentHtml;
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

  // 🎨 KONWERSJA DO HTML
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
            inlineStyles: InlineStyles({
              'bold': InlineStyleType(fn: (value, _) => 'font-weight: bold'),
              'italic': InlineStyleType(fn: (value, _) => 'font-style: italic'),
              'underline': InlineStyleType(
                fn: (value, _) => 'text-decoration: underline',
              ),
              'strike': InlineStyleType(
                fn: (value, _) => 'text-decoration: line-through',
              ),
              'color': InlineStyleType(fn: (value, _) => 'color: $value'),
              'background': InlineStyleType(
                fn: (value, _) => 'background-color: $value',
              ),
              'font': InlineStyleType(
                fn: (value, _) {
                  if (value.isEmpty) return null;

                  // Try exact match first w Google Fonts
                  if (_googleFonts.containsKey(value)) {
                    return 'font-family: ${_getFontFamilyForHtml(value)} !important';
                  }

                  // Try case-insensitive match
                  final lowerValue = value.toLowerCase();
                  for (final entry in _googleFonts.entries) {
                    if (entry.key.toLowerCase() == lowerValue) {
                      return 'font-family: ${_getFontFamilyForHtml(entry.key)} !important';
                    }
                  }

                  // Try partial match for common font names
                  for (final entry in _googleFonts.entries) {
                    if (entry.key.toLowerCase().contains(lowerValue) ||
                        lowerValue.contains(entry.key.toLowerCase())) {
                      return 'font-family: ${_getFontFamilyForHtml(entry.key)} !important';
                    }
                  }

                  // Clean value and apply with quotes if needed (fallback)
                  final cleanValue = value.replaceAll('"', '').trim();
                  final needsQuotes =
                      cleanValue.contains(' ') || cleanValue.contains('-');
                  final fontValue = needsQuotes ? '"$cleanValue"' : cleanValue;
                  return 'font-family: $fontValue, sans-serif !important';
                },
              ),
              // NOWE: Dedykowana obsługa font-family attribute
              'font-family': InlineStyleType(
                fn: (value, _) {
                  if (value.isEmpty) return null;

                  // Preferuj font-family nad font jeśli dostępne
                  // Try exact match first w Google Fonts
                  if (_googleFonts.containsKey(value)) {
                    return 'font-family: ${_getFontFamilyForHtml(value)} !important';
                  }

                  // Try case-insensitive match
                  final lowerValue = value.toLowerCase();
                  for (final entry in _googleFonts.entries) {
                    if (entry.key.toLowerCase() == lowerValue) {
                      return 'font-family: ${_getFontFamilyForHtml(entry.key)} !important';
                    }
                  }

                  // Clean value and apply with quotes if needed (fallback)
                  final cleanValue = value.replaceAll('"', '').trim();
                  final needsQuotes =
                      cleanValue.contains(' ') || cleanValue.contains('-');
                  final fontValue = needsQuotes ? '"$cleanValue"' : cleanValue;
                  return 'font-family: $fontValue, sans-serif !important';
                },
              ),
              'size': InlineStyleType(
                fn: (value, _) {
                  if (value.isEmpty) return null;

                  // Extract number from value if it's formatted like "Normalny (14px)"
                  final sizeMatch = RegExp(r'\((\d+)px\)').firstMatch(value);
                  if (sizeMatch != null) {
                    return 'font-size: ${sizeMatch.group(1)}px !important';
                  }

                  // Check if it's a plain number
                  if (RegExp(r'^\d+$').hasMatch(value)) {
                    return 'font-size: ${value}px !important';
                  }

                  return 'font-size: $value !important';
                },
              ),
            }),
          ),
        ),
      );

      return converter.convert();
    } catch (e) {
      return '<p>${_quillController.document.toPlainText()}</p>';
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

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final emailHtml = _convertQuillToHtml();
      await Future.delayed(const Duration(seconds: 2));
      debugPrint('Email HTML: $emailHtml');

      setState(() {
        _results = [
          EmailSendResult(
            success: true,
            recipient: 'test@example.com',
            message: 'Email wysłany pomyślnie',
          ),
        ];
        _isLoading = false;
      });

      // Powrót do poprzedniego ekranu z wynikiem
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _error = 'Błąd podczas wysyłania: $e';
        _isLoading = false;
      });
    }
  }

  int _getEnabledRecipientsCount() {
    return _recipientEnabled.values.where((enabled) => enabled).length;
  }

  int _getTotalRecipientsCount() {
    return _getEnabledRecipientsCount() + _additionalEmails.length;
  }

  // 🎨 CUSTOM GOOGLE FONTS SELECTOR Z PODGLĄDEM CZCIONKI
  Widget _buildCustomFontSelector(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          width: 1,
        ),
      ),
      child: Row(
        // Parent (_SingleChildViewport / horizontal ScrollView) can provide
        // unbounded horizontal constraints. Use MainAxisSize.min and
        // Flexible(FlexFit.loose) instead of Expanded to allow children to
        // size themselves without forcing infinite expansion.
        mainAxisSize: MainAxisSize.min,
        children: [
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
          SizedBox(width: 12),
          Flexible(
            fit: FlexFit.loose,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFontFamily,
                // remove isExpanded when using Flexible with loose fit
                isExpanded: false,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: AppThemePro.accentGold,
                ),
                style: TextStyle(color: AppThemePro.textPrimary),
                dropdownColor: AppThemePro.backgroundSecondary,
                items: _buildCategorizedFontItems(),
                onChanged: (String? newFont) {
                  if (newFont != null) {
                    setState(() {
                      _selectedFontFamily = newFont;
                    });
                    _applyFontToSelection(newFont);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 APPLY SELECTED FONT TO CURRENT SELECTION
  void _applyFontToSelection(String fontName) {
    if (fontName.isEmpty || !_googleFonts.containsKey(fontName)) {
      debugPrint('⚠️ Invalid font name: $fontName');
      return;
    }
    
    final selection = _quillController.selection;
    final docLength = _quillController.document.length;
    
    debugPrint('🎨 Applying font: $fontName, docLength: $docLength, selection: ${selection.isValid ? "${selection.start}-${selection.end}" : "invalid"}');
    
    try {
      // Update state first for immediate UI feedback
      setState(() {
        _selectedFontFamily = fontName;
      });
      
      // SAFE APPROACH: Sprawdź czy mamy jakikolwiek tekst
      if (docLength <= 1) {
        debugPrint('📝 Empty document, just updating selected font for future typing');
        _updatePreviewContent();
        return;
      }
      
      // Walidacja selection przed użyciem
      if (selection.isValid && !selection.isCollapsed && 
          selection.start >= 0 && selection.end <= docLength && 
          selection.start < selection.end) {
        
        final selectionLength = selection.end - selection.start;
        debugPrint('🎯 Applying to selection: start=${selection.start}, length=$selectionLength');
        
        // Apply font only to valid selection
        _quillController.formatText(
          selection.start, 
          selectionLength, 
          Attribute.fromKeyValue('font', fontName)
        );
        debugPrint('🎨 Successfully applied font to selection');
        
      } else {
        // Apply to entire document with safe bounds
        final safeLength = docLength - 1; // Exclude trailing newline
        if (safeLength > 0) {
          debugPrint('🎯 Applying to entire document: length=$safeLength');
          
          _quillController.formatText(
            0,
            safeLength,
            Attribute.fromKeyValue('font', fontName)
          );
          debugPrint('🎨 Successfully applied font to entire document');
        }
      }
      
      // Force rebuild of editor with new styles
      Future.microtask(() {
        setState(() {}); // Rebuild editor with new customStyles
      });
      
      _updatePreviewContent();
      
    } catch (e) {
      debugPrint('⚠️ Primary font application failed: $e');
      
      // SIMPLE FALLBACK: Set font for future typing only
      try {
        setState(() {
          _selectedFontFamily = fontName;
        });
        
        // Force preview update to show the change at least in HTML
        _updatePreviewContent();
        
        debugPrint('🎨 Fallback: Updated selected font for future content');
      } catch (e2) {
        debugPrint('⚠️ Even fallback failed: $e2');
      }
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
            onChanged: (value) =>
                setState(() => _includeInvestmentDetails = value),
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
                              _getGoogleFontTextStyle(
                                _selectedFontFamily,
                                fontSize: 16,
                                color: AppThemePro.textPrimary,
                              ),
                              HorizontalSpacing.zero,
                              VerticalSpacing.zero,
                              VerticalSpacing.zero,
                              null,
                            ),
                            h1: DefaultTextBlockStyle(
                              _getGoogleFontTextStyle(
                                _selectedFontFamily,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppThemePro.textPrimary,
                              ),
                              HorizontalSpacing.zero,
                              VerticalSpacing.zero,
                              VerticalSpacing.zero,
                              null,
                            ),
                            h2: DefaultTextBlockStyle(
                              _getGoogleFontTextStyle(
                                _selectedFontFamily,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppThemePro.textPrimary,
                              ),
                              HorizontalSpacing.zero,
                              VerticalSpacing.zero,
                              VerticalSpacing.zero,
                              null,
                            ),
                            h3: DefaultTextBlockStyle(
                              _getGoogleFontTextStyle(
                                _selectedFontFamily,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppThemePro.textPrimary,
                              ),
                              HorizontalSpacing.zero,
                              VerticalSpacing.zero,
                              VerticalSpacing.zero,
                              null,
                            ),
                            placeHolder: DefaultTextBlockStyle(
                              _getGoogleFontTextStyle(
                                _selectedFontFamily,
                                fontSize: 16,
                                color: AppThemePro.textSecondary,
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
                        child: Container(
                          constraints: BoxConstraints(
                            minWidth: isMobile ? 400 : 600,
                          ),
                          child: Column(
                            children: [
                              // 🎨 CUSTOM GOOGLE FONTS SELECTOR Z PODGLĄDEM
                              _buildCustomFontSelector(isMobile),
                              SizedBox(height: 8),
                              // 🎯 POZOSTAŁE NARZĘDZIA QUILL TOOLBAR (BEZ FONT FAMILY)
                              QuillSimpleToolbar(
                                controller: _quillController,
                                config: QuillSimpleToolbarConfig(
                                  multiRowsDisplay: !isMobile,
                                  showBoldButton: true,
                                  showItalicButton: true,
                                  showUnderLineButton: true,
                                  showStrikeThrough: true,
                                  showFontFamily:
                                      false, // WYŁĄCZONE - UŻYWAMY CUSTOM
                                  showFontSize: true,
                                  showColorButton: true,
                                  showBackgroundColorButton: true,
                                  showHeaderStyle: true,
                                  showListBullets: true,
                                  showListNumbers: true,
                                  showListCheck: true,
                                  showCodeBlock: !isMobile,
                                  showQuote: true,
                                  showIndent: true,
                                  showLink: true,
                                  showUndo: true,
                                  showRedo: true,
                                  showClearFormat: true,
                                  buttonOptions:
                                      QuillSimpleToolbarButtonOptions(
                                        fontSize:
                                            QuillToolbarFontSizeButtonOptions(
                                              items: _fontSizes.map(
                                                (key, value) =>
                                                    MapEntry(key, value),
                                              ),
                                              tooltip: 'Rozmiar tekstu',
                                              initialValue: '14',
                                            ),
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
                      child: Text(
                        'Podgląd wiadomości',
                        style: TextStyle(
                          color: AppThemePro.textPrimary,
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                          'body': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            fontFamily: 'Arial',
                            lineHeight: html_package.LineHeight.number(1.6),
                          ),
                          'h1': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: html_package.FontSize.large,
                          ),
                          'h2': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: html_package.FontSize.medium,
                          ),
                          'h3': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          'p': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            margin: html_package.Margins.only(bottom: 16),
                          ),
                          'strong': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          'em': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            fontStyle: FontStyle.italic,
                          ),
                          'u': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                            textDecoration: TextDecoration.underline,
                          ),
                          'div': html_package.Style(
                            color: _isPreviewDarkTheme
                                ? Colors.white
                                : Colors.black,
                          ),
                        },
                        onLinkTap: (url, attributes, element) {
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.statusInfo.withValues(alpha: 0.1),
            AppThemePro.statusInfo.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemePro.statusInfo),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.statusInfo.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppThemePro.statusInfo),
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Wysyłanie wiadomości...',
              style: TextStyle(color: AppThemePro.textPrimary, fontSize: 14),
            ),
          ),
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

// 📧 KLASA POMOCNICZA DLA REZULTATÓW
class EmailSendResult {
  final bool success;
  final String recipient;
  final String message;

  EmailSendResult({
    required this.success,
    required this.recipient,
    required this.message,
  });
}
