import '../models/client.dart';
import '../models/investor_summary.dart';

/// 🔧 MANAGER SORTOWANIA I FILTROWANIA INWESTORÓW
/// Zawiera logikę sortowania i filtrowania wydzieloną z głównego ekranu
class InvestorSortFilterManager {
  // Konfiguracja filtrów
  VotingStatus? selectedVotingStatus;
  ClientType? selectedClientType;
  bool includeInactive = false;
  bool showOnlyWithUnviableInvestments = false;

  // Konfiguracja sortowania
  String sortBy = 'totalValue';
  bool sortAscending = false;

  // Zapytania tekstowe
  String searchQuery = '';
  String companyQuery = '';
  double? minAmount;
  double? maxAmount;

  /// Sortuje listę inwestorów według aktualnych ustawień
  void sortInvestors(
    List<InvestorSummary> investors, {
    double totalViableCapital = 0.0,
    double majorityThreshold = 51.0,
  }) {
    investors.sort((a, b) {
      late int comparison;

      switch (sortBy) {
        case 'totalValue':
          comparison = a.totalValue.compareTo(b.totalValue);
          break;
        case 'name':
          comparison = a.client.name.compareTo(b.client.name);
          break;
        case 'investmentCount':
          comparison = a.investmentCount.compareTo(b.investmentCount);
          break;
        case 'viableCapital':
          comparison = a.viableRemainingCapital.compareTo(
            b.viableRemainingCapital,
          );
          break;
        case 'majority':
          // Sortowanie według odległości do progu większości
          if (totalViableCapital > 0) {
            final aMajorityDistance =
                (a.viableRemainingCapital / totalViableCapital * 100 -
                        majorityThreshold)
                    .abs();
            final bMajorityDistance =
                (b.viableRemainingCapital / totalViableCapital * 100 -
                        majorityThreshold)
                    .abs();
            comparison = aMajorityDistance.compareTo(bMajorityDistance);
          } else {
            comparison = a.totalValue.compareTo(b.totalValue);
          }
          break;
        case 'votingStatus':
          final aStatusOrder = _getVotingStatusOrder(a.client.votingStatus);
          final bStatusOrder = _getVotingStatusOrder(b.client.votingStatus);
          comparison = aStatusOrder.compareTo(bStatusOrder);
          break;
        default:
          comparison = a.totalValue.compareTo(b.totalValue);
      }

      return sortAscending ? comparison : -comparison;
    });
  }

  /// Filtruje listę inwestorów według aktualnych kryteriów
  List<InvestorSummary> filterInvestors(List<InvestorSummary> investors) {
    return investors.where((investor) {
      // Filtr tekstowy (name, company, email)
      final searchLower = searchQuery.toLowerCase();
      final matchesSearch =
          searchLower.isEmpty ||
          investor.client.name.toLowerCase().contains(searchLower) ||
          (investor.client.companyName?.toLowerCase().contains(searchLower) ??
              false) ||
          investor.client.email.toLowerCase().contains(searchLower);

      // Filtr kwoty (range)
      final matchesAmount =
          (minAmount == null || investor.totalValue >= minAmount!) &&
          (maxAmount == null || investor.totalValue <= maxAmount!);

      // Filtr firmy/produktu
      final companyLower = companyQuery.toLowerCase();
      final matchesCompany =
          companyLower.isEmpty ||
          investor.investmentsByCompany.keys.any(
            (company) => company.toLowerCase().contains(companyLower),
          ) ||
          investor.investments.any(
            (investment) =>
                investment.productName.toLowerCase().contains(companyLower),
          );

      // Filtr statusu głosowania
      final matchesVoting =
          selectedVotingStatus == null ||
          investor.client.votingStatus == selectedVotingStatus;

      // Filtr typu klienta
      final matchesType =
          selectedClientType == null ||
          investor.client.type == selectedClientType;

      // Filtr niewykonalnych inwestycji
      final matchesUnviable =
          !showOnlyWithUnviableInvestments || investor.hasUnviableInvestments;

      // Filtr aktywności
      final matchesActive = includeInactive || investor.client.isActive;

      return matchesSearch &&
          matchesAmount &&
          matchesCompany &&
          matchesVoting &&
          matchesType &&
          matchesUnviable &&
          matchesActive;
    }).toList();
  }

  /// Resetuje wszystkie filtry do wartości domyślnych
  void resetFilters() {
    selectedVotingStatus = null;
    selectedClientType = null;
    includeInactive = false;
    showOnlyWithUnviableInvestments = false;
    sortBy = 'totalValue';
    sortAscending = false;
    searchQuery = '';
    companyQuery = '';
    minAmount = null;
    maxAmount = null;
  }

  /// Zmienia parametry sortowania
  void changeSortOrder(String newSortBy) {
    if (sortBy == newSortBy) {
      sortAscending = !sortAscending;
    } else {
      sortBy = newSortBy;
      sortAscending = false;
    }
  }

  /// Sprawdza czy jakiekolwiek filtry są aktywne
  bool get hasActiveFilters {
    return selectedVotingStatus != null ||
        selectedClientType != null ||
        searchQuery.isNotEmpty ||
        companyQuery.isNotEmpty ||
        minAmount != null ||
        maxAmount != null ||
        showOnlyWithUnviableInvestments ||
        includeInactive;
  }

  /// Zwraca kolejność sortowania dla statusu głosowania
  int _getVotingStatusOrder(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return 1; // TAK - najwyższy priorytet
      case VotingStatus.no:
        return 2; // NIE
      case VotingStatus.undecided:
        return 3; // NIEZDECYDOWANY
      case VotingStatus.abstain:
        return 4; // WSTRZYMUJE - najniższy priorytet
    }
  }

  /// Tworzy kopię managera z nowymi ustawieniami
  InvestorSortFilterManager copyWith({
    VotingStatus? selectedVotingStatus,
    ClientType? selectedClientType,
    bool? includeInactive,
    bool? showOnlyWithUnviableInvestments,
    String? sortBy,
    bool? sortAscending,
    String? searchQuery,
    String? companyQuery,
    double? minAmount,
    double? maxAmount,
  }) {
    final manager = InvestorSortFilterManager();
    manager.selectedVotingStatus =
        selectedVotingStatus ?? this.selectedVotingStatus;
    manager.selectedClientType = selectedClientType ?? this.selectedClientType;
    manager.includeInactive = includeInactive ?? this.includeInactive;
    manager.showOnlyWithUnviableInvestments =
        showOnlyWithUnviableInvestments ?? this.showOnlyWithUnviableInvestments;
    manager.sortBy = sortBy ?? this.sortBy;
    manager.sortAscending = sortAscending ?? this.sortAscending;
    manager.searchQuery = searchQuery ?? this.searchQuery;
    manager.companyQuery = companyQuery ?? this.companyQuery;
    manager.minAmount = minAmount ?? this.minAmount;
    manager.maxAmount = maxAmount ?? this.maxAmount;
    return manager;
  }
}
