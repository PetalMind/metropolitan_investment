import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart' as html_package;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

import '../../models_and_services.dart';
import '../models/email_template.dart';
import '../models/email_attachment.dart';

import '../widgets/html_editor_widget.dart';
import '../widgets/email/email_template_selector.dart';
import '../utils/email_content_utils.dart';

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

// 🎯 UJEDNOLICONY ENUM dla typów odbiorców z flagami
enum RecipientType {
  main,
  additional,
  preview;

  // 🏷️ WŁAŚCIWOŚCI OKREŚLAJĄCE ZACHOWANIE (uproszczone)
  bool get includesAllInvestors {
    switch (this) {
      case RecipientType.additional:
      case RecipientType.preview:
        return true; // Wszystkie inwestycje
      case RecipientType.main:
        return false; // Firebase określa logikę
    }
  }

  String get displayName {
    switch (this) {
      case RecipientType.main:
        return 'Główni odbiorcy';
      case RecipientType.additional:
        return 'Dodatkowi odbiorcy';
      case RecipientType.preview:
        return 'Podgląd';
    }
  }

  // 🎨 UJEDNOLICONE NAGŁÓWKI dla każdego typu
  (String title, String description) getHeaders(bool isGroupEmail) {
    switch (this) {
      case RecipientType.additional:
        return (
          '📈 Szczegółowe Informacje wszystkich inwestycji',
          'Poniżej znajdą Państwo wszystkie inwestycje wszystkich wybranych klientów:',
        );
      case RecipientType.preview:
        return (
          '👀 Podgląd: Szczegółowe Informacje o Investycjach',
          'Podgląd wiadomości - pokazuje wszystkie inwestycje wybranych klientów:',
        );
      case RecipientType.main:
        return (
          '📈 Szczegółowe Informacje o Inwestycjach',
          isGroupEmail
              ? 'Poniżej znajdą Państwo wszystkie inwestycje przypisane do wybranych inwestorów:'
              : 'Poniżej znajdą Państwo Wasze inwestycje:',
        );
    }
  }
}

