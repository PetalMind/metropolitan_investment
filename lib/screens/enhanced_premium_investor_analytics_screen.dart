import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/client.dart';
import '../models/investor_summary.dart';
import '../services/firebase_functions_analytics_service_updated.dart';
import '../services/investor_analytics_service.dart' as ia_service;
import '../widgets/investor_details_modal.dart';
import '../widgets/firebase_functions_dialogs_updated.dart';
import '../widgets/enhanced_premium_analytics_dashboard.dart';
import '../utils/currency_formatter.dart';
import '../utils/voting_analysis_manager.dart';

/// 🚀 ENHANCED PREMIUM INVESTOR ANALYTICS SCREEN
/// Zintegrowany z nowymi Firebase Functions dla maksymalnej wydajności
///
/// NOWE FUNKCJE:
/// - Wykorzystuje FirebaseFunctionsAnalyticsServiceUpdated
/// - Rzeczywiste dane z Firebase Functions
/// - Integracja z Enhanced Dashboard
/// - Real-time performance monitoring
/// - Advanced cache management
class EnhancedPremiumInvestorAnalyticsScreen extends StatefulWidget {
  final String? initialSearchQuery;

  const EnhancedPremiumInvestorAnalyticsScreen({
    super.key,
    this.initialSearchQuery,
  });

  @override
  State<EnhancedPremiumInvestorAnalyticsScreen> createState() =>
      _EnhancedPremiumInvestorAnalyticsScreenState();
}

