import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/investment.dart';
import '../models/client.dart';
import '../models/investor_summary.dart';
import '../models/unified_product.dart';
import 'base_service.dart';

/// Usługa do pobierania inwestorów dla konkretnych produktów
class ProductInvestorsService extends BaseService {
  final String _investmentsCollection = 'investments';

  /// Pobiera inwestorów dla danego produktu na podstawie nazwy produktu
  Future<List<InvestorSummary>> getInvestorsByProductName(
    String productName,
  ) async {
    try {
      print(
        '📊 [ProductInvestors] Pobieranie inwestorów dla produktu: $productName',
      );

      // Pobierz wszystkie inwestycje dla danego produktu
      final snapshot = await firestore
          .collection(_investmentsCollection)
          .where('produkt_nazwa', isEqualTo: productName)
          .get();

      if (snapshot.docs.isEmpty) {
        print(
          '⚠️ [ProductInvestors] Brak inwestycji dla produktu: $productName',
        );
        return [];
      }

      // Konwertuj na obiekty Investment
      final investments = snapshot.docs.map((doc) {
        return Investment.fromFirestore(doc);
      }).toList();

      print(
        '📈 [ProductInvestors] Znaleziono ${investments.length} inwestycji',
      );

      // Grupuj inwestycje według klientów
      final Map<String, List<Investment>> investmentsByClientId = {};
      for (final investment in investments) {
        final clientId = investment.clientId;
        print(
          '🔗 [ProductInvestors] Investment ${investment.id} -> Client ID: "$clientId"',
        );
        investmentsByClientId.putIfAbsent(clientId, () => []).add(investment);
      }

      // Pobierz unikalne ID klientów
      final clientIds = investmentsByClientId.keys.toList();
      print(
        '👥 [ProductInvestors] Znaleziono ${clientIds.length} unikalnych klientów',
      );

      // Pobierz dane klientów
      final clients = await _getClientsByIds(clientIds);
      print('👤 [ProductInvestors] Załadowano dane ${clients.length} klientów');

      // Utwórz mapowanie numeryczne ID -> UUID klienta
      final Map<String, String> numericIdToUuid = {};
      for (final client in clients) {
        // Bezpośrednie mapowanie przez excelId
        if (client.excelId != null && clientIds.contains(client.excelId!)) {
          numericIdToUuid[client.excelId!] = client.id;
          print(
            '🔗 [ProductInvestors] Mapowanie przez excelId: ${client.excelId} -> ${client.id}',
          );
        } else {
          // Fallback: spróbuj znaleźć numeryczne ID dla tego klienta przez nazwę
          for (final numericId in clientIds) {
            final clientInvestments = investmentsByClientId[numericId] ?? [];
            // Sprawdź czy któraś z inwestycji ma nazwę tego klienta
            if (clientInvestments.any((inv) => inv.clientName == client.name)) {
              numericIdToUuid[numericId] = client.id;
              print(
                '🔗 [ProductInvestors] Mapowanie przez nazwę: $numericId (${client.name}) -> ${client.id}',
              );
              break;
            }
          }
        }
      }

      print(
        '🔗 [ProductInvestors] Utworzono mapowanie numericId -> UUID: $numericIdToUuid',
      );

      // Utwórz podsumowania inwestorów używając mapowania
      final List<InvestorSummary> investors = [];
      for (final client in clients) {
        // Znajdź inwestycje dla tego klienta przez mapowanie
        List<Investment> clientInvestments = [];
        for (final entry in numericIdToUuid.entries) {
          if (entry.value == client.id) {
            clientInvestments.addAll(investmentsByClientId[entry.key] ?? []);
          }
        }

        if (clientInvestments.isNotEmpty) {
          final investorSummary = InvestorSummary.fromInvestments(
            client,
            clientInvestments,
          );
          investors.add(investorSummary);
        }
      }

      // Sortuj według wartości inwestycji (malejąco)
      investors.sort((a, b) => b.totalValue.compareTo(a.totalValue));

      print(
        '✅ [ProductInvestors] Utworzono ${investors.length} podsumowań inwestorów',
      );
      return investors;
    } catch (e) {
      logError('getInvestorsByProductName', e);
      print('❌ [ProductInvestors] Błąd: $e');
      return [];
    }
  }

