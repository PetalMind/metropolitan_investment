import 'package:flutter/material.dart';
import '../../models_and_services.dart';

/// Serwis zarządzania stanem dla analityki inwestorów
/// Używa ChangeNotifier do reaktywnego zarządzania stanem UI
class InvestorAnalyticsStateService extends ChangeNotifier {
  final InvestorAnalyticsService _analyticsService = InvestorAnalyticsService();

  // Kontrola lifecycle
  bool _disposed = false;

  // Stan danych
  List<InvestorSummary> _allInvestors = [];
  List<InvestorSummary> _filteredInvestors = [];
  MajorityControlAnalysis? _majorityControlAnalysis;
  bool _isLoading = false;
  String? _error;

  // Stan filtrów
  String _searchQuery = '';
  double? _minAmount;
  double? _maxAmount;
  String _companyFilter = '';
  VotingStatus? _selectedVotingStatus;
  ClientType? _selectedClientType;
  bool _includeInactive = false;
  bool _showOnlyWithUnviableInvestments = false;

  // Stan sortowania
  String _sortBy = 'totalValue';
  bool _sortAscending = false;

  // Stan paginacji
  int _currentPage = 0;
  int _pageSize = 20;
  bool _hasNextPage = false;
  bool _hasPreviousPage = false;

  // Stan widoku
  String _currentView = 'list'; // 'list', 'cards', 'grid'

  // Gettery
  List<InvestorSummary> get allInvestors => _allInvestors;
  List<InvestorSummary> get filteredInvestors => _filteredInvestors;
  List<InvestorSummary> get currentPageData {
    final startIndex = _currentPage * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(
      0,
      _filteredInvestors.length,
    );
    return _filteredInvestors.sublist(startIndex, endIndex);
  }

  MajorityControlAnalysis? get majorityControlAnalysis =>
      _majorityControlAnalysis;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get searchQuery => _searchQuery;
  double? get minAmount => _minAmount;
  double? get maxAmount => _maxAmount;
  String get companyFilter => _companyFilter;
  VotingStatus? get selectedVotingStatus => _selectedVotingStatus;
  ClientType? get selectedClientType => _selectedClientType;
  bool get includeInactive => _includeInactive;
  bool get showOnlyWithUnviableInvestments => _showOnlyWithUnviableInvestments;

  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  bool get hasNextPage => _hasNextPage;
  bool get hasPreviousPage => _hasPreviousPage;
  int get totalPages => (_filteredInvestors.length / _pageSize)
      .ceil()
      .clamp(1, double.infinity)
      .toInt();

  String get currentView => _currentView;

  double get totalPortfolioValue {
    return _allInvestors.fold<double>(0.0, (sum, inv) => sum + inv.totalValue);
  }

  /// Ładuje dane inwestorów
  Future<void> loadInvestorData() async {
    _setLoading(true);

    try {
      print('🚀 [InvestorState] Ładowanie danych inwestorów...');

      // Ładuj wszystkich inwestorów
      final allInvestors = await _analyticsService.getAllInvestorsForAnalysis(
        includeInactive: _includeInactive,
      );

      // Pobierz analizę kontroli większościowej
      final majorityAnalysis = await _analyticsService.analyzeMajorityControl(
        includeInactive: _includeInactive,
      );

      // Sortuj dane
      _sortInvestors(allInvestors);

      _allInvestors = allInvestors;
      _majorityControlAnalysis = majorityAnalysis;

      // Zastosuj filtry
      _applyFiltersInternal();

      print('✅ [InvestorState] Załadowano ${allInvestors.length} inwestorów');
    } catch (e) {
      print('❌ [InvestorState] Błąd ładowania: $e');
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Aktualizuje filtr wyszukiwania
  void updateSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applyFilters();
    }
  }

  /// Aktualizuje filtry kwot
  void updateAmountFilters(double? minAmount, double? maxAmount) {
    if (_minAmount != minAmount || _maxAmount != maxAmount) {
      _minAmount = minAmount;
      _maxAmount = maxAmount;
      _applyFilters();
    }
  }

  /// Aktualizuje filtr firmy
  void updateCompanyFilter(String filter) {
    if (_companyFilter != filter) {
      _companyFilter = filter;
      _applyFilters();
    }
  }

  /// Aktualizuje status głosowania
  void updateVotingStatus(VotingStatus? status) {
    if (_selectedVotingStatus != status) {
      _selectedVotingStatus = status;
      _applyFilters();
    }
  }

  /// Aktualizuje typ klienta
  void updateClientType(ClientType? type) {
    if (_selectedClientType != type) {
      _selectedClientType = type;
      _applyFilters();
    }
  }

  /// Przełącza pokazywanie nieaktywnych
  void toggleIncludeInactive() {
    _includeInactive = !_includeInactive;
    loadInvestorData(); // Przeładuj dane
  }

  /// Przełącza pokazywanie tylko niewykonalnych
  void toggleShowOnlyUnviable() {
    _showOnlyWithUnviableInvestments = !_showOnlyWithUnviableInvestments;
    _applyFilters();
  }

  /// Zmienia sortowanie
  void changeSortOrder(String newSortBy) {
    if (_sortBy == newSortBy) {
      _sortAscending = !_sortAscending;
    } else {
      _sortBy = newSortBy;
      _sortAscending = false;
    }

    _sortInvestors(_allInvestors);
    _applyFilters();
  }

