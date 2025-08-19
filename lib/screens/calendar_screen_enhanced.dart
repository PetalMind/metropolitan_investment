import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/calendar/calendar_event.dart';
import '../services/calendar_service.dart';
import '../services/calendar_notification_service.dart'; // 🚀 NOWE
import '../widgets/calendar/enhanced_calendar_event_dialog.dart';
import '../theme/app_theme_professional.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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
  final CalendarNotificationService _notificationService =
      CalendarNotificationService(); // 🚀 NOWE

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

    // Mikrointerakcja z vibracją i bounce dla odpowiedniej strzałki
    _triggerMicroInteraction();
    _triggerHapticFeedback();
    _triggerBounce(); // 🚀 NOWE: Animacja strzałki

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
        _notificationService.forceRefresh(); // 🚀 NOWE: Odśwież powiadomienia
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
        _notificationService.forceRefresh(); // 🚀 NOWE: Odśwież powiadomienia
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
  // RBAC: tylko admin może dodawać / edytować wydarzenia
  final authProvider = Provider.of<AuthProvider>(context, listen: true);
  final canEdit = authProvider.isAdmin;
    return Scaffold(
      backgroundColor: AppThemePro.backgroundPrimary,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          // 🚀 NOWE: Obsługa klawiszy strzałek dla nawigacji
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.keyA) {
              _navigateWeek(-1);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.keyD) {
              _navigateWeek(1);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyT ||
                event.logicalKey == LogicalKeyboardKey.home) {
              _goToToday();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          children: [
            _buildProfessionalHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
  floatingActionButton: _buildEnhancedFAB(canEdit: canEdit),
    );
  }

  Widget _buildProfessionalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ), // 🚀 Zmniejszono padding
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
            color: Colors.black.withValues(alpha: 0.2), // 🚀 Zmniejszono shadow
            blurRadius: 12, // 🚀 Zmniejszono blur
            offset: const Offset(0, 4), // 🚀 Zmniejszono offset
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Tooltip(
                message:
                    'Skróty klawiszowe:\n← → A D - Nawigacja tygodniowa\nT Home - Dzisiaj',
                textStyle: TextStyle(fontSize: 12),
                child: Transform.scale(
                  scale: _bounceAnimation.value,
                  child: Icon(
                    Icons.calendar_today,
                    color: AppThemePro.accentGold,
                    size: 24, // 🚀 Zmniejszono rozmiar ikony
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12), // 🚀 Zmniejszono odstęp
          Expanded(
            child: Text(
              'Kalendarz',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                // 🚀 Zmniejszono rozmiar tekstu
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

  Widget _buildEnhancedFAB({required bool canEdit}) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton.extended(
        onPressed: canEdit
            ? () {
                _showAddEventDialog();
                _triggerBounce();
              }
            : null,
        backgroundColor: AppThemePro.accentGold,
        foregroundColor: AppThemePro.primaryDark,
        elevation: 8,
        icon: const Icon(Icons.add_circle_outline, size: 24),
        label: Text(
          canEdit ? 'Nowe Wydarzenie' : 'Tylko podgląd',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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

    // 🚀 ZMIANA: Zawsze pokazuj kalendarz, nawet gdy brak wydarzeń
    return FadeTransition(
      opacity: _fadeAnimation,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 🚀 NOWE: Responsywny layout bazujący na szerokości ekranu
          final isMobile = constraints.maxWidth < 600;
          final isTablet =
              constraints.maxWidth >= 600 && constraints.maxWidth < 1024;

          return Column(
            children: [
              _buildWeekNavigation(),
              if (!isMobile) // 🚀 Na mobile ukryj panel filtrów domyślnie
                _buildEnhancedFilterPanel(),
              if (isMobile) // 🚀 Na mobile dodaj kompaktowy przycisk filtrów
                _buildMobileFilterButton(),
              Expanded(
                child: Row(
                  children: [
                    // 🚀 NOWE: Lewa strzałka nawigacji - DUŻA I WIDOCZNA
                    _buildMainNavigationArrow(
                      onTap: () => _navigateWeek(-1),
                      icon: Icons.chevron_left,
                      tooltip: 'Poprzedni tydzień',
                      isLeft: true,
                      isMobile: isMobile,
                    ),

                    // Główny obszar kalendarza
                    Expanded(
                      child: _buildResponsiveWeeklyCalendar(
                        isMobile: isMobile,
                        isTablet: isTablet,
                      ),
                    ),

                    // 🚀 NOWE: Prawa strzałka nawigacji - DUŻA I WIDOCZNA
                    _buildMainNavigationArrow(
                      onTap: () => _navigateWeek(1),
                      icon: Icons.chevron_right,
                      tooltip: 'Następny tydzień',
                      isLeft: false,
                      isMobile: isMobile,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 🚀 NOWE: Kompaktowy przycisk filtrów dla mobile
  Widget _buildMobileFilterButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _showMobileFilterDialog();
              },
              icon: Icon(Icons.filter_list, size: 16),
              label: Text('Filtry', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemePro.surfaceInteractive,
                foregroundColor: AppThemePro.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppThemePro.borderPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🚀 NOWE: Dialog filtrów dla mobile
  void _showMobileFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppThemePro.premiumCardDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.filter_list, color: AppThemePro.accentGold),
                  const SizedBox(width: 8),
                  Text(
                    'Filtry kalendarza',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppThemePro.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildProfessionalSearchField(),
              const SizedBox(height: 12),
              _buildCategoryFilter(),
              const SizedBox(height: 12),
              _buildStatusFilter(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemePro.accentGold,
                    foregroundColor: AppThemePro.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Zastosuj filtry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🚀 NOWE: Responsywny kalendarz tygodniowy z obsługą gestów swipe
  Widget _buildResponsiveWeeklyCalendar({
    required bool isMobile,
    required bool isTablet,
  }) {
    return GestureDetector(
      // 🚀 NOWE: Obsługa gestów swipe dla nawigacji na mobile
      onPanEnd: isMobile
          ? (details) {
              // Sprawdź kierunek i prędkość swipe
              if (details.velocity.pixelsPerSecond.dx.abs() > 300) {
                if (details.velocity.pixelsPerSecond.dx > 0) {
                  // Swipe w prawo - poprzedni tydzień
                  _navigateWeek(-1);
                } else {
                  // Swipe w lewo - następny tydzień
                  _navigateWeek(1);
                }
              }
            }
          : null,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isMobile ? 4 : 8, // 🚀 Mniejsze marginesy na mobile
        ),
        decoration: AppThemePro.premiumCardDecoration,
        child: Column(
          children: [
            _buildGoldenDaysHeader(),
            Expanded(
              child: _buildResponsiveDaysGrid(
                isMobile: isMobile,
                isTablet: isTablet,
              ),
            ),
            // 🚀 NOWE: Wskaźnik swipe dla mobile
            if (isMobile) _buildSwipeIndicator(),
          ],
        ),
      ),
    );
  }

  /// 🚀 NOWE: Wskaźnik swipe dla mobile
  Widget _buildSwipeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lewa strzałka
          Icon(
            Icons.keyboard_arrow_left,
            size: 16,
            color: AppThemePro.accentGold.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),

          // Tekst wskazówki
          Text(
            'Przeciągnij aby przełączyć tydzień',
            style: TextStyle(
              fontSize: 11,
              color: AppThemePro.textSecondary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(width: 8),

          // Prawa strzałka
          Icon(
            Icons.keyboard_arrow_right,
            size: 16,
            color: AppThemePro.accentGold.withValues(alpha: 0.6),
          ),
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

  Widget _buildWeekNavigation() {
    final weekStart = DateFormat('d MMM', 'pl').format(_selectedWeekStart);
    final weekEnd = DateFormat(
      'd MMM yyyy',
      'pl',
    ).format(_selectedWeekStart.add(const Duration(days: 6)));

    return SlideTransition(
      position: _weekSlideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ), // 🚀 Zmniejszono marginesy
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ), // 🚀 Zmniejszono padding
        decoration: AppThemePro.premiumCardDecoration,
        child: Row(
          children: [
            // 🚀 NOWE: Kompaktowy przycisk <
            _buildCompactNavButton(
              onTap: () => _navigateWeek(-1),
              icon: '<',
              tooltip: 'Poprzedni tydzień',
            ),

            const SizedBox(width: 12),

            // Główny obszar z datą i szybkimi przyciskami
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Data tygodnia
                  Text(
                    '$weekStart - $weekEnd',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppThemePro.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Kompaktowe przyciski szybkiej nawigacji
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickNavigationButton(
                        label: 'Poprz.',
                        onTap: () => _navigateWeek(-4),
                        icon: Icons.skip_previous,
                        compact: true,
                      ),
                      _buildQuickNavigationButton(
                        label: 'Dziś',
                        onTap: _goToToday,
                        icon: Icons.today,
                        isPrimary: true,
                        compact: true,
                      ),
                      _buildQuickNavigationButton(
                        label: 'Nast.',
                        onTap: () => _navigateWeek(4),
                        icon: Icons.skip_next,
                        compact: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // 🚀 NOWE: Kompaktowy przycisk >
            _buildCompactNavButton(
              onTap: () => _navigateWeek(1),
              icon: '>',
              tooltip: 'Następny tydzień',
            ),
          ],
        ),
      ),
    );
  }

  /// 🚀 NOWE: Kompaktowy przycisk nawigacji z < > - ZŁOTE STRZAŁKI
  Widget _buildCompactNavButton({
    required VoidCallback onTap,
    required String icon,
    required String tooltip,
  }) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () {
          onTap();
          _triggerMicroInteraction();
          _triggerHapticFeedback();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppThemePro.accentGold.withValues(alpha: 0.15),
                AppThemePro.accentGoldMuted.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppThemePro.accentGold, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppThemePro.accentGold.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: AppThemePro.accentGold.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              icon,
              style: TextStyle(
                fontSize: 22, // 🚀 Zwiększono rozmiar
                fontWeight: FontWeight.w900, // 🚀 Pogrubiono
                color: AppThemePro.accentGold,
                shadows: [
                  Shadow(
                    color: AppThemePro.accentGold.withValues(alpha: 0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🚀 NOWE: Widget dla szybkiej nawigacji
  Widget _buildQuickNavigationButton({
    required String label,
    required VoidCallback onTap,
    required IconData icon,
    bool isPrimary = false,
    bool compact = false, // 🚀 NOWE: Tryb kompaktowy
  }) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () {
          onTap();
          _triggerMicroInteraction();
        },
        child: Container(
          padding: compact
              ? const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ) // 🚀 Kompaktowy padding
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPrimary
                ? AppThemePro.accentGold.withValues(alpha: 0.2)
                : AppThemePro.surfaceInteractive,
            borderRadius: BorderRadius.circular(
              compact ? 6 : 8,
            ), // 🚀 Mniejszy radius
            border: Border.all(
              color: isPrimary
                  ? AppThemePro.accentGold
                  : AppThemePro.borderPrimary,
              width: isPrimary ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: compact
                    ? 12
                    : 14, // 🚀 Mniejsza ikona w trybie kompaktowym
                color: isPrimary
                    ? AppThemePro.accentGold
                    : AppThemePro.textSecondary,
              ),
              SizedBox(width: compact ? 3 : 4), // 🚀 Mniejszy odstęp
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 10 : 11, // 🚀 Mniejszy tekst
                  fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                  color: isPrimary
                      ? AppThemePro.accentGold
                      : AppThemePro.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🚀 NOWE: Duże strzałki nawigacji po bokach głównego widoku
  Widget _buildMainNavigationArrow({
    required VoidCallback onTap,
    required IconData icon,
    required String tooltip,
    required bool isLeft,
    bool isMobile = false,
  }) {
    // 🚀 NOWE: Responsywne rozmiary dla mobile
    final arrowSize = isMobile ? 40.0 : 52.0;
    final iconSize = isMobile ? 22.0 : 28.0;
    final containerWidth = isMobile ? 48.0 : 60.0;
    final horizontalMargin = isMobile ? 4.0 : 8.0;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Container(
          width: containerWidth,
          margin: EdgeInsets.symmetric(
            horizontal: horizontalMargin,
            vertical: 16,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Główna strzałka
              GestureDetector(
                onTap: () {
                  onTap();
                  _triggerMicroInteraction();
                  _triggerHapticFeedback();
                  _triggerBounce();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: arrowSize,
                  height: arrowSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: isLeft
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      end: isLeft
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      colors: [
                        AppThemePro.accentGold.withValues(alpha: 0.2),
                        AppThemePro.accentGoldMuted.withValues(alpha: 0.15),
                        AppThemePro.accentGold.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                    border: Border.all(
                      color: AppThemePro.accentGold.withValues(alpha: 0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppThemePro.accentGold.withValues(alpha: 0.25),
                        blurRadius: isMobile ? 8 : 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: AppThemePro.accentGold.withValues(alpha: 0.1),
                        blurRadius: isMobile ? 16 : 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ScaleTransition(
                    scale: _bounceAnimation,
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: AppThemePro.accentGold,
                      shadows: [
                        Shadow(
                          color: AppThemePro.accentGold.withValues(alpha: 0.6),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (!isMobile) ...[
                const SizedBox(height: 12),

                // Tooltip pod strzałką (tylko na desktop)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppThemePro.surfaceCard.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppThemePro.accentGold.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isLeft ? 'Poprz.' : 'Nast.',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppThemePro.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Dodatkowe wskaźniki nawigacji (mniejsze kropki - tylko na desktop)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppThemePro.accentGold.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedFilterPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ), // 🚀 Zmniejszono margines
      padding: const EdgeInsets.all(12), // 🚀 Zmniejszono padding
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        children: [
          _buildProfessionalSearchField(),
          const SizedBox(height: 8), // 🚀 Zmniejszono odstęp
          Row(
            children: [
              Expanded(child: _buildCategoryFilter()),
              const SizedBox(width: 12), // 🚀 Zmniejszono odstęp
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

  /// 🚀 NOWE: Responsywna siatka dni
  Widget _buildResponsiveDaysGrid({
    required bool isMobile,
    required bool isTablet,
  }) {
  final canEdit = Provider.of<AuthProvider>(context, listen: false).isAdmin;
    return Row(
      children: List.generate(7, (index) {
        final day = _selectedWeekStart.add(Duration(days: index));
        final dayEvents = _getEventsForDay(day);
        final isToday = _isSameDay(day, DateTime.now());
        final hasNotifications = dayEvents.length > 2;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (canEdit) {
                _showAddEventDialog(initialDate: day);
                _triggerMicroInteraction();
              }
            },
            child: Container(
              height: isMobile
                  ? MediaQuery.of(context).size.height *
                        0.35 // 🚀 Mniejsza wysokość na mobile
                  : double.infinity,
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: isToday
                    ? AppThemePro.accentGold.withValues(alpha: 0.1)
                    : AppThemePro.surfaceCard,
                border: Border.all(
                  color: isToday
                      ? AppThemePro.accentGold.withValues(alpha: 0.3)
                      : AppThemePro.borderSecondary,
                  width: isToday ? 2 : 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(
                      isMobile ? 4 : 8,
                    ), // 🚀 Mniejszy padding na mobile
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
                            fontSize: isMobile
                                ? 14
                                : 16, // 🚀 Mniejszy tekst na mobile
                          ),
                        ),
                        if (hasNotifications) ...[
                          const SizedBox(width: 4),
                          _buildNotificationBadge(
                            dayEvents.length,
                            compact: isMobile, // 🚀 Kompaktowy badge na mobile
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: dayEvents.isEmpty
                        ? // 🚀 NOWE: Wskazówka dla pustych dni (tylko gdy admin)
                          Center(
                            child: canEdit
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline,
                                        size: isMobile ? 20 : 24,
                                        color: AppThemePro.textTertiary
                                            .withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      if (!isMobile) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Dodaj\nevent',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppThemePro.textTertiary
                                                .withValues(alpha: 0.7),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  )
                                : Icon(
                                    Icons.event_available,
                                    size: isMobile ? 18 : 22,
                                    color: AppThemePro.textTertiary
                                        .withValues(alpha: 0.4),
                                  ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile
                                  ? 2
                                  : 4, // 🚀 Mniejszy padding na mobile
                            ),
                            itemCount: isMobile
                                ? (dayEvents.length > 3
                                      ? 3
                                      : dayEvents
                                            .length) // 🚀 Maksymalnie 3 wydarzenia na mobile
                                : dayEvents.length,
                            itemBuilder: (context, eventIndex) {
                              if (isMobile &&
                                  eventIndex == 2 &&
                                  dayEvents.length > 3) {
                                // 🚀 Pokaż "więcej..." na mobile
                                return _buildMoreEventsIndicator(
                                  dayEvents.length - 2,
                                );
                              }

                              final event = dayEvents[eventIndex];
                              return _buildEnhancedEventTile(
                                event,
                                compact:
                                    isMobile, // 🚀 Kompaktowy widok na mobile
                              );
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

  Widget _buildNotificationBadge(int count, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppThemePro.accentGold, AppThemePro.accentGoldMuted],
        ),
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.accentGold.withValues(alpha: 0.4),
            blurRadius: compact ? 2 : 4,
            offset: Offset(0, compact ? 1 : 2),
          ),
        ],
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          color: AppThemePro.primaryDark,
          fontSize: compact ? 8 : 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 🚀 NOWE: Wskaźnik więcej wydarzeń dla mobile
  Widget _buildMoreEventsIndicator(int remainingCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppThemePro.textSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppThemePro.textSecondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          '+$remainingCount więcej',
          style: TextStyle(
            color: AppThemePro.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildEnhancedEventTile(CalendarEvent event, {bool compact = false}) {
    final color = _getEventColor(event);

    return GestureDetector(
      onTap: () {
        _showEventDetails(event);
        _triggerMicroInteraction();
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: compact ? 2 : 4,
          vertical: compact ? 1 : 2,
        ),
        padding: EdgeInsets.all(compact ? 4 : 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(compact ? 6 : 8),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: compact ? 2 : 4,
              offset: Offset(0, compact ? 1 : 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!event.isAllDay)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 4 : 6,
                  vertical: compact ? 1 : 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(compact ? 3 : 4),
                ),
                child: Text(
                  DateFormat('HH:mm').format(event.startDate),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 8 : 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (!event.isAllDay) SizedBox(height: compact ? 2 : 4),
            Text(
              event.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!compact &&
                event.location != null &&
                event.location!.isNotEmpty) ...[
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
