import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/investment.dart';
import '../models/client.dart';
import '../models/investor_summary.dart';
import '../models/product.dart';
import 'base_service.dart';

/// Usługa do pobierania inwestorów dla standardowych produktów (Product)
class StandardProductInvestorsService extends BaseService {
  final String _investmentsCollection = 'investments';

  /// Pobiera inwestorów dla danego produktu na podstawie nazwy produktu
  Future<List<InvestorSummary>> getInvestorsByProductName(
    String productName,
  ) async {
    try {
      print(
        '📊 [StandardProductInvestors] Pobieranie inwestorów dla produktu: $productName',
      );

      // Pobierz wszystkie inwestycje dla danego produktu
      final snapshot = await firestore
          .collection(_investmentsCollection)
          .where('produkt_nazwa', isEqualTo: productName)
          .get();

      if (snapshot.docs.isEmpty) {
        print(
          '⚠️ [StandardProductInvestors] Brak inwestycji dla produktu: $productName',
        );
        return [];
      }

      return await _processInvestmentsToInvestors(snapshot.docs);
    } catch (e) {
      logError('getInvestorsByProductName', e);
      print('❌ [StandardProductInvestors] Błąd: $e');
      return [];
    }
  }

  /// Pobiera inwestorów dla danego typu produktu
  Future<List<InvestorSummary>> getInvestorsByProductType(
    ProductType productType,
  ) async {
    try {
      print(
        '📊 [StandardProductInvestors] Pobieranie inwestorów dla typu: ${productType.displayName}',
      );

      // Mapowanie typu na string używany w bazie danych
      String typeStr;
      switch (productType) {
        case ProductType.bonds:
          typeStr = 'Obligacje';
          break;
        case ProductType.shares:
          typeStr = 'Udziały';
          break;
        case ProductType.loans:
          typeStr = 'Pożyczki';
          break;
        case ProductType.apartments:
          typeStr = 'Apartamenty';
          break;
      }

      // Pobierz wszystkie inwestycje dla danego typu produktu
      final snapshot = await firestore
          .collection(_investmentsCollection)
          .where('typ_produktu', isEqualTo: typeStr)
          .get();

      if (snapshot.docs.isEmpty) {
        print(
          '⚠️ [StandardProductInvestors] Brak inwestycji dla typu: $typeStr',
        );
        return [];
      }

      return await _processInvestmentsToInvestors(snapshot.docs);
    } catch (e) {
      logError('getInvestorsByProductType', e);
      print('❌ [StandardProductInvestors] Błąd: $e');
      return [];
    }
  }

  /// Pobiera inwestorów dla produktu standardowego
  Future<List<InvestorSummary>> getInvestorsForProduct(Product product) async {
    // Użyj nazwy produktu do wyszukiwania
    return await getInvestorsByProductName(product.name);
  }

  /// Pobiera inwestorów dla spółki
  Future<List<InvestorSummary>> getInvestorsByCompany(String companyId) async {
    try {
      print(
        '📊 [StandardProductInvestors] Pobieranie inwestorów dla spółki: $companyId',
      );

      // Pobierz wszystkie inwestycje dla danej spółki
      final snapshot = await firestore
          .collection(_investmentsCollection)
          .where('id_spolka', isEqualTo: companyId)
          .get();

      if (snapshot.docs.isEmpty) {
        print(
          '⚠️ [StandardProductInvestors] Brak inwestycji dla spółki: $companyId',
        );
        return [];
      }

      return await _processInvestmentsToInvestors(snapshot.docs);
    } catch (e) {
      logError('getInvestorsByCompany', e);
      print('❌ [StandardProductInvestors] Błąd: $e');
      return [];
    }
  }

  /// Pobiera statystyki inwestycji dla produktu
  Future<Map<String, dynamic>> getProductInvestmentStats(
    Product product,
  ) async {
    try {
      final snapshot = await firestore
          .collection(_investmentsCollection)
          .where('produkt_nazwa', isEqualTo: product.name)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'totalInvestors': 0,
          'totalInvestments': 0,
          'totalValue': 0.0,
          'averageInvestment': 0.0,
          'remainingCapital': 0.0,
          'realizedCapital': 0.0,
          'activeInvestments': 0,
        };
      }

      final investments = snapshot.docs.map((doc) {
        return Investment.fromFirestore(doc);
      }).toList();

      final totalValue = investments.fold<double>(
        0.0,
        (sum, inv) => sum + inv.investmentAmount,
      );

      final remainingCapital = investments.fold<double>(
        0.0,
        (sum, inv) => sum + inv.remainingCapital,
      );

      final realizedCapital = investments.fold<double>(
        0.0,
        (sum, inv) => sum + inv.realizedCapital,
      );