  /// Pobiera inwestorów dla danego typu produktu
  Future<List<InvestorSummary>> getInvestorsByProductType(
    UnifiedProductType productType,
  ) async {
    try {
      print(
        '📊 [ProductInvestors] Pobieranie inwestorów dla typu: ${productType.displayName}',
      );

      // Mapowanie typu na string używany w bazie danych
      String typeStr;
      switch (productType) {
        case UnifiedProductType.bonds:
          typeStr = 'Obligacje';
          break;
        case UnifiedProductType.shares:
          typeStr = 'Udziały';
          break;
        case UnifiedProductType.loans:
          typeStr = 'Pożyczki';
          break;
        case UnifiedProductType.apartments:
          typeStr = 'Apartamenty';
          break;
        case UnifiedProductType.other:
          typeStr = 'Inne';
          break;
      }

      // Pobierz wszystkie inwestycje dla danego typu produktu
      final snapshot = await firestore
          .collection(_investmentsCollection)
          .where('typ_produktu', isEqualTo: typeStr)
          .get();

      if (snapshot.docs.isEmpty) {
        print('⚠️ [ProductInvestors] Brak inwestycji dla typu: $typeStr');
        return [];
      }

      // Konwertuj na obiekty Investment
      final investments = snapshot.docs.map((doc) {
        return Investment.fromFirestore(doc);
      }).toList();

      print(
        '📈 [ProductInvestors] Znaleziono ${investments.length} inwestycji',
      );

      // Grupuj inwestycje według klientów
      final Map<String, List<Investment>> investmentsByClientId = {};
      for (final investment in investments) {
        final clientId = investment.clientId;
        investmentsByClientId.putIfAbsent(clientId, () => []).add(investment);
      }

      // Pobierz unikalne ID klientów
      final clientIds = investmentsByClientId.keys.toList();
      print(
        '👥 [ProductInvestors] Znaleziono ${clientIds.length} unikalnych klientów',
      );

      // Pobierz dane klientów
      final clients = await _getClientsByIds(clientIds);
      print('👤 [ProductInvestors] Załadowano dane ${clients.length} klientów');

      // Utwórz mapowanie numeryczne ID -> UUID klienta (ProductType)
      final Map<String, String> numericIdToUuid = {};
      for (final client in clients) {
        // Bezpośrednie mapowanie przez excelId
        if (client.excelId != null && clientIds.contains(client.excelId!)) {
          numericIdToUuid[client.excelId!] = client.id;
          print('🔗 [ProductInvestors] Mapowanie przez excelId: ${client.excelId} -> ${client.id}');
        } else {
          // Fallback: spróbuj znaleźć numeryczne ID dla tego klienta przez nazwę
          for (final numericId in clientIds) {
            final clientInvestments = investmentsByClientId[numericId] ?? [];
            // Sprawdź czy któraś z inwestycji ma nazwę tego klienta
            if (clientInvestments.any((inv) => inv.clientName == client.name)) {
              numericIdToUuid[numericId] = client.id;
              print('🔗 [ProductInvestors] Mapowanie przez nazwę: $numericId (${client.name}) -> ${client.id}');
              break;
            }
          }
        }
      }

      print(
        '🔗 [ProductInvestors] Utworzono mapowanie numericId -> UUID: $numericIdToUuid',
      );

      // Utwórz podsumowania inwestorów używając mapowania
      final List<InvestorSummary> investors = [];
      for (final client in clients) {
        // Znajdź inwestycje dla tego klienta przez mapowanie
        List<Investment> clientInvestments = [];
        for (final entry in numericIdToUuid.entries) {
          if (entry.value == client.id) {
            clientInvestments.addAll(investmentsByClientId[entry.key] ?? []);
          }
        }

        if (clientInvestments.isNotEmpty) {
          final investorSummary = InvestorSummary.fromInvestments(
            client,
            clientInvestments,
          );
          investors.add(investorSummary);
        }
      }

      // Sortuj według wartości inwestycji (malejąco)
      investors.sort((a, b) => b.totalValue.compareTo(a.totalValue));

      print(
        '✅ [ProductInvestors] Utworzono ${investors.length} podsumowań inwestorów',
      );
      return investors;
    } catch (e) {
      logError('getInvestorsByProductType', e);
      print('❌ [ProductInvestors] Błąd: $e');
      return [];
    }
  }
  }

  /// Pobiera inwestorów dla produktu UnifiedProduct
  Future<List<InvestorSummary>> getInvestorsForProduct(
    UnifiedProduct product,
  ) async {
    // Sprawdź czy produkt ma konkretną nazwę do wyszukiwania
    if (product.name.isNotEmpty && product.name != 'Nieznany produkt') {
      return await getInvestorsByProductName(product.name);
    } else {
      // Użyj typu produktu jako fallback
      return await getInvestorsByProductType(product.productType);
    }
  }

  /// Pobiera dane klientów na podstawie listy ID
  Future<List<Client>> _getClientsByIds(List<String> clientIds) async {
    try {
      print('🔍 [ProductInvestors] Szukam klientów o ID: $clientIds');
      final List<Client> clients = [];

      // Pierwszy krok: próbuj znaleźć po UUID (document ID)
      const batchSize = 10;
      for (int i = 0; i < clientIds.length; i += batchSize) {
        final batch = clientIds.skip(i).take(batchSize).toList();
        print('📦 [ProductInvestors] Przetwarzam batch UUID: $batch');

        final snapshot = await firestore
            .collection('clients')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        print(
          '📋 [ProductInvestors] Znaleziono ${snapshot.docs.length} dokumentów klientów w batch UUID',
        );

        final batchClients = snapshot.docs.map((doc) {
          print('👤 [ProductInvestors] Przetwarzam klienta UUID: ${doc.id}');
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
          '🔄 [ProductInvestors] Próbuję znaleźć brakujących klientów przez excelId: $missingClientIds',
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
              '✅ [ProductInvestors] Znaleziono klienta przez excelId: $missingId -> ${client.id}',
            );
          } else {
            print(
              '❌ [ProductInvestors] Nie znaleziono klienta o ID: $missingId',
            );
          }
        }
      }

      print(
        '🎯 [ProductInvestors] Łącznie załadowano ${clients.length} klientów',
      );
      return clients;
    } catch (e) {
      logError('_getClientsByIds', e);
      print('❌ [ProductInvestors] Błąd pobierania klientów: $e');
      return [];
    }
  }

  /// Pobiera statystyki inwestorów dla produktu
  Future<Map<String, dynamic>> getProductInvestorsStats(
    UnifiedProduct product,
  ) async {
    try {
      final investors = await getInvestorsForProduct(product);

      if (investors.isEmpty) {
        return {
          'totalInvestors': 0,
          'totalValue': 0.0,
          'averageInvestment': 0.0,
          'activeInvestors': 0,
        };
      }

      final totalValue = investors.fold<double>(
        0.0,
        (sum, investor) => sum + investor.totalValue,
      );

      final activeInvestors = investors
          .where((investor) => investor.client.isActive)
          .length;

      return {
        'totalInvestors': investors.length,
        'totalValue': totalValue,
        'averageInvestment': totalValue / investors.length,
        'activeInvestors': activeInvestors,
      };
    } catch (e) {
      logError('getProductInvestorsStats', e);
      return {
        'totalInvestors': 0,
        'totalValue': 0.0,
        'averageInvestment': 0.0,
        'activeInvestors': 0,
      };
    }
  }
}
