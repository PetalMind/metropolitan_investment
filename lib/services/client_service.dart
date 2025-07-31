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

  // Read all - Stream wszystkich klientów bez paginacji
  Stream<List<Client>> getAllClientsStream() {
    return firestore
        .collection(_collection)
        .orderBy('imie_nazwisko')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            // Konwertuj dane z Excel do modelu Client
            return Client(
              id: doc.id,
              name:
                  data['imie_nazwisko'] ??
                  '', // Używamy imie_nazwisko z Firebase
              email: data['email'] ?? '',
              phone: data['telefon'] ?? '',
              address: '', // Brak adresu w danych Excel
              pesel: data['pesel'] ?? '',
              createdAt: data['created_at'] != null
                  ? DateTime.parse(data['created_at'])
                  : DateTime.now(),
              updatedAt: DateTime.now(),
              isActive: true,
              additionalInfo: {
                'nazwa_firmy': data['nazwa_firmy'] ?? '',
                'source_file': data['source_file'] ?? 'Excel import',
              },
            );
          }).toList(),
        );
  }

  // Read all - ZAKTUALIZOWANE dla danych z Excel z paginacją i cache
  Stream<List<Client>> getClients({int? limit}) {
    return firestore
        .collection(_collection)
        .orderBy('imie_nazwisko')
        .limit(limit ?? 50) // Domyślnie ograniczamy do 50
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            // Konwertuj dane z Excel do modelu Client
            return Client(
              id: doc.id,
              name:
                  data['imie_nazwisko'] ??
                  '', // Używamy imie_nazwisko z Firebase
              email: data['email'] ?? '',
              phone: data['telefon'] ?? '',
              address: '', // Brak adresu w danych Excel
              pesel: data['pesel'] ?? '',
              createdAt: data['created_at'] != null
                  ? DateTime.parse(data['created_at'])
                  : DateTime.now(),
              updatedAt: DateTime.now(),
              isActive: true,
              additionalInfo: {
                'nazwa_firmy': data['nazwa_firmy'] ?? '',
                'source_file': data['source_file'] ?? 'Excel import',
              },
            );
          }).toList(),
        );
  }

  // Paginowana wersja pobierania klientów
  Future<PaginationResult<Client>> getClientsPaginated({
    PaginationParams params = const PaginationParams(),
  }) async {
    try {
      Query query = firestore
          .collection(_collection)
          .orderBy(
            params.orderBy ?? 'imie_nazwisko',
            descending: params.descending,
          )
          .limit(params.limit);

      if (params.startAfter != null) {
        query = query.startAfterDocument(params.startAfter!);
      }

      final snapshot = await query.get();
      final clients = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Client(
          id: doc.id,
          name: data['imie_nazwisko'] ?? '', // Używamy imie_nazwisko z Firebase
          email: data['email'] ?? '',
          phone: data['telefon'] ?? '',
          address: '',
          pesel: data['pesel'] ?? '',
          createdAt: data['created_at'] != null
              ? DateTime.parse(data['created_at'])
              : DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
          additionalInfo: {
            'nazwa_firmy': data['nazwa_firmy'] ?? '',
            'source_file': data['source_file'] ?? 'Excel import',
          },
        );
      }).toList();

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
  Stream<List<Client>> searchClients(String query, {int limit = 30}) {
    if (query.isEmpty) return getClients(limit: limit);

    // Wykorzystuje indeks: email + imie_nazwisko
    return firestore
        .collection(_collection)
        .where('imie_nazwisko', isGreaterThanOrEqualTo: query)
        .where('imie_nazwisko', isLessThanOrEqualTo: query + '\uf8ff')
        .orderBy('imie_nazwisko')
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return Client(
              id: doc.id,
              name:
                  data['imie_nazwisko'] ??
                  '', // Używamy imie_nazwisko z Firebase
              email: data['email'] ?? '',
              phone: data['telefon'] ?? '',
              address: '',
              pesel: data['pesel'] ?? '',
              createdAt: data['created_at'] != null
                  ? DateTime.parse(data['created_at'])
                  : DateTime.now(),
              updatedAt: DateTime.now(),
              isActive: true,
              additionalInfo: {
                'nazwa_firmy': data['nazwa_firmy'] ?? '',
                'source_file': data['source_file'] ?? 'Excel import',
              },
            );
          }).toList(),
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

  // Pobierz klientów z emailem z optymalizacją - wykorzystuje indeks email + imie_nazwisko
  Stream<List<Client>> getClientsWithEmail({int limit = 50}) {
    return firestore
        .collection(_collection)
        .where('email', isNotEqualTo: '')
        .where('email', isNotEqualTo: 'brak')
        .orderBy('email')
        .orderBy('imie_nazwisko') // Dodane dla wykorzystania indeksu
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return Client(
              id: doc.id,
              name:
                  data['imie_nazwisko'] ??
                  '', // Używamy imie_nazwisko z Firebase
              email: data['email'] ?? '',
              phone: data['telefon'] ?? '',
              address: '',
              pesel: data['pesel'] ?? '',
              createdAt: data['created_at'] != null
                  ? DateTime.parse(data['created_at'])
                  : DateTime.now(),
              updatedAt: DateTime.now(),
              isActive: true,
              additionalInfo: {
                'nazwa_firmy': data['nazwa_firmy'] ?? '',
                'source_file': data['source_file'] ?? 'Excel import',
              },
            );
          }).toList(),
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

          final phone = data['telefon']?.toString() ?? '';
          if (phone.isNotEmpty) {
            clientsWithPhone++;
          }

          final company = data['nazwa_firmy']?.toString() ?? '';
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
      final snapshot = await firestore.collection(_collection).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Client(
          id: doc.id,
          name: data['imie_nazwisko'] ?? '', // Używamy imie_nazwisko z Firebase
          email: data['email'] ?? '',
          phone: data['telefon'] ?? '',
          address: '',
          pesel: data['pesel'] ?? '',
          companyName: data['nazwa_firmy'],
          type: ClientType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => ClientType.individual,
          ),
          notes: data['notes'] ?? '',
          votingStatus: VotingStatus.values.firstWhere(
            (e) => e.name == data['votingStatus'],
            orElse: () => VotingStatus.undecided,
          ),
          colorCode: data['colorCode'] ?? '#FFFFFF',
          unviableInvestments: List<String>.from(
            data['unviableInvestments'] ?? [],
          ),
          createdAt: data['created_at'] != null
              ? DateTime.parse(data['created_at'])
              : DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: data['isActive'] ?? true,
          additionalInfo: {
            'nazwa_firmy': data['nazwa_firmy'] ?? '',
            'source_file': data['source_file'] ?? 'Excel import',
          },
        );
      }).toList();
    } catch (e) {
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

      onProgress?.call(0.6, 'Przetwarzanie informacji...');
      await Future.delayed(const Duration(milliseconds: 200));

      final clients = snapshot.docs.map((doc) {
        final data = doc.data();
        return Client(
          id: doc.id,
          name: data['imie_nazwisko'] ?? '', // Używamy imie_nazwisko z Firebase
          email: data['email'] ?? '',
          phone: data['telefon'] ?? '',
          address: '',
          pesel: data['pesel'] ?? '',
          companyName: data['nazwa_firmy'],
          type: ClientType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => ClientType.individual,
          ),
          notes: data['notes'] ?? '',
          votingStatus: VotingStatus.values.firstWhere(
            (e) => e.name == data['votingStatus'],
            orElse: () => VotingStatus.undecided,
          ),
          colorCode: data['colorCode'] ?? '#FFFFFF',
          unviableInvestments: List<String>.from(
            data['unviableInvestments'] ?? [],
          ),
          createdAt: data['created_at'] != null
              ? DateTime.parse(data['created_at'])
              : DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: data['isActive'] ?? true,
          additionalInfo: {
            'nazwa_firmy': data['nazwa_firmy'] ?? '',
            'source_file': data['source_file'] ?? 'Excel import',
          },
        );
      }).toList();

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

  // Update client with partial data
  Future<void> updateClientFields(
    String id,
    Map<String, dynamic> fields,
  ) async {
    try {
      await firestore.collection(_collection).doc(id).update({
        ...fields,
        'updatedAt': Timestamp.now(),
      });
      clearCache('all_clients');
    } catch (e) {
      logError('updateClientFields', e);
      throw Exception('Failed to update client fields: $e');
    }
  }

  // ===== NOWE METODY WYKORZYSTUJĄCE INDEKSY =====

  // Pobierz aktywnych klientów - wykorzystuje indeks isActive + imie_nazwisko
  Stream<List<Client>> getActiveClients({int limit = 100}) {
    return firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('imie_nazwisko')
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return Client(
              id: doc.id,
              name: data['imie_nazwisko'] ?? '',
              email: data['email'] ?? '',
              phone: data['telefon'] ?? '',
              address: '',
              pesel: data['pesel'] ?? '',
              createdAt: data['created_at'] != null
                  ? DateTime.parse(data['created_at'])
                  : DateTime.now(),
              updatedAt: DateTime.now(),
              isActive: data['isActive'] ?? true,
              additionalInfo: {
                'nazwa_firmy': data['nazwa_firmy'] ?? '',
                'source_file': data['source_file'] ?? 'Excel import',
              },
            );
          }).toList(),
        );
  }

  // Pobierz klientów według typu - wykorzystuje indeks type + imie_nazwisko
  Stream<List<Client>> getClientsByType(ClientType type, {int limit = 50}) {
    return firestore
        .collection(_collection)
        .where('type', isEqualTo: type.name)
        .orderBy('imie_nazwisko')
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return Client(
              id: doc.id,
              name: data['imie_nazwisko'] ?? '',
              email: data['email'] ?? '',
              phone: data['telefon'] ?? '',
              address: '',
              pesel: data['pesel'] ?? '',
              type: ClientType.values.firstWhere(
                (e) => e.name == data['type'],
                orElse: () => ClientType.individual,
              ),
              createdAt: data['created_at'] != null
                  ? DateTime.parse(data['created_at'])
                  : DateTime.now(),
              updatedAt: DateTime.now(),
              isActive: data['isActive'] ?? true,
              additionalInfo: {
                'nazwa_firmy': data['nazwa_firmy'] ?? '',
                'source_file': data['source_file'] ?? 'Excel import',
              },
            );
          }).toList(),
        );
  }

  // Pobierz klientów według statusu głosowania - wykorzystuje indeks votingStatus + updatedAt
  Stream<List<Client>> getClientsByVotingStatus(
    VotingStatus votingStatus, {
    int limit = 50,
  }) {
    return firestore
        .collection(_collection)
        .where('votingStatus', isEqualTo: votingStatus.name)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return Client(
              id: doc.id,
              name: data['imie_nazwisko'] ?? '',
              email: data['email'] ?? '',
              phone: data['telefon'] ?? '',
              address: '',
              pesel: data['pesel'] ?? '',
              type: ClientType.values.firstWhere(
                (e) => e.name == data['type'],
                orElse: () => ClientType.individual,
              ),
              votingStatus: VotingStatus.values.firstWhere(
                (e) => e.name == data['votingStatus'],
                orElse: () => VotingStatus.undecided,
              ),
              createdAt: data['created_at'] != null
                  ? DateTime.parse(data['created_at'])
                  : DateTime.now(),
              updatedAt: data['updatedAt'] != null
                  ? (data['updatedAt'] as Timestamp).toDate()
                  : DateTime.now(),
              isActive: data['isActive'] ?? true,
              additionalInfo: {
                'nazwa_firmy': data['nazwa_firmy'] ?? '',
                'source_file': data['source_file'] ?? 'Excel import',
              },
            );
          }).toList(),
        );
  }

  // Usuwam duplikat metody getClientsPaginated - zostaje ta z góry
}
