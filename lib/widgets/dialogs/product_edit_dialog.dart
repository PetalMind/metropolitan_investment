import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme_professional.dart';
import '../../models_and_services.dart';
import '../../utils/currency_formatter.dart';
import '../investment_history_widget.dart';

/// Dialog do edycji inwestycji klienta zgodny z AppThemePro
class InvestorEditDialog extends StatefulWidget {
  final InvestorSummary investor;
  final UnifiedProduct product;
  final VoidCallback? onSaved;

  const InvestorEditDialog({
    super.key,
    required this.investor,
    required this.product,
    this.onSaved,
  });

  @override
  State<InvestorEditDialog> createState() => _InvestorEditDialogState();
}

class _InvestorEditDialogState extends State<InvestorEditDialog>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // 🔍 SERWISY
  final InvestmentChangeHistoryService _historyService =
      InvestmentChangeHistoryService();

  bool _isSaving = false;
  bool _isEditMode = false;

  // Controllers for form fields
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  // Original investments for this product
  List<Investment> _productInvestments = [];

  // Modified investments
  Map<String, Investment> _modifiedInvestments = {};

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _initializeInvestments();
    _initializeControllers();
    _fadeController.forward();
  }

  void _initializeInvestments() {
    // Find investments for this specific product
    _productInvestments = widget.investor.investments.where((investment) {
      // Try matching by product ID first
      if (widget.product.id.isNotEmpty &&
          investment.productId != null &&
          investment.productId!.isNotEmpty &&
          investment.productId != "null") {
        return investment.productId == widget.product.id;
      }

      // Fallback: match by product name
      return investment.productName.trim().toLowerCase() ==
          widget.product.name.trim().toLowerCase();
    }).toList();

    // Remove duplicates based on ID
    final uniqueInvestments = <String, Investment>{};
    for (final investment in _productInvestments) {
      final key = investment.id.isNotEmpty
          ? investment.id
          : '${investment.productName}_${investment.investmentAmount}_${investment.clientId}';
      uniqueInvestments[key] = investment;
    }
    _productInvestments = uniqueInvestments.values.toList();
  }

  void _initializeControllers() {
    for (int i = 0; i < _productInvestments.length; i++) {
      final investment = _productInvestments[i];
      final prefix = 'inv_${i}_';

      // 🔢 WSZYSTKIE DOSTĘPNE KWOTY Z MODELU INVESTMENT
      _controllers['${prefix}investmentAmount'] = TextEditingController(
        text: investment.investmentAmount.toStringAsFixed(2),
      );
      _controllers['${prefix}paidAmount'] = TextEditingController(
        text: investment.paidAmount.toStringAsFixed(2),
      );
      _controllers['${prefix}remainingCapital'] = TextEditingController(
        text: investment.remainingCapital.toStringAsFixed(2),
      );
      _controllers['${prefix}realizedCapital'] = TextEditingController(
        text: investment.realizedCapital.toStringAsFixed(2),
      );
      _controllers['${prefix}realizedInterest'] = TextEditingController(
        text: investment.realizedInterest.toStringAsFixed(2),
      );
      _controllers['${prefix}remainingInterest'] = TextEditingController(
        text: investment.remainingInterest.toStringAsFixed(2),
      );
      _controllers['${prefix}transferToOtherProduct'] = TextEditingController(
        text: investment.transferToOtherProduct.toStringAsFixed(2),
      );
      _controllers['${prefix}capitalForRestructuring'] = TextEditingController(
        text: investment.capitalForRestructuring.toStringAsFixed(2),
      );
      _controllers['${prefix}capitalSecuredByRealEstate'] =
          TextEditingController(
            text: investment.capitalSecuredByRealEstate.toStringAsFixed(2),
          );
      _controllers['${prefix}plannedTax'] = TextEditingController(
        text: investment.plannedTax.toStringAsFixed(2),
      );
      _controllers['${prefix}realizedTax'] = TextEditingController(
        text: investment.realizedTax.toStringAsFixed(2),
      );

      // 🔢 FOCUS NODES DLA WSZYSTKICH PÓL
      _focusNodes['${prefix}investmentAmount'] = FocusNode();
      _focusNodes['${prefix}paidAmount'] = FocusNode();
      _focusNodes['${prefix}remainingCapital'] = FocusNode();
      _focusNodes['${prefix}realizedCapital'] = FocusNode();
      _focusNodes['${prefix}realizedInterest'] = FocusNode();
      _focusNodes['${prefix}remainingInterest'] = FocusNode();
      _focusNodes['${prefix}transferToOtherProduct'] = FocusNode();
      _focusNodes['${prefix}capitalForRestructuring'] = FocusNode();
      _focusNodes['${prefix}capitalSecuredByRealEstate'] = FocusNode();
      _focusNodes['${prefix}plannedTax'] = FocusNode();
      _focusNodes['${prefix}realizedTax'] = FocusNode();

      // 🎯 DODAJ LISTENERY DO WSZYSTKICH KONTROLERÓW - AUTOMATYCZNE ŚLEDZENIE ZMIAN
      _controllers['${prefix}investmentAmount']?.addListener(_trackChanges);
      _controllers['${prefix}paidAmount']?.addListener(_trackChanges);
      _controllers['${prefix}remainingCapital']?.addListener(_trackChanges);
      _controllers['${prefix}realizedCapital']?.addListener(_trackChanges);
      _controllers['${prefix}realizedInterest']?.addListener(_trackChanges);
      _controllers['${prefix}remainingInterest']?.addListener(_trackChanges);
      _controllers['${prefix}transferToOtherProduct']?.addListener(_trackChanges);
      _controllers['${prefix}capitalForRestructuring']?.addListener(_trackChanges);
      _controllers['${prefix}capitalSecuredByRealEstate']?.addListener(_trackChanges);
      _controllers['${prefix}plannedTax']?.addListener(_trackChanges);
      _controllers['${prefix}realizedTax']?.addListener(_trackChanges);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();

    _controllers.values.forEach((controller) => controller.dispose());
    _focusNodes.values.forEach((node) => node.dispose());

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: 800,
          height: 600,
          decoration: BoxDecoration(
            color: AppThemePro.backgroundPrimary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppThemePro.borderPrimary, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildContent()),
              _buildFooter(),
            ],
          ),
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
          colors: [AppThemePro.primaryDark, AppThemePro.primaryMedium],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Client avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppThemePro.accentGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppThemePro.accentGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppThemePro.accentGold,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // Client info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edycja inwestycji',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.investor.client.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemePro.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Edit toggle
          Container(
            decoration: BoxDecoration(
              color: _isEditMode
                  ? AppThemePro.accentGold.withOpacity(0.2)
                  : AppThemePro.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isEditMode
                    ? AppThemePro.accentGold.withOpacity(0.5)
                    : AppThemePro.borderPrimary,
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _isEditMode = !_isEditMode;
                });
              },
              icon: Icon(
                _isEditMode ? Icons.visibility : Icons.edit,
                color: _isEditMode
                    ? AppThemePro.accentGold
                    : AppThemePro.textSecondary,
                size: 20,
              ),
              tooltip: _isEditMode ? 'Tryb podglądu' : 'Tryb edycji',
            ),
          ),

          const SizedBox(width: 12),

          // Close button
          Container(
            decoration: BoxDecoration(
              color: AppThemePro.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppThemePro.borderPrimary, width: 1),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.close,
                color: AppThemePro.textSecondary,
                size: 20,
              ),
              tooltip: 'Zamknij',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_productInvestments.isEmpty) {
      return _buildEmptyState();
    }

    return Form(
      key: _formKey,
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductInfo(),
              const SizedBox(height: 24),
              _buildInvestmentsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppThemePro.premiumCardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppThemePro.getInvestmentTypeColor(
                widget.product.productType.name,
              ).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppThemePro.getInvestmentTypeColor(
                  widget.product.productType.name,
                ).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              _getProductIcon(widget.product.productType),
              color: AppThemePro.getInvestmentTypeColor(
                widget.product.productType.name,
              ),
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.product.productType.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppThemePro.statusSuccess.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppThemePro.statusSuccess.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '${_productInvestments.length} inwestycji',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppThemePro.statusSuccess,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inwestycje w produkcie',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        ...List.generate(_productInvestments.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildInvestmentCard(index),
          );
        }),
      ],
    );
  }

  Widget _buildInvestmentCard(int index) {
    final investment = _productInvestments[index];
    final prefix = 'inv_${index}_';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemePro.borderPrimary, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppThemePro.accentGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppThemePro.accentGold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Inwestycja ${index + 1}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.accentGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const Spacer(),

              if (investment.id.isNotEmpty)
                Text(
                  'ID: ${investment.id}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.textMuted,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Form fields - PIERWSZY RZĄD: Podstawowe kwoty
          Row(
            children: [
              Expanded(
                child: _buildCurrencyField(
                  label: 'Kwota inwestycji',
                  controller: _controllers['${prefix}investmentAmount']!,
                  focusNode: _focusNodes['${prefix}investmentAmount']!,
                  enabled: _isEditMode,
                  icon: Icons.account_balance_wallet,
                  color: AppThemePro.bondsBlue,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: _buildCurrencyField(
                  label: 'Kwota wpłat',
                  controller: _controllers['${prefix}paidAmount']!,
                  focusNode: _focusNodes['${prefix}paidAmount']!,
                  enabled: _isEditMode,
                  icon: Icons.payment,
                  color: AppThemePro.bondsBlue.withOpacity(0.8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // DRUGI RZĄD: Kapitały pozostałe i zrealizowane
          Row(
            children: [
              Expanded(
                child: _buildCurrencyField(
                  label: 'Kapitał pozostały',
                  controller: _controllers['${prefix}remainingCapital']!,
                  focusNode: _focusNodes['${prefix}remainingCapital']!,
                  enabled: _isEditMode,
                  icon: Icons.trending_up,
                  color: AppThemePro.sharesGreen,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: _buildCurrencyField(
                  label: 'Kapitał zrealizowany',
                  controller: _controllers['${prefix}realizedCapital']!,
                  focusNode: _focusNodes['${prefix}realizedCapital']!,
                  enabled: _isEditMode,
                  icon: Icons.check_circle,
                  color: AppThemePro.profitGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // TRZECI RZĄD: Odsetki
          Row(
            children: [
              Expanded(
                child: _buildCurrencyField(
                  label: 'Odsetki pozostałe',
                  controller: _controllers['${prefix}remainingInterest']!,
                  focusNode: _focusNodes['${prefix}remainingInterest']!,
                  enabled: _isEditMode,
                  icon: Icons.percent,
                  color: AppThemePro.accentGold,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: _buildCurrencyField(
                  label: 'Odsetki zrealizowane',
                  controller: _controllers['${prefix}realizedInterest']!,
                  focusNode: _focusNodes['${prefix}realizedInterest']!,
                  enabled: _isEditMode,
                  icon: Icons.percent_outlined,
                  color: AppThemePro.accentGoldMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // CZWARTY RZĄD: Specjalne kapitały
          Row(
            children: [
              Expanded(
                child: _buildCurrencyField(
                  label: 'Kapitał do restrukturyzacji',
                  controller: _controllers['${prefix}capitalForRestructuring']!,
                  focusNode: _focusNodes['${prefix}capitalForRestructuring']!,
                  enabled: _isEditMode,
                  icon: Icons.build,
                  color: AppThemePro.loansOrange,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: _buildCurrencyField(
                  label: 'Kapitał zabezp. nieruchomościami',
                  controller:
                      _controllers['${prefix}capitalSecuredByRealEstate']!,
                  focusNode:
                      _focusNodes['${prefix}capitalSecuredByRealEstate']!,
                  enabled: _isEditMode,
                  icon: Icons.home,
                  color: AppThemePro.neutralGray,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // PIĄTY RZĄD: Transfery i podatki
          Row(
            children: [
              Expanded(
                child: _buildCurrencyField(
                  label: 'Transfer na inny produkt',
                  controller: _controllers['${prefix}transferToOtherProduct']!,
                  focusNode: _focusNodes['${prefix}transferToOtherProduct']!,
                  enabled: _isEditMode,
                  icon: Icons.transfer_within_a_station,
                  color: AppThemePro.statusWarning,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: _buildCurrencyField(
                  label: 'Planowany podatek',
                  controller: _controllers['${prefix}plannedTax']!,
                  focusNode: _focusNodes['${prefix}plannedTax']!,
                  enabled: _isEditMode,
                  icon: Icons.receipt,
                  color: AppThemePro.lossRed.withOpacity(0.7),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // SZÓSTY RZĄD: Podatek zrealizowany (jeden element)
          Row(
            children: [
              Expanded(
                child: _buildCurrencyField(
                  label: 'Zrealizowany podatek',
                  controller: _controllers['${prefix}realizedTax']!,
                  focusNode: _focusNodes['${prefix}realizedTax']!,
                  enabled: _isEditMode,
                  icon: Icons.receipt_long,
                  color: AppThemePro.lossRed,
                ),
              ),

              const SizedBox(width: 16),

              // Puste miejsce dla symetrii
              Expanded(child: Container()),
            ],
          ),

          if (_isEditMode) ...[
            const SizedBox(height: 16),
            _buildCalculatedFields(investment, prefix),
          ],

          // 🔍 NOWE: Przycisk historii zmian
          if (!_isEditMode) ...[
            const SizedBox(height: 12),
            _buildHistoryButton(investment),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrencyField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool enabled,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemePro.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: enabled ? AppThemePro.textPrimary : AppThemePro.textMuted,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled
                ? AppThemePro.surfaceInteractive
                : AppThemePro.backgroundSecondary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixText: 'PLN',
            suffixStyle: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppThemePro.borderPrimary,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppThemePro.borderPrimary,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppThemePro.borderPrimary.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Pole jest wymagane';
            }
            if (double.tryParse(value) == null) {
              return 'Nieprawidłowa wartość';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCalculatedFields(Investment investment, String prefix) {
    final investmentAmount =
        double.tryParse(_controllers['${prefix}investmentAmount']!.text) ?? 0.0;

    final remainingCapital =
        double.tryParse(_controllers['${prefix}remainingCapital']!.text) ?? 0.0;

    final capitalForRestructuring =
        double.tryParse(
          _controllers['${prefix}capitalForRestructuring']!.text,
        ) ??
        0.0;

    // 🔢 OBLICZENIA ZGODNE Z MODELEM INVESTMENT
    final totalValue =
        remainingCapital; // Zgodnie z modelem: totalValue => remainingCapital
    final profitLoss = remainingCapital - investmentAmount; // Zgodnie z modelem
    final profitLossPercentage = investmentAmount > 0
        ? (profitLoss / investmentAmount) * 100
        : 0.0;

    // Kapitał zabezpieczony = max(remainingCapital - capitalForRestructuring, 0)
    final capitalSecured = (remainingCapital - capitalForRestructuring).clamp(
      0.0,
      double.infinity,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundTertiary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemePro.borderSecondary.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Obliczenia automatyczne',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppThemePro.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildCalculatedValue(
                'Wartość całkowita',
                totalValue,
                Icons.assessment,
                AppThemePro.neutralGray,
              ),
              _buildCalculatedValue(
                'Zysk/Strata',
                profitLoss,
                profitLoss >= 0 ? Icons.trending_up : Icons.trending_down,
                AppThemePro.getPerformanceColor(profitLoss),
              ),
              _buildCalculatedValue(
                'Kapitał zabezpieczony',
                capitalSecured,
                Icons.security,
                AppThemePro.realEstateViolet,
              ),
            ],
          ),

          if (profitLossPercentage != 0) ...[
            const SizedBox(height: 8),
            Text(
              'Wydajność: ${profitLossPercentage >= 0 ? '+' : ''}${profitLossPercentage.toStringAsFixed(2)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppThemePro.getPerformanceColor(profitLossPercentage),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalculatedValue(
    String label,
    double value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          '$label: ${CurrencyFormatter.formatCurrency(value)}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppThemePro.textSecondary),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppThemePro.neutralGray.withOpacity(0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.search_off,
                color: AppThemePro.neutralGray,
                size: 32,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Brak inwestycji',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppThemePro.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Nie znaleziono inwestycji dla tego produktu',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppThemePro.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(color: AppThemePro.borderPrimary, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Info about changes
          if (_modifiedInvestments.isNotEmpty)
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppThemePro.statusWarning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.edit,
                      color: AppThemePro.statusWarning,
                      size: 16,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Text(
                    '${_modifiedInvestments.length} zmian do zapisania',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppThemePro.statusWarning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          if (_modifiedInvestments.isEmpty) const Spacer(),

          // Buttons
          Row(
            children: [
              // Cancel button
              OutlinedButton(
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppThemePro.textSecondary,
                  side: BorderSide(
                    color: AppThemePro.borderSecondary,
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Anuluj'),
              ),

              const SizedBox(width: 12),

              // Save button
              ElevatedButton(
                onPressed:
                    _isSaving || !_isEditMode || _modifiedInvestments.isEmpty
                    ? null
                    : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemePro.accentGold,
                  foregroundColor: AppThemePro.primaryDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: _isSaving
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppThemePro.primaryDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Zapisywanie...'),
                        ],
                      )
                    : const Text('Zapisz zmiany'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getProductIcon(UnifiedProductType productType) {
    switch (productType) {
      case UnifiedProductType.bonds:
        return Icons.account_balance;
      case UnifiedProductType.shares:
        return Icons.trending_up;
      case UnifiedProductType.loans:
        return Icons.monetization_on;
      case UnifiedProductType.apartments:
        return Icons.home;
      case UnifiedProductType.other:
        return Icons.inventory;
    }
  }

  void _collectModifiedInvestments() {
    _modifiedInvestments.clear();
    

    for (int i = 0; i < _productInvestments.length; i++) {
      final investment = _productInvestments[i];
      final prefix = 'inv_${i}_';

      // Parse new values from controllers
      final newInvestmentAmount =
          double.tryParse(_controllers['${prefix}investmentAmount']!.text) ??
          0.0;
      final newPaidAmount =
          double.tryParse(_controllers['${prefix}paidAmount']!.text) ?? 0.0;
      final newRemainingCapital =
          double.tryParse(_controllers['${prefix}remainingCapital']!.text) ??
          0.0;
      final newRealizedCapital =
          double.tryParse(_controllers['${prefix}realizedCapital']!.text) ??
          0.0;
      final newRealizedInterest =
          double.tryParse(_controllers['${prefix}realizedInterest']!.text) ??
          0.0;
      final newRemainingInterest =
          double.tryParse(_controllers['${prefix}remainingInterest']!.text) ??
          0.0;
      final newTransferToOtherProduct =
          double.tryParse(
            _controllers['${prefix}transferToOtherProduct']!.text,
          ) ??
          0.0;
      final newCapitalForRestructuring =
          double.tryParse(
            _controllers['${prefix}capitalForRestructuring']!.text,
          ) ??
          0.0;
      final newCapitalSecuredByRealEstate =
          double.tryParse(
            _controllers['${prefix}capitalSecuredByRealEstate']!.text,
          ) ??
          0.0;
      final newPlannedTax =
          double.tryParse(_controllers['${prefix}plannedTax']!.text) ?? 0.0;
      final newRealizedTax =
          double.tryParse(_controllers['${prefix}realizedTax']!.text) ?? 0.0;

      // 🔍 DEBUG: Sprawdź różnice
      bool hasChanges = newInvestmentAmount != investment.investmentAmount ||
          newPaidAmount != investment.paidAmount ||
          newRemainingCapital != investment.remainingCapital ||
          newRealizedCapital != investment.realizedCapital ||
          newRealizedInterest != investment.realizedInterest ||
          newRemainingInterest != investment.remainingInterest ||
          newTransferToOtherProduct != investment.transferToOtherProduct ||
          newCapitalForRestructuring != investment.capitalForRestructuring ||
          newCapitalSecuredByRealEstate !=
              investment.capitalSecuredByRealEstate ||
          newPlannedTax != investment.plannedTax ||
          newRealizedTax != investment.realizedTax;

      if (hasChanges) {
      }

      // 🔍 SPRAWDŹ CZY KTÓRAKOLWIEK WARTOŚĆ SIĘ ZMIENIŁA
      if (hasChanges) {
          newPaidAmount != investment.paidAmount ||
          newRemainingCapital != investment.remainingCapital ||
          newRealizedCapital != investment.realizedCapital ||
          newRealizedInterest != investment.realizedInterest ||
          newRemainingInterest != investment.remainingInterest ||
          newTransferToOtherProduct != investment.transferToOtherProduct ||
          newCapitalForRestructuring != investment.capitalForRestructuring ||
          newCapitalSecuredByRealEstate !=
              investment.capitalSecuredByRealEstate ||
          newPlannedTax != investment.plannedTax ||
          newRealizedTax != investment.realizedTax) {
        final modifiedInvestment = investment.copyWith(
          investmentAmount: newInvestmentAmount,
          paidAmount: newPaidAmount,
          remainingCapital: newRemainingCapital,
          realizedCapital: newRealizedCapital,
          realizedInterest: newRealizedInterest,
          remainingInterest: newRemainingInterest,
          transferToOtherProduct: newTransferToOtherProduct,
          capitalForRestructuring: newCapitalForRestructuring,
          capitalSecuredByRealEstate: newCapitalSecuredByRealEstate,
          plannedTax: newPlannedTax,
          realizedTax: newRealizedTax,
          updatedAt: DateTime.now(),
        );

        _modifiedInvestments[investment.id] = modifiedInvestment;
      }
    }
  }

  /// 🎯 NOWA METODA: Automatycznie śledzi zmiany w polach tekstowych
  void _trackChanges() {
    if (!_isEditMode) return;

    setState(() {
      _collectModifiedInvestments();
      // 🔍 DEBUG: Sprawdź stan modyfikacji
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      _collectModifiedInvestments();

      if (_modifiedInvestments.isEmpty) {
        _showSnackBar('Brak zmian do zapisania', isError: false);
        return;
      }

      // Save to Firebase
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // 🔍 PRZYGOTUJ DANE DO HISTORII ZMIAN
      final oldInvestments = <Investment>[];
      final newInvestments = <Investment>[];

      for (final entry in _modifiedInvestments.entries) {
        final investmentId = entry.key;
        final modifiedInvestment = entry.value;

        // Znajdź oryginalną inwestycję
        final originalInvestment = _productInvestments.firstWhere(
          (inv) => inv.id == investmentId,
        );

        oldInvestments.add(originalInvestment);
        newInvestments.add(modifiedInvestment);

        final docRef = firestore.collection('investments').doc(investmentId);
        batch.update(docRef, modifiedInvestment.toFirestore());
      }

      // Zapisz zmiany do Firebase
      await batch.commit();

      // 🔍 ZAPISZ HISTORIĘ ZMIAN
      try {
        await _historyService.recordBulkChanges(
          oldInvestments: oldInvestments,
          newInvestments: newInvestments,
          customDescription:
              'Edycja inwestycji przez dialog - produkt: ${widget.product.name}',
          metadata: {
            'source': 'investor_edit_dialog',
            'productId': widget.product.id,
            'productName': widget.product.name,
            'clientId': widget.investor.client.id,
            'clientName': widget.investor.client.name,
            'investmentsCount': _modifiedInvestments.length,
          },
        );
      } catch (historyError) {
        // Nie przerywaj procesu jeśli historia się nie zapisze
      }

      _showSnackBar(
        'Zapisano ${_modifiedInvestments.length} zmian pomyślnie!',
        isError: false,
      );

      // Notify parent and close
      widget.onSaved?.call();
      Navigator.of(context).pop();
    } catch (e) {
      _showSnackBar('Błąd podczas zapisywania: $e', isError: true);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError
            ? AppThemePro.statusError
            : AppThemePro.statusSuccess,
        duration: Duration(seconds: isError ? 5 : 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// 🔍 NOWA METODA: Buduje przycisk do wyświetlania historii zmian
  Widget _buildHistoryButton(Investment investment) {
    return Container(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => _showInvestmentHistory(investment),
        style: TextButton.styleFrom(
          backgroundColor: AppThemePro.accentGold.withOpacity(0.1),
          foregroundColor: AppThemePro.accentGold,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: AppThemePro.accentGold.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        icon: const Icon(Icons.history, size: 16),
        label: Text(
          'Zobacz historię zmian',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppThemePro.accentGold,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 🔍 NOWA METODA: Pokazuje dialog z historią zmian inwestycji
  void _showInvestmentHistory(Investment investment) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppThemePro.backgroundPrimary,
                AppThemePro.backgroundSecondary,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppThemePro.accentGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppThemePro.borderPrimary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppThemePro.accentGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.history,
                        color: AppThemePro.accentGold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Historia zmian inwestycji',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppThemePro.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${investment.id}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppThemePro.textMuted,
                                  fontFamily: 'monospace',
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: AppThemePro.lossRed.withOpacity(0.1),
                        foregroundColor: AppThemePro.lossRed,
                      ),
                    ),
                  ],
                ),
              ),

              // History content
              Expanded(
                child: InvestmentHistoryWidget(investmentId: investment.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
