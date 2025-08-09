import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/calendar/calendar_event.dart';
import '../services/calendar_service.dart';
import '../widgets/calendar/enhanced_calendar_event_dialog.dart';
import '../theme/app_theme.dart';

/// 🗓 ENHANCED CALENDAR SCREEN
/// Kompletnie przeprojektowany kalendarz z Firebase integration
class CalendarScreenEnhanced extends StatefulWidget {
  const CalendarScreenEnhanced({super.key});

  @override
  State<CalendarScreenEnhanced> createState() => _CalendarScreenEnhancedState();
}

class _CalendarScreenEnhancedState extends State<CalendarScreenEnhanced>
    with TickerProviderStateMixin {
  
  final CalendarService _calendarService = CalendarService();
  
  // Data
  List<CalendarEvent> _events = [];
  List<CalendarEvent> _filteredEvents = [];
  
  // UI State
  DateTime _selectedWeekStart = DateTime.now();
  String _selectedCategory = 'all';
  String _selectedStatus = 'all';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDateFormatting();
    _calculateWeekStart();
    _loadEvents();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
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
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

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
      _animationController.forward();
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
          final query = _searchQuery.toLowerCase();
          return event.title.toLowerCase().contains(query) ||
              (event.description?.toLowerCase().contains(query) ?? false) ||
              (event.location?.toLowerCase().contains(query) ?? false);
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
    EnhancedCalendarEventDialog.show(
      context,
      event: event,
      onEventChanged: (updatedEvent) {
        _loadEvents(); // Refresh calendar after changes
      },
    );
  }

  void _showAddEventDialog({DateTime? initialDate}) {
    EnhancedCalendarEventDialog.show(
      context,
      initialDate: initialDate ?? DateTime.now(),
      onEventChanged: (newEvent) {
        _loadEvents(); // Refresh calendar after adding
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        backgroundColor: AppTheme.primaryColor,
        tooltip: 'Dodaj przypomnienie',
        child: const Icon(Icons.add, color: AppTheme.textOnPrimary),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.gradientDecoration,
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: AppTheme.textOnPrimary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Kalendarz',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.textOnPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildHeaderActions(),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _goToToday,
          icon: const Icon(Icons.today, color: AppTheme.textOnPrimary),
          tooltip: 'Dzisiaj',
        ),
        IconButton(
          onPressed: _loadEvents,
          icon: const Icon(Icons.refresh, color: AppTheme.textOnPrimary),
          tooltip: 'Odśwież',
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_events.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildWeekNavigation(),
          _buildFilterPanel(),
          Expanded(child: _buildWeeklyCalendar()),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            'Ładowanie kalendarza...',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: AppTheme.errorColor),
          const SizedBox(height: 24),
          Text(
            'Błąd ładowania kalendarza',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.errorColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Nieznany błąd',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadEvents,
            icon: const Icon(Icons.refresh),
            label: const Text('Spróbuj ponownie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.textOnPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 80, color: AppTheme.textTertiary),
          const SizedBox(height: 24),
          Text(
            'Brak wydarzeń',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Dodaj pierwsze przypomnienie, aby rozpocząć planowanie',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddEventDialog,
            icon: const Icon(Icons.add),
            label: const Text('Dodaj przypomnienie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.textOnPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNavigation() {
    final weekStart = DateFormat('d MMM', 'pl').format(_selectedWeekStart);
    final weekEnd = DateFormat('d MMM yyyy', 'pl').format(
      _selectedWeekStart.add(const Duration(days: 6)),
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          IconButton(
            onPressed: () => _navigateWeek(-1),
            icon: const Icon(Icons.chevron_left, color: AppTheme.primaryColor),
            tooltip: 'Poprzedni tydzień',
          ),
          Expanded(
            child: Text(
              '$weekStart - $weekEnd',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _navigateWeek(1),
            icon: const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
            tooltip: 'Następny tydzień',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          _buildSearchField(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildCategoryFilter()),
              const SizedBox(width: 16),
              Expanded(child: _buildStatusFilter()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Szukaj wydarzeń...',
        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: (value) {
        setState(() => _searchQuery = value);
        _applyFilters();
      },
    );
  }

  Widget _buildCategoryFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Kategoria',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderPrimary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Wszystkie')),
        DropdownMenuItem(value: 'appointment', child: Text('Wizyty')),
        DropdownMenuItem(value: 'meeting', child: Text('Spotkania')),
        DropdownMenuItem(value: 'deadline', child: Text('Terminy')),
        DropdownMenuItem(value: 'personal', child: Text('Osobiste')),
        DropdownMenuItem(value: 'work', child: Text('Praca')),
        DropdownMenuItem(value: 'client', child: Text('Klienci')),
        DropdownMenuItem(value: 'investment', child: Text('Inwestycje')),
        DropdownMenuItem(value: 'other', child: Text('Inne')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedCategory = value);
          _applyFilters();
        }
      },
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderPrimary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Wszystkie')),
        DropdownMenuItem(value: 'confirmed', child: Text('Potwierdzone')),
        DropdownMenuItem(value: 'tentative', child: Text('Wstępne')),
        DropdownMenuItem(value: 'pending', child: Text('Oczekujące')),
        DropdownMenuItem(value: 'cancelled', child: Text('Anulowane')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedStatus = value);
          _applyFilters();
        }
      },
    );
  }

  Widget _buildWeeklyCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          _buildDaysHeader(),
          Expanded(child: _buildDaysGrid()),
        ],
      ),
    );
  }

  Widget _buildDaysHeader() {
    final dayNames = ['Pon', 'Wto', 'Śro', 'Czw', 'Pią', 'Sob', 'Nie'];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: dayNames.map((day) => Expanded(
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildDaysGrid() {
    return Row(
      children: List.generate(7, (index) {
        final day = _selectedWeekStart.add(Duration(days: index));
        final dayEvents = _getEventsForDay(day);
        final isToday = _isSameDay(day, DateTime.now());

        return Expanded(
          child: GestureDetector(
            onTap: () => _showAddEventDialog(initialDate: day),
            child: Container(
              height: double.infinity,
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: isToday 
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : null,
                border: Border.all(
                  color: AppTheme.borderSecondary,
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      day.day.toString(),
                      style: TextStyle(
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? AppTheme.primaryColor : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: dayEvents.length,
                      itemBuilder: (context, eventIndex) {
                        final event = dayEvents[eventIndex];
                        return _buildEventTile(event);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEventTile(CalendarEvent event) {
    final color = _getEventColor(event);
    
    return GestureDetector(
      onTap: () => _showEventDetails(event),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!event.isAllDay)
              Text(
                DateFormat('HH:mm').format(event.startDate),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (event.location != null && event.location!.isNotEmpty)
              Text(
                event.location!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Color _getEventColor(CalendarEvent event) {
    switch (event.category) {
      case CalendarEventCategory.meeting:
        return AppTheme.primaryColor;
      case CalendarEventCategory.deadline:
        return AppTheme.errorColor;
      case CalendarEventCategory.appointment:
        return AppTheme.warningColor;
      case CalendarEventCategory.personal:
        return AppTheme.successColor;
      case CalendarEventCategory.work:
        return AppTheme.infoColor;
      case CalendarEventCategory.investment:
        return const Color(0xFF607D8B);
      case CalendarEventCategory.client:
        return const Color(0xFFE91E63);
      case CalendarEventCategory.other:
        return AppTheme.textSecondary;
    }
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