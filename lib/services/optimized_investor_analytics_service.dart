import '../models/client.dart';
import '../models/investor_summary.dart';
import 'base_service.dart';
import 'client_service.dart';
import 'optimized_investment_service.dart';

/// Zoptymalizowany serwis analityki inwestorów wykorzystujący indeksy Firestore
/// zgodnie z OPTIMIZATION_IMPLEMENTATION_REPORT.md
class OptimizedInvestorAnalyticsService extends BaseService {
  final ClientService _clientService = ClientService();
  final OptimizedInvestmentService _investmentService =
      OptimizedInvestmentService();

  // Cache z ekspiracja
  Map<String, dynamic>? _analyticsCache;
  DateTime? _cacheTimestamp;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// **OPTYMALIZACJA 1:** Pobiera inwestorów z wykorzystaniem indeksowanych zapytań
  /// Wykorzystuje indeksy: isActive + imie_nazwisko, votingStatus + updatedAt
  Future<InvestorAnalyticsResult> getOptimizedInvestorAnalytics({
    int page = 1,
    int pageSize = 250,
    String sortBy = 'viableCapital',
    bool sortAscending = false,
    bool includeInactive = false,
    VotingStatus? votingStatusFilter,
    ClientType? clientTypeFilter,
    bool showOnlyWithUnviableInvestments = false,
    String? searchQuery,
  }) async {
    final startTime = DateTime.now();
    print(
      '🚀 [OptimizedAnalytics] Rozpoczynam zoptymalizowane pobieranie danych...',
    );
    print(
      '📊 [OptimizedAnalytics] Parametry: strona=$page, rozmiar=$pageSize, sortowanie=$sortBy',
    );

    try {
      // **STEP 1:** Sprawdź cache
      if (_isAnalyticsCacheValid()) {
        print('⚡ [OptimizedAnalytics] Używam danych z cache');
        return _getFromCache(page, pageSize, sortBy, sortAscending);
      }

      // **STEP 2:** Pobierz klientów używając zoptymalizowanych zapytań
      List<Client> clients;

      if (votingStatusFilter != null) {
        // Wykorzystaj indeks: votingStatus + updatedAt
        print(
          '🎯 [OptimizedAnalytics] Filtrowanie po statusie głosowania: ${votingStatusFilter.name}',
        );
        final clientsStream = _clientService.getClientsByVotingStatus(
          votingStatusFilter,
          limit: 1000, // Zwiększony limit dla analizy
        );
        clients = await clientsStream.first;
      } else if (clientTypeFilter != null) {
        // Wykorzystaj indeks: type + imie_nazwisko
        print(
          '🎯 [OptimizedAnalytics] Filtrowanie po typie klienta: ${clientTypeFilter.name}',
        );
        final clientsStream = _clientService.getClientsByType(
          clientTypeFilter,
          limit: 1000,
        );
        clients = await clientsStream.first;
      } else if (!includeInactive) {
        // Wykorzystaj indeks: isActive + imie_nazwisko
        print('🎯 [OptimizedAnalytics] Pobieranie tylko aktywnych klientów');
        final clientsStream = _clientService.getActiveClients(limit: 1000);
        clients = await clientsStream.first;
      } else {
        // Fallback do wszystkich klientów
        print('🎯 [OptimizedAnalytics] Pobieranie wszystkich klientów');
        clients = await _clientService.getAllClients();
      }

      print('📋 [OptimizedAnalytics] Znaleziono ${clients.length} klientów');

      // **STEP 3:** Filtruj klientów po wyszukiwaniu (jeśli podano)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        clients = clients
            .where(
              (client) =>
                  client.name.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ) ||
                  client.email.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ),
            )
            .toList();
        print(
          '🔍 [OptimizedAnalytics] Po wyszukiwaniu: ${clients.length} klientów',
        );
      }

      // **STEP 4:** Batch pobieranie inwestycji dla klientów
      final List<InvestorSummary> investors = [];
      final clientBatches = _splitIntoBatches(
        clients,
        10,
      ); // 10 klientów na batch

      for (int i = 0; i < clientBatches.length; i++) {
        final batch = clientBatches[i];
        print(
          '📦 [OptimizedAnalytics] Przetwarzam batch ${i + 1}/${clientBatches.length} (${batch.length} klientów)',
        );

        final batchInvestors = await _processBatchInvestors(
          batch,
          showOnlyWithUnviableInvestments,
        );
        investors.addAll(batchInvestors);
      }

      print(
        '👥 [OptimizedAnalytics] Utworzono ${investors.length} podsumowań inwestorów',
      );

      // **STEP 5:** Sortowanie
      _sortInvestorsOptimized(investors, sortBy, sortAscending);

      // **STEP 6:** Oblicz statystyki całościowe
      final totalViableCapital = investors.fold<double>(
        0.0,
        (sum, investor) => sum + investor.viableRemainingCapital,
      );

      // **STEP 7:** Aktualizuj cache
      _updateAnalyticsCache(investors, totalViableCapital);

      // **STEP 8:** Zastosuj paginację
      final paginatedResult = _applyPagination(
        investors,
        page,
        pageSize,
        totalViableCapital,
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      print(
        '✅ [OptimizedAnalytics] Analiza zakończona w ${duration.inMilliseconds}ms',
      );
      print(
        '📊 [OptimizedAnalytics] Zwracam ${paginatedResult.investors.length} inwestorów ze strony $page',
      );

      return paginatedResult;
    } catch (e) {
      print('❌ [OptimizedAnalytics] Błąd: $e');
      logError('getOptimizedInvestorAnalytics', e);
      rethrow;
    }
  }

  /// **OPTYMALIZACJA 2:** Batch processing inwestorów z wykorzystaniem indeksów
  Future<List<InvestorSummary>> _processBatchInvestors(
    List<Client> clientBatch,
    bool showOnlyWithUnviableInvestments,
  ) async {
    final List<InvestorSummary> batchResults = [];

    // Pobierz inwestycje dla wszystkich klientów w batch równolegle
    final futures = clientBatch.map((client) async {
      try {
        // Wykorzystaj indeks: klient + data_podpisania
        final investmentsStream = _investmentService.getInvestmentsByClient(
          client.id,
          limit: 100, // Rozumny limit per klient
        );
        final investments = await investmentsStream.first;

        if (investments.isEmpty) return null;

        // Utwórz InvestorSummary
        final investorSummary = InvestorSummary.fromInvestments(
          client,
          investments,
        );

        // Filtruj według niepracujących inwestycji jeśli wymagane
        if (showOnlyWithUnviableInvestments) {
          final hasUnviableInvestments =
              investorSummary.totalValue >
              investorSummary.viableRemainingCapital;
          if (!hasUnviableInvestments) return null;
        }

        return investorSummary;
      } catch (e) {
        print('⚠️ [OptimizedAnalytics] Błąd dla klienta ${client.name}: $e');
        return null;
      }
    });

    final results = await Future.wait(futures);

    // Dodaj tylko niezerowe wyniki
    for (final result in results) {
      if (result != null) {
        batchResults.add(result);
      }
    }

    return batchResults;
  }

  /// **OPTYMALIZACJA 3:** Analiza kontroli większościowej z cache
  Future<MajorityControlAnalysis> analyzeMajorityControlOptimized({
    bool includeInactive = false,
    double controlThreshold = 51.0,
  }) async {
    print(
      '🎯 [OptimizedMajority] Rozpoczynam zoptymalizowaną analizę kontroli ${controlThreshold}%...',
    );

    try {
      // Pobierz dane używając zoptymalizowanej metody
      final result = await getOptimizedInvestorAnalytics(
        page: 1,
        pageSize: 10000, // Duży limit dla pełnej analizy
        sortBy: 'viableCapital',
        sortAscending: false,
        includeInactive: includeInactive,
      );

      final allInvestors = result.allInvestors ?? [];

      if (allInvestors.isEmpty) {
        return MajorityControlAnalysis.empty();
      }

      final totalViableCapital = result.totalViableCapital;
      final controlThresholdAmount =
          totalViableCapital * (controlThreshold / 100);

      print(
        '📊 [OptimizedMajority] Próg kontrolny: ${controlThresholdAmount.toStringAsFixed(2)} PLN',
      );

      // Znajdź grupę kontrolną
      final List<InvestorWithControlInfo> controlInvestors = [];
      final List<InvestorWithControlInfo> allInvestorsWithInfo = [];
      double cumulativeCapital = 0.0;

      for (final investor in allInvestors) {
        final previousCumulative = cumulativeCapital;
        cumulativeCapital += investor.viableRemainingCapital;

        final controlPercentage =
            (investor.viableRemainingCapital / totalViableCapital) * 100;
        final cumulativePercentage =
            (cumulativeCapital / totalViableCapital) * 100;

        final investorInfo = InvestorWithControlInfo(
          summary: investor,
          controlPercentage: controlPercentage,
          cumulativePercentage: cumulativePercentage,
          isInControlGroup: previousCumulative < controlThresholdAmount,
        );

        allInvestorsWithInfo.add(investorInfo);

        if (previousCumulative < controlThresholdAmount) {
          controlInvestors.add(investorInfo);
        }
      }

      final controlGroupCapital = controlInvestors.fold<double>(
        0.0,
        (sum, investor) => sum + investor.summary.viableRemainingCapital,
      );

      print(
        '✅ [OptimizedMajority] Grupa kontrolna: ${controlInvestors.length} inwestorów',
      );

      return MajorityControlAnalysis(
        allInvestors: allInvestorsWithInfo,
        controlGroupInvestors: controlInvestors,
        totalViableCapital: totalViableCapital,
        controlGroupCapital: controlGroupCapital,
        controlGroupCount: controlInvestors.length,
        controlThreshold: controlThreshold,
        analysisDate: DateTime.now(),
      );
    } catch (e) {
      print('❌ [OptimizedMajority] Błąd: $e');
      logError('analyzeMajorityControlOptimized', e);
      return MajorityControlAnalysis.empty();
    }
  }

  /// **OPTYMALIZACJA 4:** Rozkład głosowania z wykorzystaniem indeksów
  Future<VotingCapitalDistribution> analyzeVotingDistributionOptimized({
    bool includeInactive = false,
  }) async {
    print(
      '📊 [OptimizedVoting] Zoptymalizowana analiza rozkładu głosowania...',
    );

    try {
      final Map<VotingStatus, double> distribution = {};
      final Map<VotingStatus, int> counts = {};
      double totalCapital = 0.0;

      // Pobierz dane dla każdego statusu równolegle używając indeksów
      final futures = VotingStatus.values.map((status) async {
        try {
          // Wykorzystaj indeks: votingStatus + updatedAt
          final clientsStream = _clientService.getClientsByVotingStatus(
            status,
            limit: 1000,
          );
          final clients = await clientsStream.first;

          double statusCapital = 0.0;
          int statusCount = 0;

          // Batch processing dla każdego statusu
          final clientBatches = _splitIntoBatches(clients, 5);
          for (final batch in clientBatches) {
            final batchInvestors = await _processBatchInvestors(batch, false);
            for (final investor in batchInvestors) {
              statusCapital += investor.viableRemainingCapital;
              statusCount++;
            }
          }

          return {
            'status': status,
            'capital': statusCapital,
            'count': statusCount,
          };
        } catch (e) {
          print('⚠️ [OptimizedVoting] Błąd dla statusu ${status.name}: $e');
          return {'status': status, 'capital': 0.0, 'count': 0};
        }
      });

      final results = await Future.wait(futures);

      // Agreguj wyniki
      for (final result in results) {
        final status = result['status'] as VotingStatus;
        final capital = result['capital'] as double;
        final count = result['count'] as int;

        distribution[status] = capital;
        counts[status] = count;
        totalCapital += capital;
      }

      print(
        '✅ [OptimizedVoting] Całkowity kapitał: ${totalCapital.toStringAsFixed(2)} PLN',
      );

      return VotingCapitalDistribution(
        capitalByStatus: distribution,
        countByStatus: counts,
        totalCapital: totalCapital,
        totalInvestors: counts.values.fold(0, (sum, count) => sum + count),
        analysisDate: DateTime.now(),
      );
    } catch (e) {
      print('❌ [OptimizedVoting] Błąd: $e');
      logError('analyzeVotingDistributionOptimized', e);
      return VotingCapitalDistribution.empty();
    }
  }

  // --- UTILITY METHODS ---

  List<List<T>> _splitIntoBatches<T>(List<T> list, int batchSize) {
    final List<List<T>> batches = [];
    for (int i = 0; i < list.length; i += batchSize) {
      final end = (i + batchSize).clamp(0, list.length);
      batches.add(list.sublist(i, end));
    }
    return batches;
  }

  void _sortInvestorsOptimized(
    List<InvestorSummary> investors,
    String sortBy,
    bool ascending,
  ) {
    investors.sort((a, b) {
      late final int comparison;

      switch (sortBy) {
        case 'name':
          comparison = a.client.name.compareTo(b.client.name);
          break;
        case 'totalValue':
          comparison = a.totalValue.compareTo(b.totalValue);
          break;
        case 'viableCapital':
          comparison = a.viableRemainingCapital.compareTo(
            b.viableRemainingCapital,
          );
          break;
        case 'investmentCount':
          comparison = a.investments.length.compareTo(b.investments.length);
          break;
        case 'votingStatus':
          comparison = a.client.votingStatus.index.compareTo(
            b.client.votingStatus.index,
          );
          break;
        default:
          comparison = a.viableRemainingCapital.compareTo(
            b.viableRemainingCapital,
          );
      }

      return ascending ? comparison : -comparison;
    });
  }

  InvestorAnalyticsResult _applyPagination(
    List<InvestorSummary> allInvestors,
    int page,
    int pageSize,
    double totalViableCapital,
  ) {
    final totalCount = allInvestors.length;
    final totalPages = (totalCount / pageSize).ceil();
    final startIndex = (page - 1) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, totalCount);

    // Ogranicz do 250
    final paginatedInvestors = allInvestors.sublist(
      startIndex,
      endIndex.clamp(startIndex, startIndex + 250),
    );

    return InvestorAnalyticsResult(
      investors: paginatedInvestors,
      totalCount: totalCount,
      currentPage: page,
      totalPages: totalPages,
      pageSize: pageSize,
      totalViableCapital: totalViableCapital,
      hasNextPage: page < totalPages,
      hasPreviousPage: page > 1,
      allInvestors: allInvestors, // Dodaj wszystkich dla cache
    );
  }

  // --- CACHE MANAGEMENT ---

  bool _isAnalyticsCacheValid() {
    return _analyticsCache != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!).abs() < _cacheTimeout;
  }

  void _updateAnalyticsCache(
    List<InvestorSummary> investors,
    double totalCapital,
  ) {
    _analyticsCache = {'investors': investors, 'totalCapital': totalCapital};
    _cacheTimestamp = DateTime.now();
    print('💾 [OptimizedAnalytics] Cache zaktualizowany');
  }

  InvestorAnalyticsResult _getFromCache(
    int page,
    int pageSize,
    String sortBy,
    bool ascending,
  ) {
    final cachedInvestors = List<InvestorSummary>.from(
      _analyticsCache!['investors'],
    );
    final totalCapital = _analyticsCache!['totalCapital'] as double;

    // Ponowne sortowanie w cache
    _sortInvestorsOptimized(cachedInvestors, sortBy, ascending);

    return _applyPagination(cachedInvestors, page, pageSize, totalCapital);
  }

  @override
  void clearCache(String key) {
    _analyticsCache = null;
    _cacheTimestamp = null;
    print('🗑️ [OptimizedAnalytics] Cache wyczyszczony');
  }

  /// Aktualizuje status głosowania inwestora z invalidacją cache
  Future<void> updateVotingStatusOptimized(
    String clientId,
    VotingStatus newStatus,
  ) async {
    try {
      await _clientService.updateClientFields(clientId, {
        'votingStatus': newStatus.name,
      });
      clearCache('analytics');
      print('✅ [OptimizedAnalytics] Status głosowania zaktualizowany');
    } catch (e) {
      logError('updateVotingStatusOptimized', e);
      rethrow;
    }
  }
}

