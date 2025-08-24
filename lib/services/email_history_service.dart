import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';

/// Serwis do zarządzania historią wysłanych emaili
/// 
/// Zapewnia funkcjonalność:
/// - Pobieranie historii emaili dla konkretnego klienta
/// - Zapisywanie nowych wpisów historii
/// - Filtrowanie i sortowanie historii
/// - Cache z TTL dla optymalizacji wydajności
class EmailHistoryService extends BaseService {
  static const String _collectionName = 'email_history';
  
  /// Singleton pattern
  static final EmailHistoryService _instance = EmailHistoryService._internal();
  factory EmailHistoryService() => _instance;
  EmailHistoryService._internal();

  /// Pobiera historię emaili dla konkretnego klienta
  Future<List<EmailHistory>> getEmailHistoryForClient(String clientId) async {
    final cacheKey = 'email_history_client_$clientId';
    
    return await getCachedData<List<EmailHistory>>(
      cacheKey,
      () async {
        try {
          final query = FirebaseFirestore.instance
              .collection(_collectionName)
              .where('recipients', arrayContains: {
                'clientId': clientId,
              })
              .orderBy('sentAt', descending: true)
              .limit(50); // Limit do 50 ostatnich emaili

          final snapshot = await query.get();
          
          return snapshot.docs
              .map((doc) => EmailHistory.fromFirestore(doc))
              .toList();
              
        } catch (e) {
          logError('getEmailHistoryForClient', e);
          return <EmailHistory>[];
        }
      },
    ) ?? <EmailHistory>[];
  }

  /// Pobiera wszystkie historie emaili (dla administratorów)
  Future<List<EmailHistory>> getAllEmailHistory({
    int limit = 100,
    DateTime? since,
    EmailStatus? status,
  }) async {
    final cacheKey = 'all_email_history_${limit}_${since?.millisecondsSinceEpoch}_${status?.name}';
    
    return await getCachedData<List<EmailHistory>>(
      cacheKey,
      () async {
        try {
          Query query = FirebaseFirestore.instance
              .collection(_collectionName)
              .orderBy('sentAt', descending: true)
              .limit(limit);

          if (since != null) {
            query = query.where('sentAt', isGreaterThan: Timestamp.fromDate(since));
          }

          if (status != null) {
            query = query.where('status', isEqualTo: status.name);
          }

          final snapshot = await query.get();
          
          return snapshot.docs
              .map((doc) => EmailHistory.fromFirestore(doc))
              .toList();
              
        } catch (e) {
          logError('getAllEmailHistory', e);
          return <EmailHistory>[];
        }
      },
    ) ?? <EmailHistory>[];
  }

  /// Zapisuje nowy wpis historii emaila
  Future<String?> saveEmailHistory(EmailHistory emailHistory) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection(_collectionName)
          .add(emailHistory.toFirestore());

      // Invalidate cache dla klientów którzy otrzymali email
      for (final recipient in emailHistory.recipients) {
        invalidateCache('email_history_client_${recipient.clientId}');
      }
      
      // Invalidate general cache
      invalidateCachePattern('all_email_history_');
      
