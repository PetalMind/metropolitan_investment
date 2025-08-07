import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/voting_status_change.dart';
import '../models/client.dart';
import 'base_service.dart';
import 'client_service.dart';

/// Enhanced service for voting status changes with optimized performance,
/// transaction-based operations, and comprehensive error handling
class EnhancedVotingStatusService extends BaseService {
  static const String _collection = 'voting_status_changes';
  static const String _clientsCollection = 'clients';

  final ClientService _clientService = ClientService();

  // Cache for recently accessed clients to reduce Firebase reads
  final Map<String, Client> _clientCache = {};
  static const Duration _cacheTimeout = Duration(minutes: 5);
  DateTime? _lastCacheCleared;

  /// Optimized method to update voting status with atomic transaction
  /// and comprehensive change tracking
  Future<VotingStatusChangeResult> updateVotingStatusWithHistory(
    String clientId,
    VotingStatus newStatus, {
    String? reason,
    Map<String, dynamic>? additionalChanges,
  }) async {
    final startTime = DateTime.now();

    try {
      // Get current user info
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw VotingStatusException('Użytkownik nie jest zalogowany');
      }

      // Get current client data (with caching for performance)
      final currentClient = await _getCachedClient(clientId);
      if (currentClient == null) {
        throw VotingStatusException('Nie znaleziono klienta o ID: $clientId');
      }

      final previousStatus = currentClient.votingStatus;

      // Early return if no change needed
      if (previousStatus == newStatus) {
        return VotingStatusChangeResult.noChange(
          clientId: clientId,
          clientName: currentClient.name,
          status: newStatus,
        );
      }

      // Perform atomic transaction
      final result = await _performVotingStatusTransaction(
        clientId: clientId,
        currentClient: currentClient,
        previousStatus: previousStatus,
        newStatus: newStatus,
        reason: reason,
        additionalChanges: additionalChanges,
        user: user,
      );

      // Update cache
      _updateClientCache(
        clientId,
        currentClient.copyWith(votingStatus: newStatus),
      );

      // Clear analytics cache for consistency
      _clearRelatedCaches();

      final duration = DateTime.now().difference(startTime);
      print(
        '✅ [EnhancedVoting] Status updated in ${duration.inMilliseconds}ms for ${currentClient.name}',
      );

      return result;
    } catch (e) {
      print('❌ [EnhancedVoting] Error updating voting status: $e');
      logError('updateVotingStatusWithHistory', e);

      if (e is VotingStatusException) {
        rethrow;
      }

      throw VotingStatusException('Błąd aktualizacji statusu głosowania: $e');
    }
  }

  /// Atomic Firebase transaction for voting status update and history recording
  Future<VotingStatusChangeResult> _performVotingStatusTransaction({
    required String clientId,
    required Client currentClient,
    required VotingStatus previousStatus,
    required VotingStatus newStatus,
    required String? reason,
    required Map<String, dynamic>? additionalChanges,
    required User user,
  }) async {
    return await FirebaseFirestore.instance.runTransaction<
      VotingStatusChangeResult
    >((transaction) async {
      final clientRef = FirebaseFirestore.instance
          .collection(_clientsCollection)
          .doc(clientId);

      final changesRef = FirebaseFirestore.instance
          .collection(_collection)
          .doc(); // Auto-generate ID

      // Verify client still exists and hasn't been modified
      final clientDoc = await transaction.get(clientRef);
      if (!clientDoc.exists) {
        throw VotingStatusException(
          'Klient został usunięty podczas aktualizacji',
        );
      }

      final currentData = clientDoc.data() as Map<String, dynamic>;
      final currentVotingStatus = VotingStatus.values.firstWhere(
        (e) => e.name == currentData['votingStatus'],
        orElse: () => VotingStatus.undecided,
      );

      // Check for concurrent modifications
      if (currentVotingStatus != previousStatus) {
        throw VotingStatusException(
          'Status głosowania został zmieniony przez innego użytkownika. Odśwież stronę i spróbuj ponownie.',
        );
      }

      // Update client voting status
      transaction.update(clientRef, {
        'votingStatus': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create change record
      final change = VotingStatusChange(
        id: changesRef.id,
        investorId: clientId,
        clientId: clientId,
        clientName: currentClient.name,
        previousVotingStatus: previousStatus.displayName,
        newVotingStatus: newStatus.displayName,
        changeType: VotingStatusChangeType.statusChanged,
        editedBy: user.displayName ?? user.email ?? 'Nieznany użytkownik',
        editedByEmail: user.email ?? 'brak@email.com',
        changedAt: DateTime.now(),
        additionalChanges: additionalChanges,
        reason: reason,
      );

      transaction.set(changesRef, change.toFirestore());

      return VotingStatusChangeResult.success(
        clientId: clientId,
        clientName: currentClient.name,
        previousStatus: previousStatus,
        newStatus: newStatus,
        changeId: changesRef.id,
      );
    }, timeout: const Duration(seconds: 10));
  }

  /// Batch update multiple clients' voting status with transaction safety
  Future<BatchVotingStatusResult> updateMultipleVotingStatuses(
    List<VotingStatusUpdate> updates, {
    String? batchReason,
  }) async {
    if (updates.isEmpty) {
      return BatchVotingStatusResult.empty();
    }

    final results = <VotingStatusChangeResult>[];
    final errors = <String, String>{};

    // Process in chunks to avoid transaction limits
    const chunkSize =
        10; // Firestore transaction limit is 500 operations, but we're being conservative

    for (int i = 0; i < updates.length; i += chunkSize) {
      final chunk = updates.skip(i).take(chunkSize).toList();

      try {
        final chunkResults = await _processBatchChunk(chunk, batchReason);
        results.addAll(chunkResults);
      } catch (e) {
        // If chunk fails, try individual updates to isolate failures
        for (final update in chunk) {
          try {
            final result = await updateVotingStatusWithHistory(
              update.clientId,
              update.newStatus,
              reason: update.reason ?? batchReason,
              additionalChanges: update.additionalChanges,
            );
            results.add(result);
          } catch (error) {
            errors[update.clientId] = error.toString();
          }
        }
      }
    }

    return BatchVotingStatusResult(
      totalUpdates: updates.length,
      successfulUpdates: results.where((r) => r.isSuccess).length,
      failedUpdates: errors.length,
      results: results,
      errors: errors,
    );
  }

  /// Process a chunk of voting status updates in a single transaction
  Future<List<VotingStatusChangeResult>> _processBatchChunk(
    List<VotingStatusUpdate> chunk,
    String? batchReason,
  ) async {
    return await FirebaseFirestore.instance
        .runTransaction<List<VotingStatusChangeResult>>((transaction) async {
          final results = <VotingStatusChangeResult>[];
          final user = FirebaseAuth.instance.currentUser;

          if (user == null) {
            throw VotingStatusException('Użytkownik nie jest zalogowany');
          }

          for (final update in chunk) {
            try {
              // Get client data
              final clientRef = FirebaseFirestore.instance
                  .collection(_clientsCollection)
                  .doc(update.clientId);

              final clientDoc = await transaction.get(clientRef);
              if (!clientDoc.exists) {
                results.add(
                  VotingStatusChangeResult.error(
                    clientId: update.clientId,
                    error: 'Klient nie istnieje',
                  ),
                );
                continue;
              }

              final client = Client.fromFirestore(clientDoc);
              final previousStatus = client.votingStatus;

              // Skip if no change needed
              if (previousStatus == update.newStatus) {
                results.add(
                  VotingStatusChangeResult.noChange(
                    clientId: update.clientId,
                    clientName: client.name,
                    status: update.newStatus,
                  ),
                );
                continue;
              }

              // Update client
              transaction.update(clientRef, {
                'votingStatus': update.newStatus.name,
                'updatedAt': FieldValue.serverTimestamp(),
              });

              // Create change record
              final changesRef = FirebaseFirestore.instance
                  .collection(_collection)
                  .doc();

              final change = VotingStatusChange(
                id: changesRef.id,
                investorId: update.clientId,
                clientId: update.clientId,
                clientName: client.name,
                previousVotingStatus: previousStatus.displayName,
                newVotingStatus: update.newStatus.displayName,
                changeType: VotingStatusChangeType.statusChanged,
                editedBy:
                    user.displayName ?? user.email ?? 'Nieznany użytkownik',
                editedByEmail: user.email ?? 'brak@email.com',
                changedAt: DateTime.now(),
                additionalChanges: update.additionalChanges,
                reason: update.reason ?? batchReason,
              );

              transaction.set(changesRef, change.toFirestore());

              results.add(
                VotingStatusChangeResult.success(
                  clientId: update.clientId,
                  clientName: client.name,
                  previousStatus: previousStatus,
                  newStatus: update.newStatus,
                  changeId: changesRef.id,
                ),
              );
            } catch (e) {
              results.add(
                VotingStatusChangeResult.error(
                  clientId: update.clientId,
                  error: e.toString(),
                ),
              );
            }
          }

          return results;
        }, timeout: const Duration(seconds: 30));
  }

  /// Get client with caching for improved performance
  Future<Client?> _getCachedClient(String clientId) async {
    // Check cache first
    if (_clientCache.containsKey(clientId) && _isCacheValid()) {
      return _clientCache[clientId];
    }

    // Fetch from database
    final client = await _clientService.getClient(clientId);
    if (client != null) {
      _updateClientCache(clientId, client);
    }

    return client;
  }

  /// Update client in cache
  void _updateClientCache(String clientId, Client client) {
    _clientCache[clientId] = client;
    _lastCacheCleared = DateTime.now();
  }

  /// Check if cache is still valid
  bool _isCacheValid() {
    if (_lastCacheCleared == null) return false;
    return DateTime.now().difference(_lastCacheCleared!) < _cacheTimeout;
  }

  /// Clear related caches to maintain consistency
  void _clearRelatedCaches() {
    _clientCache.clear();
    clearCache('analytics');
    clearCache('clients');
    clearCache('voting_status_changes');
  }

  /// Get voting status history with optimized pagination
  Future<List<VotingStatusChange>> getVotingStatusHistory(
    String investorId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection(_collection)
          .where('investorId', isEqualTo: investorId)
          .orderBy('changedAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();

      final changes = <VotingStatusChange>[];
      for (int i = 0; i < querySnapshot.docs.length; i++) {
        final doc = querySnapshot.docs[i];
        try {
          final change = VotingStatusChange.fromFirestore(doc);
          changes.add(change);
        } catch (e) {
          print('❌ [EnhancedVoting] Failed to parse document ${doc.id}: $e');
          print('   Raw data: ${doc.data()}');
        }
      }

      return changes;
    } catch (e) {
      print(
        '❌ [EnhancedVoting] Błąd pobierania historii zmian dla $investorId: $e',
      );
      logError('getVotingStatusHistory', e);
      return [];
    }
  }

  /// Get recent changes with advanced filtering
  Future<List<VotingStatusChange>> getRecentChanges({
    int limit = 50,
    DateTime? since,
    List<VotingStatusChangeType>? changeTypes,
    List<String>? userEmails,
  }) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection(_collection)
          .orderBy('changedAt', descending: true);

      if (since != null) {
        query = query.where(
          'changedAt',
          isGreaterThan: Timestamp.fromDate(since),
        );
      }

      if (changeTypes != null && changeTypes.isNotEmpty) {
        query = query.where(
          'changeType',
          whereIn: changeTypes.map((e) => e.name).toList(),
        );
      }

      if (userEmails != null && userEmails.isNotEmpty) {
        query = query.where('editedByEmail', whereIn: userEmails);
      }

      final querySnapshot = await query.limit(limit).get();
      return querySnapshot.docs
          .map((doc) => VotingStatusChange.fromFirestore(doc))
          .toList();
    } catch (e) {
      logError('getRecentChanges', e);
      return [];
    }
  }

  /// Get comprehensive statistics with caching
  Future<VotingStatusStatistics> getStatistics({
    DateTime? fromDate,
    DateTime? toDate,
    bool useCache = true,
  }) async {
    final cacheKey =
        'voting_stats_${fromDate?.millisecondsSinceEpoch}_${toDate?.millisecondsSinceEpoch}';

    if (useCache) {
      return await getCachedData<VotingStatusStatistics>(cacheKey, () async {
        return await _fetchStatistics(fromDate, toDate);
      });
    } else {
      return await _fetchStatistics(fromDate, toDate);
    }
  }

  /// Internal method to fetch statistics from Firebase
  Future<VotingStatusStatistics> _fetchStatistics(
    DateTime? fromDate,
    DateTime? toDate,
  ) async {
    try {
      Query query = FirebaseFirestore.instance.collection(_collection);

      if (fromDate != null) {
        query = query.where(
          'changedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate),
        );
      }

      if (toDate != null) {
        query = query.where(
          'changedAt',
          isLessThanOrEqualTo: Timestamp.fromDate(toDate),
        );
      }

      final querySnapshot = await query.get();
      final changes = querySnapshot.docs
          .map((doc) => VotingStatusChange.fromFirestore(doc))
          .toList();

      return VotingStatusStatistics.fromChanges(changes, fromDate, toDate);
    } catch (e) {
      logError('_fetchStatistics', e);
      return VotingStatusStatistics.empty();
    }
  }

  @override
  void clearCache(String key) {
    super.clearCache(key);
    if (key == 'all' || key.contains('client')) {
      _clientCache.clear();
    }
  }
}

