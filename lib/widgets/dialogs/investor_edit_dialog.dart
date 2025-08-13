import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';
import '../premium_loading_widget.dart';

/// 📝 Dialog edycji inwestora
/// 
/// Pozwala edytować kwoty inwestycji dla wybranego inwestora w ramach produktu
/// Funkcjonalności:
/// - Edycja kwot pozostałego kapitału
/// - Edycja kwot inwestycji
/// - Edycja statusów inwestycji
/// - Walidacja danych
/// - Zapis zmian przez FirebaseFunctionsDataService
class InvestorEditDialog extends StatefulWidget {
  final InvestorSummary investor;
  final UnifiedProduct product;
  final VoidCallback onSaved;

  const InvestorEditDialog({
    super.key,
    required this.investor,
    required this.product,
    required this.onSaved,
  });

  @override
  State<InvestorEditDialog> createState() => _InvestorEditDialogState();
}

class _InvestorEditDialogState extends State<InvestorEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pl_PL',
    symbol: 'zł',
    decimalDigits: 2,
  );

  bool _isLoading = false;
  bool _isChanged = false;
  String? _error;

  // Controllers dla edytowanych wartości
  final List<TextEditingController> _remainingCapitalControllers = [];
  final List<TextEditingController> _investmentAmountControllers = [];
  final List<InvestmentStatus> _statusValues = [];

  // Kopia inwestycji do edycji
  late List<Investment> _editableInvestments;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    // Zwolnij wszystkie controllery
    for (final controller in _remainingCapitalControllers) {
      controller.dispose();
    }
    for (final controller in _investmentAmountControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeData() {
    // Znajdź inwestycje tego inwestora w danym produkcie
    _editableInvestments = widget.investor.investments
        .where((investment) => 
            investment.productId == widget.product.id ||
            (investment.productName == widget.product.name &&
             investment.creditorCompany == widget.product.companyName))
        .toList();

    // Utwórz controllery dla każdej inwestycji
    for (final investment in _editableInvestments) {
      _remainingCapitalControllers.add(
        TextEditingController(text: investment.remainingCapital.toString())
      );
      _investmentAmountControllers.add(
        TextEditingController(text: investment.investmentAmount.toString())
      );
      _statusValues.add(investment.status);
    }

    // Ustaw listenery do wykrywania zmian
    for (final controller in _remainingCapitalControllers) {
      controller.addListener(_onDataChanged);
    }
    for (final controller in _investmentAmountControllers) {
      controller.addListener(_onDataChanged);
    }
  }

  void _onDataChanged() {
    setState(() {
      _isChanged = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 800,
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
            Flexible(
              child: _buildContent(),
            ),
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
        color: AppThemePro.accentGold.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(color: AppThemePro.borderPrimary),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppThemePro.accentGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.edit,
              color: AppThemePro.accentGold,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edycja inwestora',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.investor.client.name} • ${widget.product.name}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemePro.textSecondary,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_editableInvestments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                color: AppThemePro.textMuted,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Brak inwestycji dla tego produktu',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppThemePro.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ten inwestor nie ma żadnych inwestycji w wybranym produkcie.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppThemePro.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ...[
              _buildErrorCard(),
              const SizedBox(height: 16),
            ],
            _buildInvestmentsSummary(),
            const SizedBox(height: 24),
            _buildInvestmentsEditList(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.lossRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.lossRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppThemePro.lossRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemePro.lossRed,
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _error = null),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentsSummary() {
    final totalRemainingCapital = _editableInvestments
        .fold(0.0, (sum, inv) => sum + inv.remainingCapital);
    final totalInvestmentAmount = _editableInvestments
        .fold(0.0, (sum, inv) => sum + inv.investmentAmount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Podsumowanie inwestycji',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryTile(
                  'Liczba inwestycji',
                  '${_editableInvestments.length}',
                  Icons.format_list_numbered,
                  AppThemePro.accentGold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryTile(
                  'Łączna kwota',
                  _currencyFormat.format(totalInvestmentAmount),
                  Icons.account_balance_wallet,
                  AppThemePro.bondsBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryTile(
                  'Pozostały kapitał',
                  _currencyFormat.format(totalRemainingCapital),
                  Icons.trending_up,
                  AppThemePro.profitGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentsEditList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edycja inwestycji (${_editableInvestments.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _editableInvestments.length,
          itemBuilder: (context, index) => _buildInvestmentEditCard(index),
        ),
      ],
    );
  }

  Widget _buildInvestmentEditCard(int index) {
    final investment = _editableInvestments[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header z informacjami o inwestycji
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(investment.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(investment.status),
                  color: _getStatusColor(investment.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inwestycja ${index + 1}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppThemePro.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'ID: ${investment.id.substring(0, 8)}...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppThemePro.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // Status dropdown
              _buildStatusDropdown(index),
            ],
          ),
          const SizedBox(height: 16),
          // Pola edycji
          Row(
            children: [
              Expanded(
                child: _buildCurrencyField(
                  label: 'Kwota inwestycji',
                  controller: _investmentAmountControllers[index],
                  icon: Icons.account_balance_wallet,
                  color: AppThemePro.bondsBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCurrencyField(
                  label: 'Pozostały kapitał',
                  controller: _remainingCapitalControllers[index],
                  icon: Icons.trending_up,
                  color: AppThemePro.profitGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.borderPrimary),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<InvestmentStatus>(
          value: _statusValues[index],
          onChanged: (InvestmentStatus? newStatus) {
            if (newStatus != null) {
              setState(() {
                _statusValues[index] = newStatus;
                _onDataChanged();
              });
            }
          },
          items: InvestmentStatus.values.map((status) {
            return DropdownMenuItem<InvestmentStatus>(
              value: status,
              child: Text(
                status.displayName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getStatusColor(status),
                ),
              ),
            );
          }).toList(),
          icon: Icon(
            Icons.arrow_drop_down,
            color: AppThemePro.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppThemePro.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: color, size: 20),
            suffixText: 'zł',
            suffixStyle: TextStyle(color: AppThemePro.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppThemePro.borderPrimary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color, width: 2),
            ),
            filled: true,
            fillColor: AppThemePro.surfaceElevated,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'To pole jest wymagane';
            }
            final double? parsedValue = double.tryParse(value);
            if (parsedValue == null || parsedValue < 0) {
              return 'Wprowadź prawidłową kwotę';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceElevated,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: AppThemePro.borderPrimary),
        ),
      ),
      child: Row(
        children: [
          if (_isChanged) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppThemePro.statusWarning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppThemePro.statusWarning.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit,
                    color: AppThemePro.statusWarning,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Niezapisane zmiany',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.statusWarning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ] else ...[
            const Spacer(),
          ],
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: Text('Anuluj'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: (_isLoading || !_isChanged) ? null : _saveChanges,
            icon: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppThemePro.backgroundPrimary,
                    ),
                  )
                : Icon(Icons.save),
            label: Text(_isLoading ? 'Zapisywanie...' : 'Zapisz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemePro.accentGold,
              foregroundColor: AppThemePro.backgroundPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(InvestmentStatus status) {
    switch (status) {
      case InvestmentStatus.active:
        return AppThemePro.statusSuccess;
      case InvestmentStatus.inactive:
        return AppThemePro.statusWarning;
      case InvestmentStatus.earlyRedemption:
        return AppThemePro.statusInfo;
      case InvestmentStatus.completed:
        return AppThemePro.profitGreen;
    }
  }

  IconData _getStatusIcon(InvestmentStatus status) {
    switch (status) {
      case InvestmentStatus.active:
        return Icons.check_circle;
      case InvestmentStatus.inactive:
        return Icons.pause_circle;
      case InvestmentStatus.earlyRedemption:
        return Icons.fast_forward;
      case InvestmentStatus.completed:
        return Icons.task_alt;
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Przygotuj listę zmian do zapisania
      final List<Investment> updatedInvestments = [];
      
      for (int i = 0; i < _editableInvestments.length; i++) {
        final originalInvestment = _editableInvestments[i];
        final newRemainingCapital = double.parse(_remainingCapitalControllers[i].text);
        final newInvestmentAmount = double.parse(_investmentAmountControllers[i].text);
        final newStatus = _statusValues[i];

        // Sprawdź czy są zmiany
        if (newRemainingCapital != originalInvestment.remainingCapital ||
            newInvestmentAmount != originalInvestment.investmentAmount ||
            newStatus != originalInvestment.status) {
          
          // Utwórz zaktualizowaną inwestycję
          final updatedInvestment = Investment(
            id: originalInvestment.id,
            clientId: originalInvestment.clientId,
            clientName: originalInvestment.clientName,
            productId: originalInvestment.productId,
            productName: originalInvestment.productName,
            productType: originalInvestment.productType,
            creditorCompany: originalInvestment.creditorCompany,
            companyId: originalInvestment.companyId,
            branchCode: originalInvestment.branchCode,
            employeeId: originalInvestment.employeeId,
            employeeFirstName: originalInvestment.employeeFirstName,
            employeeLastName: originalInvestment.employeeLastName,
            marketType: originalInvestment.marketType,
            proposalId: originalInvestment.proposalId,
            investmentAmount: newInvestmentAmount,
            paidAmount: originalInvestment.paidAmount,
            remainingCapital: newRemainingCapital,
            realizedCapital: originalInvestment.realizedCapital,
            realizedInterest: originalInvestment.realizedInterest,
            realizedTax: originalInvestment.realizedTax,
            transferToOtherProduct: originalInvestment.transferToOtherProduct,
            capitalSecuredByRealEstate: originalInvestment.capitalSecuredByRealEstate,
            capitalForRestructuring: originalInvestment.capitalForRestructuring,
            signedDate: originalInvestment.signedDate,
            issueDate: originalInvestment.issueDate,
            entryDate: originalInvestment.entryDate,
            exitDate: originalInvestment.exitDate,
            redemptionDate: originalInvestment.redemptionDate,
            createdAt: originalInvestment.createdAt,
            updatedAt: DateTime.now(), // Zaktualizuj timestamp
            status: newStatus,
            additionalInfo: originalInvestment.additionalInfo,
          );
          
          updatedInvestments.add(updatedInvestment);
        }
      }

      if (updatedInvestments.isEmpty) {
        setState(() {
          _error = 'Nie wykryto żadnych zmian do zapisania';
          _isLoading = false;
        });
        return;
      }

      // Zapisz zmiany przez InvestmentService
      final investmentService = InvestmentService();
      for (final updatedInvestment in updatedInvestments) {
        await investmentService.updateInvestment(
          updatedInvestment.id,
          updatedInvestment,
        );
      }

      // Powiadom o sukcesie
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
      
    } catch (e) {
      setState(() {
        _error = 'Błąd podczas zapisywania zmian: $e';
        _isLoading = false;
      });
    }
  }
}
