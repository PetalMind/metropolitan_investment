import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client.dart';
import 'base_service.dart';

class ClientService extends BaseService {
  final String _collection = 'clients';

  // Create
  Future<String> createClient(Client client) async {
    try {
      final docRef = await firestore
          .collection(_collection)
          .add(client.toFirestore());
      clearCache('all_clients');
      return docRef.id;
    } catch (e) {
      logError('createClient', e);
      throw Exception('Failed to create client: $e');
    }
  }

  // Read
  Future<Client?> getClient(String id) async {
    try {
      final doc = await firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Client.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      logError('getClient', e);
      throw Exception('Failed to get client: $e');
    }
  }

  // Check if client exists
  Future<bool> clientExists(String id) async {
    try {
      final doc = await firestore.collection(_collection).doc(id).get();
      return doc.exists;
    } catch (e) {
      logError('clientExists', e);
      return false;
    }
  }

  // Read all - Stream wszystkich klientów bez paginacji
  Stream<List<Client>> getAllClientsStream() {
    return firestore
        .collection(_collection)
        .orderBy('fullName')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Client.fromFirestore(doc)).toList(),
        );
  }

  // Read all - ZAKTUALIZOWANE dla danych z Excel z paginacją i cache
  Stream<List<Client>> getClients({int? limit}) {
    return firestore
        .collection(_collection)
        .orderBy('fullName')
        .limit(limit ?? 1000) // Zwiększony domyślny limit z 50 na 1000
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Client.fromFirestore(doc)).toList(),
        );
  }

  // Paginowana wersja pobierania klientów
  Future<PaginationResult<Client>> getClientsPaginated({
    PaginationParams params = const PaginationParams(),
  }) async {
    try {
      Query<Map<String, dynamic>> query = firestore
          .collection(_collection)
          .orderBy(params.orderBy ?? 'fullName', descending: params.descending)
          .limit(params.limit);

      if (params.startAfter != null) {
        query = query.startAfterDocument(params.startAfter!);
      }

      final snapshot = await query.get();
      final clients = snapshot.docs
          .map((doc) => Client.fromFirestore(doc))
          .toList();

      return PaginationResult<Client>(
        items: clients,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == params.limit,
      );
    } catch (e) {
      logError('getClientsPaginated', e);
      throw Exception('Failed to get clients with pagination: $e');
    }
  }

  // Search clients - ZOPTYMALIZOWANE z wykorzystaniem indeksów
  Stream<List<Client>> searchClients(String query, {int limit = 1000}) {
    // Zwiększony limit
    if (query.isEmpty) return getClients(limit: limit);

    // Wykorzystuje indeks: email + fullName
    return firestore
        .collection(_collection)
        .where('fullName', isGreaterThanOrEqualTo: query)
        .where('fullName', isLessThanOrEqualTo: query + '\uf8ff')
        .orderBy('fullName')
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Client.fromFirestore(doc)).toList(),
        );
  }

  // Update
  Future<void> updateClient(String id, Client client) async {
    try {
      await firestore
          .collection(_collection)
          .doc(id)
          .update(client.toFirestore());
      clearCache('all_clients');
    } catch (e) {
      logError('updateClient', e);
      throw Exception('Failed to update client: $e');
    }
  }

  // Delete (soft delete)
  Future<void> deleteClient(String id) async {
    try {
      await firestore.collection(_collection).doc(id).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
      clearCache('all_clients');
    } catch (e) {
      logError('deleteClient', e);
      throw Exception('Failed to delete client: $e');
    }
  }

  // Hard delete
  Future<void> hardDeleteClient(String id) async {
    try {
      await firestore.collection(_collection).doc(id).delete();
      clearCache('all_clients');
    } catch (e) {
      logError('hardDeleteClient', e);
      throw Exception('Failed to hard delete client: $e');
    }
  }

  // Get clients count - ZAKTUALIZOWANE
  Future<int> getClientsCount() async {
    try {
      final snapshot = await firestore.collection(_collection).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      logError('getClientsCount', e);
      throw Exception('Failed to get clients count: $e');
    }
  }

  // NOWE METODY dla danych z Excel

  // Pobierz klientów z emailem z optymalizacją - wykorzystuje indeks email + fullName
  Stream<List<Client>> getClientsWithEmail({int limit = 1000}) {
    // Zwiększony limit
    return firestore
        .collection(_collection)
        .where('email', isNotEqualTo: '')
        .where('email', isNotEqualTo: 'brak')
        .orderBy('email')
        .orderBy('fullName') // Dodane dla wykorzystania indeksu
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Client.fromFirestore(doc)).toList(),
        );
  }

  // Pobierz statystyki klientów z cache
  Future<Map<String, dynamic>> getClientStats() async {
    return getCachedData('client_stats', () async {
      try {
        final allClients = await firestore.collection(_collection).get();

        int totalClients = allClients.docs.length;
        int clientsWithEmail = 0;
        int clientsWithPhone = 0;
        int clientsWithCompany = 0;

        for (var doc in allClients.docs) {
          final data = doc.data();

          final email = data['email']?.toString() ?? '';
          if (email.isNotEmpty && email != 'brak' && email.contains('@')) {
            clientsWithEmail++;
          }

          final phone = (data['phone'] ?? data['telefon'])?.toString() ?? '';
          if (phone.isNotEmpty) {
            clientsWithPhone++;
          }

          final company =
              (data['companyName'] ?? data['nazwa_firmy'])?.toString() ?? '';
          if (company.isNotEmpty) {
            clientsWithCompany++;
          }
        }

        return {
          'total_clients': totalClients,
          'clients_with_email': clientsWithEmail,
          'clients_with_phone': clientsWithPhone,
          'clients_with_company': clientsWithCompany,
          'email_percentage': totalClients > 0
              ? (clientsWithEmail / totalClients * 100).toStringAsFixed(1)
              : '0',
          'phone_percentage': totalClients > 0
              ? (clientsWithPhone / totalClients * 100).toStringAsFixed(1)
              : '0',
          'company_percentage': totalClients > 0
              ? (clientsWithCompany / totalClients * 100).toStringAsFixed(1)
              : '0',
        };
      } catch (e) {
        logError('getClientStats', e);
        return {
          'total_clients': 0,
          'clients_with_email': 0,
          'clients_with_phone': 0,
          'clients_with_company': 0,
          'email_percentage': '0',
          'phone_percentage': '0',
          'company_percentage': '0',
        };
      }
    });
  }

  // Get all clients (helper method for analytics)
  Future<List<Client>> getAllClients() async {
    try {
      print(
        '🔍 [ClientService.getAllClients] Pobieranie WSZYSTKICH klientów z Firestore...',
      );
      final snapshot = await firestore.collection(_collection).get();
      print(
        '🔍 [ClientService.getAllClients] Firestore zwrócił ${snapshot.docs.length} dokumentów',
      );
      final clients = snapshot.docs
          .map((doc) => Client.fromFirestore(doc))
          .toList();
      print(
        '🔍 [ClientService.getAllClients] Przekonwertowano do ${clients.length} obiektów Client',
      );
      return clients;
    } catch (e) {
      print('❌ [ClientService.getAllClients] Błąd: $e');
      logError('getAllClients', e);
      throw Exception('Failed to get all clients: $e');
    }
  }

  // Load all clients with progress for UI
  Future<List<Client>> loadAllClientsWithProgress({
    Function(double progress, String stage)? onProgress,
  }) async {
    try {
      onProgress?.call(0.0, 'Inicjalizacja...');
      await Future.delayed(const Duration(milliseconds: 200));

      onProgress?.call(0.2, 'Łączenie z bazą danych...');
      await Future.delayed(const Duration(milliseconds: 300));

      onProgress?.call(0.4, 'Pobieranie danych klientów...');
      final snapshot = await firestore.collection(_collection).get();

      print(
        '🔍 [ClientService.loadAllClientsWithProgress] Pobrałem ${snapshot.docs.length} dokumentów z Firestore',
      );

      onProgress?.call(0.6, 'Przetwarzanie informacji...');
      await Future.delayed(const Duration(milliseconds: 200));

      final clients = snapshot.docs
          .map((doc) => Client.fromFirestore(doc))
          .toList();

      print(
        '🔍 [ClientService.loadAllClientsWithProgress] Przetworzyłem ${clients.length} klientów',
      );

      onProgress?.call(0.8, 'Optymalizacja wyświetlania...');
      await Future.delayed(const Duration(milliseconds: 200));

      onProgress?.call(1.0, 'Finalizacja...');
      await Future.delayed(const Duration(milliseconds: 100));

      return clients;
    } catch (e) {
      logError('loadAllClientsWithProgress', e);
      throw Exception('Failed to load all clients with progress: $e');
    }
  }

  // Update client with partial data - ZOPTYMALIZOWANE dla statusu głosowania
  Future<void> updateClientFields(
    String id,
    Map<String, dynamic> fields,
  ) async {
    try {
      print('🔄 [ClientService] Sprawdzanie istnienia klienta: $id');

      // Sprawdź czy dokument istnieje przed aktualizacją
      final docRef = firestore.collection(_collection).doc(id);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        print('❌ [ClientService] Klient $id nie istnieje w kolekcji clients');
        throw Exception('Client with ID $id does not exist');
      }

      print(
        '✅ [ClientService] Klient $id istnieje, aktualizuję pola: ${fields.keys.join(', ')}',
      );

      // Waliduj i konwertuj enum values do string format
      final processedFields = <String, dynamic>{};

      for (final entry in fields.entries) {
        final key = entry.key;
        final value = entry.value;

        // Konwertuj enum na string name zgodnie z modelem Client
        if (key == 'votingStatus' && value is VotingStatus) {
          processedFields[key] = value.name;
          print(
            '🗳️ [ClientService] Konwertuję votingStatus: ${value.displayName} -> ${value.name}',
          );
        } else if (key == 'type' && value is ClientType) {
          processedFields[key] = value.name;
          print(
            '👤 [ClientService] Konwertuję type: ${value.displayName} -> ${value.name}',
          );
        } else {
          processedFields[key] = value;
        }
      }

      await docRef.update({...processedFields, 'updatedAt': Timestamp.now()});

      print('✅ [ClientService] Pomyślnie zaktualizowano klienta $id');

      // Rozszerzone czyszczenie cache dla danych głosowania
      _clearClientRelatedCache();
    } catch (e) {
      print('❌ [ClientService] Błąd w updateClientFields: $e');
      logError('updateClientFields', e);
      throw Exception('Failed to update client fields: $e');
    }
  }

  /// Czyści cache związane z klientami
  void _clearClientRelatedCache() {
    clearCache('all_clients');
    clearCache('client_stats');

    // Wyczyść cache dla różnych filtrów statusu głosowania
    for (final status in VotingStatus.values) {
      clearCache('clients_voting_${status.name}');
    }

    // Wyczyść cache dla różnych typów klientów
    for (final type in ClientType.values) {
      clearCache('clients_type_${type.name}');
    }
  }

  // ===== NOWE METODY WYKORZYSTUJĄCE INDEKSY =====

  // Pobierz aktywnych klientów - wykorzystuje indeks isActive + fullName
  Stream<List<Client>> getActiveClients({int limit = 10000}) {
    // Zwiększony limit
    // Ponieważ dane z Excel nie mają pola isActive, pobieramy wszystkich klientów
    return firestore
        .collection(_collection)
        .orderBy('fullName')
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Client.fromFirestore(doc)).toList(),
        );
  }

  // Pobierz klientów według typu - dane z Excel nie mają pola type
  Stream<List<Client>> getClientsByType(ClientType type, {int limit = 1000}) {
    // Zwiększony limit
    // Pobieramy wszystkich klientów (dane nie mają pola type)
    return firestore
        .collection(_collection)
        .orderBy('fullName')
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Client.fromFirestore(doc)).toList(),
        );
  }

  // Pobierz klientów według statusu głosowania - wykorzystuje indeks votingStatus + updatedAt
  Stream<List<Client>> getClientsByVotingStatus(
    VotingStatus votingStatus, {
    int limit = 1000, // Zwiększony limit
  }) {
    // Pobieramy wszystkich klientów (dane nie mają pola votingStatus)
    return firestore
        .collection(_collection)
        .orderBy('imie_nazwisko')
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Client.fromFirestore(doc)).toList(),
        );
  }

  /// Pobiera dane klientów na podstawie listy ID
  Future<List<Client>> getClientsByIds(List<String> clientIds) async {
    try {
      print('🔍 [ClientService] Szukam klientów o ID: $clientIds');
      final List<Client> clients = [];

      // KROK 1: Najpierw szukaj po excelId (większość clientId z OptimizedInvestor to excelId)
      print('🔄 [ClientService] KROK 1: Szukam po excelId...');
      for (final clientId in clientIds) {
        final excelSnapshot = await firestore
            .collection('clients')
            .where('excelId', isEqualTo: clientId)
            .limit(1)
            .get();

        if (excelSnapshot.docs.isNotEmpty) {
          final client = Client.fromFirestore(excelSnapshot.docs.first);
          clients.add(client);
          print(
            '✅ [ClientService] Znaleziono po excelId: $clientId -> ${client.name} (doc.id: ${client.id})',
          );
        }
      }

      // KROK 2: Dla nie znalezionych, szukaj po UUID (document ID)
      final foundExcelIds = clientIds
          .where((id) => clients.any((client) => client.excelId == id))
          .toSet();
      final missingClientIds = clientIds
          .where((id) => !foundExcelIds.contains(id))
          .toList();

      if (missingClientIds.isNotEmpty) {
        print(
          '🔄 [ClientService] KROK 2: Szukam brakujących ${missingClientIds.length} po UUID...',
        );

        const batchSize = 10;
        for (int i = 0; i < missingClientIds.length; i += batchSize) {
          final batch = missingClientIds.skip(i).take(batchSize).toList();
          print('📦 [ClientService] Przetwarzam batch UUID: $batch');

          final snapshot = await firestore
              .collection('clients')
              .where(FieldPath.documentId, whereIn: batch)
              .get();

          print(
            '📋 [ClientService] Znaleziono ${snapshot.docs.length} dokumentów klientów w batch UUID',
          );

          final batchClients = snapshot.docs.map((doc) {
            print('👤 [ClientService] Przetwarzam klienta UUID: ${doc.id}');
            return Client.fromFirestore(doc);
          }).toList();

          clients.addAll(batchClients);
        }
      }

      // KROK 3: Dla nadal nie znalezionych, spróbuj po original_id
      final allFoundIds = clients.map((c) => c.excelId ?? c.id).toSet();
      final stillMissingIds = clientIds
          .where((id) => !allFoundIds.contains(id))
          .toList();

      if (stillMissingIds.isNotEmpty) {
        print(
          '🔄 [ClientService] KROK 3: Szukam ${stillMissingIds.length} po original_id...',
        );

        for (final missingId in stillMissingIds) {
          final originalIdSnapshot = await firestore
              .collection('clients')
              .where('original_id', isEqualTo: missingId)
              .limit(1)
              .get();

          if (originalIdSnapshot.docs.isNotEmpty) {
            final client = Client.fromFirestore(originalIdSnapshot.docs.first);
            clients.add(client);
            print(
              '✅ [ClientService] Znaleziono po original_id: $missingId -> ${client.name}',
            );
          } else {
            print('❌ [ClientService] Nie znaleziono klienta o ID: $missingId');
          }
        }
      }

      print(
        '🎯 [ClientService] WYNIK: Łącznie załadowano ${clients.length}/${clientIds.length} klientów',
      );
      return clients;
    } catch (e) {
      logError('getClientsByIds', e);
      print('❌ [ClientService] Błąd pobierania klientów: $e');
      return [];
    }
  }

  // Usuwam duplikat metody getClientsPaginated - zostaje ta z góry
}
