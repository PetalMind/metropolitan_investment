import 'dart:io';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RealFirebaseUploader {
  static FirebaseFirestore? _firestore;

  static Future<void> initializeFirebase() async {
    try {
      // Inicjalizacja Firebase z prawdziwymi danymi
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBVvB9XDCwQ_YourRealAPIKey',
          authDomain: 'cosmopolitan-investment.firebaseapp.com',
          projectId: 'cosmopolitan-investment',
          storageBucket: 'cosmopolitan-investment.appspot.com',
          messagingSenderId: '123456789',
          appId: '1:123456789:web:abcdef123456789',
        ),
      );

      _firestore = FirebaseFirestore.instance;
    } catch (e) {
      // Fallback - używaj emulatora lokalnego
      _firestore = FirebaseFirestore.instance;
      _firestore!.useFirestoreEmulator('localhost', 8080);
    }
  }

  static Future<void> uploadAllDataToFirestore() async {

    await initializeFirebase();

    // Upload każdej kolekcji
    await _uploadJsonToFirestore('clients_data.json', 'clients');
    await _uploadJsonToFirestore('investments_data.json', 'investments');
    await _uploadJsonToFirestore('shares_data.json', 'shares');
    await _uploadJsonToFirestore('bonds_data.json', 'bonds');
    await _uploadJsonToFirestore('loans_data.json', 'loans');

    await _verifyDataInFirestore();

  }

  static Future<void> _uploadJsonToFirestore(
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

      // Usuń wszystkie stare dane
      await _clearCollection(collectionName);

      // Wgraj w batches po 500
      const batchSize = 500;
      int totalUploaded = 0;

      for (int i = 0; i < data.length; i += batchSize) {
        final batch = _firestore!.batch();
        final end = (i + batchSize < data.length) ? i + batchSize : data.length;

        for (int j = i; j < end; j++) {
          final item = Map<String, dynamic>.from(data[j]);

          // Usuń stare ID i dodaj metadane
          item.remove('id');
          item['uploaded_at'] = FieldValue.serverTimestamp();
          item['source_file'] = fileName;
          item['batch_number'] = (i ~/ batchSize) + 1;

          final docRef = collection.doc();
          batch.set(docRef, item);
        }

        await batch.commit();
        totalUploaded += (end - i);

        // Krótka pauza między batches
        await Future.delayed(Duration(milliseconds: 100));
      }

    } catch (e) {
      rethrow;
    }
  }

  static Future<void> _clearCollection(String collectionName) async {

    try {
      final collection = _firestore!.collection(collectionName);
      final snapshot = await collection.get();

      if (snapshot.docs.isNotEmpty) {
        final batch = _firestore!.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
    }
  }

  static Future<void> _verifyDataInFirestore() async {

    final collections = ['clients', 'investments', 'shares', 'bonds', 'loans'];
    final results = <String, int>{};

    for (String collectionName in collections) {
      try {
        final snapshot = await _firestore!
            .collection(collectionName)
            .count()
            .get();
        final count = snapshot.count ?? 0;
        results[collectionName] = count;

        if (count > 0) {

          // Pokaż przykład pierwszego dokumentu
          final firstDoc = await _firestore!
              .collection(collectionName)
              .limit(1)
              .get();
          if (firstDoc.docs.isNotEmpty) {
            final data = firstDoc.docs.first.data();
            print('   📋 Przykład: ${data.keys.take(3).join(', ')}...');
          }
        } else {
        }
      } catch (e) {
        results[collectionName] = 0;
      }
    }

    final totalDocs = results.values.fold(0, (sum, count) => sum + count);

    results.forEach((collection, count) {
    });

    if (totalDocs == 0) {
      throw Exception('Brak danych w Firebase');
    } else {
    }
  }

  static Future<void> createIndexes() async {

    try {
      // Przykładowe zapytania które utworzą indeksy
      await _firestore!
          .collection('clients')
          .where('email', isNotEqualTo: '')
          .limit(1)
          .get();

      await _firestore!
          .collection('investments')
          .where('typ_produktu', isEqualTo: 'Obligacje')
          .orderBy('kwota_inwestycji', descending: true)
          .limit(1)
          .get();

    } catch (e) {
      print('⚠️ Błąd indeksów (to normalne przy pierwszym uruchomieniu): $e');
    }
  }
}

void main() async {
  try {

    await RealFirebaseUploader.uploadAllDataToFirestore();
    await RealFirebaseUploader.createIndexes();

  } catch (e) {
    exit(1);
  }
}
