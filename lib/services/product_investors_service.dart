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
