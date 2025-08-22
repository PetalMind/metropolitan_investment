import 'package:flutter/material.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';
import '../../services/universal_investment_service.dart' as universal;
import '../investor_edit/currency_controls.dart';
import '../investor_edit/investments_summary.dart';
import '../investor_edit/investment_edit_card.dart';
import '../investor_edit/investment_edit_card.dart';
import '../investment_history_widget.dart'; // 🚀 NOWE: Widget historii zmian
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

class _InvestorEditDialogState extends State<InvestorEditDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Services
  late final InvestorEditService _editService;

  // State
  late InvestorEditState _state;
  late InvestmentEditControllers _controllers;
  late List<Investment> _editableInvestments;

  // 🚀 NOWE: Kontroler zakładek
  late TabController _tabController;
  // ignore: unused_field
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _editService = InvestorEditService();
    _state = const InvestorEditState();

    // 🚀 NOWE: Inicjalizacja TabController
    _tabController = TabController(
      length: 2, // Edycja + Historia
      vsync: this,
    );
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });

    // 🎯 FORCE FRESH DATA: Rozpocznij od świeżych danych zamiast starych z widget.investor
    _initializeData();
  }

  @override
  void dispose() {
    _controllers.dispose();
    _tabController.dispose(); // 🚀 NOWE: Dispose TabController
    super.dispose();
  }

  void _initializeData() {
    // 🎯 IMPROVED: Inicjalizuj bezpośrednio ze świeżymi danymi zamiast szukania
    _loadFreshInvestmentData();
  }

  /// 🚀 NOWA METODA: Ładuje świeże dane bezpośrednio z UniversalInvestmentService
  Future<void> _loadFreshInvestmentData() async {
    try {
      debugPrint(
        '🔄 [InvestorEditDialog] Loading fresh investment data for product: ${widget.product.name}',
      );

      // Znajdź inwestycje używając podstawowego dopasowania
      final potentialInvestments = widget.investor.investments.where((inv) {
        // Podstawowe dopasowanie po nazwie produktu
        final nameMatch =
            inv.productName.trim().toLowerCase() ==
            widget.product.name.trim().toLowerCase();

        if (nameMatch) {
          debugPrint(
            '🎯 [InvestorEditDialog] Found potential match: ${inv.id} (${inv.productName})',
          );
          return true;
        }
        return false;
      }).toList();

      if (potentialInvestments.isEmpty) {
        setState(() {
          _state = _state.copyWith(
            error: 'Nie znaleziono inwestycji dla tego produktu',
          );
        });
        return;
      }

      // Pobierz świeże dane dla znalezionych inwestycji
      final investmentIds = potentialInvestments.map((inv) => inv.id).toList();
      debugPrint(
        '🔍 [InvestorEditDialog] Fetching fresh data for investments: $investmentIds',
      );

      final universalService = universal.UniversalInvestmentService.instance;
      await universalService.clearAllCache(); // Force fresh fetch

      final freshInvestments = await universalService.getInvestments(
        investmentIds,
      );

      if (freshInvestments.isEmpty) {
        debugPrint(
          '⚠️ [InvestorEditDialog] No fresh data found, using potential investments',
        );
        debugPrint(
          '⚠️ [InvestorEditDialog] This might cause data inconsistency - investigating...',
        );
        _editableInvestments = potentialInvestments;
      } else {
        debugPrint(
          '✅ [InvestorEditDialog] Using fresh data for ${freshInvestments.length} investments',
        );

        // 🔍 DIAGNOSTICS: Compare fresh vs potential data
        for (
          int i = 0;
          i < freshInvestments.length && i < potentialInvestments.length;
          i++
        ) {
          final fresh = freshInvestments[i];
          final potential = potentialInvestments[i];

          if (fresh.id == potential.id) {
            debugPrint(
              '🔍 [InvestorEditDialog] Data comparison for ${fresh.id}:',
            );
            debugPrint(
              '   FRESH:     remainingCapital=${fresh.remainingCapital}, investmentAmount=${fresh.investmentAmount}',
            );
            debugPrint(
              '   POTENTIAL: remainingCapital=${potential.remainingCapital}, investmentAmount=${potential.investmentAmount}',
            );

            if (fresh.remainingCapital != potential.remainingCapital ||
                fresh.investmentAmount != potential.investmentAmount) {
              debugPrint(
                '⚠️ [InvestorEditDialog] DATA MISMATCH DETECTED - using fresh data',
              );
            }
          }
        }

        _editableInvestments = freshInvestments;
      }

      // Loguj finalne dane
      for (int i = 0; i < _editableInvestments.length; i++) {
        final inv = _editableInvestments[i];
        debugPrint('📊 [InvestorEditDialog] Final investment $i: ${inv.id}');
        debugPrint('   - remainingCapital: ${inv.remainingCapital}');
        debugPrint('   - investmentAmount: ${inv.investmentAmount}');
        debugPrint(
          '   - capitalForRestructuring: ${inv.capitalForRestructuring}',
        );
        debugPrint(
          '   - capitalSecuredByRealEstate: ${inv.capitalSecuredByRealEstate}',
        );
        debugPrint('   - updatedAt: ${inv.updatedAt.toIso8601String()}');
      }

      _setupControllers();
    } catch (e) {
      debugPrint(
        '❌ [InvestorEditDialog] Error loading fresh investment data: $e',
      );
      setState(() {
        _state = _state.copyWith(
          error: 'Błąd podczas ładowania danych inwestycji',
        );
      });
    }
  }

  /// Reloads investment data from Firebase and updates controllers
  Future<void> _reloadInvestmentData() async {
    try {
      debugPrint('🔄 [InvestorEditDialog] Starting investment data reload...');

      // Give Firebase time to propagate changes (longer delay for consistency)
      await Future.delayed(const Duration(milliseconds: 1000));

      // 🎯 UNIFIED: Clear all caches to ensure consistency with product views
      await _editService.clearInvestmentCache();

      // 🚀 FORCE FRESH FETCH: Bypass all caching for this critical operation
      final universalService = universal.UniversalInvestmentService.instance;
      await universalService.clearAllCache();

      // Re-fetch specific investments directly by their IDs (most reliable approach)
      final originalInvestmentIds = _editableInvestments
          .map((inv) => inv.id)
          .toList();
      debugPrint(
        '� [InvestorEditDialog] Re-fetching investments by IDs: $originalInvestmentIds',
      );

      final freshInvestments = await universalService.getInvestments(
        originalInvestmentIds,
      );

      if (freshInvestments.isEmpty) {
        debugPrint(
          '⚠️ [InvestorEditDialog] No fresh investments found, keeping original data',
        );
        return;
      }

      // Update the editable investments with fresh data
      _editableInvestments = freshInvestments;

      debugPrint(
        '🔄 [InvestorEditDialog] Updated with ${_editableInvestments.length} fresh investments',
      );

      // Log the fresh values with detailed comparison
      for (int i = 0; i < _editableInvestments.length; i++) {
        final inv = _editableInvestments[i];
        debugPrint('📊 [InvestorEditDialog] Fresh investment $i: ${inv.id}');
        debugPrint('   - remainingCapital: ${inv.remainingCapital}');
        debugPrint('   - investmentAmount: ${inv.investmentAmount}');
        debugPrint(
          '   - capitalForRestructuring: ${inv.capitalForRestructuring}',
        );
        debugPrint(
          '   - capitalSecuredByRealEstate: ${inv.capitalSecuredByRealEstate}',
        );
        debugPrint('   - updatedAt: ${inv.updatedAt.toIso8601String()}');
      }

      // Dispose old controllers and create new ones with fresh data
      _controllers.dispose();
      _setupControllers();

      // Force UI update
      if (mounted) {
        setState(() {
          _state = _state.resetChanges();
        });
      }

      debugPrint(
        '✅ [InvestorEditDialog] Investment data reloaded successfully with fresh values',
      );
    } catch (e) {
      debugPrint('❌ [InvestorEditDialog] Error reloading investment data: $e');
      // Continue without error - dialog will still function with old data
    }
  }

  void _setupControllers() {
    debugPrint(
      '🔧 [InvestorEditDialog] Setting up controllers for ${_editableInvestments.length} investments',
    );

    // Utwórz kontrolery
    final remainingCapitalControllers = <TextEditingController>[];
    final investmentAmountControllers = <TextEditingController>[];
    final capitalForRestructuringControllers = <TextEditingController>[];
    final capitalSecuredControllers = <TextEditingController>[];
    final statusValues = <InvestmentStatus>[];

    for (final investment in _editableInvestments) {
      debugPrint(
        '🔧 [InvestorEditDialog] Setting up controller for investment: ${investment.id}',
      );
      debugPrint('   - SOURCE DATA:');
      debugPrint('     * remainingCapital: ${investment.remainingCapital}');
      debugPrint('     * investmentAmount: ${investment.investmentAmount}');
      debugPrint(
        '     * capitalForRestructuring: ${investment.capitalForRestructuring}',
      );
      debugPrint(
        '     * capitalSecuredByRealEstate: ${investment.capitalSecuredByRealEstate}',
      );
      debugPrint('     * updatedAt: ${investment.updatedAt.toIso8601String()}');

      final remainingCapitalFormatted = _editService.formatValueForController(
        investment.remainingCapital,
      );
      final investmentAmountFormatted = _editService.formatValueForController(
        investment.investmentAmount,
      );
      final capitalForRestructuringFormatted = _editService
          .formatValueForController(investment.capitalForRestructuring);
      final capitalSecuredFormatted = _editService.formatValueForController(
        investment.capitalSecuredByRealEstate,
      );

      debugPrint('   - FORMATTED FOR CONTROLLERS:');
      debugPrint('     * remainingCapital: "$remainingCapitalFormatted"');
      debugPrint('     * investmentAmount: "$investmentAmountFormatted"');
      debugPrint(
        '     * capitalForRestructuring: "$capitalForRestructuringFormatted"',
      );
      debugPrint(
        '     * capitalSecuredByRealEstate: "$capitalSecuredFormatted"',
      );

      remainingCapitalControllers.add(
        TextEditingController(text: remainingCapitalFormatted),
      );
      investmentAmountControllers.add(
        TextEditingController(text: investmentAmountFormatted),
      );
      capitalForRestructuringControllers.add(
        TextEditingController(text: capitalForRestructuringFormatted),
      );
      capitalSecuredControllers.add(
        TextEditingController(text: capitalSecuredFormatted),
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

    // 🔒 PRESERVE FIREBASE VALUES: Nie uruchamiaj automatycznych obliczeń przy inicjalizacji
    // Wartości z Firebase są już poprawnie ustawione w kontrolerach
    // Automatyczne obliczenia będą uruchamiane tylko gdy użytkownik zmieni pole
    debugPrint(
      '🔒 [InvestorEditDialog] Preserving Firebase values - no automatic calculations on init',
    );
    for (int i = 0; i < _editableInvestments.length; i++) {
      final investment = _editableInvestments[i];
      debugPrint(
        '✅ [InvestorEditDialog] Investment ${i + 1} (${investment.id}): remainingCapital=${investment.remainingCapital}, secured=${investment.capitalSecuredByRealEstate}, restructuring=${investment.capitalForRestructuring}',
      );
    }

    // Zaktualizuj stan
    setState(() {
      _state = _state.copyWith(originalTotalProductAmount: totalAmount);
    });
  }

  void _setupListeners() {
    // Listenery dla kontrolerów inwestycji
    for (int i = 0; i < _editableInvestments.length; i++) {
      // ⚠️ WAŻNE: NIE dodajemy listenera do remainingCapitalControllers - to pole jest obliczane automatycznie

      // Listener dla kwoty inwestycji
      _controllers.investmentAmountControllers[i].addListener(() {
        _onDataChanged();
        _calculateAutomaticValues(i);
      });

      // Listener dla kapitału do restrukturyzacji - automatycznie przeliczy kapitał pozostały
      _controllers.capitalForRestructuringControllers[i].addListener(() {
        debugPrint(
          '🔄 [InvestorEditDialog] Capital for restructuring changed for investment ${i + 1}',
        );
        debugPrint(
          '   New value: "${_controllers.capitalForRestructuringControllers[i].text}"',
        );
        _onDataChanged();
        _calculateAutomaticValues(
          i,
        ); // ← To automatycznie obliczy kapitał pozostały
      });

      // Listener dla kapitału zabezpieczonego - automatycznie przeliczy kapitał pozostały
      _controllers.capitalSecuredByRealEstateControllers[i].addListener(() {
        debugPrint(
          '🔄 [InvestorEditDialog] Capital secured changed for investment ${i + 1}',
        );
        debugPrint(
          '   New value: "${_controllers.capitalSecuredByRealEstateControllers[i].text}"',
        );
        _onDataChanged();
        _calculateAutomaticValues(
          i,
        ); // ← To automatycznie obliczy kapitał pozostały
      });
    }

    // Listener dla całkowitej kwoty produktu
    _controllers.totalProductAmountController.addListener(
      _onTotalAmountChanged,
    );
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {
        _state = _state.withChanges();
      });
    }
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
        if (mounted) {
          setState(() {
            _state = _state.copyWith(pendingTotalAmountChange: null);
          });
        }
      }
      return;
    }

    debugPrint('🔢 [RefactoredDialog] Zmiana całkowitej kwoty produktu:');
    debugPrint(
      '   - Oryginalna kwota: ${_state.originalTotalProductAmount.toStringAsFixed(2)}',
    );
    debugPrint('   - Nowa kwota: ${newTotalAmount.toStringAsFixed(2)}');

    if (mounted) {
      setState(() {
        _state = _state.copyWith(
          pendingTotalAmountChange: newTotalAmount,
          isChanged: true,
        );
      });
    }
  }

  void _calculateAutomaticValues(int index) {
    final investmentAmountText =
        _controllers.investmentAmountControllers[index].text;
    final capitalForRestructuringText =
        _controllers.capitalForRestructuringControllers[index].text;
    final capitalSecuredText =
        _controllers.capitalSecuredByRealEstateControllers[index].text;
    final currentRemainingCapitalText = 
        _controllers.remainingCapitalControllers[index].text;

    debugPrint(
      '🧮 [InvestorEditDialog] ROZPOCZĘCIE OBLICZEŃ dla investment ${index + 1}:',
    );
    debugPrint('   - investmentAmount text: "$investmentAmountText"');
    debugPrint('   - capitalForRestructuring text: "$capitalForRestructuringText"');
    debugPrint('   - capitalSecured text: "$capitalSecuredText"');
    debugPrint('   - OBECNY remainingCapital text: "$currentRemainingCapitalText"');
    
    // 🔍 DODATKOWE SPRAWDZENIE: Czy kontrolery mają wszystkie wartości?
    debugPrint('🔍 [InvestorEditDialog] Sprawdzenie wszystkich kontrolerów:');
    debugPrint('   - Kontroler capitalForRestructuring jest pusty? ${capitalForRestructuringText.trim().isEmpty}');
    debugPrint('   - Kontroler capitalSecured jest pusty? ${capitalSecuredText.trim().isEmpty}');

    // 🎯 IMPROVED: Użyj fallback parsing żeby zachować oryginalne wartości gdy pole jest puste
    final originalInvestment = _editableInvestments[index];
    final investmentAmount = _editService.parseValueFromControllerWithFallback(
      investmentAmountText,
      originalInvestment.investmentAmount,
    );
    final capitalForRestructuring = _editService.parseValueFromControllerWithFallback(
      capitalForRestructuringText,
      originalInvestment.capitalForRestructuring,
    );
    final capitalSecured = _editService.parseValueFromControllerWithFallback(
      capitalSecuredText,
      originalInvestment.capitalSecuredByRealEstate,
    );

    debugPrint(
      '🧮 [InvestorEditDialog] SPARSOWANE WARTOŚCI dla investment ${index + 1}:',
    );
    debugPrint('   - investmentAmount: $investmentAmount (oryginalny: ${originalInvestment.investmentAmount})');
    debugPrint('   - capitalForRestructuring: $capitalForRestructuring (oryginalny: ${originalInvestment.capitalForRestructuring}, tekst: "$capitalForRestructuringText")');
    debugPrint('   - capitalSecured: $capitalSecured (oryginalny: ${originalInvestment.capitalSecuredByRealEstate}, tekst: "$capitalSecuredText")');

    // 🧮 AUTOMATIC CALCULATION: Kapitał pozostały = Kapitał zabezpieczony + Kapitał do restrukturyzacji
    final calculatedRemainingCapital = capitalSecured + capitalForRestructuring;

    debugPrint(
      '🧮 [InvestorEditDialog] Auto-calculating remaining capital for investment ${index + 1}:',
    );
    debugPrint(
      '   - Kapitał zabezpieczony: ${capitalSecured.toStringAsFixed(2)}',
    );
    debugPrint(
      '   - Kapitał do restrukturyzacji: ${capitalForRestructuring.toStringAsFixed(2)}',
    );
    debugPrint(
      '   - Obliczony kapitał pozostały: ${calculatedRemainingCapital.toStringAsFixed(2)}',
    );

    // Aktualizuj pole pozostałego kapitału ZAWSZE (jest to pole kalkulowane automatycznie)
    final newRemainingCapitalText = _editService.formatValueForController(
      calculatedRemainingCapital,
    );

    // Sprawdź czy wartość rzeczywiście się zmieniła, żeby uniknąć nieskończonych pętli
    if (_controllers.remainingCapitalControllers[index].text !=
        newRemainingCapitalText) {
      debugPrint(
        '📝 [InvestorEditDialog] Updating remaining capital: ${_controllers.remainingCapitalControllers[index].text} → $newRemainingCapitalText',
      );
      _controllers.remainingCapitalControllers[index].text =
          newRemainingCapitalText;
    }

    // 📊 WALIDACJA: Sprawdź zgodność z kwotą inwestycji (tylko ostrzeżenie, nie blokuje)
    final difference = (calculatedRemainingCapital - investmentAmount).abs();
    if (difference > 0.01) {
      debugPrint(
        '⚠️ [InvestorEditDialog] Uwaga: Suma kapitałów (${calculatedRemainingCapital.toStringAsFixed(2)}) różni się od kwoty inwestycji (${investmentAmount.toStringAsFixed(2)}) o ${difference.toStringAsFixed(2)}',
      );
    } else {
      debugPrint(
        '✅ [InvestorEditDialog] Kapitały są zgodne z kwotą inwestycji',
      );
    }
  }

  void _onStatusChanged(int index, InvestmentStatus newStatus) {
    if (mounted) {
      setState(() {
        _controllers.statusValues[index] = newStatus;
        _state = _state.withChanges();
      });
    }
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
      child: Column(
        children: [
          // 🚀 NOWE: TabBar dla przełączania między edycją a historią
          _buildTabBar(),

          // 🚀 NOWE: TabBarView z zawartością
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEditTab(), // Zakładka edycji
                _buildHistoryTab(), // Zakładka historii
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🚀 NOWE: Buduje TabBar
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        border: Border(
          bottom: BorderSide(
            color: AppThemePro.accentGold.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppThemePro.accentGold,
        unselectedLabelColor: AppThemePro.textSecondary,
        indicatorColor: AppThemePro.accentGold,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        onTap: (index) {
          if (mounted) {
            setState(() {
              _currentTabIndex = index;
            });
          }
        },
        tabs: [
          Tab(icon: Icon(Icons.edit, size: 20), text: 'Edycja Inwestycji'),
          Tab(icon: Icon(Icons.history, size: 20), text: 'Historia Zmian'),
        ],
      ),
    );
  }

  /// 🚀 NOWE: Zakładka edycji (poprzednia zawartość)
  Widget _buildEditTab() {
    return Form(
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
      

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  /// 🚀 NOWE: Zakładka historii zmian
  Widget _buildHistoryTab() {
    if (_editableInvestments.isEmpty) {
      return Center(
        child: Text(
          'Brak inwestycji do wyświetlenia historii',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppThemePro.textSecondary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const SizedBox(height: 12),

          // Lista historii dla każdej inwestycji
          Expanded(
            child: ListView.separated(
              itemCount: _editableInvestments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final investment = _editableInvestments[index];
                return _buildInvestmentHistorySection(investment, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🚀 NOWE: Sekcja historii dla pojedynczej inwestycji
  Widget _buildInvestmentHistorySection(Investment investment, int index) {
    return Container(
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemePro.borderPrimary.withOpacity(0.3),
          width: 1,
        ),
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
          // Header inwestycji
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppThemePro.backgroundSecondary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
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
                    color: AppThemePro.sharesGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: AppThemePro.sharesGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        investment.productName.isNotEmpty
                            ? investment.productName
                            : 'Inwestycja ${index + 1}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppThemePro.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kapitał pozostały: ${_formatCurrency(investment.remainingCapital)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppThemePro.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Widget historii dla tej inwestycji
          SizedBox(
            height: 300, // Ograniczona wysokość dla lepszego UX
            child: InvestmentHistoryWidget(
              investmentId: investment.id,
              isCompact: true,
              maxEntries: 10, // Pokaż maksymalnie 10 ostatnich zmian
            ),
          ),
        ],
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

        if (mounted) {
          setState(() {
            _state = _state.withLoading(false);
          });
        }
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

        // 🎯 UNIFIED: Odśwież dane externally z forceRefresh
        widget.onSaved();

        // 🎯 UNIFIED: Reload investment data to show fresh values in the dialog
        await _reloadInvestmentData();

        // 🔔 DODATKOWO: Pokaż informację o tym ile inwestycji zostało zaktualizowanych
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '📊 Zaktualizowano ${_editableInvestments.length} inwestycji z najnowszymi danymi',
              ),
              backgroundColor: AppThemePro.sharesGreen,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        if (mounted) {
          setState(() {
            _state = _state.resetChanges().withLoading(false);
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _state = _state
                .withLoading(false)
                .copyWith(error: 'Błąd podczas zapisywania zmian');
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [RefactoredDialog] Błąd podczas zapisywania: $e');
      if (mounted) {
        setState(() {
          _state = _state
              .withLoading(false)
              .copyWith(
                error: 'Błąd podczas zapisywania zmian: ${e.toString()}',
              );
        });
      }
    }
  }

  /// 💰 NOWA METODA: Formatuje kwoty walutowe
  String _formatCurrency(double amount) {
    return CurrencyFormatter.formatCurrency(amount);
  }
}
