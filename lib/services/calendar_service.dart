import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/calendar/calendar_event.dart';
import '../models/calendar/calendar_models.dart';
import 'base_service.dart';

/// Serwis do zarządzania kalendarzem
class CalendarService extends BaseService {
  static const String _collectionName = 'calendar_events';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Pobiera wydarzenia w określonym zakresie dat
  Future<List<CalendarEvent>> getEventsInRange({
    required DateTime startDate,
    required DateTime endDate,
    CalendarEventFilter? filter,
  }) async {
    try {
      // Sprawdź czy użytkownik jest zalogowany
      if (_auth.currentUser == null) {
        return [];
      }

      Query query = _firestore
          .collection(_collectionName)
          .where('startDate', isLessThan: endDate)
          .where('endDate', isGreaterThan: startDate)
          .orderBy('startDate');

      // Dodaj filtry jeśli są określone
      if (filter != null) {
        if (filter.categories.isNotEmpty) {
          query = query.where('category', whereIn: filter.categories);
        }
        if (filter.statuses.isNotEmpty) {
          query = query.where('status', whereIn: filter.statuses);
        }
      }

      final snapshot = await query.get();
      final events = <CalendarEvent>[];
      
      // 🚀 FIX: Bezpieczne przetwarzanie dokumentów
      for (final doc in snapshot.docs) {
        try {
          final event = CalendarEvent.fromMap({
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          });
          
          // 🚀 Sprawdź czy wydarzenie ma ID
          if (event.id.isNotEmpty) {
            events.add(event);
          } else {
            print('CalendarService: Pominięto wydarzenie bez ID: ${doc.id}');
          }
        } catch (e) {
          // 🚀 Loguj błędne dokumenty ale nie przerywaj
          print('CalendarService: Błąd parsowania dokumentu ${doc.id}: $e');
        }
      }
      
      return events;
    } catch (e) {
      // 🚀 DEBUG: Loguj błąd w trybie debug
      print('CalendarService.getEventsInRange error: $e');
      throw Exception('Błąd podczas pobierania wydarzeń: $e');
    }
  }

