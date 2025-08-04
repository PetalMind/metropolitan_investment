import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';

/// Skrypt do naprawienia problemu z mapowaniem ID klientów
/// Aktualizuje dane w Firestore aby używać poprawnych ID
Future<void> fixClientIdMappingIssue() async {
  print('🔧 [FixClientIds] Rozpoczynam naprawę mapowania ID klientów...\n');

  final idMappingService = ClientIdMappingService();

  try {
    // Krok 1: Utwórz mapowanie Excel ID -> Firestore ID
    print('📋 Krok 1: Tworzenie mapowania ID...');
    final mapping = await idMappingService.buildCompleteIdMapping();

    if (mapping.isEmpty) {
      print('❌ Brak danych do mapowania - przerywam');
      return;
    }

    print('✅ Utworzono mapowanie dla ${mapping.length} klientów');

    // Krok 2: Wyświetl przykłady mapowania
    print('\n📋 Krok 2: Przykłady mapowania:');
    int count = 0;
    for (final entry in mapping.entries) {
      if (count < 5) {
        print('   Excel ID ${entry.key} -> Firestore ID ${entry.value}');
        count++;
      }
    }

    // Krok 3: Sprawdź konkretny przypadek ID 147
    print('\n🔍 Krok 3: Sprawdzanie konkretnego przypadku (ID 147):');
    final firestore147 = mapping['147'];
    if (firestore147 != null) {
      print('✅ Excel ID 147 -> Firestore ID: $firestore147');

      // Sprawdź czy dokument istnieje
      final clientService = ClientService();
      final exists = await clientService.clientExists(firestore147);
      print('   Dokument istnieje w Firestore: $exists');

      if (exists) {
        final client = await clientService.getClient(firestore147);
        if (client != null) {
          print('   Nazwa klienta: ${client.name}');
          print('   Email: ${client.email}');
          print('   Status głosowania: ${client.votingStatus.displayName}');
        }
      }
    } else {
      print('❌ Nie znaleziono mapowania dla Excel ID 147');
    }

    // Krok 4: Napraw ID w inwestycjach
    print('\n🔧 Krok 4: Naprawiam ID w inwestycjach...');
    await idMappingService.fixInvestmentClientIds();

    // Krok 5: Sprawdź naprawę
    print('\n✅ Krok 5: Weryfikacja naprawy...');
    final firestore = FirebaseFirestore.instance;

    // Sprawdź ile inwestycji ma poprawne ID
    final investmentsSnapshot = await firestore.collection('investments').get();
    int correctIds = 0;
    int incorrectIds = 0;

    for (final doc in investmentsSnapshot.docs) {
      final data = doc.data();
      final clientId = data['clientId']?.toString();

      if (clientId != null) {
        // Sprawdź czy to jest prawidłowe Firestore ID (długie string) czy Excel ID (liczba)
        if (RegExp(r'^\d+$').hasMatch(clientId)) {
          incorrectIds++;
        } else {
          correctIds++;
        }
      }
    }

    print('   Inwestycje z poprawnymi Firestore ID: $correctIds');
    print('   Inwestycje z nieprawidłowymi Excel ID: $incorrectIds');

    if (incorrectIds == 0) {
      print('🎉 Wszystkie inwestycje używają poprawnych Firestore ID!');
    } else {
      print(
        '⚠️ Niektóre inwestycje nadal używają Excel ID - może być potrzebna dodatkowa naprawa',
      );
    }

    print('\n✅ Naprawa zakończona pomyślnie!');
  } catch (e) {
    print('❌ Błąd podczas naprawy: $e');
    rethrow;
  }
}

/// Funkcja pomocnicza do testowania konkretnego przypadku
Future<void> testSpecificClientUpdate(String excelId) async {
  print('🧪 [Test] Testowanie aktualizacji klienta o Excel ID: $excelId');

  try {
    final idMappingService = ClientIdMappingService();
    final firestoreId = await idMappingService.findFirestoreIdByExcelId(
      excelId,
    );

    if (firestoreId == null) {
      print('❌ Nie znaleziono Firestore ID dla Excel ID: $excelId');
      return;
    }

    print('✅ Znaleziono mapowanie: Excel $excelId -> Firestore $firestoreId');

    // Spróbuj aktualizacji przez InvestorAnalyticsService
    final analyticsService = InvestorAnalyticsService();

    await analyticsService.updateInvestorDetails(
      excelId, // Przekaż Excel ID - serwis powinien go zmapować
      votingStatus: VotingStatus.yes,
      updateReason: 'Test naprawy mapowania ID',
    );

    print('✅ Aktualizacja zakończona pomyślnie!');
  } catch (e) {
    print('❌ Błąd podczas testu: $e');
  }
}

/// Funkcja main do uruchomienia naprawy
void main() async {
  print('🚀 Uruchamianie naprawy mapowania ID klientów...\n');

  try {
    // Naprawa główna
    await fixClientIdMappingIssue();

    print('\n🧪 Testowanie konkretnego przypadku...');
    await testSpecificClientUpdate('147');
  } catch (e) {
    print('\n❌ Błąd krytyczny: $e');
  }

  print('\n🏁 Skrypt zakończony.');
}
