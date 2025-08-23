import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
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

  // Export states
  bool _exportInProgress = false;
  String _currentExportFormat = '';
  AdvancedExportResult? _lastExportResult;

  @override
  void initState() {
    super.initState();

    // Inicjalizacja serwisu
    _emailService = EmailEditorService();
    _emailService.initializeRecipients(widget.investors);

    // Inicjalizacja kontrolerów
    _tabController = TabController(length: 4, vsync: this);
    _quillController = QuillController.basic();
    _editorFocusNode = FocusNode();

    // Ustawienie początkowych wartości
    _subjectController.text =
        widget.initialSubject ??
        'Aktualizacja portfela inwestycyjnego - Metropolitan Investment';

    // Dodaj listener
    _quillController.addListener(_updatePreview);

    // Opóźnij inicjalizację treści
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeEditorContent();
        _loadSmtpEmail();
      }
    });
  }

  @override
  void dispose() {
    _quillController.removeListener(_updatePreview);
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
      _quillController.clear();

      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          try {
            _quillController.document.insert(0, content);
            _quillController.updateSelection(
              TextSelection.collapsed(offset: content.length),
              ChangeSource.local,
            );
            setState(() {});
          } catch (e) {
            debugPrint('Błąd opóźnionego wstawiania: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('Błąd podczas wstawiania treści: $e');
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
      _quillController.clear();

      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          try {
            _quillController.document.insert(0, defaultTemplate);
            setState(() {});
          } catch (e) {
            debugPrint('Błąd wstawiania szablonu: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('Błąd podczas wstawiania szablonu: $e');
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

  /// Aktualizuje podgląd
  void _updatePreview() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = Provider.of<AuthProvider>(context).isAdmin;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

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
                  color: Colors.black.withOpacity(0.3),
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
          Tab(text: 'Eksport', icon: Icon(Icons.download)),
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
        _buildExportTab(),
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
              multiRowsDisplay: false,
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showColorButton: true,
              showBackgroundColorButton: false,
              showFontSize: true,
              showAlignmentButtons: true,
              showHeaderStyle: true,
              showListNumbers: true,
              showListBullets: true,
              showCodeBlock: false,
              showQuote: true,
              showIndent: true,
              showLink: false,
              showUndo: true,
              showRedo: true,
              showDirection: false,
              showSearchButton: false,
              showSubscript: false,
              showSuperscript: false,
            ),
          ),
          const SizedBox(height: 8),

          // Edytor Quill
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppThemePro.borderPrimary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: QuillEditor.basic(
                controller: _quillController,
                config: QuillEditorConfig(
                  placeholder: 'Wprowadź treść wiadomości...',
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Przyciski akcji edytora
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _insertGreeting,
                icon: const Icon(Icons.waving_hand, size: 16),
                label: const Text('Powitanie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemePro.backgroundSecondary,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _insertSignature,
                icon: const Icon(Icons.draw, size: 16),
                label: const Text('Podpis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemePro.backgroundSecondary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _clearEditor,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Wyczyść'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemePro.statusError,
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
                      title: const Text('Dołącz szczegóły inwestycji'),
                      subtitle: const Text(
                        'Automatycznie dodaje informacje o portfelu inwestora',
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
                        Text(
                          'Dodatkowe emaile',
                          style: Theme.of(context).textTheme.titleMedium,
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
          // Wybór odbiorcy do podglądu
          if (_getEnabledRecipientsCount() > 0) ...[
            DropdownButtonFormField<String>(
              value: _selectedPreviewRecipient,
              decoration: const InputDecoration(
                labelText: 'Wybierz odbiorcę do podglądu',
                prefixIcon: Icon(Icons.person),
              ),
              items: _buildPreviewRecipientItems(),
              onChanged: (value) {
                setState(() {
                  _selectedPreviewRecipient = value;
                });
              },
            ),
            const SizedBox(height: 16),
          ],

          // Podgląd emaila
          Expanded(child: _buildEmailPreview()),
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
              ? AppThemePro.statusSuccess.withOpacity(0.1)
              : AppThemePro.backgroundSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled
                ? AppThemePro.statusSuccess.withOpacity(0.3)
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
              ? AppThemePro.statusSuccess.withOpacity(0.1)
              : AppThemePro.backgroundSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isValidEmail
                ? AppThemePro.statusSuccess.withOpacity(0.3)
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

  /// Buduje podgląd emaila
  Widget _buildEmailPreview() {
    if (_selectedPreviewRecipient == null) {
      return const Center(child: Text('Wybierz odbiorcę aby zobaczyć podgląd'));
    }

    final htmlContent = _emailService.convertDocumentToHtml(
      _quillController.document,
    );

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nagłówek emaila
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Od: ${_senderNameController.text} <${_senderEmailController.text}>',
                  ),
                  Text('Do: ${_getRecipientInfo(_selectedPreviewRecipient!)}'),
                  Text('Temat: ${_subjectController.text}'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Treść emaila (HTML)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                htmlContent,
                style: const TextStyle(color: Colors.black),
              ),
            ),

            // Szczegóły inwestycji (jeśli włączone)
            if (_includeInvestmentDetails &&
                !_selectedPreviewRecipient!.startsWith('additional_')) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _buildInvestmentDetailsPreview(_selectedPreviewRecipient!),
            ],
          ],
        ),
      ),
    );
  }

  /// Zakładka eksportu do PDF, Excel, Word
  Widget _buildExportTab() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nagłówek
          Row(
            children: [
              const Icon(
                Icons.download,
                color: AppThemePro.accentGold,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eksport do plików',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppThemePro.textPrimary,
                      ),
                    ),
                    Text(
                      'Eksportuj dane ${widget.investors.length} inwestorów do plików PDF, Excel lub Word',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppThemePro.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Opcje eksportu
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // PDF Export
                  _buildExportOption(
                    icon: Icons.picture_as_pdf,
                    title: 'Eksport do PDF',
                    description:
                        'Profesjonalny raport z brandingiem Metropolitan Investment',
                    format: 'pdf',
                    color: Colors.red,
                  ),

                  const SizedBox(height: 16),

                  // Excel Export
                  _buildExportOption(
                    icon: Icons.table_chart,
                    title: 'Eksport do Excel',
                    description:
                        'Zaawansowany arkusz z formatowaniem i formułami',
                    format: 'excel',
                    color: Colors.green,
                  ),

                  const SizedBox(height: 16),

                  // Word Export
                  _buildExportOption(
                    icon: Icons.description,
                    title: 'Eksport do Word',
                    description: 'Dokument biznesowy z pełnym formatowaniem',
                    format: 'word',
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 24),

                  // Status eksportu
                  if (_exportInProgress) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppThemePro.surfaceCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppThemePro.borderPrimary),
                      ),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(
                            'Generowanie pliku $_currentExportFormat...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'To może potrwać kilka sekund',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppThemePro.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Ostatni eksport
                  if (_lastExportResult != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _lastExportResult!.isSuccessful
                            ? AppThemePro.statusSuccess.withValues(alpha: 0.1)
                            : AppThemePro.statusError.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _lastExportResult!.isSuccessful
                              ? AppThemePro.statusSuccess
                              : AppThemePro.statusError,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _lastExportResult!.isSuccessful
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: _lastExportResult!.isSuccessful
                                    ? AppThemePro.statusSuccess
                                    : AppThemePro.statusError,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _lastExportResult!.isSuccessful
                                      ? 'Eksport zakończony pomyślnie'
                                      : 'Eksport niepowodzenie',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _lastExportResult!.summaryText,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (_lastExportResult!.isSuccessful &&
                              _lastExportResult!.downloadUrl != null) ...[
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _downloadFile(
                                _lastExportResult!.downloadUrl!,
                              ),
                              icon: const Icon(Icons.download),
                              label: const Text('Pobierz plik'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppThemePro.accentGold,
                                foregroundColor: AppThemePro.textPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Buduje podgląd szczegółów inwestycji
  Widget _buildInvestmentDetailsPreview(String clientId) {
    final investor = widget.investors.firstWhere(
      (inv) => inv.client.id == clientId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Szczegóły portfela inwestycyjnego:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              _buildDetailRow('Klient:', investor.client.name),
              _buildDetailRow('Email:', investor.client.email),
              _buildDetailRow(
                'Liczba inwestycji:',
                '${investor.investments.length}',
              ),
              _buildDetailRow(
                'Łączna kwota inwestycji:',
                '${investor.totalInvestmentAmount.toStringAsFixed(2)} PLN',
              ),
              _buildDetailRow(
                'Kapitał pozostały:',
                '${investor.viableRemainingCapital.toStringAsFixed(2)} PLN',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// Buduje elementy dropdown dla podglądu odbiorców
  List<DropdownMenuItem<String>> _buildPreviewRecipientItems() {
    final items = <DropdownMenuItem<String>>[];

    // Dodaj inwestorów
    for (final investor in widget.investors) {
      final clientId = investor.client.id;
      if (_emailService.recipientEnabled[clientId] == true) {
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
      if (email.isNotEmpty &&
          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
        items.add(
          DropdownMenuItem(
            value: 'additional_$i',
            child: Text('Dodatkowy odbiorca ($email)'),
          ),
        );
      }
    }

    return items;
  }

  /// Wyświetla błąd
  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemePro.statusError.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.statusError.withOpacity(0.3)),
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
        color: AppThemePro.accentGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.accentGold.withOpacity(0.3)),
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
                color: Colors.black.withOpacity(0.8),
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
                .withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              (_lastResult!.success
                      ? AppThemePro.statusSuccess
                      : AppThemePro.statusWarning)
                  .withOpacity(0.3),
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

  /// Buduje przyciski akcji
  Widget _buildActions(bool canEdit) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        border: Border(top: BorderSide(color: AppThemePro.borderPrimary)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Przycisk debugowania
          if (kDebugMode)
            TextButton.icon(
              onPressed: _showDebugDialog,
              icon: const Icon(Icons.bug_report, size: 16),
              label: const Text('Debug'),
            ),

          const Spacer(),

          // Przyciski główne
          if (widget.showAsDialog)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),

          const SizedBox(width: 8),

          ElevatedButton.icon(
            onPressed: canEdit && !_isLoading && _hasValidEmails()
                ? _sendEmails
                : null,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send, size: 16),
            label: Text(_isLoading ? 'Wysyłanie...' : 'Wyślij emaile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemePro.accentGold,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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

  String _getRecipientInfo(String recipientId) {
    if (recipientId.startsWith('additional_')) {
      final index = int.tryParse(recipientId.split('_')[1]) ?? 0;
      if (index < _emailService.additionalEmails.length) {
        return _emailService.additionalEmails[index];
      }
      return 'Nieznany dodatkowy email';
    }

    final investor = widget.investors.firstWhere(
      (inv) => inv.client.id == recipientId,
      orElse: () => widget.investors.first,
    );

    final email =
        _emailService.recipientEmails[recipientId] ?? investor.client.email;
    return '${investor.client.name} <$email>';
  }

  // === ACTION METHODS ===

  void _insertGreeting() {
    try {
      const greeting = 'Szanowni Państwo,\n\n';
      _quillController.document.insert(0, greeting);
      Future.delayed(const Duration(milliseconds: 10), () {
        if (mounted) setState(() {});
      });
    } catch (e) {
      debugPrint('Błąd podczas wstawiania powitania: $e');
    }
  }

  void _insertSignature() {
    try {
      final signature =
          '\n\nZ poważaniem,\nZespół ${_senderNameController.text}\n';
      final length = _quillController.document.length;
      final insertPosition = length > 1 ? length - 1 : length;

      _quillController.document.insert(insertPosition, signature);
      Future.delayed(const Duration(milliseconds: 10), () {
        if (mounted) setState(() {});
      });
    } catch (e) {
      debugPrint('Błąd podczas wstawiania podpisu: $e');
    }
  }

  void _clearEditor() {
    try {
      _quillController.clear();
      Future.delayed(const Duration(milliseconds: 10), () {
        if (mounted) setState(() {});
      });
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
    if (!_formKey.currentState!.validate()) {
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
      final htmlContent = _emailService.convertDocumentToHtml(
        _quillController.document,
      );

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

  /// Buduje opcję eksportu
  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String description,
    required String format,
    required Color color,
  }) {
    final isSelected = _currentExportFormat == format;

    return Card(
      elevation: isSelected ? 4 : 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: AppThemePro.accentGold, width: 2)
              : null,
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppThemePro.textSecondary),
          ),
          trailing: _exportInProgress && _currentExportFormat == format
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_forward_ios),
          onTap: _exportInProgress ? null : () => _startExport(format),
        ),
      ),
    );
  }

  /// Rozpoczyna eksport w wybranym formacie
  Future<void> _startExport(String format) async {
    if (_exportInProgress) return;

    setState(() {
      _exportInProgress = true;
      _currentExportFormat = format;
      _lastExportResult = null;
    });

    try {
      // Pobierz ID klientów
      final clientIds = widget.investors.map((inv) => inv.client.id).toList();

      // Sprawdź czy użytkownik jest zalogowany
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      if (currentUser == null) {
        throw Exception('Użytkownik nie jest zalogowany');
      } // Wywołaj serwis eksportu
      final exportService = EmailAndExportService();
      final result = await exportService.exportInvestorsAdvanced(
        clientIds: clientIds,
        exportFormat: format,
        templateType: 'summary',
        options: {
          'includeKontakty': true,
          'includeInvestycje': true,
          'includeStatystyki': true,
        },
        requestedBy: currentUser.uid,
      );

      setState(() {
        _lastExportResult = result;
        _exportInProgress = false;
        _currentExportFormat = '';
      });

      if (result.isSuccessful) {
        // Pokazuj sukces
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Eksport $format zakończony pomyślnie!'),
              backgroundColor: AppThemePro.statusSuccess,
              action: result.downloadUrl != null
                  ? SnackBarAction(
                      label: 'Pobierz',
                      textColor: Colors.white,
                      onPressed: () => _downloadFile(result.downloadUrl!),
                    )
                  : null,
            ),
          );
        }
      } else {
        // Pokazuj błąd
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Błąd eksportu: ${result.errorMessage}'),
              backgroundColor: AppThemePro.statusError,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _lastExportResult = AdvancedExportResult(
          success: false,
          downloadUrl: null,
          fileName: null,
          fileSize: 0,
          exportFormat: format,
          errorMessage: e.toString(),
          processingTimeMs: 0,
          totalRecords: widget.investors.length,
        );
        _exportInProgress = false;
        _currentExportFormat = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas eksportu: $e'),
            backgroundColor: AppThemePro.statusError,
          ),
        );
      }
    }
  }

  /// Otwiera plik do pobrania
  Future<void> _downloadFile(String url) async {
    try {
      // W przypadku aplikacji mobilnej - otwórz w przeglądarce
      if (kIsWeb) {
        // Dla wersji web
        // ignore: avoid_web_libraries_in_flutter
        // html.window.open(url, '_blank');
      } else {
        // Dla wersji mobilnej - możesz użyć url_launcher
        if (kDebugMode) {
          print('Pobieranie pliku: $url');
        }
        // await launch(url); // Jeśli masz url_launcher
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas otwierania pliku: $e'),
            backgroundColor: AppThemePro.statusError,
          ),
        );
      }
    }
  }
}
