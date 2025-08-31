import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';

/// **NOWY PRZEPROJEKTOWANY DIALOG EDYTORA EMAIL**
/// 
/// Uproszony, intuicyjny interfejs z jasnymi instrukcjami
/// i lepszą organizacją funkcji
class RedesignedEmailEditorDialog extends StatefulWidget {
  final List<InvestorSummary> selectedInvestors;
  final VoidCallback onEmailSent;
  final String? initialSubject;
  final String? initialMessage;

  const RedesignedEmailEditorDialog({
    super.key,
    required this.selectedInvestors,
    required this.onEmailSent,
    this.initialSubject,
    this.initialMessage,
  });

  @override
  State<RedesignedEmailEditorDialog> createState() =>
      _RedesignedEmailEditorDialogState();
}

class _RedesignedEmailEditorDialogState extends State<RedesignedEmailEditorDialog>
    with TickerProviderStateMixin {
  
  // 🎯 UPROSZCZONE ZARZĄDZANIE STANEM
  late QuillController _quillController;
  late FocusNode _editorFocusNode;
  final _formKey = GlobalKey<FormState>();
  
  // Podstawowe kontrolery
  final _senderEmailController = TextEditingController();
  final _senderNameController = TextEditingController(text: 'Metropolitan Investment');
  final _subjectController = TextEditingController();
  
  // 🎨 NOWE UPROSZCZONE CZCIONKI - tylko te wybrane przez użytkownika
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
  
  // 🎨 UPROSZCZONE ROZMIARY CZCIONEK
  static const Map<String, String> _fontSizes = {
    'Mały (12px)': '12',
    'Normalny (14px)': '14',
    'Średni (16px)': '16',
    'Duży (18px)': '18',
    'Bardzo duży (24px)': '24',
    'Nagłówek (32px)': '32',
  };
  
  // Stan dialogu
  bool _isLoading = false;
  bool _includeInvestmentDetails = true;
  bool _isGroupEmail = false;
  bool _isEditorExpanded = false;
  bool _isSettingsCollapsed = false;
  String? _error;
  List<EmailSendResult>? _results;
  
  // Kontrolery animacji dla efektu WOW
  late AnimationController _settingsAnimationController;
  late AnimationController _editorAnimationController;
  late Animation<double> _settingsSlideAnimation;
  late Animation<double> _settingsOpacityAnimation;
  late Animation<double> _editorScaleAnimation;
  
  // Zarządzanie odbiorcami
  final Map<String, bool> _recipientEnabled = {};
  final Map<String, String> _recipientEmails = {};
  final List<String> _additionalEmails = [];
  final TextEditingController _additionalEmailController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _initializeDialog();
  }
  
  void _initializeDialog() {
    // Podstawowa inicjalizacja
    _quillController = QuillController.basic();
    _editorFocusNode = FocusNode();
    
    // 🎭 INICJALIZACJA ANIMACJI DLA EFEKTU WOW
    _settingsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _editorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Animacje slide i opacity dla sekcji ustawień
    _settingsSlideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _settingsAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _settingsOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _settingsAnimationController,
      curve: Curves.easeInOutCubic,
    ));
    
    // Animacja scale dla edytora
    _editorScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _editorAnimationController,
      curve: Curves.elasticOut,
    ));
    
    // Uruchom animację edytora przy starcie
    _editorAnimationController.forward();
    
    // Ustaw domyślny temat
    _subjectController.text = widget.initialSubject ?? 
        'Aktualizacja portfela inwestycyjnego - Metropolitan Investment';
    
    // Inicjalizuj odbiorców
    _initializeRecipients();
    
    // Załaduj ustawienia SMTP
    _loadSmtpEmail();
    
    // Załaduj treść po zbudowaniu widżetu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeContent();
    });
  }
  
  void _initializeRecipients() {
    for (final investor in widget.selectedInvestors) {
      final clientId = investor.client.id;
      final email = investor.client.email;
      
      _recipientEnabled[clientId] = email.isNotEmpty &&
          RegExp(r'^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$').hasMatch(email);
      _recipientEmails[clientId] = email;
    }
    
    // Wybierz pierwszego dostępnego odbiorcy dla podglądu
  }
  
  Future<void> _loadSmtpEmail() async {
    try {
      final smtpService = SmtpService();
      final smtpSettings = await smtpService.getSmtpSettings();
      if (smtpSettings != null && smtpSettings.username.isNotEmpty) {
        _senderEmailController.text = smtpSettings.username;
      }
    } catch (e) {
      // Zignoruj błąd - użytkownik może wprowadzić email ręcznie
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
    _quillController.dispose();
    _editorFocusNode.dispose();
    _senderEmailController.dispose();
    _senderNameController.dispose();
    _subjectController.dispose();
    _additionalEmailController.dispose();
    _settingsAnimationController.dispose();
    _editorAnimationController.dispose();
    super.dispose();
  }
  
  // 🎨 HELPERS DLA KONWERSJI HTML
  String _convertQuillToHtml() {
    try {
      if (_quillController.document.length <= 1) {
        return '<p></p>';
      }
      
      final plainText = _quillController.document.toPlainText();
      if (plainText.trim().isEmpty) {
        return '<p></p>';
      }
      
      // Użyj uproszczonej konwersji
      final converter = QuillDeltaToHtmlConverter(
        _quillController.document.toDelta().toJson(),
        ConverterOptions(
          converterOptions: OpConverterOptions(
            inlineStylesFlag: true,
            inlineStyles: InlineStyles({
              'bold': InlineStyleType(fn: (value, _) => 'font-weight: bold'),
              'italic': InlineStyleType(fn: (value, _) => 'font-style: italic'),
              'underline': InlineStyleType(fn: (value, _) => 'text-decoration: underline'),
              'strike': InlineStyleType(fn: (value, _) => 'text-decoration: line-through'),
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
      debugPrint('Error converting to HTML: $e');
      return '<p>${_quillController.document.toPlainText()}</p>';
    }
  }
  
  // 🎯 GŁÓWNE AKCJE
  void _insertInvestmentDetails() {
    final cursor = _quillController.selection.baseOffset;
    final investmentText = _generateInvestmentDetailsText();
    
    _quillController.document.insert(cursor, investmentText);
    _quillController.updateSelection(
      TextSelection.collapsed(offset: cursor + investmentText.length),
      ChangeSource.local,
    );
  }
  
  // 💰 GENEROWANIE SZCZEGÓŁÓW INWESTYCJI Z PRAWDZIWYMI DANYMI
  String _generateInvestmentDetailsText() {
    if (widget.selectedInvestors.isEmpty) {
      return '\n\n=== BRAK DANYCH INWESTYCYJNYCH ===\n\nNie wybrano żadnych inwestorów.\n\n';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('\n\n=== SZCZEGÓŁY INWESTYCJI ===\n');
    
    // Grupowanie danych
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
    
    // Podsumowanie ogólne
    buffer.writeln('📊 PODSUMOWANIE PORTFELA:');
    buffer.writeln('• Całkowita wartość inwestycji: ${_formatCurrency(totalInvestmentAmount)}');
    buffer.writeln('• Kapitał pozostały: ${_formatCurrency(totalRemainingCapital)}');
    buffer.writeln('• Wartość udziałów: ${_formatCurrency(totalSharesValue)}');
    buffer.writeln('• Liczba inwestycji: $totalInvestments');
    buffer.writeln('• Liczba inwestorów: ${widget.selectedInvestors.length}');
    buffer.writeln();
    
    // Szczegóły dla każdego inwestora (max 5)
    final limitedInvestors = widget.selectedInvestors.take(5).toList();
    
    if (limitedInvestors.length == 1) {
      buffer.writeln('👤 SZCZEGÓŁY INWESTORA:');
    } else {
      buffer.writeln('👥 SZCZEGÓŁY INWESTORÓW:');
    }
    
    for (int i = 0; i < limitedInvestors.length; i++) {
      final investor = limitedInvestors[i];
      final client = investor.client;
      
      buffer.writeln();
      buffer.writeln('${i + 1}. ${client.name}');
      buffer.writeln('   📧 Email: ${client.email}');
      buffer.writeln('   💰 Kapitał pozostały: ${_formatCurrency(investor.totalRemainingCapital)}');
      buffer.writeln('   📈 Wartość udziałów: ${_formatCurrency(investor.totalSharesValue)}');
      buffer.writeln('   🔢 Liczba inwestycji: ${investor.investmentCount}');
      
      // Dodaj zabezpieczenia nieruchomościami jeśli są
      if (investor.capitalSecuredByRealEstate > 0) {
        buffer.writeln('   🏠 Zabezpieczone nieruchomościami: ${_formatCurrency(investor.capitalSecuredByRealEstate)}');
      }
    }
    
    // Informacja o pozostałych inwestorach
    if (widget.selectedInvestors.length > 5) {
      buffer.writeln();
      buffer.writeln('...oraz ${widget.selectedInvestors.length - 5} innych inwestorów.');
    }
    
    // Stopka
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('Dane aktualne na dzień: ${_formatDate(DateTime.now())}');
    buffer.writeln('Metropolitan Investment');
    buffer.writeln();
    
    return buffer.toString();
  }
  
  // POMOCNICZE FUNKCJE FORMATOWANIA
  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} PLN';
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemePro.statusError,
            ),
            child: const Text('Wyczyść'),
          ),
        ],
      ),
    );
  }
  
  // 📧 ZARZĄDZANIE DODATKOWYMI EMAILAMI
  void _addAdditionalEmail() {
    final email = _additionalEmailController.text.trim();
    if (email.isEmpty) return;
    
    // Walidacja email
    if (!RegExp(r'^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$').hasMatch(email)) {
      setState(() {
        _error = 'Nieprawidłowy format adresu email: $email';
      });
      return;
    }
    
    // Sprawdź czy już nie istnieje
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
  
  // 🔄 TOGGLE EXPANDOWANIA EDYTORA Z EFEKTEM WOW
  void _toggleEditorExpansion() {
    setState(() {
      _isEditorExpanded = !_isEditorExpanded;
    });
    
    // Animacja bounce efekt dla edytora
    _editorAnimationController.reset();
    _editorAnimationController.forward();
  }
  
  // 🎭 TOGGLE ZWIJANIA SEKCJI USTAWIEŃ - GŁÓWNA ANIMACJA WOW
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
      
      // Tu będzie logika wysyłania emaili
      // Symulujemy wysyłanie
      await Future.delayed(const Duration(seconds: 2));
      
      // Używamy emailHtml w przyszłości do wysyłania
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
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canEdit = Provider.of<AuthProvider>(context).isAdmin;
        final isMobile = constraints.maxWidth < 600;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(isMobile ? 8 : 16),
          child: Container(
            width: constraints.maxWidth * (isMobile ? 0.95 : 0.85),
            height: constraints.maxHeight * (isMobile ? 0.95 : 0.9),
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
                _buildHeader(isMobile),
                Expanded(child: _buildMainContent(isMobile)),
                if (_error != null) _buildErrorBanner(),
                if (_results != null) _buildResultsBanner(),
                if (_isLoading) _buildLoadingBanner(),
                _buildActions(canEdit, isMobile),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // 📋 NAGŁÓWEK Z INSTRUKCJAMI
  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.backgroundPrimary,
            AppThemePro.accentGold.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppThemePro.accentGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.email_outlined,
                  color: AppThemePro.accentGold,
                  size: isMobile ? 24 : 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edytor Wiadomości Email',
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Odbiorcy: ${widget.selectedInvestors.length} inwestorów',
                      style: TextStyle(
                        color: AppThemePro.textSecondary,
                        fontSize: isMobile ? 13 : 15,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close,
                  color: AppThemePro.textSecondary,
                  size: isMobile ? 20 : 24,
                ),
                tooltip: 'Zamknij bez zapisywania',
              ),
            ],
          ),
          
          // 💡 INSTRUKCJE DLA UŻYTKOWNIKA
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppThemePro.statusInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppThemePro.statusInfo.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppThemePro.statusInfo,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Napisz wiadomość, użyj narzędzi formatowania, a następnie kliknij "Wyślij Wiadomości"',
                    style: TextStyle(
                      color: AppThemePro.statusInfo,
                      fontSize: isMobile ? 12 : 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // 📝 GŁÓWNA TREŚĆ - UPROSZCZONA
  Widget _buildMainContent(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // 📧 PODSTAWOWE USTAWIENIA EMAIL
            _buildEmailSettings(isMobile),
            const SizedBox(height: 20),
            
            // ✍️ EDYTOR TEKSTU
            Expanded(child: _buildEditor(isMobile)),
            const SizedBox(height: 16),
            
            // ⚙️ SZYBKIE OPCJE
            _buildQuickOptions(isMobile),
          ],
        ),
      ),
    );
  }
  
  // 📧 USTAWIENIA EMAIL - Z GLASSMORPHISM I WOW EFEKTAMI
  Widget _buildEmailSettings(bool isMobile) {
    return AnimatedBuilder(
      animation: _settingsSlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - _settingsSlideAnimation.value)),
          child: Opacity(
            opacity: _settingsOpacityAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                // 🌟 GLASSMORPHISM EFFECT
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppThemePro.backgroundSecondary.withValues(alpha: 0.8),
                    AppThemePro.backgroundPrimary.withValues(alpha: 0.9),
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
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppThemePro.accentGold.withValues(alpha: 0.2),
                                    AppThemePro.accentGold.withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppThemePro.accentGold.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Icon(Icons.settings, color: AppThemePro.accentGold, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ustawienia Wiadomości',
                                style: TextStyle(
                                  color: AppThemePro.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: isMobile ? 16 : 18,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            // 🎯 PRZYCISK ZWIJANIA/ROZWIJANIA
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppThemePro.accentGold.withValues(alpha: 0.2),
                                    AppThemePro.accentGold.withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: AppThemePro.accentGold.withValues(alpha: 0.4),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppThemePro.accentGold.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(15),
                                  onTap: _toggleSettingsCollapse,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedRotation(
                                          turns: _isSettingsCollapsed ? 0.5 : 0,
                                          duration: const Duration(milliseconds: 400),
                                          child: Icon(
                                            Icons.keyboard_arrow_up,
                                            color: AppThemePro.accentGold,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 300),
                                          child: Text(
                                            _isSettingsCollapsed ? 'Pokaż sekcje' : 'Ukryj sekcje',
                                            key: ValueKey(_isSettingsCollapsed),
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
            const SizedBox(height: 16),
            
            // Nadawca i temat
            if (!isMobile) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _senderEmailController,
                      decoration: InputDecoration(
                        labelText: 'Email nadawcy *',
                        hintText: 'twoj@email.com',
                        prefixIcon: const Icon(Icons.email),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Podaj email nadawcy';
                        }
                        if (!RegExp(r'^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$').hasMatch(value!)) {
                          return 'Nieprawidłowy format email';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _senderNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nazwa nadawcy',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Wersja mobilna - kolumnowo
              TextFormField(
                controller: _senderEmailController,
                decoration: InputDecoration(
                  labelText: 'Email nadawcy *',
                  hintText: 'twoj@email.com',
                  prefixIcon: const Icon(Icons.email),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Podaj email nadawcy';
                  if (!RegExp(r'^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$').hasMatch(value!)) {
                    return 'Nieprawidłowy format email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _senderNameController,
                decoration: const InputDecoration(
                  labelText: 'Nazwa nadawcy',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            
            // Temat
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Temat wiadomości *',
                hintText: 'Wprowadź temat...',
                prefixIcon: Icon(Icons.subject),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Podaj temat wiadomości';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Przełączniki opcji
            Row(
              children: [
                Expanded(
                  child: SwitchListTile.adaptive(
                    title: const Text('Dołącz szczegóły inwestycji'),
                    subtitle: const Text('Automatycznie dodaj tabelę inwestycji'),
                    value: _includeInvestmentDetails,
                    onChanged: (value) {
                      setState(() => _includeInvestmentDetails = value);
                    },
                    activeColor: AppThemePro.accentGold,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (!isMobile) const SizedBox(width: 16),
                if (!isMobile) 
                  Expanded(
                    child: SwitchListTile.adaptive(
                      title: const Text('Email grupowy (BCC)'),
                      subtitle: const Text('Jeden email do wszystkich'),
                      value: _isGroupEmail,
                      onChanged: (value) {
                        setState(() => _isGroupEmail = value);
                      },
                      activeColor: AppThemePro.accentGold,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
            if (isMobile) ...[
              SwitchListTile.adaptive(
                title: const Text('Email grupowy (BCC)'),
                subtitle: const Text('Jeden email do wszystkich odbiorców'),
                value: _isGroupEmail,
                onChanged: (value) {
                  setState(() => _isGroupEmail = value);
                },
                activeColor: AppThemePro.accentGold,
                contentPadding: EdgeInsets.zero,
              ),
            ],
            
            const SizedBox(height: 16),
            
            // 📧 ZARZĄDZANIE DODATKOWYMI EMAILAMI
            _buildAdditionalEmailsSection(),
          ],
        ),
      ),
    );
  }
  
  // 📧 SEKCJA DODATKOWYCH EMAILI
  Widget _buildAdditionalEmailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.email_outlined, color: AppThemePro.accentGold, size: 18),
            const SizedBox(width: 8),
            Text(
              'Dodatkowi odbiorcy',
              style: TextStyle(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Pole dodawania nowego email
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _additionalEmailController,
                decoration: const InputDecoration(
                  hintText: 'Dodaj adres email...',
                  prefixIcon: Icon(Icons.alternate_email),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: TextInputType.emailAddress,
                onFieldSubmitted: (_) => _addAdditionalEmail(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _addAdditionalEmail,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Dodaj'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemePro.accentGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        
        // Lista dodanych emaili
        if (_additionalEmails.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppThemePro.backgroundSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppThemePro.borderSecondary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dodani odbiorcy:',
                  style: TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _additionalEmails.map((email) {
                    return Chip(
                      label: Text(
                        email,
                        style: TextStyle(
                          color: AppThemePro.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                      deleteIcon: Icon(
                        Icons.close,
                        size: 16,
                        color: AppThemePro.statusError,
                      ),
                      onDeleted: () => _removeAdditionalEmail(email),
                      backgroundColor: AppThemePro.accentGold.withValues(alpha: 0.1),
                      side: BorderSide(color: AppThemePro.accentGold.withValues(alpha: 0.3)),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 8),
        
        // Lista odbiorców inwestorów
        _buildRecipientsList(),
      ],
    );
  }
  
  // 👥 LISTA ODBIORCÓW INWESTORÓW
  Widget _buildRecipientsList() {
    final enabledInvestors = widget.selectedInvestors
        .where((inv) => _recipientEnabled[inv.client.id] ?? true)
        .toList();
        
    if (enabledInvestors.isEmpty && _additionalEmails.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppThemePro.statusError.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppThemePro.statusError.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: AppThemePro.statusError, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Brak odbiorców! Dodaj przynajmniej jeden adres email.',
                style: TextStyle(
                  color: AppThemePro.statusError,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemePro.statusSuccess.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.statusSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppThemePro.statusSuccess, size: 16),
              const SizedBox(width: 6),
              Text(
                'Email zostanie wysłany do ${enabledInvestors.length + _additionalEmails.length} odbiorców:',
                style: TextStyle(
                  color: AppThemePro.statusSuccess,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Lista inwestorów
          if (enabledInvestors.isNotEmpty) ...[
            Text(
              'Inwestorzy:',
              style: TextStyle(
                color: AppThemePro.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            ...enabledInvestors.take(3).map((investor) {
              return Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 12, color: AppThemePro.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${investor.client.name} (${investor.client.email})',
                        style: TextStyle(
                          color: AppThemePro.textSecondary,
                          fontSize: 11,
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
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '...i ${enabledInvestors.length - 3} innych',
                  style: TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
          
          // Lista dodatkowych emaili
          if (_additionalEmails.isNotEmpty) ...[
            if (enabledInvestors.isNotEmpty) const SizedBox(height: 8),
            Text(
              'Dodatkowe adresy:',
              style: TextStyle(
                color: AppThemePro.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            ..._additionalEmails.map((email) {
              return Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Row(
                  children: [
                    Icon(Icons.email, size: 12, color: AppThemePro.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      email,
                      style: TextStyle(
                        color: AppThemePro.textSecondary,
                        fontSize: 11,
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
  
  // ✍️ EDYTOR Z TOOLBAR - UPROSZCZONY I CZYTELNY
  Widget _buildEditor(bool isMobile) {
    return Card(
      child: Column(
        children: [
          // Toolbar z opisami
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppThemePro.backgroundSecondary,
              border: Border(
                bottom: BorderSide(color: AppThemePro.borderPrimary),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.edit, color: AppThemePro.accentGold, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Narzędzia formatowania',
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
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
                    const Spacer(),
                    // Przycisk rozwijania edytora
                    IconButton(
                      onPressed: _toggleEditorExpansion,
                      icon: AnimatedRotation(
                        turns: _isEditorExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.expand_more,
                          color: AppThemePro.accentGold,
                          size: 20,
                        ),
                      ),
                      tooltip: _isEditorExpanded ? 'Zmniejsz edytor' : 'Rozwiń edytor',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Uproszczony toolbar
                QuillSimpleToolbar(
                  controller: _quillController,
                  config: QuillSimpleToolbarConfig(
                    multiRowsDisplay: false,
                    // Podstawowe formatowanie
                    showBoldButton: true,
                    showItalicButton: true,
                    showUnderLineButton: true,
                    showStrikeThrough: false,
                    
                    // Czcionki - tylko nasze wybrane
                    showFontFamily: !isMobile,
                    showFontSize: !isMobile,
                    
                    // Kolory
                    showColorButton: true,
                    showBackgroundColorButton: !isMobile,
                    
                    // Struktura
                    showHeaderStyle: true,
                    showListBullets: true,
                    showListNumbers: true,
                    showListCheck: false,
                    
                    // Wyrównanie
                    showAlignmentButtons: !isMobile,
                    showLeftAlignment: !isMobile,
                    showCenterAlignment: !isMobile,
                    showRightAlignment: !isMobile,
                    showJustifyAlignment: false,
                    
                    // Akcje
                    showUndo: true,
                    showRedo: true,
                    showClearFormat: true,
                    
                    // Ukryj zaawansowane
                    showQuote: false,
                    showInlineCode: false,
                    showCodeBlock: false,
                    showLink: false,
                    showSearchButton: false,
                    showSubscript: false,
                    showSuperscript: false,
                    showSmallButton: false,
                    showIndent: false,
                    showDirection: false,
                    
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
              ],
            ),
          ),
          
          // Edytor tekstu z animacją rozwijania
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            height: _isEditorExpanded ? 500 : 200,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: QuillEditor.basic(
                controller: _quillController,
                focusNode: _editorFocusNode,
                config: QuillEditorConfig(
                  placeholder: 'Napisz tutaj treść swojej wiadomości...',
                  autoFocus: false,
                  expands: false,
                  scrollable: true,
                  showCursor: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 🚀 SZYBKIE OPCJE - JASNO OPISANE
  Widget _buildQuickOptions(bool isMobile) {
    return Card(
      color: AppThemePro.backgroundSecondary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: AppThemePro.accentGold, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Szybkie Akcje',
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _insertInvestmentDetails,
                  icon: const Icon(Icons.attach_money, size: 16),
                  label: const Text('Dodaj sekcję inwestycji'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemePro.accentGold.withValues(alpha: 0.2),
                    foregroundColor: AppThemePro.accentGold,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _clearEditor,
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Wyczyść wszystko'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppThemePro.statusError,
                    side: BorderSide(color: AppThemePro.statusError),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => _buildPreviewDialog(),
                    );
                  },
                  icon: const Icon(Icons.preview, size: 16),
                  label: const Text('Podgląd email'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppThemePro.statusInfo,
                    side: BorderSide(color: AppThemePro.statusInfo),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 👁️ DIALOG PODGLĄDU
  Widget _buildPreviewDialog() {
    String htmlContent = _convertQuillToHtml();
    
    // Jeśli włączono szczegóły inwestycji, dodaj je na końcu
    if (_includeInvestmentDetails) {
      final investmentDetails = _generateInvestmentDetailsText();
      final investmentHtml = investmentDetails
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) {
            // Formatowanie nagłówków
            if (line.startsWith('===')) {
              return '<h3 style="color: #D4AF37; margin-top: 20px;">${line.replaceAll('=', '').trim()}</h3>';
            }
            // Formatowanie punktów
            if (line.startsWith('•')) {
              return '<p style="margin: 5px 0; padding-left: 15px;">$line</p>';
            }
            // Formatowanie numerowanych punktów
            if (RegExp(r'^\d+\.').hasMatch(line)) {
              return '<p style="font-weight: bold; color: #D4AF37; margin-top: 10px;">$line</p>';
            }
            // Formatowanie wcięć
            if (line.startsWith('   ')) {
              return '<p style="margin: 2px 0; padding-left: 25px; color: #666;">$line</p>';
            }
            // Formatowanie emoji linii
            if (line.contains('📊') || line.contains('👤') || line.contains('👥')) {
              return '<p style="font-weight: bold; color: #D4AF37; margin-top: 15px;">$line</p>';
            }
            // Formatowanie linii poziomej
            if (line.startsWith('---')) {
              return '<hr style="margin: 20px 0; border: 1px solid #D4AF37;">';
            }
            // Zwykłe linie
            return '<p style="margin: 5px 0;">$line</p>';
          })
          .join('\n');
      
      htmlContent = htmlContent.replaceAll('</body>', '$investmentHtml</body>');
      if (!htmlContent.contains('</body>')) {
        htmlContent += investmentHtml;
      }
    }
    
    return Dialog(
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header z informacją o odbiorcach
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppThemePro.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.preview, color: AppThemePro.accentGold, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Podgląd Wiadomości',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Email zostanie wysłany do ${_getEnabledRecipientsCount() + _additionalEmails.length} odbiorców',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppThemePro.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Preview content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: html.Html(
                    data: htmlContent,
                    style: {
                      'body': html.Style(
                        fontSize: html.FontSize(14),
                        fontFamily: 'Arial, sans-serif',
                        lineHeight: html.LineHeight(1.5),
                      ),
                      'h3': html.Style(
                        color: const Color(0xFFD4AF37),
                        fontSize: html.FontSize(18),
                        fontWeight: FontWeight.bold,
                      ),
                    },
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Zamknij'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Przejdź do wysyłania
                    _sendEmails();
                  },
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Wyślij teraz'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemePro.accentGold,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // ❌ BANNER BŁĘDU
  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemePro.statusError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.statusError),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: AppThemePro.statusError),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: AppThemePro.statusError),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _error = null),
            icon: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }
  
  // ✅ BANNER WYNIKÓW
  Widget _buildResultsBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemePro.statusSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.statusSuccess),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppThemePro.statusSuccess),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Wiadomości wysłane pomyślnie do ${_results!.length} odbiorców',
              style: TextStyle(color: AppThemePro.statusSuccess),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _results = null),
            icon: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }
  
  // ⏳ BANNER ŁADOWANIA
  Widget _buildLoadingBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemePro.statusInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.statusInfo),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppThemePro.statusInfo),
            ),
          ),
          const SizedBox(width: 12),
          const Text('Wysyłanie wiadomości...'),
        ],
      ),
    );
  }
  
  // 🎬 AKCJE DOLNE - JASNE I CZYTELNE
  Widget _buildActions(bool canEdit, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(
          top: BorderSide(color: AppThemePro.borderPrimary),
        ),
      ),
      child: Row(
        children: [
          // Info o liczbie odbiorców
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.people,
                  color: AppThemePro.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Wysłanie do ${_getTotalRecipientsCount()} odbiorców',
                  style: TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          
          // Przyciski akcji
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: canEdit && !_isLoading ? _sendEmails : null,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(_isLoading ? 'Wysyłanie...' : 'Wyślij Wiadomości'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemePro.accentGold,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 12 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  int _getEnabledRecipientsCount() {
    return _recipientEnabled.values.where((enabled) => enabled).length;
  }
  
  int _getTotalRecipientsCount() {
    return _getEnabledRecipientsCount() + _additionalEmails.length;
  }
}

// Klasa pomocnicza dla rezultatów wysyłania
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