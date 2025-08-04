import 'package:cloud_firestore/cloud_firestore.dart';

enum NoteCategory {
  general('Ogólne'),
  contact('Kontakt'),
  investment('Inwestycje'),
  meeting('Spotkanie'),
  important('Ważne'),
  reminder('Przypomnienie');

  const NoteCategory(this.displayName);
  final String displayName;
}

enum NotePriority {
  low('Niska'),
  normal('Normalna'),
  high('Wysoka'),
  urgent('Pilna');

  const NotePriority(this.displayName);
  final String displayName;
}

class ClientNote {
  final String id;
  final String clientId;
  final String title;
  final String content;
  final NoteCategory category;
  final NotePriority priority;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  ClientNote({
    required this.id,
    required this.clientId,
    required this.title,
    required this.content,
    this.category = NoteCategory.general,
    this.priority = NotePriority.normal,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.tags = const [],
    this.metadata = const {},
  });

  factory ClientNote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ClientNote(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: NoteCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => NoteCategory.general,
      ),
      priority: NotePriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => NotePriority.normal,
      ),
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      tags: List<String>.from(data['tags'] ?? []),
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'title': title,
      'content': content,
      'category': category.name,
      'priority': priority.name,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'tags': tags,
      'metadata': metadata,
    };
  }

  ClientNote copyWith({
    String? id,
    String? clientId,
    String? title,
    String? content,
    NoteCategory? category,
    NotePriority? priority,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return ClientNote(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }
}
