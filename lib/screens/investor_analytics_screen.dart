import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/client.dart';
import '../models/investor_summary.dart';
import '../services/investor_analytics_service.dart';
import '../widgets/investor_details_modal.dart';
import '../utils/currency_formatter.dart';

class InvestorAnalyticsScreen extends StatefulWidget {
  const InvestorAnalyticsScreen({super.key});

  @override
  State<InvestorAnalyticsScreen> createState() =>
      _InvestorAnalyticsScreenState();
}

class _InvestorAnalyticsScreenState extends State<InvestorAnalyticsScreen>
    with TickerProviderStateMixin {
  final InvestorAnalyticsService _analyticsService = InvestorAnalyticsService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  final TextEditingController _companyFilterController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Kontrolery animacji
  late AnimationController _filterAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<Offset> _filterSlideAnimation;
  late Animation<double> _fabScaleAnimation;

  // Stan danych
  List<InvestorSummary> _allInvestors = [];
  List<InvestorSummary> _filteredInvestors = [];
  bool _isLoading = true;
  String? _error;

  // Paginacja responsywna
  int _currentPage = 0;
  int _pageSize = 20; // Zmniejszone dla mobile
  bool _hasNextPage = false;
  bool _hasPreviousPage = false;
  bool _isLoadingMore = false;

  // Analityka
  InvestorRange? _majorityControlPoint;
  double _totalPortfolioValue = 0;

  // Filtry mobilne
  VotingStatus? _selectedVotingStatus;
  ClientType? _selectedClientType;
  bool _includeInactive = false;
  bool _showOnlyWithUnviableInvestments = false;
  bool _isFilterVisible = false;

  // Widok mobilny
  String _currentView = 'list'; // 'list', 'cards', 'grid'
  String _sortBy = 'totalValue'; // 'totalValue', 'name', 'investmentCount'
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();

    // Inicjalizacja animacji
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

    // Infinite scroll setup
    _scrollController.addListener(_onScroll);

    // Inicjalizacja danych
    _loadInvestorData();
    _searchController.addListener(_applyFilters);
    _minAmountController.addListener(_applyFilters);
    _maxAmountController.addListener(_applyFilters);
    _companyFilterController.addListener(_applyFilters);

    // Animacja wejścia FAB
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fabAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    _fabAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _companyFilterController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        _hasNextPage &&
        !_isLoadingMore) {
      _loadMoreInvestors();
    }
  }

  Future<void> _loadMoreInvestors() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final moreInvestors = await _getPagedInvestors(nextPage);

      setState(() {
        _filteredInvestors.addAll(moreInvestors);
        _currentPage = nextPage;
        _hasNextPage = moreInvestors.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd ładowania: $e')));
      }
    }
  }

  Future<List<InvestorSummary>> _getPagedInvestors(int page) async {
    // Symulacja API call z paginacją
    final startIndex = page * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, _allInvestors.length);

    if (startIndex >= _allInvestors.length) return [];

    // Dodanie opóźnienia dla UX
    await Future.delayed(const Duration(milliseconds: 500));

    return _allInvestors.sublist(startIndex, endIndex);
  }

  Future<void> _loadInvestorData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🚀 [Mobile UI] Ładowanie danych inwestorów...');

      // Ładuj wszystkich inwestorów dla analizy offline
      final allInvestors = await _analyticsService.getAllInvestorsForAnalysis(
        includeInactive: _includeInactive,
      );

      // Znajdź punkt kontroli 51%
      final majorityPoint = _analyticsService.findMajorityControlPoint(
        allInvestors,
      );

      // Oblicz łączną wartość portfela
      final totalValue = allInvestors.fold<double>(
        0.0,
        (sum, inv) => sum + inv.totalValue,
      );

      // Sortuj według wybranego kryterium
      _sortInvestors(allInvestors);

      // Inicjalna paginacja - tylko pierwsza strona
      final initialInvestors = allInvestors.take(_pageSize).toList();

      setState(() {
        _allInvestors = allInvestors;
        _filteredInvestors = initialInvestors;
        _majorityControlPoint = majorityPoint;
        _totalPortfolioValue = totalValue;
        _currentPage = 0;
        _hasNextPage = allInvestors.length > _pageSize;
        _hasPreviousPage = false;
        _isLoading = false;
      });

      print('✅ [Mobile UI] Załadowano ${allInvestors.length} inwestorów');
      print(
        '📊 [Mobile UI] Wyświetlam ${initialInvestors.length} na pierwszej stronie',
      );
    } catch (e) {
      print('❌ [Mobile UI] Błąd ładowania: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

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

  // Getter dla aktualnej strony danych
  List<InvestorSummary> get _currentPageData {
    final startIndex = _currentPage * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(
      0,
      _filteredInvestors.length,
    );
    return _filteredInvestors.sublist(startIndex, endIndex);
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
        // Filtr tekstowy (name, company)
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch =
            searchQuery.isEmpty ||
            investor.client.name.toLowerCase().contains(searchQuery) ||
            (investor.client.companyName?.toLowerCase().contains(searchQuery) ??
                false) ||
            investor.client.email.toLowerCase().contains(searchQuery);

        // Filtr kwoty (range)
        final minAmount = double.tryParse(_minAmountController.text);
        final maxAmount = double.tryParse(_maxAmountController.text);
        final matchesAmount =
            (minAmount == null || investor.totalValue >= minAmount) &&
            (maxAmount == null || investor.totalValue <= maxAmount);

        // Filtr firmy/produktu
        final companyQuery = _companyFilterController.text.toLowerCase();
        final matchesCompany =
            companyQuery.isEmpty ||
            investor.investmentsByCompany.keys.any(
              (company) => company.toLowerCase().contains(companyQuery),
            ) ||
            investor.investments.any(
              (inv) => inv.productName.toLowerCase().contains(companyQuery),
            );

        // Filtr statusu głosowania
        final matchesVoting =
            _selectedVotingStatus == null ||
            investor.client.votingStatus == _selectedVotingStatus;

        // Filtr typu klienta
        final matchesType =
            _selectedClientType == null ||
            investor.client.type == _selectedClientType;

        // Filtr niewykonalnych inwestycji
        final matchesUnviable =
            !_showOnlyWithUnviableInvestments ||
            investor.hasUnviableInvestments;

        return matchesSearch &&
            matchesAmount &&
            matchesCompany &&
            matchesVoting &&
            matchesType &&
            matchesUnviable;
      }).toList();

      // Sortuj przefiltrowane dane
      _sortInvestors(filtered);

      // Reset paginacji po filtrowaniu
      _filteredInvestors = filtered.take(_pageSize).toList();
      _currentPage = 0;
      _hasNextPage = filtered.length > _pageSize;
      _hasPreviousPage = false;
    });

    print(
      '🔍 [Mobile UI] Filtrowanie: ${_allInvestors.length} -> ${_filteredInvestors.length} inwestorów',
    );
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

  // Metoda do ładowania konkretnej strony
  void _loadPage(int pageNumber) {
    final totalPages = (_filteredInvestors.length / _pageSize).ceil();

    if (pageNumber < 0 || pageNumber >= totalPages) {
      return; // Strona poza zakresem
    }

    setState(() {
      _currentPage = pageNumber;
      _hasPreviousPage = pageNumber > 0;
      _hasNextPage = pageNumber < totalPages - 1;
    });
  }

  // Metoda do pokazywania szczegółów inwestora
  void _showInvestorDetails(InvestorSummary investor) {
    InvestorDetailsModalHelper.show(
      context: context,
      investor: investor,
      analyticsService: _analyticsService,
      onEditInvestor: () {
        _editInvestor(investor);
      },
      onViewInvestments: () {
        _viewInvestorInvestments(investor);
      },
      onUpdateInvestor: (updatedInvestor) {
        _updateInvestorInList(updatedInvestor);
        _loadAllInvestors(); // Odśwież dane po aktualizacji
      },
    );
  }

  void _updateInvestorInList(InvestorSummary updatedInvestor) {
    setState(() {
      // Znajdź i zaktualizuj inwestora na liście
      final index = _filteredInvestors.indexWhere(
        (investor) => investor.client.id == updatedInvestor.client.id,
      );
      if (index != -1) {
        _filteredInvestors[index] = updatedInvestor;
      }

      // Również zaktualizuj na głównej liście
      final allIndex = _allInvestors.indexWhere(
        (investor) => investor.client.id == updatedInvestor.client.id,
      );
      if (allIndex != -1) {
        _allInvestors[allIndex] = updatedInvestor;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Zaktualizowano dane inwestora: ${updatedInvestor.client.name}',
        ),
        backgroundColor: AppTheme.successPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editInvestor(InvestorSummary investor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edycja inwestora: ${investor.client.name}'),
        action: SnackBarAction(
          label: 'Otwórz',
          onPressed: () {
            // TODO: Navigate to edit screen
          },
        ),
      ),
    );
  }

  void _viewInvestorInvestments(InvestorSummary investor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Przeglądanie inwestycji: ${investor.client.name}'),
        action: SnackBarAction(
          label: 'Otwórz',
          onPressed: () {
            // TODO: Navigate to investments screen
          },
        ),
      ),
    );
  }

  void _changeView(String newView) {
    setState(() {
      _currentView = newView;
    });

    // Animacja zmiany widoku
    _fabAnimationController.reverse().then((_) {
      _fabAnimationController.forward();
    });
  }

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

  Widget _buildSummarySliver(bool isTablet) {
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.surfaceCard, AppTheme.backgroundSecondary],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondaryGold.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppTheme.secondaryGold.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryHeader(),
              const SizedBox(height: 24),
              if (isTablet)
                _buildTabletSummaryGrid()
              else
                _buildMobileSummaryColumn(),
              if (_majorityControlPoint != null) ...[
                const SizedBox(height: 24),
                _buildMajorityControlInfo(isTablet),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.secondaryGold,
                AppTheme.secondaryGold.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryGold.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.analytics,
            color: AppTheme.backgroundSecondary,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Podsumowanie portfela',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Analiza inwestorów i wartości',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.secondaryGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.secondaryGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            'LIVE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.secondaryGold,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletSummaryGrid() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      child: Row(
        children: [
          Expanded(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: _buildModernSummaryItem(
                      'Łączna liczba inwestorów',
                      '${_allInvestors.length}',
                      Icons.people_alt_rounded,
                      AppTheme.primaryColor,
                      0,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: _buildModernSummaryItem(
                      'Wyświetlanych',
                      '${_filteredInvestors.length}',
                      Icons.visibility_rounded,
                      AppTheme.secondaryGold,
                      100,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: _buildModernSummaryItem(
                      'Wartość portfela',
                      CurrencyFormatter.formatCurrencyShort(
                        _totalPortfolioValue,
                      ),
                      Icons.account_balance_wallet_rounded,
                      AppTheme.successColor,
                      200,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSummaryColumn() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: _buildModernSummaryItem(
                          'Inwestorzy',
                          '${_filteredInvestors.length}/${_allInvestors.length}',
                          Icons.people_alt_rounded,
                          AppTheme.primaryColor,
                          0,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: _buildModernSummaryItem(
                          'Portfel',
                          CurrencyFormatter.formatCurrencyShort(
                            _totalPortfolioValue,
                          ),
                          Icons.account_balance_wallet_rounded,
                          AppTheme.successColor,
                          100,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
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
                  Icon(Icons.filter_list, color: AppTheme.secondaryGold),
                  const SizedBox(width: 8),
                  Text(
                    'Filtry i sortowanie',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
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
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Szukaj inwestora',
                  hintText: 'Nazwa, email...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _companyFilterController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Firma/Produkt',
                  hintText: 'Nazwa firmy...',
                  prefixIcon: Icon(
                    Icons.business,
                    color: AppTheme.textSecondary,
                  ),
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minAmountController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Min. kwota',
                  hintText: '0',
                  prefixIcon: Icon(
                    Icons.currency_exchange,
                    color: AppTheme.textSecondary,
                  ),
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _maxAmountController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Max. kwota',
                  hintText: '∞',
                  prefixIcon: Icon(
                    Icons.currency_exchange,
                    color: AppTheme.textSecondary,
                  ),
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildSortDropdown()),
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
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Szukaj inwestora',
            hintText: 'Nazwa, email, firma...',
            prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
            labelStyle: TextStyle(color: AppTheme.textSecondary),
            hintStyle: TextStyle(color: AppTheme.textTertiary),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minAmountController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Min. kwota',
                  hintText: '0',
                  prefixIcon: Icon(
                    Icons.currency_exchange,
                    color: AppTheme.textSecondary,
                  ),
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _maxAmountController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Max. kwota',
                  hintText: '∞',
                  prefixIcon: Icon(
                    Icons.currency_exchange,
                    color: AppTheme.textSecondary,
                  ),
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSortDropdown(),
        const SizedBox(height: 12),
        _buildFilterChips(),
      ],
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButtonFormField<String>(
      value: _sortBy,
      style: const TextStyle(color: AppTheme.textPrimary),
      dropdownColor: AppTheme.surfaceCard,
      decoration: const InputDecoration(
        labelText: 'Sortuj według',
        prefixIcon: Icon(Icons.sort, color: AppTheme.textSecondary),
        labelStyle: TextStyle(color: AppTheme.textSecondary),
      ),
      items: const [
        DropdownMenuItem(
          value: 'totalValue',
          child: Text(
            'Wartość portfela',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
        ),
        DropdownMenuItem(
          value: 'name',
          child: Text(
            'Nazwa klienta',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
        ),
        DropdownMenuItem(
          value: 'investmentCount',
          child: Text(
            'Liczba inwestycji',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
        ),
      ],
      onChanged: (value) {
        if (value != null) _changeSortOrder(value);
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
      label: Text(
        label,
        style: TextStyle(
          color: selected ? AppTheme.textOnSecondary : AppTheme.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      onSelected: onChanged,
      selectedColor: AppTheme.secondaryGold.withOpacity(0.2),
      backgroundColor: AppTheme.surfaceElevated,
      checkmarkColor: AppTheme.secondaryGold,
      side: BorderSide(
        color: selected ? AppTheme.secondaryGold : AppTheme.borderSecondary,
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildViewOptionsBottomSheet() {
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
                  _buildViewOption('Lista', 'list', Icons.view_list),
                  _buildViewOption('Karty', 'cards', Icons.view_agenda),
                  _buildViewOption('Kafelki', 'grid', Icons.grid_view),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewOption(String title, String viewType, IconData icon) {
    final isSelected = _currentView == viewType;

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
          _changeView(viewType);
          Navigator.pop(context);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isSelected
            ? AppTheme.secondaryGold.withOpacity(0.1)
            : Colors.transparent,
      ),
    );
  }

  void _generateEmailList() {
    final selectedIds = _filteredInvestors
        .where((inv) => inv.client.email.isNotEmpty)
        .map((inv) => inv.client.id)
        .toList();

    showDialog(
      context: context,
      builder: (context) => _EmailGeneratorDialog(
        analyticsService: _analyticsService,
        clientIds: selectedIds,
      ),
    );
  }

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
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.secondaryGold),
              ),
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
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.secondaryGold,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
      floatingActionButton: _buildResponsiveFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildResponsiveAppBar(BuildContext context, bool isTablet) {
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
            color: AppTheme.secondaryGold,
          ),
          onPressed: _toggleFilter,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.secondaryGold),
          color: AppTheme.surfaceCard,
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

  Widget _buildQuickStats() {
    if (_isLoading) {
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

  Widget _buildResponsiveFAB() {
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => _buildViewOptionsBottomSheet(),
          );
        },
        backgroundColor: AppTheme.secondaryGold,
        foregroundColor: AppTheme.backgroundSecondary,
        icon: Icon(_getViewIcon()),
        label: Text(_getViewLabel()),
      ),
    );
  }

  IconData _getViewIcon() {
    switch (_currentView) {
      case 'cards':
        return Icons.view_agenda;
      case 'grid':
        return Icons.grid_view;
      default:
        return Icons.view_list;
    }
  }

  String _getViewLabel() {
    switch (_currentView) {
      case 'cards':
        return 'Karty';
      case 'grid':
        return 'Kafelki';
      default:
        return 'Lista';
    }
  }

  Widget _buildModernSummaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
    int delay,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.08), color.withOpacity(0.03)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Container(
                    width: 4,
                    height: 40 * animationValue,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [color, color.withOpacity(0.3)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvestorsList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.secondaryGold),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text(
                'Błąd podczas ładowania danych',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
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

    if (_filteredInvestors.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Brak inwestorów spełniających kryteria',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    final currentPageData = _currentPageData;
    final startIndex = _currentPage * _pageSize;

    // Wybór widoku na podstawie _currentView
    if (_currentView == 'grid') {
      return _buildInvestorsGrid(currentPageData, startIndex);
    } else if (_currentView == 'cards') {
      return _buildInvestorsCards(currentPageData, startIndex);
    } else {
      return _buildInvestorsList_Classic(currentPageData, startIndex);
    }
  }

  Widget _buildInvestorsList_Classic(
    List<InvestorSummary> currentPageData,
    int startIndex,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // First item: pagination controls (if needed)
          if (index == 0 && _filteredInvestors.length > _pageSize) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: _buildPaginationControls(),
            );
          }

          // Adjust index for investor data
          final adjustedIndex = _filteredInvestors.length > _pageSize
              ? index - 1
              : index;

          // Investor cards
          if (adjustedIndex >= 0 && adjustedIndex < currentPageData.length) {
            final investor = currentPageData[adjustedIndex];
            final globalPosition = startIndex + adjustedIndex + 1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildInvestorCard(investor, globalPosition),
            );
          }

          // Last item: pagination controls (if needed)
          if (adjustedIndex == currentPageData.length &&
              _filteredInvestors.length > _pageSize) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: _buildPaginationControls(),
            );
          }

          return null;
        },
        childCount:
            currentPageData.length +
            (_filteredInvestors.length > _pageSize
                ? 2
                : 0), // +2 for top and bottom pagination
      ),
    );
  }

  Widget _buildInvestorsGrid(
    List<InvestorSummary> currentPageData,
    int startIndex,
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
            return _buildInvestorGridTile(investor, globalPosition);
          }
          return null;
        }, childCount: currentPageData.length),
      ),
    );
  }

  Widget _buildInvestorsCards(
    List<InvestorSummary> currentPageData,
    int startIndex,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index < currentPageData.length) {
          final investor = currentPageData[index];
          final globalPosition = startIndex + index + 1;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _buildInvestorCompactCard(investor, globalPosition),
          );
        }
        return null;
      }, childCount: currentPageData.length),
    );
  }

  Widget _buildPaginationControls() {
    final totalPages = (_filteredInvestors.length / _pageSize)
        .ceil()
        .clamp(1, double.infinity)
        .toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _hasPreviousPage
                    ? () => _loadPage(_currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                'Strona ${_currentPage + 1} z $totalPages',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              IconButton(
                onPressed: _hasNextPage
                    ? () => _loadPage(_currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'Rozmiar strony:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _pageSize,
                items: [25, 50, 100, 200]
                    .map(
                      (size) =>
                          DropdownMenuItem(value: size, child: Text('$size')),
                    )
                    .toList(),
                onChanged: (newSize) {
                  if (newSize != null) {
                    setState(() {
                      _pageSize = newSize;
                      _currentPage = 0; // Reset do pierwszej strony
                      _loadPage(0);
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvestorCard(InvestorSummary investor, int position) {
    final percentage = _totalPortfolioValue > 0
        ? (investor.totalValue / _totalPortfolioValue) * 100
        : 0.0;

    Color cardColor = AppTheme.primaryAccent;
    try {
      cardColor = Color(
        int.parse('0xFF${investor.client.colorCode.replaceAll('#', '')}'),
      );
    } catch (e) {
      cardColor = AppTheme.primaryAccent;
    }

    final companies = investor.investments
        .map((inv) => inv.productName)
        .toSet()
        .take(3)
        .toList();

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (position * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.surfaceCard, AppTheme.backgroundSecondary],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardColor.withOpacity(0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: cardColor.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showInvestorDetails(investor),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildPositionBadge(position, cardColor),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildInvestorInfo(investor, companies),
                              ),
                              _buildValueSection(investor, percentage),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildStatsRow(investor),
                          const SizedBox(height: 16),
                          _buildTagsSection(investor),
                          if (investor.client.notes.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildNotesCard(investor),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPositionBadge(int position, Color cardColor) {
    // Użyj bezpiecznego koloru tła i tekstu dla lepszego kontrastu
    Color safeBackgroundColor = AppTheme.secondaryGold;
    Color textColor = Colors.white;

    // Jeśli cardColor jest zbyt jasny, użyj ciemniejszego tła
    if (cardColor.computeLuminance() > 0.5) {
      safeBackgroundColor = AppTheme.primaryColor;
    } else {
      safeBackgroundColor = cardColor;
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [safeBackgroundColor, safeBackgroundColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: safeBackgroundColor.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Center(
        child: Text(
          '#$position',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvestorInfo(InvestorSummary investor, List<String> companies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          investor.client.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (investor.client.companyName?.isNotEmpty ?? false) ...[
          const SizedBox(height: 4),
          Text(
            investor.client.companyName!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (companies.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.secondaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.secondaryGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.business_rounded,
                  size: 16,
                  color: AppTheme.secondaryGold,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    companies.join(', ') +
                        (investor.investments.length > 3
                            ? ' (+${investor.investments.length - 3})'
                            : ''),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryGold,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildValueSection(InvestorSummary investor, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.successColor,
                AppTheme.successColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppTheme.successColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            CurrencyFormatter.formatCurrency(
              investor.totalValue,
              showDecimals: false,
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.infoColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppTheme.infoColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            '${percentage.toStringAsFixed(1)}% portfela',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.infoColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(InvestorSummary investor) {
    return Row(
      children: [
        if (investor.totalRemainingCapital > 0) ...[
          Expanded(
            child: _buildStatCard(
              'Kapitał',
              CurrencyFormatter.formatCurrencyShort(
                investor.totalRemainingCapital,
              ),
              Icons.monetization_on_rounded,
              AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (investor.totalSharesValue > 0) ...[
          Expanded(
            child: _buildStatCard(
              'Udziały',
              CurrencyFormatter.formatCurrencyShort(investor.totalSharesValue),
              Icons.pie_chart_rounded,
              AppTheme.warningColor,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: _buildStatCard(
            'Inwestycje',
            '${investor.investmentCount}',
            Icons.account_balance_wallet_rounded,
            AppTheme.secondaryGold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
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

  Widget _buildTagsSection(InvestorSummary investor) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _buildModernStatusChip(
          _getVotingStatusText(investor.client.votingStatus),
          _getVotingStatusIcon(investor.client.votingStatus),
          _getVotingStatusColor(investor.client.votingStatus),
        ),
        _buildModernStatusChip(
          _getClientTypeText(investor.client.type),
          Icons.person_rounded,
          AppTheme.textSecondary,
        ),
        if (investor.hasUnviableInvestments)
          _buildModernStatusChip(
            'Niewykonalne',
            Icons.warning_rounded,
            AppTheme.errorColor,
          ),
        if (investor.client.email.isNotEmpty)
          _buildModernStatusChip(
            'Email',
            Icons.email_rounded,
            AppTheme.infoColor,
          ),
      ],
    );
  }

  Widget _buildModernStatusChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(InvestorSummary investor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.backgroundSecondary, AppTheme.surfaceCard],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.secondaryGold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.note_rounded,
              size: 18,
              color: AppTheme.secondaryGold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              investor.client.notes,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
        return 'Wstrzymuje się';
      case VotingStatus.undecided:
        return 'Niezdecydowany';
    }
  }

  String _getClientTypeText(ClientType type) {
    return type.displayName;
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

  // Metody dla różnych widoków
  Widget _buildInvestorGridTile(InvestorSummary investor, int position) {
    final percentage = _totalPortfolioValue > 0
        ? (investor.totalValue / _totalPortfolioValue) * 100
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceCard,
            AppTheme.backgroundSecondary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryGold.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppTheme.borderSecondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showInvestorDetails(investor),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pozycja i wartość
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#$position',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Nazwa klienta
              Text(
                investor.client.name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Wartość
              Text(
                CurrencyFormatter.formatCurrency(
                  investor.totalValue,
                  showDecimals: false,
                ),
                style: TextStyle(
                  color: AppTheme.successColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Liczba inwestycji
              Text(
                '${investor.investmentCount} inwestycji',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),

              const Spacer(),

              // Status
              Row(
                children: [
                  Icon(
                    _getVotingStatusIcon(investor.client.votingStatus),
                    size: 14,
                    color: _getVotingStatusColor(investor.client.votingStatus),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _getVotingStatusText(investor.client.votingStatus),
                      style: TextStyle(
                        color: _getVotingStatusColor(
                          investor.client.votingStatus,
                        ),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildInvestorCompactCard(InvestorSummary investor, int position) {
    final percentage = _totalPortfolioValue > 0
        ? (investor.totalValue / _totalPortfolioValue) * 100
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceCard,
            AppTheme.backgroundSecondary.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryGold.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppTheme.borderSecondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showInvestorDetails(investor),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Pozycja
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryGold,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    '#$position',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Informacje
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      investor.client.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.formatCurrency(
                        investor.totalValue,
                        showDecimals: false,
                      ),
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${investor.investmentCount} inwestycji • ${percentage.toStringAsFixed(1)}% portfela',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Status ikona
              Icon(
                _getVotingStatusIcon(investor.client.votingStatus),
                color: _getVotingStatusColor(investor.client.votingStatus),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dialog szczegółów inwestora
class _InvestorDetailsDialog extends StatefulWidget {
  final InvestorSummary investor;
  final InvestorAnalyticsService analyticsService;
  final VoidCallback onUpdate;

  const _InvestorDetailsDialog({
    required this.investor,
    required this.analyticsService,
    required this.onUpdate,
  });

  @override
  State<_InvestorDetailsDialog> createState() => _InvestorDetailsDialogState();
}

class _InvestorDetailsDialogState extends State<_InvestorDetailsDialog> {
  late TextEditingController _notesController;
  late VotingStatus _selectedVotingStatus;
  String _selectedColor = '#FFFFFF';
  List<String> _selectedUnviableInvestments = [];

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.investor.client.notes,
    );
    _selectedVotingStatus = widget.investor.client.votingStatus;
    _selectedColor = widget.investor.client.colorCode;
    _selectedUnviableInvestments = List.from(
      widget.investor.client.unviableInvestments,
    );
  }

  Future<void> _saveChanges() async {
    try {
      await widget.analyticsService.updateInvestorNotes(
        widget.investor.client.id,
        _notesController.text,
      );

      await widget.analyticsService.updateVotingStatus(
        widget.investor.client.id,
        _selectedVotingStatus,
      );

      await widget.analyticsService.updateInvestorColor(
        widget.investor.client.id,
        _selectedColor,
      );

      await widget.analyticsService.markInvestmentsAsUnviable(
        widget.investor.client.id,
        _selectedUnviableInvestments,
      );

      Navigator.of(context).pop();
      widget.onUpdate();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Zmiany zostały zapisane')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.investor.client.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Podstawowe informacje
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Podsumowanie inwestycji',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Łączna wartość',
                            '${CurrencyFormatter.formatCurrency(widget.investor.totalValue, showDecimals: false)}',
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Liczba inwestycji',
                            '${widget.investor.investmentCount}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Kapitał pozostały',
                            '${CurrencyFormatter.formatCurrency(widget.investor.totalRemainingCapital, showDecimals: false)}',
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Wartość udziałów',
                            '${CurrencyFormatter.formatCurrency(widget.investor.totalSharesValue, showDecimals: false)}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Edycja danych
            Text(
              'Edycja danych',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Status głosowania
            DropdownButtonFormField<VotingStatus>(
              value: _selectedVotingStatus,
              decoration: const InputDecoration(labelText: 'Status głosowania'),
              items: VotingStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Icon(
                            _getVotingStatusIcon(status),
                            color: _getVotingStatusColor(status),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(status.displayName),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedVotingStatus = value!);
              },
            ),

            const SizedBox(height: 12),

            // Notatki
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notatki',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            // Lista inwestycji z możliwością oznaczania jako niewykonalne
            Text(
              'Inwestycje (${widget.investor.investments.length})',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: widget.investor.investments.length,
                itemBuilder: (context, index) {
                  final investment = widget.investor.investments[index];
                  final isUnviable = _selectedUnviableInvestments.contains(
                    investment.id,
                  );

                  return CheckboxListTile(
                    title: Text(investment.productName),
                    subtitle: Text(
                      '${CurrencyFormatter.formatCurrency(investment.remainingCapital, showDecimals: false)} - ${investment.creditorCompany}',
                    ),
                    value: isUnviable,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedUnviableInvestments.add(investment.id);
                        } else {
                          _selectedUnviableInvestments.remove(investment.id);
                        }
                      });
                    },
                    secondary: Icon(
                      isUnviable ? Icons.warning : Icons.check_circle,
                      color: isUnviable
                          ? AppTheme.warningColor
                          : AppTheme.successColor,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Przyciski akcji
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Anuluj'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveChanges,
                  child: const Text('Zapisz'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
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
}

// Dialog generowania maili
class _EmailGeneratorDialog extends StatefulWidget {
  final InvestorAnalyticsService analyticsService;
  final List<String> clientIds;

  const _EmailGeneratorDialog({
    required this.analyticsService,
    required this.clientIds,
  });

  @override
  State<_EmailGeneratorDialog> createState() => _EmailGeneratorDialogState();
}

class _EmailGeneratorDialogState extends State<_EmailGeneratorDialog> {
  List<InvestorSummary> _emailData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmailData();
  }

  Future<void> _loadEmailData() async {
    try {
      final data = await widget.analyticsService.getInvestorsByClientIds(
        widget.clientIds,
      );
      setState(() {
        _emailData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
    }
  }

  void _copyEmailList() {
    final emails = _emailData.map((data) => data.client.email).join('; ');
    Clipboard.setData(ClipboardData(text: emails));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lista maili została skopiowana')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Generator maili (${_emailData.length})',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.secondaryGold,
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _copyEmailList,
                    icon: const Icon(Icons.copy),
                    label: const Text('Kopiuj listę maili'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryGold,
                      foregroundColor: AppTheme.backgroundSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  itemCount: _emailData.length,
                  itemBuilder: (context, index) {
                    final data = _emailData[index];
                    return Card(
                      color: AppTheme.backgroundSecondary,
                      child: ExpansionTile(
                        title: Text(
                          data.client.name,
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                        subtitle: Text(
                          data.client.email,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        iconColor: AppTheme.secondaryGold,
                        collapsedIconColor: AppTheme.textSecondary,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Inwestycje:',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  data.formattedInvestmentList,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
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
          ],
        ),
      ),
    );
  }
}
