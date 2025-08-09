import 'package:cloud_firestore/cloud_firestore.dart';

/// Model wydarzeń kalendarza
class CalendarEvent {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final String? location;
  final CalendarEventCategory category;
  final CalendarEventStatus status;
  final CalendarEventPriority priority;
  final List<String> participants;
  final bool isAllDay;
  final CalendarRecurrence? recurrence;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.description,
    this.location,
    required this.category,
    this.status = CalendarEventStatus.confirmed,
    this.priority = CalendarEventPriority.medium,
    this.participants = const [],
    this.isAllDay = false,
    this.recurrence,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Tworzy wydarzenie z mapy danych z Firestore
  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      description: map['description'],
      location: map['location'],
      category: CalendarEventCategory.values.firstWhere(
        (cat) => cat.name == map['category'],
        orElse: () => CalendarEventCategory.other,
      ),
      status: CalendarEventStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => CalendarEventStatus.confirmed,
      ),
      priority: CalendarEventPriority.values.firstWhere(
        (priority) => priority.name == map['priority'],
        orElse: () => CalendarEventPriority.medium,
      ),
      participants: List<String>.from(map['participants'] ?? []),
      isAllDay: map['isAllDay'] ?? false,
      recurrence: map['recurrence'] != null
          ? CalendarRecurrence.fromMap(map['recurrence'])
          : null,
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  /// Konwertuje do mapy dla Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'description': description,
      'location': location,
      'category': category.name,
      'status': status.name,
      'priority': priority.name,
      'participants': participants,
      'isAllDay': isAllDay,
      'recurrence': recurrence?.toMap(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  /// Sprawdza czy wydarzenie jest aktywne w danym okresie
  bool isActiveInPeriod(DateTime start, DateTime end) {
    return startDate.isBefore(end) && endDate.isAfter(start);
  }

  /// Sprawdza czy wydarzenie trwa w określonym dniu
  bool occursOnDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return isActiveInPeriod(dayStart, dayEnd);
  }

  /// Zwraca czas trwania wydarzenia
  Duration get duration => endDate.difference(startDate);

  /// Tworzy kopię z nowymi wartościami
  CalendarEvent copyWith({
    String? id,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    String? location,
    CalendarEventCategory? category,
    CalendarEventStatus? status,
    CalendarEventPriority? priority,
    List<String>? participants,
    bool? isAllDay,
    CalendarRecurrence? recurrence,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      location: location ?? this.location,
      category: category ?? this.category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      participants: participants ?? this.participants,
      isAllDay: isAllDay ?? this.isAllDay,
      recurrence: recurrence ?? this.recurrence,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Kategorie wydarzeń
enum CalendarEventCategory {
  work('Praca', 0xFF2196F3),
  personal('Osobiste', 0xFF4CAF50),
  meeting('Spotkanie', 0xFFFF9800),
  appointment('Wizyta', 0xFF9C27B0),
  investment('Inwestycje', 0xFF607D8B),
  client('Klient', 0xFFE91E63),
  deadline('Termin', 0xFFF44336),
  other('Inne', 0xFF795548);

  const CalendarEventCategory(this.displayName, this.colorValue);

  final String displayName;
  final int colorValue;
}

/// Status wydarzenia
enum CalendarEventStatus {
  confirmed('Potwierdzone'),
  tentative('Wstępne'),
  cancelled('Anulowane'),
  pending('Oczekujące');

  const CalendarEventStatus(this.displayName);

  final String displayName;
}

/// Priorytet wydarzenia
enum CalendarEventPriority {
  low('Niski'),
  medium('Średni'),
  high('Wysoki'),
  urgent('Pilny');

  const CalendarEventPriority(this.displayName);

  final String displayName;
}

/// Model dla powtarzalności wydarzeń
class CalendarRecurrence {
  final RecurrenceType type;
  final int interval;
  final List<int>? weekDays; // 1 = Monday, 7 = Sunday
  final int? monthDay; // 1-31
  final DateTime? endDate;
  final int? occurrences;

  CalendarRecurrence({
    required this.type,
    this.interval = 1,
    this.weekDays,
    this.monthDay,
    this.endDate,
    this.occurrences,
  });

  factory CalendarRecurrence.fromMap(Map<String, dynamic> map) {
    return CalendarRecurrence(
      type: RecurrenceType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => RecurrenceType.none,
      ),
      interval: map['interval'] ?? 1,
      weekDays: map['weekDays'] != null
          ? List<int>.from(map['weekDays'])
          : null,
      monthDay: map['monthDay'],
      endDate: map['endDate'] != null
          ? (map['endDate'] as Timestamp).toDate()
          : null,
      occurrences: map['occurrences'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'interval': interval,
      'weekDays': weekDays,
      'monthDay': monthDay,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'occurrences': occurrences,
    };
  }
}

/// Typy powtarzalności
enum RecurrenceType {
  none('Brak'),
  daily('Codziennie'),
  weekly('Cotygodniowo'),
  monthly('Miesięcznie'),
  yearly('Rocznie'),
  custom('Niestandardowy');

  const RecurrenceType(this.displayName);

  final String displayName;
}
