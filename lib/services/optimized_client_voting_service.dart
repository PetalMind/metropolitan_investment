import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';

/// Zoptymalizowany serwis do zarządzania statusem głosowania klientów
/// Zgodny z architekturą projektu i wzorcami Metropolitan Investment
class OptimizedClientVotingService extends BaseService {
  final String _collection = 'clients';

  /// Aktualizuje status głosowania klienta z pełną walidacją
  Future<void> updateVotingStatus(
    String clientId,
    VotingStatus newStatus, {
    String? updateReason,
  }) async {
    try {
      print(
        '🗳️ [VotingService] Aktualizacja statusu głosowania dla klienta: $clientId',
      );
      print(
        '🗳️ [VotingService] Nowy status: ${newStatus.displayName} (${newStatus.name})',
      );

      // Sprawdź czy klient istnieje
      final docRef = firestore.collection(_collection).doc(clientId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        throw Exception('Client with ID $clientId does not exist');
      }

      // Przygotuj dane do aktualizacji zgodnie z modelem Client
      final updateData = <String, dynamic>{
        'votingStatus': newStatus.name, // Zapisz jako enum name
        'updatedAt': Timestamp.now(),
      };

      // Dodaj powód aktualizacji do historii jeśli podano
      if (updateReason != null && updateReason.isNotEmpty) {
        updateData['lastVotingStatusUpdate'] = {
          'status': newStatus.name,
          'reason': updateReason,
          'timestamp': Timestamp.now(),
          'updatedBy': 'system', // TODO: Pobierz z AuthProvider
        };
      }

      // Wykonaj aktualizację
      await docRef.update(updateData);

      // Oczyść cache
      _clearVotingRelatedCache();

      print('✅ [VotingService] Pomyślnie zaktualizowano status głosowania');
    } catch (e) {
      print(
        '❌ [VotingService] Błąd podczas aktualizacji statusu głosowania: $e',
      );
      logError('updateVotingStatus', e);
      throw Exception('Failed to update voting status: $e');
    }
  }

  /// Aktualizuje multiple pól klienta włączając status głosowania
  /// Zgodne z wzorcem ClientForm
  Future<void> updateClientWithVoting(
    String clientId, {
    VotingStatus? votingStatus,
    String? notes,
    String? colorCode,
    ClientType? type,
    bool? isActive,
    String? updateReason,
  }) async {
    try {
      print('🔄 [VotingService] Kompletna aktualizacja klienta: $clientId');

      // Sprawdź czy klient istnieje
      final docRef = firestore.collection(_collection).doc(clientId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        throw Exception('Client with ID $clientId does not exist');
      }

      // Przygotuj dane do aktualizacji
      final updateData = <String, dynamic>{'updatedAt': Timestamp.now()};

      // Dodaj pola zgodnie z modelem Client.toFirestore()
      if (votingStatus != null) {
        updateData['votingStatus'] = votingStatus.name;
        print(
          '🗳️ [VotingService] Aktualizuję status głosowania: ${votingStatus.displayName}',
        );
      }

      if (notes != null) {
        updateData['notes'] = notes;
      }

      if (colorCode != null) {
        updateData['colorCode'] = colorCode;
      }

      if (type != null) {
        updateData['type'] = type.name;
      }

      if (isActive != null) {
        updateData['isActive'] = isActive;
      }

      // Dodaj historię zmian jeśli dotyczą statusu głosowania
      if (votingStatus != null &&
          updateReason != null &&
          updateReason.isNotEmpty) {
        updateData['lastVotingStatusUpdate'] = {
          'status': votingStatus.name,
          'reason': updateReason,
          'timestamp': Timestamp.now(),
          'updatedBy': 'system', // TODO: Pobierz z AuthProvider
        };
      }

      // Wykonaj aktualizację
      await docRef.update(updateData);

      // Oczyść cache
      _clearVotingRelatedCache();

      print('✅ [VotingService] Pomyślnie zaktualizowano dane klienta');
    } catch (e) {
      print('❌ [VotingService] Błąd podczas aktualizacji klienta: $e');
      logError('updateClientWithVoting', e);
      throw Exception('Failed to update client with voting data: $e');
    }
  }

  /// Pobiera klientów według statusu głosowania z cache
  Future<List<Client>> getClientsByVotingStatus(
    VotingStatus status, {
    int limit = 100,
  }) async {
    final cacheKey = 'clients_voting_${status.name}_$limit';

    return getCachedData(cacheKey, () async {
      try {
        print(
          '📊 [VotingService] Pobieranie klientów ze statusem: ${status.displayName}',
        );

        final query = firestore
            .collection(_collection)
            .where('votingStatus', isEqualTo: status.name)
            .orderBy('imie_nazwisko')
            .limit(limit);

        final snapshot = await query.get();

        final clients = snapshot.docs.map((doc) {
          return Client.fromFirestore(doc);
        }).toList();

        print(
          '📊 [VotingService] Znaleziono ${clients.length} klientów ze statusem ${status.displayName}',
        );
        return clients;
      } catch (e) {
        print(
          '❌ [VotingService] Błąd podczas pobierania klientów według statusu: $e',
        );
        logError('getClientsByVotingStatus', e);
        throw Exception('Failed to get clients by voting status: $e');
      }
    });
  }