class _EnhancedPremiumInvestorAnalyticsScreenState
    extends State<EnhancedPremiumInvestorAnalyticsScreen>
    with TickerProviderStateMixin {
  // 🎮 ENHANCED CORE SERVICES
  final FirebaseFunctionsAnalyticsServiceUpdated _analyticsService =
      FirebaseFunctionsAnalyticsServiceUpdated();
  final ia_service.InvestorAnalyticsService _fallbackService =
      ia_service.InvestorAnalyticsService();
  final VotingAnalysisManager _votingManager = VotingAnalysisManager();

  // 🎛️ UI CONTROLLERS
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();

  // 🎨 ANIMATION CONTROLLERS
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;

  // 🎭 ANIMATIONS
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // 📊 ENHANCED DATA STATE
  List<InvestorSummary> _allInvestors = [];
  List<InvestorSummary> _displayedInvestors = [];
  List<InvestorSummary> _majorityHolders = [];

  // Firebase Functions Enhanced Results
  ProductStatisticsResult? _productStats;

  // 📈 MAJORITY CONTROL ANALYSIS
  double _majorityThreshold = 51.0;

  // 🗳️ VOTING ANALYSIS
  Map<VotingStatus, double> _votingDistribution = {};
  Map<VotingStatus, int> _votingCounts = {};

  // 🔄 ENHANCED LOADING STATES
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _isLoadingEnhancedData = false;
  String? _error;

  // 📄 PAGINATION
  int _currentPage = 1;
  final int _pageSize = 250;
  bool _hasNextPage = false;

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
  bool _isEnhancedMode = true; // Toggle between enhanced and classic view

  // ⚡ PERFORMANCE METRICS
  int? _lastExecutionTime;
  bool? _lastCacheUsed;
  String _lastDataSource = 'unknown';

  // ⚙️ CONFIGURATION
  Timer? _searchDebounceTimer;
  Timer? _refreshTimer;
  static const Duration _searchDebounceDelay = Duration(milliseconds: 300);
  static const Duration _refreshInterval = Duration(
    minutes: 3,
  ); // Częstsze odświeżanie

  @override
  void initState() {
    super.initState();

    // Ustaw początkowy search query jeśli został przekazany
    if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery!.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
      _searchQuery = widget.initialSearchQuery!;
    }

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
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  void _initializeListeners() {
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted && !_isLoading && !_isRefreshing) {
        _refreshData();
      }
    });
  }

  void _disposeControllers() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _pageController.dispose();
  }

  // 🔄 EVENT HANDLERS

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreData();
    }
  }

  void _onSearchChanged() {
    if (_searchController.text != _searchQuery) {
      _debounceSearch();
    }
  }

  void _debounceSearch() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounceDelay, () {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _applyFiltersAndSort();
    });
  }

  // 📊 ENHANCED DATA METHODS

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
    });

    try {
      print('🚀 [Enhanced Analytics] Ładowanie danych z Firebase Functions...');

      // Równoległe ładowanie danych dla lepszej wydajności
      final results = await Future.wait([
        _analyticsService.getOptimizedInvestorAnalytics(
          page: _currentPage,
          pageSize: _pageSize,
          sortBy: _sortBy,
          sortAscending: _sortAscending,
          includeInactive: _includeInactive,
          votingStatusFilter: _selectedVotingStatus,
          clientTypeFilter: _selectedClientType,
          showOnlyWithUnviableInvestments: _showOnlyWithUnviableInvestments,
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        ),
        _loadEnhancedData(),
      ]);

      if (mounted) {
        final analyticsResult = results[0] as InvestorAnalyticsResult;
        _processAnalyticsResult(analyticsResult);
      }
    } catch (e) {
      print('❌ [Enhanced Analytics] Błąd głównego ładowania: $e');

      // Fallback do standardowego serwisu jeśli nowy zawiedzie
      try {
        print('🔄 [Enhanced Analytics] Próba fallback...');
        await _loadFallbackData();
      } catch (fallbackError) {
        print('❌ [Enhanced Analytics] Błąd fallback: $fallbackError');
        if (mounted) {
          setState(() {
            _error = 'Błąd ładowania danych: $e';
            _isLoading = false;
          });
        }
      }
    }
  }

  /// Ładuje dodatkowe dane z nowych Firebase Functions
  Future<void> _loadEnhancedData() async {
    setState(() => _isLoadingEnhancedData = true);

    try {
      final results = await Future.wait([
        _analyticsService.getUnifiedProductStatistics(),
        _analyticsService.getAllClients(page: 1, pageSize: 10),
      ]);

      if (mounted) {
        setState(() {
          _productStats = results[0] as ProductStatisticsResult;
          // ClientsResult nie jest obecnie używany
          _lastExecutionTime = _productStats?.metadata.executionTime;
          _lastCacheUsed = _productStats?.metadata.cacheUsed;
          _lastDataSource = 'firebase-functions-updated';
          _isLoadingEnhancedData = false;
        });
      }
    } catch (e) {
      print('❌ [Enhanced Analytics] Błąd ładowania enhanced data: $e');
      if (mounted) {
        setState(() => _isLoadingEnhancedData = false);
      }
    }
  }

  /// Fallback do standardowego serwisu w przypadku błędu
  Future<void> _loadFallbackData() async {
    print(
      '🔄 [Enhanced Analytics] Używam standardowego serwisu jako fallback...',
    );

    final result = await _fallbackService.getInvestorsSortedByRemainingCapital(
      sortBy: _sortBy,
      sortAscending: _sortAscending,
      includeInactive: _includeInactive,
      votingStatusFilter: _selectedVotingStatus,
      clientTypeFilter: _selectedClientType,
      showOnlyWithUnviableInvestments: _showOnlyWithUnviableInvestments,
    );

    // Konwertuj do Enhanced format
    final enhancedResult = InvestorAnalyticsResult(
      investors: result.investors,
      allInvestors: result.investors, // Same data for fallback
      totalCount: result.totalCount,
      currentPage: result.currentPage,
      pageSize: result.pageSize,
      hasNextPage: result.hasNextPage,
      hasPreviousPage: result.hasPreviousPage,
      totalViableCapital: result.totalViableCapital,
      votingDistribution: _getEmptyVotingDistribution(),
      executionTimeMs: 0, // Fallback nie ma timing
      source: 'fallback-service',
      message: 'Używany standardowy serwis jako fallback',
    );

    _processAnalyticsResult(enhancedResult);
  }

  Map<VotingStatus, VotingCapitalInfo> _getEmptyVotingDistribution() {
    return {
      VotingStatus.yes: VotingCapitalInfo(count: 0, capital: 0.0),
      VotingStatus.no: VotingCapitalInfo(count: 0, capital: 0.0),
      VotingStatus.abstain: VotingCapitalInfo(count: 0, capital: 0.0),
      VotingStatus.undecided: VotingCapitalInfo(count: 0, capital: 0.0),
    };
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
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );

      if (mounted) {
        setState(() {
          _allInvestors.addAll(result.investors);
          _currentPage++;
          _hasNextPage = result.hasNextPage;
          _isLoadingMore = false;
        });
        _applyFiltersAndSort();
      }
    } catch (e) {
      print('❌ [Enhanced Analytics] Błąd ładowania więcej danych: $e');
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    setState(() => _isRefreshing = true);

    try {
      // Wyczyść cache przed odświeżeniem
      await _analyticsService.clearAnalyticsCache();

      // Przeładuj dane
      await _loadInitialData();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _processAnalyticsResult(InvestorAnalyticsResult result) {
    if (!mounted) return;

    setState(() {
      _allInvestors = result.allInvestors;
      // _totalCount nie jest aktualnie używany
      _currentPage = result.currentPage;
      _hasNextPage = result.hasNextPage;
      _lastExecutionTime = result.executionTimeMs;
      _lastDataSource = result.source;
      _isLoading = false;
    });

    // Update voting analysis
    _votingManager.calculateVotingCapitalDistribution(_allInvestors);
    _calculateMajorityAnalysis();

    // Zastosuj filtry
    _applyFiltersAndSort();

    print(
      '✅ [Enhanced Analytics] Przetworzono ${_allInvestors.length} inwestorów',
    );
    print('⚡ [Enhanced Analytics] Czas wykonania: ${result.executionTimeMs}ms');
    print('🔥 [Enhanced Analytics] Źródło: ${result.source}');
  }

  void _applyFiltersAndSort() {
    if (_allInvestors.isEmpty) return;

    List<InvestorSummary> filtered = List.from(_allInvestors);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((investor) {
        return investor.client.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            investor.client.email.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (investor.client.companyName?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false);
      }).toList();
    }

    // Apply voting status filter
    if (_selectedVotingStatus != null) {
      filtered = filtered
          .where(
            (investor) => investor.client.votingStatus == _selectedVotingStatus,
          )
          .toList();
    }

    // Apply client type filter
    if (_selectedClientType != null) {
      filtered = filtered
          .where((investor) => investor.client.type == _selectedClientType)
          .toList();
    }

    // Apply capital range filter
    if (_minCapitalFilter > 0 || _maxCapitalFilter < double.infinity) {
      filtered = filtered.where((investor) {
        final capital = investor.totalValue;
        return capital >= _minCapitalFilter && capital <= _maxCapitalFilter;
      }).toList();
    }

    // Apply majority holders filter
    if (_showOnlyMajorityHolders) {
      final majorityIds = _majorityHolders.map((h) => h.client.id).toSet();
      filtered = filtered
          .where((investor) => majorityIds.contains(investor.client.id))
          .toList();
    }

    // Apply unviable investments filter
    if (_showOnlyWithUnviableInvestments) {
      filtered = filtered
          .where((investor) => investor.hasUnviableInvestments)
          .toList();
    }

    // Apply sorting
    _sortInvestors(filtered);

    setState(() {
      _displayedInvestors = filtered.take(_pageSize).toList();
      _hasNextPage = filtered.length > _pageSize;
    });
  }

  void _calculateMajorityAnalysis() {
    if (_allInvestors.isEmpty) return;

    final totalCapital = _allInvestors.fold<double>(
      0.0,
      (sum, investor) => sum + investor.totalValue,
    );

    // Sortuj inwestorów według kapitału malejąco
    final sortedInvestors = List<InvestorSummary>.from(_allInvestors);
    sortedInvestors.sort((a, b) => b.totalValue.compareTo(a.totalValue));

    // Znajdź minimalną grupę która tworzy większość (≥51%)
    _majorityHolders = [];
    double accumulatedCapital = 0.0;
    final thresholdCapital = totalCapital * (_majorityThreshold / 100);

    for (final investor in sortedInvestors) {
      if (accumulatedCapital >= thresholdCapital) break;

      _majorityHolders.add(investor);
      accumulatedCapital += investor.totalValue;
    }
  }

  void _sortInvestors(List<InvestorSummary> investors) {
    investors.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'name':
          comparison = a.client.name.compareTo(b.client.name);
          break;
        case 'viableCapital':
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
          comparison = a.totalValue.compareTo(b.totalValue);
      }

      return _sortAscending ? comparison : -comparison;
    });
  }

  // 🎨 UI BUILD METHODS

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Column(
              children: [
                _buildEnhancedAppBar(),
                Expanded(
                  child: _isEnhancedMode
                      ? _buildEnhancedDashboardView()
                      : _buildClassicListView(),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _buildEnhancedFAB(),
    );
  }

  Widget _buildEnhancedAppBar() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      '🚀 Enhanced Investor Analytics',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  _buildPerformanceIndicator(),
                  IconButton(
                    onPressed: _toggleViewMode,
                    icon: Icon(
                      _isEnhancedMode ? Icons.list : Icons.dashboard,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildQuickStatsRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceIndicator() {
    if (_lastExecutionTime == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _lastCacheUsed == true
            ? AppTheme.successPrimary.withOpacity(0.2)
            : AppTheme.warningPrimary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _lastCacheUsed == true ? Icons.cached : Icons.refresh,
            size: 14,
            color: _lastCacheUsed == true
                ? AppTheme.successPrimary
                : AppTheme.warningPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            '${_lastExecutionTime}ms',
            style: TextStyle(
              fontSize: 10,
              color: _lastCacheUsed == true
                  ? AppTheme.successPrimary
                  : AppTheme.warningPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Wyszukaj inwestorów...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _applyFiltersAndSort();
                  },
                  icon: const Icon(Icons.clear, color: Colors.white),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    return Row(
      children: [
        _buildQuickStat(
          '👥 Inwestorzy',
          '${_allInvestors.length}',
          AppTheme.infoPrimary,
        ),
        const SizedBox(width: 12),
        _buildQuickStat(
          '💰 Kapitał',
          CurrencyFormatter.formatCurrencyShort(
            _allInvestors.fold(0.0, (sum, inv) => sum + inv.totalValue),
          ),
          AppTheme.secondaryGold,
        ),
        const SizedBox(width: 12),
        if (_productStats != null)
          _buildQuickStat(
            '📦 Produkty',
            '${_productStats!.totalProducts}',
            AppTheme.successPrimary,
          ),
        const SizedBox(width: 12),
        _buildQuickStat(
          '⚡ Źródło',
          _lastDataSource.contains('updated') ? 'Enhanced' : 'Classic',
          _lastDataSource.contains('updated')
              ? AppTheme.successPrimary
              : AppTheme.warningPrimary,
        ),
      ],
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedDashboardView() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return EnhancedPremiumAnalyticsDashboard(
      investors: _displayedInvestors,
      votingDistribution: _votingDistribution,
      votingCounts: _votingCounts,
      totalCapital: _allInvestors.fold(0.0, (sum, inv) => sum + inv.totalValue),
      majorityHolders: _majorityHolders,
      onRefresh: _refreshData,
      isLoading: _isLoadingEnhancedData,
    );
  }

  Widget _buildClassicListView() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _displayedInvestors.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _displayedInvestors.length) {
          return _buildLoadingMoreIndicator();
        }

        final investor = _displayedInvestors[index];
        return _buildInvestorListItem(investor, index);
      },
    );
  }

  Widget _buildInvestorListItem(InvestorSummary investor, int index) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showInvestorDetails(investor),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      investor.client.name.isNotEmpty
                          ? investor.client.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          investor.client.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kapitał: ${CurrencyFormatter.formatCurrency(investor.totalValue)}',
                          style: TextStyle(
                            color: AppTheme.secondaryGold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Inwestycji: ${investor.investmentCount} • ${investor.client.votingStatus.name}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Performance indicators
                  Column(
                    children: [
                      if (investor.hasUnviableInvestments)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.warningPrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'RISK',
                            style: TextStyle(
                              fontSize: 8,
                              color: AppTheme.warningPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            '🚀 Ładowanie enhanced analytics...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.errorPrimary.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.errorPrimary),
            const SizedBox(height: 16),
            Text(
              'Błąd ładowania danych',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.errorPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Nieznany błąd',
              style: TextStyle(color: Colors.grey[300]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEnhancedFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        FirebaseFunctionsDialogsUpdated.showMainActionMenu(context);
      },
      backgroundColor: AppTheme.secondaryGold,
      icon: const Icon(Icons.functions, color: Colors.black),
      label: const Text(
        'Enhanced Functions',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 🛠️ UTILITY METHODS

  void _toggleViewMode() {
    setState(() {
      _isEnhancedMode = !_isEnhancedMode;
    });

    // Animate transition
    _scaleController.reset();
    _scaleController.forward();
  }

  void _showInvestorDetails(InvestorSummary investor) {
    showDialog(
      context: context,
      builder: (context) => InvestorDetailsModal(
        investor: investor,
        onUpdateInvestor: (updatedInvestor) {
          _refreshDataAfterUpdate();
        },
      ),
    );
  }

  Future<void> _refreshDataAfterUpdate() async {
    await _refreshData();
  }
}
