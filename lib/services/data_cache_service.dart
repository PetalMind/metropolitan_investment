import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/investment.dart';
import '../models/product.dart';
import 'base_service.dart';

/// Centralny serwis cache'owania danych Firebase z optymalizacjami wydajnościowymi
/// Zapobiega wielokrotnym zapytaniom do tych samych kolekcji
class DataCacheService extends BaseService {
  static final DataCacheService _instance = DataCacheService._internal();
  factory DataCacheService() => _instance;
  DataCacheService._internal();

  // Cache dla wszystkich inwestycji z timestampem
  List<Investment>? _allInvestmentsCache;
  DateTime? _allInvestmentsCacheTimestamp;
  static const Duration _investmentsCacheTimeout = Duration(minutes: 10);

  // Cache dla poszczególnych kolekcji
  final Map<String, List<Map<String, dynamic>>> _collectionsCache = {};
  final Map<String, DateTime> _collectionsCacheTimestamp = {};
  static const Duration _collectionCacheTimeout = Duration(minutes: 15);

  // Persistent cache keys
  static const String _cacheKeyInvestments = 'data_cache_investments';
  static const String _cacheKeyInvestmentsTimestamp =
      'data_cache_investments_timestamp';

  // Subskrypcje do cache'owania
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, Stream<QuerySnapshot>> _streams = {};

  /// Pobiera wszystkie inwestycje z cache'em - główna metoda optymalizacyjna
  Future<List<Investment>> getAllInvestments({
    bool forceRefresh = false,
  }) async {
    // Sprawdź cache w pamięci
    if (!forceRefresh && _isInvestmentsCacheValid()) {
      print(
        '📊 [DataCache] Używam cache w pamięci dla wszystkich inwestycji (${_allInvestmentsCache!.length} elementów)',
      );
      return _allInvestmentsCache!;
    }

    // Sprawdź persistent cache (SharedPreferences/localStorage)
    if (!forceRefresh) {
      final cachedData = await _loadFromPersistentCache();
      if (cachedData != null) {
        _allInvestmentsCache = cachedData;
        _allInvestmentsCacheTimestamp = DateTime.now();
        print(
          '📊 [DataCache] Załadowano z lokalnego storage (${cachedData.length} elementów)',
        );
        return cachedData;
      }
    }

    print(
      '📊 [DataCache] Pobieranie świeżych danych ze wszystkich kolekcji...',
    );

    try {
      // Pobierz dane równolegle ze wszystkich kolekcji
      final results = await Future.wait([
        _getCachedCollectionData('investments'),
        _getCachedCollectionData('bonds'),
        _getCachedCollectionData('loans'),
        _getCachedCollectionData('shares'),
      ]);

      final allInvestments = <Investment>[];

      // Konwertuj dane z głównej kolekcji investments
      for (final data in results[0]) {
        allInvestments.add(_convertExcelDataToInvestment(data['id'], data));
      }

      // Konwertuj dane z kolekcji bonds na Investment
      for (final data in results[1]) {
        allInvestments.add(_convertBondToInvestment(data['id'], data));
      }

      // Konwertuj dane z kolekcji loans na Investment
      for (final data in results[2]) {
        allInvestments.add(_convertLoanToInvestment(data['id'], data));
      }

      // Konwertuj dane z kolekcji shares na Investment
      for (final data in results[3]) {
        allInvestments.add(_convertShareToInvestment(data['id'], data));
      }

      // Zapisz do cache
      _allInvestmentsCache = allInvestments;
      _allInvestmentsCacheTimestamp = DateTime.now();

      // Zapisz do persistent cache
      await _saveToPersistentCache(allInvestments);

      print(
        '📊 [DataCache] Cache zaktualizowany z ${allInvestments.length} inwestycjami',
      );
      print(
        '📊 [DataCache] Breakdown: investments=${results[0].length}, bonds=${results[1].length}, loans=${results[2].length}, shares=${results[3].length}',
      );

      return allInvestments;
    } catch (e) {
      logError('getAllInvestments', e);
      return _allInvestmentsCache ?? [];
    }
  }

