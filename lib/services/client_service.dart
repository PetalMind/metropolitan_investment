import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client.dart';

class ClientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'clients';

  // Create
  Future<String> createClient(Client client) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(client.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create client: $e');
    }
  }

  // Read
  Future<Client?> getClient(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Client.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get client: $e');
    }
  }

  // Read all - ZAKTUALIZOWANE dla danych z Excel
  Stream<List<Client>> getClients() {
    return _firestore
        .collection(_collection)
        .orderBy('imie_nazwisko')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            // Konwertuj dane z Excel do modelu Client
            return Client(
              id: doc.id,
              name: data['imie_nazwisko'] ?? '',
              email: data['email'] ?? '',
              phone: data['telefon'] ?? '',
              address: '', // Brak adresu w danych Excel
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

  // Search clients - ZAKTUALIZOWANE dla danych z Excel
  Stream<List<Client>> searchClients(String query) {
    if (query.isEmpty) return getClients();

    return _firestore
        .collection(_collection)
        .where('imie_nazwisko', isGreaterThanOrEqualTo: query)
        .where('imie_nazwisko', isLessThanOrEqualTo: query + '\uf8ff')
        .orderBy('imie_nazwisko')
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
      await _firestore
          .collection(_collection)
          .doc(id)
          .update(client.toFirestore());
    } catch (e) {
      throw Exception('Failed to update client: $e');
    }
  }

  // Delete (soft delete)
  Future<void> deleteClient(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to delete client: $e');
    }
  }

  // Hard delete
  Future<void> hardDeleteClient(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to hard delete client: $e');
    }
  }

  // Get clients count - ZAKTUALIZOWANE
  Future<int> getClientsCount() async {
    try {
      final snapshot = await _firestore.collection(_collection).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get clients count: $e');
    }
  }

  // NOWE METODY dla danych z Excel

  // Pobierz klientów z emailem
  Stream<List<Client>> getClientsWithEmail() {
    return _firestore
        .collection(_collection)
        .where('email', isNotEqualTo: '')
        .where('email', isNotEqualTo: 'brak')
        .orderBy('email')
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

  // Pobierz statystyki klientów
  Future<Map<String, dynamic>> getClientStats() async {
    try {
      final allClients = await _firestore.collection(_collection).get();

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
      print('Błąd pobierania statystyk klientów: $e');
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
  }

  // Get clients with pagination
  Future<List<Client>> getClientsPaginated({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Client.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get clients with pagination: $e');
    }
  }
}
