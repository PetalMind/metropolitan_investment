import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/calendar/calendar_event.dart';
import '../../services/calendar_service.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// 📅 ENHANCED CALENDAR EVENT DIALOG
/// Profesjonalny dialog do dodawania/edycji wydarzeń kalendarza
class EnhancedCalendarEventDialog extends StatefulWidget {
  final CalendarEvent? event;
  final DateTime? initialDate;
  final Function(CalendarEvent)? onEventChanged;

  const EnhancedCalendarEventDialog({
    super.key,
    this.event,
    this.initialDate,
    this.onEventChanged,
  });

  @override
  State<EnhancedCalendarEventDialog> createState() => _EnhancedCalendarEventDialogState();

  static Future<CalendarEvent?> show(
    BuildContext context, {
    CalendarEvent? event,
    DateTime? initialDate,
    Function(CalendarEvent)? onEventChanged,
  }) {
    return showDialog<CalendarEvent>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnhancedCalendarEventDialog(
        event: event,
        initialDate: initialDate,
        onEventChanged: onEventChanged,
      ),
    );
  }
}

class _EnhancedCalendarEventDialogState extends State<EnhancedCalendarEventDialog> {
  final CalendarService _calendarService = CalendarService();
  final _formKey = GlobalKey<FormState>();

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

  bool _isLoading = false;
  bool get _isEditing => widget.event != null && widget.event!.id.isNotEmpty; // 🚀 FIX: Sprawdź też czy ma ID

  @override
  void initState() {
    super.initState();
    _initializeForm();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: AppTheme.cardDecoration.copyWith(
          color: AppTheme.surfaceCard,
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildForm()),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.gradientDecoration,
      child: Row(
        children: [
          Icon(
            _isEditing ? Icons.edit_calendar : Icons.add_circle,
            color: AppTheme.textOnPrimary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isEditing ? 'Edytuj przypomnienie' : 'Nowe przypomnienie',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textOnPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppTheme.textOnPrimary),
            tooltip: 'Zamknij',
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleField(),
            const SizedBox(height: 20),
            _buildDateTimeSection(),
            const SizedBox(height: 20),
            _buildCategoryPriorityRow(),
            const SizedBox(height: 20),
            _buildDescriptionField(),
            const SizedBox(height: 20),
            _buildLocationField(),
            const SizedBox(height: 20),
            _buildStatusSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tytuł*',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Wprowadź tytuł przypomnienia',
            prefixIcon: const Icon(Icons.title, color: AppTheme.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderPrimary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
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

  Widget _buildDateTimeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Data i czas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Switch(
                    value: _isAllDay,
                    onChanged: (value) => setState(() => _isAllDay = value),
                    activeColor: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cały dzień',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDateTimeRow('Od', _startDate, _startTime, true)),
              const SizedBox(width: 16),
              Expanded(child: _buildDateTimeRow('Do', _endDate, _endTime, false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeRow(String label, DateTime date, TimeOfDay time, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(isStart),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderSecondary),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd.MM.yyyy').format(date),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        if (!_isAllDay) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectTime(isStart),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderSecondary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    time.format(context),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryPriorityRow() {
    return Row(
      children: [
        Expanded(child: _buildCategoryDropdown()),
        const SizedBox(width: 16),
        Expanded(child: _buildPriorityDropdown()),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategoria',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<CalendarEventCategory>(
          value: _category,
          decoration: InputDecoration(
            prefixIcon: Icon(_getCategoryIcon(_category), color: AppTheme.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderPrimary),
            ),
          ),
          items: CalendarEventCategory.values.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Row(
                children: [
                  Icon(_getCategoryIcon(category), size: 16),
                  const SizedBox(width: 8),
                  Text(_getCategoryName(category)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _category = value);
          },
        ),
      ],
    );
  }

  Widget _buildPriorityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priorytet',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<CalendarEventPriority>(
          value: _priority,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.flag,
              color: _getPriorityColor(_priority),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderPrimary),
            ),
          ),
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
                  const SizedBox(width: 8),
                  Text(_getPriorityName(priority)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _priority = value);
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opis',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Dodatkowe informacje o przypomnieniu',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.description, color: AppTheme.primaryColor),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderPrimary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lokalizacja',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: 'Miejsce wydarzenia',
            prefixIcon: const Icon(Icons.location_on, color: AppTheme.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderPrimary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: CalendarEventStatus.values.map((status) {
            final isSelected = _status == status;
            return ChoiceChip(
              label: Text(_getStatusName(status)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _status = status);
              },
              backgroundColor: AppTheme.surfaceContainer,
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.textOnPrimary : AppTheme.textPrimary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          if (_isEditing) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _deleteEvent,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Usuń'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: BorderSide(color: AppTheme.errorColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppTheme.borderPrimary),
              ),
              child: const Text('Anuluj'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveEvent,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.textOnPrimary,
                      ),
                    )
                  : Icon(_isEditing ? Icons.save : Icons.add),
              label: Text(_isEditing ? 'Zapisz' : 'Dodaj'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 2,
              ),
            ),
          ),
        ],
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
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
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
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;

      if (user == null) {
        throw Exception('Użytkownik nie jest zalogowany');
      }

      // Adjust dates for all-day events
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
        id: widget.event?.id ?? '', // 🚀 Puste ID dla nowych wydarzeń - zostanie wygenerowane przez serwis
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
        // 🚀 FIX: Edytuj tylko gdy mamy ID wydarzenia
        savedEvent = await _calendarService.updateEvent(eventData);
      } else {
        // 🚀 FIX: Zawsze twórz nowe wydarzenie gdy brak ID
        savedEvent = await _calendarService.createEvent(eventData);
      }

      // 🚀 WALIDACJA: Sprawdź czy zapisane wydarzenie ma ID
      if (savedEvent.id.isEmpty) {
        throw Exception('Wydarzenie zostało zapisane ale nie otrzymało ID');
      }

      widget.onEventChanged?.call(savedEvent);

      if (!mounted) return;
      
      Navigator.of(context).pop(savedEvent);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing 
              ? 'Przypomnienie zostało zaktualizowane' 
              : 'Przypomnienie zostało dodane'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
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
      builder: (context) => AlertDialog(
        title: const Text('Usuń przypomnienie'),
        content: const Text('Czy na pewno chcesz usunąć to przypomnienie?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
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

      if (!mounted) return;
      
      Navigator.of(context).pop(true); // Return true to indicate deletion
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Przypomnienie zostało usunięte'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd usuwania: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper methods for UI labels and icons
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
        return AppTheme.successColor;
      case CalendarEventPriority.medium:
        return AppTheme.warningColor;
      case CalendarEventPriority.high:
        return AppTheme.errorColor;
      case CalendarEventPriority.urgent:
        return Colors.deepOrange;
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