  /// Pobiera dane z konkretnej kolekcji z cache'em
  Future<List<Map<String, dynamic>>> _getCachedCollectionData(
    String collectionName,
  ) async {
    // Sprawdź cache dla kolekcji
    if (_isCollectionCacheValid(collectionName)) {
      return _collectionsCache[collectionName]!;
    }

    try {
      print('📊 [DataCache] Pobieranie $collectionName z Firebase...');
      final snapshot = await firestore.collection(collectionName).get();

      final data = snapshot.docs.map((doc) {
        final docData = doc.data();
        docData['id'] = doc.id;
        return docData;
      }).toList();

      // Debug: pokaż jakie pola mamy w pierwszym dokumencie
      if (data.isNotEmpty) {
        print('🔍 [DataCache] === PIERWSZY DOKUMENT Z $collectionName ===');
        final first = data.first;
        print('🔍 [DataCache] ID: ${first['id']}');

        // Pokaż wszystkie pola z wartościami
        final sortedKeys = first.keys.toList()..sort();
        for (final key in sortedKeys) {
          final value = first[key];
          if (value != null && value != '' && value != 0) {
            print('  - $key: $value (${value.runtimeType})');
          }
        }

        // Pokaż specjalnie pola finansowe nawet jeśli są 0
        final financialFields = [
          'investment_amount',
          'Wartość nominalna',
          'wartość_nominalna',
          'paid_amount',
          'Kwota wpłacona',
          'kwota_wpłacona',
          'remaining_capital',
          'Kapitał pozostały',
          'kapitał_pozostały',
          'realized_capital',
          'Kapitał zrealizowany',
          'kapitał_zrealizowany',
          'total_value',
          'Wartość całkowita',
          'wartość_całkowita',
          'value',
          'Wartość',
          'wartość',
        ];

        print('🔍 [DataCache] Pola finansowe (nawet jeśli 0):');
        for (final field in financialFields) {
          if (first.containsKey(field)) {
            print('  - $field: ${first[field]} (${first[field].runtimeType})');
          }
        }
        print('🔍 [DataCache] === KONIEC DOKUMENTU ===');
      }

      // Zapisz do cache
      _collectionsCache[collectionName] = data;
      _collectionsCacheTimestamp[collectionName] = DateTime.now();

      return data;
    } catch (e) {
      logError('_getCachedCollectionData($collectionName)', e);
      return _collectionsCache[collectionName] ?? [];
    }
  }

  /// Pobiera dane z kolekcji jako stream z cache'em (dla real-time updates gdy potrzebne)
  Stream<List<Map<String, dynamic>>> getCollectionStream(
    String collectionName,
  ) {
    if (_streams.containsKey(collectionName)) {
      return _streams[collectionName]!.map((snapshot) {
        final data = snapshot.docs.map((doc) {
          final docData = doc.data() as Map<String, dynamic>;
          docData['id'] = doc.id;
          return docData;
        }).toList();

        // Aktualizuj cache
        _collectionsCache[collectionName] = data;
        _collectionsCacheTimestamp[collectionName] = DateTime.now();

        return data;
      });
    }

    final stream = firestore.collection(collectionName).snapshots();
    _streams[collectionName] = stream;

    return stream.map((snapshot) {
      final data = snapshot.docs.map((doc) {
        final docData = doc.data();
        docData['id'] = doc.id;
        return docData;
      }).toList();

      // Aktualizuj cache
      _collectionsCache[collectionName] = data;
      _collectionsCacheTimestamp[collectionName] = DateTime.now();

      return data;
    });
  }

  /// Sprawdza czy cache inwestycji jest aktualny
  bool _isInvestmentsCacheValid() {
    if (_allInvestmentsCache == null || _allInvestmentsCacheTimestamp == null) {
      return false;
    }
    return DateTime.now().difference(_allInvestmentsCacheTimestamp!) <
        _investmentsCacheTimeout;
  }

