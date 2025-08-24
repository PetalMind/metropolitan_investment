import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models_and_services.dart';
import '../../../theme/app_theme_professional.dart';
import '../../optimized_voting_status_widget.dart';
import '../../client_notes_widget.dart';
import '../tabs/voting_changes_tab.dart';
import '../../dialogs/investor_edit_dialog_enhancements.dart';

/// 🚀 ENHANCED INVESTOR DETAILS DIALOG
/// Najnowocześniejszy dialog szczegółów inwestora z zaawansowanymi funkcjami:
/// - Nowoczesny design inspirowany profesjonalnymi platformami finansowymi
/// - Tab-based navigation z 5 sekcjami
/// - Historia zmian inwestycji (integration z InvestmentChangeHistoryService)
/// - Historia głosowania (integration z VotingStatusChangeService)
/// - Responsywny layout (mobile, tablet, desktop)
/// - Smooth animations i microinteractions
/// - Real-time data updates
/// - Advanced filtering i search
/// - Export funkcjonalność
/// - RBAC (Role-Based Access Control)
class EnhancedInvestorDetailsDialog extends StatefulWidget {
  final InvestorSummary investor;
  final InvestorAnalyticsService? analyticsService;
  final VoidCallback? onUpdate;
  final void Function(InvestorSummary updatedInvestor)? onInvestorUpdated;

  const EnhancedInvestorDetailsDialog({
    super.key,
    required this.investor,
    this.analyticsService,
    this.onUpdate,
    this.onInvestorUpdated,
  });

  @override
  State<EnhancedInvestorDetailsDialog> createState() =>
      _EnhancedInvestorDetailsDialogState();
}

