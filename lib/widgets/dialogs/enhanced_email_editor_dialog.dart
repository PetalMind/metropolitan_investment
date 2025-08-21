import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';
import '../../providers/auth_provider.dart';

/// Zaawansowany dialog do tworzenia i wysyłania maili z edytorem Quill
///
/// Pozwala na:
/// - Formatowanie tekstu za pomocą rich text editora
/// - Podgląd HTML generowanego z edytora
/// - Wysyłanie spersonalizowanych maili do inwestorów
/// - Zapisywanie szablonów do ponownego użycia
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

  bool _isLoading = false;
  bool _includeInvestmentDetails = true;
  bool _isGroupEmail = false; // Czy wysyłać jako jeden grupowy mail
  String? _error;
  List<EmailSendResult>? _results;

  // 🚀 NOWE: Enhanced loading and debugging states
  String _loadingMessage = 'Przygotowywanie...';
  int _currentEmailIndex = 0;
  int _totalEmailsToSend = 0;
  bool _showDetailedProgress = false;
  List<String> _debugLogs = [];
  DateTime? _emailSendStartTime;

  // Mapy do zarządzania adresami email odbiorców
  Map<String, bool> _recipientEnabled = {};
  Map<String, String> _recipientEmails = {};
  List<String> _additionalEmails = [];
  String? _selectedPreviewRecipient;

  final _emailAndExportService = EmailAndExportService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Inicjalizacja QuillController z podstawową konfiguracją bezpieczną dla web
    _quillController = QuillController.basic();

    // Inicjalizacja FocusNode dla edytora
    _editorFocusNode = FocusNode();

    // Ustawienie początkowych wartości
    _subjectController.text =
        widget.initialSubject ??
        'Aktualizacja portfela inwestycyjnego - Metropolitan Investment';

    // Opóźnij inicjalizację treści i dodanie listener'a
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.initialMessage != null) {
          _insertInitialContent(widget.initialMessage!);
        } else {
          _insertDefaultTemplate();
        }

        // Dodaj listener dopiero po pełnej inicjalizacji
        _quillController.addListener(_updatePreview);
      }
    });

    // Inicjalizacja map odbiorców
    _initializeRecipients();

    // Pobierz email z ustawień SMTP
    _loadSmtpEmail();
  }

  void _insertInitialContent(String content) {
    try {
      if (_quillController.document.length > 1) {
        _quillController.clear(); // Wyczyść istniejącą treść
      }
      final document = Document()..insert(0, content);
      _quillController.document = document;
    } catch (e) {
      debugPrint('Błąd podczas wstawiania treści: $e');
      // Fallback - spróbuj prostszą metodę
      _quillController.document.insert(0, content);
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
      // Ignoruj błąd - użytkownik może wprowadzić email ręcznie
    }
  }

  void _insertDefaultTemplate() {
    const defaultTemplate = '''Szanowni Państwo,

Przesyłamy aktualne informacje dotyczące Państwa inwestycji w Metropolitan Investment.

Poniżej znajdą Państwo szczegółowe podsumowanie swojego portfela inwestycyjnego.

W razie pytań prosimy o kontakt z naszym działem obsługi klienta.

Z poważaniem,
Zespół Metropolitan Investment''';

    _insertInitialContent(defaultTemplate);
  }

  void _updatePreview() {
    setState(() {
      // Aktualizacja podglądu - wywołane przy zmianie treści
    });
  }

  @override
  @override
  void dispose() {
    // Usuń listener przed dispose
    _quillController.removeListener(_updatePreview);

    _tabController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _senderEmailController.dispose();
    _senderNameController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = Provider.of<AuthProvider>(context).isAdmin;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: AppThemePro.backgroundPrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
            if (_error != null) _buildError(),
            if (_results != null) _buildResults(),
            if (_showDetailedProgress) _buildProgressIndicator(),
            _buildActions(canEdit),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.backgroundPrimary,
            AppThemePro.accentGold.withOpacity(0.8),
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
          const Icon(Icons.edit_outlined, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zaawansowany Edytor Email',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Odbiorcy: ${widget.selectedInvestors.length} inwestorów',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppThemePro.backgroundSecondary,
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.edit), text: 'Edytor'),
          Tab(icon: Icon(Icons.settings), text: 'Ustawienia'),
          Tab(icon: Icon(Icons.preview), text: 'Podgląd'),
        ],
        labelColor: AppThemePro.accentGold,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppThemePro.accentGold,
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [_buildEditorTab(), _buildSettingsTab(), _buildPreviewTab()],
    );
  }

  Widget _buildEditorTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Editor z zabezpieczeniami dla web
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Pasek narzędzi Quill - ZAWSZE widoczny (również na web)
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
                          color: AppThemePro.backgroundPrimary,
                          size: 18,
                        ),
                        dividerColor: AppThemePro.borderPrimary,
                        tooltipTheme: TooltipThemeData(
                          decoration: BoxDecoration(
                            color: AppThemePro.backgroundModal,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppThemePro.borderPrimary,
                            ),
                          ),
                          textStyle: TextStyle(
                            color: AppThemePro.backgroundPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          // Poprawiona kolorystyka dla toolbara
                          iconTheme: IconThemeData(
                            color: AppThemePro.textPrimary,
                            size: 20,
                          ),
                          textTheme: TextTheme(
                            bodySmall: TextStyle(
                              color: AppThemePro.overlayDark,
                              fontSize: 12,
                            ),
                          ),
                          dividerTheme: DividerThemeData(
                            color: AppThemePro.borderSecondary,
                            thickness: 1,
                          ),
                        ),
                        child: QuillSimpleToolbar(
                          controller: _quillController,
                          config: QuillSimpleToolbarConfig(
                            multiRowsDisplay: false,
                            showFontFamily: false,
                            showFontSize: kIsWeb
                                ? false
                                : true, // Rozmiar czcionki tylko na desktop/mobile
                            showStrikeThrough: false,
                            showInlineCode: false,
                            showCodeBlock: false,
                            showSubscript: false,
                            showSuperscript: false,
                            showSearchButton: false,
                            showListCheck: false,
                            showHeaderStyle: true,
                            showListBullets: true,
                            showListNumbers: true,
                            showIndent: kIsWeb
                                ? false
                                : true, // Wcięcia tylko na desktop/mobile
                            showLink: false, // Wyłącz linki dla stabilności
                            showUndo: true,
                            showRedo: true,
                            showDirection: false,
                            showAlignmentButtons: true,
                            showLeftAlignment: true,
                            showCenterAlignment: true,
                            showRightAlignment: true,
                            showJustifyAlignment: false,
                            showBackgroundColorButton: kIsWeb
                                ? false
                                : true, // Kolor tła tylko na desktop/mobile
                            showColorButton: kIsWeb
                                ? false
                                : true, // Kolor tekstu tylko na desktop/mobile
                            showBoldButton: true,
                            showItalicButton: true,
                            showUnderLineButton: true,
                            showClearFormat: true,
                            showQuote: true,
                            // Improved styling for dark theme compatibility
                            decoration: BoxDecoration(
                              color: AppThemePro.backgroundTertiary,
                              border: Border.all(
                                color: AppThemePro.borderPrimary,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Separator między toolbar a edytorem
                  Container(height: 1, color: AppThemePro.borderPrimary),

                  // Edytor Quill z lepszą kolorystyką
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppThemePro.borderPrimary),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          // Nadpisanie kolorów dla lepszej widoczności
                          iconTheme: IconThemeData(
                            color: AppThemePro.textPrimary,
                          ),
                          textTheme: TextTheme(
                            bodyLarge: TextStyle(
                              color: AppThemePro.dividerColor,
                              fontSize: 14,
                            ),
                            bodyMedium: TextStyle(
                              color: AppThemePro.dividerColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        child: QuillEditor.basic(
                          controller: _quillController,
                          config: QuillEditorConfig(
                            placeholder: 'Wpisz treść swojego maila...',
                            padding: const EdgeInsets.all(16),
                            autoFocus: false,
                            enableSelectionToolbar: true,
                            scrollable: true,
                            expands: false,
                            // Web-specific optimizations
                            maxContentWidth: kIsWeb ? 800 : null,
                            // Kolorystyka edytora dla ciemnego motywu
                            customStyles: DefaultStyles(
                              paragraph: DefaultTextBlockStyle(
                                TextStyle(
                                  color: AppThemePro.surfaceCard,
                                  fontSize: 14,
                                ),
                                HorizontalSpacing.zero,
                                VerticalSpacing.zero,
                                VerticalSpacing.zero,
                                null,
                              ),
                              placeHolder: DefaultTextBlockStyle(
                                TextStyle(
                                  color: AppThemePro.backgroundModal,
                                  fontSize: 14,
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
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Szybkie akcje z dodatkowymi opcjami dla web
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _insertGreeting,
                icon: const Icon(Icons.waving_hand, size: 16),
                label: const Text('Dodaj powitanie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[100],
                  foregroundColor: Colors.blue[800],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _insertSignature,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Dodaj podpis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[100],
                  foregroundColor: Colors.green[800],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _clearEditor,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Wyczyść'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[100],
                  foregroundColor: Colors.red[800],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              if (kIsWeb) // Dodatkowe opcje dla web
                ElevatedButton.icon(
                  onPressed: _insertDefaultTemplate,
                  icon: const Icon(Icons.article, size: 16),
                  label: const Text('Szablon'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[100],
                    foregroundColor: Colors.purple[800],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Informacja o skrótach klawiszowych dla web
          if (kIsWeb)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                'Skróty: Ctrl+B (pogrubienie), Ctrl+I (kursywa), Ctrl+U (podkreślenie), Ctrl+Z (cofnij)',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Podstawowe ustawienia
            Text(
              'Ustawienia Email',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Email wysyłającego
            TextFormField(
              controller: _senderEmailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Twój Email *',
                hintText: 'your@company.com',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email wysyłającego jest wymagany';
                }
                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                  return 'Nieprawidłowy format email';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Nazwa wysyłającego
            TextFormField(
              controller: _senderNameController,
              decoration: const InputDecoration(
                labelText: 'Nazwa Wysyłającego',
                hintText: 'Metropolitan Investment',
                prefixIcon: Icon(Icons.business_outlined),
              ),
            ),

            const SizedBox(height: 16),

            // Temat
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Temat Email',
                hintText: 'Twoje inwestycje - podsumowanie',
                prefixIcon: Icon(Icons.subject_outlined),
              ),
            ),

            const SizedBox(height: 24),

            // Opcje dodatkowe
            Text(
              'Opcje Dodatkowe',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            CheckboxListTile(
              title: const Text('Dołącz szczegóły inwestycji'),
              subtitle: const Text('Automatycznie dodaj tabelę z inwestycjami'),
              value: _includeInvestmentDetails,
              onChanged: (value) {
                setState(() {
                  _includeInvestmentDetails = value ?? true;
                });
              },
              activeColor: AppThemePro.accentGold,
            ),

            // Typ wysyłki (jeśli więcej niż 1 odbiorca)
            if (widget.selectedInvestors.length > 1) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Email grupowy'),
                subtitle: Text(
                  _isGroupEmail
                      ? 'Jeden email do wszystkich odbiorców (TO/CC/BCC)'
                      : 'Osobne emaile dla każdego odbiorcy',
                ),
                value: _isGroupEmail,
                onChanged: (value) {
                  setState(() {
                    _isGroupEmail = value;
                  });
                },
                activeColor: AppThemePro.accentGold,
              ),
            ],

            // Lista odbiorców
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Odbiorcy',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addAdditionalEmail,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Dodaj email'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppThemePro.accentGold,
                  ),
                ),
              ],
            ),

            // Informacja o edycji emaili
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppThemePro.accentGold.withOpacity(0.1),
                border: Border.all(
                  color: AppThemePro.accentGold.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: AppThemePro.accentGold,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Możesz edytować adresy email inwestorów klikając przycisk edycji. Email zostanie wysłany na nowy adres zamiast na adres przypisany do klienta.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppThemePro.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Lista inwestorów
            ..._buildRecipientsList(),

            // Lista dodatkowych emaili
            if (_additionalEmails.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Dodatkowe adresy',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ..._buildAdditionalEmailsList(),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecipientsList() {
    return widget.selectedInvestors.map((investor) {
      final clientId = investor.client.id;
      final isEnabled = _recipientEnabled[clientId] ?? false;
      final currentEmail = _recipientEmails[clientId] ?? '';
      final originalEmail = investor.client.email;
      final hasCustomEmail =
          currentEmail != originalEmail && currentEmail.isNotEmpty;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isEnabled
                ? AppThemePro.accentGold.withOpacity(0.3)
                : AppThemePro.borderPrimary,
            width: isEnabled ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isEnabled
              ? AppThemePro.accentGold.withOpacity(0.05)
              : AppThemePro.backgroundTertiary,
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppThemePro.accentGold.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header z przełącznikiem i nazwą inwestora
              Row(
                children: [
                  Transform.scale(
                    scale: 0.9,
                    child: Switch(
                      value: isEnabled,
                      onChanged: (value) {
                        setState(() {
                          _recipientEnabled[clientId] = value;
                          // Jeśli włączamy i nie ma emaila, ustaw oryginalny
                          if (value &&
                              currentEmail.isEmpty &&
                              originalEmail.isNotEmpty) {
                            _recipientEmails[clientId] = originalEmail;
                          }
                        });
                      },
                      activeColor: AppThemePro.accentGold,
                      activeTrackColor: AppThemePro.accentGold.withOpacity(0.3),
                      inactiveThumbColor: Colors.grey[400],
                      inactiveTrackColor: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          investor.client.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isEnabled
                                ? AppThemePro.textPrimary
                                : AppThemePro.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              size: 14,
                              color: AppThemePro.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${investor.investmentCount} inwestycji',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppThemePro.textMuted,
                              ),
                            ),
                            if (hasCustomEmail) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppThemePro.accentGold.withOpacity(
                                    0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'WŁASNY EMAIL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppThemePro.accentGold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Pole email z lepszym designem
              TextFormField(
                initialValue: currentEmail,
                enabled: isEnabled,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                style: TextStyle(
                  fontSize: 14,
                  color: isEnabled
                      ? AppThemePro.textPrimary
                      : AppThemePro.textMuted,
                ),
                decoration: InputDecoration(
                  hintText: 'adres@email.com',
                  hintStyle: TextStyle(
                    color: AppThemePro.textMuted,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: isEnabled
                      ? Colors.white
                      : AppThemePro.backgroundSecondary,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppThemePro.borderPrimary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: hasCustomEmail
                          ? AppThemePro.accentGold.withOpacity(0.5)
                          : AppThemePro.borderPrimary,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppThemePro.accentGold,
                      width: 2,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppThemePro.borderPrimary.withOpacity(0.5),
                    ),
                  ),
                  prefixIcon: Icon(
                    hasCustomEmail ? Icons.edit_outlined : Icons.email_outlined,
                    size: 18,
                    color: isEnabled
                        ? (hasCustomEmail
                              ? AppThemePro.accentGold
                              : AppThemePro.textSecondary)
                        : AppThemePro.textMuted,
                  ),
                  suffixIcon: isEnabled
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasCustomEmail) ...[
                              IconButton(
                                icon: Icon(
                                  Icons.refresh,
                                  size: 18,
                                  color: AppThemePro.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _recipientEmails[clientId] = originalEmail;
                                  });
                                },
                                tooltip: 'Przywróć oryginalny email',
                              ),
                            ],
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: AppThemePro.accentGold,
                              ),
                              onPressed: () {
                                _showEmailEditDialog(
                                  clientId,
                                  investor.client.name,
                                  currentEmail,
                                  originalEmail,
                                );
                              },
                              tooltip: 'Edytuj email',
                            ),
                          ],
                        )
                      : null,
                ),
                onChanged: (value) {
                  _recipientEmails[clientId] = value;

                  // Sprawdź czy email jest prawidłowy i automatycznie ustaw switch
                  final isValid =
                      value.isNotEmpty &&
                      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);

                  setState(() {
                    if (isValid && !_recipientEnabled[clientId]!) {
                      _recipientEnabled[clientId] = true;
                    }
                  });
                },
                validator: isEnabled
                    ? (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email jest wymagany';
                        }
                        if (!RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(value)) {
                          return 'Nieprawidłowy format email';
                        }
                        return null;
                      }
                    : null,
              ),

              // Footer z informacją o oryginalnym emailu
              if (originalEmail.isNotEmpty &&
                  originalEmail != currentEmail) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppThemePro.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Oryginalny email: $originalEmail',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppThemePro.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildAdditionalEmailsList() {
    return _additionalEmails.asMap().entries.map((entry) {
      final index = entry.key;
      final email = entry.value;
      final isValidEmail =
          email.isNotEmpty &&
          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

      return Container(
        key: ValueKey('additional_email_$index'),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isValidEmail
                ? Colors.blue.withOpacity(0.3)
                : AppThemePro.borderPrimary,
            width: isValidEmail ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isValidEmail
              ? Colors.blue.withOpacity(0.05)
              : AppThemePro.backgroundTertiary,
          boxShadow: isValidEmail
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header z ikoną i etykietą
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person_add_outlined,
                      size: 18,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dodatkowy odbiorca ${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppThemePro.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red[600],
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _additionalEmails.removeAt(index);
                      });
                    },
                    tooltip: 'Usuń tego odbiorcę',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Pole email
              TextFormField(
                key: ValueKey('additional_email_field_$index'),
                initialValue: email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                style: TextStyle(fontSize: 14, color: AppThemePro.textPrimary),
                decoration: InputDecoration(
                  hintText: 'dodatkowy@email.com',
                  hintStyle: TextStyle(
                    color: AppThemePro.textMuted,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppThemePro.borderPrimary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isValidEmail
                          ? Colors.blue.withOpacity(0.5)
                          : AppThemePro.borderPrimary,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  prefixIcon: Icon(
                    Icons.alternate_email,
                    size: 18,
                    color: isValidEmail
                        ? Colors.blue[700]
                        : AppThemePro.textSecondary,
                  ),
                  suffixIcon: isValidEmail
                      ? Icon(
                          Icons.check_circle,
                          size: 18,
                          color: Colors.green[600],
                        )
                      : null,
                ),
                onChanged: (value) {
                  if (index < _additionalEmails.length) {
                    // Zabezpieczenie przed błędami indeksu
                    _additionalEmails[index] = value;
                  }
                },
              ),

              // Dodanie przycisków akcji - przeniesienie z niepoprawnego atrybutu trailing
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.check,
                      color: AppThemePro.statusSuccess,
                      size: 20,
                    ),
                    onPressed: () {
                      // Pobierz aktualną wartość z listy _additionalEmails
                      final currentValue = index < _additionalEmails.length
                          ? _additionalEmails[index].trim()
                          : '';

                      // Potwierdzenie dodania adresu
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            currentValue.isNotEmpty
                                ? 'Adres $currentValue został potwierdzony'
                                : 'Adres jest pusty - wprowadź poprawny email',
                          ),
                          backgroundColor: currentValue.isNotEmpty
                              ? AppThemePro.statusSuccess
                              : Colors.orange,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Potwierdź adres',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: AppThemePro.statusError,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        if (index < _additionalEmails.length) {
                          // Zabezpieczenie przed błędami indeksu
                          _additionalEmails.removeAt(index);
                        }
                      });
                    },
                    tooltip: 'Usuń adres',
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _addAdditionalEmail() {
    setState(() {
      _additionalEmails.add('');
    });
  }

  Widget _buildPreviewTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.preview, color: AppThemePro.accentGold),
              const SizedBox(width: 8),
              Text(
                'Podgląd Email',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              DropdownButton<String>(
                value: _selectedPreviewRecipient,
                hint: const Text('Wybierz odbiorcę'),
                items: _getEnabledRecipients().map((recipient) {
                  return DropdownMenuItem(
                    value: recipient['id'],
                    child: Text(
                      recipient['name'] ?? 'Nieznany',
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPreviewRecipient = value;
                    _updatePreview();
                  });
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _updatePreview,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Odśwież'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Info o wybranym odbiorcy
          if (_selectedPreviewRecipient != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Podgląd dla: ${_getRecipientInfo(_selectedPreviewRecipient!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Faktyczny podgląd email
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SingleChildScrollView(child: _buildEmailPreview()),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getEnabledRecipients() {
    final recipients = <Map<String, String>>[];

    // Dodaj aktywnych inwestorów
    for (final investor in widget.selectedInvestors) {
      final clientId = investor.client.id;
      if (_recipientEnabled[clientId] == true) {
        recipients.add({
          'id': clientId,
          'name': investor.client.name,
          'email': _recipientEmails[clientId] ?? '',
          'type': 'investor',
        });
      }
    }

    // Dodaj dodatkowe emaile
    for (int i = 0; i < _additionalEmails.length; i++) {
      final email = _additionalEmails[i];
      if (email.isNotEmpty &&
          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
        recipients.add({
          'id': 'additional_$i',
          'name': 'Dodatkowy: $email',
          'email': email,
          'type': 'additional',
        });
      }
    }

    return recipients;
  }

  String _getRecipientInfo(String recipientId) {
    if (recipientId.startsWith('additional_')) {
      final index = int.tryParse(recipientId.split('_')[1]) ?? 0;
      if (index < _additionalEmails.length) {
        return _additionalEmails[index];
      }
      return 'Nieznany dodatkowy email';
    }

    final investor = widget.selectedInvestors.firstWhere(
      (inv) => inv.client.id == recipientId,
      orElse: () => widget.selectedInvestors.first,
    );

    final email = _recipientEmails[recipientId] ?? investor.client.email;
    return '${investor.client.name} <$email>';
  }

  Widget _buildEmailPreview() {
    if (_selectedPreviewRecipient == null) {
      return Container(
        height: 300,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Wybierz odbiorcę z listy powyżej\naby zobaczyć podgląd email',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final recipientInfo = _getRecipientInfo(_selectedPreviewRecipient!);
    final plainText = _quillController.document.toPlainText();

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email header (jak w prawdziwym kliencie email)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Od: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${_senderNameController.text} <${_senderEmailController.text}>',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Do: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Expanded(child: Text(recipientInfo)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Temat: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _subjectController.text.isNotEmpty
                            ? _subjectController.text
                            : 'Brak tematu',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _subjectController.text.isNotEmpty
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Data: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(DateTime.now().toString().split('.')[0]),
                  ],
                ),
              ],
            ),
          ),

          // Email content
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Powitanie
                if (_selectedPreviewRecipient!.startsWith('additional_'))
                  const Text(
                    'Szanowni Państwo,',
                    style: TextStyle(fontSize: 16),
                  )
                else
                  Text(
                    'Szanowny/a ${widget.selectedInvestors.firstWhere((inv) => inv.client.id == _selectedPreviewRecipient!).client.name},',
                    style: const TextStyle(fontSize: 16),
                  ),

                const SizedBox(height: 16),

                // Treść z edytora - dokładnie 1:1 z zawartością edytora
                if (plainText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppThemePro.backgroundTertiary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppThemePro.borderPrimary),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plainText,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: AppThemePro.textPrimary,
                          ),
                        ),

                        // Dodanie szczegółów inwestycji jeśli włączone
                        if (_includeInvestmentDetails &&
                            !_selectedPreviewRecipient!.startsWith(
                              'additional_',
                            )) ...[
                          const SizedBox(height: 16),
                          const Divider(color: AppThemePro.borderSecondary),
                          const SizedBox(height: 16),
                          _buildInvestmentDetailsInline(
                            _selectedPreviewRecipient!,
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppThemePro.statusWarning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppThemePro.statusWarning),
                    ),
                    child: const Text(
                      'Brak treści wiadomości. Użyj edytora aby dodać treść.',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppThemePro.statusWarning,
                      ),
                    ),
                  ),

                // Szczegóły inwestycji są już wbudowane w treść powyżej
                const SizedBox(height: 24),

                // Podpis
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Z poważaniem,'),
                    Text(
                      _senderNameController.text.isNotEmpty
                          ? _senderNameController.text
                          : 'Metropolitan Investment',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Footer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Ten email został wygenerowany ${DateTime.now().toString().split('.')[0]}.\n'
                    'W razie pytań prosimy o kontakt z naszym działem obsługi klienta.',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Inline version of investment details for editor synchronization
  Widget _buildInvestmentDetailsInline(String clientId) {
    final investor = widget.selectedInvestors.firstWhere(
      (inv) => inv.client.id == clientId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Podsumowanie Twojego Portfela',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppThemePro.accentGold,
          ),
        ),
        const SizedBox(height: 12),

        // Statystyki
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppThemePro.backgroundSecondary,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppThemePro.borderSecondary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Całkowita wartość inwestycji: ${investor.totalInvestmentAmount.toStringAsFixed(2)} PLN',
                style: TextStyle(
                  color: AppThemePro.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kapitał pozostały: ${investor.totalRemainingCapital.toStringAsFixed(2)} PLN',
                style: const TextStyle(
                  color: AppThemePro.accentGold,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Lista inwestycji (pierwsze 3)
        if (investor.investments.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Szczegóły inwestycji:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppThemePro.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...investor.investments
              .take(3)
              .map(
                (investment) => Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppThemePro.backgroundSecondary,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppThemePro.borderSecondary),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          investment.productName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppThemePro.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${investment.remainingCapital.toStringAsFixed(2)} PLN',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppThemePro.accentGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (investor.investments.length > 3)
            Text(
              '... i ${investor.investments.length - 3} więcej',
              style: const TextStyle(
                fontSize: 12,
                color: AppThemePro.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_error!, style: TextStyle(color: Colors.red[700])),
          ),
        ],
      ),
    );
  }

  /// 🚀 NOWY: Szczegółowy wskaźnik postępu
  Widget _buildProgressIndicator() {
    if (!_showDetailedProgress || !_isLoading) {
      return const SizedBox.shrink();
    }

    final progress = _totalEmailsToSend > 0
        ? _currentEmailIndex / _totalEmailsToSend
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.accentGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppThemePro.accentGold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _loadingMessage,
                  style: TextStyle(
                    color: AppThemePro.accentGold,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (_totalEmailsToSend > 0)
                Text(
                  '$_currentEmailIndex / $_totalEmailsToSend',
                  style: TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          if (_totalEmailsToSend > 0) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(AppThemePro.accentGold),
            ),
          ],
          if (_debugLogs.isNotEmpty && _debugLogs.length <= 3) ...[
            const SizedBox(height: 8),
            ...(_debugLogs
                .take(3)
                .map(
                  (log) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      log.length > 60 ? '${log.substring(0, 60)}...' : log,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppThemePro.textMuted,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_results == null) return const SizedBox.shrink();

    final successful = _results!.where((r) => r.success).length;
    final failed = _results!.length - successful;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: successful == _results!.length
            ? Colors.green[50]
            : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: successful == _results!.length
              ? Colors.green[300]!
              : Colors.orange[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                successful == _results!.length
                    ? Icons.check_circle_outline
                    : Icons.warning_outlined,
                color: successful == _results!.length
                    ? Colors.green[700]
                    : Colors.orange[700],
              ),
              const SizedBox(width: 8),
              Text(
                'Wyniki wysyłania',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: successful == _results!.length
                      ? Colors.green[700]
                      : Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('✅ Wysłane pomyślnie: $successful'),
          if (failed > 0) Text('❌ Błędy: $failed'),
          const SizedBox(height: 8),
          if (kDebugMode && _debugLogs.isNotEmpty)
            TextButton.icon(
              onPressed: _showDebugDialog,
              icon: Icon(Icons.info_outline, size: 16),
              label: Text('Pokaż szczegóły debug'),
              style: TextButton.styleFrom(
                foregroundColor: AppThemePro.accentGold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(bool canEdit) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          Row(
            children: [
              // 🚀 NOWY: Przycisk debug (tylko w trybie development)
              if (kDebugMode) ...[
                ElevatedButton.icon(
                  onPressed: _debugLogs.isNotEmpty ? _showDebugDialog : null,
                  icon: Icon(Icons.bug_report, size: 16),
                  label: Text('Debug (${_debugLogs.length})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _debugLogs.any(
                          (log) => log.contains('❌') || log.contains('💥'),
                        )
                        ? Colors.red[100]
                        : Colors.grey[100],
                    foregroundColor:
                        _debugLogs.any(
                          (log) => log.contains('❌') || log.contains('💥'),
                        )
                        ? Colors.red[700]
                        : Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton.icon(
                onPressed: (!canEdit || _isLoading) ? null : _saveTemplate,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Zapisz szablon'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[100],
                  foregroundColor: Colors.blue[700],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: (!canEdit || _isLoading || !_hasValidEmails())
                    ? null
                    : _sendEmails,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isLoading ? _loadingMessage : 'Wyślij Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemePro.accentGold,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _insertGreeting() {
    try {
      const greeting = 'Szanowni Państwo,\n\n';
      _quillController.document.insert(0, greeting);
    } catch (e) {
      debugPrint('Błąd podczas wstawiania powitania: $e');
    }
  }

  void _insertSignature() {
    try {
      final signature =
          '\n\nZ poważaniem,\nZespół ${_senderNameController.text}\n';
      final length = _quillController.document.length;
      _quillController.document.insert(length - 1, signature);
    } catch (e) {
      debugPrint('Błąd podczas wstawiania podpisu: $e');
    }
  }

  void _clearEditor() {
    try {
      _quillController.clear();
    } catch (e) {
      debugPrint('Błąd podczas czyszczenia edytora: $e');
    }
  }

  bool _hasValidEmails() {
    return widget.selectedInvestors.any(
      (investor) =>
          investor.client.email.isNotEmpty &&
          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(investor.client.email),
    );
  }

  Future<void> _saveTemplate() async {
    // TODO: Implementacja zapisywania szablonu
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funkcja zapisywania szablonów będzie dostępna wkrótce'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _sendEmails() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(1); // Przejdź do zakładki ustawień
      return;
    }

    // 🚀 ENHANCED: Reset debug state and start timing
    _emailSendStartTime = DateTime.now();
    _debugLogs.clear();
    _addDebugLog('🚀 Rozpoczynam proces wysyłania maili');

    // Sprawdź czy istnieją konfiguracje SMTP
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Sprawdzam konfigurację SMTP...';
      _currentEmailIndex = 0;
      _totalEmailsToSend = 0;
      _showDetailedProgress = true;
      _error = null;
      _results = null;
    });

    try {
      // 🚀 ENHANCED: Sprawdź ustawienia SMTP przed wysyłaniem z debugowaniem
      _addDebugLog('🔧 Sprawdzam ustawienia SMTP...');
      final smtpService = SmtpService();
      final smtpSettings = await smtpService.getSmtpSettings();

      if (smtpSettings == null) {
        _addDebugLog('❌ Brak konfiguracji SMTP');
        setState(() {
          _error =
              'Brak konfiguracji serwera SMTP. Skonfiguruj ustawienia email w aplikacji.';
          _isLoading = false;
          _loadingMessage = 'Przygotowywanie...';
        });
        return;
      }

      _addDebugLog(
        '✅ Konfiguracja SMTP znaleziona: ${smtpSettings.host}:${smtpSettings.port}',
      );

      // 🚀 ENHANCED: Walidacja email wysyłającego z debugowaniem
      if (_senderEmailController.text.trim().isEmpty) {
        _addDebugLog('❌ Brak email wysyłającego');
        setState(() {
          _error = 'Podaj email wysyłającego';
          _isLoading = false;
          _loadingMessage = 'Przygotowywanie...';
        });
        return;
      }

      _addDebugLog('📧 Email wysyłającego: ${_senderEmailController.text}');

      // 🚀 ENHANCED: Pobierz inwestorów z włączonymi emailami z debugowaniem
      setState(() {
        _loadingMessage = 'Przygotowywanie listy odbiorców...';
      });

      final enabledRecipients = _getEnabledRecipients();
      _addDebugLog(
        '👥 Znaleziono ${enabledRecipients.length} aktywnych odbiorców',
      );

      if (enabledRecipients.isEmpty) {
        _addDebugLog('❌ Brak prawidłowych odbiorców');
        setState(() {
          _error = 'Brak odbiorców z prawidłowymi adresami email';
          _isLoading = false;
          _loadingMessage = 'Przygotowywanie...';
        });
        return;
      }

      setState(() {
        _totalEmailsToSend = enabledRecipients.length;
      });

      // 🚀 ENHANCED: Konwersja treści z Quill do HTML z debugowaniem
      setState(() {
        _loadingMessage = 'Konwertuję treść na HTML...';
      });

      final htmlContent = _convertDocumentToHtml(_quillController.document);
      _addDebugLog('📝 Długość treści HTML: ${htmlContent.length} znaków');

      if (htmlContent.trim().isEmpty) {
        _addDebugLog('❌ Brak treści emaila');
        setState(() {
          _error = 'Treść emaila nie może być pusta';
          _isLoading = false;
          _loadingMessage = 'Przygotowywanie...';
        });
        return;
      }

      // 🚀 ENHANCED: Przygotuj listę odbiorców z debugowaniem
      setState(() {
        _loadingMessage = 'Przetwarzam odbiorców...';
      });

      final recipientsWithInvestmentData = <InvestorSummary>[];
      final additionalEmailAddresses = <String>[];

      for (final recipient in enabledRecipients) {
        final recipientId = recipient['id']!;

        if (recipientId.startsWith('additional_')) {
          // Dodaj dodatkowe emaile do osobnej listy
          additionalEmailAddresses.add(recipient['email']!);
        } else {
          // Znajdź prawdziwego inwestora
          final investor = widget.selectedInvestors.firstWhere(
            (inv) => inv.client.id == recipientId,
            orElse: () => widget.selectedInvestors.first,
          );

          recipientsWithInvestmentData.add(investor);
        }
      }

      // 🚀 ENHANCED: Wybierz odpowiednią metodę wysyłania z debugowaniem
      _addDebugLog(
        '📊 Inwestorów: ${recipientsWithInvestmentData.length}, Dodatkowych: ${additionalEmailAddresses.length}',
      );

      setState(() {
        _loadingMessage = 'Wysyłam emaile...';
        _currentEmailIndex = 1;
      });

      List<EmailSendResult> results;

      if (additionalEmailAddresses.isNotEmpty) {
        // 🚀 ENHANCED: Użyj nowej metody dla mieszanych odbiorców z debugowaniem
        _addDebugLog('📤 Wysyłam mieszane emaile (inwestorzy + dodatkowe)');
        results = await _emailAndExportService
            .sendCustomEmailsToMixedRecipients(
              investors: recipientsWithInvestmentData,
              additionalEmails: additionalEmailAddresses,
              subject: _subjectController.text.isNotEmpty
                  ? _subjectController.text
                  : 'Wiadomość od ${_senderNameController.text}',
              htmlContent: htmlContent,
              includeInvestmentDetails: _includeInvestmentDetails,
              senderEmail: _senderEmailController.text,
              senderName: _senderNameController.text,
            );
      } else {
        // 🚀 ENHANCED: Użyj oryginalnej metody tylko dla inwestorów z debugowaniem
        _addDebugLog('📤 Wysyłam emaile tylko do inwestorów');
        results = await _emailAndExportService
            .sendCustomEmailsToMultipleClients(
              investors: recipientsWithInvestmentData,
              subject: _subjectController.text.isNotEmpty
                  ? _subjectController.text
                  : 'Wiadomość od ${_senderNameController.text}',
              htmlContent: htmlContent,
              includeInvestmentDetails: _includeInvestmentDetails,
              senderEmail: _senderEmailController.text,
              senderName: _senderNameController.text,
            );
      }

      // 🚀 ENHANCED: Analiza wyników z debugowaniem
      final successful = results.where((r) => r.success).length;
      final failed = results.length - successful;
      final duration = DateTime.now().difference(_emailSendStartTime!);

      _addDebugLog('✅ Zakończono wysyłanie w ${duration.inSeconds}s');
      _addDebugLog('📊 Podsumowanie: $successful sukces, $failed błędów');

      // Dodaj szczegóły błędów do logów
      for (final result in results.where((r) => !r.success)) {
        _addDebugLog('❌ Błąd dla ${result.clientEmail}: ${result.error}');
      }

      setState(() {
        _results = results;
        _isLoading = false;
        _loadingMessage = 'Zakończono';
        _showDetailedProgress = false;
      });

      // Pokaż snackbar z podsumowaniem - already calculated above

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failed == 0
                  ? '✅ Wysłano $successful maili pomyślnie'
                  : '⚠️ Wysłano $successful maili, błędów: $failed',
            ),
            backgroundColor: failed == 0
                ? Colors.green[700]
                : Colors.orange[700],
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Jeśli wszystkie maile zostały wysłane pomyślnie, wywołaj callback
      if (failed == 0) {
        widget.onEmailSent();
      }
    } catch (e) {
      // 🚀 ENHANCED: Szczegółowe debugowanie błędów
      final duration = _emailSendStartTime != null
          ? DateTime.now().difference(_emailSendStartTime!)
          : Duration.zero;

      _addDebugLog(
        '💥 KRYTYCZNY BŁĄD po ${duration.inSeconds}s: ${e.toString()}',
      );
      _addDebugLog('📍 Stack trace: ${StackTrace.current}');

      setState(() {
        _error = 'Błąd podczas wysyłania maili: ${e.toString()}';
        _isLoading = false;
        _loadingMessage = 'Przygotowywanie...';
        _showDetailedProgress = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Błąd wysyłania: ${e.toString()}'),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  // Pomocnicza metoda konwersji dokumentu Quill na HTML
  String _convertDocumentToHtml(Document document) {
    try {
      // Użyj niestandardowej implementacji konwersji
      return _customDocumentToHtml(document);
    } catch (e) {
      debugPrint('Błąd konwersji Quill do HTML: $e');

      // Ostateczny fallback - prosty plain text z <br>
      final plainText = document.toPlainText();
      return plainText
          .replaceAll('\n', '<br>')
          .replaceAll('  ', '&nbsp;&nbsp;');
    }
  }

  /// Niestandardowa konwersja dokumentu Quill do HTML (fallback)
  String _customDocumentToHtml(Document document) {
    try {
      final buffer = StringBuffer();
      buffer.write('<div>');

      // Iteruj przez operacje delta
      final ops = document.toDelta().operations;

      for (final op in ops) {
        if (op.isInsert) {
          String text = op.data?.toString() ?? '';

          // Sprawdź czy jest to zwykły tekst czy znak nowej linii
          if (text == '\n') {
            buffer.write('<br>');
          } else {
            // Aplikuj formatowanie na podstawie atrybutów
            String formattedText = _applyFormattingToText(text, op.attributes);
            buffer.write(formattedText);
          }
        }
      }

      buffer.write('</div>');
      return buffer.toString();
    } catch (e) {
      debugPrint('Błąd niestandardowej konwersji do HTML: $e');

      // Ostateczny fallback - prosty plain text z <br>
      final plainText = document.toPlainText();
      return plainText
          .replaceAll('\n', '<br>')
          .replaceAll('  ', '&nbsp;&nbsp;');
    }
  }

  /// Aplikuje formatowanie HTML na podstawie atrybutów Quill
  String _applyFormattingToText(String text, Map<String, dynamic>? attributes) {
    if (attributes == null || attributes.isEmpty) {
      return _escapeHtml(text);
    }

    String result = _escapeHtml(text);

    // Formatowanie tekstu
    if (attributes['bold'] == true) {
      result = '<strong>$result</strong>';
    }

    if (attributes['italic'] == true) {
      result = '<em>$result</em>';
    }

    if (attributes['underline'] == true) {
      result = '<u>$result</u>';
    }

    // Kolor tekstu
    if (attributes['color'] != null) {
      final color = attributes['color'].toString();
      result = '<span style="color: $color">$result</span>';
    }

    // Kolor tła
    if (attributes['background'] != null) {
      final bgColor = attributes['background'].toString();
      result = '<span style="background-color: $bgColor">$result</span>';
    }

    // Rozmiar czcionki
    if (attributes['size'] != null) {
      final size = attributes['size'].toString();
      result = '<span style="font-size: $size">$result</span>';
    }

    // Wyrównanie (zastosowane na poziomie akapitu)
    if (attributes['align'] != null) {
      final align = attributes['align'].toString();
      result = '<div style="text-align: $align">$result</div>';
    }

    // Nagłówki
    if (attributes['header'] != null) {
      final level = attributes['header'].toString();
      switch (level) {
        case '1':
          result = '<h1>$result</h1>';
          break;
        case '2':
          result = '<h2>$result</h2>';
          break;
        case '3':
          result = '<h3>$result</h3>';
          break;
        default:
          result = '<h4>$result</h4>';
      }
    }

    // Listy
    if (attributes['list'] != null) {
      final listType = attributes['list'].toString();
      if (listType == 'ordered') {
        result = '<li>$result</li>'; // Będzie opakowane w <ol> później
      } else if (listType == 'bullet') {
        result = '<li>$result</li>'; // Będzie opakowane w <ul> później
      }
    }

    // Cytaty
    if (attributes['blockquote'] == true) {
      result = '<blockquote>$result</blockquote>';
    }

    return result;
  }

  /// Escape HTML w tekście
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  // 🚀 NOWE: Metody debugowania
  void _addDebugLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logEntry = '[$timestamp] $message';
    _debugLogs.add(logEntry);

    // Print to console for development
    if (kDebugMode) {
      print('📧 [EmailDebug] $logEntry');
    }

    // Update UI if showing progress
    if (_showDetailedProgress && mounted) {
      setState(() {}); // Trigger rebuild to show new log
    }
  }

  /// Pokazuje dialog z debugowaniem
  void _showDebugDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppThemePro.backgroundModal,
        title: Row(
          children: [
            Icon(Icons.bug_report, color: AppThemePro.accentGold),
            const SizedBox(width: 8),
            Text(
              'Debug Logs - Wysyłanie Email',
              style: TextStyle(color: AppThemePro.textPrimary),
            ),
          ],
        ),
        content: Container(
          width: 500,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppThemePro.accentGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Logi z ostatniego procesu wysyłania (${_debugLogs.length} wpisów)',
                  style: TextStyle(
                    color: AppThemePro.accentGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _debugLogs.isEmpty
                      ? Center(
                          child: Text(
                            'Brak logów - wyślij emaile aby zobaczyć debug info',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _debugLogs.length,
                          itemBuilder: (context, index) {
                            final log = _debugLogs[index];
                            Color logColor = Colors.white;

                            // Kolorowanie na podstawie typu logu
                            if (log.contains('✅')) {
                              logColor = Colors.green[300]!;
                            } else if (log.contains('❌') ||
                                log.contains('💥')) {
                              logColor = Colors.red[300]!;
                            } else if (log.contains('⚠️')) {
                              logColor = Colors.orange[300]!;
                            } else if (log.contains('🚀')) {
                              logColor = Colors.blue[300]!;
                            } else if (log.contains('📧') ||
                                log.contains('📄')) {
                              logColor = Colors.cyan[300]!;
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              child: Text(
                                log,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: logColor,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Kopiuj logi do schowka
              Clipboard.setData(ClipboardData(text: _debugLogs.join('\n')));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 Logi skopiowane do schowka'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: Icon(Icons.copy, size: 16),
            label: Text('Kopiuj'),
            style: TextButton.styleFrom(
              foregroundColor: AppThemePro.accentGold,
            ),
          ),
          TextButton.icon(
            onPressed: () {
              _debugLogs.clear();
              Navigator.pop(context);
            },
            icon: Icon(Icons.clear, size: 16),
            label: Text('Wyczyść'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  /// Pokazuje dialog do edycji emaila inwestora
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
        backgroundColor: AppThemePro.backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppThemePro.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.edit_outlined,
                color: AppThemePro.accentGold,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edytuj Email',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppThemePro.textPrimary,
                    ),
                  ),
                  Text(
                    clientName,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppThemePro.textSecondary,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            final isValidEmail =
                tempEmail.isNotEmpty &&
                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(tempEmail);
            final hasCustomEmail =
                tempEmail != originalEmail && tempEmail.isNotEmpty;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pole do edycji emaila
                TextFormField(
                  initialValue: tempEmail,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppThemePro.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Adres email',
                    hintText: 'nowy@email.com',
                    hintStyle: TextStyle(color: AppThemePro.textMuted),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppThemePro.borderPrimary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isValidEmail
                            ? AppThemePro.accentGold.withOpacity(0.5)
                            : AppThemePro.borderPrimary,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppThemePro.accentGold,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.alternate_email,
                      size: 18,
                      color: isValidEmail
                          ? AppThemePro.accentGold
                          : AppThemePro.textSecondary,
                    ),
                    suffixIcon: isValidEmail
                        ? Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Colors.green[600],
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      tempEmail = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Informacje dodatkowe
                if (originalEmail.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppThemePro.backgroundTertiary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppThemePro.borderSecondary),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppThemePro.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Oryginalny email:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppThemePro.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          originalEmail,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppThemePro.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (hasCustomEmail) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                tempEmail = originalEmail;
                              });
                            },
                            icon: Icon(Icons.refresh, size: 16),
                            label: Text('Przywróć oryginalny'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppThemePro.accentGold,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Status walidacji
                if (tempEmail.isNotEmpty && !isValidEmail) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nieprawidłowy format email',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Anuluj',
              style: TextStyle(color: AppThemePro.textMuted),
            ),
          ),
          StatefulBuilder(
            builder: (context, setButtonState) {
              final isValidEmail =
                  tempEmail.isNotEmpty &&
                  RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(tempEmail);

              return ElevatedButton.icon(
                onPressed: isValidEmail
                    ? () {
                        setState(() {
                          _recipientEmails[clientId] = tempEmail;
                          // Automatycznie włącz odbiorcę przy prawidłowym emailu
                          _recipientEnabled[clientId] = true;
                        });
                        Navigator.pop(context);

                        // Pokaż potwierdzenie
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Email dla $clientName został zaktualizowany',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.green[600],
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    : null,
                icon: Icon(Icons.save, size: 16),
                label: Text('Zapisz email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isValidEmail
                      ? AppThemePro.accentGold
                      : Colors.grey,
                  foregroundColor: Colors.black,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
