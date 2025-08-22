import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme_professional.dart';
import '../../models/calendar/calendar_event.dart';
import '../../services/calendar_service.dart';
import '../../models_and_services.dart';
import '../metropolitan_logo_widget.dart';

/// Personalizowany nagłówek + karta z zadaniami na dzisiaj i przyszłe dni
class PersonalGreetingWeekWidget extends StatefulWidget {
  final UserProfile? userProfile;

  const PersonalGreetingWeekWidget({super.key, this.userProfile});

  @override
  State<PersonalGreetingWeekWidget> createState() =>
      _PersonalGreetingWeekWidgetState();
}

class _PersonalGreetingWeekWidgetState
    extends State<PersonalGreetingWeekWidget> {
  final CalendarService _calendarService = CalendarService();
  bool _isLoading = true;
  String? _error;
  List<CalendarEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _loadWeekEvents();
  }

  Future<void> _loadWeekEvents() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Zamiast całego tygodnia, pobierz wydarzenia od dzisiaj do przyszłości
      // Pobierz wydarzenia na następne 30 dni (zamiast tylko tego tygodnia)
      final thirtyDaysFromNow = today.add(const Duration(days: 30));

      final events = await _calendarService.getEventsInRange(
        startDate: today, // Zaczynaj od dzisiaj (nie wcześniej)
        endDate: DateTime(
          thirtyDaysFromNow.year,
          thirtyDaysFromNow.month,
          thirtyDaysFromNow.day,
          23,
          59,
          59,
        ),
      );

      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Błąd ładowania zadań: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Dzień dobry';
    if (hour >= 12 && hour < 18) return 'Dzień dobry';
    return 'Dobry wieczór';
  }

  String _formatDatePL(DateTime dt) {
    final formatted = DateFormat('EEEE, d MMMM', 'pl_PL').format(dt);
    return '${formatted[0].toUpperCase()}${formatted.substring(1)}';
  }

  Map<DateTime, List<CalendarEvent>> _groupByDay(List<CalendarEvent> events) {
    final map = <DateTime, List<CalendarEvent>>{};
    for (final e in events) {
      final dateKey = DateTime(
        e.startDate.year,
        e.startDate.month,
        e.startDate.day,
      );
      map.putIfAbsent(dateKey, () => []).add(e);
    }

    // Sortuj zadania w ramach każdego dnia według godziny
    for (final entry in map.entries) {
      entry.value.sort((a, b) => a.startDate.compareTo(b.startDate));
    }

    return map;
  }

  List<MapEntry<DateTime, List<CalendarEvent>>> _getSortedDays(
    Map<DateTime, List<CalendarEvent>> grouped,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final entries = grouped.entries.toList();
    final List<MapEntry<DateTime, List<CalendarEvent>>> result = [];

    // 1. Najpierw dzisiejsze zadania (jeśli są)
    final todayEntry = entries
        .where((e) => e.key.isAtSameMomentAs(today))
        .firstOrNull;
    if (todayEntry != null) {
      result.add(todayEntry);
    }

    // 2. Potem wszystkie przyszłe dni, posortowane chronologicznie
    final futureEntries = entries
        .where((e) => e.key.isAfter(today)) // Tylko przyszłe dni
        .toList();

    // Sortuj przyszłe dni chronologicznie (od najbliższych do najdalszych)
    futureEntries.sort((a, b) => a.key.compareTo(b.key));
    result.addAll(futureEntries);

    // Uwaga: Celowo pomijamy przeszłe dni (starsze niż dzisiaj)
    // Nie dodajemy ich do wyniku

    return result;
  }

  String _formatTime(CalendarEvent event) {
    // Sprawdź czy to wydarzenie całodniowe
    final start = event.startDate;
    final end = event.endDate;

    // Jeśli to wydarzenie oznaczone jako całodniowe
    if (event.isAllDay) {
      return 'Cały dzień';
    }

    // Sprawdź czy różnica między start a end to dokładnie 24h lub więcej i start/end to północ
    final duration = end.difference(start);
    if (duration.inDays >= 1 &&
        start.hour == 0 &&
        start.minute == 0 &&
        end.hour == 0 &&
        end.minute == 0) {
      return 'Cały dzień';
    }

    // Sprawdź czy to godzina o północy (prawdopodobnie całodniowe)
    if (start.hour == 0 &&
        start.minute == 0 &&
        end.hour == 23 &&
        end.minute == 59) {
      return 'Cały dzień';
    }

    // Wydarzenia z tą samą godziną start i end (krótkie wydarzenia)
    if (start.isAtSameMomentAs(end) || duration.inMinutes <= 15) {
      return DateFormat('HH:mm').format(start);
    }

    // Wydarzenie z godziną końcową
    return '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}';
  }

  String _relativeDue(DateTime when) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(when.year, when.month, when.day);
    final diff = date.difference(today).inDays;
    if (diff == 0) return 'Dzisiaj';
    if (diff == 1) return 'Jutro';
    if (diff < 0) return '${-diff} dni temu';
    return '$diff dni';
  }

  @override
  Widget build(BuildContext context) {
    final String name = (() {
      final up = widget.userProfile;
      if (up == null) return 'Użytkowniku';
      if (up.firstName.isNotEmpty) return up.firstName;
      if (up.fullName.isNotEmpty) return up.fullName;
      return 'Użytkowniku';
    })();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo nad tekstem powitalnym - wycentrowane
        Center(
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: const MetropolitanLogoWidget.splash(
              size: 280,
              animated: false,
            ),
          ),
        ),

        // Greeting header - tekst po lewej stronie
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDatePL(DateTime.now()),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppThemePro.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_greeting()}, $name',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Jak mogę Ci dziś pomóc?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppThemePro.accentGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Tasks card for the week
        Container(
          width: double.infinity,
          decoration: AppThemePro.premiumCardDecoration,
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppThemePro.accentGold,
                  ),
                )
              : _error != null
              ? Column(
                  children: [
                    Text(_error!, style: TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadWeekEvents,
                      child: const Text('Spróbuj ponownie'),
                    ),
                  ],
                )
              : _buildTasksList(),
        ),
      ],
    );
  }

  Widget _buildTasksList() {
    if (_events.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.task_alt_outlined, color: AppThemePro.accentGold),
              const SizedBox(width: 8),
              Text(
                'Wydarzenia z kalendarza',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                'Brak wydarzeń',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Brak zaplanowanych wydarzeń na dzisiaj i najbliższe dni',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppThemePro.textSecondary),
          ),
        ],
      );
    }

    final grouped = _groupByDay(_events);
    final sortedDays = _getSortedDays(grouped);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.task_alt_outlined, color: AppThemePro.accentGold),
            const SizedBox(width: 8),
            Text(
              'Wydarzenia z kalendarza',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${_events.length} wydarzeń',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Dzisiejsze i nadchodzące wydarzenia',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppThemePro.textTertiary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 12),
        ...sortedDays.map((entry) {
          final day = entry.key;
          final items = entry.value;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final isToday = day.isAtSameMomentAs(today);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    isToday
                        ? 'Dzisiaj'
                        : DateFormat('EEE, d MMM', 'pl_PL').format(day),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isToday
                          ? AppThemePro.accentGold
                          : AppThemePro.textTertiary,
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppThemePro.accentGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${items.length}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppThemePro.accentGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              ...items.map((ev) => _buildTaskRow(ev)),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTaskRow(CalendarEvent ev) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color:
                  (ev.priority == CalendarEventPriority.high ||
                      ev.priority == CalendarEventPriority.urgent)
                  ? Colors.redAccent
                  : AppThemePro.neutralGray,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Text(ev.title, style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Godzina wydarzenia
              Text(
                _formatTime(ev),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppThemePro.accentGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Lokalizacja (jeśli jest)
              if (ev.location != null) ...[
                const SizedBox(height: 2),
                Text(
                  ev.location!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppThemePro.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ev.priority.displayName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _relativeDue(ev.startDate),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
