import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models_and_services.dart';

class FirestoreDataInspector {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔍 Sprawdź rzeczywiste dane w kolekcjach i porównaj z modelami
  static Future<Map<String, dynamic>> inspectRealData() async {
    print('\n🔍 === FIRESTORE DATA INSPECTOR ===\n');

    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'collections': {},
      'fieldMappings': {},
      'modelCompatibility': {},
      'recommendations': [],
    };

    try {
      // 📊 Sprawdź kolekcję investments
      print('📊 Analizuję kolekcję investments...');
      final investmentsSnapshot = await _firestore
          .collection('investments')
          .limit(3)
          .get();

      results['collections']['investments'] = {
        'totalCount': investmentsSnapshot.size,
        'sampleDocuments': [],
        'uniqueFields': <String>{},
        'fieldTypes': <String, String>{},
      };

      // Analizuj próbkę dokumentów
      for (final doc in investmentsSnapshot.docs) {
        final data = doc.data();
        final sampleDoc = {
          'id': doc.id,
          'fieldCount': data.keys.length,
          'fields': data.keys.toList(),
          'sampleValues': <String, dynamic>{},
        };

        // Zbierz próbkowe wartości dla kluczowych pól
        final keyFields = [
          'clientName',
          'klient',
          'Klient',
          'investmentAmount',
          'kwota_inwestycji',
          'Kwota_inwestycji',
          'remainingCapital',
          'kapital_pozostaly',
          'Kapital Pozostaly',
          'productType',
          'typ_produktu',
          'Typ_produktu',
        ];

        for (final field in keyFields) {
          if (data.containsKey(field)) {
            (sampleDoc['sampleValues'] as Map<String, dynamic>)[field] =
                data[field];
            (results['collections']['investments']['fieldTypes']
                as Map<String, String>)[field] = data[field].runtimeType
                .toString();
          }
        }

        // Zbierz wszystkie unikalne pola
        results['collections']['investments']['uniqueFields'].addAll(data.keys);

        results['collections']['investments']['sampleDocuments'].add(sampleDoc);
      }

      // Konwertuj Set na List dla JSON serialization
      results['collections']['investments']['uniqueFields'] =
          results['collections']['investments']['uniqueFields'].toList();

      print('📊 Znaleziono ${investmentsSnapshot.size} dokumentów investments');
      print(
        '📊 Unikalne pola: ${results['collections']['investments']['uniqueFields'].length}',
      );

      // 👥 Sprawdź kolekcję clients
      print('👥 Analizuję kolekcję clients...');
      final clientsSnapshot = await _firestore
          .collection('clients')
          .limit(3)
          .get();

      results['collections']['clients'] = {
        'totalCount': clientsSnapshot.size,
        'sampleDocuments': [],
        'uniqueFields': <String>{},
        'fieldTypes': <String, String>{},
      };

      for (final doc in clientsSnapshot.docs) {
        final data = doc.data();
        final sampleDoc = {
          'id': doc.id,
          'fieldCount': data.keys.length,
          'fields': data.keys.toList(),
          'sampleValues': <String, dynamic>{},
        };

        final keyFields = [
          'fullName',
          'imie_nazwisko',
          'name',
          'email',
          'phone',
          'telefon',
          'companyName',
          'nazwa_firmy',
          'votingStatus',
        ];

        for (final field in keyFields) {
          if (data.containsKey(field)) {
            (sampleDoc['sampleValues'] as Map<String, dynamic>)[field] =
                data[field];
            (results['collections']['clients']['fieldTypes']
                as Map<String, String>)[field] = data[field].runtimeType
                .toString();
          }
        }

        results['collections']['clients']['uniqueFields'].addAll(data.keys);
        results['collections']['clients']['sampleDocuments'].add(sampleDoc);
      }

      results['collections']['clients']['uniqueFields'] =
          results['collections']['clients']['uniqueFields'].toList();

      print('👥 Znaleziono ${clientsSnapshot.size} dokumentów clients');

      // 🧪 Test konwersji modeli
      print('🧪 Testuję konwersję modeli...');

      if (investmentsSnapshot.docs.isNotEmpty) {
        try {
          final investmentDoc = investmentsSnapshot.docs.first;
          final investment = Investment.fromFirestore(investmentDoc);

          results['modelCompatibility']['Investment'] = {
            'success': true,
            'convertedId': investment.id,
            'clientName': investment.clientName,
            'investmentAmount': investment.investmentAmount,
            'remainingCapital': investment.remainingCapital,
            'productType': investment.productType.name,
            'message': 'Investment model konwersja udana',
          };
        } catch (e) {
          results['modelCompatibility']['Investment'] = {
            'success': false,
            'error': e.toString(),
            'message': 'Błąd konwersji Investment model',
          };
        }
      }

      if (clientsSnapshot.docs.isNotEmpty) {
        try {
          final clientDoc = clientsSnapshot.docs.first;
          final client = Client.fromFirestore(clientDoc);

          results['modelCompatibility']['Client'] = {
            'success': true,
            'convertedId': client.id,
            'name': client.name,
            'email': client.email,
            'phone': client.phone,
            'votingStatus': client.votingStatus.name,
            'message': 'Client model konwersja udana',
          };
        } catch (e) {
          results['modelCompatibility']['Client'] = {
            'success': false,
            'error': e.toString(),
            'message': 'Błąd konwersji Client model',
          };
        }
      }

      // 💡 Generuj rekomendacje
      _generateRecommendations(results);

      print('✅ Analiza zakończona pomyślnie');
    } catch (e) {
      print('❌ Błąd podczas analizy: $e');
      results['error'] = e.toString();
    }

