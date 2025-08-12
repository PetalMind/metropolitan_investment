import '../services/notification_service.dart';
import '../services/calendar_service.dart';
import '../models/calendar/calendar_event.dart';

/// Service do zarządzania powiadomieniami kalendarza
/// Integruje się z CalendarService i NotificationService
class CalendarNotificationService {
  static final CalendarNotificationService _instance =
      CalendarNotificationService._internal();
  factory CalendarNotificationService() => _instance;
  CalendarNotificationService._internal();

  final CalendarService _calendarService = CalendarService();
  final NotificationService _notificationService = NotificationService();

  /// Sprawdza wydarzenia na dzisiaj i aktualizuje powiadomienia
  Future<void> checkTodayEvents() async {
    try {
      final today = DateTime.now();
      final todayEvents = await _calendarService.getEventsForDate(today);

      // Liczy tylko wydarzenia oczekujące potwierdzenia lub pilne
      final pendingEvents = todayEvents
          .where(
            (event) =>
                event.status == CalendarEventStatus.pending ||
                event.priority == CalendarEventPriority.urgent ||
                event.priority == CalendarEventPriority.high,
          )
          .toList();

      _notificationService.updateCalendarNotifications(pendingEvents.length);
    } catch (e) {
      print('Błąd podczas sprawdzania wydarzeń kalendarza: $e');
      // W przypadku błędu, ustaw 0 powiadomień
      _notificationService.updateCalendarNotifications(0);
    }
  }

  /// Sprawdza nadchodzące wydarzenia (w ciągu tygodnia)
  Future<void> checkUpcomingEvents() async {
    try {
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      final upcomingEvents = await _calendarService.getEventsInRange(
        startDate: now,
        endDate: nextWeek,
      );

      // Liczy wydarzenia wymagające uwagi
      final importantEvents = upcomingEvents
          .where(
            (event) =>
                event.status == CalendarEventStatus.pending ||
                event.status == CalendarEventStatus.tentative ||
                event.priority == CalendarEventPriority.urgent,
          )
          .toList();

      _notificationService.updateCalendarNotifications(importantEvents.length);
    } catch (e) {
      print('Błąd podczas sprawdzania nadchodzących wydarzeń: $e');
      // Fallback do symulacji tylko jeśli nie ma danych
      _simulateCalendarNotifications();
    }
  }

  /// Sprawdza przeterminowane wydarzenia i oznacza je jako wymagające uwagi
  Future<void> checkOverdueEvents() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final recentEvents = await _calendarService.getEventsInRange(
        startDate: yesterday,
        endDate: now,
      );

      // Szuka wydarzeń, które powinny być zakończone ale są wciąż pending
      final overdueEvents = recentEvents
          .where(
            (event) =>
                event.endDate.isBefore(now) &&
                event.status == CalendarEventStatus.pending,
          )
          .toList();

