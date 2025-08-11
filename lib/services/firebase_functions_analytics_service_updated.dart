import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client.dart';
import '../models/investor_summary.dart';
import '../models/investment.dart';
import '../models/product.dart';
import 'base_service.dart';

/// 🚀 ZAKTUALIZOWANY FIREBASE FUNCTIONS ANALYTICS SERVICE
/// Wykorzystuje nowe modularne funkcje Firebase Functions z optimizacją wydajności
///
/// DOSTĘPNE FUNKCJE:
/// - getOptimizedInvestorAnalytics (z analytics-service.js)
/// - getAllClients (z clients-service.js)
/// - getUnifiedProducts (z products-service.js)
/// - getUnifiedProductStatistics (z statistics-service.js)
/// - getProductInvestorsOptimized (z product-investors-optimization.js)
/// - debugClientsTest (z debug-service.js)
class FirebaseFunctionsAnalyticsServiceUpdated extends BaseService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  /// **GŁÓWNA ANALITYKA INWESTORÓW** 🎯
  /// Wykorzystuje nową funkcję getOptimizedInvestorAnalytics z analytics-service.js
  /// Obecnie w fazie placeholder - będzie rozszerzona
  Future<InvestorAnalyticsResult> getOptimizedInvestorAnalytics({
    int page = 1,
    int pageSize = 250,
    String sortBy = 'viableRemainingCapital',
    bool sortAscending = false,
    bool includeInactive = false,
    VotingStatus? votingStatusFilter,
    ClientType? clientTypeFilter,
    bool showOnlyWithUnviableInvestments = false,
    String? searchQuery,
    bool forceRefresh = false,
  }) async {
    final startTime = DateTime.now();
    print('🚀 [Updated Functions Service] Rozpoczynam analizę inwestorów...');

    try {
      final callable = _functions.httpsCallable(
        'getOptimizedInvestorAnalytics',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 5)),
      );

      final response = await callable.call({
        'page': page,
        'pageSize': pageSize,
        'sortBy': sortBy,
        'sortAscending': sortAscending,
        'includeInactive': includeInactive,
        'votingStatusFilter': votingStatusFilter?.name,
        'clientTypeFilter': clientTypeFilter?.name,
        'showOnlyWithUnviableInvestments': showOnlyWithUnviableInvestments,
        'searchQuery': searchQuery,
        'forceRefresh': forceRefresh,
      });

      final data = response.data as Map<String, dynamic>;
      final executionTime = DateTime.now().difference(startTime);

      print(
        '⚡ [Updated Functions Service] Otrzymano odpowiedź w ${executionTime.inMilliseconds}ms',
      );
      print('📊 [Updated Functions Service] Status: ${data['message']}');
      print('📊 [Updated Functions Service] Source: ${data['source']}');

      // Parse investors z Firebase Functions response
      final investorsData = data['investors'] as List? ?? [];
      final allInvestorsData = data['allInvestors'] as List? ?? [];

      final investors = investorsData
          .map(
            (investorData) => _parseInvestorSummaryFromFunctions(investorData),
          )
          .toList();

      final allInvestors = allInvestorsData
          .map(
            (investorData) => _parseInvestorSummaryFromFunctions(investorData),
          )
          .toList();

      // Parse voting distribution
      final votingDistributionData =
          data['votingDistribution'] as Map<String, dynamic>? ?? {};
      final votingDistribution = <VotingStatus, VotingCapitalInfo>{};

      for (final status in VotingStatus.values) {
        final statusData =
            votingDistributionData[status.name] as Map<String, dynamic>?;
        votingDistribution[status] = VotingCapitalInfo(
          count: statusData?['count'] ?? 0,
          capital: (statusData?['capital'] ?? 0.0).toDouble(),
        );
      }

      print(
        '✅ [Updated Functions Service] Przetworzono ${investors.length} inwestorów',
      );

      return InvestorAnalyticsResult(
        investors: investors,
        allInvestors: allInvestors,
        totalCount: data['totalCount'] ?? 0,
        currentPage: data['currentPage'] ?? page,
        pageSize: data['pageSize'] ?? pageSize,
        hasNextPage: data['hasNextPage'] ?? false,
        hasPreviousPage: data['hasPreviousPage'] ?? false,
        totalViableCapital: (data['totalViableCapital'] ?? 0.0).toDouble(),
        votingDistribution: votingDistribution,
        executionTimeMs:
            data['executionTimeMs'] ?? executionTime.inMilliseconds,
        source: data['source'] ?? 'firebase-functions-updated',
        message: data['message'] as String?,
        timestamp: data['timestamp'] as String?,
      );
    } catch (e) {
      print('❌ [Updated Functions Service] Błąd analizy inwestorów: $e');
      throw Exception('Błąd Firebase Functions Analytics: $e');
    }
  }

  /// **POBIERANIE WSZYSTKICH KLIENTÓW** 👥
  /// Wykorzystuje funkcję getAllClients z clients-service.js
  Future<ClientsResult> getAllClients({
    int page = 1,
    int pageSize = 500,
    String? searchQuery,
    String sortBy = 'imie_nazwisko',
    bool forceRefresh = false,
  }) async {
    print('👥 [Updated Functions Service] Pobieranie klientów...');

    try {
      final callable = _functions.httpsCallable('getAllClients');

      final response = await callable.call({
        'page': page,
        'pageSize': pageSize,
        'searchQuery': searchQuery,
        'sortBy': sortBy,
        'forceRefresh': forceRefresh,
      });

      final data = response.data as Map<String, dynamic>;

      final clients = (data['clients'] as List? ?? [])
          .map((clientData) => _convertToClient(clientData))
          .toList();

      print('✅ [Updated Functions Service] Pobrano ${clients.length} klientów');

      return ClientsResult(
        clients: clients,
        totalCount: data['totalCount'] ?? 0,
        currentPage: data['currentPage'] ?? page,
        pageSize: data['pageSize'] ?? pageSize,
        hasNextPage: data['hasNextPage'] ?? false,
        hasPreviousPage: data['hasPreviousPage'] ?? false,
        source: data['source'] ?? 'firebase-functions',
        processingTime: data['processingTime'],
      );
    } catch (e) {
      print('❌ [Updated Functions Service] Błąd pobierania klientów: $e');
      throw Exception('Błąd pobierania klientów: $e');
    }
  }

  /// **POBIERANIE ZUNIFIKOWANYCH PRODUKTÓW** 📦
  /// Wykorzystuje funkcję getUnifiedProducts z products-service.js
  Future<ProductsResult> getUnifiedProducts({
    int page = 1,
    int pageSize = 100,
    String? productType,
    String? companyFilter,
    String? statusFilter,
    String? searchQuery,
    String sortBy = 'createdAt',
    bool sortAscending = false,
    bool forceRefresh = false,
  }) async {
    print(
      '📦 [Updated Functions Service] Pobieranie zunifikowanych produktów...',
    );

    try {
      final callable = _functions.httpsCallable('getUnifiedProducts');

      final response = await callable.call({
        'page': page,
        'pageSize': pageSize,
        'productType': productType,
        'companyFilter': companyFilter,
        'statusFilter': statusFilter,
        'searchQuery': searchQuery,
        'sortBy': sortBy,
        'sortAscending': sortAscending,
        'forceRefresh': forceRefresh,
      });

      final data = response.data as Map<String, dynamic>;

      print('✅ [Updated Functions Service] Pobrano produkty');
      print(
        '📊 [Updated Functions Service] Wykonanie: ${data['metadata']?['executionTime']}ms',
      );

      return ProductsResult(
        products: data['products'] as List? ?? [],
        pagination: PaginationInfo(
          currentPage: data['pagination']?['currentPage'] ?? page,
          pageSize: data['pagination']?['pageSize'] ?? pageSize,
          totalItems: data['pagination']?['totalItems'] ?? 0,
          totalPages: data['pagination']?['totalPages'] ?? 0,
          hasNext: data['pagination']?['hasNext'] ?? false,
          hasPrevious: data['pagination']?['hasPrevious'] ?? false,
        ),
        metadata: ResultMetadata(
          timestamp: data['metadata']?['timestamp'],
          executionTime: data['metadata']?['executionTime'],
          cacheUsed: data['metadata']?['cacheUsed'] ?? false,
          filters: data['metadata']?['filters'],
        ),
      );
    } catch (e) {
      print('❌ [Updated Functions Service] Błąd pobierania produktów: $e');
      throw Exception('Błąd pobierania produktów: $e');
    }
  }

  /// **STATYSTYKI PRODUKTÓW** 📈
  /// Wykorzystuje funkcję getUnifiedProductStatistics z statistics-service.js
  Future<ProductStatisticsResult> getUnifiedProductStatistics({
    bool forceRefresh = false,
  }) async {
    print('📈 [Updated Functions Service] Pobieranie statystyk produktów...');

    try {
      final callable = _functions.httpsCallable('getUnifiedProductStatistics');

      final response = await callable.call({'forceRefresh': forceRefresh});

      final data = response.data as Map<String, dynamic>;

      print('✅ [Updated Functions Service] Pobrano statystyki produktów');
      print(
        '📊 [Updated Functions Service] Wykonanie: ${data['metadata']?['executionTime']}ms',
      );

      return ProductStatisticsResult(
        totalProducts: data['totalProducts'] ?? 0,
        totalValue: (data['totalValue'] ?? 0).toDouble(),
        productTypeBreakdown: (data['productTypeBreakdown'] as List? ?? [])
            .map(
              (breakdown) => ProductTypeStatistics(
                type: breakdown['type'] ?? '',
                typeName: breakdown['typeName'] ?? '',
                count: breakdown['count'] ?? 0,
                totalValue: (breakdown['totalValue'] ?? 0).toDouble(),
                averageValue: (breakdown['averageValue'] ?? 0).toDouble(),
                percentage: (breakdown['percentage'] ?? 0).toDouble(),
              ),
            )
            .toList(),
        metadata: ResultMetadata(
          timestamp: data['metadata']?['timestamp'],
          executionTime: data['metadata']?['executionTime'],
          cacheUsed: data['metadata']?['cacheUsed'] ?? false,
          filters: data['metadata']?['filters'],
        ),
      );
    } catch (e) {
      print('❌ [Updated Functions Service] Błąd pobierania statystyk: $e');
      throw Exception('Błąd pobierania statystyk produktów: $e');
    }
  }

  /// **INWESTORZY PRODUKTU** 🔍
  /// Wykorzystuje funkcję getProductInvestorsOptimized z product-investors-optimization.js
  Future<ProductInvestorsResult> getProductInvestorsOptimized({
    String? productName,
    String? productType,
    String searchStrategy = 'comprehensive',
    bool forceRefresh = false,
  }) async {
    print('🔍 [Updated Functions Service] Wyszukiwanie inwestorów produktu...');

    try {
      final callable = _functions.httpsCallable('getProductInvestorsOptimized');

      final response = await callable.call({
        'productName': productName,
        'productType': productType,
        'searchStrategy': searchStrategy,
        'forceRefresh': forceRefresh,
      });

      final data = response.data as Map<String, dynamic>;

      print('✅ [Updated Functions Service] Znaleziono inwestorów produktu');
      print(
        '📊 [Updated Functions Service] Wykonanie: ${data['executionTime']}ms',
      );

      return ProductInvestorsResult(
        investors: (data['investors'] as List? ?? [])
            .map((investorData) => _convertToInvestorSummary(investorData))
            .toList(),
        totalCount: data['totalCount'] ?? 0,
        productInfo: ProductInfo(
          name: data['productInfo']?['name'] ?? '',
          type: data['productInfo']?['type'] ?? '',
          totalCapital: (data['productInfo']?['totalCapital'] ?? 0).toDouble(),
        ),
        searchResults: SearchResults(
          searchType: data['searchResults']?['searchType'] ?? '',
          matchingProducts: data['searchResults']?['matchingProducts'] ?? 0,
          totalInvestments: data['searchResults']?['totalInvestments'] ?? 0,
        ),
        fromCache: data['fromCache'] ?? false,
        executionTime: data['executionTime'] ?? 0,
      );
    } catch (e) {
      print('❌ [Updated Functions Service] Błąd wyszukiwania inwestorów: $e');
      throw Exception('Błąd wyszukiwania inwestorów produktu: $e');
    }
  }

  /// **TEST DEBUGOWANIA** 🧪
  /// Wykorzystuje funkcję debugClientsTest z debug-service.js
  Future<DebugResult> debugClientsTest() async {
    print('🧪 [Updated Functions Service] Uruchamianie testu debug...');

    try {
      final callable = _functions.httpsCallable('debugClientsTest');
      final response = await callable.call({});
      final data = response.data as Map<String, dynamic>;

      print('✅ [Updated Functions Service] Test debug zakończony');

      return DebugResult(
        functionStatus: data['functionStatus'] ?? 'unknown',
        version: data['version'] ?? '1.0.0',
        message: data['message'],
        additionalInfo: data,
      );
    } catch (e) {
      print('❌ [Updated Functions Service] Błąd testu debug: $e');
      throw Exception('Błąd testu debug: $e');
    }
  }

  /// **CZYSZCZENIE CACHE** 🗑️
  /// Czyści cache zarówno lokalnie jak i na serwerze
  Future<void> clearAnalyticsCache() async {
    try {
      print('🗑️ [Updated Functions Service] Czyszczenie cache...');

      // Wyczyść lokalny cache
      clearAllCache();

      // Wyczyść cache na serwerze
      try {
        print(
          '🗑️ [Functions Service] Rozpoczynam czyszczenie cache na serwerze...',
        );

        final callable = _functions.httpsCallable(
          'clearAnalyticsCache',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
        );

        await callable.call({});
        print('✅ [Functions Service] Cache serwera wyczyszczony');
      } catch (serverError) {
        print(
          '❌ [Functions Service] Błąd czyszczenia cache serwera: $serverError',
        );
        // Nie rethrow - czyszczenie cache nie powinno blokować głównej operacji
      }
      print('✅ [Updated Functions Service] Cache wyczyszczony');
    } catch (e) {
      print('❌ [Updated Functions Service] Błąd czyszczenia cache: $e');
      // Nie rethrow - czyszczenie cache nie powinno blokować
    }
  }

  // 🛠️ HELPER METHODS

  /// Konwertuje dane inwestora z Firebase Functions do InvestorSummary
  InvestorSummary _parseInvestorSummaryFromFunctions(
    Map<String, dynamic> data,
  ) {
    try {
      // Parse client data
      final clientData = data['client'] as Map<String, dynamic>;
      final client = Client(
        id: clientData['id'] ?? '',
        name: clientData['name'] ?? '',
        email: clientData['email'] ?? '',
        phone: clientData['phone'] ?? '',
        address: '', // Nie jest zwracany z Functions
        companyName: clientData['companyName'],
        type: ClientType.values.firstWhere(
          (e) => e.name == clientData['type'],
          orElse: () => ClientType.individual,
        ),
        votingStatus: VotingStatus.values.firstWhere(
          (e) => e.name == clientData['votingStatus'],
          orElse: () => VotingStatus.undecided,
        ),
        unviableInvestments: List<String>.from(
          clientData['unviableInvestments'] ?? [],
        ),
        createdAt: DateTime.now(), // Default - nie jest zwracany z Functions
        updatedAt: DateTime.now(), // Default - nie jest zwracany z Functions
      );

      // Parse investments data
      final investmentsData = data['investments'] as List? ?? [];
      final investments = investmentsData.map((invData) {
        final invMap = invData as Map<String, dynamic>;
        return Investment(
          id: invMap['id'] ?? '',
          clientId: invMap['clientId'] ?? '',
          clientName: invMap['clientName'] ?? '',
          employeeId: invMap['employeeId'] ?? '',
          employeeFirstName: invMap['employeeFirstName'] ?? '',
          employeeLastName: invMap['employeeLastName'] ?? '',
          branchCode: invMap['branch'] ?? invMap['branchCode'] ?? '',
          status: InvestmentStatus.active, // Default
          marketType: MarketType.primary, // Default
          signedDate: DateTime.now(), // Default
          proposalId: invMap['saleId'] ?? '',
          productType: _parseProductType(invMap['productType']),
          productName: invMap['productName'] ?? '',
          creditorCompany: invMap['creditorCompany'] ?? '',
          companyId: invMap['companyId'] ?? '',
          investmentAmount: (invMap['investmentAmount'] ?? 0.0).toDouble(),
          paidAmount: (invMap['paidAmount'] ?? 0.0).toDouble(),
          remainingCapital: (invMap['remainingCapital'] ?? 0.0).toDouble(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();

      return InvestorSummary.fromInvestments(client, investments);
    } catch (e) {
      print('❌ [Parse Error] Błąd parsowania InvestorSummary: $e');
      print('❌ [Parse Error] Data: $data');
      rethrow;
    }
  }

  /// Parsuje ProductType z stringa
  ProductType _parseProductType(String? type) {
    if (type == null) return ProductType.bonds; // Default

    switch (type.toLowerCase()) {
      case 'loan':
      case 'loans':
        return ProductType.loans;
      case 'bond':
      case 'bonds':
        return ProductType.bonds;
      case 'share':
      case 'shares':
        return ProductType.shares;
      case 'apartment':
      case 'apartments':
        return ProductType.apartments;
      default:
        return ProductType.bonds; // Default
    }
  }

  InvestorSummary _convertToInvestorSummary(Map<String, dynamic> data) {
    final clientData = data['client'] as Map<String, dynamic>? ?? {};
    final investmentsData = data['investments'] as List? ?? [];

    final client = _convertToClient(clientData);
    final investments = investmentsData
        .map((invData) => _convertToInvestment(invData))
        .toList();

    return InvestorSummary(
      client: client,
      investments: investments,
      totalRemainingCapital: (data['totalRemainingCapital'] ?? 0).toDouble(),
      totalSharesValue: (data['totalSharesValue'] ?? 0).toDouble(),
      totalValue: (data['totalValue'] ?? 0).toDouble(),
      totalInvestmentAmount: (data['totalInvestmentAmount'] ?? 0).toDouble(),
      totalRealizedCapital: (data['totalRealizedCapital'] ?? 0).toDouble(),
      capitalSecuredByRealEstate: (data['capitalSecuredByRealEstate'] ?? 0)
          .toDouble(),
      capitalForRestructuring: (data['capitalForRestructuring'] ?? 0)
          .toDouble(),
      investmentCount: data['investmentCount'] ?? 0,
    );
  }

  Investment _convertToInvestment(Map<String, dynamic> data) {
    return Investment(
      id: (data['id'] ?? '').toString(),
      clientId: (data['id_klient'] ?? '').toString(),
      clientName: data['klient'] ?? '',
      employeeId: '',
      employeeFirstName: data['pracownik_imie'] ?? '',
      employeeLastName: data['pracownik_nazwisko'] ?? '',
      branchCode: data['kod_oddzialu'] ?? data['oddzial'] ?? '',
      status: _parseInvestmentStatus(data['status_produktu']),
      isAllocated: data['przydzial']?.toString() == '1',
      marketType: MarketType.primary,
      signedDate:
          _parseDate(data['data_podpisania'] ?? data['data_kontraktu']) ??
          DateTime.now(),
      entryDate: _parseDate(
        data['data_zawarcia'] ?? data['data_wejscia_do_inwestycji'],
      ),
      exitDate: _parseDate(
        data['data_wymagalnosci'] ?? data['data_wyjscia_z_inwestycji'],
      ),
      proposalId:
          (data['numer_kontraktu'] ?? data['id_propozycja_nabycia'] ?? '')
              .toString(),
      productType: _parseProductType(data['typ_produktu']),
      productName: data['nazwa_produktu'] ?? data['produkt_nazwa'] ?? '',
      creditorCompany: data['wierzyciel_spolka'] ?? '',
      companyId: (data['id_spolka'] ?? '').toString(),
      issueDate: _parseDate(data['data_emisji']),
      redemptionDate: _parseDate(data['data_wykupu']),
      investmentAmount:
          (data['investmentAmount'] ?? data['kwota_inwestycji'] ?? 0)
              .toDouble(),
      paidAmount: (data['kwota_wplat'] ?? data['investmentAmount'] ?? 0)
          .toDouble(),
      realizedCapital:
          (data['realizedCapital'] ?? data['kapital_zrealizowany'] ?? 0)
              .toDouble(),
      realizedInterest: (data['odsetki_zrealizowane'] ?? 0).toDouble(),
      transferToOtherProduct: (data['przekaz_na_inny_produkt'] ?? 0).toDouble(),
      remainingCapital:
          (data['remainingCapital'] ??
                  data['kapital_pozostaly'] ??
                  data['kapital_do_restrukturyzacji'] ??
                  0)
              .toDouble(),
      remainingInterest: (data['odsetki_pozostale'] ?? 0).toDouble(),
      plannedTax: (data['planowany_podatek'] ?? 0).toDouble(),
      realizedTax: (data['zrealizowany_podatek'] ?? 0).toDouble(),
      currency: data['waluta']?.toString() ?? 'PLN',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      additionalInfo: {
        'source': 'firebase-functions-updated',
        'numer_kontraktu': (data['numer_kontraktu'] ?? '').toString(),
      },
    );
  }

  Client _convertToClient(Map<String, dynamic> data) {
    return Client(
      id: (data['id'] ?? '').toString(),
      name: data['imie_nazwisko'] ?? data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['telefon'] ?? data['phone'] ?? '',
      address: data['address'] ?? '',
      pesel: data['pesel']?.toString(),
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
                : DateTime.parse(data['createdAt'].toString()))
          : (data['created_at'] != null
                ? DateTime.parse(data['created_at'].toString())
                : DateTime.now()),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
                ? (data['updatedAt'] as Timestamp).toDate()
                : DateTime.parse(data['updatedAt'].toString()))
          : (data['uploaded_at'] != null
                ? DateTime.parse(data['uploaded_at'].toString())
                : DateTime.now()),
      isActive: data['isActive'] ?? true,
      additionalInfo:
          data['additionalInfo'] ?? {'source_file': data['source_file']},
    );
  }

  InvestmentStatus _parseInvestmentStatus(dynamic status) {
    final statusStr = status?.toString() ?? '';
    if (statusStr == 'Nieaktywny' || statusStr == 'Nieaktywowany') {
      return InvestmentStatus.inactive;
    } else if (statusStr == 'Wykup wczesniejszy') {
      return InvestmentStatus.earlyRedemption;
    }
    return InvestmentStatus.active;
  }

  DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    return DateTime.tryParse(date.toString());
  }
}

