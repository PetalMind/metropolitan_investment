import 'package:flutter/material.dart';
import '../../models/calendar/calendar_models.dart';

class CalendarViewSelector extends StatelessWidget {
  final CalendarViewType currentViewType;
  final ValueChanged<CalendarViewType> onViewChanged;

  const CalendarViewSelector({
    super.key,
    required this.currentViewType,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white38),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: CalendarViewType.values.map((viewType) {
          final isSelected = currentViewType == viewType;

          return GestureDetector(
            onTap: () => onViewChanged(viewType),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getShortDisplayName(viewType),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getShortDisplayName(CalendarViewType viewType) {
    switch (viewType) {
      case CalendarViewType.month:
        return 'M';
      case CalendarViewType.week:
        return 'T';
      case CalendarViewType.day:
        return 'D';
      case CalendarViewType.year:
        return 'R';
      case CalendarViewType.agenda:
        return 'L';
    }
  }
}
