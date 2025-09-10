import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models_and_services.dart';
import '../config/app_routes.dart'; // 🚀 NOWE: Import dla extension methods
import '../providers/auth_provider.dart';
import '../services/firebase_functions_products_service.dart' as fb;
import '../services/unified_product_service.dart' as unified;
import '../adapters/product_statistics_adapter.dart';
import '../widgets/premium_error_widget.dart';
import '../widgets/metropolitan_loading_system.dart';
import '../widgets/product_management/scroll_aware_product_header.dart';
import '../widgets/product_management/product_type_distribution_widget.dart';
import '../widgets/dialogs/product_details_dialog.dart'; // 🚀 NOWE: Dialog produktów

// RBAC: wspólny tooltip dla braku uprawnień
const String kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

/// 🎨 MODERN PRODUCTS MANAGEMENT SCREEN
/// 
/// Całkowicie przeprojektowany ekran zarządzania produktami z:
/// - Responsywnym scroll-aware header z animacjami
/// - Nowoczesnymi animowanymi statystykami z wykresami
/// - Płynnym przewijaniem z collapse/expand behavior
/// - Zaawansowanymi filtrami i wyszukiwaniem
/// - Gestural interactions i haptic feedback
class ModernProductsManagementScreen extends StatefulWidget {
  // Parametry do wyróżnienia konkretnego produktu lub inwestycji
  final String? highlightedProductId;
  final String? highlightedInvestmentId;

  // Parametry do początkowego wyszukiwania (fallback)
  final String? initialSearchProductName;
  final String? initialSearchProductType;
  final String? initialSearchClientId;
  final String? initialSearchClientName;

  const ModernProductsManagementScreen({
    super.key,
    this.highlightedProductId,
    this.highlightedInvestmentId,
    this.initialSearchProductName,
    this.initialSearchProductType,
    this.initialSearchClientId,
    this.initialSearchClientName,
  });

  @override
  State<ModernProductsManagementScreen> createState() =>
      _ModernProductsManagementScreenState();
}

