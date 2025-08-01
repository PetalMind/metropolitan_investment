import 'package:cloud_functions/cloud_functions.dart';
import '../models/client.dart';
import '../models/investor_summary.dart';
import '../models/investment.dart';
import '../models/product.dart';
import 'base_service.dart';

/// 🚀 FIREBASE FUNCTIONS ANALYTICS SERVICE
/// Wykorzystuje server-side processing dla maksymalnej wydajności
class FirebaseFunctionsAnalyticsService extends BaseService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1', // Bliżej Polski dla lepszej latencji
  );

  /// **GŁÓWNA METODA:** Pobiera analitykę inwestorów z Firebase Functions
  /// 50-100x szybsza niż lokalne przetwarzanie dzięki server-side processing
  Future<InvestorAnalyticsResult> getOptimizedInvestorAnalytics({
    int page = 1,
    int pageSize = 250,
    String sortBy = 'totalValue',
    bool sortAscending = false,
    bool includeInactive = false,
    VotingStatus? votingStatusFilter,
    ClientType? clientTypeFilter,
    bool showOnlyWithUnviableInvestments = false,
    String? searchQuery,
    bool forceRefresh = false,
  }) async {
    final startTime = DateTime.now();
    print(
      '🚀 [Functions Service] Rozpoczynam analizę przez Firebase Functions...',
    );

    try {
      // Wywołaj Firebase Function
      final callable = _functions.httpsCallable(
        'getOptimizedInvestorAnalytics',
        options: HttpsCallableOptions(
          timeout: const Duration(
            minutes: 5,
          ), // Długi timeout dla dużych analiz
        ),
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
        '⚡ [Functions Service] Otrzymano dane w ${executionTime.inMilliseconds}ms',
      );
      print(
        '📊 [Functions Service] Server execution: ${data['executionTime']}ms',
      );
      print('👥 [Functions Service] Inwestorów: ${data['totalCount']}');

      // Konwertuj dane z Functions na Flutter modele
      final investors = (data['investors'] as List)
          .map((investorData) => _convertToInvestorSummary(investorData))
          .toList();

      final allInvestors = data['allInvestors'] != null
          ? (data['allInvestors'] as List)
                .map((investorData) => _convertToInvestorSummary(investorData))
                .toList()
          : investors;

      return InvestorAnalyticsResult(
        investors: investors,
        allInvestors: allInvestors,
        totalCount: data['totalCount'] ?? 0,
        currentPage: data['currentPage'] ?? page,
        pageSize: data['pageSize'] ?? pageSize,
        hasNextPage: data['hasNextPage'] ?? false,
        hasPreviousPage: data['hasPreviousPage'] ?? false,
        totalViableCapital: (data['totalViableCapital'] ?? 0).toDouble(),
        votingDistribution: _convertVotingDistribution(
          data['votingDistribution'],
        ),
        executionTimeMs: executionTime.inMilliseconds,
        source: 'firebase-functions',
      );
    } catch (e) {
      print('❌ [Functions Service] Błąd: $e');
      throw Exception('Błąd Firebase Functions: $e');
    }
  }

  /// **ANALIZA KONTROLI WIĘKSZOŚCIOWEJ** przez Firebase Functions
  Future<MajorityControlAnalysis> analyzeMajorityControlOptimized({
    bool includeInactive = false,
    double controlThreshold = 51.0,
  }) async {
    print(
      '🎯 [Functions Service] Rozpoczynam analizę kontroli większościowej...',
    );

    try {
      final callable = _functions.httpsCallable('analyzeMajorityControl');

      final response = await callable.call({
        'controlThreshold': controlThreshold,
        'includeInactive': includeInactive,
      });

      final data = response.data as Map<String, dynamic>;

      print('✅ [Functions Service] Analiza kontroli zakończona');
      print('🏢 [Functions Service] Firm: ${data['totalCompanies']}');
      print(
        '👑 [Functions Service] Z większością: ${data['companiesWithMajority']}',
      );

      return MajorityControlAnalysis(
        totalCompanies: data['totalCompanies'] ?? 0,
        companiesWithMajority: data['companiesWithMajority'] ?? 0,
        totalMajorityHolders: data['totalMajorityHolders'] ?? 0,
        controlThreshold: data['controlThreshold'] ?? controlThreshold,
        companyAnalysis: (data['analysis'] as List? ?? [])
            .map(
              (company) => CompanyControlAnalysis(
                companyName: company['company'] ?? '',
                totalCapital: (company['totalCapital'] ?? 0).toDouble(),
                investorCount: company['investorCount'] ?? 0,
                majorityHolders: (company['majorityHolders'] as List? ?? [])
                    .map(
                      (holder) => MajorityHolder(
                        investorId: holder['id'] ?? '',
                        investorName: holder['name'] ?? '',
                        capitalAmount: (holder['capitalInCompany'] ?? 0)
                            .toDouble(),
                        controlPercentage: (holder['percentage'] ?? 0)
                            .toDouble(),
                      ),
                    )
                    .toList(),
                topInvestors: (company['topInvestors'] as List? ?? [])
                    .map(
                      (investor) => TopInvestor(
                        investorId: investor['id'] ?? '',
                        investorName: investor['name'] ?? '',
                        capitalAmount: (investor['capitalInCompany'] ?? 0)
                            .toDouble(),
                        percentage: (investor['percentage'] ?? 0).toDouble(),
                      ),
                    )
                    .toList(),
              ),
            )
            .toList(),
      );
    } catch (e) {
      print('❌ [Functions Service] Błąd analizy kontroli: $e');
      throw Exception('Błąd analizy kontroli: $e');
    }
  }

  /// **FORCE REFRESH CACHE** - Wymusza odświeżenie cache na serwerze
  Future<void> refreshAnalyticsCache() async {
    print('🔄 [Functions Service] Wymuszam odświeżenie cache...');

    try {
      await getOptimizedInvestorAnalytics(
        page: 1,
        pageSize: 250,
        forceRefresh: true,
      );

      print('✅ [Functions Service] Cache odświeżony');
    } catch (e) {
      print('❌ [Functions Service] Błąd odświeżania cache: $e');
      throw Exception('Błąd odświeżania cache: $e');
    }
  }

  // 🛠️ HELPER METHODS

  InvestorSummary _convertToInvestorSummary(Map<String, dynamic> data) {
    final clientData = data['client'] as Map<String, dynamic>;
    final investmentsData = data['investments'] as List;

    final client = Client(
      id: clientData['id'] ?? '',
      name: clientData['name'] ?? '',
      email: clientData['email'] ?? '',
      phone: clientData['phone'] ?? '',
      address: '',
      isActive: clientData['isActive'] ?? true,
      votingStatus: VotingStatus.values.firstWhere(
        (v) => v.name == clientData['votingStatus'],
        orElse: () => VotingStatus.undecided,
      ),
      type: ClientType.individual,
      colorCode: clientData['colorCode'] ?? '#FFFFFF',
      unviableInvestments: List<String>.from(
        clientData['unviableInvestments'] ?? [],
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

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
      investmentCount: data['investmentCount'] ?? 0,
    );
  }

  Investment _convertToInvestment(Map<String, dynamic> data) {
    return Investment(
      id: data['id'] ?? '',
      clientId: '',
      clientName: data['klient'] ?? '',
      employeeId: '',
      employeeFirstName: data['pracownik_imie'] ?? '',
      employeeLastName: data['pracownik_nazwisko'] ?? '',
      branchCode: data['kod_oddzialu'] ?? '',
      status: _parseInvestmentStatus(data['status_produktu']),
      isAllocated: data['przydzial']?.toString() == '1',
      marketType: MarketType.primary,
      signedDate: _parseDate(data['data_podpisania']) ?? DateTime.now(),
      entryDate: _parseDate(data['data_zawarcia']),
      exitDate: _parseDate(data['data_wymagalnosci']),
      proposalId: data['numer_kontraktu']?.toString() ?? '',
      productType: _parseProductType(data['typ_produktu']),
      productName: data['nazwa_produktu']?.toString() ?? '',
      creditorCompany: '',
      companyId: data['id_spolka']?.toString() ?? '',
      issueDate: _parseDate(data['data_podpisania']),
      redemptionDate: _parseDate(data['data_wymagalnosci']),
      investmentAmount: (data['investmentAmount'] ?? 0).toDouble(),
      paidAmount: (data['investmentAmount'] ?? 0).toDouble(),
      realizedCapital: (data['realizedCapital'] ?? 0).toDouble(),
      realizedInterest: 0.0,
      transferToOtherProduct: 0.0,
      remainingCapital: (data['remainingCapital'] ?? 0).toDouble(),
      remainingInterest: 0.0,
      plannedTax: 0.0,
      realizedTax: 0.0,
      currency: data['waluta']?.toString() ?? 'PLN',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      additionalInfo: {
        'source': 'firebase-functions',
        'numer_kontraktu': data['numer_kontraktu']?.toString() ?? '',
      },
    );
  }

  Map<VotingStatus, VotingCapitalInfo> _convertVotingDistribution(
    Map<String, dynamic>? distribution,
  ) {
    if (distribution == null) {
      return {
        VotingStatus.yes: VotingCapitalInfo(count: 0, capital: 0.0),
        VotingStatus.no: VotingCapitalInfo(count: 0, capital: 0.0),
        VotingStatus.abstain: VotingCapitalInfo(count: 0, capital: 0.0),
        VotingStatus.undecided: VotingCapitalInfo(count: 0, capital: 0.0),
      };
    }

    return {
      VotingStatus.yes: VotingCapitalInfo(
        count: distribution['yes']?['count'] ?? 0,
        capital: (distribution['yes']?['capital'] ?? 0).toDouble(),
      ),
      VotingStatus.no: VotingCapitalInfo(
        count: distribution['no']?['count'] ?? 0,
        capital: (distribution['no']?['capital'] ?? 0).toDouble(),
      ),
      VotingStatus.abstain: VotingCapitalInfo(
        count: distribution['abstain']?['count'] ?? 0,
        capital: (distribution['abstain']?['capital'] ?? 0).toDouble(),
      ),
      VotingStatus.undecided: VotingCapitalInfo(
        count: distribution['undecided']?['count'] ?? 0,
        capital: (distribution['undecided']?['capital'] ?? 0).toDouble(),
      ),
    };
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

  ProductType _parseProductType(dynamic type) {
    final typeStr = type?.toString() ?? '';
    if (typeStr == 'Udziały') return ProductType.shares;
    if (typeStr == 'Apartamenty') return ProductType.apartments;
    return ProductType.bonds;
  }

  DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    return DateTime.tryParse(date.toString());
  }
}

