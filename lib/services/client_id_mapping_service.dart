import '../models_and_services.dart';

/// Serwis do mapowania ID między danymi Excel a Firestore
/// Rozwiązuje problem z niezgodnością ID klientów
class ClientIdMappingService extends BaseService {
  /// Cache mapowania Excel ID -> Firestore ID
  final Map<String, String> _excelToFirestoreIdCache = {};
  final Map<String, String> _firestoreToExcelIdCache = {};

  /// Znajdź prawdziwe Firestore ID na podstawie Excel ID lub nazwy klienta
  Future<String?> findFirestoreIdByExcelId(String excelId) async {
    try {
      print('🔍 [IDMapping] Szukam Firestore ID dla Excel ID: $excelId');

      // Sprawdź cache
      if (_excelToFirestoreIdCache.containsKey(excelId)) {
        final cachedId = _excelToFirestoreIdCache[excelId]!;
        print('✅ [IDMapping] Znaleziono w cache: $cachedId');
        return cachedId;
      }

      // Szukaj przez pole excelId (jeśli istnieje)
      var query = await firestore
          .collection('clients')
          .where('excelId', isEqualTo: excelId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final firestoreId = doc.id;
        _cacheMapping(excelId, firestoreId);
        print('✅ [IDMapping] Znaleziono przez excelId: $firestoreId');
        return firestoreId;
      }

      // Szukaj przez pole id (stare pole)
      query = await firestore
          .collection('clients')
          .where('id', isEqualTo: int.parse(excelId))
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final firestoreId = doc.id;
        _cacheMapping(excelId, firestoreId);
        print('✅ [IDMapping] Znaleziono przez pole id: $firestoreId');
        return firestoreId;
      }

      // Szukaj przez id jako string
      query = await firestore
          .collection('clients')
          .where('id', isEqualTo: excelId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final firestoreId = doc.id;
        _cacheMapping(excelId, firestoreId);
        print('✅ [IDMapping] Znaleziono przez id string: $firestoreId');
        return firestoreId;
      }

      print('❌ [IDMapping] Nie znaleziono Firestore ID dla Excel ID: $excelId');
      return null;
    } catch (e) {
      print('❌ [IDMapping] Błąd wyszukiwania ID: $e');
      logError('findFirestoreIdByExcelId', e);
      return null;
    }
  }

  /// Znajdź Firestore ID na podstawie nazwy klienta
  Future<String?> findFirestoreIdByClientName(String clientName) async {
    try {
      print('🔍 [IDMapping] Szukam klienta po nazwie: $clientName');

      final query = await firestore
          .collection('clients')
          .where('imie_nazwisko', isEqualTo: clientName)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        final excelId = data['id']?.toString();

        if (excelId != null) {
          _cacheMapping(excelId, doc.id);
        }

        print('✅ [IDMapping] Znaleziono klienta po nazwie: ${doc.id}');
        return doc.id;
      }

      print('❌ [IDMapping] Nie znaleziono klienta o nazwie: $clientName');
      return null;
    } catch (e) {
      print('❌ [IDMapping] Błąd wyszukiwania po nazwie: $e');
      logError('findFirestoreIdByClientName', e);
      return null;
    }
  }

  /// Znajdź i utwórz pełne mapowanie Excel ID -> Firestore ID
  Future<Map<String, String>> buildCompleteIdMapping() async {
    try {
      print('🔄 [IDMapping] Tworzenie kompletnego mapowania ID...');

      final snapshot = await firestore.collection('clients').get();
      final mapping = <String, String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final excelId = data['id']?.toString();

        if (excelId != null) {
          mapping[excelId] = doc.id;
        }
      }

      // Aktualizuj cache
      _excelToFirestoreIdCache.clear();
      _firestoreToExcelIdCache.clear();

      for (final entry in mapping.entries) {
        _excelToFirestoreIdCache[entry.key] = entry.value;
        _firestoreToExcelIdCache[entry.value] = entry.key;
      }

      print('✅ [IDMapping] Utworzono mapowanie dla ${mapping.length} klientów');
      return mapping;
    } catch (e) {
      print('❌ [IDMapping] Błąd tworzenia mapowania: $e');
      logError('buildCompleteIdMapping', e);
      return {};
    }
  }

  /// Aktualizuj Investment z poprawnymi Firestore ID
  Future<void> fixInvestmentClientIds() async {
    try {
      print('🔧 [IDMapping] Naprawiam ID klientów w inwestycjach...');

      // Utwórz mapowanie
      final mapping = await buildCompleteIdMapping();

      if (mapping.isEmpty) {
        print('❌ [IDMapping] Brak mapowania - przerywam');
        return;
      }

      // Pobierz wszystkie inwestycje
      final investmentsSnapshot = await firestore
          .collection('investments')
          .get();
      final batch = firestore.batch();
      int fixedCount = 0;

      for (final doc in investmentsSnapshot.docs) {
        final data = doc.data();
        final currentClientId =
            data['id_klient']?.toString() ?? data['clientId']?.toString();

        if (currentClientId != null && mapping.containsKey(currentClientId)) {
          final correctFirestoreId = mapping[currentClientId]!;

          // Aktualizuj clientId w dokumencie inwestycji
          batch.update(doc.reference, {
            'clientId': correctFirestoreId,
            'original_excel_client_id':
                currentClientId, // Zachowaj oryginalne ID
            'id_klient': correctFirestoreId, // Aktualizuj oba pola
          });

          fixedCount++;
        }
      }

      if (fixedCount > 0) {
        await batch.commit();
        print('✅ [IDMapping] Naprawiono $fixedCount inwestycji');
      } else {
        print('ℹ️ [IDMapping] Brak inwestycji do naprawy');
      }
    } catch (e) {
      print('❌ [IDMapping] Błąd naprawy ID inwestycji: $e');
      logError('fixInvestmentClientIds', e);
      rethrow;
    }
  }

  /// Pomocnicza metoda do cache'owania mapowania
  void _cacheMapping(String excelId, String firestoreId) {
    _excelToFirestoreIdCache[excelId] = firestoreId;
    _firestoreToExcelIdCache[firestoreId] = excelId;
  }

  /// Pobierz Excel ID na podstawie Firestore ID
  String? getExcelIdByFirestoreId(String firestoreId) {
    return _firestoreToExcelIdCache[firestoreId];
  }

  /// Sprawdź czy mapowanie jest załadowane
  bool get isMappingLoaded => _excelToFirestoreIdCache.isNotEmpty;

  /// Załaduj mapowanie do cache
  Future<void> preloadMapping() async {
    if (!isMappingLoaded) {
      await buildCompleteIdMapping();
    }
  }
}
