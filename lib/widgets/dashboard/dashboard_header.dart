import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DashboardHeader extends StatelessWidget {
  final bool isMobile;
  final String selectedTimeFrame;
  final VoidCallback onRefresh;
  final ValueChanged<String?> onTimeFrameChanged;

  const DashboardHeader({
    super.key,
    required this.isMobile,
    required this.selectedTimeFrame,
    required this.onRefresh,
    required this.onTimeFrameChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      decoration: AppTheme.gradientDecoration,
      child: isMobile ? _buildMobileHeader() : _buildDesktopHeader(),
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard Inwestycyjny',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textOnPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Przegląd portfela i analiza wyników',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textOnPrimary.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTimeFrameSelector()),
            const SizedBox(width: 16),
            _buildRefreshButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard Inwestycyjny',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textOnPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kompleksowa analiza portfela i zaawansowane metryki',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.textOnPrimary.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        _buildTimeFrameSelector(),
        const SizedBox(width: 16),
        _buildRefreshButton(),
      ],
    );
  }

  Widget _buildTimeFrameSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: selectedTimeFrame,
        dropdownColor: AppTheme.surfaceCard,
        underline: const SizedBox(),
        style: const TextStyle(color: AppTheme.textOnPrimary),
        items: const [
          DropdownMenuItem(value: '1M', child: Text('1 miesiąc')),
          DropdownMenuItem(value: '3M', child: Text('3 miesiące')),
          DropdownMenuItem(value: '6M', child: Text('6 miesięcy')),
          DropdownMenuItem(value: '12M', child: Text('12 miesięcy')),
          DropdownMenuItem(value: 'ALL', child: Text('Wszystko')),
        ],
        onChanged: onTimeFrameChanged,
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh, color: AppTheme.textOnPrimary),
        tooltip: 'Odśwież dane',
      ),
    );
  }
}
