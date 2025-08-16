import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models_and_services.dart'; // Centralny export wszystkich modeli i serwisów
import '../services/investor_analytics_service.dart'
    as ia_service; // Tylko dla InvestorAnalyticsResult conflict resolution
import '../widgets/dialogs/enhanced_investor_email_dialog.dart';
import '../widgets/dialogs/investor_export_dialog.dart';

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
  final String? initialSearchQuery;

  const PremiumInvestorAnalyticsScreen({super.key, this.initialSearchQuery});

  @override
  State<PremiumInvestorAnalyticsScreen> createState() =>
      _PremiumInvestorAnalyticsScreenState();
}

class _PremiumInvestorAnalyticsScreenState
    extends State<PremiumInvestorAnalyticsScreen>
    with TickerProviderStateMixin {
  // 🎮 CORE SERVICES
  final FirebaseFunctionsPremiumAnalyticsService _premiumAnalyticsService =
      FirebaseFunctionsPremiumAnalyticsService(); // 🚀 NOWY: Premium Analytics Service
  final FirebaseFunctionsAnalyticsServiceUpdated _analyticsService =
      FirebaseFunctionsAnalyticsServiceUpdated(); // 🔄 FALLBACK: Stary serwis jako backup
  final ia_service.InvestorAnalyticsService _updateService =
      ia_service.InvestorAnalyticsService(); // Dla aktualizacji danych
  final VotingAnalysisManager _votingManager = VotingAnalysisManager();
  final EmailAndExportService _emailExportService =
      EmailAndExportService(); // 🚀 NOWY: Email i eksport
  final InvestmentService _investmentService =
      InvestmentService(); // 🚀 NOWY: Skalowanie inwestycji

  // 🎛️ UI CONTROLLERS
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();

  // 🎨 ANIMATION CONTROLLERS
  late AnimationController _filterAnimationController;
  late AnimationController _fabAnimationController;
  late AnimationController _statsAnimationController;
  late TabController _tabController;

  // 🎭 ANIMATIONS
  late Animation<Offset> _filterSlideAnimation;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _statsOpacityAnimation;

  // 📊 DATA STATE
  List<InvestorSummary> _allInvestors = [];
  List<InvestorSummary> _displayedInvestors = [];
  InvestorAnalyticsResult? _currentResult;
  PremiumAnalyticsResult? _premiumResult; // 🚀 NOWE: Premium Analytics Result

  // 📈 MAJORITY CONTROL ANALYSIS
  double _majorityThreshold = 51.0;
  List<InvestorSummary> _majorityHolders = [];

  // 🗳️ VOTING ANALYSIS
  Map<VotingStatus, double> _votingDistribution = {};
  Map<VotingStatus, int> _votingCounts = {};

  // 🔄 DATA REFRESH STATE
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _dataWasUpdated = false; // 📍 Flaga czy dane były rzeczywiście zmieniane
  String? _error;

  // 📄 PAGINATION
  int _currentPage = 1;
  final int _pageSize = 10000; // Zwiększony limit do 10k inwestorów
  int _totalCount = 0;

  // 🎛️ ADVANCED FILTERS
  String _sortBy = 'viableRemainingCapital';
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
  bool _showDeduplicatedProducts =
      true; // Domyślnie pokazuj deduplikowane produkty

  // 📊 VIEW MODES
  ViewMode _investorsViewMode = ViewMode.list; // Domyślnie lista zamiast kart
  ViewMode _majorityViewMode = ViewMode.list;

  // 📋 MULTI-SELECTION STATE
  bool _isSelectionMode = false;
  Set<String> _selectedInvestorIds = <String>{};
  List<InvestorSummary> get _selectedInvestors => _allInvestors
      .where((investor) => _selectedInvestorIds.contains(investor.client.id))
      .toList();

  // 📱 RESPONSIVE BREAKPOINTS
  bool get _isTablet => MediaQuery.of(context).size.width > 768;

  // ⚙️ CONFIGURATION
  Timer? _searchDebounceTimer;
  Timer? _refreshTimer;
  static const Duration _searchDebounceDelay = Duration(milliseconds: 300);
  static const Duration _refreshInterval = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();

    // Ustaw początkowy search query jeśli został przekazany
    if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery!.isNotEmpty) {
      _searchQuery = widget.initialSearchQuery!;
      _searchController.text = _searchQuery;

      // Automatycznie przełącz na zakładkę Inwestorzy i pokaż filtry
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tabController.animateTo(1); // Index 1 = Inwestorzy tab
          setState(() => _isFilterVisible = true);
          _filterAnimationController.forward();
        }
      });
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
      // Tab change animation could be added here if needed
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
      // 🚀 PIERWSZE PODEJŚCIE: Premium Analytics Service
      try {
        _premiumResult = await _premiumAnalyticsService
            .getPremiumInvestorAnalytics(
              page: _currentPage,
              pageSize: _pageSize,
              sortBy: _sortBy,
              sortAscending: _sortAscending,
              includeInactive: _includeInactive,
              votingStatusFilter: _selectedVotingStatus,
              clientTypeFilter: _selectedClientType,
              showOnlyWithUnviableInvestments: _showOnlyWithUnviableInvestments,
              searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
              majorityThreshold: _majorityThreshold,
              forceRefresh: true,
            );

        if (mounted && _premiumResult != null) {
          // 📊 PROCESY PREMIUM ANALYTICS RESULT
          _allInvestors = _premiumResult!.investors;
          _displayedInvestors = List.from(_allInvestors);
          _totalCount = _premiumResult!.totalCount;

          // 🏆 USTAW DANE Z PREMIUM ANALYTICS
          _majorityHolders = _premiumResult!.majorityAnalysis.majorityHolders;
          _majorityThreshold =
              _premiumResult!.majorityAnalysis.majorityThreshold;

          // 🗳️ USTAW VOTING DISTRIBUTION Z PREMIUM ANALYTICS
          _votingDistribution = {
            VotingStatus.yes:
                _premiumResult!.votingAnalysis.votingDistribution['yes'] ?? 0.0,
            VotingStatus.no:
                _premiumResult!.votingAnalysis.votingDistribution['no'] ?? 0.0,
            VotingStatus.abstain:
                _premiumResult!.votingAnalysis.votingDistribution['abstain'] ??
                0.0,
            VotingStatus.undecided:
                _premiumResult!
                    .votingAnalysis
                    .votingDistribution['undecided'] ??
                0.0,
          };

          _votingCounts = {
            VotingStatus.yes:
                _premiumResult!.votingAnalysis.votingCounts['yes'] ?? 0,
            VotingStatus.no:
                _premiumResult!.votingAnalysis.votingCounts['no'] ?? 0,
            VotingStatus.abstain:
                _premiumResult!.votingAnalysis.votingCounts['abstain'] ?? 0,
            VotingStatus.undecided:
                _premiumResult!.votingAnalysis.votingCounts['undecided'] ?? 0,
          };

          // 🎯 APPLY FILTERS AND SORT
          _applyFiltersAndSort();

          setState(() {
            _isLoading = false;
            _error = null;
          });

          print(
            '✅ [Premium Analytics] Załadowano ${_allInvestors.length} inwestorów z premium analytics',
          );
          return; // Sukces! Nie potrzebujemy fallback
        }
      } catch (premiumError) {
        print(
          '⚠️ [Premium Analytics] Błąd premium service, używam fallback: $premiumError',
        );
      }

      // 🔄 FALLBACK: Użyj starszego serwisu jako backup
      final fallbackService = ia_service.InvestorAnalyticsService();
      final fallbackResult = await fallbackService
          .getInvestorsSortedByRemainingCapital(
            page: _currentPage,
            pageSize: _pageSize,
            sortBy: _sortBy,
            sortAscending: _sortAscending,
            includeInactive: _includeInactive,
            votingStatusFilter: _selectedVotingStatus,
            clientTypeFilter: _selectedClientType,
            showOnlyWithUnviableInvestments: _showOnlyWithUnviableInvestments,
          );

      if (mounted) {
        // Konwertuj standardowy wynik do enhanced format
        final enhancedResult = _convertToEnhancedResult(fallbackResult);

        _processAnalyticsResult(enhancedResult);
        _calculateMajorityAnalysis();
        _calculateVotingAnalysis();
      }
    } catch (fallbackError) {
      if (mounted) {
        setState(() {
          _error = _handleAnalyticsError(fallbackError);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreData() async {
    // Nie ładuj więcej danych - teraz ładujemy wszystkie od razu
    return;
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

  /// Odświeża dane po aktualizacji inwestora z wymuszeniem przeładowania z serwera
  /// ZACHOWUJE pozycję scroll aby użytkownik pozostał w tym samym miejscu na liście
  Future<void> _refreshDataAfterUpdate() async {
    if (!mounted) return;

    print(
      '📍 [Analytics] Rozpoczynam odświeżanie danych po aktualizacji inwestora',
    );

    // 📍 ZACHOWAJ obecną pozycję scroll przed odświeżeniem
    final currentScrollOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;

    print(
      '📍 [Analytics] Zachowuję pozycję scroll: ${currentScrollOffset.toStringAsFixed(1)}px',
    );

    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
    });

    try {
      // 🚀 PIERWSZE PODEJŚCIE: Premium Analytics Service z wymuszeniem odświeżenia
      try {
        _premiumResult = await _premiumAnalyticsService
            .getPremiumInvestorAnalytics(
              page: _currentPage,
              pageSize: _pageSize,
              sortBy: _sortBy,
              sortAscending: _sortAscending,
              includeInactive: _includeInactive,
              votingStatusFilter: _selectedVotingStatus,
              clientTypeFilter: _selectedClientType,
              showOnlyWithUnviableInvestments: _showOnlyWithUnviableInvestments,
              searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
              majorityThreshold: _majorityThreshold,
              forceRefresh: true, // 🔑 WYMUSZA PRZEŁADOWANIE CACHE
            );

        if (mounted && _premiumResult != null) {
          // 📊 PROCESY PREMIUM ANALYTICS RESULT
          _allInvestors = _premiumResult!.investors;
          _displayedInvestors = List.from(_allInvestors);
          _totalCount = _premiumResult!.totalCount;

          // 🏆 USTAW DANE Z PREMIUM ANALYTICS
          _majorityHolders = _premiumResult!.majorityAnalysis.majorityHolders;

          // 🗳️ USTAW VOTING DISTRIBUTION Z PREMIUM ANALYTICS
          _votingDistribution = {
            VotingStatus.yes:
                _premiumResult!.votingAnalysis.votingDistribution['yes'] ?? 0.0,
            VotingStatus.no:
                _premiumResult!.votingAnalysis.votingDistribution['no'] ?? 0.0,
            VotingStatus.abstain:
                _premiumResult!.votingAnalysis.votingDistribution['abstain'] ??
                0.0,
            VotingStatus.undecided:
                _premiumResult!
                    .votingAnalysis
                    .votingDistribution['undecided'] ??
                0.0,
          };

          _votingCounts = {
            VotingStatus.yes:
                _premiumResult!.votingAnalysis.votingCounts['yes'] ?? 0,
            VotingStatus.no:
                _premiumResult!.votingAnalysis.votingCounts['no'] ?? 0,
            VotingStatus.abstain:
                _premiumResult!.votingAnalysis.votingCounts['abstain'] ?? 0,
            VotingStatus.undecided:
                _premiumResult!.votingAnalysis.votingCounts['undecided'] ?? 0,
          };

          // 🎯 APPLY FILTERS AND SORT
          _applyFiltersAndSort();

          // 📍 PRZYWRÓĆ pozycję scroll po odświeżeniu danych
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients && currentScrollOffset > 0) {
              print(
                '📍 [Analytics] Przywracam pozycję scroll: ${currentScrollOffset.toStringAsFixed(1)}px',
              );
              _scrollController.animateTo(
                currentScrollOffset,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });

          setState(() {
            _isLoading = false;
            _error = null;
          });

          print(
            '✅ [Premium Analytics] Odświeżono ${_allInvestors.length} inwestorów z premium analytics',
          );
          return; // Sukces! Nie potrzebujemy fallback
        }
      } catch (premiumError) {
        print(
          '⚠️ [Premium Analytics] Błąd refresh premium service, używam fallback: $premiumError',
        );
      }

      // 🔄 FALLBACK: Użyj starszego serwisu z wymuszeniem odświeżenia
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
        forceRefresh: true, // 🔑 WYMUSZA PRZEŁADOWANIE CACHE
      );

      if (mounted) {
        _processAnalyticsResult(result);
        _calculateMajorityAnalysis();
        _calculateVotingAnalysis();

        // 📍 PRZYWRÓĆ pozycję scroll po odświeżeniu danych
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients && currentScrollOffset > 0) {
            print(
              '📍 [Analytics] Przywracam pozycję scroll: ${currentScrollOffset.toStringAsFixed(1)}px',
            );
            _scrollController.animateTo(
              currentScrollOffset,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });

        // Pokaż komunikat o pomyślnym odświeżeniu
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📊 Dane zostały automatycznie odświeżone'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _handleAnalyticsError(e);
          _isLoading = false;
        });

        // Pokaż błąd odświeżania
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Błąd odświeżania danych: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
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
      _displayedInvestors = filtered; // Pokaż wszystkie przefiltrowane wyniki
      _totalCount = filtered.length;
    });
  }

  void _processAnalyticsResult(InvestorAnalyticsResult result) {
    if (!mounted) return;

    // 🔍 DEBUG: Dodaj informacje debugujące

    if (result.investors.isNotEmpty) {
      final firstInvestor = result.investors.first;

      // 🔍 DEBUG: Sprawdź pierwsze inwestycje
      if (firstInvestor.investments.isNotEmpty) {}
    }

    setState(() {
      _currentResult = result;
      _allInvestors = result.allInvestors;
      _displayedInvestors =
          result.allInvestors; // Użyj wszystkich danych zamiast stronnicowanych
      _totalCount = result
          .allInvestors
          .length; // Użyj rzeczywistej liczby wszystkich inwestorów
      _isLoading = false;
    });

    // Update voting analysis
    _votingManager.calculateVotingCapitalDistribution(_allInvestors);

    // 🔍 DEBUG: Sprawdź voting manager po aktualizacji

    // Apply initial sorting and filtering to all data
    _applyFiltersAndSort();

    // Store result for use in UI
    if (_currentResult != null) {
      _calculateMajorityAnalysis();
      _calculateVotingAnalysis();
    }

    // Jeśli mamy initial search query, zastosuj filtry po załadowaniu danych
    if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _applyFiltersAndSort();
        }
      });
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

  /// Konwertuje standardowy InvestorAnalyticsResult do Enhanced format
  InvestorAnalyticsResult _convertToEnhancedResult(
    ia_service.InvestorAnalyticsResult standardResult,
  ) {
    // Sprawdź czy investors i totalCount są spójne
    if (standardResult.investors.length != standardResult.totalCount) {}

    return InvestorAnalyticsResult(
      investors: standardResult.investors,
      allInvestors: standardResult
          .investors, // Use the same list - teraz powinno mieć wszystkich
      totalCount: standardResult.totalCount,
      currentPage: standardResult.currentPage,
      pageSize: standardResult.pageSize,
      hasNextPage: standardResult.hasNextPage,
      hasPreviousPage: standardResult.hasPreviousPage,
      totalViableCapital: standardResult.totalViableCapital,
      votingDistribution: {
        VotingStatus.yes: VotingCapitalInfo(count: 0, capital: 0.0),
        VotingStatus.no: VotingCapitalInfo(count: 0, capital: 0.0),
        VotingStatus.abstain: VotingCapitalInfo(count: 0, capital: 0.0),
        VotingStatus.undecided: VotingCapitalInfo(count: 0, capital: 0.0),
      },
      executionTimeMs: 0, // Fallback nie ma timing
      source: 'fallback-service',
      message: 'Używany standardowy serwis jako fallback',
    );
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
      _showDeduplicatedProducts = true; // Domyślnie deduplikowane produkty
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
        case 'viableRemainingCapital':
          comparison = a.viableRemainingCapital.compareTo(
            b.viableRemainingCapital,
          );
          break;
        case 'totalValue':
          comparison = a.viableRemainingCapital.compareTo(
            b.viableRemainingCapital,
          );
          break;
        case 'investmentCount':
          comparison = a.investmentCount.compareTo(b.investmentCount);
          break;
        case 'votingStatus':
          comparison = a.client.votingStatus.name.compareTo(
            b.client.votingStatus.name,
          );
          break;
        case 'totalInvestmentAmount':
          comparison = a.totalInvestmentAmount.compareTo(
            b.totalInvestmentAmount,
          );
          break;
        case 'capitalSecuredByRealEstate':
          comparison = a.capitalSecuredByRealEstate.compareTo(
            b.capitalSecuredByRealEstate,
          );
          break;
        case 'capitalForRestructuring':
          comparison = a.capitalForRestructuring.compareTo(
            b.capitalForRestructuring,
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
                  _isSelectionMode
                      ? 'Wybór Inwestorów'
                      : 'Analityka Inwestorów',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_totalCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    _isSelectionMode && _selectedInvestorIds.isNotEmpty
                        ? 'Wybrano ${_selectedInvestorIds.length} z ${_displayedInvestors.length} inwestorów'
                        : '${_totalCount} inwestorów • ${CurrencyFormatter.formatCurrency(_votingManager.totalViableCapital, showDecimals: false)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.successPrimary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Źródło: Inwestorzy (viableCapital)',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.successPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_isSelectionMode) ...[
            // Przyciski w trybie selekcji
            if (_displayedInvestors.isNotEmpty)
              TextButton.icon(
                onPressed:
                    _selectedInvestorIds.length == _displayedInvestors.length
                    ? _clearSelection
                    : _selectAllVisibleInvestors,
                icon: Icon(
                  _selectedInvestorIds.length == _displayedInvestors.length
                      ? Icons.deselect
                      : Icons.select_all,
                  size: 20,
                ),
                label: Text(
                  _selectedInvestorIds.length == _displayedInvestors.length
                      ? 'Usuń zaznaczenie'
                      : 'Zaznacz wszystko',
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.secondaryGold,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
            const SizedBox(width: 8),
          ] else ...[
            // Standardowe przyciski
            _buildRefreshButton(),
            const SizedBox(width: 8),
            _buildViewModeToggle(),
            const SizedBox(width: 8),
          ],
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
        _buildInvestorsSortBar(),
        if (_isLoading)
          _buildLoadingSliver()
        else if (_error != null)
          _buildErrorSliver()
        else
          _buildInvestorsContent(),
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
        _buildMajorityHoldersContent(),
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
          title: Text('Widok zdeduplikowanych produktów'),
          subtitle: Text('Grupuj produkty według nazwy, typu i firmy'),
          value: _showDeduplicatedProducts,
          onChanged: (value) {
            setState(() => _showDeduplicatedProducts = value ?? false);
            // Opcjonalnie: odśwież dane jeśli potrzeba
          },
          activeColor: AppTheme.primaryAccent,
        ),
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
    final hasInitialSearch =
        widget.initialSearchQuery != null &&
        widget.initialSearchQuery!.isNotEmpty;

    return SliverToBoxAdapter(
      child: Column(
        children: [
          // Info banner gdy wyszukiwanie przez link
          if (hasInitialSearch &&
              _searchQuery == widget.initialSearchQuery) ...[
            Container(
              margin: EdgeInsets.all(_isTablet ? 16 : 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.infoPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.infoPrimary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.infoPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Wyszukano inwestora: "${widget.initialSearchQuery}"',
                      style: TextStyle(
                        color: AppTheme.infoPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _applyFiltersAndSort();
                    },
                    child: Text(
                      'Wyczyść',
                      style: TextStyle(color: AppTheme.infoPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Search bar
          Container(
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
        ],
      ),
    );
  }

  Widget _buildInvestorsSortBar() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: _isTablet ? 16 : 12,
          vertical: 8,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSecondary),
        ),
        child: Row(
          children: [
            Icon(Icons.sort_rounded, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 12),
            Text(
              'Sortuj według:',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSortChip('name', 'Nazwa'),
                  _buildSortChip('viableRemainingCapital', 'Kapitał pozostały'),
                  _buildSortChip('investmentCount', 'Liczba inwestycji'),
                  _buildSortChip('votingStatus', 'Status głosowania'),
                  _buildSortChip('totalInvestmentAmount', 'Kwota inwestycji'),
                  _buildSortChip(
                    'capitalSecuredByRealEstate',
                    'Kapitał zabezpieczony nieruchomościami',
                  ),
                  _buildSortChip(
                    'capitalForRestructuring',
                    'Kapitał do restrukturyzacji',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {
                setState(() {
                  _sortAscending = !_sortAscending;
                });
                _applyFiltersAndSort();
              },
              icon: Icon(
                _sortAscending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: AppTheme.secondaryGold,
                size: 20,
              ),
              tooltip: _sortAscending ? 'Rosnąco' : 'Malejąco',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String sortKey, String label) {
    final isSelected = _sortBy == sortKey;

    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? AppTheme.backgroundPrimary
              : AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selectedColor: AppTheme.secondaryGold,
      backgroundColor: AppTheme.backgroundTertiary,
      checkmarkColor: AppTheme.backgroundPrimary,
      side: BorderSide(
        color: isSelected ? AppTheme.secondaryGold : AppTheme.borderSecondary,
        width: 1,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _sortBy = sortKey;
          });
          _applyFiltersAndSort();
        }
      },
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

  Widget _buildViewModeToggle() {
    return ViewModeSelector(
      currentMode: _investorsViewMode,
      onModeChanged: (ViewMode mode) {
        setState(() {
          if (_tabController.index == 1) {
            // Inwestorzy tab
            _investorsViewMode = mode;
          } else if (_tabController.index == 3) {
            // Większość tab
            _majorityViewMode = mode;
          }
        });
      },
      isTablet: _isTablet,
    );
  }

  Widget _buildFloatingActionButton() {
    if (_isSelectionMode) {
      // Tryb wielokrotnego wyboru - pokaż liczbę wybranych i akcje
      return ScaleTransition(
        scale: _fabScaleAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedInvestorIds.isNotEmpty) ...[
              // Email FAB
              FloatingActionButton(
                heroTag: "email_fab",
                onPressed: _showEmailDialog,
                backgroundColor: AppTheme.secondaryGold,
                foregroundColor: Colors.white,
                mini: true,
                child: const Icon(Icons.email_outlined),
              ),
              const SizedBox(height: 8),
              // Export FAB
              FloatingActionButton(
                heroTag: "export_fab",
                onPressed: _showExportDialog,
                backgroundColor: AppTheme.primaryAccent,
                foregroundColor: Colors.white,
                mini: true,
                child: const Icon(Icons.file_download_outlined),
              ),
              const SizedBox(height: 12),
            ],
            // Główny FAB z liczbą wybranych
            FloatingActionButton.extended(
              heroTag: "main_fab",
              onPressed: _exitSelectionMode,
              backgroundColor: Colors.grey[700],
              foregroundColor: Colors.white,
              icon: const Icon(Icons.close),
              label: Text('Wybrano: ${_selectedInvestorIds.length}'),
            ),
          ],
        ),
      );
    }

    // Normalny tryb - standardowy przycisk akcji
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: FloatingActionButton.extended(
        onPressed: _showActionMenu,
        backgroundColor: AppTheme.secondaryGold,
        foregroundColor: AppTheme.textOnSecondary,
        icon: const Icon(Icons.more_vert_rounded),
        label: const Text('Akcje'),
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
    // � KLUCZOWE METRYKI SYSTEMU - używa danych z premium analytics
    double totalViableCapital = 0.0;
    double totalCapital = 0.0;

    if (_premiumResult != null) {
      // Używamy danych z premium analytics (preferowane)
      totalViableCapital = _premiumResult!.performanceMetrics.totalCapital;
      totalCapital = _premiumResult!.performanceMetrics.totalCapital;
      print(
        '🚀 [StatsGrid] Używam Premium Analytics: Capital ${totalCapital.toStringAsFixed(2)}',
      );
    } else if (_currentResult != null) {
      // Fallback na standardowe dane
      totalViableCapital = _currentResult!.totalViableCapital;
      totalCapital = _allInvestors.fold<double>(
        0.0,
        (sum, investor) => sum + investor.totalInvestmentAmount,
      );

      print('   - Viable Capital: ${totalViableCapital.toStringAsFixed(2)}');
      print('   - Total Capital: ${totalCapital.toStringAsFixed(2)}');
    }

    // Oblicz próg 51% kapitału
    final majorityCapitalThreshold = totalViableCapital * 0.51;

    // Oblicz próg 51% liczby inwestorów
    final majorityInvestorCount = (_totalCount * 0.51).ceil();

    final stats = [
      _StatItem(
        'Kapitał pozostały',
        CurrencyFormatter.formatCurrency(
          totalViableCapital,
          showDecimals: false,
        ),
        Icons.account_balance_wallet_rounded,
        AppTheme.successPrimary,
      ),
      _StatItem(
        'Większość kapitału (51%)',
        CurrencyFormatter.formatCurrency(
          majorityCapitalThreshold,
          showDecimals: false,
        ),
        Icons.gavel_rounded,
        AppTheme.secondaryGold,
      ),
      _StatItem(
        'Większość osobowa (51%)',
        '${majorityInvestorCount} z ${_totalCount}',
        Icons.people_rounded,
        AppTheme.infoPrimary,
      ),
      _StatItem(
        'Kapitał całkowity',
        CurrencyFormatter.formatCurrency(totalCapital, showDecimals: false),
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

  // 🚀 NOWE FUNKCJONALNOŚCI: EMAIL I EKSPORT

  /// Eksportuje wybranych inwestorów do różnych formatów
  Future<void> _exportSelectedInvestors() async {
    if (_selectedInvestors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Najpierw wybierz inwestorów do eksportu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => InvestorExportDialog(
        selectedInvestors: _selectedInvestors,
        onExportComplete: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Eksport zakończony pomyślnie'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  /// Wysyła email do wybranych inwestorów
  Future<void> _sendEmailToSelectedInvestors() async {
    if (_selectedInvestors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Najpierw wybierz inwestorów do wysłania email'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => EnhancedInvestorEmailDialog(
        selectedInvestors: _selectedInvestors,
        onEmailSent: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Emaile zostały wysłane'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  /// Skaluje kwoty inwestycji produktu proporcjonalnie
  Future<void> _scaleProductInvestments(
    String productId,
    String productName,
    double newTotalAmount,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Skalowanie inwestycji...'),
            ],
          ),
        ),
      );

      final result = await _investmentService.scaleProductInvestments(
        productId: productId,
        productName: productName,
        newTotalAmount: newTotalAmount,
        reason: 'Proporcjonalne skalowanie z Premium Analytics',
      );

      Navigator.of(context).pop(); // Zamknij dialog loading

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Skalowanie zakończone: ${result.summary.affectedInvestments} inwestycji',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Odśwież dane
        await _refreshData();
      } else {
        throw Exception('Skalowanie nie powiodło się');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Zamknij dialog loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Błąd skalowania: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Akcje Premium Analytics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // 🚀 NOWE: Eksport danych
          _buildActionTile(
            'Eksport danych inwestorów',
            'Wyeksportuj wszystkich inwestorów do CSV/Excel/JSON',
            Icons.download_rounded,
            AppTheme.successColor,
            () async {
              Navigator.pop(context);
              await _exportSelectedInvestors();
            },
          ),

          // 🚀 NOWE: Email do inwestorów
          _buildActionTile(
            'Wyślij email do inwestorów',
            'Wyślij maile do wszystkich lub wybranych inwestorów',
            Icons.email_rounded,
            AppTheme.primaryAccent,
            () async {
              Navigator.pop(context);
              await _sendEmailToSelectedInvestors();
            },
          ),

          // Nowa opcja wielokrotnego wyboru
          _buildActionTile(
            'Wybór wielu inwestorów',
            'Zaznacz inwestorów do masowych operacji',
            Icons.checklist_rounded,
            AppTheme.primaryColor,
            () {
              Navigator.pop(context);
              _enterSelectionMode();
            },
          ),

          // 🚀 NOWE: Analiza premium
          _buildActionTile(
            'Odśwież analizę premium',
            'Wymuszenie przeładowania najnowszych danych',
            Icons.analytics_rounded,
            AppTheme.warningColor,
            () async {
              Navigator.pop(context);
              await _refreshData();
            },
          ),

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

  Widget _buildInvestorsContent() {
    // ✅ UŻYJ NOWYCH PROFESSIONAL WIDGETS Z WSZYSTKIMI 4 METRYKAMI
    return InvestorViewsContainer(
      investors: _displayedInvestors,
      majorityHolders: _majorityHolders,
      totalViableCapital: _votingManager.totalViableCapital,
      currentViewMode: _investorsViewMode,
      isTablet: _isTablet,
      isLoading: false, // Already handled at screen level
      error: null, // Already handled at screen level
      onInvestorTap: _isSelectionMode
          ? (investor) => _toggleInvestorSelection(investor.client.id)
          : _showInvestorDetails,
      isSelectionMode: _isSelectionMode,
      selectedInvestorIds: _selectedInvestorIds,
      onInvestorSelectionToggle: _toggleInvestorSelection,
    );
  }

  // 🎨 SYSTEM STATS AND ANALYTICS

  Widget _buildInvestorsTableHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('#', style: _getTableHeaderStyle())),
          Expanded(
            flex: 3,
            child: Text('Inwestor', style: _getTableHeaderStyle()),
          ),
          Expanded(
            flex: 2,
            child: Text('Status', style: _getTableHeaderStyle()),
          ),
          Expanded(
            flex: 2,
            child: Text('Kapitał pozostały', style: _getTableHeaderStyle()),
          ),
          if (_isTablet) ...[
            Expanded(
              flex: 2,
              child: Text('Kwota inwestycji', style: _getTableHeaderStyle()),
            ),
            Expanded(
              flex: 2,
              child: Text('Do restrukturyzacji', style: _getTableHeaderStyle()),
            ),
            Expanded(
              flex: 2,
              child: Text('Zabezp. nieruch.', style: _getTableHeaderStyle()),
            ),
          ] else ...[
            // Mobile view - pokazuj tylko kwotę inwestycji w kompaktowej formie
            Expanded(
              flex: 1,
              child: Text('Kwota\ninwest.', style: _getTableHeaderStyle()),
            ),
          ],
          Expanded(
            flex: 1,
            child: Text('Udział', style: _getTableHeaderStyle()),
          ),
          Expanded(
            flex: 1,
            child: Text('Liczba\ninwestycji', style: _getTableHeaderStyle()),
          ),
          if (_isTablet) ...[
            SizedBox(
              width: 48,
              child: Text('Akcje', style: _getTableHeaderStyle()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvestorsTableRow(InvestorSummary investor, int index) {
    final votingStatusColor = _getVotingStatusColor(
      investor.client.votingStatus,
    );
    final capitalPercentage = _votingManager.totalViableCapital > 0
        ? (investor.viableRemainingCapital /
                  _votingManager.totalViableCapital) *
              100
        : 0.0;
    final isMajorityHolder = _majorityHolders.contains(investor);

    return InkWell(
      onTap: () => _showInvestorDetails(investor),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMajorityHolder
              ? AppTheme.secondaryGold.withOpacity(0.05)
              : AppTheme.backgroundSecondary,
          border: Border(
            bottom: BorderSide(color: AppTheme.borderSecondary, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: votingStatusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: votingStatusColor.withOpacity(0.3)),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: votingStatusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          investor.client.name,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          investor.client.type.displayName,
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isMajorityHolder) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.star_rounded,
                      color: AppTheme.secondaryGold,
                      size: 14,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: votingStatusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: votingStatusColor.withOpacity(0.3)),
                ),
                child: Text(
                  investor.client.votingStatus.displayName,
                  style: TextStyle(
                    color: votingStatusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CurrencyFormatter.formatCurrencyShort(
                      investor.viableRemainingCapital,
                    ),
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${capitalPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (_isTablet) ...[
              Expanded(
                flex: 2,
                child: Text(
                  CurrencyFormatter.formatCurrencyShort(
                    investor.totalInvestmentAmount,
                  ),
                  style: TextStyle(
                    color: AppTheme.infoPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  CurrencyFormatter.formatCurrencyShort(
                    investor.capitalForRestructuring,
                  ),
                  style: TextStyle(
                    color: AppTheme.warningPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  CurrencyFormatter.formatCurrencyShort(
                    investor.capitalSecuredByRealEstate,
                  ),
                  style: TextStyle(
                    color: AppTheme.successPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
            ] else ...[
              // Mobile view - pokazuj tylko kwotę inwestycji
              Expanded(
                flex: 1,
                child: Text(
                  CurrencyFormatter.formatCurrencyShort(
                    investor.totalInvestmentAmount,
                  ),
                  style: TextStyle(
                    color: AppTheme.infoPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
            Expanded(
              flex: 1,
              child: Text(
                '${capitalPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isMajorityHolder
                      ? AppTheme.secondaryGold
                      : AppTheme.textSecondary,
                  fontWeight: isMajorityHolder
                      ? FontWeight.w600
                      : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${investor.investmentCount}',
                  style: TextStyle(
                    color: AppTheme.primaryAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (_isTablet) ...[
              SizedBox(
                width: 48,
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: 16),
                  color: AppTheme.backgroundModal,
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppTheme.infoPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text('Szczegóły'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'export',
                      child: Row(children: [
                    
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'details':
                        _showInvestorDetails(investor);
                        break;
                      case 'export':
                        _exportInvestorData(investor);
                        break;
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  TextStyle _getTableHeaderStyle() {
    return TextStyle(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w700,
      fontSize: 13,
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
          Row(
            children: [
              Icon(Icons.speed_rounded, color: AppTheme.secondaryGold),
              const SizedBox(width: 12),
              Text(
                'Metryki wydajności',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPerformanceGrid(),
          const SizedBox(height: 16),
          _buildPerformanceChart(),
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
          Row(
            children: [
              Icon(Icons.trending_up_rounded, color: AppTheme.secondaryGold),
              const SizedBox(width: 12),
              Text(
                'Analiza trendów',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTrendMetrics(),
          const SizedBox(height: 16),
          _buildTrendChart(),
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

  Widget _buildMajorityHoldersContent() {
    switch (_majorityViewMode) {
      case ViewMode.cards:
        return _buildMajorityHoldersCards();
      case ViewMode.list:
        return _buildMajorityHoldersSliver();
      case ViewMode.table:
        return _buildMajorityHoldersTable();
    }
  }

  Widget _buildMajorityHoldersCards() {
    if (_majorityHolders.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: EdgeInsets.all(_isTablet ? 16 : 12),
          padding: const EdgeInsets.all(40),
          decoration: AppTheme.premiumCardDecoration,
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 64,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Brak grup większościowych',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nie znaleziono inwestorów spełniających kryteria większości',
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
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _isTablet ? 2 : 1,
          childAspectRatio: _isTablet ? 2.2 : 3.0,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildMajorityHolderCard(_majorityHolders[index]),
          childCount: _majorityHolders.length,
        ),
      ),
    );
  }

  Widget _buildMajorityHoldersTable() {
    if (_majorityHolders.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: EdgeInsets.all(_isTablet ? 16 : 12),
          padding: const EdgeInsets.all(40),
          decoration: AppTheme.premiumCardDecoration,
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 64,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Brak grup większościowych',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nie znaleziono inwestorów spełniających kryteria większości',
                  style: TextStyle(color: AppTheme.textTertiary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(_isTablet ? 16 : 12),
        decoration: AppTheme.premiumCardDecoration,
        child: Column(
          children: [
            _buildMajorityTableHeader(),
            ..._majorityHolders.asMap().entries.map(
              (entry) => _buildMajorityTableRow(entry.value, entry.key),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMajorityTableHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text('Poz.', style: _getTableHeaderStyle()),
          ),
          Expanded(
            flex: 3,
            child: Text('Inwestor', style: _getTableHeaderStyle()),
          ),
          Expanded(
            flex: 2,
            child: Text('Kapitał', style: _getTableHeaderStyle()),
          ),
          Expanded(
            flex: 1,
            child: Text('Udział', style: _getTableHeaderStyle()),
          ),
          Expanded(
            flex: 1,
            child: Text('Skum.', style: _getTableHeaderStyle()),
          ),
          if (_isTablet) ...[
            Expanded(
              flex: 2,
              child: Text('Status głosowania', style: _getTableHeaderStyle()),
            ),
            SizedBox(
              width: 48,
              child: Text('Akcje', style: _getTableHeaderStyle()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMajorityTableRow(InvestorSummary investor, int index) {
    final totalCapital = _votingManager.totalViableCapital;
    final percentage = totalCapital > 0
        ? (investor.viableRemainingCapital / totalCapital) * 100
        : 0.0;

    // Pozycja w grupie większościowej (1 = największy udział)
    final position = index + 1;

    // Skumulowany procent do tej pozycji
    double cumulativeCapital = 0.0;
    for (int i = 0; i <= index; i++) {
      cumulativeCapital += _majorityHolders[i].viableRemainingCapital;
    }
    final cumulativePercentage = totalCapital > 0
        ? (cumulativeCapital / totalCapital) * 100
        : 0.0;

    final votingStatusColor = _getVotingStatusColor(
      investor.client.votingStatus,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSecondary, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.secondaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.secondaryGold.withOpacity(0.3),
                ),
              ),
              child: Text(
                '$position',
                style: TextStyle(
                  color: AppTheme.secondaryGold,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              investor.client.name,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              CurrencyFormatter.formatCurrencyShort(
                investor.viableRemainingCapital,
              ),
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${cumulativePercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: cumulativePercentage >= _majorityThreshold
                    ? AppTheme.successPrimary
                    : AppTheme.warningPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_isTablet) ...[
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: votingStatusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: votingStatusColor.withOpacity(0.3)),
                ),
                child: Text(
                  investor.client.votingStatus.displayName,
                  style: TextStyle(
                    color: votingStatusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: IconButton(
                icon: Icon(Icons.info_outline_rounded, size: 20),
                onPressed: () => _showInvestorDetails(investor),
                color: AppTheme.textSecondary,
              ),
            ),
          ],
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

    final votingStatusColor = _getVotingStatusColor(
      investor.client.votingStatus,
    );

    // Różne widoki w zależności od trybu
    if (_majorityViewMode == ViewMode.cards) {
      return Card(
        child: InkWell(
          onTap: () => _showInvestorDetails(investor),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.secondaryGold.withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$position',
                          style: TextStyle(
                            color: AppTheme.secondaryGold,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            investor.client.name,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: votingStatusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: votingStatusColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              investor.client.votingStatus.displayName,
                              style: TextStyle(
                                color: votingStatusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.star_rounded,
                      color: AppTheme.secondaryGold,
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kapitał',
                            style: TextStyle(
                              color: AppTheme.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatCurrencyShort(
                              investor.viableRemainingCapital,
                            ),
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Udział',
                            style: TextStyle(
                              color: AppTheme.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Skumulowany udział:',
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${cumulativePercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: cumulativePercentage >= _majorityThreshold
                            ? AppTheme.successPrimary
                            : AppTheme.warningPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
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

    // Domyślny widok listy
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
                color: cumulativePercentage >= _majorityThreshold
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
    // 📍 Resetuj flagę przed otwarciem modalu
    _dataWasUpdated = false;

    InvestorDetailsModalHelper.show(
      context: context,
      investor: investor,
      analyticsService: _updateService,
      onEditInvestor: () {
        // Możliwość dodania dodatkowej logiki edycji
      },
      onViewInvestments: () {
        // Funkcjonalność przeniesiona do wnętrza modalu - przycisk automatycznie przełączy na zakładkę
      },
      onUpdateInvestor: (updatedInvestor) {
        // 📍 Oznacz że dane zostały zaktualizowane
        _dataWasUpdated = true;
        // 📍 Odśwież dane po aktualizacji z wymuszeniem przeładowania z serwera
        // TYLKO gdy rzeczywiście były zapisane zmiany w danych inwestora
        // Pozycja scroll zostanie automatycznie zachowana i przywrócona
        _refreshDataAfterUpdate();
      },
    ).then((_) {
      // 📍 Po zamknięciu modalu - sprawdź czy potrzebne jest odświeżenie
      if (!_dataWasUpdated) {
        print(
          '📍 [Analytics] Modal zamknięty bez zmian - nie odświeżam danych',
        );
      }
    });
  }

  // ignore: unused_element
  Widget _buildInvestorInfoSection(InvestorSummary investor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informacje kontaktowe',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundTertiary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildInfoRow(
                Icons.email_rounded,
                'Email',
                investor.client.email.isNotEmpty
                    ? investor.client.email
                    : 'Brak',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.phone_rounded,
                'Telefon',
                investor.client.phone.isNotEmpty
                    ? investor.client.phone
                    : 'Brak',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.business_rounded,
                'Typ klienta',
                investor.client.type.displayName,
              ),
              if (investor.client.unviableInvestments.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.warning_rounded,
                  'Niewykonalne inwestycje',
                  '${investor.client.unviableInvestments.length}',
                  AppTheme.warningPrimary,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, [
    Color? valueColor,
  ]) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildInvestorStatsSection(InvestorSummary investor) {
    final totalCapital = _votingManager.totalViableCapital;
    final investorShare = totalCapital > 0
        ? (investor.viableRemainingCapital / totalCapital) * 100
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statystyki finansowe',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInvestorStatCard(
                'Kapitał pozostały',
                CurrencyFormatter.formatCurrency(
                  investor.viableRemainingCapital,
                ),
                Icons.account_balance_rounded,
                AppTheme.successPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInvestorStatCard(
                'Udział w całości',
                '${investorShare.toStringAsFixed(2)}%',
                Icons.pie_chart_rounded,
                AppTheme.infoPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInvestorStatCard(
                'Kapitał całkowity',
                CurrencyFormatter.formatCurrency(
                  investor.totalInvestmentAmount,
                ),
                Icons.account_balance_wallet_rounded,
                AppTheme.primaryAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInvestorStatCard(
                'Liczba inwestycji',
                investor.investmentCount.toString(),
                Icons.list_alt_rounded,
                AppTheme.warningPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInvestorStatCard(
                'Średnia inwestycja',
                CurrencyFormatter.formatCurrencyShort(
                  investor.investmentCount > 0
                      ? investor.viableRemainingCapital /
                            investor.investmentCount
                      : 0,
                ),
                Icons.calculate_rounded,
                AppTheme.secondaryGold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInvestorStatCard(
                'Zwrot kapitału',
                CurrencyFormatter.formatCurrency(investor.totalRealizedCapital),
                Icons.trending_up_rounded,
                AppTheme.successPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvestorStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildInvestorInvestmentsSection(InvestorSummary investor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _showDeduplicatedProducts
                  ? 'Produkty (${_getUniqueProductsCount(investor)})'
                  : 'Inwestycje (${investor.investments.length})',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (_showDeduplicatedProducts)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'DEDUPLIKOWANE',
                  style: TextStyle(
                    color: AppTheme.primaryAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (investor.client.unviableInvestments.isNotEmpty)
              Container(
                margin: EdgeInsets.only(
                  left: _showDeduplicatedProducts ? 8 : 0,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warningPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${investor.client.unviableInvestments.length} niewykonalne',
                  style: TextStyle(
                    color: AppTheme.warningPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          constraints: BoxConstraints(maxHeight: 200),
          child: _showDeduplicatedProducts
              ? _buildDeduplicatedProductsList(investor)
              : _buildRegularInvestmentsList(investor),
        ),
      ],
    );
  }

  void _navigateToProductDetails(investment) {
    // Sprawdź czy inwestycja ma właściwości potrzebne do nawigacji
    if (investment.productName != null && investment.productName.isNotEmpty) {
      context.go(
        '/products/${Uri.encodeComponent(investment.productName)}?productType=${investment.productType.name}',
      );
    } else {
      // Fallback - przejdź do listy produktów z filtrem typu
      context.go('/products?productType=${investment.productType.name}');
    }
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
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundModal,
        title: Row(
          children: [
            Icon(Icons.gavel_rounded, color: AppTheme.secondaryGold),
            const SizedBox(width: 12),
            Text(
              'Analiza kontroli większościowej',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: Container(
          width: _isTablet ? 500 : 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMajorityAnalysisContent(),
              const SizedBox(height: 20),
              _buildMajorityHoldersList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Zamknij',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _exportMajorityHoldersData,
            icon: Icon(Icons.download_rounded, size: 18),
            label: Text('Eksportuj'),
          ),
        ],
      ),
    );
  }

  Widget _buildMajorityAnalysisContent() {
    final totalCapital = _votingManager.totalViableCapital;
    final majorityCapital = _majorityHolders.fold<double>(
      0.0,
      (sum, holder) => sum + holder.viableRemainingCapital,
    );
    final majorityPercentage = totalCapital > 0
        ? (majorityCapital / totalCapital) * 100
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kluczowe metryki',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            'Próg większości:',
            '${_majorityThreshold.toStringAsFixed(0)}%',
          ),
          _buildMetricRow(
            'Posiadaczy większości:',
            '${_majorityHolders.length}',
          ),
          _buildMetricRow(
            'Kapitał większości:',
            CurrencyFormatter.formatCurrency(majorityCapital),
          ),
          _buildMetricRow(
            'Udział w całości:',
            '${majorityPercentage.toStringAsFixed(1)}%',
          ),
          const Divider(color: AppTheme.borderSecondary),
          Row(
            children: [
              Icon(
                majorityPercentage >= _majorityThreshold
                    ? Icons.check_circle
                    : Icons.warning,
                color: majorityPercentage >= _majorityThreshold
                    ? AppTheme.successPrimary
                    : AppTheme.warningPrimary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  majorityPercentage >= _majorityThreshold
                      ? 'Grupa posiada kontrolę większościową'
                      : 'Grupa nie osiąga progu większości',
                  style: TextStyle(
                    color: majorityPercentage >= _majorityThreshold
                        ? AppTheme.successPrimary
                        : AppTheme.warningPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary)),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMajorityHoldersList() {
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lista posiadaczy większości (${_majorityHolders.length})',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _majorityHolders.length,
              itemBuilder: (context, index) {
                final holder = _majorityHolders[index];
                final percentage = _votingManager.totalViableCapital > 0
                    ? (holder.viableRemainingCapital /
                              _votingManager.totalViableCapital) *
                          100
                    : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.secondaryGold.withOpacity(
                          0.2,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: AppTheme.secondaryGold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              holder.client.name,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${CurrencyFormatter.formatCurrencyShort(holder.viableRemainingCapital)} (${percentage.toStringAsFixed(1)}%)',
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _exportMajorityHoldersData() {
    final data = _majorityHolders
        .map((holder) {
          final percentage = _votingManager.totalViableCapital > 0
              ? (holder.viableRemainingCapital /
                        _votingManager.totalViableCapital) *
                    100
              : 0.0;
          return '${holder.client.name};${holder.client.email};${holder.viableRemainingCapital.toStringAsFixed(2)};${percentage.toStringAsFixed(2)}%';
        })
        .join('\n');

    final csvContent = 'Nazwa;Email;Kapitał;Udział\n$data';
    Clipboard.setData(ClipboardData(text: csvContent));
    Navigator.pop(context);
    _showSuccessSnackBar('Dane posiadaczy większości skopiowane do schowka');
  }

  void _performVotingDistributionAnalysis() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundModal,
        title: Row(
          children: [
            Icon(Icons.poll_rounded, color: AppTheme.secondaryGold),
            const SizedBox(width: 12),
            Text(
              'Analiza rozkładu głosowania',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: Container(
          width: _isTablet ? 600 : 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildVotingAnalysisChart(),
              const SizedBox(height: 20),
              _buildVotingSummaryTable(),
              const SizedBox(height: 20),
              _buildVotingInsights(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Zamknij',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _exportVotingData,
            icon: Icon(Icons.download_rounded, size: 18),
            label: Text('Eksportuj'),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingAnalysisChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Rozkład kapitału głosującego',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: VotingPieChartPainter(
                _votingDistribution,
                _votingManager.totalViableCapital,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingSummaryTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Podsumowanie głosowania',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Table(
            children: [
              TableRow(
                children: [
                  _buildTableHeader('Status'),
                  _buildTableHeader('Kapitał'),
                  _buildTableHeader('Udział'),
                  _buildTableHeader('Liczba'),
                ],
              ),
              ..._buildVotingTableRows(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<TableRow> _buildVotingTableRows() {
    final statuses = [
      VotingStatus.yes,
      VotingStatus.no,
      VotingStatus.abstain,
      VotingStatus.undecided,
    ];

    return statuses.map((status) {
      final percentage = _votingDistribution[status] ?? 0.0;
      final count = _votingCounts[status] ?? 0;
      final capital = _getVotingCapitalForStatus(status);

      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getVotingStatusColor(status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  status.displayName,
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Text(
              CurrencyFormatter.formatCurrencyShort(capital),
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Text(
              count.toString(),
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildVotingInsights() {
    final insights = _generateVotingInsights();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_rounded,
                color: AppTheme.secondaryGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Kluczowe spostrzeżenia',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...insights
              .map(
                (insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        decoration: BoxDecoration(
                          color: insight.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          insight.text,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  List<_Insight> _generateVotingInsights() {
    final insights = <_Insight>[];
    final yesPercentage = _votingDistribution[VotingStatus.yes] ?? 0.0;
    final noPercentage = _votingDistribution[VotingStatus.no] ?? 0.0;
    final undecidedPercentage =
        _votingDistribution[VotingStatus.undecided] ?? 0.0;

    if (yesPercentage >= 51.0) {
      insights.add(
        _Insight(
          'Większość kapitału głosuje ZA - decyzja może zostać podjęta',
          AppTheme.successPrimary,
        ),
      );
    } else if (noPercentage >= 51.0) {
      insights.add(
        _Insight(
          'Większość kapitału głosuje NIE - propozycja zostanie odrzucona',
          AppTheme.errorPrimary,
        ),
      );
    } else {
      insights.add(
        _Insight(
          'Brak większości - wynik zależy od niezdecydowanych głosów',
          AppTheme.warningPrimary,
        ),
      );
    }

    if (undecidedPercentage > 30.0) {
      insights.add(
        _Insight(
          'Znaczący udział niezdecydowanych inwestorów (${undecidedPercentage.toStringAsFixed(1)}%) - warto kontynuować kampanię informacyjną',
          AppTheme.infoPrimary,
        ),
      );
    }

    return insights;
  }

  double _getVotingCapitalForStatus(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return _votingManager.yesVotingCapital;
      case VotingStatus.no:
        return _votingManager.noVotingCapital;
      case VotingStatus.abstain:
        return _votingManager.abstainVotingCapital;
      case VotingStatus.undecided:
        return _votingManager.undecidedVotingCapital;
    }
  }

  void _exportVotingData() {
    final data = _votingDistribution.entries
        .map((entry) {
          final status = entry.key;
          final percentage = entry.value;
          final count = _votingCounts[status] ?? 0;
          final capital = _getVotingCapitalForStatus(status);

          return '${status.displayName};${capital.toStringAsFixed(2)};${percentage.toStringAsFixed(2)}%;${count}';
        })
        .join('\n');

    final csvContent = 'Status;Kapitał PLN;Udział;Liczba inwestorów\n$data';
    Clipboard.setData(ClipboardData(text: csvContent));
    Navigator.pop(context);
    _showSuccessSnackBar('Dane rozkładu głosowania skopiowane do schowka');
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

  // 📈 TREND ANALYSIS METHODS

  Widget _buildPerformanceGrid() {
    final metrics = _calculatePerformanceMetrics();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: _isTablet ? 4 : 2,
      childAspectRatio: _isTablet ? 1.2 : 1.1,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildPerformanceCard(
          'ROI Średni',
          metrics['avgROI']!,
          Icons.trending_up_rounded,
          AppTheme.successPrimary,
        ),
        _buildPerformanceCard(
          'Najwyższy ROI',
          metrics['maxROI']!,
          Icons.star_rounded,
          AppTheme.secondaryGold,
        ),
        _buildPerformanceCard(
          'Efektywność',
          metrics['efficiency']!,
          Icons.speed_rounded,
          AppTheme.infoPrimary,
        ),
        _buildPerformanceCard(
          'Współczynnik Sharpe',
          metrics['sharpeRatio']!,
          Icons.analytics_rounded,
          AppTheme.warningPrimary,
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: _isTablet ? 20 : 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rozkład wydajności portfela',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildPerformanceBarChart()),
        ],
      ),
    );
  }

  Widget _buildPerformanceBarChart() {
    final categories = ['Obligacje', 'Udziały', 'Pożyczki', 'Apartamenty'];
    final performances = _calculateCategoryPerformances();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: categories.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;
        final performance = performances[index];

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 40,
              height: (performance / 100) * 80 + 20,
              decoration: BoxDecoration(
                color: _getPerformanceColor(performance),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              textAlign: TextAlign.center,
            ),
            Text(
              '${performance.toStringAsFixed(1)}%',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Map<String, String> _calculatePerformanceMetrics() {
    if (_allInvestors.isEmpty) {
      return {
        'avgROI': '0.0%',
        'maxROI': '0.0%',
        'efficiency': '0.0%',
        'sharpeRatio': '0.00',
      };
    }

    // Symulowane metryki wydajności - w prawdziwej aplikacji bazowane na historycznych danych
    final totalCapital = _votingManager.totalViableCapital;
    final investorCount = _allInvestors.length;

    // Przykładowe obliczenia ROI
    final avgROI = (totalCapital / 10000000) * 8.5; // Przykładowy ROI
    final maxROI = avgROI * 1.8;
    final efficiency = (investorCount / 100) * 15.0;
    final sharpeRatio = avgROI / 12.0; // Przykładowy współczynnik Sharpe

    return {
      'avgROI': '${avgROI.toStringAsFixed(1)}%',
      'maxROI': '${maxROI.toStringAsFixed(1)}%',
      'efficiency': '${efficiency.toStringAsFixed(1)}%',
      'sharpeRatio': sharpeRatio.toStringAsFixed(2),
    };
  }

  List<double> _calculateCategoryPerformances() {
    // Symulowane dane wydajności dla kategorii
    // W prawdziwej aplikacji to by było obliczane z rzeczywistych danych
    return [12.5, 18.7, 9.8, 15.2]; // Obligacje, Udziały, Pożyczki, Apartamenty
  }

  Color _getPerformanceColor(double performance) {
    if (performance >= 15) return AppTheme.successPrimary;
    if (performance >= 10) return AppTheme.warningPrimary;
    return AppTheme.errorPrimary;
  }

  Widget _buildTrendMetrics() {
    final metrics = _calculateTrendMetrics();

    return Row(
      children: [
        Expanded(
          child: _buildTrendMetricCard(
            'Wzrost kapitału',
            metrics['capitalGrowth']!,
            Icons.trending_up_rounded,
            AppTheme.successPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTrendMetricCard(
            'Nowi inwestorzy',
            metrics['newInvestors']!,
            Icons.person_add_rounded,
            AppTheme.infoPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTrendMetricCard(
            'Średnia inwestycja',
            metrics['avgInvestment']!,
            Icons.account_balance_rounded,
            AppTheme.warningPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: _isTablet ? 18 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    final chartData = _generateTrendChartData();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend kapitału w czasie',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: TrendChartPainter(chartData),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _calculateTrendMetrics() {
    if (_allInvestors.isEmpty) {
      return {
        'capitalGrowth': '+0.0%',
        'newInvestors': '0',
        'avgInvestment': CurrencyFormatter.formatCurrencyShort(0),
      };
    }

    final totalCapital = _votingManager.totalViableCapital;
    final investorCount = _allInvestors.length;
    final avgInvestment =
        totalCapital / (investorCount > 0 ? investorCount : 1);

    // Symulacja wzrostu - w prawdziwej aplikacji to by było z historycznych danych
    final growthPercent =
        (totalCapital / 10000000) * 2.5; // Przykładowa kalkulacja

    return {
      'capitalGrowth': '+${growthPercent.toStringAsFixed(1)}%',
      'newInvestors': investorCount.toString(),
      'avgInvestment': CurrencyFormatter.formatCurrencyShort(avgInvestment),
    };
  }

  List<ChartDataPoint> _generateTrendChartData() {
    // W prawdziwej aplikacji to by były historyczne dane z Firebase
    // Tutaj generujemy przykładowe dane bazując na obecnym stanie
    final points = <ChartDataPoint>[];
    final baseCapital = _votingManager.totalViableCapital;

    for (int i = 0; i < 12; i++) {
      final variance = (i * 0.1) + (i % 3) * 0.05;
      final value = baseCapital * (0.7 + variance);
      points.add(ChartDataPoint(i.toDouble(), value));
    }

    return points;
  }

  // 📋 MULTI-SELECTION METHODS

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedInvestorIds.clear();
    });

    _fabAnimationController.forward();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tryb wyboru aktywny - zaznacz inwestorów'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedInvestorIds.clear();
    });

    _fabAnimationController.reverse();
  }

  void _toggleInvestorSelection(String investorId) {
    setState(() {
      if (_selectedInvestorIds.contains(investorId)) {
        _selectedInvestorIds.remove(investorId);
      } else {
        _selectedInvestorIds.add(investorId);
      }
    });

    // Wyjdź z trybu wyboru jeśli nic nie jest zaznaczone
    if (_selectedInvestorIds.isEmpty) {
      _exitSelectionMode();
    }
  }

  void _selectAllInvestors() {
    setState(() {
      _selectedInvestorIds.clear();
      _selectedInvestorIds.addAll(
        _displayedInvestors.map((investor) => investor.client.id),
      );
    });
  }

  void _deselectAllInvestors() {
    setState(() {
      _selectedInvestorIds.clear();
    });
    _exitSelectionMode();
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

class ChartDataPoint {
  final double x;
  final double y;

  ChartDataPoint(this.x, this.y);
}

class TrendChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;

  TrendChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = AppTheme.secondaryGold
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = AppTheme.secondaryGold.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    // Znajdź min/max dla skalowania
    final minY = data.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    final maxY = data.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    final minX = data.map((p) => p.x).reduce((a, b) => a < b ? a : b);
    final maxX = data.map((p) => p.x).reduce((a, b) => a > b ? a : b);

    // Skaluj punkty do rozmiaru canvas
    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final x = (point.x - minX) / (maxX - minX) * size.width;
      final y = size.height - ((point.y - minY) / (maxY - minY) * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Zamknij wypełnienie
    final lastPoint = data.last;
    final lastX = (lastPoint.x - minX) / (maxX - minX) * size.width;
    fillPath.lineTo(lastX, size.height);
    fillPath.close();

    // Narysuj wypełnienie i linię
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Narysuj punkty
    final pointPaint = Paint()
      ..color = AppTheme.secondaryGold
      ..style = PaintingStyle.fill;

    for (final point in data) {
      final x = (point.x - minX) / (maxX - minX) * size.width;
      final y = size.height - ((point.y - minY) / (maxY - minY) * size.height);
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class VotingPieChartPainter extends CustomPainter {
  final Map<VotingStatus, double> votingDistribution;
  final double totalCapital;

  VotingPieChartPainter(this.votingDistribution, this.totalCapital);

  @override
  void paint(Canvas canvas, Size size) {
    if (totalCapital <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width < size.height
        ? size.width / 2 - 20
        : size.height / 2 - 20;

    double startAngle = -90 * (3.14159 / 180); // Zacznij od góry

    // Narysuj segmenty
    votingDistribution.forEach((status, percentage) {
      if (percentage <= 0) return;

      final sweepAngle = (percentage / 100) * 2 * 3.14159;
      final paint = Paint()
        ..color = _getVotingStatusColorForPainter(status)
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Narysuj etykietę procentową
      if (percentage > 5) {
        // Pokazuj tylko dla większych segmentów
        final labelAngle = startAngle + sweepAngle / 2;
        final labelRadius = radius * 0.7;
        final labelX = center.dx + labelRadius * cos(labelAngle);
        final labelY = center.dy + labelRadius * sin(labelAngle);

        final textPainter = TextPainter(
          text: TextSpan(
            text: '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            labelX - textPainter.width / 2,
            labelY - textPainter.height / 2,
          ),
        );
      }

      startAngle += sweepAngle;
    });

    // Narysuj obramowanie
    final borderPaint = Paint()
      ..color = AppTheme.borderSecondary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, borderPaint);
  }

  Color _getVotingStatusColorForPainter(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return AppTheme.successPrimary;
      case VotingStatus.no:
        return AppTheme.errorPrimary;
      case VotingStatus.abstain:
        return AppTheme.warningPrimary;
      case VotingStatus.undecided:
        return AppTheme.textTertiary;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Helper extension methods for _PremiumInvestorAnalyticsScreenState
extension _PremiumInvestorAnalyticsScreenDeduplication
    on _PremiumInvestorAnalyticsScreenState {
  int _getUniqueProductsCount(InvestorSummary investor) {
    final uniqueProducts = <String>{};
    for (final investment in investor.investments) {
      final productKey =
          '${investment.productName}_${investment.productType.name}_${investment.creditorCompany}';
      uniqueProducts.add(productKey);
    }
    return uniqueProducts.length;
  }

  Widget _buildDeduplicatedProductsList(InvestorSummary investor) {
    final productGroups = <String, List<Investment>>{};

    // Grupuj inwestycje według produktu
    for (final investment in investor.investments) {
      final productKey =
          '${investment.productName}_${investment.productType.name}_${investment.creditorCompany}';
      productGroups.putIfAbsent(productKey, () => []);
      productGroups[productKey]!.add(investment);
    }

    return ListView.builder(
      itemCount: productGroups.length,
      itemBuilder: (context, index) {
        final productKey = productGroups.keys.elementAt(index);
        final productInvestments = productGroups[productKey]!;
        final firstInvestment = productInvestments.first;

        // Oblicz zagregowane wartości
        final totalCapital = productInvestments.fold<double>(
          0.0,
          (sum, inv) => sum + inv.remainingCapital,
        );

        final hasUnviable = productInvestments.any(
          (inv) => investor.client.unviableInvestments.contains(inv.id),
        );

        return GestureDetector(
          onTap: () => _navigateToProductDetails(firstInvestment),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasUnviable
                  ? AppTheme.warningPrimary.withOpacity(0.1)
                  : AppTheme.backgroundTertiary,
              borderRadius: BorderRadius.circular(8),
              border: hasUnviable
                  ? Border.all(color: AppTheme.warningPrimary.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: hasUnviable
                        ? AppTheme.warningPrimary
                        : AppTheme.successPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              firstInvestment.productName,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${productInvestments.length}x',
                              style: TextStyle(
                                color: AppTheme.primaryAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${firstInvestment.creditorCompany} • ${firstInvestment.productType.displayName}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatCurrencyShort(totalCapital),
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (hasUnviable)
                      Text(
                        'CZĘŚĆ NIEWYKONALNA',
                        style: TextStyle(
                          color: AppTheme.warningPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegularInvestmentsList(InvestorSummary investor) {
    return ListView.builder(
      itemCount: investor.investments.length,
      itemBuilder: (context, index) {
        final investment = investor.investments[index];
        final isUnviable = investor.client.unviableInvestments.contains(
          investment.id,
        );

        return GestureDetector(
          onTap: () {
            _navigateToProductDetails(investment);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnviable
                  ? AppTheme.warningPrimary.withOpacity(0.1)
                  : AppTheme.backgroundTertiary,
              borderRadius: BorderRadius.circular(8),
              border: isUnviable
                  ? Border.all(color: AppTheme.warningPrimary.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isUnviable
                        ? AppTheme.warningPrimary
                        : AppTheme.successPrimary,
                    shape: BoxShape.circle,
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
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${investment.creditorCompany} • ${investment.productType.displayName}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatCurrencyShort(
                        investment.remainingCapital,
                      ),
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (isUnviable)
                      Text(
                        'NIEWYKONALNA',
                        style: TextStyle(
                          color: AppTheme.warningPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method for exporting investor data
  void _exportInvestorData(InvestorSummary investor) {
    // Prepare data for export/sharing
    final data = StringBuffer();
    data.writeln('=== ${investor.client.name} ===');
    data.writeln('Email: ${investor.client.email}');
    data.writeln(
      'Status głosowania: ${investor.client.votingStatus.displayName}',
    );
    data.writeln('Typ klienta: ${investor.client.type.displayName}');
    data.writeln('');
    data.writeln('Szczegóły finansowe:');
    data.writeln(
      '• Kapitał pozostały: ${CurrencyFormatter.formatCurrency(investor.viableRemainingCapital)}',
    );
    data.writeln(
      '• Kwota inwestycji: ${CurrencyFormatter.formatCurrency(investor.totalInvestmentAmount)}',
    );
    data.writeln(
      '• Kapitał do restrukturyzacji: ${CurrencyFormatter.formatCurrency(investor.capitalForRestructuring)}',
    );
    data.writeln(
      '• Kapitał zabezpieczony nieruchomościami: ${CurrencyFormatter.formatCurrency(investor.capitalSecuredByRealEstate)}',
    );
    data.writeln('• Liczba inwestycji: ${investor.investmentCount}');

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: data.toString()));

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📋 Dane inwestora skopiowane do schowka'),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 📋 MULTI-SELECTION METHODS

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedInvestorIds.clear();
    });

    _fabAnimationController.forward();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('👆 Dotknij inwestorów aby ich wybrać'),
        backgroundColor: AppTheme.primaryAccent,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedInvestorIds.clear();
    });
  }

  void _toggleInvestorSelection(String investorId) {
    setState(() {
      if (_selectedInvestorIds.contains(investorId)) {
        _selectedInvestorIds.remove(investorId);
      } else {
        _selectedInvestorIds.add(investorId);
      }
    });
  }

  void _selectAllVisibleInvestors() {
    setState(() {
      for (final investor in _displayedInvestors) {
        _selectedInvestorIds.add(investor.client.id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedInvestorIds.clear();
    });
  }

  void _showEmailDialog() {
    if (_selectedInvestors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Nie wybrano żadnych inwestorów'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnhancedInvestorEmailDialog(
        selectedInvestors: _selectedInvestors,
        onEmailSent: () {
          _exitSelectionMode();
        },
      ),
    );
  }

  void _showExportDialog() {
    if (_selectedInvestors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Nie wybrano żadnych inwestorów'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => InvestorExportDialog(
        selectedInvestors: _selectedInvestors,
        onExportComplete: () {
          _exitSelectionMode();
        },
      ),
    );
  }
}