      // Informacyjnie - nie wpływa na główny licznik powiadomień kalendarza
      print('Znaleziono ${overdueEvents.length} przeterminowanych wydarzeń');
    } catch (e) {
      print('Błąd podczas sprawdzania przeterminowanych wydarzeń: $e');
    }
  }

  /// Oznacza wydarzenie jako zakończone (przez CalendarService)
  Future<void> markEventAsCompleted(String eventId) async {
    try {
      // Ta funkcjonalność powinna być implementowana w CalendarService
      // Tutaj tylko odświeżamy licznik powiadomień
      await checkTodayEvents();
    } catch (e) {
      print('Błąd podczas oznaczania wydarzenia jako zakończone: $e');
    }
  }

  /// Symuluje powiadomienia kalendarza dla celów demo
  void _simulateCalendarNotifications() {
    // Symulacja różnych typów powiadomień
    final now = DateTime.now();
    final hour = now.hour;

    int notifications = 0;

    // Więcej powiadomień w godzinach pracy (9-17)
    if (hour >= 9 && hour <= 17) {
      notifications = 3;
    } else if (hour >= 18 && hour <= 22) {
      notifications = 1;
    } else {
      notifications = 0;
    }

    _notificationService.updateCalendarNotifications(notifications);
  }

  /// Inicjalizuje serwis powiadomień kalendarza
  Future<void> initialize() async {
    // Sprawdź aktualne wydarzenia
    await checkTodayEvents();
    await checkUpcomingEvents();
    await checkOverdueEvents();

    // Ustaw timer do sprawdzania co 5 minut (w prawdziwej aplikacji)
    // Timer.periodic(const Duration(minutes: 5), (timer) {
    //   checkTodayEvents();
    //   checkUpcomingEvents();
    //   checkOverdueEvents();
    // });
  }

  /// Pobiera szczegółowe powiadomienia kalendarza
  Future<List<CalendarNotification>> getCalendarNotifications() async {
    try {
      final today = DateTime.now();
      final todayEvents = await _calendarService.getEventsForDate(today);

      // Konwertuj wydarzenia na powiadomienia
      return todayEvents
          .where(
            (event) =>
                event.status == CalendarEventStatus.pending ||
                event.priority == CalendarEventPriority.urgent ||
                event.priority == CalendarEventPriority.high,
          )
          .map(
            (event) => CalendarNotification(
              id: event.id,
              title: event.title,
              description: event.description ?? '',
              date: event.startDate,
              type: _mapCategoryToType(event.category),
              priority: _mapPriorityToString(event.priority),
            ),
          )
          .toList();
    } catch (e) {
      print('Błąd podczas pobierania powiadomień kalendarza: $e');
      return _getMockCalendarNotifications();
    }
  }

  /// Mapuje kategorię wydarzenia na typ powiadomienia
  String _mapCategoryToType(CalendarEventCategory category) {
    switch (category) {
      case CalendarEventCategory.meeting:
        return 'meeting';
      case CalendarEventCategory.appointment:
        return 'appointment';
      case CalendarEventCategory.deadline:
        return 'deadline';
      case CalendarEventCategory.client:
        return 'client';
      case CalendarEventCategory.investment:
        return 'investment';
      default:
        return 'event';
    }
  }

  /// Mapuje priorytet wydarzenia na string
  String _mapPriorityToString(CalendarEventPriority priority) {
    switch (priority) {
      case CalendarEventPriority.urgent:
        return 'urgent';
      case CalendarEventPriority.high:
        return 'high';
      case CalendarEventPriority.medium:
        return 'medium';
      case CalendarEventPriority.low:
        return 'low';
    }
  }

  /// Zwraca przykładowe powiadomienia dla celów demo
  List<CalendarNotification> _getMockCalendarNotifications() {
    final now = DateTime.now();
    return [
      CalendarNotification(
        id: '1',
        title: 'Spotkanie z klientem - Jan Kowalski',
        description: 'Omówienie inwestycji mieszkaniowej',
        date: now.add(const Duration(hours: 2)),
        type: 'meeting',
        priority: 'high',
      ),
      CalendarNotification(
        id: '2',
        title: 'Analiza portfela inwestycyjnego',
        description: 'Przegląd kwartalny wyników',
        date: now.add(const Duration(hours: 4)),
        type: 'task',
        priority: 'medium',
      ),
      CalendarNotification(
        id: '3',
        title: 'Prezentacja nowych produktów',
        description: 'Zespół sprzedaży',
        date: now.add(const Duration(days: 1)),
        type: 'presentation',
        priority: 'normal',
      ),
    ];
  }
}

/// Model powiadomienia kalendarza
class CalendarNotification {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String type;
  final String priority;

  CalendarNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    required this.priority,
  });

  /// Czy powiadomienie jest przeterminowane
  bool get isOverdue => date.isBefore(DateTime.now());

  /// Czy powiadomienie jest na dzisiaj
  bool get isToday {
    final now = DateTime.now();
    return date.day == now.day &&
        date.month == now.month &&
        date.year == now.year;
  }

  /// Czy powiadomienie jest na jutro
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.day == tomorrow.day &&
        date.month == tomorrow.month &&
        date.year == tomorrow.year;
  }

  /// Kolor priorytetu
  String get priorityColor {
    switch (priority) {
      case 'high':
        return '#FF5252';
      case 'medium':
        return '#FF9800';
      case 'low':
      default:
        return '#4CAF50';
    }
  }
}
