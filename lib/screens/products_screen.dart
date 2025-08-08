import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/product.dart';
import '../services/firebase_functions_products_service.dart';
import '../services/product_service.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/product_form.dart';
import '../widgets/animated_button.dart';
import '../widgets/standard_products/advanced_product_dialog.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final FirebaseFunctionsProductsService _functionsService =
      FirebaseFunctionsProductsService();
  final ProductService _productService = ProductService();

  // State variables
  String _search = '';
  ProductType? _filterType;
  String? _clientId;
  String? _clientName;
  int _currentPage = 1;
  static const int _pageSize = 100;

  // UI state
  Product? _editingProduct;
  bool _showForm = false;
  bool _isLoading = false;
  String? _error;

  // Data
  List<Product> _products = [];
  ProductsStats? _stats;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Sprawdź czy są parametry z nawigacji
    final state = GoRouterState.of(context);
    final clientId = state.uri.queryParameters['clientId'];
    final clientName = state.uri.queryParameters['clientName'];

    if (clientId != null && clientId != _clientId) {
      setState(() {
        _clientId = clientId;
        _clientName = clientName;
        if (clientName != null && clientName.isNotEmpty) {
          _search = clientName;
        }
      });
      _loadProducts();
    } else if (_products.isEmpty) {
      _loadProducts();
    }
  }

  void _openForm([Product? product]) {
    setState(() {
      _editingProduct = product;
      _showForm = true;
    });
  }

  void _showAdvancedProductDialog(Product product) {
    AdvancedProductDialog.show(context, product);
  }

  void _closeForm() {
    setState(() {
      _showForm = false;
      _editingProduct = null;
    });
  }

  void _clearClientFilter() {
    setState(() {
      _clientId = null;
      _clientName = null;
      _search = '';
      _currentPage = 1;
    });
    context.go('/products');
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔍 [ProductsScreen] Ładowanie produktów...');
      
      // Używaj mniejszej paginacji dla lepszej wydajności
      final result = await _functionsService.getOptimizedProducts(
        page: 1, // Zawsze pierwsza strona
        pageSize: 50, // Zmniejszony rozmiar
        searchQuery: _search.isNotEmpty ? _search : null,
        productType: _filterType,
        clientId: _clientId,
        sortBy: 'name',
        sortAscending: true,
      );

      print('✅ [ProductsScreen] Załadowano ${result.products.length} produktów');

      setState(() {
        _products = result.products;
        _stats = result.stats;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [ProductsScreen] Błąd ładowania: $e');
      setState(() {
        _error = 'Błąd podczas ładowania produktów: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshProducts() async {
    _currentPage = 1;
    await _loadProducts();
  }

  void _changePage(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
    _loadProducts();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _search = value;
      _currentPage = 1;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_search == value) {
        _loadProducts();
      }
    });
  }

  void _onFilterChanged(ProductType? type) {
    setState(() {
      _filterType = type;
      _currentPage = 1;
    });
    _loadProducts();
  }

  Future<void> _saveProduct(Product product) async {
    setState(() => _isLoading = true);
    try {
      if (product.id.isEmpty) {
        await _productService.createProduct(product);
      } else {
        await _productService.updateProduct(product.id, product);
      }

      FirebaseFunctionsProductsService.clearProductCache();
      _closeForm();
      await _loadProducts();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.gradientDecoration,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Zarządzanie Produktami',
                                style: Theme.of(context).textTheme.displayMedium
                                    ?.copyWith(color: AppTheme.textOnPrimary),
                              ),
                              if (_clientId != null) ...[
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryGold.withValues(alpha: 
                                      0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.secondaryGold.withValues(alpha: 
                                        0.5,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.filter_list,
                                        size: 16,
                                        color: AppTheme.secondaryGold,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Filtr: ${_clientName ?? 'Klient'}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppTheme.secondaryGold,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _clientId != null
                                ? 'Produkty powiązane z klientem'
                                : 'Obligacje, Udziały, Pożyczki, Apartamenty',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppTheme.textOnPrimary.withValues(alpha: 
                                    0.8,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (_clientId != null) ...[
                          AnimatedButton(
                            onPressed: _clearClientFilter,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.clear, size: 20),
                                SizedBox(width: 8),
                                Text('Usuń filtr'),
                              ],
                            ),
                            backgroundColor: AppTheme.warningColor.withValues(alpha: 
                              0.8,
                            ),
                            foregroundColor: AppTheme.textOnPrimary,
                          ),
                          const SizedBox(width: 12),
                        ],
                        AnimatedButton(
                          onPressed: () => _openForm(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.add, size: 20),
                              SizedBox(width: 8),
                              Text('Nowy Produkt'),
                            ],
                          ),
                          backgroundColor: AppTheme.surfaceCard,
                          foregroundColor: AppTheme.primaryColor,
                          width: 170,
                          height: 48,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Controls
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Szukaj po nazwie produktu lub firmie...',
                          filled: true,
                          fillColor: AppTheme.surfaceCard,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: _onSearchChanged,
                        controller: TextEditingController(text: _search),
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<ProductType?>(
                      value: _filterType,
                      hint: const Text('Typ produktu'),
                      items: [
                        const DropdownMenuItem<ProductType?>(
                          value: null,
                          child: Text('Wszystkie typy'),
                        ),
                        ...ProductType.values.map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.displayName),
                          ),
                        ),
                      ],
                      onChanged: _onFilterChanged,
                      underline: Container(),
                    ),
                    const SizedBox(width: 16),
                    AnimatedButton(
                      onPressed: _refreshProducts,
                      child: const Icon(Icons.refresh),
                      backgroundColor: AppTheme.surfaceCard,
                      foregroundColor: AppTheme.primaryColor,
                      width: 48,
                      height: 48,
                    ),
                  ],
                ),
              ),
              // Pagination info
              if (_stats != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        'Produkty ${(_currentPage - 1) * _pageSize + 1}-'
                        '${(_currentPage - 1) * _pageSize + _products.length} '
                        'z ${_stats!.totalProducts}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (_stats!.hasPreviousPage)
                        IconButton(
                          onPressed: () => _changePage(_currentPage - 1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                      Text(
                        'Strona $_currentPage z ${_stats!.totalPages}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_stats!.hasNextPage)
                        IconButton(
                          onPressed: () => _changePage(_currentPage + 1),
                          icon: const Icon(Icons.chevron_right),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // Products list
              Expanded(child: _buildProductsList()),
            ],
          ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
          // Form dialog
          if (_showForm)
            Center(
              child: Dialog(
                backgroundColor: AppTheme.surfaceCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  width: 480,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ProductForm(
                      product: _editingProduct,
                      onSave: _saveProduct,
                      onCancel: _closeForm,
                    ),
                  ),
                ),
              ),
            ),
          // Error message
          if (_error != null)
            Positioned(
              top: 100,
              left: 24,
              right: 24,
              child: Material(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => _error = null),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_isLoading && _products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              'Błąd podczas ładowania produktów',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProducts,
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _clientId != null
                  ? 'Klient nie ma produktów'
                  : 'Brak produktów do wyświetlenia',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _clientId != null
                  ? 'Ten klient nie ma jeszcze żadnych inwestycji w produkty.'
                  : 'Dodaj pierwszy produkt, aby rozpocząć zarządzanie.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (_clientId == null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _openForm(),
                child: const Text('Dodaj produkt'),
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: DataTableWidget<Product>(
        items: _products,
        columns: [
          DataTableColumn(label: 'Nazwa', value: (p) => p.name, numeric: false),
          DataTableColumn(
            label: 'Typ',
            value: (p) => p.type.displayName,
            numeric: false,
          ),
          DataTableColumn(
            label: 'Firma',
            value: (p) => p.companyName,
            numeric: false,
          ),
          DataTableColumn(
            label: 'Status',
            value: (p) => p.isActive ? 'Aktywny' : 'Nieaktywny',
            numeric: false,
          ),
        ],
        onRowTap: (p) => _showAdvancedProductDialog(p),
      ),
    );
  }
}
