import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../models/unified_product.dart';
import '../services/unified_product_service.dart';
import '../theme/app_theme.dart';
import '../widgets/unified_products/products_filter_panel.dart';
import '../widgets/unified_products/products_grid_view.dart';
import '../widgets/unified_products/products_list_view.dart';
import '../widgets/unified_products/product_details_modal.dart';
import '../widgets/unified_products/products_statistics_card.dart';

/// Główny ekran zarządzania zunifikowanymi produktami
class UnifiedProductsScreen extends StatefulWidget {
  const UnifiedProductsScreen({super.key});

  @override
  State<UnifiedProductsScreen> createState() => _UnifiedProductsScreenState();
}

class _UnifiedProductsScreenState extends State<UnifiedProductsScreen>
    with TickerProviderStateMixin {
  
  final UnifiedProductService _productService = UnifiedProductService();
  
  // Stan filtrowyania i sortowania
  ProductFilterCriteria _filterCriteria = const ProductFilterCriteria();
  ProductSortField _sortField = ProductSortField.name;
  SortDirection _sortDirection = SortDirection.ascending;
  
  // Stan UI
  bool _isLoading = false;
  bool _isGridView = true;
  bool _showFilters = false;
  String _searchText = '';
  
  // Dane
  List<UnifiedProduct> _products = [];
  List<UnifiedProduct> _filteredProducts = [];
  ProductStatistics? _statistics;
  
  // Kontrolery
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Paginacja
  static const int _itemsPerPage = 20;
  int _currentPage = 0;
  bool _hasMoreItems = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _applyTabFilter();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreItems();
    }
  }

  void _onSearchChanged() {
    final newSearchText = _searchController.text.trim();
    if (newSearchText != _searchText) {
      setState(() {
        _searchText = newSearchText;
      });
      _applyFilters();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _productService.getAllProducts(),
        _productService.getProductStatistics(),
      ]);

      setState(() {
        _products = results[0] as List<UnifiedProduct>;
        _statistics = results[1] as ProductStatistics;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Błąd podczas ładowania produktów: $e');
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || !_hasMoreItems) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Symulujemy paginację poprzez zwiększenie limitu wyników
      final newLimit = (_currentPage + 1) * _itemsPerPage;
      final moreProducts = await _productService.getFilteredProducts(
        _filterCriteria.copyWith(searchText: _searchText),
        sortField: _sortField,
        sortDirection: _sortDirection,
        limit: newLimit,
      );

      setState(() {
        _filteredProducts = moreProducts;
        _currentPage++;
        _hasMoreItems = moreProducts.length >= newLimit;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      _showErrorSnackBar('Błąd podczas ładowania kolejnych produktów: $e');
    }
  }

  void _applyTabFilter() {
    final tabIndex = _tabController.index;
    ProductFilterCriteria newCriteria;

    switch (tabIndex) {
      case 0: // Wszystkie
        newCriteria = _filterCriteria.copyWithoutTypes();
        break;
      case 1: // Obligacje
        newCriteria = _filterCriteria.copyWith(
          productTypes: [UnifiedProductType.bonds],
        );
        break;
      case 2: // Udziały
        newCriteria = _filterCriteria.copyWith(
          productTypes: [UnifiedProductType.shares],
        );
        break;
      case 3: // Pozostałe
        newCriteria = _filterCriteria.copyWith(
          productTypes: [
            UnifiedProductType.loans,
            UnifiedProductType.apartments,
            UnifiedProductType.other,
          ],
        );
        break;
      default:
        newCriteria = _filterCriteria;
    }

    setState(() {
      _filterCriteria = newCriteria;
      _currentPage = 0;
      _hasMoreItems = true;
    });
    
    _applyFilters();
  }

  void _applyFilters() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final filtered = await _productService.getFilteredProducts(
        _filterCriteria.copyWith(searchText: _searchText),
        sortField: _sortField,
        sortDirection: _sortDirection,
        limit: _itemsPerPage,
      );

      setState(() {
        _filteredProducts = filtered;
        _isLoading = false;
        _currentPage = 0;
        _hasMoreItems = filtered.length >= _itemsPerPage;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Błąd podczas filtrowania produktów: $e');
    }
  }

  void _onFilterChanged(ProductFilterCriteria newCriteria) {
    setState(() {
      _filterCriteria = newCriteria;
    });
    _applyFilters();
  }

  void _onSortChanged(ProductSortField field, SortDirection direction) {
    setState(() {
      _sortField = field;
      _sortDirection = direction;
    });
    _applyFilters();
  }

  void _onProductTap(UnifiedProduct product) {
    showDialog(
      context: context,
      builder: (context) => ProductDetailsModal(product: product),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _refreshData() async {
    await _productService.refreshCache();
    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: Column(
        children: [
          _buildHeader(context, isTablet),
          _buildTabBar(context),
          if (_statistics != null && !isMobile)
            _buildStatisticsSection(context, isTablet),
          _buildSearchAndFilters(context, isTablet),
          Expanded(
            child: _buildProductsList(context, isTablet),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: isTablet ? 32 : 28,
              color: AppTheme.secondaryGold,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zarządzanie Produktami',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_statistics != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${_statistics!.totalProducts} produktów • '
                      '${_statistics!.activeProducts} aktywnych',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              color: AppTheme.secondaryGold,
              tooltip: 'Odśwież dane',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: AppTheme.backgroundSecondary,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.secondaryGold,
        unselectedLabelColor: AppTheme.textTertiary,
        indicatorColor: AppTheme.secondaryGold,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Wszystkie'),
          Tab(text: 'Obligacje'),
          Tab(text: 'Udziały'),
          Tab(text: 'Pozostałe'),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context, bool isTablet) {
    if (_statistics == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: ProductsStatisticsCard(statistics: _statistics!),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderPrimary,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Wyszukaj produkty...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged();
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_outlined),
                color: _showFilters ? AppTheme.secondaryGold : AppTheme.textSecondary,
                tooltip: 'Filtry',
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
                icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                color: AppTheme.textSecondary,
                tooltip: _isGridView ? 'Widok listy' : 'Widok siatki',
              ),
            ],
          ),
          if (_showFilters) ...[
            const SizedBox(height: 16),
            ProductsFilterPanel(
              criteria: _filterCriteria,
              onFilterChanged: _onFilterChanged,
              sortField: _sortField,
              sortDirection: _sortDirection,
              onSortChanged: _onSortChanged,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductsList(BuildContext context, bool isTablet) {
    if (_isLoading && _filteredProducts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.secondaryGold),
            SizedBox(height: 16),
            Text(
              'Ładowanie produktów...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_outlined,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Brak produktów',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchText.isNotEmpty 
                  ? 'Nie znaleziono produktów pasujących do wyszukiwania'
                  : 'Nie znaleziono produktów spełniających kryteria filtrowania',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.secondaryGold,
      child: _isGridView
          ? ProductsGridView(
              products: _filteredProducts,
              onProductTap: _onProductTap,
              scrollController: _scrollController,
              isLoadingMore: _isLoadingMore,
              hasMoreItems: _hasMoreItems,
            )
          : ProductsListView(
              products: _filteredProducts,
              onProductTap: _onProductTap,
              scrollController: _scrollController,
              isLoadingMore: _isLoadingMore,
              hasMoreItems: _hasMoreItems,
            ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // TODO: Implementuj dodawanie nowego produktu
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funkcja dodawania produktów będzie wkrótce dostępna'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      },
      backgroundColor: AppTheme.secondaryGold,
      foregroundColor: AppTheme.textOnSecondary,
      child: const Icon(Icons.add),
    );
  }
}

/// Rozszerzenie dla ProductFilterCriteria z dodatkowymi metodami
extension ProductFilterCriteriaExtensions on ProductFilterCriteria {
  ProductFilterCriteria copyWith({
    List<UnifiedProductType>? productTypes,
    List<ProductStatus>? statuses,
    double? minInvestmentAmount,
    double? maxInvestmentAmount,
    DateTime? createdAfter,
    DateTime? createdBefore,
    String? searchText,
    String? companyName,
    double? minInterestRate,
    double? maxInterestRate,
  }) {
    return ProductFilterCriteria(
      productTypes: productTypes ?? this.productTypes,
      statuses: statuses ?? this.statuses,
      minInvestmentAmount: minInvestmentAmount ?? this.minInvestmentAmount,
      maxInvestmentAmount: maxInvestmentAmount ?? this.maxInvestmentAmount,
      createdAfter: createdAfter ?? this.createdAfter,
      createdBefore: createdBefore ?? this.createdBefore,
      searchText: searchText ?? this.searchText,
      companyName: companyName ?? this.companyName,
      minInterestRate: minInterestRate ?? this.minInterestRate,
      maxInterestRate: maxInterestRate ?? this.maxInterestRate,
    );
  }

  ProductFilterCriteria copyWithoutTypes() {
    return ProductFilterCriteria(
      productTypes: null,
      statuses: statuses,
      minInvestmentAmount: minInvestmentAmount,
      maxInvestmentAmount: maxInvestmentAmount,
      createdAfter: createdAfter,
      createdBefore: createdBefore,
      searchText: searchText,
      companyName: companyName,
      minInterestRate: minInterestRate,
      maxInterestRate: maxInterestRate,
    );
  }
}