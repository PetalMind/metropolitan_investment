import 'package:flutter/material.dart';
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
  State<EnhancedEmailEditorDialog> createState() => _EnhancedEmailEditorDialogState();
}

class _EnhancedEmailEditorDialogState extends State<EnhancedEmailEditorDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late QuillController _quillController;
  
  final _formKey = GlobalKey<FormState>();
  final _senderEmailController = TextEditingController();
  final _senderNameController = TextEditingController(text: 'Metropolitan Investment');
  final _subjectController = TextEditingController();
  
  String _emailTemplate = 'custom';
  bool _isLoading = false;
  bool _includeInvestmentDetails = true;
  String? _error;
  List<EmailSendResult>? _results;
  String _previewHtml = '';

  final _emailAndExportService = EmailAndExportService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Inicjalizacja QuillController z początkową treścią
    _quillController = QuillController.basic();
    
    // Ustawienie początkowych wartości
    _subjectController.text = widget.initialSubject ?? 
        'Aktualizacja portfela inwestycyjnego - Metropolitan Investment';
    
    if (widget.initialMessage != null) {
      _insertInitialContent(widget.initialMessage!);
    } else {
      _insertDefaultTemplate();
    }
    
    // Nasłuchiwanie zmian w edytorze dla aktualizacji podglądu
    _quillController.addListener(_updatePreview);
  }

  void _insertInitialContent(String content) {
    final document = Document()..insert(0, content);
    _quillController.document = document;
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
      _previewHtml = _generateEmailPreview();
    });
  }

  String _generateEmailPreview() {
    if (widget.selectedInvestors.isEmpty) return '';
    
    final investor = widget.selectedInvestors.first;
    final deltaToHtml = _convertDocumentToHtml(_quillController.document);
    
    // Generowanie podstawowego HTML z Quill content
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { 
      font-family: Arial, sans-serif; 
      line-height: 1.6; 
      color: #333; 
      max-width: 600px; 
      margin: 0 auto; 
      padding: 20px; 
    }
    .header { 
      background: linear-gradient(135deg, #1a237e, #3949ab); 
      color: white; 
      padding: 30px 20px; 
      text-align: center; 
      border-radius: 8px 8px 0 0; 
    }
    .content { 
      background: white; 
      padding: 30px; 
      border: 1px solid #e0e0e0; 
    }
    .summary { 
      background: #f8f9fa; 
      padding: 20px; 
      margin: 20px 0; 
      border-radius: 8px; 
      border-left: 4px solid #1a237e; 
    }
    .footer { 
      background: #f5f5f5; 
      padding: 20px; 
      text-align: center; 
      font-size: 14px; 
      color: #666; 
      border-radius: 0 0 8px 8px; 
    }
    .investment-item { 
      border: 1px solid #e0e0e0; 
      padding: 15px; 
      margin: 10px 0; 
      border-radius: 8px; 
      background: #fafafa; 
    }
    .total { 
      font-weight: bold; 
      color: #1a237e; 
      font-size: 18px; 
    }
    table { 
      width: 100%; 
      border-collapse: collapse; 
      margin: 20px 0; 
    }
    th, td { 
      border: 1px solid #ddd; 
      padding: 12px; 
      text-align: left; 
    }
    th { 
      background-color: #1a237e; 
      color: white; 
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>${_senderNameController.text}</h1>
    <h2>Twój Portfel Inwestycyjny</h2>
  </div>
  
  <div class="content">
    <p><strong>Szanowny/a ${investor.client.name},</strong></p>
    
    <div class="message-content">
      $deltaToHtml
    </div>
    
    ${_includeInvestmentDetails ? _generateInvestmentDetailsHtml(investor) : ''}
  </div>
  
  <div class="footer">
    <p>Ten email został wygenerowany automatycznie ${DateTime.now().toLocal().toString().split('.')[0]}.</p>
    <p><strong>${_senderNameController.text}</strong> - Profesjonalne Zarządzanie Kapitałem</p>
  </div>
</body>
</html>''';
  }

  String _generateInvestmentDetailsHtml(InvestorSummary investor) {
    if (investor.investments.isEmpty) return '';

    final totalInvestment = investor.investments.fold<double>(
      0.0, (sum, inv) => sum + inv.investmentAmount);
    
    String details = '''
    <div class="summary">
      <h3>📊 Podsumowanie Twojego Portfela</h3>
      <p><strong>Liczba inwestycji:</strong> ${investor.investments.length}</p>
      <p><strong>Całkowita kwota inwestycji:</strong> <span class="total">${totalInvestment.toStringAsFixed(2)} PLN</span></p>
      <p><strong>Kapitał pozostały:</strong> <span class="total">${investor.totalRemainingCapital.toStringAsFixed(2)} PLN</span></p>
    </div>
    
    <h3>📋 Szczegóły Inwestycji</h3>
    <table>
      <thead>
        <tr>
          <th>Produkt</th>
          <th>Kwota Inwestycji</th>
          <th>Kapitał Pozostały</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody>''';

    for (final investment in investor.investments) {
      details += '''
        <tr>
          <td>${investment.productName}</td>
          <td>${investment.investmentAmount.toStringAsFixed(2)} PLN</td>
          <td>${investment.remainingCapital.toStringAsFixed(2)} PLN</td>
          <td>${investment.status ?? 'Aktywna'}</td>
        </tr>''';
    }

    details += '''
      </tbody>
    </table>''';

    return details;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quillController.dispose();
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
            AppThemePro.accentGold,
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
          const Icon(
            Icons.edit_outlined,
            color: Colors.white,
            size: 28,
          ),
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
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
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
      children: [
        _buildEditorTab(),
        _buildSettingsTab(),
        _buildPreviewTab(),
      ],
    );
  }

  Widget _buildEditorTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Toolbar
          QuillSimpleToolbar(
            controller: _quillController,
            config: const QuillSimpleToolbarConfig(
              multiRowsDisplay: false,
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showStrikeThrough: true,
              showColorButton: true,
              showBackgroundColorButton: true,
              showListNumbers: true,
              showListBullets: true,
              showCodeBlock: false,
              showQuote: true,
              showLink: true,
              showDirection: false,
              showSearchButton: false,
              showFontFamily: false,
              showFontSize: true,
              showHeaderStyle: true,
              showAlignmentButtons: true,
              showCenterAlignment: true,
              showLeftAlignment: true,
              showRightAlignment: true,
              showJustifyAlignment: true,
            ),
          ),
          
          const Divider(),
          
          // Editor
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: QuillEditor.basic(
                controller: _quillController,
                config: const QuillEditorConfig(
                  placeholder: 'Wpisz treść swojego maila...',
                  padding: EdgeInsets.all(16),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Szybkie akcje
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _insertGreeting,
                icon: const Icon(Icons.waving_hand, size: 16),
                label: const Text('Dodaj powitanie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[100],
                  foregroundColor: Colors.blue[700],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _insertSignature,
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text('Dodaj podpis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[100],
                  foregroundColor: Colors.green[700],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _clearEditor,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Wyczyść'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[100],
                  foregroundColor: Colors.red[700],
                ),
              ),
            ],
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
            
            // Lista odbiorców
            const SizedBox(height: 24),
            Text(
              'Odbiorcy (${widget.selectedInvestors.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: widget.selectedInvestors.length,
                itemBuilder: (context, index) {
                  final investor = widget.selectedInvestors[index];
                  final hasValidEmail = investor.client.email != null && 
                      investor.client.email!.isNotEmpty &&
                      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(investor.client.email!);
                  
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      hasValidEmail ? Icons.email : Icons.email_outlined,
                      color: hasValidEmail ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    title: Text(
                      investor.client.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      investor.client.email ?? 'Brak email',
                      style: TextStyle(
                        fontSize: 12,
                        color: hasValidEmail ? Colors.grey[600] : Colors.red,
                      ),
                    ),
                    trailing: Text(
                      '${investor.investmentCount} inv.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
              ElevatedButton.icon(
                onPressed: _updatePreview,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Odśwież'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (widget.selectedInvestors.isNotEmpty) ...[
            Text(
              'Przykład dla: ${widget.selectedInvestors.first.client.name}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
          ],
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _previewHtml.isNotEmpty
                    ? SelectableText(
                        _previewHtml,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      )
                    : const Center(
                        child: Text(
                          'Brak treści do wyświetlenia.\nUżyj edytora, aby dodać treść.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
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
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
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
        ],
      ),
    );
  }

  Widget _buildActions(bool canEdit) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
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
                label: Text(_isLoading ? 'Wysyłam...' : 'Wyślij Email'),
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
    final greeting = 'Szanowni Państwo,\n\n';
    _quillController.document.insert(0, greeting);
  }

  void _insertSignature() {
    final signature = '\n\nZ poważaniem,\nZespół ${_senderNameController.text}\n';
    final length = _quillController.document.length;
    _quillController.document.insert(length - 1, signature);
  }

  void _clearEditor() {
    _quillController.clear();
  }

  bool _hasValidEmails() {
    return widget.selectedInvestors.any((investor) => 
        investor.client.email != null && 
        investor.client.email!.isNotEmpty &&
        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(investor.client.email!)
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
    
    // Filtruj inwestorów z prawidłowymi emailami
    final investorsWithEmail = widget.selectedInvestors
        .where((investor) => 
            investor.client.email != null && 
            investor.client.email!.isNotEmpty &&
            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(investor.client.email!))
        .toList();
    
    if (investorsWithEmail.isEmpty) {
      setState(() {
        _error = 'Brak inwestorów z prawidłowymi adresami email';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _results = null;
    });

    try {
      // Konwersja treści z Quill do HTML
      final htmlContent = _convertDocumentToHtml(_quillController.document);
      
      final results = await _emailAndExportService.sendCustomEmailsToMultipleClients(
        investors: investorsWithEmail,
        subject: _subjectController.text.isNotEmpty ? _subjectController.text : null,
        htmlContent: htmlContent,
        includeInvestmentDetails: _includeInvestmentDetails,
        senderEmail: _senderEmailController.text,
        senderName: _senderNameController.text,
      );

      setState(() {
        _results = results;
        _isLoading = false;
      });

      // Pokaż snackbar z podsumowaniem
      final successful = results.where((r) => r.success).length;
      final failed = results.length - successful;
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failed == 0 
                  ? '✅ Wysłano $successful maili pomyślnie'
                  : '⚠️ Wysłano $successful maili, błędów: $failed',
            ),
            backgroundColor: failed == 0 ? Colors.green[700] : Colors.orange[700],
          ),
        );
      }

      widget.onEmailSent();

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  // Pomocnicza metoda konwersji dokumentu Quill na HTML
  String _convertDocumentToHtml(Document document) {
    try {
      // Pobierz plain text z dokumentu
      final plainText = document.toPlainText();
      
      // Podstawowa konwersja na HTML
      return plainText
          .replaceAll('\n', '<br>')
          .replaceAll('  ', '&nbsp;&nbsp;'); // Zachowaj podwójne spacje
    } catch (e) {
      // Fallback w przypadku błędu
      return 'Błąd konwersji treści: $e';
    }
  }
}