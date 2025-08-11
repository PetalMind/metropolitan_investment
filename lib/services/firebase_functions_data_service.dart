import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../models/investment.dart';
import '../models/product.dart';
import '../models/bond.dart';
import '../models/share.dart';
import '../models/loan.dart';
import '../models/apartment.dart';
import 'base_service.dart';

/// 🚀 FIREBASE FUNCTIONS DATA SERVICE
/// Zarządzanie dużymi zbiorami danych przez server-side processing
///
/// ✅ FIXED: Null value handling in ProductStats.fromMap() methods
/// ✅ FIXED: Enhanced error logging for debugging
/// ✅ OPTIMIZED: All dashboard data now loads through Firebase Functions
class FirebaseFunctionsDataService extends BaseService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  // Cache management
  static final Map<String, dynamic> _staticCache = {};
  static final Map<String, DateTime> _staticCacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Loguje informacje w trybie debug
  void _logInfo(String message) {
    if (kDebugMode) {
      print('[FirebaseFunctionsDataService] $message');
    }
  }

  // =============================================
  // BONDS - OBLIGACJE
  // =============================================

  /// Pobiera obligacje z zaawansowanym filtrowaniem i paginacją
  Future<BondsResult> getBonds({
    int page = 1,
    int pageSize = 250,
    String sortBy = 'created_at',
    String sortDirection = 'desc',
    String? searchQuery,
    double? minRemainingCapital,
    String? productType,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey =
          'bonds_${page}_${pageSize}_${sortBy}_'
          '${sortDirection}_${searchQuery}_${minRemainingCapital}_$productType';

      if (!forceRefresh && _staticCache.containsKey(cacheKey)) {
        final timestamp = _staticCacheTimestamps[cacheKey];
        if (timestamp != null &&
            DateTime.now().difference(timestamp) < _cacheDuration) {
          _logInfo('Zwracam obligacje z cache');
          return _staticCache[cacheKey];
        }
      }

      _logInfo('Wywołuję getBonds z Firebase Functions');

      final callable = _functions.httpsCallable('getBonds');
      final result = await callable.call({
        'page': page,
        'pageSize': pageSize,
        'sortBy': sortBy,
        'sortDirection': sortDirection,
        'searchQuery': searchQuery,
        'minRemainingCapital': minRemainingCapital,
        'productType': productType,
      });

      final data = result.data as Map<String, dynamic>;
      final bondsResult = BondsResult.fromMap(data);

      // Cache wyników
      _staticCache[cacheKey] = bondsResult;
      _staticCacheTimestamps[cacheKey] = DateTime.now();

      _logInfo('Pobrano ${bondsResult.bonds.length} obligacji');
      return bondsResult;
    } catch (e) {
      logError('getBonds', e);
      throw Exception('Nie udało się pobrać obligacji: $e');
    }
  }

  // =============================================
  // SHARES - UDZIAŁY
  // =============================================

  /// Pobiera udziały z filtrowaniem
  Future<SharesResult> getShares({
    int page = 1,
    int pageSize = 250,
    String sortBy = 'created_at',
    String sortDirection = 'desc',
    String? searchQuery,
    int? minSharesCount,
    String? productType,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey =
          'shares_${page}_${pageSize}_${sortBy}_'
          '${sortDirection}_${searchQuery}_${minSharesCount}_$productType';

      if (!forceRefresh && _staticCache.containsKey(cacheKey)) {
        final timestamp = _staticCacheTimestamps[cacheKey];
        if (timestamp != null &&
            DateTime.now().difference(timestamp) < _cacheDuration) {
          _logInfo('Zwracam udziały z cache');
          return _staticCache[cacheKey];
        }
      }

      _logInfo('Wywołuję getShares z Firebase Functions');

      final callable = _functions.httpsCallable('getShares');
      final result = await callable.call({
        'page': page,
        'pageSize': pageSize,
        'sortBy': sortBy,
        'sortDirection': sortDirection,
        'searchQuery': searchQuery,
        'minSharesCount': minSharesCount,
        'productType': productType,
      });

      final data = result.data as Map<String, dynamic>;
      final sharesResult = SharesResult.fromMap(data);

      _staticCache[cacheKey] = sharesResult;
      _staticCacheTimestamps[cacheKey] = DateTime.now();

      _logInfo('Pobrano ${sharesResult.shares.length} udziałów');
      return sharesResult;
    } catch (e) {
      logError('getShares', e);
      throw Exception('Nie udało się pobrać udziałów: $e');
    }
  }

  // =============================================
  // LOANS - POŻYCZKI
  // =============================================

  /// Pobiera pożyczki z filtrowaniem
  Future<LoansResult> getLoans({
    int page = 1,
    int pageSize = 250,
    String sortBy = 'created_at',
    String sortDirection = 'desc',
    String? searchQuery,
    double? minRemainingCapital,
    String? status,
    String? borrower,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey =
          'loans_${page}_${pageSize}_${sortBy}_'
          '${sortDirection}_${searchQuery}_${minRemainingCapital}_${status}_$borrower';

      if (!forceRefresh && _staticCache.containsKey(cacheKey)) {
        final timestamp = _staticCacheTimestamps[cacheKey];
        if (timestamp != null &&
            DateTime.now().difference(timestamp) < _cacheDuration) {
          _logInfo('Zwracam pożyczki z cache');
          return _staticCache[cacheKey];
        }
      }

      _logInfo('Wywołuję getLoans z Firebase Functions');

      final callable = _functions.httpsCallable('getLoans');
      final result = await callable.call({
        'page': page,
        'pageSize': pageSize,
        'sortBy': sortBy,
        'sortDirection': sortDirection,
        'searchQuery': searchQuery,
        'minRemainingCapital': minRemainingCapital,
        'status': status,
        'borrower': borrower,
      });

      final data = result.data as Map<String, dynamic>;
      final loansResult = LoansResult.fromMap(data);

      _staticCache[cacheKey] = loansResult;
      _staticCacheTimestamps[cacheKey] = DateTime.now();

      _logInfo('Pobrano ${loansResult.loans.length} pożyczek');
      return loansResult;
    } catch (e) {
      logError('getLoans', e);
      throw Exception('Nie udało się pobrać pożyczek: $e');
    }
  }

  // =============================================
  // APARTMENTS - APARTAMENTY
  // =============================================

  /// Pobiera apartamenty z zaawansowanym filtrowaniem
  Future<ApartmentsResult> getApartments({
    int page = 1,
    int pageSize = 250,
    String sortBy = 'created_at',
    String sortDirection = 'desc',
    String? searchQuery,
    String? status,
    String? projectName,
    String? developer,
    double? minArea,
    double? maxArea,
    int? roomCount,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey =
          'apartments_${page}_${pageSize}_${sortBy}_'
          '${sortDirection}_${searchQuery}_${status}_${projectName}_'
          '${developer}_${minArea}_${maxArea}_$roomCount';

      if (!forceRefresh && _staticCache.containsKey(cacheKey)) {
        final timestamp = _staticCacheTimestamps[cacheKey];
        if (timestamp != null &&
            DateTime.now().difference(timestamp) < _cacheDuration) {
          _logInfo('Zwracam apartamenty z cache');
          return _staticCache[cacheKey];
        }
      }

      _logInfo('Wywołuję getApartments z Firebase Functions');

      final callable = _functions.httpsCallable('getApartments');
      final result = await callable.call({
        'page': page,
        'pageSize': pageSize,
        'sortBy': sortBy,
        'sortDirection': sortDirection,
        'searchQuery': searchQuery,
        'status': status,
        'projectName': projectName,
        'developer': developer,
        'minArea': minArea,
        'maxArea': maxArea,
        'roomCount': roomCount,
      });

      final data = result.data as Map<String, dynamic>;
      final apartmentsResult = ApartmentsResult.fromMap(data);

      _staticCache[cacheKey] = apartmentsResult;
      _staticCacheTimestamps[cacheKey] = DateTime.now();

      _logInfo('Pobrano ${apartmentsResult.apartments.length} apartamentów');
      return apartmentsResult;
    } catch (e) {
      logError('getApartments', e);
      throw Exception('Nie udało się pobrać apartamentów: $e');
    }
  }

  // =============================================
  // INVESTMENTS - INWESTYCJE (ENHANCED)
  // =============================================

  /// Pobiera inwestycje z zaawansowanym filtrowaniem (nowa metoda)
  Future<EnhancedInvestmentsResult> getEnhancedInvestments({
    int page = 1,
    int pageSize = 250,
    String sortBy = 'data_podpisania',
    String sortDirection = 'desc',
    String? searchQuery,
    String? clientId,
    String? productType,
    String? status,
    double? minRemainingCapital,
    String? dateFrom,
    String? dateTo,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey =
          'enhanced_investments_${page}_${pageSize}_${sortBy}_'
          '${sortDirection}_${searchQuery}_${clientId}_${productType}_'
          '${status}_${minRemainingCapital}_${dateFrom}_$dateTo';

      if (!forceRefresh && _staticCache.containsKey(cacheKey)) {
        final timestamp = _staticCacheTimestamps[cacheKey];
        if (timestamp != null &&
            DateTime.now().difference(timestamp) < _cacheDuration) {
          _logInfo('Zwracam enhanced inwestycje z cache');
          return _staticCache[cacheKey];
        }
      }

      _logInfo('Wywołuję getInvestments z Firebase Functions');

      final callable = _functions.httpsCallable('getInvestments');
      final result = await callable.call({
        'page': page,
        'pageSize': pageSize,
        'sortBy': sortBy,
        'sortDirection': sortDirection,
        'searchQuery': searchQuery,
        'clientId': clientId,
        'productType': productType,
        'status': status,
        'minRemainingCapital': minRemainingCapital,
        'dateFrom': dateFrom,
        'dateTo': dateTo,
      });

      final data = result.data as Map<String, dynamic>;
      final investmentsResult = EnhancedInvestmentsResult.fromMap(data);

      _staticCache[cacheKey] = investmentsResult;
      _staticCacheTimestamps[cacheKey] = DateTime.now();

      _logInfo(
        'Pobrano ${investmentsResult.investments.length} enhanced inwestycji',
      );
      return investmentsResult;
    } catch (e) {
      logError('getEnhancedInvestments', e);
      throw Exception('Nie udało się pobrać enhanced inwestycji: $e');
    }
  }

  // =============================================
  // STATISTICS - STATYSTYKI
  // =============================================

  /// Pobiera statystyki wszystkich typów produktów z obsługą błędów null
  Future<ProductTypeStatistics> getProductTypeStatistics({
    bool forceRefresh = false,
  }) async {
    try {
      const cacheKey = 'product_type_statistics';

      if (!forceRefresh && _staticCache.containsKey(cacheKey)) {
        final timestamp = _staticCacheTimestamps[cacheKey];
        if (timestamp != null &&
            DateTime.now().difference(timestamp) < _cacheDuration) {
          _logInfo('Zwracam statystyki z cache');
          return _staticCache[cacheKey];
        }
      }

      _logInfo('Wywołuję getProductTypeStatistics z Firebase Functions');

      final callable = _functions.httpsCallable('getProductTypeStatistics');
      final result = await callable.call();

      final data = result.data as Map<String, dynamic>;

      // Debug logging for null values
      if (kDebugMode) {
        _logInfo('Firebase Functions response: $data');
      }

      final statistics = ProductTypeStatistics.fromMap(data);

      _staticCache[cacheKey] = statistics;
      _staticCacheTimestamps[cacheKey] = DateTime.now();

      _logInfo('✅ Pobrano statystyki produktów z Firebase Functions');
      return statistics;
    } catch (e) {
      _logInfo('❌ Błąd w getProductTypeStatistics: $e');
      logError('getProductTypeStatistics', e);
      throw Exception('Nie udało się pobrać statystyk: $e');
    }
  }

  /// Czyści cache - przydatne po dodaniu/edycji danych
  static void clearDataCache() {
    _staticCache.clear();
    _staticCacheTimestamps.clear();
  }

  // =============================================
  // LEGACY METHODS - KLIENCI I INWESTYCJE
  // =============================================

  /// 👥 POBIERANIE KLIENTÓW Z SERWERA
  static Future<ClientsResult> getAllClients({
    int page = 1,
    int pageSize = 500,
    String? searchQuery,
    String sortBy = 'imie_nazwisko',
    bool forceRefresh = false,
  }) async {
    try {
      print('🔍 [Firebase Functions] Pobieranie klientów - strona $page');

      final callable = _functions.httpsCallable('getAllClients');
      final result = await callable.call({
        'page': page,
        'pageSize': pageSize,
        'searchQuery': searchQuery,
        'sortBy': sortBy,
        'forceRefresh': forceRefresh,
      });

      final data = result.data as Map<String, dynamic>;

      // Konwertuj surowe dane na modele Client
      final List<Client> clients = (data['clients'] as List)
          .map((clientData) => _convertToClient(clientData))
          .toList();

      return ClientsResult(
        clients: clients,
        totalCount: data['totalCount'] ?? 0,
        currentPage: data['currentPage'] ?? 1,
        pageSize: data['pageSize'] ?? pageSize,
        hasNextPage: data['hasNextPage'] ?? false,
        hasPreviousPage: data['hasPreviousPage'] ?? false,
        source: data['source'] ?? 'firebase-functions',
        processingTimeMs: data['processingTimeMs'],
        fromCache: data['fromCache'] ?? false,
      );
    } catch (e) {
      print('❌ [Firebase Functions] Błąd pobierania klientów: $e');
      rethrow;
    }
  }

  /// 💼 POBIERANIE INWESTYCJI Z SERWERA
  static Future<InvestmentsResult> getAllInvestments({
    int page = 1,
    int pageSize = 500,
    String? clientFilter,
    String? productTypeFilter,
    String sortBy = 'data_kontraktu',
    bool forceRefresh = false,
  }) async {
    try {
      print('💰 [Firebase Functions] Pobieranie inwestycji - strona $page');

      final callable = _functions.httpsCallable('getUnifiedProducts');
      final result = await callable.call({
        'page': page,
        'pageSize': pageSize,
        'clientFilter': clientFilter,
        'productTypeFilter': productTypeFilter,
        'sortBy': sortBy,
        'forceRefresh': forceRefresh,
      });

      final data = result.data as Map<String, dynamic>;

      // Konwertuj surowe dane na modele Investment
      // getUnifiedProducts zwraca 'products' nie 'investments'
      final productsData = data['products'] as List?;
      if (productsData == null) {
        throw Exception('Brak danych produktów w odpowiedzi z serwera');
      }

      final List<Investment> investments = productsData
          .map((investmentData) => _convertToInvestment(investmentData))
          .toList();

      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

      return InvestmentsResult(
        investments: investments,
        totalCount: pagination['totalItems'] ?? 0,
        currentPage: pagination['currentPage'] ?? 1,
        pageSize: pagination['pageSize'] ?? pageSize,
        hasNextPage: pagination['hasNext'] ?? false,
        hasPreviousPage: pagination['hasPrevious'] ?? false,
        appliedFilters: AppliedFilters(
          clientFilter: data['appliedFilters']?['clientFilter'],
          productTypeFilter: data['appliedFilters']?['productTypeFilter'],
        ),
        source: data['source'] ?? 'firebase-functions',
        processingTimeMs: data['processingTimeMs'],
        fromCache: data['fromCache'] ?? false,
      );
    } catch (e) {
      print('❌ [Firebase Functions] Błąd pobierania inwestycji: $e');
      rethrow;
    }
  }

  /// 📊 POBIERANIE STATYSTYK SYSTEMU
  static Future<SystemStats> getSystemStats({bool forceRefresh = false}) async {
    try {
      print('📈 [Firebase Functions] Pobieranie statystyk systemu');

      final callable = _functions.httpsCallable('getSystemStats');
      final result = await callable.call({'forceRefresh': forceRefresh});

      final data = result.data as Map<String, dynamic>;

      return SystemStats(
        totalClients: data['totalClients'] ?? 0,
        totalInvestments: data['totalInvestments'] ?? 0,
        totalInvestedCapital: (data['totalInvestedCapital'] ?? 0).toDouble(),
        totalRemainingCapital: (data['totalRemainingCapital'] ?? 0).toDouble(),
        averageInvestmentPerClient: (data['averageInvestmentPerClient'] ?? 0)
            .toDouble(),
        productTypeBreakdown: (data['productTypeBreakdown'] as List? ?? [])
            .map(
              (breakdown) => ProductTypeBreakdown(
                productType: breakdown['productType'] ?? '',
                count: breakdown['count'] ?? 0,
                totalCapital: (breakdown['totalCapital'] ?? 0).toDouble(),
                remainingCapital: (breakdown['remainingCapital'] ?? 0)
                    .toDouble(),
                averagePerInvestment: (breakdown['averagePerInvestment'] ?? 0)
                    .toDouble(),
              ),
            )
            .toList(),
        lastUpdated: DateTime.parse(
          data['lastUpdated'] ?? DateTime.now().toIso8601String(),
        ),
        source: data['source'] ?? 'firebase-functions',
      );
    } catch (e) {
      print('❌ [Firebase Functions] Błąd pobierania statystyk: $e');
      rethrow;
    }
  }

  // 🔄 HELPER METHODS

  /// Konwertuje surowe dane Firebase na model Client
  static Client _convertToClient(Map<String, dynamic> data) {
    return Client(
      id: data['id'] ?? '',
      name: data['imie_nazwisko'] ?? data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['telefon'] ?? data['phone'] ?? '',
      address: data['address'] ?? '',
      pesel: data['pesel'],
      companyName: data['nazwa_firmy'] ?? data['companyName'],
      type: ClientType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ClientType.individual,
      ),
      notes: data['notes'] ?? '',
      votingStatus: VotingStatus.values.firstWhere(
        (e) => e.name == data['votingStatus'],
        orElse: () => VotingStatus.undecided,
      ),
      colorCode: data['colorCode'] ?? '#FFFFFF',
      unviableInvestments: List<String>.from(data['unviableInvestments'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.parse(data['createdAt']))
          : (data['created_at'] != null
                ? DateTime.parse(data['created_at'])
                : DateTime.now()),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
                ? (data['updatedAt'] as Timestamp).toDate()
                : DateTime.parse(data['updatedAt']))
          : (data['uploaded_at'] != null
                ? DateTime.parse(data['uploaded_at'])
                : DateTime.now()),
      isActive: data['isActive'] ?? true,
      additionalInfo:
          data['additionalInfo'] ?? {'source_file': data['source_file']},
    );
  }

  /// Konwertuje surowe dane Firebase na model Investment
  static Investment _convertToInvestment(Map<String, dynamic> data) {
    // Helper function to safely convert to double
    double safeToDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    }

    // Helper function to parse date strings
    DateTime? parseDate(dynamic dateValue) {
      if (dateValue == null) return null;
      if (dateValue is DateTime) return dateValue;
      if (dateValue is String && dateValue.isEmpty) return null;
      try {
        return DateTime.parse(dateValue.toString());
      } catch (e) {
        return null;
      }
    }

    // Helper function to safely convert to string
    String safeToString(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      if (value is Map || value is List)
        return defaultValue; // Don't convert complex objects
      return value.toString();
    }

    Map<String, dynamic> _buildSafeAdditionalInfo(Map<String, dynamic> data) {
      final additionalInfo = <String, dynamic>{};

      // Safely add basic fields
      if (data['source_file'] != null) {
        additionalInfo['source_file'] = safeToString(data['source_file']);
      }
      if (data['id_sprzedaz'] != null) {
        additionalInfo['id_sprzedaz'] = safeToString(data['id_sprzedaz']);
      }

      // Safely merge nested additionalInfo
      final nestedInfo = data['additionalInfo'];
      if (nestedInfo is Map<String, dynamic>) {
        nestedInfo.forEach((key, value) {
          // Only add simple values to avoid type issues
          if (value is! Map && value is! List) {
            additionalInfo[key] = value;
          }
        });
      }

      return additionalInfo;
    }

    // Support both Polish field names (legacy) and English field names (getUnifiedProducts)
    return Investment(
      id: safeToString(data['id']),
      clientId: safeToString(data['clientId'] ?? data['id_klient']),
      clientName: safeToString(data['clientName'] ?? data['klient']),
      employeeId: '', // Not directly available
      employeeFirstName: safeToString(data['pracownik_imie']),
      employeeLastName: safeToString(data['pracownik_nazwisko']),
      branchCode: safeToString(data['oddzial']),
      status: _parseInvestmentStatus(
        safeToString(data['status'] ?? data['status_produktu']),
      ),
      isAllocated: (data['przydzial'] ?? 0) == 1 || (data['isActive'] == true),
      marketType: MarketType.values.firstWhere(
        (e) => e.displayName == safeToString(data['produkt_status_wejscie']),
        orElse: () => MarketType.primary,
      ),
      signedDate:
          parseDate(data['createdAt']) ??
          parseDate(data['data_podpisania']) ??
          parseDate(data['data_kontraktu']) ??
          DateTime.now(),
      entryDate: parseDate(data['data_wejscia_do_inwestycji']),
      exitDate: parseDate(data['data_wyjscia_z_inwestycji']),
      proposalId: safeToString(data['id_propozycja_nabycia']),
      productType: _parseProductType(
        safeToString(data['productType'] ?? data['typ_produktu']),
      ),
      productName: safeToString(
        data['name'] ?? data['productName'] ?? data['produkt_nazwa'],
      ),
      creditorCompany: safeToString(
        data['companyName'] ?? data['wierzyciel_spolka'],
      ),
      companyId: safeToString(data['companyId'] ?? data['id_spolka']),
      issueDate: parseDate(data['data_emisji']),
      redemptionDate: parseDate(data['data_wykupu']),
      sharesCount: data['ilosc_udzialow'],
      investmentAmount: safeToDouble(data['investmentAmount']) != 0
          ? safeToDouble(data['investmentAmount'])
          : safeToDouble(data['kwota_inwestycji']) != 0
          ? safeToDouble(data['kwota_inwestycji'])
          : safeToDouble(data['wartosc_kontraktu']),
      paidAmount: safeToDouble(data['kwota_wplat']),
      realizedCapital: safeToDouble(data['kapital_zrealizowany']) != 0
          ? safeToDouble(data['kapital_zrealizowany'])
          : safeToDouble(data['realizedCapital']),
      realizedInterest: safeToDouble(data['odsetki_zrealizowane']),
      transferToOtherProduct: safeToDouble(data['przekaz_na_inny_produkt']),
      remainingCapital: safeToDouble(data['totalValue']) != 0
          ? safeToDouble(data['totalValue'])
          : safeToDouble(data['kapital_pozostaly']) != 0
          ? safeToDouble(data['kapital_pozostaly'])
          : safeToDouble(data['remainingCapital']) != 0
          ? safeToDouble(data['remainingCapital'])
          : safeToDouble(data['wartosc_kontraktu']),
      remainingInterest: safeToDouble(data['odsetki_pozostale']),
      plannedTax: safeToDouble(data['planowany_podatek']),
      realizedTax: safeToDouble(data['zrealizowany_podatek']),
      currency: 'PLN',
      exchangeRate: null,
      createdAt: parseDate(data['created_at']) ?? DateTime.now(),
      updatedAt: parseDate(data['uploaded_at']) ?? DateTime.now(),
      additionalInfo: _buildSafeAdditionalInfo(data),
    );
  }

  /// Helper function to parse investment status from string
  static InvestmentStatus _parseInvestmentStatus(String? status) {
    if (status == null) return InvestmentStatus.active;

    switch (status.toLowerCase()) {
      case 'active':
      case 'aktywny':
        return InvestmentStatus.active;
      case 'inactive':
      case 'nieaktywny':
        return InvestmentStatus.inactive;
      case 'completed':
      case 'zakończony':
        return InvestmentStatus.completed;
      case 'earlyredemption':
      case 'wykup wczesniejszy':
        return InvestmentStatus.earlyRedemption;
      default:
        return InvestmentStatus.active;
    }
  }

  /// Helper function to parse product type from string
  static ProductType _parseProductType(String? productType) {
    if (productType == null) return ProductType.bonds;

    switch (productType.toLowerCase()) {
      case 'bonds':
      case 'obligacje':
        return ProductType.bonds;
      case 'loans':
      case 'pozyczki':
        return ProductType.loans;
      case 'shares':
      case 'udzialy':
        return ProductType.shares;
      case 'apartments':
      case 'mieszkania':
        return ProductType.apartments;
      default:
        return ProductType.bonds;
    }
  }
}

