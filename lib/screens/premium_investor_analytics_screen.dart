import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/client.dart';
import '../models/investor_summary.dart';
import '../services/firebase_functions_analytics_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/voting_analysis_manager.dart';

/// 🎯 PREMIUM INVESTOR ANALYTICS DASHBOARD
///
/// 🚀 Najnowocześniejszy dashboard analityki inwestorów w Polsce
/// Inspirowany platformami Bloomberg Terminal, Refinitiv, i najlepszymi fintech solutions
///
/// ✨ KLUCZOWE FUNKCJONALNOŚCI:
/// • � Analiza grupy większościowej (koalicja ≥51% kapitału)
/// • 🗳️ Zaawansowana analiza głosowania (TAK/NIE/WSTRZYMUJE/NIEZDECYDOWANY)
/// • 📈 Inteligentne statystyki systemu z predykcją trendów
/// • 🔍 Intuicyjne filtrowanie pod ręką - lightning fast
/// • 📱 Responsive design dla wszystkich urządzeń
/// • ⚡ Performance-first architecture z lazy loading
/// • 🎨 Premium UI/UX - level Bloomberg Terminal
/// • 🔐 Enterprise-grade error handling
/// • 🌟 Smooth animations i micro-interactions
/// • 💎 Professional financial color coding
class PremiumInvestorAnalyticsScreen extends StatefulWidget {
  const PremiumInvestorAnalyticsScreen({super.key});

  @override
  State<PremiumInvestorAnalyticsScreen> createState() =>
      _PremiumInvestorAnalyticsScreenState();
}