/// Custom exception for voting status operations
class VotingStatusException implements Exception {
  final String message;
  const VotingStatusException(this.message);

  @override
  String toString() => 'VotingStatusException: $message';
}

/// Result of a voting status change operation
class VotingStatusChangeResult {
  final String clientId;
  final String clientName;
  final VotingStatus? previousStatus;
  final VotingStatus newStatus;
  final String? changeId;
  final String? error;
  final bool isSuccess;
  final bool hasChanged;

  const VotingStatusChangeResult._({
    required this.clientId,
    required this.clientName,
    this.previousStatus,
    required this.newStatus,
    this.changeId,
    this.error,
    required this.isSuccess,
    required this.hasChanged,
  });

  factory VotingStatusChangeResult.success({
    required String clientId,
    required String clientName,
    required VotingStatus previousStatus,
    required VotingStatus newStatus,
    required String changeId,
  }) {
    return VotingStatusChangeResult._(
      clientId: clientId,
      clientName: clientName,
      previousStatus: previousStatus,
      newStatus: newStatus,
      changeId: changeId,
      isSuccess: true,
      hasChanged: true,
    );
  }

  factory VotingStatusChangeResult.noChange({
    required String clientId,
    required String clientName,
    required VotingStatus status,
  }) {
    return VotingStatusChangeResult._(
      clientId: clientId,
      clientName: clientName,
      newStatus: status,
      isSuccess: true,
      hasChanged: false,
    );
  }