// =============================================
// RESULT CLASSES - KLASY WYNIKÓW
// =============================================

/// Wynik zapytania o obligacje
class BondsResult {
  final List<Bond> bonds;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final Map<String, dynamic> metadata;

  BondsResult({
    required this.bonds,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.metadata,
  });

  factory BondsResult.fromMap(Map<String, dynamic> map) {
    return BondsResult(
      bonds: (map['bonds'] as List<dynamic>)
          .map((item) => _createBondFromMap(item as Map<String, dynamic>))
          .toList(),
      total: map['total'] as int,
      page: map['page'] as int,
      pageSize: map['pageSize'] as int,
      totalPages: map['totalPages'] as int,
      hasNextPage: map['hasNextPage'] as bool,
      hasPreviousPage: map['hasPreviousPage'] as bool,
      metadata: map['metadata'] as Map<String, dynamic>,
    );
  }

  static Bond _createBondFromMap(Map<String, dynamic> data) {
    return Bond(
      id: data['id'] as String,
      productType: data['productType'] as String? ?? 'Obligacje',
      investmentAmount: (data['investmentAmount'] as num?)?.toDouble() ?? 0.0,
      realizedCapital: (data['realizedCapital'] as num?)?.toDouble() ?? 0.0,
      remainingCapital: (data['remainingCapital'] as num?)?.toDouble() ?? 0.0,
      realizedInterest: (data['realizedInterest'] as num?)?.toDouble() ?? 0.0,
      remainingInterest: (data['remainingInterest'] as num?)?.toDouble() ?? 0.0,
      realizedTax: (data['realizedTax'] as num?)?.toDouble() ?? 0.0,
      remainingTax: (data['remainingTax'] as num?)?.toDouble() ?? 0.0,
      transferToOtherProduct:
          (data['transferToOtherProduct'] as num?)?.toDouble() ?? 0.0,
      capitalForRestructuring: (data['capitalForRestructuring'] as num?)
          ?.toDouble(),
      capitalSecuredByRealEstate: (data['capitalSecuredByRealEstate'] as num?)
          ?.toDouble(),
      sourceFile: data['sourceFile'] as String? ?? 'imported_data.json',
      createdAt:
          DateTime.tryParse(data['createdAt'] as String? ?? '') ??
          DateTime.now(),
      uploadedAt:
          DateTime.tryParse(data['uploadedAt'] as String? ?? '') ??
          DateTime.now(),
      additionalInfo: Map<String, dynamic>.from(data)
        ..removeWhere(
          (key, value) => [
            'id',
            'productType',
            'investmentAmount',
            'realizedCapital',
            'remainingCapital',
            'realizedInterest',
            'remainingInterest',
            'realizedTax',
            'remainingTax',
            'transferToOtherProduct',
            'capitalForRestructuring',
            'capitalSecuredByRealEstate',
            'sourceFile',
            'createdAt',
            'uploadedAt',
          ].contains(key),
        ),
    );
  }
}

