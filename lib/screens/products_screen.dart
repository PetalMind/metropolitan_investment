import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/product_form.dart';
import '../widgets/animated_button.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = ProductService();
  String _search = '';
  ProductType? _filterType;
  Product? _editingProduct;
  bool _showForm = false;
  bool _isLoading = false;
  String? _error;

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

  Future<void> _saveProduct(Product product) async {
    setState(() => _isLoading = true);
    try {
      if (product.id.isEmpty) {
        await _productService.createProduct(product);
      } else {
        await _productService.updateProduct(product.id, product);
      }
      _closeForm();
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
                          Text(
                            'Zarządzanie Produktami',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(color: AppTheme.textOnPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Obligacje, Udziały, Pożyczki, Apartamenty',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppTheme.textOnPrimary.withOpacity(
                                    0.8,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
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
                        onChanged: (v) => setState(() => _search = v.trim()),
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
                      onChanged: (v) => setState(() => _filterType = v),
                      underline: Container(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Product>>(
                  stream: _search.isEmpty
                      ? (_filterType == null
                            ? _productService.getProducts()
                            : _productService.getProductsByType(_filterType!))
                      : _productService.searchProducts(_search),
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
