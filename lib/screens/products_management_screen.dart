import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/unified_product.dart';
import '../models/investor_summary.dart';
import '../services/unified_product_service.dart';
import '../services/product_investors_service.dart';
import '../widgets/premium_loading_widget.dart';
import '../widgets/premium_error_widget.dart';
import '../widgets/product_card_widget.dart';
import '../widgets/product_stats_widget.dart';
import '../widgets/product_filter_widget.dart';

/// Ekran zarządzania produktami z wszystkich kolekcji Firebase
/// Wykorzystuje UnifiedProductService do pobierania danych z bonds, shares, loans, apartments
class ProductsManagementScreen extends StatefulWidget {
  const ProductsManagementScreen({super.key});

  @override
  State<ProductsManagementScreen> createState() =>
      _ProductsManagementScreenState();
}

class _ProductsManagementScreenState extends State<ProductsManagementScreen>
    with TickerProviderStateMixin {
  late final UnifiedProductService _productService;
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // Stan ekranu
  List<UnifiedProduct> _allProducts = [];
  List<UnifiedProduct> _filteredProducts = [];
  ProductStatistics? _statistics;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  // Kontrolery wyszukiwania i filtrowania
  final TextEditingController _searchController = TextEditingController();
  ProductFilterCriteria _filterCriteria = const ProductFilterCriteria();
  ProductSortField _sortField = ProductSortField.createdAt;
  SortDirection _sortDirection = SortDirection.descending;

  // Kontrola wyświetlania
  bool _showFilters = false;
  bool _showStatistics = true;
  ViewMode _viewMode = ViewMode.grid;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _initializeAnimations();
    _loadInitialData();
    _setupSearchListener();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleRouteParameters();
  }

  void _handleRouteParameters() {
    final state = GoRouterState.of(context);
    final productName = state.uri.queryParameters['productName'];
    final productType = state.uri.queryParameters['productType'];
    
    if (productName != null && productName.isNotEmpty) {
      _searchController.text = productName;
      _applyFiltersAndSearch();
    }
    
    if (productType != null && productType.isNotEmpty) {
      // Add product type filter if available
      // This would require extending the filter criteria
    }
  }

  void _initializeService() {
    _productService = UnifiedProductService();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      _applyFiltersAndSearch();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final results = await Future.wait([
        _productService.getAllProducts(),
        _productService.getProductStatistics(),
      ]);

      final products = results[0] as List<UnifiedProduct>;
      final statistics = results[1] as ProductStatistics;

      if (mounted) {
        setState(() {
          _allProducts = products;
          _statistics = statistics;
          _isLoading = false;
        });

        _applyFiltersAndSearch();
        _startAnimations();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Błąd podczas ładowania produktów: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _slideController.forward();
      }
    });
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    // Dodaj efekt wibracji dla lepszego UX
    HapticFeedback.mediumImpact();

    try {
      await _productService.refreshCache();
      await _loadInitialData();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _applyFiltersAndSearch() {
    List<UnifiedProduct> filtered = List.from(_allProducts);

    // Zastosuj wyszukiwanie tekstowe
    final searchText = _searchController.text.trim();
    if (searchText.isNotEmpty) {
      final searchLower = searchText.toLowerCase();
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(searchLower) ||
            product.description.toLowerCase().contains(searchLower) ||
            product.productType.displayName.toLowerCase().contains(
              searchLower,
            ) ||
            (product.companyName?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }

    // Zastosuj filtry
    filtered = filtered.where(_filterCriteria.matches).toList();

    // Zastosuj sortowanie
    _sortProducts(filtered);

    setState(() {
      _filteredProducts = filtered;
    });
  }

  void _sortProducts(List<UnifiedProduct> products) {
    products.sort((a, b) {
      int comparison;

      switch (_sortField) {
        case ProductSortField.name:
          comparison = a.name.compareTo(b.name);
          break;
        case ProductSortField.type:
          comparison = a.productType.displayName.compareTo(
            b.productType.displayName,
          );
          break;
        case ProductSortField.investmentAmount:
          comparison = a.investmentAmount.compareTo(b.investmentAmount);
          break;
        case ProductSortField.totalValue:
          comparison = a.totalValue.compareTo(b.totalValue);
          break;
        case ProductSortField.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case ProductSortField.uploadedAt:
          comparison = a.uploadedAt.compareTo(b.uploadedAt);
          break;
        case ProductSortField.status:
          comparison = a.status.displayName.compareTo(b.status.displayName);
          break;
        case ProductSortField.companyName:
          comparison = (a.companyName ?? '').compareTo(b.companyName ?? '');
          break;
        case ProductSortField.interestRate:
          comparison = (a.interestRate ?? 0.0).compareTo(b.interestRate ?? 0.0);
          break;
      }

      return _sortDirection == SortDirection.ascending
          ? comparison
          : -comparison;
    });
  }

  void _onFilterChanged(ProductFilterCriteria criteria) {
    setState(() {
      _filterCriteria = criteria;
    });
    _applyFiltersAndSearch();
  }

  void _onSortChanged(ProductSortField field, SortDirection direction) {
    setState(() {
      _sortField = field;
      _sortDirection = direction;
    });
    _applyFiltersAndSearch();
  }

  void _toggleViewMode() {
    setState(() {
      _viewMode = _viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
    });
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          if (_showStatistics && _statistics != null) _buildStatisticsSection(),
          _buildSearchAndFilters(),
          if (_isLoading)
            SliverFillRemaining(
              child: PremiumLoadingWidget(message: 'Ładowanie produktów...'),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: PremiumErrorWidget(
                error: _error!,
                onRetry: _loadInitialData,
              ),
            )
          else
            _buildProductsList(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.backgroundPrimary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Zarządzanie Produktami',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppTheme.textOnPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      '${_filteredProducts.length} z ${_allProducts.length} produktów',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textOnPrimary.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _showStatistics ? Icons.analytics_outlined : Icons.analytics,
            color: AppTheme.secondaryGold,
          ),
          onPressed: () {
            setState(() {
              _showStatistics = !_showStatistics;
            });
            HapticFeedback.lightImpact();
          },
          tooltip: _showStatistics ? 'Ukryj statystyki' : 'Pokaż statystyki',
        ),
        IconButton(
          icon: Icon(
            _viewMode == ViewMode.grid ? Icons.view_list : Icons.grid_view,
            color: AppTheme.secondaryGold,
          ),
          onPressed: _toggleViewMode,
          tooltip: 'Zmień widok',
        ),
        IconButton(
          icon: Icon(
            _isRefreshing ? Icons.hourglass_empty : Icons.refresh,
            color: AppTheme.secondaryGold,
          ),
          onPressed: _isRefreshing ? null : _refreshData,
          tooltip: 'Odśwież dane',
        ),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ProductStatsWidget(
              statistics: _statistics!,
              animationController: _fadeController,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              // Pasek wyszukiwania
              Container(
                decoration: AppTheme.premiumCardDecoration,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Wyszukaj produkty...',
                    hintStyle: TextStyle(color: AppTheme.textTertiary),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.secondaryGold,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppTheme.textTertiary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : IconButton(
                            icon: Icon(
                              _showFilters
                                  ? Icons.filter_list
                                  : Icons.filter_list_outlined,
                              color: AppTheme.secondaryGold,
                            ),
                            onPressed: () {
                              setState(() {
                                _showFilters = !_showFilters;
                              });
                              HapticFeedback.lightImpact();
                            },
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),

              // Panel filtrów
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _showFilters ? null : 0,
                child: _showFilters
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ProductFilterWidget(
                          initialCriteria: _filterCriteria,
                          initialSortField: _sortField,
                          initialSortDirection: _sortDirection,
                          onFilterChanged: _onFilterChanged,
                          onSortChanged: _onSortChanged,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    if (_filteredProducts.isEmpty) {
      return SliverFillRemaining(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _buildEmptyState(),
        ),
      );
    }

    if (_viewMode == ViewMode.grid) {
      return _buildGridView();
    } else {
      return _buildListView();
    }
  }

  Widget _buildGridView() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ProductCardWidget(
                product: _filteredProducts[index],
                viewMode: _viewMode,
                onTap: () => _showProductDetails(_filteredProducts[index]),
              ),
            ),
          );
        }, childCount: _filteredProducts.length),
      ),
    );
  }

  Widget _buildListView() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ProductCardWidget(
                  product: _filteredProducts[index],
                  viewMode: _viewMode,
                  onTap: () => _showProductDetails(_filteredProducts[index]),
                ),
              ),
            ),
          );
        }, childCount: _filteredProducts.length),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchController.text.isNotEmpty;
    final hasFilters =
        _filterCriteria.productTypes != null ||
        _filterCriteria.statuses != null ||
        _filterCriteria.minInvestmentAmount != null ||
        _filterCriteria.maxInvestmentAmount != null;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 60,
                color: AppTheme.secondaryGold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasSearch || hasFilters
                  ? 'Brak produktów spełniających kryteria'
                  : 'Brak produktów w systemie',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              hasSearch || hasFilters
                  ? 'Spróbuj zmienić filtry lub wyszukiwaną frazę'
                  : 'Dodaj pierwszy produkt do systemu',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (hasSearch || hasFilters) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _filterCriteria = const ProductFilterCriteria();
                    _showFilters = false;
                  });
                  _applyFiltersAndSearch();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Wyczyść filtry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryGold,
                  foregroundColor: AppTheme.textOnSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showAddProductDialog,
      backgroundColor: AppTheme.secondaryGold,
      foregroundColor: AppTheme.textOnSecondary,
      icon: const Icon(Icons.add),
      label: const Text('Dodaj Produkt'),
      elevation: 8,
    );
  }

  void _showProductDetails(UnifiedProduct product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => EnhancedProductDetailsBottomSheet(product: product),
    );
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        onProductAdded: () {
          _refreshData();
        },
      ),
    );
  }
}

