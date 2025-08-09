import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/calendar/calendar_event.dart';
import '../services/calendar_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarService _calendarService = CalendarService();

  List<CalendarEvent> _events = [];
  List<CalendarEvent> _filteredEvents = [];

  DateTime _selectedWeekStart = DateTime.now();
  String _selectedCategory = 'all';
  String _selectedStatus = 'all';
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    _calculateWeekStart();
    _loadEvents();
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('pl', null);
  }

  void _calculateWeekStart() {
    final now = DateTime.now();
    final weekday = now.weekday;
    _selectedWeekStart = now.subtract(Duration(days: weekday - 1));
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final events = await _calendarService.getEventsInRange(
        startDate: _selectedWeekStart,
        endDate: _selectedWeekStart.add(const Duration(days: 7)),
      );

      if (!mounted) return;
      setState(() {
        _events = events;
        _filteredEvents = events;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas ładowania wydarzeń: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    if (!mounted) return;
    setState(() {
      _filteredEvents = _events.where((event) {
        // Category filter
        if (_selectedCategory != 'all' &&
            event.category.name != _selectedCategory) {
          return false;
        }

        // Status filter
        if (_selectedStatus != 'all' && event.status.name != _selectedStatus) {
          return false;
        }

        // Search filter
        if (_searchQuery.isNotEmpty) {
          return event.title.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              (event.description?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false) ||
              (event.location?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false);
        }

        return true;
      }).toList();
    });
  }

  void _navigateWeek(int direction) {
    if (!mounted) return;
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(
        Duration(days: 7 * direction),
      );
    });
    _loadEvents();
  }

  void _goToToday() {
    _calculateWeekStart();
    _loadEvents();
  }

  void _showEventDetails(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => _buildEventDialog(event),
    );
  }

  void _showAddEventDialog() {
    final authProvider = context.read<AuthProvider>();
    final now = DateTime.now();

    final newEvent = CalendarEvent(
      id: '',
      title: '',
      startDate: now,
      endDate: now.add(const Duration(hours: 1)),
      category: CalendarEventCategory.other,
      createdBy: authProvider.user?.uid ?? '',
      createdAt: now,
      updatedAt: now,
    );

    showDialog(
      context: context,
      builder: (context) => _buildEventDialog(newEvent, isNew: true),
    );
  }

  Widget _buildEventDialog(CalendarEvent event, {bool isNew = false}) {
    return AlertDialog(
      title: Text(isNew ? 'Nowe wydarzenie' : 'Szczegóły wydarzenia'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tytuł: ${event.title}'),
            const SizedBox(height: 8),
            Text(
              'Data: ${DateFormat('dd.MM.yyyy HH:mm').format(event.startDate)}',
            ),
            const SizedBox(height: 8),
            Text('Czas trwania: ${event.duration.inMinutes} min'),
            if (event.location != null && event.location!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Lokalizacja: ${event.location}'),
            ],
            if (event.description != null && event.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Opis: ${event.description}'),
            ],
            const SizedBox(height: 8),
            Text('Kategoria: ${event.category.displayName}'),
            const SizedBox(height: 8),
            Text('Status: ${event.status.displayName}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Zamknij'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Kalendarz'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEventDialog,
            tooltip: 'Dodaj wydarzenie',
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
            tooltip: 'Dziś',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Odśwież',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWeekNavigation(),
          _buildFilterPanel(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildWeeklyCalendar(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNavigation() {
    final weekStart = DateFormat('d MMM', 'pl').format(_selectedWeekStart);
    final weekEnd = DateFormat(
      'd MMM yyyy',
      'pl',
    ).format(_selectedWeekStart.add(const Duration(days: 6)));

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _navigateWeek(-1),
          ),
          Text(
            '$weekStart - $weekEnd',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _navigateWeek(1),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              key: const Key('calendar_search_field'),
              decoration: const InputDecoration(
                hintText: 'Szukaj wydarzeń...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (!mounted) return;
                setState(() => _searchQuery = value);
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategoria',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('Wszystkie')),
                ...CalendarEventCategory.values.map(
                  (category) => DropdownMenuItem(
                    value: category.name,
                    child: Text(category.displayName),
                  ),
                ),
              ],
              onChanged: (value) {
                if (!mounted) return;
                setState(() => _selectedCategory = value ?? 'all');
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Wszystkie')),
                DropdownMenuItem(
                  value: 'confirmed',
                  child: Text('Potwierdzone'),
                ),
                DropdownMenuItem(value: 'pending', child: Text('Oczekujące')),
                DropdownMenuItem(value: 'cancelled', child: Text('Anulowane')),
              ],
              onChanged: (value) {
                if (!mounted) return;
                setState(() => _selectedStatus = value ?? 'all');
                _applyFilters();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Headers for days of week
          _buildWeekHeaders(),
          const SizedBox(height: 16),

          // Calendar grid
          Expanded(child: _buildWeekGrid()),
        ],
      ),
    );
  }

  Widget _buildWeekHeaders() {
    return Row(
      children: List.generate(7, (index) {
        final date = _selectedWeekStart.add(Duration(days: index));
        final dayName = DateFormat('EEE', 'pl').format(date);
        final dayNumber = DateFormat('d', 'pl').format(date);
        final isToday = _isSameDay(date, DateTime.now());

        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: isToday
                ? BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Column(
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isToday ? Colors.white : null,
                  ),
                ),
                Text(
                  dayNumber,
                  style: TextStyle(color: isToday ? Colors.white : null),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWeekGrid() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(7, (dayIndex) {
        final date = _selectedWeekStart.add(Duration(days: dayIndex));
        final eventsForDay = _getEventsForDay(date);

        return Expanded(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: eventsForDay.map((event) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(event.category.colorValue).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: GestureDetector(
                      onTap: () => _showEventDetails(event),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('HH:mm').format(event.startDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (event.location != null &&
                              event.location!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              event.location!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      }),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _filteredEvents
        .where((event) => _isSameDay(event.startDate, day))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }
}
