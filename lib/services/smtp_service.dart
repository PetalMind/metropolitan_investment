import 'package:cloud_firestore/cloud_firestore.dart';
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
}
