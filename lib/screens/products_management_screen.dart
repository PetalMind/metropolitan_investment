import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/unified_product.dart';
import '../services/unified_product_service.dart';
import '../widgets/premium_loading_widget.dart';
import '../widgets/premium_error_widget.dart';
import '../widgets/product_card_widget.dart';
import '../widgets/product_stats_widget.dart';
import '../widgets/product_filter_widget.dart';
import '../widgets/product_details_dialog.dart';

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
    // Opóźnienie żeby dane zostały załadowane przed obsługą parametrów
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _handleRouteParameters();
      }
    });
  }

  void _handleRouteParameters() {
    final state = GoRouterState.of(context);
    final productName = state.uri.queryParameters['productName'];
    final productType = state.uri.queryParameters['productType'];

    print('🔍 [ProductsManagementScreen] Parametry z URL:');
    print('🔍 [ProductsManagementScreen] productName: $productName');
    print('🔍 [ProductsManagementScreen] productType: $productType');

    if (productName != null && productName.isNotEmpty) {
      print(
        '🔍 [ProductsManagementScreen] Ustawianie wyszukiwania: $productName',
      );
      _searchController.text = productName;
      _applyFiltersAndSearch();
    }

    if (productType != null && productType.isNotEmpty) {
      print('🔍 [ProductsManagementScreen] Typ produktu: $productType');
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
      print('🔍 [ProductsManagementScreen] Wyszukiwanie: "$searchLower"');

      filtered = filtered.where((product) {
        // Podstawowe pola
        bool matches =
            product.name.toLowerCase().contains(searchLower) ||
            product.description.toLowerCase().contains(searchLower) ||
            product.productType.displayName.toLowerCase().contains(
              searchLower,
            ) ||
            (product.companyName?.toLowerCase().contains(searchLower) ?? false);

        // Dodatkowe wyszukiwanie w additionalInfo
        if (!matches && product.additionalInfo.isNotEmpty) {
          for (final entry in product.additionalInfo.entries) {
            final key = entry.key.toString().toLowerCase();
            final value = entry.value.toString().toLowerCase();

            // Sprawdź klucze które mogą zawierać nazwy produktów
            if ((key.contains('nazwa') ||
                    key.contains('product') ||
                    key.contains('name')) &&
                value.contains(searchLower)) {
              matches = true;
              print(
                '🔍 [ProductsManagementScreen] Znaleziono w additionalInfo[$key]: $value',
              );
              break;
            }

            // Sprawdź też inne wartości
            if (value.contains(searchLower)) {
              matches = true;
              print('🔍 [ProductsManagementScreen] Znaleziono wartość: $value');
              break;
            }
          }
        }

        // Sprawdź też ID produktu
        if (!matches && product.id.toLowerCase().contains(searchLower)) {
          matches = true;
        }

        if (matches) {
          print(
            '🔍 [ProductsManagementScreen] Dopasowanie produktu: ${product.name}',
          );
        }

        return matches;
      }).toList();

      print(
        '🔍 [ProductsManagementScreen] Znaleziono ${filtered.length} z ${_allProducts.length} produktów',
      );
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
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => EnhancedProductDetailsDialog(product: product),
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