// 📊 ROZSZERZONE MODELE DANYCH dla nowych Firebase Functions

/// Rozszerzony wynik analizy inwestorów
class InvestorAnalyticsResult {
  final List<InvestorSummary> investors;
  final List<InvestorSummary> allInvestors;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final double totalViableCapital;
  final Map<VotingStatus, VotingCapitalInfo> votingDistribution;
  final int executionTimeMs;
  final String source;
  final String? message; // Dodane dla obsługi placeholder
  final String? timestamp; // Dodane dla obsługi placeholder

  InvestorAnalyticsResult({
    required this.investors,
    required this.allInvestors,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.totalViableCapital,
    required this.votingDistribution,
    required this.executionTimeMs,
    required this.source,
    this.message,
    this.timestamp,
  });
}

class VotingCapitalInfo {
  final int count;
  final double capital;

  VotingCapitalInfo({required this.count, required this.capital});
}

class ClientsResult {
  final List<Client> clients;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final String source;
  final int? processingTime;

  ClientsResult({
    required this.clients,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.source,
    this.processingTime,
  });
}

class ProductsResult {
  final List<dynamic> products;
  final PaginationInfo pagination;
  final ResultMetadata metadata;

  ProductsResult({
    required this.products,
    required this.pagination,
    required this.metadata,
  });
}

