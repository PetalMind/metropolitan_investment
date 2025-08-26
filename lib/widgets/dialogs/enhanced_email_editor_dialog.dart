import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';

/// Enhanced email editor dialog with rich text formatting
class EnhancedEmailEditorDialog extends StatefulWidget {
  final List<InvestorSummary> selectedInvestors;
  final VoidCallback onEmailSent;
  final String? initialSubject;
  final String? initialMessage;

  const EnhancedEmailEditorDialog({
    super.key,
    required this.selectedInvestors,
    required this.onEmailSent,
    this.initialSubject,
    this.initialMessage,
  });

  @override
  State<EnhancedEmailEditorDialog> createState() =>
      _EnhancedEmailEditorDialogState();
}

class _EnhancedEmailEditorDialogState extends State<EnhancedEmailEditorDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late QuillController _quillController;
  late FocusNode _editorFocusNode;

  final _formKey = GlobalKey<FormState>();
  final _senderEmailController = TextEditingController();
  final _senderNameController = TextEditingController(
    text: 'Metropolitan Investment',
  );
  final _subjectController = TextEditingController();

  // Debounce timer for preview updates to avoid rapid rebuilds
  Timer? _previewDebounceTimer;
  
  // Auto-hide UI state when user is typing
  bool _isUserTyping = false;
  Timer? _typingDebounceTimer;

  // ⭐ Custom font sizes map - numeric values for precise control
  static const Map<String, String> _customFontSizes = {
    '8px': '8',
    '10px': '10',
    '12px': '12',
    '14px': '14',
    '16px': '16',
    '18px': '18',
    '20px': '20',
    '22px': '22',
    '24px': '24',
    '28px': '28',
    '32px': '32',
    '36px': '36',
    '48px': '48',
  };

  // ⭐ Mobile-friendly reduced font sizes
  static const Map<String, String> _mobileFontSizes = {
    '10px': '10',
    '14px': '14',
    '18px': '18',
    '24px': '24',
    '32px': '32',
  };

  // ⭐ Custom font families with web-safe fallbacks
  static const Map<String, String> _customFontFamilies = {
    'Arial': 'Arial, sans-serif',
    'Helvetica': 'Helvetica, Arial, sans-serif',
    'Times New Roman': 'Times New Roman, Times, serif',
    'Georgia': 'Georgia, serif',
    'Verdana': 'Verdana, sans-serif',
    'Calibri': 'Calibri, sans-serif',
    'Roboto': 'Roboto, sans-serif',
    'Open Sans': 'Open Sans, sans-serif',
    'Lato': 'Lato, sans-serif',
    'Source Sans Pro': 'Source Sans Pro, sans-serif',
    'Montserrat': 'Montserrat, sans-serif',
    'Oswald': 'Oswald, sans-serif',
    'Courier New': 'Courier New, Courier, monospace',
    'Monaco': 'Monaco, Consolas, monospace',
  };

  // ⭐ Mobile-friendly reduced font families
  static const Map<String, String> _mobileFontFamilies = {
    'Arial': 'Arial, sans-serif',
    'Times New Roman': 'Times New Roman, serif',
    'Georgia': 'Georgia, serif',
    'Courier New': 'Courier New, monospace',
  };

  // ⭐ Predefined color palette for quick selection
  static const List<Color> _predefinedColors = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.brown,
    Color(0xFF1976D2), // Professional blue
    Color(0xFFD4AF37), // Gold accent
    Color(0xFF2E2E2E), // Dark gray
    Color(0xFF666666), // Light gray
    Color(0xFF4CAF50), // Success green
    Color(0xFFF44336), // Error red
  ];

  bool _isLoading = false;
  bool _includeInvestmentDetails = true;
  bool _isGroupEmail = false;
  bool _previewDarkMode = false; // Theme toggle for preview
  String? _error;
  List<EmailSendResult>? _results;

  // Enhanced loading and debugging states
  String _loadingMessage = 'Przygotowywanie...';
  int _currentEmailIndex = 0;
  int _totalEmailsToSend = 0;
  bool _showDetailedProgress = false;
  final List<String> _debugLogs = [];

  // Email recipient management
  final Map<String, bool> _recipientEnabled = {};
  final Map<String, String> _recipientEmails = {};
  final List<String> _additionalEmails = [];
  final Map<String, bool> _additionalEmailsConfirmed = {};
  String? _selectedPreviewRecipient;
  
  // Individual content management
  final Map<String, QuillController> _individualControllers = {};
  final Map<String, FocusNode> _individualFocusNodes = {};
  String? _selectedRecipientForEditing;
  bool _useIndividualContent = false;

  final _emailAndExportService = EmailAndExportService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize QuillController with proper configuration
    _quillController = QuillController.basic();
    _editorFocusNode = FocusNode();

    // Set initial values
    _subjectController.text =
        widget.initialSubject ??
        'Aktualizacja portfela inwestycyjnego - Metropolitan Investment';

    // Add listener for preview updates
    _quillController.addListener(_updatePreview);
    
    // Add focus listener to detect when user starts interacting with editor
    _editorFocusNode.addListener(_onEditorFocusChange);
    
    // Initialize content after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeEditorContent();
        // Request focus after content is initialized
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _editorFocusNode.requestFocus();
          }
        });
      }
    });

    // Initialize recipients
    _initializeRecipients();
    _loadSmtpEmail();
  }

  void _initializeEditorContent() {
    try {
      if (widget.initialMessage != null) {
        _insertInitialContent(widget.initialMessage!);
      } else {
        _insertDefaultTemplate();
      }
    } catch (e) {
      debugPrint('Error initializing editor: $e');
    }
  }

  void _insertInitialContent(String content) {
    try {
      // Clear existing content
      _quillController.clear();
      
      // Insert new content with delay to ensure proper initialization
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          try {
            // Insert content at the beginning
            _quillController.document.insert(0, content);
            // Set cursor position at the end of inserted content
            _quillController.updateSelection(
              TextSelection.collapsed(offset: content.length),
              ChangeSource.local,
            );
            // Trigger rebuild to show changes
            if (mounted) {
              setState(() {});
            }
          } catch (e) {
            debugPrint('Error inserting content: $e');
            // Fallback: try simple text insertion
            _insertContentFallback(content);
          }
        }
      });
    } catch (e) {
      debugPrint('Error during content insertion: $e');
      _insertContentFallback(content);
    }
  }

  void _insertContentFallback(String content) {
    try {
      _quillController.clear();
      _quillController.document.insert(0, content);
      _quillController.updateSelection(
        TextSelection.collapsed(offset: content.length),
        ChangeSource.local,
      );
    } catch (fallbackError) {
      debugPrint('Fallback content insertion failed: $fallbackError');
    }
  }

  void _initializeRecipients() {
    for (final investor in widget.selectedInvestors) {
      final clientId = investor.client.id;
      final email = investor.client.email;

      _recipientEnabled[clientId] =
          email.isNotEmpty &&
          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
      _recipientEmails[clientId] = email;
      
      // Create individual QuillController and FocusNode for each recipient
      final controller = QuillController.basic();
      final focusNode = FocusNode();
      
      // Add listeners for typing detection
      controller.addListener(_updatePreview);
      focusNode.addListener(_onEditorFocusChange);
      
      _individualControllers[clientId] = controller;
      _individualFocusNodes[clientId] = focusNode;
    }
    
    // Auto-select first available recipient for preview
    final availableRecipients = widget.selectedInvestors
        .where((inv) => _recipientEnabled[inv.client.id] ?? false)
        .toList();
    if (availableRecipients.isNotEmpty) {
      _selectedPreviewRecipient ??= availableRecipients.first.client.id;
      _selectedRecipientForEditing ??= availableRecipients.first.client.id;
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
      // Ignore error - user can enter email manually
    }
  }

  void _insertDefaultTemplate() {
    const defaultTemplate = '''Szanowni Państwo,

Przesyłamy aktualne informacje dotyczące Państwa inwestycji w Metropolitan Investment.

Poniżej znajdą Państwo szczegółowe podsumowanie swojego portfela inwestycyjnego.

W razie pytań prosimy o kontakt z naszym działem obsługi klienta.

Z poważaniem,
Zespół Metropolitan Investment''';

    try {
      // Clear existing content
      _quillController.clear();
      
      // Insert template with delay for proper initialization
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          try {
            _quillController.document.insert(0, defaultTemplate);
            _quillController.updateSelection(
              TextSelection.collapsed(offset: defaultTemplate.length),
              ChangeSource.local,
            );
            if (mounted) {
              setState(() {});
            }
          } catch (e) {
            debugPrint('Error inserting template: $e');
            // Fallback insertion
            _insertContentFallback(defaultTemplate);
          }
        }
      });
    } catch (e) {
      debugPrint('Error during template insertion: $e');
      _insertContentFallback(defaultTemplate);
    }
  }

  void _updatePreview() {
    // Debounce preview updates to avoid heavy rebuilds while typing.
    _previewDebounceTimer?.cancel();
    _previewDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          // Trigger rebuild to refresh preview
        });
      }
    });
    
    // Handle typing state for UI auto-hiding
    _handleUserTyping();
  }
  
  /// Handle user typing detection for auto-hiding UI elements
  void _handleUserTyping() {
    // Cancel previous timer
    _typingDebounceTimer?.cancel();
    
    // Set typing state immediately if not already set
    if (!_isUserTyping && mounted) {
      setState(() {
        _isUserTyping = true;
      });
    }
    
    // Set timer to detect when user stops typing (2 seconds of inactivity)
    _typingDebounceTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted && _isUserTyping) {
        setState(() {
          _isUserTyping = false;
        });
      }
    });
  }
  
  /// Handle editor focus change - trigger typing detection on focus
  void _onEditorFocusChange() {
    if (_editorFocusNode.hasFocus) {
      // Trigger typing state when editor gains focus
      _handleUserTyping();
    }
  }

  // ⭐ Custom Color Picker Methods
  
  /// Shows an enhanced color picker dialog with predefined palette and custom color wheel
  Future<Color?> _showEnhancedColorPicker(BuildContext context, {
    required bool isBackground,
    Color? currentColor,
  }) async {
    Color pickerColor = currentColor ?? Colors.black;
    
    return showDialog<Color>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppThemePro.backgroundPrimary,
          title: Text(
            isBackground ? 'Wybierz kolor tła' : 'Wybierz kolor tekstu',
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 350,
            height: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Predefined color palette
                  _buildPredefinedColorPalette((Color color) {
                    pickerColor = color;
                  }),
                  
                  const SizedBox(height: 24),
                  
                  // Divider with label
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppThemePro.borderSecondary)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Lub wybierz custom kolor',
                          style: TextStyle(
                            color: AppThemePro.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppThemePro.borderSecondary)),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Custom color picker wheel
                  ColorPicker(
                    pickerColor: pickerColor,
                    onColorChanged: (Color color) {
                      pickerColor = color;
                    },
                    colorPickerWidth: 300,
                    pickerAreaHeightPercent: 0.7,
                    enableAlpha: false,
                    displayThumbColor: true,
                    paletteType: PaletteType.hueWheel,
                    labelTypes: const [ColorLabelType.hex],
                    hexInputBar: true,
                    pickerAreaBorderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Anuluj',
                style: TextStyle(color: AppThemePro.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(pickerColor),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemePro.accentGold,
                foregroundColor: Colors.black,
              ),
              child: const Text('Wybierz'),
            ),
          ],
        );
      },
    );
  }
  
  /// Builds a predefined color palette widget for quick color selection
  Widget _buildPredefinedColorPalette(Function(Color) onColorSelected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Szybki wybór kolorów',
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _predefinedColors.map((color) {
              return GestureDetector(
                onTap: () => onColorSelected(color),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: color == Colors.white 
                        ? AppThemePro.borderSecondary 
                        : Colors.transparent,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: color == Colors.white
                    ? Icon(
                        Icons.format_color_text,
                        color: AppThemePro.textSecondary,
                        size: 16,
                      )
                    : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  /// Applies selected color to the current text selection
  void _applyColorToSelection(Color color, {required bool isBackground}) {
    final controller = _getCurrentController();
    final selection = controller.selection;
    
    if (!selection.isValid) return;
    
    final hexColor = '#${color.r.round().toRadixString(16).padLeft(2, '0')}'
        '${color.g.round().toRadixString(16).padLeft(2, '0')}'
        '${color.b.round().toRadixString(16).padLeft(2, '0')}';
    
    if (isBackground) {
      controller.formatSelection(Attribute.fromKeyValue('background', hexColor));
    } else {
      controller.formatSelection(Attribute.fromKeyValue('color', hexColor));
    }
    
    // Trigger preview update
    _updatePreview();
  }

  @override
  void dispose() {
    _quillController.removeListener(_updatePreview);
    _editorFocusNode.removeListener(_onEditorFocusChange);
    _previewDebounceTimer?.cancel();
    _typingDebounceTimer?.cancel();
    _tabController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _senderEmailController.dispose();
    _senderNameController.dispose();
    _subjectController.dispose();
    
    // Dispose individual controllers and focus nodes
    for (final controller in _individualControllers.values) {
      controller.removeListener(_updatePreview);
      controller.dispose();
    }
    for (final focusNode in _individualFocusNodes.values) {
      focusNode.removeListener(_onEditorFocusChange);
      focusNode.dispose();
    }
    
    super.dispose();
  }

  /// Create enhanced converter options for rich text formatting
  /// Supports dynamic font sizes, colors, and font families
  ConverterOptions _createEnhancedConverterOptions() {
    return ConverterOptions(
      converterOptions: OpConverterOptions(
        inlineStylesFlag: true,
        inlineStyles: InlineStyles({
          'bold': InlineStyleType(fn: (value, _) => 'font-weight: bold'),
          'italic': InlineStyleType(fn: (value, _) => 'font-style: italic'),
          'underline': InlineStyleType(fn: (value, _) => 'text-decoration: underline'),
          'strike': InlineStyleType(fn: (value, _) => 'text-decoration: line-through'),
          
          // ⭐ Enhanced color support - handles hex, rgb, and named colors
          'color': InlineStyleType(fn: (value, _) {
            if (value.isEmpty) return '';
            // Handle hex colors
            if (value.startsWith('#')) return 'color: $value';
            // Handle rgb/rgba colors
            if (value.startsWith('rgb')) return 'color: $value';
            // Handle HSL colors
            if (value.startsWith('hsl')) return 'color: $value';
            // Default case
            return 'color: $value';
          }),
          
          // ⭐ Enhanced background color support
          'background': InlineStyleType(fn: (value, _) {
            if (value.isEmpty) return '';
            // Handle hex colors
            if (value.startsWith('#')) return 'background-color: $value';
            // Handle rgb/rgba colors
            if (value.startsWith('rgb')) return 'background-color: $value';
            // Handle HSL colors
            if (value.startsWith('hsl')) return 'background-color: $value';
            // Default case
            return 'background-color: $value';
          }),
          
          // ⭐ Enhanced font family support with fallback fonts
          'font': InlineStyleType(fn: (value, _) {
            if (value.isEmpty) return '';
            
            // Sprawdź czy wartość istnieje w naszej mapie custom fonts
            if (_customFontFamilies.containsKey(value)) {
              return 'font-family: ${_customFontFamilies[value]}';
            }
            
            // Sprawdź czy to już jest pełna definicja z fallback (zawiera przecinek)
            if (value.contains(',')) {
              return 'font-family: $value';
            }
            
            // Dla custom wartości dodaj bezpieczny fallback
            return 'font-family: "$value", Arial, sans-serif';
          }),
          
          // ⭐ Enhanced numeric font size support with better mapping
          'size': InlineStyleType(fn: (value, _) {
            if (value.isEmpty) return '';
            
            // Sprawdź czy wartość istnieje w naszej mapie custom font sizes
            final matchingSize = _customFontSizes.entries
                .firstWhere((e) => e.value == value, orElse: () => const MapEntry('', ''));
            
            if (matchingSize.key.isNotEmpty) {
              // Użyj wartości z mapy (już w px)
              return 'font-size: ${matchingSize.value}px';
            }
            
            // Handle pure numeric values (assume pixels)
            if (RegExp(r'^\d+$').hasMatch(value)) {
              return 'font-size: ${value}px';
            }
            
            // Handle values with units
            if (value.endsWith('px') || value.endsWith('pt') || 
                value.endsWith('em') || value.endsWith('rem') || 
                value.endsWith('%')) {
              return 'font-size: $value';
            }
            
            // Legacy support for predefined sizes
            final legacySizes = {
              'small': '12px',
              'large': '18px', 
              'huge': '24px'
            };
            
            if (legacySizes.containsKey(value)) {
              return 'font-size: ${legacySizes[value]}';
            }
            
            // Fallback - assume it's a valid CSS font-size value or default to 14px
            return value.isNotEmpty ? 'font-size: $value' : 'font-size: 14px';
          }),
          
          'code': InlineStyleType(fn: (value, _) => 
            'background-color: #f4f4f4; padding: 2px 4px; border-radius: 3px; font-family: monospace'),
          'link': InlineStyleType(fn: (value, _) => 'color: #007bff; text-decoration: underline'),
        }),
      ),
    );
  }

  /// **NOWA NIEZAWODNA FUNKCJA KONWERSJI QUILL → HTML**
  ///
  /// Prostsze, bardziej niezawodne rozwiązanie, które zawsze przenosi całą treść
  /// z edytora Quill do HTML, bez problemów z formatowaniem i emoji.
  String _convertQuillToReliableHtml(QuillController controller) {
    try {
      if (kDebugMode) {
        print('🔄 [EnhancedConversion] Starting enhanced conversion for controller');
      }

      // Check if document is empty
      if (controller.document.length <= 1) {
        return '<p></p>';
      }

      final plainText = controller.document.toPlainText();
      if (plainText.trim().isEmpty) {
        return '<p></p>';
      }

      if (kDebugMode) {
        print('🔄 [EnhancedConversion] Plain text length: ${plainText.length}');
        print('🔄 [EnhancedConversion] Plain text preview: ${plainText.substring(0, math.min(200, plainText.length))}...');
      }

      // Try enhanced conversion with formatting
      try {
        final delta = controller.document.toDelta();
        
        if (kDebugMode) {
          print('🔄 [EnhancedConversion] Delta operations count: ${delta.toList().length}');
        }

        // Use enhanced converter with full formatting support
        final converter = QuillDeltaToHtmlConverter(
          controller.document.toDelta().toJson(),
          _createEnhancedConverterOptions(),
        );

        final html = converter.convert();

        if (kDebugMode) {
          print('✅ [EnhancedConversion] Enhanced conversion successful, HTML length: ${html.length}');
          print('🔄 [EnhancedConversion] HTML preview: ${html.substring(0, math.min(500, html.length))}...');
        }

        return html;
      } catch (enhancedError) {
        if (kDebugMode) {
          print('⚠️ [EnhancedConversion] Enhanced conversion failed: $enhancedError');
        }

        // Fallback to basic HTML conversion
        final html = _convertPlainTextToBasicHtml(plainText);
        
        if (kDebugMode) {
          print('🔄 [EnhancedConversion] Using fallback conversion, HTML length: ${html.length}');
        }
        
        return html;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [EnhancedConversion] Complete conversion failure: $e');
      }

      // Last resort fallback
      try {
        final plainText = controller.document.toPlainText();
        return _convertPlainTextToBasicHtml(plainText);
      } catch (fallbackError) {
        if (kDebugMode) {
          print('❌ [EnhancedConversion] Even fallback failed: $fallbackError');
        }
        return '<p>Błąd podczas konwersji treści.</p>';
      }
    }
  }

  /// **UPROSZCZONA FUNKCJA DODAWANIA SZCZEGÓŁÓW INWESTYCJI**
  ///
  /// Zawsze dodaje szczegóły inwestycji na końcu treści, niezależnie od tego
  /// co już jest w treści emaila.
  String _ensureInvestmentDetails(
    String html, {
    InvestorSummary? specificInvestor,
    List<InvestorSummary>? allInvestors,
  }) {
    if (kDebugMode) {
      print('🔄 [InvestmentDetails] Adding investment details to HTML');
      print(
        '🔄 [InvestmentDetails] Specific investor: ${specificInvestor?.client.name}',
      );
      print(
        '🔄 [InvestmentDetails] All investors count: ${allInvestors?.length}',
      );
    }

    String additionalContent = '';

    if (specificInvestor != null) {
      // Dodaj szczegóły dla konkretnego inwestora
      additionalContent = _buildHtmlInvestmentsTableForInvestor(
        specificInvestor,
      );
    } else if (allInvestors != null && allInvestors.isNotEmpty) {
      // Dodaj zbiorcze szczegóły dla wszystkich inwestorów
      additionalContent = _buildAggregatedInvestmentsTableHtml(allInvestors);
    }

    if (additionalContent.isNotEmpty) {
      // Znajdź najlepsze miejsce do wstawienia - przed zamykającymi tagami jeśli są
      final insertPattern = RegExp(r'</div>\s*</body>|</body>|$');
      final match = insertPattern.firstMatch(html);

      if (match != null) {
        final insertIndex = match.start;
        html =
            '${html.substring(0, insertIndex)}'
            '\n\n'
            '$additionalContent'
            '\n\n'
            '${html.substring(insertIndex)}';
      } else {
        // Proste dodanie na końcu jeśli nie ma struktury
        html += '\n\n$additionalContent';
      }

      if (kDebugMode) {
        print(
          '✅ [InvestmentDetails] Added investment details, final length: ${html.length}',
        );
      }
    }

    return html;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canEdit = Provider.of<AuthProvider>(context).isAdmin;
        final screenSize = MediaQuery.of(context).size;
        final isSmallScreen = constraints.maxWidth < 768; // Tablet breakpoint
        final isMobile = constraints.maxWidth < 480; // Mobile breakpoint
        final isMediumScreen = constraints.maxWidth < 900;
        
        // Responsive dialog sizing
        final dialogWidth = isMobile 
            ? screenSize.width * 0.98 
            : isSmallScreen 
                ? screenSize.width * 0.95
                : isMediumScreen 
                    ? screenSize.width * 0.85
                    : screenSize.width * 0.8;
        
        final dialogHeight = isMobile
            ? screenSize.height * 0.98
            : isSmallScreen 
                ? screenSize.height * 0.95
                : screenSize.height * 0.9;
        
        final dialogPadding = isMobile ? 4.0 : isSmallScreen ? 8.0 : 16.0;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(dialogPadding),
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            decoration: BoxDecoration(
              color: AppThemePro.backgroundPrimary,
              borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(isMobile, isSmallScreen),
                _buildTabBar(isMobile, isSmallScreen),
                Expanded(child: _buildTabContent(isMobile, isSmallScreen)),
                if (_error != null) _buildError(),
                if (_results != null) _buildResults(isMobile),
                if (_showDetailedProgress) _buildProgressIndicator(),
                _buildActions(canEdit, isMobile, isSmallScreen),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMobile, bool isSmallScreen) {
    final headerPadding = isMobile ? 12.0 : isSmallScreen ? 16.0 : 24.0;
    
    return Container(
      padding: EdgeInsets.all(headerPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.backgroundPrimary,
            AppThemePro.accentGold.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isMobile ? 12 : 16),
          topRight: Radius.circular(isMobile ? 12 : 16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit_outlined, 
            color: Colors.white, 
            size: isMobile ? 24 : 28,
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMobile ? 'Edytor Email' : 'Zaawansowany Edytor Email',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 16 : isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isMobile) Text(
                  'Odbiorcy: ${widget.selectedInvestors.length} inwestorów',
                  style: TextStyle(
                    color: Colors.white70, 
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close, 
              color: Colors.white,
              size: isMobile ? 20 : 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isMobile, bool isSmallScreen) {
    return Container(
      color: AppThemePro.backgroundSecondary,
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            icon: Icon(Icons.edit, size: isMobile ? 16 : 20),
            text: isMobile ? 'Edit' : 'Edytor',
          ),
          Tab(
            icon: Icon(Icons.settings, size: isMobile ? 16 : 20),
            text: isMobile ? 'Set' : 'Ustawienia',
          ),
          Tab(
            icon: Icon(Icons.preview, size: isMobile ? 16 : 20),
            text: isMobile ? 'View' : 'Podgląd',
          ),
        ],
        labelColor: AppThemePro.accentGold,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppThemePro.accentGold,
        labelStyle: TextStyle(
          fontSize: isMobile ? 11 : isSmallScreen ? 12 : 14,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: isMobile ? 11 : isSmallScreen ? 12 : 14,
          fontWeight: FontWeight.normal,
        ),
        indicatorWeight: isMobile ? 2 : 3,
      ),
    );
  }

  Widget _buildTabContent(bool isMobile, bool isSmallScreen) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildEditorTab(isMobile, isSmallScreen), 
        _buildSettingsTab(isMobile, isSmallScreen), 
        _buildPreviewTab(isMobile, isSmallScreen)
      ],
    );
  }

  Widget _buildEditorTab(bool isMobile, bool isSmallScreen) {
    final contentPadding = isMobile ? 8.0 : isSmallScreen ? 12.0 : 16.0;
    
    return Container(
      padding: EdgeInsets.all(contentPadding),
      child: Column(
        children: [
          // Recipient selector and content mode toggle
          _buildRecipientSelectorHeader(isMobile, isSmallScreen),
          SizedBox(height: isMobile ? 8 : 16),
          
          Expanded(
            child: isMobile || isSmallScreen
                ? _buildMobileEditorLayout(isMobile, isSmallScreen)
                : _buildDesktopEditorLayout(isMobile, isSmallScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileEditorLayout(bool isMobile, bool isSmallScreen) {
    return Column(
      children: [
        // Mobile: recipient list as dropdown - animated
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          height: (_useIndividualContent && !_isUserTyping) ? null : 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: (_useIndividualContent && !_isUserTyping) ? 1.0 : 0.0,
            child: Column(
              children: [
                if (_useIndividualContent) _buildMobileRecipientSelector(isMobile),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: (_useIndividualContent && !_isUserTyping) ? (isMobile ? 8 : 12) : 0,
                ),
              ],
            ),
          ),
        ),
        
        // Editor takes full width on mobile - expands when recipient selector is hidden
        Expanded(
          child: _buildEditorContainer(isMobile, isSmallScreen),
        ),
      ],
    );
  }

  Widget _buildDesktopEditorLayout(bool isMobile, bool isSmallScreen) {
    return Row(
      children: [
        // Left sidebar - recipient list (when in individual mode) - animated
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          width: (_useIndividualContent && !_isUserTyping) ? 250 : 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: (_useIndividualContent && !_isUserTyping) ? 1.0 : 0.0,
            child: _useIndividualContent ? Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppThemePro.borderSecondary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildRecipientList(isMobile, isSmallScreen),
            ) : const SizedBox.shrink(),
          ),
        ),
        
        // Spacer - animated
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: (_useIndividualContent && !_isUserTyping) ? 16 : 0,
        ),
        
        // Main editor area - expands when sidebar is hidden
        Expanded(
          child: _buildEditorContainer(isMobile, isSmallScreen),
        ),
      ],
    );
  }

  Widget _buildMobileRecipientSelector(bool isMobile) {
    if (!_useIndividualContent || widget.selectedInvestors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppThemePro.borderSecondary),
        borderRadius: BorderRadius.circular(8),
        color: AppThemePro.backgroundSecondary,
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedRecipientForEditing ?? widget.selectedInvestors.first.client.id,
        decoration: const InputDecoration(
          labelText: 'Wybierz odbiorcę',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        items: widget.selectedInvestors.map((investor) {
          return DropdownMenuItem<String>(
            value: investor.client.id,
            child: Text(
              investor.client.name,
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: AppThemePro.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (mounted && value != null) {
            setState(() {
              _selectedRecipientForEditing = value;
            });
            // Force preview refresh when switching recipient
            _updatePreview();
          }
        },
        dropdownColor: AppThemePro.backgroundPrimary,
        style: TextStyle(
          color: AppThemePro.textPrimary,
          fontSize: isMobile ? 12 : 14,
        ),
      ),
    );
  }

  Widget _buildEditorContainer(bool isMobile, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppThemePro.borderSecondary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Quill toolbar - responsive
          Container(
            decoration: BoxDecoration(
              color: AppThemePro.backgroundSecondary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                bottom: BorderSide(color: AppThemePro.borderPrimary),
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                iconTheme: IconThemeData(
                  color: AppThemePro.textPrimary,
                  size: isMobile ? 18 : 20,
                ),
                dividerTheme: DividerThemeData(
                  color: AppThemePro.borderSecondary,
                  thickness: 1,
                ),
              ),
              child: QuillSimpleToolbar(
                controller: _getCurrentController(),
                config: QuillSimpleToolbarConfig(
                  multiRowsDisplay: true,
                  // Basic text styling
                  showBoldButton: true,
                  showItalicButton: true,
                  showUnderLineButton: true,
                  showStrikeThrough: !isMobile, // Hide on mobile to save space
                  showSubscript: !isMobile,
                  showSuperscript: !isMobile,
                  showSmallButton: !isMobile,
                  // ⭐ Enhanced font options with custom configurations
                  showFontFamily: !isMobile, // Hide on mobile - too complex
                  showFontSize: !isMobile,
                  // Colors
                  showColorButton: true,
                  showBackgroundColorButton: !isMobile,
                  // Headers and structure
                  showHeaderStyle: true,
                  showQuote: !isMobile,
                  showInlineCode: !isMobile,
                  showCodeBlock: false, // Hide completely
                  // Lists and indentation
                  showListBullets: true,
                  showListNumbers: true,
                  showListCheck: !isMobile,
                  showIndent: !isMobile,
                  // Alignment
                  showAlignmentButtons: !isMobile,
                  showLeftAlignment: !isMobile,
                  showCenterAlignment: !isMobile,
                  showRightAlignment: !isMobile,
                  showJustifyAlignment: false,
                  showDirection: false,
                  // Links and media
                  showLink: !isMobile,
                  // Actions
                  showUndo: true,
                  showRedo: true,
                  showClearFormat: !isMobile,
                  showSearchButton: false,
                  
                  // ⭐ Custom button configurations
                  buttonOptions: QuillSimpleToolbarButtonOptions(
                    // Custom font size configuration
                    fontSize: QuillToolbarFontSizeButtonOptions(
                      items: isMobile ? _mobileFontSizes : _customFontSizes,
                      tooltip: 'Rozmiar czcionki',
                    ),
                    
                    // Custom font family configuration
                    fontFamily: QuillToolbarFontFamilyButtonOptions(
                      items: isMobile ? _mobileFontFamilies : _customFontFamilies,
                      tooltip: 'Rodzaj czcionki',
                    ),
                    
                    // Enhanced color buttons (always available)
                    color: QuillToolbarColorButtonOptions(
                      tooltip: 'Kolor tekstu',
                    ),
                    
                    backgroundColor: QuillToolbarColorButtonOptions(
                      tooltip: 'Kolor tła',
                    ),
                  ),
                  
                  // Layout and styling
                  decoration: BoxDecoration(
                    color: AppThemePro.backgroundTertiary,
                    border: Border.all(
                      color: AppThemePro.borderPrimary,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  toolbarSize: isMobile ? 32 : 36,
                  toolbarSectionSpacing: isMobile ? 2 : 4,
                  toolbarIconAlignment: WrapAlignment.center,
                ),
              ),
            ),
          ),

          Container(
            height: 1, 
            color: AppThemePro.borderPrimary,
          ),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppThemePro.backgroundPrimary,
                border: Border.all(color: AppThemePro.borderPrimary),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: TextSelectionThemeData(
                    cursorColor: AppThemePro.accentGold,
                    selectionColor: AppThemePro.accentGold.withValues(alpha: 0.3),
                    selectionHandleColor: AppThemePro.accentGold,
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    border: InputBorder.none,
                  ),
                ),
                child: QuillEditor.basic(
                  controller: _getCurrentController(),
                  focusNode: _getCurrentFocusNode(),
                  config: QuillEditorConfig(
                    placeholder: 'Wpisz treść swojego maila...',
                    padding: EdgeInsets.all(isMobile ? 8 : isSmallScreen ? 12 : 16),
                    autoFocus: false,
                    expands: true,
                    scrollable: true,
                    showCursor: true,
                    enableInteractiveSelection: true,
                    enableSelectionToolbar: true,
                  ),
                ),
              ),
            ),
          ),
          
          // Investment details widget
          _buildInvestmentDetailsWidget(isMobile, isSmallScreen),

          // Quick actions
          Wrap(
            spacing: isSmallScreen ? 4 : 8,
            runSpacing: isSmallScreen ? 4 : 8,
            children: [
              ElevatedButton.icon(
                onPressed: _insertVoting,
                icon: const Icon(Icons.how_to_vote, size: 16),
                label: const Text('Dodaj głosowanie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemePro.statusInfo.withValues(alpha: 0.2),
                  foregroundColor: AppThemePro.statusInfo,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                    vertical: isSmallScreen ? 6 : 8,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _clearEditor,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Wyczyść'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemePro.statusError.withValues(
                    alpha: 0.2,
                  ),
                  foregroundColor: AppThemePro.statusError,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                    vertical: isSmallScreen ? 6 : 8,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _insertIndividualInvestmentList,
                icon: const Icon(Icons.list_alt, size: 16),
                label: const Text('Lista indywidualna'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemePro.accentGold.withValues(
                    alpha: 0.2,
                  ),
                  foregroundColor: AppThemePro.accentGold,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                    vertical: isSmallScreen ? 6 : 8,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _insertGlobalInvestmentList,
                icon: const Icon(Icons.account_tree, size: 16),
                label: const Text('Lista globalna'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemePro.accentGold.withValues(
                    alpha: 0.2,
                  ),
                  foregroundColor: AppThemePro.accentGold,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                    vertical: isSmallScreen ? 6 : 8,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(bool isMobile, bool isSmallScreen) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final contentPadding = isSmallScreen ? 12.0 : 24.0;

    return Padding(
      padding: EdgeInsets.all(contentPadding),
      child: ListView(
        children: [
          _buildSectionHeader('Główne Ustawienia', Icons.settings_outlined),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            title: const Text('Dołącz szczegóły inwestycji'),
            subtitle: const Text(
                'Automatycznie dodaj tabelę z podsumowaniem inwestycji na końcu wiadomości.'),
            value: _includeInvestmentDetails,
            onChanged: (value) => setState(() => _includeInvestmentDetails = value),
            activeColor: AppThemePro.accentGold,
            secondary: Icon(Icons.attach_money, color: AppThemePro.accentGold),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            title: const Text('Grupowa wiadomość (BCC)'),
            subtitle: const Text(
                'Wyślij jedną wiadomość do wszystkich odbiorców w polu "BCC", ukrywając ich adresy.'),
            value: _isGroupEmail,
            onChanged: (value) => setState(() => _isGroupEmail = value),
            activeColor: AppThemePro.accentGold,
            secondary: Icon(Icons.group, color: AppThemePro.accentGold),
          ),
          const Divider(height: 48),
          _buildSectionHeader('Zarządzanie Odbiorcami', Icons.people_outline),
          const SizedBox(height: 16),
          Text(
            'Zarządzanie odbiorcami zostało przeniesione do zakładki Edytor.',
            style: TextStyle(
              color: AppThemePro.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          _buildAdditionalEmailsField(),
          const SizedBox(height: 16),
          _buildRecipientsManagementInSettings(),
        ],
      ),
    );
  }

  Widget _buildRecipientsManagementInSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wysyłaj do tych inwestorów',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppThemePro.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppThemePro.backgroundSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppThemePro.borderSecondary),
          ),
          child: Column(
            children: widget.selectedInvestors.map((inv) {
              final enabled = _recipientEnabled[inv.client.id] ?? true;
              return SwitchListTile.adaptive(
                value: enabled,
                onChanged: (value) {
                  setState(() {
                    _recipientEnabled[inv.client.id] = value;
                  });
                },
                title: Text(inv.client.name, style: TextStyle(color: AppThemePro.textPrimary)),
                subtitle: Text(inv.client.email, style: TextStyle(color: AppThemePro.textSecondary)),
                secondary: CircleAvatar(
                  radius: 16,
                  backgroundColor: enabled ? AppThemePro.accentGold : AppThemePro.backgroundPrimary,
                  child: Text(inv.client.name.isNotEmpty ? inv.client.name[0].toUpperCase() : '?', style: TextStyle(color: enabled ? Colors.black : AppThemePro.textSecondary)),
                ),
                activeColor: AppThemePro.accentGold,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }


  Widget _buildAdditionalEmailsField() {
    final emailController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dodatkowi odbiorcy',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppThemePro.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Wprowadź adres email i kliknij +',
                  prefixIcon: Icon(Icons.email_outlined, color: AppThemePro.textSecondary),
                  filled: true,
                  fillColor: AppThemePro.backgroundSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (value) {
                  _addAdditionalEmail(value);
                  emailController.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                _addAdditionalEmail(emailController.text);
                emailController.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemePro.accentGold,
                foregroundColor: Colors.black,
              ),
              child: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _additionalEmails.map((e) {
            final confirmed = _additionalEmailsConfirmed[e] ?? false;
            return Chip(
              label: Text(e, style: TextStyle(color: AppThemePro.textPrimary)),
              backgroundColor: confirmed ? AppThemePro.accentGold.withValues(alpha: 0.15) : AppThemePro.backgroundSecondary,
              avatar: Icon(confirmed ? Icons.check_circle : Icons.alternate_email, size: 18, color: AppThemePro.textSecondary),
              onDeleted: () {
                setState(() {
                  _additionalEmails.remove(e);
                  _additionalEmailsConfirmed.remove(e);
                });
              },
              deleteIcon: Icon(Icons.delete, size: 18, color: AppThemePro.statusError),
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            );
          }).toList(),
        ),
        if (_additionalEmails.isNotEmpty) const SizedBox(height: 8),
        if (_additionalEmails.isNotEmpty)
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Confirm all
                  setState(() {
                    for (final e in _additionalEmails) {
                      _additionalEmailsConfirmed[e] = true;
                    }
                  });
                },
                icon: const Icon(Icons.check),
                label: const Text('Zatwierdź wszystkie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemePro.accentGold,
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _additionalEmails.clear();
                    _additionalEmailsConfirmed.clear();
                  });
                },
                child: const Text('Wyczyść'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppThemePro.accentGold, size: 22),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppThemePro.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewTab(bool isMobile, bool isSmallScreen) {
    // **NOWE PODEJŚCIE: Użyj naszej niezawodnej konwersji z aktualnym kontrolerem**
    final currentController = _getCurrentController();
    final workingHtml = _convertQuillToReliableHtml(currentController);
    final plainText = currentController.document.toPlainText();

    if (kDebugMode) {
      print('🔍 [PreviewDebug] Plain text length: ${plainText.length}');
      print('🔍 [PreviewDebug] Working HTML length: ${workingHtml.length}');
      print('🔍 [PreviewDebug] Working HTML: $workingHtml');
    }
    
    // **ZAWSZE DODAJ SZCZEGÓŁY INWESTYCJI** na podstawie wybranego odbiorcy
    String processedHtml;
    
    if (_selectedPreviewRecipient?.startsWith('investor:') == true) {
      // Dla inwestorów - dodaj ich szczegóły
      final investorId = _selectedPreviewRecipient!.substring('investor:'.length);
      final investor = widget.selectedInvestors.firstWhere(
        (inv) => inv.client.id == investorId,
        orElse: () => widget.selectedInvestors.first,
      );
      
      processedHtml = _ensureInvestmentDetails(
        workingHtml,
        specificInvestor: investor,
      );
    } else if (_selectedPreviewRecipient?.startsWith('additional:') == true) {
      // Dla dodatkowych emaili - dodaj zbiorcze dane
      final enabledInvestors = widget.selectedInvestors
          .where((inv) => _recipientEnabled[inv.client.id] ?? false)
          .toList();
      
      processedHtml = _ensureInvestmentDetails(
        workingHtml,
        allInvestors: enabledInvestors,
      );
    } else {
      // Fallback - dodaj zbiorcze dane dla wszystkich
      processedHtml = _ensureInvestmentDetails(
        workingHtml,
        allInvestors: widget.selectedInvestors,
      );
    }

    if (kDebugMode) {
      print(
        '🔍 [PreviewDebug] Final processed HTML length: ${processedHtml.length}',
      );
      print(
        '🔍 [PreviewDebug] First 500 chars: ${processedHtml.substring(0, math.min(500, processedHtml.length))}',
      );
    }

    return Container(
      color: AppThemePro.backgroundPrimary,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildPreviewControls(),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppThemePro.borderSecondary),
                borderRadius: BorderRadius.circular(8),
                color: _previewDarkMode ? const Color(0xFF1a1a1a) : Colors.white,
              ),
              child: SingleChildScrollView(
                child: html.Html(
                  // IMPORTANT: render the processed HTML (with table markers converted to HTML tables)
                  data: processedHtml,
                  style: {
                    "body": html.Style(
                      backgroundColor: _previewDarkMode ? const Color(0xFF1a1a1a) : Colors.white,
                      color: _previewDarkMode ? Colors.white : Colors.black,
                      margin: html.Margins.all(0),
                      padding: html.HtmlPaddings.all(16),
                    ),
                    "p": html.Style(
                      color: _previewDarkMode ? Colors.white : Colors.black,
                    ),
                    "div": html.Style(
                      color: _previewDarkMode ? Colors.white : Colors.black,
                    ),
                    "span": html.Style(
                      color: _previewDarkMode ? Colors.white : Colors.black,
                    ),
                    "h1, h2, h3, h4, h5, h6": html.Style(
                      color: _previewDarkMode ? Colors.white : Colors.black,
                    ),
                    // Remove global font family override to respect individual element styles
                    "table": html.Style(
                      margin: html.Margins.all(8),
                    ),
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.accentGold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            Icons.visibility,
            color: AppThemePro.accentGold,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Opcje podglądu',
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 24),
          // Theme toggle with switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppThemePro.backgroundPrimary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppThemePro.accentGold.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.light_mode,
                  color: !_previewDarkMode ? AppThemePro.accentGold : AppThemePro.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _previewDarkMode,
                  onChanged: (value) {
                    setState(() {
                      _previewDarkMode = value;
                    });
                  },
                  activeColor: AppThemePro.accentGold,
                  activeTrackColor: AppThemePro.accentGold.withValues(alpha: 0.3),
                  inactiveThumbColor: Colors.orange,
                  inactiveTrackColor: Colors.orange.withValues(alpha: 0.3),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.dark_mode,
                  color: _previewDarkMode ? AppThemePro.accentGold : AppThemePro.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  _previewDarkMode ? 'Ciemny' : 'Jasny',
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Debug button
          if (kDebugMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppThemePro.backgroundPrimary,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: InkWell(
                onTap: _testHtmlConversion,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bug_report,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Debug HTML',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          const Spacer(),
          // Recipient selector
          Expanded(
            flex: 2,
            child: _buildPreviewRecipientSelector(),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildPreviewRecipientSelector() {
    final availableRecipients = widget.selectedInvestors
        .where((inv) => _recipientEnabled[inv.client.id] ?? false)
        .toList();
    
    // Get confirmed additional emails
    final confirmedAdditionalEmails = _additionalEmails
        .where((email) => _additionalEmailsConfirmed[email] ?? false)
        .toList();

    if (availableRecipients.isEmpty && confirmedAdditionalEmails.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppThemePro.backgroundPrimary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppThemePro.textSecondary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Brak aktywnych odbiorców do podglądu',
              style: TextStyle(
                color: AppThemePro.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Build unified dropdown items for investors and additional emails
    List<DropdownMenuItem<String>> dropdownItems = [];
    
    // Add investors section
    if (availableRecipients.isNotEmpty) {
      dropdownItems.addAll(
        availableRecipients.map((investor) => DropdownMenuItem<String>(
          value: 'investor:${investor.client.id}',
          child: Row(
            children: [
              Icon(Icons.person, color: AppThemePro.accentGold, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  investor.client.name,
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ))
      );
    }
    
    // Add additional emails section
    if (confirmedAdditionalEmails.isNotEmpty) {
      dropdownItems.addAll(
        confirmedAdditionalEmails.map((email) => DropdownMenuItem<String>(
          value: 'additional:$email',
          child: Row(
            children: [
              Icon(Icons.email, color: AppThemePro.accentGold, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  email,
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ))
      );
    }

    // Ensure a default selection if none is set or the selected one is no longer valid
    final allValidIds = [
      ...availableRecipients.map((inv) => 'investor:${inv.client.id}'),
      ...confirmedAdditionalEmails.map((email) => 'additional:$email'),
    ];
    
    if (_selectedPreviewRecipient == null || !allValidIds.contains(_selectedPreviewRecipient)) {
      _selectedPreviewRecipient = allValidIds.isNotEmpty ? allValidIds.first : null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.accentGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.preview,
            color: AppThemePro.accentGold,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Podgląd dla:',
            style: TextStyle(
              color: AppThemePro.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPreviewRecipient,
                isExpanded: true,
                dropdownColor: AppThemePro.backgroundSecondary,
                icon: Icon(Icons.arrow_drop_down, color: AppThemePro.accentGold, size: 20),
                style: TextStyle(
                  color: AppThemePro.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPreviewRecipient = newValue;
                  });
                },
                items: dropdownItems,
              ),
            ),
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

    if (!_hasValidEmails()) {
      setState(() {
        _error = 'Brak prawidłowych odbiorców do wysłania wiadomości.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showDetailedProgress = true;
      _error = null;
      _results = null;
      _debugLogs.clear();
      _loadingMessage = 'Przygotowywanie wiadomości...';
    });

    try {

      final selectedRecipients = widget.selectedInvestors
          .where((inv) => _recipientEnabled[inv.client.id] ?? false)
          .toList();

      _totalEmailsToSend = selectedRecipients.length + _additionalEmails.length;
      _currentEmailIndex = 0;

      // Build a raw HTML map per-recipient using the editor's content
      Map<String, String>? completeEmailHtmlByClient;
      String? aggregatedEmailHtmlForAdditionals;

      if (selectedRecipients.isNotEmpty) {
        completeEmailHtmlByClient = <String, String>{};

        for (final investor in selectedRecipients) {
          // Choose controller (individual or global)
          final controllerToUse = (_useIndividualContent && _individualControllers.containsKey(investor.client.id))
              ? _individualControllers[investor.client.id]! : _quillController;

          // **NOWE PODEJŚCIE: Użyj naszej niezawodnej konwersji**
          final workingHtml = _convertQuillToReliableHtml(controllerToUse);

          // DEBUGGING: Check individual content
          final plainTextContent = controllerToUse.document.toPlainText();
          if (kDebugMode) {
            print(
              '🔍 [EmailDebug] Individual content for ${investor.client.name}:',
            );
            print('Plain text length: ${plainTextContent.length}');
            print('Working HTML length: ${workingHtml.length}');
            print('Working HTML: $workingHtml');
          }

          // **ZAWSZE DODAJ SZCZEGÓŁY INWESTYCJI**
          final investorSpecificHtml = _ensureInvestmentDetails(
            workingHtml,
            specificInvestor: investor,
          );

          if (kDebugMode) {
            print(
              '✅ [EmailDebug] Final HTML for ${investor.client.name} - length: ${investorSpecificHtml.length}',
            );
          }

          completeEmailHtmlByClient[investor.client.id] = investorSpecificHtml;

          if (kDebugMode) {
            print('📋 [EmailDialog] Processed HTML for ${investor.client.name} (${investor.client.id}): ${investorSpecificHtml.length} chars');
            print('📋 [EmailDialog] First 500 chars: ${investorSpecificHtml.substring(0, math.min(500, investorSpecificHtml.length))}');
          }
        }
      }

      // **NOWE PODEJŚCIE: Convert main content for additional emails**
      final workingHtml = _convertQuillToReliableHtml(_quillController);

      // DEBUGGING: Check what we get from Quill
      final plainTextContent = _quillController.document.toPlainText();
      if (kDebugMode) {
        print('🔍 [EmailDebug] Plain text content:');
        print(plainTextContent);
        print('🔍 [EmailDebug] Plain text length: ${plainTextContent.length}');
        print('🔍 [EmailDebug] Working HTML from reliable conversion:');
        print(workingHtml);
        print('🔍 [EmailDebug] Working HTML length: ${workingHtml.length}');
      }

      // **ZAWSZE DODAJ ZBIORCZE SZCZEGÓŁY** dla dodatkowych odbiorców
      final processedHtml = _ensureInvestmentDetails(
        workingHtml,
        allInvestors: selectedRecipients,
      );

      if (kDebugMode) {
        print(
          '✅ [EmailDebug] Main processed HTML with investment details - length: ${processedHtml.length}',
        );
      }
      
      // Generate aggregated email HTML for additional recipients if needed
      if (_additionalEmails.isNotEmpty) {
        // For additional emails, use aggregated content
        aggregatedEmailHtmlForAdditionals = _ensureInvestmentDetails(
          workingHtml,
          allInvestors: selectedRecipients,
        );

        if (kDebugMode) {
          print('📋 [EmailDialog] Aggregated processed HTML length: ${aggregatedEmailHtmlForAdditionals.length} chars');
        }
      }

      if (kDebugMode) {
        print('📤 [EmailDialog] Wysyłam emaile (nowa metoda z kompletnym HTML):');
        print('   - Odbiorcy: ${selectedRecipients.length}');
        print('   - Dodatkowe emaile: ${_additionalEmails.length}');
        print('   - Complete email HTML map size: ${completeEmailHtmlByClient?.length ?? 0}');
        print('   - Aggregated email HTML length: ${aggregatedEmailHtmlForAdditionals?.length ?? 0}');
      }

      // Send HTML content using the proper email service method
      // The service will properly handle the HTML content with investment details
      if (kDebugMode) {
        print('📤 [EmailDialog] Sending emails:');
        print('   - selectedRecipients: ${selectedRecipients.length}');
        print('   - additionalEmails: ${_additionalEmails.length}');
        print('   - includeInvestmentDetails: $_includeInvestmentDetails');
        print('   - completeEmailHtmlByClient: ${completeEmailHtmlByClient?.keys.length ?? 0} clients');
        if (completeEmailHtmlByClient != null) {
          completeEmailHtmlByClient.forEach((clientId, html) {
            print('     - $clientId: ${html.length} chars');
          });
        }
      }

      final results = await _emailAndExportService.sendCustomEmailsToMixedRecipients(
        investors: selectedRecipients,
        additionalEmails: _additionalEmails,
        subject: _subjectController.text,
        htmlContent: processedHtml, // Send the processed HTML that includes investment tables
        includeInvestmentDetails:
            false, // IMPORTANT: Set to false to avoid duplication since we're providing complete HTML
        investmentDetailsByClient: completeEmailHtmlByClient, // Pass individual investment details if available
        aggregatedInvestmentsForAdditionals: aggregatedEmailHtmlForAdditionals, // Pass aggregated details for additional emails
        senderEmail: _senderEmailController.text,
        senderName: _senderNameController.text,
      );

      setState(() {
        _results = results;
        _loadingMessage = 'Wysyłanie zakończone.';
      });
      
      // Play sound effects based on results
      _playResultSoundEffects(results);
    } catch (e) {
      setState(() {
        _error = 'Wystąpił nieoczekiwany błąd: $e';
        _loadingMessage = 'Błąd wysyłania.';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _showDetailedProgress = false;
      });

      // Show summary snackbar
      if (_results != null && mounted) {
        final successful = _results!.where((r) => r.success).length;
        final failed = _results!.length - successful;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wysyłanie zakończone. Pomyślnie: $successful, Błędy: $failed.'),
            backgroundColor: failed > 0 ? AppThemePro.statusError : AppThemePro.statusSuccess,
          ),
        );
      }
    }
  }

  /// Check if there are valid emails to send to
  bool _hasValidEmails() {
    final validInvestors = widget.selectedInvestors
        .where((inv) => _recipientEnabled[inv.client.id] ?? false)
        .isNotEmpty;
    final validAdditionalEmails = _additionalEmails
        .where((email) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email))
        .isNotEmpty;
    
    return validInvestors || validAdditionalEmails;
  }

  /// Play audio feedback after sending emails based on results.
  /// Uses `AudioService` which provides platform-safe sound playback.
  Future<void> _playResultSoundEffects(List<EmailSendResult> results) async {
    try {
      final audio = AudioService.instance;

      if (results.isEmpty) return;

      final successful = results.where((r) => r.success).length;
      final failed = results.length - successful;

      // If all succeeded and more than one, play a celebratory bulk sound.
      if (failed == 0 && results.length > 1) {
        await audio.playBulkSuccessSound();
        return;
      }

      // If at least one success and at least one failure, play a single success then error.
      if (successful > 0 && failed > 0) {
        await audio.playEmailSuccessSound();
        await Future.delayed(const Duration(milliseconds: 200));
        await audio.playEmailErrorSound();
        return;
      }

      // If only successes
      if (failed == 0 && successful > 0) {
        await audio.playEmailSuccessSound();
        return;
      }

      // If only failures
      if (failed > 0 && successful == 0) {
        await audio.playEmailErrorSound();
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing result sound effects: $e');
      }
    }
  }

  /// Insert voting template
  void _insertVoting() {
    try {
      final selection = _quillController.selection;
      const votingTemplate =
          '\n\n📊 GŁOSOWANIE\n\n'
          'Prosimy o zapoznanie się z materiałami dotyczącymi głosowania i wyrażenie swojej opinii:\n\n'
          '🗳️ Opcje głosowania:\n'
          '• TAK - Zgadzam się z proponowanymi zmianami\n'
          '• NIE - Nie zgadzam się z proponowanymi zmianami\n'
          '• WSTRZYMUJĘ SIĘ - Nie wyrażam opinii\n\n'
          '📅 Termin głosowania: [WPISZ TERMIN]\n'
          '📧 Odpowiedź proszę przesłać na: [WPISZ EMAIL]\n\n'
          'Dziękujemy za Państwa aktywność w procesie decyzyjnym.\n\n';

      final insertOffset = selection.isValid
          ? selection.baseOffset
          : _quillController.document.length;

      _quillController.document.insert(insertOffset, votingTemplate);
      _quillController.updateSelection(
        TextSelection.collapsed(offset: insertOffset + votingTemplate.length),
        ChangeSource.local,
      );

      // Ensure focus and update UI
      _editorFocusNode.requestFocus();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error inserting voting template: $e');
    }
  }

  /// Clear editor content
  void _clearEditor() {
    try {
      _quillController.clear();
      // Set cursor to beginning after clearing
      _quillController.updateSelection(
        const TextSelection.collapsed(offset: 0),
        ChangeSource.local,
      );
      // Maintain focus
      _editorFocusNode.requestFocus();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error clearing editor: $e');
    }
  }

  /// Insert individual investment lists for each selected investor
  void _insertIndividualInvestmentList() {
    if (_isGroupEmail) {
      _showSnackBar(
        'Lista indywidualna nie jest dostępna dla wiadomości grupowych.',
        isError: true,
      );
      return;
    }

    try {
      final controller = _getCurrentController();
      final selection = controller.selection;
      final insertIndex = selection.baseOffset;

      // Insert individual investment lists for each selected investor
      for (final investor in widget.selectedInvestors) {
        _insertInvestmentListForInvestor(controller, insertIndex, investor);
      }

      // Show confirmation
      _showSnackBar(
        'Listy inwestycji dodane dla każdego inwestora indywidualnie',
      );
    } catch (e) {
      debugPrint('Error inserting individual investment lists: $e');
      _showSnackBar('Błąd podczas dodawania list inwestycji', isError: true);
    }
  }

  /// Insert global investment list for all selected investors
  void _insertGlobalInvestmentList() {
    try {
      final controller = _getCurrentController();
      final selection = controller.selection;
      final insertIndex = selection.baseOffset;

      _insertGlobalInvestmentListForInvestors(
        controller,
        insertIndex,
        widget.selectedInvestors,
      );

      // Show confirmation
      _showSnackBar('Globalna lista inwestycji została dodana');
    } catch (e) {
      debugPrint('Error inserting global investment list: $e');
      _showSnackBar(
        'Błąd podczas dodawania globalnej listy inwestycji',
        isError: true,
      );
    }
  }

  /// Helper method to show snackbar
  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? AppThemePro.statusError
              : AppThemePro.statusSuccess,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Insert investment list for a specific investor
  void _insertInvestmentListForInvestor(
    QuillController controller,
    int index,
    InvestorSummary investor,
  ) {
    // Insert header
    controller.document.insert(index, '\n');
    int currentIndex = index + 1;

    // Header text with formatting
    final headerText = '📊 Inwestycje: ${investor.client.name}\n';
    controller.document.insert(currentIndex, headerText);

    // Apply header formatting (bold)
    controller.formatText(currentIndex, headerText.length - 1, Attribute.bold);

    currentIndex += headerText.length;

    // Insert investment details
    for (final investment in investor.investments) {
      final investmentDetails = _formatInvestmentDetails(investment);
      controller.document.insert(currentIndex, investmentDetails);
      currentIndex += investmentDetails.length;
    }

    // Insert summary
    final summary = _formatInvestorSummary(investor);
    controller.document.insert(currentIndex, summary);
    controller.formatText(currentIndex, summary.length - 1, Attribute.bold);

    controller.document.insert(currentIndex + summary.length, '\n');
  }

  /// Insert global investment list for all investors
  void _insertGlobalInvestmentListForInvestors(
    QuillController controller,
    int index,
    List<InvestorSummary> investors,
  ) {
    // Insert header
    controller.document.insert(index, '\n');
    int currentIndex = index + 1;

    // Header text with formatting
    final headerText = '📈 Zbiorcze podsumowanie inwestycji\n\n';
    controller.document.insert(currentIndex, headerText);

    // Apply header formatting (bold)
    controller.formatText(currentIndex, headerText.length - 2, Attribute.bold);

    currentIndex += headerText.length;

    double totalCapitalRemaining = 0;
    double totalCapitalSecured = 0;
    double totalCapitalForRestructuring = 0;
    double totalInvestmentAmount = 0;
    int totalInvestments = 0;

    // List each investor's summary
    for (final investor in investors) {
      final investorSummaryText =
          '• ${investor.client.name}\n'
          '  Liczba inwestycji: ${investor.investments.length}\n'
          '  Kapitał pozostały: ${_formatCurrency(investor.totalRemainingCapital)}\n'
          '  Kapitał zabezpieczony: ${_formatCurrency(investor.capitalSecuredByRealEstate)}\n'
          '  Kapitał do restrukturyzacji: ${_formatCurrency(investor.capitalForRestructuring)}\n'
          '  Kwota inwestycji: ${_formatCurrency(investor.totalInvestmentAmount)}\n\n';

      controller.document.insert(currentIndex, investorSummaryText);
      currentIndex += investorSummaryText.length;

      // Add to totals
      totalCapitalRemaining += investor.totalRemainingCapital;
      totalCapitalSecured += investor.capitalSecuredByRealEstate;
      totalCapitalForRestructuring += investor.capitalForRestructuring;
      totalInvestmentAmount += investor.totalInvestmentAmount;
      totalInvestments += investor.investments.length;
    }

    // Insert totals
    final totalsText =
        '═══ PODSUMOWANIE ŁĄCZNE ═══\n'
        'Łączna liczba inwestycji: $totalInvestments\n'
        'Łączny kapitał pozostały: ${_formatCurrency(totalCapitalRemaining)}\n'
        'Łączny kapitał zabezpieczony: ${_formatCurrency(totalCapitalSecured)}\n'
        'Łączny kapitał do restrukturyzacji: ${_formatCurrency(totalCapitalForRestructuring)}\n'
        'Łączna kwota inwestycji: ${_formatCurrency(totalInvestmentAmount)}\n\n';

    controller.document.insert(currentIndex, totalsText);
    controller.formatText(currentIndex, totalsText.length - 2, Attribute.bold);
  }

  /// Format investment details for display with voting status
  String _formatInvestmentDetails(Investment investment) {
    final votingStatusText = investment.votingStatus.displayName;
    return '  • ${investment.productName}\n'
        '    Kwota inwestycji: ${_formatCurrency(investment.investmentAmount)}\n'
        '    Kapitał pozostały: ${_formatCurrency(investment.remainingCapital)}\n'
        '    Kapitał zabezpieczony: ${_formatCurrency(investment.capitalSecuredByRealEstate)}\n'
        '    Kapitał do restrukturyzacji: ${_formatCurrency(investment.capitalForRestructuring)}\n'
        '    Status: ${investment.status.displayName}\n'
        '    Głosowanie: $votingStatusText\n\n';
  }

  /// Format investor summary
  String _formatInvestorSummary(InvestorSummary investor) {
    return '  ── PODSUMOWANIE dla ${investor.client.name} ──\n'
        '  Łącznie inwestycji: ${investor.investments.length}\n'
        '  Łączny kapitał pozostały: ${_formatCurrency(investor.totalRemainingCapital)}\n'
        '  Łączny kapitał zabezpieczony: ${_formatCurrency(investor.capitalSecuredByRealEstate)}\n'
        '  Łączny kapitał do restrukturyzacji: ${_formatCurrency(investor.capitalForRestructuring)}\n'
        '  Łączna kwota inwestycji: ${_formatCurrency(investor.totalInvestmentAmount)}\n\n';
  }


  /// Build error display widget
  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.statusError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.statusError),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppThemePro.statusError),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: AppThemePro.statusError,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _error = null),
            icon: Icon(Icons.close, color: AppThemePro.statusError),
          ),
        ],
      ),
    );
  }

  /// Build results display widget
  Widget _buildResults(bool isMobile) {
    if (_results == null || _results!.isEmpty) return const SizedBox.shrink();

    final successful = _results!.where((r) => r.success).length;
    final failed = _results!.length - successful;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: failed > 0 
            ? AppThemePro.statusWarning.withValues(alpha: 0.1)
            : AppThemePro.statusSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: failed > 0 ? AppThemePro.statusWarning : AppThemePro.statusSuccess,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                failed > 0 ? Icons.warning_outlined : Icons.check_circle_outline,
                color: failed > 0 ? AppThemePro.statusWarning : AppThemePro.statusSuccess,
              ),
              const SizedBox(width: 12),
              Text(
                'Wyniki wysyłania',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppThemePro.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Pomyślnie wysłane: $successful'),
          if (failed > 0) Text('Błędy: $failed'),
        ],
      ),
    );
  }

  /// Build progress indicator widget
  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.borderSecondary),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _loadingMessage,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppThemePro.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (_totalEmailsToSend > 0) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _currentEmailIndex / _totalEmailsToSend,
              backgroundColor: AppThemePro.borderSecondary,
              valueColor: AlwaysStoppedAnimation(AppThemePro.accentGold),
            ),
            const SizedBox(height: 4),
            Text(
              '$_currentEmailIndex / $_totalEmailsToSend maili',
              style: TextStyle(
                fontSize: 12,
                color: AppThemePro.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build action buttons
  Widget _buildActions(bool canEdit, bool isMobile, bool isSmallScreen) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(
          top: BorderSide(color: AppThemePro.borderSecondary),
        ),
      ),
      child: Row(
        children: [
          // Subject field
          Expanded(
            flex: 2,
            child: Form(
              key: _formKey,
              child: TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Temat wiadomości',
                  prefixIcon: Icon(Icons.subject, color: AppThemePro.accentGold),
                  filled: true,
                  fillColor: AppThemePro.backgroundPrimary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Temat jest wymagany';
                  }
                  return null;
                },
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Send button
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _sendEmails,
            icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(_isLoading ? 'Wysyłanie...' : 'Wyślij'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemePro.accentGold,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 24,
                vertical: isSmallScreen ? 12 : 16,
              ),
            ),
          ),
          
          // Debug button (only in debug mode)
          _buildDebugButton(),
          
          const SizedBox(width: 8),
          
          // Cancel button
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppThemePro.textSecondary,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 12 : 16,
              ),
            ),
            child: const Text('Anuluj'),
          ),
        ],
      ),
    );
  }

  /// Buduje zbiorczą tabelę HTML z inwestycjami wszystkich wybranych inwestorów
  String _buildAggregatedInvestmentsTableHtml(List<InvestorSummary> investors) {
    if (kDebugMode) {
      print('📈 [EmailDialog] Generuję zbiorczy raport dla ${investors.length} inwestorów');
    }
    final buffer = StringBuffer();
    buffer.writeln('<div class="aggregated-investments" style="margin-top: 24px; padding: 20px; background-color: #f8f9fa; border-radius: 8px; border-left: 4px solid #d4af37;">');
    buffer.writeln('<h3 style="color: #d4af37; margin-bottom: 16px; font-size: 18px;">📈 Zbiorczy raport inwestycji</h3>');
    
    // Oblicz sumy globalne
    double totalCapital = 0;
    double totalSecured = 0;
    int totalInvestmentsCount = 0;
    
    for (final investor in investors) {
      totalCapital += investor.totalRemainingCapital;
      totalSecured += investor.capitalSecuredByRealEstate;
      totalInvestmentsCount += investor.investmentCount;
    }
    
    // Podsumowanie ogólne
    buffer.writeln('<div style="margin-bottom: 20px; display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 12px;">');
    buffer.writeln('<div style="background: white; padding: 12px; border-radius: 6px; border: 1px solid #e9ecef; text-align: center;">');
    buffer.writeln('<div style="font-size: 14px; color: #6c757d; margin-bottom: 4px;">Liczba klientów</div>');
    buffer.writeln('<div style="font-size: 20px; font-weight: bold; color: #2c2c2c;">${investors.length}</div>');
    buffer.writeln('</div>');
    
    buffer.writeln('<div style="background: white; padding: 12px; border-radius: 6px; border: 1px solid #e9ecef; text-align: center;">');
    buffer.writeln('<div style="font-size: 14px; color: #6c757d; margin-bottom: 4px;">Wszystkie inwestycje</div>');
    buffer.writeln('<div style="font-size: 20px; font-weight: bold; color: #2c2c2c;">$totalInvestmentsCount</div>');
    buffer.writeln('</div>');
    
    buffer.writeln('<div style="background: white; padding: 12px; border-radius: 6px; border: 1px solid #e9ecef; text-align: center;">');
    buffer.writeln('<div style="font-size: 14px; color: #6c757d; margin-bottom: 4px;">Łączny kapitał</div>');
    buffer.writeln('<div style="font-size: 20px; font-weight: bold; color: #28a745;">${_formatCurrency(totalCapital)}</div>');
    buffer.writeln('</div>');
    
    buffer.writeln('<div style="background: white; padding: 12px; border-radius: 6px; border: 1px solid #e9ecef; text-align: center;">');
    buffer.writeln('<div style="font-size: 14px; color: #6c757d; margin-bottom: 4px;">Kapitał zabezpieczony</div>');
    buffer.writeln('<div style="font-size: 20px; font-weight: bold; color: #d4af37;">${_formatCurrency(totalSecured)}</div>');
    buffer.writeln('</div>');
    buffer.writeln('</div>');
    
    // Tabela szczegółowa per klient
    buffer.writeln('<h4 style="color: #2c2c2c; margin: 20px 0 12px 0; font-size: 16px;">📊 Szczegóły według klientów</h4>');
    buffer.writeln('<table style="width: 100%; border-collapse: collapse; margin-bottom: 16px; background: white; border-radius: 6px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">');
    
    // Nagłówki tabeli
    buffer.writeln('<thead>');
    buffer.writeln('<tr style="background: #2c2c2c; color: white;">');
    buffer.writeln('<th style="text-align: left; padding: 12px; font-weight: 600; font-size: 14px;">Klient</th>');
    buffer.writeln('<th style="text-align: right; padding: 12px; font-weight: 600; font-size: 14px;">Liczba inwest.</th>');
    buffer.writeln('<th style="text-align: right; padding: 12px; font-weight: 600; font-size: 14px;">Kapitał pozostały</th>');
    buffer.writeln('<th style="text-align: right; padding: 12px; font-weight: 600; font-size: 14px;">Kapitał zabezp.</th>');
    buffer.writeln('<th style="text-align: center; padding: 12px; font-weight: 600; font-size: 14px;">Status głosowania</th>');
    buffer.writeln('</tr>');
    buffer.writeln('</thead>');
    
    // Wiersze z klientami
    buffer.writeln('<tbody>');
    for (int i = 0; i < investors.length; i++) {
      final investor = investors[i];
      final isOdd = i % 2 == 1;
      final bgColor = isOdd ? '#f8f9fa' : 'white';
      
      buffer.writeln('<tr style="background-color: $bgColor;">');
      buffer.writeln('<td style="padding: 12px; border-bottom: 1px solid #e9ecef; font-weight: 500;">${_sanitizeHtml(investor.client.name)}</td>');
      buffer.writeln('<td style="padding: 12px; text-align: right; border-bottom: 1px solid #e9ecef;">${investor.investmentCount}</td>');
      buffer.writeln('<td style="padding: 12px; text-align: right; border-bottom: 1px solid #e9ecef; color: #28a745; font-weight: 600;">${_formatCurrency(investor.totalRemainingCapital)}</td>');
      buffer.writeln('<td style="padding: 12px; text-align: right; border-bottom: 1px solid #e9ecef;">${_formatCurrency(investor.capitalSecuredByRealEstate)}</td>');
      
      // Status głosowania z kolorkami
      final statusColor = _getVotingStatusColorHex(investor.client.votingStatus);
      final statusLabel = _getVotingStatusLabel(investor.client.votingStatus);
      buffer.writeln('<td style="padding: 12px; text-align: center; border-bottom: 1px solid #e9ecef;">');
      buffer.writeln('<span style="background: $statusColor; color: white; padding: 4px 10px; border-radius: 12px; font-size: 12px; font-weight: 600;">$statusLabel</span>');
      buffer.writeln('</td>');
      buffer.writeln('</tr>');
    }
    
    // Wiersz podsumowujący
    buffer.writeln('<tr style="background: #2c2c2c; color: white; font-weight: bold;">');
    buffer.writeln('<td style="padding: 12px; font-size: 16px;">📊 RAZEM</td>');
    buffer.writeln('<td style="padding: 12px; text-align: right; font-size: 16px;">$totalInvestmentsCount</td>');
    buffer.writeln('<td style="padding: 12px; text-align: right; font-size: 16px; color: #90EE90;">${_formatCurrency(totalCapital)}</td>');
    buffer.writeln('<td style="padding: 12px; text-align: right; font-size: 16px; color: #FFD700;">${_formatCurrency(totalSecured)}</td>');
    buffer.writeln('<td style="padding: 12px; text-align: center; font-size: 16px;">${investors.length} klientów</td>');
    buffer.writeln('</tr>');
    buffer.writeln('</tbody>');
    buffer.writeln('</table>');
    
    // Informacje dodatkowe
    buffer.writeln('<div style="margin-top: 16px; padding: 12px; background: #e7f3ff; border-radius: 6px; border-left: 3px solid #0066cc;">');
    buffer.writeln('<p style="margin: 0 0 8px 0; font-size: 14px; color: #495057;"><strong>💡 Informacje:</strong></p>');
    buffer.writeln('<ul style="margin: 0; padding-left: 16px; font-size: 14px; color: #495057;">');
    buffer.writeln('<li>Średni kapitał na klienta: <strong>${_formatCurrency(investors.isNotEmpty ? totalCapital / investors.length : 0)}</strong></li>');
    buffer.writeln('<li>Średnia liczba inwestycji na klienta: <strong>${investors.isNotEmpty ? (totalInvestmentsCount / investors.length).toStringAsFixed(1) : '0'}</strong></li>');
    buffer.writeln('<li>Raport wygenerowany: <strong>${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}</strong></li>');
    buffer.writeln('</ul>');
    buffer.writeln('</div>');
    
    buffer.writeln('</div>');
    return buffer.toString();
  }

  /// Formatuje kwotę jako walutę polską z separatorami tysięcy
  String _formatCurrency(double amount) {
    if (amount == 0) return '0,00 zł';
    
    // Formatuj z 2 miejscami po przecinku
    final formattedAmount = amount.toStringAsFixed(2);
    final parts = formattedAmount.split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    // Dodaj separatory tysięcy
    final formattedInteger = _addThousandsSeparators(integerPart);

    return '$formattedInteger,$decimalPart zł';
  }

  /// Oczyszcza tekst z HTML i niebezpiecznych znaków
  String _sanitizeHtml(String text) {
    return text
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;');
  }

  /// Pobiera kolor hex dla statusu głosowania
  String _getVotingStatusColorHex(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return '#28a745';
      case VotingStatus.no:
        return '#dc3545';
      case VotingStatus.abstain:
        return '#ffc107';
      case VotingStatus.undecided:
        return '#6c757d';
    }
  }

  /// Pobiera czytelną etykietę dla statusu głosowania
  String _getVotingStatusLabel(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return 'ZA';
      case VotingStatus.no:
        return 'PRZECIW';
      case VotingStatus.abstain:
        return 'WSTRZYMUJE';
      case VotingStatus.undecided:
        return 'NIEZDECYDOWANY';
    }
  }

  /// Builds recipient selector header with content mode toggle
  Widget _buildRecipientSelectorHeader(bool isMobile, bool isSmallScreen) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      height: _isUserTyping ? 0 : null, // Collapse when typing
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _isUserTyping ? 0.0 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: EdgeInsets.only(bottom: _isUserTyping ? 0 : 8),
          decoration: BoxDecoration(
            color: AppThemePro.backgroundSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppThemePro.borderSecondary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: AppThemePro.accentGold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Odbiorcy emaili (${widget.selectedInvestors.length})',
                    style: TextStyle(
                      color: AppThemePro.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Show/hide indicator when typing
                  if (_isUserTyping) 
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppThemePro.accentGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 12, color: AppThemePro.accentGold),
                          const SizedBox(width: 4),
                          Text(
                            'Pisanie...',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppThemePro.accentGold,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // Toggle between global and individual content
                    Container(
                      decoration: BoxDecoration(
                        color: AppThemePro.backgroundPrimary,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppThemePro.borderSecondary),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() {
                              _useIndividualContent = false;
                              _syncContentBetweenControllers();
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: !_useIndividualContent 
                                    ? AppThemePro.accentGold 
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                'Globalna',
                                style: TextStyle(
                                  color: !_useIndividualContent 
                                      ? Colors.black 
                                      : AppThemePro.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() {
                              _useIndividualContent = true;
                              _syncContentBetweenControllers();
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _useIndividualContent 
                                    ? AppThemePro.accentGold 
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                'Indywidualna',
                                style: TextStyle(
                                  color: _useIndividualContent 
                                      ? Colors.black 
                                      : AppThemePro.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (_useIndividualContent && !_isUserTyping) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppThemePro.backgroundPrimary,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppThemePro.accentGold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppThemePro.accentGold, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tryb indywidualny: każdy odbiorca może mieć inną treść wiadomości',
                          style: TextStyle(
                            color: AppThemePro.textSecondary,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds recipient list for individual content mode
  Widget _buildRecipientList(bool isMobile, bool isSmallScreen) {
    final availableRecipients = widget.selectedInvestors
        .where((inv) => _recipientEnabled[inv.client.id] ?? false)
        .toList();

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppThemePro.backgroundSecondary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.people, color: AppThemePro.accentGold, size: 16),
              const SizedBox(width: 8),
              Text(
                'Lista odbiorców',
                style: TextStyle(color: AppThemePro.textPrimary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        // Recipient list
        Expanded(
          child: ListView.builder(
            itemCount: availableRecipients.length + (_additionalEmails.isNotEmpty ? _additionalEmails.length + 1 : 0),
            itemBuilder: (context, index) {
              // If index falls into investor list
              if (index < availableRecipients.length) {
                final investor = availableRecipients[index];
                final isSelected = _selectedRecipientForEditing == investor.client.id;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? AppThemePro.accentGold.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: isSelected ? Border.all(color: AppThemePro.accentGold.withValues(alpha: 0.3)) : null,
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: isSelected ? AppThemePro.accentGold : AppThemePro.backgroundSecondary,
                      child: Text(
                        investor.client.name.isNotEmpty ? investor.client.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: isSelected ? Colors.black : AppThemePro.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(
                      investor.client.name,
                      style: TextStyle(
                        color: isSelected ? AppThemePro.accentGold : AppThemePro.textPrimary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${investor.investmentCount} inwestycji',
                      style: TextStyle(
                        color: AppThemePro.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.add, color: AppThemePro.accentGold, size: 18),
                          tooltip: 'Wstaw tabelę inwestycji',
                          onPressed: () {
                            // Insert this investor's table into editor
                            final prevSelected = _selectedRecipientForEditing;
                            setState(() {
                              _selectedRecipientForEditing = investor.client.id;
                            });
                            _insertInvestmentTableIntoEditor();
                            // restore selection
                            setState(() {
                              _selectedRecipientForEditing = prevSelected;
                            });
                          },
                        ),
                        if (isSelected) Icon(Icons.edit, color: AppThemePro.accentGold, size: 16),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _selectedRecipientForEditing = investor.client.id;
                      });
                      // Force preview refresh when switching recipient
                      _updatePreview();
                    },
                  ),
                );
              }

              // After investors, show heading for additional emails
              final additionalStartIndex = availableRecipients.length;
              if (index == additionalStartIndex) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: AppThemePro.backgroundSecondary,
                  child: Row(
                    children: [
                      Icon(Icons.alternate_email, color: AppThemePro.accentGold, size: 16),
                      const SizedBox(width: 8),
                      Text('Dodatkowi odbiorcy', style: TextStyle(color: AppThemePro.textPrimary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }

              // Additional email entries
              final addIndex = index - (availableRecipients.length + 1);
              final email = _additionalEmails[addIndex];
              final confirmed = _additionalEmailsConfirmed[email] ?? false;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: confirmed ? AppThemePro.accentGold.withValues(alpha: 0.06) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppThemePro.backgroundSecondary,
                    child: Icon(Icons.email_outlined, size: 14, color: AppThemePro.textSecondary),
                  ),
                  title: Text(email, style: TextStyle(color: AppThemePro.textPrimary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(confirmed ? 'Zatwierdzony' : 'Niezatwierdzony', style: TextStyle(color: AppThemePro.textSecondary, fontSize: 11)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.add, color: AppThemePro.accentGold, size: 18),
                        tooltip: 'Wstaw tabelę inwestycji dla tego adresu',
                        onPressed: () {
                          // Insert aggregated table (we don't have per-email investments)
                          // Temporarily set to global context and insert
                          final wasIndividual = _useIndividualContent;
                          final prevSelected = _selectedRecipientForEditing;
                          setState(() {
                            _useIndividualContent = false;
                            _selectedRecipientForEditing = null;
                          });
                          _insertInvestmentTableIntoEditor();
                          setState(() {
                            _useIndividualContent = wasIndividual;
                            _selectedRecipientForEditing = prevSelected;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: AppThemePro.statusError, size: 18),
                        tooltip: 'Usuń dodatkowy adres',
                        onPressed: () {
                          setState(() {
                            _additionalEmails.remove(email);
                            _additionalEmailsConfirmed.remove(email);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Gets the appropriate QuillController for current editing context
  QuillController _getCurrentController() {
    if (_useIndividualContent && _selectedRecipientForEditing != null) {
      return _individualControllers[_selectedRecipientForEditing]!;
    }
    return _quillController;
  }

  /// Gets the appropriate FocusNode for current editing context
  FocusNode _getCurrentFocusNode() {
    if (_useIndividualContent && _selectedRecipientForEditing != null) {
      return _individualFocusNodes[_selectedRecipientForEditing]!;
    }
    return _editorFocusNode;
  }

  /// Synchronizes content between controllers when switching modes
  void _syncContentBetweenControllers() {
    if (_useIndividualContent) {
      // Copy global content to all individual controllers if they're empty
      final globalContent = _quillController.document.toDelta().toJson();
      for (final controller in _individualControllers.values) {
        if (controller.document.isEmpty()) {
          controller.document = Document.fromJson(globalContent);
        }
      }
    }
    
    // Force preview refresh after switching modes
    _updatePreview();
  }

  /// Builds investment details widget that can be inserted into editor
  Widget _buildInvestmentDetailsWidget([bool isMobile = false, bool isSmallScreen = false]) {
    if (!_includeInvestmentDetails) return const SizedBox.shrink();
    
    final selectedInvestor = _useIndividualContent && _selectedRecipientForEditing != null
        ? widget.selectedInvestors.firstWhere((inv) => inv.client.id == _selectedRecipientForEditing)
        : null;

    return Container(
      margin: EdgeInsets.all(isMobile ? 4 : 8),
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.accentGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet, 
                color: AppThemePro.accentGold, 
                size: isMobile ? 16 : 18,
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Expanded(
                child: Text(
                  selectedInvestor != null 
                      ? (isMobile ? selectedInvestor.client.name.split(' ').first : 'Inwestycje: ${selectedInvestor.client.name}')
                      : (isMobile ? 'Inwestycje (glob.)' : 'Podgląd inwestycji (globalne)'),
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 12 : 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: isMobile ? 4 : 8),
              TextButton.icon(
                onPressed: () {
                  // Insert investment table into current editor
                  _insertInvestmentTableIntoEditor();
                },
                icon: Icon(
                  Icons.add, 
                  color: AppThemePro.accentGold, 
                  size: isMobile ? 14 : 16,
                ),
                label: Text(
                  'Wstaw',
                  style: TextStyle(
                    color: AppThemePro.accentGold,
                    fontSize: isMobile ? 10 : 12,
                  ),
                ),
              ),
            ],
          ),
          
          if (selectedInvestor != null) ...[
            const SizedBox(height: 8),
            Text(
              '${selectedInvestor.investmentCount} inwestycji • '
              '${_formatCurrency(selectedInvestor.totalRemainingCapital)} kapitału',
              style: TextStyle(
                color: AppThemePro.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Inserts investment table into the current editor as formatted content
  void _insertInvestmentTableIntoEditor() {
    final controller = _getCurrentController();
    final focusNode = _getCurrentFocusNode();
    
    // Get current selection or cursor position
    final selection = controller.selection;
    final index = selection.baseOffset;
    
    try {
      // Generate formatted content for insertion
      if (_useIndividualContent && _selectedRecipientForEditing != null) {
        final investor = widget.selectedInvestors
            .firstWhere((inv) => inv.client.id == _selectedRecipientForEditing);
        _insertInvestorTable(controller, index, investor);
      } else {
        _insertAggregatedTable(controller, index, widget.selectedInvestors);
      }

      // Update selection to end of inserted content
      controller.updateSelection(
        TextSelection.collapsed(offset: controller.document.length),
        ChangeSource.local,
      );

      // Request focus
      focusNode.requestFocus();

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tabela inwestycji dodana'),
            backgroundColor: AppThemePro.statusSuccess,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting investment table: $e');
      }
      // Fallback to plain text if rich insertion fails
      _insertPlainTextTableFallback(controller, index, focusNode);
    }
  }

  /// Insert individual investor table with rich formatting
  void _insertInvestorTable(QuillController controller, int index, InvestorSummary investor) {
    // Insert header
    controller.document.insert(index, '\n');
    int currentIndex = index + 1;
    
    // Header text with formatting
    final headerText = 'Szczegółowe inwestycje: ${investor.client.name}\n';
    controller.document.insert(currentIndex, headerText);
    
    // Apply header formatting (bold only - size formatting might not work)
    controller.formatText(
      currentIndex,
      headerText.length - 1,
      Attribute.bold,
    );
    
    currentIndex += headerText.length;
    
    // Insert table content with formatting
    _insertFormattedInvestmentTable(controller, currentIndex, investor.investments, investor.client.name);
  }

  /// Insert aggregated table with rich formatting
  void _insertAggregatedTable(QuillController controller, int index, List<InvestorSummary> recipients) {
    // Insert header
    controller.document.insert(index, '\n');
    int currentIndex = index + 1;
    
    // Header text with formatting
    final headerText = 'Zbiorcze podsumowanie inwestycji\n';
    controller.document.insert(currentIndex, headerText);
    
    // Apply header formatting (bold only - size formatting might not work)
    controller.formatText(
      currentIndex,
      headerText.length - 1,
      Attribute.bold,
    );
    
    currentIndex += headerText.length;
    
    // Insert aggregated table content
    _insertFormattedAggregatedTable(controller, currentIndex, recipients);
  }

  /// Insert formatted investment table using Quill attributes
  void _insertFormattedInvestmentTable(QuillController controller, int index, List<Investment> investments, String clientName) {
    int currentIndex = index;
    
    // Investment list format
    double totalInvestmentAmount = 0;
    double totalRemainingCapital = 0;
    double totalCapitalSecured = 0;
    double totalCapitalForRestructuring = 0;
    
    for (final inv in investments) {
      totalInvestmentAmount += inv.investmentAmount;
      totalRemainingCapital += inv.remainingCapital;
      totalCapitalSecured += inv.capitalSecuredByRealEstate;
      totalCapitalForRestructuring += inv.capitalForRestructuring;
      
      // Product name as header
      final productNameText = '${inv.productName}\n';
      controller.document.insert(currentIndex, productNameText);
      controller.formatText(
        currentIndex,
        productNameText.length - 1,
        Attribute.bold,
      );
      currentIndex += productNameText.length;

      // Investment details as bullet points
      final details = [
        '  • Kwota inwestycji: ${_formatCurrency(inv.investmentAmount)}\n',
        '  • Kapitał pozostały: ${_formatCurrency(inv.remainingCapital)}\n',
        '  • Kapitał zabezpieczony: ${_formatCurrency(inv.capitalSecuredByRealEstate)}\n',
        '  • Kapitał do restrukturyzacji: ${_formatCurrency(inv.capitalForRestructuring)}\n',
      ];
      
      if (inv.creditorCompany.isNotEmpty) {
        details.add('  • Wierzyciel: ${inv.creditorCompany}\n');
      }
      details.add('\n'); // Empty line after each investment

      for (final detail in details) {
        controller.document.insert(currentIndex, detail);
        currentIndex += detail.length;
      }
    }

    // Total summary
    final totalText = 'RAZEM:\n';
    controller.document.insert(currentIndex, totalText);
    controller.formatText(currentIndex, totalText.length - 1, Attribute.bold);
    currentIndex += totalText.length;

    final totalDetails = [
      '  • Kwota inwestycji: ${_formatCurrency(totalInvestmentAmount)}\n',
      '  • Kapitał pozostały: ${_formatCurrency(totalRemainingCapital)}\n',
      '  • Kapitał zabezpieczony: ${_formatCurrency(totalCapitalSecured)}\n',
      '  • Kapitał do restrukturyzacji: ${_formatCurrency(totalCapitalForRestructuring)}\n\n',
    ];
    
    for (final detail in totalDetails) {
      controller.document.insert(currentIndex, detail);
      currentIndex += detail.length;
    }
  }

  /// Insert formatted aggregated table
  void _insertFormattedAggregatedTable(QuillController controller, int index, List<InvestorSummary> recipients) {
    int currentIndex = index;
    
    // Table headers
    final headers = ['Klient', 'Liczba inwestycji', 'Kapitał pozostały', 'Kapitał zabezpieczony', 'Kapitał do restrukturyzacji'];
    final headerRow = '${headers.join(' | ')}\n';
    final separatorRow = '-' * 80 + '\n';
    
    controller.document.insert(currentIndex, headerRow);
    controller.formatText(currentIndex, headerRow.length - 1, Attribute.bold);
    currentIndex += headerRow.length;
    
    controller.document.insert(currentIndex, separatorRow);
    currentIndex += separatorRow.length;
    
    // Investment rows
    double totalCapitalRemaining = 0;
    double totalCapitalSecured = 0;
    double totalCapitalForRestructuring = 0;
    int totalInvestmentCount = 0;
    
    for (final inv in recipients) {
      totalCapitalRemaining += inv.totalRemainingCapital;
      totalCapitalSecured += inv.capitalSecuredByRealEstate;
      totalCapitalForRestructuring += inv.capitalForRestructuring;
      totalInvestmentCount += inv.investmentCount;
      
      final rowData = [
        inv.client.name,
        '${inv.investmentCount}',
        _formatCurrency(inv.totalRemainingCapital),
        _formatCurrency(inv.capitalSecuredByRealEstate),
        _formatCurrency(inv.capitalForRestructuring)
      ];
      
      final row = '${rowData.join(' | ')}\n';
      controller.document.insert(currentIndex, row);
      currentIndex += row.length;
    }
    
    // Total row
    final totalRowData = [
      'RAZEM',
      '$totalInvestmentCount',
      _formatCurrency(totalCapitalRemaining),
      _formatCurrency(totalCapitalSecured),
      _formatCurrency(totalCapitalForRestructuring)
    ];
    
    final totalRow = '${totalRowData.join(' | ')}\n\n';
    controller.document.insert(currentIndex, totalRow);
    controller.formatText(currentIndex, totalRow.length - 1, Attribute.bold);
  }

  /// Fallback method to insert plain text table if rich formatting fails
  void _insertPlainTextTableFallback(QuillController controller, int index, FocusNode focusNode) {
    try {
      String plainTable;
      if (_useIndividualContent && _selectedRecipientForEditing != null) {
        final investor = widget.selectedInvestors
            .firstWhere((inv) => inv.client.id == _selectedRecipientForEditing);
        plainTable = _buildPlainTextInvestmentsTableForInvestor(investor);
      } else {
        plainTable = _buildPlainTextAggregatedTable(widget.selectedInvestors);
      }

      controller.document.insert(index, plainTable);
      controller.updateSelection(
        TextSelection.collapsed(offset: index + plainTable.length),
        ChangeSource.local,
      );
      focusNode.requestFocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tabela dodana jako tekst (będzie skonwertowana na HTML w emailach)'),
            backgroundColor: AppThemePro.statusWarning,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in fallback table insertion: $e');
      }
    }
  }

  /// Builds HTML table for individual investor
  String _buildHtmlInvestmentsTableForInvestor(InvestorSummary investor) {
    final buffer = StringBuffer();
    
    // Table header
    buffer.writeln('<br><h3>Szczegółowe inwestycje: ${investor.client.name}</h3>');
    buffer.writeln('<table style="border-collapse: collapse; width: 100%; margin: 10px 0; font-family: Arial, sans-serif;">');
    buffer.writeln('<thead>');
    buffer.writeln('<tr style="background-color: #2a2a2a; color: #ffd700;">');
    buffer.writeln('<th style="border: 1px solid #666; padding: 8px; text-align: left;">Nazwa produktu</th>');
    buffer.writeln('<th style="border: 1px solid #666; padding: 8px; text-align: right;">Kwota inwestycji</th>');
    buffer.writeln('<th style="border: 1px solid #666; padding: 8px; text-align: right;">Kapitał pozostały</th>');
    buffer.writeln('<th style="border: 1px solid #666; padding: 8px; text-align: right;">Kapitał zabezpieczony</th>');
    buffer.writeln('<th style="border: 1px solid #666; padding: 8px; text-align: right;">Kapitał do restrukturyzacji</th>');
    buffer.writeln('<th style="border: 1px solid #666; padding: 8px; text-align: left;">Wierzyciel</th>');
    buffer.writeln('</tr>');
    buffer.writeln('</thead>');
    buffer.writeln('<tbody>');
    
    double totalInvestmentAmount = 0;
    double totalRemainingCapital = 0;
    double totalCapitalSecured = 0;
    double totalCapitalForRestructuring = 0;
    
    // Table rows
    for (final inv in investor.investments) {
      totalInvestmentAmount += inv.investmentAmount;
      totalRemainingCapital += inv.remainingCapital;
      totalCapitalSecured += inv.capitalSecuredByRealEstate;
      totalCapitalForRestructuring += inv.capitalForRestructuring;
      
      buffer.writeln('<tr style="background-color: #3a3a3a; color: #ffffff;">');
      buffer.writeln('<td style="border: 1px solid #666; padding: 8px;">${inv.productName}</td>');
      buffer.writeln('<td style="border: 1px solid #666; padding: 8px; text-align: right;">${_formatCurrency(inv.investmentAmount)}</td>');
      buffer.writeln('<td style="border: 1px solid #666; padding: 8px; text-align: right;">${_formatCurrency(inv.remainingCapital)}</td>');
      buffer.writeln('<td style="border: 1px solid #666; padding: 8px; text-align: right;">${_formatCurrency(inv.capitalSecuredByRealEstate)}</td>');
      buffer.writeln('<td style="border: 1px solid #666; padding: 8px; text-align: right;">${_formatCurrency(inv.capitalForRestructuring)}</td>');
      buffer.writeln('<td style="border: 1px solid #666; padding: 8px;">${inv.creditorCompany}</td>');
      buffer.writeln('</tr>');
    }
    
    // Total row
    buffer.writeln('<tr style="background-color: #4a4a4a; color: #ffd700; font-weight: bold;">');
    buffer.writeln('<td style="border: 1px solid #666; padding: 8px;">RAZEM</td>');
    buffer.writeln('<td style="border: 1px solid #666; padding: 8px; text-align: right;">${_formatCurrency(totalInvestmentAmount)}</td>');
    buffer.writeln('<td style="border: 1px solid #666; padding: 8px; text-align: right;">${_formatCurrency(totalRemainingCapital)}</td>');
    buffer.writeln('<td style="border: 1px solid #666; padding: 8px; text-align: right;">${_formatCurrency(totalCapitalSecured)}</td>');
    buffer.writeln('<td style="border: 1px solid #666; padding: 8px; text-align: right;">${_formatCurrency(totalCapitalForRestructuring)}</td>');
    buffer.writeln('<td style="border: 1px solid #666; padding: 8px;"></td>');
    buffer.writeln('</tr>');
    
    buffer.writeln('</tbody>');
    buffer.writeln('</table><br>');
    return buffer.toString();
  }

  String _buildPlainTextInvestmentsTableForInvestor(InvestorSummary investor) {
    final buffer = StringBuffer();
    buffer.writeln('\nSzczegółowe inwestycje: ${investor.client.name}');
    
    double totalInvestmentAmount = 0;
    double totalRemainingCapital = 0;
    double totalCapitalSecured = 0;
    double totalCapitalForRestructuring = 0;
    
    for (final inv in investor.investments) {
      totalInvestmentAmount += inv.investmentAmount;
      totalRemainingCapital += inv.remainingCapital;
      totalCapitalSecured += inv.capitalSecuredByRealEstate;
      totalCapitalForRestructuring += inv.capitalForRestructuring;
      
      buffer.writeln(inv.productName);
      buffer.writeln(
        '  • Kwota inwestycji: ${_formatCurrency(inv.investmentAmount)}',
      );
      buffer.writeln(
        '  • Kapitał pozostały: ${_formatCurrency(inv.remainingCapital)}',
      );
      buffer.writeln(
        '  • Kapitał zabezpieczony: ${_formatCurrency(inv.capitalSecuredByRealEstate)}',
      );
      buffer.writeln(
        '  • Kapitał do restrukturyzacji: ${_formatCurrency(inv.capitalForRestructuring)}',
      );
      if (inv.creditorCompany.isNotEmpty) {
        buffer.writeln('  • Wierzyciel: ${inv.creditorCompany}');
      }
      buffer.writeln('');
    }
    
    buffer.writeln('RAZEM:');
    buffer.writeln(
      '  • Kwota inwestycji: ${_formatCurrency(totalInvestmentAmount)}',
    );
    buffer.writeln(
      '  • Kapitał pozostały: ${_formatCurrency(totalRemainingCapital)}',
    );
    buffer.writeln(
      '  • Kapitał zabezpieczony: ${_formatCurrency(totalCapitalSecured)}',
    );
    buffer.writeln(
      '  • Kapitał do restrukturyzacji: ${_formatCurrency(totalCapitalForRestructuring)}',
    );
    buffer.writeln('\n');
    return buffer.toString();
  }

  String _buildPlainTextAggregatedTable(List<InvestorSummary> recipients) {
    final buffer = StringBuffer();
    buffer.writeln('\n----- Zbiorcze podsumowanie inwestycji -----\n');
    buffer.writeln('Klient | Liczba inwestycji | Kapitał pozostały | Kapitał zabezpieczony | Kapitał do restrukturyzacji');
    buffer.writeln('---------------------------------------------');
    
    double totalCapitalRemaining = 0;
    double totalCapitalSecured = 0;
    double totalCapitalForRestructuring = 0;
    int totalInvestmentCount = 0;
    
    for (final inv in recipients) {
      totalCapitalRemaining += inv.totalRemainingCapital;
      totalCapitalSecured += inv.capitalSecuredByRealEstate;
      totalCapitalForRestructuring += inv.capitalForRestructuring;
      totalInvestmentCount += inv.investmentCount;
      
      buffer.writeln('${inv.client.name} | ${inv.investmentCount} | ${_formatCurrency(inv.totalRemainingCapital)} | ${_formatCurrency(inv.capitalSecuredByRealEstate)} | ${_formatCurrency(inv.capitalForRestructuring)}');
    }
    
    buffer.writeln('RAZEM | $totalInvestmentCount | ${_formatCurrency(totalCapitalRemaining)} | ${_formatCurrency(totalCapitalSecured)} | ${_formatCurrency(totalCapitalForRestructuring)}');
    buffer.writeln('\n');
    return buffer.toString();
  }

  void _addAdditionalEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return;
  // Basic validation (match standard email pattern)
  final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    if (!valid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Niepoprawny adres email: $email'), backgroundColor: AppThemePro.statusError),
        );
      }
      return;
    }

    if (!_additionalEmails.contains(email)) {
      setState(() {
        _additionalEmails.add(email);
        _additionalEmailsConfirmed[email] = true; // auto-confirm on add
      });
    }
  }

  
  /// Converts new investment list format to HTML
  String _convertNewInvestmentListToHtml(
    String investorName,
    String investmentsList,
    String totalsList,
  ) {
    final buffer = StringBuffer();

    buffer.writeln(
      '<div style="margin: 20px 0; padding: 20px; background-color: #f8f9fa; border-radius: 8px; border-left: 4px solid #d4af37;">',
    );
    buffer.writeln(
      '<h3 style="color: #d4af37; margin-bottom: 16px;">📊 Szczegółowe inwestycje: $investorName</h3>',
    );

    // Parse investments from list format
    final lines = investmentsList
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    String? currentProduct;
    List<String> currentDetails = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('•') && !trimmed.startsWith('  •')) {
        // This is a product name
        if (currentProduct != null && currentDetails.isNotEmpty) {
          // Output previous product
          buffer.writeln(
            '<p style="margin: 8px 0; font-size: 14px; line-height: 1.5;">',
          );
          buffer.writeln('<strong>$currentProduct</strong><br>');
          for (final detail in currentDetails) {
            buffer.writeln('$detail<br>');
          }
          buffer.writeln('</p>');
        }
        currentProduct = trimmed;
        currentDetails.clear();
      } else if (trimmed.startsWith('•') || trimmed.startsWith('  •')) {
        // This is a detail line
        final cleanDetail = trimmed.replaceFirst(RegExp(r'^\s*•\s*'), '• ');
        currentDetails.add(cleanDetail);
      }
    }

    // Output last product
    if (currentProduct != null && currentDetails.isNotEmpty) {
      buffer.writeln(
        '<p style="margin: 8px 0; font-size: 14px; line-height: 1.5;">',
      );
      buffer.writeln('<strong>$currentProduct</strong><br>');
      for (final detail in currentDetails) {
        buffer.writeln('$detail<br>');
      }
      buffer.writeln('</p>');
    }

    // Add totals section
    if (totalsList.isNotEmpty) {
      buffer.writeln(
        '<div style="margin-top: 16px; padding: 12px; background-color: #d4af37; color: white; border-radius: 6px;">',
      );
      buffer.writeln('<strong>RAZEM</strong><br>');

      final totalLines = totalsList
          .split('\n')
          .where((line) => line.trim().isNotEmpty);
      for (final totalLine in totalLines) {
        final trimmed = totalLine.trim();
        if (trimmed.startsWith('•') || trimmed.startsWith('  •')) {
          final cleanDetail = trimmed.replaceFirst(RegExp(r'^\s*•\s*'), '• ');
          buffer.writeln('$cleanDetail<br>');
        }
      }
      buffer.writeln('</div>');
    }

    buffer.writeln('</div>');
    return buffer.toString();
  }
  
  /// Converts detailed plain text table to HTML table (for individual investor detailed tables)
  String _convertDetailedPlainTextTableToHtml(String investorName, String tableRows, String totalRow) {
    final buffer = StringBuffer();
    
    // Simple text formatting without HTML table
    buffer.writeln(
      '<div style="margin: 20px 0; padding: 20px; background-color: #f8f9fa; border-radius: 8px; border-left: 4px solid #d4af37;">',
    );
    buffer.writeln('<h3 style="color: #d4af37; margin-bottom: 16px;">📊 Szczegółowe inwestycje: $investorName</h3>');
    
    // Convert table rows to simple text lines
    final rows = tableRows.split('\n').where((row) => row.trim().isNotEmpty);
    for (final row in rows) {
      final columns = row.split('|').map((col) => col.trim()).toList();
      
      if (columns.length >= 6) {
        buffer.writeln(
          '<p style="margin: 8px 0; font-size: 14px; line-height: 1.5;">',
        );
        buffer.writeln('<strong>${columns[0]}</strong><br>');
        buffer.writeln('• Kwota inwestycji: ${columns[1]}<br>');
        buffer.writeln('• Kapitał pozostały: ${columns[2]}<br>');
        buffer.writeln('• Kapitał zabezpieczony: ${columns[3]}<br>');
        buffer.writeln('• Kapitał do restrukturyzacji: ${columns[4]}<br>');
        if (columns[5].isNotEmpty) {
          buffer.writeln('• Wierzyciel: ${columns[5]}<br>');
        }
        buffer.writeln('</p>');
      }
    }
    
    // Total row as simple text
    if (totalRow.isNotEmpty) {
      final totalColumns = totalRow.split('|').map((col) => col.trim()).toList();
      if (totalColumns.length >= 5) {
        buffer.writeln(
          '<div style="margin-top: 16px; padding: 12px; background-color: #d4af37; color: white; border-radius: 6px;">',
        );
        buffer.writeln(
          '<h4 style="margin: 0 0 8px 0; color: white;">PODSUMOWANIE:</h4>',
        );
        buffer.writeln('<p style="margin: 4px 0; font-weight: bold;">');
        buffer.writeln('• Łączna kwota inwestycji: ${totalColumns[1]}<br>');
        buffer.writeln('• Łączny kapitał pozostały: ${totalColumns[2]}<br>');
        buffer.writeln(
          '• Łączny kapitał zabezpieczony: ${totalColumns[3]}<br>',
        );
        buffer.writeln(
          '• Łączny kapitał do restrukturyzacji: ${totalColumns[4]}',
        );
        buffer.writeln('</p>');
        buffer.writeln('</div>');
      }
    }
    
    buffer.writeln('</div>');
    
    return buffer.toString();
  }
  
  /// Converts detailed aggregated plain text table to simple text format
  String _convertDetailedAggregatedTableToHtml(String tableRows, String totalRow) {
    final buffer = StringBuffer();
    
    // Simple text formatting without HTML table
    buffer.writeln(
      '<div style="margin: 20px 0; padding: 20px; background-color: #f0f8ff; border-radius: 8px; border-left: 4px solid #d4af37;">',
    );
    buffer.writeln('<h3 style="color: #d4af37; margin-bottom: 16px;">📊 Zbiorcze podsumowanie inwestycji</h3>');
    
    // Convert table rows to simple text lines
    final rows = tableRows.split('\n').where((row) => row.trim().isNotEmpty);
    for (final row in rows) {
      final columns = row.split('|').map((col) => col.trim()).toList();
      
      if (columns.length >= 5) {
        buffer.writeln(
          '<p style="margin: 12px 0; font-size: 14px; line-height: 1.6; padding: 12px; background-color: white; border-radius: 6px; border-left: 3px solid #d4af37;">',
        );
        buffer.writeln(
          '<strong style="color: #2c2c2c; font-size: 16px;">${columns[0]}</strong><br>',
        );
        buffer.writeln(
          '• Liczba inwestycji: <strong>${columns[1]}</strong><br>',
        );
        buffer.writeln(
          '• Kapitał pozostały: <strong>${columns[2]}</strong><br>',
        );
        buffer.writeln(
          '• Kapitał zabezpieczony: <strong>${columns[3]}</strong><br>',
        );
        buffer.writeln(
          '• Kapitał do restrukturyzacji: <strong>${columns[4]}</strong>',
        );
        buffer.writeln('</p>');
      }
    }
    
    // Total row as simple text
    if (totalRow.isNotEmpty) {
      final totalColumns = totalRow.split('|').map((col) => col.trim()).toList();
      if (totalColumns.length >= 5) {
        buffer.writeln(
          '<div style="margin-top: 16px; padding: 16px; background-color: #d4af37; color: white; border-radius: 8px;">',
        );
        buffer.writeln(
          '<h4 style="margin: 0 0 12px 0; color: white; font-size: 18px;">📈 ŁĄCZNE PODSUMOWANIE:</h4>',
        );
        buffer.writeln(
          '<p style="margin: 0; font-size: 16px; font-weight: bold; line-height: 1.5;">',
        );
        buffer.writeln('• Łączna liczba inwestycji: ${totalColumns[1]}<br>');
        buffer.writeln('• Łączny kapitał pozostały: ${totalColumns[2]}<br>');
        buffer.writeln(
          '• Łączny kapitał zabezpieczony: ${totalColumns[3]}<br>',
        );
        buffer.writeln(
          '• Łączny kapitał do restrukturyzacji: ${totalColumns[4]}',
        );
        buffer.writeln('</p>');
        buffer.writeln('</div>');
      }
    }
    
    buffer.writeln('</div>');
    
    return buffer.toString();
  }
  


  /// Debug method to analyze Quill content
  void _debugQuillContent() {
    if (kDebugMode) {
      final plainText = _quillController.document.toPlainText();
      final delta = _quillController.document.toDelta();

      print('🔍 [QuillDebug] Document plain text:');
      print(plainText);
      print('🔍 [QuillDebug] Plain text length: ${plainText.length}');
      print('🔍 [QuillDebug] Document delta:');
      print(delta.toJson());

      // **NOWE PODEJŚCIE: Użyj naszej niezawodnej konwersji**
      final html = _convertQuillToReliableHtml(_quillController);

      print('🔍 [QuillDebug] Generated HTML (reliable conversion):');
      print(html);
      print('🔍 [QuillDebug] HTML length: ${html.length}');

      // Check for investment content patterns
      print('🔍 [QuillDebug] Pattern analysis:');
      print(
        '- Contains "Szczegółowe inwestycje": ${plainText.contains('Szczegółowe inwestycje')}',
      );
      print(
        '- Contains "Metropolitan Investment": ${plainText.contains('Metropolitan Investment')}',
      );
      print(
        '- Contains "Kwota inwestycji": ${plainText.contains('Kwota inwestycji')}',
      );
      print('- Contains "RAZEM": ${plainText.contains('RAZEM')}');

      // Advanced debugging: Check if HTML conversion failed or is incomplete
      final conversionFailed =
          (html.length < 50 && plainText.length > 100) ||
          (plainText.length > html.length * 3) ||
          (plainText.contains('Szczegółowe inwestycje') &&
              !html.contains('Szczegółowe inwestycje')) ||
          (plainText.contains('📊 Inwestycje:') &&
              !html.contains('📊 Inwestycje:'));

      if (conversionFailed) {
        print('⚠️ [QuillDebug] PROBLEM: HTML conversion failed or incomplete!');
        print('   Plain text length: ${plainText.length}');
        print('   HTML length: ${html.length}');
        print('   Ratio: ${plainText.length / html.length}');
        print('⚠️ [QuillDebug] This indicates a conversion issue.');

        // Try alternative conversion
        final alternativeHtml = _convertPlainTextToBasicHtml(plainText);
        print('🔧 [QuillDebug] Alternative HTML conversion:');
        print(
          alternativeHtml.substring(0, math.min(1000, alternativeHtml.length)),
        );
        print(
          '🔧 [QuillDebug] Alternative HTML length: ${alternativeHtml.length}',
        );
      } else {
        print('✅ [QuillDebug] HTML conversion appears successful');
      }
    }
  }

  /// Format numbers with thousands separators for better readability
  String _formatNumbersInText(String text) {
    // Pattern to match numbers with decimal places (like 3000000,00 zł)
    final numberPattern = RegExp(
      r'(\d{4,})([,\.]\d{2})?\s*(zł|PLN|EUR|USD)?',
      caseSensitive: false,
    );

    return text.replaceAllMapped(numberPattern, (match) {
      final numberPart = match.group(1)!;
      final decimalPart = match.group(2) ?? '';
      final currency = match.group(3) ?? '';

      // Add thousands separators
      final formattedNumber = _addThousandsSeparators(numberPart);

      // Reconstruct with proper spacing
      return '$formattedNumber$decimalPart${currency.isNotEmpty ? ' $currency' : ''}';
    });
  }

  /// Add thousands separators to a number string
  String _addThousandsSeparators(String numberStr) {
    if (numberStr.length <= 3) return numberStr;

    final reversedChars = numberStr.split('').reversed.toList();
    final result = <String>[];

    for (int i = 0; i < reversedChars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        result.add(' '); // Use space as thousands separator
      }
      result.add(reversedChars[i]);
    }

    return result.reversed.join();
  }


  /// Alternative conversion method for when Quill-to-HTML fails
  String _convertPlainTextToBasicHtml(String plainText) {
    if (plainText.trim().isEmpty) return '<p></p>';

    // First, format numbers in the entire text for better readability
    final formattedText = _formatNumbersInText(plainText);

    // Convert plain text to basic HTML
    final lines = formattedText.split('\n');
    final buffer = StringBuffer();
    bool inTable = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        if (!inTable) {
          buffer.writeln('<br/>');
        }
        continue;
      }

      if (trimmed.startsWith('•')) {
        // Bullet point
        buffer.writeln(
          '<p style="margin-left: 20px; margin: 4px 0;">$trimmed</p>',
        );
      } else if (trimmed.startsWith('📊')) {
        // Investment section with emoji
        buffer.writeln(
          '<h3 style="color: #d4af37; margin: 16px 0 8px 0;">$trimmed</h3>',
        );
      } else if (trimmed.startsWith('📈')) {
        // Summary section with emoji
        buffer.writeln(
          '<h3 style="color: #d4af37; margin: 16px 0 8px 0;">$trimmed</h3>',
        );
      } else if (trimmed.startsWith('──') && trimmed.contains('PODSUMOWANIE')) {
        // Summary divider
        buffer.writeln(
          '<h4 style="color: #d4af37; margin: 12px 0 8px 0; border-top: 2px solid #d4af37; padding-top: 8px;">$trimmed</h4>',
        );
      } else if (trimmed.startsWith('═══') &&
          trimmed.contains('PODSUMOWANIE')) {
        // Global summary divider
        buffer.writeln(
          '<h4 style="color: #d4af37; margin: 12px 0 8px 0; border-top: 3px solid #d4af37; padding-top: 8px;">$trimmed</h4>',
        );
      } else if (trimmed.contains('|') &&
          (trimmed.contains('Klient') ||
              trimmed.contains('Liczba inwestycji'))) {
        // Table header
        if (!inTable) {
          buffer.writeln(
            '<table style="border-collapse: collapse; width: 100%; margin: 10px 0;">',
          );
          inTable = true;
        }
        final columns = trimmed.split('|').map((col) => col.trim()).toList();
        buffer.writeln('<tr style="background-color: #f0f0f0;">');
        for (final col in columns) {
          buffer.writeln(
            '<th style="border: 1px solid #ddd; padding: 8px; text-align: left;"><strong>$col</strong></th>',
          );
        }
        buffer.writeln('</tr>');
      } else if (trimmed.contains('|') &&
          (trimmed.contains('RAZEM') || !trimmed.startsWith('-'))) {
        // Table data row
        if (!inTable) {
          buffer.writeln(
            '<table style="border-collapse: collapse; width: 100%; margin: 10px 0;">',
          );
          inTable = true;
        }
        final columns = trimmed.split('|').map((col) => col.trim()).toList();
        final isTotal = trimmed.contains('RAZEM');
        buffer.writeln(
          '<tr${isTotal ? ' style="background-color: #fffacd; font-weight: bold;"' : ''}>',
        );
        for (final col in columns) {
          buffer.writeln(
            '<td style="border: 1px solid #ddd; padding: 8px;">$col</td>',
          );
        }
        buffer.writeln('</tr>');
      } else if (trimmed.startsWith('-') && trimmed.length > 10) {
        // Table separator line - ignore
        continue;
      } else {
        // Close table if we were in one
        if (inTable) {
          buffer.writeln('</table>');
          inTable = false;
        }

        if (trimmed.contains('RAZEM:')) {
          // Summary section
          buffer.writeln(
            '<p style="font-weight: bold; margin: 8px 0;"><strong>$trimmed</strong></p>',
          );
        } else if (trimmed.startsWith('Szczegółowe inwestycje:')) {
          // Investment section header
          buffer.writeln(
            '<h3 style="color: #d4af37; margin: 16px 0 8px 0;">📊 $trimmed</h3>',
          );
        } else if (trimmed.startsWith('Zbiorcze podsumowanie')) {
          // Summary section header
          buffer.writeln(
            '<h3 style="color: #d4af37; margin: 16px 0 8px 0;">📊 $trimmed</h3>',
          );
        } else if (trimmed.contains('Metropolitan') ||
            trimmed.contains('MI S.A.') ||
            trimmed.contains('Projekt')) {
          // Investment product name
          buffer.writeln(
            '<p style="font-weight: bold; margin: 8px 0 4px 0;"><strong>$trimmed</strong></p>',
          );
        } else if (trimmed.startsWith('Kwota inwestycji:') ||
            trimmed.startsWith('Kapitał pozostały:') ||
            trimmed.startsWith('Kapitał zabezpieczony:') ||
            trimmed.startsWith('Kapitał do restrukturyzacji:') ||
            trimmed.startsWith('Liczba inwestycji:') ||
            trimmed.startsWith('Łącznie inwestycji:') ||
            trimmed.startsWith('Łączny kapitał') ||
            trimmed.startsWith('Łączna kwota')) {
          // Investment details - with indentation
          buffer.writeln(
            '<p style="margin: 2px 0 2px 20px; font-size: 14px;">$trimmed</p>',
          );
        } else if (trimmed.startsWith('Status:')) {
          // Status line - check if it contains voting status
          String statusLine = trimmed;

          // Look for voting status patterns in the status line
          final votingPattern = RegExp(
            r'Status:\s*(\w+)(?:\s*\|\s*Głosowanie:\s*(\w+))?',
            caseSensitive: false,
          );
          final match = votingPattern.firstMatch(trimmed);

          if (match != null) {
            final mainStatus = match.group(1) ?? '';
            final votingStatus = match.group(2);

            statusLine = 'Status: $mainStatus';
            if (votingStatus != null && votingStatus.isNotEmpty) {
              statusLine += ' | Głosowanie: $votingStatus';
            }
          }

          buffer.writeln(
            '<p style="margin: 2px 0 2px 20px; font-size: 14px;">$statusLine</p>',
          );
        } else if (trimmed.startsWith('Głosowanie:')) {
          // Standalone voting status line
          final votingPattern = RegExp(
            r'Głosowanie:\s*(\w+)',
            caseSensitive: false,
          );
          final match = votingPattern.firstMatch(trimmed);

          String votingLine = trimmed;
          if (match != null) {
            final votingStatus = match.group(1);
            votingLine = 'Głosowanie: $votingStatus';
          }

          buffer.writeln(
            '<p style="margin: 2px 0 2px 20px; font-size: 14px;">$votingLine</p>',
          );
        } else {
          // Regular paragraph
          buffer.writeln('<p style="margin: 4px 0;">$trimmed</p>');
        }
      }
    }

    // Close table if we ended in one
    if (inTable) {
      buffer.writeln('</table>');
    }

    return buffer.toString();
  }

  /// Test HTML conversion and display detailed debugging information
  void _testHtmlConversion() {
    if (!kDebugMode) return;

    try {
      final currentController = _getCurrentController();
      final plainText = currentController.document.toPlainText();
      final deltaJson = currentController.document.toDelta().toJson();
      final convertedHtml = _convertQuillToReliableHtml(currentController);
      
      print('═══════════════════════════════════════');
      print('🔍 TEST KONWERSJI HTML - SZCZEGÓŁOWE DEBUGOWANIE');
      print('═══════════════════════════════════════');
      print('📝 Plain text (${plainText.length} chars):');
      print('   ${plainText.substring(0, math.min(200, plainText.length))}${plainText.length > 200 ? '...' : ''}');
      print('');
      
      print('🔄 Delta JSON (${deltaJson.toString().length} chars):');
      print('   $deltaJson');
      print('');
      
      print('📧 Converted HTML (${convertedHtml.length} chars):');
      print('   $convertedHtml');
      print('');
      
      // Test font mapping
      print('🎨 MAPOWANIE FONTÓW:');
      print('   Custom font families: ${_customFontFamilies.keys.join(', ')}');
      print('   Custom font sizes: ${_customFontSizes.keys.join(', ')}');
      print('');
      
      // Test with investment details
      String? testInvestor;
      if (_selectedPreviewRecipient?.startsWith('investor:') == true) {
        testInvestor = _selectedPreviewRecipient!.substring('investor:'.length);
        final investor = widget.selectedInvestors.firstWhere(
          (inv) => inv.client.id == testInvestor,
          orElse: () => widget.selectedInvestors.first,
        );
        
        final processedHtml = _ensureInvestmentDetails(
          convertedHtml,
          specificInvestor: investor,
        );
        
        print('📊 HTML z szczegółami inwestycji dla ${investor.client.name} (${processedHtml.length} chars):');
        print('   ${processedHtml.substring(0, math.min(300, processedHtml.length))}${processedHtml.length > 300 ? '...' : ''}');
      } else {
        final processedHtml = _ensureInvestmentDetails(
          convertedHtml,
          allInvestors: widget.selectedInvestors,
        );
        
        print('📊 HTML ze zbiorczymi szczegółami inwestycji (${processedHtml.length} chars):');
        print('   ${processedHtml.substring(0, math.min(300, processedHtml.length))}${processedHtml.length > 300 ? '...' : ''}');
      }
      print('');
      
      // Test formatting detection
      final hasFormatting = convertedHtml.contains('font-family') || 
                           convertedHtml.contains('font-size') || 
                           convertedHtml.contains('color:') ||
                           convertedHtml.contains('background-color');
      print('✨ FORMATOWANIE:');
      print('   Wykryto formatowanie: ${hasFormatting ? '✅' : '❌'}');
      if (hasFormatting) {
        if (convertedHtml.contains('font-family')) print('   - Font family: ✅');
        if (convertedHtml.contains('font-size')) print('   - Font size: ✅');
        if (convertedHtml.contains('color:')) print('   - Text color: ✅');
        if (convertedHtml.contains('background-color')) print('   - Background color: ✅');
      }
      
      print('═══════════════════════════════════════');
      
      // Show user-friendly notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.bug_report, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Debug HTML konwersji - sprawdź konsole dla szczegółów\n'
                    'HTML: ${convertedHtml.length} znaków, Formatowanie: ${hasFormatting ? 'TAK' : 'NIE'}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      }
      
    } catch (e) {
      print('❌ Błąd podczas debugowania konwersji HTML: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd debugowania: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Debug button for development (only visible in debug mode)
  Widget _buildDebugButton() {
    if (!kDebugMode) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton.icon(
        onPressed: _debugQuillContent,
        icon: const Icon(Icons.bug_report, size: 16),
        label: const Text('Debug', style: TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(0, 32),
        ),
      ),
    );
  }
}