/// Wynik zapytania o udziały
class SharesResult {
  final List<Share> shares;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final Map<String, dynamic> metadata;

  SharesResult({
    required this.shares,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.metadata,
  });

  factory SharesResult.fromMap(Map<String, dynamic> map) {
    return SharesResult(
      shares: (map['shares'] as List<dynamic>)
          .map((item) => _createShareFromMap(item as Map<String, dynamic>))
          .toList(),
      total: map['total'] as int,
      page: map['page'] as int,
      pageSize: map['pageSize'] as int,
      totalPages: map['totalPages'] as int,
      hasNextPage: map['hasNextPage'] as bool,
      hasPreviousPage: map['hasPreviousPage'] as bool,
      metadata: map['metadata'] as Map<String, dynamic>,
    );
  }

  static Share _createShareFromMap(Map<String, dynamic> data) {
    return Share(
      id: data['id'] as String,
      productType: data['productType'] as String? ?? 'Udziały',
      investmentAmount: (data['investmentAmount'] as num?)?.toDouble() ?? 0.0,
      sharesCount: data['sharesCount'] as int? ?? 0,
      remainingCapital: (data['remainingCapital'] as num?)?.toDouble() ?? 0.0,
      capitalForRestructuring: (data['capitalForRestructuring'] as num?)
          ?.toDouble(),
      capitalSecuredByRealEstate: (data['capitalSecuredByRealEstate'] as num?)
          ?.toDouble(),
      sourceFile: data['sourceFile'] as String? ?? 'imported_data.json',
      createdAt:
          DateTime.tryParse(data['createdAt'] as String? ?? '') ??
          DateTime.now(),
      uploadedAt:
          DateTime.tryParse(data['uploadedAt'] as String? ?? '') ??
          DateTime.now(),
      additionalInfo: Map<String, dynamic>.from(data)
        ..removeWhere(
          (key, value) => [
            'id',
            'productType',
            'investmentAmount',
            'sharesCount',
            'remainingCapital',
            'capitalForRestructuring',
            'capitalSecuredByRealEstate',
            'sourceFile',
            'createdAt',
            'uploadedAt',
          ].contains(key),
        ),
    );
  }
}

