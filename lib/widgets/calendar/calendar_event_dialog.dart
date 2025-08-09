import 'package:flutter/material.dart';
import '../../models/calendar/calendar_event.dart';

class CalendarEventDialog extends StatefulWidget {
  final CalendarEvent? event;
  final DateTime initialDate;
  final ValueChanged<CalendarEvent> onSave;
  final ValueChanged<CalendarEvent>? onDelete;

  const CalendarEventDialog({
    super.key,
    this.event,
    required this.initialDate,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<CalendarEventDialog> createState() => _CalendarEventDialogState();
}

class _CalendarEventDialogState extends State<CalendarEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  late DateTime _startDate;
  late DateTime _endDate;
  late CalendarEventCategory _category;
  late CalendarEventStatus _status;
  late CalendarEventPriority _priority;
  bool _isAllDay = false;
  List<String> _participants = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.event != null) {
      final event = widget.event!;
      _titleController.text = event.title;
      _descriptionController.text = event.description ?? '';
      _locationController.text = event.location ?? '';
      _startDate = event.startDate;
      _endDate = event.endDate;
      _category = event.category;
      _status = event.status;
      _priority = event.priority;
      _isAllDay = event.isAllDay;
      _participants = List.from(event.participants);
    } else {
      _startDate = widget.initialDate;
      _endDate = widget.initialDate.add(const Duration(hours: 1));
      _category = CalendarEventCategory.work;
      _status = CalendarEventStatus.confirmed;
      _priority = CalendarEventPriority.medium;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleField(),
                      const SizedBox(height: 16),
                      _buildDateTimeSection(),
                      const SizedBox(height: 16),
                      _buildCategoryPrioritySection(),
                      const SizedBox(height: 16),
                      _buildDescriptionField(),
                      const SizedBox(height: 16),
                      _buildLocationField(),
                      const SizedBox(height: 16),
                      _buildOptionsSection(),
                    ],
                  ),
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(_category.colorValue),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(
            widget.event == null ? Icons.add_circle : Icons.edit,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            widget.event == null ? 'Nowe wydarzenie' : 'Edytuj wydarzenie',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Tytuł wydarzenia',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Tytuł jest wymagany';
        }
        return null;
      },
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Data i godzina',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Row(
              children: [
                Text('Cały dzień'),
                Switch(
                  value: _isAllDay,
                  onChanged: (value) {
                    setState(() {
                      _isAllDay = value;
                      if (value) {
                        _startDate = DateTime(
                          _startDate.year,
                          _startDate.month,
                          _startDate.day,
                        );
                        _endDate = DateTime(
                          _endDate.year,
                          _endDate.month,
                          _endDate.day,
                          23,
                          59,
                        );
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectStartDate,
                icon: const Icon(Icons.calendar_today),
                label: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Początek'),
                    Text(
                      _formatDateTime(_startDate, _isAllDay),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectEndDate,
                icon: const Icon(Icons.calendar_today),
                label: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Koniec'),
                    Text(
                      _formatDateTime(_endDate, _isAllDay),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryPrioritySection() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<CalendarEventCategory>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'Kategoria',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: CalendarEventCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Color(category.colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(category.displayName),
                  ],
                ),
              );
            }).toList(),
            onChanged: (category) {
              if (category != null) {
                setState(() => _category = category);
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<CalendarEventPriority>(
            value: _priority,
            decoration: const InputDecoration(
              labelText: 'Priorytet',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.priority_high),
            ),
            items: CalendarEventPriority.values.map((priority) {
              return DropdownMenuItem(
                value: priority,
                child: Text(priority.displayName),
              );
            }).toList(),
            onChanged: (priority) {
              if (priority != null) {
                setState(() => _priority = priority);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Opis (opcjonalny)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationController,
      decoration: const InputDecoration(
        labelText: 'Lokalizacja (opcjonalna)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_on),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<CalendarEventStatus>(
          value: _status,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.info),
          ),
          items: CalendarEventStatus.values.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(status.displayName),
            );
          }).toList(),
          onChanged: (status) {
            if (status != null) {
              setState(() => _status = status);
            }
          },
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        children: [
          if (widget.event != null && widget.onDelete != null) ...[
            TextButton.icon(
              onPressed: _deleteEvent,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Usuń', style: TextStyle(color: Colors.red)),
            ),
            const SizedBox(width: 16),
          ],
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          const SizedBox(width: 16),
          ElevatedButton(onPressed: _saveEvent, child: const Text('Zapisz')),
        ],
      ),
    );
  }

  void _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      if (!_isAllDay) {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_startDate),
        );

        if (time != null) {
          setState(() {
            _startDate = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
            if (_startDate.isAfter(_endDate)) {
              _endDate = _startDate.add(const Duration(hours: 1));
            }
          });
        }
      } else {
        setState(() {
          _startDate = date;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        });
      }
    }
  }

  void _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      if (!_isAllDay) {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_endDate),
        );

        if (time != null) {
          setState(() {
            _endDate = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
          });
        }
      } else {
        setState(() {
          _endDate = DateTime(date.year, date.month, date.day, 23, 59);
        });
      }
    }
  }

  void _saveEvent() {
    if (_formKey.currentState?.validate() ?? false) {
      final now = DateTime.now();
      final event = CalendarEvent(
        id: widget.event?.id ?? '',
        title: _titleController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        category: _category,
        status: _status,
        priority: _priority,
        participants: _participants,
        isAllDay: _isAllDay,
        createdBy: widget.event?.createdBy ?? '',
        createdAt: widget.event?.createdAt ?? now,
        updatedAt: now,
      );

      widget.onSave(event);
      Navigator.of(context).pop();
    }
  }

  void _deleteEvent() {
    if (widget.event != null && widget.onDelete != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Usuń wydarzenie'),
          content: const Text('Czy na pewno chcesz usunąć to wydarzenie?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDelete!(widget.event!);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Usuń'),
            ),
          ],
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime, bool isAllDay) {
    if (isAllDay) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
