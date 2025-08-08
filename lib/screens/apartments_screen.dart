import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/apartment.dart';
import '../services/firebase_functions_data_service.dart';
import '../widgets/custom_loading_widget.dart';
import '../utils/currency_formatter.dart';

class ApartmentsScreen extends StatefulWidget {
  const ApartmentsScreen({super.key});

  @override
  State<ApartmentsScreen> createState() => _ApartmentsScreenState();
}

class _ApartmentsScreenState extends State<ApartmentsScreen> {
  final FirebaseFunctionsDataService _dataService = FirebaseFunctionsDataService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Apartment> _apartments = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  
  // Filtering
  ApartmentStatus? _selectedStatus;
  String? _selectedProjectName;
  String? _selectedDeveloper;
  double? _minArea;
  double? _maxArea;
  int? _roomCount;
  
  // Pagination
  int _currentPage = 1;
  static const int _pageSize = 100;
  bool _hasMoreData = true;
  int _totalApartments = 0;

  // Sorting
  String _sortBy = 'created_at';
  String _sortDirection = 'desc';

  @override
  void initState() {
    super.initState();
    _loadApartments();
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
      _loadMoreApartments();
    }
  }

  Future<void> _loadApartments({bool isRefresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      if (isRefresh) {
        _apartments.clear();
        _currentPage = 1;
      }
    });

    try {
      final result = await _dataService.getApartments(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
        status: _selectedStatus?.name,
        projectName: _selectedProjectName,
        developer: _selectedDeveloper,
        minArea: _minArea,
        maxArea: _maxArea,
        roomCount: _roomCount,
        sortBy: _sortBy,
        sortDirection: _sortDirection,
        forceRefresh: isRefresh,
      );

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _apartments = result.apartments;
          } else {
            _apartments.addAll(result.apartments);
          }
          _hasMoreData = result.hasNextPage;
          _totalApartments = result.total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Błąd podczas ładowania apartamentów: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreApartments() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;
      final result = await _dataService.getApartments(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
        status: _selectedStatus?.name,
        projectName: _selectedProjectName,
        developer: _selectedDeveloper,
        minArea: _minArea,
        maxArea: _maxArea,
        roomCount: _roomCount,
        sortBy: _sortBy,
        sortDirection: _sortDirection,
      );

      if (mounted) {
        setState(() {
          _apartments.addAll(result.apartments);
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
    _loadApartments(isRefresh: true);
  }

  void _onFilterChanged() {
    _currentPage = 1;
    _loadApartments(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apartamenty'),
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
                  case 'area_desc':
                    _sortBy = 'area';
                    _sortDirection = 'desc';
                    break;
                  case 'area_asc':
                    _sortBy = 'area';
                    _sortDirection = 'asc';
                    break;
                  case 'price_desc':
                    _sortBy = 'pricePerSquareMeter';
                    _sortDirection = 'desc';
                    break;
                  case 'price_asc':
                    _sortBy = 'pricePerSquareMeter';
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
                value: 'area_desc',
                child: Text('Największa powierzchnia'),
              ),
              const PopupMenuItem(
                value: 'area_asc',
                child: Text('Najmniejsza powierzchnia'),
              ),
              const PopupMenuItem(
                value: 'price_desc',
                child: Text('Najwyższa cena za m²'),
              ),
              const PopupMenuItem(
                value: 'price_asc',
                child: Text('Najniższa cena za m²'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadApartments(isRefresh: true),
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
                    hintText: 'Szukaj apartamentów...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: _onSearch,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<ApartmentStatus>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Wszystkie')),
                          ...ApartmentStatus.values.map((status) =>
                            DropdownMenuItem(
                              value: status,
                              child: Text(_getStatusName(status)),
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
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Liczba pokoi',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _roomCount = int.tryParse(value);
                          _onFilterChanged();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Min. powierzchnia (m²)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _minArea = double.tryParse(value);
                          _onFilterChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Max. powierzchnia (m²)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _maxArea = double.tryParse(value);
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
          if (_totalApartments > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Znaleziono $_totalApartments apartamentów (wyświetlono ${_apartments.length})',
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
    if (_isLoading && _apartments.isEmpty) {
      return const Center(
        child: CustomLoadingWidget(
          message: 'Ładowanie apartamentów z Firebase Functions...',
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
              onPressed: () => _loadApartments(isRefresh: true),
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    if (_apartments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apartment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Brak apartamentów spełniających kryteria'),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _apartments.length + (_hasMoreData && _apartments.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _apartments.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _buildApartmentCard(_apartments[index]);
      },
    );
  }

  Widget _buildApartmentCard(Apartment apartment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.secondaryGold,
          child: const Icon(Icons.apartment, color: Colors.white),
        ),
        title: Text(
          '${apartment.apartmentNumber} - ${apartment.building}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${apartment.area.toStringAsFixed(1)} m² • ${apartment.roomCount} pokoi'),
            Text('Piętro: ${apartment.floor} • Typ: ${_getApartmentTypeName(apartment.apartmentType)}'),
            if (apartment.pricePerSquareMeter > 0)
              Text('Cena za m²: ${CurrencyFormatter.formatCurrency(apartment.pricePerSquareMeter)}'),
            Text('Status: ${_getStatusName(apartment.status)}'),
            if (apartment.projectName != null)
              Text('Projekt: ${apartment.projectName}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.formatCurrency(apartment.investmentAmount),
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
        onTap: () => _showApartmentDetails(apartment),
      ),
    );
  }

  void _showApartmentDetails(Apartment apartment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${apartment.apartmentNumber} - ${apartment.building}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Kwota inwestycji', CurrencyFormatter.formatCurrency(apartment.investmentAmount)),
              _buildDetailRow('Numer apartamentu', apartment.apartmentNumber),
              _buildDetailRow('Budynek', apartment.building),
              _buildDetailRow('Adres', apartment.address),
              _buildDetailRow('Powierzchnia', '${apartment.area.toStringAsFixed(1)} m²'),
              _buildDetailRow('Liczba pokoi', apartment.roomCount.toString()),
              _buildDetailRow('Piętro', apartment.floor.toString()),
              _buildDetailRow('Typ', _getApartmentTypeName(apartment.apartmentType)),
              _buildDetailRow('Status', _getStatusName(apartment.status)),
              if (apartment.pricePerSquareMeter > 0)
                _buildDetailRow('Cena za m²', CurrencyFormatter.formatCurrency(apartment.pricePerSquareMeter)),
              if (apartment.deliveryDate != null)
                _buildDetailRow('Data wydania', apartment.deliveryDate!.toString().split(' ')[0]),
              if (apartment.developer != null)
                _buildDetailRow('Deweloper', apartment.developer!),
              if (apartment.projectName != null)
                _buildDetailRow('Projekt', apartment.projectName!),
              _buildDetailRow('Balkon', apartment.hasBalcony ? 'Tak' : 'Nie'),
              _buildDetailRow('Miejsce parkingowe', apartment.hasParkingSpace ? 'Tak' : 'Nie'),
              _buildDetailRow('Komórka lokatorska', apartment.hasStorage ? 'Tak' : 'Nie'),
              if (apartment.capitalForRestructuring != null && apartment.capitalForRestructuring! > 0)
                _buildDetailRow('Kapitał na restrukturyzację', CurrencyFormatter.formatCurrency(apartment.capitalForRestructuring!)),
              if (apartment.capitalSecuredByRealEstate != null && apartment.capitalSecuredByRealEstate! > 0)
                _buildDetailRow('Kapitał zabezpieczony nieruchomością', CurrencyFormatter.formatCurrency(apartment.capitalSecuredByRealEstate!)),
              _buildDetailRow('Data utworzenia', apartment.createdAt.toString().split(' ')[0]),
              _buildDetailRow('Źródło danych', apartment.sourceFile),
              if (apartment.additionalInfo.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Dodatkowe informacje:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...apartment.additionalInfo.entries.map(
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

  String _getStatusName(ApartmentStatus status) {
    switch (status) {
      case ApartmentStatus.available:
        return 'Dostępny';
      case ApartmentStatus.sold:
        return 'Sprzedany';
      case ApartmentStatus.reserved:
        return 'Zarezerwowany';
      case ApartmentStatus.underConstruction:
        return 'W budowie';
      case ApartmentStatus.ready:
        return 'Gotowy';
    }
  }

  String _getApartmentTypeName(ApartmentType type) {
    switch (type) {
      case ApartmentType.studio:
        return 'Kawalerka';
      case ApartmentType.apartment2Room:
        return '2 pokoje';
      case ApartmentType.apartment3Room:
        return '3 pokoje';
      case ApartmentType.apartment4Room:
        return '4 pokoje';
      case ApartmentType.penthouse:
        return 'Penthouse';
      case ApartmentType.other:
        return 'Inne';
    }
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