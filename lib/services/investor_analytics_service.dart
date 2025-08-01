import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client.dart';
import '../models/investment.dart';
import '../models/investor_summary.dart';
import '../models/product.dart';
import 'base_service.dart';
import 'client_service.dart';

class InvestorAnalyticsService extends BaseService {
  final ClientService _clientService = ClientService();

  // Cache dla inwestorów z czasem wygaśnięcia
  Map<String, List<InvestorSummary>>? _investorsCache;
  DateTime? _cacheTimestamp;
  static const Duration _cacheTimeout = Duration(minutes: 10);

  /// Analiza inwestorów tworzących 51% kontroli portfela
  Future<MajorityControlAnalysis> analyzeMajorityControl({
    bool includeInactive = false,
    double controlThreshold = 51.0,
  }) async {
    final startTime = DateTime.now();
    print(
      '📊 [MajorityControl] Rozpoczynam analizę kontroli ${controlThreshold}%...',
    );

    try {
      // Pobierz wszystkich inwestorów
      final allInvestors = await _loadAllInvestors(includeInactive);

      if (allInvestors.isEmpty) {
        return MajorityControlAnalysis.empty();
      }

      // Sortuj według kapitału pozostałego (viableRemainingCapital) malejąco
      allInvestors.sort(
        (a, b) => b.viableRemainingCapital.compareTo(a.viableRemainingCapital),
      );

      // Oblicz całkowitą wartość portfela na podstawie kapitału pozostałego
      final totalViableCapital = allInvestors.fold<double>(
        0.0,
        (sum, investor) => sum + investor.viableRemainingCapital,
      );

      print(
        '📊 [MajorityControl] Całkowity kapitał pozostały: ${totalViableCapital.toStringAsFixed(2)} PLN',
      );

      if (totalViableCapital <= 0) {
        return MajorityControlAnalysis.empty();
      }

      // Znajdź inwestorów tworzących próg kontrolny
      final List<InvestorWithControlInfo> controlInvestors = [];
      final List<InvestorWithControlInfo> allInvestorsWithInfo = [];
      double cumulativeCapital = 0.0;
      double controlThresholdAmount =
          totalViableCapital * (controlThreshold / 100);

      print(
        '📊 [MajorityControl] Próg kontrolny: ${controlThresholdAmount.toStringAsFixed(2)} PLN (${controlThreshold}%)',
      );

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

        // Dodaj do grupy kontrolnej jeśli jest potrzebny do osiągnięcia progu
        if (previousCumulative < controlThresholdAmount) {
          controlInvestors.add(investorInfo);
        }
      }

      final controlGroupCapital = controlInvestors.fold<double>(
        0.0,
        (sum, investor) => sum + investor.summary.viableRemainingCapital,
      );

      print(
        '📊 [MajorityControl] Grupa kontrolna: ${controlInvestors.length} inwestorów z kapitałem ${controlGroupCapital.toStringAsFixed(2)} PLN',
      );
      print(
        '📊 [MajorityControl] Analiza zakończona w ${DateTime.now().difference(startTime).inMilliseconds}ms',
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
      print('❌ [MajorityControl] Błąd analizy: $e');
      logError('analyzeMajorityControl', e);
      return MajorityControlAnalysis.empty();
    }
  }

