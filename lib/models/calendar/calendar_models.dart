import 'calendar_event.dart';

/// Typ widoku kalendarza
enum CalendarViewType {
  month('Miesiąc'),
  week('Tydzień'),
  day('Dzień'),
  year('Rok'),
  agenda('Lista');

  const CalendarViewType(this.displayName);

  final String displayName;
}

/// Konfiguracja widoku kalendarza
class CalendarViewConfig {
  final CalendarViewType viewType;
  final DateTime currentDate;
  final bool showWeekends;
  final bool showAllDay;
  final int workingHoursStart;
  final int workingHoursEnd;
  final List<String> visibleCategories;
  final bool showGrid;
  final bool showTimeLabels;

  CalendarViewConfig({
    required this.viewType,
    required this.currentDate,
    this.showWeekends = true,
    this.showAllDay = true,
    this.workingHoursStart = 8,
    this.workingHoursEnd = 18,
    this.visibleCategories = const [],
    this.showGrid = true,
    this.showTimeLabels = true,
  });

  CalendarViewConfig copyWith({
    CalendarViewType? viewType,
    DateTime? currentDate,
    bool? showWeekends,
    bool? showAllDay,
    int? workingHoursStart,
    int? workingHoursEnd,
    List<String>? visibleCategories,
    bool? showGrid,
    bool? showTimeLabels,
  }) {
    return CalendarViewConfig(
      viewType: viewType ?? this.viewType,
      currentDate: currentDate ?? this.currentDate,
      showWeekends: showWeekends ?? this.showWeekends,
      showAllDay: showAllDay ?? this.showAllDay,
      workingHoursStart: workingHoursStart ?? this.workingHoursStart,
      workingHoursEnd: workingHoursEnd ?? this.workingHoursEnd,
      visibleCategories: visibleCategories ?? this.visibleCategories,
      showGrid: showGrid ?? this.showGrid,
      showTimeLabels: showTimeLabels ?? this.showTimeLabels,
    );
  }
}

/// Filtr wydarzeń kalendarza
class CalendarEventFilter {
  final List<String> categories;
  final List<String> participants;
  final List<String> statuses;
  final List<String> priorities;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;
  final bool showAllDay;
  final bool showRecurring;

  CalendarEventFilter({
    this.categories = const [],
    this.participants = const [],
    this.statuses = const [],
    this.priorities = const [],
    this.startDate,
    this.endDate,
    this.searchQuery,
    this.showAllDay = true,
    this.showRecurring = true,
  });

  CalendarEventFilter copyWith({
    List<String>? categories,
    List<String>? participants,
    List<String>? statuses,
    List<String>? priorities,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    bool? showAllDay,
    bool? showRecurring,
  }) {
    return CalendarEventFilter(
      categories: categories ?? this.categories,
      participants: participants ?? this.participants,
      statuses: statuses ?? this.statuses,
      priorities: priorities ?? this.priorities,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
      showAllDay: showAllDay ?? this.showAllDay,
      showRecurring: showRecurring ?? this.showRecurring,
    );
  }

  /// Sprawdza czy filtr jest pusty
  bool get isEmpty {
    return categories.isEmpty &&
        participants.isEmpty &&
        statuses.isEmpty &&
        priorities.isEmpty &&
        startDate == null &&
        endDate == null &&
        (searchQuery?.isEmpty ?? true);
  }
}

/// Stan kalendarza
class CalendarState {
  final List<CalendarEvent> events;
  final CalendarViewConfig viewConfig;
  final CalendarEventFilter filter;
  final bool isLoading;
  final String? error;
  final CalendarEvent? selectedEvent;
  final DateTime? selectedDate;

  CalendarState({
    this.events = const [],
    required this.viewConfig,
    CalendarEventFilter? filter,
    this.isLoading = false,
    this.error,
    this.selectedEvent,
    this.selectedDate,
  }) : filter = filter ?? CalendarEventFilter();

  CalendarState copyWith({
    List<CalendarEvent>? events,
    CalendarViewConfig? viewConfig,
    CalendarEventFilter? filter,
    bool? isLoading,
    String? error,
    CalendarEvent? selectedEvent,
    DateTime? selectedDate,
  }) {
    return CalendarState(
      events: events ?? this.events,
      viewConfig: viewConfig ?? this.viewConfig,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedEvent: selectedEvent ?? this.selectedEvent,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }

  /// Zwraca wydarzenia dla określonego dnia
  List<CalendarEvent> getEventsForDate(DateTime date) {
    return events.where((event) => event.occursOnDate(date)).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  /// Zwraca wydarzenia w określonym zakresie dat
  List<CalendarEvent> getEventsInRange(DateTime start, DateTime end) {
    return events.where((event) => event.isActiveInPeriod(start, end)).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  /// Zwraca filtrowane wydarzenia
  List<CalendarEvent> get filteredEvents {
    if (filter.isEmpty) return events;

    return events.where((event) {
      // Filtr kategorii
      if (filter.categories.isNotEmpty &&
          !filter.categories.contains(event.category.name)) {
        return false;
      }

      // Filtr uczestników
      if (filter.participants.isNotEmpty &&
          !event.participants.any((p) => filter.participants.contains(p))) {
        return false;
      }

      // Filtr statusu
      if (filter.statuses.isNotEmpty &&
          !filter.statuses.contains(event.status.name)) {
        return false;
      }

      // Filtr priorytetu
      if (filter.priorities.isNotEmpty &&
          !filter.priorities.contains(event.priority.name)) {
        return false;
      }

      // Filtr dat
      if (filter.startDate != null &&
          event.endDate.isBefore(filter.startDate!)) {
        return false;
      }
      if (filter.endDate != null && event.startDate.isAfter(filter.endDate!)) {
        return false;
      }

      // Filtr wyszukiwania
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase();
        if (!event.title.toLowerCase().contains(query) &&
            !(event.description?.toLowerCase().contains(query) ?? false) &&
            !(event.location?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Filtr całodniowych
      if (!filter.showAllDay && event.isAllDay) {
        return false;
      }

      // Filtr powtarzających się
      if (!filter.showRecurring && event.recurrence != null) {
        return false;
      }

      return true;
    }).toList();
  }
}
