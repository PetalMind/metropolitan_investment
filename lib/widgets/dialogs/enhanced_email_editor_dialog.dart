import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart' as html;
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
  String? _selectedPreviewRecipient;

  final _emailAndExportService = EmailAndExportService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize QuillController
    _quillController = QuillController.basic();
    _editorFocusNode = FocusNode();

    // Set initial values
    _subjectController.text =
        widget.initialSubject ??
        'Aktualizacja portfela inwestycyjnego - Metropolitan Investment';

    // Add listener
    _quillController.addListener(_updatePreview);
    
    // Initialize content
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeEditorContent();
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
            debugPrint('Error inserting content: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('Error during content insertion: $e');
      try {
        _quillController.clear();
        _quillController.document.insert(0, content);
      } catch (fallbackError) {
        debugPrint('Fallback error: $fallbackError');
      }
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
    
    // Auto-select first available recipient for preview
    final availableRecipients = widget.selectedInvestors
        .where((inv) => _recipientEnabled[inv.client.id] ?? false)
        .toList();
    if (availableRecipients.isNotEmpty && _selectedPreviewRecipient == null) {
      _selectedPreviewRecipient = availableRecipients.first.client.id;
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
      _quillController.clear();
      
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          try {
            _quillController.document.insert(0, defaultTemplate);
            _quillController.updateSelection(
              TextSelection.collapsed(offset: defaultTemplate.length),
              ChangeSource.local,
            );
            setState(() {});
          } catch (e) {
            debugPrint('Error inserting template: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('Error during template insertion: $e');
    }
  }

  void _updatePreview() {
    if (mounted) {
      setState(() {
        // Update preview when content changes
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final canEdit = Provider.of<AuthProvider>(context).isAdmin;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMediumScreen = screenSize.width < 900;
    
    final dialogWidth = isSmallScreen 
        ? screenSize.width * 0.95
        : isMediumScreen 
            ? screenSize.width * 0.85
            : screenSize.width * 0.8;
    
    final dialogHeight = isSmallScreen 
        ? screenSize.height * 0.95
        : screenSize.height * 0.9;
    
    final dialogPadding = isSmallScreen ? 8.0 : 16.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(dialogPadding),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: AppThemePro.backgroundPrimary,
          borderRadius: BorderRadius.circular(16),
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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final headerPadding = isSmallScreen ? 16.0 : 24.0;
    
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
                Text(
                  'Zaawansowany Edytor Email',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final contentPadding = isSmallScreen ? 12.0 : 16.0;
    
    return Container(
      padding: EdgeInsets.all(contentPadding),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppThemePro.borderSecondary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Quill toolbar
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
                          size: 20,
                        ),
                        dividerTheme: DividerThemeData(
                          color: AppThemePro.borderSecondary,
                          thickness: 1,
                        ),
                      ),
                      child: QuillSimpleToolbar(
                        controller: _quillController,
                        config: QuillSimpleToolbarConfig(
                          multiRowsDisplay: true,
                          showFontFamily: true,
                          showFontSize: true,
                          showColorButton: true,
                          showBackgroundColorButton: true,
                          showBoldButton: true,
                          showItalicButton: true,
                          showUnderLineButton: true,
                          showStrikeThrough: true,
                          showSubscript: true,
                          showSuperscript: true,
                          showHeaderStyle: true,
                          showQuote: true,
                          showInlineCode: true,
                          showCodeBlock: false,
                          showListBullets: true,
                          showListNumbers: true,
                          showListCheck: true,
                          showIndent: true,
                          showAlignmentButtons: true,
                          showLeftAlignment: true,
                          showCenterAlignment: true,
                          showRightAlignment: true,
                          showJustifyAlignment: true,
                          showDirection: false,
                          showLink: true,
                          showUndo: true,
                          showRedo: true,
                          showClearFormat: true,
                          showSearchButton: false,
                          decoration: BoxDecoration(
                            color: AppThemePro.backgroundTertiary,
                            border: Border.all(
                              color: AppThemePro.borderPrimary,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          toolbarSize: 35,
                          toolbarSectionSpacing: 4,
                          toolbarIconAlignment: WrapAlignment.center,
                          // Enhanced button options for better formatting
                          buttonOptions: QuillSimpleToolbarButtonOptions(
                            base: QuillToolbarBaseButtonOptions(
                              iconSize: 18,
                              iconButtonFactor: 1.2,
                            ),
                            // Font size options - adding more size variations
                            fontSize: QuillToolbarFontSizeButtonOptions(
                              attribute: Attribute.size,
                            ),
                            // Color options - using default QuillToolbarColorButtonOptions
                            color: const QuillToolbarColorButtonOptions(),
                            // Background color options - using default QuillToolbarColorButtonOptions  
                            backgroundColor: const QuillToolbarColorButtonOptions(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Container(height: 1, color: AppThemePro.borderPrimary),

                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        try {
                          _editorFocusNode.requestFocus();
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (mounted && !_editorFocusNode.hasFocus) {
                              _editorFocusNode.requestFocus();
                            }
                          });
                        } catch (e) {
                          debugPrint('Focus error: $e');
                        }
                      },
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
                            iconTheme: IconThemeData(
                              color: AppThemePro.backgroundPrimary,
                            ),
                            textTheme: TextTheme(
                              bodyLarge: TextStyle(
                                color: AppThemePro.textPrimary,
                                fontSize: 14,
                              ),
                              bodyMedium: TextStyle(
                                color: AppThemePro.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            textSelectionTheme: TextSelectionThemeData(
                              cursorColor: AppThemePro.accentGold,
                              selectionColor: AppThemePro.accentGold
                                  .withValues(alpha: 0.3),
                              selectionHandleColor: AppThemePro.accentGold,
                            ),
                          ),
                          child: QuillEditor.basic(
                            controller: _quillController,
                            focusNode: _editorFocusNode,
                            config: QuillEditorConfig(
                              placeholder: 'Wpisz treść swojego maila...',
                              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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

          // Quick actions
          Wrap(
            spacing: isSmallScreen ? 4 : 8,
            runSpacing: isSmallScreen ? 4 : 8,
            children: [
              ElevatedButton.icon(
                onPressed: _insertGreeting,
                icon: const Icon(Icons.waving_hand, size: 16),
                label: const Text('Dodaj powitanie'),
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
                onPressed: _insertSignature,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Dodaj podpis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemePro.statusSuccess.withValues(alpha: 0.2),
                  foregroundColor: AppThemePro.statusSuccess,
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
                  backgroundColor: AppThemePro.statusError.withValues(alpha: 0.2),
                  foregroundColor: AppThemePro.statusError,
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

  Widget _buildSettingsTab() {
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
          _buildRecipientList(),
          const SizedBox(height: 24),
          _buildAdditionalEmailsField(),
        ],
      ),
    );
  }

  Widget _buildRecipientList() {
    if (widget.selectedInvestors.isEmpty) {
      return const Center(
        child: Text('Brak wybranych inwestorów.'),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        border: Border.all(color: AppThemePro.borderSecondary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.selectedInvestors.length,
        itemBuilder: (context, index) {
          final investor = widget.selectedInvestors[index];
          final clientId = investor.client.id;
          final email = investor.client.email;
          final isValidEmail = email.isNotEmpty &&
              RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

          return CheckboxListTile(
            title: Text(investor.client.name),
            subtitle: Text(email.isNotEmpty ? email : 'Brak adresu email'),
            value: _recipientEnabled[clientId] ?? false,
            onChanged: isValidEmail
                ? (bool? value) {
                    setState(() {
                      _recipientEnabled[clientId] = value ?? false;
                    });
                  }
                : null,
            secondary: Icon(
              isValidEmail ? Icons.person : Icons.person_off,
              color: isValidEmail
                  ? AppThemePro.statusSuccess
                  : AppThemePro.statusError,
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppThemePro.accentGold,
          );
        },
      ),
    );
  }

  Widget _buildAdditionalEmailsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dodatkowi odbiorcy (oddzieleni przecinkiem)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppThemePro.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _additionalEmails.join(', '),
          onChanged: (value) {
            setState(() {
              _additionalEmails.clear();
              _additionalEmails.addAll(
                value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
              );
            });
          },
          decoration: InputDecoration(
            hintText: 'np. email1@example.com, email2@example.com',
            prefixIcon: Icon(Icons.add, color: AppThemePro.textSecondary),
            filled: true,
            fillColor: AppThemePro.backgroundSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
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

  Widget _buildPreviewTab() {
    final converter = QuillDeltaToHtmlConverter(
      _quillController.document.toDelta().toJson(),
    );

    final htmlContent = converter.convert();
    final emailBody = _getEnhancedEmailTemplate(
      subject: _subjectController.text,
      content: htmlContent,
      investorName: _selectedPreviewRecipient != null
          ? widget.selectedInvestors
              .firstWhere((inv) => inv.client.id == _selectedPreviewRecipient)
              .client
              .name
          : 'Szanowni Państwo',
      investmentDetailsHtml: _includeInvestmentDetails
          ? '<h3>Podsumowanie Inwestycji (Przykład)</h3><p>Tutaj pojawi się tabela z danymi...</p>'
          : '',
      darkMode: _previewDarkMode,
    );

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
                  data: emailBody,
                  style: {
                    "body": html.Style(
                      backgroundColor: _previewDarkMode ? const Color(0xFF1a1a1a) : Colors.white,
                      fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
                      margin: html.Margins.all(0),
                      padding: html.HtmlPaddings.all(0),
                    ),
                    "*": html.Style(
                      fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
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

    if (availableRecipients.isEmpty) {
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

    // Ensure a default selection if none is set or the selected one is no longer valid
    if (_selectedPreviewRecipient == null ||
        !availableRecipients
            .any((inv) => inv.client.id == _selectedPreviewRecipient)) {
      _selectedPreviewRecipient = availableRecipients.first.client.id;
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
            Icons.person,
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
                items: availableRecipients
                    .map<DropdownMenuItem<String>>((InvestorSummary investor) {
                  return DropdownMenuItem<String>(
                    value: investor.client.id,
                    child: Text(
                      investor.client.name,
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
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
      final converter = QuillDeltaToHtmlConverter(
        _quillController.document.toDelta().toJson(),
      );
      final htmlContent = converter.convert();

      final selectedRecipients = widget.selectedInvestors
          .where((inv) => _recipientEnabled[inv.client.id] ?? false)
          .toList();

      _totalEmailsToSend = selectedRecipients.length + _additionalEmails.length;
      _currentEmailIndex = 0;

      // Logika wysyłki
      final results = await _emailAndExportService.sendCustomEmailsToMixedRecipients(
        investors: selectedRecipients,
        additionalEmails: _additionalEmails,
        subject: _subjectController.text,
        htmlContent: htmlContent,
        includeInvestmentDetails: _includeInvestmentDetails,
        senderEmail: _senderEmailController.text,
        senderName: _senderNameController.text,
      );

      setState(() {
        _results = results;
        _loadingMessage = 'Wysyłanie zakończone.';
      });
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
      if (_results != null) {
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

  /// Insert greeting template
  void _insertGreeting() {
    final selection = _quillController.selection;
    const greeting = '\n\nSzanowni Państwo,\n\n';
    
    try {
      _quillController.document.insert(selection.baseOffset, greeting);
      _quillController.updateSelection(
        TextSelection.collapsed(offset: selection.baseOffset + greeting.length),
        ChangeSource.local,
      );
    } catch (e) {
      debugPrint('Error inserting greeting: $e');
    }
  }

  /// Insert signature template
  void _insertSignature() {
    final selection = _quillController.selection;
    const signature = '\n\nZ poważaniem,\nZespół Metropolitan Investment\n\nTel: +48 XXX XXX XXX\nEmail: kontakt@metropolitan-investment.pl\nwww.metropolitan-investment.pl\n';
    
    try {
      _quillController.document.insert(selection.baseOffset, signature);
      _quillController.updateSelection(
        TextSelection.collapsed(offset: selection.baseOffset + signature.length),
        ChangeSource.local,
      );
    } catch (e) {
      debugPrint('Error inserting signature: $e');
    }
  }

  /// Clear editor content
  void _clearEditor() {
    try {
      _quillController.clear();
      setState(() {});
    } catch (e) {
      debugPrint('Error clearing editor: $e');
    }
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
  Widget _buildResults() {
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
  Widget _buildActions(bool canEdit) {
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
}