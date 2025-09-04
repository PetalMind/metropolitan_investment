import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart' as html_package;

import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';
import '../services/email_html_converter_service.dart';


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

  // 💾 AUTO-SAVE FUNCTIONALITY
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  bool _isAutoSaving = false;
  DateTime? _lastAutoSaveTime;
  late UserPreferencesService _preferencesService;



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

    // 💾 INITIALIZE AUTO-SAVE SERVICE
    _initializeAutoSave();

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

  // 💾 AUTO-SAVE FUNCTIONALITY IMPLEMENTATION

  /// Initialize auto-save functionality
  Future<void> _initializeAutoSave() async {
    try {
      _preferencesService = await UserPreferencesService.getInstance();

      // Check for existing draft and offer recovery
      await _checkForDraftRecovery();

      // Set up auto-save timer (every 30 seconds)
      _startAutoSaveTimer();

      // Add listeners for content changes
      _quillController.addListener(_onContentChanged);
      _subjectController.addListener(_onContentChanged);
      _senderNameController.addListener(_onContentChanged);
      _senderEmailController.addListener(_onContentChanged);

      debugPrint('💾 Auto-save initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing auto-save: $e');
    }
  }

  /// Check for existing draft and offer recovery
  Future<void> _checkForDraftRecovery() async {
    if (!_preferencesService.hasEmailDraft()) return;

    final draft = _preferencesService.getSavedEmailDraft();
    if (draft == null) return;

    final age = _preferencesService.getEmailDraftAgeInMinutes() ?? 0;

    // Show recovery dialog
    if (mounted) {
      final shouldRecover = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.restore, color: Colors.orange),
              SizedBox(width: 12),
              Text('Odzyskaj szkic'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Znaleziono zapisany szkic wiadomości sprzed $age minut.'),
              const SizedBox(height: 12),
              Text('Czy chcesz odzyskać wcześniej zapisaną treść?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Temat: ${draft['subject']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Podgląd: ${(draft['content'] as String).substring(0, (draft['content'] as String).length > 100 ? 100 : (draft['content'] as String).length)}...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Odrzuć szkic'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Odzyskaj szkic'),
            ),
          ],
        ),
      );

      if (shouldRecover == true) {
        await _recoverDraft(draft);
      } else {
        await _preferencesService.clearEmailDraft();
      }
    }
  }

  /// Recover draft content
  Future<void> _recoverDraft(Map<String, dynamic> draft) async {
    try {
      // Restore text content
      _subjectController.text = draft['subject'] ?? '';
      _senderNameController.text = draft['senderName'] ?? '';
      _senderEmailController.text = draft['senderEmail'] ?? '';

      // Restore Quill content
      final content = draft['content'] as String;
      if (content.isNotEmpty) {
        _quillController.clear();
        _quillController.document.insert(0, content);
      }

      // Restore recipients
      final recipients = draft['recipients'] as Map<String, bool>? ?? {};
      _recipientEnabled.clear();
      _recipientEnabled.addAll(recipients);

      // Restore additional emails
      final additionalEmails = draft['additionalEmails'] as List<String>? ?? [];
      _additionalEmails.clear();
      _additionalEmails.addAll(additionalEmails);

      // Restore settings
      _includeInvestmentDetails = draft['includeDetails'] ?? true;
      _isGroupEmail = draft['isGroupEmail'] ?? false;

      setState(() {
        _hasUnsavedChanges = false;
      });

      // Force preview update
      _forcePreviewUpdate();

      debugPrint('✅ Draft recovered successfully');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Szkic został pomyślnie odzyskany'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error recovering draft: $e');
    }
  }

  /// Start auto-save timer
  void _startAutoSaveTimer() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_hasUnsavedChanges && !_isAutoSaving) {
        _performAutoSave();
      }
    });
  }

  /// Handle content changes
  void _onContentChanged() {
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  /// Perform auto-save
  Future<void> _performAutoSave() async {
    if (_isAutoSaving) return;

    setState(() {
      _isAutoSaving = true;
    });

    try {
      final content = _quillController.document.toPlainText();
      final subject = _subjectController.text;
      final senderName = _senderNameController.text;
      final senderEmail = _senderEmailController.text;

      final success = await _preferencesService.saveEmailDraft(
        content: content,
        subject: subject,
        senderName: senderName,
        senderEmail: senderEmail,
        recipients: Map.from(_recipientEnabled),
        additionalEmails: List.from(_additionalEmails),
        includeDetails: _includeInvestmentDetails,
        isGroupEmail: _isGroupEmail,
      );

      if (success) {
        setState(() {
          _hasUnsavedChanges = false;
          _lastAutoSaveTime = DateTime.now();
        });
        debugPrint('💾 Auto-save completed successfully');
      }
    } catch (e) {
      debugPrint('❌ Auto-save failed: $e');
    } finally {
      setState(() {
        _isAutoSaving = false;
      });
    }
  }

  /// Manual save trigger
  Future<void> _saveManually() async {
    await _performAutoSave();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.save, color: Colors.white),
              SizedBox(width: 12),
              Text('Szkic został zapisany'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _previewUpdateTimer?.cancel(); // Clean up timer
    _autoSaveTimer?.cancel(); // Clean up auto-save timer
    _quillController.removeListener(_updatePreviewContent);
    _quillController.removeListener(
      _onContentChanged,
    ); // Remove auto-save listener
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
            _currentPreviewHtml = EmailHtmlConverterService.convertQuillToHtml(
              _quillController,
            );
            if (_includeInvestmentDetails) {
              _currentPreviewHtml =
                  EmailHtmlConverterService.addInvestmentDetailsToHtml(
                _currentPreviewHtml,
                    widget.selectedInvestors,
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
          _currentPreviewHtml = EmailHtmlConverterService.convertQuillToHtml(
            _quillController,
          );
          if (_includeInvestmentDetails) {
            _currentPreviewHtml =
                EmailHtmlConverterService.addInvestmentDetailsToHtml(
              _currentPreviewHtml,
                  widget.selectedInvestors,
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
        content: const Text(
          'Czy na pewno chcesz wyczyścić całą treść? Spowoduje to również usunięcie zapisanego szkicu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () async {
              _quillController.clear();
              _subjectController.clear();

              // Clear draft
              await _preferencesService.clearEmailDraft();

              setState(() {
                _hasUnsavedChanges = false;
                _lastAutoSaveTime = null;
              });
              
              Navigator.of(context).pop();
              
              // Show confirmation
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.delete_sweep, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Edytor i szkic zostały wyczyszczone'),
                      ],
                    ),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
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
      
      final emailHtml = EmailHtmlConverterService.convertQuillToHtml(
        _quillController,
      );
      final finalHtml = _includeInvestmentDetails 
          ? EmailHtmlConverterService.addInvestmentDetailsToHtml(
              emailHtml,
              widget.selectedInvestors,
            )
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
        
        // 💾 Clear draft after successful sending
        await _preferencesService.clearEmailDraft();
        setState(() {
          _hasUnsavedChanges = false;
          _lastAutoSaveTime = null;
        });
        debugPrint('🗑️ Draft cleared after successful email sending');
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
          // 💾 AUTO-SAVE STATUS INDICATOR
          _buildAutoSaveIndicator(isMobile),
          SizedBox(width: isMobile ? 8 : 12),
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

  // 💾 AUTO-SAVE STATUS INDICATOR
  Widget _buildAutoSaveIndicator(bool isMobile) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(
          '${_isAutoSaving}_${_hasUnsavedChanges}_${_lastAutoSaveTime?.millisecondsSinceEpoch}',
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 12,
          vertical: isMobile ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: _getAutoSaveIndicatorColor().withValues(alpha: 0.1),
          border: Border.all(
            color: _getAutoSaveIndicatorColor().withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isAutoSaving) ...[
              SizedBox(
                width: isMobile ? 12 : 14,
                height: isMobile ? 12 : 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    _getAutoSaveIndicatorColor(),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Zapisuję...',
                style: TextStyle(
                  color: _getAutoSaveIndicatorColor(),
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else if (_hasUnsavedChanges) ...[
              Icon(
                Icons.edit,
                size: isMobile ? 12 : 14,
                color: _getAutoSaveIndicatorColor(),
              ),
              const SizedBox(width: 4),
              Text(
                'Niezapisane',
                style: TextStyle(
                  color: _getAutoSaveIndicatorColor(),
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else if (_lastAutoSaveTime != null) ...[
              Icon(
                Icons.check_circle,
                size: isMobile ? 12 : 14,
                color: _getAutoSaveIndicatorColor(),
              ),
              const SizedBox(width: 4),
              Text(
                _getLastSaveText(),
                style: TextStyle(
                  color: _getAutoSaveIndicatorColor(),
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else ...[
              Icon(
                Icons.fiber_new,
                size: isMobile ? 12 : 14,
                color: _getAutoSaveIndicatorColor(),
              ),
              const SizedBox(width: 4),
              Text(
                'Nowy',
                style: TextStyle(
                  color: _getAutoSaveIndicatorColor(),
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            // Manual save button
            if (!_isAutoSaving) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _saveManually,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.save,
                    size: isMobile ? 12 : 14,
                    color: _getAutoSaveIndicatorColor().withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getAutoSaveIndicatorColor() {
    if (_isAutoSaving) return Colors.blue;
    if (_hasUnsavedChanges) return Colors.orange;
    if (_lastAutoSaveTime != null) return Colors.green;
    return Colors.grey;
  }

  String _getLastSaveText() {
    if (_lastAutoSaveTime == null) return 'Niezapisane';

    final now = DateTime.now();
    final difference = now.difference(_lastAutoSaveTime!);

    if (difference.inSeconds < 60) {
      return 'Zapisano';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min temu';
    } else {
      return '${difference.inHours}h temu';
    }
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
                icon: Icons.save_outlined,
                label: 'Zapisz szkic',
                color: _hasUnsavedChanges
                    ? AppThemePro.statusWarning
                    : AppThemePro.statusSuccess,
                onPressed: _saveManually,
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


