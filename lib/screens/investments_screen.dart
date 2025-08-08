import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/investment.dart';
import '../models/product.dart';
import '../services/firebase_functions_data_service.dart';
import '../widgets/investment_card.dart';
import '../widgets/custom_loading_widget.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  final FirebaseFunctionsDataService _dataService = FirebaseFunctionsDataService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Investment> _investments = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isGridView = false;
  String? _error;
  
  // Filtering
  InvestmentStatus? _selectedStatus;
  ProductType? _selectedProductType;
  // Future: Add branch and date range filtering

  // Pagination
  int _currentPage = 1;
  static const int _pageSize = 100;
  bool _hasMoreData = true;
  int _totalInvestments = 0;

  @override
  void initState() {
    super.initState();
    _loadInvestments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreInvestments();
    }
  }

  Future<void> _loadInvestments({bool isRefresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      if (isRefresh) {
        _investments.clear();
        _currentPage = 1;
      }
    });

    try {
      print('🔍 [InvestmentsScreen] Ładowanie inwestycji - strona $_currentPage');
      
      // Spróbuj najpierw z mniejszym page size dla szybszego ładowania
      final result = await _dataService.getEnhancedInvestments(
        page: 1, // Zawsze pierwsza strona dla lepszej wydajności
        pageSize: 50, // Zmniejszony rozmiar strony
        searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
        status: _selectedStatus?.name,
        productType: _selectedProductType?.name,
        minRemainingCapital: 0.0,
        forceRefresh: isRefresh,
      );
      
      print('✅ [InvestmentsScreen] Otrzymano ${result.investments.length} inwestycji');

      if (mounted) {
        setState(() {
          _investments = result.investments;
          _hasMoreData = result.investments.length == 50; // Prosta heurystyka
          _totalInvestments = result.investments.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [InvestmentsScreen] Błąd: $e');
      if (mounted) {
        setState(() {
          _error = 'Błąd podczas ładowania inwestycji: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreInvestments() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;
      final result = await _dataService.getEnhancedInvestments(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
        status: _selectedStatus?.name,
        productType: _selectedProductType?.name,
        minRemainingCapital: 0.0,
      );

      if (mounted) {
        setState(() {
          _investments.addAll(result.investments);
          _hasMoreData = result.hasNextPage;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentPage--; // Revert page increment on error
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd podczas ładowania więcej danych: $e')),
        );
      }
    }
  }

  void _onSearch(String query) {
    // Reset pagination and reload with new search
    _currentPage = 1;
    _loadInvestments(isRefresh: true);
  }

  void _onFilterChanged() {
    _currentPage = 1;
    _loadInvestments(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inwestycje'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadInvestments(isRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Szukaj inwestycji...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: _onSearch,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<InvestmentStatus>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Wszystkie')),
                          ...InvestmentStatus.values.map((status) =>
                            DropdownMenuItem(
                              value: status,
                              child: Text(status.displayName),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedStatus = value);
                          _onFilterChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<ProductType>(
                        value: _selectedProductType,
                        decoration: const InputDecoration(
                          labelText: 'Typ produktu',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Wszystkie')),
                          ...ProductType.values.map((type) =>
                            DropdownMenuItem(
                              value: type,
                              child: Text(type.displayName),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedProductType = value);
                          _onFilterChanged();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Results count
          if (_totalInvestments > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Znaleziono $_totalInvestments inwestycji (wyświetlono ${_investments.length})',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  if (_isLoadingMore)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _investments.isEmpty) {
      return const Center(
        child: CustomLoadingWidget(
          message: 'Ładowanie inwestycji z Firebase Functions...',
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadInvestments(isRefresh: true),
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    if (_investments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Brak inwestycji spełniających kryteria'),
          ],
        ),
      );
    }

    if (_isGridView) {
      return GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _investments.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _investments.length) {
            return const Center(child: CircularProgressIndicator());
          }
          return InvestmentCard(investment: _investments[index]);
        },
      );
    } else {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _investments.length + (_hasMoreData && _investments.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _investments.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InvestmentCard(investment: _investments[index]),
          );
        },
      );
    }
  }
}