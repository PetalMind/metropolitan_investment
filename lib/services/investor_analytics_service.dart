import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client.dart';
import '../models/investment.dart';
import '../models/investor_summary.dart';
import '../models/product.dart';
import 'base_service.dart';
import 'client_service.dart';

class InvestorAnalyticsService extends BaseService {
  final ClientService _clientService = ClientService();

  // Pobierz wszystkich inwestorów posortowanych według kapitału pozostałego
  Future<List<InvestorSummary>> getInvestorsSortedByRemainingCapital({
    bool includeInactive = false,
  }) async {
    try {
      // Pobierz wszystkich klientów
      final clients = await _clientService.getAllClients();
      final activeClients = includeInactive
          ? clients
          : clients.where((c) => c.isActive).toList();

      // Dla każdego klienta pobierz jego inwestycje
      final List<InvestorSummary> summaries = [];

      for (final client in activeClients) {
        final investments = await _getInvestmentsByClientName(client.name);
        if (investments.isNotEmpty) {
          final summary = InvestorSummary.fromInvestments(client, investments);
          summaries.add(summary);
        }
      }

      // Sortuj według łącznej wartości (kapitał pozostały + udziały)
      summaries.sort((a, b) => b.totalValue.compareTo(a.totalValue));

      // Oblicz procentowy udział każdego inwestora
      final totalPortfolioValue = summaries.fold<double>(
        0.0,
        (sum, summary) => sum + summary.totalValue,
      );

      // Dodaj informację o procentowym udziale
      for (int i = 0; i < summaries.length; i++) {
        final summary = summaries[i];
        final percentage = totalPortfolioValue > 0
            ? (summary.totalValue / totalPortfolioValue) * 100
            : 0.0;

        // Utworzenie nowego obiektu z obliczonym procentem
        summaries[i] = InvestorSummaryWithPercentage(
          summary: summary,
          percentageOfPortfolio: percentage,
          cumulativePercentage: _calculateCumulativePercentage(summaries, i),
        );
      }

      return summaries;
    } catch (e) {
      logError('getInvestorsSortedByRemainingCapital', e);
      throw Exception('Błąd podczas pobierania danych inwestorów: $e');
    }
  }

  // Oblicz skumulowany procent do danego indeksu
  double _calculateCumulativePercentage(
    List<InvestorSummary> summaries,
    int currentIndex,
  ) {
    final totalPortfolioValue = summaries.fold<double>(
      0.0,
      (sum, summary) => sum + summary.totalValue,
    );

    double cumulativeValue = 0;
    for (int i = 0; i <= currentIndex; i++) {
      cumulativeValue += summaries[i].totalValue;
    }

    return totalPortfolioValue > 0
        ? (cumulativeValue / totalPortfolioValue) * 100
        : 0.0;
  }

  // Znajdź punkt 51% kapitału
  InvestorRange? findMajorityControlPoint(
    List<InvestorSummary> sortedInvestors,
  ) {
    double cumulativeValue = 0;
    final totalValue = sortedInvestors.fold<double>(
      0.0,
      (sum, summary) => sum + summary.totalValue,
    );

    for (int i = 0; i < sortedInvestors.length; i++) {
      cumulativeValue += sortedInvestors[i].totalValue;
      final percentage = (cumulativeValue / totalValue) * 100;

      if (percentage >= 51.0) {
        return InvestorRange(
          investorCount: i + 1,
          percentage: percentage,
          totalValue: cumulativeValue,
          investors: sortedInvestors.take(i + 1).toList(),
        );
      }
    }

    return null;
  }

  // Filtruj inwestorów według wysokości kapitału
  List<InvestorSummary> filterByCapitalAmount({
    required List<InvestorSummary> investors,
    double? minAmount,
    double? maxAmount,
  }) {
    return investors.where((investor) {
      final amount = investor.totalValue;
      if (minAmount != null && amount < minAmount) return false;
      if (maxAmount != null && amount > maxAmount) return false;
      return true;
    }).toList();
  }