// --- EXTENDED RESULT CLASSES ---

/// Rozszerzona klasa wyniku analizy z dodatkowymi optymalizacjami
class InvestorAnalyticsResult {
  final List<InvestorSummary> investors;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final double totalViableCapital;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final List<InvestorSummary>? allInvestors; // Dla cache

  const InvestorAnalyticsResult({
    required this.investors,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.totalViableCapital,
    required this.hasNextPage,
    required this.hasPreviousPage,
    this.allInvestors,
  });

  double get averageViableCapital =>
      investors.isNotEmpty ? totalViableCapital / investors.length : 0.0;
}

/// Klasa analizy kontroli większościowej
class MajorityControlAnalysis {
  final List<InvestorWithControlInfo> allInvestors;
  final List<InvestorWithControlInfo> controlGroupInvestors;
  final double totalViableCapital;
  final double controlGroupCapital;
  final int controlGroupCount;
  final double controlThreshold;
  final DateTime analysisDate;

  const MajorityControlAnalysis({
    required this.allInvestors,
    required this.controlGroupInvestors,
    required this.totalViableCapital,
    required this.controlGroupCapital,
    required this.controlGroupCount,
    required this.controlThreshold,
    required this.analysisDate,
  });

  factory MajorityControlAnalysis.empty() {
    return MajorityControlAnalysis(
      allInvestors: [],
      controlGroupInvestors: [],
      totalViableCapital: 0.0,
      controlGroupCapital: 0.0,
      controlGroupCount: 0,
      controlThreshold: 51.0,
      analysisDate: DateTime.now(),
    );
  }

