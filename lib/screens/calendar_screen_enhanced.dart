import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/calendar/calendar_event.dart';
import '../services/calendar_service.dart';
import '../widgets/calendar/enhanced_calendar_event_dialog.dart';
import '../theme/app_theme_professional.dart';

/// 🗓 PROFESSIONAL ENHANCED CALENDAR SCREEN
/// Kompletnie przeprojektowany kalendarz z Firebase integration
/// Zawiera: nawigację tygodniową, złote kolory dni, badge'e powiadomień
/// oraz ulepszone UX z mikrointerakcjami
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

  // Animation Controllers
  late AnimationController _animationController;
  late AnimationController _weekNavigationController;
  late AnimationController _microInteractionController;
  late AnimationController _bounceController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _weekSlideAnimation;
  late Animation<double> _bounceAnimation;

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

    _weekNavigationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _microInteractionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _microInteractionController,
        curve: Curves.elasticOut,
      ),
    );

    _weekSlideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _weekNavigationController,
            curve: Curves.easeInOutCubic,
          ),
        );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
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

    // Uruchom animację zmiany tygodnia
    _weekNavigationController.reset();
    _weekNavigationController.forward();

    // Mikrointerakcja z vibracją
    _triggerMicroInteraction();
    _triggerHapticFeedback();

    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(
        Duration(days: 7 * direction),
      );
    });
    _loadEvents();
  }

  void _goToToday() {
    _triggerMicroInteraction();
    _triggerHapticFeedback();
    _calculateWeekStart();
    _loadEvents();
  }

  void _triggerMicroInteraction() {
    _microInteractionController.reset();
    _microInteractionController.forward();
  }

  void _triggerHapticFeedback() {
    HapticFeedback.lightImpact();
  }

  void _triggerBounce() {
    _bounceController.reset();
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });
  }

  void _showEventDetails(CalendarEvent event) {
    _triggerHapticFeedback();
    EnhancedCalendarEventDialog.show(
      context,
      event: event,
      onEventChanged: (updatedEvent) {
        _loadEvents(); // Refresh calendar after changes
      },
    );
  }

  void _showAddEventDialog({DateTime? initialDate}) {
    _triggerHapticFeedback();
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
    _weekNavigationController.dispose();
    _microInteractionController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemePro.backgroundPrimary,
      body: Column(
        children: [
          _buildProfessionalHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _buildEnhancedFAB(),
    );
  }

  Widget _buildProfessionalHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.primaryDark,
            AppThemePro.primaryMedium,
            AppThemePro.primaryLight,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _bounceAnimation.value,
                child: Icon(
                  Icons.calendar_today,
                  color: AppThemePro.accentGold,
                  size: 28,
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Kalendarz Professional',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppThemePro.textPrimary,
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
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: AppThemePro.surfaceCard.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppThemePro.accentGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () {
                _goToToday();
                _triggerBounce();
              },
              icon: const Icon(Icons.today, color: AppThemePro.accentGold),
              tooltip: 'Dzisiaj',
            ),
          ),
        ),
        const SizedBox(width: 8),
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: AppThemePro.surfaceCard.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppThemePro.accentGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () {
                _loadEvents();
                _triggerBounce();
              },
              icon: const Icon(Icons.refresh, color: AppThemePro.accentGold),
              tooltip: 'Odśwież',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedFAB() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton.extended(
        onPressed: () {
          _showAddEventDialog();
          _triggerBounce();
        },
        backgroundColor: AppThemePro.accentGold,
        foregroundColor: AppThemePro.primaryDark,
        elevation: 8,
        icon: const Icon(Icons.add_circle_outline, size: 24),
        label: const Text(
          'Nowe Wydarzenie',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
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
          _buildEnhancedFilterPanel(),
          Expanded(child: _buildProfessionalWeeklyCalendar()),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppThemePro.accentGold,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Ładowanie kalendarza...',
            style: TextStyle(
              color: AppThemePro.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: AppThemePro.premiumCardDecoration.copyWith(
          border: Border.all(
            color: AppThemePro.statusError.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 80, color: AppThemePro.statusError),
            const SizedBox(height: 24),
            Text(
              'Błąd ładowania kalendarza',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppThemePro.statusError,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Nieznany błąd',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppThemePro.textTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadEvents,
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemePro.statusError,
                foregroundColor: AppThemePro.textPrimary,
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: AppThemePro.premiumCardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available,
              size: 80,
              color: AppThemePro.textTertiary,
            ),
            const SizedBox(height: 24),
            Text(
              'Brak wydarzeń',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppThemePro.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Dodaj pierwsze przypomnienie, aby rozpocząć planowanie',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppThemePro.textTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddEventDialog,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj przypomnienie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemePro.accentGold,
                foregroundColor: AppThemePro.primaryDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekNavigation() {
    final weekStart = DateFormat('d MMM', 'pl').format(_selectedWeekStart);
    final weekEnd = DateFormat(
      'd MMM yyyy',
      'pl',
    ).format(_selectedWeekStart.add(const Duration(days: 6)));

    return SlideTransition(
      position: _weekSlideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: AppThemePro.premiumCardDecoration,
        child: Row(
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: AppThemePro.surfaceInteractive,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppThemePro.accentGold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () => _navigateWeek(-1),
                  icon: Icon(
                    Icons.chevron_left,
                    color: AppThemePro.accentGold,
                    size: 24,
                  ),
                  tooltip: 'Poprzedni tydzień',
                ),
              ),
            ),
            Expanded(
              child: Text(
                '$weekStart - $weekEnd',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppThemePro.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: AppThemePro.surfaceInteractive,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppThemePro.accentGold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () => _navigateWeek(1),
                  icon: Icon(
                    Icons.chevron_right,
                    color: AppThemePro.accentGold,
                    size: 24,
                  ),
                  tooltip: 'Następny tydzień',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedFilterPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        children: [
          _buildProfessionalSearchField(),
          const SizedBox(height: 16),
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

  Widget _buildProfessionalSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Szukaj wydarzeń...',
        prefixIcon: Icon(Icons.search, color: AppThemePro.accentGold),
        filled: true,
        fillColor: AppThemePro.surfaceInteractive,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppThemePro.borderPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppThemePro.borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppThemePro.accentGold, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      style: TextStyle(color: AppThemePro.textPrimary),
      onChanged: (value) {
        setState(() => _searchQuery = value);
        _applyFilters();
        _triggerMicroInteraction();
      },
    );
  }

  Widget _buildCategoryFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Kategoria',
        labelStyle: TextStyle(color: AppThemePro.accentGold),
        filled: true,
        fillColor: AppThemePro.surfaceInteractive,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppThemePro.borderPrimary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      dropdownColor: AppThemePro.surfaceCard,
      style: TextStyle(color: AppThemePro.textPrimary),
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
          _triggerMicroInteraction();
        }
      },
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: InputDecoration(
        labelText: 'Status',
        labelStyle: TextStyle(color: AppThemePro.accentGold),
        filled: true,
        fillColor: AppThemePro.surfaceInteractive,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppThemePro.borderPrimary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      dropdownColor: AppThemePro.surfaceCard,
      style: TextStyle(color: AppThemePro.textPrimary),
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
          _triggerMicroInteraction();
        }
      },
    );
  }

  Widget _buildProfessionalWeeklyCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        children: [
          _buildGoldenDaysHeader(),
          Expanded(child: _buildDaysGrid()),
        ],
      ),
    );
  }

  Widget _buildGoldenDaysHeader() {
    final dayNames = ['Pon', 'Wto', 'Śro', 'Czw', 'Pią', 'Sob', 'Nie'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppThemePro.accentGold.withOpacity(0.1),
            AppThemePro.accentGoldMuted.withOpacity(0.15),
            AppThemePro.accentGold.withOpacity(0.1),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: dayNames
            .map(
              (day) => Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppThemePro.accentGold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDaysGrid() {
    return Row(
      children: List.generate(7, (index) {
        final day = _selectedWeekStart.add(Duration(days: index));
        final dayEvents = _getEventsForDay(day);
        final isToday = _isSameDay(day, DateTime.now());
        final hasNotifications = dayEvents.length > 2;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              _showAddEventDialog(initialDate: day);
              _triggerMicroInteraction();
            },
            child: Container(
              height: double.infinity,
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: isToday
                    ? AppThemePro.accentGold.withOpacity(0.1)
                    : AppThemePro.surfaceCard,
                border: Border.all(
                  color: isToday
                      ? AppThemePro.accentGold.withOpacity(0.3)
                      : AppThemePro.borderSecondary,
                  width: isToday ? 2 : 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day.day.toString(),
                          style: TextStyle(
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isToday
                                ? AppThemePro.accentGold
                                : AppThemePro.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        if (hasNotifications) ...[
                          const SizedBox(width: 4),
                          _buildNotificationBadge(dayEvents.length),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: dayEvents.length,
                      itemBuilder: (context, eventIndex) {
                        final event = dayEvents[eventIndex];
                        return _buildEnhancedEventTile(event);
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

  Widget _buildNotificationBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppThemePro.accentGold, AppThemePro.accentGoldMuted],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.accentGold.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          color: AppThemePro.primaryDark,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEnhancedEventTile(CalendarEvent event) {
    final color = _getEventColor(event);

    return GestureDetector(
      onTap: () {
        _showEventDetails(event);
        _triggerMicroInteraction();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!event.isAllDay)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  DateFormat('HH:mm').format(event.startDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (!event.isAllDay) const SizedBox(height: 4),
            Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (event.location != null && event.location!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.location_on, size: 10, color: Colors.white70),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      event.location!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getEventColor(CalendarEvent event) {
    switch (event.category) {
      case CalendarEventCategory.meeting:
        return AppThemePro.accentGold;
      case CalendarEventCategory.deadline:
        return AppThemePro.statusError;
      case CalendarEventCategory.appointment:
        return AppThemePro.statusWarning;
      case CalendarEventCategory.personal:
        return AppThemePro.statusSuccess;
      case CalendarEventCategory.work:
        return AppThemePro.statusInfo;
      case CalendarEventCategory.investment:
        return AppThemePro.realEstateViolet;
      case CalendarEventCategory.client:
        return const Color(0xFFE91E63);
      case CalendarEventCategory.other:
        return AppThemePro.textSecondary;
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
