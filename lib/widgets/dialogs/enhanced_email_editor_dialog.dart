import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
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

  // Debounce timer for preview updates to avoid rapid rebuilds
  Timer? _previewDebounceTimer;

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
      _individualControllers[clientId] = QuillController.basic();
      _individualFocusNodes[clientId] = FocusNode();
    }
    
    // Auto-select first available recipient for preview
    final availableRecipients = widget.selectedInvestors
        .where((inv) => _recipientEnabled[inv.client.id] ?? false)
        .toList();
    if (availableRecipients.isNotEmpty) {
      if (_selectedPreviewRecipient == null) {
        _selectedPreviewRecipient = availableRecipients.first.client.id;
      }
      if (_selectedRecipientForEditing == null) {
        _selectedRecipientForEditing = availableRecipients.first.client.id;
      }
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
  }

  @override
  void dispose() {
    _quillController.removeListener(_updatePreview);
    _previewDebounceTimer?.cancel();
    _tabController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _senderEmailController.dispose();
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
        // Mobile: recipient list as dropdown or expandable section
        if (_useIndividualContent) ...[
          _buildMobileRecipientSelector(isMobile),
          SizedBox(height: isMobile ? 8 : 12),
        ],
        
        // Editor takes full width on mobile
        Expanded(
          child: _buildEditorContainer(isMobile, isSmallScreen),
        ),
      ],
    );
  }

  Widget _buildDesktopEditorLayout(bool isMobile, bool isSmallScreen) {
    return Row(
      children: [
        // Left sidebar - recipient list (when in individual mode)
        if (_useIndividualContent) ...[
          Container(
            width: 250,
            decoration: BoxDecoration(
              border: Border.all(color: AppThemePro.borderSecondary),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildRecipientList(isMobile, isSmallScreen),
          ),
          const SizedBox(width: 16),
        ],
        
        // Main editor area
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

    final selectedInvestor = _selectedRecipientForEditing != null
        ? widget.selectedInvestors.firstWhere(
            (inv) => inv.client.id == _selectedRecipientForEditing,
            orElse: () => widget.selectedInvestors.first,
          )
        : widget.selectedInvestors.first;

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
                  // Font options - enabled for enhanced customization
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

          Container(height: 1, color: AppThemePro.borderPrimary),

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
    // Convert the current editor (global) delta to HTML and display it verbatim.
    final converter = QuillDeltaToHtmlConverter(
      _quillController.document.toDelta().toJson(),
      ConverterOptions.forEmail(),
    );

    // Raw HTML coming directly from the editor -> shown in preview exactly as it will be sent.
    final rawEditorHtml = converter.convert();
    
    // Process HTML to replace investment table markers with actual HTML tables
    // The processing depends on the selected recipient type
    String processedHtml;
    
    if (_selectedPreviewRecipient?.startsWith('investor:') == true) {
      // For investors, show personalized content with their investment data
      final investorId = _selectedPreviewRecipient!.substring('investor:'.length);
      final investor = widget.selectedInvestors.firstWhere(
        (inv) => inv.client.id == investorId,
        orElse: () => widget.selectedInvestors.first,
      );
      
      processedHtml = _processInvestmentTableMarkersForInvestor(rawEditorHtml, investor);
    } else if (_selectedPreviewRecipient?.startsWith('additional:') == true) {
      // For additional emails, show aggregated content for all enabled investors
      final enabledInvestors = widget.selectedInvestors
          .where((inv) => _recipientEnabled[inv.client.id] ?? false)
          .toList();
      
      processedHtml = _processInvestmentTableMarkersForAggregated(rawEditorHtml, enabledInvestors);
    } else {
      // Fallback: just process tables generically
      processedHtml = _processInvestmentTableMarkers(rawEditorHtml);
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
                      margin: html.Margins.all(0),
                      padding: html.HtmlPaddings.all(16),
                    ),
                    // Remove global font family override to respect individual element styles
                    "p": html.Style(
                      margin: html.Margins.symmetric(vertical: 8),
                    ),
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
    
    /* Enhanced formatting support for rich text */
    .email-content span[style*="color"] {
      /* Preserve inline color styles from Quill */
    }
    .email-content span[style*="background-color"] {
      /* Preserve inline background colors from Quill */
    }
    .email-content span[style*="font-family"] {
      /* Preserve inline font family from Quill */
    }
    .email-content span[style*="font-size"] {
      /* Preserve inline font size from Quill */
    }
    
    /* Enhanced text formatting */
    .email-content s {
      text-decoration: line-through;
    }
    .email-content sup {
      vertical-align: super;
      font-size: smaller;
    }
    .email-content sub {
      vertical-align: sub;
      font-size: smaller;
    }
    .email-content code {
      background-color: ${darkMode ? '#3a3a3a' : '#f1f1f1'};
      padding: 2px 4px;
      border-radius: 3px;
      font-family: 'Courier New', monospace;
      font-size: 0.9em;
      color: ${darkMode ? '#e0e0e0' : '#c7254e'};
    }
    .email-content pre {
      background-color: ${darkMode ? '#2a2a2a' : '#f8f8f8'};
      padding: 16px;
      border-radius: 8px;
      overflow-x: auto;
      border: 1px solid ${darkMode ? '#444444' : '#ddd'};
      white-space: pre-wrap;
    }
    .email-content pre code {
      background: none;
      padding: 0;
      border-radius: 0;
      color: inherit;
    }
    
    /* Enhanced list styling */
    .email-content ul[style*="list-style: none"] li {
      padding: 4px 0;
    }
    
    /* Link styling */
    .email-content a {
      color: #d4af37;
      text-decoration: none;
      font-weight: 500;
      border-bottom: 1px solid transparent;
      transition: border-bottom-color 0.2s;
    }
    .email-content a:hover {
      border-bottom-color: #d4af37;
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

      final selectedRecipients = widget.selectedInvestors
          .where((inv) => _recipientEnabled[inv.client.id] ?? false)
          .toList();

      _totalEmailsToSend = selectedRecipients.length + _additionalEmails.length;
      _currentEmailIndex = 0;

      // Build a raw HTML map per-recipient using the editor's content
      Map<String, String>? completeEmailHtmlByClient;
      String? aggregatedEmailHtmlForAdditionals;
      String processedHtml = '';

      if (selectedRecipients.isNotEmpty) {
        completeEmailHtmlByClient = <String, String>{};

        for (final investor in selectedRecipients) {
          // Choose controller (individual or global)
          final controllerToUse = (_useIndividualContent && _individualControllers.containsKey(investor.client.id))
              ? _individualControllers[investor.client.id]! : _quillController;

          // Convert editor delta to raw HTML
          final converter = QuillDeltaToHtmlConverter(
            controllerToUse.document.toDelta().toJson(),
            ConverterOptions.forEmail(),
          );
          final rawHtmlContent = converter.convert();
          
          // Process HTML to replace investment table markers with actual HTML tables
          final investorSpecificHtml = _processInvestmentTableMarkersForInvestor(rawHtmlContent, investor);

          completeEmailHtmlByClient[investor.client.id] = investorSpecificHtml;

          if (kDebugMode) {
            print('📋 [EmailDialog] Processed HTML for ${investor.client.name} (${investor.client.id}): ${investorSpecificHtml.length} chars');
            print('📋 [EmailDialog] First 500 chars: ${investorSpecificHtml.substring(0, math.min(500, investorSpecificHtml.length))}');
          }
        }
      }

      // Convert main content for preview and additional emails
      final converter = QuillDeltaToHtmlConverter(
        _quillController.document.toDelta().toJson(),
        ConverterOptions.forEmail(),
      );
      final rawHtml = converter.convert();
      
      // Process HTML to replace investment table markers with actual HTML tables
      processedHtml = _processInvestmentTableMarkers(rawHtml);

      // Generate aggregated email HTML for additional recipients if needed
      if (_additionalEmails.isNotEmpty) {
        // For additional emails, process with aggregated investor data
        aggregatedEmailHtmlForAdditionals = _processInvestmentTableMarkersForAggregated(processedHtml, selectedRecipients);

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
          completeEmailHtmlByClient!.forEach((clientId, html) {
            print('     - $clientId: ${html.length} chars');
          });
        }
      }

      final results = await _emailAndExportService.sendCustomEmailsToMixedRecipients(
        investors: selectedRecipients,
        additionalEmails: _additionalEmails,
        subject: _subjectController.text,
        htmlContent: processedHtml, // Send the processed HTML that includes investment tables
        includeInvestmentDetails: _includeInvestmentDetails,
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

  /// Insert greeting template
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
      debugPrint('Error inserting greeting: $e');
    }
  }

  /// Insert signature template
  void _insertSignature() {
    try {
      final selection = _quillController.selection;
      const signature = '\n\nZ poważaniem,\nZespół Metropolitan Investment\n\nTel: +48 XXX XXX XXX\nEmail: kontakt@metropolitan-investment.pl\nwww.metropolitan-investment.pl\n';
      
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
      debugPrint('Error inserting signature: $e');
    }
  }

  /// Build a simple HTML table summarizing investments for the selected recipients.
  /// The Email service will embed this HTML into the final themed template.
  String _buildInvestmentsSummaryHtml(List<InvestorSummary> recipients) {
    // Build a generic table showing client name, number of investments and total remaining capital.
    final buffer = StringBuffer();
    buffer.writeln('<h3>Podsumowanie Inwestycji</h3>');
    buffer.writeln('<table style="width:100%; border-collapse: collapse;">');
    buffer.writeln('<thead>');
    buffer.writeln('<tr>');
    buffer.writeln('<th style="text-align:left; padding:8px; border-bottom:1px solid #ddd;">Klient</th>');
    buffer.writeln('<th style="text-align:right; padding:8px; border-bottom:1px solid #ddd;">Liczba inwestycji</th>');
    buffer.writeln('<th style="text-align:right; padding:8px; border-bottom:1px solid #ddd;">Kapitał pozostały</th>');
    buffer.writeln('</tr>');
    buffer.writeln('</thead>');
    buffer.writeln('<tbody>');

    for (final inv in recipients) {
      final name = inv.client.name.replaceAllMapped(RegExp(r'[<>]'), (m) => '');
  final count = inv.investmentCount;
  final total = inv.totalRemainingCapital.toStringAsFixed(2);

      buffer.writeln('<tr>');
      buffer.writeln('<td style="padding:8px; border-bottom:1px solid #f0f0f0;">$name</td>');
      buffer.writeln('<td style="padding:8px; text-align:right; border-bottom:1px solid #f0f0f0;">$count</td>');
      buffer.writeln('<td style="padding:8px; text-align:right; border-bottom:1px solid #f0f0f0;">$total</td>');
      buffer.writeln('</tr>');
    }

    buffer.writeln('</tbody>');
    buffer.writeln('</table>');
    return buffer.toString();
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

  /// Buduje szczegółową tabelę HTML z inwestycjami dla konkretnego inwestora
  String _buildDetailedInvestmentsTableHtml(InvestorSummary investor) {
    if (kDebugMode) {
      print('📋 [EmailDialog] Generuję tabelę dla ${investor.client.name}, inwestycji: ${investor.investments.length}');
    }
    final buffer = StringBuffer();
    buffer.writeln('<div class="investment-summary" style="margin-top: 24px; padding: 20px; background-color: #f8f9fa; border-radius: 8px; border-left: 4px solid #d4af37;">');
    buffer.writeln('<h3 style="color: #d4af37; margin-bottom: 16px; font-size: 18px;">📊 Twój portfel inwestycyjny</h3>');
    
    // Podsumowanie numeryczne
    buffer.writeln('<div style="margin-bottom: 20px; display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 12px;">');
    buffer.writeln('<div style="background: white; padding: 12px; border-radius: 6px; border: 1px solid #e9ecef;">');
    buffer.writeln('<div style="font-size: 14px; color: #6c757d; margin-bottom: 4px;">Liczba inwestycji</div>');
    buffer.writeln('<div style="font-size: 18px; font-weight: bold; color: #2c2c2c;">${investor.investmentCount}</div>');
    buffer.writeln('</div>');
    
    buffer.writeln('<div style="background: white; padding: 12px; border-radius: 6px; border: 1px solid #e9ecef;">');
    buffer.writeln('<div style="font-size: 14px; color: #6c757d; margin-bottom: 4px;">Kapitał pozostały</div>');
    buffer.writeln('<div style="font-size: 18px; font-weight: bold; color: #28a745;">${_formatCurrency(investor.totalRemainingCapital)}</div>');
    buffer.writeln('</div>');
    
    buffer.writeln('<div style="background: white; padding: 12px; border-radius: 6px; border: 1px solid #e9ecef;">');
    buffer.writeln('<div style="font-size: 14px; color: #6c757d; margin-bottom: 4px;">Całkowita wartość</div>');
    buffer.writeln('<div style="font-size: 18px; font-weight: bold; color: #d4af37;">${_formatCurrency(investor.totalInvestmentAmount)}</div>');
    buffer.writeln('</div>');
    buffer.writeln('</div>');
    
    // Tabela szczegółowa inwestycji
    if (investor.investments.isNotEmpty) {
      buffer.writeln('<h4 style="color: #2c2c2c; margin: 20px 0 12px 0; font-size: 16px;">📋 Szczegóły inwestycji</h4>');
      buffer.writeln('<table style="width: 100%; border-collapse: collapse; margin-bottom: 16px; background: white; border-radius: 6px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">');
      
      // Nagłówki tabeli
      buffer.writeln('<thead>');
      buffer.writeln('<tr style="background: #2c2c2c; color: white;">');
      buffer.writeln('<th style="text-align: left; padding: 12px; font-weight: 600; font-size: 14px;">Produkt</th>');
      buffer.writeln('<th style="text-align: right; padding: 12px; font-weight: 600; font-size: 14px;">Kwota inwest.</th>');
      buffer.writeln('<th style="text-align: right; padding: 12px; font-weight: 600; font-size: 14px;">Kapitał pozostały</th>');
      buffer.writeln('<th style="text-align: right; padding: 12px; font-weight: 600; font-size: 14px;">Kapitał zabezp.</th>');
      buffer.writeln('<th style="text-align: center; padding: 12px; font-weight: 600; font-size: 14px;">Status</th>');
      buffer.writeln('</tr>');
      buffer.writeln('</thead>');
      
      // Wiersze z inwestycjami
      buffer.writeln('<tbody>');
      for (int i = 0; i < investor.investments.length; i++) {
        final investment = investor.investments[i];
        final isOdd = i % 2 == 1;
        final bgColor = isOdd ? '#f8f9fa' : 'white';
        
        buffer.writeln('<tr style="background-color: $bgColor;">');
        buffer.writeln('<td style="padding: 10px 12px; border-bottom: 1px solid #e9ecef; font-weight: 500;">${_sanitizeHtml(investment.productName)}</td>');
        buffer.writeln('<td style="padding: 10px 12px; text-align: right; border-bottom: 1px solid #e9ecef;">${_formatCurrency(investment.investmentAmount)}</td>');
        buffer.writeln('<td style="padding: 10px 12px; text-align: right; border-bottom: 1px solid #e9ecef; color: #28a745; font-weight: 600;">${_formatCurrency(investment.remainingCapital)}</td>');
        buffer.writeln('<td style="padding: 10px 12px; text-align: right; border-bottom: 1px solid #e9ecef;">${_formatCurrency(investment.capitalSecuredByRealEstate)}</td>');
        
        // Status z kolorkiem
        final status = investment.status.displayName;
        final statusColor = status.toLowerCase().contains('aktywny') ? '#28a745' : 
                           status.toLowerCase().contains('zakończony') ? '#6c757d' : '#ffc107';
        buffer.writeln('<td style="padding: 10px 12px; text-align: center; border-bottom: 1px solid #e9ecef;">');
        buffer.writeln('<span style="background: $statusColor; color: white; padding: 4px 8px; border-radius: 12px; font-size: 12px; font-weight: 600;">$status</span>');
        buffer.writeln('</td>');
        buffer.writeln('</tr>');
      }
      buffer.writeln('</tbody>');
      buffer.writeln('</table>');
    }
    
    // Informacje dodatkowe
    buffer.writeln('<div style="margin-top: 16px; padding: 12px; background: #e7f3ff; border-radius: 6px; border-left: 3px solid #0066cc;">');
    buffer.writeln('<p style="margin: 0; font-size: 14px; color: #495057;"><strong>💡 Ważne:</strong> Powyższe dane prezentują aktualny stan Twojego portfela na dzień ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}.</p>');
    buffer.writeln('</div>');
    
    buffer.writeln('</div>');
    return buffer.toString();
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

  /// Formatuje kwotę jako walutę polską
  String _formatCurrency(double amount) {
    if (amount == 0) return '0,00 zł';
    return '${amount.toStringAsFixed(2).replaceAll('.', ',')} zł';
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
    return Container(
      padding: const EdgeInsets.all(16),
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
          if (_useIndividualContent) ...[
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
            itemCount: availableRecipients.length + (_additionalEmails.length > 0 ? _additionalEmails.length + 1 : 0),
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
    
    // Table headers
    final headers = ['Nazwa produktu', 'Kwota inwestycji', 'Kapitał pozostały', 'Kapitał zabezpieczony', 'Kapitał do restrukturyzacji', 'Wierzyciel'];
    final headerRow = headers.join(' | ') + '\n';
    final separatorRow = '-' * 100 + '\n';
    
    controller.document.insert(currentIndex, headerRow);
    controller.formatText(currentIndex, headerRow.length - 1, Attribute.bold);
    currentIndex += headerRow.length;
    
    controller.document.insert(currentIndex, separatorRow);
    currentIndex += separatorRow.length;
    
    // Investment rows
    double totalInvestmentAmount = 0;
    double totalRemainingCapital = 0;
    double totalCapitalSecured = 0;
    double totalCapitalForRestructuring = 0;
    
    for (final inv in investments) {
      totalInvestmentAmount += inv.investmentAmount;
      totalRemainingCapital += inv.remainingCapital;
      totalCapitalSecured += inv.capitalSecuredByRealEstate;
      totalCapitalForRestructuring += inv.capitalForRestructuring;
      
      final rowData = [
        inv.productName,
        _formatCurrency(inv.investmentAmount),
        _formatCurrency(inv.remainingCapital),
        _formatCurrency(inv.capitalSecuredByRealEstate),
        _formatCurrency(inv.capitalForRestructuring),
        inv.creditorCompany
      ];
      
      final row = rowData.join(' | ') + '\n';
      controller.document.insert(currentIndex, row);
      currentIndex += row.length;
    }
    
    // Total row
    final totalRowData = [
      'RAZEM',
      _formatCurrency(totalInvestmentAmount),
      _formatCurrency(totalRemainingCapital),
      _formatCurrency(totalCapitalSecured),
      _formatCurrency(totalCapitalForRestructuring),
      ''
    ];
    
    final totalRow = totalRowData.join(' | ') + '\n\n';
    controller.document.insert(currentIndex, totalRow);
    controller.formatText(currentIndex, totalRow.length - 1, Attribute.bold);
  }

  /// Insert formatted aggregated table
  void _insertFormattedAggregatedTable(QuillController controller, int index, List<InvestorSummary> recipients) {
    int currentIndex = index;
    
    // Table headers
    final headers = ['Klient', 'Liczba inwestycji', 'Kapitał pozostały', 'Kapitał zabezpieczony', 'Kapitał do restrukturyzacji'];
    final headerRow = headers.join(' | ') + '\n';
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
      
      final row = rowData.join(' | ') + '\n';
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
    
    final totalRow = totalRowData.join(' | ') + '\n\n';
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

  /// Builds HTML table for aggregated investors data
  String _buildHtmlAggregatedTable(List<InvestorSummary> recipients) {
    final buffer = StringBuffer();
    
    // Table header
    buffer.writeln('<br><h3>Zbiorcze podsumowanie inwestycji</h3>');
    buffer.writeln('<table style="border-collapse: collapse; width: 100%; margin: 10px 0; font-family: Arial, sans-serif;">');
    buffer.writeln('<thead>');
    buffer.writeln('<tr style="background-color: #2a2a2a; color: #ffd700;">');
    buffer.writeln('<th style="border: 1px solid #666; padding: 8px; text-align: left;">Klient</th>');
    buffer.writeln('<th style="border: 1px solid #666; padding: 8px; text-align: right;">Liczba inwestycji</th>');
    buffer.writeln('<th style="border: 1px solid #666; padding: 8px; text-align: right;">Kapitał pozostały</th>');
    buffer.writeln('<th style="border: 1px solid #666; padding: 8px; text-align: right;">Kapitał zabezpieczony</th>');
    buffer.writeln('<th style="border: 1px solid #666; padding: 8px; text-align: right;">Kapitał do restrukturyzacji</th>');
    buffer.writeln('</tr>');
    buffer.writeln('</thead>');
    buffer.writeln('<tbody>');
    
    double totalCapitalRemaining = 0;
    double totalCapitalSecured = 0;
    double totalCapitalForRestructuring = 0;
    int totalInvestmentCount = 0;
    
    // Table rows
    for (final inv in recipients) {
      totalCapitalRemaining += inv.totalRemainingCapital;
      totalCapitalSecured += inv.capitalSecuredByRealEstate;
      totalCapitalForRestructuring += inv.capitalForRestructuring;
      totalInvestmentCount += inv.investmentCount;
      
      buffer.writeln('<tr style="background-color: #3a3a3a; color: #ffffff;">');
      buffer.writeln('<td style="border: 1px solid #666; padding: 8px;">${inv.client.name}</td>');
      buffer.writeln('<td style="border: 1px solid #666; padding: 8px; text-align: right;">${inv.investmentCount}</td>');
      buffer.writeln('<td style="border: 1px solid #666; padding: 8px; text-align: right;">${_formatCurrency(inv.totalRemainingCapital)}</td>');
      buffer.writeln('<td style="border: 1px solid #666; padding: 8px; text-align: right;">${_formatCurrency(inv.capitalSecuredByRealEstate)}</td>');
      buffer.writeln('<td style="border: 1px solid #666; padding: 8px; text-align: right;">${_formatCurrency(inv.capitalForRestructuring)}</td>');
      buffer.writeln('</tr>');
    }
    
    // Total row
    buffer.writeln('<tr style="background-color: #4a4a4a; color: #ffd700; font-weight: bold;">');
    buffer.writeln('<td style="border: 1px solid #666; padding: 8px;">RAZEM</td>');
    buffer.writeln('<td style="border: 1px solid #666; padding: 8px; text-align: right;">$totalInvestmentCount</td>');
    buffer.writeln('<td style="border: 1px solid #666; padding: 8px; text-align: right;">${_formatCurrency(totalCapitalRemaining)}</td>');
    buffer.writeln('<td style="border: 1px solid #666; padding: 8px; text-align: right;">${_formatCurrency(totalCapitalSecured)}</td>');
    buffer.writeln('<td style="border: 1px solid #666; padding: 8px; text-align: right;">${_formatCurrency(totalCapitalForRestructuring)}</td>');
    buffer.writeln('</tr>');
    
    buffer.writeln('</tbody>');
    buffer.writeln('</table><br>');
    return buffer.toString();
  }

  String _buildPlainTextInvestmentsTableForInvestor(InvestorSummary investor) {
    final buffer = StringBuffer();
    buffer.writeln('\n----- Szczegółowe inwestycje: ${investor.client.name} -----\n');
    buffer.writeln('Nazwa produktu | Kwota inwestycji | Kapitał pozostały | Kapitał zabezpieczony | Kapitał do restrukturyzacji | Wierzyciel');
    buffer.writeln('---------------------------------------------');
    
    double totalInvestmentAmount = 0;
    double totalRemainingCapital = 0;
    double totalCapitalSecured = 0;
    double totalCapitalForRestructuring = 0;
    
    for (final inv in investor.investments) {
      totalInvestmentAmount += inv.investmentAmount;
      totalRemainingCapital += inv.remainingCapital;
      totalCapitalSecured += inv.capitalSecuredByRealEstate;
      totalCapitalForRestructuring += inv.capitalForRestructuring;
      
      buffer.writeln('${inv.productName} | ${_formatCurrency(inv.investmentAmount)} | ${_formatCurrency(inv.remainingCapital)} | ${_formatCurrency(inv.capitalSecuredByRealEstate)} | ${_formatCurrency(inv.capitalForRestructuring)} | ${inv.creditorCompany}');
    }
    
    buffer.writeln('RAZEM | ${_formatCurrency(totalInvestmentAmount)} | ${_formatCurrency(totalRemainingCapital)} | ${_formatCurrency(totalCapitalSecured)} | ${_formatCurrency(totalCapitalForRestructuring)} | ');
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

  /// Processes HTML content to replace plain text tables with HTML tables
  String _processInvestmentTableMarkers(String html) {
    if (kDebugMode) {
      print('🔄 [EmailDialog] Processing HTML for table conversion (${html.length} chars)');
      print('🔍 [EmailDialog] HTML content preview: ${html.substring(0, math.min(500, html.length))}...');
    }
    
    // Pattern 1: Individual investor tables (updated for new detailed format)
    final individualTablePattern = RegExp(
      r'----- Szczegółowe inwestycje: (.+?) -----\s*\n\s*Nazwa produktu \| Kwota inwestycji \| Kapitał pozostały \| Kapitał zabezpieczony \| Kapitał do restrukturyzacji \| Wierzyciel\s*\n\s*-+\s*\n((?:(?!RAZEM).+\n)*?)RAZEM \| (.+?)\n',
      multiLine: true,
    );
    
    html = html.replaceAllMapped(individualTablePattern, (match) {
      final investorName = match.group(1)?.trim() ?? '';
      final tableRows = match.group(2)?.trim() ?? '';
      final totalRow = match.group(3)?.trim() ?? '';
      
      if (kDebugMode) {
        print('🔄 [EmailDialog] Converting detailed individual table for: $investorName');
        print('🔍 [EmailDialog] Table rows: $tableRows');
        print('🔍 [EmailDialog] Total row: $totalRow');
      }
      
      return _convertDetailedPlainTextTableToHtml(investorName, tableRows, totalRow);
    });
    
    // Pattern 2: Aggregated tables (updated for new detailed format)
    final aggregatedTablePattern = RegExp(
      r'----- Zbiorcze podsumowanie inwestycji -----\s*\n\s*Klient \| Liczba inwestycji \| Kapitał pozostały \| Kapitał zabezpieczony \| Kapitał do restrukturyzacji\s*\n\s*-+\s*\n((?:(?!RAZEM).+\n)*?)RAZEM \| (.+?)\n',
      multiLine: true,
    );
    
    html = html.replaceAllMapped(aggregatedTablePattern, (match) {
      final tableRows = match.group(1)?.trim() ?? '';
      final totalRow = match.group(2)?.trim() ?? '';
      
      if (kDebugMode) {
        print('🔄 [EmailDialog] Converting detailed aggregated table');
        print('🔍 [EmailDialog] Table rows: $tableRows');
        print('🔍 [EmailDialog] Total row: $totalRow');
      }
      
      return _convertDetailedAggregatedTableToHtml(tableRows, totalRow);
    });
    
    if (kDebugMode) {
      print('🔄 [EmailDialog] Processing complete. Final HTML length: ${html.length}');
    }
    
    return html;
  }
  
  /// Converts plain text table to HTML table
  String _convertPlainTextTableToHtml(String title, String tableRows, String total, {required bool isIndividual}) {
    final buffer = StringBuffer();
    
    // Start HTML table structure
    buffer.writeln('<div class="investment-summary" style="margin: 20px 0; padding: 20px; background-color: #f8f9fa; border-radius: 8px; border-left: 4px solid #d4af37;">');
    buffer.writeln('<h3 style="color: #d4af37; margin-bottom: 16px;">📊 ${isIndividual ? 'Inwestycje: $title' : title}</h3>');
    
    // Create HTML table
    buffer.writeln('<table style="width: 100%; border-collapse: collapse; background: white; border-radius: 6px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">');
    
    // Table headers
    if (isIndividual) {
      buffer.writeln('<thead><tr style="background: #2c2c2c; color: white;">');
      buffer.writeln('<th style="text-align: left; padding: 12px; font-weight: 600;">Nazwa</th>');
      buffer.writeln('<th style="text-align: right; padding: 12px; font-weight: 600;">Pozostały kapitał</th>');
      buffer.writeln('<th style="text-align: left; padding: 12px; font-weight: 600;">Wierzyciel</th>');
      buffer.writeln('</tr></thead>');
    } else {
      buffer.writeln('<thead><tr style="background: #2c2c2c; color: white;">');
      buffer.writeln('<th style="text-align: left; padding: 12px; font-weight: 600;">Klient</th>');
      buffer.writeln('<th style="text-align: center; padding: 12px; font-weight: 600;">Liczba inwestycji</th>');
      buffer.writeln('<th style="text-align: right; padding: 12px; font-weight: 600;">Kapitał pozostały</th>');
      buffer.writeln('</tr></thead>');
    }
    
    // Table body
    buffer.writeln('<tbody>');
    final rows = tableRows.split('\n').where((row) => row.trim().isNotEmpty);
    for (int i = 0; i < rows.length; i++) {
      final row = rows.elementAt(i);
      final columns = row.split('|').map((col) => col.trim()).toList();
      
      if (columns.length >= 2) {
        final bgColor = i % 2 == 0 ? 'white' : '#f8f9fa';
        buffer.writeln('<tr style="background-color: $bgColor;">');
        
        for (int j = 0; j < columns.length; j++) {
          final align = (isIndividual && j == 1) || (!isIndividual && j == 2) ? 'right' : 
                       (!isIndividual && j == 1) ? 'center' : 'left';
          buffer.writeln('<td style="padding: 10px 12px; border-bottom: 1px solid #e9ecef; text-align: $align;">${columns[j]}</td>');
        }
        
        buffer.writeln('</tr>');
      }
    }
    buffer.writeln('</tbody>');
    
    // Total row if available
    if (total.isNotEmpty && isIndividual) {
      buffer.writeln('<tfoot><tr style="background: #d4af37; color: white; font-weight: bold;">');
      buffer.writeln('<td style="padding: 12px; border: none;">RAZEM</td>');
      buffer.writeln('<td style="padding: 12px; border: none; text-align: right;">$total</td>');
      buffer.writeln('<td style="padding: 12px; border: none;"></td>');
      buffer.writeln('</tr></tfoot>');
    }
    
    buffer.writeln('</table>');
    buffer.writeln('</div>');
    
    return buffer.toString();
  }
  
  /// Converts detailed plain text table to HTML table (for individual investor detailed tables)
  String _convertDetailedPlainTextTableToHtml(String investorName, String tableRows, String totalRow) {
    final buffer = StringBuffer();
    
    // Start HTML table structure
    buffer.writeln('<div class="investment-summary" style="margin: 20px 0; padding: 20px; background-color: #f8f9fa; border-radius: 8px; border-left: 4px solid #d4af37;">');
    buffer.writeln('<h3 style="color: #d4af37; margin-bottom: 16px;">📊 Szczegółowe inwestycje: $investorName</h3>');
    
    // Create HTML table
    buffer.writeln('<table style="width: 100%; border-collapse: collapse; background: white; border-radius: 6px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">');
    
    // Table headers for detailed view
    buffer.writeln('<thead><tr style="background: #2c2c2c; color: white;">');
    buffer.writeln('<th style="text-align: left; padding: 8px; font-weight: 600; font-size: 12px;">Nazwa produktu</th>');
    buffer.writeln('<th style="text-align: right; padding: 8px; font-weight: 600; font-size: 12px;">Kwota inwestycji</th>');
    buffer.writeln('<th style="text-align: right; padding: 8px; font-weight: 600; font-size: 12px;">Kapitał pozostały</th>');
    buffer.writeln('<th style="text-align: right; padding: 8px; font-weight: 600; font-size: 12px;">Kapitał zabezpieczony</th>');
    buffer.writeln('<th style="text-align: right; padding: 8px; font-weight: 600; font-size: 12px;">Kapitał do restrukturyzacji</th>');
    buffer.writeln('<th style="text-align: left; padding: 8px; font-weight: 600; font-size: 12px;">Wierzyciel</th>');
    buffer.writeln('</tr></thead>');
    
    // Table body
    buffer.writeln('<tbody>');
    final rows = tableRows.split('\n').where((row) => row.trim().isNotEmpty);
    for (int i = 0; i < rows.length; i++) {
      final row = rows.elementAt(i);
      final columns = row.split('|').map((col) => col.trim()).toList();
      
      if (columns.length >= 6) {
        final bgColor = i % 2 == 0 ? 'white' : '#f8f9fa';
        buffer.writeln('<tr style="background-color: $bgColor;">');
        
        // Product name (left)
        buffer.writeln('<td style="padding: 8px; border-bottom: 1px solid #e9ecef; text-align: left; font-size: 12px;">${columns[0]}</td>');
        // Investment amount (right)
        buffer.writeln('<td style="padding: 8px; border-bottom: 1px solid #e9ecef; text-align: right; font-size: 12px; font-weight: 500;">${columns[1]}</td>');
        // Remaining capital (right)
        buffer.writeln('<td style="padding: 8px; border-bottom: 1px solid #e9ecef; text-align: right; font-size: 12px; font-weight: 500;">${columns[2]}</td>');
        // Secured capital (right)
        buffer.writeln('<td style="padding: 8px; border-bottom: 1px solid #e9ecef; text-align: right; font-size: 12px; font-weight: 500;">${columns[3]}</td>');
        // Capital for restructuring (right)
        buffer.writeln('<td style="padding: 8px; border-bottom: 1px solid #e9ecef; text-align: right; font-size: 12px; font-weight: 500;">${columns[4]}</td>');
        // Creditor (left)
        buffer.writeln('<td style="padding: 8px; border-bottom: 1px solid #e9ecef; text-align: left; font-size: 12px;">${columns[5]}</td>');
        
        buffer.writeln('</tr>');
      }
    }
    buffer.writeln('</tbody>');
    
    // Total row
    if (totalRow.isNotEmpty) {
      final totalColumns = totalRow.split('|').map((col) => col.trim()).toList();
      if (totalColumns.length >= 6) {
        buffer.writeln('<tfoot><tr style="background: #d4af37; color: white; font-weight: bold;">');
        buffer.writeln('<td style="padding: 10px 8px; border: none; font-size: 12px;">RAZEM</td>');
        buffer.writeln('<td style="padding: 10px 8px; border: none; text-align: right; font-size: 12px;">${totalColumns[1]}</td>');
        buffer.writeln('<td style="padding: 10px 8px; border: none; text-align: right; font-size: 12px;">${totalColumns[2]}</td>');
        buffer.writeln('<td style="padding: 10px 8px; border: none; text-align: right; font-size: 12px;">${totalColumns[3]}</td>');
        buffer.writeln('<td style="padding: 10px 8px; border: none; text-align: right; font-size: 12px;">${totalColumns[4]}</td>');
        buffer.writeln('<td style="padding: 10px 8px; border: none; font-size: 12px;"></td>');
        buffer.writeln('</tr></tfoot>');
      }
    }
    
    buffer.writeln('</table>');
    buffer.writeln('</div>');
    
    return buffer.toString();
  }
  
  /// Converts detailed aggregated plain text table to HTML table
  String _convertDetailedAggregatedTableToHtml(String tableRows, String totalRow) {
    final buffer = StringBuffer();
    
    // Start HTML table structure
    buffer.writeln('<div class="investment-summary" style="margin: 20px 0; padding: 20px; background-color: #f8f9fa; border-radius: 8px; border-left: 4px solid #d4af37;">');
    buffer.writeln('<h3 style="color: #d4af37; margin-bottom: 16px;">📊 Zbiorcze podsumowanie inwestycji</h3>');
    
    // Create HTML table
    buffer.writeln('<table style="width: 100%; border-collapse: collapse; background: white; border-radius: 6px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">');
    
    // Table headers for detailed aggregated view
    buffer.writeln('<thead><tr style="background: #2c2c2c; color: white;">');
    buffer.writeln('<th style="text-align: left; padding: 10px; font-weight: 600; font-size: 13px;">Klient</th>');
    buffer.writeln('<th style="text-align: center; padding: 10px; font-weight: 600; font-size: 13px;">Liczba inwestycji</th>');
    buffer.writeln('<th style="text-align: right; padding: 10px; font-weight: 600; font-size: 13px;">Kapitał pozostały</th>');
    buffer.writeln('<th style="text-align: right; padding: 10px; font-weight: 600; font-size: 13px;">Kapitał zabezpieczony</th>');
    buffer.writeln('<th style="text-align: right; padding: 10px; font-weight: 600; font-size: 13px;">Kapitał do restrukturyzacji</th>');
    buffer.writeln('</tr></thead>');
    
    // Table body
    buffer.writeln('<tbody>');
    final rows = tableRows.split('\n').where((row) => row.trim().isNotEmpty);
    for (int i = 0; i < rows.length; i++) {
      final row = rows.elementAt(i);
      final columns = row.split('|').map((col) => col.trim()).toList();
      
      if (columns.length >= 5) {
        final bgColor = i % 2 == 0 ? 'white' : '#f8f9fa';
        buffer.writeln('<tr style="background-color: $bgColor;">');
        
        // Client name (left)
        buffer.writeln('<td style="padding: 10px; border-bottom: 1px solid #e9ecef; text-align: left; font-size: 13px;">${columns[0]}</td>');
        // Investment count (center)
        buffer.writeln('<td style="padding: 10px; border-bottom: 1px solid #e9ecef; text-align: center; font-size: 13px; font-weight: 500;">${columns[1]}</td>');
        // Remaining capital (right)
        buffer.writeln('<td style="padding: 10px; border-bottom: 1px solid #e9ecef; text-align: right; font-size: 13px; font-weight: 500;">${columns[2]}</td>');
        // Secured capital (right)
        buffer.writeln('<td style="padding: 10px; border-bottom: 1px solid #e9ecef; text-align: right; font-size: 13px; font-weight: 500;">${columns[3]}</td>');
        // Capital for restructuring (right)
        buffer.writeln('<td style="padding: 10px; border-bottom: 1px solid #e9ecef; text-align: right; font-size: 13px; font-weight: 500;">${columns[4]}</td>');
        
        buffer.writeln('</tr>');
      }
    }
    buffer.writeln('</tbody>');
    
    // Total row
    if (totalRow.isNotEmpty) {
      final totalColumns = totalRow.split('|').map((col) => col.trim()).toList();
      if (totalColumns.length >= 5) {
        buffer.writeln('<tfoot><tr style="background: #d4af37; color: white; font-weight: bold;">');
        buffer.writeln('<td style="padding: 12px 10px; border: none; font-size: 13px;">RAZEM</td>');
        buffer.writeln('<td style="padding: 12px 10px; border: none; text-align: center; font-size: 13px;">${totalColumns[1]}</td>');
        buffer.writeln('<td style="padding: 12px 10px; border: none; text-align: right; font-size: 13px;">${totalColumns[2]}</td>');
        buffer.writeln('<td style="padding: 12px 10px; border: none; text-align: right; font-size: 13px;">${totalColumns[3]}</td>');
        buffer.writeln('<td style="padding: 12px 10px; border: none; text-align: right; font-size: 13px;">${totalColumns[4]}</td>');
        buffer.writeln('</tr></tfoot>');
      }
    }
    
    buffer.writeln('</table>');
    buffer.writeln('</div>');
    
    return buffer.toString();
  }
  
  /// Processes HTML content to replace table markers with investor-specific content
  String _processInvestmentTableMarkersForInvestor(String html, InvestorSummary investor) {
    if (kDebugMode) {
      print('🔄 [EmailDialog] Processing HTML for investor: ${investor.client.name}');
    }
    
    // Pattern 1: Individual investor tables - replace with this specific investor's detailed data
    final individualTablePattern = RegExp(
      r'----- Szczegółowe inwestycje: (.+?) -----\s*\n\s*Nazwa produktu \| Kwota inwestycji \| Kapitał pozostały \| Kapitał zabezpieczony \| Kapitał do restrukturyzacji \| Wierzyciel\s*\n\s*-+\s*\n((?:(?!RAZEM).+\n)*?)RAZEM \| (.+?)\n',
      multiLine: true,
    );
    
    html = html.replaceAllMapped(individualTablePattern, (match) {
      // Generate specific table content for this investor
      final tableContent = _buildPlainTextInvestmentsTableForInvestor(investor);
      
      // Extract the plain text table from the generated content
      final tablePattern = RegExp(
        r'----- Szczegółowe inwestycje: (.+?) -----\s*\n\s*Nazwa produktu \| Kwota inwestycji \| Kapitał pozostały \| Kapitał zabezpieczony \| Kapitał do restrukturyzacji \| Wierzyciel\s*\n\s*-+\s*\n((?:(?!RAZEM).+\n)*?)RAZEM \| (.+?)\n',
        multiLine: true,
      );
      
      final tableMatch = tablePattern.firstMatch(tableContent);
      if (tableMatch != null) {
        final investorName = tableMatch.group(1)?.trim() ?? investor.client.name;
        final tableRows = tableMatch.group(2)?.trim() ?? '';
        final totalRow = tableMatch.group(3)?.trim() ?? '';
        
        return _convertDetailedPlainTextTableToHtml(investorName, tableRows, totalRow);
      }
      
      // Fallback - return original match
      return match.group(0) ?? '';
    });
    
    // Pattern 2: Aggregated tables - for individual preview, show only this investor
    final aggregatedTablePattern = RegExp(
      r'----- Zbiorcze podsumowanie inwestycji -----\s*\n\s*Klient \| Liczba inwestycji \| Kapitał pozostały \| Kapitał zabezpieczony \| Kapitał do restrukturyzacji\s*\n\s*-+\s*\n((?:(?!RAZEM).+\n)*?)RAZEM \| (.+?)\n',
      multiLine: true,
    );
    
    html = html.replaceAllMapped(aggregatedTablePattern, (match) {
      // For individual preview, show aggregated table with just this investor
      final tableContent = _buildPlainTextAggregatedTable([investor]);
      
      final tablePattern = RegExp(
        r'----- Zbiorcze podsumowanie inwestycji -----\s*\n\s*Klient \| Liczba inwestycji \| Kapitał pozostały \| Kapitał zabezpieczony \| Kapitał do restrukturyzacji\s*\n\s*-+\s*\n((?:(?!RAZEM).+\n)*?)RAZEM \| (.+?)\n',
        multiLine: true,
      );
      
      final tableMatch = tablePattern.firstMatch(tableContent);
      if (tableMatch != null) {
        final tableRows = tableMatch.group(1)?.trim() ?? '';
        final totalRow = tableMatch.group(2)?.trim() ?? '';
        return _convertDetailedAggregatedTableToHtml(tableRows, totalRow);
      }
      
      // Fallback - return original match
      return match.group(0) ?? '';
    });
    
    return html;
  }
  
  /// Processes HTML content to replace table markers with aggregated content for multiple investors
  String _processInvestmentTableMarkersForAggregated(String html, List<InvestorSummary> investors) {
    if (kDebugMode) {
      print('🔄 [EmailDialog] Processing HTML for ${investors.length} aggregated investors');
    }
    
    // Pattern 1: Individual investor tables - replace with aggregated message
    final individualTablePattern = RegExp(
      r'----- Szczegółowe inwestycje: (.+?) -----\s*\n\s*Nazwa produktu \| Kwota inwestycji \| Kapitał pozostały \| Kapitał zabezpieczony \| Kapitał do restrukturyzacji \| Wierzyciel\s*\n\s*-+\s*\n((?:(?!RAZEM).+\n)*?)RAZEM \| (.+?)\n',
      multiLine: true,
    );
    
    html = html.replaceAllMapped(individualTablePattern, (match) {
      // For additional emails, replace individual tables with a notice
      return '''
      <div class="investment-summary" style="margin: 20px 0; padding: 20px; background-color: #f0f8ff; border-radius: 8px; border-left: 4px solid #d4af37;">
        <h3 style="color: #d4af37; margin-bottom: 16px;">📊 Inwestycje klientów</h3>
        <p style="color: #555; font-style: italic;">Szczegółowe dane inwestycyjne dostępne w zbiorczym podsumowaniu poniżej.</p>
      </div>
      ''';
    });
    
    // Pattern 2: Aggregated tables - replace with data for all investors
    final aggregatedTablePattern = RegExp(
      r'----- Zbiorcze podsumowanie inwestycji -----\s*\n\s*Klient \| Liczba inwestycji \| Kapitał pozostały \| Kapitał zabezpieczony \| Kapitał do restrukturyzacji\s*\n\s*-+\s*\n((?:(?!RAZEM).+\n)*?)RAZEM \| (.+?)\n',
      multiLine: true,
    );
    
    html = html.replaceAllMapped(aggregatedTablePattern, (match) {
      // Generate aggregated table content for all investors
      final tableContent = _buildPlainTextAggregatedTable(investors);
      
      final tablePattern = RegExp(
        r'----- Zbiorcze podsumowanie inwestycji -----\s*\n\s*Klient \| Liczba inwestycji \| Kapitał pozostały \| Kapitał zabezpieczony \| Kapitał do restrukturyzacji\s*\n\s*-+\s*\n((?:(?!RAZEM).+\n)*?)RAZEM \| (.+?)\n',
        multiLine: true,
      );
      
      final tableMatch = tablePattern.firstMatch(tableContent);
      if (tableMatch != null) {
        final tableRows = tableMatch.group(1)?.trim() ?? '';
        final totalRow = tableMatch.group(2)?.trim() ?? '';
        return _convertDetailedAggregatedTableToHtml(tableRows, totalRow);
      }
      
      // Fallback - return original match
      return match.group(0) ?? '';
    });
    
    return html;
  }
}