  factory VotingStatusChangeResult.error({
    required String clientId,
    required String error,
    String? clientName,
  }) {
    return VotingStatusChangeResult._(
      clientId: clientId,
      clientName: clientName ?? 'Unknown',
      newStatus: VotingStatus.undecided,
      error: error,
      isSuccess: false,
      hasChanged: false,
    );
  }
}

/// Update data for voting status
class VotingStatusUpdate {
  final String clientId;
  final VotingStatus newStatus;
  final String? reason;
  final Map<String, dynamic>? additionalChanges;

  const VotingStatusUpdate({
    required this.clientId,
    required this.newStatus,
    this.reason,
    this.additionalChanges,
  });
}

/// Result of batch voting status updates
class BatchVotingStatusResult {
  final int totalUpdates;
  final int successfulUpdates;
  final int failedUpdates;
  final List<VotingStatusChangeResult> results;
  final Map<String, String> errors;

  const BatchVotingStatusResult({
    required this.totalUpdates,
    required this.successfulUpdates,
    required this.failedUpdates,
    required this.results,
    required this.errors,
  });

  factory BatchVotingStatusResult.empty() {
    return const BatchVotingStatusResult(
      totalUpdates: 0,
      successfulUpdates: 0,
      failedUpdates: 0,
      results: [],
      errors: {},
    );
  }

