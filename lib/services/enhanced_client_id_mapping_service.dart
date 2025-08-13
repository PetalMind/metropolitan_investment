import '../models_and_services.dart';

/// Enhanced serwis do kompleksowego mapowania ID między danymi Excel a Firestore
/// Rozwiązuje problem z niezgodnością ID klientów w całym systemie
class EnhancedClientIdMappingService extends BaseService {
  /// Cache mapowania Excel ID -> Firestore UUID
  final Map<String, String> _excelToFirestoreCache = {};
  final Map<String, String> _firestoreToExcelCache = {};

  /// Cache mapowania Nazwa Klienta -> Firestore UUID (fallback)
  final Map<String, String> _nameToFirestoreCache = {};

  bool _isInitialized = false;

  /// Inicjalizuj cache mapowania - wywołaj na starcie aplikacji
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _buildCompleteMapping();
      _isInitialized = true;
    } catch (e) {
      logError('initialize', e);
    }
  }

  /// Znajdź Firestore UUID na podstawie Excel ID
  Future<String?> getFirestoreIdByExcelId(String excelId) async {
    await _ensureInitialized();

    // Sprawdź cache
    if (_excelToFirestoreCache.containsKey(excelId)) {
      return _excelToFirestoreCache[excelId];
    }

    return null;
  }

  /// Znajdź Firestore UUID na podstawie nazwy klienta (fallback)
  Future<String?> getFirestoreIdByClientName(String clientName) async {
    await _ensureInitialized();

    // Sprawdź cache
    if (_nameToFirestoreCache.containsKey(clientName)) {
      return _nameToFirestoreCache[clientName];
    }

    return null;
  }

  /// Znajdź Excel ID na podstawie Firestore UUID
  String? getExcelIdByFirestoreId(String firestoreId) {
    return _firestoreToExcelCache[firestoreId];
  }

  /// Główna metoda mapowania - łączy produkty z klientami
  Future<String?> resolveClientFirestoreId({
    String? excelId,
    String? clientName,
  }) async {
    await _ensureInitialized();

    // Strategia 1: Mapowanie przez Excel ID (najlepsze)
    if (excelId != null && excelId.isNotEmpty) {
      final firestoreId = await getFirestoreIdByExcelId(excelId);
      if (firestoreId != null) {
        return firestoreId;
      }
    }

    // Strategia 2: Mapowanie przez nazwę klienta (fallback)
    if (clientName != null && clientName.isNotEmpty) {
      final firestoreId = await getFirestoreIdByClientName(clientName);
      if (firestoreId != null) {
        return firestoreId;
      }
    }

    return null;
  }

  /// Napraw wszystkie produkty inwestycyjne - dodaj poprawne Firebase UUID
  Future<void> fixAllProductsClientMapping() async {

    await _ensureInitialized();

    try {
      // Napraw wszystkie kolekcje
      await Future.wait([
        _fixInvestmentIds(),
        _fixBondIds(),
        _fixShareIds(),
        _fixLoanIds(),
        _fixApartmentIds(),
      ]);

    } catch (e) {
      logError('fixAllProductsClientMapping', e);
      rethrow;
    }
  }

  /// Odśwież cache - wywołaj po dodaniu nowych klientów
  Future<void> refreshCache() async {

    _excelToFirestoreCache.clear();
    _firestoreToExcelCache.clear();
    _nameToFirestoreCache.clear();
    _isInitialized = false;

    await initialize();
  }

  /// Pobierz statystyki mapowania
  Map<String, dynamic> getStatistics() {
    return {
      'excelMappings': _excelToFirestoreCache.length,
      'nameMappings': _nameToFirestoreCache.length,
      'isInitialized': _isInitialized,
      'totalUniqueClients': _excelToFirestoreCache.length,
    };
  }

  // PRIVATE METHODS

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  Future<void> _buildCompleteMapping() async {
    final snapshot = await firestore.collection('clients').get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final firestoreId = doc.id;

      // Mapowanie przez excelId
      final excelId = data['excelId']?.toString();
      if (excelId != null && excelId.isNotEmpty) {
        _excelToFirestoreCache[excelId] = firestoreId;
        _firestoreToExcelCache[firestoreId] = excelId;
      }

      // Mapowanie przez stare pole 'id'
      final oldId = data['id']?.toString();
      if (oldId != null && oldId.isNotEmpty && oldId != excelId) {
        _excelToFirestoreCache[oldId] = firestoreId;
      }

      // Mapowanie przez nazwę klienta (fallback)
      final clientName = data['imie_nazwisko'] ?? data['name'];
      if (clientName != null && clientName.isNotEmpty) {
        _nameToFirestoreCache[clientName] = firestoreId;
      }
    }

  }

  Future<void> _fixInvestmentIds() async {
    final snapshot = await firestore.collection('investments').get();
    final batch = firestore.batch();
    int fixedCount = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final currentClientId = data['id_klient']?.toString();

      if (currentClientId != null) {
        final correctFirestoreId = await resolveClientFirestoreId(
          excelId: currentClientId,
          clientName: data['klient'],
        );

        if (correctFirestoreId != null &&
            correctFirestoreId != currentClientId) {
          batch.update(doc.reference, {
            'clientId': correctFirestoreId,
            'id_klient': correctFirestoreId,
            'original_excel_id': currentClientId,
          });
          fixedCount++;
        }
      }
    }

    if (fixedCount > 0) {
      await batch.commit();
    }
  }

  Future<void> _fixBondIds() async {
    final snapshot = await firestore.collection('bonds').get();
    final batch = firestore.batch();
    int fixedCount = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final currentClientId = data['ID_Klient']?.toString();

      if (currentClientId != null) {
        final correctFirestoreId = await resolveClientFirestoreId(
          excelId: currentClientId,
          clientName: data['Klient'],
        );

        if (correctFirestoreId != null) {
          batch.update(doc.reference, {
            'client_firestore_id': correctFirestoreId,
            'original_excel_client_id': currentClientId,
          });
          fixedCount++;
        }
      }
    }

    if (fixedCount > 0) {
      await batch.commit();
    }
  }

  Future<void> _fixShareIds() async {
    final snapshot = await firestore.collection('shares').get();
    final batch = firestore.batch();
    int fixedCount = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final currentClientId = data['ID_Klient']?.toString();

      if (currentClientId != null) {
        final correctFirestoreId = await resolveClientFirestoreId(
          excelId: currentClientId,
          clientName: data['Klient'],
        );

        if (correctFirestoreId != null) {
          batch.update(doc.reference, {
            'client_firestore_id': correctFirestoreId,
            'original_excel_client_id': currentClientId,
          });
          fixedCount++;
        }
      }
    }

    if (fixedCount > 0) {
      await batch.commit();
    }
  }

  Future<void> _fixLoanIds() async {
    final snapshot = await firestore.collection('loans').get();
    final batch = firestore.batch();
    int fixedCount = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final currentClientId = data['ID_Klient']?.toString();

      if (currentClientId != null) {
        final correctFirestoreId = await resolveClientFirestoreId(
          excelId: currentClientId,
          clientName: data['Klient'],
        );

        if (correctFirestoreId != null) {
          batch.update(doc.reference, {
            'client_firestore_id': correctFirestoreId,
            'original_excel_client_id': currentClientId,
          });
          fixedCount++;
        }
      }
    }

    if (fixedCount > 0) {
      await batch.commit();
    }
  }

  Future<void> _fixApartmentIds() async {
    final snapshot = await firestore.collection('apartments').get();
    final batch = firestore.batch();
    int fixedCount = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final currentClientId = data['ID_Klient']?.toString();

      if (currentClientId != null) {
        final correctFirestoreId = await resolveClientFirestoreId(
          excelId: currentClientId,
          clientName: data['Klient'],
        );

        if (correctFirestoreId != null) {
          batch.update(doc.reference, {
            'client_firestore_id': correctFirestoreId,
            'original_excel_client_id': currentClientId,
          });
          fixedCount++;
        }
      }
    }

    if (fixedCount > 0) {
      await batch.commit();
    }
  }
}
