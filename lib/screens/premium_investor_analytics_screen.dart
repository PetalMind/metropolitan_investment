import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:html' as html show Blob, Url, AnchorElement;
// import '../theme/app_theme.dart'; // Replaced with app_theme_professional.dart
import '../theme/app_theme_professional.dart';
import '../models_and_services.dart'; // Centralny export wszystkich modeli i serwisów
// Zamieniam na istniejące dialogi zamiast nowych komponentów
// Zastąpiono starymi dialogami modułowy system email
// import '../widgets/dialogs/investor_email_dialog.dart';
// import '../widgets/dialogs/investor_export_dialog.dart';
import '../screens/wow_email_editor_screen.dart';
import '../services/investor_analytics_service.dart'
    as ia_service; // Tylko dla InvestorAnalyticsResult conflict resolution
import '../widgets/premium_analytics/system_stats_widget.dart';
import '../widgets/premium_analytics/voting_distribution_widget.dart';
import '../widgets/premium_analytics/investors_list_widget.dart';
import '../widgets/premium_analytics/investors_search_filter_widget.dart';
import '../widgets/premium_analytics/performance_metrics_widget.dart';
import '../widgets/premium_analytics/trend_analysis_widget.dart';
import '../widgets/navigation/premium_tab_navigation.dart';
import '../widgets/navigation/premium_tab_helper.dart';
import '../widgets/majority_analysis/majority_analysis_view.dart'
    as majority_widget;
const String kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

