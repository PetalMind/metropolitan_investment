import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/investment.dart';
import '../models/product.dart';
import 'base_service.dart';

/// Web-optimized cache service - lepsze dla aplikacji webowych
class WebOptimizedCacheService extends BaseService {
  static final WebOptimizedCacheService _instance =
      WebOptimizedCacheService._internal();
  factory WebOptimizedCacheService() => _instance;
  WebOptimizedCacheService._internal();

  // Cache w pamięci z timeoutami
  final Map<String, _CacheEntry<List<Investment>>> _collectionsCache = {};
  final Map<String, _CacheEntry<Map<String, dynamic>>> _aggregateCache = {};

  // Streamcontrollers dla reaktywności
  final Map<String, StreamController<List<Investment>>> _streamControllers = {};

  // Konfiguracja
  static const Duration _cacheTimeout = Duration(minutes: 5); // Krótsza dla web

  /// Pobiera wszystkie inwestycje z optymalizacją dla web
  Future<List<Investment>> getAllInvestments({
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'all_investments';

    // Sprawdź cache
    if (!forceRefresh && _isValidCache(cacheKey)) {
      print(
        '📊 [WebCache] Używam cache dla wszystkich inwestycji (${_collectionsCache[cacheKey]!.data.length} elementów)',
      );
      return _collectionsCache[cacheKey]!.data;
    }

    print('📊 [WebCache] Ładowanie danych wsadami...');

    try {
      // Ładuj równolegle ze wszystkich kolekcji
      final futures = <Future<List<Investment>>>[
        _loadInvestmentsFromCollection('investments'),
        _loadBondsAsInvestments(),
        _loadLoansAsInvestments(),
        _loadSharesAsInvestments(),
      ];

      final results = await Future.wait(futures);
      final allInvestments = <Investment>[];

      for (final investments in results) {
        allInvestments.addAll(investments);
      }

      // Zapisz do cache
      _collectionsCache[cacheKey] = _CacheEntry(allInvestments, DateTime.now());

      print('📊 [WebCache] Załadowano ${allInvestments.length} inwestycji');
      _notifyStreamListeners(cacheKey, allInvestments);

      return allInvestments;
    } catch (e) {
      logError('getAllInvestments', e);
      return _collectionsCache[cacheKey]?.data ?? [];
    }
  }

  /// Stream reaktywny dla komponentów UI
  Stream<List<Investment>> getAllInvestmentsStream() {
    const cacheKey = 'all_investments';

    if (!_streamControllers.containsKey(cacheKey)) {
      _streamControllers[cacheKey] =
          StreamController<List<Investment>>.broadcast();

      // Załaduj dane jeśli nie ma w cache
      if (!_isValidCache(cacheKey)) {
        getAllInvestments().then((investments) {
          if (_streamControllers.containsKey(cacheKey)) {
            _streamControllers[cacheKey]!.add(investments);
          }
        });
      } else {
        // Wyślij cache natychmiast
        _streamControllers[cacheKey]!.add(_collectionsCache[cacheKey]!.data);
      }
    }

    return _streamControllers[cacheKey]!.stream;
  }

  /// Pobiera inwestycje z paginacją (tylko do wyświetlania)
  List<Investment> getInvestmentsPaginated(
    List<Investment> allInvestments, {
    int offset = 0,
    int limit = 50,
    String? searchQuery,
    InvestmentStatus? statusFilter,
  }) {
    var filtered = allInvestments;

    // Filtrowanie
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (inv) =>
                inv.clientName.toLowerCase().contains(query) ||
                inv.productName.toLowerCase().contains(query) ||
                inv.employeeFirstName.toLowerCase().contains(query) ||
                inv.employeeLastName.toLowerCase().contains(query),
          )
          .toList();
    }

    if (statusFilter != null) {
      filtered = filtered.where((inv) => inv.status == statusFilter).toList();
    }

