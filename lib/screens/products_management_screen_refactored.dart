import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models_and_services.dart';

// Aliasy dla uniknięcia konfliktów
import '../services/product_management_service.dart' as pm;

/// 🚀 REFACTORED: Ekran zarządzania produktami używający centralnego ProductManagementService
///
/// Zalety tego podejścia:
/// - ✅ Jeden serwis dla wszystkich operacji na produktach
/// - ✅ Automatyczne wybieranie optymalnej strategii ładowania
/// - ✅ Ujednolicone API dla wyszukiwania, filtrowania, sortowania
/// - ✅ Centralne zarządzanie cache
/// - ✅ Łatwiejszy testing i maintenance
class ProductsManagementScreenRefactored extends StatefulWidget {
  const ProductsManagementScreenRefactored({super.key});

  @override
  State<ProductsManagementScreenRefactored> createState() =>
      _ProductsManagementScreenRefactoredState();
}

class _ProductsManagementScreenRefactoredState
    extends State<ProductsManagementScreenRefactored>
    with TickerProviderStateMixin {
  // 🚀 CENTRALNY SERWIS - jedyne źródło prawdy dla produktów
  late final ProductManagementService _productManagementService;
  // 🧹 SERWIS ZARZĄDZANIA CACHE - centralne czyszczenie cache
  late final CacheManagementService _cacheManagementService;

  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // Stan ekranu - uproszczony dzięki centralnemu serwisowi
  ProductManagementData? _data;
  List<OptimizedProduct> _filteredOptimizedProducts = [];
  List<DeduplicatedProduct> _filteredDeduplicatedProducts = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  ProductSearchResult? _searchResult;

  // Kontrolery
  final TextEditingController _searchController = TextEditingController();
  ProductSortField _sortField = ProductSortField.createdAt;
  SortDirection _sortDirection = SortDirection.descending;

  // Ustawienia wyświetlania
  bool _showFilters = false;
  bool _showDeduplicatedView = true;
  bool _useOptimizedMode = true;
  UnifiedProductType? _filterType;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _loadInitialData();
  }

  void _initializeServices() {
    _productManagementService = ProductManagementService();
    _cacheManagementService = CacheManagementService();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  /// 🚀 GŁÓWNE ŁADOWANIE DANYCH - centralny punkt wejścia
  Future<void> _loadInitialData() async {
    if (kDebugMode) {
      print('🚀 [ProductsScreen] Rozpoczynam ładowanie danych...');
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stopwatch = Stopwatch()..start();

      // 🚀 UŻYJ CENTRALNEGO SERWISU
      final data = await _productManagementService.loadProductsData(
        sortField: _sortField,
        sortDirection: _sortDirection,
        showDeduplicatedView: _showDeduplicatedView,
        useOptimizedMode: _useOptimizedMode,
      );

      stopwatch.stop();

      if (mounted) {
        setState(() {
          _data = data;
          _filteredOptimizedProducts = data.optimizedProducts;
          _filteredDeduplicatedProducts = data.deduplicatedProducts;
          _isLoading = false;
        });

        _applyCurrentFiltersAndSort();

        if (kDebugMode) {
          print(
            '✅ [ProductsScreen] Załadowano ${data.optimizedProducts.length} produktów w ${stopwatch.elapsedMilliseconds}ms',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ProductsScreen] Błąd ładowania: $e');
      }

      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// 🔍 WYSZUKIWANIE - wykorzystuje centralny serwis
  Future<void> _searchProducts(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResult = null;
      });
      _applyCurrentFiltersAndSort();
      return;
    }

    try {
      final result = await _productManagementService.searchProducts(
        query: query,
        filterType: _filterType,
        useOptimizedMode: _useOptimizedMode,
        maxResults: 100,
      );

      if (mounted) {
        setState(() {
          _searchResult = result;
          _filteredOptimizedProducts = result.products;
          _filteredDeduplicatedProducts = result.deduplicatedProducts;
        });

        if (kDebugMode) {
          print(
            '🔍 [ProductsScreen] Wyszukano "${query}": ${result.totalResults} wyników w ${result.searchTime}ms',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ProductsScreen] Błąd wyszukiwania: $e');
      }
    }
  }

  /// 🔄 ODŚWIEŻANIE DANYCH
  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);

    try {
      await _productManagementService.clearAllCache();
      await _loadInitialData();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  /// 🔽 FILTROWANIE I SORTOWANIE
  void _applyCurrentFiltersAndSort() {
    if (_data == null) return;

    List<OptimizedProduct> optimizedProducts = _data!.optimizedProducts;
    List<DeduplicatedProduct> deduplicatedProducts =
        _data!.deduplicatedProducts;

    // Filtruj według typu jeśli wybrano
    if (_filterType != null) {
      optimizedProducts = optimizedProducts
          .where((p) => p.productType == _filterType)
          .toList();
      deduplicatedProducts = deduplicatedProducts
          .where((p) => p.productType == _filterType)
          .toList();
    }

    // Sortuj
    optimizedProducts = _productManagementService
        .sortProducts<OptimizedProduct>(
          products: optimizedProducts,
          sortField: _sortField,
          direction: _sortDirection,
        );

    deduplicatedProducts = _productManagementService
        .sortProducts<DeduplicatedProduct>(
          products: deduplicatedProducts,
          sortField: _sortField,
          direction: _sortDirection,
        );

    setState(() {
      _filteredOptimizedProducts = optimizedProducts;
      _filteredDeduplicatedProducts = deduplicatedProducts;
    });
  }

  /// 🎨 BUDOWANIE UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Icon(Icons.inventory_2, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          const Text('Zarządzanie Produktami'),
          if (_searchResult != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_searchResult!.totalResults} wyników',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Toggle widoku
        IconButton(
          icon: Icon(
            _showDeduplicatedView ? Icons.view_list : Icons.view_module,
          ),
          onPressed: () {
            setState(() {
              _showDeduplicatedView = !_showDeduplicatedView;
            });
            _applyCurrentFiltersAndSort();
          },
          tooltip: _showDeduplicatedView
              ? 'Widok unified'
              : 'Widok deduplikowany',
        ),
        // Toggle trybu
        IconButton(
          icon: Icon(_useOptimizedMode ? Icons.flash_on : Icons.flash_off),
          onPressed: () {
            setState(() {
              _useOptimizedMode = !_useOptimizedMode;
            });
            _loadInitialData();
          },
          tooltip: _useOptimizedMode ? 'Tryb optimized' : 'Tryb legacy',
        ),
        // Filtry
        IconButton(
          icon: Icon(
            _showFilters ? Icons.filter_list_off : Icons.filter_list,
            color: _showFilters ? AppTheme.primaryColor : null,
          ),
          onPressed: () {
            setState(() => _showFilters = !_showFilters);
          },
        ),
        // 🧹 Cache Management
        IconButton(
          icon: const Icon(Icons.cleaning_services),
          onPressed: _showCacheManagementDialog,
          tooltip: 'Zarządzanie cache',
        ),
        // Odśwież
        IconButton(
          icon: _isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          onPressed: _isRefreshing ? null : _refreshData,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Search bar
        _buildSearchBar(),

        // Filters panel
        if (_showFilters) _buildFiltersPanel(),

        // Stats bar
        if (_data?.statistics != null) _buildStatsBar(),

        // Content
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surfaceCard,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Wyszukaj produkty...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchProducts('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppTheme.backgroundSecondary,
        ),
        onChanged: (value) {
          _searchProducts(value);
        },
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surfaceCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filtry', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              // Typ produktu
              Expanded(
                child: DropdownButtonFormField<UnifiedProductType?>(
                  value: _filterType,
                  decoration: const InputDecoration(
                    labelText: 'Typ produktu',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<UnifiedProductType?>(
                      value: null,
                      child: Text('Wszystkie'),
                    ),
                    ...UnifiedProductType.values.map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type.name)),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _filterType = value);
                    _applyCurrentFiltersAndSort();
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Sortowanie
              Expanded(
                child: DropdownButtonFormField<ProductSortField>(
                  value: _sortField,
                  decoration: const InputDecoration(
                    labelText: 'Sortuj według',
                    border: OutlineInputBorder(),
                  ),
                  items: ProductSortField.values
                      .map(
                        (field) => DropdownMenuItem(
                          value: field,
                          child: Text(field.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sortField = value);
                      _applyCurrentFiltersAndSort();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Kierunek sortowania
              IconButton(
                icon: Icon(
                  _sortDirection == SortDirection.ascending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                ),
                onPressed: () {
                  setState(() {
                    _sortDirection = _sortDirection == SortDirection.ascending
                        ? SortDirection.descending
                        : SortDirection.ascending;
                  });
                  _applyCurrentFiltersAndSort();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    final stats = _data!.statistics!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Produkty', '${stats.totalProducts}'),
          _buildStatItem(
            'Wartość',
            '${(stats.totalValue / 1000000).toStringAsFixed(1)}M zł',
          ),
          _buildStatItem(
            'Średnia',
            '${(stats.averageValue / 1000).toStringAsFixed(0)}k zł',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Ładowanie produktów...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Błąd: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    final products = _showDeduplicatedView
        ? _filteredDeduplicatedProducts
        : _filteredOptimizedProducts;

    if (products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Brak produktów do wyświetlenia'),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            if (_showDeduplicatedView) {
              return _buildDeduplicatedProductCard(
                _filteredDeduplicatedProducts[index],
              );
            } else {
              return _buildOptimizedProductCard(
                _filteredOptimizedProducts[index],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildDeduplicatedProductCard(DeduplicatedProduct product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            _getProductIcon(product.productType),
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Typ: ${product.productType.name}'),
            Text('Wartość: ${_formatCurrency(product.totalValue)}'),
            Text('Inwestorzy: ${product.actualInvestorCount}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _showProductDetails(product.id),
      ),
    );
  }

  Widget _buildOptimizedProductCard(OptimizedProduct product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            _getProductIcon(product.productType),
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Typ: ${product.productType.name}'),
            Text('Wartość: ${_formatCurrency(product.totalValue)}'),
            Text('Inwestorzy: ${product.actualInvestorCount}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _showProductDetails(product.id),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _showProductDetails('new'),
      backgroundColor: AppTheme.primaryColor,
      child: const Icon(Icons.add),
    );
  }

  /// 📋 SZCZEGÓŁY PRODUKTU - używa centralnego serwisu
  Future<void> _showProductDetails(String productId) async {
    if (productId == 'new') {
      // TODO: Dialog dodawania nowego produktu
      return;
    }

    try {
      final details = await _productManagementService.getProductDetails(
        productId,
      );

      if (details == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nie znaleziono produktu')),
          );
        }
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _buildProductDetailsDialog(details),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    }
  }

  Widget _buildProductDetailsDialog(pm.ProductDetails details) {
    return AlertDialog(
      title: Text(details.name),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${details.id}'),
            Text('Typ: ${details.productType.name}'),
            Text('Inwestorzy: ${details.totalInvestors}'),
            const SizedBox(height: 16),
            if (details.investors.isNotEmpty) ...[
              const Text(
                'Pierwsi inwestorzy:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...details.investors
                  .take(3)
                  .map((investor) => Text('• ${investor.client.name}')),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Zamknij'),
        ),
      ],
    );
  }

  // Utility methods
  IconData _getProductIcon(UnifiedProductType type) {
    switch (type) {
      case UnifiedProductType.bonds:
        return Icons.account_balance;
      case UnifiedProductType.shares:
        return Icons.trending_up;
      case UnifiedProductType.loans:
        return Icons.attach_money;
      case UnifiedProductType.apartments:
        return Icons.home;
      default:
        return Icons.inventory_2;
    }
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M zł';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k zł';
    } else {
      return '${value.toStringAsFixed(0)} zł';
    }
  }

  // 🧹 ZARZĄDZANIE CACHE
  Future<void> _showCacheManagementDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cleaning_services, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Zarządzanie Cache'),
            ],
          ),
          content: const Text(
            'Wybierz akcję do wykonania na cache:\n\n'
            '• Wyczyść wszystko - usuwa cache wszystkich serwisów\n'
            '• Inteligentne odświeżanie - selektywne czyszczenie\n'
            '• Preload - rozgrzewanie cache dla lepszej wydajności\n'
            '• Status - diagnostyka cache',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showCacheStatusDialog();
              },
              child: const Text('Status'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _preloadCache();
              },
              child: const Text('Preload'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _smartRefreshCache();
              },
              child: const Text('Odśwież'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearAllCache();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Wyczyść'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllCache() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Czyszczenie cache...'),
            ],
          ),
        ),
      );

      final result = await _cacheManagementService.clearAllCaches();

      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? '✅ Cache wyczyszczony (${result.duration}ms)'
                : '❌ Błędy podczas czyszczenia: ${result.errors.length}',
          ),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );

      if (result.success) {
        await _loadInitialData(); // Przeładuj dane
      }
    } catch (e) {
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('❌ Błąd: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _smartRefreshCache() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Inteligentne odświeżanie...'),
            ],
          ),
        ),
      );

      final result = await _cacheManagementService.smartRefresh(
        refreshProducts: true,
        refreshStatistics: true,
        refreshAnalytics: false,
      );

      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? '✅ Cache odświeżony (${result.duration}ms, ${result.refreshedServices.length} serwisów)'
                : '❌ Błędy podczas odświeżania: ${result.errors.length}',
          ),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );

      if (result.success) {
        await _loadInitialData(); // Przeładuj dane
      }
    } catch (e) {
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('❌ Błąd: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _preloadCache() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Rozgrzewanie cache...'),
            ],
          ),
        ),
      );

      final result = await _cacheManagementService.preloadCache();

      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? '✅ Cache rozgrzany (${result.duration}ms, ${result.preloadedServices.length} serwisów)'
                : '❌ Błędy podczas preload: ${result.errors.length}',
          ),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('❌ Błąd: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showCacheStatusDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<GlobalCacheStatus>(
          future: _cacheManagementService.getCacheStatus(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                title: Text('Status Cache'),
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Sprawdzam status...'),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Błąd'),
                content: Text(
                  'Nie można pobrać statusu cache: ${snapshot.error}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              );
            }

            final status = snapshot.data!;
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.info, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text('Status Cache'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🎯 Cache optimized: ${status.productManagementCache.optimizedCacheHit ? "✅" : "❌"}',
                    ),
                    Text(
                      '📊 Cache deduplikowany: ${status.productManagementCache.deduplicatedCacheActive ? "✅" : "❌"}',
                    ),
                    Text(
                      '🔄 Wersja cache: ${status.productManagementCache.cacheVersion}',
                    ),
                    Text(
                      '📊 Dashboard aktywny: ${status.dashboardCacheActive ? "✅" : "❌"}',
                    ),
                    Text('⏱️ Czas diagnostyki: ${status.diagnosticTime}ms'),
                    Text(
                      '🔄 Ostatnie odświeżenie: ${status.lastGlobalRefresh.toString().substring(11, 19)}',
                    ),
                    if (status.productManagementCache.lastRefresh != null)
                      Text(
                        '📅 Cache z: ${status.productManagementCache.lastRefresh.toString().substring(11, 19)}',
                      ),
                    if (status.productManagementCache.error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '❌ Błąd cache: ${status.productManagementCache.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      '🔧 Zintegrowane serwisy:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...status.servicesIntegrated.map(
                      (service) => Text('• $service'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
