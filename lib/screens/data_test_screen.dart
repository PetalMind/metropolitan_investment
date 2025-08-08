import 'package:flutter/material.dart';
import '../services/firebase_functions_data_service.dart';
import '../models/bond.dart';
import '../models/share.dart';
import '../models/loan.dart';
import '../models/apartment.dart';

class DataTestScreen extends StatefulWidget {
  const DataTestScreen({super.key});

  @override
  State<DataTestScreen> createState() => _DataTestScreenState();
}

class _DataTestScreenState extends State<DataTestScreen> {
  final FirebaseFunctionsDataService _dataService =
      FirebaseFunctionsDataService();

  int _currentPage = 1;
  static const int _pageSize = 10; // Mniejszy rozmiar dla testów
  String _selectedDataType = 'bonds';
  bool _isLoading = false;

  List<dynamic> _currentData = [];
  String _statusMessage = '';
  Map<String, dynamic>? _statistics;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Ładowanie danych...';
    });

    try {
      switch (_selectedDataType) {
        case 'bonds':
          await _loadBonds();
          break;
        case 'shares':
          await _loadShares();
          break;
        case 'loans':
          await _loadLoans();
          break;
        case 'apartments':
          await _loadApartments();
          break;
        case 'statistics':
          await _loadStatistics();
          break;
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Błąd: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBonds() async {
    final result = await _dataService.getBonds(
      page: _currentPage,
      pageSize: _pageSize,
    );
    setState(() {
      _currentData = result.bonds;
      _statusMessage =
          'Pobrano ${result.bonds.length} obligacji (strona ${result.page}/${result.totalPages})';
    });
  }

  Future<void> _loadShares() async {
    final result = await _dataService.getShares(
      page: _currentPage,
      pageSize: _pageSize,
    );
    setState(() {
      _currentData = result.shares;
      _statusMessage =
          'Pobrano ${result.shares.length} udziałów (strona ${result.page}/${result.totalPages})';
    });
  }

  Future<void> _loadLoans() async {
    final result = await _dataService.getLoans(
      page: _currentPage,
      pageSize: _pageSize,
    );
    setState(() {
      _currentData = result.loans;
      _statusMessage =
          'Pobrano ${result.loans.length} pożyczek (strona ${result.page}/${result.totalPages})';
    });
  }

  Future<void> _loadApartments() async {
    final result = await _dataService.getApartments(
      page: _currentPage,
      pageSize: _pageSize,
    );
    setState(() {
      _currentData = result.apartments;
      _statusMessage =
          'Pobrano ${result.apartments.length} apartamentów (strona ${result.page}/${result.totalPages})';
    });
  }

  Future<void> _loadStatistics() async {
    final result = await _dataService.getProductTypeStatistics();
    setState(() {
      _statistics = {
        'bonds': {
          'count': result.bonds.count,
          'totalValue': result.bonds.totalValue,
          'averageValue': result.bonds.averageValue,
        },
        'shares': {
          'count': result.shares.count,
          'totalValue': result.shares.totalValue,
          'averageValue': result.shares.averageValue,
        },
        'loans': {
          'count': result.loans.count,
          'totalValue': result.loans.totalValue,
          'averageValue': result.loans.averageValue,
        },
        'apartments': {
          'count': result.apartments.count,
          'totalValue': result.apartments.totalValue,
          'averageValue': result.apartments.averageValue,
          'totalArea': result.apartments.totalArea,
        },
        'summary': {
          'totalCount': result.summary.totalCount,
          'totalValue': result.summary.totalValue,
          'totalInvestmentAmount': result.summary.totalInvestmentAmount,
        },
      };
      _currentData = [];
      _statusMessage = 'Statystyki załadowane';
    });
  }

  void _clearCache() {
    FirebaseFunctionsDataService.clearDataCache();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cache wyczyszczony')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Firebase Functions Data Service'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearCache,
            tooltip: 'Wyczyść cache',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Odśwież',
          ),
        ],
      ),
      body: Column(
        children: [
          // Selektor typu danych
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Wybierz typ danych:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _selectedDataType,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDataType = value;
                          _currentPage = 1;
                        });
                        _loadData();
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: 'bonds',
                        child: Text('Obligacje'),
                      ),
                      DropdownMenuItem(value: 'shares', child: Text('Udziały')),
                      DropdownMenuItem(value: 'loans', child: Text('Pożyczki')),
                      DropdownMenuItem(
                        value: 'apartments',
                        child: Text('Apartamenty'),
                      ),
                      DropdownMenuItem(
                        value: 'statistics',
                        child: Text('Statystyki'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusMessage,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          // Paginacja
          if (_selectedDataType != 'statistics')
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _currentPage > 1
                          ? () {
                              setState(() => _currentPage--);
                              _loadData();
                            }
                          : null,
                      child: const Text('Poprzednia'),
                    ),
                    Text('Strona $_currentPage'),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _currentPage++);
                        _loadData();
                      },
                      child: const Text('Następna'),
                    ),
                  ],
                ),
              ),
            ),

          // Zawartość
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedDataType == 'statistics'
                ? _buildStatisticsView()
                : _buildDataList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsView() {
    if (_statistics == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Podsumowanie
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🏛️ PODSUMOWANIE SYSTEMU',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Łączna liczba produktów: ${_statistics!['summary']['totalCount']}',
                  ),
                  Text(
                    'Łączna wartość: ${(_statistics!['summary']['totalValue'] as double).toStringAsFixed(2)} PLN',
                  ),
                  Text(
                    'Łączne inwestycje: ${(_statistics!['summary']['totalInvestmentAmount'] as double).toStringAsFixed(2)} PLN',
                  ),
                ],
              ),
            ),
          ),

          // Statystyki poszczególnych typów
          ..._statistics!.entries.where((entry) => entry.key != 'summary').map((
            entry,
          ) {
            final data = entry.value as Map<String, dynamic>;
            final icon =
                {
                  'bonds': '📄',
                  'shares': '📈',
                  'loans': '💰',
                  'apartments': '🏠',
                }[entry.key] ??
                '📊';

            final name =
                {
                  'bonds': 'OBLIGACJE',
                  'shares': 'UDZIAŁY',
                  'loans': 'POŻYCZKI',
                  'apartments': 'APARTAMENTY',
                }[entry.key] ??
                entry.key.toUpperCase();

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$icon $name',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Liczba: ${data['count']}'),
                    Text(
                      'Wartość: ${(data['totalValue'] as double).toStringAsFixed(2)} PLN',
                    ),
                    Text(
                      'Średnia: ${(data['averageValue'] as double).toStringAsFixed(2)} PLN',
                    ),
                    if (data['totalArea'] != null)
                      Text(
                        'Łączna powierzchnia: ${(data['totalArea'] as double).toStringAsFixed(2)} m²',
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDataList() {
    if (_currentData.isEmpty) {
      return const Center(child: Text('Brak danych do wyświetlenia'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _currentData.length,
      itemBuilder: (context, index) {
        final item = _currentData[index];
        return Card(
          child: ListTile(
            title: Text(_getItemTitle(item)),
            subtitle: Text(_getItemSubtitle(item)),
            trailing: Text(_getItemValue(item)),
            dense: true,
          ),
        );
      },
    );
  }

  String _getItemTitle(dynamic item) {
    if (item is Bond) return 'Obligacja: ${item.productType}';
    if (item is Share) return 'Udziały: ${item.productType}';
    if (item is Loan) return 'Pożyczka: ${item.loanNumber ?? 'N/A'}';
    if (item is Apartment) return 'Apartament: ${item.apartmentNumber}';
    return 'Nieznany typ';
  }

  String _getItemSubtitle(dynamic item) {
    if (item is Bond) return 'ID: ${item.id}';
    if (item is Share) return 'Udziałów: ${item.sharesCount}';
    if (item is Loan) return 'Pożyczkobiorca: ${item.borrower ?? 'N/A'}';
    if (item is Apartment) return '${item.area}m² | ${item.roomCount} pokoje';
    return '';
  }

  String _getItemValue(dynamic item) {
    if (item is Bond) return '${item.remainingCapital.toStringAsFixed(2)} PLN';
    if (item is Share) return '${item.remainingCapital.toStringAsFixed(2)} PLN';
    if (item is Loan) return '${item.remainingCapital.toStringAsFixed(2)} PLN';
    if (item is Apartment)
      return '${item.investmentAmount.toStringAsFixed(2)} PLN';
    return '';
  }
}
