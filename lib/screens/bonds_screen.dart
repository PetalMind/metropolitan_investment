import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/bond.dart';
import '../services/firebase_functions_data_service.dart';
import '../widgets/custom_loading_widget.dart';
import '../utils/currency_formatter.dart';

class BondsScreen extends StatefulWidget {
  const BondsScreen({super.key});

  @override
  State<BondsScreen> createState() => _BondsScreenState();
}

class _BondsScreenState extends State<BondsScreen> {
  final FirebaseFunctionsDataService _dataService = FirebaseFunctionsDataService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Bond> _bonds = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  
  // Filtering
  String? _selectedProductType;
  double? _minRemainingCapital;
  
  // Pagination
  int _currentPage = 1;
  static const int _pageSize = 100;
  bool _hasMoreData = true;
  int _totalBonds = 0;

  // Sorting
  String _sortBy = 'created_at';
  String _sortDirection = 'desc';

  @override
  void initState() {
    super.initState();
    _loadBonds();
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
      _loadMoreBonds();
    }
  }

  Future<void> _loadBonds({bool isRefresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      if (isRefresh) {
        _bonds.clear();
        _currentPage = 1;
      }
    });

    try {
      final result = await _dataService.getBonds(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
        minRemainingCapital: _minRemainingCapital,
        productType: _selectedProductType,
        sortBy: _sortBy,
        sortDirection: _sortDirection,
        forceRefresh: isRefresh,
      );

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _bonds = result.bonds;
          } else {
            _bonds.addAll(result.bonds);
          }
          _hasMoreData = result.hasNextPage;
          _totalBonds = result.total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Błąd podczas ładowania obligacji: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreBonds() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;
      final result = await _dataService.getBonds(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
        minRemainingCapital: _minRemainingCapital,
        productType: _selectedProductType,
        sortBy: _sortBy,
        sortDirection: _sortDirection,
      );

      if (mounted) {
        setState(() {
          _bonds.addAll(result.bonds);
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
    _loadBonds(isRefresh: true);
  }

  void _onFilterChanged() {
    _currentPage = 1;
    _loadBonds(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obligacje'),
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
            onPressed: () => _loadBonds(isRefresh: true),
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
                    hintText: 'Szukaj obligacji...',
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
                          labelText: 'Min. kapitał pozostały',
                          border: OutlineInputBorder(),
                          prefixText: 'PLN ',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _minRemainingCapital = double.tryParse(value);
                          _onFilterChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedProductType,
                        decoration: const InputDecoration(
                          labelText: 'Typ obligacji',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Wszystkie')),
                          DropdownMenuItem(value: 'Obligacje', child: Text('Obligacje')),
                          DropdownMenuItem(value: 'Obligacje korporacyjne', child: Text('Korporacyjne')),
                          DropdownMenuItem(value: 'Obligacje skarbowe', child: Text('Skarbowe')),
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
          if (_totalBonds > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Znaleziono $_totalBonds obligacji (wyświetlono ${_bonds.length})',
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
    if (_isLoading && _bonds.isEmpty) {
      return const Center(
        child: CustomLoadingWidget(
          message: 'Ładowanie obligacji z Firebase Functions...',
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
              onPressed: () => _loadBonds(isRefresh: true),
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    if (_bonds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Brak obligacji spełniających kryteria'),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _bonds.length + (_hasMoreData && _bonds.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _bonds.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _buildBondCard(_bonds[index]);
      },
    );
  }

  Widget _buildBondCard(Bond bond) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.secondaryGold,
          child: const Icon(Icons.receipt_long, color: Colors.white),
        ),
        title: Text(
          bond.productType,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kapitał pozostały: ${CurrencyFormatter.formatCurrency(bond.remainingCapital)}'),
            Text('Kapitał zrealizowany: ${CurrencyFormatter.formatCurrency(bond.realizedCapital)}'),
            if (bond.remainingInterest > 0)
              Text('Odsetki pozostałe: ${CurrencyFormatter.formatCurrency(bond.remainingInterest)}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.formatCurrency(bond.investmentAmount),
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
        onTap: () => _showBondDetails(bond),
      ),
    );
  }

  void _showBondDetails(Bond bond) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(bond.productType),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Kwota inwestycji', CurrencyFormatter.formatCurrency(bond.investmentAmount)),
              _buildDetailRow('Kapitał pozostały', CurrencyFormatter.formatCurrency(bond.remainingCapital)),
              _buildDetailRow('Kapitał zrealizowany', CurrencyFormatter.formatCurrency(bond.realizedCapital)),
              if (bond.remainingInterest > 0)
                _buildDetailRow('Odsetki pozostałe', CurrencyFormatter.formatCurrency(bond.remainingInterest)),
              if (bond.realizedInterest > 0)
                _buildDetailRow('Odsetki zrealizowane', CurrencyFormatter.formatCurrency(bond.realizedInterest)),
              if (bond.transferToOtherProduct > 0)
                _buildDetailRow('Transfer na inny produkt', CurrencyFormatter.formatCurrency(bond.transferToOtherProduct)),
              _buildDetailRow('Data utworzenia', bond.createdAt.toString().split(' ')[0]),
              _buildDetailRow('Źródło danych', bond.sourceFile),
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