/// Wynik zapytania o pożyczki
class LoansResult {
  final List<Loan> loans;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final Map<String, dynamic> metadata;

  LoansResult({
    required this.loans,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.metadata,
  });

  factory LoansResult.fromMap(Map<String, dynamic> map) {
    return LoansResult(
      loans: (map['loans'] as List<dynamic>)
          .map((item) => _createLoanFromMap(item as Map<String, dynamic>))
          .toList(),
      total: map['total'] as int,
      page: map['page'] as int,
      pageSize: map['pageSize'] as int,
      totalPages: map['totalPages'] as int,
      hasNextPage: map['hasNextPage'] as bool,
      hasPreviousPage: map['hasPreviousPage'] as bool,
      metadata: map['metadata'] as Map<String, dynamic>,
    );
  }

  static Loan _createLoanFromMap(Map<String, dynamic> data) {
    return Loan(
      id: data['id'] as String,
      productType: data['productType'] as String? ?? 'Pożyczki',
      investmentAmount: (data['investmentAmount'] as num?)?.toDouble() ?? 0.0,
      remainingCapital: (data['remainingCapital'] as num?)?.toDouble() ?? 0.0,
      capitalForRestructuring: (data['capitalForRestructuring'] as num?)
          ?.toDouble(),
      capitalSecuredByRealEstate: (data['capitalSecuredByRealEstate'] as num?)
          ?.toDouble(),
      sourceFile: data['sourceFile'] as String? ?? 'imported_data.json',
      createdAt:
          DateTime.tryParse(data['createdAt'] as String? ?? '') ??
          DateTime.now(),
      uploadedAt:
          DateTime.tryParse(data['uploadedAt'] as String? ?? '') ??
          DateTime.now(),
      loanNumber: data['loanNumber'] as String?,
      borrower: data['borrower'] as String?,
      interestRate: data['interestRate'] as String?,
      disbursementDate: data['disbursementDate'] != null
          ? DateTime.tryParse(data['disbursementDate'] as String)
          : null,
      repaymentDate: data['repaymentDate'] != null
          ? DateTime.tryParse(data['repaymentDate'] as String)
          : null,
      accruedInterest: (data['accruedInterest'] as num?)?.toDouble() ?? 0.0,
      collateral: data['collateral'] as String?,
      status: data['status'] as String?,
      additionalInfo: Map<String, dynamic>.from(data)
        ..removeWhere(
          (key, value) => [
            'id',
            'productType',
            'investmentAmount',
            'remainingCapital',
            'capitalForRestructuring',
            'capitalSecuredByRealEstate',
            'sourceFile',
            'createdAt',
            'uploadedAt',
            'loanNumber',
            'borrower',
            'interestRate',
            'disbursementDate',
            'repaymentDate',
            'accruedInterest',
            'collateral',
            'status',
          ].contains(key),
        ),
    );
  }
}