  /// Sprawdza czy cache kolekcji jest aktualny
  bool _isCollectionCacheValid(String collectionName) {
    if (!_collectionsCache.containsKey(collectionName) ||
        !_collectionsCacheTimestamp.containsKey(collectionName)) {
      return false;
    }
    return DateTime.now().difference(
          _collectionsCacheTimestamp[collectionName]!,
        ) <
        _collectionCacheTimeout;
  }

  /// Czyści cache - używaj po zapisie danych
  void invalidateCache() {
    _allInvestmentsCache = null;
    _allInvestmentsCacheTimestamp = null;
    _collectionsCache.clear();
    _collectionsCacheTimestamp.clear();
    _clearPersistentCache();
    print('📊 [DataCache] Cache wyczyszczony');
  }

  /// Czyści cache konkretnej kolekcji
  void invalidateCollectionCache(String collectionName) {
    _collectionsCache.remove(collectionName);
    _collectionsCacheTimestamp.remove(collectionName);
    // Jeśli zmieniono kolekcję, która wpływa na wszystkie inwestycje
    if (['investments', 'bonds', 'loans', 'shares'].contains(collectionName)) {
      _allInvestmentsCache = null;
      _allInvestmentsCacheTimestamp = null;
      _clearPersistentCache();
    }
    print('📊 [DataCache] Cache dla $collectionName wyczyszczony');
  }

  // === PERSISTENT CACHE METHODS ===

  /// Ładuje dane z lokalnego storage (localStorage na web, SharedPreferences na mobile)
  Future<List<Investment>?> _loadFromPersistentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Sprawdź timestamp
      final timestampStr = prefs.getString(_cacheKeyInvestmentsTimestamp);
      if (timestampStr == null) return null;

      final timestamp = DateTime.parse(timestampStr);
      if (DateTime.now().difference(timestamp) > _investmentsCacheTimeout) {
        print('📊 [DataCache] Lokalny cache wygasł');
        return null;
      }

      // Załaduj dane jako JSON surowe dane Firestore
      final dataStr = prefs.getString(_cacheKeyInvestments);
      if (dataStr == null) return null;

      final List<dynamic> dataList = json.decode(dataStr);
      final investments = <Investment>[];

      for (final item in dataList) {
        final Map<String, dynamic> data = item as Map<String, dynamic>;
        final String? id = data.remove('id') as String?;
        if (id != null) {
          // Rekonstruuj Investment z surowych danych
          investments.add(_reconstructInvestmentFromData(id, data));
        }
      }

