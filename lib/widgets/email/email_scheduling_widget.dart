import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme.dart';

/// 📅 WIDGET PLANOWANIA WYSYŁKI EMAILI
///
/// Umożliwia wybór daty i godziny wysłania emaila
/// z gotowymi opcjami (za 5 min, jutro, etc.)
class EmailSchedulingWidget extends StatefulWidget {
  final DateTime? initialDateTime;
  final Function(DateTime?) onDateTimeChanged;
  final bool isEnabled;
  final String? errorText;

  const EmailSchedulingWidget({
    super.key,
    this.initialDateTime,
    required this.onDateTimeChanged,
    this.isEnabled = true,
    this.errorText,
  });

  @override
  State<EmailSchedulingWidget> createState() => _EmailSchedulingWidgetState();
}

class _EmailSchedulingWidgetState extends State<EmailSchedulingWidget>
    with TickerProviderStateMixin {
  DateTime? _selectedDateTime;
  bool _isSchedulingEnabled = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime;
    _isSchedulingEnabled = widget.initialDateTime != null;

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    if (_isSchedulingEnabled) {
      _expandController.forward();
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleScheduling(bool enabled) {
    setState(() {
      _isSchedulingEnabled = enabled;
      if (!enabled) {
        _selectedDateTime = null;
        widget.onDateTimeChanged(null);
        _expandController.reverse();
      } else {
        _expandController.forward();
      }
    });

    // Vibration feedback
    HapticFeedback.lightImpact();
  }

  void _selectQuickOption(ScheduleOption option) {
    setState(() {
      _selectedDateTime = option.dateTime;
    });
    widget.onDateTimeChanged(option.dateTime);
    HapticFeedback.selectionClick();
  }

  Future<void> _selectCustomDateTime() async {
    final now = DateTime.now();
    final initialDate = _selectedDateTime ?? now.add(const Duration(hours: 1));

    // Wybór daty
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? initialDate : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null || !mounted) return;

    // Wybór godziny
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null || !mounted) return;

    final newDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    // Sprawdź czy data nie jest w przeszłości
    if (newDateTime.isBefore(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie można zaplanować wysyłki w przeszłości'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _selectedDateTime = newDateTime;
    });
    widget.onDateTimeChanged(newDateTime);
    HapticFeedback.selectionClick();
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      return 'Dzisiaj o ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Jutro o ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      final weekday = _getWeekdayName(dateTime.weekday);
      return '$weekday o ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} o ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Poniedziałek',
      'Wtorek',
      'Środa',
      'Czwartek',
      'Piątek',
      'Sobota',
      'Niedziela',
    ];
    return weekdays[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width > 768;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.errorText != null
              ? Colors.red.withOpacity(0.5)
              : theme.dividerColor.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header z przełącznikiem
          _buildHeader(theme),

          // Expanded content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: _isSchedulingEnabled
                ? _buildContent(theme, isTablet)
                : const SizedBox.shrink(),
          ),

          // Error text
          if (widget.errorText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                widget.errorText!,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            _isSchedulingEnabled ? Icons.schedule : Icons.send,
            color: _isSchedulingEnabled
                ? AppTheme.primaryColor
                : theme.iconTheme.color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSchedulingEnabled
                      ? 'Wysyłka zaplanowana'
                      : 'Wyślij natychmiast',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _isSchedulingEnabled
                        ? AppTheme.infoPrimary
                        : theme.textTheme.titleMedium?.color,
                  ),
                ),
                if (_isSchedulingEnabled && _selectedDateTime != null)
                  Text(
                    _formatDateTime(_selectedDateTime!),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.7,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isSchedulingEnabled,
            onChanged: widget.isEnabled ? _toggleScheduling : null,
            activeColor: AppTheme.infoPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick options
          _buildQuickOptions(theme, isTablet),

          const SizedBox(height: 16),

          // Custom date/time button
          _buildCustomDateTimeButton(theme),

          if (_selectedDateTime != null) ...[
            const SizedBox(height: 12),
            _buildSelectedDateTime(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickOptions(ThemeData theme, bool isTablet) {
    final quickOptions = EmailSchedulingService.getQuickScheduleOptions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Szybkie opcje',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.textTheme.titleSmall?.color?.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickOptions.map((option) {
            final isSelected =
                _selectedDateTime != null &&
                _selectedDateTime!.difference(option.dateTime).abs().inMinutes <
                    1;

            return _buildQuickOptionChip(theme, option, isSelected);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickOptionChip(
    ThemeData theme,
    ScheduleOption option,
    bool isSelected,
  ) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(option.icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(option.label),
        ],
      ),
      selected: isSelected,
      onSelected: widget.isEnabled ? (_) => _selectQuickOption(option) : null,
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(
        color: isSelected
            ? AppTheme.primaryColor
            : theme.dividerColor.withOpacity(0.3),
      ),
    );
  }

  Widget _buildCustomDateTimeButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: widget.isEnabled ? _selectCustomDateTime : null,
        icon: const Icon(Icons.event),
        label: const Text('Wybierz własną datę i godzinę'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          side: BorderSide(color: AppTheme.primaryColor),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildSelectedDateTime(ThemeData theme) {
    final timeLeft = _selectedDateTime!.difference(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wysyłka: ${_formatDateTime(_selectedDateTime!)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                if (timeLeft.inMinutes > 0)
                  Text(
                    'Za ${_formatDuration(timeLeft)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedDateTime = null;
              });
              widget.onDateTimeChanged(null);
            },
            icon: const Icon(Icons.clear),
            iconSize: 20,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} dni ${duration.inHours % 24} godz.';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} godz. ${duration.inMinutes % 60} min.';
    } else {
      return '${duration.inMinutes} min.';
    }
  }
}
