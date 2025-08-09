import 'package:flutter/material.dart';
import '../theme/app_theme_professional.dart';
import '../models/investment.dart';
import '../models/product.dart';
import '../services/firebase_functions_data_service.dart';
import '../widgets/investment_card.dart';
import '../widgets/custom_loading_widget.dart';
import '../utils/currency_formatter.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  final FirebaseFunctionsDataService _dataService =
      FirebaseFunctionsDataService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Investment> _allInvestments = []; // Store all loaded investments
  List<Investment> _filteredInvestments =
      []; // Store filtered investments for display
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
        _allInvestments.clear();
        _filteredInvestments.clear();
        _currentPage = 1;
      }
    });

    try {
      print(
        '🔍 [InvestmentsScreen] Ładowanie inwestycji - strona $_currentPage, pageSize: $_pageSize',
      );

      // Try with simpler parameters to avoid Firebase Functions issues
      final result = await _dataService.getEnhancedInvestments(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: null, // Start without search to see if we get data
        status: null, // Start without status filter
        productType: null, // Start without product type filter
        minRemainingCapital: null,
        forceRefresh: isRefresh,
      );

      print(
        '✅ [InvestmentsScreen] Otrzymano ${result.investments.length} inwestycji z ${result.total} total',
      );

      // Debug more details about the response
      if (result.investments.isEmpty && result.total > 0) {
        print('⚠️ [InvestmentsScreen] PROBLEM: Brak inwestycji mimo total > 0');
        print('   - Total count: ${result.total}');
        print('   - Current page: ${result.page}');
        print('   - Page size: ${result.pageSize}');
        print('   - Has next page: ${result.hasNextPage}');
        print('   - Total pages: ${result.totalPages}');

        // Try to get raw data structure information
        print('   - Result type: ${result.runtimeType}');
        if (result.investments.isNotEmpty) {
          print('   - First investment: ${result.investments.first.id}');
        }
      }

      if (mounted) {
        setState(() {
          if (isRefresh || _currentPage == 1) {
            _allInvestments = result.investments;
          } else {
            _allInvestments.addAll(result.investments);
          }

          // Apply filtering to all investments
          _applyFilters();

          _hasMoreData = result.hasNextPage;
          _totalInvestments = result.total;
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

      // Use the same simple approach as in _loadInvestments
      final result = await _dataService.getEnhancedInvestments(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: null, // No server-side filtering
        status: null,
        productType: null,
        minRemainingCapital: null,
        forceRefresh: false,
      );

      if (mounted) {
        setState(() {
          // Add new investments without filtering - client-side filtering will be applied in display
          _allInvestments.addAll(result.investments);
          _applyFilters(); // Re-apply filters to include new data
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
    // Apply filters to existing data without API call
    if (mounted) {
      setState(() {
        _applyFilters();
      });
    }
  }

  void _onFilterChanged() {
    // Apply filters to existing data without API call
    if (mounted) {
      setState(() {
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    List<Investment> filteredInvestments = _allInvestments;

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      filteredInvestments = filteredInvestments
          .where(
            (investment) =>
                investment.clientName.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
                investment.productName.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ),
          )
          .toList();
    }

    // Apply status filter
    if (_selectedStatus != null) {
      filteredInvestments = filteredInvestments
          .where((investment) => investment.status == _selectedStatus)
          .toList();
    }

    // Apply product type filter
    if (_selectedProductType != null) {
      filteredInvestments = filteredInvestments
          .where((investment) => investment.productType == _selectedProductType)
          .toList();
    }

    _filteredInvestments = filteredInvestments;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemePro.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Inwestycje'),
        backgroundColor: AppThemePro.primaryDark,
        foregroundColor: AppThemePro.textPrimary,
        actions: [
          IconButton(
            key: Key('grid_view_toggle_${_isGridView}'),
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            key: const Key('refresh_investments'),
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
            color: AppThemePro.backgroundSecondary,
            child: Column(
              children: [
                TextField(
                  key: const Key('search_investments_field'),
                  controller: _searchController,
                  style: TextStyle(color: AppThemePro.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Szukaj inwestycji...',
                    hintStyle: TextStyle(color: AppThemePro.textMuted),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppThemePro.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppThemePro.surfaceInteractive,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppThemePro.borderPrimary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppThemePro.borderPrimary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppThemePro.accentGold,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: _onSearch, // Real-time search
                  onSubmitted: _onSearch,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<InvestmentStatus>(
                        key: const Key('status_filter_dropdown'),
                        value: _selectedStatus,
                        style: TextStyle(color: AppThemePro.textPrimary),
                        dropdownColor: AppThemePro.surfaceCard,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          labelStyle: TextStyle(
                            color: AppThemePro.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppThemePro.surfaceInteractive,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppThemePro.borderPrimary,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppThemePro.borderPrimary,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppThemePro.accentGold,
                              width: 2,
                            ),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(
                              'Wszystkie',
                              style: TextStyle(color: AppThemePro.textPrimary),
                            ),
                          ),
                          ...InvestmentStatus.values.map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(
                                status.displayName,
                                style: TextStyle(
                                  color: AppThemePro.textPrimary,
                                ),
                              ),
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
                        key: const Key('product_type_filter_dropdown'),
                        value: _selectedProductType,
                        style: TextStyle(color: AppThemePro.textPrimary),
                        dropdownColor: AppThemePro.surfaceCard,
                        decoration: InputDecoration(
                          labelText: 'Typ produktu',
                          labelStyle: TextStyle(
                            color: AppThemePro.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppThemePro.surfaceInteractive,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppThemePro.borderPrimary,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppThemePro.borderPrimary,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppThemePro.accentGold,
                              width: 2,
                            ),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(
                              'Wszystkie',
                              style: TextStyle(color: AppThemePro.textPrimary),
                            ),
                          ),
                          ...ProductType.values.map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                type.displayName,
                                style: TextStyle(
                                  color: AppThemePro.textPrimary,
                                ),
                              ),
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

          // Results count and applied filters info
          if (_totalInvestments > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppThemePro.backgroundSecondary,
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Znaleziono ${CurrencyFormatter.formatNumber(_totalInvestments.toDouble())} inwestycji (wyświetlono ${CurrencyFormatter.formatNumber(_filteredInvestments.length.toDouble())})',
                        style: TextStyle(
                          color: AppThemePro.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (_isLoadingMore)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppThemePro.accentGold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Show applied filters info
                  if (_searchController.text.isNotEmpty ||
                      _selectedProductType != null ||
                      _selectedStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: 14,
                            color: AppThemePro.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Aktywne filtry: ',
                            style: TextStyle(
                              color: AppThemePro.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              [
                                if (_searchController.text.isNotEmpty)
                                  'Szukaj: "${_searchController.text}"',
                                if (_selectedProductType != null)
                                  'Typ: ${_selectedProductType!.displayName}',
                                if (_selectedStatus != null)
                                  'Status: ${_selectedStatus!.displayName}',
                              ].join(', '),
                              style: TextStyle(
                                color: AppThemePro.accentGold,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _filteredInvestments.isEmpty) {
      return Center(
        child: CustomLoadingWidget(
          message: 'Ładowanie inwestycji...',
          color: AppThemePro.accentGold,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppThemePro.premiumCardDecoration,
          margin: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppThemePro.statusError,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppThemePro.textPrimary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadInvestments(isRefresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemePro.accentGold,
                  foregroundColor: AppThemePro.primaryDark,
                ),
                child: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredInvestments.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppThemePro.premiumCardDecoration,
          margin: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 64, color: AppThemePro.textMuted),
              const SizedBox(height: 16),
              Text(
                'Brak inwestycji spełniających kryteria',
                style: TextStyle(
                  color: AppThemePro.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isGridView) {
      return GridView.builder(
        key: const Key('investments_grid_view'),
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _filteredInvestments.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _filteredInvestments.length) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppThemePro.accentGold,
                ),
              ),
            );
          }
          return InvestmentCard(
            key: Key(
              'investment_grid_${_filteredInvestments[index].id}_$index',
            ),
            investment: _filteredInvestments[index],
          );
        },
      );
    } else {
      return ListView.builder(
        key: const Key('investments_list_view'),
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount:
            _filteredInvestments.length +
            (_hasMoreData && _filteredInvestments.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _filteredInvestments.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppThemePro.accentGold,
                  ),
                ),
              ),
            );
          }
          return Container(
            key: Key(
              'investment_container_${_filteredInvestments[index].id}_$index',
            ),
            margin: const EdgeInsets.only(bottom: 8),
            child: InvestmentCard(
              key: Key(
                'investment_list_${_filteredInvestments[index].id}_$index',
              ),
              investment: _filteredInvestments[index],
            ),
          );
        },
      );
    }
  }
}
