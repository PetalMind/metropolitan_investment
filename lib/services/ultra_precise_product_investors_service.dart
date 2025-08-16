import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Dodano import dla Timestamp
import 'package:flutter/foundation.dart';
import '../models_and_services.dart';

/// 🚀 ULTRA PRECYZYJNY SERWIS INWESTORÓW PRODUKTÓW
/// Wykorzystuje nową strukturę danych z logicznymi ID dla maksymalnej precyzji
class UltraPreciseProductInvestorsService {
  late final FirebaseFunctions _functions;

  UltraPreciseProductInvestorsService() {
    _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
  }

  /// 🎯 GŁÓWNA METODA: Ultra-precyzyjne wyszukiwanie inwestorów
  /// Wykorzystuje nową strukturę z productId dla 100% precyzji
  /// ⭐ NOWE: Obsługuje mapowanie deduplikowanych ID na rzeczywiste productId
  Future<UltraPreciseProductInvestorsResult> getProductInvestors({
    String?
    productId, // GŁÓWNY IDENTYFIKATOR - np. "apartment_0078" lub deduplikowany
    String? productName, // BACKUP - np. "Zatoka Komfortu"
    String searchStrategy = 'productId', // 'productId' | 'productName'
    bool forceRefresh = false,
  }) async {
    try {
      if (kDebugMode) {
        print('[UltraPrecise] 🎯 Rozpoczynam ultra-precyzyjne wyszukiwanie...');
        print('[UltraPrecise] - productId: $productId');
        print('[UltraPrecise] - productName: $productName');
        print('[UltraPrecise] - searchStrategy: $searchStrategy');
      }

      // ⚠️ WALIDACJA
      if (productId == null && productName == null) {
        throw ArgumentError('Wymagany productId lub productName');
      }

      // ⭐ NOWE: Sprawdź czy productId to deduplikowany hash ID
      String? resolvedProductId = productId;
      String? resolvedProductName = productName;

      if (productId != null && _isDeduplikatedId(productId)) {
        if (kDebugMode) {
          print('[UltraPrecise] 🔍 Wykryto deduplikowany ID: $productId');
          print(
            '[UltraPrecise] 🔄 Próba mapowania na rzeczywisty productId...',
          );
        }

        // Spróbuj znaleźć rzeczywisty productId na podstawie deduplikowanego
        final mapping = await _mapDeduplikatedToRealProductId(
          productId,
          productName,
        );
        if (mapping != null) {
          resolvedProductId = mapping.realProductId;
          resolvedProductName = mapping.productName;

          if (kDebugMode) {
            print(
              '[UltraPrecise] ✅ Zmapowano: $productId → $resolvedProductId',
            );
            print('[UltraPrecise] ✅ Nazwa: $resolvedProductName');
          }
        } else {
          if (kDebugMode) {
            print(
              '[UltraPrecise] ⚠️ Nie udało się zmapować ID, używam productName',
            );
          }
          // Fallback: użyj productName jeśli dostępne
          searchStrategy = 'productName';
        }
      }

      final callable = _functions.httpsCallable(
        'getProductInvestorsUltraPrecise',
      );

      final result = await callable.call({
        'productId': resolvedProductId,
        'productName': resolvedProductName,
        'searchStrategy': searchStrategy,
        'forceRefresh': forceRefresh,
      });

      if (kDebugMode) {
        print('[UltraPrecise] ✅ Pobrano dane z Firebase Functions');
        print('[UltraPrecise] - Strategia: ${result.data['searchStrategy']}');
        print('[UltraPrecise] - Inwestorów: ${result.data['totalCount']}');
        print('[UltraPrecise] - Czas: ${result.data['executionTime']}ms');
        print('[UltraPrecise] - Z cache: ${result.data['fromCache']}');
        print('[UltraPrecise] - Raw data keys: ${result.data.keys.toList()}');
      }

      return UltraPreciseProductInvestorsResult.fromMap(result.data);
    } catch (e) {
      if (kDebugMode) {
        print('[UltraPrecise] ❌ Błąd szczegółowy: $e');
        print('[UltraPrecise] ❌ Typ błędu: ${e.runtimeType}');
        if (e.toString().contains('500') || e.toString().contains('internal')) {
          print(
            '[UltraPrecise] 🔥 To jest błąd serwera - sprawdź logi Firebase Functions!',
          );
          print(
            '[UltraPrecise] 🔍 Uruchom: firebase functions:log --only getProductInvestorsUltraPrecise',
          );
        }
      }

      // Fallback - zwróć pustą listę z błędem
      return UltraPreciseProductInvestorsResult.empty(
        searchKey: productId ?? productName ?? 'unknown',
        error: e.toString(),
      );
    }
  }