  /// Resetuje wszystkie filtry
  void resetFilters() {
    _searchQuery = '';
    _minAmount = null;
    _maxAmount = null;
    _companyFilter = '';
    _selectedVotingStatus = null;
    _selectedClientType = null;
    _showOnlyWithUnviableInvestments = false;
    _sortBy = 'totalValue';
    _sortAscending = false;

    _sortInvestors(_allInvestors);
    _applyFilters();
  }

  /// Zmienia stronę
  void changePage(int pageNumber) {
    final totalPages = this.totalPages;

    if (pageNumber >= 0 && pageNumber < totalPages) {
      _currentPage = pageNumber;
      _updatePaginationState();
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  /// Zmienia rozmiar strony
  void changePageSize(int newPageSize) {
    if (_pageSize != newPageSize) {
      _pageSize = newPageSize;
      _currentPage = 0; // Reset do pierwszej strony
      _updatePaginationState();
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  /// Zmienia widok
  void changeView(String newView) {
    if (_currentView != newView) {
      _currentView = newView;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  /// Prywatne metody

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _error = null;
    }
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _sortInvestors(List<InvestorSummary> investors) {
    investors.sort((a, b) {
      late int comparison;

      switch (_sortBy) {
        case 'totalValue':
          comparison = a.totalValue.compareTo(b.totalValue);
          break;
        case 'name':
          comparison = a.client.name.compareTo(b.client.name);
          break;
        case 'investmentCount':
          comparison = a.investmentCount.compareTo(b.investmentCount);
          break;
        default:
          comparison = a.totalValue.compareTo(b.totalValue);
      }

      return _sortAscending ? comparison : -comparison;
    });
  }

  void _applyFilters() {
    _applyFiltersInternal();
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _applyFiltersInternal() {
    var filtered = _allInvestors.where((investor) {
      // Filtr tekstowy
      final matchesSearch =
          _searchQuery.isEmpty ||
          investor.client.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (investor.client.companyName?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false) ||
          investor.client.email.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      // Filtr kwoty
      final matchesAmount =
          (_minAmount == null || investor.totalValue >= _minAmount!) &&
          (_maxAmount == null || investor.totalValue <= _maxAmount!);

      // Filtr firmy
      final matchesCompany =
          _companyFilter.isEmpty ||
          investor.investmentsByCompany.keys.any(
            (company) =>
                company.toLowerCase().contains(_companyFilter.toLowerCase()),
          ) ||
          investor.investments.any(
            (inv) => inv.productName.toLowerCase().contains(
              _companyFilter.toLowerCase(),
            ),
          );

      // Filtr statusu głosowania
      final matchesVoting =
          _selectedVotingStatus == null ||
          investor.client.votingStatus == _selectedVotingStatus;

      // Filtr typu klienta
      final matchesType =
          _selectedClientType == null ||
          investor.client.type == _selectedClientType;

      // Filtr niewykonalnych
      final matchesUnviable =
          !_showOnlyWithUnviableInvestments || investor.hasUnviableInvestments;

      return matchesSearch &&
          matchesAmount &&
          matchesCompany &&
          matchesVoting &&
          matchesType &&
          matchesUnviable;
    }).toList();

    // Sortuj przefiltrowane dane
    _sortInvestors(filtered);

    _filteredInvestors = filtered;
    _currentPage = 0; // Reset paginacji
    _updatePaginationState();

    print(
      '🔍 [InvestorState] Filtrowanie: ${_allInvestors.length} -> ${_filteredInvestors.length} inwestorów',
    );
  }

  void _updatePaginationState() {
    final totalPages = this.totalPages;
    _hasPreviousPage = _currentPage > 0;
    _hasNextPage = _currentPage < totalPages - 1;
  }

  /// Aktualizuje inwestora na liście
  void updateInvestorInList(InvestorSummary updatedInvestor) {
    // Znajdź i zaktualizuj na głównej liście
    final allIndex = _allInvestors.indexWhere(
      (investor) => investor.client.id == updatedInvestor.client.id,
    );
    if (allIndex != -1) {
      _allInvestors[allIndex] = updatedInvestor;
    }

    // Znajdź i zaktualizuj na przefiltrowanej liście
    final filteredIndex = _filteredInvestors.indexWhere(
      (investor) => investor.client.id == updatedInvestor.client.id,
    );
    if (filteredIndex != -1) {
      _filteredInvestors[filteredIndex] = updatedInvestor;
    }

    notifyListeners();
  }

  /// Pobiera inwestorów po IDs (do generatora maili)
  Future<List<InvestorSummary>> getInvestorsByClientIds(
    List<String> clientIds,
  ) {
    return _analyticsService.getInvestorsByClientIds(clientIds);
  }

  /// Aktualizuje notatki inwestora
  Future<void> updateInvestorNotes(String clientId, String notes) {
    return _analyticsService.updateInvestorNotes(clientId, notes);
  }

  /// Aktualizuje status głosowania
  Future<void> updateVotingStatusForInvestor(
    String clientId,
    VotingStatus status,
  ) {
    return _analyticsService.updateVotingStatus(clientId, status);
  }

  /// Aktualizuje kolor inwestora
  Future<void> updateInvestorColor(String clientId, String colorCode) {
    return _analyticsService.updateInvestorColor(clientId, colorCode);
  }

  /// Oznacza inwestycje jako niewykonalne
  Future<void> markInvestmentsAsUnviable(
    String clientId,
    List<String> investmentIds,
  ) {
    return _analyticsService.markInvestmentsAsUnviable(clientId, investmentIds);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
