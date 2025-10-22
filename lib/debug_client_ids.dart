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

    for (final doc in snapshot.docs.take(5)) {
      // Data not needed for production
    }

    // Sprawdź czy istnieje dokument o ID "147"
    final doc147 = await firestore.collection('clients').doc('147').get();

    if (doc147.exists) {
      // Document exists
    } else {
      // Sprawdź czy może istnieje jako excelId
      final querySnapshot = await firestore
          .collection('clients')
          .where('excelId', isEqualTo: '147')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Found document
      } else {
        // Not found
      }
    }

    // Sprawdź wszystkie możliwe formaty ID "147"
    final possibleIds = ['147', '00147', 'client_147', 'excel_147'];

    for (final id in possibleIds) {
      final doc = await firestore.collection('clients').doc(id).get();
      if (doc.exists) {
        // Found
      } else {
        // Not found
      }
    }
  } catch (e) {
    // Error handling removed for production
  }
}
