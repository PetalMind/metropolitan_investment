import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models_and_services.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme_professional.dart';
import '../investor_edit/currency_controls.dart';
import '../investor_edit/investment_edit_card.dart';

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
class RefactoredInvestorEditDialog extends StatefulWidget {
  final InvestorSummary investor;
  final UnifiedProduct product;
  final VoidCallback onSaved;

  const RefactoredInvestorEditDialog({
    super.key,
    required this.investor,
    required this.product,
    required this.onSaved,
  });

  @override
  State<RefactoredInvestorEditDialog> createState() =>
      _RefactoredInvestorEditDialogState();
}

class _RefactoredInvestorEditDialogState
    extends State<RefactoredInvestorEditDialog> {
  final _formKey = GlobalKey<FormState>();

  // Services
  late final InvestorEditService _editService;

  // State
  late InvestorEditState _state;
  late InvestmentEditControllers _controllers;
  late List<Investment> _editableInvestments;

  // RBAC: sprawdzenie uprawnień
  bool get canEdit => context.read<AuthProvider>().isAdmin;

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
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: AppThemePro.backgroundPrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppThemePro.borderPrimary),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
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
        color: AppThemePro.backgroundSecondary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(bottom: BorderSide(color: AppThemePro.borderPrimary)),
      ),
      child: Row(
        children: [
          Icon(Icons.edit, color: AppThemePro.accentGold, size: 24),
          const SizedBox(width: 12),
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
            icon: Icon(Icons.close, color: AppThemePro.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_editableInvestments.isEmpty) {
      return _buildErrorView();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_state.error != null) _buildErrorCard(),

            // Kontrolka całkowitej kwoty produktu
            ProductTotalAmountControl(
              controller: _controllers.totalProductAmountController,
              originalAmount: _state.originalTotalProductAmount,
              isChangingAmount: _state.isChangingTotalAmount,
              pendingChange: _state.pendingTotalAmountChange,
              onChanged: _onDataChanged,
            ),

            const SizedBox(height: 24),

            // Lista inwestycji do edycji
            Text(
              'Inwestycje do edycji (${_editableInvestments.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            ...List.generate(_editableInvestments.length, (index) {
              return InvestmentEditCard(
                investment: _editableInvestments[index],
                index: index,
                remainingCapitalController:
                    _controllers.remainingCapitalControllers[index],
                investmentAmountController:
                    _controllers.investmentAmountControllers[index],
                capitalForRestructuringController:
                    _controllers.capitalForRestructuringControllers[index],
                capitalSecuredController:
                    _controllers.capitalSecuredByRealEstateControllers[index],
                statusValue: _controllers.statusValues[index],
                onStatusChanged: (status) => _onStatusChanged(index, status),
                onChanged: _onDataChanged,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppThemePro.lossRed),
            const SizedBox(height: 16),
            Text(
              'Nie znaleziono inwestycji',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _state.error ??
                  'Brak dostępnych inwestycji dla tego produktu i inwestora.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemePro.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.lossRedBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.lossRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppThemePro.lossRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _state.error!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppThemePro.lossRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(top: BorderSide(color: AppThemePro.borderPrimary)),
      ),
      child: Row(
        children: [
          // Status info
          if (_state.isChanged)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppThemePro.statusWarning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 14, color: AppThemePro.statusWarning),
                  const SizedBox(width: 4),
                  Text(
                    'Niezapisane zmiany',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.statusWarning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          // Anuluj
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Anuluj',
              style: TextStyle(color: AppThemePro.textSecondary),
            ),
          ),

          const SizedBox(width: 12),

          // Zapisz
          Tooltip(
            message: canEdit
                ? 'Zapisz zmiany inwestycji'
                : kRbacNoPermissionTooltip,
            child: ElevatedButton(
              onPressed: canEdit && !_state.isLoading ? _saveChanges : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canEdit
                    ? AppThemePro.accentGold
                    : Colors.grey.shade400,
                foregroundColor: canEdit
                    ? AppThemePro.backgroundPrimary
                    : Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: _state.isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          canEdit
                              ? AppThemePro.backgroundPrimary
                              : Colors.grey.shade600,
                        ),
                      ),
                    )
                  : Text(
                      'Zapisz zmiany',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
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