enum ViewMode { grid, list }

/// Enhanced widget do wyświetlania szczegółów produktu z listą inwestorów
class EnhancedProductDetailsBottomSheet extends StatefulWidget {
  final UnifiedProduct product;

  const EnhancedProductDetailsBottomSheet({super.key, required this.product});

  @override
  State<EnhancedProductDetailsBottomSheet> createState() =>
      _EnhancedProductDetailsBottomSheetState();
}

class _EnhancedProductDetailsBottomSheetState
    extends State<EnhancedProductDetailsBottomSheet>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ProductInvestorsService _investorsService = ProductInvestorsService();

  List<InvestorSummary> _investors = [];
  bool _isLoadingInvestors = true;
  String? _investorsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInvestors();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInvestors() async {
    try {
      setState(() {
        _isLoadingInvestors = true;
        _investorsError = null;
      });

      final investors = await _investorsService.getInvestorsByProductName(
        widget.product.name,
      );

      if (mounted) {
        setState(() {
          _investors = investors;
          _isLoadingInvestors = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _investorsError = 'Błąd podczas ładowania inwestorów: $e';
          _isLoadingInvestors = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header z gradientem
          _buildGradientHeader(),

          // Tab Bar
          _buildTabBar(),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildInvestorsTab(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.getPerformanceCardDecoration(
          widget.product.totalValue - widget.product.investmentAmount,
        ).gradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Ikona produktu z animacją
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 800),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.getProductTypeColor(
                          widget.product.productType.collectionName,
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.getProductTypeColor(
                            widget.product.productType.collectionName,
                          ).withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.getProductTypeColor(
                              widget.product.productType.collectionName,
                            ).withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _getProductIcon(widget.product.productType),
                        color: AppTheme.getProductTypeColor(
                          widget.product.productType.collectionName,
                        ),
                        size: 28,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 16),

              // Informacje o produkcie
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.product.productType.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge
              _buildAnimatedStatusBadge(),

              const SizedBox(width: 8),

              // Close button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppTheme.textPrimary),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.backgroundPrimary.withOpacity(0.3),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Metryki finansowe
          _buildFinancialMetrics(),
        ],
      ),
    );
  }

  Widget _buildAnimatedStatusBadge() {
    final color = AppTheme.getStatusColor(widget.product.status.displayName);

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.5), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.product.status.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinancialMetrics() {
    final profitLoss =
        widget.product.totalValue - widget.product.investmentAmount;
    final profitLossPercentage = widget.product.investmentAmount > 0
        ? (profitLoss / widget.product.investmentAmount) * 100
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Inwestycja',
            value: _formatCurrency(widget.product.investmentAmount),
            subtitle: 'PLN',
            icon: Icons.input,
            color: AppTheme.infoPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Wartość',
            value: _formatCurrency(widget.product.totalValue),
            subtitle: 'PLN',
            icon: Icons.account_balance_wallet,
            color: AppTheme.secondaryGold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Zysk/Strata',
            value: _formatCurrency(profitLoss),
            subtitle: '${profitLossPercentage.toStringAsFixed(1)}%',
            icon: profitLoss >= 0 ? Icons.trending_up : Icons.trending_down,
            color: profitLoss >= 0
                ? AppTheme.gainPrimary
                : AppTheme.lossPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 1000),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundPrimary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 6),
                const Text('Szczegóły'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_outline, size: 18),
                const SizedBox(width: 6),
                Text('Inwestorzy (${_investors.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.analytics_outlined, size: 18),
                const SizedBox(width: 6),
                const Text('Analiza'),
              ],
            ),
          ),
        ],
        labelColor: AppTheme.secondaryGold,
        unselectedLabelColor: AppTheme.textTertiary,
        indicatorColor: AppTheme.secondaryGold,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  IconData _getProductIcon(UnifiedProductType type) {
    switch (type) {
      case UnifiedProductType.bonds:
        return Icons.account_balance;
      case UnifiedProductType.shares:
        return Icons.trending_up;
      case UnifiedProductType.loans:
        return Icons.attach_money;
      case UnifiedProductType.apartments:
        return Icons.apartment;
      case UnifiedProductType.other:
        return Icons.inventory;
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M zł';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K zł';
    } else {
      return '${amount.toStringAsFixed(2)} zł';
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Szczegółowe informacje
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Szczegóły Produktu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Typ', widget.product.productType.displayName),
                _buildDetailRow(
                  'Status',
                  widget.product.isActive ? 'Aktywny' : 'Nieaktywny',
                ),
                _buildDetailRow('Waluta', widget.product.currency ?? 'PLN'),
                if (widget.product.interestRate != null)
                  _buildDetailRow(
                    'Oprocentowanie',
                    '${widget.product.interestRate!}%',
                  ),
                if (widget.product.maturityDate != null)
                  _buildDetailRow(
                    'Data zapadalności',
                    widget.product.maturityDate!.toString().substring(0, 10),
                  ),
                if (widget.product.sharesCount != null)
                  _buildDetailRow(
                    'Liczba udziałów',
                    widget.product.sharesCount.toString(),
                  ),
                if (widget.product.pricePerShare != null)
                  _buildDetailRow(
                    'Cena za udział',
                    _formatCurrency(widget.product.pricePerShare!),
                  ),
                if (widget.product.companyName != null)
                  _buildDetailRow('Firma', widget.product.companyName!),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Opis produktu
          if (widget.product.description.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Opis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.product.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Dodatkowe informacje
          if (widget.product.additionalInfo.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dodatkowe Informacje',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...widget.product.additionalInfo.entries.map(
                    (entry) =>
                        _buildDetailRow(entry.key, entry.value.toString()),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvestorsTab() {
    if (_isLoadingInvestors) {
      return const Center(
        child: PremiumLoadingWidget(message: 'Ładowanie inwestorów...'),
      );
    }

    if (_investorsError != null) {
      return PremiumErrorWidget(
        error: _investorsError!,
        onRetry: _loadInvestors,
      );
    }

    if (_investors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Brak inwestorów',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ten produkt nie ma jeszcze żadnych inwestorów.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _investors.length,
      itemBuilder: (context, index) {
        final investor = _investors[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(Icons.person, color: AppTheme.primaryColor),
            ),
            title: Text(
              investor.client.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (investor.client.email.isNotEmpty)
                  Text(
                    investor.client.email,
                    style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.8),
                    ),
                  ),
                if (investor.client.phone.isNotEmpty)
                  Text(
                    investor.client.phone,
                    style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.8),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Inwestycje: ${investor.investmentCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryGold,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.secondaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatCurrency(investor.viableRemainingCapital),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryGold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statystyki inwestorów
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statystyki Inwestorów',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Liczba Inwestorów',
                        _investors.length.toString(),
                        Icons.people,
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Łączny Kapitał',
                        _formatCurrency(
                          _investors.fold(
                            0.0,
                            (sum, investor) =>
                                sum + investor.viableRemainingCapital,
                          ),
                        ),
                        Icons.attach_money,
                        AppTheme.secondaryGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Średnia Inwestycja',
                        _investors.isNotEmpty
                            ? _formatCurrency(
                                _investors.fold(
                                      0.0,
                                      (sum, investor) =>
                                          sum + investor.viableRemainingCapital,
                                    ) /
                                    _investors.length,
                              )
                            : '0 zł',
                        Icons.trending_up,
                        AppTheme.successPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Łączne Inwestycje',
                        _investors
                            .fold(
                              0,
                              (sum, investor) => sum + investor.investmentCount,
                            )
                            .toString(),
                        Icons.account_balance,
                        AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Ranking inwestorów
          if (_investors.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Inwestorzy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._investors.take(5).toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final investor = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundPrimary.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: index == 0
                              ? AppTheme.secondaryGold.withOpacity(0.3)
                              : AppTheme.primaryColor.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? AppTheme.secondaryGold
                                  : AppTheme.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: index == 0
                                      ? AppTheme.backgroundPrimary
                                      : AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  investor.client.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${investor.investmentCount} inwestycji',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary.withOpacity(
                                      0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatCurrency(investor.viableRemainingCapital),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: index == 0
                                  ? AppTheme.secondaryGold
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog do dodawania nowego produktu
class AddProductDialog extends StatefulWidget {
  final VoidCallback onProductAdded;

  const AddProductDialog({super.key, required this.onProductAdded});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.backgroundSecondary,
      title: const Text(
        'Dodaj Nowy Produkt',
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      content: const Text(
        'Funkcjonalność dodawania produktów będzie dostępna wkrótce.',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Zamknij',
            style: TextStyle(color: AppTheme.secondaryGold),
          ),
        ),
      ],
    );
  }
}
