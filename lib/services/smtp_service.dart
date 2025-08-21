import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/smtp_settings.dart';
import 'base_service.dart';

class SmtpService extends BaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'app_settings';
  static const String _documentId = 'smtp_configuration';

  // Pobierz ustawienia SMTP
  Future<SmtpSettings?> getSmtpSettings() async {
    final cacheKey = 'smtp_settings';
    return await getCachedData<SmtpSettings?>(cacheKey, () async {
      try {
        final doc = await _firestore
            .collection(_collectionPath)
            .doc(_documentId)
            .get();
        if (doc.exists) {
          return SmtpSettings.fromFirestore(doc.data()!);
        }
        return null;
      } catch (e) {
        logError('getSmtpSettings', e);
        return null;
      }
    });
  }

  // Zapisz ustawienia SMTP
  Future<void> saveSmtpSettings(SmtpSettings settings) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(_documentId)
          .set(settings.toFirestore(), SetOptions(merge: true));
      clearCache('smtp_settings');
      if (kDebugMode) {
        print('Ustawienia SMTP zostały zapisane.');
      }
    } catch (e) {
      logError('saveSmtpSettings', e);
      throw Exception('Nie udało się zapisać ustawień SMTP: $e');
    }
  }

  // Sprawdź połączenie SMTP
  Future<Map<String, dynamic>> testSmtpConnection(SmtpSettings settings) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('testSmtpConnection');
      
      final result = await callable.call({
        'host': settings.host,
        'port': settings.port,
        'username': settings.username,
        'password': settings.password,
        'security': settings.security.name,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      logError('testSmtpConnection', e);
      return {
        'success': false,
        'error': 'Błąd podczas testowania połączenia: $e',
      };
    }
  }

  // Wyślij testowy email
  Future<Map<String, dynamic>> sendTestEmail({
    required SmtpSettings settings,
    required String testEmail,
    String? customMessage,
  }) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('sendTestEmail');
      
      final result = await callable.call({
        'smtpSettings': {
          'host': settings.host,
          'port': settings.port,
          'username': settings.username,
          'password': settings.password,
          'security': settings.security.name,
        },
        'testEmail': testEmail,
        'customMessage': customMessage ?? 'To jest testowy email z systemu Metropolitan Investment.',
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      logError('sendTestEmail', e);
      return {
        'success': false,
        'error': 'Błąd podczas wysyłania testowego emaila: $e',
      };
    }
  }
}
