import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme_professional.dart';
import '../../models/calendar/calendar_event.dart';
import '../../services/calendar_service.dart';
import '../../models_and_services.dart';
import '../metropolitan_logo_widget.dart';

/// Personalizowany nagłówek + karta z zadaniami na aktualny tydzień
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
      // ISO week start: Monday
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));

      final events = await _calendarService.getEventsInRange(
        startDate: DateTime(monday.year, monday.month, monday.day),
        endDate: DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59),
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
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
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
              size: 220,
              animated: true,
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
                'Jak mogę Ci pomóc dziś?',
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
                'Wydarzenia',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${_events.length} zadań',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Brak zaplanowanych zadań w tym tygodniu',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppThemePro.textSecondary),
          ),
        ],
      );
    }

    final grouped = _groupByDay(_events);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.task_alt_outlined, color: AppThemePro.accentGold),
            const SizedBox(width: 8),
            Text(
              'Moje zadania',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${_events.length} zadań',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...grouped.entries.map((entry) {
          final day = entry.key;
          final items = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                DateFormat('EEE, d MMM', 'pl_PL').format(day),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppThemePro.textTertiary,
                ),
              ),
              const SizedBox(height: 6),
              ...items.map((ev) => _buildTaskRow(ev)).toList(),
            ],
          );
        }).toList(),
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
          subtitle: ev.location != null
              ? Text(ev.location!, style: Theme.of(context).textTheme.bodySmall)
              : null,
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
