import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// ⏰ TIME RANGE SELECTOR COMPONENT
/// Dropdown for selecting analytics time range
class TimeRangeSelector extends StatelessWidget {
  final int selectedTimeRange;
  final Function(int) onChanged;

  const TimeRangeSelector({
    super.key,
    required this.selectedTimeRange,
    required this.onChanged,
  });

  static const List<TimeRangeOption> _options = [
    TimeRangeOption(value: 3, label: '3 miesiące'),
    TimeRangeOption(value: 6, label: '6 miesięcy'),
    TimeRangeOption(value: 12, label: '12 miesięcy'),
    TimeRangeOption(value: 24, label: '24 miesiące'),
    TimeRangeOption(value: -1, label: 'Cały okres'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButton<int>(
        value: selectedTimeRange,
        underline: const SizedBox(),
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 14,
        ),
        dropdownColor: AppTheme.surfaceCard,
        items: _options.map((option) {
          return DropdownMenuItem(
            value: option.value,
            child: Text(option.label),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

class TimeRangeOption {
  final int value;
  final String label;

  const TimeRangeOption({
    required this.value,
    required this.label,
  });
}