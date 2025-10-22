import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';

/// 📅 EMAIL SCHEDULING SERVICE - PLANOWANIE WYSYŁEK Z OPÓŹNIENIEM
///
/// Główne funkcjonalności:
/// - Planowanie wysyłki emaili na konkretną datę i godzinę
/// - Zarządzanie kolejką zaplanowanych emaili
/// - Anulowanie zaplanowanych wysyłek
/// - Monitorowanie statusu wysyłek
/// - Integracja z Firebase Firestore do persystencji
/// - Automatyczne uruchamianie wysyłek w tle
///
/// Obsługiwane opcje planowania:
/// - Wysyłka za X minut/godzin/dni
/// - Wysyłka w konkretną datę i godzinę
/// - Wysyłka cykliczna (opcjonalne w przyszłości)
/// - Strefa czasowa użytkownika
class EmailSchedulingService {
  static const String _collectionName = 'scheduled_emails';
  static const String _logTag = 'EmailSchedulingService';

  final FirebaseFirestore _firestore;
  final EmailAndExportService _emailService;

  EmailSchedulingService({
    FirebaseFirestore? firestore,
    EmailAndExportService? emailService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _emailService = emailService ?? EmailAndExportService();

  /// Uruchom serwis - sprawdź Cloud Functions deployment
  void start() {
    // UWAGA: Background processing zostało przeniesione do Cloud Functions
    // Funkcja processScheduledEmails uruchamia się automatycznie co minutę
    
    // Nie uruchamiamy już lokalnego timera - Cloud Functions zajmuje się tym
    // _backgroundTimer = Timer.periodic(...) // USUNIĘTE
  }

  /// Zatrzymaj serwis
  void stop() {
    // Background timer już nie jest używany - Cloud Functions zajmuje się przetwarzaniem
  }

  /// Zaplanuj wysyłkę emaila
  Future<String> scheduleEmail({
    required List<InvestorSummary> recipients,
    required String subject,
    required String htmlContent,
    required DateTime scheduledDateTime,
    required String senderEmail,
    required String senderName,
    bool includeInvestmentDetails = true,
    Map<String, String>? additionalRecipients,
    String? notes,
    String? createdBy,
  }) async {
    try {
      // Walidacja daty
      if (scheduledDateTime.isBefore(DateTime.now())) {
        throw ArgumentError('Scheduled date must be in the future');
      }

      // Walidacja recipientów
      if (recipients.isEmpty &&
          (additionalRecipients == null || additionalRecipients.isEmpty)) {
        throw ArgumentError('Lista odbiorców nie może być pusta');
      }

      // Tworzenie dokumentu zaplanowanego emaila
      final scheduledEmail = ScheduledEmail(
        id: '', // Będzie wygenerowane przez Firestore
        recipients: recipients,
        subject: subject,
        htmlContent: htmlContent,
        scheduledDateTime: scheduledDateTime,
        senderEmail: senderEmail,
        senderName: senderName,
        includeInvestmentDetails: includeInvestmentDetails,
        additionalRecipients: additionalRecipients ?? {},
        status: ScheduledEmailStatus.pending,
        createdAt: DateTime.now(),
        createdBy: createdBy ?? 'unknown',
        notes: notes,
      );

      // Zapisz do Firestore
      final docRef = await _firestore
          .collection(_collectionName)
          .add(scheduledEmail.toMap());

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Pobierz wszystkie zaplanowane emaile
  Stream<List<ScheduledEmail>> getScheduledEmailsStream({
    ScheduledEmailStatus? status,
    int limit = 50,
  }) {
    Query query = _firestore
        .collection(_collectionName)
        .orderBy('scheduledDateTime', descending: false);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    if (limit > 0) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ScheduledEmail.fromMap(data, doc.id);
      }).toList();
    });
  }

