import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/calendar/calendar_event.dart';
import '../../services/calendar_service.dart';
import '../../services/calendar_notification_service.dart';
import '../../theme/app_theme_professional.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// 📅 PREMIUM CALENDAR EVENT DIALOG
/// Najnowocześniejszy dialog do tworzenia przypomień/wydarzeń kalendarza
/// Bazuje na AppThemePro z ulepszoną responsywnością i UX
class PremiumCalendarEventDialog extends StatefulWidget {
  final CalendarEvent? event;
  final DateTime? initialDate;
  final Function(CalendarEvent)? onEventChanged;

  const PremiumCalendarEventDialog({
    super.key,
    this.event,
    this.initialDate,
    this.onEventChanged,
  });

  @override
  State<PremiumCalendarEventDialog> createState() => _PremiumCalendarEventDialogState();

  static Future<CalendarEvent?> show(
    BuildContext context, {
    CalendarEvent? event,
    DateTime? initialDate,
    Function(CalendarEvent)? onEventChanged,
  }) {
    return showDialog<CalendarEvent>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppThemePro.scrimColor.withValues(alpha: 0.8),
      builder: (context) => PremiumCalendarEventDialog(
        event: event,
        initialDate: initialDate,
        onEventChanged: onEventChanged,
      ),
    );
  }
}