/// Wynik zapytania o apartamenty
class ApartmentsResult {
  final List<Apartment> apartments;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final Map<String, dynamic> metadata;

  ApartmentsResult({
    required this.apartments,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.metadata,
  });

  factory ApartmentsResult.fromMap(Map<String, dynamic> map) {
    return ApartmentsResult(
      apartments: (map['apartments'] as List<dynamic>)
          .map((item) => _createApartmentFromMap(item as Map<String, dynamic>))
          .toList(),
      total: map['total'] as int,
      page: map['page'] as int,
      pageSize: map['pageSize'] as int,
      totalPages: map['totalPages'] as int,
      hasNextPage: map['hasNextPage'] as bool,
      hasPreviousPage: map['hasPreviousPage'] as bool,
      metadata: map['metadata'] as Map<String, dynamic>,
    );
  }

  static Apartment _createApartmentFromMap(Map<String, dynamic> data) {
    // Helper do mapowania statusu
    ApartmentStatus mapStatus(String? status) {
      switch (status) {
        case 'Sprzedany':
          return ApartmentStatus.sold;
        case 'Zarezerwowany':
          return ApartmentStatus.reserved;
        case 'W budowie':
          return ApartmentStatus.underConstruction;
        case 'Gotowy':
          return ApartmentStatus.ready;
        default:
          return ApartmentStatus.available;
      }
    }

    // Helper do mapowania typu apartamentu
    ApartmentType mapApartmentType(String? type) {
      switch (type) {
        case 'Kawalerka':
          return ApartmentType.studio;
        case '2 pokoje':
          return ApartmentType.apartment2Room;
        case '3 pokoje':
          return ApartmentType.apartment3Room;
        case '4 pokoje':
          return ApartmentType.apartment4Room;
        case 'Penthouse':
          return ApartmentType.penthouse;
        default:
          return ApartmentType.other;
      }
    }

    return Apartment(
      id: data['id'] as String,
      productType: data['productType'] as String? ?? 'Apartamenty',
      investmentAmount: (data['investmentAmount'] as num?)?.toDouble() ?? 0.0,
      capitalForRestructuring: (data['capitalForRestructuring'] as num?)
          ?.toDouble(),
      capitalSecuredByRealEstate: (data['capitalSecuredByRealEstate'] as num?)
          ?.toDouble(),
      sourceFile: data['sourceFile'] as String? ?? 'imported_data.json',
      createdAt:
          DateTime.tryParse(data['createdAt'] as String? ?? '') ??
          DateTime.now(),
      uploadedAt:
          DateTime.tryParse(data['uploadedAt'] as String? ?? '') ??
          DateTime.now(),

      // Investment fields from the new model
      saleId: data['saleId'] as String? ?? '',
      clientId: data['clientId'] as String? ?? '',
      clientName: data['clientName'] as String? ?? '',
      advisor: data['advisor'] as String? ?? '',
      branch: data['branch'] as String? ?? '',
      productStatus: data['productStatus'] as String? ?? '',
      marketEntry: data['marketEntry'] as String? ?? '',
      signedDate: data['signedDate'] != null
          ? DateTime.tryParse(data['signedDate'] as String)
          : null,
      investmentEntryDate: data['investmentEntryDate'] != null
          ? DateTime.tryParse(data['investmentEntryDate'] as String)
          : null,
      projectName: data['projectName'] as String? ?? '',
      creditorCompany: data['creditorCompany'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      issueDate: data['issueDate'] != null
          ? DateTime.tryParse(data['issueDate'] as String)
          : null,
      redemptionDate: data['redemptionDate'] != null
          ? DateTime.tryParse(data['redemptionDate'] as String)
          : null,
      shareCount: data['shareCount'] as String?,
      paymentAmount: (data['paymentAmount'] as num?)?.toDouble() ?? 0.0,
      realizedCapital: (data['realizedCapital'] as num?)?.toDouble() ?? 0.0,
      transferToOtherProduct:
          (data['transferToOtherProduct'] as num?)?.toDouble() ?? 0.0,
      remainingCapital: (data['remainingCapital'] as num?)?.toDouble() ?? 0.0,

      // Apartment-specific fields
      apartmentNumber: data['apartmentNumber'] as String? ?? 'N/A',
      building: data['building'] as String? ?? 'N/A',
      address: data['address'] as String? ?? 'N/A',
      area: (data['area'] as num?)?.toDouble() ?? 0.0,
      roomCount: data['roomCount'] as int? ?? 0,
      floor: data['floor'] as int? ?? 0,
      status: mapStatus(data['status'] as String?),
      apartmentType: mapApartmentType(data['apartmentType'] as String?),
      pricePerSquareMeter:
          (data['pricePerSquareMeter'] as num?)?.toDouble() ?? 0.0,
      hasBalcony: data['hasBalcony'] as bool? ?? false,
      hasParkingSpace: data['hasParkingSpace'] as bool? ?? false,
      hasStorage: data['hasStorage'] as bool? ?? false,
      developer: data['developer'] as String? ?? 'N/A',

      additionalInfo: Map<String, dynamic>.from(data)
        ..removeWhere(
          (key, value) => [
            'id',
            'productType',
            'investmentAmount',
            'capitalForRestructuring',
            'capitalSecuredByRealEstate',
            'sourceFile',
            'createdAt',
            'uploadedAt',
            'saleId',
            'clientId',
            'clientName',
            'advisor',
            'branch',
            'productStatus',
            'marketEntry',
            'signedDate',
            'investmentEntryDate',
            'projectName',
            'creditorCompany',
            'companyId',
            'issueDate',
            'redemptionDate',
            'shareCount',
            'paymentAmount',
            'realizedCapital',
            'transferToOtherProduct',
            'remainingCapital',
            'apartmentNumber',
            'building',
            'address',
            'area',
            'roomCount',
            'floor',
            'status',
            'apartmentType',
            'pricePerSquareMeter',
            'hasBalcony',
            'hasParkingSpace',
            'hasStorage',
            'developer',
          ].contains(key),
        ),
    );
  }
}

/// Statystyki wszystkich typów produktów
class ProductTypeStatistics {
  final ProductStats bonds;
  final ProductStats shares;
  final ProductStats loans;
  final ProductStats apartments;
  final ProductStats investments;
  final SummaryStats summary;

