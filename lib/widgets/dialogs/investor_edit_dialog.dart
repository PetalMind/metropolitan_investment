import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';
import '../../services/investment_change_history_service.dart';
import '../premium_loading_widget.dart';
import '../investment_history_widget.dart';

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
  final List<TextEditingController> _capitalForRestructuringControllers = [];
  final List<TextEditingController> _capitalSecuredByRealEstateControllers = [];
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
    for (final controller in _capitalForRestructuringControllers) {
      controller.dispose();
    }
    for (final controller in _capitalSecuredByRealEstateControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeData() {
    // 🔍 DEBUG: Wyświetl informacje o produkcie i inwestycjach
    debugPrint('🔍 [InvestorEditDialog] Szukam inwestycji dla produktu:');
    debugPrint('  Product ID: ${widget.product.id}');
    debugPrint('  Product Name: ${widget.product.name}');
    debugPrint('  Company Name: ${widget.product.companyName}');
    debugPrint('  Company ID: ${widget.product.companyId}');
    debugPrint('  Source File: ${widget.product.sourceFile}');
    debugPrint('  Product Type: ${widget.product.productType}');
    
    debugPrint('🔍 [InvestorEditDialog] Inwestycje inwestora (${widget.investor.investments.length}):');
    for (int i = 0; i < widget.investor.investments.length; i++) {
      final inv = widget.investor.investments[i];
      debugPrint('  [$i] Investment ID: ${inv.id}');
      debugPrint('      Product ID: ${inv.productId}');
      debugPrint('      Product Name: ${inv.productName}');
      debugPrint('      Creditor Company: ${inv.creditorCompany}');
      debugPrint('      Company ID: ${inv.companyId}');
      debugPrint('      Product Type: ${inv.productType}');
    }

    // 🔧 ULEPSZONA LOGIKA WYSZUKIWANIA (bazowana na product_investors_tab.dart)
    
    // 1. Najpierw deduplikacja inwestycji
    final uniqueInvestments = <String, Investment>{};
    for (final investment in widget.investor.investments) {
      final key = investment.id.isNotEmpty
          ? investment.id
          : '${investment.productName}_${investment.investmentAmount}_${investment.clientId}';
      uniqueInvestments[key] = investment;
    }

    final uniqueInvestmentsList = uniqueInvestments.values.toList();
    debugPrint('🔍 [InvestorEditDialog] Po deduplikacji: ${uniqueInvestmentsList.length} unikalnych inwestycji');

    // 2. Sprawdź po ID produktu (jeśli dostępne i niepuste)
    if (widget.product.id.isNotEmpty) {
      final matchingInvestments = uniqueInvestmentsList
          .where((investment) =>
              investment.productId != null &&
              investment.productId!.isNotEmpty &&
              investment.productId != "null" && // Wyklucz "null" jako string
              investment.productId == widget.product.id)
          .toList();

      if (matchingInvestments.isNotEmpty) {
        debugPrint('✅ [InvestorEditDialog] Znaleziono dopasowania po productId: ${matchingInvestments.length}');
        _editableInvestments = matchingInvestments;
        _setupControllers();
        return;
      } else {
        debugPrint('⚠️ [InvestorEditDialog] Brak dopasowań po productId');
      }
    }

    // 3. Fallback: sprawdź po nazwie produktu (case-insensitive trim)
    final fallbackMatches = uniqueInvestmentsList
        .where((investment) =>
            investment.productName.trim().toLowerCase() ==
            widget.product.name.trim().toLowerCase())
        .toList();
    
    if (fallbackMatches.isNotEmpty) {
      debugPrint('✅ [InvestorEditDialog] Znaleziono dopasowania po nazwie produktu: ${fallbackMatches.length}');
      _editableInvestments = fallbackMatches;
      _setupControllers();
      return;
    }

    // 4. Fallback 2: sprawdź po nazwie produktu + firmie
    final companyMatches = uniqueInvestmentsList
        .where((investment) =>
            investment.productName.trim().toLowerCase() ==
                widget.product.name.trim().toLowerCase() &&
            (investment.creditorCompany == widget.product.companyName ||
             investment.companyId == widget.product.companyId))
        .toList();
    
    if (companyMatches.isNotEmpty) {
      debugPrint('✅ [InvestorEditDialog] Znaleziono dopasowania po nazwie + firmie: ${companyMatches.length}');
      _editableInvestments = companyMatches;
      _setupControllers();
      return;
    }
    
    // 5. Ostatni fallback: jeśli to UnifiedProduct pochodzący z inwestycji, sprawdź po ID inwestycji
    if (widget.product.sourceFile == 'investments') {
      final investmentIdMatches = uniqueInvestmentsList
          .where((investment) => investment.id == widget.product.id)
          .toList();
      
      if (investmentIdMatches.isNotEmpty) {
        debugPrint('✅ [InvestorEditDialog] Znaleziono dopasowania po ID inwestycji: ${investmentIdMatches.length}');
        _editableInvestments = investmentIdMatches;
        _setupControllers();
        return;
      }
    }

    // 6. Ostateczny fallback: bardziej tolerancyjne wyszukiwanie po fragmentach nazwy
    if (_editableInvestments.isEmpty) {
      final partialMatches = uniqueInvestmentsList
          .where((investment) {
            // Usuń nadmiarowe spacje i zamień na małe litery
            final investmentName = investment.productName.trim().toLowerCase();
            final productName = widget.product.name.trim().toLowerCase();
            
            // Sprawdź czy nazwy zawierają się nawzajem
            return investmentName.contains(productName) || 
                   productName.contains(investmentName) ||
                   // Lub sprawdź po częściach rozdzielonych spacjami
                   _hasCommonWords(investmentName, productName);
          })
          .toList();
      
      if (partialMatches.isNotEmpty) {
        debugPrint('✅ [InvestorEditDialog] Znaleziono dopasowania przez podobieństwo nazw: ${partialMatches.length}');
        _editableInvestments = partialMatches;
        _setupControllers();
        return;
      }
    }

    // 7. Fallback dla produktów utworzonych z Firebase Functions (sprawdź ID inwestycji jako backup)
    if (_editableInvestments.isEmpty && widget.product.originalProduct != null) {
      if (widget.product.originalProduct is Map<String, dynamic>) {
        final originalData = widget.product.originalProduct as Map<String, dynamic>;
        final originalIds = [
          originalData['id'],
          originalData['investment_id'], 
          originalData['originalInvestmentId']
        ].where((id) => id != null).map((id) => id.toString()).toList();
        
        if (originalIds.isNotEmpty) {
          final originalMatches = uniqueInvestmentsList
              .where((investment) => originalIds.contains(investment.id))
              .toList();
          
          if (originalMatches.isNotEmpty) {
            debugPrint('✅ [InvestorEditDialog] Znaleziono dopasowania przez original IDs: ${originalMatches.length}');
            _editableInvestments = originalMatches;
            _setupControllers();
            return;
          }
        }
      }
    }

    debugPrint('❌ [InvestorEditDialog] Nie znaleziono żadnych dopasowań!');
    _editableInvestments = [];
    _setupControllers();
  }

  /// Sprawdza czy dwie nazwy mają wspólne słowa (minimum 2 znaki)
  bool _hasCommonWords(String name1, String name2) {
    final words1 = name1.split(' ').where((w) => w.length >= 2).toSet();
    final words2 = name2.split(' ').where((w) => w.length >= 2).toSet();
    return words1.intersection(words2).isNotEmpty;
  }

  void _setupControllers() {
    // Wyczyść istniejące controllery
    for (final controller in _remainingCapitalControllers) {
      controller.dispose();
    }
    for (final controller in _investmentAmountControllers) {
      controller.dispose();
    }
    for (final controller in _capitalForRestructuringControllers) {
      controller.dispose();
    }
    for (final controller in _capitalSecuredByRealEstateControllers) {
      controller.dispose();
    }
    _remainingCapitalControllers.clear();
    _investmentAmountControllers.clear();
    _capitalForRestructuringControllers.clear();
    _capitalSecuredByRealEstateControllers.clear();
    _statusValues.clear();

    // Utwórz controllery dla każdej inwestycji
    for (final investment in _editableInvestments) {
      _remainingCapitalControllers.add(
        TextEditingController(text: investment.remainingCapital.toString())
      );
      _investmentAmountControllers.add(
        TextEditingController(text: investment.investmentAmount.toString())
      );
      _capitalForRestructuringControllers.add(
        TextEditingController(text: investment.capitalForRestructuring.toString())
      );
      _capitalSecuredByRealEstateControllers.add(
        TextEditingController(text: investment.capitalSecuredByRealEstate.toString())
      );
      _statusValues.add(investment.status);
    }

    // Ustaw listenery do wykrywania zmian i automatycznych obliczeń
    for (int i = 0; i < _editableInvestments.length; i++) {
      _remainingCapitalControllers[i].addListener(_onDataChanged);
      _investmentAmountControllers[i].addListener(() {
        _onDataChanged();
        _calculateAutomaticValues(i);
      });
      _capitalForRestructuringControllers[i].addListener(() {
        _onDataChanged();
        _calculateAutomaticValues(i);
      });
      _capitalSecuredByRealEstateControllers[i].addListener(_onDataChanged);
    }
  }

  void _onDataChanged() {
    setState(() {
      _isChanged = true;
    });
  }

  /// Automatyczne obliczanie wartości na podstawie wprowadzonych kwot
  void _calculateAutomaticValues(int index) {
    final investmentAmountText = _investmentAmountControllers[index].text;
    final capitalForRestructuringText = _capitalForRestructuringControllers[index].text;
    
    final investmentAmount = double.tryParse(investmentAmountText) ?? 0.0;
    final capitalForRestructuring = double.tryParse(capitalForRestructuringText) ?? 0.0;
    
    // Oblicz pozostały kapitał (kwota inwestycji minus kapitał do restrukturyzacji)
    final calculatedRemainingCapital = investmentAmount - capitalForRestructuring;
    
    // Aktualizuj pole pozostałego kapitału (tylko jeśli wartość się zmieniła)
    final currentRemainingCapital = double.tryParse(_remainingCapitalControllers[index].text) ?? 0.0;
    if ((calculatedRemainingCapital - currentRemainingCapital).abs() > 0.01) {
      _remainingCapitalControllers[index].text = calculatedRemainingCapital.toStringAsFixed(2);
    }
    
    // Oblicz kapitał zabezpieczony nieruchomością
    // Logika: kapitał zabezpieczony = pozostały kapitał (jeśli pozytywny)
    final calculatedCapitalSecured = calculatedRemainingCapital > 0 ? calculatedRemainingCapital : 0.0;
    
    // Aktualizuj pole kapitału zabezpieczonego (tylko jeśli wartość się zmieniła)
    final currentCapitalSecured = double.tryParse(_capitalSecuredByRealEstateControllers[index].text) ?? 0.0;
    if ((calculatedCapitalSecured - currentCapitalSecured).abs() > 0.01) {
      _capitalSecuredByRealEstateControllers[index].text = calculatedCapitalSecured.toStringAsFixed(2);
    }
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
            const SizedBox(height: 16),
            // Informacja o automatycznych obliczeniach
            _buildAutomaticCalculationInfo(),
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
    final totalCapitalForRestructuring = _editableInvestments
        .fold(0.0, (sum, inv) => sum + inv.capitalForRestructuring);
    final totalCapitalSecured = _editableInvestments
        .fold(0.0, (sum, inv) => sum + inv.capitalSecuredByRealEstate);

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
          // Pierwszy rząd
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
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryTile(
                  'Łączna kwota',
                  _currencyFormat.format(totalInvestmentAmount),
                  Icons.account_balance_wallet,
                  AppThemePro.bondsBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Drugi rząd
          Row(
            children: [
              Expanded(
                child: _buildSummaryTile(
                  'Pozostały kapitał',
                  _currencyFormat.format(totalRemainingCapital),
                  Icons.trending_up,
                  AppThemePro.profitGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryTile(
                  'Do restrukturyzacji',
                  _currencyFormat.format(totalCapitalForRestructuring),
                  Icons.build,
                  AppThemePro.statusWarning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Trzeci rząd
          Row(
            children: [
              Expanded(
                child: _buildSummaryTile(
                  'Zabezpieczony',
                  _currencyFormat.format(totalCapitalSecured),
                  Icons.security,
                  AppThemePro.statusSuccess,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(), // Puste miejsce dla symetrii
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

  Widget _buildAutomaticCalculationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.accentGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calculate,
                color: AppThemePro.accentGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Automatyczne obliczenia',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppThemePro.accentGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pozostały kapitał = Kwota inwestycji - Kapitał do restrukturyzacji',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppThemePro.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pole "Zabezpieczony nieruchomością" można edytować ręcznie',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppThemePro.textTertiary,
            ),
          ),
        ],
      ),
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
                      'ID: ${investment.id.length > 8 ? investment.id.substring(0, 8) + '...' : investment.id}',
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
          // Pola edycji - pierwszy rząd (kwoty podstawowe)
          Row(
            children: [
              Expanded(
                child: _buildCurrencyField(
                  label: 'Kwota inwestycji',
                  controller: _investmentAmountControllers[index],
                  icon: Icons.account_balance_wallet,
                  color: AppThemePro.bondsBlue,
                  isEditable: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCurrencyField(
                  label: 'Kapitał do restrukturyzacji',
                  controller: _capitalForRestructuringControllers[index],
                  icon: Icons.build,
                  color: AppThemePro.statusWarning,
                  isEditable: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Drugi rząd (kwoty automatycznie obliczane)
          Row(
            children: [
              Expanded(
                child: _buildCurrencyField(
                  label: 'Pozostały kapitał (obliczany)',
                  controller: _remainingCapitalControllers[index],
                  icon: Icons.trending_up,
                  color: AppThemePro.profitGreen,
                  isEditable: false, // Tylko do odczytu
                  helpText: 'Kwota inwestycji - Kapitał do restrukturyzacji',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCurrencyField(
                  label: 'Zabezpieczony nieruchomością',
                  controller: _capitalSecuredByRealEstateControllers[index],
                  icon: Icons.security,
                  color: AppThemePro.statusSuccess,
                  isEditable: true,
                  helpText: 'Może być edytowany ręcznie',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 🔍 Przycisk historii zmian
          _buildHistoryButton(investment),
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
    bool isEditable = true,
    String? helpText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppThemePro.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (helpText != null) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: helpText,
                child: Icon(
                  Icons.help_outline,
                  size: 14,
                  color: AppThemePro.textMuted,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isEditable ? TextInputType.number : null,
          readOnly: !isEditable,
          inputFormatters: isEditable ? [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ] : null,
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
            fillColor: isEditable 
                ? AppThemePro.surfaceElevated 
                : AppThemePro.surfaceElevated.withOpacity(0.5),
          ),
          style: TextStyle(
            color: isEditable ? AppThemePro.textPrimary : AppThemePro.textMuted,
          ),
          validator: isEditable ? (value) {
            if (value == null || value.isEmpty) {
              return 'To pole jest wymagane';
            }
            
            final double? parsedValue = double.tryParse(value);
            
            // 🚀 ENHANCED: Walidacja dla znormalizowanych danych z lepszymi komunikatami
            if (parsedValue == null) {
              return 'Niepoprawny format liczbowy (użyj kropki jako separatora dziesiętnego)';
            }
            
            if (parsedValue < 0) {
              return 'Wartość nie może być ujemna';
            }
            
            // 🚀 ENHANCED: Maksymalna wartość zwiększona dla nowych danych importu
            if (parsedValue > 100000000.0) { // 100 milionów PLN zamiast domyślnego limitu
              return 'Wartość przekracza maksymalny limit (100 mln PLN)';
            }
            
            // 🚀 ENHANCED: Sprawdź precyzję - maksymalnie 2 miejsca po przecinku dla wartości finansowych
            final String valueString = parsedValue.toStringAsFixed(2);
            final double roundedValue = double.parse(valueString);
            if ((parsedValue - roundedValue).abs() > 0.001) {
              return 'Wartość może mieć maksymalnie 2 miejsca po przecinku';
            }
            
            return null;
          } : null,
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
        final newCapitalForRestructuring = double.parse(_capitalForRestructuringControllers[i].text);
        final newCapitalSecuredByRealEstate = double.parse(_capitalSecuredByRealEstateControllers[i].text);
        final newStatus = _statusValues[i];

        // Sprawdź czy są zmiany
        if (newRemainingCapital != originalInvestment.remainingCapital ||
            newInvestmentAmount != originalInvestment.investmentAmount ||
            newCapitalForRestructuring != originalInvestment.capitalForRestructuring ||
            newCapitalSecuredByRealEstate != originalInvestment.capitalSecuredByRealEstate ||
            newStatus != originalInvestment.status) {
          
          // 🚀 ENHANCED: Utwórz zaktualizowaną inwestycję z obsługą wszystkich pól znormalizowanego importu
          final updatedInvestment = Investment(
            id: originalInvestment.id,
            clientId: originalInvestment.clientId,
            clientName: originalInvestment.clientName,
            productId: originalInvestment.productId, // 🚀 ENHANCED: Obsługa productId z znormalizowanego importu
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
            
            // 🚀 ENHANCED: Zaktualizowane wartości finansowe
            investmentAmount: newInvestmentAmount,
            paidAmount: originalInvestment.paidAmount,
            remainingCapital: newRemainingCapital,
            realizedCapital: originalInvestment.realizedCapital,
            realizedInterest: originalInvestment.realizedInterest,
            remainingInterest: originalInvestment.remainingInterest, // 🚀 ENHANCED: Dodane pole
            realizedTax: originalInvestment.realizedTax,
            plannedTax: originalInvestment.plannedTax, // 🚀 ENHANCED: Dodane pole
            transferToOtherProduct: originalInvestment.transferToOtherProduct,
            
            // 🚀 ENHANCED: Pola kapitałowe z znormalizowanego importu
            capitalSecuredByRealEstate: newCapitalSecuredByRealEstate,
            capitalForRestructuring: newCapitalForRestructuring,
            
            // Daty
            signedDate: originalInvestment.signedDate,
            issueDate: originalInvestment.issueDate,
            entryDate: originalInvestment.entryDate,
            exitDate: originalInvestment.exitDate,
            redemptionDate: originalInvestment.redemptionDate,
            
            // 🚀 ENHANCED: Metadane z obsługą więcej pól
            createdAt: originalInvestment.createdAt,
            updatedAt: DateTime.now(), // Zaktualizuj timestamp
            status: newStatus,
            isAllocated: originalInvestment.isAllocated, // 🚀 ENHANCED: Dodane pole
            currency: originalInvestment.currency, // 🚀 ENHANCED: Dodane pole
            exchangeRate: originalInvestment.exchangeRate, // 🚀 ENHANCED: Dodane pole
            sharesCount: originalInvestment.sharesCount, // 🚀 ENHANCED: Dodane pole
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

      debugPrint('🔧 [InvestorEditDialog] Zapisuję ${updatedInvestments.length} zaktualizowanych inwestycji');
      debugPrint('📊 [InvestorEditDialog] Produktu: ${widget.product.name} (ID: ${widget.product.id})');

      // 🚀 ENHANCED: Zapisz zmiany przez InvestmentService z lepszą obsługą błędów
      final investmentService = InvestmentService();
      for (final updatedInvestment in updatedInvestments) {
        try {
          debugPrint('🔧 [InvestorEditDialog] Aktualizuję inwestycję: ${updatedInvestment.id}');
          debugPrint('📊 [InvestorEditDialog] Pola finansowe:');
          debugPrint('   - remainingCapital: ${updatedInvestment.remainingCapital}');
          debugPrint('   - investmentAmount: ${updatedInvestment.investmentAmount}');  
          debugPrint('   - capitalForRestructuring: ${updatedInvestment.capitalForRestructuring}');
          debugPrint('   - capitalSecuredByRealEstate: ${updatedInvestment.capitalSecuredByRealEstate}');
          debugPrint('   - status: ${updatedInvestment.status.displayName}');
          debugPrint('🔍 [InvestorEditDialog] ProductId: ${updatedInvestment.productId}, LogicalId: ${updatedInvestment.id}');
          
          await investmentService.updateInvestment(
            updatedInvestment.id,
            updatedInvestment,
          );
          debugPrint('✅ [InvestorEditDialog] Zaktualizowano inwestycję: ${updatedInvestment.id}');
        } catch (updateError) {
          debugPrint('❌ [InvestorEditDialog] Błąd aktualizacji inwestycji ${updatedInvestment.id}: $updateError');
          
          // 🚀 ENHANCED: Lepsze komunikaty błędów dla znormalizowanych danych
          String userFriendlyError = 'Błąd podczas aktualizacji inwestycji ${updatedInvestment.id.length > 12 ? updatedInvestment.id.substring(0, 12) + '...' : updatedInvestment.id}';
          
          if (updateError.toString().contains('400')) {
            userFriendlyError += ' (Błąd walidacji danych - sprawdź format pól)';
          } else if (updateError.toString().contains('permission')) {
            userFriendlyError += ' (Brak uprawnień do edycji)';
          } else if (updateError.toString().contains('network')) {
            userFriendlyError += ' (Problemy z połączeniem internetowym)';
          } else if (updateError.toString().contains('not-found')) {
            userFriendlyError = 'Inwestycja ${updatedInvestment.id} nie została znaleziona - może zostać automatycznie utworzona';
            debugPrint('🔧 [InvestorEditDialog] Investment not found, auto-recovery should handle this');
          } else if (updateError.toString().contains('Successfully created missing document')) {
            // This is actually a success after auto-recovery
            debugPrint('✅ [InvestorEditDialog] Auto-recovery successful for ${updatedInvestment.id}');
            continue; // Don't treat as error, continue with next investment
          } else if (updateError.toString().contains('undefined')) {
            userFriendlyError += ' (Błąd undefined values - sprawdź Firebase Functions)';
          }
          
          throw Exception(userFriendlyError);
        }
      }
      
      // 🔍 ZAPISZ HISTORIĘ ZMIAN
      try {
        final historyService = InvestmentChangeHistoryService();
        final oldInvestments = <Investment>[];
        final newInvestments = <Investment>[];
        
        // Przygotuj listy do historii
        for (int i = 0; i < _editableInvestments.length; i++) {
          final originalInvestment = _editableInvestments[i];
          final updatedInvestment = updatedInvestments.firstWhere(
            (inv) => inv.id == originalInvestment.id,
            orElse: () => originalInvestment,
          );
          
          if (updatedInvestment != originalInvestment) {
            oldInvestments.add(originalInvestment);
            newInvestments.add(updatedInvestment);
          }
        }
        
        if (oldInvestments.isNotEmpty) {
          debugPrint('📝 [InvestorEditDialog] Zapisuję historię zmian dla ${oldInvestments.length} inwestycji');
          debugPrint('🔍 [InvestorEditDialog] Metadane: productId=${widget.product.id}, clientId=${widget.investor.client.id}');
          
          try {
            await historyService.recordBulkChanges(
              oldInvestments: oldInvestments,
              newInvestments: newInvestments,
              customDescription: '🚀 ENHANCED: Edycja inwestycji przez InvestorEditDialog - ${widget.product.name} (znormalizowane dane JSON)',
              metadata: {
                'source': 'investor_edit_dialog',
                'productId': widget.product.id,
                'productName': widget.product.name,
                'clientId': widget.investor.client.id,
                'clientName': widget.investor.client.name,
                'investmentsCount': updatedInvestments.length,
                'platform': 'web',
                'userAgent': 'flutter_web',
                'dataStructure': 'normalized_json_import', // 🚀 ENHANCED: Tag for data source tracking
                'enhancedValidation': true, // 🚀 ENHANCED: Flag for enhanced validation
                'maxAmount': 100000000.0, // 🚀 ENHANCED: Record validation limits
                'precisionDecimals': 2, // 🚀 ENHANCED: Record precision requirements
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
            debugPrint('✅ [InvestorEditDialog] Historia zmian zapisana pomyślnie (enhanced)');
          } catch (historyError) {
            debugPrint('⚠️ [InvestorEditDialog] Błąd zapisu historii (nieblokujący): $historyError');
            // Historia jest opcjonalna - nie blokujemy zapisu głównych danych
          }
          
          // 🚀 ENHANCED: Debug export funkcji dla troubleshootingu
          try {
            final debugData = {
              'timestamp': DateTime.now().toIso8601String(),
              'productId': widget.product.id,
              'productName': widget.product.name,
              'clientId': widget.investor.client.id,
              'changedInvestments': updatedInvestments.map((inv) => {
                'id': inv.id,
                'productId': inv.productId,
                'remainingCapital': inv.remainingCapital,
                'investmentAmount': inv.investmentAmount,
                'capitalForRestructuring': inv.capitalForRestructuring,
                'capitalSecuredByRealEstate': inv.capitalSecuredByRealEstate,
                'status': inv.status.displayName,
                'updatedAt': inv.updatedAt?.toIso8601String(),
              }).toList(),
              'dataStructure': 'normalized_json_import',
            };
            debugPrint('📊 [InvestorEditDialog] Debug export data: ${debugData.toString().substring(0, (debugData.toString().length).clamp(0, 500))}${debugData.toString().length > 500 ? '...' : ''}');
          } catch (debugError) {
            debugPrint('⚠️ [InvestorEditDialog] Debug export failed: $debugError');
          }
        }
      } catch (historyError) {
        debugPrint('⚠️ [InvestorEditDialog] Błąd zapisu historii (nie blokuje operacji): $historyError');
        // Historia nie powinna blokować głównej operacji
      }

      // Powiadom o sukcesie
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ [InvestorEditDialog] Błąd podczas zapisywania zmian: $e');
      debugPrint('🔍 [InvestorEditDialog] Stack trace: $stackTrace');
      
      // 🚀 ENHANCED: Bardziej szczegółowe komunikaty błędów dla użytkownika
      String userMessage = 'Błąd podczas zapisywania zmian';
      
      if (e.toString().contains('network') || e.toString().contains('timeout')) {
        userMessage = 'Błąd połączenia z serwerem. Sprawdź połączenie internetowe i spróbuj ponownie.';
      } else if (e.toString().contains('permission') || e.toString().contains('forbidden')) {
        userMessage = 'Brak uprawnień do edycji inwestycji. Skontaktuj się z administratorem.';
      } else if (e.toString().contains('validation') || e.toString().contains('format')) {
        userMessage = 'Błąd walidacji danych. Sprawdź czy wszystkie pola mają poprawny format.';
      } else if (e.toString().contains('not-found')) {
        userMessage = 'Niektóre inwestycje nie zostały znalezione. Dane mogły zostać automatycznie odtworzone.';
      } else if (e.toString().contains('Firebase Functions')) {
        userMessage = 'Błąd Firebase Functions. Spróbuj ponownie za chwilę lub skontaktuj się z administratorem.';
      } else if (e.toString().contains('undefined')) {
        userMessage = 'Błąd przetwarzania danych na serwerze (undefined values). Skontaktuj się z administratorem.';
      } else {
        userMessage = 'Nieoczekiwany błąd podczas zapisywania. Spróbuj ponownie lub skontaktuj się z administratorem.';
      }
      
      setState(() {
        _error = userMessage + '\n\nSzczegóły techniczne: ${e.toString().substring(0, (e.toString().length).clamp(0, 200))}${e.toString().length > 200 ? '...' : ''}';
        _isLoading = false;
      });
    }
  }

  /// 🔍 Przycisk do wyświetlania historii zmian inwestycji
  Widget _buildHistoryButton(Investment investment) {
    return Container(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => _showInvestmentHistory(investment),
        style: TextButton.styleFrom(
          backgroundColor: AppThemePro.accentGold.withOpacity(0.1),
          foregroundColor: AppThemePro.accentGold,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: AppThemePro.accentGold.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        icon: const Icon(Icons.history, size: 16),
        label: const Text(
          'Historia zmian',
          style: TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  /// 📋 Pokazuje historię zmian inwestycji w dialogu
  void _showInvestmentHistory(Investment investment) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: AppThemePro.backgroundPrimary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppThemePro.borderPrimary),
          ),
          child: Column(
            children: [
              // Header dialogu
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppThemePro.surfaceElevated,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: AppThemePro.accentGold,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Historia zmian inwestycji',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppThemePro.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ID: ${investment.id.length > 12 ? investment.id.substring(0, 12) + '...' : investment.id}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppThemePro.textTertiary,
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
              ),
              // Widget historii
              Expanded(
                child: InvestmentHistoryWidget(
                  investmentId: investment.id,
                  isCompact: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