class ProductStatisticsResult {
  final int totalProducts;
  final double totalValue;
  final List<ProductTypeStatistics> productTypeBreakdown;
  final ResultMetadata metadata;

  ProductStatisticsResult({
    required this.totalProducts,
    required this.totalValue,
    required this.productTypeBreakdown,
    required this.metadata,
  });
}

class ProductInvestorsResult {
  final List<InvestorSummary> investors;
  final int totalCount;
  final ProductInfo productInfo;
  final SearchResults searchResults;
  final bool fromCache;
  final int executionTime;

  ProductInvestorsResult({
    required this.investors,
    required this.totalCount,
    required this.productInfo,
    required this.searchResults,
    required this.fromCache,
    required this.executionTime,
  });
}

class DebugResult {
  final String functionStatus;
  final String version;
  final String? message;
  final Map<String, dynamic> additionalInfo;

  DebugResult({
    required this.functionStatus,
    required this.version,
    this.message,
    required this.additionalInfo,
  });
}

// Pomocnicze klasy
class PaginationInfo {
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  PaginationInfo({
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });
}

class ResultMetadata {
  final String? timestamp;
  final int? executionTime;
  final bool cacheUsed;
  final dynamic filters;

  ResultMetadata({
    this.timestamp,
    this.executionTime,
    required this.cacheUsed,
    this.filters,
  });
}

class ProductTypeStatistics {
  final String type;
  final String typeName;
  final int count;
  final double totalValue;
  final double averageValue;
  final double percentage;

  ProductTypeStatistics({
    required this.type,
    required this.typeName,
    required this.count,
    required this.totalValue,
    required this.averageValue,
    required this.percentage,
  });
}

class ProductInfo {
  final String name;
  final String type;
  final double totalCapital;

  ProductInfo({
    required this.name,
    required this.type,
    required this.totalCapital,
  });
}

class SearchResults {
  final String searchType;
  final int matchingProducts;
  final int totalInvestments;

  SearchResults({
    required this.searchType,
    required this.matchingProducts,
    required this.totalInvestments,
  });
}
