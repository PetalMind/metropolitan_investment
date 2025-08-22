import 'dart:async';
import '../models_and_services.dart';

/// 🚀 ZOPTYMALIZOWANY CENTRALNY CACHE DANYCH
/// Usprawnia pobieranie danych o inwestorach, łącznej wartości i pozostałym kapitale
/// przez eliminację duplikacji zapytań i inteligentne cache'owanie
class OptimizedDataCacheService extends BaseService {
  static final OptimizedDataCacheService _instance =
      OptimizedDataCacheService._internal();
  factory OptimizedDataCacheService() => _instance;
  OptimizedDataCacheService._internal();

  // Cache przechowujący kompletne dane
  Map<String, dynamic>? _unifiedDataCache;
  DateTime? _cacheTimestamp;
  static const Duration _cacheTimeout = Duration(minutes: 15);

  // Streamers dla reaktywnych aktualizacji
  final StreamController<InvestorAnalyticsSummary> _analyticsController =
      StreamController<InvestorAnalyticsSummary>.broadcast();

  Stream<InvestorAnalyticsSummary> get analyticsStream =>
      _analyticsController.stream;

  /// Pobiera kompletne dane analityczne z jednym zapytaniem do bazy
  Future<InvestorAnalyticsSummary> getCompleteAnalyticsData({
    bool forceRefresh = false,
    bool includeInactive = false,
  }) async {
    final startTime = DateTime.now();

    // Sprawdź cache
    if (!forceRefresh && _isCacheValid()) {
      print('📊 [OptimizedCache] Używam danych z cache');
      return _buildSummaryFromCache(includeInactive);
    }

    print('🔄 [OptimizedCache] Ładuję świeże dane...');

    try {
      // POJEDYNCZE ZAPYTANIE: Pobierz wszystkie dane równolegle
      final futures = await Future.wait([
        _getAllClientsOptimized(),
        _getAllInvestmentsOptimized(),
        _getSystemMetadata(),
      ]);

      final clients = futures[0] as List<Client>;
      final investments = futures[1] as List<Investment>;
      final metadata = futures[2] as Map<String, dynamic>;

      print(
        '📊 [OptimizedCache] Pobrano ${clients.length} klientów, ${investments.length} inwestycji',
      );

      // OPTYMALIZACJA: Mapowanie klientów z wykorzystaniem indeksów
      final clientsById = <String, Client>{};
      final clientsByExcelId = <String, Client>{};
      final clientsByName = <String, Client>{};

      for (final client in clients) {
        clientsById[client.id] = client;
        if (client.excelId?.isNotEmpty == true) {
          clientsByExcelId[client.excelId!] = client;
        }
        clientsByName[client.name.toLowerCase().trim()] = client;
      }

      // OPTYMALIZACJA: Grupowanie inwestycji z wykorzystaniem indeksów
      final investmentsByClientId = <String, List<Investment>>{};
      for (final investment in investments) {
        investmentsByClientId
            .putIfAbsent(investment.clientId, () => [])
            .add(investment);
      }

      // SZYBKIE ŁĄCZENIE: Używaj indeksów zamiast iteracji
      final List<InvestorSummary> investors = [];
      final unprocessedInvestments = <String>{};

      for (final client in clients) {
        if (!includeInactive && !client.isActive) continue;

        List<Investment> clientInvestments = [];

        // 1. Szukaj po Excel ID
        if (client.excelId?.isNotEmpty == true) {
          clientInvestments = investmentsByClientId[client.excelId!] ?? [];
        }

        // 2. Fallback po Firebase ID
        if (clientInvestments.isEmpty) {
          clientInvestments = investmentsByClientId[client.id] ?? [];
        }

        // 3. Fallback po nazwie (tylko jeśli nadal puste)
        if (clientInvestments.isEmpty) {
          final nameKey = client.name.toLowerCase().trim();
          for (final investment in investments) {
            if (investment.clientName.toLowerCase().trim() == nameKey) {
              clientInvestments.add(investment);
            }
          }
        }

        if (clientInvestments.isNotEmpty) {
          // Oznacz inwestycje jako przetworzone
          for (final inv in clientInvestments) {
            unprocessedInvestments.add(inv.id);
          }

          final summary = _createInvestorSummaryOptimized(
            client,
            clientInvestments,
          );
          investors.add(summary);
        }
      }

      // Oblicz metryki globalne
      final globalMetrics = _calculateGlobalMetrics(investors, investments);

      // Aktualizuj cache
      _unifiedDataCache = {
        'clients': clients,
        'investments': investments,
        'investors': investors,
        'globalMetrics': globalMetrics,
        'metadata': metadata,
        'lastUpdate': DateTime.now().toIso8601String(),
      };
      _cacheTimestamp = DateTime.now();

      final summary = InvestorAnalyticsSummary(
        investors: investors,
        globalMetrics: globalMetrics,
        totalClients: clients.length,
        totalInvestments: investments.length,
        processedInvestments: unprocessedInvestments.length,
        cacheSource: 'fresh',
        processingTimeMs: DateTime.now().difference(startTime).inMilliseconds,
      );

      // Wyślij aktualizację do streamów
      _analyticsController.add(summary);

      print(
        '✅ [OptimizedCache] Kompletne dane załadowane w ${summary.processingTimeMs}ms',
      );
      return summary;
    } catch (e) {
      print('❌ [OptimizedCache] Błąd ładowania danych: $e');
      logError('getCompleteAnalyticsData', e);
      rethrow;
    }
  }

