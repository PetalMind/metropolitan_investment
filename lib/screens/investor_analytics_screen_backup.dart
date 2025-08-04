import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models_and_services.dart';
import '../services/investor_analytics/investor_analytics.dart';
import '../services/firebase_functions_analytics_service.dart' as premium;
import '../widgets/investor_analytics/investor_analytics.dart';
import '../providers/investor_analytics_provider.dart';
import '../utils/voting_analysis_manager.dart';

/// ✨ ENHANCED INVESTOR ANALYTICS SCREEN
/// Ulepszony ekran analityki inwestorów z funkcjami z premium wersji:
/// • 🗳️ Analiza głosowania w czasie rzeczywistym
/// • 📊 Zaawansowane statystyki i trendy
/// • 🎯 Analiza większościowej kontroli kapitału
/// • ⚡ Optymalizowane ładowanie z cache
/// • 📈 Inteligentne filtry i sortowanie
/// • 💎 Professional UI/UX z mikro-animacjami
/// • 🚀 Performance-first architecture
/// • 📱 Responsive design dla wszystkich urządzeń
class InvestorAnalyticsScreen extends StatefulWidget {
  const InvestorAnalyticsScreen({super.key});

  @override
  State<InvestorAnalyticsScreen> createState() =>
      _InvestorAnalyticsScreenState();
}

