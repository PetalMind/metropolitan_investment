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

      // Grupuj inwestycje według numerycznych ID klientów
      final Map<String, List<Investment>> investmentsByNumericId = {};
      for (final investment in investments) {
        final numericId = investment.clientId; // To jest numeryczne ID z Excela
        print(
          '🔗 [ProductInvestors] Investment ${investment.id} -> Numeric Client ID: "$numericId"',
        );
        investmentsByNumericId.putIfAbsent(numericId, () => []).add(investment);
      }

      // Pobierz unikalne numeryczne ID klientów
      final numericClientIds = investmentsByNumericId.keys.toList();
      print(
        '👥 [ProductInvestors] Znaleziono ${numericClientIds.length} unikalnych numerycznych ID klientów',
      );

      // Pobierz wszystkich klientów z bazy - będziemy wyszukiwać po excelId
      final clients = await _getClientsByExcelIds(numericClientIds);
      print('� [ProductInvestors] Załadowano dane ${clients.length} klientów');

      // Utwórz podsumowania inwestorów
      final List<InvestorSummary> investors = [];
      for (final client in clients) {
        // Znajdź inwestycje dla tego klienta po excelId
        final clientInvestments = investmentsByNumericId[client.excelId] ?? [];

        if (clientInvestments.isNotEmpty) {
          final investorSummary = InvestorSummary.fromInvestments(
            client,
            clientInvestments,
          );
          investors.add(investorSummary);
          print(
            '✅ [ProductInvestors] Utworzono podsumowanie dla ${client.name}: ${clientInvestments.length} inwestycji',
          );
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

      // Grupuj inwestycje według numerycznych ID klientów
      final Map<String, List<Investment>> investmentsByNumericId = {};
      for (final investment in investments) {
        final numericId = investment.clientId; // To jest numeryczne ID z Excela
        investmentsByNumericId.putIfAbsent(numericId, () => []).add(investment);
      }

      // Pobierz unikalne numeryczne ID klientów
      final numericClientIds = investmentsByNumericId.keys.toList();
      print(
        '👥 [ProductInvestors] Znaleziono ${numericClientIds.length} unikalnych numerycznych ID klientów',
      );

      // Pobierz wszystkich klientów z bazy - będziemy wyszukiwać po excelId
      final clients = await _getClientsByExcelIds(numericClientIds);
      print('� [ProductInvestors] Załadowano dane ${clients.length} klientów');

      // Utwórz podsumowania inwestorów
      final List<InvestorSummary> investors = [];
      for (final client in clients) {
        // Znajdź inwestycje dla tego klienta po excelId
        final clientInvestments = investmentsByNumericId[client.excelId] ?? [];

        if (clientInvestments.isNotEmpty) {
          final investorSummary = InvestorSummary.fromInvestments(
            client,
            clientInvestments,
          );
          investors.add(investorSummary);
          print(
            '✅ [ProductInvestors] Utworzono podsumowanie dla ${client.name}: ${clientInvestments.length} inwestycji',
          );
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

  /// Pobiera dane klientów na podstawie listy numerycznych Excel ID
  Future<List<Client>> _getClientsByExcelIds(List<String> excelIds) async {
    try {
      print('🔍 [ProductInvestors] Szukam klientów po excelId: $excelIds');
      final List<Client> clients = [];

      // Pobierz klientów gdzie excelId pasuje do numerycznych ID z inwestycji
      for (final excelId in excelIds) {
        final snapshot = await firestore
            .collection('clients')
            .where('excelId', isEqualTo: excelId)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final client = Client.fromFirestore(snapshot.docs.first);
          clients.add(client);
          print(
            '✅ [ProductInvestors] Znaleziono klienta przez excelId: $excelId -> ${client.name} (${client.id})',
          );
        } else {
          print(
            '❌ [ProductInvestors] Nie znaleziono klienta o excelId: $excelId',
          );

          // Fallback: spróbuj znaleźć przez original_id dla kompatybilności
          final originalSnapshot = await firestore
              .collection('clients')
              .where('original_id', isEqualTo: excelId)
              .limit(1)
              .get();

          if (originalSnapshot.docs.isNotEmpty) {
            final client = Client.fromFirestore(originalSnapshot.docs.first);
            clients.add(client);
            print(
              '✅ [ProductInvestors] Znaleziono klienta przez original_id: $excelId -> ${client.name} (${client.id})',
            );
          } else {
            print(
              '⚠️ [ProductInvestors] Nie można dopasować klienta o ID: $excelId',
            );
          }
        }
      }

      print(
        '🎯 [ProductInvestors] Łącznie załadowano ${clients.length} klientów przez excelId',
      );
      return clients;
    } catch (e) {
      logError('_getClientsByExcelIds', e);
      print('❌ [ProductInvestors] Błąd pobierania klientów przez excelId: $e');
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