  /// Analiza rozkładu kapitału według statusu głosowania
  Future<VotingCapitalDistribution> analyzeVotingDistribution({
    bool includeInactive = false,
  }) async {
    print('📊 [VotingDistribution] Rozpoczynam analizę rozkładu głosowania...');

    try {
      final allInvestors = await _loadAllInvestors(includeInactive);

      if (allInvestors.isEmpty) {
        return VotingCapitalDistribution.empty();
      }

      final Map<VotingStatus, double> distribution = {};
      final Map<VotingStatus, int> counts = {};

      // Inicjalizuj wszystkie statusy z zerowymi wartościami
      for (final status in VotingStatus.values) {
        distribution[status] = 0.0;
        counts[status] = 0;
      }

      double totalCapital = 0.0;

      for (final investor in allInvestors) {
        final capital = investor.viableRemainingCapital;
        final status = investor.client.votingStatus;

        distribution[status] = (distribution[status] ?? 0.0) + capital;
        counts[status] = (counts[status] ?? 0) + 1;
        totalCapital += capital;
      }

      print(
        '📊 [VotingDistribution] Całkowity kapitał: ${totalCapital.toStringAsFixed(2)} PLN',
      );
      print('📊 [VotingDistribution] Rozkład według statusów:');

      for (final entry in distribution.entries) {
        final percentage = totalCapital > 0
            ? (entry.value / totalCapital) * 100
            : 0.0;
        print(
          '   ${entry.key.name}: ${entry.value.toStringAsFixed(2)} PLN (${percentage.toStringAsFixed(1)}%) - ${counts[entry.key]} inwestorów',
        );
      }

      return VotingCapitalDistribution(
        capitalByStatus: distribution,
        countByStatus: counts,
        totalCapital: totalCapital,
        totalInvestors: allInvestors.length,
        analysisDate: DateTime.now(),
      );
    } catch (e) {
      print('❌ [VotingDistribution] Błąd analizy: $e');
      logError('analyzeVotingDistribution', e);
      return VotingCapitalDistribution.empty();
    }
  }

  /// Pobiera inwestorów posortowanych według kapitału pozostałego z obsługą paginacji
  Future<InvestorAnalyticsResult> getInvestorsSortedByRemainingCapital({
    int page = 1,
    int pageSize = 250,
    String sortBy = 'viableCapital',
    bool sortAscending = false,
    bool includeInactive = false,
    VotingStatus? votingStatusFilter,
    ClientType? clientTypeFilter,
    bool showOnlyWithUnviableInvestments = false,
  }) async {
    print(
      '📊 [Analytics] Pobieranie inwestorów - strona $page, rozmiar $pageSize',
    );
    print(
      '📊 [Analytics] Sortowanie: $sortBy (${sortAscending ? 'rosnąco' : 'malejąco'})',
    );

    try {
      // Sprawdź cache
      final isCacheValid =
          _investorsCache != null &&
          _cacheTimestamp != null &&
          DateTime.now().difference(_cacheTimestamp!).abs() < _cacheTimeout;

      List<InvestorSummary> allInvestors;

      if (isCacheValid) {
        print('📊 [Analytics] Używam danych z cache');
        allInvestors = _investorsCache!.values.expand((x) => x).toList();
      } else {
        print('📊 [Analytics] Ładuję świeże dane z bazy');
        allInvestors = await _loadAllInvestors(includeInactive);

        // Aktualizuj cache
        _investorsCache = {'all': allInvestors};
        _cacheTimestamp = DateTime.now();
      }

      // Filtrowanie
      List<InvestorSummary> filteredInvestors = allInvestors;

      if (votingStatusFilter != null) {
        filteredInvestors = filteredInvestors
            .where(
              (investor) => investor.client.votingStatus == votingStatusFilter,
            )
            .toList();
      }

      if (clientTypeFilter != null) {
        filteredInvestors = filteredInvestors
            .where((investor) => investor.client.type == clientTypeFilter)
            .toList();
      }

      if (showOnlyWithUnviableInvestments) {
        filteredInvestors = filteredInvestors
            .where(
              (investor) =>
                  investor.totalValue > investor.viableRemainingCapital,
            )
            .toList();
      }

      print(
        '📊 [Analytics] Po filtrowaniu: ${filteredInvestors.length} inwestorów',
      );

      // Sortowanie
      filteredInvestors.sort((a, b) {
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

        return sortAscending ? comparison : -comparison;
      });

      // Oblicz statystyki całkowitej listy przed paginacją
      final totalViableCapital = filteredInvestors.fold<double>(
        0.0,
        (sum, investor) => sum + investor.viableRemainingCapital,
      );

      print(
        '📊 [Analytics] Całkowity kapitał (po filtrach): ${totalViableCapital.toStringAsFixed(2)} PLN',
      );

      // Paginacja
      final totalCount = filteredInvestors.length;
      final totalPages = (totalCount / pageSize).ceil();
      final startIndex = (page - 1) * pageSize;
      final endIndex = (startIndex + pageSize).clamp(0, totalCount);
      // Ogranicz do 250
      final paginatedInvestors = filteredInvestors.sublist(
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
      );
    } catch (e) {
      print('❌ [Analytics] Błąd pobierania danych: $e');
      logError('getInvestorsSortedByRemainingCapital', e);
      rethrow;
    }
  }

