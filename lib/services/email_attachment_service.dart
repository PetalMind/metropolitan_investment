import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/email_attachment.dart';

/// 📎 EMAIL ATTACHMENT SERVICE - ZARZĄDZANIE ZAŁĄCZNIKAMI
///
/// Główne funkcjonalności:
/// - Upload załączników do Firebase Storage
/// - CRUD operacje na załącznikach
/// - Walidacja typów i rozmiarów plików
/// - Cache dla często używanych załączników
/// - Bezpieczne przechowywanie i dostęp
/// - Optymalizacja dla załączników email
class EmailAttachmentService {
  static const String _collectionName = 'email_attachments';
  static const String _storagePath = 'email_attachments';
  static const String _logTag = 'EmailAttachmentService';
  static const int _maxFileSize = 25 * 1024 * 1024; // 25MB
  
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Map<String, dynamic> _cache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheTtl = Duration(minutes: 10);

  EmailAttachmentService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  /// Sprawdza czy cache jest aktualny
  bool get _isCacheValid {
    return _lastCacheUpdate != null &&
           DateTime.now().difference(_lastCacheUpdate!) < _cacheTtl;
  }

  /// Czysci cache
  void clearCache() {
    _cache.clear();
    _lastCacheUpdate = null;
  }

  /// Pobiera dane z cache lub wykonuje query
  Future<T?> getCachedData<T>(String key, Future<T?> Function() query) async {
    if (_isCacheValid && _cache.containsKey(key)) {
      return _cache[key] as T?;
    }

    final result = await query();
    if (result != null) {
      _cache[key] = result;
      _lastCacheUpdate = DateTime.now();
    }
    return result;
  }

  /// Log błędów
  void logError(String message, dynamic error) {
  }

