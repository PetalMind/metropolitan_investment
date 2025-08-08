import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/loan.dart';
import '../services/firebase_functions_data_service.dart';
import '../widgets/custom_loading_widget.dart';
import '../utils/currency_formatter.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final FirebaseFunctionsDataService _dataService = FirebaseFunctionsDataService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Loan> _loans = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  
  // Filtering
  double? _minRemainingCapital;
  String? _selectedStatus;
  String? _selectedBorrower;
  
  // Pagination
  int _currentPage = 1;
  static const int _pageSize = 100;
  bool _hasMoreData = true;
  int _totalLoans = 0;

  // Sorting
  String _sortBy = 'created_at';
  String _sortDirection = 'desc';

  @override
  void initState() {
    super.initState();
    _loadLoans();
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
      _loadMoreLoans();
    }
  }

  Future<void> _loadLoans({bool isRefresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      if (isRefresh) {
        _loans.clear();
        _currentPage = 1;
      }
    });

    try {
      final result = await _dataService.getLoans(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
        minRemainingCapital: _minRemainingCapital,
        status: _selectedStatus,
        borrower: _selectedBorrower,
        sortBy: _sortBy,
        sortDirection: _sortDirection,
        forceRefresh: isRefresh,
      );

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _loans = result.loans;
          } else {
            _loans.addAll(result.loans);
          }
          _hasMoreData = result.hasNextPage;
          _totalLoans = result.total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Błąd podczas ładowania pożyczek: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreLoans() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;
      final result = await _dataService.getLoans(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
        minRemainingCapital: _minRemainingCapital,
        status: _selectedStatus,
        borrower: _selectedBorrower,
        sortBy: _sortBy,
        sortDirection: _sortDirection,
      );

      if (mounted) {
        setState(() {
          _loans.addAll(result.loans);
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
    _loadLoans(isRefresh: true);
  }

  void _onFilterChanged() {
    _currentPage = 1;
    _loadLoans(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pożyczki'),
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
                  case 'interest_desc':
                    _sortBy = 'accruedInterest';
                    _sortDirection = 'desc';
                    break;
                  case 'interest_asc':
                    _sortBy = 'accruedInterest';
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
              const PopupMenuItem(
                value: 'interest_desc',
                child: Text('Najwięcej odsetek'),
              ),
              const PopupMenuItem(
                value: 'interest_asc',
                child: Text('Najmniej odsetek'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadLoans(isRefresh: true),
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
                    hintText: 'Szukaj pożyczek...',
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
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status pożyczki',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Wszystkie')),
                          DropdownMenuItem(value: 'Aktywna', child: Text('Aktywna')),
                          DropdownMenuItem(value: 'Spłacona', child: Text('Spłacona')),
                          DropdownMenuItem(value: 'Opóźniona', child: Text('Opóźniona')),
                          DropdownMenuItem(value: 'Restrukturyzacja', child: Text('Restrukturyzacja')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedStatus = value);
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
          if (_totalLoans > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Znaleziono $_totalLoans pożyczek (wyświetlono ${_loans.length})',
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
    if (_isLoading && _loans.isEmpty) {
      return const Center(
        child: CustomLoadingWidget(
          message: 'Ładowanie pożyczek z Firebase Functions...',
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
              onPressed: () => _loadLoans(isRefresh: true),
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    if (_loans.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monetization_on, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Brak pożyczek spełniających kryteria'),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _loans.length + (_hasMoreData && _loans.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _loans.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _buildLoanCard(_loans[index]);
      },
    );
  }

  Widget _buildLoanCard(Loan loan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.secondaryGold,
          child: const Icon(Icons.monetization_on, color: Colors.white),
        ),
        title: Text(
          loan.productType,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (loan.loanNumber != null)
              Text('Numer pożyczki: ${loan.loanNumber}'),
            if (loan.borrower != null)
              Text('Pożyczkobiorca: ${loan.borrower}'),
            Text('Kapitał pozostały: ${CurrencyFormatter.formatCurrency(loan.remainingCapital)}'),
            if (loan.accruedInterest > 0)
              Text('Naliczone odsetki: ${CurrencyFormatter.formatCurrency(loan.accruedInterest)}'),
            if (loan.status != null)
              Text('Status: ${loan.status}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.formatCurrency(loan.investmentAmount),
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
        onTap: () => _showLoanDetails(loan),
      ),
    );
  }

  void _showLoanDetails(Loan loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loan.productType),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Kwota inwestycji', CurrencyFormatter.formatCurrency(loan.investmentAmount)),
              if (loan.loanNumber != null)
                _buildDetailRow('Numer pożyczki', loan.loanNumber!),
              if (loan.borrower != null)
                _buildDetailRow('Pożyczkobiorca', loan.borrower!),
              _buildDetailRow('Kapitał pozostały', CurrencyFormatter.formatCurrency(loan.remainingCapital)),
              if (loan.accruedInterest > 0)
                _buildDetailRow('Naliczone odsetki', CurrencyFormatter.formatCurrency(loan.accruedInterest)),
              if (loan.interestRate != null)
                _buildDetailRow('Stopa procentowa', '${loan.interestRate}%'),
              if (loan.disbursementDate != null)
                _buildDetailRow('Data wypłaty', loan.disbursementDate!.toString().split(' ')[0]),
              if (loan.repaymentDate != null)
                _buildDetailRow('Data spłaty', loan.repaymentDate!.toString().split(' ')[0]),
              if (loan.collateral != null)
                _buildDetailRow('Zabezpieczenie', loan.collateral!),
              if (loan.status != null)
                _buildDetailRow('Status', loan.status!),
              if (loan.capitalForRestructuring != null && loan.capitalForRestructuring! > 0)
                _buildDetailRow('Kapitał na restrukturyzację', CurrencyFormatter.formatCurrency(loan.capitalForRestructuring!)),
              if (loan.capitalSecuredByRealEstate != null && loan.capitalSecuredByRealEstate! > 0)
                _buildDetailRow('Kapitał zabezpieczony nieruchomością', CurrencyFormatter.formatCurrency(loan.capitalSecuredByRealEstate!)),
              _buildDetailRow('Data utworzenia', loan.createdAt.toString().split(' ')[0]),
              _buildDetailRow('Źródło danych', loan.sourceFile),
              if (loan.additionalInfo.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Dodatkowe informacje:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...loan.additionalInfo.entries.map(
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