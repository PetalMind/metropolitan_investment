import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models_and_services.dart';
import '../../optimized_voting_status_widget.dart';

/// Dialog szczegółów inwestora z możliwością edycji
class InvestorDetailsDialog extends StatefulWidget {
  final InvestorSummary investor;
  final InvestorAnalyticsService analyticsService;
  // Legacy nullable callback (kept for backward compatibility)
  final VoidCallback? onUpdate;
  // New callback used by callers expecting the updated investor object
  final void Function(InvestorSummary updatedInvestor)? onInvestorUpdated;

  InvestorDetailsDialog({
    super.key,
    required this.investor,
    InvestorAnalyticsService? analyticsService,
    this.onUpdate,
    this.onInvestorUpdated,
  }) : analyticsService = analyticsService ?? InvestorAnalyticsService();

  @override
  State<InvestorDetailsDialog> createState() => _InvestorDetailsDialogState();
}

class _InvestorDetailsDialogState extends State<InvestorDetailsDialog> {
  late TextEditingController _notesController;
  late VotingStatus _selectedVotingStatus;
  String _selectedColor = '#FFFFFF';
  List<String> _selectedUnviableInvestments = [];
  bool _isLoading = false;

  // 🆕 Stan deduplikacji i edycji
  bool _showDeduplicatedProducts = true; // Domyślnie deduplikacja
  bool _isEditMode = false; // Stan edycji inwestycji

  // Services
  final UnifiedVotingStatusService _votingService =
      UnifiedVotingStatusService();

  // Focus nodes & microinteraction state for keyboard/Tab navigation
  late FocusNode _dedupeSwitchFocusNode;
  late FocusNode _editButtonFocusNode;
  late FocusNode _closeButtonFocusNode;
  late FocusNode _votingSelectorFocusNode;
  late FocusNode _notesFocusNode;
  late FocusNode _saveButtonFocusNode;
  late FocusNode _cancelButtonFocusNode;

