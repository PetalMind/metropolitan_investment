import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client.dart';
import '../models/investment.dart';
import '../models/product.dart';

/// 🚀 FIREBASE FUNCTIONS DATA SERVICE
/// Zarządzanie dużymi zbiorami danych przez server-side processing
class FirebaseFunctionsDataService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

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

      final callable = _functions.httpsCallable('getAllInvestments');
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
      final List<Investment> investments = (data['investments'] as List)
          .map((investmentData) => _convertToInvestment(investmentData))
          .toList();

      return InvestmentsResult(
        investments: investments,
        totalCount: data['totalCount'] ?? 0,
        currentPage: data['currentPage'] ?? 1,
        pageSize: data['pageSize'] ?? pageSize,
        hasNextPage: data['hasNextPage'] ?? false,
        hasPreviousPage: data['hasPreviousPage'] ?? false,
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
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return null;
      }
    }

    return Investment(
      id: data['id'] ?? '',
      clientId: data['id_klient']?.toString() ?? '',
      clientName: data['klient'] ?? '',
      employeeId: '', // Not directly available
      employeeFirstName: data['pracownik_imie'] ?? '',
      employeeLastName: data['pracownik_nazwisko'] ?? '',
      branchCode: data['oddzial'] ?? '',
      status: InvestmentStatus.values.firstWhere(
        (e) => e.displayName == data['status_produktu'],
        orElse: () => InvestmentStatus.active,
      ),
      isAllocated: (data['przydzial'] ?? 0) == 1,
      marketType: MarketType.values.firstWhere(
        (e) => e.displayName == data['produkt_status_wejscie'],
        orElse: () => MarketType.primary,
      ),
      signedDate:
          parseDate(data['data_podpisania']) ??
          parseDate(data['data_kontraktu']) ??
          DateTime.now(),
      entryDate: parseDate(data['data_wejscia_do_inwestycji']),
      exitDate: parseDate(data['data_wyjscia_z_inwestycji']),
      proposalId: data['id_propozycja_nabycia']?.toString() ?? '',
      productType: ProductType.values.firstWhere(
        (e) => e.displayName == data['typ_produktu'],
        orElse: () => ProductType.bonds,
      ),
      productName: data['produkt_nazwa'] ?? '',
      creditorCompany: data['wierzyciel_spolka'] ?? '',
      companyId: data['id_spolka'] ?? '',
      issueDate: parseDate(data['data_emisji']),
      redemptionDate: parseDate(data['data_wykupu']),
      sharesCount: data['ilosc_udzialow'],
      investmentAmount: safeToDouble(data['kwota_inwestycji']) != 0
          ? safeToDouble(data['kwota_inwestycji'])
          : safeToDouble(data['wartosc_kontraktu']),
      paidAmount: safeToDouble(data['kwota_wplat']),
      realizedCapital: safeToDouble(data['kapital_zrealizowany']) != 0
          ? safeToDouble(data['kapital_zrealizowany'])
          : safeToDouble(data['realizedCapital']),
      realizedInterest: safeToDouble(data['odsetki_zrealizowane']),
      transferToOtherProduct: safeToDouble(data['przekaz_na_inny_produkt']),
      remainingCapital: safeToDouble(data['kapital_pozostaly']) != 0
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
      additionalInfo: {
        'source_file': data['source_file'],
        'id_sprzedaz': data['id_sprzedaz'],
        ...data['additionalInfo'] ?? {},
      },
    );
  }
}

// 📊 DATA MODELS FOR RESULTS

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
