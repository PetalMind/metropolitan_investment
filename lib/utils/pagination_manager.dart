import '../models/investor_summary.dart';

/// 📄 MANAGER PAGINACJI
/// Zawiera logikę paginacji i zarządzania stronami danych
class PaginationManager {
  // Stan paginacji
  int currentPage = 0;
  int pageSize = 250; // Limit na 250
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  bool isLoadingMore = false;

  // Dane
  List<InvestorSummary> allData = [];
  List<InvestorSummary> filteredData = [];

  /// Ustawia nowe dane i resetuje paginację
  void setData(List<InvestorSummary> data) {
    allData = data;
    filteredData = data;
    resetPagination();
  }

  /// Ustawia przefiltrowane dane i resetuje paginację
  void setFilteredData(List<InvestorSummary> data) {
    filteredData = data;
    resetPagination();
  }

  /// Resetuje paginację do pierwszej strony
  void resetPagination() {
    currentPage = 0;
    _updatePaginationState();
  }

  /// Pobiera dane dla aktualnej strony
  List<InvestorSummary> getCurrentPageData() {
    final startIndex = currentPage * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, filteredData.length);

    if (startIndex >= filteredData.length) return [];

    return filteredData.sublist(startIndex, endIndex);
  }

  /// Przechodzi do następnej strony
  bool goToNextPage() {
    if (!hasNextPage) return false;

    currentPage++;
    _updatePaginationState();
    return true;
  }

  /// Przechodzi do poprzedniej strony
  bool goToPreviousPage() {
    if (!hasPreviousPage) return false;

    currentPage--;
    _updatePaginationState();
    return true;
  }

  /// Przechodzi do konkretnej strony
  bool goToPage(int pageNumber) {
    final totalPages = getTotalPages();

    if (pageNumber < 0 || pageNumber >= totalPages) {
      return false; // Strona poza zakresem
    }

    currentPage = pageNumber;
    _updatePaginationState();
    return true;
  }

  /// Dodaje więcej danych do istniejących (infinite scroll)
  void addMoreData(List<InvestorSummary> moreData) {
    filteredData.addAll(moreData);
    _updatePaginationState();
  }

  /// Sprawdza czy można załadować więcej danych
  bool canLoadMore() {
    return hasNextPage && !isLoadingMore;
  }

  /// Ustawia stan ładowania
  void setLoadingMore(bool loading) {
    isLoadingMore = loading;
  }

  /// Zwraca całkowitą liczbę stron
  int getTotalPages() {
    if (filteredData.isEmpty) return 1;
    return (filteredData.length / pageSize).ceil();
  }

  /// Zwraca informacje o aktualnej stronie
  String getPageInfo() {
    final totalPages = getTotalPages();
    return 'Strona ${currentPage + 1} z $totalPages';
  }

  /// Zwraca zakres elementów na aktualnej stronie
  String getItemsRange() {
    if (filteredData.isEmpty) return '0-0 z 0';

    final startIndex = currentPage * pageSize + 1;
    final endIndex = ((currentPage + 1) * pageSize).clamp(
      1,
      filteredData.length,
    );

    return '$startIndex-$endIndex z ${filteredData.length}';
  }

  /// Sprawdza czy aktualna strona jest pierwsza
  bool get isFirstPage => currentPage == 0;

  /// Sprawdza czy aktualna strona jest ostatnia
  bool get isLastPage => currentPage >= getTotalPages() - 1;

  /// Zwraca numery stron do wyświetlenia w paginatorze
  List<int> getVisiblePageNumbers({int maxVisible = 7}) {
    final totalPages = getTotalPages();

    if (totalPages <= maxVisible) {
      return List.generate(totalPages, (index) => index);
    }

    final halfVisible = maxVisible ~/ 2;
    int startPage = (currentPage - halfVisible).clamp(
      0,
      totalPages - maxVisible,
    );
    int endPage = (startPage + maxVisible).clamp(maxVisible, totalPages);

    // Dostosuj start jeśli end został ograniczony
    if (endPage == totalPages) {
      startPage = (totalPages - maxVisible).clamp(0, totalPages - maxVisible);
    }

    return List.generate(endPage - startPage, (index) => startPage + index);
  }

  /// Aktualizuje stan paginacji na podstawie aktualnych danych
  void _updatePaginationState() {
    final totalPages = getTotalPages();
    hasPreviousPage = currentPage > 0;
    hasNextPage = currentPage < totalPages - 1;
  }

  /// Tworzy kopię managera z nowymi ustawieniami
  PaginationManager copyWith({
    int? currentPage,
    int? pageSize,
    List<InvestorSummary>? allData,
    List<InvestorSummary>? filteredData,
  }) {
    final manager = PaginationManager();
    manager.currentPage = currentPage ?? this.currentPage;
    manager.pageSize = pageSize ?? this.pageSize;
    manager.allData = allData ?? List.from(this.allData);
    manager.filteredData = filteredData ?? List.from(this.filteredData);
    manager._updatePaginationState();
    return manager;
  }

  /// Debug info
  void logPaginationState() {
    print('📄 [Pagination State]');
    print('   Current Page: ${currentPage + 1}/${getTotalPages()}');
    print('   Page Size: $pageSize');
    print('   Total Items: ${filteredData.length}');
    print('   Has Next: $hasNextPage');
    print('   Has Previous: $hasPreviousPage');
    print('   Items Range: ${getItemsRange()}');
  }
}
