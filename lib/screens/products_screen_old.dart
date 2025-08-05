import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/product.dart';
import '../services/firebase_functions_products_service.dart';
import '../services/product_service.dart'; // Zachowaj dla operacji CRUD
import '../widgets/data_table_widget.dart';
import '../widgets/product_form.dart';
import '../widgets/animated_button.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final FirebaseFunctionsProductsService _functionsService = FirebaseFunctionsProductsService();
  final ProductService _productService = ProductService(); // Dla operacji CRUD
  
  // State variables
  String _search = '';
  ProductType? _filterType;
  String? _clientId;
  String? _clientName;
  int _currentPage = 1;
  static const int _pageSize = 50;
  
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
        // Ustaw wyszukiwanie na nazwę klienta jeśli dostępna
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

  /// Ładuje produkty przez Firebase Functions
  Future<void> _loadProducts() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _functionsService.getOptimizedProducts(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _search.isNotEmpty ? _search : null,
        productType: _filterType,
        clientId: _clientId,
        sortBy: 'name',
        sortAscending: true,
      );

      setState(() {
        _products = result.products;
        _stats = result.stats;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Odświeża dane
  Future<void> _refreshProducts() async {
    _currentPage = 1;
    await _loadProducts();
  }

  /// Zmienia stronę
  void _changePage(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
    _loadProducts();
  }

  /// Zmienia wyszukiwanie
  void _onSearchChanged(String value) {
    setState(() {
      _search = value;
      _currentPage = 1;
    });
    // Debouncing - poczekaj chwilę przed wyszukiwaniem
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_search == value) {
        _loadProducts();
      }
    });
  }

  /// Zmienia filtr typu
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
      
      // Wyczyść cache i odśwież dane
      FirebaseFunctionsProductsService.clearProductCache();
      _closeForm();
      await _loadProducts();
      
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(Product product) async {
    setState(() => _isLoading = true);
    try {
      await _productService.deleteProduct(product.id);
      
      // Wyczyść cache i odśwież dane
      FirebaseFunctionsProductsService.clearProductCache();
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
                                    color: AppTheme.secondaryGold.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.secondaryGold.withOpacity(0.5),
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
                                        style: Theme.of(context).textTheme.bodySmall
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
                                  color: AppTheme.textOnPrimary.withOpacity(0.8),
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
                            backgroundColor: AppTheme.warningColor.withOpacity(0.8),
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
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
              // Informacje o paginacji
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
              Expanded(
                child: _buildProductsList(),
              ),

                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Błąd: ${snapshot.error}'));
                    }
                    final products = snapshot.data ?? [];
                    if (products.isEmpty) {
                      return Center(
                        child: Text(
                          'Brak produktów do wyświetlenia.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: DataTableWidget<Product>(
                        items: products,
                        columns: [
                          DataTableColumn(
                            label: 'Nazwa',
                            value: (p) => p.name,
                            sortable: true,
                          ),
                          DataTableColumn(
                            label: 'Typ',
                            value: (p) => p.type.displayName,
                            sortable: true,
                            widget: (p) => Chip(
                              label: Text(p.type.displayName),
                              backgroundColor:
                                  AppTheme.getProductTypeBackground(
                                    p.type.name,
                                  ),
                              labelStyle: TextStyle(
                                color: AppTheme.getProductTypeColor(
                                  p.type.name,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataTableColumn(
                            label: 'Firma',
                            value: (p) => p.companyName,
                            sortable: true,
                          ),
                          DataTableColumn(
                            label: 'Oprocent.',
                            value: (p) =>
                                p.interestRate?.toStringAsFixed(2) ?? '-',
                            numeric: true,
                          ),
                          DataTableColumn(
                            label: 'Aktywny',
                            value: (p) => p.isActive ? 'Tak' : 'Nie',
                            widget: (p) => Icon(
                              p.isActive ? Icons.check_circle : Icons.cancel,
                              color: p.isActive
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                              size: 20,
                            ),
                          ),
                          DataTableColumn(
                            label: 'Akcje',
                            value: (_) => '',
                            widget: (p) => Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  tooltip: 'Edytuj',
                                  onPressed: () => _openForm(p),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Usuń',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text(
                                          'Potwierdź usunięcie',
                                        ),
                                        content: Text(
                                          'Czy na pewno chcesz usunąć produkt "${p.name}"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Anuluj'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Usuń'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.errorColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await _deleteProduct(p);
                                    }
                                  },
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
          ),
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
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: AppTheme.errorBackground,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error, color: AppTheme.errorColor),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppTheme.errorColor),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: AppTheme.errorColor,
                          ),
                          onPressed: () => setState(() => _error = null),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