  ProductTypeStatistics({
    required this.bonds,
    required this.shares,
    required this.loans,
    required this.apartments,
    required this.investments,
    required this.summary,
  });

  factory ProductTypeStatistics.fromMap(Map<String, dynamic> map) {
    return ProductTypeStatistics(
      bonds: ProductStats.fromMap(map['bonds'] as Map<String, dynamic>),
      shares: ProductStats.fromMap(map['shares'] as Map<String, dynamic>),
      loans: ProductStats.fromMap(map['loans'] as Map<String, dynamic>),
      apartments: ProductStats.fromMapWithArea(
        map['apartments'] as Map<String, dynamic>,
      ),
      investments: ProductStats.fromMap(
        map['investments'] as Map<String, dynamic>,
      ),
      summary: SummaryStats.fromMap(map['summary'] as Map<String, dynamic>),
    );
  }
}

/// Statystyki pojedynczego typu produktu
class ProductStats {
  final int count;
  final double totalValue;
  final double totalInvestmentAmount;
  final double averageValue;
  final double? totalArea;
  final double? averageArea;

  ProductStats({
    required this.count,
    required this.totalValue,
    required this.totalInvestmentAmount,
    required this.averageValue,
    this.totalArea,
    this.averageArea,
  });

  factory ProductStats.fromMap(Map<String, dynamic> map) {
    return ProductStats(
      count: map['count'] as int? ?? 0,
      totalValue: (map['totalValue'] as num?)?.toDouble() ?? 0.0,
      totalInvestmentAmount:
          (map['totalInvestmentAmount'] as num?)?.toDouble() ?? 0.0,
      averageValue: (map['averageValue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory ProductStats.fromMapWithArea(Map<String, dynamic> map) {
    return ProductStats(
      count: map['count'] as int? ?? 0,
      totalValue: (map['totalValue'] as num?)?.toDouble() ?? 0.0,
      totalInvestmentAmount:
          (map['totalInvestmentAmount'] as num?)?.toDouble() ?? 0.0,
      averageValue: (map['averageValue'] as num?)?.toDouble() ?? 0.0,
      totalArea: (map['totalArea'] as num?)?.toDouble(),
      averageArea: (map['averageArea'] as num?)?.toDouble(),
    );
  }
}

/// Statystyki podsumowujące
class SummaryStats {
  final int totalCount;
  final double totalValue;
  final double totalInvestmentAmount;

  SummaryStats({
    required this.totalCount,
    required this.totalValue,
    required this.totalInvestmentAmount,
  });

  factory SummaryStats.fromMap(Map<String, dynamic> map) {
    return SummaryStats(
      totalCount: map['totalCount'] as int? ?? 0,
      totalValue: (map['totalValue'] as num?)?.toDouble() ?? 0.0,
      totalInvestmentAmount:
          (map['totalInvestmentAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Wynik zapytania o enhanced inwestycje
class EnhancedInvestmentsResult {
  final List<Investment> investments;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final Map<String, dynamic> metadata;

  EnhancedInvestmentsResult({
    required this.investments,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.metadata,
  });

  factory EnhancedInvestmentsResult.fromMap(Map<String, dynamic> map) {
    return EnhancedInvestmentsResult(
      investments: (map['investments'] as List<dynamic>)
          .map((item) => _createInvestmentFromMap(item as Map<String, dynamic>))
          .toList(),
      total: map['total'] as int,
      page: map['page'] as int,
      pageSize: map['pageSize'] as int,
      totalPages: map['totalPages'] as int,
      hasNextPage: map['hasNextPage'] as bool,
      hasPreviousPage: map['hasPreviousPage'] as bool,
      metadata: map['metadata'] as Map<String, dynamic>,
    );
  }

  static Investment _createInvestmentFromMap(Map<String, dynamic> data) {
    // Helper function to safely convert to double
    double safeToDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    }

    // Helper function to parse date strings
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return null;
      }
    }

    // Helper to map product type
    ProductType mapProductType(String? productType) {
      switch (productType) {
        case 'shares':
          return ProductType.shares;
        case 'loans':
          return ProductType.loans;
        case 'apartments':
          return ProductType.apartments;
        default:
          return ProductType.bonds;
      }
    }

    // Helper to map investment status
    InvestmentStatus mapStatus(String? status) {
      switch (status) {
        case 'inactive':
          return InvestmentStatus.inactive;
        case 'earlyRedemption':
          return InvestmentStatus.earlyRedemption;
        case 'completed':
          return InvestmentStatus.completed;
        default:
          return InvestmentStatus.active;
      }
    }

    // Helper to map market type
    MarketType mapMarketType(String? marketType) {
      switch (marketType) {
        case 'secondary':
          return MarketType.secondary;
        case 'clientRedemption':
          return MarketType.clientRedemption;
        default:
          return MarketType.primary;
      }
    }

    return Investment(
      id: data['id'] as String,
      clientId: data['clientId'] as String? ?? '',
      clientName: data['clientName'] as String? ?? '',
      employeeId: data['employeeId'] as String? ?? '',
      employeeFirstName: data['employeeFirstName'] as String? ?? '',
      employeeLastName: data['employeeLastName'] as String? ?? '',
      branchCode: data['branchCode'] as String? ?? '',
      status: mapStatus(data['status'] as String?),
      isAllocated: data['isAllocated'] as bool? ?? false,
      marketType: mapMarketType(data['marketType'] as String?),
      signedDate: parseDate(data['signedDate'] as String?) ?? DateTime.now(),
      entryDate: parseDate(data['entryDate'] as String?),
      exitDate: parseDate(data['exitDate'] as String?),
      proposalId: data['proposalId'] as String? ?? '',
      productType: mapProductType(data['productType'] as String?),
      productName: data['productName'] as String? ?? '',
      creditorCompany: data['creditorCompany'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      issueDate: parseDate(data['issueDate'] as String?),
      redemptionDate: parseDate(data['redemptionDate'] as String?),
      sharesCount: data['sharesCount'] as int?,
      investmentAmount: safeToDouble(data['investmentAmount']),
      paidAmount: safeToDouble(data['paidAmount']),
      realizedCapital: safeToDouble(data['realizedCapital']),
      realizedInterest: safeToDouble(data['realizedInterest']),
      transferToOtherProduct: safeToDouble(data['transferToOtherProduct']),
      remainingCapital: safeToDouble(data['remainingCapital']),
      remainingInterest: safeToDouble(data['remainingInterest']),
      plannedTax: safeToDouble(data['plannedTax']),
      realizedTax: safeToDouble(data['realizedTax']),
      currency: data['currency'] as String? ?? 'PLN',
      createdAt: parseDate(data['createdAt'] as String?) ?? DateTime.now(),
      updatedAt: parseDate(data['updatedAt'] as String?) ?? DateTime.now(),
      additionalInfo: {
        'source_file': data['source_file'],
        'id_sprzedaz': data['id_sprzedaz'],
      },
    );
  }
}

// 📊 LEGACY DATA MODELS FOR RESULTS - ISTNIEJĄCE KLASY

class ClientsResult {
  final List<Client> clients;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final String source;
  final int? processingTimeMs;
  final bool fromCache;

  ClientsResult({
    required this.clients,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.source,
    this.processingTimeMs,
    this.fromCache = false,
  });
}

class InvestmentsResult {
  final List<Investment> investments;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final AppliedFilters appliedFilters;
  final String source;
  final int? processingTimeMs;
  final bool fromCache;

  InvestmentsResult({
    required this.investments,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.appliedFilters,
    required this.source,
    this.processingTimeMs,
    this.fromCache = false,
  });
}

class AppliedFilters {
  final String? clientFilter;
  final String? productTypeFilter;

  AppliedFilters({this.clientFilter, this.productTypeFilter});
}

class SystemStats {
  final int totalClients;
  final int totalInvestments;
  final double totalInvestedCapital;
  final double totalRemainingCapital;
  final double averageInvestmentPerClient;
  final List<ProductTypeBreakdown> productTypeBreakdown;
  final DateTime lastUpdated;
  final String source;

  SystemStats({
    required this.totalClients,
    required this.totalInvestments,
    required this.totalInvestedCapital,
    required this.totalRemainingCapital,
    required this.averageInvestmentPerClient,
    required this.productTypeBreakdown,
    required this.lastUpdated,
    required this.source,
  });
}

class ProductTypeBreakdown {
  final String productType;
  final int count;
  final double totalCapital;
  final double remainingCapital;
  final double averagePerInvestment;

  ProductTypeBreakdown({
    required this.productType,
    required this.count,
    required this.totalCapital,
    required this.remainingCapital,
    required this.averagePerInvestment,
  });
}