  /// Ładuje wszystkich inwestorów z cache lub bazy danych
  Future<List<InvestorSummary>> _loadAllInvestors(bool includeInactive) async {
    // Sprawdź cache
    final isCacheValid =
        _investorsCache != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!).abs() < _cacheTimeout;

    if (isCacheValid) {
      return _investorsCache!.values.expand((x) => x).toList();
    }

    // Załaduj z bazy danych
    final loadedInvestors = await getAllInvestorsForAnalysis(
      includeInactive: includeInactive,
    );

    // Aktualizuj cache
    _investorsCache = {'all': loadedInvestors};
    _cacheTimestamp = DateTime.now();

    return loadedInvestors;
  }

  /// Pobiera wszystkich inwestorów do analizy z obliczeniami kapitału
  Future<List<InvestorSummary>> getAllInvestorsForAnalysis({
    bool includeInactive = false,
  }) async {
    print('📊 [Analytics] Pobieranie wszystkich inwestorów do analizy...');

    try {
      final clients = await _clientService.getAllClients();
      print('📊 [Analytics] Znaleziono ${clients.length} klientów');

      final allInvestments = await _getAllInvestments();
      print('📊 [Analytics] Znaleziono ${allInvestments.length} inwestycji');

      final Map<String, List<Investment>> investmentsByClientId = {};
      for (final investment in allInvestments) {
        final clientId = investment.clientId;
        investmentsByClientId.putIfAbsent(clientId, () => []).add(investment);
      }

      print('📊 [Analytics] Grupowanie inwestycji według klientów...');

      final List<InvestorSummary> investors = [];

      for (final client in clients) {
        if (!includeInactive && !client.isActive) continue;

        final clientInvestments = investmentsByClientId[client.id] ?? [];
        if (clientInvestments.isEmpty) {
          print('⚠️ [Analytics] Klient ${client.name} nie ma inwestycji');
          continue;
        }

        // Utwórz podsumowanie inwestora używając factory method
        final investorSummary = InvestorSummary.fromInvestments(
          client,
          clientInvestments,
        );
        investors.add(investorSummary);
      }

      print(
        '📊 [Analytics] Utworzono ${investors.length} podsumowań inwestorów',
      );

      return investors;
    } catch (e) {
      print('❌ [Analytics] Błąd pobierania inwestorów: $e');
      logError('getAllInvestorsForAnalysis', e);
      rethrow;
    }
  }

  /// Pobiera wszystkie inwestycje z bazy danych
  Future<List<Investment>> _getAllInvestments() async {
    try {
      final snapshot = await firestore.collection('investments').get();
      return snapshot.docs
          .map((doc) => _convertExcelDataToInvestment(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ [Analytics] Błąd pobierania inwestycji: $e');
      logError('_getAllInvestments', e);
      rethrow;
    }
  }

  /// Konwertuje dane z Excel/Firestore na obiekt Investment
  Investment _convertExcelDataToInvestment(
    Map<String, dynamic> data,
    String docId,
  ) {
    return Investment(
      id: docId,
      clientId:
          data['id_klient']?.toString() ??
          data['clientId'] ??
          data['client_id'] ??
          '',
      clientName:
          data['klient'] ?? data['clientName'] ?? data['client_name'] ?? '',
      employeeId: data['employeeId'] ?? '',
      employeeFirstName: data['employeeFirstName'] ?? '',
      employeeLastName: data['employeeLastName'] ?? '',
      branchCode: data['branchCode'] ?? '',
      status: InvestmentStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => InvestmentStatus.active,
      ),
      isAllocated: data['isAllocated'] ?? true,
      marketType: MarketType.values.firstWhere(
        (type) => type.name == data['marketType'],
        orElse: () => MarketType.primary,
      ),
      signedDate: _parseDate(data['signedDate']) ?? DateTime.now(),
      entryDate: _parseDate(data['entryDate']),
      exitDate: _parseDate(data['exitDate']),
      proposalId: data['proposalId'] ?? '',
      productType: ProductType.values.firstWhere(
        (type) => type.name == data['productType'],
        orElse: () => ProductType.bonds,
      ),
      productName: data['productName'] ?? '',
      creditorCompany: data['creditorCompany'] ?? '',
      companyId: data['companyId'] ?? '',
      issueDate: _parseDate(data['issueDate']),
      redemptionDate: _parseDate(data['redemptionDate']),
      sharesCount: data['sharesCount'],
      investmentAmount: (data['investmentAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (data['paidAmount'] as num?)?.toDouble() ?? 0.0,
      realizedCapital: (data['realizedCapital'] as num?)?.toDouble() ?? 0.0,
      realizedInterest: (data['realizedInterest'] as num?)?.toDouble() ?? 0.0,
      transferToOtherProduct:
          (data['transferToOtherProduct'] as num?)?.toDouble() ?? 0.0,
      remainingCapital: (data['remainingCapital'] as num?)?.toDouble() ?? 0.0,
      remainingInterest: (data['remainingInterest'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'PLN',
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(data['updatedAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Aktualizuje status głosowania inwestora
  Future<void> updateVotingStatus(
    String clientId,
    VotingStatus newStatus,
  ) async {
    try {
      await _clientService.updateClientFields(clientId, {
        'votingStatus': newStatus.name,
      });
      clearCache('clients');
    } catch (e) {
      logError('updateVotingStatus', e);
      rethrow;
    }
  }

  /// Aktualizuje notatki inwestora
  Future<void> updateInvestorNotes(String clientId, String notes) async {
    try {
      await _clientService.updateClientFields(clientId, {'notes': notes});
      clearCache('clients');
    } catch (e) {
      logError('updateInvestorNotes', e);
      rethrow;
    }
  }

  /// Aktualizuje kolor inwestora
  Future<void> updateInvestorColor(String clientId, String colorHex) async {
    try {
      await _clientService.updateClientFields(clientId, {
        'colorCode': colorHex,
      });
      clearCache('clients');
    } catch (e) {
      logError('updateInvestorColor', e);
      rethrow;
    }
  }

  /// Oznacza inwestycje jako nierentowne
  Future<void> markInvestmentsAsUnviable(
    String clientId,
    List<String> investmentIds,
  ) async {
    try {
      await _clientService.updateClientFields(clientId, {
        'unviableInvestments': investmentIds,
      });
      clearCache('clients');
    } catch (e) {
      logError('markInvestmentsAsUnviable', e);
      rethrow;
    }
  }

  /// Generuje dane do wysyłki email
  Future<Map<String, dynamic>> generateEmailData(
    List<InvestorSummary> selectedInvestors,
    String emailTemplate,
  ) async {
    try {
      final emails = selectedInvestors
          .map((investor) => investor.client.email)
          .where((email) => email.isNotEmpty)
          .toList();

      return {
        'emails': emails,
        'template': emailTemplate,
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      logError('generateEmailData', e);
      rethrow;
    }
  }

  /// Czyści cache inwestorów
  @override
  void clearCache(String key) {
    _investorsCache = null;
    _cacheTimestamp = null;
    print('🗑️ [Analytics] Cache wyczyszczony');
  }
}

/// Klasa przechowująca wyniki analizy kontroli większościowej
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

/// Klasa przechowująca informacje o inwestorze z jego udziałem kontrolnym
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

/// Klasa przechowująca rozkład kapitału według statusów głosowania
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

/// Klasa przechowująca wyniki analizy inwestorów z paginacją
class InvestorAnalyticsResult {
  final List<InvestorSummary> investors;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final double totalViableCapital;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const InvestorAnalyticsResult({
    required this.investors,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.totalViableCapital,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  double get averageViableCapital =>
      investors.isNotEmpty ? totalViableCapital / investors.length : 0.0;
}
