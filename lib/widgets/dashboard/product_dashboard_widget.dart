import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme_professional.dart';
import '../../models_and_services.dart';
import '../premium_error_widget.dart';
import 'personal_greeting_week_widget.dart';

/// 🚀 METROPOLITAN PRODUCT DASHBOARD
/// Nowoczesny, funkcjonalny dashboard produktów inwestycyjnych
///
/// Funkcje:
/// - Powitanie zalogowanego użytkownika z logo
/// - Górny panel - szybkie podsumowanie (5 kafli)
/// - Sekcja szczegółów produktu
/// - Terminy i oś czasu z kolorowymi ostrzeżeniami
/// - Sekcja ryzyk i statusów finansowych
/// - Płynne animacje i mikrointerakcje
class ProductDashboardWidget extends StatefulWidget {
  const ProductDashboardWidget({super.key});

  @override
  State<ProductDashboardWidget> createState() => _ProductDashboardWidgetState();
}

class _ProductDashboardWidgetState extends State<ProductDashboardWidget>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Services
  final AuthService _authService = AuthService();
  final OptimizedProductService _optimizedProductService =
      OptimizedProductService(); // 🚀 NOWY
  final UnifiedDashboardStatisticsService _statisticsService =
      UnifiedDashboardStatisticsService();

  // State
  bool _isLoading = true;
  String? _error;
  UserProfile? _userProfile;
  List<Investment> _investments = [];
  List<OptimizedProduct> _optimizedProducts = []; // 🚀 NOWY TYP
  List<Investment> _filteredInvestments = [];
  List<OptimizedProduct> _filteredOptimizedProducts = []; // 🚀 NOWY TYP
  Investment? _selectedInvestment;
  Set<String> _selectedProductIds = {};
  final bool _showOptimizedView =
      true; // 🚀 NOWA FLAGA - domyślnie zoptymalizowany widok
  UnifiedDashboardStatistics?
  _dashboardStatistics; // 🚀 NOWE: Zunifikowane statystyki

  // 🚀 COMPATIBILITY: Dodaj aliasy dla kompatybilności wstecznej
  List<OptimizedProduct> get _deduplicatedProducts => _optimizedProducts;
  List<OptimizedProduct> get _filteredDeduplicatedProducts =>
      _filteredOptimizedProducts;
  bool get _showDeduplicatedView => _showOptimizedView;

  // Filtering and sorting state
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'amount', 'date', 'type', 'status'
  bool _sortAscending = true;
  UnifiedProductType? _filterByType;
  InvestmentStatus? _filterByStatus;
  ProductStatus? _filterByProductStatus;

  // Date formatter
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy', 'pl_PL');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pl_PL',
    symbol: 'zł',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load user profile
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _userProfile = await _authService.getUserProfile(currentUser.uid);
      }

      // 🚀 NOWE: Używaj zoptymalizowanego serwisu - JEDNO WYWOŁANIE zamiast setek
      final optimizedResult = await _optimizedProductService
          .getAllProductsOptimized(forceRefresh: true, includeStatistics: true);

      _optimizedProducts = optimizedResult.products;

      // 🚀 OPTYMALIZACJA: Nie rób dodatkowego wywołania getAllInvestments - użyj danych z OptimizedProductService
      if (kDebugMode) {
        print(
          '🚀 [ProductDashboardWidget] Używam danych z OptimizedProductService - brak dodatkowych wywołań!',
        );
        print(
          '🚀 [ProductDashboardWidget] Produkty: ${optimizedResult.products.length}',
        );
      }

      // 🚀 NOWE: Używaj OptimizedProduct bezpośrednio, nie konwertuj na Investment
      // Investment jest zbyt różne od OptimizedProduct - zostaw puste i użyj _optimizedProducts
      _investments =
          []; // Puste - używamy _optimizedProducts zamiast _investments

      if (kDebugMode) {
        print(
          '🚀 [ProductDashboardWidget] Używam ${_optimizedProducts.length} OptimizedProducts bezpośrednio',
        );
      }

      // Load dashboard statistics
      if (optimizedResult.statistics != null) {
        // 🚀 FIXED: Konwertuj GlobalProductStatistics na UnifiedDashboardStatistics
        _dashboardStatistics = _convertGlobalStatsToUnified(
          optimizedResult.statistics!,
        );
        if (kDebugMode) {
          print(
            '🎯 [ProductDashboardWidget] Używam statystyk z OptimizedProductService',
          );
        }
      } else {
        // Fallback na serwis inwestorów
        _dashboardStatistics = await _statisticsService
            .getStatisticsFromInvestors();
        if (kDebugMode) {
          print(
            '🔄 [ProductDashboardWidget] Fallback na UnifiedDashboardStatisticsService',
          );
        }
      }

      // Apply filtering and sorting
      _applyFilteringAndSorting();

      // Select first investment if available
      _selectedInvestment = _investments.isNotEmpty ? _investments.first : null;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Start animations
      _fadeController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _slideController.forward();
      await Future.delayed(const Duration(milliseconds: 100));
      _scaleController.forward();

      if (kDebugMode) {
        print(
          '✅ [ProductDashboard] Załadowano ${_optimizedProducts.length} produktów w ${optimizedResult.executionTime}ms (cache: ${optimizedResult.fromCache})',
        );
        print(
          '📊 [ProductDashboard] Statystyki dostępne: ${_dashboardStatistics != null}',
        );
        if (_dashboardStatistics != null) {
          print(
            '💰 [ProductDashboard] Źródło statystyk: ${_dashboardStatistics!.dataSource}',
          );
          print(
            '💰 [ProductDashboard] Total Investment Amount: ${_dashboardStatistics!.totalInvestmentAmount}',
          );
          print(
            '💰 [ProductDashboard] Total Remaining Capital: ${_dashboardStatistics!.totalRemainingCapital}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Błąd podczas ładowania danych: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // Filtering and sorting methods
  void _applyFilteringAndSorting() {
    // Apply filtering and sorting to investments
    _filteredInvestments = _investments.where((investment) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!investment.productName.toLowerCase().contains(query) &&
            !investment.clientName.toLowerCase().contains(query) &&
            !investment.creditorCompany.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Type filter
      if (_filterByType != null && investment.productType != _filterByType) {
        return false;
      }

      // Status filter
      if (_filterByStatus != null && investment.status != _filterByStatus) {
        return false;
      }

      return true;
    }).toList();

    // 🚀 NOWE: Apply filtering and sorting to optimized products
    _filteredOptimizedProducts = _optimizedProducts.where((product) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!product.name.toLowerCase().contains(query) &&
            !product.companyName.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Type filter
      if (_filterByType != null && product.productType != _filterByType) {
        return false;
      }

      // Status filter (for optimized products)
      if (_filterByProductStatus != null &&
          product.status != _filterByProductStatus) {
        return false;
      }

      return true;
    }).toList();

    // Sort investments
    _filteredInvestments.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.productName.compareTo(b.productName);
          break;
        case 'client':
          comparison = a.clientName.compareTo(b.clientName);
          break;
        case 'amount':
          comparison = a.remainingCapital.compareTo(b.remainingCapital);
          break;
        case 'date':
          comparison = a.signedDate.compareTo(b.signedDate);
          break;
        case 'type':
          comparison = a.productType.displayName.compareTo(
            b.productType.displayName,
          );
          break;
        case 'status':
          comparison = a.status.displayName.compareTo(b.status.displayName);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    // 🚀 NOWE: Sort optimized products
    _filteredOptimizedProducts.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'company':
          comparison = a.companyName.compareTo(b.companyName);
          break;
        case 'amount':
          comparison = a.totalRemainingCapital.compareTo(
            b.totalRemainingCapital,
          );
          break;
        case 'investments':
          comparison = a.totalInvestments.compareTo(b.totalInvestments);
          break;
        case 'investors':
          comparison = a.actualInvestorCount.compareTo(b.actualInvestorCount);
          break;
        case 'type':
          comparison = a.productType.displayName.compareTo(
            b.productType.displayName,
          );
          break;
        case 'status':
          comparison = a.status.displayName.compareTo(b.status.displayName);
          break;
        case 'value':
          comparison = a.totalValue.compareTo(b.totalValue);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilteringAndSorting();
    });
  }

  void _updateSort(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = sortBy;
        _sortAscending = true;
      }
      _applyFilteringAndSorting();
    });
  }

  void _updateTypeFilter(UnifiedProductType? type) {
    setState(() {
      _filterByType = type;
      _applyFilteringAndSorting();
    });
  }

  void _updateStatusFilter(dynamic status) {
    setState(() {
      if (status is InvestmentStatus) {
        _filterByStatus = status;
        _filterByProductStatus = null;
      } else if (status is ProductStatus) {
        _filterByProductStatus = status;
        _filterByStatus = null;
      } else {
        _filterByStatus = null;
        _filterByProductStatus = null;
      }
      _applyFilteringAndSorting();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: PremiumShimmerLoadingWidget.fullScreen());
    }

    if (_error != null) {
      return Center(
        child: PremiumErrorWidget(error: _error!, onRetry: _loadData),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppThemePro.backgroundPrimary,
            AppThemePro.backgroundSecondary.withOpacity(0.5),
          ],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal greeting + this week's tasks
            PersonalGreetingWeekWidget(userProfile: _userProfile),
            const SizedBox(height: 20),

            // Quick summary tiles - CAŁA BAZA DANYCH
            _buildGlobalSummary(),
            const SizedBox(height: 32),

            // Product selector
            _buildProductSelector(),
            const SizedBox(height: 32),

            // Selected products summary - WYBRANE PRODUKTY
            _buildSelectedProductsSummary(),
            const SizedBox(height: 32),

            // Product details section - SZCZEGÓŁY WYBRANYCH PRODUKTÓW
            _buildSelectedProductsDetails(),
            const SizedBox(height: 32),

            // Timeline section
            _buildTimelineSection(),
            const SizedBox(height: 32),

            // Financial risks section
            _buildFinancialRisksSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalSummary() {
    // 🚀 NOWE: Używamy zunifikowanych statystyk zamiast manualnych obliczeń
    if (_dashboardStatistics == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: AppThemePro.premiumCardDecoration,
        child: Center(
          child: Text(
            'Ładowanie statystyk...',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppThemePro.textMuted),
          ),
        ),
      );
    }

    final stats = _dashboardStatistics!;

    final tiles = [
      _SummaryTileData(
        title: 'Łączna kwota inwestycji',
        value: _currencyFormat.format(stats.totalInvestmentAmount),
        icon: Icons.account_balance_wallet,
        color: AppThemePro.accentGold,
        trend: null,
      ),
      _SummaryTileData(
        title: 'Łączny pozostały kapitał',
        value: _currencyFormat.format(stats.totalRemainingCapital),
        icon: Icons.trending_up,
        color: AppThemePro.profitGreen,
        trend: stats.totalRemainingCapital > 0 ? 'positive' : 'negative',
      ),
      _SummaryTileData(
        title: 'Łączny kapitał zabezpieczony',
        value: _currencyFormat.format(stats.totalCapitalSecured),
        icon: Icons.security,
        color: AppThemePro.bondsBlue,
        trend: null,
      ),
      _SummaryTileData(
        title: 'Łączny kapitał w restrukturyzacji',
        value: _currencyFormat.format(stats.totalCapitalForRestructuring),
        icon: Icons.refresh,
        color: AppThemePro.loansOrange,
        trend: stats.totalCapitalForRestructuring > 0 ? 'warning' : null,
      ),
      _SummaryTileData(
        title: 'Liczba produktów (unikalne)',
        value: '${_deduplicatedProducts.length}',
        icon: Icons.inventory,
        color: AppThemePro.neutralGray,
        trend: null,
      ),
    ];

    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Podsumowanie',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppThemePro.accentGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppThemePro.accentGold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'GLOBALNE • ${_deduplicatedProducts.length} UNIKALNYCH',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppThemePro.accentGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 1200;
              final crossAxisCount = isWide
                  ? 5
                  : (constraints.maxWidth > 800 ? 3 : 2);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: tiles.length,
                itemBuilder: (context, index) =>
                    _buildSummaryTile(tiles[index], index),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelector() {
    // Wybierz odpowiedną listę na podstawie trybu wyświetlania
    final displayList = _showDeduplicatedView
        ? _filteredDeduplicatedProducts
        : _filteredInvestments;
    final totalCount = displayList.length;
    final totalUnfilteredCount = _showDeduplicatedView
        ? _deduplicatedProducts.length
        : _investments.length;

    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wybierz produkty do analizy',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppThemePro.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _showDeduplicatedView
                        ? 'Widok: Produkty unikalne ($totalCount z $totalUnfilteredCount pozycji)'
                        : 'Widok: Wszystkie inwestycje ($totalCount z $totalUnfilteredCount pozycji)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_showDeduplicatedView) {
                          _selectedProductIds = _filteredDeduplicatedProducts
                              .map((prod) => prod.id)
                              .toSet();
                        } else {
                          _selectedProductIds = _filteredInvestments
                              .map((inv) => inv.id)
                              .toSet();
                        }
                      });
                    },
                    icon: Icon(Icons.select_all, size: 18),
                    label: Text('Zaznacz wszystkie'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppThemePro.accentGold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedProductIds.clear();
                      });
                    },
                    icon: Icon(Icons.clear, size: 18),
                    label: Text('Wyczyść'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppThemePro.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search and filters row
          _buildSearchAndFilters(),
          const SizedBox(height: 16),

          Container(
            decoration: AppThemePro.premiumCardDecoration,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppThemePro.accentGold.withOpacity(0.05),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppThemePro.accentGold,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Wybrane produkty: ${_selectedProductIds.length}/$totalCount',
                        style: TextStyle(
                          color: AppThemePro.accentGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (totalCount != totalUnfilteredCount) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppThemePro.statusInfo.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppThemePro.statusInfo.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'PRZEFILTROWANO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppThemePro.statusInfo,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 400,
                  ), // Zwiększ wysokość
                  child: _showDeduplicatedView
                      ? _buildDeduplicatedProductsList()
                      : _buildInvestmentsList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary, width: 1),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: _updateSearch,
            decoration: InputDecoration(
              hintText: _showDeduplicatedView
                  ? 'Szukaj produktów lub firm...'
                  : 'Szukaj produktów, klientów lub firm...',
              prefixIcon: Icon(Icons.search, color: AppThemePro.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppThemePro.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppThemePro.accentGold, width: 2),
              ),
              filled: true,
              fillColor: AppThemePro.backgroundPrimary,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: TextStyle(color: AppThemePro.textPrimary),
          ),
          const SizedBox(height: 16),

          // Filters and sorting row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Sort dropdown
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppThemePro.backgroundPrimary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppThemePro.borderPrimary),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: AppThemePro.textSecondary,
                      ),
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontSize: 14,
                      ),
                      dropdownColor: AppThemePro.backgroundPrimary,
                      items: _getSortOptions(),
                      onChanged: (value) =>
                          value != null ? _updateSort(value) : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Sort direction button
                IconButton(
                  onPressed: () => _updateSort(_sortBy),
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: AppThemePro.accentGold,
                  ),
                  tooltip: _sortAscending ? 'Rosnąco' : 'Malejąco',
                  style: IconButton.styleFrom(
                    backgroundColor: AppThemePro.accentGold.withOpacity(0.1),
                    foregroundColor: AppThemePro.accentGold,
                  ),
                ),
                const SizedBox(width: 16),

                // Type filter
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppThemePro.backgroundPrimary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppThemePro.borderPrimary),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<UnifiedProductType?>(
                      value: _filterByType,
                      hint: Text(
                        'Typ produktu',
                        style: TextStyle(
                          color: AppThemePro.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      icon: Icon(
                        Icons.filter_list,
                        color: AppThemePro.textSecondary,
                      ),
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontSize: 14,
                      ),
                      dropdownColor: AppThemePro.backgroundPrimary,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Wszystkie typy'),
                        ),
                        ...UnifiedProductType.values.map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.displayName),
                          ),
                        ),
                      ],
                      onChanged: _updateTypeFilter,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Status filter
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppThemePro.backgroundPrimary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppThemePro.borderPrimary),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<dynamic>(
                      value: _filterByStatus ?? _filterByProductStatus,
                      hint: Text(
                        'Status',
                        style: TextStyle(
                          color: AppThemePro.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      icon: Icon(
                        Icons.filter_list,
                        color: AppThemePro.textSecondary,
                      ),
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontSize: 14,
                      ),
                      dropdownColor: AppThemePro.backgroundPrimary,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Wszystkie statusy'),
                        ),
                        if (_showDeduplicatedView)
                          ...ProductStatus.values.map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.displayName),
                            ),
                          )
                        else
                          ...InvestmentStatus.values.map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.displayName),
                            ),
                          ),
                      ],
                      onChanged: _updateStatusFilter,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Clear filters button
                if (_searchQuery.isNotEmpty ||
                    _filterByType != null ||
                    _filterByStatus != null ||
                    _filterByProductStatus != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _filterByType = null;
                        _filterByStatus = null;
                        _filterByProductStatus = null;
                        _applyFilteringAndSorting();
                      });
                    },
                    icon: Icon(Icons.clear, size: 16),
                    label: Text('Wyczyść filtry'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppThemePro.statusWarning,
                      textStyle: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _getSortOptions() {
    if (_showDeduplicatedView) {
      return [
        DropdownMenuItem(value: 'name', child: Text('Nazwa')),
        DropdownMenuItem(value: 'company', child: Text('Firma')),
        DropdownMenuItem(value: 'amount', child: Text('Kapitał')),
        DropdownMenuItem(
          value: 'investments',
          child: Text('Liczba inwestycji'),
        ),
        DropdownMenuItem(value: 'type', child: Text('Typ')),
        DropdownMenuItem(value: 'status', child: Text('Status')),
      ];
    } else {
      return [
        DropdownMenuItem(value: 'name', child: Text('Nazwa')),
        DropdownMenuItem(value: 'client', child: Text('Klient')),
        DropdownMenuItem(value: 'amount', child: Text('Kapitał')),
        DropdownMenuItem(value: 'date', child: Text('Data')),
        DropdownMenuItem(value: 'type', child: Text('Typ')),
        DropdownMenuItem(value: 'status', child: Text('Status')),
      ];
    }
  }

  Widget _buildDeduplicatedProductsList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _filteredDeduplicatedProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredDeduplicatedProducts[index];
        final isSelected = _selectedProductIds.contains(product.id);

        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppThemePro.borderPrimary, width: 0.5),
            ),
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedProductIds.add(product.id);
                } else {
                  _selectedProductIds.remove(product.id);
                }
              });
            },
            title: Text(
              product.name,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${product.companyName} • ${product.productType.displayName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.textSecondary,
                  ),
                ),
                Text(
                  '${product.totalInvestments} inwestycji • ${_currencyFormat.format(product.totalRemainingCapital)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.accentGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getUnifiedProductTypeColor(
                  product.productType,
                ).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getProductTypeIcon(product.productType),
                color: _getUnifiedProductTypeColor(product.productType),
                size: 20,
              ),
            ),
            activeColor: AppThemePro.accentGold,
            checkColor: AppThemePro.backgroundPrimary,
          ),
        );
      },
    );
  }

  Widget _buildInvestmentsList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _filteredInvestments.length,
      itemBuilder: (context, index) {
        final investment = _filteredInvestments[index];
        final isSelected = _selectedProductIds.contains(investment.id);

        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppThemePro.borderPrimary, width: 0.5),
            ),
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedProductIds.add(investment.id);
                  _selectedInvestment = investment;
                } else {
                  _selectedProductIds.remove(investment.id);
                }
              });
            },
            title: Text(
              investment.productName.isNotEmpty
                  ? investment.productName
                  : 'Produkt ${investment.id.substring(0, 8)}...',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${investment.clientName} • ${investment.productType.displayName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.textSecondary,
                  ),
                ),
                Text(
                  _currencyFormat.format(investment.remainingCapital),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.accentGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getStatusColor(investment.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getStatusIcon(investment.status),
                color: _getStatusColor(investment.status),
                size: 20,
              ),
            ),
            activeColor: AppThemePro.accentGold,
            checkColor: AppThemePro.backgroundPrimary,
          ),
        );
      },
    );
  }

  Widget _buildSelectedProductsSummary() {
    // Wybierz odpowiednią listę i oblicz wybrane produkty
    List<dynamic> selectedItems;
    if (_showDeduplicatedView) {
      selectedItems = _deduplicatedProducts
          .where((prod) => _selectedProductIds.contains(prod.id))
          .toList();
    } else {
      selectedItems = _investments
          .where((inv) => _selectedProductIds.contains(inv.id))
          .toList();
    }

    if (selectedItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: AppThemePro.premiumCardDecoration,
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.check_box_outline_blank,
                color: AppThemePro.textMuted,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Nie wybrano żadnych produktów',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppThemePro.textMuted),
              ),
              const SizedBox(height: 8),
              Text(
                'Zaznacz produkty powyżej aby zobaczyć szczegóły',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppThemePro.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 🚀 ULEPSZONY: Oblicz statystyki wybranych produktów używając zunifikowanego podejścia
    double totalInvestmentAmount = 0;
    double totalRemainingCapital = 0;
    double totalCapitalSecured = 0;
    double totalCapitalForRestructuring = 0;
    int activeItems = 0;

    if (_showDeduplicatedView) {
      // Oblicz dla deduplikowanych produktów
      for (final product in selectedItems.cast<OptimizedProduct>()) {
        totalInvestmentAmount += product.totalValue;
        totalRemainingCapital += product.totalRemainingCapital;

        // 🚀 POPRAWIONE: Kapitał zabezpieczony = suma capitalSecuredByRealEstate z inwestycji
        // Szukamy powiązanych inwestycji dla tego produktu
        final relatedInvestments = _investments
            .where(
              (inv) =>
                  inv.productName == product.name &&
                  inv.creditorCompany == product.companyName,
            )
            .toList();

        double productCapitalForRestructuring = 0;
        double productCapitalSecured = 0;
        for (final inv in relatedInvestments) {
          productCapitalForRestructuring += _getCapitalForRestructuring(inv);
          // 🚀 FIX: Oblicz kapitał zabezpieczony po stronie frontendu
          // Backend zwraca zawsze 0, więc obliczamy: remainingCapital - capitalForRestructuring
          final calculatedSecured = (inv.remainingCapital - _getCapitalForRestructuring(inv)).clamp(0.0, double.infinity);
          productCapitalSecured += calculatedSecured;
        }

        totalCapitalForRestructuring += productCapitalForRestructuring;
        totalCapitalSecured += productCapitalSecured;

        if (product.status == ProductStatus.active) {
          activeItems++;
        }
      }
    } else {
      // 🚀 POPRAWIONE: Kapitał zabezpieczony = suma capitalSecuredByRealEstate z inwestycji
      for (final investment in selectedItems.cast<Investment>()) {
        totalInvestmentAmount += investment.investmentAmount;
        totalRemainingCapital += investment.remainingCapital;

        final investmentCapitalForRestructuring = _getCapitalForRestructuring(
          investment,
        );
        totalCapitalForRestructuring += investmentCapitalForRestructuring;

        // 🚀 FIX: Oblicz kapitał zabezpieczony po stronie frontendu
        // Backend zwraca zawsze 0, więc obliczamy: remainingCapital - capitalForRestructuring
        final calculatedSecured = (investment.remainingCapital - investmentCapitalForRestructuring).clamp(0.0, double.infinity);
        totalCapitalSecured += calculatedSecured;
        
        // 🔍 DEBUG: Log dla wybranych inwestycji
        if (investment.remainingCapital > 0) {
          print('🔍 [Selected] ${investment.id}: remaining=${investment.remainingCapital}, restructuring=${investmentCapitalForRestructuring}, secured=${calculatedSecured}');
        }

        if (investment.status == InvestmentStatus.active) {
          activeItems++;
        }
      }
    }

    final tiles = [
      _SummaryTileData(
        title: 'Kwota wybranych inwestycji',
        value: _currencyFormat.format(totalInvestmentAmount),
        icon: Icons.account_balance_wallet,
        color: AppThemePro.accentGold,
        trend: null,
      ),
      _SummaryTileData(
        title: 'Pozostały kapitał wybranych',
        value: _currencyFormat.format(totalRemainingCapital),
        icon: Icons.trending_up,
        color: AppThemePro.profitGreen,
        trend: totalRemainingCapital > 0 ? 'positive' : 'negative',
      ),
      _SummaryTileData(
        title: 'Zabezpieczony kapitał',
        value: _currencyFormat.format(totalCapitalSecured),
        icon: Icons.security,
        color: AppThemePro.bondsBlue,
        trend: null,
      ),
      _SummaryTileData(
        title: 'W restrukturyzacji',
        value: _currencyFormat.format(totalCapitalForRestructuring),
        icon: Icons.refresh,
        color: AppThemePro.loansOrange,
        trend: totalCapitalForRestructuring > 0 ? 'warning' : null,
      ),
      _SummaryTileData(
        title: 'Aktywne produkty',
        value: '$activeItems/${selectedItems.length}',
        icon: Icons.check_circle,
        color: AppThemePro.statusSuccess,
        trend: null,
      ),
    ];

    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Podsumowanie wybranych produktów',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppThemePro.profitGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppThemePro.profitGreen.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${selectedItems.length} WYBRANYCH',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppThemePro.profitGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 1200;
              final crossAxisCount = isWide
                  ? 5
                  : (constraints.maxWidth > 800 ? 3 : 2);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: tiles.length,
                itemBuilder: (context, index) =>
                    _buildSummaryTile(tiles[index], index),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedProductsDetails() {
    // 🚀 POPRAWKA: Używaj odpowiedniej listy w zależności od trybu wyświetlania
    if (_showDeduplicatedView) {
      // Tryb zoptymalizowany - używamy OptimizedProduct
      final selectedProducts = _optimizedProducts
          .where((prod) => _selectedProductIds.contains(prod.id))
          .toList();

      if (selectedProducts.isEmpty) {
        return _buildNoSelectedProductsMessage();
      }

      return FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Szczegóły wybranych produktów',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppThemePro.statusInfo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppThemePro.statusInfo.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${selectedProducts.length} PRODUKTÓW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppThemePro.statusInfo,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pokaż listę wybranych zoptymalizowanych produktów
            _buildOptimizedProductsList(selectedProducts),
          ],
        ),
      );
    } else {
      // Tryb tradycyjny - używamy Investment (ale lista jest pusta)
      final selectedInvestments = _investments
          .where((inv) => _selectedProductIds.contains(inv.id))
          .toList();

      if (selectedInvestments.isEmpty) {
        return _buildNoSelectedProductsMessage();
      }

      return FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Szczegóły wybranych produktów',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppThemePro.statusInfo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppThemePro.statusInfo.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${selectedInvestments.length} PRODUKTÓW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppThemePro.statusInfo,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Jeśli wybrano tylko jeden produkt, pokaż szczegóły jak wcześniej
            if (selectedInvestments.length == 1) ...[
              _buildSingleProductDetails(selectedInvestments.first),
            ] else ...[
              // Jeśli wybrano wiele produktów, pokaż listę
              _buildMultipleProductsList(selectedInvestments),
            ],
          ],
        ),
      );
    }
  }

  Widget _buildSingleProductDetails(Investment investment) {
    return Container(
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        children: [
          _buildDetailRow('Nazwa produktu', investment.productName),
          _buildDetailRow('Typ', investment.productType.displayName),
          _buildDetailRow('Status', investment.status.displayName),
          _buildDetailRow('Emitent / Spółka', investment.creditorCompany),
          _buildDetailRow('Oddział sprzedaży', investment.branchCode),
          _buildDetailRow('Doradca', investment.employeeFullName),
          _buildDetailRow('Klient', investment.clientName),
          _buildDetailRow(
            'Kwota inwestycji',
            _currencyFormat.format(investment.investmentAmount),
          ),
          _buildDetailRow(
            'Pozostały kapitał',
            _currencyFormat.format(investment.remainingCapital),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleProductsList(List<Investment> selectedInvestments) {
    return Container(
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        children: [
          // Header tabeli
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppThemePro.accentGold.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Nazwa produktu',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Klient',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Typ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Pozostały kapitał',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Status',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Lista produktów
          ...selectedInvestments.asMap().entries.map((entry) {
            final index = entry.key;
            final investment = entry.value;
            final isLast = index == selectedInvestments.length - 1;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: AppThemePro.borderPrimary,
                          width: 0.5,
                        ),
                      ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      investment.productName.isNotEmpty
                          ? investment.productName
                          : 'Produkt ${investment.id.substring(0, 8)}...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppThemePro.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      investment.clientName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppThemePro.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getProductTypeColor(
                          investment.productType,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        investment.productType.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getProductTypeColor(investment.productType),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _currencyFormat.format(investment.remainingCapital),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppThemePro.accentGold,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          investment.status,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getStatusIcon(investment.status),
                        color: _getStatusColor(investment.status),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    if (_selectedInvestment == null) return const SizedBox.shrink();

    final investment = _selectedInvestment!;
    final now = DateTime.now();

    // 🚀 NOWE: Licznik terminów wymagających uwagi
    final dates = [
      investment.signedDate,
      investment.issueDate,
      investment.entryDate,
      investment.redemptionDate,
      DateTime.tryParse(investment.additionalInfo['repaymentDate'] ?? ''),
    ];

    final warningCount = dates
        .where((date) => _shouldShowWarningForDate(date, 'termin'))
        .length;

    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Terminy i oś czasu',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // 🎨 NOWE: Badge z liczbą terminów wymagających uwagi
              if (warningCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppThemePro.statusWarning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppThemePro.statusWarning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppThemePro.statusWarning,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$warningCount ${warningCount == 1
                            ? 'termin'
                            : warningCount <= 4
                            ? 'terminy'
                            : 'terminów'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppThemePro.statusWarning,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: AppThemePro.premiumCardDecoration,
            child: Column(
              children: [
                _buildTimelineItem(
                  'Data podpisania',
                  investment.signedDate,
                  Icons.edit,
                  AppThemePro.accentGold,
                  showWarning: _shouldShowWarningForDate(
                    investment.signedDate,
                    'Data podpisania',
                  ),
                ),
                _buildTimelineItem(
                  'Data emisji',
                  investment.issueDate,
                  Icons.launch,
                  AppThemePro.bondsBlue,
                  showWarning: _shouldShowWarningForDate(
                    investment.issueDate,
                    'Data emisji',
                  ),
                ),
                _buildTimelineItem(
                  'Data wprowadzenia',
                  investment.entryDate,
                  Icons.input,
                  AppThemePro.sharesGreen,
                  showWarning: _shouldShowWarningForDate(
                    investment.entryDate,
                    'Data wprowadzenia',
                  ),
                ),
                _buildTimelineItem(
                  'Data wykupu',
                  investment.redemptionDate,
                  Icons.event_available,
                  _getTimelineColor(investment.redemptionDate, now),
                  showWarning: _shouldShowWarningForDate(
                    investment.redemptionDate,
                    'Data wykupu',
                  ),
                ),
                if (investment.additionalInfo['repaymentDate'] != null)
                  _buildTimelineItem(
                    'Data faktycznej spłaty',
                    DateTime.tryParse(
                      investment.additionalInfo['repaymentDate'],
                    ),
                    Icons.payment,
                    AppThemePro.profitGreen,
                    showWarning: _shouldShowWarningForDate(
                      DateTime.tryParse(
                        investment.additionalInfo['repaymentDate'],
                      ),
                      'Data faktycznej spłaty',
                    ),
                  ),
                // 📊 NOWE: Podsumowanie timeline
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppThemePro.backgroundSecondary,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppThemePro.textMuted,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          warningCount > 0
                              ? 'Uwaga: $warningCount ${warningCount == 1 ? 'termin wymaga' : 'terminów wymaga'} uwagi'
                              : 'Wszystkie terminy pod kontrolą',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: warningCount > 0
                                    ? AppThemePro.statusWarning
                                    : AppThemePro.textMuted,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                        ),
                      ),
                      if (investment.redemptionDate != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          investment.redemptionDate!.isAfter(DateTime.now())
                              ? 'Status: Aktywna'
                              : 'Status: Zakończona',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color:
                                    investment.redemptionDate!.isAfter(
                                      DateTime.now(),
                                    )
                                    ? AppThemePro.profitGreen
                                    : AppThemePro.textMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String label,
    DateTime? date,
    IconData icon,
    Color color, {
    bool showWarning = false,
  }) {
    if (date == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppThemePro.borderPrimary, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppThemePro.textMuted.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppThemePro.textMuted, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppThemePro.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '—',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemePro.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // 🚀 NOWE: Oblicz dynamiczne informacje o terminie
    final now = DateTime.now();
    final daysDiff = date.difference(now).inDays;
    final isPast = daysDiff < 0;
    final isToday = daysDiff == 0;
    final isNearDue = daysDiff > 0 && daysDiff <= 30;

    // Przygotuj dodatkowy tekst statusu
    String statusText = '';
    Color statusColor = color;

    if (isToday) {
      statusText = ' • DZISIAJ';
      statusColor = AppThemePro.statusWarning;
      showWarning = true;
    } else if (isPast) {
      statusText = ' • ${daysDiff.abs()} dni temu';
      statusColor = AppThemePro.textMuted;
    } else if (isNearDue) {
      statusText = ' • Za $daysDiff dni';
      statusColor = AppThemePro.statusWarning;
      showWarning = true;
    } else if (daysDiff > 30) {
      statusText = ' • Za $daysDiff dni';
      statusColor = AppThemePro.statusSuccess;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppThemePro.borderPrimary, width: 0.5),
        ),
        // 🎨 NOWE: Subtelne podświetlenie dla terminów wymagających uwagi
        color: showWarning ? statusColor.withOpacity(0.05) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              // 🎨 NOWE: Border dla ważnych terminów
              border: showWarning
                  ? Border.all(color: statusColor.withOpacity(0.3), width: 1)
                  : null,
            ),
            child: Icon(
              showWarning && (isToday || isNearDue)
                  ? Icons.warning_amber_rounded
                  : icon,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemePro.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (statusText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    statusText.substring(3), // Usuń " • " z początku
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _dateFormat.format(date),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showWarning && (isToday || isNearDue)) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    isToday ? 'DZIŚ' : 'PILNE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.warning_rounded,
                  color: AppThemePro.statusWarning,
                  size: 16,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 🚀 NOWE: Pomocnicza metoda do automatycznego wykrywania ostrzeżeń
  bool _shouldShowWarningForDate(DateTime? date, String label) {
    if (date == null) return false;

    final now = DateTime.now();
    final daysDiff = date.difference(now).inDays;

    // Terminy wykupu - ostrzeżenie 60 dni wcześniej
    if (label.toLowerCase().contains('wykup') &&
        daysDiff > 0 &&
        daysDiff <= 60) {
      return true;
    }

    // Wprowadzenie na rynek - ostrzeżenie 30 dni wcześniej
    if (label.toLowerCase().contains('wprowadzenie') &&
        daysDiff > 0 &&
        daysDiff <= 30) {
      return true;
    }

    // Wszystkie terminy dzisiejsze
    if (daysDiff == 0) {
      return true;
    }

    // Terminy przeterminowane (do 7 dni wstecz)
    if (daysDiff < 0 && daysDiff >= -7) {
      return true;
    }

    return false;
  }

  Widget _buildFinancialRisksSection() {
    if (_selectedInvestment == null) return const SizedBox.shrink();

    final investment = _selectedInvestment!;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sekcja ryzyk i statusów finansowych',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: AppThemePro.premiumCardDecoration,
            child: Column(
              children: [
                _buildRiskRow(
                  'Zrealizowany kapitał',
                  investment.realizedCapital,
                  _getRiskStatus(investment.realizedCapital),
                ),
                _buildRiskRow(
                  'Zrealizowane odsetki',
                  investment.realizedInterest,
                  _getRiskStatus(investment.realizedInterest),
                ),
                _buildRiskRow(
                  'Zrealizowany podatek',
                  investment.realizedTax,
                  investment.realizedTax > 0 ? 'positive' : 'warning',
                ),
                _buildRiskRow(
                  'Przeniesione do innego produktu',
                  investment.transferToOtherProduct,
                  investment.transferToOtherProduct > 0 ? 'neutral' : 'neutral',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskRow(String label, double value, String status) {
    final statusData = _getRiskStatusData(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppThemePro.borderPrimary, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemePro.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _currencyFormat.format(value),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusData.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusData.color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusData.icon, color: statusData.color, size: 16),
                const SizedBox(width: 6),
                Text(
                  statusData.text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusData.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(_SummaryTileData data, int index) {
    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 100)),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  data.color.withOpacity(0.1),
                  data.color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: data.color.withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: data.color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // Add haptic feedback
                  // HapticFeedback.lightImpact();
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: data.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(data.icon, color: data.color, size: 24),
                          ),
                          if (data.trend != null) ...[
                            const Spacer(),
                            Icon(
                              data.trend == 'positive'
                                  ? Icons.trending_up
                                  : data.trend == 'negative'
                                  ? Icons.trending_down
                                  : Icons.warning,
                              color: data.trend == 'positive'
                                  ? AppThemePro.profitGreen
                                  : data.trend == 'negative'
                                  ? AppThemePro.lossRed
                                  : AppThemePro.loansOrange,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      const Spacer(),
                      Text(
                        data.value,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppThemePro.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppThemePro.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppThemePro.borderPrimary, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemePro.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : '—',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppThemePro.textPrimary),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  double _getCapitalForRestructuring(Investment investment) {
    return investment.capitalForRestructuring;
  }

  IconData _getStatusIcon(InvestmentStatus status) {
    switch (status) {
      case InvestmentStatus.active:
        return Icons.check_circle;
      case InvestmentStatus.inactive:
        return Icons.pause_circle;
      case InvestmentStatus.earlyRedemption:
        return Icons.fast_forward;
      case InvestmentStatus.completed:
        return Icons.task_alt;
    }
  }

  Color _getStatusColor(InvestmentStatus status) {
    switch (status) {
      case InvestmentStatus.active:
        return AppThemePro.statusSuccess;
      case InvestmentStatus.inactive:
        return AppThemePro.statusWarning;
      case InvestmentStatus.earlyRedemption:
        return AppThemePro.statusInfo;
      case InvestmentStatus.completed:
        return AppThemePro.profitGreen;
    }
  }

  Color _getProductTypeColor(ProductType productType) {
    switch (productType) {
      case ProductType.bonds:
        return AppThemePro.bondsBlue;
      case ProductType.shares:
        return AppThemePro.sharesGreen;
      case ProductType.loans:
        return AppThemePro.loansOrange;
      case ProductType.apartments:
        return AppThemePro.lossRed;
    }
  }

  Color _getUnifiedProductTypeColor(UnifiedProductType productType) {
    switch (productType) {
      case UnifiedProductType.bonds:
        return AppThemePro.bondsBlue;
      case UnifiedProductType.shares:
        return AppThemePro.sharesGreen;
      case UnifiedProductType.loans:
        return AppThemePro.loansOrange;
      case UnifiedProductType.apartments:
        return AppThemePro.lossRed;
      case UnifiedProductType.other:
        return AppThemePro.textSecondary;
    }
  }

  IconData _getProductTypeIcon(UnifiedProductType productType) {
    switch (productType) {
      case UnifiedProductType.bonds:
        return Icons.account_balance;
      case UnifiedProductType.shares:
        return Icons.trending_up;
      case UnifiedProductType.loans:
        return Icons.handshake;
      case UnifiedProductType.apartments:
        return Icons.home;
      case UnifiedProductType.other:
        return Icons.category;
    }
  }

  Color _getTimelineColor(DateTime? date, DateTime now) {
    if (date == null) return AppThemePro.textMuted;

    final daysUntil = date.difference(now).inDays;

    if (daysUntil < 0) return AppThemePro.lossRed; // Past due
    if (daysUntil <= 30) return AppThemePro.statusWarning; // Warning
    return AppThemePro.profitGreen; // Good
  }

  String _getRiskStatus(double value) {
    if (value > 0) return 'positive';
    if (value < 0) return 'negative';
    return 'warning';
  }

  _RiskStatusData _getRiskStatusData(String status) {
    switch (status) {
      case 'positive':
        return _RiskStatusData(
          color: AppThemePro.statusSuccess,
          icon: Icons.check_circle,
          text: 'OK',
        );
      case 'negative':
        return _RiskStatusData(
          color: AppThemePro.lossRed,
          icon: Icons.cancel,
          text: 'Brak spłat',
        );
      case 'warning':
        return _RiskStatusData(
          color: AppThemePro.statusWarning,
          icon: Icons.warning,
          text: 'Niewyliczony',
        );
      default:
        return _RiskStatusData(
          color: AppThemePro.neutralGray,
          icon: Icons.remove,
          text: '—',
        );
    }
  }

  /// 🚀 POPRAWIONE: Konwertuje GlobalProductStatistics na UnifiedDashboardStatistics
  /// Używa rzeczywistego kapitału zabezpieczonego zamiast szacunkowego
  UnifiedDashboardStatistics _convertGlobalStatsToUnified(
    GlobalProductStatistics globalStats,
  ) {
    // 🚀 FIX: Użyj tej samej szacunkowej metody co w analityce
    // Szacuj kapitał do restrukturyzacji jako 5% całkowitej wartości (benchmark)
    final estimatedCapitalForRestructuring = globalStats.totalValue * 0.05;

    // Szacuj kapitał zabezpieczony jako pozostały kapitał minus do restrukturyzacji
    final estimatedCapitalSecured =
        (globalStats.totalRemainingCapital - estimatedCapitalForRestructuring)
            .clamp(0.0, double.infinity);

    print('  • Total Remaining Capital: ${globalStats.totalRemainingCapital}');
    print(
      '  • Estimated Capital for Restructuring (5%): $estimatedCapitalForRestructuring',
    );

    return UnifiedDashboardStatistics(
      totalInvestmentAmount: globalStats.totalValue,
      totalRemainingCapital: globalStats.totalRemainingCapital,
      totalCapitalSecured: estimatedCapitalSecured,
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
      dataSource: 'OptimizedProductService (estimated method)',
      calculatedAt: DateTime.now(),
    );
  }

  // 🚀 NOWE: Widget dla komunikatu o braku wybranych produktów
  Widget _buildNoSelectedProductsMessage() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppThemePro.premiumCardDecoration,
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.check_box_outline_blank,
              color: AppThemePro.textMuted,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Nie wybrano żadnych produktów',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppThemePro.textMuted),
            ),
            const SizedBox(height: 8),
            Text(
              'Zaznacz produkty powyżej aby zobaczyć szczegóły',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppThemePro.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  // 🚀 NOWE: Lista szczegółów dla zoptymalizowanych produktów
  Widget _buildOptimizedProductsList(List<OptimizedProduct> selectedProducts) {
    return Container(
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        children: [
          // Header tabeli
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppThemePro.accentGold.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Nazwa produktu',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Firma',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Inwestycje',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Typ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Pozostały kapitał',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Status',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Lista produktów
          ...selectedProducts.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            final isLast = index == selectedProducts.length - 1;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: AppThemePro.borderPrimary,
                          width: 0.5,
                        ),
                      ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      product.name.isNotEmpty
                          ? product.name
                          : 'Produkt ${product.id.substring(0, 8)}...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppThemePro.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      product.companyName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppThemePro.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${product.totalInvestments}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppThemePro.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getUnifiedProductTypeColor(
                          product.productType,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.productType.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getUnifiedProductTypeColor(
                            product.productType,
                          ),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _currencyFormat.format(product.totalRemainingCapital),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppThemePro.accentGold,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getProductStatusColor(
                          product.status,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getProductStatusIcon(product.status),
                        color: _getProductStatusColor(product.status),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 🚀 NOWE: Metody pomocnicze dla statusów produktów
  Color _getProductStatusColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.active:
        return AppThemePro.statusSuccess;
      case ProductStatus.inactive:
        return AppThemePro.statusWarning;
      case ProductStatus.pending:
        return AppThemePro.statusInfo;
      case ProductStatus.suspended:
        return AppThemePro.lossRed;
    }
  }

  IconData _getProductStatusIcon(ProductStatus status) {
    switch (status) {
      case ProductStatus.active:
        return Icons.check_circle;
      case ProductStatus.inactive:
        return Icons.pause_circle;
      case ProductStatus.pending:
        return Icons.pending;
      case ProductStatus.suspended:
        return Icons.cancel;
    }
  }
}

// Helper classes
class _SummaryTileData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;

  _SummaryTileData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
  });
}

class _RiskStatusData {
  final Color color;
  final IconData icon;
  final String text;

  _RiskStatusData({
    required this.color,
    required this.icon,
    required this.text,
  });
}
