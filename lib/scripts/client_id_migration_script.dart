import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';
import '../services/enhanced_client_id_mapping_service.dart';

/// Główny skrypt migracji do naprawienia problemu mapowania ID klientów
/// Wykonuje kompletną migrację systemu do nowej architektury mapowania
class ClientIdMigrationScript {
  late final EnhancedClientIdMappingService _mappingService;
  late final FirebaseFirestore _firestore;

  ClientIdMigrationScript() {
    _mappingService = EnhancedClientIdMappingService();
    _firestore = FirebaseFirestore.instance;
  }

  /// Wykonaj kompletną migrację systemu
  Future<void> executeMigration() async {

    try {
      await _step1_InitializeMapping();
      await _step2_ValidateCurrentState();
      await _step3_FixAllProducts();
      await _step4_ValidateResults();
      await _step5_CreateReport();

    } catch (e) {
      rethrow;
    }
  }

  /// Krok 1: Inicjalizacja systemu mapowania
  Future<void> _step1_InitializeMapping() async {

    await _mappingService.initialize();
    final stats = _mappingService.getStatistics();

  }

  /// Krok 2: Walidacja obecnego stanu
  Future<void> _step2_ValidateCurrentState() async {

    final results = await Future.wait([
      _validateCollection('investments', 'id_klient', 'klient'),
      _validateCollection('bonds', 'ID_Klient', 'Klient'),
      _validateCollection('shares', 'ID_Klient', 'Klient'),
      _validateCollection('loans', 'ID_Klient', 'Klient'),
      _validateCollection('apartments', 'ID_Klient', 'Klient'),
    ]);

    for (int i = 0; i < results.length; i++) {
      final collections = [
        'investments',
        'bonds',
        'shares',
        'loans',
        'apartments',
      ];
      final result = results[i];
    }
  }

  /// Krok 3: Napraw wszystkie produkty
  Future<void> _step3_FixAllProducts() async {

    await _mappingService.fixAllProductsClientMapping();
  }

  /// Krok 4: Walidacja wyników
  Future<void> _step4_ValidateResults() async {

    final results = await Future.wait([
      _validateCollection(
        'investments',
        'id_klient',
        'klient',
        checkFixed: true,
      ),
      _validateCollection('bonds', 'ID_Klient', 'Klient', checkFixed: true),
      _validateCollection('shares', 'ID_Klient', 'Klient', checkFixed: true),
      _validateCollection('loans', 'ID_Klient', 'Klient', checkFixed: true),
      _validateCollection(
        'apartments',
        'ID_Klient',
        'Klient',
        checkFixed: true,
      ),
    ]);

    for (int i = 0; i < results.length; i++) {
      final collections = [
        'investments',
        'bonds',
        'shares',
        'loans',
        'apartments',
      ];
      final result = results[i];
    }
  }

  /// Krok 5: Generuj raport
  Future<void> _step5_CreateReport() async {

    final stats = _mappingService.getStatistics();
    final report = {
      'migration_date': DateTime.now().toIso8601String(),
      'mapping_statistics': stats,
      'status': 'completed',
      'collections_processed': [
        'investments',
        'bonds',
        'shares',
        'loans',
        'apartments',
      ],
    };

    // Zapisz raport do Firestore
    await _firestore.collection('migration_reports').add(report);

  }

  /// Pomocnicza metoda walidacji kolekcji
  Future<Map<String, int>> _validateCollection(
    String collectionName,
    String clientIdField,
    String clientNameField, {
    bool checkFixed = false,
  }) async {
    final snapshot = await _firestore.collection(collectionName).get();
    int total = snapshot.docs.length;
    int resolved = 0;
    int fixed = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final excelId = data[clientIdField]?.toString();
      final clientName = data[clientNameField];

      // Sprawdź czy można zmapować
      final firestoreId = await _mappingService.resolveClientFirestoreId(
        excelId: excelId,
        clientName: clientName,
      );

      if (firestoreId != null) {
        resolved++;
      }

      // Sprawdź czy już naprawione
      if (checkFixed && data['client_firestore_id'] != null) {
        fixed++;
      }
    }

    return {
      'total': total,
      'resolved': resolved,
      'fixed': checkFixed ? fixed : 0,
    };
  }
}

/// Funkcja główna do uruchomienia migracji
Future<void> runClientIdMigration() async {

  final migration = ClientIdMigrationScript();
  await migration.executeMigration();

}
