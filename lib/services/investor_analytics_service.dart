import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';
import 'firebase_functions_analytics_service.dart';

class InvestorAnalyticsService extends BaseService {
  final ClientService _clientService = ClientService();
  final ClientIdMappingService _idMappingService = ClientIdMappingService();
  final UnifiedVotingStatusService _votingService =
      UnifiedVotingStatusService();
  final FirebaseFunctionsAnalyticsService _functionsService =
      FirebaseFunctionsAnalyticsService();

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

    try {
      // Pobierz wszystkich inwestorów
      final allInvestors = await _loadAllInvestors(includeInactive);

      if (allInvestors.isEmpty) {
        return MajorityControlAnalysis.empty();
      }

      // Sortuj według kapitału pozostałego (remainingCapital) malejąco
      allInvestors.sort(
        (a, b) => b.viableRemainingCapital.compareTo(a.viableRemainingCapital),
      );

      // ⭐ Oblicz całkowitą wartość portfela TYLKO na podstawie kapitału pozostałego
      final totalViableCapital = allInvestors.fold<double>(
        0.0,
        (sum, investor) => sum + investor.viableRemainingCapital,
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
      logError('analyzeMajorityControl', e);
      return MajorityControlAnalysis.empty();
    }
  }

  /// Analiza rozkładu kapitału według statusu głosowania
  Future<VotingCapitalDistribution> analyzeVotingDistribution({
    bool includeInactive = false,
  }) async {

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

      for (final entry in distribution.entries) {
        final percentage = totalCapital > 0
            ? (entry.value / totalCapital) * 100
            : 0.0;
      }

      return VotingCapitalDistribution(
        capitalByStatus: distribution,
        countByStatus: counts,
        totalCapital: totalCapital,
        totalInvestors: allInvestors.length,
        analysisDate: DateTime.now(),
      );
    } catch (e) {
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

    try {
      // Sprawdź cache
      final isCacheValid =
          _investorsCache != null &&
          _cacheTimestamp != null &&
          DateTime.now().difference(_cacheTimestamp!).abs() < _cacheTimeout;

      List<InvestorSummary> allInvestors;

      if (isCacheValid) {
        allInvestors = _investorsCache!.values.expand((x) => x).toList();
      } else {
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
                  investor.totalRemainingCapital >
                  investor.viableRemainingCapital,
            )
            .toList();
      }

      // Sortowanie
      filteredInvestors.sort((a, b) {
        late final int comparison;

        switch (sortBy) {
          case 'name':
            comparison = a.client.name.compareTo(b.client.name);
            break;
          case 'totalValue':
            comparison = a.viableRemainingCapital.compareTo(
              b.viableRemainingCapital,
            );
            break;
          case 'viableCapital':
          case 'viableRemainingCapital':
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
          case 'totalInvestmentAmount':
            comparison = a.totalInvestmentAmount.compareTo(
              b.totalInvestmentAmount,
            );
            break;
          case 'capitalSecuredByRealEstate':
            comparison = a.capitalSecuredByRealEstate.compareTo(
              b.capitalSecuredByRealEstate,
            );
            break;
          case 'capitalForRestructuring':
            comparison = a.capitalForRestructuring.compareTo(
              b.capitalForRestructuring,
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

      // Paginacja
      final totalCount = filteredInvestors.length;
      final totalPages = (totalCount / pageSize).ceil();
      final startIndex = (page - 1) * pageSize;
      final endIndex = (startIndex + pageSize).clamp(0, totalCount);
      // Użyj wszystkich przefiltrowanych inwestorów dla analityki
      final paginatedInvestors = filteredInvestors.sublist(
        startIndex,
        endIndex, // Usuń ograniczenie do 250
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

    try {
      print('🔍 [DEBUG] Wywołuję _clientService.getAllClients()...');
      final clients = await _clientService.getAllClients();

      // DODATKOWE SPRAWDZENIE - czy to rzeczywiście wszystkie dokumenty?
      final directCheck = await FirebaseFirestore.instance
          .collection('clients')
          .get();

      if (directCheck.docs.length != clients.length) {
      }

      // DEBUG: Sprawdź pierwsze kilku klientów
      if (clients.isNotEmpty) {
        final firstClient = clients.first;
      }

      final allInvestments = await _getAllInvestments();

      // DEBUG: Sprawdź pierwsze kilka inwestycji
      if (allInvestments.isNotEmpty) {
        final firstInvestment = allInvestments.first;
      }

      // Grupa inwestycji według clientId (nie ExcelID!)
      final Map<String, List<Investment>> investmentsByClientId = {};
      for (final investment in allInvestments) {
        final clientId = investment.clientId; // To powinno odpowiadać client.id
        investmentsByClientId.putIfAbsent(clientId, () => []).add(investment);
      }

      final List<InvestorSummary> investors = [];

      for (final client in clients) {
        if (!includeInactive && !client.isActive) continue;

        // UŻYJ excelId (które teraz zawiera data['id'] z Firebase) do łączenia z investment.clientId
        List<Investment> clientInvestments = [];

        // 1. Sprawdź po excelId (to jest data['id'] number z Firebase jako string)
        if (client.excelId != null && client.excelId!.isNotEmpty) {
          clientInvestments = investmentsByClientId[client.excelId!] ?? [];
        }

        // 2. Jeśli nie znaleziono po excelId, spróbuj po Firebase doc ID
        if (clientInvestments.isEmpty) {
          clientInvestments = investmentsByClientId[client.id] ?? [];
        }

        // 3. Jeśli nadal nie ma, spróbuj po nazwie klienta
        if (clientInvestments.isEmpty) {
          for (final investment in allInvestments) {
            if (investment.clientName.toLowerCase().trim() ==
                client.name.toLowerCase().trim()) {
              clientInvestments.add(investment);
            }
          }
          if (clientInvestments.isNotEmpty) {
          }
        }

        if (clientInvestments.isEmpty) {
          continue;
        }

        // DEBUG: Sprawdź kapitał klienta
        final totalCapital = clientInvestments.fold<double>(
          0.0,
          (sum, inv) => sum + inv.remainingCapital,
        );

        // 🚀 NOWE: Utwórz podsumowanie inwestora używając ServerSideStatisticsService
        // zamiast lokalnych obliczeń w InvestorSummary.fromInvestments()
        final investorSummary =
            await _createInvestorSummaryWithServerCalculations(
              client,
              clientInvestments,
            );

        // DEBUG: Sprawdź viableRemainingCapital

        investors.add(investorSummary);
      }

      final totalCapitalAllInvestors = investors.fold<double>(
        0.0,
        (sum, inv) => sum + inv.viableRemainingCapital,
      );

      return investors;
    } catch (e) {
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
      logError('_getAllInvestments', e);
      rethrow;
    }
  }

  /// 🚀 NOWA METODA: Tworzy InvestorSummary używając ServerSideStatisticsService
  Future<InvestorSummary> _createInvestorSummaryWithServerCalculations(
    Client client,
    List<Investment> investments,
  ) async {
    try {

      // Oblicz podstawowe sumy
      final totalInvestmentAmount = investments.fold(
        0.0,
        (sum, inv) => sum + inv.investmentAmount,
      );
      final totalRemainingCapital = investments.fold(
        0.0,
        (sum, inv) => sum + inv.remainingCapital,
      );
      final totalRealizedCapital = investments.fold(
        0.0,
        (sum, inv) => sum + inv.realizedCapital,
      );
      final capitalSecuredByRealEstate = investments.fold(
        0.0,
        (sum, inv) => sum + inv.capitalSecuredByRealEstate,
      );
      final capitalForRestructuring = investments.fold(
        0.0,
        (sum, inv) => sum + inv.capitalForRestructuring,
      );

      // Używamy standardowego konstruktora InvestorSummary
      return InvestorSummary(
        client: client,
        investments: investments,
        totalInvestmentAmount: totalInvestmentAmount,
        totalRemainingCapital: totalRemainingCapital,
        totalRealizedCapital: totalRealizedCapital,
        totalSharesValue: 0.0, // Zawsze 0 dla nowej architektury
        totalValue: totalRemainingCapital, // totalValue = totalRemainingCapital
        capitalSecuredByRealEstate: capitalSecuredByRealEstate,
        capitalForRestructuring: capitalForRestructuring,
        investmentCount: investments.length,
      );
    } catch (e) {

      // ⚠️ DEPRECATED: Fallback do starych obliczeń - używaj withoutCalculations()
      return InvestorSummary.fromInvestments(client, investments);
    }
  }

  /// Konwertuje dane z Excel/Firestore na obiekt Investment
  Investment _convertExcelDataToInvestment(
    Map<String, dynamic> data,
    String docId,
  ) {
    // Helper function to parse capital values with commas
    double parseCapitalValue(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        // Handle empty strings and NULL values
        if (value.isEmpty ||
            value.trim().isEmpty ||
            value.toUpperCase() == 'NULL') {
          return 0.0;
        }

        // Debug logging for problematic values
        if (value.contains(',')) {
        }
        // Handle string values like "200,000.00" from Firebase
        final cleaned = value.toString().replaceAll(',', '');
        final parsed = double.tryParse(cleaned);
        if (parsed == null) {
        }
        return parsed ?? 0.0;
      }
      return 0.0;
    }

    return Investment(
      id: docId,
      // ⭐ KLIENT - używamy angielskich pól z Firebase
      clientId: data['clientId']?.toString() ?? '',
      clientName: data['clientName']?.toString() ?? '',
      employeeId: data['employeeId']?.toString() ?? '',
      employeeFirstName: data['employeeFirstName']?.toString() ?? '',
      employeeLastName: data['employeeLastName']?.toString() ?? '',
      branchCode:
          data['branch']?.toString() ?? data['branchCode']?.toString() ?? '',

      // ⭐ STATUS - mapowanie ze statusów Firebase
      status: _mapInvestmentStatus(data['status']?.toString()),
      isAllocated: data['isAllocated'] ?? true,
      marketType: _mapMarketType(data['productStatusEntry']?.toString()),

      // ⭐ DATY - parsowanie z różnych formatów
      signedDate:
          _parseDate(data['signingDate']) ??
          _parseDate(data['signedDate']) ??
          DateTime.now(),
      entryDate:
          _parseDate(data['investmentEntryDate']) ??
          _parseDate(data['entryDate']),
      exitDate: _parseDate(data['exitDate']),

      // ⭐ PRODUKT
      proposalId:
          data['proposalId']?.toString() ?? data['saleId']?.toString() ?? '',
      productType: _mapProductType(data['productType']?.toString()),
      productName: data['productName']?.toString() ?? '',
      creditorCompany: data['creditorCompany']?.toString() ?? '',
      companyId: data['companyId']?.toString() ?? '',
      issueDate: _parseDate(data['issueDate']),
      redemptionDate:
          _parseDate(data['redemptionDate']) ??
          _parseDate(data['repaymentDate']),

      // ⭐ UDZIAŁY
      sharesCount: data['shareCount'] != null && data['shareCount'] != 'NULL'
          ? int.tryParse(data['shareCount'].toString())
          : null,

      // ⭐ KWOTY FINANSOWE - tylko angielskie pola bez polskich!
      investmentAmount: parseCapitalValue(data['investmentAmount']),
      paidAmount: parseCapitalValue(data['paidAmount']),
      realizedCapital: parseCapitalValue(data['realizedCapital']),
      realizedInterest: parseCapitalValue(data['realizedInterest']),
      transferToOtherProduct: parseCapitalValue(data['transferToOtherProduct']),
      remainingCapital: parseCapitalValue(data['remainingCapital']),
      remainingInterest: parseCapitalValue(data['remainingInterest']),
      capitalForRestructuring: parseCapitalValue(
        data['capitalForRestructuring'],
      ),
      capitalSecuredByRealEstate: parseCapitalValue(
        data['capitalSecuredByRealEstate'],
      ),
      // ⭐ INNE
      currency: data['currency']?.toString() ?? 'PLN',

      // ⭐ DODATKOWE POLA dla kompatybilności
      additionalInfo: {
        ...data.map((key, value) => MapEntry(key, value)),

    
        if (data['accruedInterest'] != null)
          'narosle_odsetki': data['accruedInterest'],
        if (data['interestRate'] != null)
          'oprocentowanie': data['interestRate'],
        if (data['borrower'] != null) 'pozyczkobiorca': data['borrower'],
        if (data['collateral'] != null) 'zabezpieczenie': data['collateral'],
        if (data['loanNumber'] != null) 'numer_pozyczki': data['loanNumber'],
      },

      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(data['updatedAt']) ?? DateTime.now(),
    );
  }

  /// Mapuje status z Firebase na InvestmentStatus
  InvestmentStatus _mapInvestmentStatus(String? status) {
    if (status == null) return InvestmentStatus.active;

    switch (status.toLowerCase()) {
      case 'aktywny':
      case 'active':
        return InvestmentStatus.active;
      case 'nieaktywny':
      case 'inactive':
        return InvestmentStatus.inactive;
      case 'zakończony':
      case 'completed':
      case 'zakonczone':
      case 'spłacone':
      case 'splacone':
        return InvestmentStatus.completed;
      case 'opóźnienia':
      case 'opoznienia':
      case 'delayed':
        return InvestmentStatus.active; // Traktujemy jako aktywne
      default:
        return InvestmentStatus.active;
    }
  }

  /// Mapuje typ rynku z Firebase na MarketType
  MarketType _mapMarketType(String? marketType) {
    if (marketType == null) return MarketType.primary;

    switch (marketType.toLowerCase()) {
      case 'rynek wtórny':
      case 'rynek wtorny':
      case 'secondary':
      case 'wtórny':
      case 'wtorny':
        return MarketType.secondary;
      case 'odkup od klienta':
      case 'client redemption':
      case 'odkup':
        return MarketType.clientRedemption;
      case 'rynek pierwotny':
      case 'primary':
      case 'pierwotny':
      default:
        return MarketType.primary;
    }
  }

  /// Mapuje typ produktu z Firebase na ProductType
  ProductType _mapProductType(String? productType) {
    if (productType == null) return ProductType.bonds;

    switch (productType.toLowerCase()) {
      case 'loan':
      case 'loans':
      case 'pożyczka':
      case 'pozyczka':
      case 'pożyczki':
      case 'pozyczki':
        return ProductType.loans;
      case 'share':
      case 'shares':
      case 'udział':
      case 'udzial':
      case 'udziały':
      case 'udzialy':
        return ProductType.shares;
      case 'apartment':
      case 'apartments':
      case 'apartament':
      case 'apartamenty':
        return ProductType.apartments;
      case 'bond':
      case 'bonds':
      case 'obligacja':
      case 'obligacje':
      default:
        return ProductType.bonds;
    }
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

  /// Aktualizuje dane inwestora zgodnie z wzorcem OptimizedClientVotingService
  /// Z obsługą mapowania Excel ID -> Firestore ID
  Future<void> updateInvestorDetails(
    String clientId, {
    VotingStatus? votingStatus,
    String? notes,
    String? colorCode,
    ClientType? type,
    bool? isActive,
    String? updateReason,
    String? editedBy,
    String? editedByEmail,
    String? editedByName,
    String? userId,
    String? updatedVia,
  }) async {
    try {

      // Spróbuj znaleźć prawdziwe Firestore ID jeśli to Excel ID
      String? actualFirestoreId = clientId;

      // Sprawdź czy to może być Excel ID (numeryczne)
      if (RegExp(r'^\d+$').hasMatch(clientId)) {
        actualFirestoreId = await _idMappingService.findFirestoreIdByExcelId(
          clientId,
        );

        if (actualFirestoreId == null) {
          throw Exception(
            'Cannot find Firestore ID for Excel ID: $clientId. The client may have been deleted or the ID mapping is incomplete.',
          );
        }

      }

      // Sprawdź czy klient istnieje w Firestore
      final exists = await _clientService.clientExists(actualFirestoreId);
      if (!exists) {
        throw Exception(
          'Client with Firestore ID $actualFirestoreId does not exist',
        );
      }

      final Map<String, dynamic> updates = {};

      // Handle voting status update with history using EnhancedVotingStatusService
      if (votingStatus != null) {

        // Use UnifiedVotingStatusService for voting status with history
        final result = await _votingService.updateVotingStatus(
          actualFirestoreId,
          votingStatus,
          reason:
              updateReason ??
              'Aktualizacja danych inwestora przez interfejs użytkownika',
          editedBy: editedBy,
          editedByEmail: editedByEmail,
          editedByName: editedByName,
          userId: userId,
          updatedVia: updatedVia ?? 'investor_analytics_service',
          additionalChanges: {'original_client_id': clientId},
        );

        if (!result.isSuccess) {
          throw Exception(
            'Błąd aktualizacji statusu głosowania: ${result.error}',
          );
        }
      }

      // Handle other fields (notes, color, type, etc.)
      if (notes != null) {
        updates['notes'] = notes;
      }
      if (colorCode != null) {
        updates['colorCode'] = colorCode;
      }
      if (type != null) {
        updates['type'] = type; // Przekaż enum object
      }
      if (isActive != null) {
        updates['isActive'] = isActive;
      }

      // Update remaining non-voting fields if any
      if (updates.isNotEmpty) {
        await _clientService.updateClientFields(actualFirestoreId, updates);
      }

      // Clear analytics cache
      _clearAnalyticsCache();

    } catch (e) {
      logError('updateInvestorDetails', e);
      rethrow;
    }
  }

  /// Czyści cache związane z analitykami
  void _clearAnalyticsCache() {
    clearCache('clients');
    clearCache('all_investors');
    clearCache('majority_control');
    clearCache('investor_summary');

    // Wyczyść cache dla różnych filtrów
    for (final status in VotingStatus.values) {
      clearCache('investors_voting_${status.name}');
    }
  }

  /// Publiczna metoda czyszczenia cache dla całej analityki
  void clearAnalyticsCache() {
    _clearAnalyticsCache();

    // Asynchronicznie wyczyść także cache Firebase Functions
    _functionsService.clearServerCache().catchError((e) {
    });
  }

  /// Generuje dane do wysyłki email na podstawie wybranych inwestorów
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

  /// Pobiera inwestorów na podstawie listy ID klientów do generowania emaili
  Future<List<InvestorSummary>> getInvestorsByClientIds(
    List<String> clientIds,
  ) async {
    try {

      final allInvestors = await getAllInvestorsForAnalysis(
        includeInactive: true,
      );

      final filteredInvestors = allInvestors
          .where((investor) => clientIds.contains(investor.client.id))
          .toList();

      return filteredInvestors;
    } catch (e) {
      logError('getInvestorsByClientIds', e);
      rethrow;
    }
  }

  /// Czyści cache inwestorów
  @override
  void clearCache(String key) {
    _investorsCache = null;
    _cacheTimestamp = null;
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
