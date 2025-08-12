import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models_and_services.dart';
import '../models/calendar/calendar_event.dart';
import '../services/calendar_service.dart';
import '../services/calendar_notification_service.dart';
import '../widgets/calendar/enhanced_calendar_event_dialog.dart';
import '../theme/app_theme_professional.dart';

/// 🗓 PROFESSIONAL ENHANCED CALENDAR SCREEN
/// Kompletnie przeprojektowany kalendarz z Firebase integration
/// Zawiera:
/// - Nawigację tygodniową z płynną animacją
/// - Złote kolory nazw dni tygodnia
/// - Badge'e powiadomień w sidebarze i dniach z wieloma wydarzeniami
/// - Ulepszone UX z mikrointerakcjami i haptic feedback
/// - Professional dark theme z gradientami
class CalendarScreenProfessional extends StatefulWidget {
  const CalendarScreenProfessional({super.key});

  @override
  State<CalendarScreenProfessional> createState() =>
      _CalendarScreenProfessionalState();
}

class _CalendarScreenProfessionalState extends State<CalendarScreenProfessional>
    with TickerProviderStateMixin {
  final CalendarService _calendarService = CalendarService();
  final CalendarNotificationService _notificationService =
      CalendarNotificationService();

  // Data
  List<CalendarEvent> _events = [];
  List<CalendarEvent> _filteredEvents = [];
  int _notificationCount = 0;

  // UI State
  DateTime _selectedWeekStart = DateTime.now();
  String _selectedCategory = 'all';
  String _selectedStatus = 'all';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;

  // Animation Controllers dla mikrointerakcji
  late AnimationController _mainAnimationController;
  late AnimationController _weekNavigationController;
  late AnimationController _microInteractionController;
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  // Animations
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _weekSlideAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDateFormatting();
    _calculateWeekStart();
    _loadEvents();
  }

  void _initializeAnimations() {
    // Main content animation
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Week navigation animation
    _weekNavigationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Micro interactions
    _microInteractionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Bounce effect dla przycisków
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Pulse effect dla powiadomień
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Shimmer effect dla loading
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Configure animations
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: Curves.easeOutQuart,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _microInteractionController,
        curve: Curves.elasticOut,
      ),
    );

    _weekSlideAnimation =
        Tween<Offset>(begin: const Offset(0.3, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _weekNavigationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Start repeating animations
    _pulseController.repeat(reverse: true);
    _shimmerController.repeat();
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
        _notificationCount = events.where((e) => _isUpcoming(e)).length;
        _isLoading = false;
      });

      _applyFilters();
      _mainAnimationController.forward();

      // Aktualizuj powiadomienia w sidebarze
      _notificationService.checkTodayEvents();
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

      // Aktualizuj liczbę powiadomień
      _notificationCount = _filteredEvents.where((e) => _isUpcoming(e)).length;
    });
  }

  bool _isUpcoming(CalendarEvent event) {
    final now = DateTime.now();
    final eventStart = event.startDate;
    return eventStart.isAfter(now) &&
        eventStart.isBefore(now.add(const Duration(days: 7)));
  }

  // Animacje i mikrointerakcje
  void _navigateWeek(int direction) {
    if (!mounted) return;

    // Uruchom animacje
    _weekNavigationController.reset();
    _weekNavigationController.forward();
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
    _triggerBounceEffect();
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

  void _triggerBounceEffect() {
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
        _loadEvents();
      },
    );
  }

  void _showAddEventDialog({DateTime? initialDate}) {
    _triggerHapticFeedback();
    _triggerBounceEffect();
    EnhancedCalendarEventDialog.show(
      context,
      initialDate: initialDate ?? DateTime.now(),
      onEventChanged: (newEvent) {
        _loadEvents();
      },
    );
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _weekNavigationController.dispose();
    _microInteractionController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemePro.backgroundPrimary,
      body: Column(
        children: [
          _buildProfessionalHeader(),
          Expanded(child: _buildMainContent()),
        ],
      ),
      floatingActionButton: _buildEnhancedFAB(),
    );
  }

  Widget _buildProfessionalHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
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
            color: Colors.black.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated calendar icon
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _bounceAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppThemePro.accentGold,
                        AppThemePro.accentGoldMuted,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppThemePro.accentGold.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: AppThemePro.primaryDark,
                    size: 28,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 20),

          // Title with notification badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Kalendarz Professional',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            color: AppThemePro.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                    ),
                    if (_notificationCount > 0) ...[
                      const SizedBox(width: 12),
                      _buildHeaderNotificationBadge(),
                    ],
                  ],
                ),
                Text(
                  'Zarządzanie wydarzeniami i terminami',
                  style: TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          _buildHeaderActions(),
        ],
      ),
    );
  }

  Widget _buildHeaderNotificationBadge() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppThemePro.statusWarning,
                  AppThemePro.statusWarning.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppThemePro.statusWarning.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_active,
                  size: 14,
                  color: AppThemePro.primaryDark,
                ),
                const SizedBox(width: 4),
                Text(
                  _notificationCount.toString(),
                  style: TextStyle(
                    color: AppThemePro.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dzisiaj button
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: AppThemePro.interactiveDecoration.copyWith(
              color: AppThemePro.surfaceCard.withOpacity(0.6),
              border: Border.all(
                color: AppThemePro.accentGold.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: IconButton(
              onPressed: _goToToday,
              icon: Icon(
                Icons.today_outlined,
                color: AppThemePro.accentGold,
                size: 22,
              ),
              tooltip: 'Przejdź do dzisiaj',
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Refresh button
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: AppThemePro.interactiveDecoration.copyWith(
              color: AppThemePro.surfaceCard.withOpacity(0.6),
              border: Border.all(
                color: AppThemePro.accentGold.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: IconButton(
              onPressed: () {
                _loadEvents();
                _triggerBounceEffect();
              },
              icon: Icon(
                Icons.refresh_rounded,
                color: AppThemePro.accentGold,
                size: 22,
              ),
              tooltip: 'Odśwież kalendarz',
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
        onPressed: _showAddEventDialog,
        backgroundColor: AppThemePro.accentGold,
        foregroundColor: AppThemePro.primaryDark,
        elevation: 12,
        heroTag: "calendar_add_event",
        icon: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppThemePro.primaryDark.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.add_circle_outline, size: 24),
        ),
        label: const Text(
          'Nowe Wydarzenie',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return _buildShimmerLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_events.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeInAnimation,
      child: Column(
        children: [
          _buildWeekNavigation(),
          _buildEnhancedFilterPanel(),
          Expanded(child: _buildProfessionalWeeklyCalendar()),
        ],
      ),
    );
  }

  Widget _buildShimmerLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Shimmer effect loading
          AnimatedBuilder(
            animation: _shimmerAnimation,
            builder: (context, child) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppThemePro.accentGold.withOpacity(0.3),
                      AppThemePro.accentGold,
                      AppThemePro.accentGold.withOpacity(0.3),
                    ],
                    stops: [
                      _shimmerAnimation.value - 0.3,
                      _shimmerAnimation.value,
                      _shimmerAnimation.value + 0.3,
                    ],
                  ),
                ),
                child: Icon(
                  Icons.calendar_month,
                  color: AppThemePro.primaryDark,
                  size: 40,
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Ładowanie kalendarza...',
            style: TextStyle(
              color: AppThemePro.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Przygotowujemy wydarzenia dla Ciebie',
            style: TextStyle(color: AppThemePro.textTertiary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: AppThemePro.premiumCardDecoration.copyWith(
          border: Border.all(
            color: AppThemePro.statusError.withOpacity(0.4),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppThemePro.statusError.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: AppThemePro.statusError,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Błąd ładowania kalendarza',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppThemePro.statusError,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Wystąpił nieznany błąd',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppThemePro.textTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadEvents,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Spróbuj ponownie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemePro.statusError,
                foregroundColor: AppThemePro.textPrimary,
                elevation: 6,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: AppThemePro.premiumCardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppThemePro.accentGold.withOpacity(0.1),
                    AppThemePro.accentGoldMuted.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.event_available_rounded,
                size: 80,
                color: AppThemePro.accentGold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Brak wydarzeń w tym tygodniu',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppThemePro.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Dodaj pierwsze wydarzenie, aby rozpocząć\nplanowanie swojego czasu',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppThemePro.textTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddEventDialog,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Dodaj pierwsze wydarzenie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemePro.accentGold,
                foregroundColor: AppThemePro.primaryDark,
                elevation: 6,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
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
        padding: const EdgeInsets.all(20),
        decoration: AppThemePro.premiumCardDecoration,
        child: Row(
          children: [
            // Poprzedni tydzień
            _buildWeekNavigationButton(
              onPressed: () => _navigateWeek(-1),
              icon: Icons.chevron_left_rounded,
              tooltip: 'Poprzedni tydzień',
            ),

            // Aktualny zakres tygodnia
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '$weekStart - $weekEnd',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppThemePro.textPrimary,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // Następny tydzień
            _buildWeekNavigationButton(
              onPressed: () => _navigateWeek(1),
              icon: Icons.chevron_right_rounded,
              tooltip: 'Następny tydzień',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekNavigationButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String tooltip,
  }) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppThemePro.surfaceElevated,
              AppThemePro.surfaceInteractive,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppThemePro.accentGold.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppThemePro.accentGold.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: AppThemePro.accentGold, size: 28),
          tooltip: tooltip,
        ),
      ),
    );
  }

  Widget _buildEnhancedFilterPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list_rounded,
                color: AppThemePro.accentGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Filtrowanie wydarzeń',
                style: TextStyle(
                  color: AppThemePro.accentGold,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Wyszukaj wydarzenia, lokalizację...',
          hintStyle: TextStyle(color: AppThemePro.textTertiary, fontSize: 14),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_rounded,
              color: AppThemePro.accentGold,
              size: 20,
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    setState(() => _searchQuery = '');
                    _applyFilters();
                  },
                  icon: Icon(
                    Icons.clear_rounded,
                    color: AppThemePro.textTertiary,
                    size: 18,
                  ),
                )
              : null,
          filled: true,
          fillColor: AppThemePro.surfaceInteractive,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppThemePro.borderPrimary.withOpacity(0.5),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppThemePro.accentGold, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: TextStyle(color: AppThemePro.textPrimary, fontSize: 14),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _applyFilters();
          if (value.isNotEmpty) _triggerMicroInteraction();
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: InputDecoration(
          labelText: 'Kategoria',
          labelStyle: TextStyle(
            color: AppThemePro.accentGold,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.category_rounded,
            color: AppThemePro.accentGold,
            size: 20,
          ),
          filled: true,
          fillColor: AppThemePro.surfaceInteractive,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppThemePro.borderPrimary.withOpacity(0.5),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppThemePro.accentGold, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        dropdownColor: AppThemePro.surfaceCard,
        style: TextStyle(color: AppThemePro.textPrimary, fontSize: 14),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('Wszystkie')),
          DropdownMenuItem(value: 'appointment', child: Text('📅 Wizyty')),
          DropdownMenuItem(value: 'meeting', child: Text('🤝 Spotkania')),
          DropdownMenuItem(value: 'deadline', child: Text('⏰ Terminy')),
          DropdownMenuItem(value: 'personal', child: Text('👤 Osobiste')),
          DropdownMenuItem(value: 'work', child: Text('💼 Praca')),
          DropdownMenuItem(value: 'client', child: Text('🏢 Klienci')),
          DropdownMenuItem(value: 'investment', child: Text('📊 Inwestycje')),
          DropdownMenuItem(value: 'other', child: Text('📋 Inne')),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedCategory = value);
            _applyFilters();
            _triggerMicroInteraction();
          }
        },
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedStatus,
        decoration: InputDecoration(
          labelText: 'Status',
          labelStyle: TextStyle(
            color: AppThemePro.accentGold,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.flag_rounded,
            color: AppThemePro.accentGold,
            size: 20,
          ),
          filled: true,
          fillColor: AppThemePro.surfaceInteractive,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppThemePro.borderPrimary.withOpacity(0.5),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppThemePro.accentGold, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        dropdownColor: AppThemePro.surfaceCard,
        style: TextStyle(color: AppThemePro.textPrimary, fontSize: 14),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('Wszystkie')),
          DropdownMenuItem(value: 'confirmed', child: Text('✅ Potwierdzone')),
          DropdownMenuItem(value: 'tentative', child: Text('❓ Wstępne')),
          DropdownMenuItem(value: 'pending', child: Text('⏳ Oczekujące')),
          DropdownMenuItem(value: 'cancelled', child: Text('❌ Anulowane')),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedStatus = value);
            _applyFilters();
            _triggerMicroInteraction();
          }
        },
      ),
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
    final dayNames = [
      'Poniedziałek',
      'Wtorek',
      'Środa',
      'Czwartek',
      'Piątek',
      'Sobota',
      'Niedziela',
    ];
    final dayShortNames = ['Pon', 'Wto', 'Śro', 'Czw', 'Pią', 'Sob', 'Nie'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppThemePro.accentGold.withOpacity(0.05),
            AppThemePro.accentGold.withOpacity(0.15),
            AppThemePro.accentGoldMuted.withOpacity(0.15),
            AppThemePro.accentGold.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppThemePro.accentGold.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: List.generate(7, (index) {
          final isWeekend = index >= 5; // Sobota i niedziela
          return Expanded(
            child: Column(
              children: [
                Text(
                  dayShortNames[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isWeekend
                        ? AppThemePro.accentGoldMuted
                        : AppThemePro.accentGold,
                    fontSize: 16,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 3,
                  width: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isWeekend
                          ? [
                              AppThemePro.accentGoldMuted.withOpacity(0.3),
                              AppThemePro.accentGoldMuted,
                            ]
                          : [
                              AppThemePro.accentGold.withOpacity(0.3),
                              AppThemePro.accentGold,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDaysGrid() {
    return Row(
      children: List.generate(7, (index) {
        final day = _selectedWeekStart.add(Duration(days: index));
        final dayEvents = _getEventsForDay(day);
        final isToday = _isSameDay(day, DateTime.now());
        final isWeekend = index >= 5;
        final hasMultipleNotifications = dayEvents.length > 3;

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
                gradient: isToday
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppThemePro.accentGold.withOpacity(0.15),
                          AppThemePro.accentGold.withOpacity(0.05),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          AppThemePro.backgroundSecondary,
                          AppThemePro.surfaceCard,
                        ],
                      ),
                border: Border.all(
                  color: isToday
                      ? AppThemePro.accentGold.withOpacity(0.4)
                      : AppThemePro.borderSecondary.withOpacity(0.3),
                  width: isToday ? 2 : 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Header z datą i badge'ami
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: isToday
                          ? LinearGradient(
                              colors: [
                                AppThemePro.accentGold.withOpacity(0.1),
                                Colors.transparent,
                              ],
                            )
                          : null,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: isToday
                              ? BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppThemePro.accentGold,
                                      AppThemePro.accentGoldMuted,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppThemePro.accentGold.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                )
                              : null,
                          child: Text(
                            day.day.toString(),
                            style: TextStyle(
                              fontWeight: isToday
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isToday
                                  ? AppThemePro.primaryDark
                                  : (isWeekend
                                        ? AppThemePro.accentGoldMuted
                                        : AppThemePro.textPrimary),
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (hasMultipleNotifications) ...[
                          const SizedBox(width: 6),
                          _buildDayNotificationBadge(dayEvents.length),
                        ],
                      ],
                    ),
                  ),

                  // Lista wydarzeń
                  Expanded(
                    child: dayEvents.isEmpty
                        ? Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppThemePro.surfaceInteractive
                                    .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.add_circle_outline,
                                color: AppThemePro.textTertiary.withOpacity(
                                  0.6,
                                ),
                                size: 20,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            itemCount: dayEvents.length,
                            itemBuilder: (context, eventIndex) {
                              final event = dayEvents[eventIndex];
                              return _buildEnhancedEventTile(event, isToday);
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

  Widget _buildDayNotificationBadge(int count) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value * 0.8 + 0.2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppThemePro.statusWarning,
                  AppThemePro.statusWarning.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppThemePro.statusWarning.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              count > 9 ? '9+' : count.toString(),
              style: TextStyle(
                color: AppThemePro.primaryDark,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedEventTile(CalendarEvent event, bool isToday) {
    final color = _getEventColor(event);

    return GestureDetector(
      onTap: () {
        _showEventDetails(event);
        _triggerMicroInteraction();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.85), color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
            if (isToday)
              BoxShadow(
                color: AppThemePro.accentGold.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Czas wydarzenia
            if (!event.isAllDay) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  DateFormat('HH:mm').format(event.startDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],

            // Tytuł wydarzenia
            Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Lokalizacja
            if (event.location != null && event.location!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
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
