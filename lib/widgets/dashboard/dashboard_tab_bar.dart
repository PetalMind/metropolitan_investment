import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DashboardTabBar extends StatelessWidget {
  final bool isMobile;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  const DashboardTabBar({
    super.key,
    required this.isMobile,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16.0 : 24.0,
        vertical: 16,
      ),
      child: isMobile ? _buildMobileTabBar() : _buildDesktopTabBar(),
    );
  }

  Widget _buildMobileTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCompactTabButton(0, 'Przegląd', Icons.dashboard),
          _buildCompactTabButton(1, 'Wydajność', Icons.trending_up),
          _buildCompactTabButton(2, 'Ryzyko', Icons.security),
          _buildCompactTabButton(3, 'Prognozy', Icons.analytics),
          _buildCompactTabButton(4, 'Benchmarki', Icons.compare),
          _buildCompactTabButton(5, 'Cache Debug', Icons.storage),
        ],
      ),
    );
  }

  Widget _buildDesktopTabBar() {
    return Row(
      children: [
        _buildTabButton(0, 'Przegląd', Icons.dashboard),
        _buildTabButton(1, 'Wydajność', Icons.trending_up),
        _buildTabButton(2, 'Ryzyko', Icons.security),
        _buildTabButton(3, 'Prognozy', Icons.analytics),
        _buildTabButton(4, 'Benchmarki', Icons.compare),
        _buildTabButton(5, 'Cache Debug', Icons.storage),
      ],
    );
  }

  Widget _buildCompactTabButton(int index, String label, IconData icon) {
    final isSelected = selectedTab == index;

    return GestureDetector(
      onTap: () => onTabChanged(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.borderSecondary,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppTheme.textOnPrimary
                  : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? AppTheme.textOnPrimary
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