  /// Pobiera wydarzenia na określony dzień
  Future<List<CalendarEvent>> getEventsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getEventsInRange(startDate: startOfDay, endDate: endOfDay);
  }

  /// Pobiera wydarzenia dla aktualnego miesiąca
  Future<List<CalendarEvent>> getEventsForMonth(DateTime date) async {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final endOfMonth = DateTime(date.year, date.month + 1, 1);

    return getEventsInRange(startDate: startOfMonth, endDate: endOfMonth);
  }

  /// Pobiera wydarzenia dla aktualnego tygodnia
  Future<List<CalendarEvent>> getEventsForWeek(DateTime date) async {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return getEventsInRange(startDate: startOfWeek, endDate: endOfWeek);
  }

  /// Tworzy nowe wydarzenie
  Future<CalendarEvent> createEvent(CalendarEvent event) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Użytkownik nie jest zalogowany');

      final now = DateTime.now();
      
      // 🚀 FIX: Przygotuj dane wydarzenia do zapisu (bez ID)
      final eventData = event.copyWith(
        id: '', // Wyczyść ID - Firestore wygeneruje nowe
        createdBy: user.uid,
        createdAt: now,
        updatedAt: now,
      ).toMap();
      
      // Usuń ID z mapy - Firestore automatycznie wygeneruje
      eventData.remove('id');

      final docRef = await _firestore
          .collection(_collectionName)
          .add(eventData);

      // 🚀 FIX: Zwróć wydarzenie z nowo wygenerowanym ID
      final finalEvent = event.copyWith(
        id: docRef.id,
        createdBy: user.uid,
        createdAt: now,
        updatedAt: now,
      );
      
      // 🚀 DEBUG: Loguj utworzone wydarzenie
      print('CalendarService.createEvent: Created event with ID: ${finalEvent.id}');
      
      return finalEvent;
    } catch (e) {
      // 🚀 DEBUG: Loguj błąd tworzenia
      print('CalendarService.createEvent error: $e');
      throw Exception('Błąd podczas tworzenia wydarzenia: $e');
    }
  }

  /// Aktualizuje istniejące wydarzenie
  Future<CalendarEvent> updateEvent(CalendarEvent event) async {
    try {
      if (event.id.isEmpty) throw Exception('ID wydarzenia nie może być puste');

      final updatedEvent = event.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection(_collectionName)
          .doc(event.id)
          .update(updatedEvent.toMap());

      return updatedEvent;
    } catch (e) {
      throw Exception('Błąd podczas aktualizacji wydarzenia: $e');
    }
  }

  /// Usuwa wydarzenie
  Future<void> deleteEvent(String eventId) async {
    try {
      if (eventId.isEmpty) throw Exception('ID wydarzenia nie może być puste');

      await _firestore.collection(_collectionName).doc(eventId).delete();
    } catch (e) {
      throw Exception('Błąd podczas usuwania wydarzenia: $e');
    }
  }

  /// Pobiera pojedyncze wydarzenie po ID
  Future<CalendarEvent?> getEvent(String eventId) async {
    try {
      // Sprawdź czy użytkownik jest zalogowany
      if (_auth.currentUser == null) {
        return null;
      }

      final doc = await _firestore
          .collection(_collectionName)
          .doc(eventId)
          .get();

      if (!doc.exists) return null;

      return CalendarEvent.fromMap({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      });
    } catch (e) {
      throw Exception('Błąd podczas pobierania wydarzenia: $e');
    }
  }

  /// Wyszukuje wydarzenia według zapytania
  Future<List<CalendarEvent>> searchEvents({
    required String query,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      // Sprawdź czy użytkownik jest zalogowany
      if (_auth.currentUser == null) {
        return [];
      }

      Query firestoreQuery = _firestore
          .collection(_collectionName)
          .orderBy('startDate', descending: true)
          .limit(limit);

      if (startDate != null) {
        firestoreQuery = firestoreQuery.where(
          'startDate',
          isGreaterThanOrEqualTo: startDate,
        );
      }

      if (endDate != null) {
        firestoreQuery = firestoreQuery.where(
          'startDate',
          isLessThanOrEqualTo: endDate,
        );
      }

      final snapshot = await firestoreQuery.get();
      final events = snapshot.docs
          .map(
            (doc) => CalendarEvent.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();

      // Filtruj wyniki lokalnie dla wyszukiwania tekstowego
      if (query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        return events.where((event) {
          return event.title.toLowerCase().contains(lowerQuery) ||
              (event.description?.toLowerCase().contains(lowerQuery) ??
                  false) ||
              (event.location?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      }

      return events;
    } catch (e) {
      throw Exception('Błąd podczas wyszukiwania wydarzeń: $e');
    }
  }

  /// Pobiera nadchodzące wydarzenia (następne 7 dni)
  Future<List<CalendarEvent>> getUpcomingEvents({int days = 7}) async {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));

    return getEventsInRange(startDate: now, endDate: endDate);
  }

  /// Pobiera wydarzenia wymagające uwagi (rozpoczynające się w ciągu 2 godzin)
  Future<List<CalendarEvent>> getEventsRequiringAttention() async {
    final now = DateTime.now();
    final twoHoursLater = now.add(const Duration(hours: 2));

    final events = await getEventsInRange(
      startDate: now,
      endDate: twoHoursLater,
    );

    return events
        .where(
          (event) =>
              event.status == CalendarEventStatus.confirmed ||
              event.priority == CalendarEventPriority.high ||
              event.priority == CalendarEventPriority.urgent,
        )
        .toList();
  }

  /// Pobiera statystyki wydarzeń
  Future<Map<String, dynamic>> getEventStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now().add(const Duration(days: 30));

      final events = await getEventsInRange(startDate: start, endDate: end);

      final stats = <String, dynamic>{
        'totalEvents': events.length,
        'byCategory': <String, int>{},
        'byStatus': <String, int>{},
        'byPriority': <String, int>{},
        'upcomingEvents': 0,
        'overdue': 0,
      };

      final now = DateTime.now();

      for (final event in events) {
        // Statystyki kategorii
        final categoryName = event.category.name;
        stats['byCategory'][categoryName] =
            (stats['byCategory'][categoryName] ?? 0) + 1;

        // Statystyki statusu
        final statusName = event.status.name;
        stats['byStatus'][statusName] =
            (stats['byStatus'][statusName] ?? 0) + 1;

        // Statystyki priorytetu
        final priorityName = event.priority.name;
        stats['byPriority'][priorityName] =
            (stats['byPriority'][priorityName] ?? 0) + 1;

        // Nadchodzące wydarzenia
        if (event.startDate.isAfter(now)) {
          stats['upcomingEvents']++;
        }

        // Przeterminowane
        if (event.endDate.isBefore(now) &&
            event.status != CalendarEventStatus.cancelled) {
          stats['overdue']++;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Błąd podczas pobierania statystyk: $e');
    }
  }

  /// Pobiera stream wydarzeń dla określonego zakresu dat
  Stream<List<CalendarEvent>> getEventsStream({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _firestore
        .collection(_collectionName)
        .where('startDate', isLessThan: endDate)
        .where('endDate', isGreaterThan: startDate)
        .orderBy('startDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => CalendarEvent.fromMap({'id': doc.id, ...doc.data()}),
              )
              .toList(),
        );
  }

  /// Generuje powtarzające się wydarzenia
  List<CalendarEvent> generateRecurringEvents({
    required CalendarEvent baseEvent,
    required DateTime startDate,
    required DateTime endDate,
    int maxOccurrences = 100,
  }) {
    if (baseEvent.recurrence == null ||
        baseEvent.recurrence!.type == RecurrenceType.none) {
      return [baseEvent];
    }

    final events = <CalendarEvent>[];
    final recurrence = baseEvent.recurrence!;
    var currentStart = baseEvent.startDate;
    var currentEnd = baseEvent.endDate;
    final duration = baseEvent.duration;

    int occurrenceCount = 0;

    while (currentStart.isBefore(endDate) && occurrenceCount < maxOccurrences) {
      if (currentStart.isAfter(startDate) || currentStart == startDate) {
        events.add(
          baseEvent.copyWith(
            id: '${baseEvent.id}_$occurrenceCount',
            startDate: currentStart,
            endDate: currentEnd,
          ),
        );
      }

      // Sprawdź warunki zakończenia
      if (recurrence.endDate != null &&
          currentStart.isAfter(recurrence.endDate!)) {
        break;
      }

      if (recurrence.occurrences != null &&
          occurrenceCount >= recurrence.occurrences!) {
        break;
      }

      // Oblicz następną datę
      switch (recurrence.type) {
        case RecurrenceType.daily:
          currentStart = currentStart.add(Duration(days: recurrence.interval));
          break;
        case RecurrenceType.weekly:
          currentStart = currentStart.add(
            Duration(days: 7 * recurrence.interval),
          );
          break;
        case RecurrenceType.monthly:
          currentStart = DateTime(
            currentStart.year,
            currentStart.month + recurrence.interval,
            currentStart.day,
            currentStart.hour,
            currentStart.minute,
          );
          break;
        case RecurrenceType.yearly:
          currentStart = DateTime(
            currentStart.year + recurrence.interval,
            currentStart.month,
            currentStart.day,
            currentStart.hour,
            currentStart.minute,
          );
          break;
        default:
          break;
      }

      currentEnd = currentStart.add(duration);
      occurrenceCount++;
    }

    return events;
  }
}