class _ModernProductsManagementScreenState extends State<ModernProductsManagementScreen>
    with TickerProviderStateMixin {
  late final FirebaseFunctionsProductsService _productService;
  late final DeduplicatedProductService _deduplicatedProductService;
  late final OptimizedProductService _optimizedProductService;

  // Animation controllers
  late final AnimationController _fadeController;
  late final AnimationController _staggerController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _staggerAnimation;

  // Scroll controller for header animations
  final ScrollController _scrollController = ScrollController();

  // Stan ekranu
  List<UnifiedProduct> _allProducts = [];
  List<UnifiedProduct> _filteredProducts = [];
  List<DeduplicatedProduct> _deduplicatedProducts = [];
  List<DeduplicatedProduct> _filteredDeduplicatedProducts = [];
  List<OptimizedProduct> _optimizedProducts = [];
  List<OptimizedProduct> _filteredOptimizedProducts = [];
  fb.ProductStatistics? _statistics;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  // RBAC getter
  bool get canEdit => Provider.of<AuthProvider>(context, listen: false).isAdmin;

  // Kontrolery wyszukiwania i filtrowania
  final TextEditingController _searchController = TextEditingController();
  final ProductFilterCriteria _filterCriteria = const ProductFilterCriteria();
  final ProductSortField _sortField = ProductSortField.createdAt;
  final SortDirection _sortDirection = SortDirection.descending;

  // Kontrola wyświetlania
  bool _showFilters = false;
  final bool _showStatistics = true;
  bool _showCharts = true;
  final ViewMode _viewMode = ViewMode.list;
  bool _showDeduplicatedView = true;
  final bool _useOptimizedMode = true;

  // Email functionality
  bool _isSelectionMode = false;
  final Set<String> _selectedProductIds = <String>{};

  // Gettery dla wybranych produktów
  List<DeduplicatedProduct> get _selectedProducts {
    return _filteredDeduplicatedProducts
        .where((product) => _selectedProductIds.contains(product.id))
        .toList();
  }

  // Gettery dla liczników
  int get _totalCount {
    if (_useOptimizedMode) return _optimizedProducts.length;
    if (_showDeduplicatedView) return _deduplicatedProducts.length;
    return _allProducts.length;
  }

  int get _filteredCount {
    if (_useOptimizedMode) return _filteredOptimizedProducts.length;
    if (_showDeduplicatedView) return _filteredDeduplicatedProducts.length;
    return _filteredProducts.length;
  }

  @override
  void initState() {
    super.initState();
    _initializeServices();
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

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeServices() {
    _productService = FirebaseFunctionsProductsService();
    _deduplicatedProductService = DeduplicatedProductService();
    _optimizedProductService = OptimizedProductService();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _staggerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _staggerController, curve: Curves.easeOutQuart),
    );
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      _applyFiltersAndSearch();
    });
  }

  void _handleRouteParameters() {
    final state = GoRouterState.of(context);
    final productName =
        widget.initialSearchProductName ??
        state.uri.queryParameters['productName'];
    final investmentIdFromUrl = state.uri.queryParameters['investmentId'];

    if (investmentIdFromUrl != null && investmentIdFromUrl.isNotEmpty) {
      _findAndShowProductForInvestment(investmentIdFromUrl);
      return;
    }

    if (widget.highlightedProductId != null ||
        widget.highlightedInvestmentId != null) {
      _highlightSpecificProduct();
      return;
    }

    if (productName != null && productName.isNotEmpty) {
      _searchController.text = productName;
      _applyFiltersAndSearch();
    }
  }

  Future<void> _findAndShowProductForInvestment(String investmentId) async {
    // Implementacja podobna do oryginału
    // TODO: Przenieś logikę z oryginalnej wersji
  }

  void _highlightSpecificProduct() async {
    // Implementacja podobna do oryginału
    // TODO: Przenieś logikę z oryginalnej wersji
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      if (kDebugMode) {
        print('🔄 [ModernProductsManagement] Rozpoczynam ładowanie danych...');
      }

      // Wyczyść cache liczby inwestorów przed załadowaniem danych
      try {
        final investorCountService = UnifiedInvestorCountService();
        investorCountService.clearAllCache();
        debugPrint('✅ [ModernProductsManagement] Cache liczby inwestorów wyczyszczony');
      } catch (e) {
        debugPrint('⚠️ [ModernProductsManagement] Błąd czyszczenia cache: $e');
      }

      if (_useOptimizedMode) {
        await _loadOptimizedData();
      } else {
        await _loadLegacyData();
      }

      // Start animations after data is loaded
      _startAnimations();

    } catch (e) {
      if (kDebugMode) {
        print('❌ [ModernProductsManagement] Błąd podczas ładowania: $e');
      }

      if (mounted) {
        setState(() {
          _error = 'Błąd podczas ładowania produktów: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadOptimizedData() async {
    if (kDebugMode) {
      print('⚡ [ModernProductsManagement] Używam OptimizedProductService...');
    }

    final stopwatch = Stopwatch()..start();

    final optimizedResult = await _optimizedProductService
        .getAllProductsOptimized(forceRefresh: false, includeStatistics: true);

    stopwatch.stop();

    if (mounted) {
      setState(() {
        _optimizedProducts = optimizedResult.products;
        _filteredOptimizedProducts = List.from(optimizedResult.products);

        // Konwertuj OptimizedProduct na DeduplicatedProduct dla kompatybilności
        _deduplicatedProducts = optimizedResult.products
            .map((opt) => _convertOptimizedToDeduplicatedProduct(opt))
            .toList();
        _filteredDeduplicatedProducts = List.from(_deduplicatedProducts);

        if (optimizedResult.statistics != null) {
          _statistics = _convertGlobalStatsToFBStatsViAdapter(
            optimizedResult.statistics!,
          );
        }

        _isLoading = false;
      });

      _applyFiltersAndSearch();

      if (kDebugMode) {
        print(
          '✅ [ModernProductsManagement] OptimizedProductService: ${optimizedResult.products.length} produktów w ${stopwatch.elapsedMilliseconds}ms',
        );
      }
    }
  }

  Future<void> _loadLegacyData() async {
    if (kDebugMode) {
      print('🔄 [ModernProductsManagement] Używam legacy loading...');
    }

    // Pobierz produkty, statystyki i deduplikowane produkty równolegle
    final results = await Future.wait([
      _productService.getUnifiedProducts(
        pageSize: 1000,
        sortBy: _sortField.name,
        sortAscending: _sortDirection == SortDirection.ascending,
      ),
      _showDeduplicatedView
          ? _deduplicatedProductService.getDeduplicatedProductStatistics().then(
              (stats) => ProductStatisticsAdapter.adaptFromUnifiedToFB(stats),
            )
          : _productService.getProductStatistics(),
      _deduplicatedProductService.getAllUniqueProducts(),
    ]);

    final productsResult = results[0] as UnifiedProductsResult;
    final statistics = results[1] as fb.ProductStatistics;
    final deduplicatedProducts = results[2] as List<DeduplicatedProduct>;

    if (mounted) {
      setState(() {
        _allProducts = productsResult.products;
        _filteredProducts = List.from(_allProducts);
        _deduplicatedProducts = deduplicatedProducts;
        _filteredDeduplicatedProducts = List.from(deduplicatedProducts);
        _statistics = statistics;
        _isLoading = false;
      });

      _applyFiltersAndSearch();
    }
  }

  DeduplicatedProduct _convertOptimizedToDeduplicatedProduct(OptimizedProduct opt) {
    return DeduplicatedProduct(
      id: opt.id,
      name: opt.name,
      productType: opt.productType,
      companyId: opt.companyId,
      companyName: opt.companyName,
      totalValue: opt.totalValue,
      totalRemainingCapital: opt.totalRemainingCapital,
      totalInvestments: opt.totalInvestments,
      uniqueInvestors: opt.uniqueInvestors,
      actualInvestorCount: opt.actualInvestorCount,
      averageInvestment: opt.averageInvestment,
      earliestInvestmentDate: opt.earliestInvestmentDate,
      latestInvestmentDate: opt.latestInvestmentDate,
      status: opt.status,
      interestRate: opt.interestRate,
      maturityDate: null,
      originalInvestmentIds: [],
      metadata: opt.metadata,
    );
  }

  fb.ProductStatistics _convertGlobalStatsToFBStatsViAdapter(
    GlobalProductStatistics global,
  ) {
    final unifiedStats = unified.ProductStatistics(
      totalProducts: global.totalProducts,
      activeProducts: global.totalProducts,
      inactiveProducts: 0,
      totalInvestmentAmount: global.totalValue,
      totalValue: global.totalValue,
      averageInvestmentAmount: global.averageValuePerProduct,
      averageValue: global.averageValuePerProduct,
      typeDistribution: _convertTypeDistribution(global.productTypeDistribution),
      statusDistribution: const {ProductStatus.active: 1},
      mostValuableType: UnifiedProductType.bonds,
    );

    return ProductStatisticsAdapter.adaptFromUnifiedToFB(unifiedStats);
  }

  Map<UnifiedProductType, int> _convertTypeDistribution(
    Map<String, int> typeDistribution,
  ) {
    final Map<UnifiedProductType, int> result = {};

    for (final entry in typeDistribution.entries) {
      final unifiedType = _mapStringToUnifiedProductType(entry.key);
      if (unifiedType != null) {
        result[unifiedType] = entry.value;
      }
    }

    return result;
  }

  UnifiedProductType? _mapStringToUnifiedProductType(String type) {
    switch (type.toLowerCase()) {
      case 'bonds':
      case 'obligacje':
        return UnifiedProductType.bonds;
      case 'shares':
      case 'akcje':
        return UnifiedProductType.shares;
      case 'loans':
      case 'pozyczki':
        return UnifiedProductType.loans;
      case 'apartments':
      case 'mieszkania':
        return UnifiedProductType.apartments;
      case 'other':
      case 'inne':
        return UnifiedProductType.other;
      default:
        return UnifiedProductType.bonds;
    }
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _staggerController.forward();
      }
    });
  }

  Future<void> _refreshData() async {
    if (_isRefreshing || !mounted) return;

    if (mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }

    HapticFeedback.mediumImpact();

    try {
      // Wyczyść cache liczby inwestorów przy każdym odświeżaniu
      try {
        final investorCountService = UnifiedInvestorCountService();
        investorCountService.clearAllCache();
        debugPrint('✅ [ModernProductsManagement] Cache wyczyszczony przy odświeżaniu');
      } catch (e) {
        debugPrint('⚠️ [ModernProductsManagement] Błąd czyszczenia cache: $e');
      }

      if (_useOptimizedMode) {
        await _optimizedProductService.refreshProducts();
        await _loadOptimizedData();
      } else {
        await _productService.refreshCache();
        await _loadLegacyData();
      }

      if (kDebugMode) {
        print('🔄 [ModernProductsManagement] Dane odświeżone');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _applyFiltersAndSearch() {
    if (_useOptimizedMode) {
      _applyFiltersAndSearchForOptimizedProducts();
    } else if (_showDeduplicatedView) {
      _applyFiltersAndSearchForDeduplicatedProducts();
    } else {
      _applyFiltersAndSearchForRegularProducts();
    }
  }

  void _applyFiltersAndSearchForOptimizedProducts() {
    List<OptimizedProduct> filtered = List.from(_optimizedProducts);

    final searchText = _searchController.text.trim();
    if (searchText.isNotEmpty) {
      final searchLower = searchText.toLowerCase();
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(searchLower) ||
            product.companyName.toLowerCase().contains(searchLower) ||
            product.productType.displayName.toLowerCase().contains(searchLower);
      }).toList();
    }

    // Apply filters similar to original implementation
    // TODO: Implement filtering logic

    setState(() {
      _filteredOptimizedProducts = filtered;
      _filteredDeduplicatedProducts = filtered
          .map((opt) => _convertOptimizedToDeduplicatedProduct(opt))
          .toList();
    });
  }

  void _applyFiltersAndSearchForDeduplicatedProducts() {
    // TODO: Implement filtering for deduplicated products
  }

  void _applyFiltersAndSearchForRegularProducts() {
    // TODO: Implement filtering for regular products
  }

  void _showEmailDialog() {
    // TODO: Implement email dialog
  }

  void _showProductDetails(UnifiedProduct product) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => EnhancedProductDetailsDialog(
        product: product,
        onShowInvestors: () {
          Navigator.of(context).pop();
          // Przejdź do analizy inwestorów z wyszukiwaniem produktu
          context.goToInvestorAnalyticsWithSearch(product.name);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          ScrollAwareProductHeader(
            scrollController: _scrollController,
            searchController: _searchController,
            productStatistics: _statistics,
            isLoading: _isLoading,
            onSearchChanged: (value) => _applyFiltersAndSearch(),
            showCharts: _showCharts,
            onToggleCharts: () {
              setState(() {
                _showCharts = !_showCharts;
              });
              HapticFeedback.selectionClick();
            },
            onRefresh: _refreshData,
            subtitle: _showDeduplicatedView
                ? 'Zarządzanie unikalnymi produktami'
                : 'Zarządzanie wszystkimi produktami',
            totalCount: _totalCount,
            filteredCount: _filteredCount,
            additionalActions: _buildHeaderActions(),
          ),

          if (_showFilters)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildFiltersSection(),
              ),
            ),

          if (!_isLoading && _statistics != null)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.textSecondary.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.shadowColor.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ProductTypeDistributionWidget(
                    productStatistics: _statistics,
                    isLoading: false,
                    height: 300,
                    showAnimation: true,
                    showLegend: true,
                    padding: const EdgeInsets.all(20),
                  ),
                ),
              ),
            ),

          if (_isLoading)
            SliverFillRemaining(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: const Center(
                  child: MetropolitanLoadingWidget.products(showProgress: true),
                ),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: PremiumErrorWidget(
                  error: _error!,
                  onRetry: _loadInitialData,
                ),
              ),
            )
          else
            _buildProductsList(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Email functionality w trybie selekcji
        if (_isSelectionMode) ...[
          IconButton(
            icon: Icon(
              Icons.email,
              color: _selectedProducts.isNotEmpty
                  ? AppTheme.secondaryGold
                  : AppTheme.textSecondary,
            ),
            onPressed: _selectedProducts.isNotEmpty ? _showEmailDialog : null,
            tooltip: 'Wyślij email do wybranych (${_selectedProducts.length})',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.secondaryGold),
            onPressed: () {
              setState(() {
                _isSelectionMode = false;
                _selectedProductIds.clear();
              });
            },
            tooltip: 'Anuluj selekcję',
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.email, color: AppTheme.secondaryGold),
            onPressed: () {
              setState(() {
                _isSelectionMode = true;
              });
            },
            tooltip: 'Wybierz produkty do email',
          ),
        ],


        // Filters toggle
        IconButton(
          icon: Icon(
            _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
            color: AppTheme.secondaryGold,
          ),
          onPressed: () {
            setState(() {
              _showFilters = !_showFilters;
            });
            HapticFeedback.selectionClick();
          },
          tooltip: _showFilters ? 'Ukryj filtry' : 'Pokaż filtry',
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.3),
        ),
      ),
      child: const Text(
        'Filtry - TODO: Implementacja',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildProductsList() {
    final products = _showDeduplicatedView
        ? _filteredDeduplicatedProducts
        : _filteredProducts;

    if (products.isEmpty) {
      return SliverFillRemaining(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppTheme.textSecondary,
                ),
                SizedBox(height: 16),
                Text(
                  'Nie znaleziono produktów',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Spróbuj zmienić kryteria wyszukiwania',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: AnimatedBuilder(
        animation: _staggerAnimation,
        builder: (context, child) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final animationDelay = (index * 0.1).clamp(0.0, 1.0);
                final itemAnimation = Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: _staggerController,
                  curve: Interval(
                    animationDelay,
                    (animationDelay + 0.3).clamp(0.0, 1.0),
                    curve: Curves.easeOutCubic,
                  ),
                ));

                return FadeTransition(
                  opacity: itemAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(itemAnimation),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: _buildProductCard(products[index], index),
                    ),
                  ),
                );
              },
              childCount: products.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(dynamic product, int index) {
    final isDeduplicatedProduct = product is DeduplicatedProduct;
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            if (isDeduplicatedProduct) {
              // TODO: Show deduplicated product details
            } else {
              _showProductDetails(product as UnifiedProduct);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.productType.displayName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.secondaryGold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  product.companyName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatChip(
                        'Wartość',
                        '${(product.totalValue / 1000).toStringAsFixed(0)}k PLN',
                        Icons.account_balance_wallet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatChip(
                        'Inwestorzy',
                        '${product.actualInvestorCount ?? 0}',
                        Icons.people,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (!canEdit) return null;

    return FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.mediumImpact();
        // TODO: Navigate to add product screen
      },
      backgroundColor: AppTheme.secondaryGold,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Nowy Produkt'),
    );
  }
}