    // Sortowanie (najnowsze pierwsze)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Paginacja
    final end = (offset + limit).clamp(0, filtered.length);
    return filtered.sublist(offset.clamp(0, filtered.length), end);
  }

  /// Pobiera agregowane metryki z cache
  Future<Map<String, dynamic>> getAggregatedMetrics({
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'aggregated_metrics';

    if (!forceRefresh && _isValidAggregateCache(cacheKey)) {
      return _aggregateCache[cacheKey]!.data;
    }

    print('📊 [WebCache] Obliczanie metryk...');

    try {
      final investments = await getAllInvestments();

      final metrics = {
        'totalInvestments': investments.length,
        'totalValue': investments.fold<double>(
          0,
          (sum, inv) => sum + inv.totalValue,
        ),
        'totalInvestmentAmount': investments.fold<double>(
          0,
          (sum, inv) => sum + inv.investmentAmount,
        ),
        'totalRealizedCapital': investments.fold<double>(
          0,
          (sum, inv) => sum + inv.realizedCapital,
        ),
        'totalRemainingCapital': investments.fold<double>(
          0,
          (sum, inv) => sum + inv.remainingCapital,
        ),
        'totalRealizedInterest': investments.fold<double>(
          0,
          (sum, inv) => sum + inv.realizedInterest,
        ),
        'activeInvestments': investments
            .where((inv) => inv.status == InvestmentStatus.active)
            .length,
        'completedInvestments': investments
            .where((inv) => inv.status == InvestmentStatus.completed)
            .length,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      _aggregateCache[cacheKey] = _CacheEntry(metrics, DateTime.now());
      return metrics;
    } catch (e) {
      logError('getAggregatedMetrics', e);
      return _aggregateCache[cacheKey]?.data ?? {};
    }
  }

  /// Ładuje inwestycje z głównej kolekcji
  Future<List<Investment>> _loadInvestmentsFromCollection(
    String collectionName,
  ) async {
    print('📊 [WebCache] Ładowanie z kolekcji: $collectionName');

    final snapshot = await firestore.collection(collectionName).get();
    final investments = <Investment>[];

    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();
        data['id'] = doc.id;
        investments.add(_convertFirebaseDataToInvestment(data));
      } catch (e) {
        print('⚠️ [WebCache] Błąd konwersji dokumentu ${doc.id}: $e');
      }
    }

    return investments;
  }

  /// Ładuje obligacje jako inwestycje
  Future<List<Investment>> _loadBondsAsInvestments() async {
    print('📊 [WebCache] Ładowanie obligacji...');

    final snapshot = await firestore.collection('bonds').get();
    final investments = <Investment>[];

    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();
        data['id'] = doc.id;
        data['typ_produktu'] = 'Obligacje'; // Oznacz jako obligacje
        investments.add(_convertFirebaseDataToInvestment(data));
      } catch (e) {
        print('⚠️ [WebCache] Błąd konwersji obligacji ${doc.id}: $e');
      }
    }

    return investments;
  }

  /// Ładuje pożyczki jako inwestycje
  Future<List<Investment>> _loadLoansAsInvestments() async {
    print('📊 [WebCache] Ładowanie pożyczek...');

    final snapshot = await firestore.collection('loans').get();
    final investments = <Investment>[];

    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();
        data['id'] = doc.id;
        data['typ_produktu'] = 'Pożyczki'; // Oznacz jako pożyczki
        investments.add(_convertFirebaseDataToInvestment(data));
      } catch (e) {
        print('⚠️ [WebCache] Błąd konwersji pożyczki ${doc.id}: $e');
      }
    }

    return investments;
  }

  /// Ładuje udziały jako inwestycje
  Future<List<Investment>> _loadSharesAsInvestments() async {
    print('📊 [WebCache] Ładowanie udziałów...');

    final snapshot = await firestore.collection('shares').get();
    final investments = <Investment>[];

    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();
        data['id'] = doc.id;
        data['typ_produktu'] = 'Udziały'; // Oznacz jako udziały
        investments.add(_convertFirebaseDataToInvestment(data));
      } catch (e) {
        print('⚠️ [WebCache] Błąd konwersji udziału ${doc.id}: $e');
      }
    }

    return investments;
  }

  /// Konwertuje dane Firebase na Investment
  Investment _convertFirebaseDataToInvestment(Map<String, dynamic> data) {
    final now = DateTime.now();

    return Investment(
      id: data['id'] ?? '',
      clientId: data['id_klient']?.toString() ?? data['id'] ?? '',
      clientName: data['klient'] ?? data['client_name'] ?? '',
      employeeId: data['employee_id'] ?? '',
      employeeFirstName:
          data['praconwnik_imie'] ?? data['employee_first_name'] ?? '',
      employeeLastName:
          data['pracownik_nazwisko'] ?? data['employee_last_name'] ?? '',
      branchCode: data['oddzial'] ?? data['branch_code'] ?? 'DEFAULT',
      status: _parseStatus(
        data['status_produktu'] ?? data['status'] ?? 'Aktywny',
      ),
      marketType: data['produkt_status_wejscie'] == 'Rynek pierwotny'
          ? MarketType.primary
          : MarketType.secondary,
      signedDate:
          _parseDate(data['data_podpisania'] ?? data['signed_date']) ?? now,
      entryDate: _parseDate(
        data['data_wejscia_do_inwestycji'] ?? data['start_date'],
      ),
      exitDate: _parseDate(
        data['data_wyjscia_z_inwestycji'] ?? data['end_date'],
      ),
      proposalId: data['id_propozycja_nabycia']?.toString() ?? data['id'] ?? '',
      productType: _parseProductType(data['typ_produktu'] ?? 'Obligacje'),
      productName: data['produkt_nazwa'] ?? data['product_name'] ?? '',
      creditorCompany:
          data['wierzyciel_spolka'] ?? data['creditor_company'] ?? '',
      companyId: data['id_spolka'] ?? data['company_id'] ?? '',
      issueDate: _parseDate(data['data_emisji'] ?? data['issue_date']),
      redemptionDate: _parseDate(
        data['data_wykupu'] ?? data['redemption_date'],
      ),
      investmentAmount: _parseDouble(
        data['kwota_inwestycji'] ?? data['investment_amount'] ?? 0,
      ),
      paidAmount: _parseDouble(data['kwota_wplat'] ?? data['paid_amount'] ?? 0),
      remainingCapital: _parseDouble(
        data['kapital_pozostaly'] ?? data['remaining_capital'] ?? 0,
      ),
      realizedCapital: _parseDouble(
        data['kapital_zrealizowany'] ?? data['realized_capital'] ?? 0,
      ),
      remainingInterest: _parseDouble(
        data['odsetki_pozostale'] ?? data['remaining_interest'] ?? 0,
      ),
      realizedInterest: _parseDouble(
        data['odsetki_zrealizowane'] ?? data['realized_interest'] ?? 0,
      ),
      transferToOtherProduct: _parseDouble(
        data['przekaz_na_inny_produkt'] ??
            data['transfer_to_other_product'] ??
            0,
      ),
      plannedTax: _parseDouble(
        data['planowany_podatek'] ?? data['planned_tax'] ?? 0,
      ),
      realizedTax: _parseDouble(
        data['zrealizowany_podatek'] ?? data['realized_tax'] ?? 0,
      ),
      createdAt: _parseDate(data['created_at']) ?? now,
      updatedAt: _parseDate(data['uploaded_at']) ?? now,
    );
  }

  // Metody pomocnicze
  bool _isValidCache(String key) {
    final entry = _collectionsCache[key];
    if (entry == null) return false;
    return DateTime.now().difference(entry.timestamp) < _cacheTimeout;
  }

  bool _isValidAggregateCache(String key) {
    final entry = _aggregateCache[key];
    if (entry == null) return false;
    return DateTime.now().difference(entry.timestamp) < _cacheTimeout;
  }

  void _notifyStreamListeners(String key, List<Investment> data) {
    if (_streamControllers.containsKey(key)) {
      _streamControllers[key]!.add(data);
    }
  }

  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String)
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    return 0.0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  InvestmentStatus _parseStatus(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'active':
        case 'aktywny':
          return InvestmentStatus.active;
        case 'completed':
        case 'zakończony':
          return InvestmentStatus.completed;
        case 'inactive':
        case 'nieaktywny':
          return InvestmentStatus.inactive;
        case 'earlyredemption':
        case 'wykup wczesniejszy':
          return InvestmentStatus.earlyRedemption;
        default:
          return InvestmentStatus.active;
      }
    }
    return InvestmentStatus.active;
  }

  ProductType _parseProductType(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'obligacje':
        case 'bonds':
          return ProductType.bonds;
        case 'akcje':
        case 'udziały':
        case 'shares':
          return ProductType.shares;
        case 'pożyczki':
        case 'pozyczki':
        case 'loans':
          return ProductType.loans;
        case 'apartamenty':
        case 'apartments':
          return ProductType.apartments;
        default:
          return ProductType.bonds;
      }
    }
    return ProductType.bonds;
  }

  /// Wyczyść cache
  @override
  void clearCache(String key) {
    if (key == 'all') {
      _collectionsCache.clear();
      _aggregateCache.clear();
      print('📊 [WebCache] Cały cache wyczyszczony');
    } else {
      _collectionsCache.remove(key);
      _aggregateCache.remove(key);
      print('📊 [WebCache] Cache dla $key wyczyszczony');
    }
  }

  /// Wyczyść cały cache (metoda dodatkowa)
  void clearAllCache() {
    _collectionsCache.clear();
    _aggregateCache.clear();
    print('📊 [WebCache] Cache wyczyszczony');
  }

  /// Zamknij wszystkie streamy
  void dispose() {
    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
  }

  /// Stats cache
  Map<String, dynamic> getCacheStats() {
    return {
      'collections_cached': _collectionsCache.length,
      'aggregate_cached': _aggregateCache.length,
      'active_streams': _streamControllers.length,
      'cache_timeout_minutes': _cacheTimeout.inMinutes,
    };
  }
}

/// Helper class dla cache entries
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry(this.data, this.timestamp);
}