  /// Pobiera statystyki głosowania z cache
  Future<Map<VotingStatus, int>> getVotingStatistics() async {
    return getCachedData('voting_statistics', () async {
      try {
        print('📊 [VotingService] Obliczanie statystyk głosowania...');

        final snapshot = await firestore.collection(_collection).get();

        final Map<VotingStatus, int> stats = {};

        // Inicjalizuj wszystkie statusy
        for (final status in VotingStatus.values) {
          stats[status] = 0;
        }

        // Policz wystąpienia
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final statusString = data['votingStatus'] as String?;

          if (statusString != null) {
            try {
              final status = VotingStatus.values.firstWhere(
                (s) => s.name == statusString,
                orElse: () => VotingStatus.undecided,
              );
              stats[status] = (stats[status] ?? 0) + 1;
            } catch (e) {
              // Jeśli nie można znaleźć statusu, traktuj jako undecided
              stats[VotingStatus.undecided] =
                  (stats[VotingStatus.undecided] ?? 0) + 1;
            }
          } else {
            // Brak statusu - traktuj jako undecided
            stats[VotingStatus.undecided] =
                (stats[VotingStatus.undecided] ?? 0) + 1;
          }
        }

        print('📊 [VotingService] Statystyki głosowania obliczone:');
        stats.forEach((status, count) {
          print('   ${status.displayName}: $count');
        });

        return stats;
      } catch (e) {
        print('❌ [VotingService] Błąd podczas obliczania statystyk: $e');
        logError('getVotingStatistics', e);
        throw Exception('Failed to calculate voting statistics: $e');
      }
    });
  }

  /// Aktualizuje status głosowania wielu klientów jednocześnie
  Future<void> bulkUpdateVotingStatus(
    Map<String, VotingStatus> clientStatusMap, {
    String? updateReason,
  }) async {
    try {
      print(
        '🔄 [VotingService] Masowa aktualizacja statusu głosowania dla ${clientStatusMap.length} klientów',
      );

      final batch = firestore.batch();

      for (final entry in clientStatusMap.entries) {
        final clientId = entry.key;
        final newStatus = entry.value;

        final docRef = firestore.collection(_collection).doc(clientId);

        final updateData = <String, dynamic>{
          'votingStatus': newStatus.name,
          'updatedAt': Timestamp.now(),
        };

        if (updateReason != null && updateReason.isNotEmpty) {
          updateData['lastVotingStatusUpdate'] = {
            'status': newStatus.name,
            'reason': updateReason,
            'timestamp': Timestamp.now(),
            'updatedBy': 'system', // TODO: Pobierz z AuthProvider
          };
        }

        batch.update(docRef, updateData);
      }

      await batch.commit();

      // Oczyść cache
      _clearVotingRelatedCache();

      print(
        '✅ [VotingService] Pomyślnie zaktualizowano status głosowania dla ${clientStatusMap.length} klientów',
      );
    } catch (e) {
      print('❌ [VotingService] Błąd podczas masowej aktualizacji: $e');
      logError('bulkUpdateVotingStatus', e);
      throw Exception('Failed to bulk update voting status: $e');
    }
  }

  /// Czyści cache związane z głosowaniem
  void _clearVotingRelatedCache() {
    // Wyczyść cache klientów
    clearCache('all_clients');
    clearCache('client_stats');
    clearCache('voting_statistics');

    // Wyczyść cache klientów według statusu głosowania
    for (final status in VotingStatus.values) {
      clearCache('clients_voting_${status.name}_100');
      clearCache('clients_voting_${status.name}_50');
    }

    // Wyczyść cache analityk inwestorów
    clearCache('investor_analytics');
    clearCache('majority_control');

    print(
      '🧹 [VotingService] Cache związane z głosowaniem zostały wyczyszczone',
    );
  }

  /// Waliduje poprawność statusu głosowania
  bool isValidVotingStatus(String? statusString) {
    if (statusString == null || statusString.isEmpty) {
      return false;
    }

    return VotingStatus.values.any((status) => status.name == statusString);
  }

  /// Konwertuje string na VotingStatus z fallback
  VotingStatus parseVotingStatus(String? statusString) {
    if (statusString == null || statusString.isEmpty) {
      return VotingStatus.undecided;
    }

    try {
      return VotingStatus.values.firstWhere(
        (status) => status.name == statusString,
        orElse: () => VotingStatus.undecided,
      );
    } catch (e) {
      print(
        '⚠️ [VotingService] Nie można sparsować statusu głosowania: $statusString',
      );
      return VotingStatus.undecided;
    }
  }

  /// Pobiera historię zmian statusu głosowania dla klienta
  Future<List<Map<String, dynamic>>> getVotingHistory(String clientId) async {
    try {
      final doc = await firestore.collection(_collection).doc(clientId).get();

      if (!doc.exists) {
        return [];
      }

      final data = doc.data() as Map<String, dynamic>;
      final history = data['votingStatusHistory'] as List<dynamic>?;

      if (history == null) {
        return [];
      }

      return history.cast<Map<String, dynamic>>();
    } catch (e) {
      print(
        '❌ [VotingService] Błąd podczas pobierania historii głosowania: $e',
      );
      logError('getVotingHistory', e);
      return [];
    }
  }
}
