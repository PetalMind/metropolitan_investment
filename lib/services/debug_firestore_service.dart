import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/investment.dart';
import '../models/client.dart';

/// Debug service do testowania połączenia z Firestore
class DebugFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test podstawowego połączenia z Firestore
  static Future<void> testFirestoreConnection() async {
    print('🔍 [DEBUG] === TEST POŁĄCZENIA Z FIRESTORE ===');

    try {
      // Test 1: Sprawdź dostępne kolekcje
      print('🔍 [DEBUG] Test 1: Sprawdzanie kolekcji investments...');
      final investmentsSnapshot = await _firestore
          .collection('investments')
          .limit(3)
          .get();

      print(
        '🔍 [DEBUG] - Znaleziono ${investmentsSnapshot.docs.length} dokumentów investments',
      );

      if (investmentsSnapshot.docs.isNotEmpty) {
        for (int i = 0; i < investmentsSnapshot.docs.length; i++) {
          final doc = investmentsSnapshot.docs[i];
          final data = doc.data();
          print('🔍 [DEBUG] - Dokument ${i + 1} (${doc.id}):');
          print('🔍 [DEBUG]   - clientName: ${data['clientName']}');
          print('🔍 [DEBUG]   - productType: ${data['productType']}');
          print('🔍 [DEBUG]   - investmentAmount: ${data['investmentAmount']}');
          print('🔍 [DEBUG]   - remainingCapital: ${data['remainingCapital']}');
          print(
            '🔍 [DEBUG]   - signingDate: ${data['signingDate']} (type: ${data['signingDate'].runtimeType})',
          );

          // Test konwersji do modelu
          try {
            final investment = Investment.fromFirestore(doc);
            print('🔍 [DEBUG]   - Model konwersja: ✅ SUCCESS');
            print('🔍 [DEBUG]   - Model clientName: ${investment.clientName}');
            print('🔍 [DEBUG]   - Model totalValue: ${investment.totalValue}');
            print(
              '🔍 [DEBUG]   - Model productType: ${investment.productType}',
            );
          } catch (e) {
            print('🔍 [DEBUG]   - Model konwersja: ❌ ERROR - $e');
          }
        }
      } else {
        print('🔍 [DEBUG] - ⚠️ Brak dokumentów w kolekcji investments');
      }

      // Test 2: Sprawdź kolekcję clients
      print('🔍 [DEBUG] Test 2: Sprawdzanie kolekcji clients...');
      final clientsSnapshot = await _firestore
          .collection('clients')
          .limit(3)
          .get();

      print(
        '🔍 [DEBUG] - Znaleziono ${clientsSnapshot.docs.length} dokumentów clients',
      );

      if (clientsSnapshot.docs.isNotEmpty) {
        for (int i = 0; i < clientsSnapshot.docs.length; i++) {
          final doc = clientsSnapshot.docs[i];
          final data = doc.data();
          print('🔍 [DEBUG] - Dokument ${i + 1} (${doc.id}):');
          print('🔍 [DEBUG]   - fullName: ${data['fullName']}');
          print('🔍 [DEBUG]   - companyName: ${data['companyName']}');
          print('🔍 [DEBUG]   - email: ${data['email']}');

          // Test konwersji do modelu
          try {
            final client = Client.fromFirestore(doc);
            print('🔍 [DEBUG]   - Model konwersja: ✅ SUCCESS');
            print('🔍 [DEBUG]   - Model name: ${client.name}');
          } catch (e) {
            print('🔍 [DEBUG]   - Model konwersja: ❌ ERROR - $e');
          }
        }
      } else {
        print('🔍 [DEBUG] - ⚠️ Brak dokumentów w kolekcji clients');
      }

      // Test 3: Sprawdź inne kolekcje
      print('🔍 [DEBUG] Test 3: Sprawdzanie innych kolekcji...');
      final collections = [
        'products',
        'bonds',
        'shares',
        'loans',
        'apartments',
      ];

      for (final collectionName in collections) {
        try {
          final snapshot = await _firestore
              .collection(collectionName)
              .limit(1)
              .get();
          print(
            '🔍 [DEBUG] - Kolekcja $collectionName: ${snapshot.docs.length} dokumentów',
          );
        } catch (e) {
          print('🔍 [DEBUG] - Kolekcja $collectionName: ERROR - $e');
        }
      }

      print('🔍 [DEBUG] === KONIEC TESTU FIRESTORE ===');
    } catch (e) {
      print('❌ [ERROR] Test Firestore connection failed: $e');
      rethrow;
    }
  }

  /// Test specyficznych zapytań
  static Future<void> testSpecificQueries() async {
    print('🔍 [DEBUG] === TEST SPECYFICZNYCH ZAPYTAŃ ===');

    try {
      // Test: Zapytanie z filtrem daty
      final now = DateTime.now();
      final yearAgo = now.subtract(const Duration(days: 365));
      final timestampFilter = Timestamp.fromDate(yearAgo);

      print('🔍 [DEBUG] Test filtra daty od: $yearAgo');
      final filteredSnapshot = await _firestore
          .collection('investments')
          .where('signingDate', isGreaterThan: timestampFilter)
          .limit(5)
          .get();

      print(
        '🔍 [DEBUG] - Znaleziono ${filteredSnapshot.docs.length} dokumentów z filtrem daty',
      );

      // Test: Zapytanie po productType
      final apartmentQuery = await _firestore
          .collection('investments')
          .where('productType', isEqualTo: 'apartment')
          .limit(5)
          .get();

      print(
        '🔍 [DEBUG] - Znaleziono ${apartmentQuery.docs.length} apartamentów',
      );
    } catch (e) {
      print('❌ [ERROR] Test specific queries failed: $e');
      rethrow;
    }
  }
}
