import 'package:flutter/material.dart';
import '../../models/calendar/calendar_event.dart';
import '../../models/calendar/calendar_models.dart';

class CalendarFilterPanel extends StatefulWidget {
  final CalendarEventFilter filter;
  final ValueChanged<CalendarEventFilter> onFilterChanged;

  const CalendarFilterPanel({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<CalendarFilterPanel> createState() => _CalendarFilterPanelState();
}

class _CalendarFilterPanelState extends State<CalendarFilterPanel> {
  late CalendarEventFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filtry',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (!_filter.isEmpty) ...[
                TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text('Wyczyść wszystkie'),
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                onPressed: () => widget.onFilterChanged(_filter),
                icon: const Icon(Icons.check),
                tooltip: 'Zastosuj filtry',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildCategoryFilter(),
              _buildStatusFilter(),
              _buildPriorityFilter(),
              _buildDateRangeFilter(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategorie', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: CalendarEventCategory.values.map((category) {
            final isSelected = _filter.categories.contains(category.name);

            return FilterChip(
              label: Text(category.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _filter = _filter.copyWith(
                      categories: [..._filter.categories, category.name],
                    );
                  } else {
                    _filter = _filter.copyWith(
                      categories: _filter.categories
                          .where((c) => c != category.name)
                          .toList(),
                    );
                  }
                });
              },
              backgroundColor: Color(category.colorValue).withOpacity(0.1),
              selectedColor: Color(category.colorValue).withOpacity(0.3),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: CalendarEventStatus.values.map((status) {
            final isSelected = _filter.statuses.contains(status.name);

            return FilterChip(
              label: Text(status.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _filter = _filter.copyWith(
                      statuses: [..._filter.statuses, status.name],
                    );
                  } else {
                    _filter = _filter.copyWith(
                      statuses: _filter.statuses
                          .where((s) => s != status.name)
                          .toList(),
                    );
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriorityFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Priorytet', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: CalendarEventPriority.values.map((priority) {
            final isSelected = _filter.priorities.contains(priority.name);

            return FilterChip(
              label: Text(priority.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _filter = _filter.copyWith(
                      priorities: [..._filter.priorities, priority.name],
                    );
                  } else {
                    _filter = _filter.copyWith(
                      priorities: _filter.priorities
                          .where((p) => p != priority.name)
                          .toList(),
                    );
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Zakres dat', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectStartDate(),
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _filter.startDate != null
                      ? '${_filter.startDate!.day}/${_filter.startDate!.month}/${_filter.startDate!.year}'
                      : 'Data od',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectEndDate(),
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _filter.endDate != null
                      ? '${_filter.endDate!.day}/${_filter.endDate!.month}/${_filter.endDate!.year}'
                      : 'Data do',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _filter.startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _filter = _filter.copyWith(startDate: date);
      });
    }
  }

  void _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _filter.endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _filter.startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _filter = _filter.copyWith(endDate: date);
      });
    }
  }

  void _clearAllFilters() {
    setState(() {
      _filter = CalendarEventFilter();
    });
    widget.onFilterChanged(_filter);
  }
}