  double get controlGroupPercentage => totalViableCapital > 0
      ? (controlGroupCapital / totalViableCapital) * 100
      : 0.0;

  bool get hasControlGroup => controlGroupCount > 0;
}

/// Klasa informacji o inwestorze z kontrolą
class InvestorWithControlInfo {
  final InvestorSummary summary;
  final double controlPercentage;
  final double cumulativePercentage;
  final bool isInControlGroup;

  const InvestorWithControlInfo({
    required this.summary,
    required this.controlPercentage,
    required this.cumulativePercentage,
    required this.isInControlGroup,
  });
}

/// Klasa rozkładu kapitału głosowania
class VotingCapitalDistribution {
  final Map<VotingStatus, double> capitalByStatus;
  final Map<VotingStatus, int> countByStatus;
  final double totalCapital;
  final int totalInvestors;
  final DateTime analysisDate;

  const VotingCapitalDistribution({
    required this.capitalByStatus,
    required this.countByStatus,
    required this.totalCapital,
    required this.totalInvestors,
    required this.analysisDate,
  });

  factory VotingCapitalDistribution.empty() {
    return VotingCapitalDistribution(
      capitalByStatus: {},
      countByStatus: {},
      totalCapital: 0.0,
      totalInvestors: 0,
      analysisDate: DateTime.now(),
    );
  }

  double getCapitalPercentage(VotingStatus status) {
    final capital = capitalByStatus[status] ?? 0.0;
    return totalCapital > 0 ? (capital / totalCapital) * 100 : 0.0;
  }

  double getCountPercentage(VotingStatus status) {
    final count = countByStatus[status] ?? 0;
    return totalInvestors > 0 ? (count / totalInvestors) * 100 : 0.0;
  }
}
