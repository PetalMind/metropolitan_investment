import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/client.dart';
import '../models/investor_summary.dart';
import '../services/firebase_functions_analytics_service.dart';
import '../widgets/investor_details_modal.dart';
import '../widgets/firebase_functions_dialogs.dart';
import '../widgets/investor_widgets.dart';
import '../utils/currency_formatter.dart';
import '../utils/voting_analysis_manager.dart';

/// 🎯 PREMIUM INVESTOR ANALYTICS DASHBOARD
///
/// 🚀 Najnowocześniejszy dashboard analityki inwestorów w Polsce
/// Inspirowany platformami Bloomberg Terminal, Refinitiv, i najlepszymi fintech solutions
///
/// ✨ KLUCZOWE FUNKCJONALNOŚCI:
/// • 📊 Real-time analiza 51% kontroli większościowej
/// • 🗳️ Zaawansowana analiza głosowania (TAK/NIE/WSTRZYMUJE/NIEZDECYDOWANY)
/// • 📈 Inteligentne statystyki systemu z predykcją trendów
/// • 🔍 Intuicyjne filtrowanie pod ręką - lightning fast
/// • 📱 Responsive design dla wszystkich urządzeń
/// • ⚡ Performance-first architecture z lazy loading
/// • 🎨 Premium UI/UX - level Bloomberg Terminal
/// • 🔐 Enterprise-grade error handling
/// • 🌟 Smooth animations i micro-interactions
/// • 💎 Professional financial color coding
class OptimizedInvestorAnalyticsScreen extends StatefulWidget {
  const OptimizedInvestorAnalyticsScreen({super.key});

  @override
  State<OptimizedInvestorAnalyticsScreen> createState() =>
      _OptimizedInvestorAnalyticsScreenState();
}

