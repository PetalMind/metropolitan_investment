import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';

/// Narzędzie diagnostyczne do sprawdzania stanu mapowania ID klientów
class ClientIdDiagnosticTool {
  late final EnhancedClientIdMappingService _mappingService;

  ClientIdDiagnosticTool() {
    _mappingService = EnhancedClientIdMappingService();
  }

  /// Przeprowadź pełną diagnostykę systemu mapowania
  Future<void> runCompleteDiagnostic() async {

    await _mappingService.initialize();

    await _checkMappingQuality();
    await _checkProductsIntegrity();
    await _checkDuplicates();
    await _generateRecommendations();

  }

  /// Sprawdź jakość mapowania
  Future<void> _checkMappingQuality() async {

    final stats = _mappingService.getStatistics();

    // Sprawdź przykłady mapowania
    await _showMappingExamples();
  }

  /// Sprawdź integralność produktów
  Future<void> _checkProductsIntegrity() async {

    final collections = [
      {'name': 'bonds', 'idField': 'ID_Klient', 'nameField': 'Klient'},
      {'name': 'shares', 'idField': 'ID_Klient', 'nameField': 'Klient'},
      {'name': 'loans', 'idField': 'ID_Klient', 'nameField': 'Klient'},
      {'name': 'investments', 'idField': 'id_klient', 'nameField': 'klient'},
      {'name': 'apartments', 'idField': 'ID_Klient', 'nameField': 'Klient'},
    ];

    for (final collection in collections) {
      await _analyzeCollection(
        collection['name']!,
        collection['idField']!,
        collection['nameField']!,
      );
    }
  }

  /// Sprawdź duplikaty
  Future<void> _checkDuplicates() async {

    final firestore = FirebaseFirestore.instance;
    final clientsSnapshot = await firestore.collection('clients').get();

    final nameGroups = <String, List<String>>{};
    final excelIdGroups = <String, List<String>>{};

    for (final doc in clientsSnapshot.docs) {
      final data = doc.data();
      final name = data['imie_nazwisko'] ?? data['name'];
      final excelId = data['excelId']?.toString() ?? data['id']?.toString();

      if (name != null) {
        nameGroups.putIfAbsent(name, () => []).add(doc.id);
      }

      if (excelId != null) {
        excelIdGroups.putIfAbsent(excelId, () => []).add(doc.id);
      }
    }

    // Znajdź duplikaty nazw
    final nameDuplicates = nameGroups.entries
        .where((entry) => entry.value.length > 1)
        .toList();

    // Znajdź duplikaty Excel ID
    final excelIdDuplicates = excelIdGroups.entries
        .where((entry) => entry.value.length > 1)
        .toList();

    if (nameDuplicates.isNotEmpty) {
      print('\n⚠️ Duplikaty nazw (pierwsze 3):');
      for (int i = 0; i < nameDuplicates.length && i < 3; i++) {
        final duplicate = nameDuplicates[i];
      }
    }

    if (excelIdDuplicates.isNotEmpty) {
      print('\n⚠️ Duplikaty Excel ID (pierwsze 3):');
      for (int i = 0; i < excelIdDuplicates.length && i < 3; i++) {
        final duplicate = excelIdDuplicates[i];
      }
    }
  }

  /// Generuj rekomendacje
  Future<void> _generateRecommendations() async {

    final stats = _mappingService.getStatistics();

    if (stats['excelMappings'] < 100) {
    }

    if (stats['nameMappings'] > stats['excelMappings'] * 1.2) {
    }

    print('   1. Uruchom migrację: `runClientIdMigration()`');
  }

  /// Pokaż przykłady mapowania
  Future<void> _showMappingExamples() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('clients').limit(3).get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final excelId = data['excelId']?.toString() ?? data['id']?.toString();
      final name = data['imie_nazwisko'] ?? data['name'];

      if (excelId != null) {
        final resolvedId = await _mappingService.getFirestoreIdByExcelId(
          excelId,
        );
      }
    }
  }

  /// Analizuj konkretną kolekcję
  Future<void> _analyzeCollection(
    String collectionName,
    String idField,
    String nameField,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection(collectionName)
        .limit(100)
        .get();

    int total = snapshot.docs.length;
    int withId = 0;
    int withName = 0;
    int resolvable = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final excelId = data[idField]?.toString();
      final clientName = data[nameField];

      if (excelId != null && excelId.isNotEmpty) withId++;
      if (clientName != null && clientName.isNotEmpty) withName++;

      final resolved = await _mappingService.resolveClientFirestoreId(
        excelId: excelId,
        clientName: clientName,
      );
      if (resolved != null) resolvable++;
    }

    print('   - Z Excel ID ($idField): $withId');
    print('   - Z nazwą ($nameField): $withName');

    if (resolvable < total * 0.8) {
    }
  }

  /// Sprawdź konkretny przypadek
  Future<void> testSpecificCase(String excelId, String clientName) async {

    await _mappingService.initialize();

    final firestoreId = await _mappingService.resolveClientFirestoreId(
      excelId: excelId,
      clientName: clientName,
    );

    if (firestoreId != null) {

      // Sprawdź czy dokument istnieje
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('clients').doc(firestoreId).get();

      if (doc.exists) {
        final data = doc.data()!;
      } else {
      }
    } else {
    }
  }
}

/// Funkcja główna diagnostyki
Future<void> runClientIdDiagnostic() async {
  final tool = ClientIdDiagnosticTool();
  await tool.runCompleteDiagnostic();
}

/// Test konkretnego przypadku
Future<void> testClientMapping(String excelId, String clientName) async {
  final tool = ClientIdDiagnosticTool();
  await tool.testSpecificCase(excelId, clientName);
}
