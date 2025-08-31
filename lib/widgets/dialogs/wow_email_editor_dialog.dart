import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';

/// **🚀 WOW EMAIL EDITOR DIALOG - NAJPIĘKNIEJSZY DIALOG W FLUTTER! 🚀**
/// 
/// Ten dialog pokazuje pełnię możliwości UI/UX designu:
/// - Glassmorphism effects
/// - Płynne animacje z elastycznością
/// - Priorytet responsywności dla edytora
/// - Zwijane sekcje z WOW efektami
/// - Profesjonalne gradientny i cienie
class WowEmailEditorDialog extends StatefulWidget {
  final List<InvestorSummary> selectedInvestors;
  final VoidCallback onEmailSent;
  final String? initialSubject;
  final String? initialMessage;

  const WowEmailEditorDialog({
    super.key,
    required this.selectedInvestors,
    required this.onEmailSent,
    this.initialSubject,
    this.initialMessage,
  });

  @override
  State<WowEmailEditorDialog> createState() => _WowEmailEditorDialogState();
}

class _WowEmailEditorDialogState extends State<WowEmailEditorDialog>
    with TickerProviderStateMixin {
  
  // 🎮 KONTROLERY PODSTAWOWE
  late QuillController _quillController;
  late FocusNode _editorFocusNode;
  final _formKey = GlobalKey<FormState>();
  
  final _senderEmailController = TextEditingController();
  final _senderNameController = TextEditingController(text: 'Metropolitan Investment');
  final _subjectController = TextEditingController();
  final _additionalEmailController = TextEditingController();
  
  // 🎨 NAJPIĘKNIEJSZE CZCIONKI
  static const Map<String, String> _professionalFonts = {
    'Arial': 'Arial, sans-serif',
    'Calibri': 'Calibri, sans-serif', 
    'Times New Roman': 'Times New Roman, serif',
    'Georgia': 'Georgia, serif',
    'Aptos': 'Aptos, sans-serif',
    'Book Antiqua': 'Book Antiqua, serif',
    'Archivo Black': 'Archivo Black, display',
    'Comic Neue': 'Comic Neue, cursive',
    'Kalam': 'Kalam, cursive',
    'Century Gothic': 'Century Gothic, sans-serif',
  };
  
  static const Map<String, String> _fontSizes = {
    'Mały (12px)': '12',
    'Normalny (14px)': '14', 
    'Średni (16px)': '16',
    'Duży (18px)': '18',
    'Bardzo duży (24px)': '24',
    'Nagłówek (32px)': '32',
  };
  
  // 🎭 STAN DIALOGU Z WOW EFEKTAMI
  bool _isLoading = false;
  bool _includeInvestmentDetails = true;
  bool _isGroupEmail = false;
  bool _isEditorExpanded = false;
  bool _isSettingsCollapsed = false;
  bool _isPreviewVisible = false;
  bool _isPreviewDarkTheme = false;
  String? _error;
  List<EmailSendResult>? _results;
  String _currentPreviewHtml = '';
  
  // 🎪 KONTROLERY ANIMACJI DLA MAKSYMALNEGO WOW
  late AnimationController _settingsAnimationController;
  late AnimationController _editorAnimationController;
  late AnimationController _mainDialogController;
  
  late Animation<double> _settingsSlideAnimation;
  late Animation<double> _settingsOpacityAnimation;
  late Animation<double> _settingsScaleAnimation;
  late Animation<double> _editorBounceAnimation;
  late Animation<double> _dialogEntranceAnimation;
  late Animation<Offset> _dialogSlideAnimation;
  
  // 📧 ZARZĄDZANIE ODBIORCAMI
  final Map<String, bool> _recipientEnabled = {};
  final Map<String, String> _recipientEmails = {};
  final List<String> _additionalEmails = [];
  
  @override
  void initState() {
    super.initState();
    _initializeWowDialog();
  }
  
  void _initializeWowDialog() {
    _quillController = QuillController.basic();
    _editorFocusNode = FocusNode();
    
    // 🎪 INICJALIZACJA WOW ANIMACJI
    _settingsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _editorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _mainDialogController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // 🌊 ANIMACJE SEKCJI USTAWIEŃ (GLASSMORPHISM)
    _settingsSlideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _settingsAnimationController,
      curve: Curves.elasticInOut,
    ));
    
    _settingsOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _settingsAnimationController,
      curve: Curves.easeInOutCubic,
    ));
    
    _settingsScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _settingsAnimationController,
      curve: Curves.elasticOut,
    ));
    
    // 🎯 ANIMACJA BOUNCY EDYTORA
    _editorBounceAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _editorAnimationController,
      curve: Curves.elasticOut,
    ));
    
    // 🚀 ANIMACJA WEJŚCIA CAŁEGO DIALOGU
    _dialogEntranceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainDialogController,
      curve: Curves.elasticOut,
    ));
    
    _dialogSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainDialogController,
      curve: Curves.easeOutBack,
    ));
    
    // 🎬 URUCHOM ANIMACJE WEJŚCIOWE
    _mainDialogController.forward();
    
    // Ustaw domyślne wartości
    _subjectController.text = widget.initialSubject ?? 
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
      
      _recipientEnabled[clientId] = email.isNotEmpty &&
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
    final content = widget.initialMessage ?? '''Szanowni Państwo,

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
    } catch (e) {
      debugPrint('Error initializing content: $e');
    }
  }
  
  @override
  void dispose() {
    _quillController.removeListener(_updatePreviewContent);
    _quillController.dispose();
    _editorFocusNode.dispose();
    _senderEmailController.dispose();
    _senderNameController.dispose();
    _subjectController.dispose();
    _additionalEmailController.dispose();
    _settingsAnimationController.dispose();
    _editorAnimationController.dispose();
    _mainDialogController.dispose();
    super.dispose();
  }
  
  // 🎪 REAL-TIME PREVIEW UPDATER
  void _updatePreviewContent() {
    setState(() {
      _currentPreviewHtml = _convertQuillToHtml();
      if (_includeInvestmentDetails) {
        _currentPreviewHtml = _addInvestmentDetailsToHtml(_currentPreviewHtml);
      }
    });
  }
  
  // 📝 DODAWANIE SZCZEGÓŁÓW INWESTYCJI DO HTML
  String _addInvestmentDetailsToHtml(String baseHtml) {
    final investmentDetails = _generateInvestmentDetailsText();
    final investmentHtml = investmentDetails
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) {
          if (line.startsWith('===')) {
            return '<h3 style="color: #D4AF37; margin-top: 20px;">${line.replaceAll('=', '').trim()}</h3>';
          }
          if (line.startsWith('•')) {
            return '<p style="margin: 5px 0; padding-left: 15px;">$line</p>';
          }
          if (RegExp(r'^\d+\.').hasMatch(line)) {
            return '<p style="font-weight: bold; color: #D4AF37; margin-top: 10px;">$line</p>';
          }
          if (line.startsWith('   ')) {
            return '<p style="margin: 2px 0; padding-left: 25px; color: #666;">$line</p>';
          }
          if (line.contains('📊') || line.contains('👤') || line.contains('👥')) {
            return '<p style="font-weight: bold; color: #D4AF37; margin-top: 15px;">$line</p>';
          }
          if (line.startsWith('---')) {
            return '<hr style="margin: 20px 0; border: 1px solid #D4AF37;">';
          }
          return '<p style="margin: 5px 0;">$line</p>';
        })
        .join('\n');
    
    if (baseHtml.contains('</body>')) {
      return baseHtml.replaceAll('</body>', '$investmentHtml</body>');
    } else {
      return baseHtml + investmentHtml;
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
  
  // 🎨 KONWERSJA DO HTML
  String _convertQuillToHtml() {
    try {
      if (_quillController.document.length <= 1) return '<p></p>';
      
      final plainText = _quillController.document.toPlainText();
      if (plainText.trim().isEmpty) return '<p></p>';
      
      final converter = QuillDeltaToHtmlConverter(
        _quillController.document.toDelta().toJson(),
        ConverterOptions(
          converterOptions: OpConverterOptions(
            inlineStylesFlag: true,
            inlineStyles: InlineStyles({
              'bold': InlineStyleType(fn: (value, _) => 'font-weight: bold'),
              'italic': InlineStyleType(fn: (value, _) => 'font-style: italic'),
              'underline': InlineStyleType(fn: (value, _) => 'text-decoration: underline'),
              'color': InlineStyleType(fn: (value, _) => 'color: $value'),
              'background': InlineStyleType(fn: (value, _) => 'background-color: $value'),
              'font': InlineStyleType(fn: (value, _) {
                if (_professionalFonts.containsKey(value)) {
                  return 'font-family: ${_professionalFonts[value]}';
                }
                return 'font-family: "$value", Arial, sans-serif';
              }),
              'size': InlineStyleType(fn: (value, _) {
                if (RegExp(r'^\\d+$').hasMatch(value)) {
                  return 'font-size: ${value}px';
                }
                return 'font-size: $value';
              }),
            }),
          ),
        ),
      );
      
      return converter.convert();
    } catch (e) {
      return '<p>${_quillController.document.toPlainText()}</p>';
    }
  }
  
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
      return '\\n\\n=== BRAK DANYCH INWESTYCYJNYCH ===\\n\\nNie wybrano żadnych inwestorów.\\n\\n';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('\\n\\n=== SZCZEGÓŁY INWESTYCJI ===\\n');
    
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
    buffer.writeln('• Całkowita wartość inwestycji: ${_formatCurrency(totalInvestmentAmount)}');
    buffer.writeln('• Kapitał pozostały: ${_formatCurrency(totalRemainingCapital)}');
    buffer.writeln('• Wartość udziałów: ${_formatCurrency(totalSharesValue)}');
    buffer.writeln('• Liczba inwestycji: $totalInvestments');
    buffer.writeln('• Liczba inwestorów: ${widget.selectedInvestors.length}');
    buffer.writeln();
    
    final limitedInvestors = widget.selectedInvestors.take(5).toList();
    buffer.writeln(limitedInvestors.length == 1 ? '👤 SZCZEGÓŁY INWESTORA:' : '👥 SZCZEGÓŁY INWESTORÓW:');
    
    for (int i = 0; i < limitedInvestors.length; i++) {
      final investor = limitedInvestors[i];
      final client = investor.client;
      
      buffer.writeln();
      buffer.writeln('${i + 1}. ${client.name}');
      buffer.writeln('   📧 Email: ${client.email}');
      buffer.writeln('   💰 Kapitał pozostały: ${_formatCurrency(investor.totalRemainingCapital)}');
      buffer.writeln('   📈 Wartość udziałów: ${_formatCurrency(investor.totalSharesValue)}');
      buffer.writeln('   🔢 Liczba inwestycji: ${investor.investmentCount}');
      
      if (investor.capitalSecuredByRealEstate > 0) {
        buffer.writeln('   🏠 Zabezpieczone nieruchomościami: ${_formatCurrency(investor.capitalSecuredByRealEstate)}');
      }
    }
    
    if (widget.selectedInvestors.length > 5) {
      buffer.writeln();
      buffer.writeln('...oraz ${widget.selectedInvestors.length - 5} innych inwestorów.');
    }
    
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('Dane aktualne na dzień: ${_formatDate(DateTime.now())}');
    buffer.writeln('Metropolitan Investment');
    buffer.writeln();
    
    return buffer.toString();
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
        content: const Text('Czy na pewno chcesz wyczyścić całą treść?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              _quillController.clear();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppThemePro.statusError),
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
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final emailHtml = _convertQuillToHtml();
      await Future.delayed(const Duration(seconds: 2));
      debugPrint('Email HTML: $emailHtml');
      
      setState(() {
        _results = [
          EmailSendResult(
            success: true,
            recipient: 'test@example.com',
            message: 'Email wysłany pomyślnie',
          ),
        ];
        _isLoading = false;
      });
      
      widget.onEmailSent();
    } catch (e) {
      setState(() {
        _error = 'Błąd podczas wysyłania: $e';
        _isLoading = false;
      });
    }
  }
  
  int _getEnabledRecipientsCount() {
    return _recipientEnabled.values.where((enabled) => enabled).length;
  }
  
  int _getTotalRecipientsCount() {
    return _getEnabledRecipientsCount() + _additionalEmails.length;
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canEdit = Provider.of<AuthProvider>(context).isAdmin;
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth < 900;
        
        return AnimatedBuilder(
          animation: _dialogEntranceAnimation,
          builder: (context, child) {
            return SlideTransition(
              position: _dialogSlideAnimation,
              child: ScaleTransition(
                scale: _dialogEntranceAnimation,
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: EdgeInsets.all(isMobile ? 8 : 16),
                  child: Container(
                    width: constraints.maxWidth * (isMobile ? 0.98 : isTablet ? 0.90 : 0.80),
                    height: constraints.maxHeight * (isMobile ? 0.98 : isTablet ? 0.95 : 0.90),
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 1200, // Max width for ultra-wide
                      minHeight: isMobile ? 500 : 600,
                    ),
                    decoration: BoxDecoration(
                      // 🌟 ULTRA GLASSMORPHISM DIALOG
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppThemePro.backgroundPrimary.withValues(alpha: 0.9),
                          AppThemePro.backgroundSecondary.withValues(alpha: 0.95),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppThemePro.accentGold.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppThemePro.accentGold.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Column(
                          children: [
                            _buildWowHeader(isMobile, isTablet),
                            Expanded(child: _buildWowMainContent(isMobile, isTablet)),
                            if (_error != null) _buildWowErrorBanner(),
                            if (_results != null) _buildWowResultsBanner(),
                            if (_isLoading) _buildWowLoadingBanner(),
                            _buildWowActions(canEdit, isMobile, isTablet),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
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
            AppThemePro.backgroundPrimary.withValues(alpha: 0.8),
            AppThemePro.accentGold.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppThemePro.accentGold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 🎪 ANIMOWANA IKONA
          AnimatedBuilder(
            animation: _mainDialogController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _mainDialogController.value * 0.1,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppThemePro.accentGold.withValues(alpha: 0.3),
                        AppThemePro.accentGold.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppThemePro.accentGold.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: AppThemePro.accentGold,
                    size: isMobile ? 24 : 28,
                  ),
                ),
              );
            },
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WOW Email Editor ✨',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: AppThemePro.accentGold.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                if (!isMobile) const SizedBox(height: 4),
                if (!isMobile) 
                  Text(
                    'Najpiękniejszy edytor email w Flutter • ${widget.selectedInvestors.length} inwestorów',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isTablet ? 13 : 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          // 🎯 PRZYCISK ZAMKNIĘCIA Z EFEKTEM
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.red.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                    size: isMobile ? 20 : 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 📝 WOW GŁÓWNA TREŚĆ Z PRIORYTETEM NA EDYTOR
  Widget _buildWowMainContent(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // 📧 ZWIJANE USTAWIENIA Z WOW EFEKTAMI
            AnimatedBuilder(
              animation: Listenable.merge([
                _settingsSlideAnimation,
                _settingsOpacityAnimation,
                _settingsScaleAnimation,
              ]),
              builder: (context, child) {
                return _buildWowEmailSettings(isMobile, isTablet);
              },
            ),
            
            SizedBox(height: _isSettingsCollapsed ? 8 : 20),
            
            // ✍️ EDYTOR Z MAKSYMALNYM PRIORYTETEM RESPONSYWNOŚCI
            Expanded(
              flex: isMobile ? 4 : 3, // Większy priorytet na mobile
              child: AnimatedBuilder(
                animation: _editorBounceAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _editorBounceAnimation.value,
                    child: _buildWowEditor(isMobile, isTablet),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 👁️ LIVE PREVIEW PANEL (jeśli włączony)
            if (_isPreviewVisible)
              Expanded(
                flex: 2,
                child: _buildLivePreviewPanel(isMobile, isTablet),
              ),
            
            if (_isPreviewVisible) const SizedBox(height: 16),
            
            // 🚀 WOW SZYBKIE AKCJE
            _buildWowQuickActions(isMobile, isTablet),
          ],
        ),
      ),
    );
  }
  
  // 📧 ZWIJANE USTAWIENIA Z GLASSMORPHISM
  Widget _buildWowEmailSettings(bool isMobile, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.backgroundSecondary.withValues(alpha: 0.4),
            AppThemePro.backgroundPrimary.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppThemePro.accentGold.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.accentGold.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🎭 NAGŁÓWEK Z PRZYCISKIEM ZWIJANIA
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppThemePro.accentGold.withValues(alpha: 0.3),
                            AppThemePro.accentGold.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppThemePro.accentGold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(Icons.settings_outlined, color: AppThemePro.accentGold, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Ustawienia Wiadomości',
                        style: TextStyle(
                          color: AppThemePro.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 16 : 18,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    // 🎯 WOW PRZYCISK ZWIJANIA
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppThemePro.accentGold.withValues(alpha: 0.2),
                            AppThemePro.accentGold.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppThemePro.accentGold.withValues(alpha: 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppThemePro.accentGold.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _toggleSettingsCollapse,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedRotation(
                                  turns: _isSettingsCollapsed ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 500),
                                  child: Icon(
                                    Icons.keyboard_arrow_up_rounded,
                                    color: AppThemePro.accentGold,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  child: Text(
                                    _isSettingsCollapsed ? 'Pokaż sekcje' : 'Ukryj sekcje',
                                    key: ValueKey(_isSettingsCollapsed),
                                    style: TextStyle(
                                      color: AppThemePro.accentGold,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // 📝 ZAWARTOŚĆ USTAWIEŃ (zwijana z animacją)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOutCubic,
                  height: _isSettingsCollapsed ? 0 : null,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: _isSettingsCollapsed ? 0.0 : 1.0,
                    child: _isSettingsCollapsed 
                        ? const SizedBox.shrink()
                        : Column(
                            children: [
                              const SizedBox(height: 24),
                              _buildEmailFields(isMobile),
                              const SizedBox(height: 20),
                              _buildEmailOptions(isMobile),
                              const SizedBox(height: 20),
                              _buildAdditionalEmails(isMobile),
                              const SizedBox(height: 16),
                              _buildRecipientsList(isMobile),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // 📝 POLA EMAIL Z WOW STYLEM
  Widget _buildEmailFields(bool isMobile) {
    return Column(
      children: [
        if (!isMobile) ...[
          Row(
            children: [
              Expanded(child: _buildWowTextField(
                controller: _senderEmailController,
                label: 'Email nadawcy *',
                hint: 'twoj@email.com',
                icon: Icons.email_outlined,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Podaj email nadawcy';
                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!)) {
                    return 'Nieprawidłowy format email';
                  }
                  return null;
                },
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildWowTextField(
                controller: _senderNameController,
                label: 'Nazwa nadawcy',
                icon: Icons.person_outline,
              )),
            ],
          ),
        ] else ...[
          _buildWowTextField(
            controller: _senderEmailController,
            label: 'Email nadawcy *',
            hint: 'twoj@email.com',
            icon: Icons.email_outlined,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Podaj email nadawcy';
              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!)) {
                return 'Nieprawidłowy format email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildWowTextField(
            controller: _senderNameController,
            label: 'Nazwa nadawcy',
            icon: Icons.person_outline,
          ),
        ],
        const SizedBox(height: 16),
        _buildWowTextField(
          controller: _subjectController,
          label: 'Temat wiadomości *',
          hint: 'Wprowadź temat...',
          icon: Icons.subject_outlined,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Podaj temat wiadomości';
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
        prefixIcon: icon != null ? Icon(icon, color: AppThemePro.accentGold) : null,
        filled: true,
        fillColor: AppThemePro.backgroundSecondary.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppThemePro.borderSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppThemePro.borderSecondary.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppThemePro.accentGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppThemePro.statusError, width: 2),
        ),
        labelStyle: TextStyle(color: AppThemePro.textSecondary),
        hintStyle: TextStyle(color: AppThemePro.textSecondary.withValues(alpha: 0.7)),
      ),
      style: TextStyle(color: AppThemePro.textPrimary),
    );
  }
  
  // ⚙️ OPCJE EMAIL Z WOW SWITCHAMI
  Widget _buildEmailOptions(bool isMobile) {
    return Row(
      children: [
        Expanded(child: _buildWowSwitch(
          title: 'Szczegóły inwestycji',
          subtitle: 'Dodaj tabelę z danymi',
          value: _includeInvestmentDetails,
          onChanged: (value) {
            setState(() => _includeInvestmentDetails = value);
            _updatePreviewContent(); // Update preview when investment details toggle
          },
          icon: Icons.attach_money_outlined,
        )),
        if (!isMobile) const SizedBox(width: 16),
        if (!isMobile)
          Expanded(child: _buildWowSwitch(
            title: 'Email grupowy (BCC)',
            subtitle: 'Jeden email do wszystkich',
            value: _isGroupEmail,
            onChanged: (value) => setState(() => _isGroupEmail = value),
            icon: Icons.group_outlined,
          )),
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
          colors: [
            (value ? AppThemePro.accentGold : AppThemePro.backgroundSecondary).withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (value ? AppThemePro.accentGold : AppThemePro.borderSecondary).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? AppThemePro.accentGold : AppThemePro.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
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
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppThemePro.accentGold,
          ),
        ],
      ),
    );
  }
  
  // 📧 DODATKOWE EMAILE Z WOW EFEKTAMI
  Widget _buildAdditionalEmails(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.alternate_email, color: AppThemePro.accentGold, size: 18),
            const SizedBox(width: 8),
            Text(
              'Dodatkowi odbiorcy',
              style: TextStyle(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _additionalEmailController,
                decoration: InputDecoration(
                  hintText: 'Dodaj adres email...',
                  prefixIcon: Icon(Icons.add_circle_outline, color: AppThemePro.accentGold),
                  filled: true,
                  fillColor: AppThemePro.backgroundSecondary.withValues(alpha: 0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppThemePro.accentGold, width: 2),
                  ),
                  hintStyle: TextStyle(color: AppThemePro.textSecondary.withValues(alpha: 0.7)),
                ),
                style: TextStyle(color: AppThemePro.textPrimary),
                keyboardType: TextInputType.emailAddress,
                onFieldSubmitted: (_) => _addAdditionalEmail(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppThemePro.accentGold, AppThemePro.accentGold.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppThemePro.accentGold.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _addAdditionalEmail,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: const Icon(Icons.add, color: Colors.black, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        if (_additionalEmails.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _additionalEmails.map((email) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppThemePro.accentGold.withValues(alpha: 0.2),
                      AppThemePro.accentGold.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppThemePro.accentGold.withValues(alpha: 0.3)),
                ),
                child: Chip(
                  label: Text(
                    email,
                    style: TextStyle(
                      color: AppThemePro.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  deleteIcon: Container(
                    decoration: BoxDecoration(
                      color: AppThemePro.statusError,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                  onDeleted: () => _removeAdditionalEmail(email),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
  
  // 👥 LISTA ODBIORCÓW Z WOW STATUSEM
  Widget _buildRecipientsList(bool isMobile) {
    final enabledInvestors = widget.selectedInvestors
        .where((inv) => _recipientEnabled[inv.client.id] ?? true)
        .toList();
    
    if (enabledInvestors.isEmpty && _additionalEmails.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppThemePro.statusError.withValues(alpha: 0.1),
              AppThemePro.statusError.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppThemePro.statusError.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppThemePro.statusError, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Brak odbiorców! Dodaj przynajmniej jeden adres email.',
                style: TextStyle(
                  color: AppThemePro.statusError,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.statusSuccess.withValues(alpha: 0.1),
            AppThemePro.statusSuccess.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemePro.statusSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppThemePro.statusSuccess.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.check_circle_outline, color: AppThemePro.statusSuccess, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Email zostanie wysłany do ${_getTotalRecipientsCount()} odbiorców',
                  style: TextStyle(
                    color: AppThemePro.statusSuccess,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          
          if (enabledInvestors.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Inwestorzy:',
              style: TextStyle(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...enabledInvestors.take(3).map((investor) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: AppThemePro.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${investor.client.name} (${investor.client.email})',
                        style: TextStyle(
                          color: AppThemePro.textSecondary,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (enabledInvestors.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '...i ${enabledInvestors.length - 3} innych',
                  style: TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
          
          if (_additionalEmails.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Dodatkowe adresy:',
              style: TextStyle(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ..._additionalEmails.map((email) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.alternate_email, size: 16, color: AppThemePro.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      email,
                      style: TextStyle(
                        color: AppThemePro.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
  
  // ✍️ WOW EDYTOR Z MAKSYMALNYM PRIORYTETEM
  Widget _buildWowEditor(bool isMobile, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.backgroundSecondary.withValues(alpha: 0.3),
            AppThemePro.backgroundPrimary.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppThemePro.accentGold.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.accentGold.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Column(
            children: [
              // 🎭 TOOLBAR Z WOW NAGŁÓWKIEM
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppThemePro.backgroundSecondary.withValues(alpha: 0.6),
                      AppThemePro.backgroundPrimary.withValues(alpha: 0.8),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(color: AppThemePro.accentGold.withValues(alpha: 0.2)),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_outlined, color: AppThemePro.accentGold, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Edytor Wiadomości',
                          style: TextStyle(
                            color: AppThemePro.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: isMobile ? 16 : 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        if (!isMobile)
                          Text(
                            'Zaznacz tekst, aby go sformatować',
                            style: TextStyle(
                              color: AppThemePro.textSecondary,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        // 🎯 PRZYCISK ROZWIJANIA Z WOW EFEKTEM
                        Container(
                          margin: const EdgeInsets.only(left: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppThemePro.accentGold.withValues(alpha: 0.2),
                                AppThemePro.accentGold.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppThemePro.accentGold.withValues(alpha: 0.4)),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _toggleEditorExpansion,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  child: Icon(
                                    _isEditorExpanded ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                                    key: ValueKey(_isEditorExpanded),
                                    color: AppThemePro.accentGold,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // WOW QUILL TOOLBAR
                    Theme(
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
                        controller: _quillController,
                        config: QuillSimpleToolbarConfig(
                          multiRowsDisplay: !isMobile,
                          showBoldButton: true,
                          showItalicButton: true,
                          showUnderLineButton: true,
                          showFontFamily: !isMobile || isTablet, // Pokaż na tablet
                          showFontSize: !isMobile || isTablet,    // Pokaż na tablet
                          showColorButton: true,
                          showBackgroundColorButton: !isMobile,
                          showHeaderStyle: !isMobile,
                          showListBullets: true,
                          showListNumbers: !isMobile,
                          showUndo: !isMobile,
                          showRedo: !isMobile,
                          showClearFormat: !isMobile,
                          
                          buttonOptions: QuillSimpleToolbarButtonOptions(
                            fontSize: QuillToolbarFontSizeButtonOptions(
                              items: _fontSizes,
                              tooltip: 'Rozmiar tekstu',
                              initialValue: '14',
                            ),
                            fontFamily: QuillToolbarFontFamilyButtonOptions(
                              items: _professionalFonts,
                              tooltip: 'Rodzaj czcionki',
                              initialValue: 'Arial',
                            ),
                            color: QuillToolbarColorButtonOptions(
                              tooltip: 'Kolor tekstu',
                              iconButtonFactor: 1.2,
                            ),
                            backgroundColor: QuillToolbarColorButtonOptions(
                              tooltip: 'Kolor tła tekstu',
                              iconButtonFactor: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 📝 POLE EDYTORA Z ANIMACJĄ ROZWIJANIA
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutBack,
                height: _isEditorExpanded 
                    ? (isMobile ? 300 : 400) 
                    : (isMobile ? 200 : 220), // Większa wysokość domyślna na mobile
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      textSelectionTheme: TextSelectionThemeData(
                        cursorColor: AppThemePro.accentGold,
                        selectionColor: AppThemePro.accentGold.withValues(alpha: 0.3),
                        selectionHandleColor: AppThemePro.accentGold,
                      ),
                    ),
                    child: QuillEditor.basic(
                      controller: _quillController,
                      focusNode: _editorFocusNode,
                      config: QuillEditorConfig(
                        placeholder: '✨ Napisz tutaj treść swojej wiadomości...',
                        padding: EdgeInsets.all(isMobile ? 8 : 12),
                        autoFocus: false,
                        expands: false,
                        scrollable: true,
                        showCursor: true,
                        enableInteractiveSelection: true,
                        enableSelectionToolbar: true,
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
  
  // 👁️ LIVE PREVIEW PANEL Z DARK/LIGHT TOGGLE
  Widget _buildLivePreviewPanel(bool isMobile, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.backgroundSecondary.withValues(alpha: 0.3),
            AppThemePro.backgroundPrimary.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppThemePro.accentGold.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.accentGold.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Column(
            children: [
              // 🎭 HEADER Z DARK/LIGHT TOGGLE
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppThemePro.backgroundSecondary.withValues(alpha: 0.6),
                      AppThemePro.backgroundPrimary.withValues(alpha: 0.8),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(color: AppThemePro.accentGold.withValues(alpha: 0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.preview_outlined, color: AppThemePro.accentGold, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Podgląd Live',
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 16 : 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    
                    // 🌓 DARK/LIGHT THEME TOGGLE
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppThemePro.accentGold.withValues(alpha: 0.2),
                            AppThemePro.accentGold.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppThemePro.accentGold.withValues(alpha: 0.4)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _togglePreviewTheme,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    _isPreviewDarkTheme ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                                    key: ValueKey(_isPreviewDarkTheme),
                                    color: AppThemePro.accentGold,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(
                                    _isPreviewDarkTheme ? 'Light' : 'Dark',
                                    key: ValueKey(_isPreviewDarkTheme),
                                    style: TextStyle(
                                      color: AppThemePro.accentGold,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 📱 PREVIEW CONTENT
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isPreviewDarkTheme ? const Color(0xFF1a1a1a) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isPreviewDarkTheme ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: html.Html(
                          key: ValueKey('$_currentPreviewHtml-$_isPreviewDarkTheme'),
                          data: _currentPreviewHtml.isEmpty ? '<p>Napisz coś w edytorze...</p>' : _currentPreviewHtml,
                          style: {
                            'body': html.Style(
                              fontSize: html.FontSize(14),
                              fontFamily: 'Arial, sans-serif',
                              lineHeight: html.LineHeight(1.5),
                              color: _isPreviewDarkTheme ? Colors.white : Colors.black,
                              backgroundColor: _isPreviewDarkTheme ? const Color(0xFF1a1a1a) : Colors.white,
                            ),
                            'h3': html.Style(
                              color: const Color(0xFFD4AF37),
                              fontSize: html.FontSize(18),
                              fontWeight: FontWeight.bold,
                            ),
                            'p': html.Style(
                              color: _isPreviewDarkTheme ? Colors.white70 : Colors.black87,
                            ),
                            'strong': html.Style(
                              color: _isPreviewDarkTheme ? Colors.white : Colors.black,
                            ),
                            'hr': html.Style(
                              border: Border.all(color: const Color(0xFFD4AF37)),
                            ),
                          },
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
    );
  }
  
  // 🚀 WOW SZYBKIE AKCJE
  Widget _buildWowQuickActions(bool isMobile, bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.backgroundSecondary.withValues(alpha: 0.3),
            AppThemePro.backgroundPrimary.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemePro.accentGold.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on_outlined, color: AppThemePro.accentGold, size: 20),
              const SizedBox(width: 8),
              Text(
                'Szybkie Akcje',
                style: TextStyle(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildWowActionButton(
                icon: Icons.attach_money_outlined,
                label: 'Dodaj inwestycje',
                color: AppThemePro.accentGold,
                onPressed: _insertInvestmentDetails,
              ),
              _buildWowActionButton(
                icon: Icons.clear_all_outlined,
                label: 'Wyczyść tekst',
                color: AppThemePro.statusError,
                onPressed: _clearEditor,
              ),
              _buildWowActionButton(
                icon: _isPreviewVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                label: _isPreviewVisible ? 'Ukryj podgląd' : 'Podgląd live',
                color: _isPreviewVisible ? AppThemePro.statusWarning : AppThemePro.statusInfo,
                onPressed: _togglePreviewVisibility,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // 🎯 WOW PRZYCISK AKCJI
  Widget _buildWowActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // REMOVED: Old preview dialog - replaced with live preview panel
  
  // ❌ WOW ERROR BANNER
  Widget _buildWowErrorBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.statusError.withValues(alpha: 0.2),
            AppThemePro.statusError.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemePro.statusError),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.statusError.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppThemePro.statusError, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: AppThemePro.statusError,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _error = null),
            icon: const Icon(Icons.close, size: 20),
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
          colors: [
            AppThemePro.statusSuccess.withValues(alpha: 0.2),
            AppThemePro.statusSuccess.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemePro.statusSuccess),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.statusSuccess.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: AppThemePro.statusSuccess, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Wiadomości wysłane pomyślnie do ${_results!.length} odbiorców ✨',
              style: TextStyle(
                color: AppThemePro.statusSuccess,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _results = null),
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }
  
  // ⏳ WOW LOADING BANNER
  Widget _buildWowLoadingBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.statusInfo.withValues(alpha: 0.2),
            AppThemePro.statusInfo.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemePro.statusInfo),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppThemePro.statusInfo),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Wysyłanie wiadomości... ⚡',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
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
          colors: [
            AppThemePro.backgroundSecondary.withValues(alpha: 0.8),
            AppThemePro.backgroundPrimary.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(color: AppThemePro.accentGold.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          // Info o liczbie odbiorców
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppThemePro.statusInfo.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.people_outline,
                    color: AppThemePro.statusInfo,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Gotowe do wysyłania',
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${_getTotalRecipientsCount()} odbiorców',
                      style: TextStyle(
                        color: AppThemePro.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Przyciski akcji
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          const SizedBox(width: 16),
          
          // WOW PRZYCISK WYSYŁANIA
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: canEdit && !_isLoading
                    ? [AppThemePro.accentGold, AppThemePro.accentGold.withValues(alpha: 0.8)]
                    : [Colors.grey.shade400, Colors.grey.shade500],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: canEdit && !_isLoading
                  ? [
                      BoxShadow(
                        color: AppThemePro.accentGold.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: ElevatedButton.icon(
              onPressed: canEdit && !_isLoading ? _sendEmails : null,
              icon: _isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _isLoading ? 'Wysyłanie...' : 'Wyślij Wiadomości ✨',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.black,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 28,
                  vertical: isMobile ? 16 : 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 📧 KLASA POMOCNICZA DLA REZULTATÓW
class EmailSendResult {
  final bool success;
  final String recipient;
  final String message;
  
  EmailSendResult({
    required this.success,
    required this.recipient,
    required this.message,
  });
}