  bool get hasErrors => failedUpdates > 0;
  bool get isCompleteSuccess => failedUpdates == 0 && totalUpdates > 0;
  double get successRate =>
      totalUpdates > 0 ? successfulUpdates / totalUpdates : 0.0;
}

/// Comprehensive statistics for voting status changes
class VotingStatusStatistics {
  final int totalChanges;
  final Map<VotingStatusChangeType, int> changesByType;
  final Map<String, int> changesByUser;
  final Map<String, int> changesByStatus;
  final Map<String, int> changesByDay;
  final DateTime? fromDate;
  final DateTime? toDate;
  final DateTime generatedAt;

  const VotingStatusStatistics({
    required this.totalChanges,
    required this.changesByType,
    required this.changesByUser,
    required this.changesByStatus,
    required this.changesByDay,
    this.fromDate,
    this.toDate,
    required this.generatedAt,
  });

  factory VotingStatusStatistics.fromChanges(
    List<VotingStatusChange> changes,
    DateTime? fromDate,
    DateTime? toDate,
  ) {
    final changesByType = <VotingStatusChangeType, int>{};
    final changesByUser = <String, int>{};
    final changesByStatus = <String, int>{};
    final changesByDay = <String, int>{};

    for (final change in changes) {
      // Count by type
      changesByType[change.changeType] =
          (changesByType[change.changeType] ?? 0) + 1;

      // Count by user
      changesByUser[change.editedBy] =
          (changesByUser[change.editedBy] ?? 0) + 1;

      // Count by new status
      if (change.newVotingStatus != null) {
        changesByStatus[change.newVotingStatus!] =
            (changesByStatus[change.newVotingStatus!] ?? 0) + 1;
      }

      // Count by day
      final dayKey =
          '${change.changedAt.year}-${change.changedAt.month.toString().padLeft(2, '0')}-${change.changedAt.day.toString().padLeft(2, '0')}';
      changesByDay[dayKey] = (changesByDay[dayKey] ?? 0) + 1;
    }

    return VotingStatusStatistics(
      totalChanges: changes.length,
      changesByType: changesByType,
      changesByUser: changesByUser,
      changesByStatus: changesByStatus,
      changesByDay: changesByDay,
      fromDate: fromDate,
      toDate: toDate,
      generatedAt: DateTime.now(),
    );
  }

  factory VotingStatusStatistics.empty() {
    return VotingStatusStatistics(
      totalChanges: 0,
      changesByType: {},
      changesByUser: {},
      changesByStatus: {},
      changesByDay: {},
      generatedAt: DateTime.now(),
    );
  }
}
