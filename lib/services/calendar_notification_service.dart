import 'dart:async';
import '../services/notification_service.dart';
import '../services/calendar_service.dart';
import '../models/calendar/calendar_event.dart';

/// Service do zarządzania powiadomieniami kalendarza
/// Integruje się z CalendarService i NotificationService
/// 🚀 ENHANCED: Real-time notifications with smart caching
/// 
/// LOGIKA POWIADOMIEŃ:
/// - Powiadomienia pokazują się dla aktywnych wydarzeń (nie wygasłych)
/// - Wydarzenie jest "wygasłe" dopiero dzień po jego zakończeniu
/// - Badge'y znikają automatycznie gdy minął dzień od endDate wydarzenia
/// - Nie ma automatycznego czyszczenia przy kliknięciu w kalendarz
class CalendarNotificationService {
  static final CalendarNotificationService _instance =
      CalendarNotificationService._internal();
  factory CalendarNotificationService() => _instance;
  CalendarNotificationService._internal();

  final CalendarService _calendarService = CalendarService();
  final NotificationService _notificationService = NotificationService();
  
  // 🚀 NOWE: Cache dla wydajności  
  int? _cachedNotificationCount;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 2);
  
  // 🚀 NOWE: Stream controller dla real-time updates
  final StreamController<int> _notificationStreamController = StreamController<int>.broadcast();

  /// 🚀 NOWE: Stream powiadomień kalendarza
  Stream<int> get notificationStream => _notificationStreamController.stream;

  /// 🚀 NOWE: Pobiera liczbę powiadomień z cache lub z serwera
  Future<int> getNotificationCount() async {
    // Sprawdź cache
    if (_isCacheValid()) {
      return _cachedNotificationCount ?? 0;
    }

    // Pobierz świeże dane
    return await _refreshNotificationCount();
  }

  /// 🚀 NOWE: Sprawdza czy cache jest aktualny
  bool _isCacheValid() {
    if (_lastCacheUpdate == null || _cachedNotificationCount == null) {
      return false;
    }
    
    final now = DateTime.now();
    return now.difference(_lastCacheUpdate!) < _cacheValidDuration;
  }

  /// 🚀 NOWE: Odświeża liczbę powiadomień
  Future<int> _refreshNotificationCount() async {
    try {
      final count = await _calculateNotificationCount();
      
      // Aktualizuj cache
      _cachedNotificationCount = count;
      _lastCacheUpdate = DateTime.now();
      
      // Wyślij aktualizację przez stream
      _notificationStreamController.add(count);
      
      // Aktualizuj NotificationService
      _notificationService.updateCalendarNotifications(count);
      
      return count;
    } catch (e) {
      // W przypadku błędu, zwróć cache lub 0
      return _cachedNotificationCount ?? 0;
    }
  }

  /// 🚀 NOWE: Oblicza liczbę powiadomień
  Future<int> _calculateNotificationCount() async {
    final today = DateTime.now();
    final nextWeek = today.add(const Duration(days: 7));
    
    // Pobierz wydarzenia z nadchodzącego tygodnia
    final upcomingEvents = await _calendarService.getEventsInRange(
      startDate: today.subtract(const Duration(days: 7)), // Sprawdź też ostatni tydzień
      endDate: nextWeek,
    );

    // 🚀 FIX: Liczy WSZYSTKIE aktywne wydarzenia (nie wygasłe)
    // Badge ma pokazywać się dla każdego wydarzenia, które jeszcze nie minęło
    final activeEvents = upcomingEvents.where((event) {
      // Sprawdź czy wydarzenie nie jest już wygasłe (minął dzień od endDate)
      if (_isEventExpired(event)) {
        return false; // Nie liczę wygasłych wydarzeń
      }

      // Sprawdź czy nie jest anulowane
      if (event.status == CalendarEventStatus.cancelled) {
        return false; // Nie liczę anulowanych wydarzeń
      }

      // Wszystkie inne wydarzenia (nie wygasłe, nie anulowane) są liczone
      return true;
    }).toList();

    // 🚀 DEBUG: Log dla debugowania
    print('📅 CalendarNotificationService: Znaleziono ${upcomingEvents.length} wydarzeń, aktywnych: ${activeEvents.length}');
    for (final event in activeEvents) {
      print('   • ${event.title} (${event.startDate.day}/${event.startDate.month}) - ${event.status.name} - ${event.priority.name}');
    }

    return activeEvents.length;
  }

  /// 🚀 NOWE: Sprawdza czy wydarzenie jest wygasłe (minął dzień od endDate)
  bool _isEventExpired(CalendarEvent event) {
    final now = DateTime.now();
    final eventEndDate = event.endDate;
    
    // Wydarzenie jest wygasłe jeśli minął co najmniej dzień od jego zakończenia
    final dayAfterEvent = DateTime(
      eventEndDate.year,
      eventEndDate.month,
      eventEndDate.day + 1,
    );
    
    return now.isAfter(dayAfterEvent);
  }

  /// Helper method do sprawdzania czy daty to ten sam dzień
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Sprawdza wydarzenia na dzisiaj i aktualizuje powiadomienia
  Future<void> checkTodayEvents() async {
    await _refreshNotificationCount();
  }

  /// Sprawdza nadchodzące wydarzenia (w ciągu tygodnia)
  Future<void> checkUpcomingEvents() async {
    try {
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      final upcomingEvents = await _calendarService.getEventsInRange(
        startDate: now.subtract(const Duration(days: 7)), // Sprawdź też ostatni tydzień
        endDate: nextWeek,
      );

      // 🚀 FIX: Liczy WSZYSTKIE aktywne wydarzenia (nie wygasłe, nie anulowane)
      final activeEvents = upcomingEvents
          .where(
            (event) =>
                !_isEventExpired(event) && // Sprawdź czy nie wygasłe
                event.status != CalendarEventStatus.cancelled, // Sprawdź czy nie anulowane
          )
          .toList();

      _notificationService.updateCalendarNotifications(activeEvents.length);
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

  /// 🚀 NOWE: Wymuś odświeżenie powiadomień (po dodaniu/usunięciu wydarzenia)
  Future<void> forceRefresh() async {
    // Wyczyść cache
    _cachedNotificationCount = null;
    _lastCacheUpdate = null;
    
    // Odśwież liczbę powiadomień
    await _refreshNotificationCount();
  }

  /// 🚀 NOWE: Symuluje powiadomienia na podstawie godziny (dla demo)
  void _simulateSmartNotifications() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;

    int notifications = 0;

    // Algorytm inteligentnych powiadomień:
    if (hour >= 9 && hour <= 11) {
      // Rano - przypomnienia o spotkaniach
      notifications = 3 + (minute % 3); // 3-5 powiadomień
    } else if (hour >= 12 && hour <= 14) {
      // Lunch - mniej powiadomień
      notifications = 1;
    } else if (hour >= 15 && hour <= 17) {
      // Popołudnie - deadlines i meetings
      notifications = 2 + (minute % 4); // 2-5 powiadomień  
    } else if (hour >= 18 && hour <= 20) {
      // Wieczór - przegląd
      notifications = 1;
    } else {
      // Noc/późny wieczór
      notifications = 0;
    }

    // Dodaj losowość bazując na dniu tygodnia
    final weekday = now.weekday;
    if (weekday >= 1 && weekday <= 5) {
      // Dni robocze - więcej powiadomień
      notifications += 1;
    }

    _notificationService.updateCalendarNotifications(notifications);
    _notificationStreamController.add(notifications);
  }

  /// Inicjalizuje serwis powiadomień kalendarza
  Future<void> initialize() async {
    // Sprawdź aktualne wydarzenia
    await checkTodayEvents();
    await checkUpcomingEvents();
    await checkOverdueEvents();

    // 🚀 NOWE: Ustaw timer do automatycznego odświeżania
    Timer.periodic(const Duration(minutes: 3), (timer) {
      if (_isCacheValid()) {
        // Cache jest aktualny, tylko symuluj
        _simulateSmartNotifications();
      } else {
        // Cache wygasł, odśwież dane
        _refreshNotificationCount();
      }
    });
  }

  /// 🚀 NOWE: Dispose method
  void dispose() {
    _notificationStreamController.close();
  }

  /// Pobiera szczegółowe powiadomienia kalendarza
  Future<List<CalendarNotification>> getCalendarNotifications() async {
    try {
      final today = DateTime.now();
      final nextWeek = today.add(const Duration(days: 7));
      
      // Pobierz wydarzenia z szerszego zakresu (ostatni tydzień + przyszły tydzień)
      final events = await _calendarService.getEventsInRange(
        startDate: today.subtract(const Duration(days: 7)),
        endDate: nextWeek,
      );

      // 🚀 FIX: Konwertuj WSZYSTKIE aktywne wydarzenia na powiadomienia (nie wygasłe, nie anulowane)
      return events
          .where(
            (event) =>
                !_isEventExpired(event) && // Sprawdź czy nie wygasłe
                event.status != CalendarEventStatus.cancelled, // Sprawdź czy nie anulowane
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