class _InvestorAnalyticsScreenState extends State<InvestorAnalyticsScreen>
    with TickerProviderStateMixin {
  // 🚀 CORE SERVICES - Dual Service Architecture
  final premium.FirebaseFunctionsAnalyticsService _premiumAnalyticsService =
      premium.FirebaseFunctionsAnalyticsService();
  final VotingAnalysisManager _votingManager = VotingAnalysisManager();

  // 🎨 ANIMATION CONTROLLERS
  late AnimationController _filterAnimationController;
  late AnimationController _fabAnimationController;
  late AnimationController _statsAnimationController;
  late Animation<Offset> _filterSlideAnimation;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _statsOpacityAnimation;

  // 🎛️ UI CONTROLLERS
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  final TextEditingController _companyFilterController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 📊 ENHANCED DATA STATE
  List<InvestorSummary> _allInvestors = [];
  List<InvestorSummary> _majorityHolders = [];
  premium.InvestorAnalyticsResult? _currentResult;

  // 🗳️ VOTING ANALYSIS STATE
  Map<VotingStatus, double> _votingDistribution = {};
  Map<VotingStatus, int> _votingCounts = {};
  double _majorityThreshold = 51.0;

  // ⚙️ LOADING & ERROR STATES
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  // 📄 ENHANCED PAGINATION
  int _currentPage = 0; // 0-based for consistency with existing pagination
  final int _pageSize = 100; // Smaller page size for better UX
  bool _hasNextPage = false;
  int _totalCount = 0;

  // 🎛️ ADVANCED FILTERS (from premium)
  String _sortBy = 'viableCapital';
  bool _sortAscending = false;
  VotingStatus? _selectedVotingStatus;
  ClientType? _selectedClientType;
  bool _includeInactive = false;
  bool _showOnlyWithUnviableInvestments = false;
  bool _showOnlyMajorityHolders = false;
  double _minCapitalFilter = 0.0;
  double _maxCapitalFilter = double.infinity;
  String _searchQuery = '';

  // 🖼️ VIEW CONFIGURATION
  bool _isFilterVisible = false;
  bool _usePremiumMode = false; // Toggle between local and Firebase Functions

  // ⚙️ PERFORMANCE OPTIMIZATION
  Timer? _searchDebounceTimer;
  Timer? _refreshTimer;
  static const Duration _searchDebounceDelay = Duration(milliseconds: 300);
  static const Duration _refreshInterval = Duration(minutes: 5);

  // 📱 RESPONSIVE BREAKPOINTS
  bool get _isTablet => MediaQuery.of(context).size.width > 768;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupControllers();
    _startPeriodicRefresh();
    _loadInitialData();
  }

  @override
  void dispose() {
    _disposeControllers();
    _searchDebounceTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // 🎨 INITIALIZATION METHODS

  void _initializeAnimations() {
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _filterSlideAnimation =
        Tween<Offset>(
          begin: const Offset(0.0, -1.0),
          end: const Offset(0.0, 0.0),
        ).animate(
          CurvedAnimation(
            parent: _filterAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _statsOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _statsAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start initial animations
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _fabAnimationController.forward();
        _statsAnimationController.forward();
      }
    });
  }

  void _setupControllers() {
    // Enhanced debounced search
    _searchController.addListener(_onSearchChanged);
    _minAmountController.addListener(_onFilterChanged);
    _maxAmountController.addListener(_onFilterChanged);
    _companyFilterController.addListener(_onFilterChanged);
    _scrollController.addListener(_onScroll);
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted && !_isLoading) {
        _refreshData();
      }
    });
  }

  void _disposeControllers() {
    _filterAnimationController.dispose();
    _fabAnimationController.dispose();
    _statsAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _companyFilterController.dispose();
  }

  // 🔄 EVENT HANDLERS

  void _onSearchChanged() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounceDelay, () {
      if (mounted && _searchController.text != _searchQuery) {
        setState(() {
          _searchQuery = _searchController.text;
          _currentPage = 0;
        });
        _loadData();
      }
    });
  }

  void _onFilterChanged() {
    // Debounced filter updates
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounceDelay, () {
      if (mounted) {
        setState(() {
          _minCapitalFilter = double.tryParse(_minAmountController.text) ?? 0.0;
          _maxCapitalFilter =
              double.tryParse(_maxAmountController.text) ?? double.infinity;
          _currentPage = 0;
        });
        _loadData();
      }
    });
  }

  void _onScroll() {
    // Auto-load more when approaching bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  // 📊 DATA METHODS

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 0;
    });

    await _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      if (_usePremiumMode) {
        await _loadDataPremium();
      } else {
        await _loadDataStandard();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _handleAnalyticsError(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDataPremium() async {
    final result = await _premiumAnalyticsService.getOptimizedInvestorAnalytics(
      page: _currentPage + 1,
      pageSize: _pageSize,
      sortBy: _sortBy,
      sortAscending: _sortAscending,
      includeInactive: _includeInactive,
      votingStatusFilter: _selectedVotingStatus,
      clientTypeFilter: _selectedClientType,
      showOnlyWithUnviableInvestments: _showOnlyWithUnviableInvestments,
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
    );

    if (mounted) {
      setState(() {
        _currentResult = result;
        _allInvestors = result.allInvestors;
        _totalCount = result.totalCount;
        _hasNextPage = result.hasNextPage;
        _isLoading = false;
      });

      // Update voting analysis
      _votingManager.calculateVotingCapitalDistribution(_allInvestors);
      _calculateMajorityAnalysis();
      _calculateVotingAnalysis();
    }
  }

  Future<void> _loadDataStandard() async {
    final stateService = context.read<InvestorAnalyticsStateService>();
    await stateService.loadInvestorData();

    if (mounted) {
      setState(() {
        _allInvestors = stateService.allInvestors;
        _totalCount = stateService.filteredInvestors.length;
        _isLoading = false;
      });

      // Update voting analysis
      _votingManager.calculateVotingCapitalDistribution(_allInvestors);
      _calculateMajorityAnalysis();
      _calculateVotingAnalysis();
    }
  }

  Future<void> _loadMoreData() async {
    if (!_hasNextPage || _isLoading || !mounted) return;

    setState(() => _currentPage++);
    await _loadData();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    setState(() => _isRefreshing = true);

    try {
      await _loadInitialData();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _calculateMajorityAnalysis() {
    if (_allInvestors.isEmpty) return;

    final totalCapital = _allInvestors.fold<double>(
      0.0,
      (sum, investor) => sum + investor.viableRemainingCapital,
    );

    // Sort investors by capital descending
    final sortedInvestors = List<InvestorSummary>.from(_allInvestors);
    sortedInvestors.sort(
      (a, b) => b.viableRemainingCapital.compareTo(a.viableRemainingCapital),
    );

    // Find minimal group that creates majority (≥51%)
    _majorityHolders = [];
    double accumulatedCapital = 0.0;

    for (final investor in sortedInvestors) {
      _majorityHolders.add(investor);
      accumulatedCapital += investor.viableRemainingCapital;

      final accumulatedPercentage = totalCapital > 0
          ? (accumulatedCapital / totalCapital) * 100
          : 0.0;

      // When we reach 51%, stop
      if (accumulatedPercentage >= _majorityThreshold) {
        break;
      }
    }
  }

  void _calculateVotingAnalysis() {
    if (_allInvestors.isEmpty) return;

    _votingDistribution = {
      VotingStatus.yes: _votingManager.yesVotingPercentage,
      VotingStatus.no: _votingManager.noVotingPercentage,
      VotingStatus.abstain: _votingManager.abstainVotingPercentage,
      VotingStatus.undecided: _votingManager.undecidedVotingPercentage,
    };

    _votingCounts = {
      VotingStatus.yes: _allInvestors
          .where((i) => i.client.votingStatus == VotingStatus.yes)
          .length,
      VotingStatus.no: _allInvestors
          .where((i) => i.client.votingStatus == VotingStatus.no)
          .length,
      VotingStatus.abstain: _allInvestors
          .where((i) => i.client.votingStatus == VotingStatus.abstain)
          .length,
      VotingStatus.undecided: _allInvestors
          .where((i) => i.client.votingStatus == VotingStatus.undecided)
          .length,
    };
  }

  String _handleAnalyticsError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('cors')) {
      return 'Problem z CORS - uruchom aplikację przez Firebase Hosting';
    } else if (errorStr.contains('timeout')) {
      return 'Przekroczono czas oczekiwania - spróbuj ponownie';
    } else if (errorStr.contains('network')) {
      return 'Brak połączenia z internetem';
    } else {
      return 'Wystąpił błąd podczas ładowania danych: ${error.toString()}';
    }
  }

  void _toggleFilter() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
    });

    if (_isFilterVisible) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  void _resetFilters() {
    _searchController.clear();
    _minAmountController.clear();
    _maxAmountController.clear();
    _companyFilterController.clear();

    context.read<InvestorAnalyticsStateService>().resetFilters();
    _toggleFilter();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filtry zostały zresetowane'),
        duration: Duration(seconds: 2),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInvestorDetails(InvestorSummary investor) {
    showDialog(
      context: context,
      builder: (context) => InvestorDetailsDialog(
        investor: investor,
        analyticsService: InvestorAnalyticsService(),
        onUpdate: () {
          context.read<InvestorAnalyticsStateService>().loadInvestorData();
        },
      ),
    );
  }

  void _generateEmailList() {
    final stateService = context.read<InvestorAnalyticsStateService>();
    final selectedIds = stateService.filteredInvestors
        .where((inv) => inv.client.email.isNotEmpty)
        .map((inv) => inv.client.id)
        .toList();

    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brak inwestorów z adresami email w aktualnej liście'),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => EmailGeneratorDialog(
        analyticsService: InvestorAnalyticsService(),
        clientIds: selectedIds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InvestorAnalyticsProvider(
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        body: Consumer<InvestorAnalyticsStateService>(
          builder: (context, stateService, child) {
            if (_isLoading && _allInvestors.isEmpty) {
              return _buildLoadingView();
            }

            if (_error != null) {
              return _buildErrorView();
            }

            return _buildMainContent(stateService);
          },
        ),
        floatingActionButton: _buildEnhancedFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.secondaryGold),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _statsOpacityAnimation,
            child: const Text(
              'Ładowanie zaawansowanej analityki...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Wystąpił błąd',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Nieznany błąd',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _refreshData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Spróbuj ponownie'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryGold,
                    foregroundColor: AppTheme.backgroundPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _usePremiumMode = !_usePremiumMode;
                    _loadInitialData();
                  }),
                  icon: Icon(_usePremiumMode ? Icons.cloud_off : Icons.cloud),
                  label: Text(
                    _usePremiumMode ? 'Tryb lokalny' : 'Tryb premium',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.secondaryGold,
                    side: const BorderSide(color: AppTheme.secondaryGold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(InvestorAnalyticsStateService stateService) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.secondaryGold,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildEnhancedAppBar(stateService),
          _buildVotingAnalysisCard(),
          _buildMajorityControlCard(),
          if (_isFilterVisible) _buildFilterPanel(stateService),
          _buildInvestorsList(stateService),
          if (_hasNextPage) _buildLoadMoreButton(),
        ],
      ),
    );
  }

  Widget _buildEnhancedAppBar(InvestorAnalyticsStateService stateService) {
    return SliverAppBar(
      expandedHeight: _isTablet ? 220 : 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.backgroundSecondary,
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          children: [
            const Text(
              'Analityka Inwestorów',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_usePremiumMode) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryGold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: AppTheme.backgroundPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.backgroundSecondary,
                AppTheme.surfaceCard.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildStatsRow(),
                  if (_isTablet) ...[
                    const SizedBox(height: 12),
                    _buildQuickActions(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_usePremiumMode ? Icons.cloud : Icons.cloud_off),
          tooltip: _usePremiumMode ? 'Tryb Premium (Firebase)' : 'Tryb Lokalny',
          onPressed: () {
            setState(() {
              _usePremiumMode = !_usePremiumMode;
            });
            _loadInitialData();
          },
        ),
        IconButton(icon: const Icon(Icons.tune), onPressed: _toggleFilters),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
      ],
    );
  }

  Widget _buildStatsRow() {
    return FadeTransition(
      opacity: _statsOpacityAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Inwestorzy', _totalCount.toString(), Icons.people),
          _buildStatCard(
            'Kapitał',
            '${(_allInvestors.fold<double>(0, (sum, i) => sum + i.viableRemainingCapital) / 1000000).toStringAsFixed(1)}M',
            Icons.trending_up,
          ),
          _buildStatCard(
            'Większość',
            '${_majorityHolders.length}',
            Icons.gavel,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondaryGold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.secondaryGold, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionChip(
          'Wszyscy',
          !_showOnlyMajorityHolders,
          () => setState(() => _showOnlyMajorityHolders = false),
        ),
        _buildActionChip(
          'Większość',
          _showOnlyMajorityHolders,
          () => setState(() => _showOnlyMajorityHolders = true),
        ),
        _buildActionChip('Export', false, _exportData),
      ],
    );
  }

  Widget _buildActionChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondaryGold : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.secondaryGold : AppTheme.textSecondary,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppTheme.backgroundPrimary
                : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveAppBar(
    BuildContext context,
    bool isTablet,
    InvestorAnalyticsStateService stateService,
  ) {
    return SliverAppBar(
      expandedHeight: isTablet ? 200 : 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.backgroundSecondary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Analityka Inwestorów',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.backgroundSecondary, AppTheme.surfaceCard],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isTablet) ...[
                    Text(
                      'Zarządzanie portfelem inwestycyjnym',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  _buildQuickStats(stateService),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFilterVisible ? Icons.filter_list_off : Icons.filter_list,
            color: AppTheme.secondaryGold,
          ),
          onPressed: _toggleFilter,
          tooltip: _isFilterVisible ? 'Ukryj filtry' : 'Pokaż filtry',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.secondaryGold),
          color: AppTheme.surfaceCard,
          onSelected: (value) {
            switch (value) {
              case 'refresh':
                stateService.loadInvestorData();
                break;
              case 'export':
                _generateEmailList();
                break;
              case 'reset':
                _resetFilters();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'refresh',
              child: ListTile(
                leading: Icon(Icons.refresh, color: AppTheme.secondaryGold),
                title: Text(
                  'Odśwież dane',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.email, color: AppTheme.secondaryGold),
                title: Text(
                  'Generuj maile',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'reset',
              child: ListTile(
                leading: Icon(Icons.clear_all, color: AppTheme.secondaryGold),
                title: Text(
                  'Resetuj filtry',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(InvestorAnalyticsStateService stateService) {
    if (stateService.isLoading) {
      return const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.secondaryGold,
            ),
          ),
          SizedBox(width: 8),
          Text('Ładowanie...', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildQuickStatItem(
            '${stateService.filteredInvestors.length}',
            'Inwestorów',
            Icons.people,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildQuickStatItem(
            '${stateService.pageSize}',
            'Na stronie',
            Icons.view_list,
          ),
        ),
        if (stateService.majorityControlAnalysis?.hasControlGroup ?? false) ...[
          const SizedBox(width: 16),
          Expanded(
            child: _buildQuickStatItem(
              '${stateService.majorityControlAnalysis!.controlGroupCount}',
              'Do 51%',
              Icons.pie_chart,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickStatItem(String value, String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.secondaryGold),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildErrorView(InvestorAnalyticsStateService stateService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Wystąpił błąd',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              stateService.error ?? 'Nieznany błąd',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                stateService.loadInvestorData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryGold,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestorsList(
    InvestorAnalyticsStateService stateService,
    bool isTablet,
  ) {
    if (stateService.filteredInvestors.isEmpty && !stateService.isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: AppTheme.textSecondary.withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Brak inwestorów spełniających kryteria',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Spróbuj zmienić filtry wyszukiwania',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final currentPageData = stateService.currentPageData;
    final startIndex = stateService.currentPage * stateService.pageSize;

    switch (stateService.currentView) {
      case 'grid':
        return _buildInvestorsGrid(currentPageData, startIndex, stateService);
      case 'cards':
        return _buildInvestorsCards(currentPageData, startIndex, stateService);
      default:
        return _buildInvestorsList_Classic(
          currentPageData,
          startIndex,
          stateService,
        );
    }
  }

  Widget _buildInvestorsList_Classic(
    List<InvestorSummary> currentPageData,
    int startIndex,
    InvestorAnalyticsStateService stateService,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index < currentPageData.length) {
          final investor = currentPageData[index];
          final globalPosition = startIndex + index + 1;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InvestorCard(
              investor: investor,
              position: globalPosition,
              totalPortfolioValue: stateService.totalPortfolioValue,
              onTap: () => _showInvestorDetails(investor),
            ),
          );
        }
        return null;
      }, childCount: currentPageData.length),
    );
  }

  Widget _buildInvestorsGrid(
    List<InvestorSummary> currentPageData,
    int startIndex,
    InvestorAnalyticsStateService stateService,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index < currentPageData.length) {
            final investor = currentPageData[index];
            final globalPosition = startIndex + index + 1;
            return InvestorGridTile(
              investor: investor,
              position: globalPosition,
              totalPortfolioValue: stateService.totalPortfolioValue,
              onTap: () => _showInvestorDetails(investor),
            );
          }
          return null;
        }, childCount: currentPageData.length),
      ),
    );
  }

  Widget _buildInvestorsCards(
    List<InvestorSummary> currentPageData,
    int startIndex,
    InvestorAnalyticsStateService stateService,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index < currentPageData.length) {
          final investor = currentPageData[index];
          final globalPosition = startIndex + index + 1;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InvestorCompactCard(
              investor: investor,
              position: globalPosition,
              totalPortfolioValue: stateService.totalPortfolioValue,
              onTap: () => _showInvestorDetails(investor),
            ),
          );
        }
        return null;
      }, childCount: currentPageData.length),
    );
  }

  Widget _buildResponsiveFAB() {
    return Consumer<InvestorAnalyticsStateService>(
      builder: (context, stateService, child) {
        return ScaleTransition(
          scale: _fabScaleAnimation,
          child: FloatingActionButton.extended(
            onPressed: () => _showViewOptions(stateService),
            backgroundColor: AppTheme.secondaryGold,
            foregroundColor: Colors.white,
            icon: Icon(_getViewIcon(stateService.currentView)),
            label: Text(_getViewLabel(stateService.currentView)),
            tooltip: 'Zmień widok',
          ),
        );
      },
    );
  }

  void _showViewOptions(InvestorAnalyticsStateService stateService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildViewOptionsBottomSheet(stateService),
    );
  }

  Widget _buildViewOptionsBottomSheet(
    InvestorAnalyticsStateService stateService,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Opcje widoku',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildViewOption(
                    'Lista',
                    'list',
                    Icons.view_list,
                    stateService,
                  ),
                  _buildViewOption(
                    'Karty',
                    'cards',
                    Icons.view_agenda,
                    stateService,
                  ),
                  _buildViewOption(
                    'Kafelki',
                    'grid',
                    Icons.grid_view,
                    stateService,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewOption(
    String title,
    String viewType,
    IconData icon,
    InvestorAnalyticsStateService stateService,
  ) {
    final isSelected = stateService.currentView == viewType;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.secondaryGold : AppTheme.textSecondary,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.secondaryGold : AppTheme.textPrimary,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check, color: AppTheme.secondaryGold)
            : null,
        onTap: () {
          stateService.changeView(viewType);
          Navigator.pop(context);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isSelected
            ? AppTheme.secondaryGold.withOpacity(0.1)
            : Colors.transparent,
      ),
    );
  }

  IconData _getViewIcon(String currentView) {
    switch (currentView) {
      case 'cards':
        return Icons.view_agenda;
      case 'grid':
        return Icons.grid_view;
      default:
        return Icons.view_list;
    }
  }

  String _getViewLabel(String currentView) {
    switch (currentView) {
      case 'cards':
        return 'Karty';
      case 'grid':
        return 'Kafelki';
      default:
        return 'Lista';
    }
  }

  // 🎯 ENHANCED METHODS FROM PREMIUM

  Widget _buildEnhancedFAB() {
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: FloatingActionButton.extended(
        onPressed: _toggleFilters,
        backgroundColor: AppTheme.secondaryGold,
        foregroundColor: AppTheme.backgroundPrimary,
        icon: AnimatedRotation(
          turns: _isFilterVisible ? 0.5 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: const Icon(Icons.tune),
        ),
        label: Text(_isFilterVisible ? 'Ukryj filtry' : 'Filtry'),
      ),
    );
  }

  Widget _buildVotingAnalysisCard() {
    if (_votingDistribution.isEmpty) return const SliverToBoxAdapter();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: AppTheme.surfaceCard,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.how_to_vote,
                      color: AppTheme.secondaryGold,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Analiza Głosowania',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Voting distribution bars
                ..._votingDistribution.entries.map(
                  (entry) => _buildVotingBar(
                    entry.key,
                    entry.value,
                    _votingCounts[entry.key] ?? 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVotingBar(VotingStatus status, double percentage, int count) {
    final color = _getVotingStatusColor(status);
    final label = _getVotingStatusLabel(status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppTheme.backgroundTertiary,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${percentage.toStringAsFixed(1)}% ($count)',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return Colors.green;
      case VotingStatus.no:
        return Colors.red;
      case VotingStatus.abstain:
        return Colors.orange;
      case VotingStatus.undecided:
        return AppTheme.textSecondary;
    }
  }

  String _getVotingStatusLabel(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return 'Za';
      case VotingStatus.no:
        return 'Przeciw';
      case VotingStatus.abstain:
        return 'Wstrzym.';
      case VotingStatus.undecided:
        return 'Niezdec.';
    }
  }

  Widget _buildMajorityControlCard() {
    if (_majorityHolders.isEmpty) return const SliverToBoxAdapter();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: AppTheme.surfaceCard,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.gavel, color: AppTheme.secondaryGold),
                    const SizedBox(width: 8),
                    const Text(
                      'Kontrola Większościowa',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Minimalna grupa ${_majorityHolders.length} inwestorów kontroluje ≥51% kapitału',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                // Top majority holders
                ...(_majorityHolders
                    .take(3)
                    .map((investor) => _buildMajorityHolderTile(investor))),
                if (_majorityHolders.length > 3)
                  Text(
                    '... i ${_majorityHolders.length - 3} innych',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMajorityHolderTile(InvestorSummary investor) {
    final totalCapital = _allInvestors.fold<double>(
      0.0,
      (sum, i) => sum + i.viableRemainingCapital,
    );
    final percentage = totalCapital > 0
        ? (investor.viableRemainingCapital / totalCapital) * 100
        : 0.0;

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor: AppTheme.secondaryGold,
        child: Text(
          investor.client.imieNazwisko.isNotEmpty
              ? investor.client.imieNazwisko[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: AppTheme.backgroundPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        investor.client.imieNazwisko,
        style: const TextStyle(color: AppTheme.textPrimary),
      ),
      trailing: Text(
        '${percentage.toStringAsFixed(1)}%',
        style: const TextStyle(
          color: AppTheme.secondaryGold,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFilterPanel(InvestorAnalyticsStateService stateService) {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _filterSlideAnimation,
        child: InvestorFilterPanel(
          searchController: _searchController,
          minAmountController: _minAmountController,
          maxAmountController: _maxAmountController,
          companyFilterController: _companyFilterController,
          selectedVotingStatus: stateService.selectedVotingStatus,
          selectedClientType: stateService.selectedClientType,
          includeInactive: stateService.includeInactive,
          showOnlyWithUnviableInvestments:
              stateService.showOnlyWithUnviableInvestments,
          sortBy: stateService.sortBy,
          sortAscending: stateService.sortAscending,
          isTablet: _isTablet,
          onVotingStatusChanged: (status) {
            stateService.updateVotingStatus(status);
          },
          onClientTypeChanged: (type) {
            stateService.updateClientType(type);
          },
          onIncludeInactiveChanged: (include) {
            stateService.toggleIncludeInactive();
          },
          onShowUnviableChanged: (show) {
            stateService.toggleShowOnlyUnviable();
          },
          onSortChanged: (sortBy) {
            stateService.changeSortOrder(sortBy);
          },
          onResetFilters: _resetFilters,
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _loadMoreData,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.expand_more),
            label: Text(_isLoading ? 'Ładowanie...' : 'Załaduj więcej'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surfaceCard,
              foregroundColor: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  void _toggleFilters() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
    });

    if (_isFilterVisible) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  void _exportData() {
    // TODO: Implement data export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funkcja eksportu będzie dostępna wkrótce'),
        backgroundColor: AppTheme.secondaryGold,
      ),
    );
  }

  void _resetFilters() {
    _searchController.clear();
    _minAmountController.clear();
    _maxAmountController.clear();
    _companyFilterController.clear();

    setState(() {
      _selectedVotingStatus = null;
      _selectedClientType = null;
      _includeInactive = true;
      _showOnlyWithUnviableInvestments = false;
      _minCapitalFilter = 0.0;
      _maxCapitalFilter = double.infinity;
      _searchQuery = '';
      _currentPage = 0;
    });

    _loadData();
  }
}
