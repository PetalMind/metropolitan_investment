import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models_and_services.dart';
import '../services/product_management_service.dart';
import '../widgets/premium_loading_widget.dart';
import '../widgets/premium_error_widget.dart';
import '../widgets/product_management/product_card_advanced.dart';
import '../widgets/dialogs/enhanced_investor_email_dialog.dart';

/// Nowy ekran zarządzania produktami z rozdzieloną architekturą
/// Wykorzystuje ProductManagementService i wydzielone komponenty
class NewProductsManagementScreen extends StatefulWidget {
  // Parametry do wyróżnienia konkretnego produktu lub inwestycji
  final String? highlightedProductId;
  final String? highlightedInvestmentId;

  // Parametry do początkowego wyszukiwania (fallback)
  final String? initialSearchProductName;
  final String? initialSearchProductType;
  final String? initialSearchClientId;
  final String? initialSearchClientName;

  const NewProductsManagementScreen({
    super.key,
    this.highlightedProductId,
    this.highlightedInvestmentId,
    this.initialSearchProductName,
    this.initialSearchProductType,
    this.initialSearchClientId,
    this.initialSearchClientName,
  });

  @override
  State<NewProductsManagementScreen> createState() =>
      _NewProductsManagementScreenState();
}

class _NewProductsManagementScreenState
    extends State<NewProductsManagementScreen>
    with TickerProviderStateMixin {
  late final ProductManagementService _productManagementService;

  // Stan ekranu
  ProductManagementData? _currentData;
  bool _isLoading = false;
  String? _error;

  // Ustawienia widoku
  bool _showDeduplicatedView = false;
  bool _useOptimizedMode = false;
  ProductSortField _sortField = ProductSortField.name;
  SortDirection _sortDirection = SortDirection.ascending;

  // Wybór produktów dla działań email
  final Set<String> _selectedProductIds = {};

  // Kontrolery dla wyszukiwania
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _productManagementService = ProductManagementService();
    _initializeSearch();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeSearch() {
    if (widget.initialSearchProductName != null) {
      _searchController.text = widget.initialSearchProductName!;
      _searchQuery = widget.initialSearchProductName!;
    }
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _productManagementService.loadProductsData(
        sortField: _sortField,
        sortDirection: _sortDirection,
        showDeduplicatedView: _showDeduplicatedView,
        useOptimizedMode: _useOptimizedMode,
      );

      if (mounted) {
        setState(() {
          _currentData = data;
          _isLoading = false;
        });
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

  Future<void> _refreshData() async {
    await _productManagementService.refreshCache();
    await _loadProducts();
  }

  void _toggleOptimizedMode() {
    setState(() {
      _useOptimizedMode = !_useOptimizedMode;
    });
    _loadProducts();
  }

  void _toggleDeduplicatedView() {
    setState(() {
      _showDeduplicatedView = !_showDeduplicatedView;
    });
    _loadProducts();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onProductSelectionChanged(String productId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedProductIds.add(productId);
      } else {
        _selectedProductIds.remove(productId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedProductIds.clear();
    });
  }

  void _selectAll() {
    setState(() {
      _selectedProductIds.clear();
      final products = _getFilteredProducts();
      for (final product in products) {
        _selectedProductIds.add(product.id);
      }
    });
  }

  List<DeduplicatedProduct> _getFilteredProducts() {
    if (_currentData == null) return [];

    final products = _showDeduplicatedView
        ? _currentData!.deduplicatedProducts
        : _currentData!.deduplicatedProducts;

    if (_searchQuery.isEmpty) return products;

    return products.where((product) {
      final searchLower = _searchQuery.toLowerCase();
      return product.name.toLowerCase().contains(searchLower) ||
          product.companyName.toLowerCase().contains(searchLower) ||
          product.productType.displayName.toLowerCase().contains(searchLower);
    }).toList();
  }

  Future<void> _showEmailDialog() async {
    if (_selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wybierz produkty do wysłania email'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedProducts = _getFilteredProducts()
        .where((product) => _selectedProductIds.contains(product.id))
        .toList();

    // Konwertuj DeduplicatedProduct na InvestorSummary dla email dialog
    final investorSummaries = selectedProducts.map((product) {
      // Tworzymy sztucznego klienta dla produktu
      final client = Client(
        id: product.id,
        name: 'Produkt: ${product.name}',
        companyName: product.companyName,
        email: '',
        phone: '',
        address: '',
        type: ClientType.other,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return InvestorSummary(
        client: client,
        investments: [],
        totalInvestmentAmount: product.totalValue,
        totalRemainingCapital: product.totalRemainingCapital,
        totalSharesValue: 0.0,
        totalValue: product.totalValue,
        totalRealizedCapital: 0.0,
        capitalSecuredByRealEstate: 0.0,
        capitalForRestructuring: 0.0,
        investmentCount: product.totalInvestments,
      );
    }).toList();

    await showDialog(
      context: context,
      builder: (context) => EnhancedInvestorEmailDialog(
        selectedInvestors: investorSummaries,
        onEmailSent: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email został wysłany'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zarządzanie Produktami'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedProductIds.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.email),
              onPressed: _showEmailDialog,
              tooltip: 'Wyślij email',
            ),
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearSelection,
              tooltip: 'Wyczyść zaznaczenie',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  '${_selectedProductIds.length} zaznaczonych',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAll,
              tooltip: 'Zaznacz wszystkie',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Odśwież',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Szukaj produktów...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _onSearch,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text('Deduplikowane produkty'),
                  value: _showDeduplicatedView,
                  onChanged: (value) => _toggleDeduplicatedView(),
                ),
              ),
              Expanded(
                child: SwitchListTile(
                  title: const Text('Tryb zoptymalizowany'),
                  value: _useOptimizedMode,
                  onChanged: (value) => _toggleOptimizedMode(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: PremiumLoadingWidget(message: 'Ładowanie produktów...'),
      );
    }

    if (_error != null) {
      return PremiumErrorWidget(error: _error!, onRetry: _loadProducts);
    }

    if (_currentData == null) {
      return const Center(child: Text('Brak danych do wyświetlenia'));
    }

    final filteredProducts = _getFilteredProducts();

    if (filteredProducts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Brak produktów do wyświetlenia',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        final isSelected = _selectedProductIds.contains(product.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ProductCardAdvanced(
            product: product,
            index: index,
            isSelected: isSelected,
            isSelectionMode: _selectedProductIds.isNotEmpty,
            onSelectionChanged: (selected) =>
                _onProductSelectionChanged(product.id, selected ?? false),
            onTap: () => _showProductDetails(product),
          ),
        );
      },
    );
  }

  void _showProductDetails(DeduplicatedProduct product) {
    // Implementacja pokazywania szczegółów produktu
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Firma: ${product.companyName}'),
            Text('Typ: ${product.productType.displayName}'),
            Text(
              'Kwota inwestycji: ${product.totalValue.toStringAsFixed(2)} PLN',
            ),
            Text(
              'Pozostały kapitał: ${product.totalRemainingCapital.toStringAsFixed(2)} PLN',
            ),
            Text('Status: ${product.status.displayName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }
}