  /// Pobierz zaplanowane emaile dla konkretnego użytkownika
  Stream<List<ScheduledEmail>> getScheduledEmailsForUser(
    String userId, {
    int limit = 20,
  }) {
    return _firestore
        .collection(_collectionName)
        .where('createdBy', isEqualTo: userId)
        .orderBy('scheduledDateTime', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return ScheduledEmail.fromMap(data, doc.id);
          }).toList();
        });
  }

  /// Anuluj zaplanowany email
  Future<void> cancelScheduledEmail(String emailId) async {
    try {
      await _firestore.collection(_collectionName).doc(emailId).update({
        'status': ScheduledEmailStatus.cancelled.name,
        'cancelledAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      rethrow;
    }
  }

  /// Edytuj zaplanowany email (tylko jeśli jeszcze nie został wysłany)
  Future<void> updateScheduledEmail(
    String emailId, {
    DateTime? newScheduledDateTime,
    String? newSubject,
    String? newHtmlContent,
    String? newNotes,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (newScheduledDateTime != null) {
        if (newScheduledDateTime.isBefore(DateTime.now())) {
          throw ArgumentError('New scheduled date must be in the future');
        }
        updates['scheduledDateTime'] = Timestamp.fromDate(newScheduledDateTime);
      }

      if (newSubject != null) {
        updates['subject'] = newSubject;
      }

      if (newHtmlContent != null) {
        updates['htmlContent'] = newHtmlContent;
      }

      if (newNotes != null) {
        updates['notes'] = newNotes;
      }

      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();

        await _firestore
            .collection(_collectionName)
            .doc(emailId)
            .update(updates);

      }
    } catch (e) {
      rethrow;
    }
  }

  /// Przetwarzaj zaplanowane emaile - główna logika wysyłania
  Future<void> _processScheduledEmails() async {
    try {
      final now = DateTime.now();

      // Pobierz emaile gotowe do wysłania
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: ScheduledEmailStatus.pending.name)
          .where(
            'scheduledDateTime',
            isLessThanOrEqualTo: Timestamp.fromDate(now),
          )
          .limit(10) // Przetwarzaj maksymalnie 10 na raz
          .get();

      if (querySnapshot.docs.isEmpty) {
        return; // Brak emaili do wysłania
      }

      for (final doc in querySnapshot.docs) {
        await _processScheduledEmail(doc.id, doc.data());
      }
    } catch (e) {
    }
  }

  /// Przetwórz pojedynczy zaplanowany email
  Future<void> _processScheduledEmail(
    String emailId,
    Map<String, dynamic> data,
  ) async {
    try {
      final scheduledEmail = ScheduledEmail.fromMap(data, emailId);

      // Walidacja recipientów przed wysłaniem
      if (scheduledEmail.recipients.isEmpty) {
        await _updateEmailStatus(
          emailId,
          ScheduledEmailStatus.failed,
          errorMessage: 'Brak odbiorców - email nie może zostać wysłany',
        );
        return;
      }

      // Oznacz jako wysyłany
      await _updateEmailStatus(emailId, ScheduledEmailStatus.sending);

      // Wyślij email przez EmailAndExportService - używamy nowej metody dla spójności
      final additionalEmails = scheduledEmail.additionalRecipients.keys.toList();
      final results = await _emailService.sendCustomEmailsToMixedRecipients(
        investors: scheduledEmail.recipients,
        additionalEmails: additionalEmails,
        subject: scheduledEmail.subject,
        htmlContent: scheduledEmail.htmlContent,
        senderEmail: scheduledEmail.senderEmail,
        senderName: scheduledEmail.senderName,
        includeInvestmentDetails: scheduledEmail.includeInvestmentDetails,
        isGroupEmail: true, // Zaplanowane emaile są domyślnie grupowe
      );

      // Sprawdź wyniki wysyłki
      final hasErrors = results.any((result) => !result.success);
      final successCount = results.where((result) => result.success).length;
      final totalCount = results.length;

      // Zapisz wyniki
      await _updateEmailStatus(
        emailId,
        hasErrors
            ? ScheduledEmailStatus.partiallyFailed
            : ScheduledEmailStatus.sent,
        sentAt: DateTime.now(),
        results: results,
        successCount: successCount,
        totalCount: totalCount,
      );

      // Odtwórz dźwięk sukcesu (opcjonalne)
      if (!hasErrors) {
        // Audio is optional
      }

    } catch (e) {
      // Oznacz jako nieudany
      await _updateEmailStatus(
        emailId,
        ScheduledEmailStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  /// Aktualizuj status emaila
  Future<void> _updateEmailStatus(
    String emailId,
    ScheduledEmailStatus status, {
    DateTime? sentAt,
    List<EmailSendResult>? results,
    int? successCount,
    int? totalCount,
    String? errorMessage,
  }) async {
    final Map<String, dynamic> updates = {
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (sentAt != null) {
      updates['sentAt'] = Timestamp.fromDate(sentAt);
    }

    if (results != null) {
      updates['sendResultsCount'] = results.length;
    }

    if (successCount != null) {
      updates['successCount'] = successCount;
    }

    if (totalCount != null) {
      updates['totalCount'] = totalCount;
    }

    if (errorMessage != null) {
      updates['errorMessage'] = errorMessage;
    }

    await _firestore.collection(_collectionName).doc(emailId).update(updates);
  }

  /// Pobierz statystyki zaplanowanych emaili
  Future<SchedulingStatistics> getStatistics({String? userId}) async {
    Query query = _firestore.collection(_collectionName);

    if (userId != null) {
      query = query.where('createdBy', isEqualTo: userId);
    }

    final snapshot = await query.get();

    int pending = 0;
    int sent = 0;
    int failed = 0;
    int cancelled = 0;

    for (final doc in snapshot.docs) {
      final status = (doc.data() as Map<String, dynamic>)['status'] as String?;
      switch (status) {
        case 'pending':
          pending++;
          break;
        case 'sent':
          sent++;
          break;
        case 'failed':
        case 'partiallyFailed':
          failed++;
          break;
        case 'cancelled':
          cancelled++;
          break;
      }
    }

    return SchedulingStatistics(
      totalScheduled: snapshot.docs.length,
      pending: pending,
      sent: sent,
      failed: failed,
      cancelled: cancelled,
    );
  }

  /// Usuń stare zaplanowane emaile (cleanup)
  Future<void> cleanupOldEmails({
    Duration olderThan = const Duration(days: 30),
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(olderThan);

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .where('status', whereIn: ['sent', 'failed', 'cancelled'])
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

    } catch (e) {
    }
  }

  /// Helper: Stwórz quick schedule options
  static List<ScheduleOption> getQuickScheduleOptions() {
    final now = DateTime.now();

    return [
      ScheduleOption(
        label: 'Za 5 minut',
        dateTime: now.add(const Duration(minutes: 5)),
        icon: '⏰',
      ),
      ScheduleOption(
        label: 'Za 15 minut',
        dateTime: now.add(const Duration(minutes: 15)),
        icon: '⏰',
      ),
      ScheduleOption(
        label: 'Za 30 minut',
        dateTime: now.add(const Duration(minutes: 30)),
        icon: '⏰',
      ),
      ScheduleOption(
        label: 'Za 1 godzinę',
        dateTime: now.add(const Duration(hours: 1)),
        icon: '🕐',
      ),
      ScheduleOption(
        label: 'Za 2 godziny',
        dateTime: now.add(const Duration(hours: 2)),
        icon: '🕑',
      ),
      ScheduleOption(
        label: 'Jutro o 9:00',
        dateTime: DateTime(now.year, now.month, now.day + 1, 9, 0),
        icon: '🌅',
      ),
      ScheduleOption(
        label: 'Jutro o 14:00',
        dateTime: DateTime(now.year, now.month, now.day + 1, 14, 0),
        icon: '🕐',
      ),
      ScheduleOption(
        label: 'W poniedziałek o 9:00',
        dateTime: _getNextWeekday(now, DateTime.monday, 9, 0),
        icon: '📅',
      ),
    ];
  }

  /// Helper: Pobierz następny dzień tygodnia
  static DateTime _getNextWeekday(
    DateTime from,
    int weekday,
    int hour,
    int minute,
  ) {
    int daysToAdd = weekday - from.weekday;
    if (daysToAdd <= 0) daysToAdd += 7;

    return DateTime(from.year, from.month, from.day + daysToAdd, hour, minute);
  }

  /// Dispose resources
  void dispose() {
    stop();
  }

  /// 🔧 DEBUG: Sprawdź i napraw zaplanowane emaile z pustymi recipientami
  Future<List<String>> debugAndFixEmptyRecipients() async {
    final List<String> fixedEmails = [];

    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: ScheduledEmailStatus.pending.name)
          .get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final recipientsData = data['recipientsData'] as List<dynamic>? ?? [];

        if (recipientsData.isEmpty) {
          // Email z pustymi recipientami - oznacz jako failed
          await _updateEmailStatus(
            doc.id,
            ScheduledEmailStatus.failed,
            errorMessage:
                'Email zaplanowany bez odbiorców - automatycznie anulowany',
          );

          fixedEmails.add(doc.id);
        }
      }

      if (fixedEmails.isNotEmpty) {
      } else {
      }
    } catch (e) {
    }

    return fixedEmails;
  }
}

/// 📊 STATYSTYKI PLANOWANIA EMAILI
class SchedulingStatistics {
  final int totalScheduled;
  final int pending;
  final int sent;
  final int failed;
  final int cancelled;

  const SchedulingStatistics({
    required this.totalScheduled,
    required this.pending,
    required this.sent,
    required this.failed,
    required this.cancelled,
  });

  double get successRate {
    if (totalScheduled == 0) return 0.0;
    return sent / totalScheduled;
  }

  double get failureRate {
    if (totalScheduled == 0) return 0.0;
    return failed / totalScheduled;
  }
}

/// ⏰ OPCJA SZYBKIEGO PLANOWANIA
class ScheduleOption {
  final String label;
  final DateTime dateTime;
  final String icon;

  const ScheduleOption({
    required this.label,
    required this.dateTime,
    required this.icon,
  });
}
