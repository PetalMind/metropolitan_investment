import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEvent {
  final String? id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String category;
  final Color color;
  final List<String> participants;
  final String location;
  final bool isRecurring;
  final String? recurrenceRule;
  final String status; // 'confirmed', 'pending', 'cancelled'
  final String? meetingUrl;
  final bool hasReminder;
  final int reminderMinutes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CalendarEvent({
    this.id,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    this.category = 'general',
    this.color = Colors.blue,
    this.participants = const [],
    this.location = '',
    this.isRecurring = false,
    this.recurrenceRule,
    this.status = 'confirmed',
    this.meetingUrl,
    this.hasReminder = false,
    this.reminderMinutes = 15,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  // Duration in minutes for time planner
  int get durationInMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  // Days duration (for multi-day events)
  int get daysDuration {
    final days = endTime.difference(startTime).inDays;
    return days > 0 ? days : 1;
  }

  // Create from Firestore document
  factory CalendarEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarEvent(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      category: data['category'] ?? 'general',
      color: Color(data['color'] ?? Colors.blue.value),
      participants: List<String>.from(data['participants'] ?? []),
      location: data['location'] ?? '',
      isRecurring: data['isRecurring'] ?? false,
      recurrenceRule: data['recurrenceRule'],
      status: data['status'] ?? 'confirmed',
      meetingUrl: data['meetingUrl'],
      hasReminder: data['hasReminder'] ?? false,
      reminderMinutes: data['reminderMinutes'] ?? 15,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'category': category,
      'color': color.value,
      'participants': participants,
      'location': location,
      'isRecurring': isRecurring,
      'recurrenceRule': recurrenceRule,
      'status': status,
      'meetingUrl': meetingUrl,
      'hasReminder': hasReminder,
      'reminderMinutes': reminderMinutes,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Copy with method for updates
  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? category,
    Color? color,
    List<String>? participants,
    String? location,
    bool? isRecurring,
    String? recurrenceRule,
    String? status,
    String? meetingUrl,
    bool? hasReminder,
    int? reminderMinutes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      color: color ?? this.color,
      participants: participants ?? this.participants,
      location: location ?? this.location,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      status: status ?? this.status,
      meetingUrl: meetingUrl ?? this.meetingUrl,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CalendarEvent(id: $id, title: $title, startTime: $startTime, endTime: $endTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Event categories with predefined colors
class EventCategories {
  static const Map<String, Color> categories = {
    'meeting': Colors.blue,
    'deadline': Colors.red,
    'personal': Colors.green,
    'work': Colors.orange,
    'client': Colors.purple,
    'investment': Colors.teal,
    'general': Colors.grey,
  };

  static Color getColorForCategory(String category) {
    return categories[category] ?? Colors.grey;
  }

  static List<String> get allCategories => categories.keys.toList();
}
