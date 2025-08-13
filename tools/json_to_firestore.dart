import 'dart:io';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JsonToFirestore {
  static FirebaseFirestore? _firestore;
  static int _batchSize = 500;

  static Future<void> initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyDemoKeyForLocalDevelopment',
          appId: '1:123456789:web:abcdef123456',
          messagingSenderId: '123456789',
          projectId: 'cosmopolitan-investment',
          storageBucket: 'cosmopolitan-investment.appspot.com',
        ),
      );
      _firestore = FirebaseFirestore.instance;
    } catch (e) {
    }
  }

  static Future<void> uploadAllJsonsToFirestore() async {

    await initFirebase();

    // 1. Klienci
    await uploadJsonToCollection('clients_data.json', 'clients');

    // 2. Inwestycje
    await uploadJsonToCollection('investments_data.json', 'investments');

    // 3. Udziały
    await uploadJsonToCollection('shares_data.json', 'shares');

    // 4. Obligacje
    await uploadJsonToCollection('bonds_data.json', 'bonds');

    // 5. Pożyczki
    await uploadJsonToCollection('loans_data.json', 'loans');

  }

  static Future<void> uploadJsonToCollection(
    String fileName,
    String collectionName,
  ) async {

    try {
      final file = File(fileName);
      if (!file.existsSync()) {
        return;
      }

      final jsonString = await file.readAsString();
      final List<dynamic> data = json.decode(jsonString);

      final collection = _firestore!.collection(collectionName);
      final batch = _firestore!.batch();
      int batchCount = 0;
      int totalUploaded = 0;

      for (int i = 0; i < data.length; i++) {
        final item = data[i] as Map<String, dynamic>;

        // Usuń stare ID jeśli istnieje
        item.remove('id');

        // Dodaj metadane
        item['uploadedAt'] = FieldValue.serverTimestamp();
        item['sourceFile'] = fileName;

        final docRef = collection.doc();
        batch.set(docRef, item);
        batchCount++;

        if (batchCount >= _batchSize) {
          await batch.commit();
          totalUploaded += batchCount;
          batchCount = 0;
        }
      }

      // Wgraj pozostałe
      if (batchCount > 0) {
        await batch.commit();
        totalUploaded += batchCount;
      }

    } catch (e) {
    }
  }

  static Future<void> generateFirestoreStats() async {

    try {
      final stats = <String, int>{};

      final collections = [
        'clients',
        'investments',
        'shares',
        'bonds',
        'loans',
      ];

      for (String collectionName in collections) {
        final snapshot = await _firestore!
            .collection(collectionName)
            .count()
            .get();
        stats[collectionName] = snapshot.count ?? 0;
      }

      stats.forEach((collection, count) {
      });

      final total = stats.values.fold(0, (sum, count) => sum + count);
    } catch (e) {
    }
  }
}

void main() async {
  try {

    await JsonToFirestore.uploadAllJsonsToFirestore();
    await JsonToFirestore.generateFirestoreStats();

  } catch (e) {
    exit(1);
  }
}
