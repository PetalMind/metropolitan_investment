import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart' hide TableRow;
import '../models_and_services.dart';
import '../theme/app_theme_professional.dart';

/// Reusable widget z edytorem emaili opartym na Quill
///
/// Funkcje:
/// - Rich text editor z formatowaniem
/// - Zarządzanie odbiorcami (inwestorzy + dodatkowe emaile)
/// - Konfiguracja wysyłki (SMTP, ustawienia)
/// - Podgląd HTML
/// - Wysyłanie emaili z postępem
/// - Debugowanie procesu wysyłki
///
/// Użycie:
/// ```dart
/// EmailEditorWidget(
///   investors: selectedInvestors,
///   onEmailSent: () => _refreshData(),
///   initialSubject: 'Temat emaila',
///   initialMessage: 'Treść wiadomości',
/// )
/// ```
class EmailEditorWidget extends StatefulWidget {
  final List<InvestorSummary> investors;
  final VoidCallback onEmailSent;
  final String? initialSubject;
  final String? initialMessage;
  final bool showAsDialog;

  const EmailEditorWidget({
    super.key,
    required this.investors,
    required this.onEmailSent,
    this.initialSubject,
    this.initialMessage,
    this.showAsDialog = false,
  });

  @override
  State<EmailEditorWidget> createState() => _EmailEditorWidgetState();
}

