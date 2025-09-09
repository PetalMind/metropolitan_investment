import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';

/// Widget do wysyłania maili do wybranych inwestorów
/// 
/// Pozwala na wybór szablonu email, personalizację wiadomości
/// i wysłanie maili z listą inwestycji.
class InvestorEmailDialog extends StatefulWidget {
  final List<InvestorSummary> selectedInvestors;
  final VoidCallback onEmailSent;

  const InvestorEmailDialog({
    super.key,
    required this.selectedInvestors,
    required this.onEmailSent,
  });

  @override
  State<InvestorEmailDialog> createState() => _InvestorEmailDialogState();
}

class _InvestorEmailDialogState extends State<InvestorEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _senderEmailController = TextEditingController();
  final _senderNameController = TextEditingController(text: 'Metropolitan Investment');
  final _subjectController = TextEditingController();
  final _customMessageController = TextEditingController();
  
  String _emailTemplate = 'summary';
  bool _isLoading = false;
  String? _error;
  List<EmailSendResult>? _results;

  final _emailAndExportService = EmailAndExportService();

  @override
  void initState() {
    super.initState();
    _subjectController.text = 'Twoje inwestycje w Metropolitan Investment - podsumowanie';
  }

  @override
  void dispose() {
    _senderEmailController.dispose();
    _senderNameController.dispose();
    _subjectController.dispose();
    _customMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: BoxConstraints(
          maxWidth: 700,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(child: _buildContent()),
            if (_results != null) _buildResults(),
            _buildActions(),
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
            AppTheme.secondaryGold,
            AppTheme.secondaryGold.withOpacity(0.8),
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
            Icons.email_outlined,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wyślij Email do Inwestorów',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Wybrano ${widget.selectedInvestors.length} inwestorów',
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

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lista wybranych inwestorów
            _buildSelectedInvestorsList(),
            
            const SizedBox(height: 24),
            
            // Formularz email
            _buildEmailForm(),
            
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
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
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedInvestorsList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.people_outline, size: 20),
                SizedBox(width: 8),
                Text(
                  'Wybrani Inwestorzy',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.selectedInvestors.length,
              itemBuilder: (context, index) {
                final investor = widget.selectedInvestors[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.secondaryGold,
                    child: Text(
                      investor.client.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    investor.client.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    '${investor.client.email ?? 'Brak email'} • ${investor.investmentCount} inwestycji',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    '${investor.totalRemainingCapital.toStringAsFixed(0)} PLN',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryGold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        
        // Szablon email
        DropdownButtonFormField<String>(
          value: _emailTemplate,
          decoration: const InputDecoration(
            labelText: 'Szablon Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          items: const [
            DropdownMenuItem(
              value: 'summary',
              child: Text('Podsumowanie (krótkie)'),
            ),
            DropdownMenuItem(
              value: 'detailed',
              child: Text('Szczegółowe (z tabelą)'),
            ),
            DropdownMenuItem(
              value: 'custom',
              child: Text('Niestandardowe'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _emailTemplate = value!;
            });
          },
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
        
        const SizedBox(height: 16),
        
        // Dodatkowa wiadomość
        TextFormField(
          controller: _customMessageController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Dodatkowa Wiadomość (opcjonalnie)',
            hintText: 'Dodaj osobistą wiadomość...',
            prefixIcon: Icon(Icons.message_outlined),
            alignLabelWithHint: true,
          ),
        ),
      ],
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
          
          if (_results!.length <= 5) ...[
            const SizedBox(height: 8),
            ...(_results!.map((result) => Text(
              result.formattedResult,
              style: const TextStyle(fontSize: 12),
            ))),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
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
          ElevatedButton.icon(
            onPressed: (_isLoading || !_hasValidEmails()) ? null : _sendEmails,
            icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(_isLoading ? 'Wysyłam...' : 'Wyślij Email'),
          ),
        ],
      ),
    );
  }

  bool _hasValidEmails() {
    return widget.selectedInvestors.any((investor) => 
        investor.client.email.isNotEmpty &&
        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(investor.client.email)
    );
  }

  String _generatePersonalizedHtmlContent(InvestorSummary investor) {
    final customMessage = _customMessageController.text.isNotEmpty
        ? _customMessageController.text
        : null;

    switch (_emailTemplate) {
      case 'summary':
        return '''
<p>Witaj ${investor.client.name},</p>

<p>Poniżej znajdziesz podsumowanie Twoich inwestycji w Metropolitan Investment:</p>

<ul>
  <li><strong>Liczba inwestycji:</strong> ${investor.investmentCount}</li>
  <li><strong>Całkowita wartość pozostała do spłaty:</strong> ${investor.totalRemainingCapital.toStringAsFixed(2)} PLN</li>
</ul>

${customMessage != null ? '<p>$customMessage</p>' : ''}

<p>Pozdrawiamy,<br/>
Zespół Metropolitan Investment</p>
''';

      case 'detailed':
        return '''
<p>Witaj ${investor.client.name},</p>

<p>Szczegółowe informacje o Twoich inwestycjach:</p>

<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse;">
  <tr>
    <th style="background-color: #f0f0f0;">Liczba inwestycji</th>
    <th style="background-color: #f0f0f0;">Wartość pozostała do spłaty</th>
  </tr>
  <tr>
    <td style="text-align: center;">${investor.investmentCount}</td>
    <td style="text-align: right;">${investor.totalRemainingCapital.toStringAsFixed(2)} PLN</td>
  </tr>
</table>

${customMessage != null ? '<p>$customMessage</p>' : ''}

<p>W razie pytań prosimy o kontakt.</p>

<p>Pozdrawiamy,<br/>
Zespół Metropolitan Investment</p>
''';

      case 'custom':
      default:
        return '''
<p>Witaj ${investor.client.name},</p>

${customMessage ?? 'Dziękujemy za zaufanie i wybór Metropolitan Investment.'}

<p>Pozdrawiamy,<br/>
Zespół Metropolitan Investment</p>
''';
    }
  }

  Future<void> _sendEmails() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Filtruj inwestorów z prawidłowymi emailami
    final investorsWithEmail = widget.selectedInvestors
        .where((investor) => 
            investor.client.email.isNotEmpty &&
            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(investor.client.email))
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
      // Przygotuj spersonalizowaną zawartość HTML dla każdego klienta
      final completeEmailHtmlByClient = <String, String>{};
      for (final investor in investorsWithEmail) {
        completeEmailHtmlByClient[investor.client.id] =
            _generatePersonalizedHtmlContent(investor);
      }

      final results = await _emailAndExportService
          .sendPreGeneratedEmailsToMixedRecipients(
        investors: investorsWithEmail,
            additionalEmails: [], // Brak dodatkowych emaili
        subject: _subjectController.text.isNotEmpty ? _subjectController.text : null,
            completeEmailHtmlByClient: completeEmailHtmlByClient,
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
}