  /// Sprawdza czy cache jest aktualny
  bool _isCacheValid() {
    return _unifiedDataCache != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!).abs() < _cacheTimeout;
  }

  /// Buduje podsumowanie z cache
  InvestorAnalyticsSummary _buildSummaryFromCache(bool includeInactive) {
    final investors = (_unifiedDataCache!['investors'] as List<InvestorSummary>)
        .where((inv) => includeInactive || inv.client.isActive)
        .toList();

    return InvestorAnalyticsSummary(
      investors: investors,
      globalMetrics: _unifiedDataCache!['globalMetrics'] as GlobalMetrics,
      totalClients: (_unifiedDataCache!['clients'] as List).length,
      totalInvestments: (_unifiedDataCache!['investments'] as List).length,
      processedInvestments: investors.fold(
        0,
        (sum, inv) => sum + inv.investments.length,
      ),
      cacheSource: 'cache',
      processingTimeMs: 0,
    );
  }

  /// Optymalizowane pobieranie klientów z batch processing
  Future<List<Client>> _getAllClientsOptimized() async {
    try {
      final snapshot = await firestore
          .collection('clients')
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => Client.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ [OptimizedCache] Błąd pobierania klientów: $e');
      rethrow;
    }
  }

  /// Optymalizowane pobieranie inwestycji z field selection
  Future<List<Investment>> _getAllInvestmentsOptimized() async {
    try {
      final snapshot = await firestore
          .collection('investments')
          .orderBy('clientId')
          .get();

      return snapshot.docs.map((doc) => Investment.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ [OptimizedCache] Błąd pobierania inwestycji: $e');
      rethrow;
    }
  }

  /// Pobiera metadane systemu
  Future<Map<String, dynamic>> _getSystemMetadata() async {
    return {
      'lastSync': DateTime.now().toIso8601String(),
      'version': '2.0.0',
      'optimizedCache': true,
    };
  }

  /// Tworzy zoptymalizowane podsumowanie inwestora
  InvestorSummary _createInvestorSummaryOptimized(
    Client client,
    List<Investment> investments,
  ) {
    // Oblicz sumy jednym przejściem przez inwestycje
    double totalInvestmentAmount = 0;
    double totalRemainingCapital = 0;
    double totalRealizedCapital = 0;
    double capitalForRestructuring = 0;

    for (final investment in investments) {
      totalInvestmentAmount += investment.investmentAmount;
      totalRemainingCapital += investment.remainingCapital;
      totalRealizedCapital += investment.realizedCapital;
      capitalForRestructuring += investment.capitalForRestructuring;
    }

    // 🎯 ZUNIFIKOWANY WZÓR jak w Dashboard: secured = max(remaining - restructuring, 0)
    // ⭐ ZGODNY Z PRODUCT_DASHBOARD_WIDGET
    final capitalSecuredByRealEstate =
        (totalRemainingCapital - capitalForRestructuring).clamp(
          0.0,
          double.infinity,
        );

    print(
      '🎯 [OptimizedDataCache] ${client.name}: remaining=$totalRemainingCapital, restructuring=$capitalForRestructuring, secured=$capitalSecuredByRealEstate',
    );

    return InvestorSummary(
      client: client,
      investments: investments,
      totalInvestmentAmount: totalInvestmentAmount,
      totalRemainingCapital: totalRemainingCapital,
      totalRealizedCapital: totalRealizedCapital,
      totalSharesValue: 0.0, // Nie używane w nowej architekturze
      totalValue: totalRemainingCapital,
      capitalSecuredByRealEstate: capitalSecuredByRealEstate,
      capitalForRestructuring: capitalForRestructuring,
      investmentCount: investments.length,
    );
  }

  /// Oblicza globalne metryki systemu
  GlobalMetrics _calculateGlobalMetrics(
    List<InvestorSummary> investors,
    List<Investment> allInvestments,
  ) {
    double totalInvestmentAmount = 0;
    double totalRemainingCapital = 0;
    double totalViableCapital = 0;
    int activeInvestorCount = 0;

    final votingDistribution = <VotingStatus, VotingCapitalInfo>{};
    for (final status in VotingStatus.values) {
      votingDistribution[status] = VotingCapitalInfo(count: 0, capital: 0.0);
    }

    for (final investor in investors) {
      totalInvestmentAmount += investor.totalInvestmentAmount;
      totalRemainingCapital += investor.totalRemainingCapital;
      totalViableCapital += investor.viableRemainingCapital;

      if (investor.client.isActive) {
        activeInvestorCount++;
      }

      // Aktualizuj rozkład głosowania
      final status = investor.client.votingStatus;
      final current = votingDistribution[status]!;
      votingDistribution[status] = VotingCapitalInfo(
        count: current.count + 1,
        capital: current.capital + investor.viableRemainingCapital,
      );
    }

    return GlobalMetrics(
      totalInvestorCount: investors.length,
      activeInvestorCount: activeInvestorCount,
      totalInvestmentAmount: totalInvestmentAmount,
      totalRemainingCapital: totalRemainingCapital,
      totalViableCapital: totalViableCapital,
      averageInvestmentPerInvestor: investors.isNotEmpty
          ? totalInvestmentAmount / investors.length
          : 0.0,
      votingDistribution: votingDistribution,
      calculatedAt: DateTime.now(),
    );
  }

  /// Filtruje inwestorów według kryteriów z wykorzystaniem cache
  List<InvestorSummary> filterInvestors({
    VotingStatus? votingStatusFilter,
    ClientType? clientTypeFilter,
    bool showOnlyWithUnviableInvestments = false,
    String? searchQuery,
  }) {
    if (!_isCacheValid() || _unifiedDataCache == null) {
      throw StateError(
        'Cache nie jest aktualny. Wywołaj getCompleteAnalyticsData() najpierw.',
      );
    }

    var investors = _unifiedDataCache!['investors'] as List<InvestorSummary>;

    if (votingStatusFilter != null) {
      investors = investors
          .where((inv) => inv.client.votingStatus == votingStatusFilter)
          .toList();
    }

    if (clientTypeFilter != null) {
      investors = investors
          .where((inv) => inv.client.type == clientTypeFilter)
          .toList();
    }

    if (showOnlyWithUnviableInvestments) {
      investors = investors
          .where(
            (inv) => inv.totalRemainingCapital > inv.viableRemainingCapital,
          )
          .toList();
    }

    if (searchQuery?.isNotEmpty == true) {
      final query = searchQuery!.toLowerCase();
      investors = investors
          .where((inv) => inv.client.name.toLowerCase().contains(query))
          .toList();
    }

    return investors;
  }

  /// Czyści cache i wymusza odświeżenie
  @override
  void clearCache(String key) {
    _unifiedDataCache = null;
    _cacheTimestamp = null;
    print('🗑️ [OptimizedCache] Cache wyczyszczony');
  }

  /// Czyści cały cache
  @override
  void clearAllCache() {
    clearCache('all');
  }

  /// Zwraca status cache
  Map<String, dynamic> getCacheStatus() {
    return {
      'isValid': _isCacheValid(),
      'lastUpdate': _cacheTimestamp?.toIso8601String(),
      'cacheSize': _unifiedDataCache?.length ?? 0,
      'timeToExpiry': _cacheTimestamp != null
          ? _cacheTimeout.inMilliseconds -
                DateTime.now().difference(_cacheTimestamp!).inMilliseconds
          : 0,
    };
  }

  /// Zamyka streamy
  void dispose() {
    _analyticsController.close();
  }
}