    return results;
  }

  static void _generateRecommendations(Map<String, dynamic> results) {
    final recommendations = <String>[];

    // Sprawdź mappingi pól investments
    final investmentFields =
        results['collections']['investments']['uniqueFields'] as List;

    if (investmentFields.contains('clientName') &&
        investmentFields.contains('klient')) {
      recommendations.add(
        '🔄 Investments: Zarówno "clientName" jak i "klient" są obecne - sprawdź mapowanie',
      );
    }

    if (investmentFields.contains('investmentAmount') &&
        investmentFields.contains('kwota_inwestycji')) {
      recommendations.add(
        '💰 Investments: Duplikaty pól kwoty inwestycji - możliwa normalizacja',
      );
    }

    if (investmentFields.contains('remainingCapital') &&
        investmentFields.contains('kapital_pozostaly')) {
      recommendations.add(
        '💰 Investments: Duplikaty pól kapitału pozostałego - sprawdź mapowanie',
      );
    }

    // Sprawdź mappingi pól clients
    final clientFields =
        results['collections']['clients']['uniqueFields'] as List;

    if (clientFields.contains('fullName') &&
        clientFields.contains('imie_nazwisko')) {
      recommendations.add(
        '👤 Clients: Zarówno "fullName" jak i "imie_nazwisko" są obecne - sprawdź mapowanie',
      );
    }

    // Sprawdź kompatybilność modeli
    final investmentCompat = results['modelCompatibility']['Investment'];
    if (investmentCompat != null && !investmentCompat['success']) {
      recommendations.add('🚨 Investment model: ${investmentCompat['error']}');
    }

    final clientCompat = results['modelCompatibility']['Client'];
    if (clientCompat != null && !clientCompat['success']) {
      recommendations.add('🚨 Client model: ${clientCompat['error']}');
    }

    // Sprawdź liczby dokumentów
    final investmentCount = results['collections']['investments']['totalCount'];
    final clientCount = results['collections']['clients']['totalCount'];

    if (investmentCount == 0 && clientCount > 0) {
      recommendations.add(
        '⚠️ 0 investments vs $clientCount clients - prawdopodobnie błąd w query lub indeksach',
      );
    }

    results['recommendations'] = recommendations;
  }

  /// 🔍 Sprawdź konkretny dokument investment
  static Future<Map<String, dynamic>> inspectInvestmentDocument(
    String docId,
  ) async {
    try {
      final doc = await _firestore.collection('investments').doc(docId).get();

      if (!doc.exists) {
        return {'error': 'Dokument $docId nie istnieje'};
      }

      final data = doc.data()!;

      return {
        'id': doc.id,
        'exists': doc.exists,
        'fieldCount': data.keys.length,
        'allFields': data.keys.toList(),
        'fieldValues': data,
        'fieldTypes': data.map(
          (key, value) => MapEntry(key, value.runtimeType.toString()),
        ),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 🔍 Sprawdź konkretny dokument client
  static Future<Map<String, dynamic>> inspectClientDocument(
    String docId,
  ) async {
    try {
      final doc = await _firestore.collection('clients').doc(docId).get();

      if (!doc.exists) {
        return {'error': 'Dokument $docId nie istnieje'};
      }

      final data = doc.data()!;

      return {
        'id': doc.id,
        'exists': doc.exists,
        'fieldCount': data.keys.length,
        'allFields': data.keys.toList(),
        'fieldValues': data,
        'fieldTypes': data.map(
          (key, value) => MapEntry(key, value.runtimeType.toString()),
        ),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 📊 Statystyki wszystkich kolekcji
  static Future<Map<String, dynamic>> getCollectionStats() async {
    final stats = <String, dynamic>{};

    final collections = ['investments', 'clients', 'products', 'employees'];

    for (final collection in collections) {
      try {
        final snapshot = await _firestore.collection(collection).count().get();
        stats[collection] = {'count': snapshot.count, 'exists': true};
      } catch (e) {
        stats[collection] = {
          'count': 0,
          'exists': false,
          'error': e.toString(),
        };
      }
    }

    return stats;
  }
}