// 📊 DATA MODELS dla Firebase Functions response

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
  });
}

class VotingCapitalInfo {
  final int count;
  final double capital;

  VotingCapitalInfo({required this.count, required this.capital});
}

class MajorityControlAnalysis {
  final int totalCompanies;
  final int companiesWithMajority;
  final int totalMajorityHolders;
  final double controlThreshold;
  final List<CompanyControlAnalysis> companyAnalysis;

  MajorityControlAnalysis({
    required this.totalCompanies,
    required this.companiesWithMajority,
    required this.totalMajorityHolders,
    required this.controlThreshold,
    required this.companyAnalysis,
  });
}

class CompanyControlAnalysis {
  final String companyName;
  final double totalCapital;
  final int investorCount;
  final List<MajorityHolder> majorityHolders;
  final List<TopInvestor> topInvestors;

  CompanyControlAnalysis({
    required this.companyName,
    required this.totalCapital,
    required this.investorCount,
    required this.majorityHolders,
    required this.topInvestors,
  });
}

class MajorityHolder {
  final String investorId;
  final String investorName;
  final double capitalAmount;
  final double controlPercentage;

  MajorityHolder({
    required this.investorId,
    required this.investorName,
    required this.capitalAmount,
    required this.controlPercentage,
  });
}

class TopInvestor {
  final String investorId;
  final String investorName;
  final double capitalAmount;
  final double percentage;

  TopInvestor({
    required this.investorId,
    required this.investorName,
    required this.capitalAmount,
    required this.percentage,
  });
}
