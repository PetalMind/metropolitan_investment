import 'dart:async';
import 'package:flutter/material.dart';
import '../../models_and_services.dart';
import '../firebase_functions_analytics_service.dart' as premium;
import '../../utils/voting_analysis_manager.dart';

/// 🚀 ENHANCED INVESTOR ANALYTICS SERVICE
/// Serwis zarządzający zaawansowaną analityką inwestorów z funkcjami premium
class EnhancedInvestorAnalyticsService extends ChangeNotifier {
  // 🚀 CORE SERVICES - Dual Service Architecture
  final premium.FirebaseFunctionsAnalyticsService _premiumAnalyticsService =
      premium.FirebaseFunctionsAnalyticsService();
  final VotingAnalysisManager _votingManager = VotingAnalysisManager();

  // 📊 DATA STATE
  List<InvestorSummary> _allInvestors = [];
  premium.InvestorAnalyticsResult? _currentResult;
  List<InvestorSummary> _majorityHolders = [];
  Map<VotingStatus, double> _votingDistribution = {};
  Map<VotingStatus, int> _votingCounts = {};

  // 🎛️ UI STATE
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  bool _usePremiumMode = true;
  bool _isFilterVisible = false;

  // 📄 PAGINATION STATE
  int _currentPage = 0;
  int _totalCount = 0;
  final int _pageSize = 250;
  bool _hasNextPage = false;

  // 🔍 FILTER STATE
  String _searchQuery = '';
  VotingStatus? _selectedVotingStatus;
  ClientType? _selectedClientType;
  bool _includeInactive = true;
  bool _showOnlyWithUnviableInvestments = false;
  bool _showOnlyMajorityHolders = false;
  double _minCapitalFilter = 0.0;
  double _maxCapitalFilter = double.infinity;

  // 🗂️ SORTING STATE
  String _sortBy = 'viableRemainingCapital';
  bool _sortAscending = false;

  // ⏰ TIMERS & INTERVALS
  Timer? _refreshTimer;
  Timer? _searchDebounceTimer;
  final Duration _refreshInterval = const Duration(minutes: 5);
  final Duration _searchDebounceDelay = const Duration(milliseconds: 500);

  // 🎯 CONSTANTS
  final double _majorityThreshold = 51.0;

  // 📊 GETTERS
  List<InvestorSummary> get allInvestors => _allInvestors;
  premium.InvestorAnalyticsResult? get currentResult => _currentResult;
  List<InvestorSummary> get majorityHolders => _majorityHolders;
  Map<VotingStatus, double> get votingDistribution => _votingDistribution;
  Map<VotingStatus, int> get votingCounts => _votingCounts;

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  bool get usePremiumMode => _usePremiumMode;
  bool get isFilterVisible => _isFilterVisible;

  int get currentPage => _currentPage;
  int get totalCount => _totalCount;
  int get pageSize => _pageSize;
  bool get hasNextPage => _hasNextPage;

  String get searchQuery => _searchQuery;
  VotingStatus? get selectedVotingStatus => _selectedVotingStatus;
  ClientType? get selectedClientType => _selectedClientType;
  bool get includeInactive => _includeInactive;
  bool get showOnlyWithUnviableInvestments => _showOnlyWithUnviableInvestments;
  bool get showOnlyMajorityHolders => _showOnlyMajorityHolders;
  double get minCapitalFilter => _minCapitalFilter;
  double get maxCapitalFilter => _maxCapitalFilter;

  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  // 🚀 INITIALIZATION
  void initialize() {
    _startPeriodicRefresh();
    loadInitialData();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (!_isLoading) {
        refreshData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  // 📊 DATA METHODS
  Future<void> loadInitialData() async {
    _setLoading(true);
    _currentPage = 0;
    _error = null;
    notifyListeners();

    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (_usePremiumMode) {
        await _loadDataPremium();
      } else {
        await _loadDataStandard();
      }
    } catch (e) {
      _error = _handleAnalyticsError(e);
      _isLoading = false;
      notifyListeners();
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

    _currentResult = result;
    _allInvestors = result.allInvestors;
    _totalCount = result.totalCount;
    _hasNextPage = result.hasNextPage;
    _isLoading = false;

    // Update voting analysis
    _votingManager.calculateVotingCapitalDistribution(_allInvestors);
    _calculateMajorityAnalysis();
    _calculateVotingAnalysis();

    notifyListeners();
  }

  Future<void> _loadDataStandard() async {
    // Note: This would need to be implemented with local service
    // For now, fallback to premium mode
    await _loadDataPremium();
  }

  Future<void> loadMoreData() async {
    if (!_hasNextPage || _isLoading) return;

    _currentPage++;
    await _loadData();
  }

  Future<void> refreshData() async {
    _isRefreshing = true;
    notifyListeners();

    try {
      await loadInitialData();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // 🧮 ANALYTICS CALCULATIONS
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

  // 🔍 FILTER METHODS
  void updateSearchQuery(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounceDelay, () {
      if (_searchQuery != query) {
        _searchQuery = query;
        _currentPage = 0;
        _loadData();
      }
    });
  }

  void updateVotingStatus(VotingStatus? status) {
    _selectedVotingStatus = status;
    _currentPage = 0;
    _loadData();
  }

  void updateClientType(ClientType? type) {
    _selectedClientType = type;
    _currentPage = 0;
    _loadData();
  }

  void updateAmountFilters(double? min, double? max) {
    _minCapitalFilter = min ?? 0.0;
    _maxCapitalFilter = max ?? double.infinity;
    _currentPage = 0;
    _loadData();
  }

  void toggleIncludeInactive() {
    _includeInactive = !_includeInactive;
    _currentPage = 0;
    _loadData();
  }

  void toggleShowOnlyUnviable() {
    _showOnlyWithUnviableInvestments = !_showOnlyWithUnviableInvestments;
    _currentPage = 0;
    _loadData();
  }

  void toggleShowOnlyMajorityHolders() {
    _showOnlyMajorityHolders = !_showOnlyMajorityHolders;
    notifyListeners();
  }

  void toggleFilterVisibility() {
    _isFilterVisible = !_isFilterVisible;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedVotingStatus = null;
    _selectedClientType = null;
    _includeInactive = true;
    _showOnlyWithUnviableInvestments = false;
    _showOnlyMajorityHolders = false;
    _minCapitalFilter = 0.0;
    _maxCapitalFilter = double.infinity;
    _currentPage = 0;
    _loadData();
  }

  // 🗂️ SORTING METHODS
  void changeSortOrder(String sortBy) {
    if (_sortBy == sortBy) {
      _sortAscending = !_sortAscending;
    } else {
      _sortBy = sortBy;
      _sortAscending = false;
    }
    _currentPage = 0;
    _loadData();
  }

  // 🎛️ UI METHODS
  void togglePremiumMode() {
    _usePremiumMode = !_usePremiumMode;
    loadInitialData();
  }

  // 🔧 UTILITY METHODS
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
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

  // 📊 HELPER GETTERS FOR UI
  List<InvestorSummary> get displayedInvestors {
    if (_showOnlyMajorityHolders) {
      return _majorityHolders;
    }
    return _allInvestors;
  }

  double get totalCapital {
    return _allInvestors.fold<double>(
      0.0,
      (sum, investor) => sum + investor.viableRemainingCapital,
    );
  }

  bool get isTablet => false; // Will be set from UI context
}
