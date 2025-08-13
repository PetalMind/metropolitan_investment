import 'package:cloud_firestore/cloud_firestore.dart';
import '../lib/models_and_services.dart';

/// Test który bezpośrednio pobiera dane z Firestore i sprawdza czy mają capitalForRestructuring
Future<void> testDirectFirestore() async {
  print('🔍 [TEST] Test bezpośredniego odczytu z Firestore...');

  try {
    // Pobierz pierwsze 5 dokumentów z investments gdzie capitalForRestructuring > 0
    final snapshot = await FirebaseFirestore.instance
        .collection('investments')
        .where('capitalForRestructuring', isGreaterThan: 0)
        .limit(5)
        .get();

    print(
      '📊 [TEST] Znaleziono ${snapshot.docs.length} dokumentów z capitalForRestructuring > 0',
    );

    for (int i = 0; i < snapshot.docs.length; i++) {
      final doc = snapshot.docs[i];
      final data = doc.data();

      print('🔍 [TEST] Dokument ${i + 1}: ${doc.id}');
      print(
        '  - capitalForRestructuring (raw): ${data['capitalForRestructuring']} (${data['capitalForRestructuring'].runtimeType})',
      );
      print(
        '  - capitalSecuredByRealEstate (raw): ${data['capitalSecuredByRealEstate']} (${data['capitalSecuredByRealEstate'].runtimeType})',
      );
      print(
        '  - remainingCapital (raw): ${data['remainingCapital']} (${data['remainingCapital'].runtimeType})',
      );
      print('  - productName: ${data['productName']}');
      print('  - clientName: ${data['clientName']}');

      // Test utworzenia Investment z danych Firestore
      try {
        final investment = Investment.fromFirestore(doc);
        print('  ✅ Investment created successfully:');
        print(
          '    - capitalForRestructuring: ${investment.capitalForRestructuring} (${investment.capitalForRestructuring.runtimeType})',
        );
        print(
          '    - capitalSecuredByRealEstate: ${investment.capitalSecuredByRealEstate} (${investment.capitalSecuredByRealEstate.runtimeType})',
        );
        print(
          '    - remainingCapital: ${investment.remainingCapital} (${investment.remainingCapital.runtimeType})',
        );
        print(
          '    - capitalForRestructuring (direct field): ${investment.capitalForRestructuring}',
        );
        print(
          '    - capitalSecuredByRealEstate (direct field): ${investment.capitalSecuredByRealEstate}',
        );
        print(
          '    - additionalInfo[\'capitalForRestructuring\']: ${investment.additionalInfo['capitalForRestructuring']}',
        );
      } catch (e) {
        print('  ❌ Error creating Investment: $e');
      }

      print(''); // Empty line
    }

    // Test grupowania w InvestorSummary
    print('🔍 [TEST] Test grupowania w InvestorSummary...');

    // Pobierz klientów
    final clientsSnapshot = await FirebaseFirestore.instance
        .collection('clients')
        .limit(3)
        .get();

    for (final clientDoc in clientsSnapshot.docs) {
      final client = Client.fromFirestore(clientDoc);
      print('👤 [TEST] Klient: ${client.name}');

      // Pobierz jego inwestycje
      final investmentsSnapshot = await FirebaseFirestore.instance
          .collection('investments')
          .where('clientName', isEqualTo: client.name)
          .get();

      if (investmentsSnapshot.docs.isEmpty) {
        print('  ⚠️ Brak inwestycji dla klienta');
        continue;
      }

      final investments = investmentsSnapshot.docs
          .map((doc) => Investment.fromFirestore(doc))
          .toList();

      print('  📊 Inwestycje: ${investments.length}');
      for (final investment in investments) {
        print(
          '    - ${investment.productName}: capitalForRestructuring=${investment.capitalForRestructuring}, remainingCapital=${investment.remainingCapital}',
        );
      }

      // Utwórz InvestorSummary
      final investorSummary = InvestorSummary.fromInvestments(
        client,
        investments,
      );
      print('  💰 InvestorSummary:');
      print(
        '    - capitalForRestructuring: ${investorSummary.capitalForRestructuring}',
      );
      print(
        '    - capitalSecuredByRealEstate: ${investorSummary.capitalSecuredByRealEstate}',
      );
      print(
        '    - viableRemainingCapital: ${investorSummary.viableRemainingCapital}',
      );

      break; // Test tylko pierwszego klienta
    }
  } catch (e) {
    print('❌ [TEST] Błąd: $e');
  }
}