class _PremiumCalendarEventDialogState extends State<PremiumCalendarEventDialog>
    with TickerProviderStateMixin {
  final CalendarService _calendarService = CalendarService();
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  // Form data
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  late CalendarEventCategory _category;
  late CalendarEventStatus _status;
  late CalendarEventPriority _priority;
  late bool _isAllDay;
  late List<String> _participants;

  // UI State
  bool _isLoading = false;
  int _currentPage = 0;
  final int _totalPages = 3; // Podstawowe info, Data/czas, Dodatkowe

  // Animation Controllers
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rippleController;
  late AnimationController _bounceController;

  // Animations
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _bounceAnimation;

  bool get _isEditing => widget.event != null && widget.event!.id.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeForm();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOutCirc,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    // Uruchom animacje wejścia
    _slideController.forward();
    _scaleController.forward();
  }

  void _initializeForm() {
    final event = widget.event;
    final initialDate = widget.initialDate ?? DateTime.now();

    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(text: event?.description ?? '');
    _locationController = TextEditingController(text: event?.location ?? '');

    _startDate = event?.startDate ?? initialDate;
    _startTime = TimeOfDay.fromDateTime(_startDate);
    _endDate = event?.endDate ?? initialDate.add(const Duration(hours: 1));
    _endTime = TimeOfDay.fromDateTime(_endDate);
    _category = event?.category ?? CalendarEventCategory.appointment;
    _status = event?.status ?? CalendarEventStatus.confirmed;
    _priority = event?.priority ?? CalendarEventPriority.medium;
    _isAllDay = event?.isAllDay ?? false;
    _participants = List.from(event?.participants ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _rippleController.dispose();
    _bounceController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _triggerMicroInteraction() {
    HapticFeedback.lightImpact();
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _triggerMicroInteraction();
      setState(() => _currentPage++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _triggerMicroInteraction();
      setState(() => _currentPage--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 900;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: isMobile
                ? screenSize.width * 0.95
                : isTablet
                    ? screenSize.width * 0.8
                    : 600,
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: isMobile ? screenSize.height * 0.9 : 700,
            ),
            decoration: AppThemePro.premiumCardDecoration.copyWith(
              color: AppThemePro.surfaceCard,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: AppThemePro.accentGold.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildPremiumHeader(isMobile),
                Expanded(child: _buildPageView(isMobile)),
                _buildNavigationControls(isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.accentGold.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _bounceAnimation,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppThemePro.accentGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppThemePro.accentGold.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Icon(
                _isEditing ? Icons.edit_calendar : Icons.add_task,
                color: AppThemePro.accentGold,
                size: isMobile ? 20 : 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edytuj Przypomnienie' : 'Nowe Przypomnienie',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.w700,
                    color: AppThemePro.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(height: 4),
                  Text(
                    _getStepTitle(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppThemePro.accentGold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildProgressIndicator(isMobile),
          const SizedBox(width: 12),
          _buildCloseButton(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppThemePro.accentGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_totalPages, (index) {
          final isActive = index == _currentPage;
          final isCompleted = index < _currentPage;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: isMobile ? 6 : 8,
            height: isMobile ? 6 : 8,
            decoration: BoxDecoration(
              color: isActive
                  ? AppThemePro.accentGold
                  : isCompleted
                      ? AppThemePro.accentGoldMuted
                      : AppThemePro.textMuted,
              borderRadius: BorderRadius.circular(4),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppThemePro.accentGold.withValues(alpha: 0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: () {
        _triggerMicroInteraction();
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppThemePro.surfaceCard.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppThemePro.textMuted.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.close,
          color: AppThemePro.textSecondary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildPageView(bool isMobile) {
    return Form(
      key: _formKey,
      child: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Tylko programowa nawigacja
        onPageChanged: (index) => setState(() => _currentPage = index),
        children: [
          _buildBasicInfoPage(isMobile),
          _buildDateTimePage(isMobile),
          _buildAdditionalInfoPage(isMobile),
        ],
      ),
    );
  }

  Widget _buildBasicInfoPage(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Podstawowe informacje', Icons.info_outline),
          const SizedBox(height: 24),
          _buildPremiumTitleField(isMobile),
          const SizedBox(height: 20),
          _buildCategoryPriorityRow(isMobile),
          const SizedBox(height: 20),
          _buildDescriptionField(isMobile),
        ],
      ),
    );
  }

  Widget _buildDateTimePage(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Data i czas', Icons.schedule),
          const SizedBox(height: 24),
          _buildAllDayToggle(isMobile),
          const SizedBox(height: 20),
          _buildDateTimeGrid(isMobile),
          const SizedBox(height: 20),
          _buildLocationField(isMobile),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoPage(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Dodatkowe opcje', Icons.tune),
          const SizedBox(height: 24),
          _buildStatusSection(isMobile),
          const SizedBox(height: 20),
          _buildSummaryCard(isMobile),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppThemePro.accentGold,
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppThemePro.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumTitleField(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tytuł wydarzenia*',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppThemePro.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppThemePro.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Wpisz tytuł przypomnienia...',
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.title,
                color: AppThemePro.accentGold,
                size: 22,
              ),
            ),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppThemePro.statusError, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Tytuł jest wymagany';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategoryPriorityRow(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildPremiumCategoryDropdown(),
          const SizedBox(height: 16),
          _buildPremiumPriorityDropdown(),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildPremiumCategoryDropdown()),
        const SizedBox(width: 16),
        Expanded(child: _buildPremiumPriorityDropdown()),
      ],
    );
  }

  Widget _buildPremiumCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategoria',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppThemePro.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<CalendarEventCategory>(
          value: _category,
          style: TextStyle(
            color: AppThemePro.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                _getCategoryIcon(_category),
                color: AppThemePro.accentGold,
                size: 20,
              ),
            ),
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
              vertical: 16,
            ),
          ),
          dropdownColor: AppThemePro.surfaceCard,
          items: CalendarEventCategory.values.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    size: 18,
                    color: AppThemePro.getInvestmentTypeColor(category.name),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _getCategoryName(category),
                    style: TextStyle(
                      color: AppThemePro.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _category = value);
              _triggerMicroInteraction();
            }
          },
        ),
      ],
    );
  }

  Widget _buildPremiumPriorityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priorytet',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppThemePro.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<CalendarEventPriority>(
          value: _priority,
          style: TextStyle(
            color: AppThemePro.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.flag,
                color: _getPriorityColor(_priority),
                size: 20,
              ),
            ),
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
              vertical: 16,
            ),
          ),
          dropdownColor: AppThemePro.surfaceCard,
          items: CalendarEventPriority.values.map((priority) {
            return DropdownMenuItem(
              value: priority,
              child: Row(
                children: [
                  Icon(
                    Icons.flag,
                    size: 16,
                    color: _getPriorityColor(priority),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _getPriorityName(priority),
                    style: TextStyle(
                      color: AppThemePro.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _priority = value);
              _triggerMicroInteraction();
            }
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opis (opcjonalny)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppThemePro.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: isMobile ? 3 : 4,
          style: TextStyle(
            fontSize: 15,
            color: AppThemePro.textPrimary,
            height: 1.4,
          ),
          decoration: InputDecoration(
            hintText: 'Dodatkowe szczegóły wydarzenia...',
            prefixIcon: Padding(
              padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
              child: Icon(
                Icons.description,
                color: AppThemePro.accentGold,
                size: 20,
              ),
            ),
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
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllDayToggle(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceInteractive.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemePro.borderSecondary,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: AppThemePro.accentGold,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wydarzenie całodniowe',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppThemePro.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Wydarzenie bez określonej godziny',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppThemePro.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAllDay,
            onChanged: (value) {
              setState(() => _isAllDay = value);
              _triggerMicroInteraction();
            },
            activeColor: AppThemePro.accentGold,
            activeTrackColor: AppThemePro.accentGold.withValues(alpha: 0.3),
            inactiveThumbColor: AppThemePro.textMuted,
            inactiveTrackColor: AppThemePro.surfaceElevated,
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeGrid(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildDateTimeCard('Od', _startDate, _startTime, true, isMobile),
          const SizedBox(height: 16),
          _buildDateTimeCard('Do', _endDate, _endTime, false, isMobile),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildDateTimeCard('Od', _startDate, _startTime, true, isMobile)),
        const SizedBox(width: 16),
        Expanded(child: _buildDateTimeCard('Do', _endDate, _endTime, false, isMobile)),
      ],
    );
  }

  Widget _buildDateTimeCard(String label, DateTime date, TimeOfDay time, bool isStart, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemePro.borderPrimary,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppThemePro.accentGold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          
          // Data
          GestureDetector(
            onTap: () => _selectDate(isStart),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppThemePro.surfaceInteractive,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppThemePro.borderSecondary,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: AppThemePro.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd.MM.yyyy', 'pl').format(date),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppThemePro.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Czas (tylko jeśli nie całodniowe)
          if (!_isAllDay) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectTime(isStart),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppThemePro.surfaceInteractive,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppThemePro.borderSecondary,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: AppThemePro.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time.format(context),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppThemePro.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationField(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lokalizacja (opcjonalnie)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppThemePro.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _locationController,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppThemePro.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Miejsce wydarzenia...',
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.location_on,
                color: AppThemePro.accentGold,
                size: 22,
              ),
            ),
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
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status wydarzenia',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppThemePro.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CalendarEventStatus.values.map((status) {
            final isSelected = _status == status;
            return GestureDetector(
              onTap: () {
                setState(() => _status = status);
                _triggerMicroInteraction();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppThemePro.accentGold.withValues(alpha: 0.2)
                      : AppThemePro.surfaceInteractive,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppThemePro.accentGold
                        : AppThemePro.borderSecondary,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppThemePro.accentGold.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  _getStatusName(status),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppThemePro.accentGold
                        : AppThemePro.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.accentGold.withValues(alpha: 0.1),
            AppThemePro.accentGoldMuted.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemePro.accentGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize,
                color: AppThemePro.accentGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Podsumowanie',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppThemePro.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Tytuł', _titleController.text.isNotEmpty 
              ? _titleController.text 
              : 'Nie wprowadzono'),
          _buildSummaryRow('Kategoria', _getCategoryName(_category)),
          _buildSummaryRow('Priorytet', _getPriorityName(_priority)),
          _buildSummaryRow('Status', _getStatusName(_status)),
          _buildSummaryRow('Data', _formatDateRange()),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppThemePro.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppThemePro.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border(
          top: BorderSide(
            color: AppThemePro.borderPrimary,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Przycisk Wstecz
          if (_currentPage > 0)
            Expanded(
              child: _buildNavigationButton(
                label: 'Wstecz',
                icon: Icons.arrow_back,
                onPressed: _previousPage,
                isPrimary: false,
                isMobile: isMobile,
              ),
            ),
          
          if (_currentPage > 0) const SizedBox(width: 12),
          
          // Przycisk usuwania (tylko w trybie edycji)
          if (_isEditing && _currentPage == _totalPages - 1) ...[
            Expanded(
              child: _buildNavigationButton(
                label: 'Usuń',
                icon: Icons.delete_outline,
                onPressed: _deleteEvent,
                isPrimary: false,
                isDestructive: true,
                isMobile: isMobile,
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          // Przycisk Dalej/Zapisz
          Expanded(
            child: _buildNavigationButton(
              label: _currentPage == _totalPages - 1
                  ? (_isEditing ? 'Zapisz' : 'Dodaj')
                  : 'Dalej',
              icon: _currentPage == _totalPages - 1
                  ? (_isEditing ? Icons.save : Icons.add_task)
                  : Icons.arrow_forward,
              onPressed: _currentPage == _totalPages - 1 ? _saveEvent : _nextPage,
              isPrimary: true,
              isMobile: isMobile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
    required bool isMobile,
    bool isDestructive = false,
  }) {
    return ScaleTransition(
      scale: _bounceAnimation,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: _isLoading && isPrimary
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppThemePro.primaryDark,
                ),
              )
            : Icon(
                icon,
                size: isMobile ? 18 : 20,
              ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? AppThemePro.accentGold
              : isDestructive
                  ? AppThemePro.statusError
                  : AppThemePro.surfaceInteractive,
          foregroundColor: isPrimary
              ? AppThemePro.primaryDark
              : isDestructive
                  ? AppThemePro.textPrimary
                  : AppThemePro.textPrimary,
          elevation: isPrimary ? 8 : 2,
          shadowColor: isPrimary
              ? AppThemePro.accentGold.withValues(alpha: 0.4)
              : Colors.black26,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 12 : 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Event handlers
  Future<void> _selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppThemePro.accentGold,
              onPrimary: AppThemePro.primaryDark,
              surface: AppThemePro.surfaceCard,
              onSurface: AppThemePro.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = DateTime(date.year, date.month, date.day,
              _startDate.hour, _startDate.minute);
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate.add(const Duration(hours: 1));
            _endTime = TimeOfDay.fromDateTime(_endDate);
          }
        } else {
          _endDate = DateTime(date.year, date.month, date.day,
              _endDate.hour, _endDate.minute);
        }
      });
      _triggerMicroInteraction();
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppThemePro.accentGold,
              onPrimary: AppThemePro.primaryDark,
              surface: AppThemePro.surfaceCard,
              onSurface: AppThemePro.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        if (isStart) {
          _startTime = time;
          _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day,
              time.hour, time.minute);
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate.add(const Duration(hours: 1));
            _endTime = TimeOfDay.fromDateTime(_endDate);
          }
        } else {
          _endTime = time;
          _endDate = DateTime(_endDate.year, _endDate.month, _endDate.day,
              time.hour, time.minute);
        }
      });
      _triggerMicroInteraction();
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      // Przejdź do pierwszej strony jeśli błąd walidacji
      if (_currentPage != 0) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentPage = 0);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;

      if (user == null) {
        throw Exception('Użytkownik nie jest zalogowany');
      }

      // Dostosuj daty dla wydarzeń całodniowych
      DateTime startDateTime, endDateTime;
      
      if (_isAllDay) {
        startDateTime = DateTime(_startDate.year, _startDate.month, _startDate.day);
        endDateTime = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
      } else {
        startDateTime = DateTime(_startDate.year, _startDate.month, _startDate.day,
            _startTime.hour, _startTime.minute);
        endDateTime = DateTime(_endDate.year, _endDate.month, _endDate.day,
            _endTime.hour, _endTime.minute);
      }

      final eventData = CalendarEvent(
        id: widget.event?.id ?? '',
        title: _titleController.text.trim(),
        startDate: startDateTime,
        endDate: endDateTime,
        description: _descriptionController.text.trim().isEmpty 
            ? null : _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty 
            ? null : _locationController.text.trim(),
        category: _category,
        status: _status,
        priority: _priority,
        participants: _participants,
        isAllDay: _isAllDay,
        createdBy: user.uid,
        createdAt: widget.event?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      CalendarEvent savedEvent;
      
      if (_isEditing && widget.event != null && widget.event!.id.isNotEmpty) {
        savedEvent = await _calendarService.updateEvent(eventData);
      } else {
        savedEvent = await _calendarService.createEvent(eventData);
      }

      if (savedEvent.id.isEmpty) {
        throw Exception('Wydarzenie zostało zapisane ale nie otrzymało ID');
      }

  widget.onEventChanged?.call(savedEvent);
  // Ensure global calendar notification badges are refreshed when an event is added/updated
  CalendarNotificationService().forceRefresh();

      if (!mounted) return;

      // Avoid calling pop synchronously during gesture handling which can
      // cause Navigator to be locked. Schedule the pop after the current frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(savedEvent);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppThemePro.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                _isEditing 
                    ? 'Przypomnienie zostało zaktualizowane' 
                    : 'Przypomnienie zostało dodane',
                style: TextStyle(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: AppThemePro.statusSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error,
                color: AppThemePro.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Błąd: ${e.toString()}',
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppThemePro.statusError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: AppThemePro.scrimColor.withValues(alpha: 0.6),
      builder: (context) => AlertDialog(
        backgroundColor: AppThemePro.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: AppThemePro.statusError,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Usuń przypomnienie',
              style: TextStyle(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Czy na pewno chcesz usunąć to przypomnienie? Ta operacja jest nieodwracalna.',
          style: TextStyle(
            color: AppThemePro.textSecondary,
            fontSize: 16,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Anuluj',
              style: TextStyle(
                color: AppThemePro.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemePro.statusError,
              foregroundColor: AppThemePro.textPrimary,
            ),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      await _calendarService.deleteEvent(widget.event!.id);
      
  widget.onEventChanged?.call(widget.event!);
  // Ensure global calendar notification badges are refreshed when an event is deleted
  CalendarNotificationService().forceRefresh();

      if (!mounted) return;

      // Schedule pop to avoid _debugLocked assertion when invoked inside gesture
      // handlers on web/desktop builds.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(true);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppThemePro.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'Przypomnienie zostało usunięte',
                style: TextStyle(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: AppThemePro.statusSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error,
                color: AppThemePro.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Błąd usuwania: ${e.toString()}',
                style: TextStyle(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: AppThemePro.statusError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper methods
  String _getStepTitle() {
    switch (_currentPage) {
      case 0:
        return 'Krok 1: Podstawowe informacje';
      case 1:
        return 'Krok 2: Data i czas';
      case 2:
        return 'Krok 3: Dodatkowe opcje';
      default:
        return '';
    }
  }

  String _formatDateRange() {
    final startFormatted = DateFormat('dd.MM.yyyy', 'pl').format(_startDate);
    final endFormatted = DateFormat('dd.MM.yyyy', 'pl').format(_endDate);
    
    if (_isAllDay) {
      if (_startDate.day == _endDate.day &&
          _startDate.month == _endDate.month &&
          _startDate.year == _endDate.year) {
        return '$startFormatted (cały dzień)';
      }
      return '$startFormatted - $endFormatted (całodniowe)';
    } else {
      final startTime = _startTime.format(context);
      final endTime = _endTime.format(context);
      
      if (_startDate.day == _endDate.day &&
          _startDate.month == _endDate.month &&
          _startDate.year == _endDate.year) {
        return '$startFormatted, $startTime - $endTime';
      }
      return '$startFormatted $startTime - $endFormatted $endTime';
    }
  }

  IconData _getCategoryIcon(CalendarEventCategory category) {
    switch (category) {
      case CalendarEventCategory.meeting:
        return Icons.people;
      case CalendarEventCategory.deadline:
        return Icons.event_available;
      case CalendarEventCategory.appointment:
        return Icons.notifications;
      case CalendarEventCategory.personal:
        return Icons.person;
      case CalendarEventCategory.work:
        return Icons.work;
      case CalendarEventCategory.investment:
        return Icons.trending_up;
      case CalendarEventCategory.client:
        return Icons.person_outline;
      case CalendarEventCategory.other:
        return Icons.label;
    }
  }

  String _getCategoryName(CalendarEventCategory category) {
    switch (category) {
      case CalendarEventCategory.meeting:
        return 'Spotkanie';
      case CalendarEventCategory.deadline:
        return 'Termin';
      case CalendarEventCategory.appointment:
        return 'Wizyta';
      case CalendarEventCategory.personal:
        return 'Osobiste';
      case CalendarEventCategory.work:
        return 'Praca';
      case CalendarEventCategory.investment:
        return 'Inwestycje';
      case CalendarEventCategory.client:
        return 'Klient';
      case CalendarEventCategory.other:
        return 'Inne';
    }
  }

  Color _getPriorityColor(CalendarEventPriority priority) {
    switch (priority) {
      case CalendarEventPriority.low:
        return AppThemePro.statusSuccess;
      case CalendarEventPriority.medium:
        return AppThemePro.statusWarning;
      case CalendarEventPriority.high:
        return AppThemePro.statusError;
      case CalendarEventPriority.urgent:
        return AppThemePro.lossRed;
    }
  }

  String _getPriorityName(CalendarEventPriority priority) {
    switch (priority) {
      case CalendarEventPriority.low:
        return 'Niski';
      case CalendarEventPriority.medium:
        return 'Średni';
      case CalendarEventPriority.high:
        return 'Wysoki';
      case CalendarEventPriority.urgent:
        return 'Pilny';
    }
  }

  String _getStatusName(CalendarEventStatus status) {
    switch (status) {
      case CalendarEventStatus.tentative:
        return 'Wstępny';
      case CalendarEventStatus.confirmed:
        return 'Potwierdzony';
      case CalendarEventStatus.cancelled:
        return 'Anulowany';
      case CalendarEventStatus.pending:
        return 'Oczekujący';
    }
  }
}