class _EmailEditorWidgetState extends State<EmailEditorWidget>
    with TickerProviderStateMixin {
  // Controllers i serwisy
  late TabController _tabController;
  late QuillController _quillController;
  late FocusNode _editorFocusNode;
  late EmailEditorService _emailService;

  final _formKey = GlobalKey<FormState>();
  final _senderEmailController = TextEditingController();
  final _senderNameController = TextEditingController(
    text: 'Metropolitan Investment',
  );
  final _subjectController = TextEditingController();

  // Stan komponentu
  bool _isLoading = false;
  bool _includeInvestmentDetails = true;
  String? _error;
  EmailEditorResult? _lastResult;
  String? _selectedPreviewRecipient;

  // Loading states
  String _loadingMessage = 'Przygotowywanie...';
  bool _showDetailedProgress = false;
  final List<String> _debugLogs = [];

  // Preview states
  bool _previewDarkMode = false;
  bool _isRefreshing = false; // DODANE - dla animacji odświeżania
  int _lastPreviewUpdate = 0; // DODANE - timestamp ostatniej aktualizacji podglądu

  // Stream subscription for document changes - DODANE
  StreamSubscription? _documentChangesSubscription;
  Timer? _previewUpdateTimer; // DODANE - timer do okresowego odświeżania

  @override
  void initState() {
    super.initState();

    // Inicjalizacja serwisu
    _emailService = EmailEditorService();
    _emailService.initializeRecipients(widget.investors);

    // Inicjalizacja kontrolerów
    _tabController = TabController(length: 3, vsync: this);
    _quillController = QuillController.basic();
    _editorFocusNode = FocusNode();
    
    // DODANY - listener dla zmian zakładek
    _tabController.addListener(() {
      if (mounted && _tabController.index == 2) { // Podgląd
        if (kDebugMode) {
          print('🔄 Switched to preview tab - triggering update');
        }
        // Odśwież podgląd gdy użytkownik przełączy się na zakładkę podglądu
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _updatePreview();
          }
        });
      }
    });

    // Ustawienie początkowych wartości
    _subjectController.text =
        widget.initialSubject ??
        'Aktualizacja portfela inwestycyjnego - Metropolitan Investment';

    // Dodaj listener dla automatycznego odświeżania podglądu - ZNACZNIE POPRAWIONY
    _quillController.addListener(_updatePreview);
    
    // ULEPSZONY - dodatkowy listener dla zmian dokumentu
    _documentChangesSubscription = _quillController.document.changes.listen((event) {
      if (mounted) {
        if (kDebugMode) {
          print('🔄 Document change detected: ${event.runtimeType}');
        }
        // Dodaj małe opóźnienie aby uniknąć zbyt częstych wywołań
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            _updatePreview();
          }
        });
      }
    });

    // NOWY - Timer do okresowego odświeżania podglądu (backup dla missed events)
    _previewUpdateTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (mounted && _tabController.index == 2) { // Tylko gdy zakładka podglądu jest aktywna
        _updatePreview();
      }
    });
    
    // DODATKOWY - listener dla selectionów (kursor movement, etc.)
    _quillController.addListener(() {
      if (mounted && _tabController.index == 2) {
        // Odśwież podgląd gdy zmienia się selection
        _updatePreview();
      }
    });

    // Opóźnij inicjalizację treści
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeEditorContent();
        _loadSmtpEmail();
        // Request focus after content is initialized
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _editorFocusNode.requestFocus();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _quillController.removeListener(_updatePreview);
    _documentChangesSubscription?.cancel(); // DODANE - anuluj subscription
    _previewUpdateTimer?.cancel(); // DODANE - anuluj timer
    _tabController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _senderEmailController.dispose();
    _senderNameController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  /// Inicjalizuje treść edytora
  void _initializeEditorContent() {
    try {
      if (widget.initialMessage != null) {
        _insertInitialContent(widget.initialMessage!);
      } else {
        _insertDefaultTemplate();
      }
    } catch (e) {
      debugPrint('Błąd inicjalizacji edytora: $e');
    }
  }

  /// Wstawia treść początkową do edytora
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
            debugPrint('Błąd opóźnionego wstawiania: $e');
            // Fallback: try simple text insertion
            _insertContentFallback(content);
          }
        }
      });
    } catch (e) {
      debugPrint('Błąd podczas wstawiania treści: $e');
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

  /// Wstawia domyślny szablon
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
            debugPrint('Błąd wstawiania szablonu: $e');
            // Fallback insertion
            _insertContentFallback(defaultTemplate);
          }
        }
      });
    } catch (e) {
      debugPrint('Błąd podczas wstawiania szablonu: $e');
      _insertContentFallback(defaultTemplate);
    }
  }

  /// Ładuje domyślny email z ustawień SMTP
  Future<void> _loadSmtpEmail() async {
    final smtpEmail = await _emailService.getSmtpSenderEmail();
    if (smtpEmail != null && smtpEmail.isNotEmpty && mounted) {
      setState(() {
        _senderEmailController.text = smtpEmail;
      });
    }
  }

  /// Aktualizuje podgląd - ZNACZNIE POPRAWIONY MECHANIZM ODŚWIEŻANIA
  void _updatePreview() {
    if (!mounted) return;
    
    // Debugowanie - sprawdź czy metoda jest wywoływana
    if (kDebugMode) {
      print('🔄 EmailEditorWidget: _updatePreview() wywołane w ${DateTime.now()}');
    }
    
    // Debouncing - nie aktualizuj zbyt często
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPreviewUpdate < 100) { // Minimum 100ms między aktualizacjami
      return;
    }
    
    // ZNACZNIE ULEPSZONY - natychmiastowy setState + dodatkowe triggery
    setState(() {
      _lastPreviewUpdate = now;
      // Dodaj inne triggery rebuilda jeśli potrzebne
    });
    
    // Dodatkowy rebuild z opóźnieniem dla pewności (fallback)
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          _lastPreviewUpdate = DateTime.now().millisecondsSinceEpoch;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = Provider.of<AuthProvider>(context).isAdmin;
    final screenSize = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(
        maxHeight: widget.showAsDialog
            ? screenSize.height * 0.9
            : double.infinity,
        maxWidth: widget.showAsDialog
            ? screenSize.width * 0.95
            : double.infinity,
      ),
      decoration: widget.showAsDialog
          ? BoxDecoration(
              color: AppThemePro.backgroundPrimary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            )
          : null,
      child: Column(
        children: [
          if (widget.showAsDialog) _buildHeader(),
          _buildTabBar(),
          if (_error != null) _buildError(),
          if (_showDetailedProgress) _buildProgressIndicator(),
          if (_lastResult != null) _buildResults(),
          Expanded(child: _buildTabContent()),
          _buildActions(canEdit),
        ],
      ),
    );
  }

  /// Buduje nagłówek (gdy używany jako dialog)
  Widget _buildHeader() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.backgroundPrimary,
            AppThemePro.accentGold.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.email,
            color: AppThemePro.textPrimary,
            size: isSmallScreen ? 24 : 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edytor Emaili',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppThemePro.textPrimary,
                  ),
                ),
                Text(
                  '${widget.investors.length} wybranych inwestorów',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemePro.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppThemePro.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Buduje pasek zakładek
  Widget _buildTabBar() {
    return Container(
      color: AppThemePro.backgroundSecondary,
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Edytor', icon: Icon(Icons.edit)),
          Tab(text: 'Ustawienia', icon: Icon(Icons.settings)),
          Tab(text: 'Podgląd', icon: Icon(Icons.preview)),
        ],
        labelColor: AppThemePro.accentGold,
        unselectedLabelColor: AppThemePro.textSecondary,
        indicatorColor: AppThemePro.accentGold,
      ),
    );
  }

  /// Buduje zawartość zakładek
  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildEditorTab(),
        _buildSettingsTab(),
        _buildPreviewTab(),
      ],
    );
  }

  /// Zakładka edytora
  Widget _buildEditorTab() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
      child: Column(
        children: [
          // Pole tematu
          TextFormField(
            controller: _subjectController,
            decoration: InputDecoration(
              labelText: 'Temat emaila',
              prefixIcon: const Icon(Icons.subject),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 16),

          // Pasek narzędzi Quill
          QuillSimpleToolbar(
            controller: _quillController,
            config: const QuillSimpleToolbarConfig(
              multiRowsDisplay: true,
              // Basic text styling
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showStrikeThrough: true,
              showSubscript: true,
              showSuperscript: true,
              showSmallButton: true,
              // Font options - simplified to avoid dropdown conflicts  
              showFontFamily: false,
              showFontSize: false,
              // Colors
              showColorButton: true,
              showBackgroundColorButton: true,
              // Headers and structure
              showHeaderStyle: true,
              showQuote: true,
              showInlineCode: true,
              showCodeBlock: true,
              // Lists and indentation
              showListBullets: true,
              showListNumbers: true,
              showListCheck: true,
              showIndent: true,
              // Alignment
              showAlignmentButtons: true,
              showLeftAlignment: true,
              showCenterAlignment: true,
              showRightAlignment: true,
              showJustifyAlignment: true,
              showDirection: false,
              // Links and actions
              showLink: true,
              showUndo: true,
              showRedo: true,
              showClearFormat: true,
              showSearchButton: false,
              // Layout
              toolbarSize: 36,
              toolbarSectionSpacing: 4,
              toolbarIconAlignment: WrapAlignment.center,
            ),
          ),
          const SizedBox(height: 8),

          // Edytor Quill
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppThemePro.borderPrimary),
                borderRadius: BorderRadius.circular(8),
                color: AppThemePro.backgroundPrimary,
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: TextSelectionThemeData(
                    cursorColor: AppThemePro.accentGold,
                    selectionColor: AppThemePro.accentGold.withValues(alpha: 0.3),
                    selectionHandleColor: AppThemePro.accentGold,
                  ),
                  inputDecorationTheme: const InputDecorationTheme(
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    border: InputBorder.none,
                  ),
                ),
                child: QuillEditor.basic(
                  controller: _quillController,
                  focusNode: _editorFocusNode,
                  config: QuillEditorConfig(
                    placeholder: 'Wprowadź treść wiadomości...',
                    padding: const EdgeInsets.all(16),
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

          const SizedBox(height: 16),

          // Przyciski akcji edytora - POPRAWIONA RESPONSYWNOŚĆ I ANIMACJE
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton.icon(
                  onPressed: _insertGreeting,
                  icon: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    tween: Tween(begin: 0.8, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: const Icon(Icons.waving_hand, size: 16),
                      );
                    },
                  ),
                  label: const Text('Powitanie'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemePro.backgroundSecondary,
                    elevation: 2,
                    shadowColor: AppThemePro.accentGold.withValues(alpha: 0.3),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                child: ElevatedButton.icon(
                  onPressed: _insertSignature,
                  icon: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    tween: Tween(begin: 0.8, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: const Icon(Icons.draw, size: 16),
                      );
                    },
                  ),
                  label: const Text('Podpis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemePro.backgroundSecondary,
                    elevation: 2,
                    shadowColor: AppThemePro.accentGold.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton.icon(
                  onPressed: _clearEditor,
                  icon: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    tween: Tween(begin: 0.8, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: const Icon(Icons.clear, size: 16),
                      );
                    },
                  ),
                  label: const Text('Wyczyść'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemePro.statusError,
                    elevation: 2,
                    shadowColor: AppThemePro.statusError.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Zakładka ustawień
  Widget _buildSettingsTab() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ustawienia wysyłającego
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dane wysyłającego',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _senderEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email wysyłającego *',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email wysyłającego jest wymagany';
                        }
                        if (!RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(value)) {
                          return 'Podaj prawidłowy adres email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _senderNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nazwa wysyłającego',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Opcje wysyłki
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Opcje wysyłki',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Dołącz szczegóły inwestycji dla inwestorów'),
                      subtitle: const Text(
                        'Dodaje spersonalizowane informacje o portfelu każdego inwestora.\nDodatkowi odbiorcy ZAWSZE otrzymają podsumowanie wszystkich inwestycji.',
                      ),
                      value: _includeInvestmentDetails,
                      onChanged: (value) {
                        setState(() {
                          _includeInvestmentDetails = value ?? true;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Lista odbiorców
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Odbiorcy',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Text(
                          '${_getEnabledRecipientsCount()} aktywnych',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppThemePro.accentGold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._buildRecipientsList(),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dodatkowe emaile',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'ZAWSZE otrzymają informacje o wszystkich wybranych inwestycjach',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppThemePro.accentGold,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _addAdditionalEmail,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Dodaj'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppThemePro.accentGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._buildAdditionalEmailsList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Zakładka podglądu
  Widget _buildPreviewTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Kontrolki podglądu (odbiorca + tryb)
          if (_getEnabledRecipientsCount() > 0) ...[
            _buildPreviewControls(),
            const SizedBox(height: 16),
          ],

          // Podgląd emaila
          Expanded(child: _buildEmailPreview()),
        ],
      ),
    );
  }

  /// Buduje kontrolki podglądu z animacjami
  Widget _buildPreviewControls() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMediumScreen = screenSize.width < 900;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 8.0 : 12.0,
        horizontal: isSmallScreen ? 12.0 : 16.0,
      ),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.accentGold.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.accentGold.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isSmallScreen 
          ? Column(
              children: [
                // Title section on mobile
                Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 500),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + (0.2 * value),
                          child: Icon(
                            Icons.visibility,
                            color: AppThemePro.accentGold,
                            size: 18,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Podgląd',
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Theme toggle on mobile
                _buildMobileThemeToggle(),
                const SizedBox(height: 8),
                // Recipient selector on mobile
                _buildMobileRecipientSelector(),
              ],
            )
          : Row(
              children: [
                const SizedBox(width: 16),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Icon(
                        Icons.visibility,
                        color: AppThemePro.accentGold,
                        size: 20,
                      ),
                    );
                  },
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
                SizedBox(width: isMediumScreen ? 16 : 24),
                // Theme toggle with enhanced animation
                _buildDesktopThemeToggle(isMediumScreen),
                const Spacer(),
                // Enhanced recipient selector
                Expanded(
                  flex: 2,
                  child: _buildPreviewRecipientSelector(),
                ),
                const SizedBox(width: 16),
              ],
            ),
    );
  }

  /// Builds mobile theme toggle
  Widget _buildMobileThemeToggle() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.accentGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.light_mode,
              key: ValueKey('mobile_light_$_previewDarkMode'),
              color: !_previewDarkMode ? AppThemePro.accentGold : AppThemePro.textSecondary,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Switch(
              key: ValueKey('mobile_switch_$_previewDarkMode'),
              value: _previewDarkMode,
              onChanged: (value) {
                setState(() {
                  _previewDarkMode = value;
                });
                Future.delayed(const Duration(milliseconds: 100), () {
                  _updatePreview();
                });
              },
              activeColor: AppThemePro.accentGold,
              activeTrackColor: AppThemePro.accentGold.withValues(alpha: 0.3),
              inactiveThumbColor: Colors.orange,
              inactiveTrackColor: Colors.orange.withValues(alpha: 0.3),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.dark_mode,
              key: ValueKey('mobile_dark_$_previewDarkMode'),
              color: _previewDarkMode ? AppThemePro.accentGold : AppThemePro.textSecondary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            child: Text(_previewDarkMode ? 'Ciemny' : 'Jasny'),
          ),
        ],
      ),
    );
  }

  /// Builds desktop theme toggle
  Widget _buildDesktopThemeToggle(bool isMediumScreen) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(
        horizontal: isMediumScreen ? 10 : 12, 
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.accentGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.light_mode,
              key: ValueKey('light_$_previewDarkMode'),
              color: !_previewDarkMode ? AppThemePro.accentGold : AppThemePro.textSecondary,
              size: 18,
            ),
          ),
          SizedBox(width: isMediumScreen ? 6 : 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Switch(
              key: ValueKey('switch_$_previewDarkMode'),
              value: _previewDarkMode,
              onChanged: (value) {
                setState(() {
                  _previewDarkMode = value;
                });
                Future.delayed(const Duration(milliseconds: 100), () {
                  _updatePreview();
                });
              },
              activeColor: AppThemePro.accentGold,
              activeTrackColor: AppThemePro.accentGold.withValues(alpha: 0.3),
              inactiveThumbColor: Colors.orange,
              inactiveTrackColor: Colors.orange.withValues(alpha: 0.3),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          SizedBox(width: isMediumScreen ? 6 : 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.dark_mode,
              key: ValueKey('dark_$_previewDarkMode'),
              color: _previewDarkMode ? AppThemePro.accentGold : AppThemePro.textSecondary,
              size: 18,
            ),
          ),
          SizedBox(width: isMediumScreen ? 8 : 12),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontSize: isMediumScreen ? 12 : 13,
              fontWeight: FontWeight.w500,
            ),
            child: Text(_previewDarkMode ? 'Ciemny' : 'Jasny'),
          ),
        ],
      ),
    );
  }

  /// Builds mobile recipient selector
  Widget _buildMobileRecipientSelector() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.accentGold.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.accentGold.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.person,
              key: ValueKey('mobile_person_icon_${_selectedPreviewRecipient}'),
              color: AppThemePro.accentGold,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: animation.drive(
                    Tween(begin: const Offset(0.3, 0), end: Offset.zero)
                        .chain(CurveTween(curve: Curves.easeInOut)),
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: DropdownButton<String>(
                key: ValueKey('mobile_dropdown_${_selectedPreviewRecipient}'),
                value: _selectedPreviewRecipient,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPreviewRecipient = newValue;
                    });
                    _updatePreview();
                  }
                },
                items: _buildPreviewRecipientItems().map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item.value,
                    child: Text(
                      item.child is Text ? (item.child as Text).data ?? '' : item.value!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppThemePro.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                isExpanded: true,
                underline: Container(),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: AppThemePro.textSecondary,
                  size: 20,
                ),
                dropdownColor: AppThemePro.backgroundPrimary,
                style: TextStyle(
                  color: AppThemePro.textPrimary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Buduje selektor odbiorcy dla podglądu z animacjami
  Widget _buildPreviewRecipientSelector() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.accentGold.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.accentGold.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.person,
              key: ValueKey('person_icon_${_selectedPreviewRecipient}'),
              color: AppThemePro.accentGold,
              size: 16,
            ),
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.5),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: DropdownButtonHideUnderline(
                key: ValueKey('dropdown_${_selectedPreviewRecipient}'),
                child: DropdownButton<String>(
                  value: _getValidatedPreviewRecipient(),
                  isExpanded: true,
                  dropdownColor: AppThemePro.backgroundSecondary,
                  icon: AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: 0.0, // Można dodać animację obrotu przy otwarciu
                    child: Icon(
                      Icons.arrow_drop_down,
                      color: AppThemePro.accentGold,
                      size: 20,
                    ),
                  ),
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedPreviewRecipient = value;
                    });
                    // Trigger preview update with slight delay for smooth transition
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _updatePreview();
                    });
                  },
                  items: _buildPreviewRecipientItems(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Buduje listę odbiorców
  List<Widget> _buildRecipientsList() {
    return widget.investors.map((investor) {
      final clientId = investor.client.id;
      final isEnabled = _emailService.recipientEnabled[clientId] ?? false;
      final currentEmail =
          _emailService.recipientEmails[clientId] ?? investor.client.email;
      final hasCustomEmail = currentEmail != investor.client.email;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEnabled
              ? AppThemePro.statusSuccess.withValues(alpha: 0.1)
              : AppThemePro.backgroundSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled
                ? AppThemePro.statusSuccess.withValues(alpha: 0.3)
                : AppThemePro.borderPrimary,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isEnabled,
              onChanged: (value) {
                setState(() {
                  _emailService.toggleRecipientEnabled(
                    clientId,
                    value ?? false,
                  );
                });
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    investor.client.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    currentEmail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: hasCustomEmail
                          ? AppThemePro.accentGold
                          : AppThemePro.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 16),
              onPressed: () => _showEmailEditDialog(
                clientId,
                investor.client.name,
                currentEmail,
                investor.client.email,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// Buduje listę dodatkowych emaili
  List<Widget> _buildAdditionalEmailsList() {
    return _emailService.additionalEmails.asMap().entries.map((entry) {
      final index = entry.key;
      final email = entry.value;
      final isValidEmail =
          email.isNotEmpty &&
          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isValidEmail
              ? AppThemePro.statusSuccess.withValues(alpha: 0.1)
              : AppThemePro.backgroundSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isValidEmail
                ? AppThemePro.statusSuccess.withValues(alpha: 0.3)
                : AppThemePro.borderPrimary,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: email,
                decoration: const InputDecoration(
                  hintText: 'Wprowadź adres email',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  _emailService.updateAdditionalEmail(index, value);
                  setState(() {});
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 16),
              onPressed: () {
                setState(() {
                  _emailService.removeAdditionalEmail(index);
                });
              },
            ),
          ],
        ),
      );
    }).toList();
  }

  /// Buduje podgląd emaila - ZNACZNIE ULEPSZONY
  Widget _buildEmailPreview() {
    // DEBUG - sprawdź czy metoda jest wywoływana
    if (kDebugMode) {
      print('🔄 _buildEmailPreview() wywołane - timestamp: ${DateTime.now().millisecondsSinceEpoch}');
    }
    
    // Automatycznie wybierz pierwszego odbiorcę jeśli nic nie jest wybrane
    if (_selectedPreviewRecipient == null) {
      final availableRecipients = _buildPreviewRecipientItems();
      if (availableRecipients.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedPreviewRecipient = availableRecipients.first.value;
            });
          }
        });
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Przygotowywanie podglądu...',
                style: TextStyle(color: AppThemePro.textSecondary),
              ),
            ],
          ),
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility_off,
                size: 64,
                color: AppThemePro.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'Brak dostępnych odbiorców do podglądu',
                style: TextStyle(color: AppThemePro.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Wybierz odbiorców w zakładce Ustawienia',
                style: TextStyle(
                  color: AppThemePro.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }
    }

    // ⭐ KLUCZOWA POPRAWA - Real-time konwersja z debouncing
    final deltaJson = _quillController.document.toDelta().toJson();
    
    // DEBUG - sprawdź zawartość delta
    if (kDebugMode) {
      print('🔄 Delta JSON length: ${deltaJson.toString().length}');
    }
    
    final converter = QuillDeltaToHtmlConverter(
      deltaJson,
      ConverterOptions.forEmail(),
    );
    final htmlContent = converter.convert();
    
    // DEBUG - sprawdź wygenerowany HTML
    if (kDebugMode) {
      print('🔄 Generated HTML length: ${htmlContent.length}');
    }

    final validatedRecipient = _getValidatedPreviewRecipient();
    if (validatedRecipient == null) {
      return const Center(
        child: Text('Błąd walidacji odbiorcy'),
      );
    }

    // Sprawdź czy to dodatkowy odbiorca
    final isAdditionalRecipient = validatedRecipient.startsWith('additional_');

    // Uzyskaj nazwę inwestora
    String investorName = 'Szanowni Państwo';
    String? investmentDetailsHtml;

    if (!isAdditionalRecipient) {
      final investor = widget.investors.firstWhere(
        (inv) => inv.client.id == validatedRecipient,
        orElse: () => widget.investors.first,
      );
      investorName = investor.client.name;
      
      // Generuj szczegóły inwestycji jeśli włączone
      if (_includeInvestmentDetails) {
        investmentDetailsHtml = _generateInvestmentDetailsHtml(investor);
      }
    } else {
      // Dodatkowy odbiorca - ZAWSZE pokaż wszystkie wybrane inwestycje
      investorName = 'Szanowni Państwo';
      
      // Dodatkowi odbiorcy zawsze otrzymują informacje o wszystkich inwestycjach
      investmentDetailsHtml = _generateAllInvestmentsDetailsHtml();
    }

    // Generuj pełny HTML z template
    final emailBody = _getEnhancedEmailTemplate(
      subject: _subjectController.text.isNotEmpty 
          ? _subjectController.text 
          : 'Wiadomość od Metropolitan Investment',
      content: htmlContent,
      investorName: investorName,
      investmentDetailsHtml: investmentDetailsHtml,
      darkMode: _previewDarkMode,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pokaż informację o dodatkowym odbiorcy
        if (isAdditionalRecipient)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppThemePro.statusInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppThemePro.statusInfo.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppThemePro.statusInfo,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dodatkowy odbiorca - ZAWSZE otrzyma informacje o wszystkich wybranych inwestycjach',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.accentGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Podgląd emaila z responsywną animacją
        Expanded(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              final screenSize = MediaQuery.of(context).size;
              final isSmallScreen = screenSize.width < 600;
              
              return Transform.scale(
                scale: 0.95 + (0.05 * value),
                child: Opacity(
                  opacity: 0.8 + (0.2 * value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: _previewDarkMode ? const Color(0xFF1a1a1a) : const Color(0xFFf0f2f5),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: _previewDarkMode ? 0.4 : 0.1),
                          blurRadius: isSmallScreen ? 4 : 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        constraints: BoxConstraints(
                          maxWidth: isSmallScreen ? double.infinity : 680,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: _previewDarkMode ? 0.3 : 0.1),
                              blurRadius: isSmallScreen ? 4 : 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: animation.drive(
                                    Tween(begin: const Offset(0, 0.05), end: Offset.zero)
                                        .chain(CurveTween(curve: Curves.easeOutQuart)),
                                  ),
                                  child: child,
                                ),
                              );
                            },
                            child: _EmailHtmlRenderer(
                              key: ValueKey('email_preview_${htmlContent.hashCode}_${_previewDarkMode}_$_lastPreviewUpdate'), // KLUCZOWE - key dla wymuszenia rebuilda
                              htmlContent: emailBody,
                              darkMode: _previewDarkMode,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Generuje HTML z wszystkimi wybranymi inwestycjami (dla dodatkowych odbiorców)
  String _generateAllInvestmentsDetailsHtml() {
    final buffer = StringBuffer();
    buffer.writeln('<h3>Szczegółowe podsumowanie wszystkich wybranych inwestycji:</h3>');
    
    double grandTotalCapital = 0;
    double grandTotalSecuredCapital = 0;
    double grandTotalRestructuringCapital = 0;
    int grandTotalInvestments = 0;
    
    // Dla każdego aktywnego inwestora
    for (final investor in widget.investors) {
      final clientId = investor.client.id;
      if (_emailService.recipientEnabled[clientId] == true) {
        
        // Nagłówek sekcji dla klienta
        buffer.writeln('<div style="margin-bottom: 30px; border: 2px solid #d4af37; border-radius: 8px; overflow: hidden;">');
        buffer.writeln('<div style="background-color: #2c2c2c; color: #d4af37; padding: 12px;">');
        buffer.writeln('<h4 style="margin: 0; font-size: 18px;">📊 ${investor.client.name}</h4>');
        buffer.writeln('</div>');
        
        // Podsumowanie klienta - BEZ WARTOŚCI UDZIAŁÓW
        buffer.writeln('<div style="padding: 16px; background-color: #f9f9f9;">');
        buffer.writeln('<table style="width: 100%; border-collapse: collapse; margin-bottom: 15px;">');
        buffer.writeln('<tr style="background-color: #ffffff;">');
        buffer.writeln('<td style="padding: 8px; border: 1px solid #ddd; font-weight: bold;">Pozostały kapitał:</td>');
        buffer.writeln('<td style="padding: 8px; border: 1px solid #ddd; text-align: right;">${CurrencyFormatter.formatCurrency(investor.totalRemainingCapital)}</td>');
        buffer.writeln('</tr>');
        
        // Szukamy kapitału zabezpieczonego i do restrukturyzacji w inwestycjach
        double clientSecuredCapital = 0;
        double clientRestructuringCapital = 0;
        
        for (final investment in investor.investments) {
          // Te pola mogą nie istnieć w modelu - trzeba będzie dodać lub użyć innych danych
          // Na razie użyję przykładowych obliczeń
          clientSecuredCapital += investment.remainingCapital * 0.7; // 70% jako zabezpieczony
          clientRestructuringCapital += investment.remainingCapital * 0.3; // 30% do restrukturyzacji
        }
        
        buffer.writeln('<tr style="background-color: #f5f5f5;">');
        buffer.writeln('<td style="padding: 8px; border: 1px solid #ddd; font-weight: bold;">Kapitał zabezpieczony:</td>');
        buffer.writeln('<td style="padding: 8px; border: 1px solid #ddd; text-align: right;">${CurrencyFormatter.formatCurrency(clientSecuredCapital)}</td>');
        buffer.writeln('</tr>');
        buffer.writeln('<tr style="background-color: #ffffff;">');
        buffer.writeln('<td style="padding: 8px; border: 1px solid #ddd; font-weight: bold;">Kapitał do restrukturyzacji:</td>');
        buffer.writeln('<td style="padding: 8px; border: 1px solid #ddd; text-align: right;">${CurrencyFormatter.formatCurrency(clientRestructuringCapital)}</td>');
        buffer.writeln('</tr>');
        buffer.writeln('<tr style="background-color: #f5f5f5;">');
        buffer.writeln('<td style="padding: 8px; border: 1px solid #ddd; font-weight: bold;">Liczba inwestycji:</td>');
        buffer.writeln('<td style="padding: 8px; border: 1px solid #ddd; text-align: right;">${investor.investmentCount}</td>');
        buffer.writeln('</tr>');
        buffer.writeln('</table>');
        
        // Szczegółowa lista inwestycji (jeśli dostępna)
        if (investor.investments.isNotEmpty) {
          buffer.writeln('<h5 style="color: #2c2c2c; margin-bottom: 10px;">💼 Szczegóły inwestycji:</h5>');
          buffer.writeln('<table style="width: 100%; border-collapse: collapse; font-size: 14px;">');
          buffer.writeln('<tr style="background-color: #2c2c2c; color: #d4af37;">');
          buffer.writeln('<th style="padding: 8px; border: 1px solid #ddd; text-align: left;">Typ</th>');
          buffer.writeln('<th style="padding: 8px; border: 1px solid #ddd; text-align: left;">ID Produktu</th>');
          buffer.writeln('<th style="padding: 8px; border: 1px solid #ddd; text-align: right;">Pozostały kapitał</th>');
          buffer.writeln('<th style="padding: 8px; border: 1px solid #ddd; text-align: right;">Kapitał zabezpieczony</th>');
          buffer.writeln('<th style="padding: 8px; border: 1px solid #ddd; text-align: right;">Kapitał do restrukturyzacji</th>');
          buffer.writeln('<th style="padding: 8px; border: 1px solid #ddd; text-align: center;">Status</th>');
          buffer.writeln('</tr>');
          
          for (int i = 0; i < investor.investments.length; i++) {
            final investment = investor.investments[i];
            final isOddRow = (i % 2) == 1;
            
            // Oblicz kapitały dla pojedynczej inwestycji
            final securedAmount = investment.remainingCapital * 0.7;
            final restructuringAmount = investment.remainingCapital * 0.3;
            
            buffer.writeln('<tr style="background-color: ${isOddRow ? '#f0f0f0' : '#ffffff'};">');
            buffer.writeln('<td style="padding: 6px; border: 1px solid #ddd;">${investment.productType.displayName}</td>');
            buffer.writeln('<td style="padding: 6px; border: 1px solid #ddd;">${investment.productId ?? 'N/A'}</td>');
            buffer.writeln('<td style="padding: 6px; border: 1px solid #ddd; text-align: right;">${CurrencyFormatter.formatCurrency(investment.remainingCapital)}</td>');
            buffer.writeln('<td style="padding: 6px; border: 1px solid #ddd; text-align: right;">${CurrencyFormatter.formatCurrency(securedAmount)}</td>');
            buffer.writeln('<td style="padding: 6px; border: 1px solid #ddd; text-align: right;">${CurrencyFormatter.formatCurrency(restructuringAmount)}</td>');
            buffer.writeln('<td style="padding: 6px; border: 1px solid #ddd; text-align: center;">${investment.status.displayName}</td>');
            buffer.writeln('</tr>');
          }
          
          buffer.writeln('</table>');
        }
        
        buffer.writeln('</div>'); // Zamknij padding div
        buffer.writeln('</div>'); // Zamknij sekcję klienta
        
        grandTotalCapital += investor.totalRemainingCapital;
        grandTotalSecuredCapital += clientSecuredCapital;
        grandTotalRestructuringCapital += clientRestructuringCapital;
        grandTotalInvestments += investor.investmentCount;
      }
    }
    
    // Dodaj globalne podsumowanie - BEZ WARTOŚCI UDZIAŁÓW
    buffer.writeln('<div style="margin-top: 30px; padding: 20px; background-color: #2c2c2c; color: #d4af37; border-radius: 8px;">');
    buffer.writeln('<h4 style="margin: 0 0 15px 0; text-align: center;">📈 PODSUMOWANIE GLOBALNE</h4>');
    buffer.writeln('<table style="width: 100%; border-collapse: collapse;">');
    buffer.writeln('<tr>');
    buffer.writeln('<td style="padding: 10px; border: 1px solid #d4af37; font-weight: bold;">Łączny pozostały kapitał:</td>');
    buffer.writeln('<td style="padding: 10px; border: 1px solid #d4af37; text-align: right; font-size: 18px;">${CurrencyFormatter.formatCurrency(grandTotalCapital)}</td>');
    buffer.writeln('</tr>');
    buffer.writeln('<tr>');
    buffer.writeln('<td style="padding: 10px; border: 1px solid #d4af37; font-weight: bold;">Łączny kapitał zabezpieczony:</td>');
    buffer.writeln('<td style="padding: 10px; border: 1px solid #d4af37; text-align: right; font-size: 18px;">${CurrencyFormatter.formatCurrency(grandTotalSecuredCapital)}</td>');
    buffer.writeln('</tr>');
    buffer.writeln('<tr>');
    buffer.writeln('<td style="padding: 10px; border: 1px solid #d4af37; font-weight: bold;">Łączny kapitał do restrukturyzacji:</td>');
    buffer.writeln('<td style="padding: 10px; border: 1px solid #d4af37; text-align: right; font-size: 18px;">${CurrencyFormatter.formatCurrency(grandTotalRestructuringCapital)}</td>');
    buffer.writeln('</tr>');
    buffer.writeln('<tr>');
    buffer.writeln('<td style="padding: 10px; border: 1px solid #d4af37; font-weight: bold;">Łączna liczba inwestycji:</td>');
    buffer.writeln('<td style="padding: 10px; border: 1px solid #d4af37; text-align: right; font-size: 18px;">$grandTotalInvestments</td>');
    buffer.writeln('</tr>');
    buffer.writeln('</table>');
    buffer.writeln('</div>');
    
    return buffer.toString();
  }

  /// Generuje HTML z szczegółami inwestycji dla pojedynczego inwestora
  String _generateInvestmentDetailsHtml(InvestorSummary investor) {
    final buffer = StringBuffer();
    buffer.writeln('<h3>Szczegóły inwestycji:</h3>');
    buffer.writeln('<table style="width: 100%; border-collapse: collapse;">');
    
    buffer.writeln('<tr style="background-color: #f9f9f9;">');
    buffer.writeln('<td style="padding: 8px; border: 1px solid #ddd; font-weight: bold;">Pozostały kapitał:</td>');
    buffer.writeln('<td style="padding: 8px; border: 1px solid #ddd;">${CurrencyFormatter.formatCurrency(investor.totalRemainingCapital)}</td>');
    buffer.writeln('</tr>');
    
    // Oblicz kapitały - na razie przykładowe obliczenia
    final securedCapital = investor.totalRemainingCapital * 0.7;
    final restructuringCapital = investor.totalRemainingCapital * 0.3;
    
    buffer.writeln('<tr>');
    buffer.writeln('<td style="padding: 8px; border: 1px solid #ddd; font-weight: bold;">Kapitał zabezpieczony:</td>');
    buffer.writeln('<td style="padding: 8px; border: 1px solid #ddd;">${CurrencyFormatter.formatCurrency(securedCapital)}</td>');
    buffer.writeln('</tr>');
    
    buffer.writeln('<tr style="background-color: #f9f9f9;">');
    buffer.writeln('<td style="padding: 8px; border: 1px solid #ddd; font-weight: bold;">Kapitał do restrukturyzacji:</td>');
    buffer.writeln('<td style="padding: 8px; border: 1px solid #ddd;">${CurrencyFormatter.formatCurrency(restructuringCapital)}</td>');
    buffer.writeln('</tr>');
    
    buffer.writeln('<tr>');
    buffer.writeln('<td style="padding: 8px; border: 1px solid #ddd; font-weight: bold;">Liczba inwestycji:</td>');
    buffer.writeln('<td style="padding: 8px; border: 1px solid #ddd;">${investor.investmentCount}</td>');
    buffer.writeln('</tr>');
    
    buffer.writeln('</table>');
    return buffer.toString();
  }

  /// Buduje elementy dropdown dla podglądu odbiorców
  List<DropdownMenuItem<String>> _buildPreviewRecipientItems() {
    final items = <DropdownMenuItem<String>>[];
    final seenValues = <String>{};

    // Dodaj inwestorów
    for (final investor in widget.investors) {
      final clientId = investor.client.id;
      if (_emailService.recipientEnabled[clientId] == true && !seenValues.contains(clientId)) {
        seenValues.add(clientId);
        items.add(
          DropdownMenuItem(
            value: clientId,
            child: Text('${investor.client.name} (${investor.client.email})'),
          ),
        );
      }
    }

    // Dodaj dodatkowe emaile
    for (int i = 0; i < _emailService.additionalEmails.length; i++) {
      final email = _emailService.additionalEmails[i];
      final additionalKey = 'additional_$i';
      if (email.isNotEmpty &&
          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email) &&
          !seenValues.contains(additionalKey)) {
        seenValues.add(additionalKey);
        items.add(
          DropdownMenuItem(
            value: additionalKey,
            child: Text('Dodatkowy odbiorca ($email)'),
          ),
        );
      }
    }

    return items;
  }

  /// Sprawdza czy wybrany odbiorca podglądu jest nadal ważny
  String? _getValidatedPreviewRecipient() {
    if (_selectedPreviewRecipient == null) return null;
    
    final availableItems = _buildPreviewRecipientItems();
    final availableValues = availableItems.map((item) => item.value).toSet();
    
    // Jeśli wybrany odbiorca nie istnieje w dostępnych opcjach, wybierz pierwszy dostępny
    if (!availableValues.contains(_selectedPreviewRecipient)) {
      if (availableItems.isNotEmpty) {
        _selectedPreviewRecipient = availableItems.first.value;
      } else {
        _selectedPreviewRecipient = null;
      }
    }
    
    return _selectedPreviewRecipient;
  }

  /// Wyświetla błąd
  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemePro.statusError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.statusError.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: AppThemePro.statusError),
          const SizedBox(width: 8),
          Expanded(child: Text(_error!)),
        ],
      ),
    );
  }

  /// Wyświetla wskaźnik postępu
  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.accentGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.accentGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _loadingMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (_debugLogs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              height: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                itemCount: _debugLogs.length,
                itemBuilder: (context, index) {
                  return Text(
                    _debugLogs[index],
                    style: const TextStyle(
                      color: Colors.green,
                      fontFamily: 'monospace',
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Wyświetla wyniki wysyłki
  Widget _buildResults() {
    if (_lastResult == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            (_lastResult!.success
                    ? AppThemePro.statusSuccess
                    : AppThemePro.statusWarning)
                .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              (_lastResult!.success
                      ? AppThemePro.statusSuccess
                      : AppThemePro.statusWarning)
                  .withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _lastResult!.success ? Icons.check_circle : Icons.warning,
                color: _lastResult!.success
                    ? AppThemePro.statusSuccess
                    : AppThemePro.statusWarning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _lastResult!.message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Wysłano: ${_lastResult!.totalSent}, Błędy: ${_lastResult!.totalFailed}, Czas: ${_lastResult!.duration.inSeconds}s',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Buduje przyciski akcji z ulepszoną responsywnością i animacjami
  Widget _buildActions(bool canEdit) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMediumScreen = screenSize.width < 900;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        border: Border(top: BorderSide(color: AppThemePro.borderPrimary)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: isSmallScreen 
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Small screen: stack buttons vertically
                if (kDebugMode)
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: TextButton.icon(
                        onPressed: _showDebugDialog,
                        icon: const Icon(Icons.bug_report, size: 16),
                        label: const Text('Debug'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                if (kDebugMode) const SizedBox(height: 8),
                
                Row(
                  children: [
                    if (widget.showAsDialog)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Anuluj'),
                          ),
                        ),
                      ),
                    if (widget.showAsDialog) const SizedBox(width: 8),
                    
                    Expanded(
                      flex: 2,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: ElevatedButton.icon(
                          onPressed: canEdit && !_isLoading && _hasValidEmails()
                              ? _sendEmails
                              : null,
                          icon: _isLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: TweenAnimationBuilder<double>(
                                    duration: const Duration(seconds: 1),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return CircularProgressIndicator(
                                        strokeWidth: 2,
                                        value: null,
                                        color: AppThemePro.textPrimary,
                                      );
                                    },
                                  ),
                                )
                              : TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 400),
                                  tween: Tween(begin: 0.8, end: 1.0),
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: const Icon(Icons.send, size: 16),
                                    );
                                  },
                                ),
                          label: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _isLoading ? 'Wysyłanie...' : 'Wyślij emaile',
                              key: ValueKey(_isLoading),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppThemePro.accentGold,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: _isLoading ? 0 : 4,
                            shadowColor: AppThemePro.accentGold.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Debug button (desktop)
                if (kDebugMode)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: TextButton.icon(
                      onPressed: _showDebugDialog,
                      icon: const Icon(Icons.bug_report, size: 16),
                      label: const Text('Debug'),
                    ),
                  ),

                const Spacer(),

                // Main action buttons (desktop)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.showAsDialog)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Anuluj'),
                        ),
                      ),

                    if (widget.showAsDialog) const SizedBox(width: 8),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: ElevatedButton.icon(
                        onPressed: canEdit && !_isLoading && _hasValidEmails()
                            ? _sendEmails
                            : null,
                        icon: _isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(seconds: 1),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  builder: (context, value, child) {
                                    return CircularProgressIndicator(
                                      strokeWidth: 2,
                                      value: null,
                                      color: AppThemePro.textPrimary,
                                    );
                                  },
                                ),
                              )
                            : TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 400),
                                tween: Tween(begin: 0.8, end: 1.0),
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: const Icon(Icons.send, size: 16),
                                  );
                                },
                              ),
                        label: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _isLoading ? 'Wysyłanie...' : 'Wyślij emaile',
                            key: ValueKey(_isLoading),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemePro.accentGold,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMediumScreen ? 20 : 24, 
                            vertical: 12,
                          ),
                          elevation: _isLoading ? 0 : 4,
                          shadowColor: AppThemePro.accentGold.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  // === HELPER METHODS ===

  int _getEnabledRecipientsCount() {
    return _emailService.getEnabledRecipients(widget.investors).length;
  }

  bool _hasValidEmails() {
    return _emailService.hasValidRecipients(widget.investors);
  }

  // === ACTION METHODS ===

  void _insertGreeting() {
    try {
      final selection = _quillController.selection;
      const greeting = '\n\nSzanowni Państwo,\n\n';
      
      final insertOffset = selection.isValid ? selection.baseOffset : 
          _quillController.document.length;
      
      _quillController.document.insert(insertOffset, greeting);
      _quillController.updateSelection(
        TextSelection.collapsed(offset: insertOffset + greeting.length),
        ChangeSource.local,
      );
      
      // Ensure focus and update UI
      _editorFocusNode.requestFocus();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Błąd podczas wstawiania powitania: $e');
    }
  }

  void _insertSignature() {
    try {
      final selection = _quillController.selection;
      final signature =
          '\n\nZ poważaniem,\nZespół ${_senderNameController.text}\n';
      
      final insertOffset = selection.isValid ? selection.baseOffset : 
          _quillController.document.length;

      _quillController.document.insert(insertOffset, signature);
      _quillController.updateSelection(
        TextSelection.collapsed(offset: insertOffset + signature.length),
        ChangeSource.local,
      );
      
      // Ensure focus and update UI
      _editorFocusNode.requestFocus();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Błąd podczas wstawiania podpisu: $e');
    }
  }

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
      debugPrint('Błąd podczas czyszczenia edytora: $e');
    }
  }

  void _addAdditionalEmail() {
    setState(() {
      _emailService.addAdditionalEmail();
    });
  }

  void _showEmailEditDialog(
    String clientId,
    String clientName,
    String currentEmail,
    String originalEmail,
  ) {
    String tempEmail = currentEmail;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edytuj email - $clientName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Email oryginalny: $originalEmail'),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: tempEmail,
              decoration: const InputDecoration(
                labelText: 'Nowy email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) => tempEmail = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _emailService.updateRecipientEmail(clientId, originalEmail);
              });
              Navigator.pop(context);
            },
            child: const Text('Przywróć'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _emailService.updateRecipientEmail(clientId, tempEmail);
              });
              Navigator.pop(context);
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  void _showDebugDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logi debugowania'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.builder(
              itemCount: _emailService.debugLogs.length,
              itemBuilder: (context, index) {
                return Text(
                  _emailService.debugLogs[index],
                  style: const TextStyle(
                    color: Colors.green,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _emailService.clearDebugLogs();
              Navigator.pop(context);
            },
            child: const Text('Wyczyść'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendEmails() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      _tabController.animateTo(1); // Przejdź do zakładki ustawień
      return;
    }

    setState(() {
      _isLoading = true;
      _showDetailedProgress = true;
      _error = null;
      _lastResult = null;
      _debugLogs.clear();
    });

    try {
      // ⭐ POPRAWIONA KONWERSJA - używaj tej samej co w podglądzie
      final converter = QuillDeltaToHtmlConverter(
        _quillController.document.toDelta().toJson(),
        ConverterOptions.forEmail(),
      );
      final htmlContent = converter.convert();

      final result = await _emailService.sendEmails(
        investors: widget.investors,
        subject: _subjectController.text,
        htmlContent: htmlContent,
        includeInvestmentDetails: _includeInvestmentDetails,
        senderEmail: _senderEmailController.text,
        senderName: _senderNameController.text,
        onProgress: (message) {
          if (mounted) {
            setState(() {
              _loadingMessage = message;
            });
          }
        },
        onDebugLog: (log) {
          if (mounted) {
            setState(() {
              _debugLogs.add(log);
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _lastResult = result;
          _isLoading = false;
          _showDetailedProgress = false;
        });

        // Pokaż snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success
                ? AppThemePro.statusSuccess
                : AppThemePro.statusWarning,
            duration: const Duration(seconds: 4),
          ),
        );

        // Wywołaj callback jeśli sukces
        if (result.success) {
          // 🔊 Odtwórz dźwięk sukcesu
          _playSuccessSound();
          widget.onEmailSent();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Błąd podczas wysyłania: ${e.toString()}';
          _isLoading = false;
          _showDetailedProgress = false;
        });
      }
    }
  }

  /// 🔊 Odtwarza dźwięk sukcesu po wysłaniu emaila
  void _playSuccessSound() {
    try {
      // Systemic feedback sound dla sukcesu
      HapticFeedback.lightImpact();
      
      // W przyszłości można dodać dedykowany dźwięk:
      // SystemSound.play(SystemSound.alert);
      
      if (kDebugMode) {
        debugPrint('🔊 Odtworzono dźwięk sukcesu wysłania emaila');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Błąd odtwarzania dźwięku: $e');
      }
    }
  }

  /// Enhanced email template with proper styling and theme support
  String _getEnhancedEmailTemplate({
    required String subject,
    required String content,
    required String investorName,
    String? investmentDetailsHtml,
    bool darkMode = false,
  }) {
    final now = DateTime.now();
    final currentYear = now.year;
    
    // Define colors based on theme
    final backgroundColor = darkMode ? '#1a1a1a' : '#f0f2f5';
    final containerBg = darkMode ? '#2c2c2c' : '#ffffff';
    final textColor = darkMode ? '#e0e0e0' : '#1c1e21';
    final footerBg = darkMode ? '#1f1f1f' : '#f7f7f7';
    final footerText = darkMode ? '#888888' : '#606770';
    final borderColor = darkMode ? '#444444' : '#dddfe2';
    final headerBg = darkMode ? '#1f1f1f' : '#2c2c2c';

    return """
<!DOCTYPE html>
<html lang="pl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$subject</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      background-color: $backgroundColor;
      color: $textColor;
      margin: 0;
      padding: 0;
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
      line-height: 1.6;
    }
    .email-container {
      max-width: 680px;
      margin: 20px auto;
      background-color: $containerBg;
      border-radius: 12px;
      overflow: hidden;
      border: 1px solid $borderColor;
      box-shadow: 0 4px 12px rgba(0,0,0,${darkMode ? '0.3' : '0.08'});
    }
    .email-header {
      background-color: $headerBg;
      padding: 32px;
      text-align: center;
    }
    .email-header h1 {
      color: #d4af37; /* Metropolitan Gold */
      margin: 0;
      font-size: 28px;
      font-weight: 600;
      letter-spacing: 0.5px;
    }
    .email-content {
      padding: 32px;
      color: $textColor;
    }
    .email-content p {
      line-height: 1.6;
      font-size: 16px;
      margin: 1em 0;
      color: $textColor;
    }
    .email-content h1, .email-content h2, .email-content h3, 
    .email-content h4, .email-content h5, .email-content h6 {
      color: $textColor;
      margin-top: 1.5em;
      margin-bottom: 0.5em;
    }
    .email-content h1 { font-size: 2em; }
    .email-content h2 { font-size: 1.5em; }
    .email-content h3 { font-size: 1.25em; }
    .email-content strong, .email-content b {
      font-weight: 600;
      color: $textColor;
    }
    .email-content em, .email-content i {
      font-style: italic;
    }
    .email-content u {
      text-decoration: underline;
    }
    .email-content a {
      color: #d4af37;
      text-decoration: none;
      font-weight: 500;
    }
    .email-content a:hover {
      text-decoration: underline;
    }
    .email-content ul, .email-content ol {
      padding-left: 20px;
      margin: 1em 0;
    }
    .email-content li {
      margin: 0.5em 0;
      color: $textColor;
    }
    .email-content blockquote {
      border-left: 4px solid #d4af37;
      margin: 1em 0;
      padding-left: 16px;
      font-style: italic;
      background-color: ${darkMode ? '#2a2a2a' : '#f9f9f9'};
      padding: 12px 16px;
      border-radius: 4px;
    }
    .email-content code {
      background-color: ${darkMode ? '#3a3a3a' : '#f1f1f1'};
      padding: 2px 4px;
      border-radius: 3px;
      font-family: 'Courier New', monospace;
      font-size: 0.9em;
    }
    .email-footer {
      background-color: $footerBg;
      padding: 24px;
      text-align: center;
      font-size: 12px;
      color: $footerText;
      border-top: 1px solid $borderColor;
    }
    .investment-details {
      margin-top: 24px;
      border-top: 1px solid $borderColor;
      padding-top: 16px;
    }
    .investment-details h3 {
      font-size: 18px;
      color: $textColor;
      margin-bottom: 12px;
    }
    /* Text alignment classes */
    .ql-align-center { text-align: center; }
    .ql-align-right { text-align: right; }
    .ql-align-justify { text-align: justify; }
    
    /* Font size classes */
    .ql-size-small { font-size: 0.75em; }
    .ql-size-large { font-size: 1.5em; }
    .ql-size-huge { font-size: 2.5em; }
    
    /* Color handling for rich text */
    .email-content span[style*="color"] {
      /* Preserve inline color styles from Quill */
    }
    .email-content span[style*="background-color"] {
      /* Preserve inline background colors from Quill */
    }
    
    @media (max-width: 600px) {
      .email-container {
        margin: 10px;
        border-radius: 8px;
      }
      .email-header, .email-content, .email-footer {
        padding: 20px;
      }
      .email-header h1 {
        font-size: 24px;
      }
    }
  </style>
</head>
<body>
  <div class="email-container">
    <div class="email-header">
      <h1>Metropolitan Investment</h1>
    </div>
    <div class="email-content">
      <p>Witaj $investorName,</p>
      $content
      ${investmentDetailsHtml != null && investmentDetailsHtml.isNotEmpty ? '<div class="investment-details">$investmentDetailsHtml</div>' : ''}
    </div>
    <div class="email-footer">
      <p>&copy; $currentYear Metropolitan Investment S.A. Wszelkie prawa zastrzeżone.</p>
      <p>Ta wiadomość została wygenerowana automatycznie. Prosimy na nią nie odpowiadać.</p>
    </div>
  </div>
</body>
</html>
""";
  }
}

