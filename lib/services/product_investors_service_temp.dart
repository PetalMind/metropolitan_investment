import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/investment.dart';
import '../models/client.dart';
import '../models/investor_summary.dart';
import '../models/unified_product.dart';
import 'base_service.dart';

/// Usługa do pobierania inwestorów dla konkretnych produktów
class ProductInvestorsService extends BaseService {
  final String _investmentsCollection = 'investments';
  final String _clientsCollection = 'clients';

  /// Pobiera inwestorów dla danego produktu na podstawie nazwy produktu
  Future<List<InvestorSummary>> getInvestorsByProductName(
    String productName,
  ) async {
    try {
      print(
        '📊 [ProductInvestors] Pobieranie inwestorów dla produktu: $productName',
      );

      // Pobierz wszystkie inwestycje dla danego produktu - sprawdzaj nowe i stare pola nazw
      QuerySnapshot<Map<String, dynamic>> snapshot;

      try {
        snapshot = await firestore
            .collection(_investmentsCollection)
            .where('Produkt_nazwa', isEqualTo: productName) // Nowe pole
            .get();
      } catch (e) {
        // Jeśli błąd z indeksem dla Produkt_nazwa, spróbuj starego pola
        print(
          '⚠️ [ProductInvestors] Błąd z Produkt_nazwa, próbuję produkt_nazwa: $e',
        );
        snapshot = await firestore
            .collection(_investmentsCollection)
            .where('produkt_nazwa', isEqualTo: productName) // Stare pole
            .get();
      }

      // Jeśli nie znaleziono przez nowe pole, spróbuj starego
      if (snapshot.docs.isEmpty) {
        print(
          '⚠️ [ProductInvestors] Brak wyników dla Produkt_nazwa, próbuję produkt_nazwa...',
        );
        final fallbackSnapshot = await firestore
            .collection(_investmentsCollection)
            .where('produkt_nazwa', isEqualTo: productName) // Stare pole
            .get();

        if (fallbackSnapshot.docs.isEmpty) {
          print(
            '⚠️ [ProductInvestors] Brak inwestycji dla produktu: $productName',
          );
          return [];
        }
        snapshot = fallbackSnapshot;
      }

      return await _processInvestmentSnapshot(snapshot, productName);
    } catch (e) {
      logError('getInvestorsByProductName', e);
      print('❌ [ProductInvestors] Błąd: $e');
      return [];
    }
  }

  /// Przetwarza snapshot inwestycji i tworzy podsumowania inwestorów
  Future<List<InvestorSummary>> _processInvestmentSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String productName,
  ) async {
    try {
      print(
        '📋 [ProductInvestors] Przetwarzanie ${snapshot.docs.length} inwestycji dla produktu: $productName',
      );

      // Grupuj inwestycje według ID klienta
      final Map<String, List<Investment>> investmentsByClientId = {};

      for (final doc in snapshot.docs) {
        final investment = Investment.fromFirestore(doc);

        // Sprawdź czy inwestycja ma ID klienta (nowe i stare pola)
        String? clientId = investment.clientId;
        if (clientId.isEmpty) {
          // Spróbuj starszego pola
          clientId = doc.data()['klient_id'] as String?;
        }

        if (clientId != null && clientId.isNotEmpty) {
          investmentsByClientId.putIfAbsent(clientId, () => []);
          investmentsByClientId[clientId]!.add(investment);
        } else {
          print('⚠️ [ProductInvestors] Inwestycja bez ID klienta: ${doc.id}');
        }
      }

      // Pobierz dane klientów
      final List<InvestorSummary> investors = [];

      for (final entry in investmentsByClientId.entries) {
        final clientId = entry.key;
        final investments = entry.value;

        try {
          final clientDoc = await firestore
              .collection(_clientsCollection)
              .doc(clientId)
              .get();

          if (clientDoc.exists) {
            final client = Client.fromFirestore(clientDoc);

            // Ręcznie stwórz InvestorSummary
            double totalValue = 0.0;

            for (final investment in investments) {
              totalValue += investment.remainingCapital;
            }

            final investor = InvestorSummary(
              client: client,
              investments: investments,
              totalRemainingCapital: totalValue,
              totalSharesValue: 0.0,
              totalValue: totalValue,
              totalInvestmentAmount: investments.fold<double>(
                0.0,
                (sum, inv) => sum + inv.investmentAmount,
              ),
              totalRealizedCapital: investments.fold<double>(
                0.0,
                (sum, inv) => sum + inv.realizedCapital,
              ),
              capitalSecuredByRealEstate: 0.0,
              capitalForRestructuring: 0.0,
              investmentCount: investments.length,
            );

            investors.add(investor);
          } else {
            print(
              '⚠️ [ProductInvestors] Nie znaleziono klienta o ID: $clientId',
            );
          }
        } catch (e) {
          print(
            '❌ [ProductInvestors] Błąd podczas pobierania klienta $clientId: $e',
          );
        }
      }

      print(
        '✅ [ProductInvestors] Znaleziono ${investors.length} inwestorów dla produktu: $productName',
      );

      return investors;
    } catch (e) {
      logError('_processInvestmentSnapshot', e);
      print('❌ [ProductInvestors] Błąd podczas przetwarzania: $e');
      return [];
    }
  }

  /// Pobiera inwestorów dla zunifikowanego produktu
  Future<List<InvestorSummary>> getInvestorsForProduct(
    UnifiedProduct product,
  ) async {
    try {
      print(
        '🔍 [ProductInvestors] Szukanie inwestorów dla produktu: ${product.name} (typ: ${product.productType})',
      );

      // Najpierw spróbuj dokładnej nazwy
      final investorsByName = await getInvestorsByProductName(product.name);
      if (investorsByName.isNotEmpty) {
        return investorsByName;
      }

      print(
        '⚠️ [ProductInvestors] Brak inwestorów dla produktu: ${product.name}',
      );
      return [];
    } catch (e) {
      logError('getInvestorsForProduct', e);
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
        (sum, investor) => sum + investor.totalRemainingCapital,
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
