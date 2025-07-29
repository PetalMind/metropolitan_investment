import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/client.dart';
import '../models/investor_summary.dart';
import '../services/investor_analytics_service.dart';
import '../utils/currency_formatter.dart';
import '../widgets/investor_details_modal.dart';

class InvestorAnalyticsScreen extends StatefulWidget {
  const InvestorAnalyticsScreen({super.key});

  @override
  State<InvestorAnalyticsScreen> createState() =>
      _InvestorAnalyticsScreenState();
}

class _InvestorAnalyticsScreenState extends State<InvestorAnalyticsScreen>
    with TickerProviderStateMixin {
  // === SERWISY I KONTROLERY ===
  final InvestorAnalyticsService _analyticsService = InvestorAnalyticsService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // === ANIMACJE ===
  late AnimationController _filterAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<Offset> _filterSlideAnimation;
  late Animation<double> _fabScaleAnimation;

  // === STAN DANYCH ===
  List<InvestorSummary> _allInvestors = [];
  List<InvestorSummary> _filteredInvestors = [];
  bool _isLoading = true;
  String? _error;

  // === PAGINACJA MOBILNA ===
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasNextPage = false;
  bool _isLoadingMore = false;

  // === ANALITYKA ===
  InvestorRange? _majorityControlPoint;
  double _totalPortfolioValue = 0;

  // === FILTRY I WIDOK ===
  VotingStatus? _selectedVotingStatus;
  ClientType? _selectedClientType;
  bool _includeInactive = false;
  bool _showOnlyWithUnviableInvestments = false;
  bool _isFilterVisible = false;

  String _sortBy = 'totalValue'; // 'totalValue', 'name', 'investmentCount'
  bool _sortAscending = false;
  bool _showQuickActions = false;
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeScrolling();
    _initializeFilters();
    _loadInvestorData();
  }

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

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // Animacja wejścia FAB
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fabAnimationController.forward();
    });
  }

  void _initializeScrolling() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          _hasNextPage &&
          !_isLoadingMore) {
        _loadMoreInvestors();
      }
    });
  }

  void _initializeFilters() {
    _searchController.addListener(_applyFilters);
    _minAmountController.addListener(_applyFilters);
    _maxAmountController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    _fabAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  // === ŁADOWANIE DANYCH ===
  Future<void> _loadInvestorData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🚀 [Mobile UI] Ładowanie danych inwestorów...');

      final allInvestors = await _analyticsService.getAllInvestorsForAnalysis(
        includeInactive: _includeInactive,
      );

      final majorityPoint = _analyticsService.findMajorityControlPoint(
        allInvestors,
      );
      final totalValue = allInvestors.fold<double>(
        0.0,
        (sum, inv) => sum + inv.totalValue,
      );

      _sortInvestors(allInvestors);
      final initialInvestors = allInvestors.take(_pageSize).toList();

      setState(() {
        _allInvestors = allInvestors;
        _filteredInvestors = initialInvestors;
        _majorityControlPoint = majorityPoint;
        _totalPortfolioValue = totalValue;
        _currentPage = 0;
        _hasNextPage = allInvestors.length > _pageSize;
        _isLoading = false;
      });

      print('✅ [Mobile UI] Załadowano ${allInvestors.length} inwestorów');
    } catch (e) {
      print('❌ [Mobile UI] Błąd ładowania: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreInvestors() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500)); // UX delay

      final nextPage = _currentPage + 1;
      final startIndex = nextPage * _pageSize;
      final endIndex = (startIndex + _pageSize).clamp(0, _allInvestors.length);

      if (startIndex < _allInvestors.length) {
        final moreInvestors = _allInvestors.sublist(startIndex, endIndex);

        setState(() {
          _filteredInvestors.addAll(moreInvestors);
          _currentPage = nextPage;
          _hasNextPage = endIndex < _allInvestors.length;
          _isLoadingMore = false;
        });
      } else {
        setState(() => _isLoadingMore = false);
      }
    } catch (e) {
      setState(() => _isLoadingMore = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd ładowania: $e')));
      }
    }
  }

  // === SORTOWANIE I FILTROWANIE ===
  void _sortInvestors(List<InvestorSummary> investors) {
    investors.sort((a, b) {
      late int comparison;

      switch (_sortBy) {
        case 'totalValue':
          comparison = a.totalValue.compareTo(b.totalValue);
          break;
        case 'name':
          comparison = a.client.name.compareTo(b.client.name);
          break;
        case 'investmentCount':
          comparison = a.investmentCount.compareTo(b.investmentCount);
          break;
        default:
          comparison = a.totalValue.compareTo(b.totalValue);
      }

      return _sortAscending ? comparison : -comparison;
    });
  }

  void _changeSortOrder(String newSortBy) {
    setState(() {
      if (_sortBy == newSortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = newSortBy;
        _sortAscending = false;
      }
    });

    _sortInvestors(_allInvestors);
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      var filtered = _allInvestors.where((investor) {
        // Filtr tekstowy
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch =
            searchQuery.isEmpty ||
            investor.client.name.toLowerCase().contains(searchQuery) ||
            (investor.client.companyName?.toLowerCase().contains(searchQuery) ??
                false) ||
            investor.client.email.toLowerCase().contains(searchQuery);

        // Filtr kwoty
        final minAmount = double.tryParse(_minAmountController.text);
        final maxAmount = double.tryParse(_maxAmountController.text);
        final matchesAmount =
            (minAmount == null || investor.totalValue >= minAmount) &&
            (maxAmount == null || investor.totalValue <= maxAmount);

        // Filtr statusu głosowania
        final matchesVoting =
            _selectedVotingStatus == null ||
            investor.client.votingStatus == _selectedVotingStatus;

        // Filtr typu klienta
        final matchesType =
            _selectedClientType == null ||
            investor.client.type == _selectedClientType;

        // Filtr niewykonalnych
        final matchesUnviable =
            !_showOnlyWithUnviableInvestments ||
            investor.hasUnviableInvestments;

        return matchesSearch &&
            matchesAmount &&
            matchesVoting &&
            matchesType &&
            matchesUnviable;
      }).toList();

      _sortInvestors(filtered);
      _filteredInvestors = filtered.take(_pageSize).toList();
      _currentPage = 0;
      _hasNextPage = filtered.length > _pageSize;
    });

    print(
      '🔍 [Mobile UI] Filtrowanie: ${_allInvestors.length} -> ${_filteredInvestors.length} inwestorów',
    );
  }

  void _toggleFilter() {
    setState(() => _isFilterVisible = !_isFilterVisible);

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

    setState(() {
      _selectedVotingStatus = null;
      _selectedClientType = null;
      _showOnlyWithUnviableInvestments = false;
      _sortBy = 'totalValue';
      _sortAscending = false;
    });

    _applyFilters();
    _toggleFilter();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filtry zostały zresetowane'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // === INTERFACE BUILDER ===
  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildResponsiveAppBar(context, isTablet),
          if (_isLoading && _filteredInvestors.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(child: _buildErrorView())
          else ...[
            _buildSummarySliver(isTablet),
            if (_isFilterVisible) _buildFilterSliver(isTablet),
            _buildInvestorsList(),
            if (_isLoadingMore)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ],
      ),
      floatingActionButton: _buildResponsiveFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // === RESPONSYWNY APP BAR ===
  Widget _buildResponsiveAppBar(BuildContext context, bool isTablet) {
    return SliverAppBar(
      expandedHeight: isTablet ? 200 : 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Analityka Inwestorów',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textOnPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: AppTheme.gradientDecoration,
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
                        color: AppTheme.textOnPrimary.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  _buildQuickStats(),
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
            color: AppTheme.textOnPrimary,
          ),
          onPressed: _toggleFilter,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.textOnPrimary),
          onSelected: (value) {
            switch (value) {
              case 'refresh':
                _loadInvestorData();
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
            const PopupMenuItem(
              value: 'refresh',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Odśwież dane'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.email),
                title: Text('Generuj maile'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'reset',
              child: ListTile(
                leading: Icon(Icons.clear_all),
                title: Text('Resetuj filtry'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // === SZYBKIE STATYSTYKI ===
  Widget _buildQuickStats() {
    if (_isLoading) {
      return const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Ładowanie...', style: TextStyle(color: AppTheme.textOnPrimary)),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildQuickStatItem(
            '${_filteredInvestors.length}',
            'Inwestorów',
            Icons.people,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildQuickStatItem(
            CurrencyFormatter.formatCurrencyShort(_totalPortfolioValue),
            'Wartość portfela',
            Icons.account_balance_wallet,
          ),
        ),
        if (_majorityControlPoint != null) ...[
          const SizedBox(width: 16),
          Expanded(
            child: _buildQuickStatItem(
              '${_majorityControlPoint!.investorCount}',
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
            Icon(
              icon,
              size: 16,
              color: AppTheme.textOnPrimary.withOpacity(0.8),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textOnPrimary,
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
          style: TextStyle(
            color: AppTheme.textOnPrimary.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // === FAB RESPONSYWNY ===
  Widget _buildResponsiveFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showQuickActions) ...[
          // Eksport danych
          ScaleTransition(
            scale: _fabScaleAnimation,
            child: FloatingActionButton.small(
              onPressed: _exportInvestorData,
              heroTag: "export_fab",
              backgroundColor: AppTheme.infoColor,
              tooltip: 'Eksportuj dane',
              child: const Icon(Icons.file_download, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),

          // Generuj email masowy
          ScaleTransition(
            scale: _fabScaleAnimation,
            child: FloatingActionButton.small(
              onPressed: _generateBulkEmails,
              heroTag: "email_fab",
              backgroundColor: AppTheme.warningColor,
              tooltip: 'Email masowy',
              child: const Icon(Icons.email, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),

          // Dodaj nowego inwestora
          ScaleTransition(
            scale: _fabScaleAnimation,
            child: FloatingActionButton.small(
              onPressed: _addNewInvestor,
              heroTag: "add_fab",
              backgroundColor: AppTheme.successColor,
              tooltip: 'Dodaj inwestora',
              child: const Icon(Icons.person_add, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Główny FAB
        ScaleTransition(
          scale: _fabScaleAnimation,
          child: FloatingActionButton.extended(
            onPressed: _toggleQuickActions,
            backgroundColor: AppTheme.secondaryGold,
            foregroundColor: AppTheme.textOnSecondary,
            icon: AnimatedRotation(
              turns: _showQuickActions ? 0.125 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(_showQuickActions ? Icons.close : Icons.more_horiz),
            ),
            label: Text(_showQuickActions ? 'Zamknij' : 'Akcje'),
          ),
        ),
      ],
    );
  }

  void _toggleQuickActions() {
    setState(() {
      _showQuickActions = !_showQuickActions;
    });
  }

  void _exportInvestorData() {
    setState(() {
      _showQuickActions = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Eksportowanie danych ${_filteredInvestors.length} inwestorów...',
        ),
        action: SnackBarAction(
          label: 'Pobierz',
          onPressed: () {
            // TODO: Implement actual export functionality
          },
        ),
      ),
    );
  }

  void _generateBulkEmails() {
    setState(() {
      _showQuickActions = false;
    });

    // Show dialog to configure bulk email
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email masowy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Wysłać email do ${_filteredInvestors.length} inwestorów?'),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Temat wiadomości',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement bulk email sending
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wysyłanie emaili...')),
              );
            },
            child: const Text('Wyślij'),
          ),
        ],
      ),
    );
  }

  void _addNewInvestor() {
    setState(() {
      _showQuickActions = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Dodawanie nowego inwestora...'),
        action: SnackBarAction(
          label: 'Otwórz formularz',
          onPressed: () {
            // TODO: Navigate to add investor screen
          },
        ),
      ),
    );
  }

  // === PLACEHOLDER METODY ===
  void _generateEmailList() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funkcja generowania maili - w przygotowaniu'),
      ),
    );
  }

  // === WIDOK BŁĘDU ===
  Widget _buildErrorView() {
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
              _error ?? 'Nieznany błąd',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadInvestorData,
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      ),
    );
  }

  // === SEKCJA PODSUMOWANIA ===
  Widget _buildSummarySliver(bool isTablet) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.premiumCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Podsumowanie portfela',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (isTablet)
              _buildTabletSummaryGrid()
            else
              _buildMobileSummaryColumn(),
            if (_majorityControlPoint != null) ...[
              const SizedBox(height: 16),
              _buildMajorityControlInfo(isTablet),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabletSummaryGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryItem(
            'Łączna liczba',
            '${_allInvestors.length}',
            Icons.people,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryItem(
            'Wyświetlanych',
            '${_filteredInvestors.length}',
            Icons.visibility,
            AppTheme.secondaryGold,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryItem(
            'Wartość portfela',
            CurrencyFormatter.formatCurrencyShort(_totalPortfolioValue),
            Icons.account_balance_wallet,
            AppTheme.successColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSummaryColumn() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                'Inwestorzy',
                '${_filteredInvestors.length}/${_allInvestors.length}',
                Icons.people,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryItem(
                'Portfel',
                CurrencyFormatter.formatCurrencyShort(_totalPortfolioValue),
                Icons.account_balance_wallet,
                AppTheme.successColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMajorityControlInfo(bool isTablet) {
    final point = _majorityControlPoint!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warningColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: AppTheme.warningColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Punkt kontroli 51%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isTablet)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${point.investorCount} największych inwestorów kontroluje ${point.percentage.toStringAsFixed(1)}% portfela',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatCurrencyShort(point.totalValue),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warningColor,
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${point.investorCount} inwestorów → ${point.percentage.toStringAsFixed(1)}%',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  CurrencyFormatter.formatCurrencyShort(point.totalValue),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warningColor,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // === SEKCJA FILTRÓW ===
  Widget _buildFilterSliver(bool isTablet) {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _filterSlideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.premiumCardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.filter_list, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Filtry i sortowanie',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Resetuj'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isTablet) _buildTabletFilters() else _buildMobileFilters(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Szukaj inwestora',
                  hintText: 'Nazwa, email...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _minAmountController,
                decoration: const InputDecoration(
                  labelText: 'Min. kwota',
                  hintText: '0',
                  prefixIcon: Icon(Icons.currency_exchange),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _maxAmountController,
                decoration: const InputDecoration(
                  labelText: 'Max. kwota',
                  hintText: '∞',
                  prefixIcon: Icon(Icons.currency_exchange),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSortDropdown()),
            const SizedBox(width: 12),
            Expanded(child: _buildVotingStatusDropdown()),
            const SizedBox(width: 12),
            Expanded(child: _buildClientTypeDropdown()),
          ],
        ),
        const SizedBox(height: 12),
        _buildFilterChips(),
      ],
    );
  }

  Widget _buildMobileFilters() {
    return Column(
      children: [
        TextFormField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Szukaj inwestora',
            hintText: 'Nazwa, email, firma...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minAmountController,
                decoration: const InputDecoration(
                  labelText: 'Min. kwota',
                  hintText: '0',
                  prefixIcon: Icon(Icons.currency_exchange),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _maxAmountController,
                decoration: const InputDecoration(
                  labelText: 'Max. kwota',
                  hintText: '∞',
                  prefixIcon: Icon(Icons.currency_exchange),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSortDropdown(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildVotingStatusDropdown()),
            const SizedBox(width: 12),
            Expanded(child: _buildClientTypeDropdown()),
          ],
        ),
        const SizedBox(height: 12),
        _buildFilterChips(),
      ],
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButtonFormField<String>(
      value: _sortBy,
      decoration: const InputDecoration(
        labelText: 'Sortuj według',
        prefixIcon: Icon(Icons.sort),
      ),
      items: const [
        DropdownMenuItem(value: 'totalValue', child: Text('Wartość portfela')),
        DropdownMenuItem(value: 'name', child: Text('Nazwa klienta')),
        DropdownMenuItem(
          value: 'investmentCount',
          child: Text('Liczba inwestycji'),
        ),
      ],
      onChanged: (value) {
        if (value != null) _changeSortOrder(value);
      },
    );
  }

  Widget _buildVotingStatusDropdown() {
    return DropdownButtonFormField<VotingStatus?>(
      value: _selectedVotingStatus,
      decoration: const InputDecoration(
        labelText: 'Status głosowania',
        prefixIcon: Icon(Icons.how_to_vote),
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('Wszystkie')),
        DropdownMenuItem(value: VotingStatus.yes, child: Text('Za')),
        DropdownMenuItem(value: VotingStatus.no, child: Text('Przeciw')),
        DropdownMenuItem(
          value: VotingStatus.abstain,
          child: Text('Wstrzymuję'),
        ),
        DropdownMenuItem(
          value: VotingStatus.undecided,
          child: Text('Niezdecydowany'),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedVotingStatus = value;
          _applyFilters();
        });
      },
    );
  }

  Widget _buildClientTypeDropdown() {
    return DropdownButtonFormField<ClientType?>(
      value: _selectedClientType,
      decoration: const InputDecoration(
        labelText: 'Typ klienta',
        prefixIcon: Icon(Icons.person_outline),
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('Wszystkie')),
        DropdownMenuItem(
          value: ClientType.individual,
          child: Text('Osoba fizyczna'),
        ),
        DropdownMenuItem(value: ClientType.company, child: Text('Firma')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedClientType = value;
          _applyFilters();
        });
      },
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          'Nieaktywni',
          _includeInactive,
          (value) => setState(() {
            _includeInactive = value;
            _loadInvestorData();
          }),
        ),
        _buildFilterChip(
          'Niewykonalne',
          _showOnlyWithUnviableInvestments,
          (value) => setState(() {
            _showOnlyWithUnviableInvestments = value;
            _applyFilters();
          }),
        ),
        _buildFilterChip(
          _sortAscending ? 'Rosnąco' : 'Malejąco',
          true,
          (_) => setState(() {
            _sortAscending = !_sortAscending;
            _applyFilters();
          }),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    bool selected,
    Function(bool) onChanged,
  ) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onChanged,
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  // === LISTA INWESTORÓW ===
  Widget _buildInvestorsList() {
    if (_filteredInvestors.isEmpty) {
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
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textTertiary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index < _filteredInvestors.length) {
          final investor = _filteredInvestors[index];
          final position = index + 1;

          return _buildResponsiveInvestorCard(investor, position);
        }
        return null;
      }, childCount: _filteredInvestors.length),
    );
  }

  Widget _buildResponsiveInvestorCard(InvestorSummary investor, int position) {
    final isTablet = MediaQuery.of(context).size.width > 768;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: isTablet ? 8 : 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showInvestorDetails(investor),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: isTablet
                ? _buildTabletInvestorLayout(investor, position)
                : _buildMobileInvestorLayout(investor, position),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletInvestorLayout(InvestorSummary investor, int position) {
    final percentage = _totalPortfolioValue > 0
        ? (investor.totalValue / _totalPortfolioValue) * 100
        : 0.0;

    return Row(
      children: [
        // Pozycja i avatar
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getClientColor(investor.client),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#$position',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),

        // Główne informacje
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                investor.client.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (investor.client.companyName?.isNotEmpty ?? false)
                Text(
                  investor.client.companyName!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildInfoChip(
                    '${investor.investmentCount} inwestycji',
                    Icons.account_balance_wallet,
                  ),
                  if (investor.hasUnviableInvestments)
                    _buildInfoChip(
                      'Niewykonalne',
                      Icons.warning,
                      AppTheme.warningColor,
                    ),
                  _buildInfoChip(
                    _getVotingStatusText(investor.client.votingStatus),
                    _getVotingStatusIcon(investor.client.votingStatus),
                    _getVotingStatusColor(investor.client.votingStatus),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Wartości finansowe
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatCurrency(investor.totalValue),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(2)}% portfela',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (investor.totalRemainingCapital > 0) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Kapitał',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textTertiary),
                        ),
                        Text(
                          CurrencyFormatter.formatCurrencyShort(
                            investor.totalRemainingCapital,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (investor.totalSharesValue > 0) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Udziały',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textTertiary),
                        ),
                        Text(
                          CurrencyFormatter.formatCurrencyShort(
                            investor.totalSharesValue,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileInvestorLayout(InvestorSummary investor, int position) {
    final percentage = _totalPortfolioValue > 0
        ? (investor.totalValue / _totalPortfolioValue) * 100
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nagłówek z pozycją i nazwą
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getClientColor(investor.client),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#$position',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (investor.client.companyName?.isNotEmpty ?? false)
                    Text(
                      investor.client.companyName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Wartość główna
            Text(
              CurrencyFormatter.formatCurrencyShort(investor.totalValue),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Szczegóły w dwóch kolumnach
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMobileStatItem(
                    'Inwestycje',
                    '${investor.investmentCount}',
                    Icons.account_balance_wallet,
                  ),
                  const SizedBox(height: 4),
                  if (investor.totalRemainingCapital > 0)
                    _buildMobileStatItem(
                      'Kapitał',
                      CurrencyFormatter.formatCurrencyShort(
                        investor.totalRemainingCapital,
                      ),
                      Icons.monetization_on,
                    ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMobileStatItem(
                    'Udział',
                    '${percentage.toStringAsFixed(1)}%',
                    Icons.pie_chart,
                  ),
                  const SizedBox(height: 4),
                  if (investor.totalSharesValue > 0)
                    _buildMobileStatItem(
                      'Udziały',
                      CurrencyFormatter.formatCurrencyShort(
                        investor.totalSharesValue,
                      ),
                      Icons.business,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Statusy i oznaczenia
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _buildMobileChip(
              _getVotingStatusText(investor.client.votingStatus),
              _getVotingStatusColor(investor.client.votingStatus),
            ),
            if (investor.hasUnviableInvestments)
              _buildMobileChip('Niewykonalne', AppTheme.warningColor),
            if (investor.client.email.isNotEmpty)
              _buildMobileChip('Email', AppTheme.infoColor),
          ],
        ),
      ],
    );
  }

  // === POMOCNICZE METODY UI ===
  Widget _buildInfoChip(String label, IconData icon, [Color? color]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color ?? AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // === METODY POMOCNICZE ===
  Color _getClientColor(Client client) {
    try {
      return Color(int.parse('0xFF${client.colorCode.replaceAll('#', '')}'));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  void _showInvestorDetails(InvestorSummary investor) {
    InvestorDetailsModalHelper.show(
      context: context,
      investor: investor,
      onGenerateEmail: (subject) {
        _generateEmailForInvestor(investor, subject);
      },
      onEditInvestor: () {
        _editInvestor(investor);
      },
      onViewInvestments: () {
        _viewInvestorInvestments(investor);
      },
    );
  }

  void _generateEmailForInvestor(InvestorSummary investor, String subject) {
    // TODO: Implement email generation logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generowanie emaila dla ${investor.client.name}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _editInvestor(InvestorSummary investor) {
    // TODO: Navigate to investor edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edycja inwestora: ${investor.client.name}'),
        action: SnackBarAction(
          label: 'Otwórz',
          onPressed: () {
            // Navigate to edit screen
          },
        ),
      ),
    );
  }

  void _viewInvestorInvestments(InvestorSummary investor) {
    // TODO: Navigate to investor investments screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Przeglądanie inwestycji: ${investor.client.name}'),
        action: SnackBarAction(
          label: 'Otwórz',
          onPressed: () {
            // Navigate to investments screen
          },
        ),
      ),
    );
  }

  String _getVotingStatusText(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return 'Za';
      case VotingStatus.no:
        return 'Przeciw';
      case VotingStatus.abstain:
        return 'Wstrzymuję';
      case VotingStatus.undecided:
        return 'Niezdecydowany';
    }
  }

  IconData _getVotingStatusIcon(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return Icons.check_circle;
      case VotingStatus.no:
        return Icons.cancel;
      case VotingStatus.abstain:
        return Icons.remove_circle;
      case VotingStatus.undecided:
        return Icons.help;
    }
  }

  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return AppTheme.successColor;
      case VotingStatus.no:
        return AppTheme.errorColor;
      case VotingStatus.abstain:
        return AppTheme.warningColor;
      case VotingStatus.undecided:
        return AppTheme.textSecondary;
    }
  }

  // Następne kroki będą w kolejnych commitach...
}
