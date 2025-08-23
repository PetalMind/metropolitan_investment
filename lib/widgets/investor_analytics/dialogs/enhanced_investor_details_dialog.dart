import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../models_and_services.dart';
import '../../../theme/app_theme_professional.dart';
import '../../optimized_voting_status_widget.dart';
import '../../client_notes_widget.dart';
import '../tabs/voting_changes_tab.dart';

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

  // === STATE VARIABLES ===
  // Investor data
  late VotingStatus _selectedVotingStatus;
  String _selectedColor = '#FFFFFF';
  List<String> _selectedUnviableInvestments = [];

  // UI State
  int _selectedTabIndex = 0;
  bool _isLoading = false;
  bool _isEditing = false;
  bool _hasChanges = false;

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
    _selectedVotingStatus = widget.investor.client.votingStatus;
    _selectedColor = widget.investor.client.colorCode;
    _selectedUnviableInvestments =
        List.from(widget.investor.client.unviableInvestments);

    // Initialize controllers
    _notesController = TextEditingController(
      text: widget.investor.client.notes,
    );
    _searchController = TextEditingController();

    // Tab controller
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: 0,
    );

    _tabController.addListener(_onTabChanged);
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
      setState(() {
        _selectedTabIndex = _tabController.index;
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
      decoration: BoxDecoration(
        color: AppThemePro.backgroundPrimary,
        borderRadius: BorderRadius.circular(_isSmallScreen ? 16 : 24),
        border: Border.all(
          color: AppThemePro.borderPrimary,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
          if (_hasChanges || _isEditing) _buildActionBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(_isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.primaryDark,
            AppThemePro.primaryMedium,
          ],
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_isSmallScreen ? 16 : 24),
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
        // Edit toggle
        _buildHeaderButton(
          icon: _isEditing ? Icons.edit_off : Icons.edit,
          tooltip: _isEditing ? 'Wyłącz edycję' : 'Włącz edycję',
          onPressed: () {
            setState(() {
              _isEditing = !_isEditing;
            });
            _triggerHapticFeedback();
          },
          isActive: _isEditing,
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

    return Tab(
      height: 60,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _isSmallScreen ? 8 : 16,
          vertical: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? tab.activeIcon : tab.icon,
              size: _isSmallScreen ? 18 : 20,
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: _isSmallScreen ? 10 : 12,
              ),
            ),
          ],
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
    return Column(
      children: [
        _buildInvestmentsToolbar(),
        Expanded(child: _buildInvestmentsList()),
      ],
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
          // Search bar
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

          // Filters
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
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
          onTap: () => _navigateToInvestmentDetails(investment),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
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
                    if (_isEditing)
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
                ),

                const SizedBox(height: 16),

                // Financial data
                Row(
                  children: [
                    Expanded(
                      child: _buildFinancialDataItem(
                        'Kwota inwestycji',
                        CurrencyFormatter.formatCurrency(
                          investment.investmentAmount,
                        ),
                        AppThemePro.bondsBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFinancialDataItem(
                        'Kapitał pozostały',
                        CurrencyFormatter.formatCurrency(
                          investment.remainingCapital,
                        ),
                        AppThemePro.profitGreen,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildFinancialDataItem(
                        'Status',
                        investment.status.displayName,
                        AppThemePro.getStatusColor(investment.status.name),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFinancialDataItem(
                        'Typ rynku',
                        investment.marketType.displayName,
                        AppThemePro.neutralGray,
                      ),
                    ),
                  ],
                ),

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
      padding: EdgeInsets.all(_isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(_isSmallScreen ? 16 : 24),
        ),
        border: Border(
          top: BorderSide(
            color: AppThemePro.borderPrimary,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (_hasChanges) ...[
            Icon(
              Icons.edit,
              color: AppThemePro.accentGold,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Masz niezapisane zmiany',
              style: TextStyle(
                color: AppThemePro.accentGold,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const Spacer(),
          TextButton(
            onPressed: _isLoading ? null : _closeDialog,
            child: const Text('Anuluj'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveChanges,
            icon: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        AppThemePro.primaryDark,
                      ),
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_isLoading ? 'Zapisywanie...' : 'Zapisz zmiany'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemePro.accentGold,
              foregroundColor: AppThemePro.primaryDark,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
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