      final activeInvestments = investments
          .where((inv) => inv.status == InvestmentStatus.active)
          .length;

      final uniqueInvestors = investments
          .map((inv) => inv.clientId)
          .toSet()
          .length;

      return {
        'totalInvestors': uniqueInvestors,
        'totalInvestments': investments.length,
        'totalValue': totalValue,
        'averageInvestment': totalValue / investments.length,
        'remainingCapital': remainingCapital,
        'realizedCapital': realizedCapital,
        'activeInvestments': activeInvestments,
      };
    } catch (e) {
      logError('getProductInvestmentStats', e);
      return {
        'totalInvestors': 0,
        'totalInvestments': 0,
        'totalValue': 0.0,
        'averageInvestment': 0.0,
        'remainingCapital': 0.0,
        'realizedCapital': 0.0,
        'activeInvestments': 0,
      };
    }
  }

  /// Pobiera top inwestorów dla produktu
  Future<List<Map<String, dynamic>>> getTopInvestorsForProduct(
    Product product, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await firestore
          .collection(_investmentsCollection)
          .where('produkt_nazwa', isEqualTo: product.name)
          .orderBy('kapital_pozostaly', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'clientName': data['klient'] ?? '',
          'investmentAmount': data['kwota_inwestycji'] ?? 0.0,
          'remainingCapital': data['kapital_pozostaly'] ?? 0.0,
          'realizedCapital': data['kapital_zrealizowany'] ?? 0.0,
          'signedDate': data['data_podpisania'] ?? '',
        };
      }).toList();
    } catch (e) {
      logError('getTopInvestorsForProduct', e);
      return [];
    }
  }

  /// Przetwarza dokumenty inwestycji na listę inwestorów
  /// 🚀 NOWE: UŻYWA obliczenia NA KOŃCU zamiast dla każdego klienta osobno
  Future<List<InvestorSummary>> _processInvestmentsToInvestors(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    try {
      // Konwertuj na obiekty Investment
      final investments = docs.map((doc) {
        return Investment.fromFirestore(doc);
      }).toList();

      print(
        '📈 [StandardProductInvestors] Znaleziono ${investments.length} inwestycji',
      );

      // Grupuj inwestycje według klientów
      final Map<String, List<Investment>> investmentsByClientId = {};
      for (final investment in investments) {
        final clientId = investment.clientId;
        print(
          '🔍 [StandardProductInvestors] Investment clientId: "$clientId", clientName: "${investment.clientName}"',
        );
        investmentsByClientId.putIfAbsent(clientId, () => []).add(investment);
      }

      // Pobierz unikalne ID klientów
      final clientIds = investmentsByClientId.keys.toList();
      print(
        '👥 [StandardProductInvestors] Znaleziono ${clientIds.length} unikalnych klientów',
      );

      // Pobierz dane klientów
      final clients = await _getClientsByIds(clientIds);
      print(
        '👤 [StandardProductInvestors] Załadowano dane ${clients.length} klientów',
      );

      // Jeśli nie znaleziono klientów po ID, spróbuj wyszukać po nazwie
      if (clients.isEmpty && clientIds.isNotEmpty) {
        print(
          '🔄 [StandardProductInvestors] Próbuję wyszukać klientów po nazwie...',
        );
        final clientsByName = await _getClientsByNames(investments);
        print(
          '👤 [StandardProductInvestors] Znaleziono ${clientsByName.length} klientów po nazwie',
        );
        return await _createInvestorSummariesFromClientNames(
          investments,
          clientsByName,
        );
      } // Utwórz mapowanie numeryczne ID -> UUID klienta
      final Map<String, String> numericIdToUuid = {};
      for (final client in clients) {
        // Bezpośrednie mapowanie przez excelId
        if (client.excelId != null && clientIds.contains(client.excelId!)) {
          numericIdToUuid[client.excelId!] = client.id;
          print(
            '🔗 [StandardProductInvestors] Mapowanie przez excelId: ${client.excelId} -> ${client.id}',
          );
        } else {
          // Fallback: spróbuj znaleźć numeryczne ID dla tego klienta przez nazwę
          for (final numericId in clientIds) {
            final clientInvestments = investmentsByClientId[numericId] ?? [];
            // Sprawdź czy któraś z inwestycji ma nazwę tego klienta
            if (clientInvestments.any((inv) => inv.clientName == client.name)) {
              numericIdToUuid[numericId] = client.id;
              print(
                '🔗 [StandardProductInvestors] Mapowanie przez nazwę: $numericId (${client.name}) -> ${client.id}',
              );
              break;
            }
          }
        }
      }

      print(
        '🔗 [StandardProductInvestors] Utworzono mapowanie numericId -> UUID: $numericIdToUuid',
      );

      print(
        '🚀 [StandardProductInvestors] Tworzenie inwestorów z obliczeniami na końcu',
      );

      // ✅ NOWE: Utwórz podsumowania BEZ OBLICZEŃ (tylko zbieranie danych)
      final List<InvestorSummary> investorsWithoutCalculations = [];
      for (final client in clients) {
        // Znajdź inwestycje dla tego klienta przez mapowanie
        List<Investment> clientInvestments = [];
        for (final entry in numericIdToUuid.entries) {
          if (entry.value == client.id) {
            clientInvestments.addAll(investmentsByClientId[entry.key] ?? []);
          }
        }

        if (clientInvestments.isNotEmpty) {
          // ⭐ KLUCZOWA ZMIANA: Używamy withoutCalculations() zamiast fromInvestments()
          final investorSummary = InvestorSummary.withoutCalculations(
            client,
            clientInvestments,
          );
          investorsWithoutCalculations.add(investorSummary);
        }
      }

      print(
        '  ✅ Utworzono ${investorsWithoutCalculations.length} InvestorSummary bez obliczeń',
      );

      // 🧮 OBLICZENIA NA KOŃCU: Oblicz capitalSecuredByRealEstate TYLKO RAZ dla wszystkich
      final investors = InvestorSummary.calculateSecuredCapitalForAll(
        investorsWithoutCalculations,
      );

      // Sortuj według wartości inwestycji (malejąco)
      investors.sort((a, b) => b.totalValue.compareTo(a.totalValue));

      print(
        '✅ [StandardProductInvestors] Utworzono ${investors.length} podsumowań inwestorów z ServerSideStatisticsService',
      );
      return investors;
    } catch (e) {
      logError('_processInvestmentsToInvestors', e);
      return [];
    }
  }

  /// Pobiera dane klientów na podstawie listy ID
  Future<List<Client>> _getClientsByIds(List<String> clientIds) async {
    try {
      print('🔍 [StandardProductInvestors] Szukam klientów o ID: $clientIds');
      final List<Client> clients = [];

      // Pierwszy krok: próbuj znaleźć po UUID (document ID)
      const batchSize = 10;
      for (int i = 0; i < clientIds.length; i += batchSize) {
        final batch = clientIds.skip(i).take(batchSize).toList();
        print('� [StandardProductInvestors] Przetwarzam batch UUID: $batch');

        final snapshot = await firestore
            .collection('clients')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        print(
          '� [StandardProductInvestors] Znaleziono ${snapshot.docs.length} dokumentów klientów w batch UUID',
        );

        final batchClients = snapshot.docs.map((doc) {
          print(
            '👤 [StandardProductInvestors] Przetwarzam klienta UUID: ${doc.id}',
          );
          return Client.fromFirestore(doc);
        }).toList();

        clients.addAll(batchClients);
      }

      // Jeśli nie znaleziono wszystkich klientów, spróbuj przez excelId
      final foundClientIds = clients.map((c) => c.id).toSet();
      final missingClientIds = clientIds
          .where((id) => !foundClientIds.contains(id))
          .toList();

      if (missingClientIds.isNotEmpty) {
        print(
          '🔄 [StandardProductInvestors] Próbuję znaleźć brakujących klientów przez excelId: $missingClientIds',
        );

        for (final missingId in missingClientIds) {
          final excelSnapshot = await firestore
              .collection('clients')
              .where('excelId', isEqualTo: missingId)
              .limit(1)
              .get();

          if (excelSnapshot.docs.isNotEmpty) {
            final client = Client.fromFirestore(excelSnapshot.docs.first);
            clients.add(client);
            print(
              '✅ [StandardProductInvestors] Znaleziono klienta przez excelId: $missingId -> ${client.id}',
            );
          } else {
            print(
              '❌ [StandardProductInvestors] Nie znaleziono klienta o ID: $missingId',
            );
          }
        }
      }

      print(
        '🎯 [StandardProductInvestors] Łącznie załadowano ${clients.length} klientów',
      );
      return clients;
    } catch (e) {
      logError('_getClientsByIds', e);
      print('❌ [StandardProductInvestors] Błąd pobierania klientów: $e');
      return [];
    }
  }

  /// Pobiera klientów na podstawie nazw z inwestycji (fallback method)
  Future<List<Client>> _getClientsByNames(List<Investment> investments) async {
    try {
      final uniqueClientNames = investments
          .map((inv) => inv.clientName)
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      print(
        '🔍 [StandardProductInvestors] Szukam klientów po nazwach: $uniqueClientNames',
      );

      final List<Client> clients = [];

      for (final clientName in uniqueClientNames) {
        final snapshot = await firestore
            .collection('clients')
            .where('imie_nazwisko', isEqualTo: clientName)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final client = Client.fromFirestore(snapshot.docs.first);
          clients.add(client);
          print(
            '✅ [StandardProductInvestors] Znaleziono klienta po nazwie: ${client.name}',
          );
        } else {
          print(
            '❌ [StandardProductInvestors] Nie znaleziono klienta: $clientName',
          );
        }
      }

      return clients;
    } catch (e) {
      logError('_getClientsByNames', e);
      return [];
    }
  }

  /// Tworzy podsumowania inwestorów na podstawie nazw klientów
  /// 🚀 NOWE: Używa obliczenia NA KOŃCU zamiast dla każdego klienta osobno
  Future<List<InvestorSummary>> _createInvestorSummariesFromClientNames(
    List<Investment> investments,
    List<Client> clients,
  ) async {
    try {
      // Grupuj inwestycje według nazw klientów
      final Map<String, List<Investment>> investmentsByClientName = {};
      for (final investment in investments) {
        final clientName = investment.clientName;
        investmentsByClientName
            .putIfAbsent(clientName, () => [])
            .add(investment);
      }

      print(
        '🚀 [StandardProductInvestors] Tworzenie ${clients.length} inwestorów z obliczeniami na końcu',
      );

      // ✅ NOWE: Utwórz podsumowania BEZ OBLICZEŃ (tylko zbieranie danych)
      final List<InvestorSummary> investorsWithoutCalculations = [];
      for (final client in clients) {
        final clientInvestments = investmentsByClientName[client.name] ?? [];
        if (clientInvestments.isNotEmpty) {
          // ⭐ KLUCZOWA ZMIANA: Używamy withoutCalculations() zamiast fromInvestments()
          final investorSummary = InvestorSummary.withoutCalculations(
            client,
            clientInvestments,
          );
          investorsWithoutCalculations.add(investorSummary);
        }
      }

      print(
        '  ✅ Utworzono ${investorsWithoutCalculations.length} InvestorSummary bez obliczeń',
      );

      // 🧮 OBLICZENIA NA KOŃCU: Oblicz capitalSecuredByRealEstate TYLKO RAZ dla wszystkich
      final investors = InvestorSummary.calculateSecuredCapitalForAll(
        investorsWithoutCalculations,
      );

      // Sortuj według wartości inwestycji (malejąco)
      investors.sort((a, b) => b.totalValue.compareTo(a.totalValue));

      print(
        '✅ [StandardProductInvestors] Utworzono ${investors.length} podsumowań inwestorów z obliczeniami na końcu',
      );
      return investors;
    } catch (e) {
      logError('_createInvestorSummariesFromClientNames', e);
      return [];
    }
  }

  /// Pobiera trendy inwestycji dla produktu (ostatnie 12 miesięcy)
  Future<List<Map<String, dynamic>>> getProductInvestmentTrends(
    Product product,
  ) async {
    try {
      final now = DateTime.now();
      final twelveMonthsAgo = DateTime(now.year - 1, now.month, now.day);

      final snapshot = await firestore
          .collection(_investmentsCollection)
          .where('produkt_nazwa', isEqualTo: product.name)
          .where(
            'data_podpisania',
            isGreaterThan: twelveMonthsAgo.toIso8601String(),
          )
          .orderBy('data_podpisania')
          .get();

      // Grupuj według miesięcy
      final monthlyData = <String, Map<String, dynamic>>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final dateStr = data['data_podpisania'] as String?;
        if (dateStr != null) {
          final date = DateTime.tryParse(dateStr);
          if (date != null) {
            final monthKey =
                '${date.year}-${date.month.toString().padLeft(2, '0')}';

            monthlyData.putIfAbsent(
              monthKey,
              () => {
                'month': monthKey,
                'count': 0,
                'totalValue': 0.0,
                'averageValue': 0.0,
              },
            );

            monthlyData[monthKey]!['count'] =
                (monthlyData[monthKey]!['count'] as int) + 1;
            monthlyData[monthKey]!['totalValue'] =
                (monthlyData[monthKey]!['totalValue'] as double) +
                (data['kwota_inwestycji'] as num? ?? 0).toDouble();
          }
        }
      }

      // Oblicz średnie wartości
      for (final monthData in monthlyData.values) {
        final count = monthData['count'] as int;
        final totalValue = monthData['totalValue'] as double;
        monthData['averageValue'] = count > 0 ? totalValue / count : 0.0;
      }

      return monthlyData.values.toList()..sort(
        (a, b) => (a['month'] as String).compareTo(b['month'] as String),
      );
    } catch (e) {
      logError('getProductInvestmentTrends', e);
      return [];
    }
  }
}
