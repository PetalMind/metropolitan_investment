import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../models_and_services.dart';
import '../../models/email_template.dart';
import '../../theme/app_theme_professional.dart';
import '../../services/enhanced_email_editor_service.dart';
import '../../services/email_recipients_service.dart';
import '../../services/email_templates_service.dart';
import '../html_editor_widget.dart';
import 'enhanced_email_editor/email_editor_header.dart';
import 'enhanced_email_editor/email_editor_tabs.dart';
import 'enhanced_email_editor/email_editor_actions.dart';

/// Enhanced email editor dialog with rich text formatting
/// Completely rewritten to use html_editor_enhanced while maintaining identical functionality
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
  // Controllers and services
  late TabController _tabController;
  late HtmlEditorControllerWrapper _htmlController;
  late FocusNode _editorFocusNode;
  late EnhancedEmailEditorService _editorService;
  late EmailRecipientsService _recipientsService;
  late EmailTemplatesService _templatesService;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _senderNameController = TextEditingController(
    text: 'Metropolitan Investment',
  );
  final _subjectController = TextEditingController();

  // State management
  Timer? _previewDebounceTimer;
  bool _isLoading = false;
  String? _error;
  List<EmailSendResult>? _results;

  // Preview settings
  String _previewMode = 'html'; // 'html' or 'text'
  bool _previewDarkMode = false;

  // Templates management
  List<EmailTemplateModel> _emailTemplates = [];
  bool _isLoadingTemplates = false;

  // Editor formatting options
  Color _selectedTextColor = Colors.white;
  Color _selectedBackgroundColor = Colors.transparent;
  String _selectedFontFamily = 'Arial';

  // Individual content management
  final Map<String, HtmlEditorControllerWrapper> _individualControllers = {};
  final Map<String, FocusNode> _individualFocusNodes = {};
  String? _selectedRecipientForEditing;
  String? _selectedPreviewRecipient;
  bool _useIndividualContent = false;
  @override
  void initState() {
    super.initState();

    // Initialize services
    _editorService = EnhancedEmailEditorService();
    _recipientsService = EmailRecipientsService();
    _templatesService = EmailTemplatesService();

    // Initialize controllers
    _tabController = TabController(length: 3, vsync: this);
    _htmlController = HtmlEditorControllerWrapper();
    _editorFocusNode = FocusNode();

    // Set initial values
    _subjectController.text =
        widget.initialSubject ??
        'Aktualizacja portfela inwestycyjnego - Metropolitan Investment';

    // Add listener for preview updates
    _htmlController.addListener(_updatePreview);

    // Initialize content after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeContent();
        _initializeRecipients();
        _loadEmailTemplates();
        _loadSmtpEmail();
      }
    });
  }

  void _initializeContent() {
    try {
      final initial = widget.initialMessage;
      if (initial != null && initial.isNotEmpty) {
        _htmlController.setText(initial);
      } else {
        final template = _editorService.getDefaultTemplate();
        // Initialize with white text on transparent background
        final styledTemplate = '''
        <div style="color: white; font-family: Arial, sans-serif; font-size: 14px;">
          ${template.replaceAll('\n', '<br>')}
        </div>
        ''';
        _htmlController.setText(styledTemplate);
      }
    } catch (e) {
      debugPrint('Error initializing content: $e');
    }
  }

  Future<void> _loadEmailTemplates() async {
    setState(() {
      _isLoadingTemplates = true;
    });

    try {
      final templates = await _templatesService.getEmailTemplates();
      if (mounted) {
        setState(() {
          _emailTemplates = templates;
          _isLoadingTemplates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTemplates = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Błąd ładowania szablonów: $e'),
            backgroundColor: AppThemePro.statusError,
          ),
        );
      }
      debugPrint('Error loading templates: $e');
    }
  }

  void _initializeRecipients() {
    _recipientsService.initializeRecipients(widget.selectedInvestors);

    // Initialize individual controllers for each recipient
    for (final investor in widget.selectedInvestors) {
      final clientId = investor.client.id;
      _individualControllers[clientId] = HtmlEditorControllerWrapper();
      _individualFocusNodes[clientId] = FocusNode();
    }

    // Auto-select first available recipient for preview
    _selectedPreviewRecipient = _recipientsService.getFirstAvailableRecipient(
      widget.selectedInvestors,
    );
  }

  Future<void> _loadSmtpEmail() async {
    try {
      final smtpService = SmtpService();
      final smtpSettings = await smtpService.getSmtpSettings();
      if (smtpSettings != null && smtpSettings.username.isNotEmpty) {
        // Sender email already configured in SMTP settings
      }
    } catch (e) {
      // Ignore error - user can enter email manually
    }
  }

  void _updatePreview() {
    _previewDebounceTimer?.cancel();
    _previewDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  /// Build templates section for settings tab
  Widget _buildTemplatesSection() {
    return Column(
      children: [
        // Template selector
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppThemePro.borderSecondary),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
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
                    Icon(Icons.article, color: AppThemePro.accentGold),
                    const SizedBox(width: 8),
                    Text(
                      'Wybierz szablon',
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadEmailTemplates,
                      tooltip: 'Odśwież szablony',
                    ),
                  ],
                ),
              ),
              
              // Templates list
              if (_isLoadingTemplates)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                )
              else if (_emailTemplates.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Brak dostępnych szablonów',
                    style: TextStyle(color: AppThemePro.textSecondary),
                  ),
                )
              else
                Column(
                  children: _emailTemplates.map<Widget>((template) {
                    return ListTile(
                      title: Text(template.name),
                      subtitle: Text(template.description.isNotEmpty 
                          ? template.description 
                          : 'Brak opisu'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => _previewTemplate(template),
                            tooltip: 'Podgląd',
                          ),
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () => _applyTemplate(template),
                            tooltip: 'Zastosuj',
                            color: AppThemePro.accentGold,
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editTemplate(template),
                            tooltip: 'Edytuj',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteTemplate(template),
                            tooltip: 'Usuń',
                            color: AppThemePro.statusError,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Template actions
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _createNewTemplate,
              icon: const Icon(Icons.add),
              label: const Text('Nowy szablon'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemePro.accentGold,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _saveCurrentAsTemplate,
              icon: const Icon(Icons.save),
              label: const Text('Zapisz bieżącą treść'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppThemePro.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build formatting section for settings tab
  Widget _buildFormattingSection() {
    return Column(
      children: [
        // Font family selector
        Row(
          children: [
            Icon(Icons.font_download, color: AppThemePro.accentGold),
            const SizedBox(width: 8),
            Text(
              'Czcionka:',
              style: TextStyle(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedFontFamily,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: EnhancedEmailEditorService.customFontFamilies.entries
                    .map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(
                      entry.key,
                      style: TextStyle(fontFamily: entry.value),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFontFamily = value;
                    });
                    _applyFontFamily(value);
                  }
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Color pickers
        Row(
          children: [
            // Text color
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kolor tekstu:',
                    style: TextStyle(
                      color: AppThemePro.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _showTextColorPicker,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedTextColor,
                        border: Border.all(color: AppThemePro.borderSecondary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Kliknij, aby zmienić',
                          style: TextStyle(
                            color: _selectedTextColor.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Background color
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kolor tła:',
                    style: TextStyle(
                      color: AppThemePro.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _showBackgroundColorPicker,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedBackgroundColor == Colors.transparent
                            ? Colors.white
                            : _selectedBackgroundColor,
                        border: Border.all(color: AppThemePro.borderSecondary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _selectedBackgroundColor == Colors.transparent
                              ? 'Przezroczyste'
                              : 'Kliknij, aby zmienić',
                          style: TextStyle(
                            color: _selectedBackgroundColor == Colors.transparent
                                ? Colors.black
                                : _selectedBackgroundColor.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Apply formatting button
        ElevatedButton.icon(
          onPressed: _applySelectedFormatting,
          icon: const Icon(Icons.format_paint),
          label: const Text('Zastosuj formatowanie'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppThemePro.accentGold,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _htmlController.removeListener(_updatePreview);
    _previewDebounceTimer?.cancel();
    _tabController.dispose();
    _htmlController.dispose();
    _editorFocusNode.dispose();
    _senderNameController.dispose();
    _subjectController.dispose();

    // Dispose individual controllers and focus nodes
    for (final controller in _individualControllers.values) {
      controller.dispose();
    }
    for (final focusNode in _individualFocusNodes.values) {
      focusNode.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isSmallScreen = constraints.maxWidth < 900;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Form(
            key: _formKey,
            child: Container(
              width: constraints.maxWidth * (isMobile ? 0.95 : 0.9),
              height: constraints.maxHeight * (isMobile ? 0.95 : 0.9),
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 1200,
                maxHeight: isMobile ? double.infinity : 800,
              ),
              decoration: BoxDecoration(
                color: AppThemePro.backgroundPrimary,
                borderRadius: BorderRadius.circular(12),
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
                  // Header
                  EmailEditorHeader(
                    isMobile: isMobile,
                    isSmallScreen: isSmallScreen,
                    selectedInvestorsCount: widget.selectedInvestors.length,
                    onClose: () => Navigator.of(context).pop(),
                  ),

                  // Tab Bar
                  EmailEditorTabs(
                    tabController: _tabController,
                    isMobile: isMobile,
                    isSmallScreen: isSmallScreen,
                  ),

                  // Tab Content
                  Expanded(child: _buildTabContent(isMobile, isSmallScreen)),

                  // Actions
                  EmailEditorActions(
                    isMobile: isMobile,
                    isSmallScreen: isSmallScreen,
                    isLoading: _isLoading,
                    hasValidEmails: _recipientsService.hasValidEmails(),
                    error: _error,
                    results: _results,
                    onSend: _sendEmails,
                    onInsertVoting: _insertVoting,
                    onInsertInvestmentTable: _insertInvestmentTable,
                    onClear: _clearEditor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabContent(bool isMobile, bool isSmallScreen) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildEditorTab(isMobile, isSmallScreen),
        _buildSettingsTab(isMobile, isSmallScreen),
        _buildPreviewTab(isMobile, isSmallScreen),
      ],
    );
  }

  Widget _buildEditorTab(bool isMobile, bool isSmallScreen) {
    final contentPadding = isMobile
        ? 8.0
        : isSmallScreen
        ? 12.0
        : 16.0;

    return Container(
      padding: EdgeInsets.all(contentPadding),
      child: isMobile
          ? _buildMobileEditorLayout(isMobile, isSmallScreen)
          : _buildDesktopEditorLayout(isMobile, isSmallScreen),
    );
  }

  Widget _buildMobileEditorLayout(bool isMobile, bool isSmallScreen) {
    return Column(
      children: [
        if (_useIndividualContent) _buildMobileRecipientSelector(isMobile),
        const SizedBox(height: 8),
        Expanded(child: _buildEditorContainer(isMobile, isSmallScreen)),
      ],
    );
  }

  Widget _buildDesktopEditorLayout(bool isMobile, bool isSmallScreen) {
    return Row(
      children: [
        Expanded(
          flex: _useIndividualContent ? 3 : 1,
          child: _buildEditorContainer(isMobile, isSmallScreen),
        ),
        if (_useIndividualContent) ...[
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: _buildRecipientList(isMobile, isSmallScreen),
          ),
        ],
      ],
    );
  }

  Widget _buildMobileRecipientSelector(bool isMobile) {
    // Implementation for mobile recipient selector
    return Container(
      height: 60,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.borderPrimary),
      ),
      child: const Center(child: Text('Mobile Recipient Selector')),
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
          // Editor with toolbar
          Expanded(
            child: HtmlEditorWidget(
              controller: _getCurrentController(),
              focusNode: _getCurrentFocusNode(),
              placeholder: 'Wpisz treść swojego emaila...',
              padding: EdgeInsets.all(
                isMobile
                    ? 8
                    : isSmallScreen
                    ? 12
                    : 16,
              ),
              autoFocus: false,
              showToolbar: true,
              isMobile: isMobile,
              isSmallScreen: isSmallScreen,
              onChanged: _updatePreview,
            ),
          ),

          // Quick actions bar
          _buildQuickActionsBar(isMobile, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildQuickActionsBar(bool isMobile, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        border: Border(top: BorderSide(color: AppThemePro.borderPrimary)),
      ),
      child: Wrap(
        spacing: isSmallScreen ? 4 : 8,
        runSpacing: isSmallScreen ? 4 : 8,
        children: [
          ElevatedButton.icon(
            onPressed: _insertVoting,
            icon: const Icon(Icons.how_to_vote, size: 16),
            label: Text(isMobile ? 'Głosowanie' : 'Wstaw szablon głosowania'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 16,
                vertical: isMobile ? 4 : 8,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _insertInvestmentTable,
            icon: const Icon(Icons.table_chart, size: 16),
            label: Text(isMobile ? 'Tabela' : 'Wstaw tabelę inwestycji'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 16,
                vertical: isMobile ? 4 : 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientList(bool isMobile, bool isSmallScreen) {
    final enabledInvestors = widget.selectedInvestors
        .where((inv) => _recipientsService.recipientEnabled[inv.client.id] ?? false)
        .toList();
    
    final confirmedAdditionalEmails = _recipientsService.additionalEmails
        .where((email) => _recipientsService.additionalEmailsConfirmed[email] ?? false)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: AppThemePro.accentGold, size: 20),
              const SizedBox(width: 8),
              Text(
                'Odbiorcy emaili',
                style: TextStyle(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Investors section
          if (enabledInvestors.isNotEmpty) ...[
            Text(
              'Inwestorzy (${enabledInvestors.length}):',
              style: TextStyle(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...enabledInvestors.map((investor) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: AppThemePro.accentGold,
                    radius: 16,
                    child: Text(
                      investor.client.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    investor.client.name,
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    investor.client.email,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppThemePro.textSecondary,
                    ),
                  ),
                  trailing: Text(
                    '${investor.investments.length} inw.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppThemePro.textSecondary,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedRecipientForEditing = investor.client.id;
                    });
                  },
                ),
              );
            }).toList(),
          ],
          
          // Additional emails section
          if (confirmedAdditionalEmails.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Dodatkowe adresy (${confirmedAdditionalEmails.length}):',
              style: TextStyle(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...confirmedAdditionalEmails.map((email) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: AppThemePro.statusInfo,
                    radius: 16,
                    child: const Icon(
                      Icons.email,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    email,
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Dodatkowy odbiorca',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              );
            }).toList(),
          ],
          
          // Empty state
          if (enabledInvestors.isEmpty && confirmedAdditionalEmails.isEmpty) ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox,
                    size: 48,
                    color: AppThemePro.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Brak wybranych odbiorców',
                    style: TextStyle(
                      color: AppThemePro.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Przejdź do zakładki "Ustawienia"\naby wybrać odbiorców',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppThemePro.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsTab(bool isMobile, bool isSmallScreen) {
    final contentPadding = isMobile ? 12.0 : 24.0;

    return Padding(
      padding: EdgeInsets.all(contentPadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender Information Section
            _buildSectionHeader('Dane nadawcy', Icons.person),
            const SizedBox(height: 12),
            _buildSenderInfoSection(isMobile),

            const SizedBox(height: 24),

            // Subject Section
            _buildSectionHeader('Temat wiadomości', Icons.subject),
            const SizedBox(height: 12),
            _buildSubjectSection(isMobile),

            const SizedBox(height: 24),

            // Templates Section
            _buildSectionHeader('Szablony wiadomości', Icons.save),
            const SizedBox(height: 12),
            _buildTemplatesSection(),

            const SizedBox(height: 24),

            // Recipients Management Section
            _buildSectionHeader('Zarządzanie odbiorcami', Icons.group),
            const SizedBox(height: 12),
            _buildRecipientsManagementInSettings(),

            const SizedBox(height: 24),

            // Email Options Section
            _buildSectionHeader('Opcje wysyłania', Icons.settings),
            const SizedBox(height: 12),
            _buildEmailOptionsSection(),

            const SizedBox(height: 24),

            // Editor Formatting Section
            _buildSectionHeader('Formatowanie tekstu', Icons.format_paint),
            const SizedBox(height: 12),
            _buildFormattingSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppThemePro.accentGold, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: AppThemePro.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSenderInfoSection(bool isMobile) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _senderNameController,
                decoration: InputDecoration(
                  labelText: 'Nazwa nadawcy',
                  prefixIcon: Icon(
                    Icons.business,
                    color: AppThemePro.accentGold,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Nazwa nadawcy jest wymagana';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubjectSection(bool isMobile) {
    return TextFormField(
      controller: _subjectController,
      decoration: InputDecoration(
        labelText: 'Temat emaila',
        prefixIcon: Icon(Icons.title, color: AppThemePro.accentGold),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Temat emaila jest wymagany';
        }
        return null;
      },
    );
  }

  Widget _buildEmailOptionsSection() {
    return Column(
      children: [
        CheckboxListTile(
          title: const Text('Użyj indywidualnej treści dla każdego odbiorcy'),
          subtitle: const Text(
            'Pozwala na personalizację wiadomości dla każdego inwestora',
          ),
          value: _useIndividualContent,
          onChanged: (value) {
            setState(() {
              _useIndividualContent = value ?? false;
              if (_useIndividualContent) {
                _syncContentBetweenControllers();
              }
            });
          },
          activeColor: AppThemePro.accentGold,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildRecipientsManagementInSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipients list
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppThemePro.borderSecondary),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
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
                    Icon(Icons.people, color: AppThemePro.accentGold, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Odbiorcy (${_recipientsService.getEnabledRecipientsCount()})',
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Recipients list
              ...widget.selectedInvestors.map((investor) {
                final clientId = investor.client.id;
                final isEnabled =
                    _recipientsService.recipientEnabled[clientId] ?? false;
                final email =
                    _recipientsService.recipientEmails[clientId] ?? '';

                return ListTile(
                  leading: Checkbox(
                    value: isEnabled,
                    onChanged: (value) {
                      setState(() {
                        _recipientsService.toggleRecipient(
                          clientId,
                          value ?? false,
                        );
                      });
                    },
                    activeColor: AppThemePro.accentGold,
                  ),
                  title: Text(
                    investor.client.name,
                    style: TextStyle(
                      color: AppThemePro.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    email.isNotEmpty ? email : 'Brak emaila',
                    style: TextStyle(
                      color: email.isNotEmpty
                          ? AppThemePro.textSecondary
                          : AppThemePro.statusError,
                      fontSize: 12,
                    ),
                  ),
                  trailing: email.isNotEmpty
                      ? Icon(
                          Icons.email,
                          color: isEnabled
                              ? AppThemePro.statusSuccess
                              : AppThemePro.statusError,
                          size: 18,
                        )
                      : Icon(
                          Icons.error_outline,
                          color: AppThemePro.statusError,
                          size: 18,
                        ),
                );
              }).toList(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Additional emails section
        _buildAdditionalEmailsField(),
      ],
    );
  }

  Widget _buildAdditionalEmailsField() {
    final emailController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dodatkowe adresy email',
          style: TextStyle(
            color: AppThemePro.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Wprowadź dodatkowy adres email',
                  prefixIcon: Icon(
                    Icons.add_circle_outline,
                    color: AppThemePro.accentGold,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                onFieldSubmitted: (value) {
                  _addAdditionalEmail(value, emailController);
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                _addAdditionalEmail(emailController.text, emailController);
              },
              icon: Icon(Icons.add, color: AppThemePro.accentGold),
              tooltip: 'Dodaj email',
            ),
          ],
        ),
        if (_recipientsService.additionalEmails.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppThemePro.borderSecondary),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: _recipientsService.additionalEmails.map((email) {
                final isConfirmed =
                    _recipientsService.additionalEmailsConfirmed[email] ??
                    false;

                return ListTile(
                  leading: Checkbox(
                    value: isConfirmed,
                    onChanged: (value) {
                      setState(() {
                        _recipientsService.toggleAdditionalEmailConfirmation(
                          email,
                          value ?? false,
                        );
                      });
                    },
                    activeColor: AppThemePro.accentGold,
                  ),
                  title: Text(
                    email,
                    style: TextStyle(
                      color: AppThemePro.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  trailing: IconButton(
                    onPressed: () {
                      setState(() {
                        _recipientsService.removeAdditionalEmail(email);
                      });
                    },
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppThemePro.statusError,
                      size: 18,
                    ),
                    tooltip: 'Usuń email',
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  void _addAdditionalEmail(String email, TextEditingController controller) {
    if (_recipientsService.addAdditionalEmail(email)) {
      controller.clear();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Dodano email: $email'),
          backgroundColor: AppThemePro.statusSuccess,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Nieprawidłowy email lub już istnieje'),
          backgroundColor: AppThemePro.statusError,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Synchronizes content between controllers when switching modes
  void _syncContentBetweenControllers() async {
    if (_useIndividualContent) {
      // Copy main content to all individual controllers
      final mainContent = await _htmlController.getText();

      for (final investor in widget.selectedInvestors) {
        final clientId = investor.client.id;
        final controller = _individualControllers[clientId];
        if (controller != null) {
          controller.setText(mainContent);
        }
      }
    } else {
      // Copy first individual controller content back to main
      if (_selectedRecipientForEditing != null) {
        final individualController =
            _individualControllers[_selectedRecipientForEditing!];
        if (individualController != null) {
          final individualContent = await individualController.getText();
          _htmlController.setText(individualContent);
        }
      }
    }
  }

  Widget _buildPreviewTab(bool isMobile, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
      child: Column(
        children: [
          // Preview controls
          _buildPreviewControls(),

          const SizedBox(height: 16),

          // Preview content
          Expanded(child: _buildPreviewContent(isMobile, isSmallScreen)),
        ],
      ),
    );
  }

  Widget _buildPreviewControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.borderSecondary),
      ),
      child: Column(
        children: [
          // Recipient selector
          _buildPreviewRecipientSelector(),

          const SizedBox(height: 12),

          // View mode toggles
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'html',
                      label: Text('HTML'),
                      icon: Icon(Icons.code, size: 16),
                    ),
                    ButtonSegment(
                      value: 'text',
                      label: Text('Tekst'),
                      icon: Icon(Icons.text_fields, size: 16),
                    ),
                  ],
                  selected: {_previewMode},
                  onSelectionChanged: (Set<String> selection) {
                    setState(() {
                      _previewMode = selection.first;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  setState(() {
                    _previewDarkMode = !_previewDarkMode;
                  });
                },
                icon: Icon(
                  _previewDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: AppThemePro.accentGold,
                ),
                tooltip: _previewDarkMode ? 'Tryb jasny' : 'Tryb ciemny',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRecipientSelector() {
    // Get available recipients
    final availableRecipients = widget.selectedInvestors
        .where(
          (inv) => _recipientsService.recipientEnabled[inv.client.id] ?? false,
        )
        .toList();

    // Get confirmed additional emails
    final confirmedAdditionalEmails = _recipientsService.additionalEmails
        .where(
          (email) =>
              _recipientsService.additionalEmailsConfirmed[email] ?? false,
        )
        .toList();

    if (availableRecipients.isEmpty && confirmedAdditionalEmails.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppThemePro.statusWarning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppThemePro.statusWarning),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: AppThemePro.statusWarning, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Brak dostępnych odbiorców do podglądu',
                style: TextStyle(
                  color: AppThemePro.statusWarning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Build dropdown items for investors and additional emails
    List<DropdownMenuItem<String>> dropdownItems = [];

    // Add investors section
    if (availableRecipients.isNotEmpty) {
      dropdownItems.add(
        DropdownMenuItem<String>(
          enabled: false,
          child: Text(
            '--- INWESTORZY ---',
            style: TextStyle(
              color: AppThemePro.accentGold,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      );

      for (final investor in availableRecipients) {
        dropdownItems.add(
          DropdownMenuItem<String>(
            value: 'investor:${investor.client.id}',
            child: Text(
              '${investor.client.name} (${investor.client.email})',
              style: TextStyle(color: AppThemePro.textPrimary),
            ),
          ),
        );
      }
    }

    // Add additional emails section
    if (confirmedAdditionalEmails.isNotEmpty) {
      if (dropdownItems.isNotEmpty) {
        dropdownItems.add(
          DropdownMenuItem<String>(
            enabled: false,
            child: Text(
              '--- DODATKOWE EMAILE ---',
              style: TextStyle(
                color: AppThemePro.accentGold,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        );
      }

      for (final email in confirmedAdditionalEmails) {
        dropdownItems.add(
          DropdownMenuItem<String>(
            value: 'additional:$email',
            child: Text(
              email,
              style: TextStyle(color: AppThemePro.textPrimary),
            ),
          ),
        );
      }
    }

    // Ensure a default selection if none is set or the selected one is no longer valid
    final allValidIds = [
      ...availableRecipients.map((inv) => 'investor:${inv.client.id}'),
      ...confirmedAdditionalEmails.map((email) => 'additional:$email'),
    ];

    if (_selectedPreviewRecipient == null ||
        !allValidIds.contains(_selectedPreviewRecipient)) {
      _selectedPreviewRecipient = allValidIds.isNotEmpty
          ? allValidIds.first
          : null;
    }

    return Row(
      children: [
        Icon(Icons.preview, color: AppThemePro.accentGold, size: 20),
        const SizedBox(width: 8),
        Text(
          'Podgląd dla:',
          style: TextStyle(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedPreviewRecipient,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: dropdownItems,
            onChanged: (String? newValue) {
              setState(() {
                _selectedPreviewRecipient = newValue;
              });
            },
            isExpanded: true,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewContent(bool isMobile, bool isSmallScreen) {
    if (_selectedPreviewRecipient == null) {
      return Center(
        child: Text(
          'Wybierz odbiorcę do podglądu',
          style: TextStyle(color: AppThemePro.textSecondary, fontSize: 16),
        ),
      );
    }

    return FutureBuilder<String>(
      future: _getPreviewContent(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Błąd podczas generowania podglądu: ${snapshot.error}',
              style: TextStyle(color: AppThemePro.statusError),
            ),
          );
        }

        final content = snapshot.data ?? '';

        return Container(
          decoration: BoxDecoration(
            color: _previewDarkMode ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppThemePro.borderSecondary),
          ),
          child: _previewMode == 'html'
              ? _buildHtmlPreview(content)
              : _buildTextPreview(content),
        );
      },
    );
  }

  Widget _buildHtmlPreview(String htmlContent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: _previewDarkMode ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Html(
          data: htmlContent,
          style: {
            "body": Style(
              color: _previewDarkMode ? Colors.white : Colors.black,
              fontSize: FontSize(14),
              lineHeight: const LineHeight(1.5),
            ),
            "p": Style(
              margin: Margins.only(bottom: 8),
            ),
            "h1, h2, h3, h4, h5, h6": Style(
              margin: Margins.symmetric(vertical: 8),
            ),
            "table": Style(
              border: Border.all(color: Colors.grey),
            ),
            "th, td": Style(
              border: Border.all(color: Colors.grey),
              padding: HtmlPaddings.all(8),
            ),
          },
        ),
      ),
    );
  }

  Widget _buildTextPreview(String htmlContent) {
    // Simple HTML to text conversion
    String textContent = htmlContent
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        textContent,
        style: TextStyle(
          color: _previewDarkMode ? Colors.white : Colors.black,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }

  Future<String> _getPreviewContent() async {
    try {
      // Get current editor content
      final htmlContent = await _getCurrentController().getText();

      // Return content as-is since user controls investment details via editor buttons
      return htmlContent;
    } catch (e) {
      debugPrint('Error getting preview content: $e');
      return 'Błąd podczas generowania podglądu';
    }
  }

  // Helper methods
  HtmlEditorControllerWrapper _getCurrentController() {
    if (_useIndividualContent && _selectedRecipientForEditing != null) {
      return _individualControllers[_selectedRecipientForEditing]!;
    }
    return _htmlController;
  }

  FocusNode _getCurrentFocusNode() {
    if (_useIndividualContent && _selectedRecipientForEditing != null) {
      return _individualFocusNodes[_selectedRecipientForEditing]!;
    }
    return _editorFocusNode;
  }

  // Action methods
  void _insertVoting() {
    final votingTemplate = _editorService.generateVotingTemplate();
    _getCurrentController().insertHtml(votingTemplate);
  }

  void _insertInvestmentTable() {
    if (_selectedPreviewRecipient?.startsWith('investor:') == true) {
      final clientId = _selectedPreviewRecipient!.substring('investor:'.length);
      final investor = widget.selectedInvestors.firstWhere(
        (inv) => inv.client.id == clientId,
      );
      final tableHtml = _editorService.generateInvestorTableHtml(investor);
      _getCurrentController().insertHtml(tableHtml);
    } else {
      final tableHtml = _editorService.generateAggregatedTableHtml(
        widget.selectedInvestors,
      );
      _getCurrentController().insertHtml(tableHtml);
    }
  }

  void _clearEditor() {
    _getCurrentController().clear();
  }

  Future<void> _sendEmails() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Sprawdź poprawność danych w formularzu'),
          backgroundColor: AppThemePro.statusError,
        ),
      );
      return;
    }

    if (!_recipientsService.hasValidEmails()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Brak prawidłowych adresów email do wysyłki'),
          backgroundColor: AppThemePro.statusError,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _results = null;
    });

    try {
      // Get email content
      final htmlContent = await _htmlController.getText();

      // Prepare investor recipients
      final investorRecipients = widget.selectedInvestors
          .where(
            (investor) =>
                investor.client.email.isNotEmpty &&
                (_recipientsService.recipientEnabled[investor.client.id] ??
                    false),
          )
          .toList();

      // Get additional email addresses that are confirmed
      final additionalEmails = _recipientsService.additionalEmails
          .where(
            (email) =>
                _recipientsService.additionalEmailsConfirmed[email] ?? false,
          )
          .toList();

      final emailAndExportService = EmailAndExportService();
      List<EmailSendResult> results = [];

      // Use sendCustomEmailsToMixedRecipients for all sending
      if (investorRecipients.isNotEmpty || additionalEmails.isNotEmpty) {
        final emailResults = await emailAndExportService
            .sendCustomEmailsToMixedRecipients(
              investors: investorRecipients,
              additionalEmails: additionalEmails,
              subject: _subjectController.text.isNotEmpty
                  ? _subjectController.text
                  : 'Wiadomość od ${_senderNameController.text}',
              htmlContent: htmlContent,
              includeInvestmentDetails: false, // Removed - user controls via editor
              senderEmail: 'noreply@metropolitan-investment.com', // Default SMTP email
              senderName: _senderNameController.text.isNotEmpty
                  ? _senderNameController.text
                  : 'Metropolitan Investment',
            );

        results.addAll(emailResults);
      }

      if (kDebugMode) {
        print('📧 Email sending completed:');
        for (final result in results) {
          print(
            '   ${result.clientName} (${result.clientEmail}): ${result.success ? 'SUCCESS' : 'FAILED'}',
          );
          if (!result.success && result.error != null) {
            print('      Error: ${result.error}');
          }
        }
      }

      setState(() {
        _isLoading = false;
        _results = results;
      });

      // Show success/error summary
      final successful = results.where((r) => r.success).length;
      final failed = results.length - successful;

      if (failed == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Wszystkie emaile zostały wysłane pomyślnie ($successful)',
            ),
            backgroundColor: AppThemePro.statusSuccess,
          ),
        );
        widget.onEmailSent();
      } else if (successful == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Wszystkie emaile nie zostały wysłane ($failed błędów)',
            ),
            backgroundColor: AppThemePro.statusError,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Wysłano $successful emaili, $failed nie powiodło się',
            ),
            backgroundColor: AppThemePro.statusWarning,
          ),
        );
        widget.onEmailSent();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Błąd wysyłania: ${e.toString()}'),
          backgroundColor: AppThemePro.statusError,
        ),
      );

      if (kDebugMode) {
        print('📧 Critical email sending error: $e');
      }
    }
  }

  // Template management methods
  void _previewTemplate(EmailTemplateModel template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Podgląd szablonu: ${template.name}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Temat: ${template.subject}'),
              const SizedBox(height: 16),
              const Text('Treść:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppThemePro.borderSecondary),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Html(data: template.content),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zamknij'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applyTemplate(template);
            },
            child: const Text('Zastosuj'),
          ),
        ],
      ),
    );
  }

  void _applyTemplate(EmailTemplateModel template) {
    _subjectController.text = template.subject;
    
    // Use the enhanced white color styling method
    _htmlController.setTextWithWhiteDefault(template.content);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Zastosowano szablon: ${template.name}'),
        backgroundColor: AppThemePro.statusSuccess,
      ),
    );
  }

  void _editTemplate(EmailTemplateModel template) {
    _showTemplateDialog(template);
  }

  void _deleteTemplate(EmailTemplateModel template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń szablon'),
        content: Text('Czy na pewno chcesz usunąć szablon "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await _templatesService.deleteEmailTemplate(template.id);
              if (success) {
                _loadEmailTemplates();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Usunięto szablon: ${template.name}'),
                    backgroundColor: AppThemePro.statusSuccess,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Błąd podczas usuwania szablonu'),
                    backgroundColor: AppThemePro.statusError,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemePro.statusError,
            ),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }

  void _createNewTemplate() {
    _showTemplateDialog();
  }

  void _saveCurrentAsTemplate() async {
    final currentContent = await _htmlController.getText();
    
    // Ensure content has white color styling as default
    final styledContent = _ensureWhiteColorStyling(currentContent);
    
    final newTemplate = EmailTemplateModel(
      id: '',
      name: 'Szablon z ${DateTime.now().day}.${DateTime.now().month}',
      subject: _subjectController.text,
      content: styledContent,
      description: 'Zapisano z edytora',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'System',
    );
    
    _showTemplateDialog(newTemplate);
  }

  void _showTemplateDialog([EmailTemplateModel? template]) {
    final nameController = TextEditingController(text: template?.name ?? '');
    final subjectController = TextEditingController(text: template?.subject ?? _subjectController.text);
    final descriptionController = TextEditingController(text: template?.description ?? '');
    final contentController = TextEditingController(text: template?.content ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(template == null ? 'Nowy szablon' : 'Edytuj szablon'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nazwa szablonu',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Temat',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Opis (opcjonalny)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Treść HTML',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final newTemplate = EmailTemplateModel(
                  id: template?.id ?? '',
                  name: nameController.text,
                  subject: subjectController.text,
                  content: contentController.text,
                  description: descriptionController.text,
                  createdAt: template?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                  createdBy: template?.createdBy ?? 'System',
                );
                
                final success = await _templatesService.saveEmailTemplate(newTemplate);
                if (success) {
                  Navigator.of(context).pop();
                  _loadEmailTemplates();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Zapisano szablon: ${newTemplate.name}'),
                      backgroundColor: AppThemePro.statusSuccess,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Błąd podczas zapisywania szablonu'),
                      backgroundColor: AppThemePro.statusError,
                    ),
                  );
                }
              }
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  // Formatting methods
  void _showTextColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wybierz kolor tekstu'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedTextColor,
            onColorChanged: (color) {
              setState(() {
                _selectedTextColor = color;
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applyTextColor();
            },
            child: const Text('Zastosuj'),
          ),
        ],
      ),
    );
  }

  void _showBackgroundColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wybierz kolor tła'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColorPicker(
                pickerColor: _selectedBackgroundColor == Colors.transparent
                    ? Colors.white
                    : _selectedBackgroundColor,
                onColorChanged: (color) {
                  setState(() {
                    _selectedBackgroundColor = color;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedBackgroundColor = Colors.transparent;
                  });
                },
                child: const Text('Przezroczyste tło'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applyBackgroundColor();
            },
            child: const Text('Zastosuj'),
          ),
        ],
      ),
    );
  }

  void _applyTextColor() {
    final colorHex = '#${_selectedTextColor.value.toRadixString(16).substring(2)}';
    _getCurrentController().insertHtml(
      '<span style="color: $colorHex;">',
    );
  }

  void _applyBackgroundColor() {
    if (_selectedBackgroundColor == Colors.transparent) {
      _getCurrentController().insertHtml(
        '<span style="background-color: transparent;">',
      );
    } else {
      final colorHex = '#${_selectedBackgroundColor.value.toRadixString(16).substring(2)}';
      _getCurrentController().insertHtml(
        '<span style="background-color: $colorHex;">',
      );
    }
  }

  void _applyFontFamily(String fontFamily) {
    final fontValue = EnhancedEmailEditorService.customFontFamilies[fontFamily] ?? fontFamily;
    _getCurrentController().insertHtml(
      '<span style="font-family: $fontValue;">',
    );
  }

  void _applySelectedFormatting() {
    final colorHex = '#${_selectedTextColor.value.toRadixString(16).substring(2)}';
    final bgColorHex = _selectedBackgroundColor == Colors.transparent
        ? 'transparent'
        : '#${_selectedBackgroundColor.value.toRadixString(16).substring(2)}';
    final fontValue = EnhancedEmailEditorService.customFontFamilies[_selectedFontFamily] ?? _selectedFontFamily;
    
    _getCurrentController().insertHtml(
      '<div style="color: $colorHex; background-color: $bgColorHex; font-family: $fontValue;">',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Formatowanie zostało zastosowane'),
        backgroundColor: AppThemePro.statusSuccess,
      ),
    );
  }

  /// Ensures that content has white color as default styling
  String _ensureWhiteColorStyling(String content) {
    if (content.isEmpty) return content;
    
    // Check if content already has body or div wrapper with color styling
    if (content.contains('color:') && content.contains('white')) {
      return content;
    }
    
    // If no color styling, wrap content with white color default
    if (!content.contains('<body') && !content.contains('<div')) {
      return '''
      <div style="color: white; font-family: Arial, sans-serif; font-size: 14px;">
        $content
      </div>
      ''';
    }
    
    // If already has wrapper but no color, add white color to existing style
    if (content.contains('style=')) {
      return content.replaceFirst(
        RegExp(r'style="([^"]*)"'),
        'style="color: white; \$1"',
      );
    }
    
    return content;
  }
}