/// Model kompletnego podsumowania analitycznego
class InvestorAnalyticsSummary {
  final List<InvestorSummary> investors;
  final GlobalMetrics globalMetrics;
  final int totalClients;
  final int totalInvestments;
  final int processedInvestments;
  final String cacheSource;
  final int processingTimeMs;

  const InvestorAnalyticsSummary({
    required this.investors,
    required this.globalMetrics,
    required this.totalClients,
    required this.totalInvestments,
    required this.processedInvestments,
    required this.cacheSource,
    required this.processingTimeMs,
  });

  double get averageInvestmentPerInvestor => investors.isNotEmpty
      ? globalMetrics.totalInvestmentAmount / investors.length
      : 0.0;

  double get dataProcessingEfficiency => totalInvestments > 0
      ? (processedInvestments / totalInvestments) * 100
      : 0.0;
}

/// Model globalnych metryk systemu
class GlobalMetrics {
  final int totalInvestorCount;
  final int activeInvestorCount;
  final double totalInvestmentAmount;
  final double totalRemainingCapital;
  final double totalViableCapital;
  final double averageInvestmentPerInvestor;
  final Map<VotingStatus, VotingCapitalInfo> votingDistribution;
  final DateTime calculatedAt;

  const GlobalMetrics({
    required this.totalInvestorCount,
    required this.activeInvestorCount,
    required this.totalInvestmentAmount,
    required this.totalRemainingCapital,
    required this.totalViableCapital,
    required this.averageInvestmentPerInvestor,
    required this.votingDistribution,
    required this.calculatedAt,
  });

  double get majorityControlThreshold => totalViableCapital * 0.51;

  double get averageCapitalPerInvestor =>
      totalInvestorCount > 0 ? totalViableCapital / totalInvestorCount : 0.0;
}