class _WowEmailEditorScreenState extends State<WowEmailEditorScreen>
    with TickerProviderStateMixin {
  // 🎮 KONTROLERY PODSTAWOWE
  late FocusNode _editorFocusNode;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _senderEmailController = TextEditingController();
  final _senderNameController = TextEditingController(
    text: 'Metropolitan Investment',
  );
  final _subjectController = TextEditingController();
  final _additionalEmailController = TextEditingController();
  final _contentController = TextEditingController(); // For HTML content

  // 🎭 STAN SCREEN Z WOW EFEKTAMI
  bool _isLoading = false;
  bool _includeInvestmentDetails = true;
  bool _isGroupEmail = false;
  bool _isEditorExpanded = true; // Domyślnie rozwinięty dla lepszego doświadczenia
  bool _isSettingsCollapsed = false;
  bool _isRecipientsCollapsed = false;
  bool _isPreviewVisible = false;
  bool _isPreviewDarkTheme = false;
  String? _error;
  List<EmailSendResult>? _results;
  String _currentPreviewHtml =
      '<div style="font-family: Arial, sans-serif; font-size: 16px; line-height: 1.6; color: #666; font-style: italic;"><p>Ładowanie podglądu...</p></div>';
  double _previewZoomLevel = 1.0;

  // 🆕 NEW HTML EDITOR INTEGRATION
  bool _useHtmlEditor = true; // Toggle between Quill and HTML editor

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

  // 📅 EMAIL SCHEDULING FUNCTIONALITY
  late EmailSchedulingService _emailSchedulingService;
  DateTime? _scheduledDateTime;
  bool _isSchedulingEnabled = false;
  String? _schedulingError;

  // 💾 AUTO-SAVE FUNCTIONALITY
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  bool _isAutoSaving = false;
  DateTime? _lastAutoSaveTime;
  late UserPreferencesService _preferencesService;
  
  // 📧 TEMPLATE & ATTACHMENT FUNCTIONALITY
  bool _isTemplatesSectionCollapsed = false;
  bool _isAttachmentsSectionCollapsed = false;
  List<EmailAttachment> _attachments = [];
  EmailTemplateModel? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _initializeWowScreen();
  }

  void _initializeWowScreen() {
    // Initialize with HTML content if provided
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      _contentController.text = widget.initialMessage!;
    }

    _editorFocusNode = FocusNode();

    // 💾 INITIALIZE AUTO-SAVE SERVICE
    _initializeAutoSave();

    // 📅 INITIALIZE EMAIL SCHEDULING SERVICE
    _emailSchedulingService = EmailSchedulingService();
    _emailSchedulingService.start();

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

    // 🎪 REAL-TIME PREVIEW LISTENER - Only listen to content controller now
    _contentController.addListener(_updatePreviewContent);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeContent();
      _updatePreviewContent(); // Initial preview
    });
  }

  void _initializeRecipients() {
    
    for (final investor in widget.selectedInvestors) {
      final clientId = investor.client.id;
      final email = investor.client.email;

      // Walidacja email i domyślne włączenie dla prawidłowych adresów
      final hasValidEmail =
          email.isNotEmpty &&
          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
      
      _recipientEnabled[clientId] = hasValidEmail;
      _recipientEmails[clientId] = email;

      // Log potential issues
      if (email.isEmpty) {
      } else if (!hasValidEmail) {
      }
    }

    final enabledCount = _recipientEnabled.values
        .where((enabled) => enabled)
        .length;
    final disabledCount = _recipientEnabled.values
        .where((enabled) => !enabled)
        .length;

    // Additional warning if no recipients are enabled
    if (enabledCount == 0) {
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
        EmailContentUtils.getDefaultEmailContentForEditor();

    try {
      _contentController.text = content;

    } catch (e) {
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

      // Add listeners for content changes (cleanup in dispose())
      _contentController.addListener(_onContentChanged);
      _subjectController.addListener(_onContentChanged);
      _senderNameController.addListener(_onContentChanged);
      _senderEmailController.addListener(_onContentChanged);

    } catch (e) {
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

      // Restore HTML content
      final content = draft['content'] as String;
      if (content.isNotEmpty) {
        _contentController.text = content;
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
      final content = _contentController.text;
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
      }
    } catch (e) {
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
    // 🧹 PROPER CLEANUP - Cancel all timers first
    _previewUpdateTimer?.cancel();
    _autoSaveTimer?.cancel();

    // 🧹 REMOVE ALL LISTENERS (Memory leak fix)
    _contentController.removeListener(_updatePreviewContent);
    _contentController.removeListener(_onContentChanged);
    _subjectController.removeListener(_onContentChanged);
    _senderNameController.removeListener(_onContentChanged);
    _senderEmailController.removeListener(_onContentChanged);

    // 🧹 DISPOSE ALL CONTROLLERS
    _editorFocusNode.dispose();
    _senderEmailController.dispose();
    _senderNameController.dispose();
    _subjectController.dispose();
    _additionalEmailController.dispose();
    _contentController.dispose();

    // 🧹 DISPOSE ALL ANIMATION CONTROLLERS
    _settingsAnimationController.dispose();
    _editorAnimationController.dispose();
    _mainScreenController.dispose();
    _recipientsAnimationController.dispose();

    // 🧹 STOP SERVICES
    _emailSchedulingService.stop();

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

            // 🎨 USE HTML EDITOR CONTENT DIRECTLY (Quill removed)
            _currentPreviewHtml = _contentController.text.isNotEmpty
                ? _contentController.text
                : '<p style="font-family: Arial, sans-serif; color: #666; font-style: italic;">Wpisz treść wiadomości...</p>';

            // 📧 DODAJ SZCZEGÓŁY INWESTYCJI JEŚLI WŁĄCZONE (asynchronicznie)
            if (_includeInvestmentDetails) {
              _currentPreviewHtml +=
                  '<div style="margin-top: 20px; padding: 15px; background: #f5f5f5; border-radius: 8px; color: #666; font-style: italic;">⏳ Ładowanie szczegółów inwestycji...</div>';

              // Asynchroniczne ładowanie szczegółów inwestycji dla preview
              _generateInvestmentDetailsHtml(type: RecipientType.preview)
                  .then((investmentDetailsHtml) {
                    if (mounted) {
                      setState(() {
                        // Zamień placeholder na rzeczywiste dane
                        _currentPreviewHtml = _currentPreviewHtml.replaceAll(
                          '<div style="margin-top: 20px; padding: 15px; background: #f5f5f5; border-radius: 8px; color: #666; font-style: italic;">⏳ Ładowanie szczegółów inwestycji...</div>',
                          investmentDetailsHtml,
                        );
                      });
                    }
                  })
                  .catchError((e) {
                    if (mounted) {
                      setState(() {
                        _currentPreviewHtml = _currentPreviewHtml.replaceAll(
                          '<div style="margin-top: 20px; padding: 15px; background: #f5f5f5; border-radius: 8px; color: #666; font-style: italic;">⏳ Ładowanie szczegółów inwestycji...</div>',
                          '<div style="margin-top: 20px; padding: 15px; background: #f8d7da; border-radius: 8px; color: #721c24;">❌ Błąd ładowania danych inwestycji</div>',
                        );
                      });
                    }
                  });

            }

          } catch (e) {
            // Fallback to plain text if conversion fails
            String fallbackText = _contentController.text;
            _currentPreviewHtml =
                '<div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">${fallbackText.isNotEmpty ? fallbackText.replaceAll('\n', '<br>') : 'Wpisz treść wiadomości...'}</div>';
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

          // 🎨 HANDLE BOTH QUILL AND HTML EDITOR CONTENT
          if (_useHtmlEditor) {
            // For HTML editor, use the content directly
            _currentPreviewHtml = _contentController.text.isNotEmpty
                ? _contentController.text
                : '<p style="font-family: Arial, sans-serif; color: #666; font-style: italic;">Wpisz treść wiadomości...</p>';
          } else {
            // For fallback case, use content controller directly
            _currentPreviewHtml = _contentController.text.isNotEmpty
                ? _contentController.text
                : '<p>Wpisz treść wiadomości...</p>';
          }

          // 📧 DODAJ SZCZEGÓŁY INWESTYCJI JEŚLI WŁĄCZONE (asynchronicznie)
          if (_includeInvestmentDetails) {
            _currentPreviewHtml +=
                '<div style="margin-top: 20px; padding: 15px; background: #f5f5f5; border-radius: 8px; color: #666; font-style: italic;">⏳ Ładowanie szczegółów inwestycji...</div>';

            // Asynchroniczne ładowanie szczegółów inwestycji dla preview
            _generateInvestmentDetailsHtml(type: RecipientType.preview)
                .then((investmentDetailsHtml) {
                  if (mounted) {
                    setState(() {
                      // Zamień placeholder na rzeczywiste dane
                      _currentPreviewHtml = _currentPreviewHtml.replaceAll(
                        '<div style="margin-top: 20px; padding: 15px; background: #f5f5f5; border-radius: 8px; color: #666; font-style: italic;">⏳ Ładowanie szczegółów inwestycji...</div>',
                        investmentDetailsHtml,
                      );
                    });
                  }
                })
                .catchError((e) {
                  if (mounted) {
                    setState(() {
                      _currentPreviewHtml = _currentPreviewHtml.replaceAll(
                        '<div style="margin-top: 20px; padding: 15px; background: #f5f5f5; border-radius: 8px; color: #666; font-style: italic;">⏳ Ładowanie szczegółów inwestycji...</div>',
                        '<div style="margin-top: 20px; padding: 15px; background: #f8d7da; border-radius: 8px; color: #721c24;">❌ Błąd ładowania danych inwestycji</div>',
                      );
                    });
                  }
                });
          }

        } catch (e) {
          String fallbackText;
          if (_useHtmlEditor) {
            fallbackText = _contentController.text;
          } else {
            fallbackText =
                _contentController.text; // Always use HTML content now
          }
          _currentPreviewHtml =
              '<div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">${fallbackText.isNotEmpty ? fallbackText.replaceAll('\n', '<br>') : 'Wpisz treść wiadomości...'}</div>';
        }
      });
    }
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

  // 🎯 ZOPTYMALIZOWANA IMPLEMENTACJA - Jedna funkcja z cache dla wszystkich typów odbiorców

  Map<String, String> _investmentDetailsCache = {};
  Map<String, List<Investment>> _clientInvestmentsCache =
      {}; // 🚀 Smart cache dla inwestycji klientów

  // 🗑️ Czyszczenie cache (np. przy zmianie danych)
  void _clearInvestmentDetailsCache() {
    _investmentDetailsCache.clear();
    _clientInvestmentsCache.clear();
  }
  
  Future<String> _generateInvestmentDetailsHtml({
    RecipientType type = RecipientType.main,
    List<InvestorSummary>? specificInvestors,
  }) async {
    // 🚀 CACHE KEY - unikalne dla każdego typu odbiorców
    final cacheKey =
        '${type.name}_${specificInvestors?.length ?? widget.selectedInvestors.length}';

    // 📋 Sprawdź cache
    if (_investmentDetailsCache.containsKey(cacheKey)) {
      return _investmentDetailsCache[cacheKey]!;
    }

    // 🎯 UJEDNOLICONA LOGIKA dla wszystkich typów odbiorców
    final investorsToProcess = specificInvestors ?? widget.selectedInvestors;

    if (investorsToProcess.isEmpty) {
      return '<div style="padding: 20px; text-align: center; color: #666; font-style: italic;">Nie wybrano żadnych inwestorów.</div>';
    }

    // 🎯 UPROSZCZONA LOGIKA - Firebase Function już obsługuje filtrowanie
    // Firebase już wie które dane wysłać do którego typu odbiorcy
    List<InvestorSummary> enabledInvestors = List.from(investorsToProcess);

    // 📋 Walidacja - sprawdź czy mamy inwestorów do przetworzenia
    if (enabledInvestors.isEmpty) {
      final emptyMessage =
          '<div style="padding: 20px; text-align: center; color: #666; font-style: italic;">Nie wybrano żadnych inwestorów do analizy.</div>';
      _investmentDetailsCache[cacheKey] = emptyMessage;
      return emptyMessage;
    }
    final buffer = StringBuffer();

    // 🎨 NAGŁÓWKI z wykorzystaniem metody enum
    final (headerTitle, headerDescription) = type.getHeaders(_isGroupEmail);

    buffer.write('''
      <div style="margin: 20px 0; padding: 20px; background: linear-gradient(135deg, #f8f9fa, #e9ecef); border-radius: 12px; border-left: 4px solid #d4af37;">
        <h3 style="margin: 0 0 16px 0; color: #2c2c2c; font-size: 18px; font-weight: 600;">
          $headerTitle
        </h3>
        <p style="margin: 0; color: #666; font-size: 14px;">
          $headerDescription
        </p>
      </div>
    ''');

    // Statystyki globalne
    int totalInvestments = 0;

    try {
      // 🎯 UPROSZCZONA LOGIKA - Firebase obsługuje personalizację
      final finalInvestorsToProcess = enabledInvestors;

      // Pobierz inwestycje dla każdego inwestora
      for (int index = 0; index < finalInvestorsToProcess.length; index++) {
        final investor = finalInvestorsToProcess[index];
        final clientId = investor.client.id;
        final clientName = investor.client.name;

        // Pobierz inwestycje klienta z Firebase
        final investments = await _getInvestmentsByClientId(clientId);
        
        if (investments.isNotEmpty) {
          // Oblicz podsumowania dla klienta
          double clientInvestmentAmount = 0;
          double clientRemainingCapital = 0;
          double clientRealizedCapital = 0;
          double clientCapitalSecuredByRealEstate = 0;
          double clientCapitalForRestructuring = 0;

          final investmentRows = <String>[];

          for (final investment in investments) {
            final investmentAmount = investment.investmentAmount;
            final remainingCapital = investment.remainingCapital;
            final realizedCapital = investment.realizedCapital;
            final capitalSecuredByRealEstate =
                investment.capitalSecuredByRealEstate;
            final capitalForRestructuring = investment.capitalForRestructuring;

            clientInvestmentAmount += investmentAmount;
            clientRemainingCapital += remainingCapital;
            clientRealizedCapital += realizedCapital;
            clientCapitalSecuredByRealEstate += capitalSecuredByRealEstate;
            clientCapitalForRestructuring += capitalForRestructuring;

            // Wiersz inwestycji
            investmentRows.add('''
              <tr style="border-bottom: 1px solid #e9ecef;">
                <td style="padding: 12px 8px; vertical-align: top;">
                  <div style="font-weight: 500; color: #2c2c2c; margin-bottom: 4px;">${investment.productName}</div>
                  <div style="font-size: 12px; color: #666;">${investment.productType.displayName}</div>
                </td>
                <td style="padding: 12px 8px; text-align: right; color: #2c2c2c; font-weight: 500;">${CurrencyFormatter.formatCurrencyForEmail(investmentAmount)}</td>
                <td style="padding: 12px 8px; text-align: right; color: #28a745; font-weight: 500;">${CurrencyFormatter.formatCurrencyForEmail(remainingCapital)}</td>
                <td style="padding: 12px 8px; text-align: right; color: #007bff; font-weight: 500;">${CurrencyFormatter.formatCurrencyForEmail(realizedCapital)}</td>
                <td style="padding: 12px 8px; text-align: right; color: #ff6b35; font-weight: 500;">${CurrencyFormatter.formatCurrencyForEmail(capitalSecuredByRealEstate)}</td>
                <td style="padding: 12px 8px; text-align: right; color: #ffa500; font-weight: 500;">${CurrencyFormatter.formatCurrencyForEmail(capitalForRestructuring)}</td>
                <td style="padding: 12px 8px; text-align: center;">
                  <span style="padding: 4px 8px; border-radius: 12px; font-size: 12px; font-weight: 500; 
                               background: ${investment.status.toString() == 'InvestmentStatus.active' ? '#d4edda' : '#f8d7da'}; 
                               color: ${investment.status.toString() == 'InvestmentStatus.active' ? '#155724' : '#721c24'};">
                    ${investment.status == InvestmentStatus.active ? 'Aktywna' : 'Nieaktywna'}
                  </span>
                </td>
              </tr>
            ''');
          }

          // Dodaj do globalnych statystyk
          totalInvestments += investments.length;

          // Sekcja dla klienta
          buffer.write('''
            <div style="margin: 24px 0; border: 1px solid #e9ecef; border-radius: 8px; overflow: hidden;">
              <div style="background: #2c2c2c; color: #d4af37; padding: 16px;">
                <h4 style="margin: 0; font-size: 16px; font-weight: 600;">👤 $clientName</h4>
                <div style="margin-top: 8px; display: flex; gap: 24px; font-size: 14px;">
                  <span>📊 Inwestycje: ${investments.length}</span>
                  <span>💰 Kapitał pozostały: ${CurrencyFormatter.formatCurrencyForEmail(clientRemainingCapital)}</span>
                </div>
              </div>
              
              <div style="overflow-x: auto;">
                <table style="width: 100%; border-collapse: collapse; font-size: 14px;">
                  <thead>
                    <tr style="background: #f8f9fa; color: #495057;">
                      <th style="padding: 12px 8px; text-align: left; font-weight: 600;">Produkt</th>
                      <th style="padding: 12px 8px; text-align: right; font-weight: 600;">Kwota Inwestycji</th>
                      <th style="padding: 12px 8px; text-align: right; font-weight: 600;">Kapitał Pozostały</th>
                      <th style="padding: 12px 8px; text-align: right; font-weight: 600;">Kapitał Zrealizowany</th>
                      <th style="padding: 12px 8px; text-align: right; font-weight: 600;">Kapitał Zabezpieczony</th>
                      <th style="padding: 12px 8px; text-align: right; font-weight: 600;">Kapitał do Restrukturyzacji</th>
                      <th style="padding: 12px 8px; text-align: center; font-weight: 600;">Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    ${investmentRows.join('')}
                    <tr style="background: #e8f5e8; font-weight: 600; border-top: 2px solid #28a745;">
                      <td style="padding: 12px 8px;">📈 PODSUMOWANIE</td>
                      <td style="padding: 12px 8px; text-align: right; color: #2c2c2c;">${CurrencyFormatter.formatCurrencyForEmail(clientInvestmentAmount)}</td>
                      <td style="padding: 12px 8px; text-align: right; color: #28a745;">${CurrencyFormatter.formatCurrencyForEmail(clientRemainingCapital)}</td>
                      <td style="padding: 12px 8px; text-align: right; color: #007bff;">${CurrencyFormatter.formatCurrencyForEmail(clientRealizedCapital)}</td>
                      <td style="padding: 12px 8px; text-align: right; color: #ff6b35;">${CurrencyFormatter.formatCurrencyForEmail(clientCapitalSecuredByRealEstate)}</td>
                      <td style="padding: 12px 8px; text-align: right; color: #ffa500;">${CurrencyFormatter.formatCurrencyForEmail(clientCapitalForRestructuring)}</td>
                      <td style="padding: 12px 8px; text-align: center; color: #28a745;">${investments.length} inwestycji</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          ''');
        } else {
          // Brak inwestycji dla klienta
          buffer.write('''
            <div style="margin: 16px 0; padding: 16px; border: 1px solid #ffc107; border-radius: 8px; background: #fff3cd;">
              <div style="color: #856404; font-weight: 500;">⚠️ $clientName</div>
              <div style="color: #856404; font-size: 14px; margin-top: 4px;">Brak inwestycji w systemie</div>
            </div>
          ''');
        }
      }

      // Szczegółowa lista wszystkich inwestycji
      if (totalInvestments > 0) {
        // Zbierz wszystkie inwestycje z wszystkich klientów
        final allInvestments = <Map<String, dynamic>>[];

        for (int index = 0; index < finalInvestorsToProcess.length; index++) {
          final investor = finalInvestorsToProcess[index];
          final clientId = investor.client.id;
          final clientName = investor.client.name;

          try {
            final investments = await _getInvestmentsByClientId(clientId);
            for (final investment in investments) {
              allInvestments.add({
                'clientName': clientName,
                'investment': investment,
              });
            }
          } catch (e) {
            // Error handled silently - continue with other clients
          }
        }

        if (allInvestments.isNotEmpty) {
          final detailsTitle = switch (type) {
            RecipientType.additional =>
              '📋 SZCZEGÓŁOWA LISTA WSZYSTKICH INWESTYCJI',
            RecipientType.preview =>
              '📋 SZCZEGÓŁOWA LISTA WSZYSTKICH INWESTYCJI',
            RecipientType.main =>
              _isGroupEmail
                  ? 'SZCZEGÓŁOWA LISTA INWESTYCJI'
                  : 'SZCZEGÓŁOWA LISTA TWOICH INWESTYCJI',
          };

          buffer.write('''
            <div style="margin: 24px 0; padding: 20px; background: linear-gradient(135deg, #f8f9fa, #e9ecef); border-radius: 12px; border-left: 4px solid #007bff;">
              <h3 style="margin: 0 0 20px 0; color: #2c2c2c; font-size: 18px; font-weight: 600; text-align: center;">
                $detailsTitle
              </h3>
              <div style="overflow-x: auto;">
                <table style="width: 100%; border-collapse: collapse; font-size: 14px; background: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                  <thead>
                    <tr style="background: linear-gradient(135deg, #2c2c2c, #1a1a1a); color: #d4af37;">
                      <th style="padding: 16px 12px; text-align: left; font-weight: 600; border-bottom: 2px solid #d4af37;">Klient</th>
                      <th style="padding: 16px 12px; text-align: left; font-weight: 600; border-bottom: 2px solid #d4af37;">Produkt</th>
                      <th style="padding: 16px 12px; text-align: right; font-weight: 600; border-bottom: 2px solid #d4af37;">Kwota Inwestycji</th>
                      <th style="padding: 16px 12px; text-align: right; font-weight: 600; border-bottom: 2px solid #d4af37;">Kapitał Pozostały</th>
                      <th style="padding: 16px 12px; text-align: right; font-weight: 600; border-bottom: 2px solid #d4af37;">Kapitał Zrealizowany</th>
                      <th style="padding: 16px 12px; text-align: right; font-weight: 600; border-bottom: 2px solid #d4af37;">Kapitał Zabezpieczony</th>
                      <th style="padding: 16px 12px; text-align: right; font-weight: 600; border-bottom: 2px solid #d4af37;">Kapitał do Restrukturyzacji</th>
                      <th style="padding: 16px 12px; text-align: center; font-weight: 600; border-bottom: 2px solid #d4af37;">Status</th>
                    </tr>
                  </thead>
                  <tbody>
          ''');

          // Dodaj każdą inwestycję jako osobny wiersz
          for (int i = 0; i < allInvestments.length; i++) {
            final item = allInvestments[i];
            final clientName = item['clientName'] as String;
            final investment = item['investment'] as Investment;

            final rowStyle = i % 2 == 0
                ? 'background: #ffffff;'
                : 'background: #f8f9fa;';

            final statusColor = investment.status == InvestmentStatus.active
                ? '#28a745'
                : '#dc3545';
            final statusBg = investment.status == InvestmentStatus.active
                ? '#d4edda'
                : '#f8d7da';
            final statusText = investment.status == InvestmentStatus.active
                ? 'Aktywna'
                : 'Nieaktywna';

            buffer.write('''
              <tr style="$rowStyle border-bottom: 1px solid #e9ecef;">
                <td style="padding: 14px 12px; vertical-align: top;">
                  <div style="font-weight: 500; color: #2c2c2c;">$clientName</div>
                </td>
                <td style="padding: 14px 12px; vertical-align: top;">
                  <div style="font-weight: 500; color: #2c2c2c; margin-bottom: 4px;">${investment.productName}</div>
                  <div style="font-size: 12px; color: #666;">${investment.productType.displayName}</div>
                </td>
                <td style="padding: 14px 12px; text-align: right; color: #2c2c2c; font-weight: 500;">
                  ${CurrencyFormatter.formatCurrencyForEmail(investment.investmentAmount)}
                </td>
                <td style="padding: 14px 12px; text-align: right; color: #28a745; font-weight: 500;">
                  ${CurrencyFormatter.formatCurrencyForEmail(investment.remainingCapital)}
                </td>
                <td style="padding: 14px 12px; text-align: right; color: #007bff; font-weight: 500;">
                  ${CurrencyFormatter.formatCurrencyForEmail(investment.realizedCapital)}
                </td>
                <td style="padding: 14px 12px; text-align: right; color: #ff6b35; font-weight: 500;">
                  ${CurrencyFormatter.formatCurrencyForEmail(investment.capitalSecuredByRealEstate)}
                </td>
                <td style="padding: 14px 12px; text-align: right; color: #ffa500; font-weight: 500;">
                  ${CurrencyFormatter.formatCurrencyForEmail(investment.capitalForRestructuring)}
                </td>
                <td style="padding: 14px 12px; text-align: center;">
                  <span style="padding: 6px 12px; border-radius: 20px; font-size: 12px; font-weight: 500; background: $statusBg; color: $statusColor;">
                    $statusText
                  </span>
                </td>
              </tr>
            ''');
          }

          buffer.write('''
                  </tbody>
                </table>
              </div>
            </div>
          ''');
        }
      }

      // Szczegółowe podsumowanie inwestycji klienta
      if (totalInvestments > 0) {
        // Pokaż inwestycje pogrupowane według klientów
        for (int index = 0; index < finalInvestorsToProcess.length; index++) {
          final investor = finalInvestorsToProcess[index];
          final clientId = investor.client.id;
          final clientName = investor.client.name;

          try {
            final investments = await _getInvestmentsByClientId(clientId);

            if (investments.isNotEmpty) {
              // Nagłówek klienta - bardziej kompaktowy
              buffer.write('''
                <div style="margin-bottom: 20px; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(212, 175, 55, 0.2);">
                  <div style="background: linear-gradient(135deg, #2c2c2c 0%, #1a1a1a 100%); padding: 12px 16px; border-bottom: 2px solid #d4af37;">
                    <h4 style="margin: 0; color: #d4af37; font-size: 15px; font-weight: 600; display: flex; align-items: center;">
                      👤 $clientName <span style="margin-left: 12px; font-size: 12px; color: #ffffff; opacity: 0.8;">(${investments.length} inwestycji)</span>
                    </h4>
                  </div>
              ''');

              // Lista inwestycji klienta - kompaktowa lista
              buffer.write('''
                <div style="background: #ffffff;">
              ''');

              for (int i = 0; i < investments.length; i++) {
                final investment = investments[i];
                final statusColor = investment.status == InvestmentStatus.active
                    ? '#28a745'
                    : '#dc3545';
                final statusBg = investment.status == InvestmentStatus.active
                    ? '#e8f5e8'
                    : '#fdeaea';
                final statusText = investment.status == InvestmentStatus.active
                    ? 'Aktywna'
                    : 'Nieaktywna';
                final bgColor = i % 2 == 0 ? '#ffffff' : '#f8f9fa';

                buffer.write('''
                  <div style="display: flex; align-items: center; padding: 10px 16px; background: $bgColor; border-bottom: 1px solid #e9ecef;">
                    <!-- Nazwa produktu i status -->
                    <div style="flex: 1; min-width: 200px;">
                      <div style="font-weight: 600; color: #2c2c2c; font-size: 14px; margin-bottom: 4px;">${investment.productName}</div>
                      <span style="font-size: 12px; color: #666; opacity: 0.8;">${investment.productType.displayName}</span>
                      <span style="padding: 2px 8px; border-radius: 10px; font-size: 10px; font-weight: 500; background: $statusBg; color: $statusColor;">
                        $statusText
                      </span>
                    </div>
                    
                    <!-- Kwoty w jednej linii poziomej -->
                    <div style="display: flex; gap: 20px; align-items: center; flex-wrap: wrap;">
                      <div style="display: flex; align-items: center; gap: 6px;">
                        <span style="font-size: 10px; color: #666; opacity: 0.8;">Kwota Inwestycji:</span>
                        <span style="font-size: 13px; font-weight: 600; color: #2c2c2c;">${CurrencyFormatter.formatCurrencyForEmail(investment.investmentAmount)}</span>
                      </div>
                      <div style="display: flex; align-items: center; gap: 6px;">
                        <span style="font-size: 10px; color: #666; opacity: 0.8;">Kapitał Pozostały:</span>
                        <span style="font-size: 13px; font-weight: 600; color: #28a745;">${CurrencyFormatter.formatCurrencyForEmail(investment.remainingCapital)}</span>
                      </div>
                      <div style="display: flex; align-items: center; gap: 6px;">
                        <span style="font-size: 10px; color: #666; opacity: 0.8;">Kapitał Zrealizowany:</span>
                        <span style="font-size: 13px; font-weight: 600; color: #007bff;">${CurrencyFormatter.formatCurrencyForEmail(investment.realizedCapital)}</span>
                      </div>
                      <div style="display: flex; align-items: center; gap: 6px;">
                        <span style="font-size: 10px; color: #666; opacity: 0.8;">Kapitał Zabezpieczony:</span>
                        <span style="font-size: 13px; font-weight: 600; color: #ff6b35;">${CurrencyFormatter.formatCurrencyForEmail(investment.capitalSecuredByRealEstate)}</span>
                      </div>
                      <div style="display: flex; align-items: center; gap: 6px;">
                        <span style="font-size: 10px; color: #666; opacity: 0.8;">Kapitał do Restrukturyzacji:</span>
                        <span style="font-size: 13px; font-weight: 600; color: #ffa500;">${CurrencyFormatter.formatCurrencyForEmail(investment.capitalForRestructuring)}</span>
                      </div>
                    </div>
                  </div>
                ''');
              }

              buffer.write('''
                </div>
              </div>
              '''); // Zamknij sekcję klienta
            }
          } catch (e) {
            // Error handled silently - continue with other clients
          }
        }
      }


    } catch (e) {
      return '''<div style="padding: 20px; text-align: center; color: #dc3545; border: 1px solid #dc3545; border-radius: 8px; background: #f8d7da;">
                 ⚠️ Wystąpił błąd podczas pobierania danych inwestycji: $e
               </div>''';
    }

    final result = buffer.toString();

    // 🚀 CACHE RESULT for future use
    _investmentDetailsCache[cacheKey] = result;

    if (result.length < 100) {
    } else {
    }
    
    return result;
  }

  // 📊 HELPER METHOD - Pobiera inwestycje klienta z Firebase z cache'owaniem
  Future<List<Investment>> _getInvestmentsByClientId(String clientId) async {
    // 🚀 SPRAWDŹ CACHE NAJPIERW
    if (_clientInvestmentsCache.containsKey(clientId)) {
      return _clientInvestmentsCache[clientId]!;
    }
    
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('investments')
          .where('clientId', isEqualTo: clientId)
          .get();

      final investments = querySnapshot.docs
          .map((doc) => Investment.fromFirestore(doc))
          .toList();
          
      // 🚀 ZAPISZ W CACHE
      _clientInvestmentsCache[clientId] = investments;

      for (final investment in investments) {
      }

      return investments;
    } catch (e) {
      return [];
    }
  }

  // 📊 NOWA FUNKCJA - Generuje dane inwestycji dla pojedynczego klienta (nie wszystkich)
  Future<String> _generateInvestmentDetailsForClient(
    String clientId,
    String clientName,
  ) async {
    // 🚀 CACHE KEY dla pojedynczego klienta
    final cacheKey = 'client_${clientId}_investment_details';

    // 📋 Sprawdź cache
    if (_investmentDetailsCache.containsKey(cacheKey)) {
      return _investmentDetailsCache[cacheKey]!;
    }

    try {
      // Pobierz inwestycje tylko dla tego klienta
      final investments = await _getInvestmentsByClientId(clientId);

      if (investments.isEmpty) {
        final emptyMessage =
            '''
          <div style="margin: 20px 0; padding: 16px; border: 1px solid #ffc107; border-radius: 8px; background: #fff3cd;">
            <div style="color: #856404; font-weight: 500;">⚠️ $clientName</div>
            <div style="color: #856404; font-size: 14px; margin-top: 4px;">Brak inwestycji w systemie</div>
          </div>
        ''';
        _investmentDetailsCache[cacheKey] = emptyMessage;
        return emptyMessage;
      }

      // Oblicz podsumowania dla klienta
      double clientInvestmentAmount = 0;
      double clientRemainingCapital = 0;
      double clientRealizedCapital = 0;
      double clientCapitalSecuredByRealEstate = 0;
      double clientCapitalForRestructuring = 0;

      final investmentRows = <String>[];

      for (final investment in investments) {
        final investmentAmount = investment.investmentAmount;
        final remainingCapital = investment.remainingCapital;
        final realizedCapital = investment.realizedCapital;
        final capitalSecuredByRealEstate =
            investment.capitalSecuredByRealEstate;
        final capitalForRestructuring = investment.capitalForRestructuring;

        clientInvestmentAmount += investmentAmount;
        clientRemainingCapital += remainingCapital;
        clientRealizedCapital += realizedCapital;
        clientCapitalSecuredByRealEstate += capitalSecuredByRealEstate;
        clientCapitalForRestructuring += capitalForRestructuring;

        // Wiersz inwestycji
        investmentRows.add('''
          <tr style="border-bottom: 1px solid #e9ecef;">
            <td style="padding: 12px 8px; vertical-align: top;">
              <div style="font-weight: 500; color: #2c2c2c; margin-bottom: 4px;">${investment.productName}</div>
              <div style="font-size: 12px; color: #666;">${investment.productType.displayName}</div>
            </td>
            <td style="padding: 12px 8px; text-align: right; color: #2c2c2c; font-weight: 500;">${CurrencyFormatter.formatCurrencyForEmail(investmentAmount)}</td>
            <td style="padding: 12px 8px; text-align: right; color: #28a745; font-weight: 500;">${CurrencyFormatter.formatCurrencyForEmail(remainingCapital)}</td>
            <td style="padding: 12px 8px; text-align: right; color: #007bff; font-weight: 500;">${CurrencyFormatter.formatCurrencyForEmail(realizedCapital)}</td>
            <td style="padding: 12px 8px; text-align: right; color: #ff6b35; font-weight: 500;">${CurrencyFormatter.formatCurrencyForEmail(capitalSecuredByRealEstate)}</td>
            <td style="padding: 12px 8px; text-align: right; color: #ffa500; font-weight: 500;">${CurrencyFormatter.formatCurrencyForEmail(capitalForRestructuring)}</td>
            <td style="padding: 12px 8px; text-align: center;">
              <span style="padding: 4px 8px; border-radius: 12px; font-size: 12px; font-weight: 500; 
                           background: ${investment.status.toString() == 'InvestmentStatus.active' ? '#d4edda' : '#f8d7da'}; 
                           color: ${investment.status.toString() == 'InvestmentStatus.active' ? '#155724' : '#721c24'};">
                ${investment.status == InvestmentStatus.active ? 'Aktywna' : 'Nieaktywna'}
              </span>
            </td>
          </tr>
        ''');
      }

      // Generuj HTML dla pojedynczego klienta
      final result =
          '''
        <div style="margin: 20px 0; padding: 20px; background: linear-gradient(135deg, #f8f9fa, #e9ecef); border-radius: 12px; border-left: 4px solid #d4af37;">
          <h3 style="margin: 0 0 16px 0; color: #2c2c2c; font-size: 18px; font-weight: 600;">
            📊 Podsumowanie Portfela
          </h3>
          <p style="margin: 0; color: #666; font-size: 14px;">
            Personalizowane zestawienie inwestycji dla: $clientName
          </p>
        </div>
        
        <div style="margin: 24px 0; border: 1px solid #e9ecef; border-radius: 8px; overflow: hidden;">
          <div style="background: #2c2c2c; color: #d4af37; padding: 16px;">
            <h4 style="margin: 0; font-size: 16px; font-weight: 600;">👤 $clientName</h4>
            <div style="margin-top: 8px; display: flex; gap: 24px; font-size: 14px;">
              <span>📊 Inwestycje: ${investments.length}</span>
              <span>💰 Kapitał pozostały: ${CurrencyFormatter.formatCurrencyForEmail(clientRemainingCapital)}</span>
            </div>
          </div>
          
          <div style="overflow-x: auto;">
            <table style="width: 100%; border-collapse: collapse; font-size: 14px;">
              <thead>
                <tr style="background: #f8f9fa; color: #495057;">
                  <th style="padding: 12px 8px; text-align: left; font-weight: 600;">Produkt</th>
                  <th style="padding: 12px 8px; text-align: right; font-weight: 600;">Kwota Inwestycji</th>
                  <th style="padding: 12px 8px; text-align: right; font-weight: 600;">Kapitał Pozostały</th>
                  <th style="padding: 12px 8px; text-align: right; font-weight: 600;">Kapitał Zrealizowany</th>
                  <th style="padding: 12px 8px; text-align: right; font-weight: 600;">Kapitał Zabezpieczony</th>
                  <th style="padding: 12px 8px; text-align: right; font-weight: 600;">Kapitał do Restrukturyzacji</th>
                  <th style="padding: 12px 8px; text-align: center; font-weight: 600;">Status</th>
                </tr>
              </thead>
              <tbody>
                ${investmentRows.join('')}
                <tr style="background: #e8f5e8; font-weight: 600; border-top: 2px solid #28a745;">
                  <td style="padding: 12px 8px;">📈 PODSUMOWANIE</td>
                  <td style="padding: 12px 8px; text-align: right; color: #2c2c2c;">${CurrencyFormatter.formatCurrencyForEmail(clientInvestmentAmount)}</td>
                  <td style="padding: 12px 8px; text-align: right; color: #28a745;">${CurrencyFormatter.formatCurrencyForEmail(clientRemainingCapital)}</td>
                  <td style="padding: 12px 8px; text-align: right; color: #007bff;">${CurrencyFormatter.formatCurrencyForEmail(clientRealizedCapital)}</td>
                  <td style="padding: 12px 8px; text-align: right; color: #ff6b35;">${CurrencyFormatter.formatCurrencyForEmail(clientCapitalSecuredByRealEstate)}</td>
                  <td style="padding: 12px 8px; text-align: right; color: #ffa500;">${CurrencyFormatter.formatCurrencyForEmail(clientCapitalForRestructuring)}</td>
                  <td style="padding: 12px 8px; text-align: center; color: #28a745;">${investments.length} inwestycji</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      ''';

      // 🚀 CACHE RESULT for future use
      _investmentDetailsCache[cacheKey] = result;

      return result;
    } catch (e) {
      final errorMessage =
          '''
        <div style="margin: 20px 0; padding: 16px; border: 1px solid #dc3545; border-radius: 8px; background: #f8d7da;">
          <div style="color: #721c24; font-weight: 500;">❌ $clientName</div>
          <div style="color: #721c24; font-size: 14px; margin-top: 4px;">Błąd podczas pobierania danych inwestycji</div>
        </div>
      ''';

      _investmentDetailsCache[cacheKey] = errorMessage;
      return errorMessage;
    }
  }



  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatTimeOnly(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
              _contentController.clear(); // Clear HTML content instead
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

  // 📅 SCHEDULING FUNCTIONS
  void _onSchedulingDateTimeChanged(DateTime? dateTime) {
    setState(() {
      _scheduledDateTime = dateTime;
      _isSchedulingEnabled = dateTime != null;
      _schedulingError = null;
    });
  }

  String _formatScheduledDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      return 'dzisiaj o ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'jutro o ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      final weekday = _getWeekdayName(dateTime.weekday);
      return '$weekday o ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} o ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'poniedziałek',
      'wtorek',
      'środę',
      'czwartek',
      'piątek',
      'sobotę',
      'niedzielę',
    ];
    return weekdays[weekday - 1];
  }

  Future<void> _sendEmails() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _error = 'Proszę wypełnić wszystkie wymagane pola.';
      });
      return;
    }

    // Validate scheduling if enabled
    if (_isSchedulingEnabled) {
      if (_scheduledDateTime == null) {
        setState(() {
          _schedulingError = 'Wybierz datę i godzinę wysyłki.';
        });
        return;
      }

      if (_scheduledDateTime!.isBefore(DateTime.now())) {
        setState(() {
          _schedulingError = 'Data wysyłki nie może być w przeszłości.';
        });
        return;
      }
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
      _loadingMessage = _isSchedulingEnabled
          ? 'Planowanie wysyłki...'
          : 'Przygotowywanie wiadomości...';
    });

    if (allEmails.isEmpty) {
      setState(() {
        _error =
            'Brak odbiorców z prawidłowymi adresami email. Sprawdź czy odbiorcy mają prawidłowe adresy email i są zaznaczeni.';
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

      // 🎨 GET EMAIL HTML FROM APPROPRIATE EDITOR
      String emailHtml;
      if (_useHtmlEditor) {
        // For HTML editor, use content directly
        emailHtml = _contentController.text.isNotEmpty
            ? _contentController.text
            : '<p>Treść wiadomości jest pusta.</p>';
      } else {
        // Fallback case - use HTML content as well
        emailHtml = _contentController.text.isNotEmpty
            ? _contentController.text
            : '<p>Treść wiadomości jest pusta.</p>';
      }

      // 📊 NOWE PODEJŚCIE - Generujemy mapę danych per klient dla indywidualnych emaili
      String finalHtml = emailHtml;
      String? aggregatedInvestmentsForAdditionals;
      Map<String, String>? investmentDetailsByClient;

      if (_includeInvestmentDetails) {
        setState(() {
          _loadingMessage = 'Pobieranie szczegółów inwestycji...';
          _loadingProgress = 0.15;
        });

        // 🔥 KLUCZOWA POPRAWKA: Generuj dane PER KLIENT dla indywidualnych emaili
        if (!_isGroupEmail) {
          investmentDetailsByClient = <String, String>{};

          // Generuj dane dla każdego włączonego inwestora osobno
          for (final investor in enabledInvestors) {
            final individualHtml = await _generateInvestmentDetailsForClient(
              investor.client.id,
              investor.client.name,
            );

            investmentDetailsByClient[investor.client.id] = individualHtml;
          }

        } else {
          // Tryb grupowy - użyj istniejącej logiki
          final investmentDetailsHtml = await _generateInvestmentDetailsHtml(
            type: RecipientType.main,
          );
          finalHtml = emailHtml + investmentDetailsHtml;
        }
      }

      // 🔥 WAŻNE: Zawsze generuj dane dla dodatkowych odbiorców, niezależnie od _includeInvestmentDetails
      // 📧 DODATKOWI ODBIORCY otrzymują ZAWSZE wszystkie inwestycje WSZYSTKICH pierwotnie wybranych inwestorów
      // 📧 niezależnie od tego czy główni odbiorcy są zaznaczeni w checkboxach czy nie
      if (_additionalEmails.isNotEmpty) {
        setState(() {
          _loadingMessage =
              'Przygotowywanie danych dla dodatkowych odbiorców...';
          _loadingProgress = 0.18;
        });

        // 🔥 KLUCZOWA LOGIKA: Dodatkowi odbiorcy ZAWSZE dostają inwestycje WSZYSTKICH pierwotnie wybranych
        // 📋 WAŻNE: Obejmuje to również inwestycje klientów ODZNACZONYCH w checkboxach!
        // 🎯 Logika: Odznaczeni klienci = NIE dostają maili, ALE ich inwestycje = SĄ w zestawieniu dla dodatkowych
        final allInvestorsHtml = await _generateInvestmentDetailsHtml(
          type: RecipientType.additional,
          specificInvestors: widget
              .selectedInvestors, // ← WSZYSTKICH pierwotnie wybranych (również odznaczonych!)
        );
        aggregatedInvestmentsForAdditionals = allInvestorsHtml;
        
        if (allInvestorsHtml.isEmpty) {
        } else {
        }
      }

      // 🎨 ENHANCED LOGGING FOR EMAIL HTML

      // Handle scheduled vs immediate sending
      if (_isSchedulingEnabled && _scheduledDateTime != null) {
        // Additional validation for scheduling
        if (enabledInvestors.isEmpty && _additionalEmails.isEmpty) {
          setState(() {
            _error =
                'Nie można zaplanować emaila bez odbiorców. Sprawdź czy odbiorcy mają prawidłowe adresy email i są zaznaczeni.';
            _isLoading = false;
            _schedulingError = 'Brak odbiorców do zaplanowania';
          });
          return;
        }

        // Dodatkowa walidacja przed planowaniem
        final invalidEmails = <String>[];
        final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
        
        for (final investor in enabledInvestors) {
          if (!emailRegex.hasMatch(investor.client.email)) {
            invalidEmails.add('${investor.client.name}: ${investor.client.email}');
          }
        }
        
        for (final email in _additionalEmails) {
          if (!emailRegex.hasMatch(email)) {
            invalidEmails.add('Dodatkowy: $email');
          }
        }
        
        if (invalidEmails.isNotEmpty) {
          setState(() {
            _error = 'Nieprawidłowe adresy email:\n${invalidEmails.join('\n')}';
            _isLoading = false;
            _schedulingError = 'Napraw adresy email przed planowaniem';
          });
          return;
        }

        // Log scheduling details for debugging
        for (final investor in enabledInvestors) {
        }
        for (final email in _additionalEmails) {
        }

        // Schedule email for later
        setState(() {
          _loadingMessage = 'Planowanie wysyłki emaila...';
          _loadingProgress = 0.5;
        });

        final scheduledEmailId = await _emailSchedulingService.scheduleEmail(
          recipients: enabledInvestors,
          subject: _subjectController.text,
          htmlContent: finalHtml,
          scheduledDateTime: _scheduledDateTime!,
          senderEmail: _senderEmailController.text,
          senderName: _senderNameController.text,
          includeInvestmentDetails: _includeInvestmentDetails,
          additionalRecipients: Map.fromIterable(
            _additionalEmails,
            key: (email) => email,
            value: (email) => email,
          ),
          notes: 'Zaplanowane z edytora emaili',
          createdBy: 'current_user', // TODO: Get actual user ID
        );

        setState(() {
          _loadingMessage = 'Email zaplanowany pomyślnie';
          _loadingProgress = 1.0;
          _isLoading = false;
        });

        // Clear draft after scheduling
        await _preferencesService.clearEmailDraft();
        setState(() {
          _hasUnsavedChanges = false;
          _lastAutoSaveTime = null;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Email zaplanowany na ${_formatScheduledDateTime(_scheduledDateTime!)}',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }

        // Return to previous screen
        if (mounted) {
          Navigator.of(context).pop(true);
        }
        return;
      }

      // Step 2: Connecting to email service (immediate sending)
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
        isGroupEmail: _isGroupEmail,
        investmentDetailsByClient: investmentDetailsByClient,
        senderEmail: _senderEmailController.text,
        senderName: _senderNameController.text,
        aggregatedInvestmentsForAdditionals:
            aggregatedInvestmentsForAdditionals,
        attachments: _attachments,
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
        _loadingMessage =
            'Wysłano $successfulEmails z ${results.length} wiadomości';
        _results = results;
        _isLoading = false;
      });

      // 🔊 Play success sound if emails were sent successfully
      if (successfulEmails > 0) {
        await _playSuccessSound();

        // 💾 Clear draft after successful sending
        await _preferencesService.clearEmailDraft();
        setState(() {
          _hasUnsavedChanges = false;
          _lastAutoSaveTime = null;
        });
      }

      // Powrót do poprzedniego ekranu z wynikiem
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _error =
            'Błąd podczas ${_isSchedulingEnabled ? 'planowania' : 'wysyłania'}: $e';
        _isLoading = false;
        _loadingMessage =
            'Błąd ${_isSchedulingEnabled ? 'planowania' : 'wysyłania'}';
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

      // Convert HTML content to plain text for backup
      final plainTextContent = _contentController.text
          .replaceAll(RegExp(r'<[^>]*>'), '') // Strip HTML tags
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .trim();

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
      } else {
      }
    } catch (e) {
      // Don't throw error - this is not critical for email sending
    }
  }

  // 🔊 PLAY SUCCESS SOUND FOR EMAIL SENDING
  // 🔊 PLAY SUCCESS SOUND FOR EMAIL SENDING
  Future<void> _playSuccessSound() async {
    try {

      // Use AudioService to play custom email_sound.mp3
      await AudioService.instance.playEmailSentSound();

    } catch (e) {

      // Fallback to system sound if AudioService fails
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (fallbackError) {
      }
    }
  }

  int _getEnabledRecipientsCount() {
    return _recipientEnabled.values.where((enabled) => enabled).length;
  }

  int _getTotalRecipientsCount() {
    return _getEnabledRecipientsCount() + _additionalEmails.length;
  }

  /// Sprawdza czy są dostępni odbiorcy do wysłania
  bool _hasValidRecipients() {
    final enabledRecipients = _getEnabledRecipientsCount();
    final additionalEmails = _additionalEmails.length;
    return enabledRecipients > 0 || additionalEmails > 0;
  }

  /// Sprawdza czy można zaplanować email (ma odbiorców i ustawienia)
  bool _canScheduleEmail() {
    if (!_hasValidRecipients()) return false;
    if (_isSchedulingEnabled && _scheduledDateTime == null) return false;
    if (_isSchedulingEnabled && _scheduledDateTime!.isBefore(DateTime.now()))
      return false;
    return true;
  }

  /// Pobierz komunikat o stanie odbiorców
  String _getRecipientsStatusMessage() {
    final enabledRecipients = _getEnabledRecipientsCount();
    final additionalEmails = _additionalEmails.length;
    final totalSelected = widget.selectedInvestors.length;

    if (enabledRecipients == 0 && additionalEmails == 0) {
      return 'Brak odbiorców - dodaj odbiorców lub sprawdź adresy email';
    } else if (enabledRecipients < totalSelected) {
      final disabled = totalSelected - enabledRecipients;
      final total = enabledRecipients + additionalEmails;
      if (additionalEmails > 0) {
        return '$enabledRecipients odbiorców z checkboxów + $additionalEmails dodatkowych = $total łącznie ($disabled wyłączonych checkboxów)';
      } else {
        return '$enabledRecipients odbiorców gotowych ($disabled wyłączonych z powodu błędnych adresów email)';
      }
    } else {
      final total = enabledRecipients + additionalEmails;
      if (additionalEmails > 0) {
        return '$enabledRecipients odbiorców z checkboxów + $additionalEmails dodatkowych = $total łącznie';
      } else {
        return '$total odbiorców gotowych do wysłania';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundSecondary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edytor Email',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Preview toggle button
          IconButton(
            icon: Icon(
              _isPreviewVisible ? Icons.visibility_off : Icons.visibility,
              color: AppTheme.textSecondary,
            ),
            tooltip: _isPreviewVisible ? 'Ukryj podgląd' : 'Pokaż podgląd',
            onPressed: _togglePreviewVisibility,
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
                          AppTheme.backgroundPrimary,
                          AppTheme.backgroundSecondary.withValues(alpha: 0.8),
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

                            // Loading Banner - HIDDEN: Loading is now shown in actions area
                            // if (_isLoading) _buildWowLoadingBanner(),

                            // Email Settings
                            _buildWowEmailSettings(isMobile, isTablet),

                            SizedBox(height: isMobile ? 16 : 24),

                            // Recipients List
                            _buildRecipientsList(isMobile),

                            SizedBox(height: isMobile ? 16 : 24),

                            // Editor
                            _buildWowEditor(isMobile, isTablet),

                            SizedBox(height: isMobile ? 16 : 24),

                            // Attachments Section
                            _buildAttachmentsSection(isMobile, isTablet),

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
            AppTheme.secondaryGold.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border(
          top: BorderSide(
            color: AppTheme.secondaryGold.withOpacity(0.3),
            width: 2,
          ),
          left: BorderSide(
            color: AppTheme.secondaryGold.withOpacity(0.3),
            width: 2,
          ),
          right: BorderSide(
            color: AppTheme.secondaryGold.withOpacity(0.3),
            width: 2,
          ),
          bottom: BorderSide(
            color: AppTheme.secondaryGold.withOpacity(0.3),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryGold.withOpacity(0.1),
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
                colors: [AppTheme.secondaryGold, AppTheme.primaryColor],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.email_outlined,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edytor Email',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Wyślij spersonalizowane wiadomości do inwestorów',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
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
              color: AppTheme.secondaryGold,
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
          color: _getAutoSaveIndicatorColor().withOpacity(0.1),
          border: Border.all(
            color: _getAutoSaveIndicatorColor().withOpacity(0.3),
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
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.secondaryGold,
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
                    color: _getAutoSaveIndicatorColor().withOpacity(0.7),
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

          SizedBox(height: isMobile ? 16 : 24),

          // Email Scheduling
          EmailSchedulingWidget(
            initialDateTime: _scheduledDateTime,
            onDateTimeChanged: _onSchedulingDateTimeChanged,
            isEnabled: !_isLoading,
            errorText: _schedulingError,
          ),
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
                AppTheme.backgroundSecondary.withOpacity(0.9),
                AppTheme.backgroundPrimary.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.borderPrimary.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
            ? Icon(icon, color: AppTheme.secondaryGold)
            : null,
        filled: true,
        fillColor: AppTheme.backgroundSecondary.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.borderPrimary.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.secondaryGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.errorPrimary, width: 2),
        ),
        labelStyle: TextStyle(color: AppTheme.textSecondary),
        hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7)),
      ),
      style: TextStyle(color: AppTheme.textPrimary),
    );
  }

  // ⚙️ OPCJE EMAIL Z WOW SWITCHAMI
  Widget _buildEmailOptions(bool isMobile) {
    if (isMobile) {
      // Mobile layout: Stack switches vertically
      return Column(
        children: [
          _buildWowSwitch(
            title: 'Szczegóły inwestycji',
            subtitle: 'Dołącz informacje o inwestycjach',
            value: _includeInvestmentDetails,
            onChanged: (value) {
              setState(() => _includeInvestmentDetails = value);
              _forcePreviewUpdate(); // Immediately update preview when toggling investment details
            },
            icon: Icons.attach_money_outlined,
          ),
          SizedBox(height: 12),
          _buildWowSwitch(
            title: 'Email grupowy',
            subtitle: 'Wyślij do wszystkich odbiorców',
            value: _isGroupEmail,
            onChanged: (value) {
              setState(() => _isGroupEmail = value);
              _forcePreviewUpdate(); // Update preview when toggling group email
            },
            icon: Icons.group_outlined,
          ),
        ],
      );
    } else {
      // Desktop layout: Keep switches side by side
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
          SizedBox(width: 16),
          Expanded(
            child: _buildWowSwitch(
              title: 'Email grupowy',
              subtitle: 'Wyślij do wszystkich odbiorców',
              value: _isGroupEmail,
              onChanged: (value) {
                setState(() => _isGroupEmail = value);
                _forcePreviewUpdate(); // Update preview when toggling group email
              },
              icon: Icons.group_outlined,
            ),
          ),
        ],
      );
    }
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
            AppTheme.backgroundSecondary.withOpacity(0.5),
            AppTheme.backgroundPrimary.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (value ? AppTheme.secondaryGold : AppTheme.borderPrimary)
              .withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? AppTheme.secondaryGold.withOpacity(0.1)
                  : AppTheme.borderPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? AppTheme.secondaryGold : AppTheme.textSecondary,
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
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.secondaryGold,
            activeTrackColor: AppTheme.secondaryGold.withOpacity(0.3),
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
              AppTheme.errorPrimary.withOpacity(0.1),
              AppTheme.errorPrimary.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.errorPrimary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_outlined,
                  color: AppTheme.errorPrimary,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Brak odbiorców email. Dodaj inwestorów lub dodatkowe adresy email.',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
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
                  colors: [AppTheme.secondaryGold, AppTheme.primaryColor],
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
                  color: AppTheme.primaryColor,
                ),
                label: Text(
                  'Dodaj odbiorców',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
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
                AppTheme.successPrimary.withOpacity(0.1),
                AppTheme.successPrimary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.successPrimary.withOpacity(0.3)),
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
                      color: AppTheme.successPrimary,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Odbiorcy (${_getTotalRecipientsCount()})',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
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
                        color: AppTheme.secondaryGold,
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
                                  color: AppTheme.secondaryGold,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Dodatkowi odbiorcy',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
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
                                    foregroundColor: AppTheme.secondaryGold,
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
                                      fillColor: AppTheme.backgroundSecondary
                                          .withOpacity(0.3),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: AppTheme.borderPrimary
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: AppTheme.borderPrimary
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: AppTheme.secondaryGold,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                    ),
                                    onSubmitted: (_) => _addAdditionalEmail(),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.secondaryGold,
                                        AppTheme.primaryColor,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    onPressed: _addAdditionalEmail,
                                    icon: Icon(
                                      Icons.add,
                                      color: AppTheme.primaryColor,
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
                                      AppTheme.backgroundSecondary.withOpacity(
                                        0.5,
                                      ),
                                      AppTheme.backgroundPrimary.withValues(
                                        alpha: 0.3,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.borderPrimary.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dodani odbiorcy:',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
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
                                              color: AppTheme.textPrimary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          backgroundColor: AppTheme
                                              .secondaryGold
                                              .withOpacity(0.1),
                                          deleteIcon: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: AppTheme.errorPrimary,
                                          ),
                                          onDeleted: () =>
                                              _removeAdditionalEmail(email),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            side: BorderSide(
                                              color: AppTheme.secondaryGold
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // 🎯 INFORMACJA O DODATKOWYCH ODBIORCACH
                              SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryGold.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.secondaryGold.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: AppTheme.secondaryGold,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Dodatkowi odbiorcy otrzymają informacje o WSZYSTKICH wybranych inwestorach, niezależnie od ustawień checkboxów poniżej',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
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
                                  color: AppTheme.textSecondary,
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
                                          AppTheme.backgroundSecondary
                                              .withOpacity(0.3),
                                          AppTheme.backgroundPrimary
                                              .withOpacity(0.2),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isEnabled
                                            ? AppTheme.successPrimary
                                                  .withOpacity(0.3)
                                            : AppTheme.errorPrimary.withOpacity(
                                                0.3,
                                              ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: isEnabled
                                                ? AppTheme.successPrimary
                                                : AppTheme.errorPrimary,
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
                                                      ? AppTheme.textPrimary
                                                      : AppTheme.textSecondary
                                                            .withOpacity(0.6),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                client.email,
                                                style: TextStyle(
                                                  color: isEnabled
                                                      ? AppTheme.textSecondary
                                                      : AppTheme.textSecondary
                                                            .withOpacity(0.5),
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
                                          activeColor: AppTheme.secondaryGold,
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
                  AppTheme.backgroundSecondary.withOpacity(0.8),
                  AppTheme.backgroundPrimary.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.secondaryGold.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryGold.withOpacity(0.1),
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
                    // Editor Header with Toggle
                    Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.secondaryGold.withOpacity(0.1),
                            AppTheme.primaryColor.withOpacity(0.1),
                          ],
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: AppTheme.borderPrimary.withValues(
                              alpha: 0.3,
                            ),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _useHtmlEditor ? Icons.code : Icons.edit_outlined,
                            color: AppTheme.secondaryGold,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _useHtmlEditor
                                      ? 'Edytor '
                                      : 'Classic Editor (Quill)',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (!isMobile)
                                  Text(
                                    'Profesjonalny edytor HTML',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              _isEditorExpanded
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
                              color: AppTheme.secondaryGold,
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
                          ? (isMobile ? 600 : (isTablet ? 750 : 900))
                          : (isMobile ? 400 : (isTablet ? 500 : 600)),
                      padding: EdgeInsets.all(isMobile ? 8 : 12),
                      child: _buildHtmlEditor(
                        isMobile,
                        isTablet,
                      ), // Always use HTML editor
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

  // 📝 Metoda budująca HTML Editor
  Widget _buildHtmlEditor(bool isMobile, bool isTablet) {
    return HtmlEditorWidget(
      height: isMobile ? 500 : (isTablet ? 650 : 800), // Znacznie zwiększona wysokość w zależności od urządzenia
      showPreview: false, // Preview handled separately in main screen
      enabled: true,
      onContentChanged: (content) {
        _contentController.text = content;
        _updatePreviewContent();
      },
      onReady: () {
        if (kDebugMode) {
        }
      },
      onFileAttached: (EmailAttachment attachment) {
        setState(() {
          _attachments.add(attachment);
          _markUnsavedChanges();
        });
        
        // Pokaż powiadomienie o dodaniu załącznika
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.attach_file, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Dodano załącznik: ${attachment.fileName}'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      onFocusChanged: (focused) {
        if (kDebugMode) {
        }
      },
      onError: (error) {
        if (kDebugMode) {
        }
      },
      initialContent: _contentController.text.isNotEmpty
          ? _contentController.text
          : '<p>Napisz swoją wiadomość...</p>',
    );
  } // 📝 Metoda budująca Quill Editor (fallback)

  // REMOVED: _buildQuillEditor function completely removed since we only use HTML editor

  // � Metoda przełączania edytorów
  // REMOVED: _switchEditor function no longer needed since we only use HTML editor

  // 👁️ LIVE PREVIEW PANEL Z DARK/LIGHT TOGGLE
  Widget _buildLivePreviewPanel(bool isMobile, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundSecondary.withOpacity(0.9),
            AppTheme.backgroundPrimary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.secondaryGold.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryGold.withOpacity(0.1),
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
                      AppTheme.secondaryGold.withOpacity(0.1),
                      AppTheme.primaryColor.withOpacity(0.1),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.borderPrimary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      color: AppTheme.secondaryGold,
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
                              color: AppTheme.textPrimary,
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
                              color: AppTheme.successPrimary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppTheme.successPrimary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.text_format,
                                  size: 14,
                                  color: AppTheme.successPrimary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Podstawowe formatowanie',
                                  style: TextStyle(
                                    color: AppTheme.successPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                          color: AppTheme.textSecondary,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundSecondary.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(_previewZoomLevel * 100).round()}%',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.zoom_in, size: 20),
                          onPressed: _zoomInPreview,
                          tooltip: 'Powiększ',
                          color: AppTheme.textSecondary,
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh, size: 20),
                          onPressed: _resetPreviewZoom,
                          tooltip: 'Resetuj zoom',
                          color: AppTheme.textSecondary,
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
                      child: Builder(
                        builder: (context) {
                          if (_currentPreviewHtml.isEmpty) {
                            return Text(
                              'Brak treści do podglądu',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          }

                          return html_package.Html(
                            data: _currentPreviewHtml,
                            style: {
                              'body': html_package.Style(
                                color: _isPreviewDarkTheme
                                    ? Colors.white
                                    : Colors.black,
                                lineHeight: html_package.LineHeight.number(1.6),
                                fontSize: html_package.FontSize(16),
                                fontFamily: 'Arial, sans-serif',
                              ),
                              // 🎨 ENHANCED SPANS WITH FULL FONT AND COLOR SUPPORT
                              'span': html_package.Style(
                                // Let inline styles override - no default overrides
                              ),
                              // 🎨 FONT ELEMENTS - Support for different font families
                              'font': html_package.Style(
                                // Let inline font attributes take precedence
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
                                // Remove default color to allow inline styles to take precedence
                                margin: html_package.Margins.only(bottom: 16),
                                lineHeight: html_package.LineHeight.number(1.6),
                                // Remove default fontFamily to allow inheritance
                              ),
                              'div': html_package.Style(
                                // Remove default color to allow inline styles to take precedence
                                lineHeight: html_package.LineHeight.number(1.6),
                                // Remove default fontFamily to allow inheritance
                              ),

                              // ✏️ TEXT FORMATTING - Enhanced support
                              'strong': html_package.Style(
                                fontWeight: FontWeight.bold,
                              ),
                              'b': html_package.Style(
                                fontWeight: FontWeight.bold,
                              ),
                              'em': html_package.Style(
                                fontStyle: FontStyle.italic,
                              ),
                              'i': html_package.Style(
                                fontStyle: FontStyle.italic,
                              ),
                              'u': html_package.Style(
                                textDecoration: TextDecoration.underline,
                              ),
                              'ins': html_package.Style(
                                textDecoration: TextDecoration.underline,
                              ),
                              's': html_package.Style(
                                textDecoration: TextDecoration.lineThrough,
                              ),
                              'del': html_package.Style(
                                textDecoration: TextDecoration.lineThrough,
                              ),
                              'strike': html_package.Style(
                                textDecoration: TextDecoration.lineThrough,
                              ),
                              // 🎨 Support for combined decorations (underline + strikethrough)
                              'u s': html_package.Style(
                                textDecoration: TextDecoration.combine([
                                  TextDecoration.underline,
                                  TextDecoration.lineThrough,
                                ]),
                              ),
                              's u': html_package.Style(
                                textDecoration: TextDecoration.combine([
                                  TextDecoration.underline,
                                  TextDecoration.lineThrough,
                                ]),
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
                                padding: html_package.HtmlPaddings.only(
                                  left: 20,
                                ),
                              ),
                              'ol': html_package.Style(
                                color: _isPreviewDarkTheme
                                    ? Colors.white
                                    : Colors.black,
                                margin: html_package.Margins.only(
                                  left: 20,
                                  bottom: 16,
                                ),
                                padding: html_package.HtmlPaddings.only(
                                  left: 20,
                                ),
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
                              // Handle link taps if needed
                            },
                          );
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
            AppTheme.backgroundSecondary.withOpacity(0.8),
            AppTheme.backgroundPrimary.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondaryGold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.electric_bolt,
                color: AppTheme.secondaryGold,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Szybkie akcje',
                style: TextStyle(
                  color: AppTheme.textPrimary,
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
                icon: Icons.save_outlined,
                label: 'Zapisz szkic',
                color: _hasUnsavedChanges
                    ? AppTheme.secondaryAmber
                    : AppTheme.successPrimary,
                onPressed: _saveManually,
              ),
              _buildWowActionButton(
                icon: Icons.visibility_outlined,
                label: 'Podgląd',
                color: AppTheme.secondaryGold,
                onPressed: _togglePreviewVisibility,
              ),
              _buildWowActionButton(
                icon: Icons.clear,
                label: 'Wyczyść edytor',
                color: AppTheme.errorPrimary,
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
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
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
            AppTheme.errorPrimary.withOpacity(0.1),
            AppTheme.errorPrimary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorPrimary),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorPrimary.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.errorPrimary, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20),
            onPressed: () => setState(() => _error = null),
            color: AppTheme.textSecondary,
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
            AppTheme.successPrimary.withOpacity(0.1),
            AppTheme.successPrimary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successPrimary),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successPrimary.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppTheme.successPrimary,
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
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Liczba wysłanych wiadomości: ${_results!.length}',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ⏳ WOW LOADING BANNER
  // REMOVED: _buildWowLoadingBanner function no longer needed

  // 🎬 WOW AKCJE DOLNE
  Widget _buildWowActions(bool canEdit, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundSecondary.withOpacity(0.9),
            AppTheme.backgroundPrimary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondaryGold.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryGold.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: _isLoading
          ? _buildLoadingContentForActions()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipients status message
                if (!_hasValidRecipients() ||
                    (_isSchedulingEnabled && _schedulingError != null))
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            !_hasValidRecipients()
                                ? _getRecipientsStatusMessage()
                                : _schedulingError ?? 'Błąd planowania',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close),
                        label: Text('Anuluj'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: BorderSide(color: AppTheme.borderPrimary),
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            canEdit && _hasValidRecipients() && !_isLoading
                            ? _sendEmails
                            : null,
                        icon: Icon(
                          _isSchedulingEnabled ? Icons.schedule : Icons.send,
                        ),
                        label: Text(
                          _isSchedulingEnabled
                              ? 'Zaplanuj wysyłkę'
                              : 'Wyślij wiadomości',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              canEdit && _hasValidRecipients() && !_isLoading
                              ? AppTheme.secondaryGold
                              : Colors.grey,
                          foregroundColor:
                              canEdit && _hasValidRecipients() && !_isLoading
                              ? AppTheme.primaryColor
                              : Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  // 🔄 LOADING CONTENT FOR ACTIONS AREA
  Widget _buildLoadingContentForActions() {
    return Column(
      children: [
        // Header row with spinning indicator
        Row(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: _loadingProgress > 0 ? _loadingProgress : null,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.secondaryGold,
                ),
                backgroundColor: AppTheme.secondaryGold.withOpacity(0.2),
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
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _loadingMessage,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
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
                  backgroundColor: AppTheme.backgroundSecondary,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.secondaryGold,
                  ),
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
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_totalEmailsToSend > 0)
                    Text(
                      '$_emailsSent / $_totalEmailsToSend emaili',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
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
    );
  }

  /// 📧 TEMPLATE SECTION
  Widget _buildTemplateSection(bool isMobile, bool isTablet) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isTemplatesSectionCollapsed ? 60 : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundSecondary.withValues(alpha: 0.9),
              AppTheme.backgroundPrimary.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.borderPrimary.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            InkWell(
              onTap: () {
                setState(() {
                  _isTemplatesSectionCollapsed = !_isTemplatesSectionCollapsed;
                });
                HapticFeedback.selectionClick();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: AppTheme.secondaryGold,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Szablony Email',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_selectedTemplate != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedTemplate!.name,
                          style: TextStyle(
                            color: AppTheme.secondaryGold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      _isTemplatesSectionCollapsed
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            // Content
            if (!_isTemplatesSectionCollapsed)
              Container(
                height: 400,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: EmailTemplateSelector(
                  onTemplateSelected: _onTemplateSelected,
                  showCategoryFilter: true,
                  selectedTemplateId: _selectedTemplate?.id,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 📧 TEMPLATE SELECTION HANDLER
  void _onTemplateSelected(EmailTemplateModel template) {
    setState(() {
      _selectedTemplate = template;
    });
    
    // Apply template to editor
    if (widget.selectedInvestors.isNotEmpty) {
      final investor = widget.selectedInvestors.first;
      final personalizedContent = template.renderForInvestor(investor);
      
      // Set subject
      _subjectController.text = template.subject;
      
      // Set content
      _contentController.text = personalizedContent;
      
      // Update preview
      _updatePreviewContent();
    } else {
      // Use template without personalization
      _subjectController.text = template.subject;
      _contentController.text = template.content;
      _updatePreviewContent();
    }
    
    // Mark as having changes
    _markUnsavedChanges();
    
    HapticFeedback.mediumImpact();
  }

  /// 📎 ATTACHMENTS CHANGED HANDLER
  void _onAttachmentsChanged(List<EmailAttachment> attachments) {
    setState(() {
      _attachments = List.from(attachments);
    });
    
    _markUnsavedChanges();
  }

  /// 📎 GET TOTAL ATTACHMENT SIZE
  String _getTotalAttachmentSize() {
    final totalBytes = _attachments.fold<int>(0, (total, attachment) => total + attachment.size);
    if (totalBytes < 1024) {
      return '$totalBytes B';
    } else if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// 📎 ATTACHMENTS SECTION
  Widget _buildAttachmentsSection(bool isMobile, bool isTablet) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isAttachmentsSectionCollapsed ? 60 : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundSecondary.withOpacity(0.9),
              AppTheme.backgroundPrimary.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.borderPrimary.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            InkWell(
              onTap: () {
                setState(() {
                  _isAttachmentsSectionCollapsed = !_isAttachmentsSectionCollapsed;
                });
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.attach_file,
                        color: AppTheme.secondaryGold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Załączniki',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _attachments.isEmpty
                                ? 'Brak załączników'
                                : '${_attachments.length} załączników (${_getTotalAttachmentSize()})',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_attachments.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_attachments.length}',
                          style: TextStyle(
                            color: AppTheme.secondaryGold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      _isAttachmentsSectionCollapsed
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            // Content
            if (!_isAttachmentsSectionCollapsed)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildAttachmentsList(isMobile),
              ),
          ],
        ),
      ),
    );
  }

  /// 📎 ATTACHMENTS LIST WIDGET
  Widget _buildAttachmentsList(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add attachment button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickAttachment,
            icon: Icon(Icons.add, color: AppTheme.secondaryGold),
            label: Text(
              'Dodaj załącznik',
              style: TextStyle(color: AppTheme.secondaryGold),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.secondaryGold),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 16),
          // Attachments list
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.borderPrimary.withOpacity(0.2),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _attachments.length,
              separatorBuilder: (context, index) => Divider(
                color: AppTheme.borderPrimary.withOpacity(0.2),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final attachment = _attachments[index];
                return _buildAttachmentItem(attachment, index);
              },
            ),
          ),
          
          const SizedBox(height: 8),
          // Total size info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Całkowity rozmiar: ${_getTotalAttachmentSize()}',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (_getTotalAttachmentSizeBytes() > 25 * 1024 * 1024)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Przekroczono 25MB',
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 📎 ATTACHMENT ITEM WIDGET
  Widget _buildAttachmentItem(EmailAttachment attachment, int index) {
    final sizeStr = _formatFileSize(attachment.size);
    final isTooBig = attachment.size > 25 * 1024 * 1024; // 25MB limit
    
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // File icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _getFileTypeColor(attachment.fileName).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getFileTypeIcon(attachment.fileName),
              size: 16,
              color: _getFileTypeColor(attachment.fileName),
            ),
          ),
          const SizedBox(width: 12),
          
          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      sizeStr,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (isTooBig) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'Za duży',
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _editAttachment(index),
                icon: Icon(
                  Icons.edit,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                tooltip: 'Edytuj nazwę',
              ),
              IconButton(
                onPressed: () => _removeAttachment(index),
                icon: Icon(
                  Icons.delete,
                  size: 16,
                  color: AppTheme.errorColor,
                ),
                tooltip: 'Usuń załącznik',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📎 GET TOTAL ATTACHMENT SIZE IN BYTES
  int _getTotalAttachmentSizeBytes() {
    return _attachments.fold<int>(0, (total, attachment) => total + attachment.size);
  }

  /// 📎 FORMAT FILE SIZE
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// 📎 GET FILE TYPE ICON
  IconData _getFileTypeIcon(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      default:
        return Icons.attach_file;
    }
  }

  /// 📎 GET FILE TYPE COLOR
  Color _getFileTypeColor(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.purple;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.amber;
      default:
        return AppTheme.textSecondary;
    }
  }

  /// 📎 PICK ATTACHMENT
  Future<void> _pickAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true, // Need file data for email attachment
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Check file size (max 25MB per attachment)
        if (file.size > 25 * 1024 * 1024) {
          _showErrorDialog('Plik jest za duży', 'Maksymalny rozmiar pojedynczego załącznika to 25MB. Wybrany plik ma ${_formatFileSize(file.size)}.');
          return;
        }
        
        // Check total size (max 50MB total)
        final totalSize = _getTotalAttachmentSizeBytes() + file.size;
        if (totalSize > 50 * 1024 * 1024) {
          _showErrorDialog('Przekroczono limit', 'Całkowity rozmiar załączników nie może przekraczać 50MB. Aktualnie: ${_getTotalAttachmentSize()}, po dodaniu: ${_formatFileSize(totalSize)}.');
          return;
        }

        final attachment = EmailAttachment.simple(
          fileName: file.name,
          content: file.bytes!,
          mimeType: file.extension != null ? _getContentType(file.extension!) : 'application/octet-stream',
        );

        setState(() {
          _attachments.add(attachment);
        });

        _markUnsavedChanges();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Dodano załącznik: ${file.name}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Błąd', 'Nie udało się dodać załącznika: $e');
    }
  }

  /// 📎 REMOVE ATTACHMENT
  void _removeAttachment(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Usuń załącznik'),
        content: Text('Czy na pewno chcesz usunąć załącznik "${_attachments[index].fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _attachments.removeAt(index);
              });
              _markUnsavedChanges();
            },
            child: Text('Usuń', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  /// 📎 EDIT ATTACHMENT
  void _editAttachment(int index) {
    final attachment = _attachments[index];
    final controller = TextEditingController(text: attachment.fileName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edytuj nazwę załącznika'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Nazwa pliku',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            SizedBox(height: 8),
            Text(
              'Rozmiar: ${_formatFileSize(attachment.size)}',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != attachment.fileName) {
                setState(() {
                  _attachments[index] = attachment.copyWith(
                    name: newName,
                  );
                });
                _markUnsavedChanges();
              }
              Navigator.of(context).pop();
            },
            child: Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  /// 📎 GET CONTENT TYPE
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'zip':
        return 'application/zip';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  /// 📎 SHOW ERROR DIALOG
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: AppTheme.errorColor),
            SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 📎 MARK UNSAVED CHANGES
  void _markUnsavedChanges() {
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

}
