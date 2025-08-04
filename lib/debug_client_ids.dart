import 'package:cloud_firestore/cloud_firestore.dart';

/// Skrypt diagnostyczny do analizy problemu z ID klientów
/// Sprawdza mapowanie ID między Excel a Firestore
void main() async {
  // Initialize Firestore
  final firestore = FirebaseFirestore.instance;

  try {
    print('🔍 Diagnostyka ID klientów w bazie danych...\n');

    // Pobierz pierwsze 10 dokumentów
    final snapshot = await firestore.collection('clients').limit(10).get();

    print(
      '📊 Znaleziono ${snapshot.docs.length} dokumentów w kolekcji clients\n',
    );

    for (final doc in snapshot.docs) {
      final data = doc.data();

      print('📋 Dokument ID: ${doc.id}');
      print('   - Imię/Nazwisko: ${data['imie_nazwisko'] ?? 'brak'}');
      print('   - Email: ${data['email'] ?? 'brak'}');
      print('   - Excel ID: ${data['excelId'] ?? 'brak'}');
      print('   - Source File: ${data['source_file'] ?? 'brak'}');
      print('   - VotingStatus: ${data['votingStatus'] ?? 'brak'}');
      print('   - Type: ${data['type'] ?? 'brak'}');
      print('');
    }

    // Sprawdź czy istnieje dokument o ID "147"
    print('🔍 Sprawdzanie dokumentu o ID "147"...');
    final doc147 = await firestore.collection('clients').doc('147').get();

    if (doc147.exists) {
      print('✅ Dokument 147 istnieje!');
      final data = doc147.data()!;
      print('   Dane: ${data.toString()}');
    } else {
      print('❌ Dokument 147 NIE istnieje');

      // Sprawdź czy może istnieje jako excelId
      print('🔍 Szukam dokumentu z excelId = "147"...');
      final querySnapshot = await firestore
          .collection('clients')
          .where('excelId', isEqualTo: '147')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        print('✅ Znaleziono dokument z excelId 147!');
        print('   Firestore ID: ${doc.id}');
        print('   Dane: ${doc.data().toString()}');
      } else {
        print('❌ Nie znaleziono dokumentu z excelId = "147"');
      }
    }

    // Sprawdź wszystkie możliwe formaty ID "147"
    final possibleIds = ['147', '00147', 'client_147', 'excel_147'];
    print('\n🔍 Sprawdzanie alternatywnych formatów ID dla "147"...');

    for (final id in possibleIds) {
      final doc = await firestore.collection('clients').doc(id).get();
      if (doc.exists) {
        print('✅ Znaleziono dokument o ID: $id');
        final data = doc.data()!;
        print('   Imię: ${data['imie_nazwisko']}');
      } else {
        print('❌ Nie znaleziono dokumentu o ID: $id');
      }
    }
  } catch (e) {
    print('❌ Błąd diagnostyki: $e');
  }
}