      logInfo('Zapisano historię emaila: ${docRef.id}');
      return docRef.id;
      
    } catch (e) {
      logError('saveEmailHistory', e);
      return null;
    }
  }

  /// Aktualizuje status doręczenia dla konkretnego odbiorcy
  Future<bool> updateDeliveryStatus(
    String emailHistoryId, 
    String clientId, 
    DeliveryStatus status, {
    String? error,
    String? messageId,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(emailHistoryId);

      // Pobierz dokument
      final doc = await docRef.get();
      if (!doc.exists) return false;

      final emailHistory = EmailHistory.fromFirestore(doc);
      
      // Znajdź i zaktualizuj odbiorce
      final updatedRecipients = emailHistory.recipients.map((recipient) {
        if (recipient.clientId == clientId) {
          return recipient.copyWith(
            deliveryStatus: status,
            deliveryError: error,
            messageId: messageId,
            deliveredAt: status == DeliveryStatus.delivered ? DateTime.now() : null,
          );
        }
        return recipient;
      }).toList();

      // Zaktualizuj dokument
      await docRef.update({
        'recipients': updatedRecipients.map((r) => r.toJson()).toList(),
      });

      // Invalidate cache
      invalidateCache('email_history_client_$clientId');
      invalidateCachePattern('all_email_history_');
      
      logInfo('Zaktualizowano status doręczenia dla klienta $clientId');
      return true;
      
    } catch (e) {
      logError('updateDeliveryStatus', e);
      return false;
    }
  }

  /// Pobiera statystyki emaili dla klienta
  Future<EmailClientStatistics> getEmailStatisticsForClient(String clientId) async {
    final cacheKey = 'email_stats_client_$clientId';
    
    return await getCachedData<EmailClientStatistics>(
      cacheKey,
      () async {
        try {
          final emailHistory = await getEmailHistoryForClient(clientId);
          
          final totalEmails = emailHistory.length;
          final successfulEmails = emailHistory.where((e) => e.status == EmailStatus.sent).length;
          final failedEmails = emailHistory.where((e) => e.status == EmailStatus.failed).length;
          
          final lastEmailDate = emailHistory.isNotEmpty ? emailHistory.first.sentAt : null;
          
          final totalRecipients = emailHistory.fold<int>(0, (sum, email) => sum + email.recipients.length);
          final deliveredRecipients = emailHistory.fold<int>(0, (sum, email) => 
            sum + email.recipients.where((r) => r.deliveryStatus == DeliveryStatus.delivered).length);
          
          return EmailClientStatistics(
            clientId: clientId,
            totalEmails: totalEmails,
            successfulEmails: successfulEmails,
            failedEmails: failedEmails,
            lastEmailDate: lastEmailDate,
            totalRecipients: totalRecipients,
            deliveredRecipients: deliveredRecipients,
            deliveryRate: totalRecipients > 0 ? (deliveredRecipients / totalRecipients) * 100 : 0.0,
          );
          
        } catch (e) {
          logError('getClientStatistics', e);
          return EmailClientStatistics.empty(clientId);
        }
      },
    ) ?? EmailClientStatistics.empty(clientId);
  }

  /// Usuwa stare wpisy historii (dla maintenance)
  Future<int> cleanupOldHistory({required Duration olderThan}) async {
    try {
      final cutoffDate = DateTime.now().subtract(olderThan);
      
      final query = FirebaseFirestore.instance
          .collection(_collectionName)
          .where('sentAt', isLessThan: Timestamp.fromDate(cutoffDate));

      final snapshot = await query.get();
      
      int deletedCount = 0;
      final batch = FirebaseFirestore.instance.batch();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        deletedCount++;
      }
      
      if (deletedCount > 0) {
        await batch.commit();
        
        // Clear all cache
        clearAllCache();
        
        logInfo('Usunięto $deletedCount starych wpisów historii emaili');
      }
      
      return deletedCount;
      
    } catch (e) {
      logError('cleanOldHistory', e);
      return 0;
    }
  }
}

/// Statystyki emaili dla klienta
class EmailClientStatistics {
  final String clientId;
  final int totalEmails;
  final int successfulEmails;
  final int failedEmails;
  final DateTime? lastEmailDate;
  final int totalRecipients;
  final int deliveredRecipients;
  final double deliveryRate;

  const EmailClientStatistics({
    required this.clientId,
    required this.totalEmails,
    required this.successfulEmails,
    required this.failedEmails,
    this.lastEmailDate,
    required this.totalRecipients,
    required this.deliveredRecipients,
    required this.deliveryRate,
  });

  factory EmailClientStatistics.empty(String clientId) {
    return EmailClientStatistics(
      clientId: clientId,
      totalEmails: 0,
      successfulEmails: 0,
      failedEmails: 0,
      lastEmailDate: null,
      totalRecipients: 0,
      deliveredRecipients: 0,
      deliveryRate: 0.0,
    );
  }

  bool get hasEmailHistory => totalEmails > 0;
  
  String get formattedDeliveryRate => '${deliveryRate.toStringAsFixed(1)}%';
  
  String get lastEmailAgo {
    if (lastEmailDate == null) return 'Nigdy';
    
    final now = DateTime.now();
    final difference = now.difference(lastEmailDate!);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} dni temu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} godzin temu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minut temu';
    } else {
      return 'Przed chwilą';
    }
  }
}