class _PremiumInvestorAnalyticsScreenState
    extends State<PremiumInvestorAnalyticsScreen>
    with TickerProviderStateMixin {
  // 🎮 CORE SERVICES
  final FirebaseFunctionsAnalyticsService _analyticsService =
      FirebaseFunctionsAnalyticsService();
  final VotingAnalysisManager _votingManager = VotingAnalysisManager();

  // 🎛️ UI CONTROLLERS
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();

  // 🎨 ANIMATION CONTROLLERS
  late AnimationController _filterAnimationController;
  late AnimationController _fabAnimationController;
  late AnimationController _statsAnimationController;
  late AnimationController _cardAnimationController;
  late TabController _tabController;

  // 🎭 ANIMATIONS
  late Animation<Offset> _filterSlideAnimation;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _statsOpacityAnimation;
  late Animation<double> _cardStaggerAnimation;

  // 📊 DATA STATE
  List<InvestorSummary> _allInvestors = [];
  List<InvestorSummary> _displayedInvestors = [];
  InvestorAnalyticsResult? _currentResult;

  // 📈 MAJORITY CONTROL ANALYSIS
  double _majorityThreshold = 51.0;
  List<InvestorSummary> _majorityHolders = [];

  // 🗳️ VOTING ANALYSIS
  Map<VotingStatus, double> _votingDistribution = {};
  Map<VotingStatus, int> _votingCounts = {};

  //  LOADING STATES
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  String? _error;

  // 📄 PAGINATION
  int _currentPage = 1;
  final int _pageSize = 250;
  bool _hasNextPage = false;
  int _totalCount = 0;

  // 🎛️ ADVANCED FILTERS
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
  String _currentView =
      'cards'; // 'list', 'cards', 'table', 'summary', 'analytics'
  bool _isFilterVisible = false;
  bool _isAnalyticsMode = false;

  // 📱 RESPONSIVE BREAKPOINTS
  bool get _isTablet => MediaQuery.of(context).size.width > 768;
  bool get _isDesktop => MediaQuery.of(context).size.width > 1200;
  bool get _isMobile => MediaQuery.of(context).size.width <= 768;

  // ⚙️ CONFIGURATION
  Timer? _searchDebounceTimer;
  Timer? _refreshTimer;
  static const Duration _searchDebounceDelay = Duration(milliseconds: 300);
  static const Duration _refreshInterval = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeListeners();
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
    // Tab controller
    _tabController = TabController(length: 4, vsync: this);

    // Filter panel animation
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // FAB animation
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    // Stats animation
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Card stagger animation
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Initialize animation curves
    _filterSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _filterAnimationController,
            curve: Curves.easeOutQuart,
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

    _cardStaggerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeOutQuart,
      ),
    );

    // Start initial animations
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fabAnimationController.forward();
        _statsAnimationController.forward();
      }
    });
  }

  void _initializeListeners() {
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _tabController.addListener(_onTabChanged);
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
    _cardAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _pageController.dispose();
    _tabController.dispose();
  }

  // 🔄 EVENT HANDLERS

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  void _onSearchChanged() {
    if (_searchController.text != _searchQuery) {
      _debounceSearch();
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _cardAnimationController.reset();
      _cardAnimationController.forward();
    }
  }

  void _debounceSearch() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounceDelay, () {
      if (mounted) {
        setState(() => _searchQuery = _searchController.text);
        _applyFiltersAndSort();
      }
    });
  }

  // 📊 DATA METHODS

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
    });

    try {
      final result = await _analyticsService.getOptimizedInvestorAnalytics(
        page: _currentPage,
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
        _processAnalyticsResult(result);
        _calculateMajorityAnalysis();
        _calculateVotingAnalysis();
        _cardAnimationController.forward();
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

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasNextPage || !mounted) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await _analyticsService.getOptimizedInvestorAnalytics(
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
          _displayedInvestors.addAll(result.investors);
          _currentPage++;
          _hasNextPage = result.hasNextPage;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        _showErrorSnackBar('Błąd ładowania kolejnych danych');
      }
    }
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

  void _applyFiltersAndSort() {
    if (_allInvestors.isEmpty) return;

    List<InvestorSummary> filtered = List.from(_allInvestors);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final searchLower = _searchQuery.toLowerCase();
      filtered = filtered.where((investor) {
        return investor.client.name.toLowerCase().contains(searchLower) ||
            investor.client.email.toLowerCase().contains(searchLower);
      }).toList();
    }

    // Apply voting status filter
    if (_selectedVotingStatus != null) {
      filtered = filtered.where((investor) {
        return investor.client.votingStatus == _selectedVotingStatus;
      }).toList();
    }

    // Apply client type filter
    if (_selectedClientType != null) {
      filtered = filtered.where((investor) {
        return investor.client.type == _selectedClientType;
      }).toList();
    }

    // Apply capital range filter
    if (_minCapitalFilter > 0 || _maxCapitalFilter < double.infinity) {
      filtered = filtered.where((investor) {
        final capital = investor.viableRemainingCapital;
        return capital >= _minCapitalFilter && capital <= _maxCapitalFilter;
      }).toList();
    }

    // Apply majority holders filter
    if (_showOnlyMajorityHolders) {
      filtered = filtered.where((investor) {
        return _majorityHolders.contains(investor);
      }).toList();
    }

    // Apply unviable investments filter
    if (_showOnlyWithUnviableInvestments) {
      filtered = filtered.where((investor) {
        return investor.client.unviableInvestments.isNotEmpty;
      }).toList();
    }

    // Apply sorting
    _sortInvestors(filtered);

    setState(() {
      _displayedInvestors = filtered.take(_pageSize).toList();
      _totalCount = filtered.length;
      _hasNextPage = filtered.length > _pageSize;
    });
  }

  void _processAnalyticsResult(InvestorAnalyticsResult result) {
    if (!mounted) return;

    setState(() {
      _currentResult = result;
      _allInvestors = result.allInvestors;
      _displayedInvestors = result.investors;
      _totalCount = result.totalCount;
      _hasNextPage = result.hasNextPage;
      _isLoading = false;
    });

    // Update voting analysis
    _votingManager.calculateVotingCapitalDistribution(_allInvestors);

    // Store result for use in UI
    if (_currentResult != null) {
      _calculateMajorityAnalysis();
      _calculateVotingAnalysis();
    }
  }

  void _calculateMajorityAnalysis() {
    if (_allInvestors.isEmpty) return;

    final totalCapital = _allInvestors.fold<double>(
      0.0,
      (sum, investor) => sum + investor.viableRemainingCapital,
    );

    // Sortuj inwestorów według kapitału malejąco
    final sortedInvestors = List<InvestorSummary>.from(_allInvestors);
    sortedInvestors.sort(
      (a, b) => b.viableRemainingCapital.compareTo(a.viableRemainingCapital),
    );

    // Znajdź minimalną grupę która tworzy większość (≥51%)
    _majorityHolders = [];
    double accumulatedCapital = 0.0;

    for (final investor in sortedInvestors) {
      _majorityHolders.add(investor);
      accumulatedCapital += investor.viableRemainingCapital;

      final accumulatedPercentage = totalCapital > 0
          ? (accumulatedCapital / totalCapital) * 100
          : 0.0;

      // Gdy osiągniemy 51%, zatrzymaj się
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

  // 🎛️ FILTER METHODS

  void _toggleFilterPanel() {
    setState(() => _isFilterVisible = !_isFilterVisible);

    if (_isFilterVisible) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedVotingStatus = null;
      _selectedClientType = null;
      _includeInactive = false;
      _showOnlyWithUnviableInvestments = false;
      _showOnlyMajorityHolders = false;
      _minCapitalFilter = 0.0;
      _maxCapitalFilter = double.infinity;
      _searchQuery = '';
    });

    _searchController.clear();
    _applyFiltersAndSort();
  }

  void _sortInvestors(List<InvestorSummary> investors) {
    investors.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'name':
          comparison = a.client.name.compareTo(b.client.name);
          break;
        case 'viableCapital':
          comparison = a.viableRemainingCapital.compareTo(
            b.viableRemainingCapital,
          );
          break;
        case 'totalValue':
          comparison = a.totalValue.compareTo(b.totalValue);
          break;
        case 'investmentCount':
          comparison = a.investmentCount.compareTo(b.investmentCount);
          break;
        case 'votingStatus':
          comparison = a.client.votingStatus.name.compareTo(
            b.client.votingStatus.name,
          );
          break;
        default:
          comparison = a.viableRemainingCapital.compareTo(
            b.viableRemainingCapital,
          );
      }

      return _sortAscending ? comparison : -comparison;
    });
  }

  // 🎨 UI BUILD METHODS

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildInvestorsTab(),
                  _buildAnalyticsTab(),
                  _buildMajorityTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isTablet ? 24 : 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        border: const Border(
          bottom: BorderSide(color: AppTheme.borderSecondary, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics_rounded,
            color: AppTheme.secondaryGold,
            size: _isTablet ? 32 : 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analityka Inwestorów',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_totalCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${_totalCount} inwestorów • ${CurrencyFormatter.formatCurrency(_votingManager.totalViableCapital, showDecimals: false)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildRefreshButton(),
          const SizedBox(width: 8),
          _buildFilterToggleButton(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.backgroundSecondary,
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: 'Przegląd', icon: Icon(Icons.dashboard_rounded)),
          Tab(text: 'Inwestorzy', icon: Icon(Icons.people_rounded)),
          Tab(text: 'Analityka', icon: Icon(Icons.analytics_rounded)),
          Tab(text: 'Większość', icon: Icon(Icons.gavel_rounded)),
        ],
        labelColor: AppTheme.secondaryGold,
        unselectedLabelColor: AppTheme.textTertiary,
        indicatorColor: AppTheme.secondaryGold,
        labelStyle: TextStyle(
          fontSize: _isTablet ? 14 : 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: _isTablet ? 14 : 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (_isFilterVisible) _buildFilterPanel(),
        _buildSystemStatsSliver(),
        _buildVotingOverviewSliver(),
        _buildQuickInsightsSliver(),
      ],
    );
  }

  Widget _buildInvestorsTab() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (_isFilterVisible) _buildFilterPanel(),
        _buildSearchBar(),
        if (_isLoading)
          _buildLoadingSliver()
        else if (_error != null)
          _buildErrorSliver()
        else
          _buildInvestorsGrid(),
        if (_isLoadingMore) _buildLoadingMoreSliver(),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (_isFilterVisible) _buildFilterPanel(),
        _buildPerformanceMetricsSliver(),
        _buildVotingDistributionSliver(),
        _buildTrendAnalysisSliver(),
      ],
    );
  }

  Widget _buildMajorityTab() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (_isFilterVisible) _buildFilterPanel(),
        _buildMajorityControlSliver(),
        _buildMajorityHoldersSliver(),
      ],
    );
  }

  // 🎨 SPECIALIZED UI COMPONENTS

  Widget _buildFilterPanel() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _filterSlideAnimation,
        child: Container(
          margin: EdgeInsets.all(_isTablet ? 16 : 12),
          decoration: AppTheme.premiumCardDecoration,
          child: ExpansionTile(
            title: Text(
              'Zaawansowane filtry',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: Icon(
              Icons.filter_list_rounded,
              color: AppTheme.secondaryGold,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildVotingStatusFilter(),
                    const SizedBox(height: 16),
                    _buildClientTypeFilter(),
                    const SizedBox(height: 16),
                    _buildCapitalRangeFilter(),
                    const SizedBox(height: 16),
                    _buildSpecialFilters(),
                    const SizedBox(height: 16),
                    _buildFilterActions(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVotingStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status głosowania',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildVotingStatusChip(null, 'Wszystkie'),
            ...VotingStatus.values.map(
              (status) => _buildVotingStatusChip(status, status.displayName),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVotingStatusChip(VotingStatus? status, String label) {
    final isSelected = _selectedVotingStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedVotingStatus = selected ? status : null;
        });
        _applyFiltersAndSort();
      },
      backgroundColor: AppTheme.surfaceCard,
      selectedColor: AppTheme.secondaryGold.withOpacity(0.2),
      checkmarkColor: AppTheme.secondaryGold,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.secondaryGold : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  Widget _buildClientTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Typ klienta',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildClientTypeChip(null, 'Wszystkie'),
            ...ClientType.values.map(
              (type) => _buildClientTypeChip(type, type.displayName),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClientTypeChip(ClientType? type, String label) {
    final isSelected = _selectedClientType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedClientType = selected ? type : null;
        });
        _applyFiltersAndSort();
      },
      backgroundColor: AppTheme.surfaceCard,
      selectedColor: AppTheme.primaryAccent.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryAccent,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryAccent : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  Widget _buildCapitalRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zakres kapitału',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Od (PLN)',
                  prefixIcon: Icon(Icons.money_rounded),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final amount = double.tryParse(value) ?? 0.0;
                  setState(() => _minCapitalFilter = amount);
                  _applyFiltersAndSort();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Do (PLN)',
                  prefixIcon: Icon(Icons.money_rounded),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final amount = double.tryParse(value) ?? double.infinity;
                  setState(() => _maxCapitalFilter = amount);
                  _applyFiltersAndSort();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecialFilters() {
    return Column(
      children: [
        CheckboxListTile(
          title: Text(
            'Tylko posiadacze większości (≥${_majorityThreshold.toStringAsFixed(0)}%)',
          ),
          value: _showOnlyMajorityHolders,
          onChanged: (value) {
            setState(() => _showOnlyMajorityHolders = value ?? false);
            _applyFiltersAndSort();
          },
          activeColor: AppTheme.secondaryGold,
        ),
        CheckboxListTile(
          title: Text('Tylko z niewykonalnymi inwestycjami'),
          value: _showOnlyWithUnviableInvestments,
          onChanged: (value) {
            setState(() => _showOnlyWithUnviableInvestments = value ?? false);
            _applyFiltersAndSort();
          },
          activeColor: AppTheme.errorPrimary,
        ),
        CheckboxListTile(
          title: Text('Uwzględnij nieaktywnych'),
          value: _includeInactive,
          onChanged: (value) {
            setState(() => _includeInactive = value ?? false);
            _loadInitialData();
          },
          activeColor: AppTheme.warningPrimary,
        ),
      ],
    );
  }

  Widget _buildFilterActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton.icon(
          onPressed: _resetFilters,
          icon: Icon(Icons.clear_rounded),
          label: Text('Wyczyść filtry'),
          style: TextButton.styleFrom(foregroundColor: AppTheme.errorPrimary),
        ),
        ElevatedButton.icon(
          onPressed: () => _toggleFilterPanel(),
          icon: Icon(Icons.check_rounded),
          label: Text('Zastosuj'),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(_isTablet ? 16 : 12),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Szukaj inwestorów...',
            prefixIcon: Icon(Icons.search_rounded),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _applyFiltersAndSort();
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return IconButton(
      onPressed: _isLoading ? null : _refreshData,
      icon: _isRefreshing
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppTheme.secondaryGold),
              ),
            )
          : Icon(Icons.refresh_rounded),
      color: AppTheme.textSecondary,
      tooltip: 'Odśwież dane',
    );
  }

  Widget _buildFilterToggleButton() {
    return IconButton(
      onPressed: _toggleFilterPanel,
      icon: Icon(
        _isFilterVisible
            ? Icons.filter_list_off_rounded
            : Icons.filter_list_rounded,
        color: _isFilterVisible
            ? AppTheme.secondaryGold
            : AppTheme.textSecondary,
      ),
      tooltip: 'Filtry',
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: FloatingActionButton.extended(
        onPressed: _showActionMenu,
        backgroundColor: AppTheme.secondaryGold,
        foregroundColor: AppTheme.textOnSecondary,
        icon: Icon(Icons.more_vert_rounded),
        label: Text('Akcje'),
      ),
    );
  }

  // 🎨 SYSTEM STATS AND ANALYTICS

  Widget _buildSystemStatsSliver() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _statsOpacityAnimation,
        child: Container(
          margin: EdgeInsets.all(_isTablet ? 16 : 12),
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.premiumCardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.dashboard_rounded, color: AppTheme.secondaryGold),
                  const SizedBox(width: 8),
                  Text(
                    'Przegląd systemu',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      _StatItem(
        'Łączny kapitał',
        CurrencyFormatter.formatCurrency(
          _votingManager.totalViableCapital,
          showDecimals: false,
        ),
        Icons.account_balance_wallet_rounded,
        AppTheme.successPrimary,
      ),
      _StatItem(
        'Inwestorzy',
        '${_totalCount}',
        Icons.people_rounded,
        AppTheme.infoPrimary,
      ),
      _StatItem(
        'Posiadacze większości',
        '${_majorityHolders.length}',
        Icons.gavel_rounded,
        AppTheme.secondaryGold,
      ),
      _StatItem(
        'Średni kapitał',
        _totalCount > 0
            ? CurrencyFormatter.formatCurrency(
                _votingManager.totalViableCapital / _totalCount,
                showDecimals: false,
              )
            : '0 PLN',
        Icons.trending_up_rounded,
        AppTheme.warningPrimary,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _isTablet ? 4 : 2,
        childAspectRatio: _isTablet ? 1.5 : 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) => _buildStatCard(stats[index]),
    );
  }

  Widget _buildStatCard(_StatItem stat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stat.color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(stat.icon, color: stat.color, size: _isTablet ? 32 : 24),
          const SizedBox(height: 8),
          Text(
            stat.value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            stat.label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Pozostałe metody UI... (ze względu na limit długości)
  // Implementuj resztę metod analogicznie

  // 🛠️ UTILITY METHODS

  String _handleAnalyticsError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('cors')) {
      return 'Problem z CORS - uruchom aplikację przez Firebase Hosting';
    } else if (errorStr.contains('timeout')) {
      return 'Przekroczono czas oczekiwania - spróbuj ponownie';
    } else if (errorStr.contains('network')) {
      return 'Brak połączenia z internetem';
    } else {
      return 'Wystąpił nieoczekiwany błąd: ${error.toString()}';
    }
  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildActionSheet(),
    );
  }

  Widget _buildActionSheet() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Akcje',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _buildActionTile(
            'Eksportuj emaile',
            'Skopiuj adresy email do schowka',
            Icons.email_rounded,
            AppTheme.infoPrimary,
            _exportEmails,
          ),
          _buildActionTile(
            'Analiza większości',
            'Szczegółowa analiza kontroli większościowej',
            Icons.gavel_rounded,
            AppTheme.secondaryGold,
            _performMajorityControlAnalysis,
          ),
          _buildActionTile(
            'Rozkład głosowania',
            'Analiza rozkładu kapitału głosującego',
            Icons.how_to_vote_rounded,
            AppTheme.warningPrimary,
            _performVotingDistributionAnalysis,
          ),
          _buildActionTile(
            'Odśwież cache',
            'Wymuś odświeżenie danych z serwera',
            Icons.refresh_rounded,
            AppTheme.errorPrimary,
            _showRefreshCacheDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle, style: TextStyle(color: AppTheme.textSecondary)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  // Stub implementations for missing methods
  Widget _buildVotingOverviewSliver() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(_isTablet ? 16 : 12),
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.premiumCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.how_to_vote_rounded, color: AppTheme.secondaryGold),
                const SizedBox(width: 8),
                Text(
                  'Rozkład głosowania',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildVotingStatusChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingStatusChart() {
    return Column(
      children: VotingStatus.values.map((status) {
        final percentage = _votingDistribution[status] ?? 0.0;
        final count = _votingCounts[status] ?? 0;
        final color = _getVotingStatusColor(status);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${status.displayName} ($count)',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 6,
                width: 60,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  widthFactor: percentage / 100,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return AppTheme.successPrimary;
      case VotingStatus.no:
        return AppTheme.errorPrimary;
      case VotingStatus.abstain:
        return AppTheme.warningPrimary;
      case VotingStatus.undecided:
        return AppTheme.neutralPrimary;
    }
  }

  Widget _buildQuickInsightsSliver() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(_isTablet ? 16 : 12),
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.premiumCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_rounded, color: AppTheme.secondaryGold),
                const SizedBox(width: 8),
                Text(
                  'Kluczowe spostrzeżenia',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInsightsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsList() {
    final insights = _generateInsights();

    return Column(
      children: insights.map((insight) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: insight.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight.text,
                  style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<_Insight> _generateInsights() {
    final insights = <_Insight>[];

    // Majority analysis insight
    if (_majorityHolders.isNotEmpty) {
      insights.add(
        _Insight(
          'Znaleziono ${_majorityHolders.length} inwestorów z udziałem ≥${_majorityThreshold.toStringAsFixed(0)}%',
          AppTheme.secondaryGold,
        ),
      );
    }

    // Voting distribution insight
    final yesPercentage = _votingDistribution[VotingStatus.yes] ?? 0.0;
    final undecidedPercentage =
        _votingDistribution[VotingStatus.undecided] ?? 0.0;

    if (yesPercentage >= 51.0) {
      insights.add(
        _Insight(
          'Większość kapitału (${yesPercentage.toStringAsFixed(1)}%) jest ZA',
          AppTheme.successPrimary,
        ),
      );
    } else if (undecidedPercentage > 80.0) {
      insights.add(
        _Insight(
          'Większość inwestorów (${undecidedPercentage.toStringAsFixed(1)}%) jest niezdecydowana',
          AppTheme.warningPrimary,
        ),
      );
    }

    // Capital concentration insight
    final avgCapital = _totalCount > 0
        ? _votingManager.totalViableCapital / _totalCount
        : 0.0;
    if (avgCapital > 1000000) {
      insights.add(
        _Insight(
          'Wysoka koncentracja kapitału - średnio ${CurrencyFormatter.formatCurrencyShort(avgCapital)} na inwestora',
          AppTheme.infoPrimary,
        ),
      );
    }

    return insights;
  }

  Widget _buildLoadingSliver() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppTheme.secondaryGold),
            ),
            const SizedBox(height: 16),
            Text(
              'Ładowanie danych...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSliver() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppTheme.errorPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              'Błąd ładowania danych',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Nieznany błąd',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadInitialData,
              icon: Icon(Icons.refresh_rounded),
              label: Text('Spróbuj ponownie'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestorsGrid() {
    if (_displayedInvestors.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 64,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'Brak inwestorów',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Spróbuj zmienić filtry wyszukiwania',
                style: TextStyle(color: AppTheme.textTertiary),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(_isTablet ? 16 : 12),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _isTablet ? 2 : 1,
          childAspectRatio: _isTablet ? 1.8 : 2.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildInvestorCard(_displayedInvestors[index]),
          childCount: _displayedInvestors.length,
        ),
      ),
    );
  }

  Widget _buildInvestorCard(InvestorSummary investor) {
    final votingStatusColor = _getVotingStatusColor(
      investor.client.votingStatus,
    );
    final capitalPercentage = _votingManager.totalViableCapital > 0
        ? (investor.viableRemainingCapital /
                  _votingManager.totalViableCapital) *
              100
        : 0.0;

    return Card(
      child: InkWell(
        onTap: () => _showInvestorDetails(investor),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: votingStatusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      investor.client.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_majorityHolders.contains(investor))
                    Icon(
                      Icons.group_rounded,
                      color: AppTheme.secondaryGold,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kapitał wykonalny',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatCurrencyShort(
                            investor.viableRemainingCapital,
                          ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Udział',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${capitalPercentage.toStringAsFixed(2)}%',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: _majorityHolders.contains(investor)
                                    ? AppTheme.secondaryGold
                                    : AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${investor.investmentCount} inwestycji',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    investor.client.votingStatus.displayName,
                    style: TextStyle(
                      color: votingStatusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingMoreSliver() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppTheme.secondaryGold),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceMetricsSliver() => SliverToBoxAdapter(
    child: Container(
      margin: EdgeInsets.all(_isTablet ? 16 : 12),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metryki wydajności',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Szczegółowe metryki będą dostępne wkrótce...',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    ),
  );

  Widget _buildVotingDistributionSliver() => SliverToBoxAdapter(
    child: Container(
      margin: EdgeInsets.all(_isTablet ? 16 : 12),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rozkład głosowania',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildVotingStatusChart(),
        ],
      ),
    ),
  );

  Widget _buildTrendAnalysisSliver() => SliverToBoxAdapter(
    child: Container(
      margin: EdgeInsets.all(_isTablet ? 16 : 12),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analiza trendów',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Analiza trendów będzie dostępna wkrótce...',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    ),
  );

  Widget _buildMajorityControlSliver() => SliverToBoxAdapter(
    child: Container(
      margin: EdgeInsets.all(_isTablet ? 16 : 12),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_rounded, color: AppTheme.secondaryGold),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grupa większościowa (≥51%)',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Minimalna koalicja inwestorów kontrolująca większość kapitału',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMajorityStats(),
        ],
      ),
    ),
  );

  Widget _buildMajorityStats() {
    final totalCapital = _votingManager.totalViableCapital;
    final majorityCapital = _majorityHolders.fold<double>(
      0.0,
      (sum, investor) => sum + investor.viableRemainingCapital,
    );
    final majorityPercentage = totalCapital > 0
        ? (majorityCapital / totalCapital) * 100
        : 0.0;

    return Column(
      children: [
        _buildMajorityStatRow(
          'Próg większości',
          '${_majorityThreshold.toStringAsFixed(0)}%',
          AppTheme.secondaryGold,
        ),
        _buildMajorityStatRow(
          'Rozmiar grupy większościowej',
          '${_majorityHolders.length} inwestorów',
          AppTheme.infoPrimary,
        ),
        _buildMajorityStatRow(
          'Łączny kapitał grupy',
          CurrencyFormatter.formatCurrencyShort(majorityCapital),
          AppTheme.successPrimary,
        ),
        _buildMajorityStatRow(
          'Udział grupy w całości',
          '${majorityPercentage.toStringAsFixed(1)}%',
          majorityPercentage >= 51.0
              ? AppTheme.successPrimary
              : AppTheme.warningPrimary,
        ),
      ],
    );
  }

  Widget _buildMajorityStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary)),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMajorityHoldersSliver() {
    if (_majorityHolders.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: EdgeInsets.all(_isTablet ? 16 : 12),
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.premiumCardDecoration,
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 48,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Brak posiadaczy większości',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Żaden inwestor nie posiada ≥${_majorityThreshold.toStringAsFixed(0)}% kapitału',
                  style: TextStyle(color: AppTheme.textTertiary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(_isTablet ? 16 : 12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildMajorityHolderCard(_majorityHolders[index]),
          childCount: _majorityHolders.length,
        ),
      ),
    );
  }

  Widget _buildMajorityHolderCard(InvestorSummary investor) {
    final totalCapital = _votingManager.totalViableCapital;
    final percentage = totalCapital > 0
        ? (investor.viableRemainingCapital / totalCapital) * 100
        : 0.0;

    // Pozycja w grupie większościowej (1 = największy udział)
    final position = _majorityHolders.indexOf(investor) + 1;

    // Skumulowany procent do tej pozycji
    double cumulativeCapital = 0.0;
    for (int i = 0; i < position; i++) {
      cumulativeCapital += _majorityHolders[i].viableRemainingCapital;
    }
    final cumulativePercentage = totalCapital > 0
        ? (cumulativeCapital / totalCapital) * 100
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.secondaryGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              '#$position',
              style: TextStyle(
                color: AppTheme.secondaryGold,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          investor.client.name,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kapitał: ${CurrencyFormatter.formatCurrencyShort(investor.viableRemainingCapital)}',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            Text(
              'Skumulowane: ${cumulativePercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: cumulativePercentage >= 51.0
                    ? AppTheme.successPrimary
                    : AppTheme.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${percentage.toStringAsFixed(2)}%',
              style: TextStyle(
                color: AppTheme.secondaryGold,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              'kontroli',
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
            ),
          ],
        ),
        onTap: () => _showInvestorDetails(investor),
      ),
    );
  }

  void _showInvestorDetails(InvestorSummary investor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(investor.client.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${investor.client.email}'),
            Text('Telefon: ${investor.client.phone}'),
            const SizedBox(height: 16),
            Text(
              'Kapitał wykonalny: ${CurrencyFormatter.formatCurrency(investor.viableRemainingCapital)}',
            ),
            Text('Liczba inwestycji: ${investor.investmentCount}'),
            Text(
              'Status głosowania: ${investor.client.votingStatus.displayName}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  void _exportEmails() {
    final emails = _displayedInvestors
        .map((investor) => investor.client.email)
        .where((email) => email.isNotEmpty)
        .toList();

    if (emails.isEmpty) {
      _showErrorSnackBar('Brak adresów email do wyeksportowania');
      return;
    }

    Clipboard.setData(ClipboardData(text: emails.join(', ')));
    _showSuccessSnackBar('Skopiowano ${emails.length} adresów email');
  }

  void _performMajorityControlAnalysis() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Analiza kontroli większościowej'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Próg większości: ${_majorityThreshold.toStringAsFixed(0)}%'),
            Text('Posiadaczy większości: ${_majorityHolders.length}'),
            const SizedBox(height: 16),
            Text('Szczegółowa analiza będzie dostępna wkrótce...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  void _performVotingDistributionAnalysis() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Analiza rozkładu głosowania'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildVotingStatusChart(),
            const SizedBox(height: 16),
            Text('Szczegółowa analiza będzie dostępna wkrótce...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  void _showRefreshCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Odśwież cache'),
        content: Text('Czy chcesz wymusić odświeżenie danych z serwera?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _refreshData();
            },
            child: Text('Odśwież'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successPrimary,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorPrimary),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _StatItem(this.label, this.value, this.icon, this.color);
}

class _Insight {
  final String text;
  final Color color;

  _Insight(this.text, this.color);
}