      print(
        '📊 [DataCache] Załadowano ${investments.length} inwestycji z lokalnego storage',
      );
      return investments;
    } catch (e) {
      print('📊 [DataCache] Błąd podczas ładowania z lokalnego storage: $e');
      return null;
    }
  }

  /// Zapisuje dane do lokalnego storage
  Future<void> _saveToPersistentCache(List<Investment> investments) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Zapisz timestamp
      await prefs.setString(
        _cacheKeyInvestmentsTimestamp,
        DateTime.now().toIso8601String(),
      );

      // Konwertuj Investment do surowych danych z ID
      final dataList = investments.map((inv) {
        final data = inv.toFirestore();
        data['id'] = inv.id;
        return data;
      }).toList();

      await prefs.setString(_cacheKeyInvestments, json.encode(dataList));

      print(
        '📊 [DataCache] Zapisano ${investments.length} inwestycji do lokalnego storage',
      );
    } catch (e) {
      print('📊 [DataCache] Błąd podczas zapisu do lokalnego storage: $e');
    }
  }

  /// Czyści persistent cache
  Future<void> _clearPersistentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKeyInvestments);
      await prefs.remove(_cacheKeyInvestmentsTimestamp);
      print('📊 [DataCache] Lokalny cache wyczyszczony');
    } catch (e) {
      print('📊 [DataCache] Błąd podczas czyszczenia lokalnego cache: $e');
    }
  }

  /// Zwraca statystyki cache'a
  Map<String, dynamic> getCacheStats() {
    return {
      'allInvestmentsCache': {
        'isValid': _isInvestmentsCacheValid(),
        'count': _allInvestmentsCache?.length ?? 0,
        'lastUpdate': _allInvestmentsCacheTimestamp?.toIso8601String(),
      },
      'collectionsCache': _collectionsCache.map(
        (key, value) => MapEntry(key, {
          'isValid': _isCollectionCacheValid(key),
          'count': value.length,
          'lastUpdate': _collectionsCacheTimestamp[key]?.toIso8601String(),
        }),
      ),
    };
  }

  /// Sprawdza dostępność persistent cache
  Future<Map<String, dynamic>> getPersistentCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(_cacheKeyInvestmentsTimestamp);
      final hasData = prefs.getString(_cacheKeyInvestments) != null;

      DateTime? timestamp;
      bool isValid = false;

      if (timestampStr != null) {
        timestamp = DateTime.parse(timestampStr);
        isValid =
            DateTime.now().difference(timestamp) < _investmentsCacheTimeout;
      }

      return {
        'hasPersistedData': hasData,
        'isValid': isValid,
        'timestamp': timestamp?.toIso8601String(),
        'timeToExpiry': isValid && timestamp != null
            ? _investmentsCacheTimeout.inMinutes -
                  DateTime.now().difference(timestamp).inMinutes
            : 0,
      };
    } catch (e) {
      return {
        'hasPersistedData': false,
        'isValid': false,
        'error': e.toString(),
      };
    }
  }

  /// Force refresh - usuwa wszystkie cache i pobiera fresh data
  Future<List<Investment>> forceRefreshFromFirebase() async {
    print('📊 [DataCache] FORCE REFRESH - czyszczę wszystkie cache');
    await _clearPersistentCache();
    invalidateCache();
    return getAllInvestments(forceRefresh: true);
  }

  /// Zatrzymuje wszystkie subskrypcje
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _streams.clear();
  }

  // Metody konwersji - przeniesione z innych serwisów dla centralizacji
  Investment _convertExcelDataToInvestment(
    String id,
    Map<String, dynamic> data,
  ) {
    final now = DateTime.now();
    return Investment(
      id: id,
      clientId: data['id_klient']?.toString() ?? id,
      clientName: data['klient'] ?? data['client_name'] ?? '',
      employeeId: data['employee_id'] ?? '',
      employeeFirstName:
          data['praconwnik_imie'] ?? data['employee_first_name'] ?? '',
      employeeLastName:
          data['pracownik_nazwisko'] ?? data['employee_last_name'] ?? '',
      branchCode: data['oddzial'] ?? data['branch_code'] ?? 'DEFAULT',
      status: _parseStatus(
        data['status_produktu'] ?? data['status'] ?? 'Active',
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
      proposalId: data['id_propozycja_nabycia']?.toString() ?? id,
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

  Investment _convertBondToInvestment(String id, Map<String, dynamic> data) {
    final now = DateTime.now();
    return Investment(
      id: id,
      clientId: data['client_id'] ?? id,
      clientName: data['Nazwa klienta'] ?? data['client_name'] ?? '',
      employeeId: data['employee_id'] ?? '',
      employeeFirstName:
          data['Imię pracownika'] ?? data['employee_first_name'] ?? '',
      employeeLastName:
          data['Nazwisko pracownika'] ?? data['employee_last_name'] ?? '',
      branchCode: data['branch_code'] ?? 'DEFAULT',
      status: _parseStatus(data['Status'] ?? data['status'] ?? 'Active'),
      marketType: MarketType.primary,
      signedDate:
          _parseDate(data['Data podpisania'] ?? data['signed_date']) ?? now,
      entryDate: _parseDate(data['Data rozpoczęcia'] ?? data['start_date']),
      exitDate: _parseDate(data['Data zakończenia'] ?? data['end_date']),
      proposalId: data['proposal_id'] ?? id,
      productType: ProductType.bonds,
      productName: data['Nazwa obligacji'] ?? data['bond_name'] ?? '',
      creditorCompany: data['Firma emitent'] ?? data['issuer_company'] ?? '',
      companyId: data['company_id'] ?? '',
      issueDate: _parseDate(data['Data emisji'] ?? data['issue_date']),
      redemptionDate: _parseDate(
        data['Data wykupu'] ?? data['redemption_date'],
      ),
      investmentAmount: _parseDouble(
        data['Wartość nominalna'] ?? data['nominal_value'] ?? 0,
      ),
      paidAmount: _parseDouble(
        data['Kwota wpłacona'] ?? data['paid_amount'] ?? 0,
      ),
      remainingCapital: _parseDouble(
        data['Kapitał pozostały'] ?? data['remaining_capital'] ?? 0,
      ),
      createdAt: now,
      updatedAt: now,
    );
  }

  Investment _convertLoanToInvestment(String id, Map<String, dynamic> data) {
    final now = DateTime.now();
    return Investment(
      id: id,
      clientId: data['client_id'] ?? id,
      clientName: data['Nazwa klienta'] ?? data['client_name'] ?? '',
      employeeId: data['employee_id'] ?? '',
      employeeFirstName:
          data['Imię pracownika'] ?? data['employee_first_name'] ?? '',
      employeeLastName:
          data['Nazwisko pracownika'] ?? data['employee_last_name'] ?? '',
      branchCode: data['branch_code'] ?? 'DEFAULT',
      status: _parseStatus(data['Status'] ?? data['status'] ?? 'Active'),
      marketType: MarketType.primary,
      signedDate:
          _parseDate(data['Data podpisania'] ?? data['signed_date']) ?? now,
      entryDate: _parseDate(data['Data rozpoczęcia'] ?? data['start_date']),
      exitDate: _parseDate(data['Data zakończenia'] ?? data['end_date']),
      proposalId: data['proposal_id'] ?? id,
      productType: ProductType.loans,
      productName: data['Nazwa pożyczki'] ?? data['loan_name'] ?? '',
      creditorCompany:
          data['Firma pożyczkodawca'] ?? data['lender_company'] ?? '',
      companyId: data['company_id'] ?? '',
      issueDate: _parseDate(data['Data udzielenia'] ?? data['grant_date']),
      redemptionDate: _parseDate(data['Data spłaty'] ?? data['repayment_date']),
      investmentAmount: _parseDouble(
        data['Kwota pożyczki'] ?? data['loan_amount'] ?? 0,
      ),
      paidAmount: _parseDouble(
        data['Kwota wypłacona'] ?? data['paid_amount'] ?? 0,
      ),
      remainingCapital: _parseDouble(
        data['Kapitał pozostały'] ?? data['remaining_capital'] ?? 0,
      ),
      createdAt: now,
      updatedAt: now,
    );
  }

  Investment _convertShareToInvestment(String id, Map<String, dynamic> data) {
    final now = DateTime.now();
    return Investment(
      id: id,
      clientId: data['client_id'] ?? id,
      clientName: data['Nazwa klienta'] ?? data['client_name'] ?? '',
      employeeId: data['employee_id'] ?? '',
      employeeFirstName:
          data['Imię pracownika'] ?? data['employee_first_name'] ?? '',
      employeeLastName:
          data['Nazwisko pracownika'] ?? data['employee_last_name'] ?? '',
      branchCode: data['branch_code'] ?? 'DEFAULT',
      status: _parseStatus(data['Status'] ?? data['status'] ?? 'Active'),
      marketType: MarketType.primary,
      signedDate:
          _parseDate(data['Data podpisania'] ?? data['signed_date']) ?? now,
      entryDate: _parseDate(data['Data nabycia'] ?? data['acquisition_date']),
      exitDate: _parseDate(data['Data sprzedaży'] ?? data['sale_date']),
      proposalId: data['proposal_id'] ?? id,
      productType: ProductType.shares,
      productName: data['Nazwa udziału'] ?? data['share_name'] ?? '',
      creditorCompany: data['Firma spółka'] ?? data['company_name'] ?? '',
      companyId: data['company_id'] ?? '',
      issueDate: _parseDate(data['Data emisji'] ?? data['issue_date']),
      sharesCount: _parseInt(data['Liczba udziałów'] ?? data['shares_count']),
      investmentAmount: _parseDouble(data['Wartość'] ?? data['value'] ?? 0),
      paidAmount: _parseDouble(
        data['Kwota wpłacona'] ?? data['paid_amount'] ?? 0,
      ),
      remainingCapital: _parseDouble(
        data['Kapitał pozostały'] ?? data['remaining_capital'] ?? 0,
      ),
      createdAt: now,
      updatedAt: now,
    );
  }

  // Metody pomocnicze
  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String)
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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

  /// Rekonstruuje Investment z surowych danych (dla persistent cache)
  Investment _reconstructInvestmentFromData(
    String id,
    Map<String, dynamic> data,
  ) {
    return Investment(
      id: id,
      clientId: data['client_id'] ?? id,
      clientName: data['client_name'] ?? '',
      employeeId: data['employee_id'] ?? '',
      employeeFirstName: data['employee_first_name'] ?? '',
      employeeLastName: data['employee_last_name'] ?? '',
      branchCode: data['branch_code'] ?? 'DEFAULT',
      status: _parseStatus(data['status'] ?? 'Active'),
      isAllocated: data['is_allocated'] ?? false,
      marketType: _parseMarketType(data['market_type']),
      signedDate: _parseDate(data['signed_date']) ?? DateTime.now(),
      entryDate: _parseDate(data['entry_date']),
      exitDate: _parseDate(data['exit_date']),
      proposalId: data['proposal_id'] ?? id,
      productType: _parseProductType(data['product_type']),
      productName: data['product_name'] ?? '',
      creditorCompany: data['creditor_company'] ?? '',
      companyId: data['company_id'] ?? '',
      issueDate: _parseDate(data['issue_date']),
      redemptionDate: _parseDate(data['redemption_date']),
      sharesCount: _parseInt(data['shares_count']),
      investmentAmount: _parseDouble(data['investment_amount'] ?? 0),
      paidAmount: _parseDouble(data['paid_amount'] ?? 0),
      realizedCapital: _parseDouble(data['realized_capital'] ?? 0),
      realizedInterest: _parseDouble(data['realized_interest'] ?? 0),
      transferToOtherProduct: _parseDouble(
        data['transfer_to_other_product'] ?? 0,
      ),
      remainingCapital: _parseDouble(data['remaining_capital'] ?? 0),
      remainingInterest: _parseDouble(data['remaining_interest'] ?? 0),
      plannedTax: _parseDouble(data['planned_tax'] ?? 0),
      realizedTax: _parseDouble(data['realized_tax'] ?? 0),
      currency: data['currency'] ?? 'PLN',
      exchangeRate: data['exchange_rate'] != null
          ? _parseDouble(data['exchange_rate'])
          : null,
      createdAt: _parseDate(data['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(data['updated_at']) ?? DateTime.now(),
      additionalInfo: data['additional_info'] != null
          ? Map<String, dynamic>.from(data['additional_info'])
          : {},
    );
  }

  MarketType _parseMarketType(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'primary':
        case 'rynek pierwotny':
          return MarketType.primary;
        case 'secondary':
        case 'rynek wtórny':
          return MarketType.secondary;
        case 'clientredemption':
        case 'odkup od klienta':
          return MarketType.clientRedemption;
        default:
          return MarketType.primary;
      }
    }
    return MarketType.primary;
  }
}
