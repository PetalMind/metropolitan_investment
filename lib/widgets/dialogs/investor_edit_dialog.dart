import 'package:flutter/material.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';
import '../investor_edit/currency_controls.dart';
import '../investor_edit/investments_summary.dart';
import '../investor_edit/investment_edit_card.dart';
import 'investor_edit_dialog_enhancements.dart';

/// 📝 Dialog edycji inwestora - Wersja refaktoryzowana
///
/// Pozwala edytować kwoty inwestycji dla wybranego inwestora w ramach produktu
/// Funkcjonalności:
/// - Edycja kwot pozostałego kapitału
/// - Edycja kwot inwestycji
/// - Edycja statusów inwestycji
/// - Skalowanie całego produktu
/// - Walidacja danych
/// - Zapis zmian przez InvestorEditService
/// - Historia zmian
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

  // Services
  late final InvestorEditService _editService;

  // State
  late InvestorEditState _state;
  late InvestmentEditControllers _controllers;
  late List<Investment> _editableInvestments;

  @override
  void initState() {
    super.initState();
    _editService = InvestorEditService();
    _state = const InvestorEditState();
    _initializeData();
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  void _initializeData() {
    // Znajdź inwestycje dla produktu
    _editableInvestments = _editService.findInvestmentsForProduct(
      widget.investor,
      widget.product,
    );

    if (_editableInvestments.isEmpty) {
      setState(() {
        _state = _state.copyWith(
          error: 'Nie znaleziono inwestycji dla tego produktu',
        );
      });
      return;
    }

    _setupControllers();
  }

  void _setupControllers() {
    // Utwórz kontrolery
    final remainingCapitalControllers = <TextEditingController>[];
    final investmentAmountControllers = <TextEditingController>[];
    final capitalForRestructuringControllers = <TextEditingController>[];
    final capitalSecuredControllers = <TextEditingController>[];
    final statusValues = <InvestmentStatus>[];

    for (final investment in _editableInvestments) {
      remainingCapitalControllers.add(
        TextEditingController(
          text: _editService.formatValueForController(
            investment.remainingCapital,
          ),
        ),
      );
      investmentAmountControllers.add(
        TextEditingController(
          text: _editService.formatValueForController(
            investment.investmentAmount,
          ),
        ),
      );
      capitalForRestructuringControllers.add(
        TextEditingController(
          text: _editService.formatValueForController(
            investment.capitalForRestructuring,
          ),
        ),
      );
      capitalSecuredControllers.add(
        TextEditingController(
          text: _editService.formatValueForController(
            investment.capitalSecuredByRealEstate,
          ),
        ),
      );
      statusValues.add(investment.status);
    }

    // Oblicz całkowitą kwotę produktu
    final totalAmount = _editableInvestments.fold<double>(
      0.0,
      (sum, inv) => sum + inv.investmentAmount,
    );

    final totalController = TextEditingController(
      text: _editService.formatValueForController(totalAmount),
    );

    _controllers = InvestmentEditControllers(
      remainingCapitalControllers: remainingCapitalControllers,
      investmentAmountControllers: investmentAmountControllers,
      capitalForRestructuringControllers: capitalForRestructuringControllers,
      capitalSecuredByRealEstateControllers: capitalSecuredControllers,
      statusValues: statusValues,
      totalProductAmountController: totalController,
    );

    // Ustaw listenery
    _setupListeners();

    // Zaktualizuj stan
    setState(() {
      _state = _state.copyWith(originalTotalProductAmount: totalAmount);
    });
  }

  void _setupListeners() {
    // Listenery dla kontrolerów inwestycji
    for (int i = 0; i < _editableInvestments.length; i++) {
      _controllers.remainingCapitalControllers[i].addListener(_onDataChanged);
      _controllers.investmentAmountControllers[i].addListener(() {
        _onDataChanged();
        _calculateAutomaticValues(i);
      });
      _controllers.capitalForRestructuringControllers[i].addListener(() {
        _onDataChanged();
        _calculateAutomaticValues(i);
      });
      _controllers.capitalSecuredByRealEstateControllers[i].addListener(() {
        _onDataChanged();
        _calculateAutomaticValues(i);
      });
    }

    // Listener dla całkowitej kwoty produktu
    _controllers.totalProductAmountController.addListener(
      _onTotalAmountChanged,
    );
  }

  void _onDataChanged() {
    setState(() {
      _state = _state.withChanges();
    });
  }

  void _onTotalAmountChanged() {
    if (_state.isChangingTotalAmount) return;

    final newTotalAmountText = _controllers.totalProductAmountController.text;
    final newTotalAmount = _editService.parseValueFromController(
      newTotalAmountText,
    );

    if (newTotalAmount <= 0) return;

    // Sprawdź czy wartość rzeczywiście się zmieniła
    if ((newTotalAmount - _state.originalTotalProductAmount).abs() < 0.01) {
      if (_state.pendingTotalAmountChange != null) {
        setState(() {
          _state = _state.copyWith(pendingTotalAmountChange: null);
        });
      }
      return;
    }

    debugPrint('🔢 [RefactoredDialog] Zmiana całkowitej kwoty produktu:');
    debugPrint(
      '   - Oryginalna kwota: ${_state.originalTotalProductAmount.toStringAsFixed(2)}',
    );
    debugPrint('   - Nowa kwota: ${newTotalAmount.toStringAsFixed(2)}');

    setState(() {
      _state = _state.copyWith(
        pendingTotalAmountChange: newTotalAmount,
        isChanged: true,
      );
    });
  }

  void _calculateAutomaticValues(int index) {
    final investmentAmountText =
        _controllers.investmentAmountControllers[index].text;
    final capitalForRestructuringText =
        _controllers.capitalForRestructuringControllers[index].text;
    final capitalSecuredText =
        _controllers.capitalSecuredByRealEstateControllers[index].text;

    final investmentAmount = _editService.parseValueFromController(
      investmentAmountText,
    );
    final capitalForRestructuring = _editService.parseValueFromController(
      capitalForRestructuringText,
    );
    final capitalSecured = _editService.parseValueFromController(
      capitalSecuredText,
    );

    // Oblicz kapitał pozostały
    final calculatedRemainingCapital = _editService.calculateRemainingCapital(
      capitalSecured,
      capitalForRestructuring,
    );

    // Aktualizuj pole pozostałego kapitału
    final currentRemainingCapital = _editService.parseValueFromController(
      _controllers.remainingCapitalControllers[index].text,
    );

    if ((calculatedRemainingCapital - currentRemainingCapital).abs() > 0.01) {
      _controllers.remainingCapitalControllers[index].text = _editService
          .formatValueForController(calculatedRemainingCapital);
    }

    // Sprawdź zgodność z kwotą inwestycji
    if ((calculatedRemainingCapital - investmentAmount).abs() > 0.01) {
      debugPrint(
        '⚠️ [RefactoredDialog] Niezgodność sum dla inwestycji ${index + 1}',
      );
    }
  }

  void _onStatusChanged(int index, InvestmentStatus newStatus) {
    setState(() {
      _controllers.statusValues[index] = newStatus;
      _state = _state.withChanges();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: DialogBreakpoints.getDialogPadding(context),
      child: Container(
        width: DialogBreakpoints.getDialogWidth(context),
        height: DialogBreakpoints.getDialogHeight(context),
        decoration: PremiumDialogDecorations.premiumContainerDecoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              _buildPremiumHeader(),
              Expanded(child: _buildProfessionalContent()),
              _buildPremiumActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: PremiumDialogDecorations.headerGradient,
        border: Border(
          bottom: BorderSide(
            color: AppThemePro.accentGold.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: Row(
          children: [
            // Premium icon with glow effect
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppThemePro.accentGold, AppThemePro.accentGoldMuted],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppThemePro.accentGold.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.edit_rounded,
                color: AppThemePro.primaryDark,
                size: 28,
              ),
            ),

            const SizedBox(width: 20),

            // Title section with enhanced typography
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        'EDYCJA INWESTORA',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppThemePro.textPrimary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              height: 1.1,
                            ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppThemePro.accentGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppThemePro.accentGold.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'PREMIUM',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppThemePro.accentGold,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: AppThemePro.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.investor.client.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppThemePro.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppThemePro.accentGold,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.business_center_rounded,
                        size: 16,
                        color: AppThemePro.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppThemePro.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Close button with premium styling
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppThemePro.backgroundTertiary.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppThemePro.borderSecondary,
                  width: 1,
                ),
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close_rounded,
                  color: AppThemePro.textSecondary,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalContent() {
    if (_editableInvestments.isEmpty) {
      return _buildPremiumErrorView();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppThemePro.backgroundPrimary,
            AppThemePro.backgroundPrimary.withBlue(15),
          ],
        ),
      ),
      child: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // Error notification if present
            if (_state.error != null)
              SliverToBoxAdapter(child: _buildPremiumErrorCard()),

            // Investments grid section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _buildInvestmentsSection(),
              ),
            ),
            // Executive summary section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: _buildExecutiveSummary(),
              ),
            ),

           

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveSummary() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.backgroundSecondary,
            AppThemePro.backgroundSecondary.withBlue(20),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemePro.accentGold.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.accentGold.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppThemePro.accentGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.analytics_rounded,
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
                        'KONTROLA PRODUKTU',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppThemePro.textPrimary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                      ),
                      Text(
                        'Zarządzanie całkowitą wartością i skalowanie',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppThemePro.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Product total amount control with enhanced styling
            ProductTotalAmountControl(
              controller: _controllers.totalProductAmountController,
              originalAmount: _state.originalTotalProductAmount,
              isChangingAmount: _state.isChangingTotalAmount,
              pendingChange: _state.pendingTotalAmountChange,
              onChanged: _onDataChanged,
            ),

            const SizedBox(height: 28),

            // Enhanced investments summary
            Container(
              decoration: BoxDecoration(
                color: AppThemePro.backgroundTertiary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppThemePro.borderSecondary.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: InvestmentsSummaryWidget(
                  investments: _editableInvestments,
                  remainingCapitalControllers:
                      _controllers.remainingCapitalControllers,
                  investmentAmountControllers:
                      _controllers.investmentAmountControllers,
                  capitalForRestructuringControllers:
                      _controllers.capitalForRestructuringControllers,
                  capitalSecuredControllers:
                      _controllers.capitalSecuredByRealEstateControllers,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with modern styling
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppThemePro.backgroundSecondary.withOpacity(0.8),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            border: Border.all(color: AppThemePro.borderPrimary, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppThemePro.accentGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: AppThemePro.accentGold,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INWESTYCJE DO EDYCJI',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppThemePro.textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_editableInvestments.length} pozycji do zarządzania',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppThemePro.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppThemePro.accentGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppThemePro.accentGold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${_editableInvestments.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppThemePro.accentGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Investments cards with enhanced spacing
        Container(
          decoration: BoxDecoration(
            color: AppThemePro.backgroundSecondary.withOpacity(0.3),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            border: Border(
              left: BorderSide(color: AppThemePro.borderPrimary, width: 1),
              right: BorderSide(color: AppThemePro.borderPrimary, width: 1),
              bottom: BorderSide(color: AppThemePro.borderPrimary, width: 1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: List.generate(_editableInvestments.length, (index) {
                return Container(
                  margin: EdgeInsets.only(
                    bottom: index < _editableInvestments.length - 1 ? 20 : 0,
                  ),
                  child: InvestmentEditCard(
                    investment: _editableInvestments[index],
                    index: index,
                    remainingCapitalController:
                        _controllers.remainingCapitalControllers[index],
                    investmentAmountController:
                        _controllers.investmentAmountControllers[index],
                    capitalForRestructuringController:
                        _controllers.capitalForRestructuringControllers[index],
                    capitalSecuredController: _controllers
                        .capitalSecuredByRealEstateControllers[index],
                    statusValue: _controllers.statusValues[index],
                    onStatusChanged: (status) =>
                        _onStatusChanged(index, status),
                    onChanged: _onDataChanged,
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumErrorView() {
    return Container(
      margin: const EdgeInsets.all(32),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppThemePro.lossRedBg.withOpacity(0.1),
                AppThemePro.lossRedBg.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppThemePro.lossRed.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppThemePro.lossRed.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppThemePro.lossRed.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: AppThemePro.lossRed,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'BRAK DOSTĘPNYCH INWESTYCJI',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Text(
                  _state.error ??
                      'Nie znaleziono inwestycji dla tego produktu i inwestora. Sprawdź konfigurację lub skontaktuj się z administratorem.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppThemePro.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.arrow_back_rounded, size: 18),
                label: Text('Powrót do listy'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemePro.accentGold,
                  foregroundColor: AppThemePro.backgroundPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumErrorCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.lossRedBg.withOpacity(0.8),
            AppThemePro.lossRedBg.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemePro.lossRed.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.lossRed.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppThemePro.lossRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: AppThemePro.lossRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BŁĄD OPERACJI',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppThemePro.lossRed,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _state.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemePro.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumActions() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: PremiumDialogDecorations.footerGradient,
        border: Border(
          top: BorderSide(
            color: AppThemePro.accentGold.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: Row(
          children: [
            // Status indicator section
            Expanded(
              child: ChangeStatusIndicator(
                hasChanges: _state.isChanged,
                changeText: 'ZMIANY OCZEKUJĄ',
                noChangeText: 'GOTOWY DO EDYCJI',
              ),
            ),

            const SizedBox(width: 24),

            // Action buttons
            Row(
              children: [
                // Cancel button
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppThemePro.backgroundTertiary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppThemePro.borderSecondary,
                      width: 1,
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Anuluj',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppThemePro.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Save button
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: _state.isLoading
                        ? LinearGradient(
                            colors: [
                              AppThemePro.accentGold.withOpacity(0.6),
                              AppThemePro.accentGoldMuted.withOpacity(0.6),
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppThemePro.accentGold,
                              AppThemePro.accentGoldMuted,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _state.isLoading
                        ? null
                        : [
                            BoxShadow(
                              color: AppThemePro.accentGold.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: ElevatedButton(
                    onPressed: _state.isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppThemePro.backgroundPrimary,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_state.isLoading) ...[
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppThemePro.backgroundPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Zapisywanie...',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppThemePro.backgroundPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ] else ...[
                          Icon(
                            Icons.save_rounded,
                            size: 18,
                            color: AppThemePro.backgroundPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ZAPISZ ZMIANY',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppThemePro.backgroundPrimary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _state = _state.withLoading(true).clearError();
    });

    try {
      // Najpierw obsłuż skalowanie całego produktu (jeśli wymagane)
      if (_state.pendingTotalAmountChange != null) {
        final scalingResult = await _editService.scaleProduct(
          product: widget.product,
          newTotalAmount: _state.pendingTotalAmountChange!,
          originalTotalAmount: _state.originalTotalProductAmount,
          reason:
              'Skalowanie całkowitej kwoty produktu przez ${widget.investor.client.name}',
        );

        if (!scalingResult.success) {
          setState(() {
            _state = _state
                .withLoading(false)
                .copyWith(error: scalingResult.message);
          });
          return;
        }

        // Zapisz zmianę całkowitej kwoty do historii i przeładuj dane
        final newAmount = _state.pendingTotalAmountChange!;

        setState(() {
          _state = _state.copyWith(
            originalTotalProductAmount: newAmount,
            pendingTotalAmountChange: null,
            isChanged: false,
          );
        });

        // Przeładuj dane inwestycji po skalowaniu
        final updatedInvestments = await _editService
            .reloadInvestmentsAfterScaling(_editableInvestments);
        setState(() {
          _editableInvestments = updatedInvestments;
        });

        // Pokaż powiadomienie o sukcesie
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Skalowanie produktu zakończone pomyślnie'),
              backgroundColor: Colors.green[700],
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Odśwież dane externally
        widget.onSaved();

        setState(() {
          _state = _state.withLoading(false);
        });
        return;
      }

      // Obsłuż standardowe zmiany pojedynczych inwestycji
      final success = await _editService.saveInvestmentChanges(
        originalInvestments: _editableInvestments,
        remainingCapitalControllers: _controllers.remainingCapitalControllers,
        investmentAmountControllers: _controllers.investmentAmountControllers,
        capitalForRestructuringControllers:
            _controllers.capitalForRestructuringControllers,
        capitalSecuredControllers:
            _controllers.capitalSecuredByRealEstateControllers,
        statusValues: _controllers.statusValues,
        changeReason: 'Edycja inwestycji przez ${widget.investor.client.name}',
      );

      if (success) {
        // Pokaż powiadomienie o sukcesie
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Zmiany zostały zapisane pomyślnie'),
              backgroundColor: Colors.green[700],
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Odśwież dane externally
        widget.onSaved();

        setState(() {
          _state = _state.resetChanges().withLoading(false);
        });
      } else {
        setState(() {
          _state = _state
              .withLoading(false)
              .copyWith(error: 'Błąd podczas zapisywania zmian');
        });
      }
    } catch (e) {
      debugPrint('❌ [RefactoredDialog] Błąd podczas zapisywania: $e');
      setState(() {
        _state = _state
            .withLoading(false)
            .copyWith(error: 'Błąd podczas zapisywania zmian: ${e.toString()}');
      });
    }
  }
}