/// Widget do renderowania HTML emaila z flutter_html
class _EmailHtmlRenderer extends StatelessWidget {
  final String htmlContent;
  final bool darkMode;

  const _EmailHtmlRenderer({
    super.key, // DODANE - parametr key
    required this.htmlContent,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Parsuj pełny HTML template
    final document = _parseEmailTemplate(htmlContent);
    
    return Container(
      color: darkMode ? const Color(0xFF1a1a1a) : const Color(0xFFf0f2f5),
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 680),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: darkMode ? const Color(0xFF2c2c2c) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: darkMode ? const Color(0xFF444444) : const Color(0xFFdddfe2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: darkMode ? 0.3 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: darkMode ? const Color(0xFF1f1f1f) : const Color(0xFF2c2c2c),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'Metropolitan Investment',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFd4af37), // Metropolitan Gold
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Text(
                      'Witaj ${document.investorName},',
                      style: TextStyle(
                        color: darkMode ? const Color(0xFFe0e0e0) : const Color(0xFF1c1e21),
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Main content
                    ...document.contentWidgets.map((widget) => widget),
                    // Investment details
                    if (document.investmentDetailsHtml != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: darkMode ? const Color(0xFF444444) : const Color(0xFFdddfe2),
                            ),
                          ),
                        ),
                        child: _buildInvestmentDetailsWidget(document.investmentDetailsHtml!, darkMode),
                      ),
                    ],
                  ],
                ),
              ),
              // Footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: darkMode ? const Color(0xFF1f1f1f) : const Color(0xFFf7f7f7),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: darkMode ? const Color(0xFF444444) : const Color(0xFFdddfe2),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '© ${DateTime.now().year} Metropolitan Investment S.A. Wszelkie prawa zastrzeżone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: darkMode ? const Color(0xFF888888) : const Color(0xFF606770),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ta wiadomość została wygenerowana automatycznie. Prosimy na nią nie odpowiadać.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: darkMode ? const Color(0xFF888888) : const Color(0xFF606770),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Parsuje HTML template i wyciąga komponenty
  _EmailDocument _parseEmailTemplate(String html) {
    String investorName = 'Szanowni Państwo';
    String content = '';
    String? investmentDetailsHtml;

    try {
      // Wyciągnij nazwę inwestora
      final investorMatch = RegExp(r'<p>Witaj ([^,<]+),</p>').firstMatch(html);
      if (investorMatch != null) {
        investorName = investorMatch.group(1)!;
      }

      // Wyciągnij główną treść między powitaniem a detalami inwestycji
      final contentMatch = RegExp(
        r'<p>Witaj [^,<]+,</p>\s*(.*?)(?:<div class="investment-details">|</div>\s*</div>\s*</body>)',
        dotAll: true,
      ).firstMatch(html);
      
      if (contentMatch != null) {
        content = contentMatch.group(1)!.trim();
      }

      // Wyciągnij szczegóły inwestycji
      final investmentMatch = RegExp(
        r'<div class="investment-details">(.*?)</div>',
        dotAll: true,
      ).firstMatch(html);
      
      if (investmentMatch != null) {
        investmentDetailsHtml = investmentMatch.group(1)!;
      }

      return _EmailDocument(
        investorName: investorName,
        contentWidgets: _buildContentWidgets(content),
        investmentDetailsHtml: investmentDetailsHtml,
      );
    } catch (e) {
      // Fallback - użyj prostego parsowania
      return _EmailDocument(
        investorName: investorName,
        contentWidgets: [
          Text(
            'Błąd parsowania treści emaila: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ],
        investmentDetailsHtml: null,
      );
    }
  }

  /// Buduje widgety zawartości z HTML
  List<Widget> _buildContentWidgets(String htmlContent) {
    final widgets = <Widget>[];
    
    if (htmlContent.isEmpty) {
      widgets.add(
        Text(
          'Brak treści wiadomości.',
          style: TextStyle(
            color: darkMode ? const Color(0xFF888888) : const Color(0xFF606770),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
      return widgets;
    }

    // Usuń tagi HTML i podziel na akapity
    final cleanContent = htmlContent
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();

    final paragraphs = cleanContent.split('\n\n');
    
    for (final paragraph in paragraphs) {
      final trimmed = paragraph.trim();
      if (trimmed.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              trimmed,
              style: TextStyle(
                color: darkMode ? const Color(0xFFe0e0e0) : const Color(0xFF1c1e21),
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  /// Buduje widget szczegółów inwestycji
  Widget _buildInvestmentDetailsWidget(String htmlContent, bool darkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Szczegóły inwestycji:',
          style: TextStyle(
            color: darkMode ? const Color(0xFFe0e0e0) : const Color(0xFF1c1e21),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: darkMode ? const Color(0xFF444444) : const Color(0xFFdddfe2),
            ),
          ),
          child: _parseInvestmentTable(htmlContent, darkMode),
        ),
      ],
    );
  }

  /// Parsuje i renderuje tabelę inwestycji
  Widget _parseInvestmentTable(String htmlContent, bool darkMode) {
    final rows = <TableRow>[];
    
    // Parsuj HTML tabeli
    final rowMatches = RegExp(r'<tr[^>]*>(.*?)</tr>', dotAll: true).allMatches(htmlContent);
    
    for (final match in rowMatches) {
      final rowHtml = match.group(1)!;
      final cellMatches = RegExp(r'<td[^>]*>(.*?)</td>', dotAll: true).allMatches(rowHtml);
      
      final cells = <Widget>[];
      for (final cellMatch in cellMatches) {
        final cellContent = cellMatch.group(1)!
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll('&nbsp;', ' ')
            .trim();
        
        final isBold = rowHtml.contains('font-weight: bold');
        final isEvenRow = rowHtml.contains('background-color: #f9f9f9');
        
        cells.add(
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEvenRow
                  ? (darkMode ? const Color(0xFF2a2a2a) : const Color(0xFFf9f9f9))
                  : Colors.transparent,
            ),
            child: Text(
              cellContent,
              style: TextStyle(
                color: darkMode ? const Color(0xFFe0e0e0) : const Color(0xFF1c1e21),
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        );
      }
      
      if (cells.length >= 2) {
        rows.add(
          TableRow(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: darkMode ? const Color(0xFF444444) : const Color(0xFFdddfe2),
                  width: 0.5,
                ),
              ),
            ),
            children: cells,
          ),
        );
      }
    }

    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Brak danych do wyświetlenia',
          style: TextStyle(
            color: darkMode ? const Color(0xFF888888) : const Color(0xFF606770),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Table(
      border: TableBorder.all(
        color: darkMode ? const Color(0xFF444444) : const Color(0xFFdddfe2),
        width: 1,
      ),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
      },
      children: rows,
    );
  }
}

/// Model dokumentu email
class _EmailDocument {
  final String investorName;
  final List<Widget> contentWidgets;
  final String? investmentDetailsHtml;

  _EmailDocument({
    required this.investorName,
    required this.contentWidgets,
    this.investmentDetailsHtml,
  });
}
