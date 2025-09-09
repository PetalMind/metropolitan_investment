import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 📎 MODEL ZAŁĄCZNIKA EMAIL
///
/// Reprezentuje załącznik do wiadomości email z:
/// - Wsparciem dla różnych typów plików
/// - Upload do Firebase Storage
/// - Metadane pliku (rozmiar, typ, nazwa)
/// - Bezpieczne przechowywanie i dostęp
class EmailAttachment {
  final String id;
  final String name;
  final String originalName;
  final String mimeType;
  final int size;
  final String? description;
  final String? storageUrl;
  final String? storagePath;
  final Uint8List? data; // For small files or temporary storage
  final DateTime createdAt;
  final String uploadedBy;
  final Map<String, dynamic> metadata;
  
  const EmailAttachment({
    required this.id,
    required this.name,
    required this.originalName,
    required this.mimeType,
    required this.size,
    this.description,
    this.storageUrl,
    this.storagePath,
    this.data,
    required this.createdAt,
    required this.uploadedBy,
    this.metadata = const {},
  });

  /// Tworzy EmailAttachment z Firestore DocumentSnapshot
  factory EmailAttachment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmailAttachment.fromMap(data, doc.id);
  }

  /// Tworzy EmailAttachment z Map
  factory EmailAttachment.fromMap(Map<String, dynamic> data, String id) {
    return EmailAttachment(
      id: id,
      name: data['name'] ?? '',
      originalName: data['originalName'] ?? '',
      mimeType: data['mimeType'] ?? '',
      size: data['size'] ?? 0,
      description: data['description'],
      storageUrl: data['storageUrl'],
      storagePath: data['storagePath'],
      data: null, // Data is not stored in Firestore
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      uploadedBy: data['uploadedBy'] ?? '',
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Konwertuje do Map dla Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'originalName': originalName,
      'mimeType': mimeType,
      'size': size,
      'description': description,
      'storageUrl': storageUrl,
      'storagePath': storagePath,
      'createdAt': Timestamp.fromDate(createdAt),
      'uploadedBy': uploadedBy,
      'metadata': metadata,
    };
  }

  /// Kopiuje attachment z nowymi wartościami
  EmailAttachment copyWith({
    String? id,
    String? name,
    String? originalName,
    String? mimeType,
    int? size,
    String? description,
    String? storageUrl,
    String? storagePath,
    Uint8List? data,
    DateTime? createdAt,
    String? uploadedBy,
    Map<String, dynamic>? metadata,
  }) {
    return EmailAttachment(
      id: id ?? this.id,
      name: name ?? this.name,
      originalName: originalName ?? this.originalName,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      description: description ?? this.description,
      storageUrl: storageUrl ?? this.storageUrl,
      storagePath: storagePath ?? this.storagePath,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Sprawdza czy załącznik jest obrazem
  bool get isImage => mimeType.startsWith('image/');

  /// Sprawdza czy załącznik jest dokumentem PDF
  bool get isPdf => mimeType == 'application/pdf';

  /// Sprawdza czy załącznik jest dokumentem Word
  bool get isWord => mimeType.contains('word') || mimeType.contains('document');

  /// Sprawdza czy załącznik jest arkuszem Excel
  bool get isExcel => mimeType.contains('sheet') || mimeType.contains('excel');

  /// Pobiera ikonę dla typu pliku
  String get fileIcon {
    if (isImage) return '🖼️';
    if (isPdf) return '📄';
    if (isWord) return '📝';
    if (isExcel) return '📊';
    if (mimeType.startsWith('text/')) return '📃';
    if (mimeType.startsWith('video/')) return '🎬';
    if (mimeType.startsWith('audio/')) return '🎵';
    return '📎';
  }

  /// Formatuje rozmiar pliku
  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Sprawdza czy rozmiar pliku jest akceptowalny (max 25MB dla email)
  bool get isSizeAcceptable => size <= 25 * 1024 * 1024;

  /// Sprawdza czy typ pliku jest bezpieczny
  bool get isSafeType {
    const safeMimeTypes = [
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
      'application/pdf',
      'text/plain',
      'text/csv',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    ];
    
    return safeMimeTypes.contains(mimeType) || 
           mimeType.startsWith('text/') ||
           mimeType.startsWith('image/');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is EmailAttachment &&
        other.id == id &&
        other.name == name &&
        other.size == size &&
        other.mimeType == mimeType;
  }

  @override
  int get hashCode {
    return id.hashCode ^ 
           name.hashCode ^ 
           size.hashCode ^ 
           mimeType.hashCode;
  }

  @override
  String toString() {
    return 'EmailAttachment(id: $id, name: $name, size: $formattedSize, type: $mimeType)';
  }
}

/// 📎 KATEGORIE ZAŁĄCZNIKÓW
enum AttachmentCategory {
  document('Dokumenty', 'Pliki dokumentów i arkuszy'),
  image('Obrazy', 'Zdjęcia i grafiki'),
  report('Raporty', 'Raporty i analizy'),
  contract('Umowy', 'Dokumenty umów i prawne'),
  other('Inne', 'Pozostałe pliki');

  const AttachmentCategory(this.displayName, this.description);
  
  final String displayName;
  final String description;

  /// Pobiera ikonę kategorii
  String get icon {
    switch (this) {
      case AttachmentCategory.document:
        return '📄';
      case AttachmentCategory.image:
        return '🖼️';
      case AttachmentCategory.report:
        return '📊';
      case AttachmentCategory.contract:
        return '📋';
      case AttachmentCategory.other:
        return '📎';
    }
  }

  /// Określa kategorię na podstawie typu MIME
  static AttachmentCategory fromMimeType(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return AttachmentCategory.image;
    } else if (mimeType.contains('pdf') || 
               mimeType.contains('word') || 
               mimeType.contains('document')) {
      return AttachmentCategory.document;
    } else if (mimeType.contains('sheet') || 
               mimeType.contains('excel') ||
               mimeType.contains('csv')) {
      return AttachmentCategory.report;
    } else {
      return AttachmentCategory.other;
    }
  }
}