  /// Wybiera pliki za pomocą file picker
  Future<List<PlatformFile>?> pickFiles({
    bool allowMultiple = true,
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: allowedExtensions != null 
            ? FileType.custom 
            : FileType.any,
        allowedExtensions: allowedExtensions,
        withData: true, // Pobierz dane pliku dla web
      );

      if (result != null && result.files.isNotEmpty) {
        // Waliduj rozmiary
        final validFiles = result.files.where((file) {
          if (file.size > _maxFileSize) {
            return false;
          }
          return true;
        }).toList();

        return validFiles;
      }
      
      return null;
    } catch (e) {
      logError('Error picking files', e);
      return null;
    }
  }

  /// Przesyła plik do Firebase Storage
  Future<String?> uploadFile(
    PlatformFile file,
    String userId, {
    String? customPath,
    Function(double)? onProgress,
  }) async {
    try {
      if (file.bytes == null) {
        logError('File has no data', 'bytes is null');
        return null;
      }

      // Sanitize filename
      final sanitizedName = _sanitizeFileName(file.name);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = customPath ?? 
          '$_storagePath/$userId/$timestamp-$sanitizedName';

      final ref = _storage.ref().child(filePath);
      
      // Set metadata
      final metadata = SettableMetadata(
        contentType: _getMimeType(file.extension ?? ''),
        customMetadata: {
          'originalName': file.name,
          'uploadedBy': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload with progress tracking
      final uploadTask = ref.putData(file.bytes!, metadata);
      
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      logError('Error uploading file', e);
      return null;
    }
  }

  /// Tworzy attachment w bazie danych
  Future<String?> createAttachment({
    required PlatformFile file,
    required String uploadedBy,
    String? description,
    String? storageUrl,
    String? storagePath,
  }) async {
    try {
      final attachment = EmailAttachment(
        id: '', // Firestore wygeneruje ID
        name: _sanitizeFileName(file.name),
        originalName: file.name,
        mimeType: _getMimeType(file.extension ?? ''),
        size: file.size,
        description: description,
        storageUrl: storageUrl,
        storagePath: storagePath,
        data: kIsWeb ? file.bytes : null, // Store data only on web
        createdAt: DateTime.now(),
        uploadedBy: uploadedBy,
        metadata: {
          'category': AttachmentCategory.fromMimeType(_getMimeType(file.extension ?? '')).name,
          'extension': file.extension ?? '',
          'uploadMethod': kIsWeb ? 'web' : 'mobile',
        },
      );

      final docRef = await _firestore
          .collection(_collectionName)
          .add(attachment.toFirestore());

      clearCache();
      return docRef.id;
    } catch (e) {
      logError('Error creating attachment', e);
      return null;
    }
  }

  /// Upload i zapisuje attachment w jednej operacji
  Future<EmailAttachment?> uploadAndCreateAttachment({
    required PlatformFile file,
    required String userId,
    String? description,
    Function(double)? onProgress,
  }) async {
    try {
      // Upload do Storage
      final storageUrl = await uploadFile(file, userId, onProgress: onProgress);
      if (storageUrl == null) {
        logError('Failed to upload file', 'storageUrl is null');
        return null;
      }

      // Utwórz attachment w bazie
      final attachmentId = await createAttachment(
        file: file,
        uploadedBy: userId,
        description: description,
        storageUrl: storageUrl,
        storagePath: '$_storagePath/$userId/${DateTime.now().millisecondsSinceEpoch}-${_sanitizeFileName(file.name)}',
      );

      if (attachmentId == null) {
        logError('Failed to create attachment', 'attachmentId is null');
        return null;
      }

      return await getAttachment(attachmentId);
    } catch (e) {
      logError('Error uploading and creating attachment', e);
      return null;
    }
  }

  /// Pobiera attachment według ID
  Future<EmailAttachment?> getAttachment(String attachmentId) async {
    return await getCachedData('attachment_$attachmentId', () async {
      try {
        final doc = await _firestore
            .collection(_collectionName)
            .doc(attachmentId)
            .get();

        if (!doc.exists) {
          return null;
        }

        return EmailAttachment.fromFirestore(doc);
      } catch (e) {
        logError('Error fetching attachment', e);
        return null;
      }
    });
  }

  /// Pobiera wszystkie attachmenty użytkownika
  Future<List<EmailAttachment>?> getUserAttachments(
    String userId, {
    int limit = 50,
    AttachmentCategory? category,
  }) async {
    return await getCachedData('user_attachments_${userId}_${category?.name}', () async {
      try {
        Query query = _firestore
            .collection(_collectionName)
            .where('uploadedBy', isEqualTo: userId)
            .orderBy('createdAt', descending: true);

        if (category != null) {
          query = query.where('metadata.category', isEqualTo: category.name);
        }

        if (limit > 0) {
          query = query.limit(limit);
        }

        final snapshot = await query.get();
        final attachments = snapshot.docs
            .map((doc) => EmailAttachment.fromFirestore(doc))
            .toList();

        return attachments;
      } catch (e) {
        logError('Error fetching user attachments', e);
        return null;
      }
    });
  }

  /// Usuwa attachment
  Future<bool> deleteAttachment(String attachmentId, {bool deleteFromStorage = true}) async {
    try {
      // Pobierz attachment żeby uzyskać storage path
      final attachment = await getAttachment(attachmentId);
      
      // Usuń z Storage jeśli ma storage path
      if (deleteFromStorage && attachment?.storagePath != null) {
        try {
          await _storage.ref(attachment!.storagePath!).delete();
        } catch (storageError) {
        }
      }

      // Usuń z Firestore
      await _firestore.collection(_collectionName).doc(attachmentId).delete();
      
      clearCache();
      return true;
    } catch (e) {
      logError('Error deleting attachment', e);
      return false;
    }
  }

  /// Waliduje plik przed uploadem
  Map<String, dynamic> validateFile(PlatformFile file) {
    final issues = <String>[];
    final warnings = <String>[];

    // Sprawdź rozmiar
    if (file.size > _maxFileSize) {
      issues.add('Plik jest za duży (${(file.size / (1024 * 1024)).toStringAsFixed(1)}MB). Maksymalny rozmiar: ${_maxFileSize / (1024 * 1024)}MB.');
    }

    // Sprawdź typ pliku
    final attachment = EmailAttachment(
      id: 'temp',
      name: file.name,
      originalName: file.name,
      mimeType: _getMimeType(file.extension ?? ''),
      size: file.size,
      createdAt: DateTime.now(),
      uploadedBy: 'temp',
    );

    if (!attachment.isSafeType) {
      issues.add('Typ pliku ${attachment.mimeType} może nie być bezpieczny.');
    }

    // Sprawdź czy dane są dostępne
    if (file.bytes == null) {
      issues.add('Nie można odczytać zawartości pliku.');
    }

    // Ostrzeżenia
    if (file.size > 5 * 1024 * 1024) { // 5MB
      warnings.add('Duży plik może spowolnić wysyłkę email.');
    }

    return {
      'isValid': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
      'attachment': attachment,
    };
  }

  /// Pobiera estatystyki załączników użytkownika
  Future<Map<String, dynamic>?> getUserAttachmentStats(String userId) async {
    return await getCachedData('user_stats_$userId', () async {
      try {
        final attachments = await getUserAttachments(userId, limit: 0);
        if (attachments == null) return null;

        int totalSize = 0;
        final categoryCounts = <String, int>{};
        final typeCounts = <String, int>{};

        for (final attachment in attachments) {
          totalSize += attachment.size;
          
          final category = AttachmentCategory.fromMimeType(attachment.mimeType);
          categoryCounts[category.name] = (categoryCounts[category.name] ?? 0) + 1;
          
          typeCounts[attachment.mimeType] = (typeCounts[attachment.mimeType] ?? 0) + 1;
        }

        return {
          'totalCount': attachments.length,
          'totalSize': totalSize,
          'averageSize': attachments.isNotEmpty ? totalSize / attachments.length : 0,
          'categoryCounts': categoryCounts,
          'typeCounts': typeCounts,
          'formattedTotalSize': _formatSize(totalSize),
        };
      } catch (e) {
        logError('Error getting user attachment stats', e);
        return null;
      }
    });
  }

  /// Czyści stare załączniki (cleanup)
  Future<int> cleanupOldAttachments({
    Duration olderThan = const Duration(days: 90),
    String? userId,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(olderThan);
      
      Query query = _firestore
          .collection(_collectionName)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate));

      if (userId != null) {
        query = query.where('uploadedBy', isEqualTo: userId);
      }

      final snapshot = await query.get();
      int deletedCount = 0;

      for (final doc in snapshot.docs) {
        final attachment = EmailAttachment.fromFirestore(doc);
        final success = await deleteAttachment(attachment.id);
        if (success) {
          deletedCount++;
        }
      }

      return deletedCount;
    } catch (e) {
      logError('Error cleaning up old attachments', e);
      return 0;
    }
  }

  // Helper methods
  
  String _sanitizeFileName(String fileName) {
    // Remove unsafe characters
    return fileName.replaceAll(RegExp(r'[^\w\-_.]'), '_');
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      default:
        return 'application/octet-stream';
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Stream załączników w czasie rzeczywistym
  Stream<List<EmailAttachment>> getUserAttachmentsStream(
    String userId, {
    AttachmentCategory? category,
  }) {
    Query query = _firestore
        .collection(_collectionName)
        .where('uploadedBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (category != null) {
      query = query.where('metadata.category', isEqualTo: category.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => EmailAttachment.fromFirestore(doc))
          .toList();
    });
  }
}