  /// 🔧 HELPER: Wyszukaj po produktId (preferowana metoda)
  Future<UltraPreciseProductInvestorsResult> getByProductId(
    String productId, {
    bool forceRefresh = false,
  }) async {
    return getProductInvestors(
      productId: productId,
      searchStrategy: 'productId',
      forceRefresh: forceRefresh,
    );
  }

  /// 🔧 HELPER: Wyszukaj po nazwie produktu (fallback)
  Future<UltraPreciseProductInvestorsResult> getByProductName(
    String productName, {
    bool forceRefresh = false,
  }) async {
    return getProductInvestors(
      productName: productName,
      searchStrategy: 'productName',
      forceRefresh: forceRefresh,
    );
  }

  /// 🧪 TEST: Sprawdź połączenie z Firebase Functions
  Future<bool> testConnection() async {
    try {
      await getProductInvestors(
        productId: 'test_connection',
        forceRefresh: true,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[UltraPrecise] ❌ Test połączenia nieudany: $e');
      }
      return false;
    }
  }
}

/// 📊 WYNIK ULTRA-PRECYZYJNEGO WYSZUKIWANIA
class UltraPreciseProductInvestorsResult {
  final List<InvestorSummary> investors;
  final int totalCount;
  final String searchStrategy;
  final String searchKey;
  final int executionTime;
  final bool fromCache;
  final UltraPreciseStatistics statistics;
  final MappingStatistics mappingStats;
  final String? error;

  const UltraPreciseProductInvestorsResult({
    required this.investors,
    required this.totalCount,
    required this.searchStrategy,
    required this.searchKey,
    required this.executionTime,
    required this.fromCache,
    required this.statistics,
    required this.mappingStats,
    this.error,
  });

  /// Tworzy wynik z mapy danych Firebase Functions
  factory UltraPreciseProductInvestorsResult.fromMap(
    Map<String, dynamic> data,
  ) {
    final investorsData = data['investors'] as List<dynamic>? ?? [];

    // ✅ NOWA ARCHITEKTURA: Utwórz bez obliczeń, potem oblicz raz dla wszystkich
    final investorsWithoutCalculations = investorsData
        .map((item) => _createInvestorSummaryFromUltraPreciseData(item))
        .toList();

    // ✅ OBLICZ KAPITAŁ ZABEZPIECZONY RAZ DLA WSZYSTKICH
    final investors = InvestorSummary.calculateSecuredCapitalForAll(
      investorsWithoutCalculations,
    );

    return UltraPreciseProductInvestorsResult(
      investors: investors,
      totalCount: data['totalCount'] as int? ?? 0,
      searchStrategy: data['searchStrategy'] as String? ?? 'unknown',
      searchKey: data['searchKey'] as String? ?? '',
      executionTime: data['executionTime'] as int? ?? 0,
      fromCache: data['fromCache'] as bool? ?? false,
      statistics: UltraPreciseStatistics.fromMap(
        data['statistics'] as Map<String, dynamic>? ?? {},
      ),
      mappingStats: MappingStatistics.fromMap(
        data['mappingStats'] as Map<String, dynamic>? ?? {},
      ),
      error: data['error'] as String?,
    );
  }