class _EnhancedInvestorDetailsDialogState
    extends State<EnhancedInvestorDetailsDialog>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // === CORE CONTROLLERS ===
  late TabController _tabController;
  late AnimationController _slideAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // === FORM CONTROLLERS ===
  late TextEditingController _notesController;
  late TextEditingController _searchController;

  // === SERVICES ===
  late InvestorAnalyticsService _analyticsService;
  final UnifiedVotingStatusService _votingService =
      UnifiedVotingStatusService();
  final InvestmentChangeHistoryService _historyService =
      InvestmentChangeHistoryService();
  // 🚀 NOWE: Serwisy edycji z InvestorEditDialog
  late final InvestorEditService _editService;

  // === STATE VARIABLES ===
  // Investor data
  late VotingStatus _selectedVotingStatus;
  String _selectedColor = '#FFFFFF';
  List<String> _selectedUnviableInvestments = [];

  // UI State
  int _selectedTabIndex = 0;
  bool _isLoading = false;
  final bool _isEditing = false;
  bool _hasChanges = false;
  bool _isInvestmentEditMode = false; // Nowy: tryb edycji inwestycji
  String? _editingInvestmentId; // Nowy: ID edytowanej inwestycji

  // Investment editing controllers (dla każdej inwestycji)
  final Map<String, Map<String, TextEditingController>> _investmentControllers = {};
  final Map<String, bool> _investmentHasChanges = {}; // Czy inwestycja ma zmiany
  
  // 🚀 NOWE: Kontrolery edycji z InvestorEditDialog
  late InvestmentEditControllers _unifiedControllers;
  late InvestorEditState _editState;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Investment filtering and search
  String _investmentSearchQuery = '';
  ProductType? _selectedProductTypeFilter;
  bool _showOnlyUnviable = false;

  // History data
  List<InvestmentChangeHistory> _investmentHistory = [];
  List<VotingStatusChange> _votingHistory = [];
  bool _historyLoading = false;

  // Layout & responsiveness
  bool get _isLargeScreen => MediaQuery.of(context).size.width > 1200;
  bool get _isMediumScreen => MediaQuery.of(context).size.width > 768;
  bool get _isSmallScreen => MediaQuery.of(context).size.width <= 768;

  // === TAB DEFINITIONS ===
  static const List<_TabDefinition> _tabs = [
    _TabDefinition(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Przegląd',
      tooltip: 'Główne informacje o inwestorze',
    ),
    _TabDefinition(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      label: 'Inwestycje',
      tooltip: 'Lista inwestycji z możliwością edycji',
    ),
    _TabDefinition(
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
      label: 'Historia zmian',
      tooltip: 'Historia zmian inwestycji',
    ),
    _TabDefinition(
      icon: Icons.how_to_vote_outlined,
      activeIcon: Icons.how_to_vote,
      label: 'Głosowania',
      tooltip: 'Historia statusów głosowania',
    ),
    _TabDefinition(
      icon: Icons.note_outlined,
      activeIcon: Icons.note,
      label: 'Notatki',
      tooltip: 'Notatki klienta',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeState();
    _initializeAnimations();
    _loadInitialData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeControllers();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Handle screen size changes
    if (mounted) {
      setState(() {});
    }
  }

  void _initializeState() {
    _analyticsService = widget.analyticsService ?? InvestorAnalyticsService();
    // 🚀 NOWE: Inicjalizacja serwisu edycji
    _editService = InvestorEditService();
    _editState = const InvestorEditState();
    
    _selectedVotingStatus = widget.investor.client.votingStatus;
    _selectedColor = widget.investor.client.colorCode;
    _selectedUnviableInvestments =
        List.from(widget.investor.client.unviableInvestments);

    // Initialize controllers
    _notesController = TextEditingController(
      text: widget.investor.client.notes,
    );
    _searchController = TextEditingController();

    // Initialize investment editing controllers
    _initializeInvestmentControllers();
    // 🚀 NOWE: Inicjalizacja unifiedControllers dla advanced editing
    _setupUnifiedControllers();

    // Tab controller
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: 0,
    );

    _tabController.addListener(_onTabChanged);
  }

  void _initializeInvestmentControllers() {
    for (final investment in widget.investor.investments) {
      _investmentControllers[investment.id] = {
        // 🎯 UPROSZCZONE: Tylko 4 kluczowe pola do edycji (jak w products_management_screen)
        'investmentAmount': TextEditingController(
          text: investment.investmentAmount.toStringAsFixed(2),
        ),
        'remainingCapital': TextEditingController(
          text: investment.remainingCapital.toStringAsFixed(2),
        ),
        'capitalForRestructuring': TextEditingController(
          text: investment.capitalForRestructuring.toStringAsFixed(2),
        ),
        'capitalSecuredByRealEstate': TextEditingController(
          text: investment.capitalSecuredByRealEstate.toStringAsFixed(2),
        ),
      };
      _investmentHasChanges[investment.id] = false;
      
      // � NOWE: Dodaj listenery dla automatycznego przeliczania remainingCapital
      final controllers = _investmentControllers[investment.id]!;
      
      // Listener dla kapitału do restrukturyzacji - automatycznie przeliczy kapitał pozostały
      controllers['capitalForRestructuring']!.addListener(() {
        debugPrint('🔄 [EnhancedDialog] Capital for restructuring changed for ${investment.id}');
        _calculateAutomaticRemainingCapital(investment.id);
      });
      
      // Listener dla kapitału zabezpieczonego - automatycznie przeliczy kapitał pozostały
      controllers['capitalSecuredByRealEstate']!.addListener(() {
        debugPrint('🔄 [EnhancedDialog] Capital secured changed for ${investment.id}');
        _calculateAutomaticRemainingCapital(investment.id);
      });
      
      // �🔍 DEBUG: Log wartości kontrolerów
      debugPrint('🔧 [EnhancedDialog] Initialized controllers for ${investment.id}:');
      debugPrint('   - capitalSecuredByRealEstate: ${investment.capitalSecuredByRealEstate} → controller: ${investment.capitalSecuredByRealEstate.toStringAsFixed(2)}');
    }
  }

  /// 🚀 NOWE: Setupuje unified controllers dla zaawansowanej edycji
  void _setupUnifiedControllers() {
    debugPrint(
      '🔧 [EnhancedDialog] Setting up unified controllers for ${widget.investor.investments.length} investments',
    );

    // Utwórz kontrolery
    final remainingCapitalControllers = <TextEditingController>[];
    final investmentAmountControllers = <TextEditingController>[];
    final capitalForRestructuringControllers = <TextEditingController>[];
    final capitalSecuredControllers = <TextEditingController>[];
    final statusValues = <InvestmentStatus>[];

    for (final investment in widget.investor.investments) {
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

      // 🔍 DEBUG: Log formatowania
      debugPrint('🔧 [UnifiedControllers] Investment ${investment.id}:');
      debugPrint('   - Raw capitalSecuredByRealEstate: ${investment.capitalSecuredByRealEstate}');
      debugPrint('   - Formatted capitalSecuredByRealEstate: $capitalSecuredFormatted');

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

    // Oblicz całkowitą kwotę
    final totalAmount = widget.investor.investments.fold<double>(
      0.0,
      (sum, inv) => sum + inv.investmentAmount,
    );

    final totalController = TextEditingController(
      text: _editService.formatValueForController(totalAmount),
    );

    _unifiedControllers = InvestmentEditControllers(
      remainingCapitalControllers: remainingCapitalControllers,
      investmentAmountControllers: investmentAmountControllers,
      capitalForRestructuringControllers: capitalForRestructuringControllers,
      capitalSecuredByRealEstateControllers: capitalSecuredControllers,
      statusValues: statusValues,
      totalProductAmountController: totalController,
    );

    // Ustaw stan edycji
    setState(() {
      _editState = _editState.copyWith(originalTotalProductAmount: totalAmount);
    });

    debugPrint('✅ [EnhancedDialog] Unified controllers setup completed');
  }

  void _initializeAnimations() {
    // Slide animation for modal entrance
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Fade animation for content
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _slideAnimationController.forward();
    _fadeAnimationController.forward();
  }

  void _disposeControllers() {
    _tabController.dispose();
    _slideAnimationController.dispose();
    _fadeAnimationController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    
    // Dispose investment controllers
    for (final controllers in _investmentControllers.values) {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
    
    // 🚀 NOWE: Dispose unified controllers
    _unifiedControllers.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadInvestmentHistory(),
      _loadVotingHistory(),
    ]);
  }

  Future<void> _loadInvestmentHistory() async {
    try {
      setState(() => _historyLoading = true);

      debugPrint('[ENHANCED_DIALOG] Loading history for clientId: ${widget.investor.client.id}');
      final history = await _historyService.getClientHistory(
        widget.investor.client.id,
      );
      debugPrint('[ENHANCED_DIALOG] Received ${history.length} history records');

      if (mounted) {
        setState(() {
          _investmentHistory = history;
          _historyLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyLoading = false;
        });
        debugPrint('Błąd podczas ładowania historii inwestycji: $e');
      }
    }
  }

  Future<void> _loadVotingHistory() async {
    try {
      final history = await _votingService.getVotingStatusHistory(
        widget.investor.client.id,
      );

      if (mounted) {
        setState(() {
          _votingHistory = history;
        });
      }
    } catch (e) {
      debugPrint('Error loading voting history: $e');
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final newIndex = _tabController.index;
      
      // Blokuj przejście na inne taby gdy aktywny jest tryb edycji inwestycji
      if (_isInvestmentEditMode && newIndex != 1) { // Index 1 = "Inwestycje"
        // Animuj z powrotem do taba inwestycji
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tabController.animateTo(1);
        });
        
        // Pokaż toast info
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Text('Tryb edycji inwestycji - dostępny tylko tab "Inwestycje"'),
              ],
            ),
            backgroundColor: AppThemePro.statusWarning,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }
      
      setState(() {
        _selectedTabIndex = newIndex;
      });
      _triggerHapticFeedback();
    }
  }

  void _triggerHapticFeedback() {
    HapticFeedback.selectionClick();
  }

  Future<void> _closeDialog() async {
    if (_hasChanges) {
      final shouldClose = await _showUnsavedChangesDialog();
      if (!shouldClose) return;
    }

    await _slideAnimationController.reverse();
    await _fadeAnimationController.reverse();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppThemePro.surfaceCard,
            title: Text(
              'Niezapisane zmiany',
              style: TextStyle(color: AppThemePro.textPrimary),
            ),
            content: Text(
              'Masz niezapisane zmiany. Czy na pewno chcesz zamknąć dialog?',
              style: TextStyle(color: AppThemePro.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Anuluj'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemePro.lossRed,
                ),
                child: const Text('Zamknij bez zapisywania'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasChanges) {
          final shouldClose = await _showUnsavedChangesDialog();
          if (shouldClose && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: _isSmallScreen ? 8 : 32,
              vertical: _isSmallScreen ? 16 : 24,
            ),
            child: _buildDialogContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogContent() {
    return Container(
      width: double.infinity,
      height: _isSmallScreen
          ? MediaQuery.of(context).size.height - 32
          : MediaQuery.of(context).size.height * 0.9,
      constraints: BoxConstraints(
        maxWidth: _isLargeScreen ? 1400 : (_isMediumScreen ? 1000 : 600),
        maxHeight: 800,
      ),
      decoration: PremiumDialogDecorations.premiumContainerDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
            if (_hasChanges || _isEditing) _buildActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(_isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        gradient: PremiumDialogDecorations.headerGradient,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_isSmallScreen ? 16 : 24),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppThemePro.accentGold.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar/Icon
          Container(
            width: _isSmallScreen ? 48 : 56,
            height: _isSmallScreen ? 48 : 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppThemePro.accentGold,
                  AppThemePro.accentGoldMuted,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppThemePro.accentGold.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.person_rounded,
              color: AppThemePro.primaryDark,
              size: _isSmallScreen ? 24 : 28,
            ),
          ),

          SizedBox(width: _isSmallScreen ? 12 : 16),

          // Client info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.investor.client.name,
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontSize: _isSmallScreen ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.investor.client.companyName?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.investor.client.companyName!,
                    style: TextStyle(
                      color: AppThemePro.textSecondary,
                      fontSize: _isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                _buildQuickStats(),
              ],
            ),
          ),

          SizedBox(width: _isSmallScreen ? 8 : 16),

          // Actions
          _buildHeaderActions(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _buildStatChip(
          '${widget.investor.investmentCount}',
          'inwestycji',
          Icons.account_balance_wallet,
          AppThemePro.bondsBlue,
        ),
        _buildStatChip(
          CurrencyFormatter.formatCurrency(
            widget.investor.totalValue,
            showDecimals: false,
          ),
          'wartość',
          Icons.trending_up,
          AppThemePro.profitGreen,
        ),
      ],
    );
  }

  Widget _buildStatChip(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Investment edit toggle
        _buildHeaderButton(
          icon: _isInvestmentEditMode ? Icons.edit_off : Icons.edit,
          tooltip: _isInvestmentEditMode ? 'Wyłącz edycję inwestycji' : 'Włącz edycję inwestycji',
          onPressed: _toggleInvestmentEditMode,
          isActive: _isInvestmentEditMode,
        ),

        SizedBox(width: _isSmallScreen ? 4 : 8),

        // Close button
        _buildHeaderButton(
          icon: Icons.close,
          tooltip: 'Zamknij',
          onPressed: _closeDialog,
        ),
      ],
    );
  }

  void _toggleInvestmentEditMode() {
    setState(() {
      _isInvestmentEditMode = !_isInvestmentEditMode;
      
      if (_isInvestmentEditMode) {
        // Gdy włączamy tryb edycji, automatycznie przechodzimy na tab "Inwestycje"
        if (_selectedTabIndex != 1) { // Index 1 = tab "Inwestycje"
          _tabController.animateTo(1);
        }
      } else {
        // Resetuj editing state
        _editingInvestmentId = null;
        // Sprawdź czy są zmiany do zapisania
        _checkForInvestmentChanges();
      }
    });
    _triggerHapticFeedback();
  }

  void _checkForInvestmentChanges() {
    bool hasAnyChanges = false;
    for (final hasChanges in _investmentHasChanges.values) {
      if (hasChanges) {
        hasAnyChanges = true;
        break;
      }
    }
    setState(() {
      _hasChanges = _hasChanges || hasAnyChanges;
    });
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            padding: EdgeInsets.all(_isSmallScreen ? 8 : 10),
            decoration: BoxDecoration(
              color: isActive
                  ? AppThemePro.accentGold.withOpacity(0.2)
                  : AppThemePro.surfaceInteractive.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? AppThemePro.accentGold.withOpacity(0.5)
                    : AppThemePro.borderSecondary.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? AppThemePro.accentGold : AppThemePro.textSecondary,
              size: _isSmallScreen ? 18 : 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        border: Border(
          bottom: BorderSide(
            color: AppThemePro.borderPrimary,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: _isSmallScreen,
        tabAlignment: _isSmallScreen ? TabAlignment.start : TabAlignment.fill,
        labelColor: AppThemePro.accentGold,
        unselectedLabelColor: AppThemePro.textSecondary,
        indicatorColor: AppThemePro.accentGold,
        indicatorWeight: 3,
        labelStyle: TextStyle(
          fontSize: _isSmallScreen ? 12 : 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: _isSmallScreen ? 12 : 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: _tabs.map((tab) => _buildTab(tab)).toList(),
      ),
    );
  }

  Widget _buildTab(_TabDefinition tab) {
    final isSelected = _selectedTabIndex == _tabs.indexOf(tab);
    final tabIndex = _tabs.indexOf(tab);
    final isInvestmentsTab = tabIndex == 1; // Index 1 = "Inwestycje"
    final isBlocked = _isInvestmentEditMode && !isInvestmentsTab;

    return Tab(
      height: 60,
      child: Opacity(
        opacity: isBlocked ? 0.4 : 1.0,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: _isSmallScreen ? 8 : 16,
            vertical: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Icon(
                    isSelected ? tab.activeIcon : tab.icon,
                    size: _isSmallScreen ? 18 : 20,
                    color: isBlocked ? AppThemePro.textMuted : null,
                  ),
                  if (isBlocked)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppThemePro.statusWarning,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppThemePro.backgroundSecondary,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: _isSmallScreen ? 10 : 12,
                  color: isBlocked ? AppThemePro.textMuted : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildInvestmentsTab(),
        _buildInvestmentHistoryTab(),
        _buildVotingHistoryTab(),
        _buildNotesTab(),
      ],
    );
  }

  // === TAB CONTENT BUILDERS ===

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_isSmallScreen ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewStats(),
          const SizedBox(height: 24),
          _buildVotingStatusSection(),
          const SizedBox(height: 24),
          _buildRecentActivitySection(),
        ],
      ),
    );
  }

  Widget _buildOverviewStats() {
    final stats = [
      _StatItem(
        'Kwota inwestycji',
        CurrencyFormatter.formatCurrency(widget.investor.totalInvestmentAmount),
        Icons.trending_up,
        AppThemePro.accentGold,
        description: 'Początkowa wartość inwestycji',
      ),
      _StatItem(
        'Kapitał pozostały',
        CurrencyFormatter.formatCurrency(widget.investor.totalRemainingCapital),
        Icons.account_balance_wallet,
        AppThemePro.profitGreen,
        description: 'Aktualna wartość inwestycji',
      ),
      _StatItem(
        'Kapitał zabezpieczony',
        CurrencyFormatter.formatCurrency(widget.investor.capitalSecuredByRealEstate),
        Icons.security,
        AppThemePro.bondsBlue,
        description: 'Zabezpieczony nieruchomościami',
      ),
      _StatItem(
        'Kapitał do restrukturyzacji',
        CurrencyFormatter.formatCurrency(widget.investor.capitalForRestructuring),
        Icons.construction,
        AppThemePro.statusWarning,
        description: 'Kwota do restrukturyzacji',
      ),
  
      _StatItem(
        'Łączna wartość',
        CurrencyFormatter.formatCurrency(widget.investor.totalValue),
        Icons.savings,
        AppThemePro.accentGold,
        description: 'Kapitał pozostały + udziały',
        isHighlighted: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header z ulepszoną ikoną i opisem
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppThemePro.accentGold.withOpacity(0.1),
                AppThemePro.primaryLight.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppThemePro.accentGold.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppThemePro.accentGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics,
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
                      'Podsumowanie finansowe',
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontSize: _isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Szczegółowa analiza kapitałów i inwestycji',
                      style: TextStyle(
                        color: AppThemePro.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppThemePro.statusSuccess.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${widget.investor.investmentCount} inwestycji',
                  style: TextStyle(
                    color: AppThemePro.statusSuccess,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Lista statystyk
        Container(
          decoration: BoxDecoration(
            color: AppThemePro.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppThemePro.borderPrimary,
              width: 1,
            ),
          ),
          child: Column(
            children: stats.asMap().entries.map((entry) {
              final index = entry.key;
              final stat = entry.value;
              final isLast = index == stats.length - 1;
              
              return _buildStatListItem(stat, isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatListItem(_StatItem stat, bool isLast) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _isSmallScreen ? 16 : 20,
                vertical: _isSmallScreen ? 14 : 16,
              ),
              decoration: BoxDecoration(
                border: !isLast ? Border(
                  bottom: BorderSide(
                    color: AppThemePro.borderSecondary,
                    width: 0.5,
                  ),
                ) : null,
                color: stat.isHighlighted 
                  ? stat.color.withOpacity(0.05) 
                  : Colors.transparent,
              ),
              child: Row(
                children: [
                  // Ikona z kolorowym tłem
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          stat.color.withOpacity(0.15),
                          stat.color.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: stat.color.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      stat.icon,
                      color: stat.color,
                      size: _isSmallScreen ? 18 : 20,
                    ),
                  ),
                  
                  SizedBox(width: _isSmallScreen ? 12 : 16),
                  
                  // Teksty
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                stat.label,
                                style: TextStyle(
                                  color: AppThemePro.textPrimary,
                                  fontSize: _isSmallScreen ? 13 : 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            if (stat.isHighlighted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: stat.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: stat.color.withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  'SUMA',
                                  style: TextStyle(
                                    color: stat.color,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (stat.description != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            stat.description!,
                            style: TextStyle(
                              color: AppThemePro.textMuted,
                              fontSize: _isSmallScreen ? 11 : 12,
                              fontWeight: FontWeight.w400,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  SizedBox(width: _isSmallScreen ? 8 : 12),
                  
                  // Wartość (po prawej stronie)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          stat.value,
                          style: TextStyle(
                            color: stat.color,
                            fontSize: _isSmallScreen ? 16 : (stat.isHighlighted ? 18 : 16),
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVotingStatusSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.how_to_vote,
                color: AppThemePro.accentGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Status głosowania',
                style: TextStyle(
                  color: AppThemePro.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OptimizedVotingStatusSelector(
            currentStatus: _selectedVotingStatus,
            onStatusChanged: (status) {
              setState(() {
                _selectedVotingStatus = status;
                _hasChanges = true;
              });
            },
            isCompact: false,
            showLabels: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    final recentChanges = _investmentHistory.take(3).toList();
    final recentVotingChanges = _votingHistory.take(2).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: AppThemePro.accentGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Ostatnia aktywność',
                style: TextStyle(
                  color: AppThemePro.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentChanges.isEmpty && recentVotingChanges.isEmpty)
            Text(
              'Brak ostatniej aktywności',
              style: TextStyle(
                color: AppThemePro.textMuted,
                fontStyle: FontStyle.italic,
              ),
            )
          else ...[
            ...recentChanges.map((change) => _buildActivityItem(
                  title: change.changeDescription,
                  subtitle: 'Zmiana inwestycji',
                  time: change.changedAt,
                  icon: Icons.edit,
                  color: AppThemePro.bondsBlue,
                )),
            ...recentVotingChanges.map((change) => _buildActivityItem(
                  title: 'Zmiana statusu głosowania',
                  subtitle:
                      '${change.oldStatus?.displayName ?? 'Nieznany'} → ${change.newStatus?.displayName ?? 'Nieznany'}',
                  time: change.timestamp,
                  icon: Icons.how_to_vote,
                  color: AppThemePro.accentGold,
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required DateTime time,
    required IconData icon,
    required Color color,
  }) {
    final timeAgo = _formatTimeAgo(time);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeAgo,
            style: TextStyle(
              color: AppThemePro.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentsTab() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // 🚀 NOWE: Toolbar z przełącznikiem trybu edycji
          _buildInvestmentsToolbar(),
          
          // Main content area
          Expanded(
            child: _isInvestmentEditMode 
              ? _buildAdvancedEditingView()
              : _buildStandardInvestmentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentsToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        border: Border(
          bottom: BorderSide(
            color: AppThemePro.borderPrimary,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 🚀 NOWE: Header z trybem edycji
          Row(
            children: [
              Expanded(
                child: Text(
                  'INWESTYCJE (${widget.investor.investments.length})',
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // 🚀 NOWE: Toggle button dla zaawansowanej edycji
              Container(
                decoration: BoxDecoration(
                  color: _isInvestmentEditMode 
                    ? AppThemePro.accentGold.withOpacity(0.1)
                    : AppThemePro.backgroundTertiary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isInvestmentEditMode 
                      ? AppThemePro.accentGold.withOpacity(0.3)
                      : AppThemePro.borderSecondary,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _toggleInvestmentEditMode,
                      icon: Icon(
                        _isInvestmentEditMode 
                          ? Icons.edit 
                          : Icons.edit_outlined,
                        size: 18,
                      ),
                      color: _isInvestmentEditMode 
                        ? AppThemePro.accentGold 
                        : AppThemePro.textSecondary,
                      tooltip: _isInvestmentEditMode 
                        ? 'Wyłącz tryb edycji'
                        : 'Włącz zaawansowaną edycję',
                    ),
                    if (_isInvestmentEditMode) ...[
                      Container(
                        width: 1,
                        height: 24,
                        color: AppThemePro.accentGold.withOpacity(0.3),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'EDYCJA',
                        style: TextStyle(
                          color: AppThemePro.accentGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search bar (tylko jeśli nie ma trybu edycji)
          if (!_isInvestmentEditMode) ...[
            TextField(
              controller: _searchController,
              style: TextStyle(color: AppThemePro.textPrimary),
              decoration: InputDecoration(
                hintText: 'Szukaj inwestycji...',
                hintStyle: TextStyle(color: AppThemePro.textMuted),
                prefixIcon: Icon(Icons.search, color: AppThemePro.textSecondary),
                suffixIcon: _investmentSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppThemePro.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _investmentSearchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppThemePro.surfaceInteractive,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _investmentSearchQuery = value;
                });
              },
            ),

            const SizedBox(height: 12),

            // Filters (tylko jeśli nie ma trybu edycji)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    'Wszystkie',
                    _selectedProductTypeFilter == null,
                    () => setState(() => _selectedProductTypeFilter = null),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Obligacje',
                    _selectedProductTypeFilter == ProductType.bonds,
                    () => setState(() =>
                        _selectedProductTypeFilter = ProductType.bonds),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Udziały',
                    _selectedProductTypeFilter == ProductType.shares,
                    () => setState(() =>
                        _selectedProductTypeFilter = ProductType.shares),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Pożyczki',
                    _selectedProductTypeFilter == ProductType.loans,
                    () => setState(() =>
                        _selectedProductTypeFilter = ProductType.loans),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Apartamenty',
                    _selectedProductTypeFilter == ProductType.apartments,
                    () => setState(() =>
                        _selectedProductTypeFilter = ProductType.apartments),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Tylko nieopłacalne',
                    _showOnlyUnviable,
                    () => setState(() => _showOnlyUnviable = !_showOnlyUnviable),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Informacja o trybie edycji
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppThemePro.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppThemePro.accentGold.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppThemePro.accentGold,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tryb zaawansowanej edycji aktywny. Możesz edytować wszystkie pola z automatycznymi obliczeniami.',
                      style: TextStyle(
                        color: AppThemePro.accentGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppThemePro.accentGold.withOpacity(0.2)
                : AppThemePro.surfaceInteractive,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppThemePro.accentGold
                  : AppThemePro.borderSecondary,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppThemePro.accentGold : AppThemePro.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvestmentsList() {
    final filteredInvestments = _getFilteredInvestments();

    if (filteredInvestments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: AppThemePro.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Brak inwestycji spełniających kryteria',
              style: TextStyle(
                color: AppThemePro.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredInvestments.length,
      itemBuilder: (context, index) {
        return _buildInvestmentCard(filteredInvestments[index]);
      },
    );
  }

  /// 🚀 NOWE: Standard investments list (tylko podgląd)
  Widget _buildStandardInvestmentsList() {
    return _buildInvestmentsList();
  }

  /// 🚀 NOWE: Zaawansowany widok edycji używający komponentów z InvestorEditDialog
  Widget _buildAdvancedEditingView() {
    return CustomScrollView(
      slivers: [
        // Loading indicator jeśli operacja w toku
        if (_editState.isLoading)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: PremiumLoadingIndicator(
                isLoading: true,
                text: 'Zapisywanie zmian...',
              ),
            ),
          ),

        // Error notification if present
        if (_editState.error != null)
          SliverToBoxAdapter(child: _buildPremiumErrorCard()),

        // Investments editing section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header z informacją o trybie edycji
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppThemePro.accentGold.withOpacity(0.1),
                        AppThemePro.accentGold.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppThemePro.accentGold.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppThemePro.accentGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          color: AppThemePro.accentGold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TRYB ZAAWANSOWANEJ EDYCJI',
                              style: TextStyle(
                                color: AppThemePro.accentGold,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Edycja wszystkich kluczowych pól inwestycji z automatycznymi obliczeniami',
                              style: TextStyle(
                                color: AppThemePro.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Investment cards z zaawansowaną edycją
                Column(
                  children: List.generate(
                    widget.investor.investments.length,
                    (index) {
                      final investment = widget.investor.investments[index];
                      return Container(
                        margin: EdgeInsets.only(
                          bottom: index < widget.investor.investments.length - 1 ? 20 : 0,
                        ),
                        child: InvestmentEditCard(
                          investment: investment,
                          index: index,
                          remainingCapitalController:
                              _unifiedControllers.remainingCapitalControllers[index],
                          investmentAmountController:
                              _unifiedControllers.investmentAmountControllers[index],
                          capitalForRestructuringController:
                              _unifiedControllers.capitalForRestructuringControllers[index],
                          capitalSecuredController: _unifiedControllers
                              .capitalSecuredByRealEstateControllers[index],
                          statusValue: _unifiedControllers.statusValues[index],
                          onStatusChanged: (status) => _onUnifiedStatusChanged(index, status),
                          onChanged: _onUnifiedDataChanged,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  /// 🚀 NOWE: Error card z premium stylistyką
  Widget _buildPremiumErrorCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
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
                  style: TextStyle(
                    color: AppThemePro.lossRed,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _editState.error!,
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontSize: 13,
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

  /// 🚀 NOWE: Handler dla zmian unified controllers
  void _onUnifiedDataChanged() {
    if (mounted) {
      setState(() {
        _editState = _editState.withChanges();
        _hasChanges = true;
      });
    }
  }

  /// 🚀 NOWE: Handler dla zmian statusu
  void _onUnifiedStatusChanged(int index, InvestmentStatus newStatus) {
    if (mounted) {
      setState(() {
        _unifiedControllers.statusValues[index] = newStatus;
        _editState = _editState.withChanges();
        _hasChanges = true;
      });
    }
  }

  List<Investment> _getFilteredInvestments() {
    return widget.investor.investments.where((investment) {
      // Search filter
      if (_investmentSearchQuery.isNotEmpty &&
          !investment.productName
              .toLowerCase()
              .contains(_investmentSearchQuery.toLowerCase()) &&
          !investment.creditorCompany
              .toLowerCase()
              .contains(_investmentSearchQuery.toLowerCase())) {
        return false;
      }

      // Product type filter
      if (_selectedProductTypeFilter != null &&
          investment.productType != _selectedProductTypeFilter) {
        return false;
      }

      // Unviable filter
      if (_showOnlyUnviable &&
          !_selectedUnviableInvestments.contains(investment.id)) {
        return false;
      }

      return true;
    }).toList();
  }

  Widget _buildInvestmentCard(Investment investment) {
    final isUnviable = _selectedUnviableInvestments.contains(investment.id);
    final productTypeColor = AppThemePro.getInvestmentTypeColor(
      investment.productType.name,
    );
    final isEditing = _isInvestmentEditMode && _editingInvestmentId == investment.id;
    final hasChanges = _investmentHasChanges[investment.id] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _isInvestmentEditMode 
        ? PremiumDialogDecorations.getInvestmentCardDecoration(
            hasChanges: hasChanges,
            isHovered: isEditing,
          )
        : BoxDecoration(
            color: AppThemePro.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnviable
                  ? AppThemePro.lossRed.withOpacity(0.3)
                  : productTypeColor.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isUnviable ? AppThemePro.lossRed : productTypeColor)
                    .withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isInvestmentEditMode 
            ? () => _toggleInvestmentEdit(investment.id)
            : () => _navigateToInvestmentDetails(investment),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header z statusem edycji
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: productTypeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getProductTypeIcon(investment.productType),
                        color: productTypeColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            investment.productName,
                            style: TextStyle(
                              color: AppThemePro.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            investment.creditorCompany,
                            style: TextStyle(
                              color: AppThemePro.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isInvestmentEditMode) ...[
                      if (hasChanges)
                        ChangeStatusIndicator(
                          hasChanges: true,
                          changeText: 'ZMIENIONO',
                        )
                      else
                        Icon(
                          isEditing ? Icons.edit : Icons.edit_outlined,
                          color: AppThemePro.accentGold,
                          size: 20,
                        ),
                    ] else if (_isEditing) ...[
                      Checkbox(
                        value: isUnviable,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedUnviableInvestments.add(investment.id);
                            } else {
                              _selectedUnviableInvestments.remove(investment.id);
                            }
                            _hasChanges = true;
                          });
                        },
                        activeColor: AppThemePro.lossRed,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Financial data - edytowalne lub tylko do odczytu
                if (isEditing)
                  _buildEditableInvestmentFields(investment)
                else
                  _buildReadOnlyInvestmentFields(investment),

                if (isUnviable) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppThemePro.lossRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppThemePro.lossRed.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: AppThemePro.lossRed,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Oznaczone jako nieopłacalne',
                          style: TextStyle(
                            color: AppThemePro.lossRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialDataItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppThemePro.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _toggleInvestmentEdit(String investmentId) {
    setState(() {
      if (_editingInvestmentId == investmentId) {
        // Wyłącz edycję tej inwestycji
        _editingInvestmentId = null;
      } else {
        // Włącz edycję tej inwestycji
        _editingInvestmentId = investmentId;
      }
    });
    _triggerHapticFeedback();
  }

  Widget _buildReadOnlyInvestmentFields(Investment investment) {
    return Column(
      children: [
        // Pierwszy rząd - kwoty podstawowe (🎯 UPROSZCZONE: tylko kluczowe pola)
        Row(
          children: [
            Expanded(
              child: _buildFinancialDataItem(
                'Kwota inwestycji',
                CurrencyFormatter.formatCurrency(investment.investmentAmount),
                AppThemePro.bondsBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinancialDataItem(
                'Kapitał pozostały',
                CurrencyFormatter.formatCurrency(investment.remainingCapital),
                AppThemePro.profitGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Drugi rząd - kapitały specjalne (🎯 UPROSZCZONE: tylko kluczowe pola)
        Row(
          children: [
            Expanded(
              child: _buildFinancialDataItem(
                'Kapitał do restrukturyzacji',
                CurrencyFormatter.formatCurrency(investment.capitalForRestructuring),
                AppThemePro.loansOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinancialDataItem(
                'Kapitał zabezpieczony',
                CurrencyFormatter.formatCurrency(investment.capitalSecuredByRealEstate),
                AppThemePro.neutralGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Czwarty rząd - kapitał zabezpieczony i restrukturyzacja
        Row(
          children: [
            Expanded(
              child: _buildFinancialDataItem(
                'Kapitał zabezpieczony',
                CurrencyFormatter.formatCurrency(investment.capitalSecuredByRealEstate),
                AppThemePro.realEstateViolet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinancialDataItem(
                'Do restrukturyzacji',
                CurrencyFormatter.formatCurrency(investment.capitalForRestructuring),
                AppThemePro.statusWarning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // 🔢 AUTOMATYCZNE OBLICZENIA (tylko do wyświetlania)
        _buildCalculatedFields(investment),
      ],
    );
  }

  Widget _buildEditableInvestmentFields(Investment investment) {
    final controllers = _investmentControllers[investment.id];
    if (controllers == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: PremiumDialogDecorations.getInputDecorationTheme().fillColor != null 
        ? BoxDecoration(
            color: AppThemePro.backgroundTertiary.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppThemePro.accentGold.withOpacity(0.3),
              width: 1,
            ),
          )
        : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: AppThemePro.accentGold,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Tryb edycji (tylko kluczowe pola)',
                style: TextStyle(
                  color: AppThemePro.accentGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Pierwszy rząd - kwoty podstawowe (🎯 UPROSZCZONE: tylko kluczowe pola)
          Row(
            children: [
              Expanded(
                child: _buildEditableField(
                  'Kwota inwestycji',
                  controllers['investmentAmount']!,
                  investment.id,
                  'investmentAmount',
                  AppThemePro.bondsBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEditableField(
                  'Kapitał pozostały',
                  controllers['remainingCapital']!,
                  investment.id,
                  'remainingCapital',
                  AppThemePro.profitGreen,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Drugi rząd - kapitały specjalne (🎯 UPROSZCZONE: tylko kluczowe pola)
          Row(
            children: [
              Expanded(
                child: _buildEditableField(
                  'Kapitał do restrukturyzacji',
                  controllers['capitalForRestructuring']!,
                  investment.id,
                  'capitalForRestructuring',
                  AppThemePro.loansOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEditableField(
                  'Kapitał zabezpieczony',
                  controllers['capitalSecuredByRealEstate']!,
                  investment.id,
                  'capitalSecuredByRealEstate',
                  AppThemePro.neutralGray,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // === OBLICZENIA AUTOMATYCZNE ===
          _buildCalculatedFields(investment),
          
          const SizedBox(height: 16),
          
          // Przyciski akcji
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _resetInvestmentFields(investment.id),
                  icon: Icon(Icons.refresh, size: 16),
                  label: const Text('Resetuj'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppThemePro.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _saveInvestmentChanges(investment.id),
                  icon: Icon(Icons.save, size: 16),
                  label: const Text('Zapisz'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemePro.accentGold,
                    foregroundColor: AppThemePro.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    String investmentId,
    String fieldName,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [CurrencyInputFormatter()],
          style: TextStyle(
            color: AppThemePro.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: '0,00',
            hintStyle: TextStyle(color: AppThemePro.textMuted),
            filled: true,
            fillColor: AppThemePro.backgroundSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: (_) => _onInvestmentFieldChanged(investmentId),
        ),
      ],
    );
  }

  Widget _buildCalculatedFields(Investment investment) {
    final controllers = _investmentControllers[investment.id];
    if (controllers == null) return const SizedBox.shrink();

    // Parsuj aktualne wartości z kontrolerów używając editService (usuwa spacje!)
    final investmentAmount = _editService.parseValueFromController(controllers['investmentAmount']!.text);
    final remainingCapital = _editService.parseValueFromController(controllers['remainingCapital']!.text);
    final capitalForRestructuring = _editService.parseValueFromController(controllers['capitalForRestructuring']!.text);

    // 🔢 OBLICZENIA ZGODNE Z MODELEM INVESTMENT
    final totalValue = remainingCapital; // Zgodnie z modelem: totalValue => remainingCapital
    final profitLoss = remainingCapital - investmentAmount; // Zgodnie z modelem
    final profitLossPercentage = investmentAmount > 0 ? (profitLoss / investmentAmount) * 100 : 0.0;

    // Kapitał zabezpieczony = max(remainingCapital - capitalForRestructuring, 0)
    final capitalSecured = (remainingCapital - capitalForRestructuring).clamp(0.0, double.infinity);

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
          Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                color: AppThemePro.accentGold,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Obliczenia automatyczne',
                style: TextStyle(
                  color: AppThemePro.accentGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
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
                'Kapitał zabezpieczony (oblicz.)',
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
              style: TextStyle(
                color: AppThemePro.getPerformanceColor(profitLossPercentage),
                fontSize: 11,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppThemePro.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              CurrencyFormatter.formatCurrency(value),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _onInvestmentFieldChanged(String investmentId) {
    setState(() {
      _investmentHasChanges[investmentId] = true;
      _hasChanges = true;
    });
  }

  /// 🔧 NOWE: Automatyczne przeliczanie kapitału pozostałego
  /// remainingCapital = capitalSecuredByRealEstate + capitalForRestructuring
  void _calculateAutomaticRemainingCapital(String investmentId) {
    final controllers = _investmentControllers[investmentId];
    if (controllers == null) return;

    try {
      // Pobierz wartości z kontrolerów
      final capitalForRestructuringText = controllers['capitalForRestructuring']!.text;
      final capitalSecuredText = controllers['capitalSecuredByRealEstate']!.text;
      final currentRemainingCapitalText = controllers['remainingCapital']!.text;

      debugPrint('🧮 [EnhancedDialog] Auto-calculating remaining capital for $investmentId:');
      debugPrint('   - capitalForRestructuring text: "$capitalForRestructuringText"');
      debugPrint('   - capitalSecured text: "$capitalSecuredText"');
      debugPrint('   - CURRENT remainingCapital text: "$currentRemainingCapitalText"');

      // Parsuj wartości używając editService (usuwa spacje)
      final capitalForRestructuring = _editService.parseValueFromController(capitalForRestructuringText);
      final capitalSecured = _editService.parseValueFromController(capitalSecuredText);

      // 🧮 LOGIKA BIZNESOWA: Kapitał pozostały = Kapitał zabezpieczony + Kapitał do restrukturyzacji
      final calculatedRemainingCapital = capitalSecured + capitalForRestructuring;

      debugPrint('   - Parsed capitalForRestructuring: $capitalForRestructuring');
      debugPrint('   - Parsed capitalSecured: $capitalSecured');
      debugPrint('   - Calculated remainingCapital: $calculatedRemainingCapital');

      // Sformatuj nową wartość
      final newRemainingCapitalText = calculatedRemainingCapital.toStringAsFixed(2);

      // Aktualizuj kontroler tylko jeśli wartość się zmieniła (unikamy nieskończonych pętli)
      if (controllers['remainingCapital']!.text != newRemainingCapitalText) {
        debugPrint('📝 [EnhancedDialog] Updating remaining capital: $currentRemainingCapitalText → $newRemainingCapitalText');
        
        controllers['remainingCapital']!.text = newRemainingCapitalText;
        
        // Oznacz jako zmienione
        _onInvestmentFieldChanged(investmentId);
      }
    } catch (e) {
      debugPrint('❌ [EnhancedDialog] Error calculating automatic remaining capital: $e');
    }
  }

  void _resetInvestmentFields(String investmentId) {
    final investment = widget.investor.investments.firstWhere((inv) => inv.id == investmentId);
    final controllers = _investmentControllers[investmentId];
    
    if (controllers != null) {
      // 🎯 UPROSZCZONE: Resetuj tylko 4 kluczowe pola
      controllers['investmentAmount']!.text = investment.investmentAmount.toStringAsFixed(2);
      controllers['remainingCapital']!.text = investment.remainingCapital.toStringAsFixed(2);
      controllers['capitalForRestructuring']!.text = investment.capitalForRestructuring.toStringAsFixed(2);
      controllers['capitalSecuredByRealEstate']!.text = investment.capitalSecuredByRealEstate.toStringAsFixed(2);
      
      setState(() {
        _investmentHasChanges[investmentId] = false;
      });
    }
  }

  Future<void> _saveInvestmentChanges(String investmentId) async {
    final controllers = _investmentControllers[investmentId];
    if (controllers == null) return;

    try {
      setState(() => _isLoading = true);

      // Znajdź inwestycję i stwórz zaktualizowaną wersję
      final investment = widget.investor.investments.firstWhere((inv) => inv.id == investmentId);
      
      // 🎯 UPROSZCZONE: Parsuj tylko 4 kluczowe pola używając editService (usuwa spacje!)
      final investmentAmount = _editService.parseValueFromController(controllers['investmentAmount']!.text);
      final remainingCapital = _editService.parseValueFromController(controllers['remainingCapital']!.text);
      final capitalForRestructuring = _editService.parseValueFromController(controllers['capitalForRestructuring']!.text);
      final capitalSecuredByRealEstate = _editService.parseValueFromController(controllers['capitalSecuredByRealEstate']!.text);

      // Stwórz zaktualizowany obiekt Investment (zachowaj pozostałe pola)
      final updatedInvestment = Investment(
        id: investment.id,
        clientId: investment.clientId,
        clientName: investment.clientName,
        employeeId: investment.employeeId,
        employeeFirstName: investment.employeeFirstName,
        employeeLastName: investment.employeeLastName,
        branchCode: investment.branchCode,
        status: investment.status,
        isAllocated: investment.isAllocated,
        marketType: investment.marketType,
        signedDate: investment.signedDate,
        entryDate: investment.entryDate,
        exitDate: investment.exitDate,
        proposalId: investment.proposalId,
        productType: investment.productType,
        productName: investment.productName,
        productId: investment.productId,
        creditorCompany: investment.creditorCompany,
        companyId: investment.companyId,
        issueDate: investment.issueDate,
        redemptionDate: investment.redemptionDate,
        sharesCount: investment.sharesCount,
        // 🎯 ZAKTUALIZOWANE: Tylko 4 kluczowe pola
        investmentAmount: investmentAmount,
        remainingCapital: remainingCapital,
        capitalForRestructuring: capitalForRestructuring,
        capitalSecuredByRealEstate: capitalSecuredByRealEstate,
        // 🔒 ZACHOWANE: Pozostałe pola bez zmian
        paidAmount: investment.paidAmount,
        realizedCapital: investment.realizedCapital,
        realizedInterest: investment.realizedInterest,
        remainingInterest: investment.remainingInterest,
        transferToOtherProduct: investment.transferToOtherProduct,
        plannedTax: investment.plannedTax,
        realizedTax: investment.realizedTax,
        currency: investment.currency,
        exchangeRate: investment.exchangeRate,
        createdAt: investment.createdAt,
        updatedAt: DateTime.now(),
        additionalInfo: investment.additionalInfo,
      );

      // Zapisz bezpośrednio do Firestore (jak w product_edit_dialog)
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore.collection('investments').doc(investmentId);
      await docRef.update(updatedInvestment.toFirestore());

      // Wyczyść cache
      final cacheService = DataCacheService();
      cacheService.invalidateCache();
      cacheService.invalidateCollectionCache('investments');

      setState(() {
        _investmentHasChanges[investmentId] = false;
        _editingInvestmentId = null;
      });

      // Pokaż sukces
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Text('Zmiany zostały zapisane'),
              ],
            ),
            backgroundColor: AppThemePro.profitGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }

      // Przeładuj dane
      if (widget.onUpdate != null) {
        widget.onUpdate!();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Błąd zapisywania: $e')),
              ],
            ),
            backgroundColor: AppThemePro.lossRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildInvestmentHistoryTab() {
    // Używamy już załadowanych danych z _investmentHistory zamiast InvestmentHistoryWidget
    return _buildClientHistoryView();
  }

  Widget _buildClientHistoryView() {
    if (_historyLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: 16),
            Text('Ładowanie historii zmian...'),
          ],
        ),
      );
    }

    if (_investmentHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppThemePro.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Brak historii zmian',
              style: TextStyle(
                color: AppThemePro.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ten klient nie ma jeszcze żadnych zapisanych zmian inwestycji.',
              style: TextStyle(
                color: AppThemePro.textMuted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(_isSmallScreen ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppThemePro.accentGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.history,
                  size: 20,
                  color: AppThemePro.accentGold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historia zmian inwestycji',
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontSize: _isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_investmentHistory.length} ${_getHistoryCountText(_investmentHistory.length)}',
                      style: TextStyle(
                        color: AppThemePro.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadInvestmentHistory,
                icon: Icon(
                  Icons.refresh,
                  color: AppThemePro.textSecondary,
                ),
                tooltip: 'Odśwież historię',
              ),
            ],
          ),
          
          const SizedBox(height: 20),

          // History entries
          ..._investmentHistory.map((entry) => _buildClientHistoryEntry(entry)),
        ],
      ),
    );
  }

  Widget _buildClientHistoryEntry(InvestmentChangeHistory entry) {
    final changeTypeColor = _getChangeTypeColor(entry.changeType);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: changeTypeColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: changeTypeColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with change type and date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: changeTypeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: changeTypeColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getChangeTypeIcon(entry.changeType),
                      size: 16,
                      color: changeTypeColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      InvestmentChangeType.fromValue(entry.changeType).displayName,
                      style: TextStyle(
                        color: changeTypeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppThemePro.backgroundSecondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatHistoryDate(entry.changedAt),
                  style: TextStyle(
                    color: AppThemePro.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Investment info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppThemePro.backgroundSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 16,
                  color: AppThemePro.accentGold,
                ),
                const SizedBox(width: 8),
                Text(
                  'Inwestycja: ${_getProductNameFromInvestmentId(entry.investmentId)}',
                  style: TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Change description
          Text(
            entry.changeDescription,
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          // User info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppThemePro.accentGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.person,
                  size: 14,
                  color: AppThemePro.accentGold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.userName,
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      entry.userEmail,
                      style: TextStyle(
                        color: AppThemePro.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Field changes
          if (entry.fieldChanges.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppThemePro.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppThemePro.borderSecondary,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.list_alt,
                        size: 16,
                        color: AppThemePro.accentGold,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Szczegóły zmian (${entry.fieldChanges.length})',
                        style: TextStyle(
                          color: AppThemePro.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Show amount changes first with highlighting
                  ...entry.fieldChanges
                      .where((change) => _isAmountField(change.fieldName))
                      .map((change) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppThemePro.accentGold.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppThemePro.accentGold.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  size: 12,
                                  color: AppThemePro.accentGold,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    change.changeDescription,
                                    style: TextStyle(
                                      color: AppThemePro.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                  
                  // Show other changes
                  ...entry.fieldChanges
                      .where((change) => !_isAmountField(change.fieldName))
                      .map((change) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppThemePro.textSecondary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    change.changeDescription,
                                    style: TextStyle(
                                      color: AppThemePro.textPrimary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper methods for history display
  String _getHistoryCountText(int count) {
    if (count == 1) return 'wpis';
    if (count >= 2 && count <= 4) return 'wpisy';
    return 'wpisów';
  }

  String _getProductNameFromInvestmentId(String investmentId) {
    // Znajdź inwestycję po ID w aktualnych inwestycjach inwestora
    try {
      final investment = widget.investor.investments.firstWhere(
        (inv) => inv.id == investmentId,
      );
      
      // Jeśli ma productName, użyj go
      if (investment.productName.isNotEmpty) {
        return investment.productName;
      }
      
      // Fallback: spróbuj utworzyć czytelną nazwę z typu i firmy
      String productName = investment.productType.displayName;
      if (investment.creditorCompany.isNotEmpty) {
        productName += ' (${investment.creditorCompany})';
      }
      
      return productName;
    } catch (e) {
      // Jeśli nie znaleziono inwestycji, zwróć samo ID
      debugPrint('🔍 [EnhancedInvestorDetailsDialog] Nie można znaleźć nazwy produktu dla ID: $investmentId');
      return investmentId;
    }
  }

  String _formatHistoryDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return 'Dziś ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Wczoraj ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dni temu';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }
  }

  Color _getChangeTypeColor(String changeType) {
    switch (changeType) {
      case 'field_update':
        return AppThemePro.accentGold;
      case 'bulk_update':
        return AppThemePro.profitGreen;
      case 'import':
        return AppThemePro.sharesGreen;
      case 'manual_entry':
        return AppThemePro.bondsBlue;
      case 'system_update':
        return AppThemePro.neutralGray;
      case 'correction':
        return AppThemePro.lossRed;
      default:
        return AppThemePro.textSecondary;
    }
  }

  IconData _getChangeTypeIcon(String changeType) {
    switch (changeType) {
      case 'field_update':
        return Icons.edit;
      case 'bulk_update':
        return Icons.batch_prediction;
      case 'import':
        return Icons.upload_file;
      case 'manual_entry':
        return Icons.create;
      case 'system_update':
        return Icons.system_update;
      case 'correction':
        return Icons.build_circle;
      default:
        return Icons.change_history;
    }
  }

  bool _isAmountField(String fieldName) {
    const amountFields = {
      'investmentAmount',
      'paidAmount', 
      'remainingCapital',
      'realizedCapital',
      'realizedInterest',
      'remainingInterest',
      'capitalForRestructuring',
      'capitalSecuredByRealEstate',
      'plannedTax',
      'realizedTax',
      'totalProductAmount',
      'transferToOtherProduct',
    };
    return amountFields.contains(fieldName);
  }

  Widget _buildVotingHistoryTab() {
    return VotingChangesTab(investor: widget.investor);
  }

  Widget _buildNotesTab() {
    return ClientNotesWidget(
      clientId: widget.investor.client.id,
      clientName: widget.investor.client.name,
      currentUserId: 'current_user_id', // TODO: Get from AuthProvider
      currentUserName: 'Current User', // TODO: Get from AuthProvider
    );
  }



  Widget _buildActionBar() {
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
                hasChanges: _hasChanges,
                changeText: _isInvestmentEditMode 
                  ? 'ZAAWANSOWANE ZMIANY OCZEKUJĄ'
                  : 'ZMIANY OCZEKUJĄ',
                noChangeText: _isInvestmentEditMode 
                  ? 'GOTOWY DO ZAAWANSOWANEJ EDYCJI'
                  : 'GOTOWY DO EDYCJI',
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
                    gradient: (_isLoading || _editState.isLoading)
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
                    boxShadow: (_isLoading || _editState.isLoading)
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
                    onPressed: (_isLoading || _editState.isLoading) 
                      ? null 
                      : (_isInvestmentEditMode ? _saveUnifiedChanges : _saveChanges),
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
                        if (_isLoading || _editState.isLoading) ...[
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
                            _isInvestmentEditMode 
                              ? 'ZAPISZ INWESTYCJE'
                              : 'ZAPISZ ZMIANY',
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

  // === HELPER METHODS ===

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      // Check if voting status changed
      final oldVotingStatus = widget.investor.client.votingStatus;
      final votingStatusChanged = oldVotingStatus != _selectedVotingStatus;

      // Update notes
      await _analyticsService.updateInvestorNotes(
        widget.investor.client.id,
        _notesController.text,
      );

      // Update voting status
      if (votingStatusChanged) {
        await _votingService.updateVotingStatus(
          widget.investor.client.id,
          _selectedVotingStatus,
          reason: 'Updated via enhanced investor details dialog',
          editedBy: 'Enhanced Analytics Dialog',
          editedByEmail: 'system@enhanced-dialog.local',
          updatedVia: 'enhanced_investor_details_dialog',
        );
      }

      // Update color
      await _analyticsService.updateInvestorColor(
        widget.investor.client.id,
        _selectedColor,
      );

      // Update unviable investments
      await _analyticsService.markInvestmentsAsUnviable(
        widget.investor.client.id,
        _selectedUnviableInvestments,
      );

      // Create updated investor object
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

      if (mounted) {
        // Call callbacks
        if (widget.onInvestorUpdated != null) {
          widget.onInvestorUpdated!(updatedInvestor);
        } else if (widget.onUpdate != null) {
          widget.onUpdate!();
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Zmiany zostały zapisane pomyślnie'),
              ],
            ),
            backgroundColor: AppThemePro.profitGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // Update state
        setState(() {
          _hasChanges = false;
        });

        // Reload data
        await _loadInitialData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Błąd podczas zapisywania: $e')),
              ],
            ),
            backgroundColor: AppThemePro.lossRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToInvestmentDetails(Investment investment) {
    Navigator.of(context).pop();
    context.go('/products?investmentId=${investment.id}');
  }

  IconData _getProductTypeIcon(ProductType type) {
    switch (type) {
      case ProductType.bonds:
        return Icons.account_balance;
      case ProductType.shares:
        return Icons.trending_up;
      case ProductType.loans:
        return Icons.handshake;
      case ProductType.apartments:
        return Icons.home;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} dni temu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} godz. temu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min. temu';
    } else {
      return 'Teraz';
    }
  }

  /// 🚀 NOWE: Zapisywanie zmian w trybie zaawansowanej edycji
  Future<void> _saveUnifiedChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _editState = _editState.withLoading(true).clearError();
    });

    try {
      // Obsłuż standardowe zmiany pojedynczych inwestycji
      final success = await _editService.saveInvestmentChanges(
        originalInvestments: widget.investor.investments,
        remainingCapitalControllers: _unifiedControllers.remainingCapitalControllers,
        investmentAmountControllers: _unifiedControllers.investmentAmountControllers,
        capitalForRestructuringControllers:
            _unifiedControllers.capitalForRestructuringControllers,
        capitalSecuredControllers:
            _unifiedControllers.capitalSecuredByRealEstateControllers,
        statusValues: _unifiedControllers.statusValues,
        changeReason: 'Zaawansowana edycja inwestycji przez ${widget.investor.client.name}',
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

        // Wywołaj callback aktualizacji
        if (widget.onInvestorUpdated != null) {
          // Utworzenie zaktualizowanego InvestorSummary z nowymi danymi
          final updatedInvestments = widget.investor.investments;
          final updatedInvestor = InvestorSummary(
            client: widget.investor.client,
            investments: updatedInvestments,
            totalInvestmentAmount: widget.investor.totalInvestmentAmount,
            totalRemainingCapital: widget.investor.totalRemainingCapital,
            totalSharesValue: widget.investor.totalSharesValue,
            totalValue: widget.investor.totalValue,
            totalRealizedCapital: widget.investor.totalRealizedCapital,
            capitalForRestructuring: widget.investor.capitalForRestructuring,
            capitalSecuredByRealEstate: widget.investor.capitalSecuredByRealEstate,
            investmentCount: widget.investor.investmentCount,
          );
          widget.onInvestorUpdated!(updatedInvestor);
        }

        if (mounted) {
          setState(() {
            _editState = _editState.resetChanges().withLoading(false);
            _hasChanges = false;
            _isInvestmentEditMode = false; // Wyłącz tryb edycji po zapisaniu
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _editState = _editState
                .withLoading(false)
                .copyWith(error: 'Błąd podczas zapisywania zmian');
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [EnhancedDialog] Błąd podczas zapisywania: $e');
      if (mounted) {
        setState(() {
          _editState = _editState
              .withLoading(false)
              .copyWith(
                error: 'Błąd podczas zapisywania zmian: ${e.toString()}',
              );
        });
      }
    }
  }

  /// 🚀 NOWE: Formatuje kwoty walutowe
  String _formatCurrency(double amount) {
    return CurrencyFormatter.formatCurrency(amount);
  }
}

// === HELPER CLASSES ===

class _TabDefinition {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String tooltip;

  const _TabDefinition({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.tooltip,
  });
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? description;
  final bool isHighlighted;

  const _StatItem(
    this.label, 
    this.value, 
    this.icon, 
    this.color, {
    this.description,
    this.isHighlighted = false,
  });
}