import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';
import '../../providers/auth_provider.dart';

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
  bool _showHtmlPreview = true;
  String? _error;
  List<EmailSendResult>? _results;

  // Enhanced loading and debugging states
  String _loadingMessage = 'Przygotowywanie...';
  int _currentEmailIndex = 0;
  int _totalEmailsToSend = 0;
  bool _showDetailedProgress = false;
  final List<String> _debugLogs = [];
  DateTime? _emailSendStartTime;

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
      final initial = widget.initialMessage;
      if (initial != null && initial.isNotEmpty) {
        _insertInitialContent(initial);
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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final headerPadding = isSmallScreen ? 16.0 : 24.0;
    
    return Container(
      padding: EdgeInsets.all(headerPadding),
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
                          buttonOptions: QuillSimpleToolbarButtonOptions(
                            base: QuillToolbarBaseButtonOptions(
                              iconSize: 18,
                              iconButtonFactor: 1.2,
                            ),
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
                                  .withOpacity(0.3),
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
                  backgroundColor: AppThemePro.statusInfo.withOpacity(0.2),
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
                  backgroundColor: AppThemePro.statusSuccess.withOpacity(0.2),
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
                  backgroundColor: AppThemePro.statusError.withOpacity(0.2),
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
    return const Center(
      child: Text('Settings tab - placeholder'),
    );
  }

  Widget _buildPreviewTab() {
    return const Center(
      child: Text('Preview tab - placeholder'),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemePro.statusError.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.statusError.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppThemePro.statusError),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_error!, style: TextStyle(color: AppThemePro.statusError)),
          ),
        ],
      ),
    );
  }

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
              backgroundColor: AppThemePro.borderSecondary,
              valueColor: AlwaysStoppedAnimation(AppThemePro.accentGold),
            ),
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
            ? AppThemePro.statusSuccess.withOpacity(0.1)
            : AppThemePro.statusWarning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: successful == _results!.length
              ? AppThemePro.statusSuccess.withOpacity(0.3)
              : AppThemePro.statusWarning.withOpacity(0.3),
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
                    ? AppThemePro.statusSuccess
                    : AppThemePro.statusWarning,
              ),
              const SizedBox(width: 8),
              Text(
                'Wyniki wysyłania',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: successful == _results!.length
                      ? AppThemePro.statusSuccess
                      : AppThemePro.statusWarning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('✅ Wysłane pomyślnie: $successful'),
          if (failed > 0) Text('❌ Błędy: $failed'),
        ],
      ),
    );
  }

  Widget _buildActions(bool canEdit) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final actionsPadding = isSmallScreen ? 16.0 : 24.0;
    
    return Container(
      padding: EdgeInsets.all(actionsPadding),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: isSmallScreen 
            ? MainAxisAlignment.spaceEvenly 
            : MainAxisAlignment.spaceBetween,
        children: [
          if (!isSmallScreen)
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: (!canEdit || _isLoading) ? null : _saveTemplate,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Zapisz szablon'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemePro.statusInfo.withOpacity(0.2),
                  foregroundColor: AppThemePro.statusInfo,
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
      final currentLength = _quillController.document.length;
      
      _quillController.document.insert(0, greeting);

      Future.delayed(const Duration(milliseconds: 10), () {
        if (mounted) {
          try {
            _quillController.updateSelection(
              TextSelection.collapsed(offset: greeting.length),
              ChangeSource.local,
            );
            _editorFocusNode.requestFocus();
          } catch (e) {
            debugPrint('Error setting cursor: $e');
          }
        }
      });

      setState(() {});
    } catch (e) {
      debugPrint('Error inserting greeting: $e');
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
        if (mounted) {
          try {
            final newPosition = insertPosition + signature.length;
            _quillController.updateSelection(
              TextSelection.collapsed(offset: newPosition),
              ChangeSource.local,
            );
            _editorFocusNode.requestFocus();
          } catch (e) {
            debugPrint('Error setting cursor after signature: $e');
          }
        }
      });

      setState(() {});
    } catch (e) {
      debugPrint('Error inserting signature: $e');
    }
  }

  void _clearEditor() {
    try {
      _quillController.clear();

      Future.delayed(const Duration(milliseconds: 10), () {
        if (mounted) {
          try {
            _quillController.updateSelection(
              const TextSelection.collapsed(offset: 0),
              ChangeSource.local,
            );
            _editorFocusNode.requestFocus();
          } catch (e) {
            debugPrint('Error resetting cursor: $e');
          }
        }
      });

      setState(() {});
    } catch (e) {
      debugPrint('Error clearing editor: $e');
    }
  }

  bool _hasValidEmails() {
    final hasValidInvestorEmails = widget.selectedInvestors.any(
      (investor) =>
          _recipientEnabled[investor.client.id] == true &&
          investor.client.email.isNotEmpty &&
          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(investor.client.email),
    );

    final hasValidAdditionalEmails = _additionalEmails.any(
      (email) =>
          email.isNotEmpty &&
          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email),
    );

    return hasValidInvestorEmails || hasValidAdditionalEmails;
  }

  Future<void> _saveTemplate() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funkcja zapisywania szablonów będzie dostępna wkrótce'),
        backgroundColor: AppThemePro.statusWarning,
      ),
    );
  }

  Future<void> _sendEmails() async {
    // Simplified version - just show message for now
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funkcja wysyłania email będzie dostępna wkrótce'),
        backgroundColor: AppThemePro.statusInfo,
      ),
    );
  }
}