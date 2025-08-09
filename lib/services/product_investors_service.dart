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
        String clientId = investment.clientId;
        if (clientId.isEmpty) {
          // Spróbuj starszego pola
          final legacyClientId = doc.data()['klient_id'] as String?;
          clientId = legacyClientId ?? '';
        }

        if (clientId.isNotEmpty) {
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

      // Pobierz wszystkie inwestycje dla danego typu produktu - sprawdzaj nowe i stare pola
      final snapshot = await firestore
          .collection(_investmentsCollection)
          .where('Typ_produktu', isEqualTo: typeStr) // Nowe pole
          .get();

      // Jeśli nie znaleziono przez nowe pole, spróbuj starego
      if (snapshot.docs.isEmpty) {
        print(
          '⚠️ [ProductInvestors] Brak wyników dla Typ_produktu, próbuję typ_produktu...',
        );
        final fallbackSnapshot = await firestore
            .collection(_investmentsCollection)
            .where('typ_produktu', isEqualTo: typeStr) // Stare pole
            .get();

        if (fallbackSnapshot.docs.isEmpty) {
          print('⚠️ [ProductInvestors] Brak inwestycji dla typu: $typeStr');
          return [];
        }
        return _processInvestmentSnapshot(fallbackSnapshot, 'Type: $typeStr');
      }

      return _processInvestmentSnapshot(snapshot, 'Type: $typeStr');
    } catch (e) {
      logError('getInvestorsByProductType', e);
      print('❌ [ProductInvestors] Błąd: $e');
      return [];
    }
  }

  /// Pobiera inwestorów dla produktu UnifiedProduct z zaawansowanymi strategiami wyszukiwania
  Future<List<InvestorSummary>> getInvestorsForProduct(
    UnifiedProduct product,
  ) async {
    print(
      '🔍 [ProductInvestors] Zaawansowane wyszukiwanie dla produktu: "${product.name}"',
    );

    // Strategia 1: Wyszukaj po dokładnej nazwie produktu
    if (product.name.isNotEmpty && product.name != 'Nieznany produkt') {
      final investorsByName = await getInvestorsByProductName(product.name);
      if (investorsByName.isNotEmpty) {
        print(
          '✅ [ProductInvestors] Znaleziono ${investorsByName.length} inwestorów po nazwie',
        );
        return investorsByName;
      }
    }

    // Strategia 2: Wyszukaj po typie produktu
    print(
      '📋 [ProductInvestors] Próbuję wyszukiwanie po typie: ${product.productType.displayName}',
    );
    final investorsByType = await getInvestorsByProductType(
      product.productType,
    );
    if (investorsByType.isNotEmpty) {
      print(
        '✅ [ProductInvestors] Znaleziono ${investorsByType.length} inwestorów po typie produktu',
      );
      return investorsByType;
    }

    // Strategia 3: Wyszukiwanie częściowe dla apartamentów
    if (product.productType == UnifiedProductType.apartments &&
        product.name.isNotEmpty) {
      print(
        '🏢 [ProductInvestors] Próbuję częściowe wyszukiwanie apartamentów...',
      );
      return await _searchApartmentsByPartialName(product.name);
    }

    // Strategia 4: Wyszukiwanie wszystkich produktów danego typu i próba dopasowania
    if (product.name.isNotEmpty) {
      print(
        '🔍 [ProductInvestors] Próbuję wyszukiwanie podobne do nazwy: "${product.name}"',
      );
      return await _searchBySimilarName(product.name, product.productType);
    }

    print('❌ [ProductInvestors] Nie znaleziono inwestorów żadną strategią');
    return [];
  }

  /// Wyszukuje apartamenty po częściowej nazwie
  Future<List<InvestorSummary>> _searchApartmentsByPartialName(
    String productName,
  ) async {
    try {
      // Wydziel główną część nazwy (przed myślnikiem)
      final mainName = productName.split(' - ').first.trim();
      print(
        '🏢 [ProductInvestors] Szukam apartamentów podobnych do: "$mainName"',
      );

      // Pobierz wszystkie inwestycje typu Apartamenty
      final snapshot = await firestore
          .collection(_investmentsCollection)
          .where('typ_produktu', isEqualTo: 'Apartamenty')
          .get();

      print(
        '📊 [ProductInvestors] Znaleziono ${snapshot.docs.length} inwestycji typu Apartamenty',
      );

      if (snapshot.docs.isEmpty) return [];

      // Znajdź pasujące nazwy produktów
      final Set<String> matchingProductNames = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final dbProductName = data['produkt_nazwa'] as String? ?? '';

        if (dbProductName.isNotEmpty) {
          // Sprawdź czy zawiera główną część nazwy
          if (dbProductName.toLowerCase().contains(mainName.toLowerCase()) ||
              mainName.toLowerCase().contains(dbProductName.toLowerCase())) {
            matchingProductNames.add(dbProductName);
            print('✅ [ProductInvestors] Dopasowana nazwa: "$dbProductName"');
          }
        }
      }

      // Pobierz inwestorów dla wszystkich dopasowanych nazw
      final List<InvestorSummary> allInvestors = [];
      for (final matchedName in matchingProductNames) {
        final investors = await getInvestorsByProductName(matchedName);
        allInvestors.addAll(investors);
      }

      // Usuń duplikaty na podstawie ID klienta
      final Map<String, InvestorSummary> uniqueInvestors = {};
      for (final investor in allInvestors) {
        uniqueInvestors[investor.client.id] = investor;
      }

      final result = uniqueInvestors.values.toList();
      print(
        '🎯 [ProductInvestors] Znaleziono ${result.length} unikalnych inwestorów po częściowej nazwie',
      );
      return result;
    } catch (e) {
      logError('_searchApartmentsByPartialName', e);
      return [];
    }
  }

  /// Wyszukuje po podobnej nazwie w ramach typu produktu
  Future<List<InvestorSummary>> _searchBySimilarName(
    String searchName,
    UnifiedProductType productType,
  ) async {
    try {
      // Mapowanie typu na nazwę w bazie
      String typeInDb;
      switch (productType) {
        case UnifiedProductType.bonds:
          typeInDb = 'Obligacje';
          break;
        case UnifiedProductType.shares:
          typeInDb = 'Udziały';
          break;
        case UnifiedProductType.loans:
          typeInDb = 'Pożyczki';
          break;
        case UnifiedProductType.apartments:
          typeInDb = 'Apartamenty';
          break;
        case UnifiedProductType.other:
          typeInDb = 'Inne';
          break;
      }

      print('🔍 [ProductInvestors] Szukam podobnych nazw w typie: $typeInDb');

      // Pobierz wszystkie inwestycje danego typu
      final snapshot = await firestore
          .collection(_investmentsCollection)
          .where('typ_produktu', isEqualTo: typeInDb)
          .get();

      if (snapshot.docs.isEmpty) return [];

      // Znajdź najbardziej podobną nazwę
      String? bestMatch;
      int bestScore = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final dbProductName = data['produkt_nazwa'] as String? ?? '';

        if (dbProductName.isNotEmpty) {
          final score = _calculateSimilarity(searchName, dbProductName);
          if (score > bestScore && score > 50) {
            // Minimum 50% podobieństwa
            bestScore = score;
            bestMatch = dbProductName;
          }
        }
      }

      if (bestMatch != null) {
        print(
          '✅ [ProductInvestors] Najlepsze dopasowanie: "$bestMatch" (${bestScore}% podobieństwa)',
        );
        return await getInvestorsByProductName(bestMatch);
      }

      return [];
    } catch (e) {
      logError('_searchBySimilarName', e);
      return [];
    }
  }

  /// Oblicza procentowe podobieństwo między dwoma stringami
  int _calculateSimilarity(String str1, String str2) {
    final s1 = str1.toLowerCase();
    final s2 = str2.toLowerCase();

    // Proste sprawdzenie zawierania
    if (s1 == s2) return 100;
    if (s1.contains(s2) || s2.contains(s1)) return 80;

    // Sprawdź wspólne słowa
    final words1 = s1.split(' ');
    final words2 = s2.split(' ');

    int commonWords = 0;
    for (final word in words1) {
      if (words2.any((w) => w.contains(word) || word.contains(w))) {
        commonWords++;
      }
    }

    if (words1.isNotEmpty) {
      return (commonWords * 100 / words1.length).round();
    }

    return 0;
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