// === Przywrócona definicja widgetu i stanu ===
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
  // === POLA PRZYWRÓCONE ===
  // RBAC
  bool get canEdit => Provider.of<AuthProvider>(context, listen: false).isAdmin;
  // Serwisy - 🚀 UJEDNOLICONE Z DASHBOARD
  final OptimizedProductService _optimizedProductService =
      OptimizedProductService();
  final EnhancedClientService _enhancedClientService =
      EnhancedClientService(); // 🚀 DODANE: Do pobierania wszystkich klientów
  final AnalyticsMigrationService _migrationService =
      AnalyticsMigrationService();
  final FirebaseFunctionsPremiumAnalyticsService _premiumAnalyticsService =
      FirebaseFunctionsPremiumAnalyticsService();
  final FirebaseFunctionsAnalyticsServiceUpdated _analyticsService =
      FirebaseFunctionsAnalyticsServiceUpdated();

  final VotingAnalysisManager _votingManager = VotingAnalysisManager();
  // Kontrolery
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  // Animacje
  late AnimationController _filterAnimationController;
  late AnimationController _fabAnimationController;
  late AnimationController _statsAnimationController;
  late TabController _tabController;
  late Animation<Offset> _filterSlideAnimation;

  // Dane główne
  List<InvestorSummary> _allInvestors = [];
  List<InvestorSummary> _displayedInvestors = [];
  InvestorAnalyticsResult? _currentResult;
  PremiumAnalyticsResult? _premiumResult;

  // Analiza większości
  double _majorityThreshold = 51.0;
  List<InvestorSummary> _majorityHolders = [];

  // Głosowanie
  Map<VotingStatus, double> _votingDistribution = {};
  Map<VotingStatus, int> _votingCounts = {};

  // Dashboard statistics for unified calculations
  UnifiedDashboardStatistics? _dashboardStatistics;

  // Stany ładowania
  bool _isLoading = true;
  final bool _isLoadingMore = false;
  // Brak zmiennej _isRefreshing już nie potrzebujemy
  bool _dataWasUpdated = false;
  String? _error;

  // Paginacja
  int _currentPage = 1;
  final int _pageSize = 10000;
  int _totalCount = 0;

  // Filtry / sortowanie
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

  // Widoki
  bool _isFilterVisible = false;
  bool _showDeduplicatedProducts = true;
  ViewMode _investorsViewMode = ViewMode.list;
  ViewMode _majorityViewMode = ViewMode.list;


  // Selekcja
  bool _isSelectionMode = false;
  bool _isExportMode = false; // 🚀 NOWY: Tryb eksportu
  bool _isEmailMode = false; // 🚀 NOWY: Tryb email
  final Set<String> _selectedInvestorIds = <String>{};
  List<InvestorSummary> get _selectedInvestors => _allInvestors
      .where((i) => _selectedInvestorIds.contains(i.client.id))
      .toList();

  // Responsywność
  bool get _isTablet => MediaQuery.of(context).size.width > 768;

  // Timery
  Timer? _searchDebounceTimer;
  Timer? _refreshTimer;
  static const Duration _searchDebounceDelay = Duration(milliseconds: 300);
  static const Duration _refreshInterval = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery!.isNotEmpty) {
      _searchQuery = widget.initialSearchQuery!;
      _searchController.text = _searchQuery;
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

  void _initializeAnimations() {
    _tabController = TabController(length: 4, vsync: this);
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
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _filterAnimationController,
            curve: Curves.easeOutQuart,
          ),
        );
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
      // 🚀 UJEDNOLICONE Z DASHBOARD: Sprawdź OptimizedProductService dla statystyk
      print(
        '🎯 [Premium Analytics] Pobieram statystyki z OptimizedProductService...',
      );

      final optimizedResult = await _optimizedProductService
          .getAllProductsOptimized(
            forceRefresh: true,
            includeStatistics: true,
            maxProducts: 10000,
          );

      // 🆕 SPRAWDŹ czy OptimizedProduct zawiera statusy głosowania
      bool hasVotingStatuses = false;
      if (optimizedResult.products.isNotEmpty) {
        final firstProduct = optimizedResult.products.first;
        if (firstProduct.topInvestors.isNotEmpty) {
          final firstInvestor = firstProduct.topInvestors.first;
          hasVotingStatuses = firstInvestor.votingStatus != null;
          print(
            '🔍 [Premium Analytics] Status głosowania pierwszy inwestor: ${firstInvestor.votingStatus}',
          );
        }
      }

      if (hasVotingStatuses) {
        // ✅ OptimizedProduct zawiera statusy głosowania - konwertuj bezpośrednio
        print(
          '✅ [Premium Analytics] OptimizedProduct zawiera statusy głosowania - używam bezpośrednio',
        );

        final convertedInvestors =
            await _convertOptimizedProductsToInvestorSummaries(
              optimizedResult.products,
            );

        // Zachowaj statystyki z OptimizedProduct dla spójności z Dashboard
        if (optimizedResult.statistics != null) {
          _dashboardStatistics = _convertGlobalStatsToUnified(
            optimizedResult.statistics!,
          );
          print(
            '✅ [Premium Analytics] Zachowuję statystyki z OptimizedProductService',
          );
          print(
            '💰 [Premium Analytics] totalInvestmentAmount: ${_dashboardStatistics!.totalInvestmentAmount}',
          );
        }

        // Procesuj dane
        // 🚀 UJEDNOLICENIE Z DASHBOARD: Używaj totalRemainingCapital z serwera
        final totalRemainingCapitalFromServer =
            optimizedResult.statistics?.totalRemainingCapital ?? 0.0;

        print(
          '✅ [Premium Analytics] Używam totalRemainingCapital z OptimizedProductService: ${totalRemainingCapitalFromServer.toStringAsFixed(2)}',
        );

        final enhanced = InvestorAnalyticsResult(
          investors: convertedInvestors,
          allInvestors: convertedInvestors,
          totalCount: convertedInvestors.length,
          currentPage: 1,
          pageSize: convertedInvestors.length,
          hasNextPage: false,
          hasPreviousPage: false,
          // 🚀 KLUCZ: Używaj totalRemainingCapital z serwera zamiast viableRemainingCapital
          totalViableCapital: totalRemainingCapitalFromServer,
          votingDistribution:
              {}, // Zostanie obliczone w _calculateVotingAnalysis
          executionTimeMs: 0, // Placeholder
          source: 'OptimizedProductService',
        );

        _processAnalyticsResult(enhanced);
        _calculateMajorityAnalysis();
        _calculateVotingAnalysis();

        print('✅ [Premium Analytics] OptimizedProduct zakończone pomyślnie');

        setState(() {
          _isLoading = false;
        });

        return; // Sukces - nie potrzebujemy fallback
      } else {
        // ⚠️ OptimizedProduct nie zawiera statusów głosowania - przejdź na fallback
        print(
          '⚠️ [Premium Analytics] OptimizedProduct nie zawiera statusów głosowania',
        );
        print(
          '🔄 [Premium Analytics] Przechodzę na fallback z pełnymi danymi klientów...',
        );

        // Zachowaj statystyki z OptimizedProduct dla spójności z Dashboard
        if (optimizedResult.statistics != null) {
          _dashboardStatistics = _convertGlobalStatsToUnified(
            optimizedResult.statistics!,
          );
          print(
            '✅ [Premium Analytics] Zachowuję statystyki z OptimizedProductService',
          );
          print(
            '💰 [Premium Analytics] totalInvestmentAmount: ${_dashboardStatistics!.totalInvestmentAmount}',
          );
        }

        // Wyrzuć wyjątek aby przejść na fallback z pełnymi danymi klientów
        throw Exception(
          'Potrzebuję pełnych danych klientów dla głosowania - używam fallback',
        );
      }
    } catch (fallbackError) {
      print(
        '❌ [Premium Analytics] Błąd OptimizedProductService: $fallbackError',
      );

      // 🔄 FALLBACK: Spróbuj starego sposobu jako ostatnią deską ratunku
      try {
        print(
          '🔄 [Premium Analytics] Próbuje fallback na AnalyticsMigrationService...',
        );

        final fallbackResult = await _migrationService
            .getInvestorsSortedByRemainingCapital(
              page: _currentPage,
              pageSize: _pageSize,
              sortBy: _sortBy,
              sortAscending: _sortAscending,
              includeInactive: _includeInactive,
              votingStatusFilter: _selectedVotingStatus,
              clientTypeFilter: _selectedClientType,
              showOnlyWithUnviableInvestments: _showOnlyWithUnviableInvestments,
              forceRefresh: true,
            );

        final enhanced = _convertToEnhancedResult(fallbackResult);
        _processAnalyticsResult(enhanced);
        _calculateMajorityAnalysis();
        _calculateVotingAnalysis();

        print('✅ [Premium Analytics] Fallback zakończony pomyślnie');

        setState(() {
          _isLoading = false;
        });
      } catch (finalError) {
        print('❌ [Premium Analytics] Ostateczny błąd: $finalError');
        if (mounted) {
          setState(() {
            _error = _handleAnalyticsError(finalError);
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _loadMoreData() async {
    // Nie ładuj więcej danych - teraz ładujemy wszystkie od razu
    return;
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    try {
      await _loadInitialData();
    } finally {
      // Refresh zakończony
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
            backgroundColor: AppThemePro.statusSuccess,
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
            backgroundColor: AppThemePro.statusError,
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
        final capital =
            investor.totalRemainingCapital; // 🚀 UJEDNOLICENIE z Dashboard
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

    // Update voting analysis - używając wartości z serwera dla lepszej dokładności
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

    // Priorytet: Zawsze używaj danych z premium analytics jeśli są dostępne
    if (_premiumResult != null) {
      _majorityHolders = _premiumResult!.majorityAnalysis.majorityHolders;
      _majorityThreshold = _premiumResult!.majorityAnalysis.majorityThreshold;

      print(
        '✅ [MajorityAnalysis] Używam danych z premium analytics: ${_majorityHolders.length} większościowych posiadaczy',
      );
      return;
    }

    // 🔍 LOKALNE OBLICZENIA (FALLBACK)
    print('⚠️ [MajorityAnalysis] Używam lokalnych obliczeń jako fallback');

    // Pobierz totalViableCapital z serwera jeśli dostępny
    double totalCapital;
    if (_currentResult != null) {
      totalCapital = _currentResult!.totalViableCapital;
      print('   - Używam totalViableCapital z serwera: $totalCapital');
    } else {
      // ⭐ FALLBACK: używaj totalRemainingCapital (dla analizy większości właściwe)
      totalCapital = _allInvestors.fold<double>(
        0.0,
        (sum, investor) => sum + investor.totalRemainingCapital,
      );
      print('   - Obliczam lokalnie totalCapital (remainingCapital): $totalCapital');
    }

    // Sortuj inwestorów według kapitału pozostałego malejąco (zgodnie z Dashboard)
    final sortedInvestors = List<InvestorSummary>.from(_allInvestors);
    sortedInvestors.sort(
      (a, b) => b.totalRemainingCapital.compareTo(a.totalRemainingCapital),
    );

    // Znajdź minimalną grupę która tworzy większość (≥51%)
    _majorityHolders = [];
    double accumulatedCapital = 0.0;

    for (final investor in sortedInvestors) {
      _majorityHolders.add(investor);
      // 🚀 UJEDNOLICENIE: używaj totalRemainingCapital zamiast viableRemainingCapital
      accumulatedCapital += investor.totalRemainingCapital;

      final accumulatedPercentage = totalCapital > 0
          ? (accumulatedCapital / totalCapital) * 100
          : 0.0;

      // Gdy osiągniemy 51%, zatrzymaj się
      if (accumulatedPercentage >= _majorityThreshold) {
        break;
      }
    }

    print(
      '   - Znaleziono ${_majorityHolders.length} większościowych posiadaczy (>$_majorityThreshold%)',
    );
  }

  void _calculateVotingAnalysis() {
    if (_allInvestors.isEmpty) return;

    // Priorytet: Zawsze używaj danych z premium analytics jeśli są dostępne
    if (_premiumResult != null) {
      _votingDistribution = {
        VotingStatus.yes:
            _premiumResult!.votingAnalysis.votingDistribution['yes'] ?? 0.0,
        VotingStatus.no:
            _premiumResult!.votingAnalysis.votingDistribution['no'] ?? 0.0,
        VotingStatus.abstain:
            _premiumResult!.votingAnalysis.votingDistribution['abstain'] ?? 0.0,
        VotingStatus.undecided:
            _premiumResult!.votingAnalysis.votingDistribution['undecided'] ??
            0.0,
      };

      _votingCounts = {
        VotingStatus.yes:
            _premiumResult!.votingAnalysis.votingCounts['yes'] ?? 0,
        VotingStatus.no: _premiumResult!.votingAnalysis.votingCounts['no'] ?? 0,
        VotingStatus.abstain:
            _premiumResult!.votingAnalysis.votingCounts['abstain'] ?? 0,
        VotingStatus.undecided:
            _premiumResult!.votingAnalysis.votingCounts['undecided'] ?? 0,
      };

      print('✅ [VotingAnalysis] Używam danych z premium analytics');
      return;
    }

    // 🔍 LOKALNE OBLICZENIA (FALLBACK)
    print('⚠️ [VotingAnalysis] Używam lokalnych obliczeń jako fallback');

    // Zaktualizuj dane w VotingAnalysisManager z właściwymi inwestorami i totalCapital
    if (_currentResult != null) {
      // Jeśli mamy dostęp do serwera, użyj jego totalViableCapital
      _votingManager.calculateVotingCapitalDistribution(_allInvestors);
      print(
        '   - Używam totalViableCapital z serwera dla VotingAnalysisManager',
      );
    } else {
      // Standardowe obliczenie
      _votingManager.calculateVotingCapitalDistribution(_allInvestors);
    }

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
          // 🚀 UJEDNOLICENIE: używaj totalRemainingCapital dla spójności z Dashboard
          comparison = a.totalRemainingCapital.compareTo(
            b.totalRemainingCapital,
          );
          break;
        case 'totalValue':
          comparison = a.totalRemainingCapital.compareTo(
            b.totalRemainingCapital,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              AppThemePro.primaryDark,
              AppThemePro.backgroundPrimary,
              AppThemePro.backgroundSecondary.withValues(alpha: 0.8),
              AppThemePro.backgroundPrimary,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildTabBar(),
              Expanded(
                child: _isExportMode
                    ? _buildInvestorsTab() // W trybie eksportu tylko tab Inwestorzy
                    : TabBarView(
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
      ),
      // 🚀 USUNIĘTO: FloatingActionButton - zastąpiony ikoną eksportu w AppBar
    );
  }

  Widget _buildAppBar() {
    return PremiumAnalyticsHeader(
      isTablet: _isTablet,
      canEdit: canEdit,
      totalCount: _totalCount,
      isLoading: _isLoading,
      isSelectionMode: _isSelectionMode,
      isExportMode: _isExportMode,
      isEmailMode: _isEmailMode,
      isFilterVisible: _isFilterVisible,
      selectedInvestorIds: _selectedInvestorIds,
      displayedInvestors: _displayedInvestors,
      onToggleExport: _toggleExportMode,
      onToggleEmail: _toggleEmailMode,
      onToggleFilter: _toggleFilterPanel,
      onSelectAll: _selectAllVisibleInvestors,
      onClearSelection: _clearSelection,
    );
  }

  Widget _buildTabBar() {
    return PremiumTabNavigation(
      tabController: _tabController,
      tabs: PremiumTabHelper.getAnalyticsTabItems(),
      isTablet: _isTablet,
      isExportMode: _isExportMode,
      isEmailMode: _isEmailMode,
      customExportBar: _isExportMode
          ? PremiumTabHelper.buildExportModeBar(
              selectedCount: _selectedInvestorIds.length,
              onComplete: () => _showExportFormatDialog(),
              onClose: _toggleExportMode,
            )
          : null,
      customEmailBar: _isEmailMode
          ? PremiumTabHelper.buildEmailModeBar(
              selectedCount: _selectedInvestorIds.length,
              onSendEmails: () => _sendEmailToSelectedInvestors(),
              onClose: _toggleEmailMode,
            )
          : null,
    );
  }

  Widget _buildExportModeBanner() {
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppThemePro.accentGold.withOpacity(0.1),
              AppThemePro.accentGoldMuted.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppThemePro.accentGold.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppThemePro.accentGold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.download_rounded,
                color: AppThemePro.primaryDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tryb eksportu aktywny',
                    style: TextStyle(
                      color: AppThemePro.accentGold,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Zaznacz inwestorów, których dane chcesz wyeksportować. Następnie kliknij "Dokończ eksport" w górnej części ekranu.',
                    style: TextStyle(
                      color: AppThemePro.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedInvestorIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppThemePro.accentGold,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_selectedInvestorIds.length} wybranych',
                  style: TextStyle(
                    color: AppThemePro.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (_isFilterVisible) _buildFilterPanel(),
        if (_isLoading)
          _buildLoadingSliver()
        else if (_error != null)
          _buildErrorSliver()
        else ...[
          _buildSystemStatsSliver(),
          _buildVotingOverviewSliver(),
          _buildQuickInsightsSliver(),
        ],
      ],
    );
  }

  Widget _buildInvestorsTab() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (_isExportMode) _buildExportModeBanner(),
        _buildEnhancedSearchFilterSection(),
        if (_isLoading)
          _buildLoadingSliver()
        else if (_error != null)
          _buildErrorSliver()
        else
          _buildEnhancedInvestorsContent(),
        if (_isLoadingMore) _buildLoadingMoreSliver(),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (_isFilterVisible) _buildFilterPanel(),
        if (_isLoading)
          _buildLoadingSliver()
        else if (_error != null)
          _buildErrorSliver()
        else ...[
          _buildPerformanceMetricsSliver(),
          _buildVotingDistributionSliver(),
          _buildTrendAnalysisSliver(),
        ],
      ],
    );
  }

  Widget _buildMajorityTab() {
    if (_isLoading) {
      return _buildLoadingSliver();
    }

    if (_error != null) {
      return _buildErrorSliver();
    }

    // Oblicz całkowity kapitał z wszystkich inwestorów
    final totalCapital = _majorityHolders.fold<double>(
      0.0,
      (sum, investor) => sum + investor.totalRemainingCapital,
    );

    return majority_widget.MajorityAnalysisView(
      majorityHolders: _majorityHolders,
      majorityThreshold: _majorityThreshold,
      totalCapital: totalCapital,
      isTablet: _isTablet,
      viewMode: majority_widget.ViewMode.cards, // Domyślny tryb widoku
      onInvestorTap: (investor) {
        // Nawiguj do sekcji Klienci z parametrem klienta do pokazania w dialogu
        context.go('/clients?showClient=${investor.client.id}');
      },
    );
  }

  // 🎨 SPECIALIZED UI COMPONENTS

  Widget _buildFilterPanel() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _filterSlideAnimation,
        child: Container(
          margin: EdgeInsets.all(_isTablet ? 16 : 12),
          decoration: AppThemePro.premiumCardDecoration,
          child: ExpansionTile(
            title: Text(
              'Zaawansowane filtry',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: Icon(
              Icons.filter_list_rounded,
              color: AppThemePro.accentGold,
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
      backgroundColor: AppThemePro.surfaceCard,
      selectedColor: AppThemePro.accentGold.withOpacity(0.2),
      checkmarkColor: AppThemePro.accentGold,
      labelStyle: TextStyle(
        color: isSelected ? AppThemePro.accentGold : AppThemePro.textSecondary,
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
          ).textTheme.titleSmall?.copyWith(color: AppThemePro.textSecondary),
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
      backgroundColor: AppThemePro.surfaceCard,
      selectedColor: AppThemePro.accentGold.withOpacity(0.2),
      checkmarkColor: AppThemePro.accentGold,
      labelStyle: TextStyle(
        color: isSelected ? AppThemePro.accentGold : AppThemePro.textSecondary,
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
          ).textTheme.titleSmall?.copyWith(color: AppThemePro.textSecondary),
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
          activeColor: AppThemePro.accentGold,
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
          activeColor: AppThemePro.accentGold,
        ),
        CheckboxListTile(
          title: Text('Tylko z niewykonalnymi inwestycjami'),
          value: _showOnlyWithUnviableInvestments,
          onChanged: (value) {
            setState(() => _showOnlyWithUnviableInvestments = value ?? false);
            _applyFiltersAndSort();
          },
          activeColor: AppThemePro.statusError,
        ),
        CheckboxListTile(
          title: Text('Uwzględnij nieaktywnych'),
          value: _includeInactive,
          onChanged: (value) {
            setState(() => _includeInactive = value ?? false);
            _loadInitialData();
          },
          activeColor: AppThemePro.statusWarning,
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
          style: TextButton.styleFrom(foregroundColor: AppThemePro.statusError),
        ),
        ElevatedButton.icon(
          onPressed: () => _toggleFilterPanel(),
          icon: Icon(Icons.check_rounded),
          label: Text('Zastosuj'),
        ),
      ],
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
              ? AppThemePro.backgroundPrimary
              : AppThemePro.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selectedColor: AppThemePro.accentGold,
      backgroundColor: AppThemePro.backgroundTertiary,
      checkmarkColor: AppThemePro.backgroundPrimary,
      side: BorderSide(
        color: isSelected
            ? AppThemePro.accentGold
            : AppThemePro.borderSecondary,
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

  // 🗑️ Usunięto stare metody przycisków - przeniesione do PremiumAnalyticsHeader

  SliverToBoxAdapter _buildSystemStatsSliver() {
    return SliverToBoxAdapter(
      child: SystemStatsWidget(
        isLoading: _isLoading,
        isTablet: _isTablet,
        allInvestors: _allInvestors,
        dashboardStatistics: _dashboardStatistics,
        premiumResult: _premiumResult,
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
          ).textTheme.titleSmall?.copyWith(color: AppThemePro.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildVotingStatusChip(null, 'Wszystkie'),
            _buildVotingStatusChip(VotingStatus.yes, 'TAK'),
            _buildVotingStatusChip(VotingStatus.no, 'NIE'),
            _buildVotingStatusChip(VotingStatus.abstain, 'WSTRZYMUJE'),
            _buildVotingStatusChip(VotingStatus.undecided, 'NIEZDEC.'),
          ],
        ),
      ],
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

  // � DOWNLOAD FILE METHOD
  Future<void> _downloadFile(
    String base64Data,
    String filename,
    String contentType,
  ) async {
    try {
      // PEŁNA WALIDACJA NULL-SAFE Z ASSERT'ami w debug mode
      assert(base64Data.isNotEmpty, 'base64Data nie może być pusty');
      assert(filename.isNotEmpty, 'filename nie może być pusty');

      if (base64Data.isEmpty) {
        throw Exception('Dane pliku są puste');
      }

      if (filename.isEmpty) {
        throw Exception('Nazwa pliku jest pusta');
      }

      // Zabezpieczenie contentType - jeśli null lub pusty, użyj domyślnego
      final safeContentType = (contentType.isNotEmpty)
          ? contentType
          : 'application/octet-stream';

      print(
        '🔍 Rozpoczynam pobieranie pliku: $filename (${base64Data.length} znaków base64)',
      );
      print('📄 Content type: $safeContentType');

      // Dekoduj base64 do bajtów - może rzucić wyjątek jeśli nieprawidłowy base64
      late List<int> bytes;
      try {
        bytes = base64Decode(base64Data);
      } catch (decodeError) {
        throw Exception('Błąd dekodowania base64: $decodeError');
      }

      print('📦 Zdekodowano ${bytes.length} bajtów');

      // Sprawdź czy jesteśmy na web
      if (kIsWeb) {
        try {
          // Web - użyj URL.createObjectURL i <a> download
          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrl(blob);

          html.AnchorElement(href: url)
            ..setAttribute('download', filename)
            ..click();

          // Cleanup
          html.Url.revokeObjectUrl(url);

          print('✅ Plik pobrany pomyślnie przez przeglądarkę');
        } catch (webError) {
          print('❌ Błąd pobierania w przeglądarce: $webError');
          throw Exception('Błąd pobierania w przeglądarce: $webError');
        }
      } else {
        // Mobile/Desktop - użyj path_provider
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$filename';

        final file = File(filePath);
        await file.writeAsBytes(bytes);

        print('Plik zapisany w: $filePath');
      }
    } catch (e) {
      print('❌ [_downloadFile] Błąd pobierania pliku: $e');
      print(
        '❌ [_downloadFile] Parametry: base64Length=${base64Data.length}, filename=$filename, contentType=$contentType',
      );
      rethrow;
    }
  }

  // �🚀 NOWE FUNKCJONALNOŚCI: EMAIL I EKSPORT

  /// 🔄 Doładowuje pełne dane klientów z Firebase gdy są potrzebne funkcje email/eksportu
  Future<void> _ensureFullClientData() async {
    // Sprawdź czy klienci mają pełne dane (emaile)
    bool hasFullClientData = false;
    if (_allInvestors.isNotEmpty) {
      final firstClient = _allInvestors.first.client;
      hasFullClientData =
          firstClient.email.isNotEmpty ||
          firstClient.phone.isNotEmpty ||
          firstClient.address.isNotEmpty;
    }

    if (hasFullClientData) {
      print(
        '✅ [Premium Analytics] Klienci mają już pełne dane - nie pobieram z Firebase',
      );
      return;
    }

    print(
      '🔄 [Premium Analytics] Doładowuję pełne dane klientów z Firebase dla funkcji email/eksportu...',
    );

    try {
      final IntegratedClientService clientService = IntegratedClientService();
      final allClients = await clientService.getAllClients();
      final Map<String, Client> fullClientsById = {
        for (final client in allClients) client.id: client,
      };

      print(
        '✅ [Premium Analytics] Pobrano ${fullClientsById.length} pełnych klientów z Firebase',
      );

      // Zaktualizuj istniejących inwestorów z pełnymi danymi klientów
      final updatedInvestors = <InvestorSummary>[];

      for (final investor in _allInvestors) {
        final fullClient = fullClientsById[investor.client.id];
        if (fullClient != null) {
          // Zastąp klienta pełnymi danymi z Firebase, zachowując status głosowania z OptimizedProduct
          final updatedClient = fullClient.copyWith(
            votingStatus: investor
                .client
                .votingStatus, // Zachowaj status głosowania z OptimizedProduct
          );

          final updatedInvestor = InvestorSummary(
            client: updatedClient,
            investments: investor.investments,
            totalRemainingCapital: investor.totalRemainingCapital,
            totalSharesValue: investor.totalSharesValue,
            totalValue: investor.totalValue,
            totalInvestmentAmount: investor.totalInvestmentAmount,
            totalRealizedCapital: investor.totalRealizedCapital,
            capitalSecuredByRealEstate: investor.capitalSecuredByRealEstate,
            capitalForRestructuring: investor.capitalForRestructuring,
            investmentCount: investor.investmentCount,
          );

          updatedInvestors.add(updatedInvestor);
        } else {
          // Jeśli nie znaleziono klienta w Firebase, zostaw oryginalnego
          updatedInvestors.add(investor);
        }
      }

      setState(() {
        _allInvestors = updatedInvestors;
      });

      // Ponownie zastosuj filtry z nowymi danymi
      _applyFiltersAndSort();

      print(
        '🔄 [Premium Analytics] Zaktualizowano ${updatedInvestors.length} inwestorów z pełnymi danymi klientów',
      );
    } catch (e) {
      print(
        '⚠️ [Premium Analytics] Błąd podczas ładowania pełnych danych klientów: $e',
      );
      // Kontynuuj bez pełnych danych - funkcje email/eksportu będą działać z ograniczeniami
    }
  }

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
          // Dialog already handles its own closure, so we don't call Navigator.of(context).pop() here
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
          content: Text('❌ Najpierw wybierz odbiorców maili\n💡 Użyj trybu email aby wybrać inwestorów'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      
      if (!_isEmailMode && !_isSelectionMode) {
        _toggleEmailMode();
      }
      return;
    }

    // Filtruj inwestorów z prawidłowymi emailami
    final investorsWithEmail = _selectedInvestors
        .where(
          (investor) =>
              investor.client.email.isNotEmpty &&
              RegExp(
                r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
              ).hasMatch(investor.client.email),
        )
        .toList();

    if (investorsWithEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Wybrani inwestorzy nie mają prawidłowych adresów email'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WowEmailEditorScreen(
          selectedInvestors: investorsWithEmail,
          initialSubject: 'Informacje o inwestorach - Metropolitan Investment',
        ),
      ),
    );

    // Sprawdź czy emaile zostały wysłane pomyślnie
    if (result == true && mounted) {
      _toggleEmailMode(); // Wyłącz tryb email po wysłaniu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Emaile zostały wysłane do ${investorsWithEmail.length} odbiorców',
          ),
          backgroundColor: AppThemePro.statusSuccess,
        ),
      );
    }
  }

  // Stub implementations for missing methods
  Widget _buildVotingOverviewSliver() {
    return SliverToBoxAdapter(
      child: VotingDistributionWidget(
        isLoading: _isLoading,
        isTablet: _isTablet,
        votingDistribution: _votingDistribution,
        votingCounts: _votingCounts,
        totalCount: _totalCount,
      ),
    );
  }


  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return AppThemePro.statusSuccess;
      case VotingStatus.no:
        return AppThemePro.statusError;
      case VotingStatus.abstain:
        return AppThemePro.statusWarning;
      case VotingStatus.undecided:
        return AppThemePro.neutralGray;
    }
  }

  Widget _buildQuickInsightsSliver() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(_isTablet ? 16 : 12),
        padding: const EdgeInsets.all(20),
        decoration: AppThemePro.premiumCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_rounded, color: AppThemePro.accentGold),
                const SizedBox(width: 8),
                Text(
                  'Kluczowe spostrzeżenia',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppThemePro.textPrimary,
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
                  style: TextStyle(
                    color: AppThemePro.textSecondary,
                    height: 1.4,
                  ),
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
          AppThemePro.accentGold,
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
          AppThemePro.statusSuccess,
        ),
      );
    } else if (undecidedPercentage > 80.0) {
      insights.add(
        _Insight(
          'Większość inwestorów (${undecidedPercentage.toStringAsFixed(1)}%) jest niezdecydowana',
          AppThemePro.statusWarning,
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
          AppThemePro.accentGold,
        ),
      );
    }

    return insights;
  }

  Widget _buildLoadingSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnalyticsShimmerLayouts.investorOverview(),
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
              color: AppThemePro.statusError,
            ),
            const SizedBox(height: 16),
            Text(
              'Błąd ładowania danych',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Nieznany błąd',
              style: TextStyle(color: AppThemePro.textSecondary),
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
      onInvestorTap: (_isSelectionMode || _isExportMode)
          ? (investor) => _toggleInvestorSelection(investor.client.id)
          : _showInvestorDetails,
      isSelectionMode:
          _isSelectionMode ||
          _isExportMode, // Aktivuj selekcję także w trybie eksportu
      selectedInvestorIds: _selectedInvestorIds,
      onInvestorSelectionToggle: _toggleInvestorSelection,
    );
  }

  // 🎨 ENHANCED INVESTORS TAB COMPONENTS

  Widget _buildEnhancedSearchFilterSection() {
    return InvestorsSearchFilterWidget(
      searchController: _searchController,
      searchQuery: _searchQuery,
      onSearchChanged: (query) {
        setState(() => _searchQuery = query);
        _applyFiltersAndSort();
      },
      initialSearchQuery: widget.initialSearchQuery,
      isFilterVisible: _isFilterVisible,
      onToggleFilter: _toggleFilterPanel,
      onResetFilters: _resetFilters,
      isTablet: _isTablet,
      selectedVotingStatus: _selectedVotingStatus,
      onVotingStatusChanged: (status) {
        setState(() => _selectedVotingStatus = status);
        _applyFiltersAndSort();
      },
      sortBy: _sortBy,
      sortAscending: _sortAscending,
      onSortChanged: (sortKey) {
        setState(() => _sortBy = sortKey);
        _applyFiltersAndSort();
      },
      onSortDirectionChanged: () {
        setState(() => _sortAscending = !_sortAscending);
        _applyFiltersAndSort();
      },
    );
  }

  Widget _buildEnhancedInvestorsContent() {
    return InvestorsListWidget(
      investors: _displayedInvestors,
      majorityHolders: _majorityHolders,
      totalViableCapital: _votingManager.totalViableCapital,
      isTablet: _isTablet,
      onInvestorTap: (_isSelectionMode || _isExportMode)
          ? (investor) => _toggleInvestorSelection(investor.client.id)
          : _showInvestorDetails,
      isSelectionMode: _isSelectionMode || _isExportMode,
      selectedInvestorIds: _selectedInvestorIds,
      onInvestorSelectionToggle: _toggleInvestorSelection,
    );
  }

  // 🎨 SYSTEM STATS AND ANALYTICS

  TextStyle _getTableHeaderStyle() {
    return TextStyle(
      color: AppThemePro.textPrimary,
      fontWeight: FontWeight.w700,
      fontSize: 13,
    );
  }

  Widget _buildLoadingMoreSliver() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: PremiumShimmerLoadingWidget.listItem(),
      ),
    );
  }

  Widget _buildPerformanceMetricsSliver() => SliverToBoxAdapter(
    child: PerformanceMetricsWidget(
      isLoading: _isLoading,
      isTablet: _isTablet,
      allInvestors: _allInvestors,
      totalViableCapital: _votingManager.totalViableCapital,
    ),
  );

  Widget _buildVotingDistributionSliver() => SliverToBoxAdapter(
    child: VotingDistributionWidget(
      isLoading: _isLoading,
      isTablet: _isTablet,
      votingDistribution: _votingDistribution,
      votingCounts: _votingCounts,
      totalCount: _totalCount,
    ),
  );

  Widget _buildTrendAnalysisSliver() => SliverToBoxAdapter(
    child: TrendAnalysisWidget(
      isLoading: _isLoading,
      isTablet: _isTablet,
      allInvestors: _allInvestors,
      totalViableCapital: _votingManager.totalViableCapital,
    ),
  );

  Widget _buildMajorityControlSliver() => SliverToBoxAdapter(
    child: Container(
      margin: EdgeInsets.all(_isTablet ? 16 : 12),
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_rounded, color: AppThemePro.accentGold),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grupa większościowa (≥51%)',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppThemePro.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Minimalna koalicja inwestorów kontrolująca większość kapitału',
                      style: TextStyle(
                        color: AppThemePro.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const PremiumShimmerLoadingWidget.chart(height: 150)
              : _buildMajorityStats(),
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
          AppThemePro.accentGold,
        ),
        _buildMajorityStatRow(
          'Rozmiar grupy większościowej',
          '${_majorityHolders.length} inwestorów',
          AppThemePro.accentGold,
        ),
        _buildMajorityStatRow(
          'Łączny kapitał grupy',
          CurrencyFormatter.formatCurrencyShort(majorityCapital),
          AppThemePro.statusSuccess,
        ),
        _buildMajorityStatRow(
          'Udział grupy w całości',
          '${majorityPercentage.toStringAsFixed(1)}%',
          majorityPercentage >= 51.0
              ? AppThemePro.statusSuccess
              : AppThemePro.statusWarning,
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
          Text(label, style: TextStyle(color: AppThemePro.textSecondary)),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMajorityHoldersContent() {
    if (_isLoading) {
      return SliverToBoxAdapter(
        child: AnalyticsShimmerLayouts.majorityAnalysis(),
      );
    }

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
          decoration: AppThemePro.premiumCardDecoration,
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 64,
                  color: AppThemePro.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Brak grup większościowych',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppThemePro.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nie znaleziono inwestorów spełniających kryteria większości',
                  style: TextStyle(color: AppThemePro.textTertiary),
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
          decoration: AppThemePro.premiumCardDecoration,
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 64,
                  color: AppThemePro.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Brak grup większościowych',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppThemePro.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nie znaleziono inwestorów spełniających kryteria większości',
                  style: TextStyle(color: AppThemePro.textTertiary),
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
        decoration: AppThemePro.premiumCardDecoration,
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
        color: AppThemePro.surfaceCard,
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
          bottom: BorderSide(color: AppThemePro.borderSecondary, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppThemePro.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppThemePro.accentGold.withOpacity(0.3),
                ),
              ),
              child: Text(
                '$position',
                style: TextStyle(
                  color: AppThemePro.accentGold,
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
                color: AppThemePro.textPrimary,
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
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: AppThemePro.textSecondary,
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
                    ? AppThemePro.statusSuccess
                    : AppThemePro.statusWarning,
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
                color: AppThemePro.textSecondary,
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
          decoration: AppThemePro.premiumCardDecoration,
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 48,
                  color: AppThemePro.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Brak posiadaczy większości',
                  style: TextStyle(color: AppThemePro.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Żaden inwestor nie posiada ≥${_majorityThreshold.toStringAsFixed(0)}% kapitału',
                  style: TextStyle(color: AppThemePro.textTertiary),
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
                        color: AppThemePro.accentGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppThemePro.accentGold.withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$position',
                          style: TextStyle(
                            color: AppThemePro.accentGold,
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
                              color: AppThemePro.textPrimary,
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
                      color: AppThemePro.accentGold,
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
                              color: AppThemePro.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatCurrencyShort(
                              investor.viableRemainingCapital,
                            ),
                            style: TextStyle(
                              color: AppThemePro.textPrimary,
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
                              color: AppThemePro.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: AppThemePro.textPrimary,
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
                        color: AppThemePro.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${cumulativePercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: cumulativePercentage >= _majorityThreshold
                            ? AppThemePro.statusSuccess
                            : AppThemePro.statusWarning,
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
            color: AppThemePro.accentGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              '#$position',
              style: TextStyle(
                color: AppThemePro.accentGold,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          investor.client.name,
          style: TextStyle(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kapitał: ${CurrencyFormatter.formatCurrencyShort(investor.viableRemainingCapital)}',
              style: TextStyle(color: AppThemePro.textSecondary, fontSize: 12),
            ),
            Text(
              'Skumulowane: ${cumulativePercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: cumulativePercentage >= _majorityThreshold
                    ? AppThemePro.statusSuccess
                    : AppThemePro.textTertiary,
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
                color: AppThemePro.accentGold,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              'kontroli',
              style: TextStyle(color: AppThemePro.textTertiary, fontSize: 12),
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

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => EnhancedInvestorDetailsDialog(
        investor: investor,
        onInvestorUpdated: (updatedInvestor) {
        // 📍 Oznacz że dane zostały zaktualizowane
        _dataWasUpdated = true;
        // 📍 Odśwież dane po aktualizacji z wymuszeniem przeładowania z serwera
        // TYLKO gdy rzeczywiście były zapisane zmiany w danych inwestora
        // Pozycja scroll zostanie automatycznie zachowana i przywrócona
        _refreshDataAfterUpdate();
        },
      ),
    ).then((_) {
      // 📍 Po zamknięciu modalu - sprawdź czy potrzebne jest odświeżenie
      if (!_dataWasUpdated) {
        print(
          '📍 [Analytics] Modal zamknięty bez zmian - nie odświeżam danych',
        );
      }
    });
  }



  void _navigateToProductDetails(investment) {
    print(
      '🎯 [PremiumInvestorAnalyticsScreen] Nawigacja do szczegółów produktu:',
    );
    print('  - Investment ID (logiczne): ${investment.id}');
    print('  - Investment proposalId (hash): ${investment.proposalId}');
    print('  - Product Name: ${investment.productName}');
    print('  - Product Type: ${investment.productType}');

    // 🚀 NAPRAWIONE: Użyj TYLKO logicznego ID z Firebase (np. apartment_0089, bond_0001)
    final logicalInvestmentId = investment.id;

    // 🎯 Używaj TYLKO logicznego ID z Firebase dla products_management_screen
    if (logicalInvestmentId != null && logicalInvestmentId.isNotEmpty) {
      // Przekaż logiczne investmentId przez URL query parameter
      final encodedInvestmentId = Uri.encodeComponent(logicalInvestmentId);
      context.go('/products?investmentId=$encodedInvestmentId');

      print(
        '✅ [PremiumInvestorAnalyticsScreen] Nawigacja z logicznym ID: $encodedInvestmentId',
      );
    } else if (investment.productName != null &&
        investment.productName.isNotEmpty) {
      // Fallback - nawigacja po nazwie produktu (stara metoda)
      final encodedProductName = Uri.encodeComponent(investment.productName);
      context.go(
        '/products?productName=$encodedProductName&productType=${investment.productType.name}',
      );

      print(
        '✅ [PremiumInvestorAnalyticsScreen] Fallback nawigacja po nazwie: $encodedProductName',
      );
    } else {
      // Fallback - przejdź do listy produktów z filtrem typu
      context.go('/products?productType=${investment.productType.name}');

      print(
        '⚠️ [PremiumInvestorAnalyticsScreen] Fallback nawigacja po typie produktu',
      );
    }
  }




  // � EXPORT MODE METHODS

  void _toggleExportMode() {
    setState(() {
      _isExportMode = !_isExportMode;
      if (_isExportMode) {
        _isSelectionMode = true;
        _selectedInvestorIds.clear();
        _tabController.animateTo(1); // Przejdź na tab "Inwestorzy"
      } else {
        _isSelectionMode = false;
        _selectedInvestorIds.clear();
      }
    });

    if (_isExportMode) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Tryb eksportu aktywny - wybierz inwestorów do eksportu',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppThemePro.accentGold,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Anuluj',
            textColor: AppThemePro.primaryDark,
            onPressed: _toggleExportMode,
          ),
        ),
      );
    }
  }

  void _toggleEmailMode() {
    setState(() {
      _isEmailMode = !_isEmailMode;
      if (_isEmailMode) {
        _isSelectionMode = true;
        _selectedInvestorIds.clear();
        _tabController.animateTo(1); // Przejdź na tab "Inwestorzy"
        // Wyłącz tryb eksportu jeśli był aktywny
        _isExportMode = false;
      } else {
        _isSelectionMode = false;
        _selectedInvestorIds.clear();
      }
    });

    if (_isEmailMode) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Tryb email aktywny - wybierz odbiorców wiadomości',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppThemePro.accentGold,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Anuluj',
            textColor: AppThemePro.primaryDark,
            onPressed: _toggleEmailMode,
          ),
        ),
      );
    }
  }


  // Usunięto niepotrzebną metodę _ensureFullClientDataThenShowEmailDialog - zastąpiono modułowym systemem

  void _showExportFormatDialog() {
    if (_selectedInvestorIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Najpierw wybierz inwestorów do eksportu\n💡 Użyj trybu selekcji lub eksportu aby wybrać inwestorów',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );

      if (!_isExportMode && !_isSelectionMode) {
        _toggleExportMode();
      }
      return;
    }

    // Używamy istniejącego InvestorExportDialog
    showDialog(
      context: context,
      builder: (context) => InvestorExportDialog(
        selectedInvestors: _selectedInvestors,
        onExportComplete: () {
          // Dialog already handles its own closure, so we don't call Navigator.pop(context) here
          _toggleExportMode();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Eksport zakończony pomyślnie'),
              backgroundColor: AppThemePro.statusSuccess,
            ),
          );
        },
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

    // Wyjdź z trybu wyboru jeśli nic nie jest zaznaczone (ale nie z trybu eksportu)
    if (_selectedInvestorIds.isEmpty && !_isExportMode) {
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

  // === RBAC aliasy i brakujące metody używane w UI (oryginalnie w extension) ===
  void _clearSelection() => _deselectAllInvestors();
  void _selectAllVisibleInvestors() => _selectAllInvestors();

  // 🚀 NOWE METODY POMOCNICZE DLA UJEDNOLICENIA Z DASHBOARD

  /// Konwertuje OptimizedProduct na InvestorSummary używając server-side danych
  /// 🚀 NOWA WERSJA: Pobiera WSZYSTKICH klientów, nie tylko tych z inwestycjami
  Future<List<InvestorSummary>> _convertOptimizedProductsToInvestorSummaries(
    List<OptimizedProduct> products,
  ) async {
    print(
      '🚀 [Premium Analytics] Konwertuję ${products.length} OptimizedProducts na InvestorSummary (WSZYSCY KLIENCI)',
    );

    // KROK 1: Pobierz WSZYSTKICH klientów z bazy
    print('🎯 [Premium Analytics] Pobieram WSZYSTKICH klientów z bazy...');

    final enhancedResult = await _enhancedClientService.getAllActiveClients(
      limit: 10000,
      includeInactive: true, // Pobierz wszystkich, łącznie z nieaktywnymi
      forceRefresh: true,
    );

    if (enhancedResult.hasError || enhancedResult.clients.isEmpty) {
      print(
        '❌ [Premium Analytics] Błąd pobierania klientów: ${enhancedResult.error}',
      );
      throw Exception('Nie można pobrać klientów: ${enhancedResult.error}');
    }

    final allClients = enhancedResult.clients;
    print(
      '✅ [Premium Analytics] Pobrano ${allClients.length} WSZYSTKICH klientów z bazy',
    );

    // KROK 2: Grupuj produkty według clientId (z topInvestors)
    final Map<String, List<OptimizedProduct>> productsByClient = {};

    for (final product in products) {
      for (final investor in product.topInvestors) {
        productsByClient.putIfAbsent(investor.clientId, () => []).add(product);
      }
    }

    print(
      '💼 [Premium Analytics] ${productsByClient.length} klientów ma inwestycje',
    );
    print(
      '👥 [Premium Analytics] ${allClients.length - productsByClient.length} klientów BEZ inwestycji',
    );

    // KROK 3: 🚀 MEGA OPTYMALIZACJA: Użyj nowej bulk metody z UniversalInvestmentService
    print(
      '🚀 [Premium Analytics] Używam bulk metody UniversalInvestmentService...',
    );

    final Map<String, List<Investment>> investmentsByClient =
        await UniversalInvestmentService.instance
            .getAllInvestmentsGroupedByClient();

    print(
      '✅ [Premium Analytics] Otrzymano inwestycje dla ${investmentsByClient.length} klientów (bulk)',
    );

    // KROK 4: Stwórz InvestorSummary dla WSZYSTKICH klientów (szybko, bez dodatkowych zapytań)
    final List<InvestorSummary> investors = [];

    for (final client in allClients) {
      final clientId = client.id;

      // Pobierz inwestycje dla tego klienta z przygotowanej mapy (bez zapytania Firebase)
      final clientInvestments = investmentsByClient[clientId] ?? [];

      // Stwórz InvestorSummary dla klienta
      final investorSummary = InvestorSummary.fromInvestments(
        client,
        clientInvestments, // Prawdziwe inwestycje z Firebase z logicznymi ID
      );

      investors.add(investorSummary);
    }

    print(
      '✅ [Premium Analytics] Utworzono ${investors.length} InvestorSummary (wszyscy klienci)',
    );
    print(
      '   - ${investors.where((i) => i.investments.isNotEmpty).length} z inwestycjami',
    );
    print(
      '   - ${investors.where((i) => i.investments.isEmpty).length} bez inwestycji',
    );

    return investors;
  }

  /// Konwertuje GlobalProductStatistics na UnifiedDashboardStatistics (kopiuje z Dashboard)
  UnifiedDashboardStatistics _convertGlobalStatsToUnified(
    GlobalProductStatistics globalStats,
  ) {
    // Szacuj kapitał do restrukturyzacji jako 5% całkowitej wartości (benchmark)
    final estimatedCapitalForRestructuring = globalStats.totalValue * 0.05;

    // Szacuj kapitał zabezpieczony jako pozostały kapitał minus do restrukturyzacji
    final estimatedCapitalSecured =
        (globalStats.totalRemainingCapital - estimatedCapitalForRestructuring)
            .clamp(0.0, double.infinity);

    return UnifiedDashboardStatistics(
      totalInvestmentAmount: globalStats.totalValue,
      totalRemainingCapital: globalStats.totalRemainingCapital,
      totalCapitalSecured: estimatedCapitalSecured.toDouble(),
      totalCapitalForRestructuring: estimatedCapitalForRestructuring,
      totalViableCapital:
          globalStats.totalRemainingCapital, // Całość jako viable
      totalInvestments: globalStats.totalProducts,
      activeInvestments:
          globalStats.totalProducts, // Szacuj wszystkie jako aktywne
      averageInvestmentAmount: globalStats.averageValuePerProduct,
      averageRemainingCapital: globalStats.totalProducts > 0
          ? globalStats.totalRemainingCapital / globalStats.totalProducts
          : 0,
      dataSource: 'OptimizedProductService (converted)',
      calculatedAt: DateTime.now(),
    );
  }
}

// ================== HELPER DATA CLASSES (Top-level) ==================


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
      ..color = AppThemePro.accentGold
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = AppThemePro.accentGold.withOpacity(0.1)
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
      ..color = AppThemePro.accentGold
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

// === KONIEC KLASY STANU ===

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
      ..color = AppThemePro.borderSecondary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, borderPaint);
  }

  Color _getVotingStatusColorForPainter(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return AppThemePro.statusSuccess;
      case VotingStatus.no:
        return AppThemePro.statusError;
      case VotingStatus.abstain:
        return AppThemePro.statusWarning;
      case VotingStatus.undecided:
        return AppThemePro.textTertiary;
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
                  ? AppThemePro.statusWarning.withOpacity(0.1)
                  : AppThemePro.backgroundTertiary,
              borderRadius: BorderRadius.circular(8),
              border: hasUnviable
                  ? Border.all(
                      color: AppThemePro.statusWarning.withOpacity(0.3),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: hasUnviable
                        ? AppThemePro.statusWarning
                        : AppThemePro.statusSuccess,
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
                                color: AppThemePro.textPrimary,
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
                              color: AppThemePro.accentGold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${productInvestments.length}x',
                              style: TextStyle(
                                color: AppThemePro.accentGold,
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
                          color: AppThemePro.textSecondary,
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
                        color: AppThemePro.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (hasUnviable)
                      Text(
                        'CZĘŚĆ NIEWYKONALNA',
                        style: TextStyle(
                          color: AppThemePro.statusWarning,
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
                  ? AppThemePro.statusWarning.withOpacity(0.1)
                  : AppThemePro.backgroundTertiary,
              borderRadius: BorderRadius.circular(8),
              border: isUnviable
                  ? Border.all(
                      color: AppThemePro.statusWarning.withOpacity(0.3),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isUnviable
                        ? AppThemePro.statusWarning
                        : AppThemePro.statusSuccess,
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
                          color: AppThemePro.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${investment.creditorCompany} • ${investment.productType.displayName}',
                        style: TextStyle(
                          color: AppThemePro.textSecondary,
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
                        color: AppThemePro.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (isUnviable)
                      Text(
                        'NIEWYKONALNA',
                        style: TextStyle(
                          color: AppThemePro.statusWarning,
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
}
