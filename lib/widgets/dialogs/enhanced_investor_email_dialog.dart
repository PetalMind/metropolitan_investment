import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme.dart';

/// 🚀 ROZSZERZONY DIALOG WYSYŁANIA MAILI DO INWESTORÓW
///
/// Pozwala na:
/// • Zaznaczenie wielu inwestorów z mozliwością wysłania im konkretnych list inwestycji
/// • Dowolną edycję treści maila i adresu email odbiorcy
/// • Edycję tytułu maila
/// • Personalizację dla każdego inwestora
/// • Preview wiadomości przed wysłaniem
/// • Bulk operations z progress tracking
class EnhancedInvestorEmailDialog extends StatefulWidget {
  final List<InvestorSummary> selectedInvestors;
  final VoidCallback onEmailSent;

  const EnhancedInvestorEmailDialog({
    super.key,
    required this.selectedInvestors,
    required this.onEmailSent,
  });

  @override
  State<EnhancedInvestorEmailDialog> createState() =>
      _EnhancedInvestorEmailDialogState();
}

class _EnhancedInvestorEmailDialogState
    extends State<EnhancedInvestorEmailDialog>
    with TickerProviderStateMixin {
  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _customMessageController = TextEditingController();
  final _senderEmailController = TextEditingController();
  final _senderNameController = TextEditingController(
    text: 'Metropolitan Investment',
  );
  late TabController _tabController;

  // State
  String _emailTemplate = 'detailed';
  bool _isLoading = false;
  String? _error;
  List<EmailSendResult>? _results;

  // Enhanced features
  Map<String, bool> _selectedInvestorIds = {};
  Map<String, String> _customEmails =
      {}; // Możliwość edycji emaili per inwestor
  Map<String, List<String>> _selectedInvestmentIds =
      {}; // Wybrane inwestycje per inwestor
  bool _personalizeForEachInvestor = true;
  bool _includeInvestmentDetails = true;
  bool _showPreview = false;

  final _emailAndExportService = EmailAndExportService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeDefaults();
  }

  void _initializeDefaults() {
    _subjectController.text =
        'Twoje inwestycje w Metropolitan Investment - szczegółowe podsumowanie';

    // Domyślnie wszystkich inwestorów zaznaczamy
    for (final investor in widget.selectedInvestors) {
      _selectedInvestorIds[investor.client.id] = true;
      _customEmails[investor.client.id] = investor.client.email;

      // Domyślnie wszystkie inwestycje inwestora
      _selectedInvestmentIds[investor.client.id] = investor.investments
          .map((inv) => inv.id)
          .toList();
    }

    _customMessageController.text = '''
Szanowni Państwo,

Przesyłamy Państwu aktualne podsumowanie inwestycji w naszej firmie.

W załączeniu znajdą Państwo szczegółowe informacje dotyczące:
• Aktualnego stanu kapitału
• Szczegółów poszczególnych inwestycji
• Podsumowania finansowego

W razie pytań prosimy o kontakt.
    ''';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _customMessageController.dispose();
    _senderEmailController.dispose();
    _senderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRecipientsTab(),
                  _buildEmailContentTab(),
                  _buildPreviewTab(),
                  _buildSendTab(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.secondaryGold.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.email_outlined,
                  color: AppTheme.secondaryGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wyślij email do inwestorów',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    Text(
                      '${_getSelectedInvestorsCount()} z ${widget.selectedInvestors.length} inwestorów',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.backgroundSecondary,
                  foregroundColor: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.people), text: 'Odbiorcy'),
              Tab(icon: Icon(Icons.edit), text: 'Treść'),
              Tab(icon: Icon(Icons.preview), text: 'Podgląd'),
              Tab(icon: Icon(Icons.send), text: 'Wyślij'),
            ],
            labelColor: AppTheme.secondaryGold,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.secondaryGold,
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Akcje grupowe
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _selectAllInvestors,
                icon: const Icon(Icons.select_all),
                label: const Text('Zaznacz wszystkich'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryGold.withOpacity(0.1),
                  foregroundColor: AppTheme.secondaryGold,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _deselectAllInvestors,
                icon: const Icon(Icons.clear),
                label: const Text('Odznacz wszystkich'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                  foregroundColor: AppTheme.errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Lista inwestorów
          Expanded(
            child: ListView.builder(
              itemCount: widget.selectedInvestors.length,
              itemBuilder: (context, index) {
                final investor = widget.selectedInvestors[index];
                final isSelected =
                    _selectedInvestorIds[investor.client.id] ?? false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isSelected
                      ? AppTheme.secondaryGold.withOpacity(0.1)
                      : AppTheme.surfaceCard,
                  child: ExpansionTile(
                    leading: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          _selectedInvestorIds[investor.client.id] =
                              value ?? false;
                        });
                      },
                      activeColor: AppTheme.secondaryGold,
                    ),
                    title: Text(
                      investor.client.name,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Edytowalny email
                        TextField(
                          controller: TextEditingController(
                            text: _customEmails[investor.client.id] ?? '',
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: UnderlineInputBorder(),
                            isDense: true,
                          ),
                          style: const TextStyle(color: AppTheme.textSecondary),
                          onChanged: (value) {
                            _customEmails[investor.client.id] = value;
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kapitał: ${CurrencyFormatter.formatCurrency(investor.viableRemainingCapital)}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      // Lista inwestycji do wyboru
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wybierz inwestycje do wysłania (${investor.investments.length}):',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            ...investor.investments.map((investment) {
                              final isInvestmentSelected =
                                  _selectedInvestmentIds[investor.client.id]
                                      ?.contains(investment.id) ??
                                  false;

                              return CheckboxListTile(
                                value: isInvestmentSelected,
                                onChanged: isSelected
                                    ? (value) {
                                        setState(() {
                                          _selectedInvestmentIds[investor
                                                  .client
                                                  .id] ??=
                                              [];
                                          if (value ?? false) {
                                            _selectedInvestmentIds[investor
                                                    .client
                                                    .id]!
                                                .add(investment.id);
                                          } else {
                                            _selectedInvestmentIds[investor
                                                    .client
                                                    .id]!
                                                .remove(investment.id);
                                          }
                                        });
                                      }
                                    : null,
                                title: Text(
                                  investment.productName,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '${CurrencyFormatter.formatCurrency(investment.remainingCapital)} - ${investment.creditorCompany}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                activeColor: AppTheme.secondaryGold,
                                dense: true,
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailContentTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Temat
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Temat wiadomości',
                prefixIcon: const Icon(Icons.subject),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.backgroundSecondary,
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Podaj temat' : null,
            ),
            const SizedBox(height: 20),

            // Dane nadawcy
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _senderEmailController,
                    decoration: InputDecoration(
                      labelText: 'Email nadawcy',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundSecondary,
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Podaj email nadawcy';
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value!)) {
                        return 'Nieprawidłowy format email';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _senderNameController,
                    decoration: InputDecoration(
                      labelText: 'Nazwa nadawcy',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Szablon email
            DropdownButtonFormField<String>(
              value: _emailTemplate,
              decoration: InputDecoration(
                labelText: 'Szablon wiadomości',
                prefixIcon: const Icon(Icons.text_snippet_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.backgroundSecondary,
              ),
              items: const [
                DropdownMenuItem(value: 'summary', child: Text('Podsumowanie')),
                DropdownMenuItem(value: 'detailed', child: Text('Szczegółowy')),
                DropdownMenuItem(
                  value: 'custom',
                  child: Text('Niestandardowy'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _emailTemplate = value!;
                });
              },
            ),
            const SizedBox(height: 20),

            // Opcje
            Card(
              color: AppTheme.backgroundSecondary,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Personalizuj dla każdego inwestora'),
                      subtitle: const Text(
                        'Każdy inwestor dostanie tylko swoje inwestycje',
                      ),
                      value: _personalizeForEachInvestor,
                      onChanged: (value) {
                        setState(() {
                          _personalizeForEachInvestor = value;
                        });
                      },
                      activeColor: AppTheme.secondaryGold,
                    ),
                    SwitchListTile(
                      title: const Text('Dołącz szczegóły inwestycji'),
                      subtitle: const Text(
                        'Lista inwestycji w treści wiadomości',
                      ),
                      value: _includeInvestmentDetails,
                      onChanged: (value) {
                        setState(() {
                          _includeInvestmentDetails = value;
                        });
                      },
                      activeColor: AppTheme.secondaryGold,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Treść wiadomości
            Expanded(
              child: TextFormField(
                controller: _customMessageController,
                decoration: InputDecoration(
                  labelText: 'Treść wiadomości',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundSecondary,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTab() {
    if (!_showPreview) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.preview, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Wygeneruj podgląd wiadomości',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showPreview = true;
                });
              },
              icon: const Icon(Icons.preview),
              label: const Text('Generuj podgląd'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryGold,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Wybierz pierwszego zaznaczonego inwestora do podglądu
    final selectedInvestor = widget.selectedInvestors.firstWhere(
      (inv) => _selectedInvestorIds[inv.client.id] ?? false,
      orElse: () => widget.selectedInvestors.first,
    );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Podgląd dla: ${selectedInvestor.client.name}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showPreview = false;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Odśwież'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderSecondary),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header maila
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundSecondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Do: ${_customEmails[selectedInvestor.client.id]}',
                          ),
                          Text(
                            'Od: ${_senderNameController.text} <${_senderEmailController.text}>',
                          ),
                          Text('Temat: ${_subjectController.text}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Treść maila - preview
                    _buildEmailPreviewContent(selectedInvestor),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendTab() {
    final selectedCount = _getSelectedInvestorsCount();
    final totalInvestments = _getTotalSelectedInvestments();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Podsumowanie
          Card(
            color: AppTheme.backgroundSecondary,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Podsumowanie wysyłki',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Odbiorcy', '$selectedCount inwestorów'),
                  _buildSummaryRow('Inwestycje', '$totalInvestments wybranych'),
                  _buildSummaryRow('Temat', _subjectController.text),
                  _buildSummaryRow('Szablon', _getTemplateDisplayName()),
                  _buildSummaryRow(
                    'Personalizacja',
                    _personalizeForEachInvestor ? 'Tak' : 'Nie',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Progress i wyniki
          if (_isLoading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Wysyłanie wiadomości...'),
          ],

          if (_results != null) ...[
            _buildResultsSummary(),
            const SizedBox(height: 16),
            Expanded(child: _buildResultsList()),
          ],

          if (_error != null) ...[
            Card(
              color: AppTheme.errorColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error, color: AppTheme.errorColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const Spacer(),

          // Przycisk wysyłania
          if (!_isLoading && _results == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: selectedCount > 0 ? _sendEmails : null,
                icon: const Icon(Icons.send),
                label: Text('Wyślij do $selectedCount inwestorów'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryGold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          const Spacer(),
          if (_tabController.index > 0)
            TextButton.icon(
              onPressed: () {
                _tabController.animateTo(_tabController.index - 1);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Wstecz'),
            ),
          const SizedBox(width: 12),
          if (_tabController.index < 3)
            ElevatedButton.icon(
              onPressed: _canGoToNextTab()
                  ? () {
                      _tabController.animateTo(_tabController.index + 1);
                    }
                  : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Dalej'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryGold,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  // Helper methods
  int _getSelectedInvestorsCount() {
    return _selectedInvestorIds.values.where((selected) => selected).length;
  }

  int _getTotalSelectedInvestments() {
    return _selectedInvestmentIds.values.fold<int>(
      0,
      (sum, investments) => sum + investments.length,
    );
  }

  String _getTemplateDisplayName() {
    switch (_emailTemplate) {
      case 'summary':
        return 'Podsumowanie';
      case 'detailed':
        return 'Szczegółowy';
      case 'custom':
        return 'Niestandardowy';
      default:
        return 'Nieznany';
    }
  }

  bool _canGoToNextTab() {
    switch (_tabController.index) {
      case 0: // Recipients tab
        return _getSelectedInvestorsCount() > 0;
      case 1: // Content tab
        return _formKey.currentState?.validate() ?? false;
      case 2: // Preview tab
        return true;
      default:
        return true;
    }
  }

  void _selectAllInvestors() {
    setState(() {
      for (final investor in widget.selectedInvestors) {
        _selectedInvestorIds[investor.client.id] = true;
      }
    });
  }

  void _deselectAllInvestors() {
    setState(() {
      for (final investor in widget.selectedInvestors) {
        _selectedInvestorIds[investor.client.id] = false;
      }
    });
  }

  Widget _buildEmailPreviewContent(InvestorSummary investor) {
    final selectedInvestments = investor.investments
        .where(
          (inv) =>
              _selectedInvestmentIds[investor.client.id]?.contains(inv.id) ??
              false,
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Szanowny/a ${investor.client.name},',
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
        const SizedBox(height: 16),

        Text(
          _customMessageController.text,
          style: const TextStyle(fontSize: 14, color: Colors.black),
        ),
        const SizedBox(height: 16),

        if (_includeInvestmentDetails && selectedInvestments.isNotEmpty) ...[
          Text(
            'SZCZEGÓŁY INWESTYCJI:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),

          ...selectedInvestments.map(
            (investment) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '• ${investment.productName}\n'
                '  Kapitał pozostały: ${CurrencyFormatter.formatCurrency(investment.remainingCapital)}\n'
                '  Spółka: ${investment.creditorCompany}',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'PODSUMOWANIE:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            '• Liczba inwestycji: ${selectedInvestments.length}\n'
            '• Łączny kapitał pozostały: ${CurrencyFormatter.formatCurrency(selectedInvestments.fold<double>(0, (sum, inv) => sum + inv.remainingCapital))}',
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 16),
        ],

        const Text(
          'Z poważaniem,\nZespół Metropolitan Investment',
          style: TextStyle(fontSize: 14, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSummary() {
    final successful = _results?.where((r) => r.success).length ?? 0;
    final failed = (_results?.length ?? 0) - successful;

    return Card(
      color: successful == _results?.length
          ? AppTheme.successColor.withOpacity(0.1)
          : AppTheme.warningColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              successful == _results?.length
                  ? Icons.check_circle
                  : Icons.warning,
              color: successful == _results?.length
                  ? AppTheme.successColor
                  : AppTheme.warningColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                failed == 0
                    ? '✅ Wysłano $successful maili pomyślnie'
                    : '⚠️ Wysłano $successful maili, błędów: $failed',
                style: TextStyle(
                  color: successful == _results?.length
                      ? AppTheme.successColor
                      : AppTheme.warningColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      itemCount: _results?.length ?? 0,
      itemBuilder: (context, index) {
        final result = _results![index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: result.success
                  ? AppTheme.successColor
                  : AppTheme.errorColor,
            ),
            title: Text(result.clientName),
            subtitle: Text(
              result.success
                  ? 'Email wysłany pomyślnie'
                  : result.error ?? 'Nieznany błąd',
            ),
            trailing: result.success
                ? Text(
                    '${result.investmentCount} inw.',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  )
                : const Icon(Icons.error_outline, color: AppTheme.errorColor),
          ),
        );
      },
    );
  }

  Future<void> _sendEmails() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(1); // Go to content tab
      return;
    }

    final selectedInvestors = widget.selectedInvestors
        .where((inv) => _selectedInvestorIds[inv.client.id] ?? false)
        .toList();

    if (selectedInvestors.isEmpty) {
      setState(() {
        _error = 'Nie wybrano żadnych inwestorów';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _results = null;
    });

    try {
      final results = <EmailSendResult>[];

      for (final investor in selectedInvestors) {
        final customEmail = _customEmails[investor.client.id];
        if (customEmail?.isEmpty ?? true) continue;

        // Filtruj inwestycje dla tego inwestora
        final selectedInvestmentIds =
            _selectedInvestmentIds[investor.client.id] ?? [];
        final filteredInvestments = investor.investments
            .where((inv) => selectedInvestmentIds.contains(inv.id))
            .toList();

        // Wyślij email
        final result = await _emailAndExportService.sendInvestmentEmailToClient(
          clientId: investor.client.id,
          clientEmail: customEmail ?? investor.client.email,
          clientName: investor.client.name,
          investmentIds: filteredInvestments.map((inv) => inv.id).toList(),
          emailTemplate: _emailTemplate,
          subject: _subjectController.text.isNotEmpty
              ? _subjectController.text
              : null,
          customMessage: _customMessageController.text.isNotEmpty
              ? _customMessageController.text
              : null,
          senderEmail: _senderEmailController.text,
          senderName: _senderNameController.text,
        );

        results.add(result);
      }

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
                ? AppTheme.successColor
                : AppTheme.warningColor,
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
}