  // Filtruj inwestorów według firmy
  List<InvestorSummary> filterByCompany({
    required List<InvestorSummary> investors,
    required String companyName,
  }) {
    return investors.where((investor) {
      return investor.investmentsByCompany.keys.any(
        (company) => company.toLowerCase().contains(companyName.toLowerCase()),
      );
    }).toList();
  }

  // Aktualizuj status głosowania inwestora
  Future<void> updateVotingStatus(String clientId, VotingStatus status) async {
    try {
      await _clientService.updateClientFields(clientId, {
        'votingStatus': status.name,
      });
      clearCache('investor_analytics');
    } catch (e) {
      logError('updateVotingStatus', e);
      throw Exception('Błąd podczas aktualizacji statusu głosowania: $e');
    }
  }

  // Aktualizuj notatki inwestora
  Future<void> updateInvestorNotes(String clientId, String notes) async {
    try {
      await _clientService.updateClientFields(clientId, {'notes': notes});
      clearCache('investor_analytics');
    } catch (e) {
      logError('updateInvestorNotes', e);
      throw Exception('Błąd podczas aktualizacji notatek: $e');
    }
  }

  // Aktualizuj kolor inwestora
  Future<void> updateInvestorColor(String clientId, String colorCode) async {
    try {
      await _clientService.updateClientFields(clientId, {
        'colorCode': colorCode,
      });
      clearCache('investor_analytics');
    } catch (e) {
      logError('updateInvestorColor', e);
      throw Exception('Błąd podczas aktualizacji koloru: $e');
    }
  }

  // Oznacz inwestycje jako niewykonalne
  Future<void> markInvestmentsAsUnviable(
    String clientId,
    List<String> investmentIds,
  ) async {
    try {
      await _clientService.updateClientFields(clientId, {
        'unviableInvestments': investmentIds,
      });
      clearCache('investor_analytics');
    } catch (e) {
      logError('markInvestmentsAsUnviable', e);
      throw Exception(
        'Błąd podczas oznaczania inwestycji jako niewykonalne: $e',
      );
    }
  }

  // Generuj dane do wysyłki maili
  Future<List<InvestorEmailData>> generateEmailData(
    List<String> clientIds,
  ) async {
    try {
      final List<InvestorEmailData> emailData = [];

      for (final clientId in clientIds) {
        final client = await _clientService.getClient(clientId);
        if (client != null && client.email.isNotEmpty) {
          final investments = await _getInvestmentsByClientName(client.name);
          emailData.add(
            InvestorEmailData(client: client, investments: investments),
          );
        }
      }

      return emailData;
    } catch (e) {
      logError('generateEmailData', e);
      throw Exception('Błąd podczas generowania danych do maili: $e');
    }
  }

