import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';

/// Skrypt do naprawienia problemu z mapowaniem ID klientów
/// Aktualizuje dane w Firestore aby używać poprawnych ID
Future<void> fixClientIdMappingIssue() async {

  final idMappingService = ClientIdMappingService();

  try {
    // Krok 1: Utwórz mapowanie Excel ID -> Firestore ID
    final mapping = await idMappingService.buildCompleteIdMapping();

    if (mapping.isEmpty) {
      return;
    }

    // Krok 2: Wyświetl przykłady mapowania
    int count = 0;
    for (final entry in mapping.entries) {
      if (count < 5) {
        count++;
      }
    }

    // Krok 3: Sprawdź konkretny przypadek ID 147
    print('\n🔍 Krok 3: Sprawdzanie konkretnego przypadku (ID 147):');
    final firestore147 = mapping['147'];
    if (firestore147 != null) {

      // Sprawdź czy dokument istnieje
      final clientService = ClientService();
      final exists = await clientService.clientExists(firestore147);

      if (exists) {
        final client = await clientService.getClient(firestore147);
        if (client != null) {
        }
      }
    } else {
    }

    // Krok 4: Napraw ID w inwestycjach
    await idMappingService.fixInvestmentClientIds();

    // Krok 5: Sprawdź naprawę
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

    if (incorrectIds == 0) {
    } else {
    }

  } catch (e) {
    rethrow;
  }
}

/// Funkcja pomocnicza do testowania konkretnego przypadku
Future<void> testSpecificClientUpdate(String excelId) async {

  try {
    final idMappingService = ClientIdMappingService();
    final firestoreId = await idMappingService.findFirestoreIdByExcelId(
      excelId,
    );

    if (firestoreId == null) {
      return;
    }

    // Spróbuj aktualizacji przez InvestorAnalyticsService
    final analyticsService = InvestorAnalyticsService();

    await analyticsService.updateInvestorDetails(
      excelId, // Przekaż Excel ID - serwis powinien go zmapować
      votingStatus: VotingStatus.yes,
      updateReason: 'Test naprawy mapowania ID',
    );

  } catch (e) {
  }
}

/// Funkcja main do uruchomienia naprawy
void main() async {

  try {
    // Naprawa główna
    await fixClientIdMappingIssue();

    await testSpecificClientUpdate('147');
  } catch (e) {
  }

}
