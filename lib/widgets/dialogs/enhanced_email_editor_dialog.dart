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
  State<EnhancedEmailEditorDialog> createState() =>
      _EnhancedEmailEditorDialogState();
}

class _EnhancedEmailEditorDialogState extends State<EnhancedEmailEditorDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late QuillController _quillController;

  final _formKey = GlobalKey<FormState>();
  final _senderEmailController = TextEditingController();
  final _senderNameController = TextEditingController(
    text: 'Metropolitan Investment',
  );
  final _subjectController = TextEditingController();

  String _emailTemplate = 'custom';
  bool _isLoading = false;
  bool _includeInvestmentDetails = true;
  bool _isGroupEmail = false; // Czy wysyłać jako jeden grupowy mail
  String? _error;
  List<EmailSendResult>? _results;
  String _previewHtml = '';

  // Zmienne dla testowania SMTP
  bool _isTesting = false;
  bool _isSendingTest = false;
  String? _testResult;

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

    // Inicjalizacja QuillController z początkową treścią
    _quillController = QuillController.basic();

    // Ustawienie początkowych wartości
    _subjectController.text =
        widget.initialSubject ??
        'Aktualizacja portfela inwestycyjnego - Metropolitan Investment';

    if (widget.initialMessage != null) {
      _insertInitialContent(widget.initialMessage!);
    } else {
      _insertDefaultTemplate();
    }

    // Nasłuchiwanie zmian w edytorze dla aktualizacji podglądu
    _quillController.addListener(_updatePreview);

    // Inicjalizacja map odbiorców
    _initializeRecipients();
  }

  void _insertInitialContent(String content) {
    final document = Document()..insert(0, content);
    _quillController.document = document;
  }

  void _initializeRecipients() {
    for (final investor in widget.selectedInvestors) {
      final clientId = investor.client.id;
      final email = investor.client.email ?? '';

      _recipientEnabled[clientId] =
          email.isNotEmpty &&
          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
      _recipientEmails[clientId] = email;
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
      0.0,
      (sum, inv) => sum + inv.investmentAmount,
    );

    String details =
        '''
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
      details +=
          '''
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

            // Sekcja testowania SMTP
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue[50],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings_remote, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Test Połączenia SMTP',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sprawdź czy serwer email jest poprawnie skonfigurowany przed wysyłaniem maili.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTesting ? null : _testSmtpConnection,
                          icon: _isTesting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.wifi_tethering),
                          label: Text(
                            _isTesting ? 'Testowanie...' : 'Test Połączenia',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[100],
                            foregroundColor: Colors.blue[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              (_isSendingTest ||
                                  _senderEmailController.text.trim().isEmpty)
                              ? null
                              : _sendTestEmail,
                          icon: _isSendingTest
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.email_outlined),
                          label: Text(
                            _isSendingTest ? 'Wysyłanie...' : 'Wyślij Test',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[100],
                            foregroundColor: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: _testResult!.startsWith('✅')
                            ? Colors.green[100]
                            : Colors.red[100],
                      ),
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          color: _testResult!.startsWith('✅')
                              ? Colors.green[700]
                              : Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
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

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppThemePro.borderPrimary),
          borderRadius: BorderRadius.circular(8),
          color: isEnabled ? AppThemePro.profitGreenBg : AppThemePro.lossRedBg,
        ),
        child: ListTile(
          leading: Switch(
            value: isEnabled,
            onChanged: (value) {
              setState(() {
                _recipientEnabled[clientId] = value;
              });
            },
            activeColor: AppThemePro.accentGold,
          ),
          title: Text(
            investor.client.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${investor.investmentCount} inwestycji',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              TextFormField(
                initialValue: currentEmail,
                enabled: isEnabled,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'adres@email.com',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  prefixIcon: const Icon(Icons.email, size: 16),
                ),
                style: const TextStyle(fontSize: 12),
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
            ],
          ),
          trailing: isEnabled
              ? Icon(Icons.check_circle, color: Colors.green[700], size: 20)
              : Icon(Icons.cancel, color: Colors.red[700], size: 20),
        ),
      );
    }).toList();
  }

  List<Widget> _buildAdditionalEmailsList() {
    return _additionalEmails.asMap().entries.map((entry) {
      final index = entry.key;
      final email = entry.value;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppThemePro.borderPrimary),
          borderRadius: BorderRadius.circular(8),
          color: AppThemePro.backgroundTertiary,
        ),
        child: ListTile(
          leading: const Icon(Icons.person_add, color: Colors.blue),
          title: TextFormField(
            initialValue: email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'dodatkowy@email.com',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              prefixIcon: const Icon(Icons.email, size: 16),
            ),
            onChanged: (value) {
              _additionalEmails[index] = value;
            },
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.check,
                  color: AppThemePro.statusSuccess,
                  size: 20,
                ),
                onPressed: () {
                  // Potwierdzenie dodania adresu
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Adres ${email.isNotEmpty ? email : "(pusty)"} został potwierdzony',
                      ),
                      backgroundColor: AppThemePro.statusSuccess,
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
                    _additionalEmails.removeAt(index);
                  });
                },
                tooltip: 'Usuń adres',
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

    final email = _recipientEmails[recipientId] ?? investor.client.email ?? '';
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

  Widget _buildInvestmentDetailsPreview(String clientId) {
    final investor = widget.selectedInvestors.firstWhere(
      (inv) => inv.client.id == clientId,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Podsumowanie Twojego Portfela',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Statystyki
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Liczba inwestycji',
                  investor.investmentCount.toString(),
                  Icons.account_balance_wallet,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Kapitał pozostały',
                  '${investor.totalRemainingCapital.toStringAsFixed(2)} PLN',
                  Icons.monetization_on,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Lista inwestycji (pierwsze 3)
          if (investor.investments.isNotEmpty) ...[
            Text(
              'Ostatnie inwestycje:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blue[700],
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            investment.productName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${investment.remainingCapital.toStringAsFixed(2)} PLN',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            if (investor.investments.length > 3)
              Text(
                '... i ${investor.investments.length - 3} więcej',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
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
                'Liczba inwestycji: ${investor.investmentCount}',
                style: const TextStyle(
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.blue[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.blue[600]),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
            child: Text(_error!, style: TextStyle(color: Colors.red[700])),
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
    final signature =
        '\n\nZ poważaniem,\nZespół ${_senderNameController.text}\n';
    final length = _quillController.document.length;
    _quillController.document.insert(length - 1, signature);
  }

  void _clearEditor() {
    _quillController.clear();
  }

  bool _hasValidEmails() {
    return widget.selectedInvestors.any(
      (investor) =>
          investor.client.email != null &&
          investor.client.email!.isNotEmpty &&
          RegExp(
            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
          ).hasMatch(investor.client.email!),
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

    // Sprawdź czy istnieją konfiguracje SMTP
    setState(() {
      _isLoading = true;
      _error = null;
      _results = null;
    });

    try {
      // Sprawdź ustawienia SMTP przed wysyłaniem
      final smtpService = SmtpService();
      final smtpSettings = await smtpService.getSmtpSettings();

      if (smtpSettings == null) {
        setState(() {
          _error =
              'Brak konfiguracji serwera SMTP. Skonfiguruj ustawienia email w aplikacji.';
          _isLoading = false;
        });
        return;
      }

      // Walidacja email wysyłającego
      if (_senderEmailController.text.trim().isEmpty) {
        setState(() {
          _error = 'Podaj email wysyłającego';
          _isLoading = false;
        });
        return;
      }

      // Pobierz inwestorów z włączonymi emailami
      final enabledRecipients = _getEnabledRecipients();

      if (enabledRecipients.isEmpty) {
        setState(() {
          _error = 'Brak odbiorców z prawidłowymi adresami email';
          _isLoading = false;
        });
        return;
      }

      // Konwersja treści z Quill do HTML
      final htmlContent = _convertDocumentToHtml(_quillController.document);

      if (htmlContent.trim().isEmpty) {
        setState(() {
          _error = 'Treść emaila nie może być pusta';
          _isLoading = false;
        });
        return;
      }

      // Przygotuj listę odbiorców
      final recipientsWithInvestmentData = <InvestorSummary>[];

      for (final recipient in enabledRecipients) {
        final recipientId = recipient['id']!;

        if (recipientId.startsWith('additional_')) {
          // Dla dodatkowych emaili nie dodajemy ich do głównej listy
          // Będą obsługiwane osobno w przyszłych wersjach
          continue;
        } else {
          // Znajdź prawdziwego inwestora
          final investor = widget.selectedInvestors.firstWhere(
            (inv) => inv.client.id == recipientId,
            orElse: () => widget.selectedInvestors.first,
          );

          // Aktualizuj email jeśli został zmieniony
          final updatedEmail =
              _recipientEmails[recipientId] ?? investor.client.email;
          if (updatedEmail != investor.client.email) {
            // Tworzy kopię inwestora z zaktualizowanym emailem
            // W rzeczywistej implementacji możesz potrzebować bardziej zaawansowanej logiki
          }

          recipientsWithInvestmentData.add(investor);
        }
      }

      // Wywołaj zintegrowaną funkcję wysyłania
      final results = await _emailAndExportService
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
      setState(() {
        _error = 'Błąd podczas wysyłania maili: ${e.toString()}';
        _isLoading = false;
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

  /// Testuje połączenie SMTP
  Future<void> _testSmtpConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final smtpService = SmtpService();
      final smtpSettings = await smtpService.getSmtpSettings();

      if (smtpSettings == null) {
        setState(() {
          _testResult =
              '❌ Brak konfiguracji SMTP. Skonfiguruj ustawienia w aplikacji.';
        });
        return;
      }

      final result = await smtpService.testSmtpConnection(smtpSettings);

      setState(() {
        if (result['success'] == true) {
          _testResult =
              '✅ Połączenie pomyślne! Czas odpowiedzi: ${result['details']['responseTime']}ms';
        } else {
          _testResult = '❌ Błąd połączenia: ${result['error']}';
        }
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Błąd podczas testowania: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  /// Wysyła testowy email
  Future<void> _sendTestEmail() async {
    if (_senderEmailController.text.trim().isEmpty) {
      setState(() {
        _testResult = '❌ Podaj email wysyłającego przed testem';
      });
      return;
    }

    setState(() {
      _isSendingTest = true;
      _testResult = null;
    });

    try {
      final smtpService = SmtpService();
      final smtpSettings = await smtpService.getSmtpSettings();

      if (smtpSettings == null) {
        setState(() {
          _testResult =
              '❌ Brak konfiguracji SMTP. Skonfiguruj ustawienia w aplikacji.';
        });
        return;
      }

      final result = await smtpService.sendTestEmail(
        settings: smtpSettings,
        testEmail: _senderEmailController.text.trim(),
        customMessage: 'Test z edytora email - Metropolitan Investment',
      );

      setState(() {
        if (result['success'] == true) {
          _testResult =
              '✅ Email testowy wysłany! ID: ${result['details']['messageId']}';
        } else {
          _testResult = '❌ Błąd wysyłania: ${result['error']}';
        }
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Błąd podczas wysyłania: $e';
      });
    } finally {
      setState(() {
        _isSendingTest = false;
      });
    }
  }
}
