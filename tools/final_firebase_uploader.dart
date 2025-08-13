import 'dart:io';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import prawdziwego config
import '../lib/firebase_options.dart';

class FinalFirebaseUploader {
  static FirebaseFirestore? _firestore;

  static Future<void> initializeFirebase() async {
    try {

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _firestore = FirebaseFirestore.instance;

      // Test połączenia
      await _firestore!.collection('test').doc('connection').set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Firebase działa!',
      });

    } catch (e) {
      rethrow;
    }
  }

  static Future<void> uploadAllDataNow() async {

    await initializeFirebase();

    // Upload każdego pliku JSON
    await _realUpload('clients_data.json', 'clients');
    await _realUpload('investments_data.json', 'investments');
    await _realUpload('shares_data.json', 'shares');
    await _realUpload('bonds_data.json', 'bonds');
    await _realUpload('loans_data.json', 'loans');

    await _verifyAllData();

  }

  static Future<void> _realUpload(
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

      // Wgraj wszystkie dane w małych batches
      const batchSize = 100; // Mniejsze batche dla pewności
      int uploaded = 0;

      for (int i = 0; i < data.length; i += batchSize) {
        final batch = _firestore!.batch();
        final endIndex = (i + batchSize < data.length)
            ? i + batchSize
            : data.length;

        for (int j = i; j < endIndex; j++) {
          final item = Map<String, dynamic>.from(data[j]);

          // Usuń stare ID
          item.remove('id');

          // Dodaj metadane Firebase
          item['firebase_uploaded_at'] = FieldValue.serverTimestamp();
          item['source_file'] = fileName;
          item['upload_batch'] = (i ~/ batchSize) + 1;

          // Utwórz dokument z auto-generated ID
          final docRef = collection.doc();
          batch.set(docRef, item);
        }

        // Wyślij batch do Firebase
        await batch.commit();
        uploaded += (endIndex - i);

        final percent = ((uploaded / data.length) * 100).toStringAsFixed(1);
        print('  ⏳ ${uploaded}/${data.length} ($percent%) wgrane...');

        // Krótka pauza
        await Future.delayed(Duration(milliseconds: 200));
      }

    } catch (e) {
      rethrow;
    }
  }

  static Future<void> _verifyAllData() async {

    final collections = ['clients', 'investments', 'shares', 'bonds', 'loans'];
    int totalDocs = 0;

    for (String collectionName in collections) {
      try {
        final snapshot = await _firestore!
            .collection(collectionName)
            .count()
            .get();
        final count = snapshot.count ?? 0;
        totalDocs += count;

        if (count > 0) {

          // Pokaż przykład
          final sampleDoc = await _firestore!
              .collection(collectionName)
              .limit(1)
              .get();
          if (sampleDoc.docs.isNotEmpty) {
            final data = sampleDoc.docs.first.data();
            final keys = data.keys
                .where((k) => !k.startsWith('firebase_'))
                .take(3);
            print('   📋 Pola: ${keys.join(', ')}');
          }
        } else {
        }
      } catch (e) {
      }
    }

    if (totalDocs == 0) {
      throw Exception('KURWA ŻADNYCH DANYCH W FIREBASE!');
    }
  }

  static Future<void> createSampleQueries() async {

    try {
      // Test 1: Klienci z emailem
      final clientsWithEmail = await _firestore!
          .collection('clients')
          .where('email', isNotEqualTo: '')
          .limit(5)
          .get();

      // Test 2: Najwyższe inwestycje
      final topInvestments = await _firestore!
          .collection('investments')
          .orderBy('kwota_inwestycji', descending: true)
          .limit(3)
          .get();

      for (var doc in topInvestments.docs) {
        final data = doc.data();
      }

      // Test 3: Obligacje
      final bonds = await _firestore!
          .collection('investments')
          .where('typ_produktu', isEqualTo: 'Obligacje')
          .limit(1)
          .get();

    } catch (e) {
    }
  }
}

void main() async {
  try {

    await FinalFirebaseUploader.uploadAllDataNow();
    await FinalFirebaseUploader.createSampleQueries();

  } catch (e) {
    exit(1);
  }
}
