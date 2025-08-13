import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';

/// Proste testy odczytu danych z Firebase
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🔍 [TEST] Test bezpośredniego odczytu z Firestore...');

  try {
    // Pobierz pierwszych 3 dokumentów z kolekcji investments
    final snapshot = await FirebaseFirestore.instance
        .collection('investments')
        .limit(3)
        .get();

    print('📊 [TEST] Znaleziono ${snapshot.docs.length} dokumentów');

    for (int i = 0; i < snapshot.docs.length; i++) {
      final doc = snapshot.docs[i];
      final data = doc.data();

      print('🔍 [TEST] Dokument ${i + 1}: ${doc.id}');
      print('  - capitalForRestructuring: ${data['capitalForRestructuring']}');
      print(
        '  - capitalSecuredByRealEstate: ${data['capitalSecuredByRealEstate']}',
      );
      print('  - remainingCapital: ${data['remainingCapital']}');
      print('  - productName: ${data['productName']}');
      print('  - clientName: ${data['clientName']}');

      // Test utworzenia Investment z danych Firestore
      try {
        final investment = Investment.fromFirestore(doc);
        print('  ✅ Investment created:');
        print(
          '    - capitalForRestructuring: ${investment.capitalForRestructuring}',
        );
        print(
          '    - capitalSecuredByRealEstate: ${investment.capitalSecuredByRealEstate}',
        );
        print('    - remainingCapital: ${investment.remainingCapital}');
      } catch (e) {
        print('  ❌ Error creating Investment: $e');
      }

      print(''); // Empty line
    }
  } catch (e) {
    print('❌ [TEST] Błąd: $e');
  }
}