  /// Tworzy pusty wynik z błędem
  factory UltraPreciseProductInvestorsResult.empty({
    required String searchKey,
    String? error,
  }) {
    return UltraPreciseProductInvestorsResult(
      investors: [],
      totalCount: 0,
      searchStrategy: 'error',
      searchKey: searchKey,
      executionTime: 0,
      fromCache: false,
      statistics: UltraPreciseStatistics.empty(),
      mappingStats: MappingStatistics.empty(),
      error: error,
    );
  }

  /// Czy wyszukiwanie zakończyło się sukcesem
  bool get isSuccess => error == null && investors.isNotEmpty;

  /// Czy wynik jest pusty (bez błędu)
  bool get isEmpty => error == null && investors.isEmpty;

  /// Czy wystąpił błąd
  bool get hasError => error != null;
}

/// 📈 STATYSTYKI ULTRA-PRECYZYJNE
class UltraPreciseStatistics {
  final int totalInvestments;
  final double totalCapital;
  final double averageCapital;

  const UltraPreciseStatistics({
    required this.totalInvestments,
    required this.totalCapital,
    required this.averageCapital,
  });

  factory UltraPreciseStatistics.fromMap(Map<String, dynamic> data) {
    return UltraPreciseStatistics(
      totalInvestments: data['totalInvestments'] as int? ?? 0,
      totalCapital: (data['totalCapital'] as num?)?.toDouble() ?? 0.0,
      averageCapital: (data['averageCapital'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory UltraPreciseStatistics.empty() {
    return const UltraPreciseStatistics(
      totalInvestments: 0,
      totalCapital: 0.0,
      averageCapital: 0.0,
    );
  }
}

/// 🔗 STATYSTYKI MAPOWANIA
class MappingStatistics {
  final int mapped;
  final int unmapped;
  final double mappingRatio;

  const MappingStatistics({
    required this.mapped,
    required this.unmapped,
    required this.mappingRatio,
  });

  factory MappingStatistics.fromMap(Map<String, dynamic> data) {
    return MappingStatistics(
      mapped: data['mapped'] as int? ?? 0,
      unmapped: data['unmapped'] as int? ?? 0,
      mappingRatio: (data['mappingRatio'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory MappingStatistics.empty() {
    return const MappingStatistics(mapped: 0, unmapped: 0, mappingRatio: 0.0);
  }

  /// Całkowita liczba próbek mapowania
  int get total => mapped + unmapped;

  /// Procent pomyślnie zmapowanych
  double get successPercentage => mappingRatio * 100;
}

/// 🔧 HELPER: Tworzy InvestorSummary z ultra-precyzyjnych danych
InvestorSummary _createInvestorSummaryFromUltraPreciseData(
  Map<String, dynamic> data,
) {
  // Konwertuj dane klienta
  final clientData = data['client'] as Map<String, dynamic>? ?? {};

  // Konwertuj inwestycje
  final investmentsData = data['investments'] as List<dynamic>? ?? [];
  final investments = investmentsData.map((invData) {
    // ✅ MAPOWANIE ZGODNE Z RZECZYWISTYMI DANYMI FIREBASE
    final Map<String, dynamic> investment = invData as Map<String, dynamic>;

    return Investment(
      id: investment['id'] as String? ?? '',
      clientId:
          investment['clientId'] as String? ??
          clientData['id'] as String? ??
          '',
      clientName:
          investment['clientName'] as String? ??
          clientData['name'] as String? ??
          '',
      // ✅ Preferuj productName, fallback na projectName
      productName:
          investment['productName'] as String? ??
          investment['projectName'] as String? ??
          '',
      productId: investment['productId'] as String?,
      // ✅ Sprawdź productType, potem investmentType, potem fallback
      productType: _parseProductTypeForInvestment(
        investment['productType'] as String? ??
            investment['investmentType'] as String? ??
            '',
      ),
      investmentAmount:
          (investment['investmentAmount'] as num?)?.toDouble() ?? 0.0,
      remainingCapital:
          (investment['remainingCapital'] as num?)?.toDouble() ?? 0.0,
      // ✅ Używaj signingDate z Firebase (nie signedDate)
      signedDate:
          _parseDate(investment['signingDate']) ??
          _parseDate(investment['investmentEntryDate']) ??
          DateTime.now(),
      // ✅ Używaj productStatus z Firebase
      status: _parseInvestmentStatus(
        investment['productStatus'] as String? ?? '',
      ),
      companyId:
          investment['companyId'] as String? ??
          clientData['companyName'] as String? ??
          '',
      createdAt: _parseDate(investment['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(investment['updatedAt']) ?? DateTime.now(),
      // ✅ POPRAWIONE: Mapowanie zgodne z rzeczywistymi polami Firebase
      capitalForRestructuring:
          (investment['capitalForRestructuring'] as num?)?.toDouble() ?? 0.0,
      capitalSecuredByRealEstate:
          (investment['capitalSecuredByRealEstate'] as num?)?.toDouble() ??
          (investment['realEstateSecuredCapital'] as num?)?.toDouble() ??
          0.0,
      employeeId: investment['employeeId'] as String? ?? '',
      employeeFirstName: investment['employeeFirstName'] as String? ?? '',
      employeeLastName:
          investment['employeeLastName'] as String? ??
          investment['advisor'] as String? ??
          '',
      branchCode: investment['branch'] as String? ?? '',
      marketType: _parseMarketType(
        investment['productStatusEntry'] as String? ?? '',
      ),
      proposalId: investment['saleId'] as String? ?? '',
      creditorCompany: investment['creditorCompany'] as String? ?? '',
      paidAmount: (investment['paidAmount'] as num?)?.toDouble() ?? 0.0,
      // ✅ Dodatkowe pola z Firebase
      realizedCapital:
          (investment['realizedCapital'] as num?)?.toDouble() ?? 0.0,
      realizedInterest:
          (investment['realizedInterest'] as num?)?.toDouble() ?? 0.0,
      transferToOtherProduct:
          (investment['transferToOtherProduct'] as num?)?.toDouble() ?? 0.0,
      remainingInterest:
          (investment['remainingInterest'] as num?)?.toDouble() ?? 0.0,
      plannedTax: (investment['plannedTax'] as num?)?.toDouble() ?? 0.0,
      realizedTax: (investment['realizedTax'] as num?)?.toDouble() ?? 0.0,
      currency: investment['currency'] as String? ?? 'PLN',
      exchangeRate: (investment['exchangeRate'] as num?)?.toDouble(),
      isAllocated: investment['isAllocated'] as bool? ?? false,
      additionalInfo: {
        'productId': investment['productId'],
        'saleId': investment['saleId'],
        'branch': investment['branch'],
        'advisor': investment['advisor'],
        'sourceFile': investment['sourceFile'],
        'projectName': investment['projectName'],
        'realEstateSecuredCapital': investment['realEstateSecuredCapital'],
        'ultraPreciseSource': true,
      },
    );
  }).toList();

  // Utwórz Client
  final client = Client(
    id: clientData['id'] as String? ?? '',
    name: clientData['name'] as String? ?? '',
    email: clientData['email'] as String? ?? '',
    phone: clientData['phone'] as String? ?? '',
    address: clientData['address'] as String? ?? '',
    companyName: clientData['companyName'] as String?,
    isActive: clientData['isActive'] as bool? ?? true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  // ✅ UŻYWAJ NOWEJ ARCHITEKTURY: bez obliczeń na początku
  return InvestorSummary.withoutCalculations(client, investments);
}

/// 🔧 HELPERS dla konwersji danych - używają standardowych helper'ów z Investment

ProductType _parseProductTypeForInvestment(String type) {
  if (type.isEmpty) return ProductType.bonds;

  final lowerType = type.toLowerCase();

  if (lowerType.contains('apartament')) return ProductType.apartments;
  if (lowerType.contains('obligacje') || lowerType.contains('bonds'))
    return ProductType.bonds;
  if (lowerType.contains('udziały') || lowerType.contains('shares'))
    return ProductType.shares;
  if (lowerType.contains('pożyczki') || lowerType.contains('loans'))
    return ProductType.loans;

  // Fallback
  return ProductType.bonds;
}

DateTime? _parseDate(dynamic dateValue) {
  if (dateValue == null) return null;

  // Handle Firestore Timestamp
  if (dateValue is Timestamp) {
    return dateValue.toDate();
  }

  // Handle string dates
  if (dateValue is String && dateValue.isNotEmpty) {
    try {
      return DateTime.parse(dateValue);
    } catch (e) {
      return null;
    }
  }

  // Handle DateTime
  if (dateValue is DateTime) {
    return dateValue;
  }

  return null;
}

InvestmentStatus _parseInvestmentStatus(String status) {
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

MarketType _parseMarketType(String marketType) {
  switch (marketType.toLowerCase()) {
    case 'rynek pierwotny':
    case 'primary':
      return MarketType.primary;
    case 'rynek wtórny':
    case 'secondary':
      return MarketType.secondary;
    case 'odkup od klienta':
    case 'client redemption':
      return MarketType.clientRedemption;
    default:
      return MarketType.primary;
  }
}

/// 🔍 HELPER: Sprawdza czy productId to deduplikowany hash ID
bool _isDeduplikatedId(String productId) {
  // Deduplikowane ID to zwykle długie liczby (hash codes)
  // Rzeczywiste productId to formaty jak: apartment_0001, bond_0123, itp.

  if (productId.contains('_')) {
    // To wygląda na rzeczywisty productId (apartment_0001)
    return false;
  }

  // Sprawdź czy to tylko cyfry (prawdopodobnie hash)
  final isOnlyDigits = RegExp(r'^\d+$').hasMatch(productId);
  if (isOnlyDigits && productId.length > 6) {
    // Długa liczba - prawdopodobnie deduplikowany hash
    return true;
  }

  return false;
}

/// 🔗 HELPER: Mapuje deduplikowany ID na rzeczywisty productId
Future<ProductIdMapping?> _mapDeduplikatedToRealProductId(
  String deduplikatedId,
  String? productName,
) async {
  try {
    // Pobierz przykładową inwestycję z Firebase żeby znaleźć prawdziwy productId
    final firestore = FirebaseFirestore.instance;

    QuerySnapshot query;

    if (productName != null) {
      // Strategia 1: Szukaj po nazwie produktu
      query = await firestore
          .collection('investments')
          .where('productName', isEqualTo: productName)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        // Fallback: szukaj po projectName
        query = await firestore
            .collection('investments')
            .where('projectName', isEqualTo: productName)
            .limit(1)
            .get();
      }
    } else {
      // Strategia 2: Szukaj po ID (mało prawdopodobne ale spróbuj)
      query = await firestore
          .collection('investments')
          .where('id', isEqualTo: deduplikatedId)
          .limit(1)
          .get();
    }

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final data = doc.data() as Map<String, dynamic>;

      final realProductId = data['productId'] as String?;
      final mappedProductName =
          data['productName'] ?? data['projectName'] as String?;

      if (realProductId != null) {
        return ProductIdMapping(
          deduplikatedId: deduplikatedId,
          realProductId: realProductId,
          productName: mappedProductName ?? productName ?? 'Unknown',
        );
      }
    }

    return null;
  } catch (e) {
    if (kDebugMode) {
      print('[UltraPrecise] ❌ Błąd mapowania ID: $e');
    }
    return null;
  }
}

/// 📋 MODEL: Mapowanie tussen deduplikowany ID a rzeczywisty productId
class ProductIdMapping {
  final String deduplikatedId;
  final String realProductId;
  final String productName;

  const ProductIdMapping({
    required this.deduplikatedId,
    required this.realProductId,
    required this.productName,
  });
}