  // Track focused investment indices for animated focus styling
  final Set<int> _focusedInvestmentIndices = <int>{};
  final Set<int> _hoveredInvestmentIndices = <int>{};

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.investor.client.notes,
    );
    _selectedVotingStatus = widget.investor.client.votingStatus;
    _selectedColor = widget.investor.client.colorCode;
    _selectedUnviableInvestments = List.from(
      widget.investor.client.unviableInvestments,
    );

    // init focus nodes
    _dedupeSwitchFocusNode = FocusNode(debugLabel: 'dedupeSwitch');
    _editButtonFocusNode = FocusNode(debugLabel: 'editButton');
    _closeButtonFocusNode = FocusNode(debugLabel: 'closeButton');
    _votingSelectorFocusNode = FocusNode(debugLabel: 'votingSelector');
    _notesFocusNode = FocusNode(debugLabel: 'notesField');
    _saveButtonFocusNode = FocusNode(debugLabel: 'saveButton');
    _cancelButtonFocusNode = FocusNode(debugLabel: 'cancelButton');
  }

  @override
  void dispose() {
    _notesController.dispose();
    _dedupeSwitchFocusNode.dispose();
    _editButtonFocusNode.dispose();
    _closeButtonFocusNode.dispose();
    _votingSelectorFocusNode.dispose();
    _notesFocusNode.dispose();
    _saveButtonFocusNode.dispose();
    _cancelButtonFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      // Sprawdź czy status głosowania się zmienił
      final oldVotingStatus = widget.investor.client.votingStatus;
      final votingStatusChanged = oldVotingStatus != _selectedVotingStatus;

      await widget.analyticsService.updateInvestorNotes(
        widget.investor.client.id,
        _notesController.text,
      );

      await widget.analyticsService.updateVotingStatus(
        widget.investor.client.id,
        _selectedVotingStatus,
      );

      await widget.analyticsService.updateInvestorColor(
        widget.investor.client.id,
        _selectedColor,
      );

      await widget.analyticsService.markInvestmentsAsUnviable(
        widget.investor.client.id,
        _selectedUnviableInvestments,
      );

      // Jeśli status głosowania się zmienił, zapisz historię przez UnifiedVotingService
      if (votingStatusChanged) {
        print(
          '🗳️ [InvestorDetailsDialog] Status głosowania zmieniony: ${oldVotingStatus.name} -> ${_selectedVotingStatus.name}',
        );

        await _votingService.updateVotingStatus(
          widget.investor.client.id,
          _selectedVotingStatus,
          reason: 'Updated via investor analytics dialog',
          editedBy: 'Analytics Dialog',
          editedByEmail: 'system@analytics-dialog.local',
          updatedVia: 'investor_details_dialog',
        );

        print('✅ [InvestorDetailsDialog] Historia głosowania zapisana');
      }

      if (mounted) {
        Navigator.of(context).pop();

        // Przygotuj zaktualizowany obiekt InvestorSummary (nie modyfikujemy oryginalnego)
        final updatedClient = widget.investor.client.copyWith(
          notes: _notesController.text,
          votingStatus: _selectedVotingStatus,
          colorCode: _selectedColor,
          unviableInvestments: List<String>.from(_selectedUnviableInvestments),
          updatedAt: DateTime.now(),
        );

        final updatedInvestor = InvestorSummary(
          client: updatedClient,
          investments: widget.investor.investments,
          totalRemainingCapital: widget.investor.totalRemainingCapital,
          totalSharesValue: widget.investor.totalSharesValue,
          totalValue: widget.investor.totalValue,
          totalInvestmentAmount: widget.investor.totalInvestmentAmount,
          totalRealizedCapital: widget.investor.totalRealizedCapital,
          capitalSecuredByRealEstate: widget.investor.capitalSecuredByRealEstate,
          capitalForRestructuring: widget.investor.capitalForRestructuring,
          investmentCount: widget.investor.investmentCount,
        );

        // Preferowane wywołanie nowego callbacku z aktualnym obiektem
        if (widget.onInvestorUpdated != null) {
          widget.onInvestorUpdated!(updatedInvestor);
        } else if (widget.onUpdate != null) {
          widget.onUpdate!();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Zmiany zostały zapisane'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas zapisywania: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        // Group traversal so Tab order follows logical ordering we provide
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Column(
            children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.secondaryGold.withOpacity(0.1),
                    AppTheme.primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: AppTheme.secondaryGold,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.investor.client.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.investor.client.companyName?.isNotEmpty ??
                            false) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.investor.client.companyName!,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 🆕 Switch deduplikacji
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Deduplikacja',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Make the switch focusable and part of Tab order
                      FocusTraversalOrder(
                        order: NumericFocusOrder(1.0),
                        child: Focus(
                          focusNode: _dedupeSwitchFocusNode,
                          child: FocusableActionDetector(
                            autofocus: false,
                            onShowFocusHighlight: (_) => setState(() {}),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: AnimatedScale(
                                scale: _dedupeSwitchFocusNode.hasFocus ? 1.04 : 1,
                                duration: const Duration(milliseconds: 160),
                                child: Switch(
                                  value: _showDeduplicatedProducts,
                                  onChanged: (value) {
                                    setState(() {
                                      _showDeduplicatedProducts = value;
                                    });
                                  },
                                  activeColor: AppTheme.secondaryGold,
                                  inactiveThumbColor: AppTheme.textTertiary,
                                  inactiveTrackColor: AppTheme.backgroundSecondary,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // 🆕 Przycisk edycji inwestycji (focus + microanimation)
                  FocusTraversalOrder(
                    order: NumericFocusOrder(2.0),
                    child: Focus(
                      focusNode: _editButtonFocusNode,
                      child: FocusableActionDetector(
                        onShowFocusHighlight: (_) => setState(() {}),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: AnimatedScale(
                            scale: _editButtonFocusNode.hasFocus ? 1.06 : 1,
                            duration: const Duration(milliseconds: 140),
                            child: IconButton(
                              onPressed: () => setState(() {
                                _isEditMode = !_isEditMode;
                              }),
                              icon: Icon(
                                _isEditMode ? Icons.edit_off : Icons.edit,
                                color: _isEditMode
                                    ? AppTheme.warningColor
                                    : AppTheme.textSecondary,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: _isEditMode
                                    ? AppTheme.warningColor.withOpacity(0.1)
                                    : AppTheme.backgroundSecondary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              tooltip: _isEditMode
                                  ? 'Wyłącz edycję'
                                  : 'Włącz edycję inwestycji',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Close button with focus and animation
                  FocusTraversalOrder(
                    order: NumericFocusOrder(3.0),
                    child: Focus(
                      focusNode: _closeButtonFocusNode,
                      child: FocusableActionDetector(
                        onShowFocusHighlight: (_) => setState(() {}),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: AnimatedScale(
                            scale: _closeButtonFocusNode.hasFocus ? 1.06 : 1,
                            duration: const Duration(milliseconds: 140),
                            child: IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close,
                                color: AppTheme.textSecondary,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.backgroundSecondary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Podsumowanie inwestycji
                    _buildSummaryCard(),
                    const SizedBox(height: 24),

                    // Edycja danych
                    _buildEditSection(),
                    const SizedBox(height: 24),

                    // Lista inwestycji
                    _buildInvestmentsSection(),
                  ],
                ),
              ),
            ),

            // Footer z przyciskami
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppTheme.borderSecondary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: FocusTraversalOrder(
                      order: NumericFocusOrder(1000.0),
                      child: Focus(
                        focusNode: _cancelButtonFocusNode,
                        child: FocusableActionDetector(
                          onShowFocusHighlight: (_) => setState(() {}),
                          child: AnimatedScale(
                            scale: _cancelButtonFocusNode.hasFocus ? 1.04 : 1,
                            duration: const Duration(milliseconds: 130),
                            child: const Text('Anuluj'),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FocusTraversalOrder(
                    order: NumericFocusOrder(1001.0),
                    child: Focus(
                      focusNode: _saveButtonFocusNode,
                      child: FocusableActionDetector(
                        onShowFocusHighlight: (_) => setState(() {}),
                        child: AnimatedScale(
                          scale: _saveButtonFocusNode.hasFocus ? 1.04 : 1,
                          duration: const Duration(milliseconds: 130),
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveChanges,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(_isLoading ? 'Zapisywanie...' : 'Zapisz'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryGold,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.backgroundSecondary, AppTheme.surfaceElevated],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderSecondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Podsumowanie inwestycji',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FocusTraversalOrder(
                  order: NumericFocusOrder(6.0),
                  child: FocusableActionDetector(
                    onShowFocusHighlight: (_) => setState(() {}),
                    child: Focus(
                      child: AnimatedScale(
                        scale: 1.0,
                        duration: const Duration(milliseconds: 120),
                        child: _buildStatItem(
                          'Łączna wartość',
                          CurrencyFormatter.formatCurrency(
                            widget.investor.totalValue,
                            showDecimals: false,
                          ),
                          Icons.account_balance_wallet,
                          AppTheme.successColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FocusTraversalOrder(
                  order: NumericFocusOrder(7.0),
                  child: FocusableActionDetector(
                    onShowFocusHighlight: (_) => setState(() {}),
                    child: Focus(
                      child: AnimatedScale(
                        scale: 1.0,
                        duration: const Duration(milliseconds: 120),
                        child: _buildStatItem(
                          'Liczba inwestycji',
                          '${widget.investor.investmentCount}',
                          Icons.pie_chart,
                          AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FocusTraversalOrder(
                  order: NumericFocusOrder(8.0),
                  child: FocusableActionDetector(
                    onShowFocusHighlight: (_) => setState(() {}),
                    child: Focus(
                      child: AnimatedScale(
                        scale: 1.0,
                        duration: const Duration(milliseconds: 120),
                        child: _buildStatItem(
                          'Kapitał pozostały',
                          CurrencyFormatter.formatCurrency(
                            widget.investor.totalRemainingCapital,
                            showDecimals: false,
                          ),
                          Icons.monetization_on,
                          AppTheme.warningColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FocusTraversalOrder(
                  order: NumericFocusOrder(9.0),
                  child: FocusableActionDetector(
                    onShowFocusHighlight: (_) => setState(() {}),
                    child: Focus(
                      child: AnimatedScale(
                        scale: 1.0,
                        duration: const Duration(milliseconds: 120),
                        child: _buildStatItem(
                          'Wartość udziałów',
                          CurrencyFormatter.formatCurrency(
                            widget.investor.totalSharesValue,
                            showDecimals: false,
                          ),
                          Icons.trending_up,
                          AppTheme.infoColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edycja danych',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Status głosowania (focusable wrapper so it has a Tab stop)
        FocusTraversalOrder(
          order: NumericFocusOrder(4.0),
          child: Focus(
            focusNode: _votingSelectorFocusNode,
            child: FocusableActionDetector(
              onShowFocusHighlight: (_) => setState(() {}),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: OptimizedVotingStatusSelector(
                  currentStatus: _selectedVotingStatus,
                  onStatusChanged: (VotingStatus newStatus) {
                    setState(() => _selectedVotingStatus = newStatus);
                  },
                  isCompact: false,
                  showLabels: true,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Notatki
        FocusTraversalOrder(
          order: NumericFocusOrder(5.0),
          child: TextField(
            focusNode: _notesFocusNode,
            controller: _notesController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
            labelText: 'Notatki',
            labelStyle: const TextStyle(color: AppTheme.textSecondary),
            hintText: 'Dodaj notatki o kliencie...',
            hintStyle: const TextStyle(color: AppTheme.textTertiary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderSecondary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderSecondary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.secondaryGold, width: 2),
            ),
          ),
          maxLines: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildInvestmentsSection() {
    // 🔄 Przygotuj deduplikowane produkty
    final deduplicatedProducts = <String, DeduplicatedProduct>{};

    if (_showDeduplicatedProducts) {
      for (final investment in widget.investor.investments) {
        final productKey = investment.productName.trim().toLowerCase();

        if (deduplicatedProducts.containsKey(productKey)) {
          // Dodaj inwestycję do istniejącego produktu
          final existing = deduplicatedProducts[productKey]!;
          deduplicatedProducts[productKey] = DeduplicatedProduct(
            id: existing.id,
            name: existing.name,
            productType: existing.productType,
            companyId: existing.companyId,
            companyName: existing.companyName,
            totalValue: existing.totalValue + investment.investmentAmount,
            totalRemainingCapital:
                existing.totalRemainingCapital + investment.remainingCapital,
            totalInvestments: existing.totalInvestments + 1,
            uniqueInvestors: existing.uniqueInvestors,
            actualInvestorCount: existing.actualInvestorCount,
            averageInvestment: 0, // Będzie przeliczone
            earliestInvestmentDate: existing.earliestInvestmentDate,
            latestInvestmentDate: existing.latestInvestmentDate,
            status: existing.status,
            interestRate: existing.interestRate,
            maturityDate: existing.maturityDate,
            originalInvestmentIds: [
              ...existing.originalInvestmentIds,
              investment.id,
            ],
            metadata: existing.metadata,
          );
        } else {
          // Utwórz nowy produkt deduplikowany
          deduplicatedProducts[productKey] = DeduplicatedProduct(
            id: investment.id,
            name: investment.productName,
            productType: _mapInvestmentTypeToUnified(
              investment.productType.name,
            ),
            companyId: investment.companyId,
            companyName: investment.creditorCompany,
            totalValue: investment.investmentAmount,
            totalRemainingCapital: investment.remainingCapital,
            totalInvestments: 1,
            uniqueInvestors: 1,
            actualInvestorCount: 1,
            averageInvestment: investment.investmentAmount,
            earliestInvestmentDate: investment.createdAt,
            latestInvestmentDate: investment.updatedAt,
            status: _mapInvestmentStatusToProduct(investment.status),
            interestRate: null, // Investment nie ma interestRate
            maturityDate: null, // Investment nie ma maturityDate
            originalInvestmentIds: [investment.id],
            metadata: {},
          );
        }
      }

      // Przelicz średnią inwestycję
      for (final key in deduplicatedProducts.keys) {
        final product = deduplicatedProducts[key]!;
        deduplicatedProducts[key] = DeduplicatedProduct(
          id: product.id,
          name: product.name,
          productType: product.productType,
          companyId: product.companyId,
          companyName: product.companyName,
          totalValue: product.totalValue,
          totalRemainingCapital: product.totalRemainingCapital,
          totalInvestments: product.totalInvestments,
          uniqueInvestors: product.uniqueInvestors,
          actualInvestorCount: product.actualInvestorCount,
          averageInvestment: product.totalInvestments > 0
              ? product.totalValue / product.totalInvestments
              : 0,
          earliestInvestmentDate: product.earliestInvestmentDate,
          latestInvestmentDate: product.latestInvestmentDate,
          status: product.status,
          interestRate: product.interestRate,
          maturityDate: product.maturityDate,
          originalInvestmentIds: product.originalInvestmentIds,
          metadata: product.metadata,
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.business_center,
              color: AppTheme.secondaryGold,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _showDeduplicatedProducts
                  ? 'Produkty (${deduplicatedProducts.length} deduplikowanych)'
                  : 'Inwestycje (${widget.investor.investments.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            if (_showDeduplicatedProducts)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.secondaryGold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Deduplikacja',
                  style: TextStyle(
                    color: AppTheme.secondaryGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.borderSecondary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: _showDeduplicatedProducts
              ? _buildDeduplicatedProductsList(
                  deduplicatedProducts.values.toList(),
                )
              : _buildRegularInvestmentsList(),
        ),
      ],
    );
  }

  // 🔄 Pomocnicze metody mapowania
  UnifiedProductType _mapInvestmentTypeToUnified(String investmentType) {
    switch (investmentType.toLowerCase()) {
      case 'bonds':
      case 'obligacje':
        return UnifiedProductType.bonds;
      case 'shares':
      case 'udziały':
      case 'akcje':
        return UnifiedProductType.shares;
      case 'loans':
      case 'pożyczki':
        return UnifiedProductType.loans;
      case 'apartments':
      case 'apartamenty':
        return UnifiedProductType.apartments;
      default:
        return UnifiedProductType.bonds;
    }
  }

  ProductStatus _mapInvestmentStatusToProduct(
    InvestmentStatus investmentStatus,
  ) {
    switch (investmentStatus) {
      case InvestmentStatus.active:
        return ProductStatus.active;
      case InvestmentStatus.inactive:
        return ProductStatus.inactive;
      case InvestmentStatus.earlyRedemption:
      case InvestmentStatus.completed:
        return ProductStatus.pending;
    }
  }

  Widget _buildDeduplicatedProductsList(List<DeduplicatedProduct> products) {
    if (products.isEmpty) {
      return const Center(
        child: Text(
          'Brak produktów deduplikowanych',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return FocusTraversalOrder(
          order: NumericFocusOrder(10 + index.toDouble()),
          child: Focus(
            onFocusChange: (focused) {
              setState(() {
                if (focused) {
                  _focusedInvestmentIndices.add(index);
                } else {
                  _focusedInvestmentIndices.remove(index);
                }
              });
            },
            child: FocusableActionDetector(
              mouseCursor: SystemMouseCursors.click,
              onShowFocusHighlight: (_) => setState(() {}),
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoveredInvestmentIndices.add(index)),
                onExit: (_) => setState(() => _hoveredInvestmentIndices.remove(index)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  transform: Matrix4.identity()
                    ..scale(_focusedInvestmentIndices.contains(index) ? 1.02 : (_hoveredInvestmentIndices.contains(index) ? 1.01 : 1)),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Card(
                    color: AppTheme.surfaceCard,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: product.productType.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getProductTypeIcon(product.productType),
                          color: product.productType.color,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        product.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${CurrencyFormatter.formatCurrency(product.totalRemainingCapital, showDecimals: false)} - ${product.companyName}',
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                          if (product.totalInvestments > 1)
                            Text(
                              '${product.totalInvestments} inwestycji',
                              style: TextStyle(
                                color: AppTheme.secondaryGold,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: AppTheme.textTertiary,
                        size: 16,
                      ),
                      onTap: () => _navigateToProductDetails(product),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegularInvestmentsList() {
    if (widget.investor.investments.isEmpty) {
      return const Center(
        child: Text(
          'Brak inwestycji',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: widget.investor.investments.length,
      itemBuilder: (context, index) {
        final investment = widget.investor.investments[index];
        final isUnviable = _selectedUnviableInvestments.contains(investment.id);

        return FocusTraversalOrder(
          order: NumericFocusOrder(200 + index.toDouble()),
          child: Focus(
            onFocusChange: (focused) {
              setState(() {
                if (focused) {
                  _focusedInvestmentIndices.add(index);
                } else {
                  _focusedInvestmentIndices.remove(index);
                }
              });
            },
            child: FocusableActionDetector(
              mouseCursor: SystemMouseCursors.click,
              onShowFocusHighlight: (_) => setState(() {}),
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoveredInvestmentIndices.add(index)),
                onExit: (_) => setState(() => _hoveredInvestmentIndices.remove(index)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  transform: Matrix4.identity()
                    ..scale(_focusedInvestmentIndices.contains(index) ? 1.02 : (_hoveredInvestmentIndices.contains(index) ? 1.01 : 1)),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Card(
                    color: AppTheme.surfaceCard,
                    child: InkWell(
                      onTap: () => _navigateToProductDetails(investment),
                      child: CheckboxListTile(
                        title: Text(
                          investment.productName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${CurrencyFormatter.formatCurrency(investment.remainingCapital, showDecimals: false)} - ${investment.creditorCompany}',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        value: isUnviable,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedUnviableInvestments.add(investment.id);
                            } else {
                              _selectedUnviableInvestments.remove(investment.id);
                            }
                          });
                        },
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                (isUnviable
                                        ? AppTheme.warningColor
                                        : AppTheme.successColor)
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isUnviable ? Icons.warning : Icons.check_circle,
                            color: isUnviable
                                ? AppTheme.warningColor
                                : AppTheme.successColor,
                            size: 20,
                          ),
                        ),
                        activeColor: AppTheme.warningColor,
                        checkColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getProductTypeIcon(UnifiedProductType type) {
    switch (type) {
      case UnifiedProductType.bonds:
        return Icons.account_balance;
      case UnifiedProductType.shares:
        return Icons.trending_up;
      case UnifiedProductType.loans:
        return Icons.handshake;
      case UnifiedProductType.apartments:
        return Icons.home;
      case UnifiedProductType.other:
        return Icons.category;
    }
  }

  // 🎯 Nawigacja do produktów
  void _navigateToProductDetails(dynamic productOrInvestment) {
    // Implementacja nawigacji - podobna do premium_investor_analytics_screen.dart
    print(
      '🎯 [InvestorDetailsDialog] Nawigacja do produktu: $productOrInvestment',
    );

    String? investmentId;

    if (productOrInvestment is DeduplicatedProduct) {
      investmentId = productOrInvestment.originalInvestmentIds.first;
    } else if (productOrInvestment is Investment) {
      investmentId = productOrInvestment.id;
    } else {
      print('❌ [InvestorDetailsDialog] Nieznany typ produktu');
      return;
    }

    print(
      '🎯 [InvestorDetailsDialog] Przechodzę do /products z investmentId: $investmentId',
    );

    // Używamy go_router do nawigacji - najpierw zamknij dialog
    Navigator.of(context).pop();

    // Następnie nawiguj
    context.go('/products?investmentId=$investmentId');
  }
}