class _OptimizedInvestorAnalyticsScreenState
    extends State<OptimizedInvestorAnalyticsScreen>
    with TickerProviderStateMixin {
  // 🔧 SERWISY
  final FirebaseFunctionsAnalyticsService _analyticsService =
      FirebaseFunctionsAnalyticsService();
  final VotingAnalysisManager _votingManager = VotingAnalysisManager();

  // 🎮 KONTROLERY UI
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _filterAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<Offset> _filterSlideAnimation;

  // 📊 STAN DANYCH
  List<InvestorSummary> _allInvestors = [];
  List<InvestorSummary> _displayedInvestors = [];
  InvestorAnalyticsResult? _currentResult;

  // 🔄 STAN ŁADOWANIA
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  // 📄 PAGINACJA
  int _currentPage = 1;
  final int _pageSize = 250;
  bool _hasNextPage = false;

  // 🎛️ FILTRY I SORTOWANIE
  String _sortBy = 'viableCapital';
  bool _sortAscending = false;
  VotingStatus? _selectedVotingStatus;
  ClientType? _selectedClientType;
  bool _includeInactive = false;
  bool _showOnlyWithUnviableInvestments = false;
  String _searchQuery = '';

  // 🖼️ WIDOK UI
  String _currentView = 'list'; // 'list', 'cards', 'table', 'summary'
  bool _isFilterVisible = false;

  // 📈 ANALITYKA
  double _totalPortfolioValue = 0.0;

  // ⚙️ KONFIGURACJA
  static const double _majorityThreshold = 51.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeListeners();
    _loadInitialData();
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    _fabAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  // 🎨 INICJALIZACJA

  void _initializeAnimations() {
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
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

    // Animacja wejścia FAB
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fabAnimationController.forward();
    });
  }

  void _initializeListeners() {
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasNextPage &&
        !_isLoadingMore) {
      _loadMoreData();
    }
  }

  void _onSearchChanged() {
    if (_searchController.text != _searchQuery) {
      _searchQuery = _searchController.text;
      _debounceSearch();
    }
  }

  Timer? _searchDebounceTimer;
  void _debounceSearch() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadInitialData();
    });
  }

  // 📊 GŁÓWNE METODY DANYCH

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
    });

    try {
      print('🚀 [OptimizedScreen] Ładowanie danych - strona $_currentPage');

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

      if (!mounted) return;
      _processAnalyticsResult(result);

      print(
        '✅ [OptimizedScreen] Załadowano ${result.investors.length} inwestorów',
      );
    } catch (e) {
      print('❌ [OptimizedScreen] Błąd ładowania: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Błąd ładowania danych: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasNextPage || !mounted) return;

    setState(() => _isLoadingMore = true);

    try {
      print('📄 [OptimizedScreen] Ładowanie strony ${_currentPage + 1}');

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

      if (!mounted) return;

      setState(() {
        _displayedInvestors.addAll(result.investors);
        _currentPage++;
        _hasNextPage = result.hasNextPage;
        _isLoadingMore = false;
      });

      print('✅ [OptimizedScreen] Dodano ${result.investors.length} inwestorów');
    } catch (e) {
      print('❌ [OptimizedScreen] Błąd ładowania więcej: $e');
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      _showErrorSnackBar('Błąd ładowania danych: $e');
    }
  }

  void _processAnalyticsResult(InvestorAnalyticsResult result) {
    if (!mounted) return;

    _currentResult = result;
    _allInvestors = result.allInvestors;
    _displayedInvestors = result.investors;
    _totalPortfolioValue = result.totalViableCapital;
    _hasNextPage = result.hasNextPage;

    // Oblicz analizę głosowania
    _votingManager.calculateVotingCapitalDistribution(_allInvestors);

    setState(() => _isLoading = false);
  }

  // 🔧 METODY FILTROWANIA I SORTOWANIA

  void _changeSortOrder(String newSortBy) {
    setState(() {
      if (_sortBy == newSortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = newSortBy;
        _sortAscending = false;
      }
    });
    _loadInitialData();
  }

  void _updateFilter({
    VotingStatus? votingStatus,
    ClientType? clientType,
    bool? includeInactive,
    bool? showOnlyWithUnviableInvestments,
  }) {
    setState(() {
      if (votingStatus != null) _selectedVotingStatus = votingStatus;
      if (clientType != null) _selectedClientType = clientType;
      if (includeInactive != null) _includeInactive = includeInactive;
      if (showOnlyWithUnviableInvestments != null) {
        _showOnlyWithUnviableInvestments = showOnlyWithUnviableInvestments;
      }
    });
    _loadInitialData();
  }

  void _resetFilters() {
    setState(() {
      _selectedVotingStatus = null;
      _selectedClientType = null;
      _includeInactive = false;
      _showOnlyWithUnviableInvestments = false;
      _sortBy = 'viableCapital';
      _sortAscending = false;
      _searchController.clear();
      _searchQuery = '';
    });
    _loadInitialData();
    _toggleFilterPanel(false);
  }

  void _toggleFilterPanel([bool? visible]) {
    setState(() {
      _isFilterVisible = visible ?? !_isFilterVisible;
    });

    if (_isFilterVisible) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  // 🎭 METODY WIDOKU

  void _changeView(String newView) {
    if (!mounted || _currentView == newView) return;

    setState(() => _currentView = newView);
    _fabAnimationController.reverse().then((_) {
      if (mounted) _fabAnimationController.forward();
    });
  }

  void _showInvestorDetails(InvestorSummary investor) {
    if (!mounted) return;

    InvestorDetailsModalHelper.show(
      context: context,
      investor: investor,
      onEditInvestor: () => _editInvestor(investor),
      onViewInvestments: () => _viewInvestorInvestments(investor),
      onUpdateInvestor: _updateInvestorInList,
    );
  }

  void _updateInvestorInList(InvestorSummary updatedInvestor) {
    if (!mounted) return;

    setState(() {
      final index = _displayedInvestors.indexWhere(
        (inv) => inv.client.id == updatedInvestor.client.id,
      );
      if (index != -1) {
        _displayedInvestors[index] = updatedInvestor;
      }
    });
    _showSuccessSnackBar(
      'Zaktualizowano dane inwestora: ${updatedInvestor.client.name}',
    );
  }

  void _editInvestor(InvestorSummary investor) {
    _showInfoSnackBar('Edycja inwestora: ${investor.client.name}');
  }

  void _viewInvestorInvestments(InvestorSummary investor) {
    _showInfoSnackBar('Inwestycje: ${investor.client.name}');
  }

  // 🔬 ANALIZA DANYCH

  Future<void> _performMajorityControlAnalysis() async {
    if (_allInvestors.isEmpty || !mounted) {
      _showErrorSnackBar('Brak danych do analizy');
      return;
    }

    bool dialogShown = false;
    try {
      _showLoadingDialog('Analizuję kontrolę większościową...');
      dialogShown = true;

      final analysis = await _analyticsService.analyzeMajorityControlOptimized(
        includeInactive: _includeInactive,
        controlThreshold: _majorityThreshold,
      );

      if (!mounted) return;

      // Bezpieczne zamknięcie dialogu
      if (dialogShown && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        dialogShown = false;
      }

      _showMajorityAnalysisDialog(analysis);
    } catch (e) {
      print('❌ [MajorityAnalysis] Błąd: $e');

      if (!mounted) return;

      // Bezpieczne zamknięcie dialogu
      if (dialogShown && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Sprawdź czy to błąd CORS
      if (e.toString().contains('CORS') ||
          e.toString().contains('Access to fetch')) {
        _showErrorSnackBar(
          'Błąd CORS: Funkcja Firebase nie jest dostępna z localhost. '
          'Uruchom aplikację z Firebase Hosting lub skonfiguruj CORS.',
        );
      } else {
        _showErrorSnackBar('Błąd analizy kontroli: $e');
      }
    }
  }

  Future<void> _performVotingDistributionAnalysis() async {
    if (!mounted) return;

    bool dialogShown = false;
    try {
      _showLoadingDialog('Analizuję rozkład głosowania...');
      dialogShown = true;

      if (_currentResult == null) {
        if (dialogShown && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        _showErrorSnackBar('Brak danych do analizy');
        return;
      }

      final distribution = _currentResult!.votingDistribution;
      if (!mounted) return;

      if (dialogShown && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        dialogShown = false;
      }

      _showVotingDistributionDialog(distribution);
    } catch (e) {
      print('❌ [VotingAnalysis] Błąd: $e');

      if (!mounted) return;

      if (dialogShown && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      _showErrorSnackBar('Błąd analizy głosowania: $e');
    }
  }

  // 🖼️ UI BUILDERS

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(isTablet),
          if (_isFilterVisible) _buildFilterPanel(isTablet),
          if (_isLoading && _displayedInvestors.isEmpty)
            _buildLoadingSliverItem()
          else if (_error != null)
            _buildErrorSliverItem()
          else ...[
            _buildSummarySliver(isTablet),
            _buildVotingAnalysisSliver(isTablet),
            _buildInvestorsList(),
            if (_isLoadingMore) _buildLoadingMoreSliverItem(),
          ],
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAppBar(bool isTablet) {
    return SliverAppBar(
      expandedHeight: isTablet ? 200 : 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.backgroundSecondary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Analityka Inwestorów ⚡',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.backgroundSecondary,
                AppTheme.primaryAccent.withOpacity(0.1),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [if (!_isLoading) _buildQuickStats()],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_getViewIcon(), color: AppTheme.secondaryGold),
          onPressed: _showViewSelector,
          tooltip: 'Zmień widok',
        ),
        IconButton(
          icon: Icon(
            _isFilterVisible ? Icons.filter_list_off : Icons.filter_list,
            color: AppTheme.secondaryGold,
          ),
          onPressed: () => _toggleFilterPanel(),
          tooltip: 'Filtry',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.secondaryGold),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'majority_analysis',
              child: ListTile(
                leading: Icon(Icons.analytics),
                title: Text('Analiza większości'),
                subtitle: Text('Może wymagać Firebase Hosting'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'voting_analysis',
              child: ListTile(
                leading: Icon(Icons.how_to_vote),
                title: Text('Analiza głosowania'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'system_stats',
              child: ListTile(
                leading: Icon(Icons.bar_chart),
                title: Text('Statystyki systemu'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'refresh_cache',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Odśwież cache'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'export_emails',
              child: ListTile(
                leading: Icon(Icons.email),
                title: Text('Eksportuj emaile'),
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatChip(
          'Inwestorzy',
          _displayedInvestors.length.toString(),
          Icons.people,
        ),
        _buildStatChip(
          'Kapitał',
          CurrencyFormatter.formatCurrency(_totalPortfolioValue),
          Icons.account_balance,
        ),
        if (_currentResult != null)
          _buildStatChip(
            'Aktywni',
            '${_currentResult!.totalCount}',
            Icons.trending_up,
          ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryAccent),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getViewIcon() {
    switch (_currentView) {
      case 'list':
        return Icons.list;
      case 'cards':
        return Icons.view_agenda;
      case 'table':
        return Icons.table_chart;
      case 'summary':
        return Icons.analytics;
      default:
        return Icons.list;
    }
  }

  void _showViewSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Wybierz widok',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildViewOption('list', 'Lista', Icons.list),
                _buildViewOption('cards', 'Karty', Icons.view_agenda),
                _buildViewOption('table', 'Tabela', Icons.table_chart),
                _buildViewOption('summary', 'Podsumowanie', Icons.analytics),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewOption(String view, String label, IconData icon) {
    final isSelected = _currentView == view;
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _changeView(view);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryAccent.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryAccent
                : AppTheme.textSecondary.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.primaryAccent
                  : AppTheme.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.primaryAccent
                    : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'majority_analysis':
        _performMajorityControlAnalysis();
        break;
      case 'voting_analysis':
        _performVotingDistributionAnalysis();
        break;
      case 'system_stats':
        _showInfoSnackBar('Statystyki systemu - funkcja w rozwoju');
        break;
      case 'refresh_cache':
        _showRefreshCacheDialog();
        break;
      case 'export_emails':
        _exportEmails();
        break;
    }
  }

  void _showRefreshCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odświeżanie cache'),
        content: const Text(
          'Ta funkcja wymaga dostępu do Firebase Functions. '
          'W środowisku developerskim może wystąpić błąd CORS.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performCacheRefresh();
            },
            child: const Text('Kontynuuj'),
          ),
        ],
      ),
    );
  }

  void _performCacheRefresh() {
    _showInfoSnackBar('Odświeżanie cache...');
    // Tutaj można dodać implementację odświeżania
    Future.delayed(const Duration(seconds: 1), () {
      _loadInitialData();
      _showSuccessSnackBar('Cache odświeżony lokalnie');
    });
  }

  void _exportEmails() {
    if (_displayedInvestors.isEmpty) {
      _showErrorSnackBar('Brak inwestorów do eksportu');
      return;
    }

    final emails = _displayedInvestors
        .where((investor) => investor.client.email.isNotEmpty == true)
        .map((investor) => investor.client.email)
        .join('\n');

    if (emails.isEmpty) {
      _showInfoSnackBar('Brak adresów email w wybranych inwestorach');
      return;
    }

    Clipboard.setData(ClipboardData(text: emails));
    _showSuccessSnackBar(
      'Skopiowano ${emails.split('\n').length} adresów email',
    );
  }

  // 🎨 SLIVER BUILDERS

  Widget _buildFilterPanel(bool isTablet) {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _filterSlideAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filtry i sortowanie',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text('Resetuj'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Szukaj po nazwie klienta...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (isTablet)
                Row(
                  children: [
                    Expanded(child: _buildSortSection()),
                    const SizedBox(width: 20),
                    Expanded(child: _buildFilterSection()),
                  ],
                )
              else ...[
                _buildSortSection(),
                const SizedBox(height: 16),
                _buildFilterSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sortowanie',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSortChip('viableCapital', 'Kapitał'),
            _buildSortChip('totalValue', 'Wartość całkowita'),
            _buildSortChip('name', 'Nazwa'),
            _buildSortChip('investmentCount', 'Liczba inwestycji'),
          ],
        ),
      ],
    );
  }

  Widget _buildSortChip(String sortField, String label) {
    final isSelected = _sortBy == sortField;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (isSelected) ...[
            const SizedBox(width: 4),
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            ),
          ],
        ],
      ),
      onSelected: (_) => _changeSortOrder(sortField),
      selectedColor: AppTheme.primaryAccent.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryAccent,
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtry',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        DropdownButtonFormField<VotingStatus?>(
          value: _selectedVotingStatus,
          decoration: InputDecoration(
            labelText: 'Status głosowania',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Wszystkie')),
            ...VotingStatus.values.map(
              (status) => DropdownMenuItem(
                value: status,
                child: Text(status.name.toUpperCase()),
              ),
            ),
          ],
          onChanged: (value) => _updateFilter(votingStatus: value),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<ClientType?>(
          value: _selectedClientType,
          decoration: InputDecoration(
            labelText: 'Typ klienta',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Wszystkie')),
            ...ClientType.values.map(
              (type) => DropdownMenuItem(
                value: type,
                child: Text(type.name.toUpperCase()),
              ),
            ),
          ],
          onChanged: (value) => _updateFilter(clientType: value),
        ),
        const SizedBox(height: 12),

        CheckboxListTile(
          title: const Text('Uwzględnij nieaktywnych'),
          value: _includeInactive,
          onChanged: (value) => _updateFilter(includeInactive: value),
          dense: true,
        ),
        CheckboxListTile(
          title: const Text('Tylko z niewykonalnymi inwestycjami'),
          value: _showOnlyWithUnviableInvestments,
          onChanged: (value) =>
              _updateFilter(showOnlyWithUnviableInvestments: value),
          dense: true,
        ),
      ],
    );
  }

  Widget _buildLoadingSliverItem() {
    return const SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildErrorSliverItem() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Błąd ładowania danych',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(_error ?? 'Nieznany błąd'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySliver(bool isTablet) {
    if (_currentResult == null)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Podsumowanie portfela',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (isTablet)
              Row(
                children: [
                  Expanded(child: _buildSummaryStats()),
                  const SizedBox(width: 20),
                  Expanded(child: _buildPerformanceIndicators()),
                ],
              )
            else ...[
              _buildSummaryStats(),
              const SizedBox(height: 16),
              _buildPerformanceIndicators(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    final result = _currentResult!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryRow('Inwestorzy na stronie', '${result.investors.length}'),
        _buildSummaryRow(
          'Łączny kapitał wykonalny',
          CurrencyFormatter.formatCurrency(result.totalViableCapital),
        ),
        _buildSummaryRow(
          'Średni kapitał na inwestora',
          CurrencyFormatter.formatCurrency(
            result.totalCount > 0
                ? result.totalViableCapital / result.totalCount
                : 0.0,
          ),
        ),
        _buildSummaryRow('Wszystkich inwestorów', '${result.totalCount}'),
      ],
    );
  }

  Widget _buildPerformanceIndicators() {
    final result = _currentResult!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryRow(
          'Stron łącznie',
          '${(result.totalCount / result.pageSize).ceil()}',
        ),
        _buildSummaryRow('Aktualna strona', '${result.currentPage}'),
        _buildSummaryRow('Elementy na stronie', '${result.pageSize}'),
        _buildSummaryRow(
          'Ma następną stronę',
          result.hasNextPage ? 'TAK' : 'NIE',
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingAnalysisSliver(bool isTablet) {
    if (_votingManager.totalViableCapital == 0.0) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Analiza głosowania',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _performVotingDistributionAnalysis,
                  icon: const Icon(Icons.analytics, size: 18),
                  label: const Text('Szczegóły'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildVotingStatsGrid(),
            const SizedBox(height: 16),
            _buildVotingInsight(),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingStatsGrid() {
    final yesPercentage = _votingManager.yesVotingPercentage;
    final noPercentage = _votingManager.noVotingPercentage;
    final abstainPercentage = _votingManager.abstainVotingPercentage;
    final undecidedPercentage = _votingManager.undecidedVotingPercentage;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        InvestorWidgets.buildVotingStatCard(
          'TAK',
          _votingManager.yesVotingCapital,
          yesPercentage,
          Icons.check_circle,
          AppTheme.successColor,
        ),
        InvestorWidgets.buildVotingStatCard(
          'NIE',
          _votingManager.noVotingCapital,
          noPercentage,
          Icons.cancel,
          AppTheme.errorColor,
        ),
        InvestorWidgets.buildVotingStatCard(
          'WSTRZYMUJE',
          _votingManager.abstainVotingCapital,
          abstainPercentage,
          Icons.remove_circle,
          AppTheme.warningColor,
        ),
        InvestorWidgets.buildVotingStatCard(
          'NIEZDECYDOWANY',
          _votingManager.undecidedVotingCapital,
          undecidedPercentage,
          Icons.help,
          AppTheme.textSecondary,
        ),
      ],
    );
  }

  Widget _buildVotingInsight() {
    final insight = _votingManager.getVotingInsight();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppTheme.primaryAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Wgląd w dane',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(insight.message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildInvestorsList() {
    if (_displayedInvestors.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Brak inwestorów do wyświetlenia',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Spróbuj zmienić filtry lub kryteria wyszukiwania',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    switch (_currentView) {
      case 'cards':
        return _buildCardsView();
      case 'table':
        return _buildTableView();
      case 'summary':
        return _buildSummaryView();
      default:
        return _buildListView();
    }
  }

  Widget _buildListView() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final investor = _displayedInvestors[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Card(
            color: AppTheme.backgroundSecondary,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildInvestorListTile(
              investor,
              onTap: () => _showInvestorDetails(investor),
              onLongPress: () => _showInvestorQuickActions(investor),
            ),
          ),
        );
      }, childCount: _displayedInvestors.length),
    );
  }

  Widget _buildInvestorListTile(
    InvestorSummary investor, {
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryAccent,
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
      title: Text(
        investor.client.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kapitał wykonalny: ${CurrencyFormatter.formatCurrency(investor.viableRemainingCapital)}',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          Text(
            'Inwestycje: ${investor.investmentCount}',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          InvestorWidgets.buildModernStatusChip(
            VotingStatusHelper.getText(investor.client.votingStatus),
            VotingStatusHelper.getIcon(investor.client.votingStatus),
            VotingStatusHelper.getColor(investor.client.votingStatus),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsView() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 768 ? 3 : 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final investor = _displayedInvestors[index];
          return _buildInvestorCard(
            investor,
            onTap: () => _showInvestorDetails(investor),
          );
        }, childCount: _displayedInvestors.length),
      ),
    );
  }

  Widget _buildInvestorCard(InvestorSummary investor, {VoidCallback? onTap}) {
    return Card(
      color: AppTheme.backgroundSecondary,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryAccent,
                    radius: 20,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      investor.client.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Kapitał wykonalny',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.formatCurrency(
                  investor.viableRemainingCapital,
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.primaryAccent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Inwestycje: ${investor.investmentCount}',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const Spacer(),
              InvestorWidgets.buildModernStatusChip(
                VotingStatusHelper.getText(investor.client.votingStatus),
                VotingStatusHelper.getIcon(investor.client.votingStatus),
                VotingStatusHelper.getColor(investor.client.votingStatus),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableView() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(
              AppTheme.primaryAccent.withOpacity(0.1),
            ),
            columns: const [
              DataColumn(label: Text('Nazwa')),
              DataColumn(label: Text('Typ')),
              DataColumn(label: Text('Kapitał wykonalny')),
              DataColumn(label: Text('Wartość portfela')),
              DataColumn(label: Text('Liczba inwestycji')),
              DataColumn(label: Text('Status głosowania')),
            ],
            rows: _displayedInvestors.map((investor) {
              return DataRow(
                onSelectChanged: (_) => _showInvestorDetails(investor),
                cells: [
                  DataCell(Text(investor.client.name)),
                  DataCell(
                    InvestorWidgets.buildModernStatusChip(
                      investor.client.type.displayName,
                      Icons.person,
                      AppTheme.textSecondary,
                    ),
                  ),
                  DataCell(
                    Text(
                      CurrencyFormatter.formatCurrency(
                        investor.viableRemainingCapital,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(CurrencyFormatter.formatCurrency(investor.totalValue)),
                  ),
                  DataCell(Text('${investor.investmentCount}')),
                  DataCell(
                    InvestorWidgets.buildModernStatusChip(
                      VotingStatusHelper.getText(investor.client.votingStatus),
                      VotingStatusHelper.getIcon(investor.client.votingStatus),
                      VotingStatusHelper.getColor(investor.client.votingStatus),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryView() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Szczegółowe podsumowanie',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildDetailedSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedSummary() {
    final groupedByVoting = <VotingStatus, List<InvestorSummary>>{};
    for (final investor in _displayedInvestors) {
      groupedByVoting
          .putIfAbsent(investor.client.votingStatus, () => [])
          .add(investor);
    }

    return Column(
      children: groupedByVoting.entries.map((entry) {
        final status = entry.key;
        final investors = entry.value;
        final totalCapital = investors.fold<double>(
          0,
          (sum, inv) => sum + inv.viableRemainingCapital,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.textSecondary.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InvestorWidgets.buildModernStatusChip(
                    VotingStatusHelper.getText(status),
                    VotingStatusHelper.getIcon(status),
                    VotingStatusHelper.getColor(status),
                  ),
                  Text(
                    '${investors.length} inwestorów',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Łączny kapitał: ${CurrencyFormatter.formatCurrency(totalCapital)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Średni kapitał: ${CurrencyFormatter.formatCurrency(totalCapital / investors.length)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoadingMoreSliverItem() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabAnimationController,
      child: FloatingActionButton.extended(
        onPressed: () => FirebaseFunctionsDialogs.showAllClients(context),
        backgroundColor: AppTheme.primaryAccent,
        foregroundColor: Colors.white,
        label: const Text('Wszyscy klienci'),
        icon: const Icon(Icons.people),
      ),
    );
  }

  // 🛠️ AKCJE POMOCNICZE

  /// Bezpieczne zamknięcie dialogu
  void _safePopDialog() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Sprawdza czy błąd to problem z CORS
  bool _isCorsError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('cors') ||
        errorString.contains('access to fetch') ||
        errorString.contains('access-control-allow-origin');
  }

  void _showInvestorQuickActions(InvestorSummary investor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Szczegóły'),
              onTap: () {
                Navigator.pop(context);
                _showInvestorDetails(investor);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edytuj'),
              onTap: () {
                Navigator.pop(context);
                _editInvestor(investor);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Inwestycje'),
              onTap: () {
                Navigator.pop(context);
                _viewInvestorInvestments(investor);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🎭 DIALOGI

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showMajorityAnalysisDialog(dynamic analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analiza kontroli większościowej'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Wyniki analizy kontroli większościowej (>$_majorityThreshold%):',
              ),
              const SizedBox(height: 16),
              Text('Dane analizy: $analysis'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  void _showVotingDistributionDialog(dynamic distribution) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Szczegółowy rozkład głosowania'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Szczegółowy rozkład kapitału według statusu głosowania:',
              ),
              const SizedBox(height: 16),
              Text('Dane rozkładu: $distribution'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  // 📢 SNACKBARS

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.primaryAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