  // Pobierz inwestycje klienta według nazwy
  Future<List<Investment>> _getInvestmentsByClientName(
    String clientName,
  ) async {
    try {
      final snapshot = await firestore
          .collection('investments')
          .where('klient', isEqualTo: clientName)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _convertExcelDataToInvestment(doc.id, data);
      }).toList();
    } catch (e) {
      logError('_getInvestmentsByClientName', e);
      return [];
    }
  }

  // Konwersja danych Excel do Investment (kopiowana z InvestmentService)
  Investment _convertExcelDataToInvestment(
    String id,
    Map<String, dynamic> data,
  ) {
    // Mapowanie statusu
    InvestmentStatus status = InvestmentStatus.active;
    final statusStr = data['status_produktu']?.toString() ?? '';
    if (statusStr == 'Nieaktywny' || statusStr == 'Nieaktywowany') {
      status = InvestmentStatus.inactive;
    } else if (statusStr == 'Wykup wczesniejszy') {
      status = InvestmentStatus.earlyRedemption;
    }

    // Mapowanie typu produktu
    ProductType productType = ProductType.bonds;
    final typeStr = data['typ_produktu']?.toString() ?? '';
    if (typeStr == 'Udziały') productType = ProductType.shares;
    if (typeStr == 'Apartamenty') productType = ProductType.apartments;

    return Investment(
      id: id,
      clientId: '',
      clientName: data['klient']?.toString() ?? '',
      employeeId: '',
      employeeFirstName: data['praconwnik_imie']?.toString() ?? '',
      employeeLastName: data['pracownik_nazwisko']?.toString() ?? '',
      branchCode: data['oddzial']?.toString() ?? '',
      status: status,
      isAllocated: data['przydzial']?.toString() == '1',
      marketType: MarketType.primary,
      signedDate: _parseDate(data['data_podpisania']) ?? DateTime.now(),
      entryDate: _parseDate(data['data_wejscia_do_inwestycji']),
      exitDate: _parseDate(data['data_wyjscia_z_inwestycji']),
      proposalId: data['id_propozycja_nabycia']?.toString() ?? '',
      productType: productType,
      productName: data['produkt_nazwa']?.toString() ?? '',
      creditorCompany: data['wierzyciel_spolka']?.toString() ?? '',
      companyId: data['id_spolka']?.toString() ?? '',
      issueDate: _parseDate(data['data_emisji']),
      redemptionDate: _parseDate(data['data_wykupu']),
      sharesCount: data['ilosc_udzialow']?.toInt(),
      investmentAmount:
          double.tryParse(data['kwota_inwestycji']?.toString() ?? '0') ?? 0.0,
      paidAmount:
          double.tryParse(data['kwota_wplat']?.toString() ?? '0') ?? 0.0,
      realizedCapital:
          double.tryParse(data['kapital_zrealizowany']?.toString() ?? '0') ??
          0.0,
      realizedInterest:
          double.tryParse(data['odsetki_zrealizowane']?.toString() ?? '0') ??
          0.0,
      transferToOtherProduct:
          double.tryParse(data['przekaz_na_inny_produkt']?.toString() ?? '0') ??
          0.0,
      remainingCapital:
          double.tryParse(data['kapital_pozostaly']?.toString() ?? '0') ?? 0.0,
      remainingInterest:
          double.tryParse(data['odsetki_pozostale']?.toString() ?? '0') ?? 0.0,
      plannedTax:
          double.tryParse(data['planowany_podatek']?.toString() ?? '0') ?? 0.0,
      realizedTax:
          double.tryParse(data['zrealizowany_podatek']?.toString() ?? '0') ??
          0.0,
      currency: 'PLN',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      additionalInfo: {'source_file': 'Excel import'},
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}

// Rozszerzenie InvestorSummary o informacje procentowe
class InvestorSummaryWithPercentage extends InvestorSummary {
  final double percentageOfPortfolio;
  final double cumulativePercentage;

  InvestorSummaryWithPercentage({
    required InvestorSummary summary,
    required this.percentageOfPortfolio,
    required this.cumulativePercentage,
  }) : super(
         client: summary.client,
         investments: summary.investments,
         totalRemainingCapital: summary.totalRemainingCapital,
         totalSharesValue: summary.totalSharesValue,
         totalValue: summary.totalValue,
         totalInvestmentAmount: summary.totalInvestmentAmount,
         totalRealizedCapital: summary.totalRealizedCapital,
         investmentCount: summary.investmentCount,
       );
}

// Klasa reprezentująca zakres inwestorów (np. do punktu 51%)
class InvestorRange {
  final int investorCount;
  final double percentage;
  final double totalValue;
  final List<InvestorSummary> investors;

  InvestorRange({
    required this.investorCount,
    required this.percentage,
    required this.totalValue,
    required this.investors,
  });
}

// Klasa do generowania danych email
class InvestorEmailData {
  final Client client;
  final List<Investment> investments;

  InvestorEmailData({required this.client, required this.investments});

  String get formattedInvestmentList {
    return investments
        .map(
          (inv) =>
              '• ${inv.productName} - ${inv.remainingCapital.toStringAsFixed(2)} PLN',
        )
        .join('\n');
  }
}
