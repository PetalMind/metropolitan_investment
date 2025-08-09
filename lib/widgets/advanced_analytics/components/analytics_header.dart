import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'analytics_tab_bar.dart';
import 'time_range_selector.dart';

/// 📊 ANALYTICS HEADER COMPONENT
/// Header with title, controls and tab bar
class AnalyticsHeader extends StatelessWidget {
  final String selectedTab;
  final int selectedTimeRange;
  final bool isTablet;
  final VoidCallback onExport;
  final Function(String) onTabChanged;
  final Function(int) onTimeRangeChanged;

  const AnalyticsHeader({
    super.key,
    required this.selectedTab,
    required this.selectedTimeRange,
    required this.isTablet,
    required this.onExport,
    required this.onTabChanged,
    required this.onTimeRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.gradientDecoration,
      child: Column(
        children: [
          _buildHeaderContent(context),
          const SizedBox(height: 24),
          AnalyticsTabBar(
            selectedTab: selectedTab,
            onTabChanged: onTabChanged,
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderContent(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zaawansowana Analityka',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.textOnPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kompleksowa analiza portfela inwestycyjnego',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textOnPrimary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        if (isTablet) ...[
          TimeRangeSelector(
            selectedTimeRange: selectedTimeRange,
            onChanged: onTimeRangeChanged,
          ),
          const SizedBox(width: 16),
          _buildExportButton(),
        ] else ...[
          _buildMobileControls(),
        ],
      ],
    );
  }

  Widget _buildExportButton() {
    return ElevatedButton.icon(
      onPressed: onExport,
      icon: const Icon(Icons.download),
      label: const Text('Eksport'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.surfaceCard,
        foregroundColor: AppTheme.primaryColor,
        elevation: 2,
      ),
    );
  }

  Widget _buildMobileControls() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppTheme.textOnPrimary),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.download),
              SizedBox(width: 8),
              Text('Eksport'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'timerange',
          child: Row(
            children: [
              Icon(Icons.date_range),
              SizedBox(width: 8),
              Text('Zakres czasu'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'export':
            onExport();
            break;
          case 'timerange':
            _showTimeRangeDialog(context);
            break;
        }
      },
    );
  }

  void _showTimeRangeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wybierz zakres czasu'),
        content: TimeRangeSelector(
          selectedTimeRange: selectedTimeRange,
          onChanged: (value) {
            onTimeRangeChanged(value);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}