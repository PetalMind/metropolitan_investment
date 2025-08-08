import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/share.dart';
import '../services/firebase_functions_data_service.dart';
import '../widgets/custom_loading_widget.dart';
import '../utils/currency_formatter.dart';

class SharesScreen extends StatefulWidget {
  const SharesScreen({super.key});

  @override
  State<SharesScreen> createState() => _SharesScreenState();
}

class _SharesScreenState extends State<SharesScreen> {
  final FirebaseFunctionsDataService _dataService = FirebaseFunctionsDataService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Share> _shares = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  
  // Filtering
  String? _selectedProductType;
  int? _minSharesCount;
  
  // Pagination
  int _currentPage = 1;
  static const int _pageSize = 100;
  bool _hasMoreData = true;
  int _totalShares = 0;

  // Sorting
  String _sortBy = 'created_at';
  String _sortDirection = 'desc';

  @override
  void initState() {
    super.initState();
    _loadShares();
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
      _loadMoreShares();
    }
  }

  Future<void> _loadShares({bool isRefresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      if (isRefresh) {
        _shares.clear();
        _currentPage = 1;
      }
    });

    try {
      final result = await _dataService.getShares(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
        minSharesCount: _minSharesCount,
        productType: _selectedProductType,
        sortBy: _sortBy,
        sortDirection: _sortDirection,
        forceRefresh: isRefresh,
      );

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _shares = result.shares;
          } else {
            _shares.addAll(result.shares);
          }
          _hasMoreData = result.hasNextPage;
          _totalShares = result.total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Błąd podczas ładowania udziałów: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreShares() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;
      final result = await _dataService.getShares(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
        minSharesCount: _minSharesCount,
        productType: _selectedProductType,
        sortBy: _sortBy,
        sortDirection: _sortDirection,
      );

      if (mounted) {
        setState(() {
          _shares.addAll(result.shares);
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
    _currentPage = 1;
    _loadShares(isRefresh: true);
  }

  void _onFilterChanged() {
    _currentPage = 1;
    _loadShares(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Udziały'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                switch (value) {
                  case 'created_at_desc':
                    _sortBy = 'created_at';
                    _sortDirection = 'desc';
                    break;
                  case 'created_at_asc':
                    _sortBy = 'created_at';
                    _sortDirection = 'asc';
                    break;
                  case 'shares_count_desc':
                    _sortBy = 'sharesCount';
                    _sortDirection = 'desc';
                    break;
                  case 'shares_count_asc':
                    _sortBy = 'sharesCount';
                    _sortDirection = 'asc';
                    break;
                  case 'remaining_capital_desc':
                    _sortBy = 'remainingCapital';
                    _sortDirection = 'desc';
                    break;
                  case 'remaining_capital_asc':
                    _sortBy = 'remainingCapital';
                    _sortDirection = 'asc';
                    break;
                }
              });
              _onFilterChanged();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'created_at_desc',
                child: Text('Najnowsze'),
              ),
              const PopupMenuItem(
                value: 'created_at_asc',
                child: Text('Najstarsze'),
              ),
              const PopupMenuItem(
                value: 'shares_count_desc',
                child: Text('Najwięcej udziałów'),
              ),
              const PopupMenuItem(
                value: 'shares_count_asc',
                child: Text('Najmniej udziałów'),
              ),
              const PopupMenuItem(
                value: 'remaining_capital_desc',
                child: Text('Największa wartość'),
              ),
              const PopupMenuItem(
                value: 'remaining_capital_asc',
                child: Text('Najmniejsza wartość'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadShares(isRefresh: true),
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
                    hintText: 'Szukaj udziałów...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: _onSearch,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Min. liczba udziałów',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _minSharesCount = int.tryParse(value);
                          _onFilterChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedProductType,
                        decoration: const InputDecoration(
                          labelText: 'Typ udziałów',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Wszystkie')),
                          DropdownMenuItem(value: 'Udziały', child: Text('Udziały')),
                          DropdownMenuItem(value: 'Udziały spółki', child: Text('Udziały spółki')),
                          DropdownMenuItem(value: 'Akcje', child: Text('Akcje')),
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
          if (_totalShares > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Znaleziono $_totalShares udziałów (wyświetlono ${_shares.length})',
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
    if (_isLoading && _shares.isEmpty) {
      return const Center(
        child: CustomLoadingWidget(
          message: 'Ładowanie udziałów z Firebase Functions...',
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
              onPressed: () => _loadShares(isRefresh: true),
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    if (_shares.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Brak udziałów spełniających kryteria'),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _shares.length + (_hasMoreData && _shares.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _shares.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _buildShareCard(_shares[index]);
      },
    );
  }

  Widget _buildShareCard(Share share) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.secondaryGold,
          child: const Icon(Icons.pie_chart, color: Colors.white),
        ),
        title: Text(
          share.productType,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Liczba udziałów: ${share.sharesCount}'),
            Text('Kapitał pozostały: ${CurrencyFormatter.formatCurrency(share.remainingCapital)}'),
            if (share.capitalForRestructuring != null && share.capitalForRestructuring! > 0)
              Text('Kapitał na restrukturyzację: ${CurrencyFormatter.formatCurrency(share.capitalForRestructuring!)}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.formatCurrency(share.investmentAmount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'PLN',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () => _showShareDetails(share),
      ),
    );
  }

  void _showShareDetails(Share share) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(share.productType),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Kwota inwestycji', CurrencyFormatter.formatCurrency(share.investmentAmount)),
              _buildDetailRow('Liczba udziałów', share.sharesCount.toString()),
              _buildDetailRow('Kapitał pozostały', CurrencyFormatter.formatCurrency(share.remainingCapital)),
              if (share.capitalForRestructuring != null && share.capitalForRestructuring! > 0)
                _buildDetailRow('Kapitał na restrukturyzację', CurrencyFormatter.formatCurrency(share.capitalForRestructuring!)),
              if (share.capitalSecuredByRealEstate != null && share.capitalSecuredByRealEstate! > 0)
                _buildDetailRow('Kapitał zabezpieczony nieruchomością', CurrencyFormatter.formatCurrency(share.capitalSecuredByRealEstate!)),
              _buildDetailRow('Data utworzenia', share.createdAt.toString().split(' ')[0]),
              _buildDetailRow('Źródło danych', share.sourceFile),
              if (share.additionalInfo.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Dodatkowe informacje:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...share.additionalInfo.entries.map(
                  (entry) => _buildDetailRow(entry.key, entry.value.toString()),
                ),
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}